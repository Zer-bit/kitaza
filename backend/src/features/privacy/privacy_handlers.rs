use axum::Json;
use axum::extract::State;
use axum::http::StatusCode;

use crate::application::AppState;
use crate::features::access::CurrentOwner;
use crate::shared::{ApiResult, ValidatedJson};

use super::privacy_payloads::{AccountExport, DeletionState, PrivacyState, RecordConsentRequest};

pub async fn privacy_state(
    State(state): State<AppState>,
    CurrentOwner(actor): CurrentOwner,
) -> ApiResult<Json<PrivacyState>> {
    Ok(Json(state.privacy_service.state(actor.owner_id).await?))
}

pub async fn record_consent(
    State(state): State<AppState>,
    CurrentOwner(actor): CurrentOwner,
    ValidatedJson(request): ValidatedJson<RecordConsentRequest>,
) -> ApiResult<StatusCode> {
    state
        .privacy_service
        .record(actor.owner_id, request.document, &request.version)
        .await?;
    Ok(StatusCode::NO_CONTENT)
}

/// Everything the server holds about this account, as one JSON file.
pub async fn export_account(
    State(state): State<AppState>,
    CurrentOwner(actor): CurrentOwner,
) -> ApiResult<Json<AccountExport>> {
    Ok(Json(state.privacy_service.export(actor.owner_id).await?))
}

pub async fn request_deletion(
    State(state): State<AppState>,
    CurrentOwner(actor): CurrentOwner,
) -> ApiResult<Json<DeletionState>> {
    Ok(Json(
        state
            .privacy_service
            .request_deletion(actor.owner_id)
            .await?,
    ))
}

pub async fn cancel_deletion(
    State(state): State<AppState>,
    CurrentOwner(actor): CurrentOwner,
) -> ApiResult<StatusCode> {
    state
        .privacy_service
        .cancel_deletion(actor.owner_id)
        .await?;
    Ok(StatusCode::NO_CONTENT)
}
