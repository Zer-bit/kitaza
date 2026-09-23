use chrono::{DateTime, Duration, Utc};
use serde_json::Value;
use sqlx::PgPool;
use sqlx::Row;
use uuid::Uuid;

use crate::shared::ApiResult;

use super::privacy_payloads::{ConsentGiven, DeletionState, LegalDocument};

/// Reads a table as JSON rows. The SQL is glued together by `concat!` at
/// compile time, never at runtime: the export touches a dozen tables, and a
/// query built from a `format!` is the shape SQL injection arrives in.
macro_rules! json_rows {
    ($pool:expr, $owner:expr, $sql:literal) => {{
        let rows = sqlx::query(concat!("SELECT to_jsonb(t) AS row FROM (", $sql, ") t"))
            .bind($owner)
            .fetch_all($pool)
            .await?;
        rows.into_iter()
            .map(|row| row.get::<Value, _>("row"))
            .collect::<Vec<Value>>()
    }};
}

#[derive(Clone)]
pub struct ConsentRepository {
    pool: PgPool,
}

impl ConsentRepository {
    pub fn new(pool: PgPool) -> Self {
        Self { pool }
    }

    /// Records an agreement. Agreeing twice to the same version is not an
    /// error: a phone that lost the reply will send it again.
    pub async fn record(
        &self,
        owner_id: Uuid,
        document: LegalDocument,
        version: &str,
    ) -> ApiResult<()> {
        sqlx::query(
            "INSERT INTO consent_records (owner_id, document, version)
             SELECT $1, $2, $3
             WHERE NOT EXISTS (
                 SELECT 1 FROM consent_records
                 WHERE owner_id = $1 AND document = $2 AND version = $3
             )",
        )
        .bind(owner_id)
        .bind(document.column_value())
        .bind(version)
        .execute(&self.pool)
        .await?;
        Ok(())
    }

    /// The newest agreement on record for each document.
    pub async fn given_by(&self, owner_id: Uuid) -> ApiResult<Vec<ConsentGiven>> {
        let rows = sqlx::query(
            "SELECT DISTINCT ON (document) document, version, agreed_at
             FROM consent_records
             WHERE owner_id = $1
             ORDER BY document, agreed_at DESC",
        )
        .bind(owner_id)
        .fetch_all(&self.pool)
        .await?;

        Ok(rows
            .into_iter()
            .filter_map(|row| {
                let raw: String = row.get("document");
                let document = match raw.as_str() {
                    "privacy_notice" => LegalDocument::PrivacyNotice,
                    "terms" => LegalDocument::Terms,
                    _ => return None,
                };
                Some(ConsentGiven {
                    document,
                    version: row.get("version"),
                    agreed_at: row.get("agreed_at"),
                })
            })
            .collect())
    }

    /// Marks an account for deletion and returns when it becomes final.
    /// Asking twice does not move the date further away.
    pub async fn request_deletion(
        &self,
        owner_id: Uuid,
        grace: Duration,
    ) -> ApiResult<DeletionState> {
        let row = sqlx::query(
            "UPDATE owners
             SET deletion_requested_at = COALESCE(deletion_requested_at, now()),
                 delete_after = COALESCE(delete_after, now() + $2)
             WHERE id = $1
             RETURNING deletion_requested_at, delete_after",
        )
        .bind(owner_id)
        .bind(grace)
        .fetch_one(&self.pool)
        .await?;

        Ok(DeletionState {
            requested_at: row.get("deletion_requested_at"),
            deletes_at: row.get("delete_after"),
        })
    }

    pub async fn cancel_deletion(&self, owner_id: Uuid) -> ApiResult<()> {
        sqlx::query(
            "UPDATE owners
             SET deletion_requested_at = NULL, delete_after = NULL
             WHERE id = $1",
        )
        .bind(owner_id)
        .execute(&self.pool)
        .await?;
        Ok(())
    }

