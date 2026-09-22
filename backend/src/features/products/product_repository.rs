use rust_decimal::Decimal;
use uuid::Uuid;

use crate::infrastructure::database::PgPool;
use crate::shared::{ApiResult, Money, PageRequest, Quantity};

use super::product_payloads::{ProductFilter, ProductView};

#[derive(Clone)]
pub struct ProductRepository {
    pool: PgPool,
}

impl ProductRepository {
    pub fn new(pool: PgPool) -> Self {
        Self { pool }
    }

    pub async fn list(
        &self,
        store_id: Uuid,
        filter: &ProductFilter,
        page: PageRequest,
    ) -> ApiResult<Vec<ProductView>> {
        let search = filter
            .search
            .as_deref()
            .map(str::trim)
            .filter(|term| !term.is_empty())
            .map(|term| format!("%{term}%"));

        let products = sqlx::query_as::<_, ProductView>(
            "SELECT id, name, barcode, unit_label, cost_price, selling_price,
                    stock_quantity, reorder_level, is_active, updated_at FROM products
             WHERE store_id = $1
               AND deleted_at IS NULL
               AND ($2 OR is_active)
               AND ($3::text IS NULL OR name ILIKE $3 OR barcode ILIKE $3)
               AND (NOT $4 OR (reorder_level > 0 AND stock_quantity <= reorder_level))
             ORDER BY name
             LIMIT $5 OFFSET $6",
        )
        .bind(store_id)
        .bind(filter.include_inactive.unwrap_or(false))
        .bind(search)
        .bind(filter.only_low_stock.unwrap_or(false))
        .bind(page.limit())
        .bind(page.offset())
        .fetch_all(&self.pool)
        .await?;

        Ok(products)
    }

    pub async fn find(&self, store_id: Uuid, product_id: Uuid) -> ApiResult<Option<ProductView>> {
        let product = sqlx::query_as::<_, ProductView>(
            "SELECT id, name, barcode, unit_label, cost_price, selling_price,
                    stock_quantity, reorder_level, is_active, updated_at FROM products
             WHERE store_id = $1 AND id = $2 AND deleted_at IS NULL",
        )
        .bind(store_id)
        .bind(product_id)
        .fetch_optional(&self.pool)
        .await?;

        Ok(product)
    }

    /// Insert-or-update keyed on the client supplied id. Stock is only set on
    /// insert; afterwards it belongs to the inventory ledger.
    #[allow(clippy::too_many_arguments)]
    pub async fn upsert(
        &self,
        store_id: Uuid,
        product_id: Uuid,
        name: &str,
        barcode: Option<&str>,
        unit_label: &str,
        cost_price: Money,
        selling_price: Money,
        opening_stock: Quantity,
        reorder_level: Quantity,
    ) -> ApiResult<ProductView> {
        let product = sqlx::query_as::<_, ProductView>(
            "INSERT INTO products
                 (id, store_id, name, barcode, unit_label, cost_price,
                  selling_price, stock_quantity, reorder_level)
             VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
             ON CONFLICT (id) DO UPDATE SET
                 name          = EXCLUDED.name,
                 barcode       = EXCLUDED.barcode,
                 unit_label    = EXCLUDED.unit_label,
                 cost_price    = EXCLUDED.cost_price,
                 selling_price = EXCLUDED.selling_price,
                 reorder_level = EXCLUDED.reorder_level,
                 is_active     = TRUE,
                 deleted_at    = NULL,
                 updated_at    = now()
             RETURNING id, name, barcode, unit_label, cost_price, selling_price,
                    stock_quantity, reorder_level, is_active, updated_at",
        )
        .bind(product_id)
        .bind(store_id)
        .bind(name)
        .bind(barcode)
        .bind(unit_label)
        .bind(cost_price)
        .bind(selling_price)
        .bind(opening_stock)
        .bind(reorder_level)
        .fetch_one(&self.pool)
        .await?;

        Ok(product)
    }

    pub async fn soft_delete(&self, store_id: Uuid, product_id: Uuid) -> ApiResult<bool> {
        let result = sqlx::query(
            "UPDATE products SET deleted_at = now(), is_active = FALSE, updated_at = now()
             WHERE store_id = $1 AND id = $2 AND deleted_at IS NULL",
        )
        .bind(store_id)
        .bind(product_id)
        .execute(&self.pool)
        .await?;

        Ok(result.rows_affected() > 0)
    }

    pub async fn list_low_stock(&self, store_id: Uuid) -> ApiResult<Vec<ProductView>> {
        let products = sqlx::query_as::<_, ProductView>(
            "SELECT id, name, barcode, unit_label, cost_price, selling_price,
                    stock_quantity, reorder_level, is_active, updated_at FROM products
             WHERE store_id = $1 AND deleted_at IS NULL AND is_active
               AND reorder_level > 0 AND stock_quantity <= reorder_level
             ORDER BY (stock_quantity - reorder_level), name",
        )
        .bind(store_id)
        .fetch_all(&self.pool)
        .await?;

        Ok(products)
    }

    pub async fn stock_on_hand(&self, store_id: Uuid, product_id: Uuid) -> ApiResult<Decimal> {
        let value: Option<(Decimal,)> =
            sqlx::query_as("SELECT stock_quantity FROM products WHERE store_id = $1 AND id = $2")
                .bind(store_id)
                .bind(product_id)
                .fetch_optional(&self.pool)
                .await?;

        Ok(value.map(|row| row.0).unwrap_or(Decimal::ZERO))
    }
}
