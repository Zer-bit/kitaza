use axum::Json;
use axum::extract::State;
use axum::http::StatusCode;

use crate::application::AppState;
use crate::features::access::CurrentActor;
use crate::shared::{ApiResult, ValidatedJson};

use super::auth_payloads::{
    AccountView, AuthenticatedSession, JoinRequest, LoginRequest, RefreshRequest, RegisterRequest,
};

pub async fn register(
    State(state): State<AppState>,
    ValidatedJson(request): ValidatedJson<RegisterRequest>,
) -> ApiResult<(StatusCode, Json<AuthenticatedSession>)> {
    let session = state.auth_service.register(request).await?;
    Ok((StatusCode::CREATED, Json(session)))
}

pub async fn login(
    State(state): State<AppState>,
    ValidatedJson(request): ValidatedJson<LoginRequest>,
) -> ApiResult<Json<AuthenticatedSession>> {
    Ok(Json(state.auth_service.login(request).await?))
}

pub async fn join(
    State(state): State<AppState>,
    ValidatedJson(request): ValidatedJson<JoinRequest>,
) -> ApiResult<Json<AuthenticatedSession>> {
    Ok(Json(state.auth_service.join(request).await?))
}

pub async fn refresh(
    State(state): State<AppState>,
    ValidatedJson(request): ValidatedJson<RefreshRequest>,
) -> ApiResult<Json<AuthenticatedSession>> {
    Ok(Json(
        state.auth_service.refresh(&request.refresh_token).await?,
    ))
}

pub async fn logout(
    State(state): State<AppState>,
    ValidatedJson(request): ValidatedJson<RefreshRequest>,
) -> ApiResult<StatusCode> {
    state.auth_service.logout(&request.refresh_token).await?;
    Ok(StatusCode::NO_CONTENT)
}

/// Who this device is signed in as, and what it may do. Devices re-read this
/// so a permission the owner changed takes effect without signing out.
pub async fn current_account(
    State(state): State<AppState>,
    CurrentActor(actor): CurrentActor,
) -> ApiResult<Json<AccountView>> {
    Ok(Json(state.auth_service.account(&actor).await?))
}
