use serde_json::{Map, Value, json};
use uuid::Uuid;

use crate::features::access::{Actor, Permission};
use crate::features::audit::{AuditAction, AuditEntry, AuditTrail};
use crate::infrastructure::realtime::{EventBroadcaster, RealtimeEvent, RealtimeTopic};
use crate::shared::{
    ApiError, ApiResult, Money, PageRequest, money_from_f64, money_zero, quantity_from_f64,
};

use super::product_payloads::{ProductFilter, ProductView, SaveProductRequest};
use super::product_repository::ProductRepository;

#[derive(Clone)]
pub struct ProductService {
    repository: ProductRepository,
    broadcaster: EventBroadcaster,
    audit: AuditTrail,
}

impl ProductService {
    pub fn new(
        repository: ProductRepository,
        broadcaster: EventBroadcaster,
        audit: AuditTrail,
    ) -> Self {
        Self {
            repository,
            broadcaster,
            audit,
        }
    }

    pub async fn list(
        &self,
        store_id: Uuid,
        filter: ProductFilter,
        page: PageRequest,
    ) -> ApiResult<Vec<ProductView>> {
        self.repository.list(store_id, &filter, page).await
    }

    pub async fn find(&self, store_id: Uuid, product_id: Uuid) -> ApiResult<ProductView> {
        self.repository
            .find(store_id, product_id)
            .await?
            .ok_or(ApiError::NotFound("product"))
    }

    pub async fn save(
        &self,
        store_id: Uuid,
        actor: &Actor,
        request: SaveProductRequest,
    ) -> ApiResult<ProductView> {
        actor.require(Permission::ManageProducts)?;

        let product_id = request.id.unwrap_or_else(Uuid::new_v4);
        let before = self.repository.find(store_id, product_id).await?;
        let selling = money_from_f64(request.selling_price);

        // A device without cost access sends zero for the cost it was never
        // shown. Keeping the stored cost stops that zero from wiping it.
        let cost = if actor.can(Permission::ViewProfit) {
            money_from_f64(request.cost_price)
        } else {
            before
                .as_ref()
                .map(|product| product.cost_price)
                .unwrap_or_else(money_zero)
        };

        if selling < cost {
            return Err(ApiError::BadRequest(
                "selling price is lower than cost price, this product would lose money".into(),
            ));
        }

        let barcode = request
            .barcode
            .as_deref()
            .map(str::trim)
            .filter(|value| !value.is_empty());

        let product = self
            .repository
            .upsert(
                store_id,
                product_id,
                request.name.trim(),
                barcode,
                request.unit_label.trim(),
                cost,
                selling,
                quantity_from_f64(request.opening_stock),
                quantity_from_f64(request.reorder_level),
            )
            .await?;

        if let Some(entry) = describe_save(store_id, before.as_ref(), &product) {
            self.audit.record(actor, entry).await;
        }

        self.broadcaster
            .publish(RealtimeEvent::new(
                store_id,
                RealtimeTopic::ProductChanged,
                Some(product.id),
            ))
            .await;

        Ok(product)
    }

    pub async fn remove(&self, store_id: Uuid, actor: &Actor, product_id: Uuid) -> ApiResult<()> {
        actor.require(Permission::ManageProducts)?;

        let name = self
            .repository
            .soft_delete(store_id, product_id)
            .await?
            .ok_or(ApiError::NotFound("product"))?;

        self.audit
            .record(
                actor,
                AuditEntry::new(
                    store_id,
                    AuditAction::ProductRemoved,
                    product_id,
                    json!({ "name": name }),
                ),
            )
            .await;

        self.broadcaster
            .publish(RealtimeEvent::new(
                store_id,
                RealtimeTopic::ProductChanged,
                Some(product_id),
            ))
            .await;

        Ok(())
    }

    pub async fn low_stock(&self, store_id: Uuid) -> ApiResult<Vec<ProductView>> {
        self.repository.list_low_stock(store_id).await
    }
}

/// What the log should say about a save, if anything. A device retrying a
/// push re-sends products unchanged; those are not news.
fn describe_save(
    store_id: Uuid,
    before: Option<&ProductView>,
    after: &ProductView,
) -> Option<AuditEntry> {
    let Some(before) = before else {
        return Some(AuditEntry::new(
            store_id,
            AuditAction::ProductAdded,
            after.id,
            json!({ "name": after.name, "selling_price": after.selling_price }),
        ));
    };

    let mut changes = Map::new();
    if before.name != after.name {
        changes.insert("name".into(), json!([before.name, after.name]));
    }
    let mut money_change = |field: &str, old: Money, new: Money| {
        if old != new {
            changes.insert(field.into(), json!([old, new]));
        }
    };
    money_change("selling_price", before.selling_price, after.selling_price);
    money_change("cost_price", before.cost_price, after.cost_price);

    if changes.is_empty() {
        return None;
    }

    Some(AuditEntry::new(
        store_id,
        AuditAction::ProductChanged,
        after.id,
        json!({ "name": after.name, "changes": Value::Object(changes) }),
    ))
}
