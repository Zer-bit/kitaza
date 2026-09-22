use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;
use validator::Validate;

use super::billing_repository::PaymentView;
use super::plan::{Plan, Standing};

/// Where an account stands, as phones show it. Sent with every account
/// description so a phone knows whether its uploads will be taken.
#[derive(Debug, Serialize)]
pub struct SubscriptionSummary {
    /// `unlimited`, `trial`, `active`, `grace` or `paused`.
    pub status: &'static str,
    /// The plan whose features apply now. Absent while paused.
    #[serde(skip_serializing_if = "Option::is_none")]
    pub plan: Option<Plan>,
    /// When the trial or paid period runs out.
    #[serde(skip_serializing_if = "Option::is_none")]
    pub period_ends_at: Option<DateTime<Utc>>,
    /// When uploads pause if nothing is paid, or paused since.
    #[serde(skip_serializing_if = "Option::is_none")]
    pub pauses_at: Option<DateTime<Utc>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub store_limit: Option<i64>,
    pub allows_staff: bool,
}

impl SubscriptionSummary {
    pub fn of(standing: Standing, grace: chrono::Duration) -> Self {
        let (period_ends_at, pauses_at) = match standing {
            Standing::Unlimited => (None, None),
            Standing::Trial { ends_at } => (Some(ends_at), Some(ends_at + grace)),
            Standing::Active { until, .. } => (Some(until), Some(until + grace)),
            Standing::Grace { until, .. } => (None, Some(until)),
            Standing::Paused { since } => (None, Some(since)),
        };

        Self {
            status: standing.status(),
            plan: standing.plan(),
            period_ends_at,
            pauses_at,
            store_limit: standing.store_limit(),
            allows_staff: standing.allows_staff(),
        }
    }
}

#[derive(Debug, Serialize)]
pub struct PlanOffer {
    pub plan: Plan,
    pub monthly_price: f64,
    pub yearly_price: f64,
    pub store_limit: i64,
    pub allows_staff: bool,
}

impl PlanOffer {
    pub fn of(plan: Plan) -> Self {
        Self {
            plan,
            monthly_price: plan.price_centavos(1) as f64 / 100.0,
            yearly_price: plan.price_centavos(12) as f64 / 100.0,
            store_limit: plan.store_limit(),
            allows_staff: plan.allows_staff(),
        }
    }
}

#[derive(Debug, Serialize)]
pub struct BillingOverview {
    /// False on a server with billing switched off: nothing to pay.
    pub enabled: bool,
    pub subscription: SubscriptionSummary,
    pub plans: Vec<PlanOffer>,
    pub payments: Vec<PaymentView>,
}

#[derive(Debug, Deserialize, Validate)]
pub struct CheckoutRequestBody {
    pub plan: Plan,
    #[validate(range(min = 1, max = 12, message = "must be 1 or 12"))]
    pub months: u32,
}

#[derive(Debug, Serialize)]
pub struct CheckoutView {
    pub payment_id: Uuid,
    pub checkout_url: String,
    pub amount: f64,
}
