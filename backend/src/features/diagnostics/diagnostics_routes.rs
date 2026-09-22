use axum::Router;
use axum::routing::post;

use crate::application::AppState;

use super::diagnostics_handlers;

pub fn diagnostics_routes() -> Router<AppState> {
    Router::new().route(
        "/diagnostics/errors",
        post(diagnostics_handlers::report_errors),
    )
}
