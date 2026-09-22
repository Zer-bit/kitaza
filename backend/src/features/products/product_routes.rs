use axum::Router;
use axum::routing::get;

use crate::application::AppState;

use super::product_handlers;

pub fn product_routes() -> Router<AppState> {
    Router::new()
        .route(
            "/stores/{store_id}/products",
            get(product_handlers::list_products).post(product_handlers::save_product),
        )
        .route(
            "/stores/{store_id}/products/low-stock",
            get(product_handlers::low_stock_products),
        )
        .route(
            "/stores/{store_id}/products/{product_id}",
            get(product_handlers::get_product).delete(product_handlers::delete_product),
        )
}
