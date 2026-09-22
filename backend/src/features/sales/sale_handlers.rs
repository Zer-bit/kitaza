use axum::Json;
use axum::extract::{Path, Query, State};
use axum::http::StatusCode;
use uuid::Uuid;

use crate::application::AppState;
use crate::features::access::Permission;
use crate::features::stores::StoreScope;
use crate::shared::{ApiResult, PageRequest, ValidatedJson};

use super::sale_payloads::{RecordSaleRequest, SaleDetail, SaleFilter, SaleView};

pub async fn record_sale(
    State(state): State<AppState>,
    scope: StoreScope,
    ValidatedJson(request): ValidatedJson<RecordSaleRequest>,
) -> ApiResult<(StatusCode, Json<SaleDetail>)> {
    let sale = state
        .sale_service
        .record(scope.store_id, &scope.actor, request)
        .await?;
    let sale = if scope.actor.can(Permission::ViewProfit) {
        sale
    } else {
        sale.without_costs()
    };
    Ok((StatusCode::CREATED, Json(sale)))
}

pub async fn list_sales(
    State(state): State<AppState>,
    scope: StoreScope,
    Query(filter): Query<SaleFilter>,
    Query(page): Query<PageRequest>,
) -> ApiResult<Json<Vec<SaleView>>> {
    scope.actor.require(Permission::ViewProfit)?;
    Ok(Json(
        state
            .sale_service
            .list(scope.store_id, filter, page)
            .await?,
    ))
}

pub async fn get_sale(
    State(state): State<AppState>,
    scope: StoreScope,
    Path((_store_id, sale_id)): Path<(Uuid, Uuid)>,
) -> ApiResult<Json<SaleDetail>> {
    scope.actor.require(Permission::ViewProfit)?;
    Ok(Json(
        state.sale_service.detail(scope.store_id, sale_id).await?,
    ))
}

pub async fn void_sale(
    State(state): State<AppState>,
    scope: StoreScope,
    Path((_store_id, sale_id)): Path<(Uuid, Uuid)>,
) -> ApiResult<StatusCode> {
    state
        .sale_service
        .void(scope.store_id, &scope.actor, sale_id)
        .await?;
    Ok(StatusCode::NO_CONTENT)
}
