use axum::Router;
use axum::routing::get;

use crate::application::AppState;

use super::benchmark_handlers;

pub fn benchmark_routes() -> Router<AppState> {
    Router::new().route(
        "/stores/{store_id}/benchmarks",
        get(benchmark_handlers::compare),
    )
}
