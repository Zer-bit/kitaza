use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use uuid::Uuid;
use validator::Validate;

use crate::shared::{Money, Quantity};

#[derive(Debug, Clone, Deserialize, Validate)]
pub struct RecordMovementRequest {
    #[serde(default)]
    pub id: Option<Uuid>,

    pub product_id: Uuid,

    /// `stock_in`, `stock_out`, `adjustment` or `spoilage`. Sale deductions are
    /// written by the sales flow and cannot be posted here.
    #[validate(length(min = 1, message = "is required"))]
    pub movement: String,

    /// An amount for in/out movements, or the counted total for an
    /// adjustment, which may be zero.
    #[validate(range(min = 0.0, message = "cannot be negative"))]
    pub quantity: f64,

    #[serde(default)]
    #[validate(range(min = 0.0, message = "cannot be negative"))]
    pub unit_cost: f64,

    #[serde(default)]
    pub note: Option<String>,

    #[serde(default)]
    pub occurred_at: Option<DateTime<Utc>>,
}

#[derive(Debug, Clone, Serialize, FromRow)]
pub struct MovementView {
    pub id: Uuid,
    pub product_id: Uuid,
    pub product_name: String,
    pub movement: String,
    pub quantity: Quantity,
    pub unit_cost: Money,
    pub note: Option<String>,
    pub occurred_at: DateTime<Utc>,
}

#[derive(Debug, Serialize)]
pub struct InventoryValuation {
    pub product_count: i64,
    pub low_stock_count: i64,
    pub stock_value_at_cost: Money,
    pub stock_value_at_selling: Money,
}
