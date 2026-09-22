use chrono::{DateTime, Utc};
use uuid::Uuid;

use crate::infrastructure::database::PgPool;
use crate::shared::{ApiResult, Money, PageRequest};

use super::withdrawal_payloads::WithdrawalView;

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
    ) -> ApiResult<WithdrawalView> {
        let withdrawal = sqlx::query_as::<_, WithdrawalView>(
            "INSERT INTO owner_withdrawals (id, store_id, amount, reason, occurred_at)
             VALUES ($1, $2, $3, $4, $5)
             ON CONFLICT (id) DO UPDATE SET
                 amount      = EXCLUDED.amount,
                 reason      = EXCLUDED.reason,
                 occurred_at = EXCLUDED.occurred_at,
                 deleted_at  = NULL,
                 updated_at  = now()
             RETURNING id, amount, reason, occurred_at",
        )
        .bind(withdrawal_id)
        .bind(store_id)
        .bind(amount)
        .bind(reason)
        .bind(occurred_at)
        .fetch_one(&self.pool)
        .await?;

        Ok(withdrawal)
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

    pub async fn soft_delete(&self, store_id: Uuid, withdrawal_id: Uuid) -> ApiResult<bool> {
        let result = sqlx::query(
            "UPDATE owner_withdrawals SET deleted_at = now(), updated_at = now()
             WHERE store_id = $1 AND id = $2 AND deleted_at IS NULL",
        )
        .bind(store_id)
        .bind(withdrawal_id)
        .execute(&self.pool)
        .await?;

        Ok(result.rows_affected() > 0)
    }
}
