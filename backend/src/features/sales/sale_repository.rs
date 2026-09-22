use chrono::{DateTime, Utc};
use uuid::Uuid;

use crate::features::products::foreign_id;
use crate::infrastructure::database::PgPool;
use crate::shared::{ApiError, ApiResult, Money, PageRequest, Quantity};

use super::sale_payloads::{SaleFilter, SaleLineView, SaleView};

/// A sale line after the service has resolved prices and costs.
#[derive(Debug, Clone)]
pub struct PreparedLine {
    pub id: Uuid,
    pub product_id: Option<Uuid>,
    pub product_name: String,
    pub quantity: Quantity,
    pub unit_price: Money,
    pub unit_cost: Money,
    pub line_total: Money,
}

#[derive(Debug, Clone)]
pub struct PreparedSale {
    pub id: Uuid,
    pub store_id: Uuid,
    pub payment_method: String,
    pub total_amount: Money,
    pub cost_amount: Money,
    pub discount_amount: Money,
    pub note: Option<String>,
    pub occurred_at: DateTime<Utc>,
    pub lines: Vec<PreparedLine>,
}

/// Who is recording, as far as the sales table cares.
#[derive(Debug, Clone, Copy)]
pub struct Recorder {
    pub staff_id: Option<Uuid>,
    pub is_owner: bool,
}

pub struct RecordedSale {
    pub sale: SaleView,
    /// False for a replay of a sale the server already had.
    pub created: bool,
}

#[derive(sqlx::FromRow)]
struct ExistingSale {
    store_id: Uuid,
    recorded_by_staff_id: Option<Uuid>,
    voided: bool,
}

#[derive(Clone)]
pub struct SaleRepository {
    pool: PgPool,
}

impl SaleRepository {
    pub fn new(pool: PgPool) -> Self {
        Self { pool }
    }

    /// Writes the sale, its lines, the stock deduction and the stock ledger in
    /// a single transaction. A half-recorded sale would silently corrupt both
    /// profit and inventory, so this is all-or-nothing.
    pub async fn record(&self, sale: PreparedSale, by: Recorder) -> ApiResult<RecordedSale> {
        let mut transaction = self.pool.begin().await?;

        let existing: Option<ExistingSale> = sqlx::query_as(
            "SELECT store_id, recorded_by_staff_id, deleted_at IS NOT NULL AS voided
             FROM sales WHERE id = $1 FOR UPDATE",
        )
        .bind(sale.id)
        .fetch_optional(&mut *transaction)
        .await?;

        if let Some(existing) = &existing {
            if existing.store_id != sale.store_id {
                return Err(foreign_id());
            }
            // A voided sale is final. Replaying it - a phone retrying an old
            // push after the owner voided it elsewhere - must not bring it
            // back, and must not hand its stock back a second time.
            if existing.voided {
                let stored = find_any(&mut transaction, sale.id).await?;
                transaction.commit().await?;
                return Ok(RecordedSale {
                    sale: stored,
                    created: false,
                });
            }
            if !by.is_owner && existing.recorded_by_staff_id != by.staff_id {
                return Err(ApiError::Forbidden(
                    "only the owner can change a sale someone else recorded".into(),
                ));
            }

            // Re-pushing a sale from an offline device must not deduct stock
            // twice, so any previous effect of this sale id is reversed first
            // and then reapplied from the lines we are about to write.
            restore_stock_for(&mut transaction, sale.id, sale.store_id).await?;
            retire_movements_for(&mut transaction, sale.id, sale.store_id).await?;
        }

        let stored = sqlx::query_as::<_, SaleView>(
            "INSERT INTO sales
                 (id, store_id, payment_method, total_amount, cost_amount,
                  discount_amount, note, occurred_at, recorded_by_staff_id)
             VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
             ON CONFLICT (id) DO UPDATE SET
                 payment_method  = EXCLUDED.payment_method,
                 total_amount    = EXCLUDED.total_amount,
                 cost_amount     = EXCLUDED.cost_amount,
                 discount_amount = EXCLUDED.discount_amount,
                 note            = EXCLUDED.note,
                 occurred_at     = EXCLUDED.occurred_at,
                 updated_at      = now()
             RETURNING id, reference, payment_method, total_amount, cost_amount,
                    discount_amount, note, occurred_at",
        )
        .bind(sale.id)
        .bind(sale.store_id)
        .bind(&sale.payment_method)
        .bind(sale.total_amount)
        .bind(sale.cost_amount)
        .bind(sale.discount_amount)
        .bind(sale.note.as_deref())
        .bind(sale.occurred_at)
        .bind(by.staff_id)
        .fetch_one(&mut *transaction)
        .await?;

        sqlx::query("DELETE FROM sale_items WHERE sale_id = $1")
            .bind(sale.id)
            .execute(&mut *transaction)
            .await?;

        for line in &sale.lines {
            sqlx::query(
                "INSERT INTO sale_items
                     (id, sale_id, product_id, product_name, quantity,
                      unit_price, unit_cost, line_total)
                 VALUES ($1, $2, $3, $4, $5, $6, $7, $8)",
            )
            .bind(line.id)
            .bind(sale.id)
            .bind(line.product_id)
            .bind(&line.product_name)
            .bind(line.quantity)
            .bind(line.unit_price)
            .bind(line.unit_cost)
            .bind(line.line_total)
            .execute(&mut *transaction)
            .await?;

            let Some(product_id) = line.product_id else {
                continue;
            };

            sqlx::query(
                "UPDATE products
                 SET stock_quantity = stock_quantity - $1, updated_at = now()
                 WHERE id = $2 AND store_id = $3",
            )
            .bind(line.quantity)
            .bind(product_id)
            .bind(sale.store_id)
            .execute(&mut *transaction)
            .await?;

            sqlx::query(
                "INSERT INTO stock_movements
                     (id, store_id, product_id, movement, quantity, unit_cost, note, occurred_at)
                 VALUES ($1, $2, $3, 'sale', $4, $5, $6, $7)",
            )
            .bind(Uuid::new_v4())
            .bind(sale.store_id)
            .bind(product_id)
            .bind(-line.quantity)
            .bind(line.unit_cost)
            .bind(format!("sale {}", sale.id))
            .bind(sale.occurred_at)
            .execute(&mut *transaction)
            .await?;
        }

        transaction.commit().await?;
        Ok(RecordedSale {
            sale: stored,
            created: existing.is_none(),
        })
    }

