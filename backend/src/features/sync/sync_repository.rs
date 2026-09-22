use std::time::Duration;

use chrono::{DateTime, Utc};
use serde_json::Value;
use uuid::Uuid;

use crate::infrastructure::database::PgPool;
use crate::shared::ApiResult;

use super::sync_cursor::{SyncTable, TableMark};

/// One page of changed rows, plus where that page ended.
pub struct ChangedPage {
    pub rows: Vec<Value>,
    pub last: Option<TableMark>,
}

/// Rows are returned as JSON built in the database. The pull is a
/// pass-through to the device's SQLite, so shaping each table into a Rust
/// struct first would be pure overhead.
#[derive(Clone)]
pub struct SyncRepository {
    pool: PgPool,
    settle_window: Duration,
}

impl SyncRepository {
    pub fn new(pool: PgPool, settle_window: Duration) -> Self {
        Self {
            pool,
            settle_window,
        }
    }

    /// Keyset pagination on `(updated_at, id)`. Unlike "everything since a
    /// timestamp", this never skips rows when a page is full, and never
    /// splits a group of rows that share a timestamp.
    pub async fn changed_since(
        &self,
        table: SyncTable,
        store_id: Uuid,
        after: TableMark,
        limit: i64,
    ) -> ApiResult<ChangedPage> {
        let rows: Vec<(Value, DateTime<Utc>, Uuid)> = sqlx::query_as(page_query(table))
            .bind(store_id)
            .bind(after.updated_at)
            .bind(after.id)
            .bind(self.settle_window.as_secs_f64())
            .bind(limit)
            .fetch_all(&self.pool)
            .await?;

        let last = rows.last().map(|(_, updated_at, id)| TableMark {
            updated_at: *updated_at,
            id: *id,
        });

        Ok(ChangedPage {
            rows: rows.into_iter().map(|(row, _, _)| row).collect(),
            last,
        })
    }

    pub async fn lines_for_sales(&self, sale_ids: &[Uuid]) -> ApiResult<Vec<Value>> {
        if sale_ids.is_empty() {
            return Ok(Vec::new());
        }

        let rows: Vec<(Value,)> = sqlx::query_as(
            "SELECT to_jsonb(i) FROM sale_items i WHERE i.sale_id = ANY($1) ORDER BY i.sale_id",
        )
        .bind(sale_ids)
        .fetch_all(&self.pool)
        .await?;

        Ok(rows.into_iter().map(|(row,)| row).collect())
    }
}

/// One literal query per table: sqlx rejects SQL assembled at runtime, and the
/// five differ only in the table name.
fn page_query(table: SyncTable) -> &'static str {
    match table {
        SyncTable::Products => {
            "SELECT to_jsonb(t) - 'store_id', t.updated_at, t.id FROM products t
             WHERE t.store_id = $1 AND (t.updated_at, t.id) > ($2, $3)
               AND t.updated_at < now() - ($4 * interval '1 second')
             ORDER BY t.updated_at, t.id LIMIT $5"
        }
        SyncTable::Sales => {
            "SELECT to_jsonb(t) - 'store_id', t.updated_at, t.id FROM sales t
             WHERE t.store_id = $1 AND (t.updated_at, t.id) > ($2, $3)
               AND t.updated_at < now() - ($4 * interval '1 second')
             ORDER BY t.updated_at, t.id LIMIT $5"
        }
        SyncTable::Expenses => {
            "SELECT to_jsonb(t) - 'store_id', t.updated_at, t.id FROM expenses t
             WHERE t.store_id = $1 AND (t.updated_at, t.id) > ($2, $3)
               AND t.updated_at < now() - ($4 * interval '1 second')
             ORDER BY t.updated_at, t.id LIMIT $5"
        }
        SyncTable::Withdrawals => {
            "SELECT to_jsonb(t) - 'store_id', t.updated_at, t.id FROM owner_withdrawals t
             WHERE t.store_id = $1 AND (t.updated_at, t.id) > ($2, $3)
               AND t.updated_at < now() - ($4 * interval '1 second')
             ORDER BY t.updated_at, t.id LIMIT $5"
        }
        SyncTable::StockMovements => {
            "SELECT to_jsonb(t) - 'store_id', t.updated_at, t.id FROM stock_movements t
             WHERE t.store_id = $1 AND (t.updated_at, t.id) > ($2, $3)
               AND t.updated_at < now() - ($4 * interval '1 second')
             ORDER BY t.updated_at, t.id LIMIT $5"
        }
    }
}
