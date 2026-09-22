use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;
use validator::Validate;

use crate::features::expenses::RecordExpenseRequest;
use crate::features::products::SaveProductRequest;
use crate::features::sales::RecordSaleRequest;
use crate::features::withdrawals::RecordWithdrawalRequest;

/// Everything a device queued while it was offline. Each list is independent,
/// so a single bad row never blocks the rest of the batch.
#[derive(Debug, Deserialize, Validate)]
pub struct PushRequest {
    #[serde(default)]
    #[validate(nested)]
    pub products: Vec<SaveProductRequest>,

    #[serde(default)]
    #[validate(nested)]
    pub sales: Vec<RecordSaleRequest>,

    #[serde(default)]
    #[validate(nested)]
    pub expenses: Vec<RecordExpenseRequest>,

    #[serde(default)]
    #[validate(nested)]
    pub withdrawals: Vec<RecordWithdrawalRequest>,
}

#[derive(Debug, Serialize)]
pub struct PushOutcome {
    pub applied: Vec<Uuid>,
    pub rejected: Vec<RejectedRow>,
    pub server_time: DateTime<Utc>,
}

#[derive(Debug, Serialize)]
pub struct RejectedRow {
    pub entity: &'static str,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub id: Option<Uuid>,
    pub reason: String,
}

#[derive(Debug, Deserialize)]
pub struct PullQuery {
    /// Everything changed strictly after this instant. Absent means a first
    /// full download.
    #[serde(default)]
    pub since: Option<DateTime<Utc>>,
}

#[derive(Debug, Serialize)]
pub struct PullResponse {
    pub products: Vec<serde_json::Value>,
    pub sales: Vec<serde_json::Value>,
    pub sale_items: Vec<serde_json::Value>,
    pub expenses: Vec<serde_json::Value>,
    pub withdrawals: Vec<serde_json::Value>,
    pub stock_movements: Vec<serde_json::Value>,
    /// Pass this back as `since` on the next pull.
    pub cursor: DateTime<Utc>,
}
