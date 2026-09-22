use chrono::{DateTime, Utc};
use serde_json::Value;
use uuid::Uuid;

use crate::infrastructure::database::PgPool;
use crate::shared::ApiResult;

/// Rows are returned as JSON built in the database. The sync endpoint is a
/// pass-through to the client's local SQLite, so shaping each table into a Rust
/// struct first would be pure overhead.
#[derive(Clone)]
pub struct SyncRepository {
    pool: PgPool,
}

impl SyncRepository {
    pub fn new(pool: PgPool) -> Self {
        Self { pool }
    }

    pub async fn changed_products(
        &self,
        store_id: Uuid,
        since: DateTime<Utc>,
    ) -> ApiResult<Vec<Value>> {
        self.changed_rows(
            "SELECT to_jsonb(p) - 'store_id' FROM products p
             WHERE p.store_id = $1 AND p.updated_at > $2
             ORDER BY p.updated_at LIMIT 2000",
            store_id,
            since,
        )
        .await
    }

    pub async fn changed_sales(
        &self,
        store_id: Uuid,
        since: DateTime<Utc>,
    ) -> ApiResult<Vec<Value>> {
        self.changed_rows(
            "SELECT to_jsonb(s) - 'store_id' FROM sales s
             WHERE s.store_id = $1 AND s.updated_at > $2
             ORDER BY s.updated_at LIMIT 2000",
            store_id,
            since,
        )
        .await
    }

    pub async fn changed_sale_items(
        &self,
        store_id: Uuid,
        since: DateTime<Utc>,
    ) -> ApiResult<Vec<Value>> {
        self.changed_rows(
            "SELECT to_jsonb(i) FROM sale_items i
             JOIN sales s ON s.id = i.sale_id
             WHERE s.store_id = $1 AND s.updated_at > $2
             ORDER BY s.updated_at LIMIT 5000",
            store_id,
            since,
        )
        .await
    }

    pub async fn changed_expenses(
        &self,
        store_id: Uuid,
        since: DateTime<Utc>,
    ) -> ApiResult<Vec<Value>> {
        self.changed_rows(
            "SELECT to_jsonb(e) - 'store_id' FROM expenses e
             WHERE e.store_id = $1 AND e.updated_at > $2
             ORDER BY e.updated_at LIMIT 2000",
            store_id,
            since,
        )
        .await
    }

    pub async fn changed_withdrawals(
        &self,
        store_id: Uuid,
        since: DateTime<Utc>,
    ) -> ApiResult<Vec<Value>> {
        self.changed_rows(
            "SELECT to_jsonb(w) - 'store_id' FROM owner_withdrawals w
             WHERE w.store_id = $1 AND w.updated_at > $2
             ORDER BY w.updated_at LIMIT 2000",
            store_id,
            since,
        )
        .await
    }

    pub async fn changed_stock_movements(
        &self,
        store_id: Uuid,
        since: DateTime<Utc>,
    ) -> ApiResult<Vec<Value>> {
        self.changed_rows(
            "SELECT to_jsonb(m) - 'store_id' FROM stock_movements m
             WHERE m.store_id = $1 AND m.updated_at > $2
             ORDER BY m.updated_at LIMIT 5000",
            store_id,
            since,
        )
        .await
    }

    async fn changed_rows(
        &self,
        query: &'static str,
        store_id: Uuid,
        since: DateTime<Utc>,
    ) -> ApiResult<Vec<Value>> {
        let rows: Vec<(Value,)> = sqlx::query_as(query)
            .bind(store_id)
            .bind(since)
            .fetch_all(&self.pool)
            .await?;

        Ok(rows.into_iter().map(|row| row.0).collect())
    }
}
