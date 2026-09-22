use chrono::{DateTime, Utc};
use uuid::Uuid;

use crate::infrastructure::database::PgPool;
use crate::shared::ApiResult;

use super::report_payloads::{DailyPoint, ExpenseSample, ExpenseSlice, ProductPerformance};

#[derive(Clone)]
pub struct ReportRepository {
    pool: PgPool,
}

impl ReportRepository {
    pub fn new(pool: PgPool) -> Self {
        Self { pool }
    }

    /// One row per local calendar day. The offset is applied inside the query
    /// so days are bucketed by the store's clock, not the server's.
    pub async fn daily_series(
        &self,
        store_id: Uuid,
        from: DateTime<Utc>,
        to: DateTime<Utc>,
        utc_offset_minutes: i32,
    ) -> ApiResult<Vec<DailyPoint>> {
        let offset = format!("{utc_offset_minutes} minutes");

        let points = sqlx::query_as::<_, DailyPoint>(
            "WITH sale_days AS (
                 SELECT (occurred_at + $4::interval)::date AS day,
                        SUM(total_amount) AS sales_total,
                        SUM(cost_amount)  AS cost_total
                 FROM sales
                 WHERE store_id = $1 AND deleted_at IS NULL
                   AND occurred_at >= $2 AND occurred_at < $3
                 GROUP BY 1
             ),
             expense_days AS (
                 SELECT (occurred_at + $4::interval)::date AS day,
                        SUM(amount) AS expenses_total
                 FROM expenses
                 WHERE store_id = $1 AND deleted_at IS NULL
                   AND occurred_at >= $2 AND occurred_at < $3
                 GROUP BY 1
             )
             SELECT COALESCE(s.day, e.day)                            AS day,
                    COALESCE(s.sales_total, 0)::numeric(14,2)         AS sales_total,
                    COALESCE(s.cost_total, 0)::numeric(14,2)          AS cost_total,
                    COALESCE(e.expenses_total, 0)::numeric(14,2)      AS expenses_total
             FROM sale_days s
             FULL OUTER JOIN expense_days e ON e.day = s.day
             ORDER BY day",
        )
        .bind(store_id)
        .bind(from)
        .bind(to)
        .bind(offset)
        .fetch_all(&self.pool)
        .await?;

        Ok(points)
    }

    pub async fn product_performance(
        &self,
        store_id: Uuid,
        from: DateTime<Utc>,
        to: DateTime<Utc>,
        limit: i64,
    ) -> ApiResult<Vec<ProductPerformance>> {
        let rows = sqlx::query_as::<_, ProductPerformance>(
            "SELECT i.product_name,
                    SUM(i.quantity)::numeric(14,3)                            AS quantity_sold,
                    SUM(i.line_total)::numeric(14,2)                          AS revenue,
                    SUM(i.line_total - (i.unit_cost * i.quantity))::numeric(14,2) AS profit
             FROM sale_items i
             JOIN sales s ON s.id = i.sale_id
             WHERE s.store_id = $1 AND s.deleted_at IS NULL
               AND s.occurred_at >= $2 AND s.occurred_at < $3
             GROUP BY i.product_name
             ORDER BY profit DESC
             LIMIT $4",
        )
        .bind(store_id)
        .bind(from)
        .bind(to)
        .bind(limit)
        .fetch_all(&self.pool)
        .await?;

        Ok(rows)
    }

    pub async fn expense_breakdown(
        &self,
        store_id: Uuid,
        from: DateTime<Utc>,
        to: DateTime<Utc>,
    ) -> ApiResult<Vec<ExpenseSlice>> {
        let rows = sqlx::query_as::<_, ExpenseSlice>(
            "SELECT category,
                    SUM(amount)::numeric(14,2) AS total_amount,
                    COUNT(*)                   AS entry_count
             FROM expenses
             WHERE store_id = $1 AND deleted_at IS NULL
               AND occurred_at >= $2 AND occurred_at < $3
             GROUP BY category
             ORDER BY total_amount DESC",
        )
        .bind(store_id)
        .bind(from)
        .bind(to)
        .fetch_all(&self.pool)
        .await?;

        Ok(rows)
    }

    /// Recent history the insight engine scores for outliers.
    pub async fn recent_expenses(
        &self,
        store_id: Uuid,
        since: DateTime<Utc>,
    ) -> ApiResult<Vec<ExpenseSample>> {
        let rows = sqlx::query_as::<_, ExpenseSample>(
            "SELECT id, category, description, amount, occurred_at
             FROM expenses
             WHERE store_id = $1 AND deleted_at IS NULL AND occurred_at >= $2
             ORDER BY occurred_at DESC
             LIMIT 500",
        )
        .bind(store_id)
        .bind(since)
        .fetch_all(&self.pool)
        .await?;

        Ok(rows)
    }
}
