use chrono::Utc;
use serde_json::Value;
use uuid::Uuid;

use crate::features::access::{Actor, Permission};
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

    /// Each row is checked against what `actor` may do, so a staff phone
    /// that queued something it was not allowed to gets that row refused
    /// with a reason, and the rest of its batch still goes through.
    pub async fn push(
        &self,
        store_id: Uuid,
        actor: &Actor,
        request: PushRequest,
    ) -> ApiResult<PushOutcome> {
        let mut outcome = Outcome::default();

        // Products first: a queued sale or stock count may refer to a product
        // that was created on the same device while it was offline.
        for product in request.products {
            let id = product.id;
            match self.products.save(store_id, actor, product).await {
                Ok(saved) => outcome.applied(PushedEntity::Product, saved.id),
                Err(error) => outcome.rejected(PushedEntity::Product, id, error),
            }
        }

        for event in into_timeline(request.sales, request.stock_movements) {
            match event {
                StockEvent::Sale(sale) => {
                    let id = sale.id;
                    match self.sales.record(store_id, actor, sale).await {
                        Ok(saved) => outcome.applied(PushedEntity::Sale, saved.sale.id),
                        Err(error) => outcome.rejected(PushedEntity::Sale, id, error),
                    }
                }
                StockEvent::Movement(movement) => {
                    let id = movement.id;
                    match self.inventory.record(store_id, actor, movement).await {
                        Ok(()) => outcome.applied_if_known(PushedEntity::StockMovement, id),
                        Err(error) => outcome.rejected(PushedEntity::StockMovement, id, error),
                    }
                }
            }
        }

        for expense in request.expenses {
            let id = expense.id;
            match self.expenses.record(store_id, actor, expense).await {
                Ok(saved) => outcome.applied(PushedEntity::Expense, saved.id),
                Err(error) => outcome.rejected(PushedEntity::Expense, id, error),
            }
        }

        for withdrawal in request.withdrawals {
            let id = withdrawal.id;
            match self.withdrawals.record(store_id, actor, withdrawal).await {
                Ok(saved) => outcome.applied(PushedEntity::Withdrawal, saved.id),
                Err(error) => outcome.rejected(PushedEntity::Withdrawal, id, error),
            }
        }

        // Deletions last, so a row created and removed in the same batch ends
        // up removed.
        for deletion in request.deletions {
            let id = deletion.id;
            match self.delete(store_id, actor, &deletion).await {
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

    /// Staff without profit access get no cost figures, expenses or
    /// withdrawals: hiding them on screen is not enough when the phone's
    /// database can be read. Their cursor never advances past the withheld
    /// tables, so granting access later downloads those in full.
    pub async fn pull(
        &self,
        store_id: Uuid,
        actor: &Actor,
        query: PullQuery,
    ) -> ApiResult<PullResponse> {
        let sees_costs = actor.can(Permission::ViewProfit);
        let mut cursor = SyncCursor::decode(query.cursor.as_deref());
        let mut has_more = false;
        let mut pages = Vec::with_capacity(SyncTable::ALL.len());

        for table in SyncTable::ALL {
            if !sees_costs && matches!(table, SyncTable::Expenses | SyncTable::Withdrawals) {
                pages.push(Vec::new());
                continue;
            }

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

        let [
            mut products,
            mut sales,
            expenses,
            withdrawals,
            mut stock_movements,
        ]: [Vec<_>; 5] = pages
            .try_into()
            .map_err(|_| ApiError::Internal(anyhow::anyhow!("sync table count changed")))?;

        let sale_ids: Vec<Uuid> = sales
            .iter()
            .filter_map(|row| row.get("id")?.as_str()?.parse().ok())
            .collect();
        let mut sale_items = self.repository.lines_for_sales(&sale_ids).await?;

        if !sees_costs {
            zero_field(&mut products, "cost_price");
            zero_field(&mut sales, "cost_amount");
            zero_field(&mut sale_items, "unit_cost");
            zero_field(&mut stock_movements, "unit_cost");
        }

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
    async fn delete(
        &self,
        store_id: Uuid,
        actor: &Actor,
        deletion: &DeletionRequest,
    ) -> ApiResult<()> {
        let result = match deletion.entity.as_str() {
            "sale" => self.sales.void(store_id, actor, deletion.id).await,
            "expense" => self.expenses.remove(store_id, actor, deletion.id).await,
            "withdrawal" => self.withdrawals.remove(store_id, actor, deletion.id).await,
            "product" => self.products.remove(store_id, actor, deletion.id).await,
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

fn zero_field(rows: &mut [Value], field: &str) {
    for row in rows {
        if let Some(value) = row.get_mut(field) {
            *value = Value::from(0);
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
