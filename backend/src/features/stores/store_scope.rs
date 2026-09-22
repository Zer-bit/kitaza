use std::collections::HashMap;

use axum::extract::{FromRequestParts, Path};
use axum::http::request::Parts;
use uuid::Uuid;

use crate::application::AppState;
use crate::features::access::{Actor, CurrentActor};
use crate::shared::ApiError;

/// Resolves `/stores/{store_id}/...` and verifies access in one step, so no
/// handler can forget the check. Owners reach any store they own; staff only
/// the one store they were added to.
#[derive(Debug, Clone)]
pub struct StoreScope {
    pub store_id: Uuid,
    pub actor: Actor,
}

impl FromRequestParts<AppState> for StoreScope {
    type Rejection = ApiError;

    async fn from_request_parts(
        parts: &mut Parts,
        state: &AppState,
    ) -> Result<Self, Self::Rejection> {
        let CurrentActor(actor) = CurrentActor::from_request_parts(parts, state).await?;

        // Extracted as a map because nested routes carry extra path segments
        // such as the product or sale id.
        let Path(segments) = Path::<HashMap<String, String>>::from_request_parts(parts, state)
            .await
            .map_err(|_| ApiError::BadRequest("a valid store id is required".into()))?;

        let store_id = segments
            .get("store_id")
            .and_then(|raw| Uuid::parse_str(raw).ok())
            .ok_or_else(|| ApiError::BadRequest("a valid store id is required".into()))?;

        authorise(state, &actor, store_id).await?;

        Ok(Self { store_id, actor })
    }
}

pub async fn authorise(state: &AppState, actor: &Actor, store_id: Uuid) -> Result<(), ApiError> {
    match actor.staff {
        Some(grant) if grant.store_id == store_id => Ok(()),
        Some(_) => Err(ApiError::Forbidden(
            "this store does not belong to you".into(),
        )),
        None => {
            state
                .store_directory
                .assert_owner_of(actor.owner_id, store_id)
                .await
        }
    }
}
