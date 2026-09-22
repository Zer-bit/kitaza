use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;

use crate::shared::{Money, Quantity, ReportPeriod};

use super::business_score::BusinessHealth;

#[derive(Debug, Deserialize)]
pub struct DashboardQuery {
    #[serde(default)]
    pub period: ReportPeriod,

    /// Minutes east of UTC on the device, so "today" means the owner's today.
    #[serde(default)]
    pub utc_offset_minutes: i32,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct SalesTotals {
    pub sales_total: Money,
    pub cost_total: Money,
    pub discount_total: Money,
    pub sale_count: i64,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct BestSeller {
    pub product_name: String,
    pub quantity_sold: Quantity,
    pub revenue: Money,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DashboardSummary {
    pub period: ReportPeriod,
    pub range_start: DateTime<Utc>,
    pub range_end: DateTime<Utc>,

    pub sales_total: Money,
    pub sale_count: i64,
    pub cost_of_goods: Money,
    pub gross_profit: Money,

    pub expenses_total: Money,
    pub net_profit: Money,
    pub withdrawals_total: Money,
    pub cash_movement: Money,

    pub previous_net_profit: Money,
    pub low_stock_count: i64,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub best_seller: Option<BestSeller>,

    pub health: BusinessHealth,
}
