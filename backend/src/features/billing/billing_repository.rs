use chrono::{DateTime, Utc};
use rust_decimal::Decimal;
use serde::Serialize;
use sqlx::FromRow;
use uuid::Uuid;

use crate::infrastructure::database::PgPool;
use crate::shared::{ApiResult, Money};

use super::plan::{Plan, SubscriptionRecord, paid_through_after};

#[derive(Debug, Serialize, FromRow)]
pub struct PaymentView {
    pub id: Uuid,
    pub plan: String,
    pub months: i32,
    pub amount: Money,
    pub currency: String,
    pub status: String,
    pub method: Option<String>,
    pub paid_through: Option<DateTime<Utc>>,
    pub created_at: DateTime<Utc>,
    pub paid_at: Option<DateTime<Utc>>,
}

/// A payment that has just been confirmed, and what it bought.
#[derive(Debug)]
pub struct ConfirmedPayment {
    pub owner_id: Uuid,
    pub owner_name: String,
    pub plan: Plan,
    pub months: u32,
    pub amount: Money,
    pub method: Option<String>,
    pub paid_through: DateTime<Utc>,
}

#[derive(FromRow)]
struct PendingPayment {
    owner_id: Uuid,
    owner_name: String,
    plan: String,
    months: i32,
    amount: Money,
}

#[derive(Clone)]
pub struct BillingRepository {
    pool: PgPool,
}

impl BillingRepository {
    pub fn new(pool: PgPool) -> Self {
        Self { pool }
    }

    pub async fn subscription(&self, owner_id: Uuid) -> ApiResult<Option<SubscriptionRecord>> {
        let record = sqlx::query_as::<_, SubscriptionRecord>(
            "SELECT plan, trial_ends_at, paid_through FROM subscriptions WHERE owner_id = $1",
        )
        .bind(owner_id)
        .fetch_optional(&self.pool)
        .await?;

        Ok(record)
    }

    pub async fn open_payment(
        &self,
        id: Uuid,
        owner_id: Uuid,
        plan: Plan,
        months: u32,
        amount_centavos: i64,
        provider: &str,
    ) -> ApiResult<()> {
        sqlx::query(
            "INSERT INTO payments (id, owner_id, plan, months, amount, provider)
             VALUES ($1, $2, $3, $4, $5, $6)",
        )
        .bind(id)
        .bind(owner_id)
        .bind(plan.as_str())
        .bind(months as i32)
        .bind(Decimal::new(amount_centavos, 2))
        .bind(provider)
        .execute(&self.pool)
        .await?;

        Ok(())
    }

    pub async fn set_reference(&self, id: Uuid, reference: &str) -> ApiResult<()> {
        sqlx::query("UPDATE payments SET provider_reference = $2 WHERE id = $1")
            .bind(id)
            .bind(reference)
            .execute(&self.pool)
            .await?;

        Ok(())
    }

