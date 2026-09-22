use axum::Json;
use axum::extract::{Query, State};

use crate::application::AppState;
use crate::features::stores::StoreScope;
use crate::shared::{ApiResult, ValidatedJson};

use super::sync_payloads::{PullQuery, PullResponse, PushOutcome, PushRequest};

pub async fn push_changes(
    State(state): State<AppState>,
    scope: StoreScope,
    ValidatedJson(request): ValidatedJson<PushRequest>,
) -> ApiResult<Json<PushOutcome>> {
    Ok(Json(
        state.sync_service.push(scope.store_id, request).await?,
    ))
}

pub async fn pull_changes(
    State(state): State<AppState>,
    scope: StoreScope,
    Query(query): Query<PullQuery>,
) -> ApiResult<Json<PullResponse>> {
    Ok(Json(state.sync_service.pull(scope.store_id, query).await?))
}
