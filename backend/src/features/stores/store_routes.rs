use axum::Router;
use axum::routing::{patch, post};

use crate::application::AppState;

use super::store_handlers;

pub fn store_routes() -> Router<AppState> {
    Router::new()
        .route("/stores", post(store_handlers::create_store))
        .route("/stores/{store_id}", patch(store_handlers::update_store))
}
