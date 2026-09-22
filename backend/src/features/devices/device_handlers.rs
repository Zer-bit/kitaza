use axum::Json;
use axum::extract::{Path, State};
use axum::http::StatusCode;
use serde_json::json;
use uuid::Uuid;

use crate::application::AppState;
use crate::features::access::CurrentOwner;
use crate::features::audit::{AuditAction, AuditEntry};
use crate::shared::{ApiError, ApiResult};

use super::device_repository::DeviceView;

/// Every phone signed in to the owner's account or their stores, the one
/// asking included.
pub async fn list_devices(
    State(state): State<AppState>,
    CurrentOwner(owner): CurrentOwner,
) -> ApiResult<Json<Vec<DeviceView>>> {
    let mut devices = state.device_repository.list(owner.owner_id).await?;
    for device in &mut devices {
        device.is_current = device.id == owner.session_id;
    }
    Ok(Json(devices))
}

/// Signs a device out from elsewhere - a lost phone, a staff member who
/// left. It stops syncing on its next request and cannot refresh.
pub async fn revoke_device(
    State(state): State<AppState>,
    CurrentOwner(owner): CurrentOwner,
    Path(session_id): Path<Uuid>,
) -> ApiResult<StatusCode> {
    let revoked = state
        .device_repository
        .revoke(owner.owner_id, session_id)
        .await?
        .ok_or(ApiError::NotFound("device"))?;

    state.session_directory.forget_all();
    state
        .audit_trail
        .record(
            &owner,
            AuditEntry::account(
                revoked.store_id,
                AuditAction::DeviceSignedOut,
                session_id,
                json!({ "device": revoked.device_name, "name": revoked.member_name }),
            ),
        )
        .await;

    Ok(StatusCode::NO_CONTENT)
}
