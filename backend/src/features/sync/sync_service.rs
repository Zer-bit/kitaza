use chrono::{DateTime, TimeZone, Utc};
use uuid::Uuid;

use crate::features::expenses::ExpenseService;
use crate::features::products::ProductService;
use crate::features::sales::SaleService;
use crate::features::withdrawals::WithdrawalService;
use crate::shared::{ApiError, ApiResult};

use super::sync_payloads::{PullQuery, PullResponse, PushOutcome, PushRequest, RejectedRow};
use super::sync_repository::SyncRepository;

/// Moves data between a device's local SQLite and the cloud. Every write is an
/// upsert on a client generated id, so replaying the same batch is harmless -
/// which matters when a phone loses signal mid-sync.
#[derive(Clone)]
pub struct SyncService {
    repository: SyncRepository,
    products: ProductService,
    sales: SaleService,
    expenses: ExpenseService,
    withdrawals: WithdrawalService,
}

impl SyncService {
    pub fn new(
        repository: SyncRepository,
        products: ProductService,
        sales: SaleService,
        expenses: ExpenseService,
        withdrawals: WithdrawalService,
    ) -> Self {
        Self {
            repository,
            products,
            sales,
            expenses,
            withdrawals,
        }
    }

    pub async fn push(&self, store_id: Uuid, request: PushRequest) -> ApiResult<PushOutcome> {
        let mut applied = Vec::new();
        let mut rejected = Vec::new();

        // Products first: a queued sale may reference a product created on the
        // same device while it was offline.
        for product in request.products {
            let id = product.id;
            match self.products.save(store_id, product).await {
                Ok(saved) => applied.push(saved.id),
                Err(error) => rejected.push(reject("product", id, error)),
            }
        }

        for sale in request.sales {
            let id = sale.id;
            match self.sales.record(store_id, sale).await {
                Ok(saved) => applied.push(saved.sale.id),
                Err(error) => rejected.push(reject("sale", id, error)),
            }
        }

        for expense in request.expenses {
            let id = expense.id;
            match self.expenses.record(store_id, expense).await {
                Ok(saved) => applied.push(saved.id),
                Err(error) => rejected.push(reject("expense", id, error)),
            }
        }

        for withdrawal in request.withdrawals {
            let id = withdrawal.id;
            match self.withdrawals.record(store_id, withdrawal).await {
                Ok(saved) => applied.push(saved.id),
                Err(error) => rejected.push(reject("withdrawal", id, error)),
            }
        }

        Ok(PushOutcome {
            applied,
            rejected,
            server_time: Utc::now(),
        })
    }

    pub async fn pull(&self, store_id: Uuid, query: PullQuery) -> ApiResult<PullResponse> {
        let since = query.since.unwrap_or_else(epoch);
        // Read the cursor before querying so a row written mid-pull is picked
        // up by the next sync instead of being skipped.
        let cursor = Utc::now();

        let (products, sales, sale_items, expenses, withdrawals, stock_movements) = tokio::try_join!(
            self.repository.changed_products(store_id, since),
            self.repository.changed_sales(store_id, since),
            self.repository.changed_sale_items(store_id, since),
            self.repository.changed_expenses(store_id, since),
            self.repository.changed_withdrawals(store_id, since),
            self.repository.changed_stock_movements(store_id, since),
        )?;

        Ok(PullResponse {
            products,
            sales,
            sale_items,
            expenses,
            withdrawals,
            stock_movements,
            cursor,
        })
    }
}

fn reject(entity: &'static str, id: Option<Uuid>, error: ApiError) -> RejectedRow {
    RejectedRow {
        entity,
        id,
        reason: error.to_string(),
    }
}

fn epoch() -> DateTime<Utc> {
    Utc.timestamp_opt(0, 0).single().unwrap_or_else(Utc::now)
}
