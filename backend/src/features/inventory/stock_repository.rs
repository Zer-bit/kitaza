use chrono::{DateTime, Utc};
use rust_decimal::Decimal;
use sqlx::FromRow;
use uuid::Uuid;

use crate::infrastructure::database::PgPool;
use crate::shared::{ApiResult, Money, PageRequest, Quantity};

use super::inventory_payloads::{InventoryValuation, MovementView};

#[derive(FromRow)]
struct ValuationRow {
    product_count: i64,
    low_stock_count: i64,
    stock_value_at_cost: Decimal,
    stock_value_at_selling: Decimal,
}

#[derive(Clone)]
pub struct StockRepository {
    pool: PgPool,
}

impl StockRepository {
    pub fn new(pool: PgPool) -> Self {
        Self { pool }
    }

    /// The ledger row and the product's running total are written together so
    /// the two can never disagree.
    #[allow(clippy::too_many_arguments)]
    pub async fn record_movement(
        &self,
        store_id: Uuid,
        movement_id: Uuid,
        product_id: Uuid,
        movement: &str,
        signed_quantity: Quantity,
        unit_cost: Money,
        note: Option<&str>,
        occurred_at: DateTime<Utc>,
    ) -> ApiResult<()> {
        let mut transaction = self.pool.begin().await?;

        sqlx::query(
            "INSERT INTO stock_movements
                 (id, store_id, product_id, movement, quantity, unit_cost, note, occurred_at)
             VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
             ON CONFLICT (id) DO NOTHING",
        )
        .bind(movement_id)
        .bind(store_id)
        .bind(product_id)
        .bind(movement)
        .bind(signed_quantity)
        .bind(unit_cost)
        .bind(note)
        .bind(occurred_at)
        .execute(&mut *transaction)
        .await?;

        sqlx::query(
            "UPDATE products
             SET stock_quantity = stock_quantity + $1,
                 cost_price = CASE WHEN $2 > 0 THEN $2 ELSE cost_price END,
                 updated_at = now()
             WHERE id = $3 AND store_id = $4",
        )
        .bind(signed_quantity)
        .bind(unit_cost)
        .bind(product_id)
        .bind(store_id)
        .execute(&mut *transaction)
        .await?;

        transaction.commit().await?;
        Ok(())
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
