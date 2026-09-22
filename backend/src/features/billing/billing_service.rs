use chrono::Utc;
use serde_json::json;
use uuid::Uuid;

use crate::config::BillingSettings;
use crate::features::access::{Actor, SessionDirectory};
use crate::features::audit::{AuditAction, AuditEntry, AuditTrail};
use crate::infrastructure::realtime::{EventBroadcaster, RealtimeEvent, RealtimeTopic};
use crate::shared::{ApiError, ApiResult};

use super::billing_payloads::{BillingOverview, CheckoutView, PlanOffer, SubscriptionSummary};
use super::billing_repository::{BillingRepository, ConfirmedPayment};
use super::payment_gateway::{CheckoutRequest, PaidCheckout, PaymentGateway};
use super::plan::{OFFERED_MONTHS, Plan, Standing, SubscriptionRecord};

pub struct BillingDependencies {
    pub repository: BillingRepository,
    pub settings: BillingSettings,
    pub sessions: SessionDirectory,
    pub audit: AuditTrail,
    pub broadcaster: EventBroadcaster,
}

/// Plans, payments, and the answer to "may this account do that right now".
#[derive(Clone)]
pub struct BillingService {
    repository: BillingRepository,
    gateway: Option<PaymentGateway>,
    settings: BillingSettings,
    sessions: SessionDirectory,
    audit: AuditTrail,
    broadcaster: EventBroadcaster,
}

impl BillingService {
    pub fn new(dependencies: BillingDependencies) -> Self {
        Self {
            gateway: PaymentGateway::from_settings(&dependencies.settings),
            repository: dependencies.repository,
            settings: dependencies.settings,
            sessions: dependencies.sessions,
            audit: dependencies.audit,
            broadcaster: dependencies.broadcaster,
        }
    }

    pub fn standing(&self, subscription: Option<&SubscriptionRecord>) -> Standing {
        Standing::of(
            subscription,
            Utc::now(),
            self.settings.grace,
            self.settings.enforced(),
        )
    }

    pub fn summary(&self, subscription: Option<&SubscriptionRecord>) -> SubscriptionSummary {
        SubscriptionSummary::of(self.standing(subscription), self.settings.grace)
    }

    pub async fn subscription_of(&self, owner_id: Uuid) -> ApiResult<Option<SubscriptionRecord>> {
        self.repository.subscription(owner_id).await
    }

    pub fn trial_length(&self) -> chrono::Duration {
        self.settings.trial
    }

    pub fn gateway(&self) -> Option<&PaymentGateway> {
        self.gateway.as_ref()
    }

    pub async fn overview(&self, owner_id: Uuid) -> ApiResult<BillingOverview> {
        let subscription = self.repository.subscription(owner_id).await?;
        Ok(BillingOverview {
            enabled: self.settings.enforced(),
            subscription: self.summary(subscription.as_ref()),
            plans: vec![PlanOffer::of(Plan::Basic), PlanOffer::of(Plan::Pro)],
            payments: self.repository.payments(owner_id).await?,
        })
    }

    /// Opens a checkout for [months] of [plan] and says where to pay.
    pub async fn checkout(
        &self,
        owner: &Actor,
        plan: Plan,
        months: u32,
    ) -> ApiResult<CheckoutView> {
        let gateway = self
            .gateway
            .as_ref()
            .ok_or_else(|| ApiError::BadRequest("this server does not take payments".into()))?;
        if !OFFERED_MONTHS.contains(&months) {
            return Err(ApiError::BadRequest("months must be 1 or 12".into()));
        }

        let request = CheckoutRequest {
            payment_id: Uuid::new_v4(),
            plan,
            months,
            amount_centavos: plan.price_centavos(months),
        };
        let provider = match gateway {
            PaymentGateway::Test { .. } => "test",
            PaymentGateway::PayMongo(_) => "paymongo",
        };

        self.repository
            .open_payment(
                request.payment_id,
                owner.owner_id,
                plan,
                months,
                request.amount_centavos,
                provider,
            )
            .await?;
        let checkout = gateway.create_checkout(&request).await?;
        self.repository
            .set_reference(request.payment_id, &checkout.reference)
            .await?;

        Ok(CheckoutView {
            payment_id: request.payment_id,
            checkout_url: checkout.url,
            amount: request.amount_centavos as f64 / 100.0,
        })
    }

