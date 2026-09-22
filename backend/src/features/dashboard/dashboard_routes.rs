use axum::Router;
use axum::routing::get;

use crate::application::AppState;

use super::dashboard_handlers;

pub fn dashboard_routes() -> Router<AppState> {
    Router::new().route(
        "/stores/{store_id}/dashboard",
        get(dashboard_handlers::store_summary),
    )
}
