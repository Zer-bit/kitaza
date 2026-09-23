use axum::Router;
use axum::routing::{get, post};

use crate::application::AppState;

use super::privacy_handlers;

pub fn privacy_routes() -> Router<AppState> {
    Router::new()
        .route("/account/privacy", get(privacy_handlers::privacy_state))
        .route("/account/consent", post(privacy_handlers::record_consent))
        .route("/account/export", get(privacy_handlers::export_account))
        .route(
            "/account/deletion",
            post(privacy_handlers::request_deletion).delete(privacy_handlers::cancel_deletion),
        )
}
