use axum::Router;
use axum::routing::get;

use crate::application::AppState;

use super::report_handlers;

pub fn report_routes() -> Router<AppState> {
    Router::new()
        .route(
            "/stores/{store_id}/reports/summary",
            get(report_handlers::periodic_summary),
        )
        .route(
            "/stores/{store_id}/reports/profit-trend",
            get(report_handlers::profit_trend),
        )
        .route(
            "/stores/{store_id}/reports/top-products",
            get(report_handlers::top_products),
        )
        .route(
            "/stores/{store_id}/reports/expense-breakdown",
            get(report_handlers::expense_breakdown),
        )
        .route(
            "/stores/{store_id}/reports/unusual-expenses",
            get(report_handlers::unusual_expenses),
        )
}
