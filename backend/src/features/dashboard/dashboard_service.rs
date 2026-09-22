use chrono::Utc;
use uuid::Uuid;

use crate::infrastructure::cache::DashboardCache;
use crate::shared::{ApiResult, DateRange, ReportPeriod};

use super::business_score::{HealthInputs, evaluate};
use super::dashboard_payloads::{DashboardQuery, DashboardSummary};
use super::dashboard_repository::DashboardRepository;

#[derive(Clone)]
pub struct DashboardService {
    repository: DashboardRepository,
    cache: DashboardCache,
}

impl DashboardService {
    pub fn new(repository: DashboardRepository, cache: DashboardCache) -> Self {
        Self { repository, cache }
    }

    pub async fn summary(
        &self,
        store_id: Uuid,
        query: DashboardQuery,
    ) -> ApiResult<DashboardSummary> {
        let cache_key = format!(
            "summary:{}:{}",
            query.period.as_cache_key(),
            query.utc_offset_minutes
        );

        if let Some(cached) = self
            .cache
            .read::<DashboardSummary>(store_id, &cache_key)
            .await
        {
            return Ok(cached);
        }

        let range = DateRange::for_period(query.period, query.utc_offset_minutes, Utc::now());
        let summary = self.compute(store_id, query.period, range).await?;

        self.cache.write(store_id, &cache_key, &summary).await;
        Ok(summary)
    }

    async fn compute(
        &self,
        store_id: Uuid,
        period: ReportPeriod,
        range: DateRange,
    ) -> ApiResult<DashboardSummary> {
        let previous = range.previous_window();

        // Independent aggregates, so they run concurrently on the pool rather
        // than serially adding up latency on the dashboard's critical path.
        let (
            sales,
            expenses_total,
            withdrawals_total,
            best_seller,
            low_stock_count,
            previous_sales,
            previous_expenses,
        ) = tokio::try_join!(
            self.repository
                .sales_totals(store_id, range.start, range.end),
            self.repository
                .expenses_total(store_id, range.start, range.end),
            self.repository
                .withdrawals_total(store_id, range.start, range.end),
            self.repository
                .best_seller(store_id, range.start, range.end),
            self.repository.low_stock_count(store_id),
            self.repository
                .sales_totals(store_id, previous.start, previous.end),
            self.repository
                .expenses_total(store_id, previous.start, previous.end),
        )?;

        let gross_profit = sales.sales_total - sales.cost_total;
        let net_profit = gross_profit - expenses_total;
        let previous_net_profit =
            (previous_sales.sales_total - previous_sales.cost_total) - previous_expenses;

        let health = evaluate(&HealthInputs {
            sales_total: sales.sales_total,
            net_profit,
            previous_net_profit,
            withdrawals_total,
            low_stock_count,
        });

        Ok(DashboardSummary {
            period,
            range_start: range.start,
            range_end: range.end,
            sales_total: sales.sales_total,
            sale_count: sales.sale_count,
            cost_of_goods: sales.cost_total,
            gross_profit,
            expenses_total,
            net_profit,
            withdrawals_total,
            // What actually stayed in the cash box after the owner took their
            // share, which is the number most owners check first.
            cash_movement: net_profit - withdrawals_total,
            previous_net_profit,
            low_stock_count,
            best_seller,
            health,
        })
    }
}
