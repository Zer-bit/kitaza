use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;
use validator::Validate;

use crate::features::expenses::RecordExpenseRequest;
use crate::features::inventory::RecordMovementRequest;
use crate::features::products::SaveProductRequest;
use crate::features::sales::RecordSaleRequest;
use crate::features::withdrawals::RecordWithdrawalRequest;

/// Everything a device queued while it was offline. Rows are applied one by
/// one, so a single bad row never blocks the rest of the batch.
#[derive(Debug, Deserialize, Validate)]
pub struct PushRequest {
    #[serde(default)]
    #[validate(nested)]
    pub products: Vec<SaveProductRequest>,

    #[serde(default)]
    #[validate(nested)]
    pub stock_movements: Vec<RecordMovementRequest>,

    #[serde(default)]
    #[validate(nested)]
    pub sales: Vec<RecordSaleRequest>,

    #[serde(default)]
    #[validate(nested)]
    pub expenses: Vec<RecordExpenseRequest>,

    #[serde(default)]
    #[validate(nested)]
    pub withdrawals: Vec<RecordWithdrawalRequest>,

    /// Voids and removals made on the device.
    #[serde(default)]
    #[validate(nested)]
    pub deletions: Vec<DeletionRequest>,
}

#[derive(Debug, Deserialize, Validate)]
pub struct DeletionRequest {
    #[validate(length(min = 1, message = "is required"))]
    pub entity: String,
    pub id: Uuid,
}

/// The kind of row a push result refers to, so the device can tell a sale
/// from a deletion of that same sale.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize)]
#[serde(rename_all = "snake_case")]
pub enum PushedEntity {
    Product,
    StockMovement,
    Sale,
    Expense,
    Withdrawal,
    Deletion,
}

#[derive(Debug, Serialize)]
pub struct PushedRow {
    pub entity: PushedEntity,
    pub id: Uuid,
}

#[derive(Debug, Serialize)]
pub struct RejectedRow {
    pub entity: PushedEntity,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub id: Option<Uuid>,
    pub reason: String,
}

#[derive(Debug, Serialize)]
pub struct PushOutcome {
    pub applied: Vec<PushedRow>,
    pub rejected: Vec<RejectedRow>,
    pub server_time: DateTime<Utc>,
}

#[derive(Debug, Deserialize)]
pub struct PullQuery {
    /// The opaque cursor from the previous pull. Absent means a first, full
    /// download.
    #[serde(default)]
    pub cursor: Option<String>,
}

#[derive(Debug, Serialize)]
pub struct PullResponse {
    pub products: Vec<serde_json::Value>,
    pub sales: Vec<serde_json::Value>,
    /// Every line of every sale in `sales`, so a device can replace a sale's
    /// lines wholesale rather than merging them.
    pub sale_items: Vec<serde_json::Value>,
    pub expenses: Vec<serde_json::Value>,
    pub withdrawals: Vec<serde_json::Value>,
    pub stock_movements: Vec<serde_json::Value>,
    pub cursor: String,
    /// True when at least one table filled its page. Pull again with the new
    /// cursor until this is false.
    pub has_more: bool,
}
