use axum::Router;
use axum::routing::{get, post};

use crate::application::AppState;

use super::billing_handlers;

/// Under `/api/v1`.
pub fn billing_routes() -> Router<AppState> {
    Router::new()
        .route("/billing", get(billing_handlers::overview))
        .route("/billing/checkout", post(billing_handlers::checkout))
        .route(
            "/billing/webhooks/paymongo",
            post(billing_handlers::paymongo_webhook),
        )
}

/// Plain pages for a phone's browser, outside the API prefix.
pub fn billing_pages() -> Router<AppState> {
    Router::new()
        .route("/billing/return", get(billing_handlers::checkout_return))
        .route(
            "/billing/test-checkout/{payment_id}",
            get(billing_handlers::test_checkout_page).post(billing_handlers::test_checkout_pay),
        )
}
