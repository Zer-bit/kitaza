use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use uuid::Uuid;
use validator::Validate;

use crate::shared::Money;

#[derive(Debug, Deserialize, Validate)]
pub struct RecordExpenseRequest {
    #[serde(default)]
    pub id: Option<Uuid>,

    #[validate(length(min = 1, message = "is required"))]
    pub category: String,

    #[serde(default)]
    pub description: Option<String>,

    #[validate(range(exclusive_min = 0.0, message = "must be greater than zero"))]
    pub amount: f64,

    #[serde(default)]
    pub occurred_at: Option<DateTime<Utc>>,
}

#[derive(Debug, Clone, Serialize, FromRow)]
pub struct ExpenseView {
    pub id: Uuid,
    pub category: String,
    pub description: Option<String>,
    pub amount: Money,
    pub occurred_at: DateTime<Utc>,
}

#[derive(Debug, Deserialize, Default)]
pub struct ExpenseFilter {
    #[serde(default)]
    pub from: Option<DateTime<Utc>>,
    #[serde(default)]
    pub to: Option<DateTime<Utc>>,
    #[serde(default)]
    pub category: Option<String>,
}
