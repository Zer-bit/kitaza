use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use uuid::Uuid;
use validator::Validate;

use crate::shared::Money;

#[derive(Debug, Deserialize, Validate)]
pub struct RecordWithdrawalRequest {
    #[serde(default)]
    pub id: Option<Uuid>,

    #[validate(range(exclusive_min = 0.0, message = "must be greater than zero"))]
    pub amount: f64,

    #[serde(default)]
    pub reason: Option<String>,

    #[serde(default)]
    pub occurred_at: Option<DateTime<Utc>>,
}

#[derive(Debug, Clone, Serialize, FromRow)]
pub struct WithdrawalView {
    pub id: Uuid,
    pub amount: Money,
    pub reason: Option<String>,
    pub occurred_at: DateTime<Utc>,
}
