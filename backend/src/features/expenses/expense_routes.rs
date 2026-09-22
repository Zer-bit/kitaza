use axum::Router;
use axum::routing::{delete, get};

use crate::application::AppState;

use super::expense_handlers;

pub fn expense_routes() -> Router<AppState> {
    Router::new()
        .route(
            "/expense-categories",
            get(expense_handlers::list_categories),
        )
        .route(
            "/stores/{store_id}/expenses",
            get(expense_handlers::list_expenses).post(expense_handlers::record_expense),
        )
        .route(
            "/stores/{store_id}/expenses/{expense_id}",
            delete(expense_handlers::delete_expense),
        )
}
