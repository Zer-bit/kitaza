use chrono::{DateTime, Utc};
use rust_decimal::Decimal;
use sqlx::FromRow;
use uuid::Uuid;

use crate::infrastructure::database::PgPool;
use crate::shared::{ApiError, ApiResult, Money, PageRequest, Quantity};

use super::inventory_payloads::{InventoryValuation, MovementView};

#[derive(FromRow)]
struct ValuationRow {
    product_count: i64,
    low_stock_count: i64,
    stock_value_at_cost: Decimal,
    stock_value_at_selling: Decimal,
}

/// How a movement changes stock: by an amount, or to a counted total.
#[derive(Debug, Clone, Copy)]
pub enum StockEffect {
    Change(Quantity),
    SetTo(Quantity),
}

pub struct LedgerEntry<'a> {
    pub store_id: Uuid,
    pub movement_id: Uuid,
    pub product_id: Uuid,
    pub movement: &'a str,
    pub effect: StockEffect,
    pub unit_cost: Money,
    pub note: Option<&'a str>,
    pub occurred_at: DateTime<Utc>,
}

#[derive(Clone)]
pub struct StockRepository {
    pool: PgPool,
}

impl StockRepository {
    pub fn new(pool: PgPool) -> Self {
        Self { pool }
    }

    /// Writes one ledger row and moves the product's running total to match,
    /// in a single transaction.
    ///
    /// Idempotent on `movement_id`: a device that loses signal mid-sync will
    /// resend the same movement, and the second copy must change nothing. The
    /// product row is locked first so a counted adjustment and a concurrent
    /// sale cannot interleave.
    ///
    /// Returns `false` when the movement had already been recorded.
    pub async fn record_movement(&self, entry: LedgerEntry<'_>) -> ApiResult<bool> {
        let mut transaction = self.pool.begin().await?;

        let on_hand: Option<(Quantity,)> = sqlx::query_as(
            "SELECT stock_quantity FROM products
             WHERE id = $1 AND store_id = $2 AND deleted_at IS NULL
             FOR UPDATE",
        )
        .bind(entry.product_id)
        .bind(entry.store_id)
        .fetch_optional(&mut *transaction)
        .await?;

        let Some((on_hand,)) = on_hand else {
            return Err(ApiError::NotFound("product"));
        };

        let delta = match entry.effect {
            StockEffect::Change(delta) => delta,
            StockEffect::SetTo(counted) => counted - on_hand,
        };

        let inserted = sqlx::query(
            "INSERT INTO stock_movements
                 (id, store_id, product_id, movement, quantity, unit_cost, note, occurred_at)
             VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
             ON CONFLICT (id) DO NOTHING",
        )
        .bind(entry.movement_id)
        .bind(entry.store_id)
        .bind(entry.product_id)
        .bind(entry.movement)
        .bind(delta)
        .bind(entry.unit_cost)
        .bind(entry.note)
        .bind(entry.occurred_at)
        .execute(&mut *transaction)
        .await?
        .rows_affected();

        if inserted == 0 {
            transaction.rollback().await?;
            return Ok(false);
        }

        sqlx::query(
            "UPDATE products
             SET stock_quantity = stock_quantity + $1,
                 cost_price = CASE WHEN $2 > 0 THEN $2 ELSE cost_price END,
                 updated_at = now()
             WHERE id = $3 AND store_id = $4",
        )
        .bind(delta)
        .bind(entry.unit_cost)
        .bind(entry.product_id)
        .bind(entry.store_id)
        .execute(&mut *transaction)
        .await?;

        transaction.commit().await?;
        Ok(true)
    }

    pub async fn list_movements(
        &self,
        store_id: Uuid,
        product_id: Option<Uuid>,
        page: PageRequest,
    ) -> ApiResult<Vec<MovementView>> {
        let movements = sqlx::query_as::<_, MovementView>(
            "SELECT m.id, m.product_id, p.name AS product_name, m.movement,
                    m.quantity, m.unit_cost, m.note, m.occurred_at
             FROM stock_movements m
             JOIN products p ON p.id = m.product_id
             WHERE m.store_id = $1
               AND m.deleted_at IS NULL
               AND ($2::uuid IS NULL OR m.product_id = $2)
             ORDER BY m.occurred_at DESC
             LIMIT $3 OFFSET $4",
        )
        .bind(store_id)
        .bind(product_id)
        .bind(page.limit())
        .bind(page.offset())
        .fetch_all(&self.pool)
        .await?;

        Ok(movements)
    }

    pub async fn valuation(&self, store_id: Uuid) -> ApiResult<InventoryValuation> {
        let row = sqlx::query_as::<_, ValuationRow>(
            "SELECT COUNT(*) AS product_count,
                    COUNT(*) FILTER (
                        WHERE reorder_level > 0 AND stock_quantity <= reorder_level
                    ) AS low_stock_count,
                    COALESCE(SUM(stock_quantity * cost_price), 0)::numeric(14,2)
                        AS stock_value_at_cost,
                    COALESCE(SUM(stock_quantity * selling_price), 0)::numeric(14,2)
                        AS stock_value_at_selling
             FROM products
             WHERE store_id = $1 AND deleted_at IS NULL AND is_active",
        )
        .bind(store_id)
        .fetch_one(&self.pool)
        .await?;

        Ok(InventoryValuation {
            product_count: row.product_count,
            low_stock_count: row.low_stock_count,
            stock_value_at_cost: row.stock_value_at_cost,
            stock_value_at_selling: row.stock_value_at_selling,
        })
    }
}
