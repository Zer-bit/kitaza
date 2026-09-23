use serde::Serialize;
use sqlx::FromRow;
use uuid::Uuid;

use crate::infrastructure::database::PgPool;
use crate::shared::ApiResult;

/// The last month of trading, the window every comparison is made over.
const WINDOW_DAYS: i32 = 30;

/// One store's month, as the comparison sees it.
#[derive(Debug, Clone, Copy, FromRow, Serialize)]
pub struct StoreMonth {
    pub sales_total: f64,
    pub cost_total: f64,
    pub expense_total: f64,
    pub sale_count: i64,
}

impl StoreMonth {
    pub fn margin_percent(&self) -> Option<f64> {
        (self.sales_total > 0.0)
            .then(|| (self.sales_total - self.cost_total) / self.sales_total * 100.0)
    }

    pub fn expense_percent(&self) -> Option<f64> {
        (self.sales_total > 0.0).then(|| self.expense_total / self.sales_total * 100.0)
    }

    pub fn daily_sales(&self) -> f64 {
        self.sales_total / f64::from(WINDOW_DAYS)
    }

    /// Enough trading to be worth comparing, in either direction.
    pub fn is_trading(&self) -> bool {
        self.sale_count >= 20 && self.sales_total > 0.0
    }
}

/// Stores are only ever compared with stores of the same kind and roughly
/// the same size: a carinderia and a sari-sari store keep different margins,
/// and so do a stall and a shop.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize)]
#[serde(rename_all = "snake_case")]
pub enum SizeBand {
    Small,
    Medium,
    Large,
}

impl SizeBand {
    pub fn of(monthly_sales: f64) -> Self {
        match monthly_sales {
            sales if sales < 30_000.0 => SizeBand::Small,
            sales if sales < 150_000.0 => SizeBand::Medium,
            _ => SizeBand::Large,
        }
    }

    pub fn bounds(self) -> (f64, f64) {
        match self {
            SizeBand::Small => (0.0, 30_000.0),
            SizeBand::Medium => (30_000.0, 150_000.0),
            SizeBand::Large => (150_000.0, f64::INFINITY),
        }
    }

    pub fn as_str(self) -> &'static str {
        match self {
            SizeBand::Small => "small",
            SizeBand::Medium => "medium",
            SizeBand::Large => "large",
        }
    }
}

/// The middle of the pack, and how many stores are in it.
#[derive(Debug, Clone, Copy, FromRow)]
pub struct PeerMedians {
    pub sample_size: i64,
    pub margin_percent: Option<f64>,
    pub expense_percent: Option<f64>,
    pub daily_sales: Option<f64>,
}

#[derive(Clone)]
pub struct BenchmarkRepository {
    pool: PgPool,
}

impl BenchmarkRepository {
    pub fn new(pool: PgPool) -> Self {
        Self { pool }
    }

    pub async fn store_month(&self, store_id: Uuid) -> ApiResult<StoreMonth> {
        let month = sqlx::query_as::<_, StoreMonth>(
            "SELECT
                 COALESCE((SELECT SUM(total_amount) FROM sales
                           WHERE store_id = $1 AND deleted_at IS NULL
                             AND occurred_at >= now() - make_interval(days => $2)), 0)::float8
                     AS sales_total,
                 COALESCE((SELECT SUM(cost_amount) FROM sales
                           WHERE store_id = $1 AND deleted_at IS NULL
                             AND occurred_at >= now() - make_interval(days => $2)), 0)::float8
                     AS cost_total,
                 COALESCE((SELECT SUM(amount) FROM expenses
                           WHERE store_id = $1 AND deleted_at IS NULL
                             AND occurred_at >= now() - make_interval(days => $2)), 0)::float8
                     AS expense_total,
                 COALESCE((SELECT COUNT(*) FROM sales
                           WHERE store_id = $1 AND deleted_at IS NULL
                             AND occurred_at >= now() - make_interval(days => $2)), 0)
                     AS sale_count",
        )
        .bind(store_id)
        .bind(WINDOW_DAYS)
        .fetch_one(&self.pool)
        .await?;

        Ok(month)
    }

    /// The medians of every other store of this kind and size that shares
    /// its figures. The asking store is left out, so an owner is compared
    /// with others rather than partly with themselves.
    pub async fn peer_medians(
        &self,
        store_id: Uuid,
        business_type: &str,
        band: SizeBand,
    ) -> ApiResult<PeerMedians> {
        let (lower, upper) = band.bounds();
        let medians = sqlx::query_as::<_, PeerMedians>(
            "WITH peers AS (
                 SELECT s.id,
                        COALESCE(sales.total, 0)::float8   AS sales_total,
                        COALESCE(sales.cost, 0)::float8    AS cost_total,
                        COALESCE(spend.total, 0)::float8   AS expense_total,
                        COALESCE(sales.entries, 0)         AS sale_count
                 FROM stores s
                 LEFT JOIN LATERAL (
                     SELECT SUM(total_amount) AS total, SUM(cost_amount) AS cost,
                            COUNT(*) AS entries
                     FROM sales
                     WHERE store_id = s.id AND deleted_at IS NULL
                       AND occurred_at >= now() - make_interval(days => $3)
                 ) sales ON TRUE
                 LEFT JOIN LATERAL (
                     SELECT SUM(amount) AS total FROM expenses
                     WHERE store_id = s.id AND deleted_at IS NULL
                       AND occurred_at >= now() - make_interval(days => $3)
                 ) spend ON TRUE
                 WHERE s.share_benchmarks
                   AND s.id <> $1
                   AND s.business_type = $2
             ),
             trading AS (
                 SELECT * FROM peers
                 WHERE sale_count >= 20 AND sales_total > 0
                   AND sales_total >= $4 AND ($5 = 0 OR sales_total < $5)
             )
             SELECT count(*) AS sample_size,
                    percentile_cont(0.5) WITHIN GROUP (
                        ORDER BY (sales_total - cost_total) / sales_total * 100) AS margin_percent,
                    percentile_cont(0.5) WITHIN GROUP (
                        ORDER BY expense_total / sales_total * 100) AS expense_percent,
                    percentile_cont(0.5) WITHIN GROUP (
                        ORDER BY sales_total / $3::float8) AS daily_sales
             FROM trading",
        )
        .bind(store_id)
        .bind(business_type)
        .bind(WINDOW_DAYS)
        .bind(lower)
        .bind(if upper.is_finite() { upper } else { 0.0 })
        .fetch_one(&self.pool)
        .await?;

        Ok(medians)
    }

    pub async fn business_type_of(&self, store_id: Uuid) -> ApiResult<String> {
        let (business_type,): (String,) =
            sqlx::query_as("SELECT business_type FROM stores WHERE id = $1")
                .bind(store_id)
                .fetch_one(&self.pool)
                .await?;

        Ok(business_type)
    }
}
