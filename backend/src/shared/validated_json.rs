use axum::Json;
use axum::extract::{FromRequest, Request};
use serde::de::DeserializeOwned;
use validator::Validate;

use super::ApiError;

/// `Json<T>` that runs `validator` rules before the handler sees the body, so
/// handlers only ever deal with well-formed input.
pub struct ValidatedJson<T>(pub T);

impl<S, T> FromRequest<S> for ValidatedJson<T>
where
    S: Send + Sync,
    T: DeserializeOwned + Validate + 'static,
{
    type Rejection = ApiError;

    async fn from_request(request: Request, state: &S) -> Result<Self, Self::Rejection> {
        let Json(payload) = Json::<T>::from_request(request, state)
            .await
            .map_err(|rejection| ApiError::BadRequest(rejection.body_text()))?;

        payload
            .validate()
            .map_err(|errors| ApiError::BadRequest(summarise(&errors)))?;

        Ok(Self(payload))
    }
}

fn summarise(errors: &validator::ValidationErrors) -> String {
    errors
        .field_errors()
        .iter()
        .map(|(field, issues)| {
            let detail = issues
                .first()
                .and_then(|issue| issue.message.clone())
                .map(|message| message.to_string())
                .unwrap_or_else(|| "is invalid".to_owned());
            format!("{field} {detail}")
        })
        .collect::<Vec<_>>()
        .join(", ")
}
