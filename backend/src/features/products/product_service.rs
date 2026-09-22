use uuid::Uuid;

use crate::infrastructure::realtime::{EventBroadcaster, RealtimeEvent, RealtimeTopic};
use crate::shared::{ApiError, ApiResult, PageRequest, money_from_f64, quantity_from_f64};

use super::product_payloads::{ProductFilter, ProductView, SaveProductRequest};
use super::product_repository::ProductRepository;

#[derive(Clone)]
pub struct ProductService {
    repository: ProductRepository,
    broadcaster: EventBroadcaster,
}

impl ProductService {
    pub fn new(repository: ProductRepository, broadcaster: EventBroadcaster) -> Self {
        Self {
            repository,
            broadcaster,
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
        request: SaveProductRequest,
    ) -> ApiResult<ProductView> {
        let selling = money_from_f64(request.selling_price);
        let cost = money_from_f64(request.cost_price);

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
                request.id.unwrap_or_else(Uuid::new_v4),
                request.name.trim(),
                barcode,
                request.unit_label.trim(),
                cost,
                selling,
                quantity_from_f64(request.opening_stock),
                quantity_from_f64(request.reorder_level),
            )
            .await?;

        self.broadcaster
            .publish(RealtimeEvent::new(
                store_id,
                RealtimeTopic::ProductChanged,
                Some(product.id),
            ))
            .await;

        Ok(product)
    }

    pub async fn remove(&self, store_id: Uuid, product_id: Uuid) -> ApiResult<()> {
        if !self.repository.soft_delete(store_id, product_id).await? {
            return Err(ApiError::NotFound("product"));
        }

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
