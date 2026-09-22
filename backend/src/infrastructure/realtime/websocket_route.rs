use std::time::Duration;

use axum::Router;
use axum::extract::ws::{Message, WebSocket, WebSocketUpgrade};
use axum::extract::{Query, State};
use axum::response::Response;
use axum::routing::get;
use serde::Deserialize;
use tokio::sync::broadcast::error::RecvError;
use uuid::Uuid;

use crate::application::AppState;
use crate::shared::{ApiError, ApiResult};

const KEEPALIVE_INTERVAL: Duration = Duration::from_secs(25);

#[derive(Deserialize)]
struct RealtimeQuery {
    /// Browsers cannot attach headers to a websocket handshake, so the access
    /// token travels as a query parameter over TLS.
    token: String,
}

pub fn realtime_routes() -> Router<AppState> {
    Router::new().route("/ws/store/{store_id}", get(upgrade_connection))
}

async fn upgrade_connection(
    upgrade: WebSocketUpgrade,
    State(state): State<AppState>,
    axum::extract::Path(store_id): axum::extract::Path<Uuid>,
    Query(query): Query<RealtimeQuery>,
) -> ApiResult<Response> {
    let claims = state.token_issuer.verify_access_token(&query.token)?;

    state
        .store_directory
        .assert_owner_of(claims.owner_id(), store_id)
        .await
        .map_err(|_| ApiError::Forbidden("this store does not belong to you".into()))?;

    Ok(upgrade.on_upgrade(move |socket| pump_events(socket, state, store_id)))
}

async fn pump_events(mut socket: WebSocket, state: AppState, store_id: Uuid) {
    let mut events = state.broadcaster.subscribe(store_id);
    let mut keepalive = tokio::time::interval(KEEPALIVE_INTERVAL);

    loop {
        tokio::select! {
            incoming = socket.recv() => match incoming {
                Some(Ok(Message::Close(_))) | None => break,
                Some(Err(_)) => break,
                Some(Ok(_)) => continue,
            },
            event = events.recv() => match event {
                Ok(event) => {
                    let Ok(payload) = serde_json::to_string(&event) else { continue };
                    if socket.send(Message::Text(payload.into())).await.is_err() {
                        break;
                    }
                }
                // A slow client that fell behind is told to resynchronise
                // rather than silently missing writes.
                Err(RecvError::Lagged(_)) => {
                    let _ = socket.send(Message::Text("{\"topic\":\"dashboard_stale\"}".into())).await;
                }
                Err(RecvError::Closed) => break,
            },
            _ = keepalive.tick() => {
                if socket.send(Message::Ping(Vec::new().into())).await.is_err() {
                    break;
                }
            }
        }
    }

    tracing::debug!(%store_id, "realtime socket closed");
}
