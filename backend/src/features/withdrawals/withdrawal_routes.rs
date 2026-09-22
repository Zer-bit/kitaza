use axum::Router;
use axum::routing::{delete, get};

use crate::application::AppState;

use super::withdrawal_handlers;

pub fn withdrawal_routes() -> Router<AppState> {
    Router::new()
        .route(
            "/stores/{store_id}/withdrawals",
            get(withdrawal_handlers::list_withdrawals).post(withdrawal_handlers::record_withdrawal),
        )
        .route(
            "/stores/{store_id}/withdrawals/{withdrawal_id}",
            delete(withdrawal_handlers::delete_withdrawal),
        )
}
