use axum::Json;
use axum::extract::{Path, Query, State};
use axum::http::StatusCode;
use uuid::Uuid;

use crate::application::AppState;
use crate::features::stores::StoreScope;
use crate::shared::{ApiResult, PageRequest, ValidatedJson};

use super::withdrawal_payloads::{RecordWithdrawalRequest, WithdrawalView};

pub async fn record_withdrawal(
    State(state): State<AppState>,
    scope: StoreScope,
    ValidatedJson(request): ValidatedJson<RecordWithdrawalRequest>,
) -> ApiResult<(StatusCode, Json<WithdrawalView>)> {
    let withdrawal = state
        .withdrawal_service
        .record(scope.store_id, request)
        .await?;
    Ok((StatusCode::CREATED, Json(withdrawal)))
}

pub async fn list_withdrawals(
    State(state): State<AppState>,
    scope: StoreScope,
    Query(page): Query<PageRequest>,
) -> ApiResult<Json<Vec<WithdrawalView>>> {
    Ok(Json(
        state.withdrawal_service.list(scope.store_id, page).await?,
    ))
}

pub async fn delete_withdrawal(
    State(state): State<AppState>,
    scope: StoreScope,
    Path((_store_id, withdrawal_id)): Path<(Uuid, Uuid)>,
) -> ApiResult<StatusCode> {
    state
        .withdrawal_service
        .remove(scope.store_id, withdrawal_id)
        .await?;
    Ok(StatusCode::NO_CONTENT)
}