    /// Acts on a gateway's word that a checkout was paid. Safe to be told
    /// twice; the second time changes nothing.
    pub async fn confirm(&self, paid: PaidCheckout) -> ApiResult<()> {
        let Some(confirmed) = self
            .repository
            .confirm(&paid.reference, paid.method.as_deref())
            .await?
        else {
            return Ok(());
        };

        // Paying unpauses at once: every instance re-reads its sessions, and
        // the owner's phones are told to re-read their access and upload
        // what waited.
        self.sessions.forget_all();
        self.log(&confirmed).await;
        for store_id in self.repository.store_ids(confirmed.owner_id).await? {
            self.broadcaster
                .publish(RealtimeEvent::new(
                    store_id,
                    RealtimeTopic::AccessChanged,
                    None,
                ))
                .await;
        }
        Ok(())
    }

    pub async fn paymongo_webhook(&self, signature: &str, raw_body: &[u8]) -> ApiResult<()> {
        let Some(PaymentGateway::PayMongo(gateway)) = &self.gateway else {
            return Err(ApiError::NotFound("webhook"));
        };
        match gateway.verify_webhook(signature, raw_body)? {
            Some(paid) => self.confirm(paid).await,
            None => Ok(()),
        }
    }

    /// The test gateway's "pay" button. Refuses on any other gateway.
    pub async fn pay_test_checkout(&self, payment_id: Uuid) -> ApiResult<()> {
        if !matches!(self.gateway, Some(PaymentGateway::Test { .. })) {
            return Err(ApiError::NotFound("checkout"));
        }
        let (reference, _) = self
            .repository
            .pending_reference(payment_id)
            .await?
            .ok_or(ApiError::NotFound("checkout"))?;

        self.confirm(PaidCheckout {
            reference,
            method: Some("test".into()),
        })
        .await
    }

    pub async fn test_checkout_amount(&self, payment_id: Uuid) -> ApiResult<Option<String>> {
        if !matches!(self.gateway, Some(PaymentGateway::Test { .. })) {
            return Ok(None);
        }
        Ok(self
            .repository
            .pending_reference(payment_id)
            .await?
            .map(|(_, amount)| format!("₱{amount}")))
    }

    /// Whether this owner may open one more store.
    pub async fn check_new_store(&self, owner: &Actor) -> ApiResult<()> {
        let standing = self.standing(owner.subscription.as_ref());
        if !standing.can_upload() {
            return Err(paused());
        }
        if let Some(limit) = standing.store_limit()
            && self.repository.store_count(owner.owner_id).await? >= limit
        {
            return Err(ApiError::UpgradeRequired(format!(
                "your plan includes {limit} store{}",
                if limit == 1 { "" } else { "s" }
            )));
        }
        Ok(())
    }

    /// Whether this owner's plan includes staff.
    pub fn check_staff(&self, subscription: Option<&SubscriptionRecord>) -> ApiResult<()> {
        let standing = self.standing(subscription);
        if standing.allows_staff() {
            return Ok(());
        }
        if standing.can_upload() {
            Err(ApiError::UpgradeRequired(
                "staff accounts come with Kitaza Pro".into(),
            ))
        } else {
            Err(paused())
        }
    }

    /// Checked on every store-scoped request after ownership. Reads are
    /// always open to the owner: nothing is ever held back from them.
    pub async fn check_store_request(
        &self,
        actor: &Actor,
        store_id: Uuid,
        is_write: bool,
    ) -> ApiResult<()> {
        let standing = self.standing(actor.subscription.as_ref());

        if !actor.is_owner() && !standing.allows_staff() {
            return Err(if standing.can_upload() {
                ApiError::UpgradeRequired("the store's plan no longer includes staff".into())
            } else {
                paused()
            });
        }
        if !is_write {
            return Ok(());
        }
        if !standing.can_upload() {
            return Err(paused());
        }
        if let Some(limit) = standing.store_limit()
            && !self
                .repository
                .is_within_first(actor.owner_id, store_id, limit)
                .await?
        {
            return Err(ApiError::UpgradeRequired(format!(
                "your plan takes new entries in {limit} store{}",
                if limit == 1 { "" } else { "s" }
            )));
        }
        Ok(())
    }

    async fn log(&self, confirmed: &ConfirmedPayment) {
        let payer = Actor {
            owner_id: confirmed.owner_id,
            session_id: Uuid::nil(),
            name: confirmed.owner_name.clone(),
            device_name: confirmed.method.clone().unwrap_or_else(|| "payment".into()),
            staff: None,
            subscription: None,
        };
        self.audit
            .record(
                &payer,
                AuditEntry::account(
                    None,
                    AuditAction::SubscriptionPaid,
                    confirmed.owner_id,
                    json!({
                        "plan": confirmed.plan,
                        "months": confirmed.months,
                        "amount": confirmed.amount,
                        "paid_through": confirmed.paid_through,
                    }),
                ),
            )
            .await;
    }
}

fn paused() -> ApiError {
    ApiError::SubscriptionRequired(
        "this account is paused until it is paid; nothing on the phones is lost".into(),
    )
}
