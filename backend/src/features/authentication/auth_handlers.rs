use axum::Json;
use axum::extract::State;
use axum::http::StatusCode;

use crate::application::AppState;
use crate::shared::{ApiResult, ValidatedJson};

use super::auth_payloads::{
    AuthenticatedSession, LoginRequest, OwnerProfile, RefreshRequest, RegisterRequest, StoreSummary,
};
use super::current_owner::CurrentOwner;

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

#[derive(serde::Serialize)]
pub struct ProfileResponse {
    owner: OwnerProfile,
    stores: Vec<StoreSummary>,
}

pub async fn current_profile(
    State(state): State<AppState>,
    owner: CurrentOwner,
) -> ApiResult<Json<ProfileResponse>> {
    let (profile, stores) = state.auth_service.profile(owner.owner_id).await?;
    Ok(Json(ProfileResponse {
        owner: profile,
        stores,
    }))
}
