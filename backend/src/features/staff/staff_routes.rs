use axum::Router;
use axum::routing::{get, patch, post};

use crate::application::AppState;

use super::staff_handlers;

pub fn staff_routes() -> Router<AppState> {
    Router::new()
        .route(
            "/stores/{store_id}/staff",
            get(staff_handlers::list_staff).post(staff_handlers::add_staff),
        )
        .route(
            "/stores/{store_id}/staff/{staff_id}",
            patch(staff_handlers::update_staff).delete(staff_handlers::remove_staff),
        )
        .route(
            "/stores/{store_id}/staff/{staff_id}/invite",
            post(staff_handlers::reinvite_staff),
        )
}
