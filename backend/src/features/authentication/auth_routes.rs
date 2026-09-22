use axum::Router;
use axum::routing::{get, post};

use crate::application::AppState;

use super::auth_handlers;

pub fn auth_routes() -> Router<AppState> {
    Router::new()
        .route("/auth/register", post(auth_handlers::register))
        .route("/auth/login", post(auth_handlers::login))
        .route("/auth/refresh", post(auth_handlers::refresh))
        .route("/auth/logout", post(auth_handlers::logout))
        .route("/auth/me", get(auth_handlers::current_profile))
}