    pub async fn deletion_state(&self, owner_id: Uuid) -> ApiResult<Option<DeletionState>> {
        let row =
            sqlx::query("SELECT deletion_requested_at, delete_after FROM owners WHERE id = $1")
                .bind(owner_id)
                .fetch_optional(&self.pool)
                .await?;

        Ok(row.and_then(|row| {
            let requested_at: Option<DateTime<Utc>> = row.get("deletion_requested_at");
            let deletes_at: Option<DateTime<Utc>> = row.get("delete_after");
            Some(DeletionState {
                requested_at: requested_at?,
                deletes_at: deletes_at?,
            })
        }))
    }

    /// Everything the server holds about one account, table by table.
    pub async fn export(&self, owner_id: Uuid) -> ApiResult<ExportedTables> {
        Ok(ExportedTables {
            account: json_rows!(
                &self.pool,
                owner_id,
                "SELECT id, email, full_name, created_at,
                        deletion_requested_at, delete_after
                 FROM owners WHERE id = $1"
            )
            .into_iter()
            .next()
            .unwrap_or(Value::Null),
            stores: json_rows!(
                &self.pool,
                owner_id,
                "SELECT * FROM stores WHERE owner_id = $1"
            ),
            staff: json_rows!(
                &self.pool,
                owner_id,
                "SELECT s.* FROM staff_members s
                 JOIN stores st ON st.id = s.store_id
                 WHERE st.owner_id = $1"
            ),
            devices: json_rows!(
                &self.pool,
                owner_id,
                "SELECT id, device_name, created_at, last_seen_at, revoked_at
                 FROM device_sessions WHERE owner_id = $1"
            ),
            products: json_rows!(
                &self.pool,
                owner_id,
                "SELECT p.* FROM products p
                 JOIN stores st ON st.id = p.store_id WHERE st.owner_id = $1"
            ),
            sales: json_rows!(
                &self.pool,
                owner_id,
                "SELECT s.*, (
                     SELECT json_agg(i) FROM sale_items i WHERE i.sale_id = s.id
                 ) AS items
                 FROM sales s
                 JOIN stores st ON st.id = s.store_id
                 WHERE st.owner_id = $1"
            ),
            expenses: json_rows!(
                &self.pool,
                owner_id,
                "SELECT e.* FROM expenses e
                 JOIN stores st ON st.id = e.store_id WHERE st.owner_id = $1"
            ),
            withdrawals: json_rows!(
                &self.pool,
                owner_id,
                "SELECT w.* FROM owner_withdrawals w
                 JOIN stores st ON st.id = w.store_id WHERE st.owner_id = $1"
            ),
            stock_movements: json_rows!(
                &self.pool,
                owner_id,
                "SELECT m.* FROM stock_movements m
                 JOIN stores st ON st.id = m.store_id WHERE st.owner_id = $1"
            ),
            activity: json_rows!(
                &self.pool,
                owner_id,
                "SELECT * FROM audit_events WHERE owner_id = $1"
            ),
            consents: json_rows!(
                &self.pool,
                owner_id,
                "SELECT document, version, agreed_at
                 FROM consent_records WHERE owner_id = $1"
            ),
            payments: json_rows!(
                &self.pool,
                owner_id,
                "SELECT id, plan, months, amount, currency, provider, status,
                        method, paid_through, created_at, paid_at
                 FROM payments WHERE owner_id = $1"
            ),
            error_reports: json_rows!(
                &self.pool,
                owner_id,
                "SELECT error_type, message, occurrences, first_seen, last_seen,
                        app_version, platform
                 FROM client_error_reports WHERE owner_id = $1"
            ),
        })
    }
}

pub struct ExportedTables {
    pub account: Value,
    pub stores: Vec<Value>,
    pub staff: Vec<Value>,
    pub devices: Vec<Value>,
    pub products: Vec<Value>,
    pub sales: Vec<Value>,
    pub expenses: Vec<Value>,
    pub withdrawals: Vec<Value>,
    pub stock_movements: Vec<Value>,
    pub activity: Vec<Value>,
    pub consents: Vec<Value>,
    pub payments: Vec<Value>,
    pub error_reports: Vec<Value>,
}