    pub async fn list(
        &self,
        store_id: Uuid,
        filter: &SaleFilter,
        page: PageRequest,
    ) -> ApiResult<Vec<SaleView>> {
        let sales = sqlx::query_as::<_, SaleView>(
            "SELECT id, reference, payment_method, total_amount, cost_amount,
                    discount_amount, note, occurred_at FROM sales
             WHERE store_id = $1
               AND deleted_at IS NULL
               AND ($2::timestamptz IS NULL OR occurred_at >= $2)
               AND ($3::timestamptz IS NULL OR occurred_at < $3)
               AND ($4::text IS NULL OR payment_method = $4)
             ORDER BY occurred_at DESC
             LIMIT $5 OFFSET $6",
        )
        .bind(store_id)
        .bind(filter.from)
        .bind(filter.to)
        .bind(filter.payment_method.as_deref())
        .bind(page.limit())
        .bind(page.offset())
        .fetch_all(&self.pool)
        .await?;

        Ok(sales)
    }

    pub async fn find(&self, store_id: Uuid, sale_id: Uuid) -> ApiResult<Option<SaleView>> {
        let sale = sqlx::query_as::<_, SaleView>(
            "SELECT id, reference, payment_method, total_amount, cost_amount,
                    discount_amount, note, occurred_at FROM sales
             WHERE store_id = $1 AND id = $2 AND deleted_at IS NULL",
        )
        .bind(store_id)
        .bind(sale_id)
        .fetch_optional(&self.pool)
        .await?;

        Ok(sale)
    }

    pub async fn lines_for(&self, sale_id: Uuid) -> ApiResult<Vec<SaleLineView>> {
        let lines = sqlx::query_as::<_, SaleLineView>(
            "SELECT id, sale_id, product_id, product_name, quantity,
                    unit_price, unit_cost, line_total
             FROM sale_items WHERE sale_id = $1 ORDER BY product_name",
        )
        .bind(sale_id)
        .fetch_all(&self.pool)
        .await?;

        Ok(lines)
    }

    /// Voiding puts the stock back, so a mistaken entry does not leave the
    /// inventory count wrong.
    /// Returns the voided sale, or `None` if there was nothing to void.
    pub async fn void(&self, store_id: Uuid, sale_id: Uuid) -> ApiResult<Option<SaleView>> {
        let mut transaction = self.pool.begin().await?;

        let voided = sqlx::query_as::<_, SaleView>(
            "UPDATE sales SET deleted_at = now(), updated_at = now()
             WHERE store_id = $1 AND id = $2 AND deleted_at IS NULL
             RETURNING id, reference, payment_method, total_amount, cost_amount,
                       discount_amount, note, occurred_at",
        )
        .bind(store_id)
        .bind(sale_id)
        .fetch_optional(&mut *transaction)
        .await?;

        if voided.is_none() {
            transaction.rollback().await?;
            return Ok(None);
        }

        restore_stock_for(&mut transaction, sale_id, store_id).await?;
        retire_movements_for(&mut transaction, sale_id, store_id).await?;

        transaction.commit().await?;
        Ok(voided)
    }
}

type Transaction<'a> = sqlx::Transaction<'a, sqlx::Postgres>;

async fn find_any(transaction: &mut Transaction<'_>, sale_id: Uuid) -> ApiResult<SaleView> {
    let sale = sqlx::query_as::<_, SaleView>(
        "SELECT id, reference, payment_method, total_amount, cost_amount,
                discount_amount, note, occurred_at FROM sales WHERE id = $1",
    )
    .bind(sale_id)
    .fetch_one(&mut **transaction)
    .await?;

    Ok(sale)
}

/// Gives back the stock that the sale's current lines took out.
async fn restore_stock_for(
    transaction: &mut Transaction<'_>,
    sale_id: Uuid,
    store_id: Uuid,
) -> ApiResult<()> {
    sqlx::query(
        "UPDATE products p
         SET stock_quantity = p.stock_quantity + i.quantity, updated_at = now()
         FROM sale_items i
         WHERE i.sale_id = $1 AND i.product_id = p.id AND p.store_id = $2",
    )
    .bind(sale_id)
    .bind(store_id)
    .execute(&mut **transaction)
    .await?;

    Ok(())
}

async fn retire_movements_for(
    transaction: &mut Transaction<'_>,
    sale_id: Uuid,
    store_id: Uuid,
) -> ApiResult<()> {
    sqlx::query(
        "UPDATE stock_movements SET deleted_at = now(), updated_at = now()
         WHERE store_id = $1 AND note = $2 AND deleted_at IS NULL",
    )
    .bind(store_id)
    .bind(format!("sale {sale_id}"))
    .execute(&mut **transaction)
    .await?;

    Ok(())
}
