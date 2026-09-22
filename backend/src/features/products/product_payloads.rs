use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use uuid::Uuid;
use validator::Validate;

use crate::shared::{Money, Quantity};

#[derive(Debug, Clone, Serialize, FromRow)]
pub struct ProductView {
    pub id: Uuid,
    pub name: String,
    pub barcode: Option<String>,
    pub unit_label: String,
    pub cost_price: Money,
    pub selling_price: Money,
    pub stock_quantity: Quantity,
    pub reorder_level: Quantity,
    pub is_active: bool,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Deserialize, Validate)]
pub struct SaveProductRequest {
    /// Supplied by the client so a product created offline keeps its identity
    /// once it syncs.
    #[serde(default)]
    pub id: Option<Uuid>,

    #[validate(length(min = 1, max = 120, message = "is required"))]
    pub name: String,

    #[serde(default)]
    pub barcode: Option<String>,

    #[serde(default = "default_unit")]
    pub unit_label: String,

    #[validate(range(min = 0.0, message = "cannot be negative"))]
    pub cost_price: f64,

    #[validate(range(min = 0.0, message = "cannot be negative"))]
    pub selling_price: f64,

    #[serde(default)]
    #[validate(range(min = 0.0, message = "cannot be negative"))]
    pub opening_stock: f64,

    #[serde(default)]
    #[validate(range(min = 0.0, message = "cannot be negative"))]
    pub reorder_level: f64,
}

#[derive(Debug, Deserialize, Default)]
pub struct ProductFilter {
    #[serde(default)]
    pub search: Option<String>,
    #[serde(default)]
    pub only_low_stock: Option<bool>,
    #[serde(default)]
    pub include_inactive: Option<bool>,
}

fn default_unit() -> String {
    "pc".to_owned()
}
