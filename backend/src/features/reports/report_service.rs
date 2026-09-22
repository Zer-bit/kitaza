use chrono::{Duration, Utc};
use uuid::Uuid;

use crate::features::dashboard::DashboardRepository;
use crate::shared::{ApiResult, DateRange};

use super::insight_engine::detect_unusual_expenses;
use super::report_payloads::{
    ExpenseSlice, ProductPerformance, ProfitTrend, ReportQuery, TrendPoint, TrendQuery,
    UnusualExpense, WeeklySummary,
};
use super::report_repository::ReportRepository;

const TOP_PRODUCT_LIMIT: i64 = 5;
const MAX_TREND_DAYS: i64 = 90;
const INSIGHT_LOOKBACK_DAYS: i64 = 60;

#[derive(Clone)]
pub struct ReportService {
    reports: ReportRepository,
    dashboard: DashboardRepository,
}

impl ReportService {
    pub fn new(reports: ReportRepository, dashboard: DashboardRepository) -> Self {
        Self { reports, dashboard }
    }

    pub async fn profit_trend(&self, store_id: Uuid, query: TrendQuery) -> ApiResult<ProfitTrend> {
        let days = query.days.clamp(1, MAX_TREND_DAYS);
        let end = Utc::now();
        let start = end - Duration::days(days);

        let points = self
            .reports
            .daily_series(store_id, start, end, query.utc_offset_minutes)
            .await?
            .into_iter()
            .map(|point| TrendPoint {
                day: point.day,
                sales_total: point.sales_total,
                expenses_total: point.expenses_total,
                net_profit: point.net_profit(),
            })
            .collect();

        Ok(ProfitTrend { points })
    }

    pub async fn top_products(
        &self,
        store_id: Uuid,
        query: ReportQuery,
    ) -> ApiResult<Vec<ProductPerformance>> {
        let range = self.resolve(&query);
        self.reports
            .product_performance(store_id, range.start, range.end, TOP_PRODUCT_LIMIT)
            .await
    }

    pub async fn expense_breakdown(
        &self,
        store_id: Uuid,
        query: ReportQuery,
    ) -> ApiResult<Vec<ExpenseSlice>> {
        let range = self.resolve(&query);
        self.reports
            .expense_breakdown(store_id, range.start, range.end)
            .await
    }

    pub async fn unusual_expenses(&self, store_id: Uuid) -> ApiResult<Vec<UnusualExpense>> {
        let since = Utc::now() - Duration::days(INSIGHT_LOOKBACK_DAYS);
        let samples = self.reports.recent_expenses(store_id, since).await?;

        Ok(detect_unusual_expenses(&samples))
    }

    /// The single call the "weekly summary" screen makes, so the client shows
    /// one loading state instead of five.
    pub async fn periodic_summary(
        &self,
        store_id: Uuid,
        query: ReportQuery,
    ) -> ApiResult<WeeklySummary> {
        let range = self.resolve(&query);
        let since = Utc::now() - Duration::days(INSIGHT_LOOKBACK_DAYS);

        let (sales, expenses_total, withdrawals_total, top_products, expense_breakdown, samples) =
            tokio::try_join!(
                self.dashboard
                    .sales_totals(store_id, range.start, range.end),
                self.dashboard
                    .expenses_total(store_id, range.start, range.end),
                self.dashboard
                    .withdrawals_total(store_id, range.start, range.end),
                self.reports.product_performance(
                    store_id,
                    range.start,
                    range.end,
                    TOP_PRODUCT_LIMIT
                ),
                self.reports
                    .expense_breakdown(store_id, range.start, range.end),
                self.reports.recent_expenses(store_id, since),
            )?;

        Ok(WeeklySummary {
            period: query.period,
            sales_total: sales.sales_total,
            expenses_total,
            net_profit: sales.sales_total - sales.cost_total - expenses_total,
            withdrawals_total,
            top_products,
            expense_breakdown,
            unusual_expenses: detect_unusual_expenses(&samples),
        })
    }

    fn resolve(&self, query: &ReportQuery) -> DateRange {
        DateRange::for_period(query.period, query.utc_offset_minutes, Utc::now())
    }
}
