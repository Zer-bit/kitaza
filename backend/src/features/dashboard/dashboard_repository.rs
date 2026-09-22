use chrono::{DateTime, Utc};
use rust_decimal::Decimal;
use uuid::Uuid;

use crate::infrastructure::database::PgPool;
use crate::shared::{ApiResult, Money};

use super::dashboard_payloads::{BestSeller, SalesTotals};

#[derive(Clone)]
pub struct DashboardRepository {
    pool: PgPool,
}

impl DashboardRepository {
    pub fn new(pool: PgPool) -> Self {
        Self { pool }
    }

    pub async fn sales_totals(
        &self,
        store_id: Uuid,
        from: DateTime<Utc>,
        to: DateTime<Utc>,
    ) -> ApiResult<SalesTotals> {
        let totals = sqlx::query_as::<_, SalesTotals>(
            "SELECT COALESCE(SUM(total_amount), 0)::numeric(14,2)    AS sales_total,
                    COALESCE(SUM(cost_amount), 0)::numeric(14,2)     AS cost_total,
                    COALESCE(SUM(discount_amount), 0)::numeric(14,2) AS discount_total,
                    COUNT(*)                                         AS sale_count
             FROM sales
             WHERE store_id = $1 AND deleted_at IS NULL
               AND occurred_at >= $2 AND occurred_at < $3",
        )
        .bind(store_id)
        .bind(from)
        .bind(to)
        .fetch_one(&self.pool)
        .await?;

        Ok(totals)
    }

    pub async fn expenses_total(
        &self,
        store_id: Uuid,
        from: DateTime<Utc>,
        to: DateTime<Utc>,
    ) -> ApiResult<Money> {
        let total: (Decimal,) = sqlx::query_as(
            "SELECT COALESCE(SUM(amount), 0)::numeric(14,2)
             FROM expenses
             WHERE store_id = $1 AND deleted_at IS NULL
               AND occurred_at >= $2 AND occurred_at < $3",
        )
        .bind(store_id)
        .bind(from)
        .bind(to)
        .fetch_one(&self.pool)
        .await?;

        Ok(total.0)
    }

    pub async fn withdrawals_total(
        &self,
        store_id: Uuid,
        from: DateTime<Utc>,
        to: DateTime<Utc>,
    ) -> ApiResult<Money> {
        let total: (Decimal,) = sqlx::query_as(
            "SELECT COALESCE(SUM(amount), 0)::numeric(14,2)
             FROM owner_withdrawals
             WHERE store_id = $1 AND deleted_at IS NULL
               AND occurred_at >= $2 AND occurred_at < $3",
        )
        .bind(store_id)
        .bind(from)
        .bind(to)
        .fetch_one(&self.pool)
        .await?;

        Ok(total.0)
    }

    pub async fn best_seller(
        &self,
        store_id: Uuid,
        from: DateTime<Utc>,
        to: DateTime<Utc>,
    ) -> ApiResult<Option<BestSeller>> {
        let best = sqlx::query_as::<_, BestSeller>(
            "SELECT i.product_name,
                    SUM(i.quantity)::numeric(14,3)   AS quantity_sold,
                    SUM(i.line_total)::numeric(14,2) AS revenue
             FROM sale_items i
             JOIN sales s ON s.id = i.sale_id
             WHERE s.store_id = $1 AND s.deleted_at IS NULL
               AND s.occurred_at >= $2 AND s.occurred_at < $3
             GROUP BY i.product_name
             ORDER BY revenue DESC
             LIMIT 1",
        )
        .bind(store_id)
        .bind(from)
        .bind(to)
        .fetch_optional(&self.pool)
        .await?;

        Ok(best)
    }

    pub async fn low_stock_count(&self, store_id: Uuid) -> ApiResult<i64> {
        let count: (i64,) = sqlx::query_as(
            "SELECT COUNT(*) FROM products
             WHERE store_id = $1 AND deleted_at IS NULL AND is_active
               AND reorder_level > 0 AND stock_quantity <= reorder_level",
        )
        .bind(store_id)
        .fetch_one(&self.pool)
        .await?;

        Ok(count.0)
    }
}
