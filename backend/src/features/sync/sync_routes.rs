use axum::Router;
use axum::routing::{get, post};

use crate::application::AppState;

use super::sync_handlers;

pub fn sync_routes() -> Router<AppState> {
    Router::new()
        .route(
            "/stores/{store_id}/sync/push",
            post(sync_handlers::push_changes),
        )
        .route(
            "/stores/{store_id}/sync/pull",
            get(sync_handlers::pull_changes),
        )
}
