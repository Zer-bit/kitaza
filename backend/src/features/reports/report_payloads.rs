use chrono::{DateTime, NaiveDate, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;

use crate::shared::{Money, Quantity, ReportPeriod};

#[derive(Debug, Deserialize)]
pub struct ReportQuery {
    #[serde(default)]
    pub period: ReportPeriod,
    #[serde(default)]
    pub utc_offset_minutes: i32,
}

#[derive(Debug, Deserialize)]
pub struct TrendQuery {
    #[serde(default = "default_trend_days")]
    pub days: i64,
    #[serde(default)]
    pub utc_offset_minutes: i32,
}

fn default_trend_days() -> i64 {
    14
}

#[derive(Debug, Clone, Serialize, FromRow)]
pub struct DailyPoint {
    pub day: NaiveDate,
    pub sales_total: Money,
    pub cost_total: Money,
    pub expenses_total: Money,
}

impl DailyPoint {
    pub fn net_profit(&self) -> Money {
        self.sales_total - self.cost_total - self.expenses_total
    }
}

#[derive(Debug, Clone, Serialize)]
pub struct ProfitTrend {
    pub points: Vec<TrendPoint>,
}

#[derive(Debug, Clone, Serialize)]
pub struct TrendPoint {
    pub day: NaiveDate,
    pub sales_total: Money,
    pub expenses_total: Money,
    pub net_profit: Money,
}

#[derive(Debug, Clone, Serialize, FromRow)]
pub struct ProductPerformance {
    pub product_name: String,
    pub quantity_sold: Quantity,
    pub revenue: Money,
    pub profit: Money,
}

#[derive(Debug, Clone, Serialize, FromRow)]
pub struct ExpenseSlice {
    pub category: String,
    pub total_amount: Money,
    pub entry_count: i64,
}

#[derive(Debug, Clone, Serialize, FromRow)]
pub struct ExpenseSample {
    pub id: uuid::Uuid,
    pub category: String,
    pub description: Option<String>,
    pub amount: Money,
    pub occurred_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize)]
pub struct UnusualExpense {
    #[serde(flatten)]
    pub expense: ExpenseSample,
    pub category_average: Money,
    pub times_above_average: f64,
    pub explanation: String,
}

#[derive(Debug, Clone, Serialize)]
pub struct WeeklySummary {
    pub period: ReportPeriod,
    pub sales_total: Money,
    pub expenses_total: Money,
    pub net_profit: Money,
    pub withdrawals_total: Money,
    pub top_products: Vec<ProductPerformance>,
    pub expense_breakdown: Vec<ExpenseSlice>,
    pub unusual_expenses: Vec<UnusualExpense>,
}
