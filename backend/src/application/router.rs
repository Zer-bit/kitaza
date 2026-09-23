use std::time::Duration;

use axum::Router;
use axum::http::{HeaderValue, Method, StatusCode, header};
use tower_http::compression::CompressionLayer;
use tower_http::cors::{Any, CorsLayer};
use tower_http::limit::RequestBodyLimitLayer;
use tower_http::timeout::TimeoutLayer;
use tower_http::trace::TraceLayer;

use crate::config::ServerSettings;
use crate::features::audit::audit_routes;
use crate::features::authentication::auth_routes;
use crate::features::benchmarks::benchmark_routes;
use crate::features::billing::{billing_pages, billing_routes};
use crate::features::dashboard::dashboard_routes;
use crate::features::devices::device_routes;
use crate::features::diagnostics::diagnostics_routes;
use crate::features::expenses::expense_routes;
use crate::features::health::health_routes;
use crate::features::inventory::inventory_routes;
use crate::features::products::product_routes;
use crate::features::reports::report_routes;
use crate::features::sales::sale_routes;
use crate::features::staff::staff_routes;
use crate::features::stores::store_routes;
use crate::features::sync::sync_routes;
use crate::features::withdrawals::withdrawal_routes;
use crate::infrastructure::realtime::realtime_routes;

use super::AppState;

const API_PREFIX: &str = "/api/v1";

pub fn build_router(state: AppState, settings: &ServerSettings) -> Router {
    let api = Router::new()
        .merge(auth_routes())
        .merge(billing_routes())
        .merge(benchmark_routes())
        .merge(store_routes())
        .merge(staff_routes())
        .merge(device_routes())
        .merge(audit_routes())
        .merge(product_routes())
        .merge(inventory_routes())
        .merge(sale_routes())
        .merge(expense_routes())
        .merge(withdrawal_routes())
        .merge(dashboard_routes())
        .merge(report_routes())
        .merge(sync_routes())
        .merge(diagnostics_routes());

    Router::new()
        .merge(health_routes())
        .merge(billing_pages())
        .merge(realtime_routes(settings.realtime_keepalive))
        .nest(API_PREFIX, api)
        .layer(CompressionLayer::new())
        .layer(TimeoutLayer::with_status_code(
            StatusCode::REQUEST_TIMEOUT,
            Duration::from_secs(settings.request_timeout_seconds),
        ))
        .layer(RequestBodyLimitLayer::new(settings.max_body_bytes))
        .layer(cors_layer(settings))
        .layer(TraceLayer::new_for_http())
        .with_state(state)
}

fn cors_layer(settings: &ServerSettings) -> CorsLayer {
    let base = CorsLayer::new()
        .allow_methods([
            Method::GET,
            Method::POST,
            Method::PATCH,
            Method::DELETE,
            Method::OPTIONS,
        ])
        .allow_headers([header::AUTHORIZATION, header::CONTENT_TYPE])
        .max_age(Duration::from_secs(3600));

    if settings.allows_any_origin() {
        return base.allow_origin(Any);
    }

    let origins: Vec<HeaderValue> = settings
        .allowed_origins
        .iter()
        .filter_map(|origin| origin.parse().ok())
        .collect();

    base.allow_origin(origins).allow_credentials(true)
}
