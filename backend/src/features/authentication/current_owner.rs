use axum::extract::FromRequestParts;
use axum::http::header::AUTHORIZATION;
use axum::http::request::Parts;
use uuid::Uuid;

use crate::application::AppState;
use crate::shared::ApiError;

/// Proof that the request carries a valid access token. Any handler that takes
/// this extractor is authenticated by construction.
#[derive(Debug, Clone, Copy)]
pub struct CurrentOwner {
    pub owner_id: Uuid,
}

impl FromRequestParts<AppState> for CurrentOwner {
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

        let claims = state.token_issuer.verify_access_token(token.trim())?;
        Ok(Self {
            owner_id: claims.owner_id(),
        })
    }
}
