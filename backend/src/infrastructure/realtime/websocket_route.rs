use std::time::Duration;

use axum::Router;
use axum::extract::ws::{Message, WebSocket, WebSocketUpgrade};
use axum::extract::{Extension, Query, State};
use axum::response::Response;
use axum::routing::get;
use serde::Deserialize;
use tokio::sync::broadcast::error::RecvError;
use uuid::Uuid;

use crate::application::AppState;
use crate::features::access::actor_for_token;
use crate::features::stores::authorise;
use crate::shared::{ApiError, ApiResult};

/// How often an open socket is pinged and its device re-checked.
#[derive(Clone, Copy)]
pub struct KeepaliveInterval(pub Duration);

#[derive(Deserialize)]
struct RealtimeQuery {
    /// Browsers cannot attach headers to a websocket handshake, so the access
    /// token travels as a query parameter over TLS.
    token: String,
}

pub fn realtime_routes(keepalive: Duration) -> Router<AppState> {
    Router::new()
        .route("/ws/store/{store_id}", get(upgrade_connection))
        .layer(Extension(KeepaliveInterval(keepalive)))
}

async fn upgrade_connection(
    upgrade: WebSocketUpgrade,
    State(state): State<AppState>,
    axum::extract::Path(store_id): axum::extract::Path<Uuid>,
    Query(query): Query<RealtimeQuery>,
    Extension(keepalive): Extension<KeepaliveInterval>,
) -> ApiResult<Response> {
    let actor = actor_for_token(&state, &query.token).await?;

    authorise(&state, &actor, store_id)
        .await
        .map_err(|_| ApiError::Forbidden("this store does not belong to you".into()))?;
    state
        .billing_service
        .check_store_request(&actor, store_id, false)
        .await?;

    let session_id = actor.session_id;
    Ok(upgrade
        .on_upgrade(move |socket| pump_events(socket, state, store_id, session_id, keepalive.0)))
}

async fn pump_events(
    mut socket: WebSocket,
    state: AppState,
    store_id: Uuid,
    session_id: Uuid,
    keepalive_interval: Duration,
) {
    let mut events = state.broadcaster.subscribe(store_id);
    let mut keepalive = tokio::time::interval(keepalive_interval);

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
                // A socket outlives the check made when it opened. A device
                // signed out since then stops hearing the store's events.
                if !matches!(state.session_directory.resolve(session_id).await, Ok(Some(_))) {
                    let _ = socket.send(Message::Close(None)).await;
                    break;
                }
                if socket.send(Message::Ping(Vec::new().into())).await.is_err() {
                    break;
                }
            }
        }
    }

    tracing::debug!(%store_id, "realtime socket closed");
}
