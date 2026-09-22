use axum::Router;
use axum::routing::get;

use crate::application::AppState;

use super::audit_handlers;

pub fn audit_routes() -> Router<AppState> {
    Router::new().route(
        "/stores/{store_id}/activity",
        get(audit_handlers::list_activity),
    )
}
