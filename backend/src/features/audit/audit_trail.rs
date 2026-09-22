use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use serde_json::Value;
use sqlx::FromRow;
use uuid::Uuid;

use crate::features::access::Actor;
use crate::infrastructure::database::PgPool;
use crate::shared::ApiResult;

use super::audit_action::AuditAction;

const MAX_PAGE: i64 = 100;

/// One thing that happened, about to be written to the log.
pub struct AuditEntry {
    pub store_id: Option<Uuid>,
    pub action: AuditAction,
    pub entity_id: Option<Uuid>,
    pub occurred_at: DateTime<Utc>,
    pub details: Value,
}

impl AuditEntry {
    pub fn new(store_id: Uuid, action: AuditAction, entity_id: Uuid, details: Value) -> Self {
        Self {
            store_id: Some(store_id),
            action,
            entity_id: Some(entity_id),
            occurred_at: Utc::now(),
            details,
        }
    }

    /// Something about the account rather than one store, such as signing
    /// out the owner's own phone. Shown in every store's log.
    pub fn account(
        store_id: Option<Uuid>,
        action: AuditAction,
        entity_id: Uuid,
        details: Value,
    ) -> Self {
        Self {
            store_id,
            ..Self::new(Uuid::nil(), action, entity_id, details)
        }
    }

    /// For an offline entry: when it happened on the phone, not when the
    /// server heard about it.
    pub fn at(mut self, occurred_at: DateTime<Utc>) -> Self {
        self.occurred_at = occurred_at;
        self
    }
}

#[derive(Debug, Serialize, FromRow)]
pub struct AuditEventView {
    #[serde(rename = "id")]
    pub seq: i64,
    pub action: String,
    pub actor_name: String,
    pub is_staff: bool,
    pub device_name: String,
    pub entity_id: Option<Uuid>,
    pub details: Value,
    pub occurred_at: DateTime<Utc>,
    pub recorded_at: DateTime<Utc>,
}

#[derive(Debug, Default, Clone, Copy, Deserialize, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
pub enum AuditFilter {
    #[default]
    All,
    Removals,
}

/// The append-only activity log.
///
/// Written after the change it describes, outside that change's transaction,
/// and never allowed to fail it: a sale that happened must stay recorded even
/// if its log line could not be written. The trade is that a crash in the
/// instant between the two loses a log line, which is logged loudly.
#[derive(Clone)]
pub struct AuditTrail {
    pool: PgPool,
}

impl AuditTrail {
    pub fn new(pool: PgPool) -> Self {
        Self { pool }
    }

    pub async fn record(&self, actor: &Actor, entry: AuditEntry) {
        let written = sqlx::query(
            "INSERT INTO audit_events
                 (owner_id, store_id, staff_id, actor_name, device_name, action,
                  entity_id, details, occurred_at)
             VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)",
        )
        .bind(actor.owner_id)
        .bind(entry.store_id)
        .bind(actor.staff_id())
        .bind(&actor.name)
        .bind(&actor.device_name)
        .bind(entry.action.as_str())
        .bind(entry.entity_id)
        .bind(&entry.details)
        .bind(entry.occurred_at)
        .execute(&self.pool)
        .await;

        if let Err(error) = written {
            tracing::error!(
                ?error,
                action = entry.action.as_str(),
                "could not write an activity log entry"
            );
        }
    }

    /// Newest first. `before` is the id of the last entry already shown.
    pub async fn page(
        &self,
        owner_id: Uuid,
        store_id: Uuid,
        filter: AuditFilter,
        before: Option<i64>,
        limit: i64,
    ) -> ApiResult<Vec<AuditEventView>> {
        let only: Option<Vec<&str>> = match filter {
            AuditFilter::All => None,
            AuditFilter::Removals => Some(
                AuditAction::REMOVALS
                    .iter()
                    .map(|action| action.as_str())
                    .collect(),
            ),
        };

        let events = sqlx::query_as::<_, AuditEventView>(
            "SELECT seq, action, actor_name, staff_id IS NOT NULL AS is_staff, device_name,
                    entity_id, details, occurred_at, recorded_at
             FROM audit_events
             WHERE owner_id = $1
               AND (store_id = $2 OR store_id IS NULL)
               AND ($3::bigint IS NULL OR seq < $3)
               AND ($4::text[] IS NULL OR action = ANY($4))
             ORDER BY seq DESC
             LIMIT $5",
        )
        .bind(owner_id)
        .bind(store_id)
        .bind(before)
        .bind(only)
        .bind(limit.clamp(1, MAX_PAGE))
        .fetch_all(&self.pool)
        .await?;

        Ok(events)
    }
}