    /// Marks the payment behind [reference] paid and extends its owner's
    /// subscription, in one transaction.
    ///
    /// Gateways deliver the same event more than once, so this is written to
    /// be told twice: only a pending payment can be confirmed, and a second
    /// confirmation returns `None` and changes nothing.
    pub async fn confirm(
        &self,
        reference: &str,
        method: Option<&str>,
    ) -> ApiResult<Option<ConfirmedPayment>> {
        let mut transaction = self.pool.begin().await?;

        let pending = sqlx::query_as::<_, PendingPayment>(
            "UPDATE payments p SET status = 'paid', paid_at = now(), method = $2
             FROM owners o
             WHERE p.provider_reference = $1 AND p.status = 'pending' AND o.id = p.owner_id
             RETURNING p.owner_id, o.full_name AS owner_name, p.plan, p.months, p.amount",
        )
        .bind(reference)
        .bind(method)
        .fetch_optional(&mut *transaction)
        .await?;

        let Some(pending) = pending else {
            transaction.rollback().await?;
            return Ok(None);
        };

        let current = sqlx::query_as::<_, SubscriptionRecord>(
            "SELECT plan, trial_ends_at, paid_through FROM subscriptions
             WHERE owner_id = $1 FOR UPDATE",
        )
        .bind(pending.owner_id)
        .fetch_optional(&mut *transaction)
        .await?;

        let plan = Plan::parse(&pending.plan).unwrap_or(Plan::Basic);
        let months = pending.months.max(1) as u32;
        let paid_through = paid_through_after(current.as_ref(), plan, months, Utc::now());

        sqlx::query(
            "INSERT INTO subscriptions (owner_id, plan, paid_through) VALUES ($1, $2, $3)
             ON CONFLICT (owner_id) DO UPDATE SET
                 plan = EXCLUDED.plan, paid_through = EXCLUDED.paid_through, updated_at = now()",
        )
        .bind(pending.owner_id)
        .bind(plan.as_str())
        .bind(paid_through)
        .execute(&mut *transaction)
        .await?;

        sqlx::query("UPDATE payments SET paid_through = $2 WHERE provider_reference = $1")
            .bind(reference)
            .bind(paid_through)
            .execute(&mut *transaction)
            .await?;

        transaction.commit().await?;
        Ok(Some(ConfirmedPayment {
            owner_id: pending.owner_id,
            owner_name: pending.owner_name,
            plan,
            months,
            amount: pending.amount,
            method: method.map(str::to_owned),
            paid_through,
        }))
    }

    pub async fn payments(&self, owner_id: Uuid) -> ApiResult<Vec<PaymentView>> {
        let payments = sqlx::query_as::<_, PaymentView>(
            "SELECT id, plan, months, amount, currency, status, method, paid_through,
                    created_at, paid_at
             FROM payments WHERE owner_id = $1 AND status = 'paid'
             ORDER BY created_at DESC LIMIT 50",
        )
        .bind(owner_id)
        .fetch_all(&self.pool)
        .await?;

        Ok(payments)
    }

    /// For the test gateway's checkout page.
    pub async fn pending_reference(&self, payment_id: Uuid) -> ApiResult<Option<(String, Money)>> {
        let row: Option<(String, Money)> = sqlx::query_as(
            "SELECT provider_reference, amount FROM payments
             WHERE id = $1 AND status = 'pending' AND provider_reference IS NOT NULL",
        )
        .bind(payment_id)
        .fetch_optional(&self.pool)
        .await?;

        Ok(row)
    }

    pub async fn store_count(&self, owner_id: Uuid) -> ApiResult<i64> {
        let (count,): (i64,) = sqlx::query_as("SELECT count(*) FROM stores WHERE owner_id = $1")
            .bind(owner_id)
            .fetch_one(&self.pool)
            .await?;

        Ok(count)
    }

    /// Whether [store_id] is among the owner's first [limit] stores. On a
    /// smaller plan the oldest stores keep taking entries and the rest wait.
    pub async fn is_within_first(
        &self,
        owner_id: Uuid,
        store_id: Uuid,
        limit: i64,
    ) -> ApiResult<bool> {
        let (within,): (bool,) = sqlx::query_as(
            "SELECT $2 IN (SELECT id FROM stores WHERE owner_id = $1
                           ORDER BY created_at, id LIMIT $3)",
        )
        .bind(owner_id)
        .bind(store_id)
        .bind(limit)
        .fetch_one(&self.pool)
        .await?;

        Ok(within)
    }

    pub async fn store_ids(&self, owner_id: Uuid) -> ApiResult<Vec<Uuid>> {
        let ids: Vec<(Uuid,)> = sqlx::query_as("SELECT id FROM stores WHERE owner_id = $1")
            .bind(owner_id)
            .fetch_all(&self.pool)
            .await?;

        Ok(ids.into_iter().map(|(id,)| id).collect())
    }
}
