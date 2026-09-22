use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use uuid::Uuid;
use validator::Validate;

use crate::shared::{Money, Quantity};

#[derive(Debug, Deserialize, Validate)]
pub struct RecordSaleRequest {
    #[serde(default)]
    pub id: Option<Uuid>,

    #[serde(default)]
    pub payment_method: Option<String>,

    #[serde(default)]
    #[validate(range(min = 0.0, message = "cannot be negative"))]
    pub discount_amount: f64,

    #[serde(default)]
    pub note: Option<String>,

    /// Absent means "right now". Offline clients send the original timestamp so
    /// a sale lands on the day it actually happened.
    #[serde(default)]
    pub occurred_at: Option<DateTime<Utc>>,

    #[validate(length(min = 1, message = "must contain at least one line"))]
    #[validate(nested)]
    pub items: Vec<SaleLineRequest>,
}

// `Serialize` is required by validator to report the failing line back.
#[derive(Debug, Serialize, Deserialize, Validate)]
pub struct SaleLineRequest {
    /// Omitted for a quick sale that is not tied to a tracked product.
    #[serde(default)]
    pub product_id: Option<Uuid>,

    #[serde(default)]
    pub product_name: Option<String>,

    #[validate(range(exclusive_min = 0.0, message = "must be greater than zero"))]
    pub quantity: f64,

    /// Falls back to the product's selling price when omitted.
    #[serde(default)]
    pub unit_price: Option<f64>,

    #[serde(default)]
    pub unit_cost: Option<f64>,
}

#[derive(Debug, Clone, Serialize, FromRow)]
pub struct SaleView {
    pub id: Uuid,
    pub reference: Option<String>,
    pub payment_method: String,
    pub total_amount: Money,
    pub cost_amount: Money,
    pub discount_amount: Money,
    pub note: Option<String>,
    pub occurred_at: DateTime<Utc>,
}

impl SaleView {
    pub fn profit_amount(&self) -> Money {
        self.total_amount - self.cost_amount
    }
}

#[derive(Debug, Clone, Serialize, FromRow)]
pub struct SaleLineView {
    pub id: Uuid,
    pub sale_id: Uuid,
    pub product_id: Option<Uuid>,
    pub product_name: String,
    pub quantity: Quantity,
    pub unit_price: Money,
    pub unit_cost: Money,
    pub line_total: Money,
}

#[derive(Debug, Serialize)]
pub struct SaleDetail {
    #[serde(flatten)]
    pub sale: SaleView,
    pub profit_amount: Money,
    pub items: Vec<SaleLineView>,
}

impl SaleDetail {
    pub fn new(sale: SaleView, items: Vec<SaleLineView>) -> Self {
        Self {
            profit_amount: sale.profit_amount(),
            sale,
            items,
        }
    }
}

#[derive(Debug, Deserialize, Default)]
pub struct SaleFilter {
    #[serde(default)]
    pub from: Option<DateTime<Utc>>,
    #[serde(default)]
    pub to: Option<DateTime<Utc>>,
    #[serde(default)]
    pub payment_method: Option<String>,
}
