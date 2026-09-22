use axum::extract::FromRequestParts;
use axum::http::header::AUTHORIZATION;
use axum::http::request::Parts;

use crate::application::AppState;
use crate::shared::{ApiError, ApiResult};

use super::actor::Actor;

/// Proof that the request comes from a live session. Any handler that takes
/// this extractor is authenticated by construction.
#[derive(Debug, Clone)]
pub struct CurrentActor(pub Actor);

/// The same, restricted to the account owner: staff get a 403.
#[derive(Debug, Clone)]
pub struct CurrentOwner(pub Actor);

impl FromRequestParts<AppState> for CurrentActor {
    type Rejection = ApiError;

    async fn from_request_parts(
        parts: &mut Parts,
        state: &AppState,
    ) -> Result<Self, Self::Rejection> {
        let header = parts
            .headers
            .get(AUTHORIZATION)
            .and_then(|value| value.to_str().ok())
            .ok_or_else(|| ApiError::Unauthorized("missing authorization header".into()))?;

        let token = header
            .strip_prefix("Bearer ")
            .ok_or_else(|| ApiError::Unauthorized("expected a bearer token".into()))?;

        Ok(Self(actor_for_token(state, token.trim()).await?))
    }
}

impl FromRequestParts<AppState> for CurrentOwner {
    type Rejection = ApiError;

    async fn from_request_parts(
        parts: &mut Parts,
        state: &AppState,
    ) -> Result<Self, Self::Rejection> {
        let CurrentActor(actor) = CurrentActor::from_request_parts(parts, state).await?;
        actor.require_owner()?;
        Ok(Self(actor))
    }
}

/// Shared with the websocket handshake, which carries its token in the query
/// string instead of a header.
pub async fn actor_for_token(state: &AppState, token: &str) -> ApiResult<Actor> {
    let claims = state.token_issuer.verify_access_token(token)?;

    state
        .session_directory
        .resolve(claims.session_id())
        .await?
        .ok_or_else(|| ApiError::Unauthorized("this device was signed out".into()))
}
