use axum::Router;
use axum::routing::{delete, get};

use crate::application::AppState;

use super::device_handlers;

pub fn device_routes() -> Router<AppState> {
    Router::new()
        .route("/devices", get(device_handlers::list_devices))
        .route(
            "/devices/{session_id}",
            delete(device_handlers::revoke_device),
        )
}
