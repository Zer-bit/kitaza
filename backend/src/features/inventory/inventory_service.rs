use chrono::Utc;
use serde_json::json;
use uuid::Uuid;

use crate::features::access::{Actor, Permission};
use crate::features::audit::{AuditAction, AuditEntry, AuditTrail};
use crate::infrastructure::cache::DashboardCache;
use crate::infrastructure::realtime::{EventBroadcaster, RealtimeEvent, RealtimeTopic};
use crate::shared::{
    ApiError, ApiResult, PageRequest, money_from_f64, money_zero, quantity_from_f64,
};

use super::inventory_payloads::{InventoryValuation, MovementView, RecordMovementRequest};
use super::stock_repository::{LedgerEntry, StockEffect, StockRepository};

/// Movements that add stock; everything else in the allowed list removes it.
const INBOUND_MOVEMENTS: [&str; 1] = ["stock_in"];
const OUTBOUND_MOVEMENTS: [&str; 2] = ["stock_out", "spoilage"];

#[derive(Clone)]
pub struct InventoryService {
    stock: StockRepository,
    cache: DashboardCache,
    broadcaster: EventBroadcaster,
    audit: AuditTrail,
}

impl InventoryService {
    pub fn new(
        stock: StockRepository,
        cache: DashboardCache,
        broadcaster: EventBroadcaster,
        audit: AuditTrail,
    ) -> Self {
        Self {
            stock,
            cache,
            broadcaster,
            audit,
        }
    }

    pub async fn record(
        &self,
        store_id: Uuid,
        actor: &Actor,
        request: RecordMovementRequest,
    ) -> ApiResult<()> {
        actor.require(Permission::ManageProducts)?;

        let movement = request.movement.trim().to_lowercase();
        let quantity = quantity_from_f64(request.quantity);

        let effect = if INBOUND_MOVEMENTS.contains(&movement.as_str()) {
            StockEffect::Change(quantity)
        } else if OUTBOUND_MOVEMENTS.contains(&movement.as_str()) {
            StockEffect::Change(-quantity)
        } else if movement == "adjustment" {
            // An adjustment records what the owner physically counted, which
            // may legitimately be zero.
            StockEffect::SetTo(quantity)
        } else {
            return Err(ApiError::BadRequest(format!(
                "unsupported stock movement '{movement}'"
            )));
        };

        if movement != "adjustment" && quantity.is_zero() {
            return Err(ApiError::BadRequest(
                "quantity must be greater than zero".into(),
            ));
        }

        // A delivery's cost updates the product's cost price. From a device
        // that cannot see costs it is a zero it was never shown, not news.
        let unit_cost = if actor.can(Permission::ViewProfit) {
            money_from_f64(request.unit_cost)
        } else {
            money_zero()
        };
        let movement_id = request.id.unwrap_or_else(Uuid::new_v4);
        let occurred_at = request.occurred_at.unwrap_or_else(Utc::now);

        let applied = self
            .stock
            .record_movement(LedgerEntry {
                store_id,
                movement_id,
                product_id: request.product_id,
                movement: &movement,
                effect,
                unit_cost,
                note: request
                    .note
                    .as_deref()
                    .map(str::trim)
                    .filter(|n| !n.is_empty()),
                occurred_at,
            })
            .await?;

        if let Some(applied) = applied {
            if let Some(action) = AuditAction::for_movement(&movement) {
                let details = if movement == "adjustment" {
                    json!({
                        "name": applied.product_name,
                        "counted": quantity,
                        "change": applied.change,
                    })
                } else {
                    json!({ "name": applied.product_name, "quantity": quantity })
                };
                self.audit
                    .record(
                        actor,
                        AuditEntry::new(store_id, action, request.product_id, details)
                            .at(occurred_at),
                    )
                    .await;
            }

            self.cache.invalidate_store(store_id).await;
            self.broadcaster
                .publish(RealtimeEvent::new(
                    store_id,
                    RealtimeTopic::ProductChanged,
                    Some(request.product_id),
                ))
                .await;
        }

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
