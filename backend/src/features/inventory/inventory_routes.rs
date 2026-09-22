use axum::Router;
use axum::routing::get;

use crate::application::AppState;

use super::inventory_handlers;

pub fn inventory_routes() -> Router<AppState> {
    Router::new()
        .route(
            "/stores/{store_id}/stock-movements",
            get(inventory_handlers::list_movements).post(inventory_handlers::record_movement),
        )
        .route(
            "/stores/{store_id}/inventory/valuation",
            get(inventory_handlers::inventory_valuation),
        )
}
