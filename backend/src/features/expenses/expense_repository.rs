use chrono::{DateTime, Utc};
use uuid::Uuid;

use crate::infrastructure::database::PgPool;
use crate::shared::{ApiResult, Money, PageRequest};

use super::expense_payloads::{ExpenseFilter, ExpenseView};

#[derive(Debug, sqlx::FromRow)]
pub struct UpsertedExpense {
    #[sqlx(flatten)]
    pub expense: ExpenseView,
    /// False when an existing row was updated, as on a retried push.
    pub inserted: bool,
}

#[derive(Clone)]
pub struct ExpenseRepository {
    pool: PgPool,
}

impl ExpenseRepository {
    pub fn new(pool: PgPool) -> Self {
        Self { pool }
    }

    /// Insert-or-update on the device's id. An existing expense is only
    /// overwritten by the owner or by whoever first recorded it; `None`
    /// means the write was refused.
    #[allow(clippy::too_many_arguments)]
    pub async fn upsert(
        &self,
        store_id: Uuid,
        expense_id: Uuid,
        category: &str,
        description: Option<&str>,
        amount: Money,
        occurred_at: DateTime<Utc>,
        recorded_by: Option<Uuid>,
        is_owner: bool,
    ) -> ApiResult<Option<UpsertedExpense>> {
        let expense = sqlx::query_as::<_, UpsertedExpense>(
            "INSERT INTO expenses
                 (id, store_id, category, description, amount, occurred_at, recorded_by_staff_id)
             VALUES ($1, $2, $3, $4, $5, $6, $7)
             ON CONFLICT (id) DO UPDATE SET
                 category    = EXCLUDED.category,
                 description = EXCLUDED.description,
                 amount      = EXCLUDED.amount,
                 occurred_at = EXCLUDED.occurred_at,
                 deleted_at  = NULL,
                 updated_at  = now()
             WHERE expenses.store_id = EXCLUDED.store_id
               AND ($8 OR expenses.recorded_by_staff_id = EXCLUDED.recorded_by_staff_id)
             RETURNING id, category, description, amount, occurred_at, (xmax = 0) AS inserted",
        )
        .bind(expense_id)
        .bind(store_id)
        .bind(category)
        .bind(description)
        .bind(amount)
        .bind(occurred_at)
        .bind(recorded_by)
        .bind(is_owner)
        .fetch_optional(&self.pool)
        .await?;

        Ok(expense)
    }

    pub async fn list(
        &self,
        store_id: Uuid,
        filter: &ExpenseFilter,
        page: PageRequest,
    ) -> ApiResult<Vec<ExpenseView>> {
        let expenses = sqlx::query_as::<_, ExpenseView>(
            "SELECT id, category, description, amount, occurred_at FROM expenses
             WHERE store_id = $1
               AND deleted_at IS NULL
               AND ($2::timestamptz IS NULL OR occurred_at >= $2)
               AND ($3::timestamptz IS NULL OR occurred_at < $3)
               AND ($4::text IS NULL OR category = $4)
             ORDER BY occurred_at DESC
             LIMIT $5 OFFSET $6",
        )
        .bind(store_id)
        .bind(filter.from)
        .bind(filter.to)
        .bind(filter.category.as_deref())
        .bind(page.limit())
        .bind(page.offset())
        .fetch_all(&self.pool)
        .await?;

        Ok(expenses)
    }

    pub async fn soft_delete(
        &self,
        store_id: Uuid,
        expense_id: Uuid,
    ) -> ApiResult<Option<ExpenseView>> {
        let removed = sqlx::query_as::<_, ExpenseView>(
            "UPDATE expenses SET deleted_at = now(), updated_at = now()
             WHERE store_id = $1 AND id = $2 AND deleted_at IS NULL
             RETURNING id, category, description, amount, occurred_at",
        )
        .bind(store_id)
        .bind(expense_id)
        .fetch_optional(&self.pool)
        .await?;

        Ok(removed)
    }
}
