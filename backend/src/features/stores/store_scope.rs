use std::collections::HashMap;

use axum::extract::{FromRequestParts, Path};
use axum::http::request::Parts;
use uuid::Uuid;

use crate::application::AppState;
use crate::features::authentication::CurrentOwner;
use crate::shared::ApiError;

/// Resolves `/stores/{store_id}/...` and verifies ownership in one step, so no
/// handler can forget the check.
#[derive(Debug, Clone, Copy)]
pub struct StoreScope {
    pub store_id: Uuid,
}

impl FromRequestParts<AppState> for StoreScope {
    type Rejection = ApiError;

    async fn from_request_parts(
        parts: &mut Parts,
        state: &AppState,
    ) -> Result<Self, Self::Rejection> {
        let owner = CurrentOwner::from_request_parts(parts, state).await?;

        // Extracted as a map because nested routes carry extra path segments
        // such as the product or sale id.
        let Path(segments) = Path::<HashMap<String, String>>::from_request_parts(parts, state)
            .await
            .map_err(|_| ApiError::BadRequest("a valid store id is required".into()))?;

        let store_id = segments
            .get("store_id")
            .and_then(|raw| Uuid::parse_str(raw).ok())
            .ok_or_else(|| ApiError::BadRequest("a valid store id is required".into()))?;

        state
            .store_directory
            .assert_owner_of(owner.owner_id, store_id)
            .await?;

        Ok(Self { store_id })
    }
}
