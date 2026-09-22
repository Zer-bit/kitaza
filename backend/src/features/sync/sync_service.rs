use chrono::Utc;
use uuid::Uuid;

use crate::features::expenses::ExpenseService;
use crate::features::inventory::InventoryService;
use crate::features::products::ProductService;
use crate::features::sales::SaleService;
use crate::features::withdrawals::WithdrawalService;
use crate::shared::{ApiError, ApiResult};

use super::push_timeline::{StockEvent, into_timeline};
use super::sync_cursor::{SyncCursor, SyncTable};
use super::sync_payloads::{
    DeletionRequest, PullQuery, PullResponse, PushOutcome, PushRequest, PushedEntity, PushedRow,
    RejectedRow,
};
use super::sync_repository::SyncRepository;

/// Moves data between a device's SQLite and the cloud.
///
/// Every write is an upsert on a client-generated id and every stock change is
/// idempotent, so replaying a batch is harmless - which matters, because a
/// phone losing signal halfway through a push is the normal case.
#[derive(Clone)]
pub struct SyncService {
    repository: SyncRepository,
    page_size: i64,
    products: ProductService,
    inventory: InventoryService,
    sales: SaleService,
    expenses: ExpenseService,
    withdrawals: WithdrawalService,
}

/// The services a push fans out to.
pub struct SyncDependencies {
    pub products: ProductService,
    pub inventory: InventoryService,
    pub sales: SaleService,
    pub expenses: ExpenseService,
    pub withdrawals: WithdrawalService,
}

impl SyncService {
    pub fn new(repository: SyncRepository, page_size: i64, services: SyncDependencies) -> Self {
        Self {
            repository,
            page_size,
            products: services.products,
            inventory: services.inventory,
            sales: services.sales,
            expenses: services.expenses,
            withdrawals: services.withdrawals,
        }
    }

    pub async fn push(&self, store_id: Uuid, request: PushRequest) -> ApiResult<PushOutcome> {
        let mut outcome = Outcome::default();

        // Products first: a queued sale or stock count may refer to a product
        // that was created on the same device while it was offline.
        for product in request.products {
            let id = product.id;
            match self.products.save(store_id, product).await {
                Ok(saved) => outcome.applied(PushedEntity::Product, saved.id),
                Err(error) => outcome.rejected(PushedEntity::Product, id, error),
            }
        }

        for event in into_timeline(request.sales, request.stock_movements) {
            match event {
                StockEvent::Sale(sale) => {
                    let id = sale.id;
                    match self.sales.record(store_id, sale).await {
                        Ok(saved) => outcome.applied(PushedEntity::Sale, saved.sale.id),
                        Err(error) => outcome.rejected(PushedEntity::Sale, id, error),
                    }
                }
                StockEvent::Movement(movement) => {
                    let id = movement.id;
                    match self.inventory.record(store_id, movement).await {
                        Ok(()) => outcome.applied_if_known(PushedEntity::StockMovement, id),
                        Err(error) => outcome.rejected(PushedEntity::StockMovement, id, error),
                    }
                }
            }
        }

        for expense in request.expenses {
            let id = expense.id;
            match self.expenses.record(store_id, expense).await {
                Ok(saved) => outcome.applied(PushedEntity::Expense, saved.id),
                Err(error) => outcome.rejected(PushedEntity::Expense, id, error),
            }
        }

        for withdrawal in request.withdrawals {
            let id = withdrawal.id;
            match self.withdrawals.record(store_id, withdrawal).await {
                Ok(saved) => outcome.applied(PushedEntity::Withdrawal, saved.id),
                Err(error) => outcome.rejected(PushedEntity::Withdrawal, id, error),
            }
        }

        // Deletions last, so a row created and removed in the same batch ends
        // up removed.
        for deletion in request.deletions {
            let id = deletion.id;
            match self.delete(store_id, &deletion).await {
                Ok(()) => outcome.applied(PushedEntity::Deletion, id),
                Err(error) => outcome.rejected(PushedEntity::Deletion, Some(id), error),
            }
        }

        Ok(PushOutcome {
            applied: outcome.applied,
            rejected: outcome.rejected,
            server_time: Utc::now(),
        })
    }

    pub async fn pull(&self, store_id: Uuid, query: PullQuery) -> ApiResult<PullResponse> {
        let mut cursor = SyncCursor::decode(query.cursor.as_deref());
        let mut has_more = false;
        let mut pages = Vec::with_capacity(SyncTable::ALL.len());

        for table in SyncTable::ALL {
            let page = self
                .repository
                .changed_since(table, store_id, cursor.mark(table), self.page_size)
                .await?;

            if page.rows.len() as i64 >= self.page_size {
                has_more = true;
            }
            if let Some(last) = page.last {
                cursor.advance(table, last);
            }
            pages.push(page.rows);
        }

        let [products, sales, expenses, withdrawals, stock_movements]: [Vec<_>; 5] = pages
            .try_into()
            .map_err(|_| ApiError::Internal(anyhow::anyhow!("sync table count changed")))?;

        let sale_ids: Vec<Uuid> = sales
            .iter()
            .filter_map(|row| row.get("id")?.as_str()?.parse().ok())
            .collect();
        let sale_items = self.repository.lines_for_sales(&sale_ids).await?;

        Ok(PullResponse {
            products,
            sales,
            sale_items,
            expenses,
            withdrawals,
            stock_movements,
            cursor: cursor.encode(),
            has_more,
        })
    }

    /// Removing something that is already gone counts as success: the device
    /// may be retrying a deletion the server accepted last time.
    async fn delete(&self, store_id: Uuid, deletion: &DeletionRequest) -> ApiResult<()> {
        let result = match deletion.entity.as_str() {
            "sale" => self.sales.void(store_id, deletion.id).await,
            "expense" => self.expenses.remove(store_id, deletion.id).await,
            "withdrawal" => self.withdrawals.remove(store_id, deletion.id).await,
            "product" => self.products.remove(store_id, deletion.id).await,
            other => Err(ApiError::BadRequest(format!(
                "cannot delete unknown entity '{other}'"
            ))),
        };

        match result {
            Err(ApiError::NotFound(_)) => Ok(()),
            other => other,
        }
    }
}

#[derive(Default)]
struct Outcome {
    applied: Vec<PushedRow>,
    rejected: Vec<RejectedRow>,
}

impl Outcome {
    fn applied(&mut self, entity: PushedEntity, id: Uuid) {
        self.applied.push(PushedRow { entity, id });
    }

    fn applied_if_known(&mut self, entity: PushedEntity, id: Option<Uuid>) {
        if let Some(id) = id {
            self.applied(entity, id);
        }
    }

    fn rejected(&mut self, entity: PushedEntity, id: Option<Uuid>, error: ApiError) {
        // Internal failures are logged here and reported generically: the
        // device shows this reason to the owner, and a database message is
        // neither useful to them nor safe to expose.
        let reason = match error {
            ApiError::Internal(cause) => {
                tracing::error!(error = ?cause, ?entity, ?id, "sync row failed");
                "could not be saved right now; it will be retried".to_owned()
            }
            other => other.to_string(),
        };

        self.rejected.push(RejectedRow { entity, id, reason });
    }
}
