use axum::Json;
use axum::extract::{Path, State};
use axum::http::StatusCode;
use uuid::Uuid;

use crate::application::AppState;
use crate::features::stores::StoreScope;
use crate::shared::{ApiResult, ValidatedJson};

use super::staff_payloads::{AddedStaff, InviteView, SaveStaffRequest, StaffView};

pub async fn list_staff(
    State(state): State<AppState>,
    scope: StoreScope,
) -> ApiResult<Json<Vec<StaffView>>> {
    scope.actor.require_owner()?;
    Ok(Json(state.staff_service.list(scope.store_id).await?))
}

pub async fn add_staff(
    State(state): State<AppState>,
    scope: StoreScope,
    ValidatedJson(request): ValidatedJson<SaveStaffRequest>,
) -> ApiResult<(StatusCode, Json<AddedStaff>)> {
    scope.actor.require_owner()?;
    let added = state
        .staff_service
        .add(scope.store_id, &scope.actor, request)
        .await?;
    Ok((StatusCode::CREATED, Json(added)))
}

pub async fn update_staff(
    State(state): State<AppState>,
    scope: StoreScope,
    Path((_store_id, staff_id)): Path<(Uuid, Uuid)>,
    ValidatedJson(request): ValidatedJson<SaveStaffRequest>,
) -> ApiResult<Json<StaffView>> {
    scope.actor.require_owner()?;
    Ok(Json(
        state
            .staff_service
            .update(scope.store_id, &scope.actor, staff_id, request)
            .await?,
    ))
}

pub async fn remove_staff(
    State(state): State<AppState>,
    scope: StoreScope,
    Path((_store_id, staff_id)): Path<(Uuid, Uuid)>,
) -> ApiResult<StatusCode> {
    scope.actor.require_owner()?;
    state
        .staff_service
        .remove(scope.store_id, &scope.actor, staff_id)
        .await?;
    Ok(StatusCode::NO_CONTENT)
}

pub async fn reinvite_staff(
    State(state): State<AppState>,
    scope: StoreScope,
    Path((_store_id, staff_id)): Path<(Uuid, Uuid)>,
) -> ApiResult<(StatusCode, Json<InviteView>)> {
    scope.actor.require_owner()?;
    let invite = state
        .staff_service
        .reinvite(scope.store_id, &scope.actor, staff_id)
        .await?;
    Ok((StatusCode::CREATED, Json(invite)))
}
