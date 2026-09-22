use chrono::{DateTime, Utc};
use uuid::Uuid;

use crate::infrastructure::database::PgPool;
use crate::shared::{ApiResult, Money, PageRequest};

use super::withdrawal_payloads::WithdrawalView;

#[derive(sqlx::FromRow)]
struct UpsertedWithdrawal {
    #[sqlx(flatten)]
    withdrawal: WithdrawalView,
    inserted: bool,
}

#[derive(Clone)]
pub struct WithdrawalRepository {
    pool: PgPool,
}

impl WithdrawalRepository {
    pub fn new(pool: PgPool) -> Self {
        Self { pool }
    }

    pub async fn upsert(
        &self,
        store_id: Uuid,
        withdrawal_id: Uuid,
        amount: Money,
        reason: Option<&str>,
        occurred_at: DateTime<Utc>,
    ) -> ApiResult<Option<(WithdrawalView, bool)>> {
        let withdrawal = sqlx::query_as::<_, UpsertedWithdrawal>(
            "INSERT INTO owner_withdrawals (id, store_id, amount, reason, occurred_at)
             VALUES ($1, $2, $3, $4, $5)
             ON CONFLICT (id) DO UPDATE SET
                 amount      = EXCLUDED.amount,
                 reason      = EXCLUDED.reason,
                 occurred_at = EXCLUDED.occurred_at,
                 deleted_at  = NULL,
                 updated_at  = now()
             WHERE owner_withdrawals.store_id = EXCLUDED.store_id
             RETURNING id, amount, reason, occurred_at, (xmax = 0) AS inserted",
        )
        .bind(withdrawal_id)
        .bind(store_id)
        .bind(amount)
        .bind(reason)
        .bind(occurred_at)
        .fetch_optional(&self.pool)
        .await?;

        Ok(withdrawal.map(|row| (row.withdrawal, row.inserted)))
    }

    pub async fn list(&self, store_id: Uuid, page: PageRequest) -> ApiResult<Vec<WithdrawalView>> {
        let withdrawals = sqlx::query_as::<_, WithdrawalView>(
            "SELECT id, amount, reason, occurred_at FROM owner_withdrawals
             WHERE store_id = $1 AND deleted_at IS NULL
             ORDER BY occurred_at DESC
             LIMIT $2 OFFSET $3",
        )
        .bind(store_id)
        .bind(page.limit())
        .bind(page.offset())
        .fetch_all(&self.pool)
        .await?;

        Ok(withdrawals)
    }

    pub async fn soft_delete(
        &self,
        store_id: Uuid,
        withdrawal_id: Uuid,
    ) -> ApiResult<Option<WithdrawalView>> {
        let removed = sqlx::query_as::<_, WithdrawalView>(
            "UPDATE owner_withdrawals SET deleted_at = now(), updated_at = now()
             WHERE store_id = $1 AND id = $2 AND deleted_at IS NULL
             RETURNING id, amount, reason, occurred_at",
        )
        .bind(store_id)
        .bind(withdrawal_id)
        .fetch_optional(&self.pool)
        .await?;

        Ok(removed)
    }
}
