use axum::Json;
use axum::extract::{Query, State};
use axum::http::StatusCode;
use serde::Deserialize;
use uuid::Uuid;

use crate::application::AppState;
use crate::features::stores::StoreScope;
use crate::shared::{ApiResult, PageRequest, ValidatedJson};

use super::inventory_payloads::{InventoryValuation, MovementView, RecordMovementRequest};

#[derive(Deserialize)]
pub struct MovementFilter {
    #[serde(default)]
    pub product_id: Option<Uuid>,
}

pub async fn record_movement(
    State(state): State<AppState>,
    scope: StoreScope,
    ValidatedJson(request): ValidatedJson<RecordMovementRequest>,
) -> ApiResult<StatusCode> {
    state
        .inventory_service
        .record(scope.store_id, request)
        .await?;
    Ok(StatusCode::CREATED)
}

pub async fn list_movements(
    State(state): State<AppState>,
    scope: StoreScope,
    Query(filter): Query<MovementFilter>,
    Query(page): Query<PageRequest>,
) -> ApiResult<Json<Vec<MovementView>>> {
    Ok(Json(
        state
            .inventory_service
            .movements(scope.store_id, filter.product_id, page)
            .await?,
    ))
}

pub async fn inventory_valuation(
    State(state): State<AppState>,
    scope: StoreScope,
) -> ApiResult<Json<InventoryValuation>> {
    Ok(Json(
        state.inventory_service.valuation(scope.store_id).await?,
    ))
}
