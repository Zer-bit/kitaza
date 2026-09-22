use axum::Json;
use axum::Router;
use axum::extract::State;
use axum::http::StatusCode;
use axum::routing::get;
use serde::Serialize;

use crate::application::AppState;

#[derive(Serialize)]
struct HealthReport {
    status: &'static str,
    version: &'static str,
    database: &'static str,
    cache: &'static str,
}

pub fn health_routes() -> Router<AppState> {
    Router::new()
        .route("/health", get(liveness))
        .route("/health/ready", get(readiness))
}

async fn liveness() -> &'static str {
    "ok"
}

/// Readiness checks the database because the API is useless without it. Redis
/// is reported but never fails the probe: the server degrades gracefully.
async fn readiness(State(state): State<AppState>) -> (StatusCode, Json<HealthReport>) {
    let database_up = sqlx::query_scalar::<_, i32>("SELECT 1")
        .fetch_one(&state.pool)
        .await
        .is_ok();

    let status_code = if database_up {
        StatusCode::OK
    } else {
        StatusCode::SERVICE_UNAVAILABLE
    };

    (
        status_code,
        Json(HealthReport {
            status: if database_up { "ready" } else { "degraded" },
            version: env!("CARGO_PKG_VERSION"),
            database: if database_up { "up" } else { "down" },
            cache: if state.cache_enabled {
                "up"
            } else {
                "disabled"
            },
        }),
    )
}
