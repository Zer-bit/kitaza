use axum::Router;
use axum::routing::get;

use crate::application::AppState;

use super::sale_handlers;

pub fn sale_routes() -> Router<AppState> {
    Router::new()
        .route(
            "/stores/{store_id}/sales",
            get(sale_handlers::list_sales).post(sale_handlers::record_sale),
        )
        .route(
            "/stores/{store_id}/sales/{sale_id}",
            get(sale_handlers::get_sale).delete(sale_handlers::void_sale),
        )
}
