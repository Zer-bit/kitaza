use axum::Json;
use axum::extract::{Path, Query, State};
use axum::http::StatusCode;
use uuid::Uuid;

use crate::application::AppState;
use crate::features::access::{Actor, Permission};
use crate::features::stores::StoreScope;
use crate::shared::{ApiResult, PageRequest, ValidatedJson};

use super::product_payloads::{ProductFilter, ProductView, SaveProductRequest};

pub async fn list_products(
    State(state): State<AppState>,
    scope: StoreScope,
    Query(filter): Query<ProductFilter>,
    Query(page): Query<PageRequest>,
) -> ApiResult<Json<Vec<ProductView>>> {
    let products = state
        .product_service
        .list(scope.store_id, filter, page)
        .await?;
    Ok(Json(shown_to(&scope.actor, products)))
}

pub async fn low_stock_products(
    State(state): State<AppState>,
    scope: StoreScope,
) -> ApiResult<Json<Vec<ProductView>>> {
    let products = state.product_service.low_stock(scope.store_id).await?;
    Ok(Json(shown_to(&scope.actor, products)))
}

pub async fn get_product(
    State(state): State<AppState>,
    scope: StoreScope,
    Path((_store_id, product_id)): Path<(Uuid, Uuid)>,
) -> ApiResult<Json<ProductView>> {
    let product = state
        .product_service
        .find(scope.store_id, product_id)
        .await?;
    Ok(Json(shown_to(&scope.actor, vec![product]).remove(0)))
}

pub async fn save_product(
    State(state): State<AppState>,
    scope: StoreScope,
    ValidatedJson(request): ValidatedJson<SaveProductRequest>,
) -> ApiResult<(StatusCode, Json<ProductView>)> {
    let product = state
        .product_service
        .save(scope.store_id, &scope.actor, request)
        .await?;
    Ok((
        StatusCode::OK,
        Json(shown_to(&scope.actor, vec![product]).remove(0)),
    ))
}

pub async fn delete_product(
    State(state): State<AppState>,
    scope: StoreScope,
    Path((_store_id, product_id)): Path<(Uuid, Uuid)>,
) -> ApiResult<StatusCode> {
    state
        .product_service
        .remove(scope.store_id, &scope.actor, product_id)
        .await?;
    Ok(StatusCode::NO_CONTENT)
}

/// Staff sell from the catalogue, so they may read it, but without costs
/// unless the owner allowed them.
fn shown_to(actor: &Actor, products: Vec<ProductView>) -> Vec<ProductView> {
    if actor.can(Permission::ViewProfit) {
        return products;
    }
    products
        .into_iter()
        .map(ProductView::without_cost)
        .collect()
}
