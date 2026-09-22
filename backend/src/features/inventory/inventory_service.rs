use chrono::Utc;
use uuid::Uuid;

use crate::features::products::ProductRepository;
use crate::infrastructure::cache::DashboardCache;
use crate::infrastructure::realtime::{EventBroadcaster, RealtimeEvent, RealtimeTopic};
use crate::shared::{ApiError, ApiResult, PageRequest, money_from_f64, quantity_from_f64};

use super::inventory_payloads::{InventoryValuation, MovementView, RecordMovementRequest};
use super::stock_repository::StockRepository;

/// Movements that add stock; everything else in the allowed list removes it.
const INBOUND_MOVEMENTS: [&str; 1] = ["stock_in"];
const OUTBOUND_MOVEMENTS: [&str; 2] = ["stock_out", "spoilage"];

#[derive(Clone)]
pub struct InventoryService {
    stock: StockRepository,
    products: ProductRepository,
    cache: DashboardCache,
    broadcaster: EventBroadcaster,
}

impl InventoryService {
    pub fn new(
        stock: StockRepository,
        products: ProductRepository,
        cache: DashboardCache,
        broadcaster: EventBroadcaster,
    ) -> Self {
        Self {
            stock,
            products,
            cache,
            broadcaster,
        }
    }

    pub async fn record(&self, store_id: Uuid, request: RecordMovementRequest) -> ApiResult<()> {
        let movement = request.movement.trim().to_lowercase();
        let magnitude = quantity_from_f64(request.quantity);

        let signed_quantity = if INBOUND_MOVEMENTS.contains(&movement.as_str()) {
            magnitude
        } else if OUTBOUND_MOVEMENTS.contains(&movement.as_str()) {
            -magnitude
        } else if movement == "adjustment" {
            // An adjustment sets the counted total, so the ledger records the
            // difference against what the system currently believes.
            magnitude
                - self
                    .products
                    .stock_on_hand(store_id, request.product_id)
                    .await?
        } else {
            return Err(ApiError::BadRequest(format!(
                "unsupported stock movement '{movement}'"
            )));
        };

        self.stock
            .record_movement(
                store_id,
                request.id.unwrap_or_else(Uuid::new_v4),
                request.product_id,
                &movement,
                signed_quantity,
                money_from_f64(request.unit_cost),
                request
                    .note
                    .as_deref()
                    .map(str::trim)
                    .filter(|n| !n.is_empty()),
                request.occurred_at.unwrap_or_else(Utc::now),
            )
            .await?;

        self.cache.invalidate_store(store_id).await;
        self.broadcaster
            .publish(RealtimeEvent::new(
                store_id,
                RealtimeTopic::ProductChanged,
                Some(request.product_id),
            ))
            .await;

        Ok(())
    }

    pub async fn movements(
        &self,
        store_id: Uuid,
        product_id: Option<Uuid>,
        page: PageRequest,
    ) -> ApiResult<Vec<MovementView>> {
        self.stock.list_movements(store_id, product_id, page).await
    }

    pub async fn valuation(&self, store_id: Uuid) -> ApiResult<InventoryValuation> {
        self.stock.valuation(store_id).await
    }
}
