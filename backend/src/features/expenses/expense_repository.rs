use chrono::{DateTime, Utc};
use uuid::Uuid;

use crate::infrastructure::database::PgPool;
use crate::shared::{ApiResult, Money, PageRequest};

use super::expense_payloads::{ExpenseFilter, ExpenseView};

#[derive(Clone)]
pub struct ExpenseRepository {
    pool: PgPool,
}

impl ExpenseRepository {
    pub fn new(pool: PgPool) -> Self {
        Self { pool }
    }

    pub async fn upsert(
        &self,
        store_id: Uuid,
        expense_id: Uuid,
        category: &str,
        description: Option<&str>,
        amount: Money,
        occurred_at: DateTime<Utc>,
    ) -> ApiResult<ExpenseView> {
        let expense = sqlx::query_as::<_, ExpenseView>(
            "INSERT INTO expenses (id, store_id, category, description, amount, occurred_at)
             VALUES ($1, $2, $3, $4, $5, $6)
             ON CONFLICT (id) DO UPDATE SET
                 category    = EXCLUDED.category,
                 description = EXCLUDED.description,
                 amount      = EXCLUDED.amount,
                 occurred_at = EXCLUDED.occurred_at,
                 deleted_at  = NULL,
                 updated_at  = now()
             RETURNING id, category, description, amount, occurred_at",
        )
        .bind(expense_id)
        .bind(store_id)
        .bind(category)
        .bind(description)
        .bind(amount)
        .bind(occurred_at)
        .fetch_one(&self.pool)
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

    pub async fn soft_delete(&self, store_id: Uuid, expense_id: Uuid) -> ApiResult<bool> {
        let result = sqlx::query(
            "UPDATE expenses SET deleted_at = now(), updated_at = now()
             WHERE store_id = $1 AND id = $2 AND deleted_at IS NULL",
        )
        .bind(store_id)
        .bind(expense_id)
        .execute(&self.pool)
        .await?;

        Ok(result.rows_affected() > 0)
    }
}
