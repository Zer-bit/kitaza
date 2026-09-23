#![cfg(feature = "integration")]

mod support;

use std::time::Duration;

use axum::http::{Method, StatusCode};
use chrono::Utc;
use kitaza_server::infrastructure::realtime::RealtimeTopic;
use serde_json::{Value, json};
use sqlx::PgPool;
use support::{TestApp, product, sale};
use uuid::Uuid;

#[sqlx::test(migrations = "./migrations")]
async fn a_synced_sale_is_announced_to_the_stores_listeners(pool: PgPool) {
    let app = TestApp::new(pool);
    let owner = app.register("realtime@example.com").await;
    let other = app.register("elsewhere@example.com").await;

    // What a connected phone's websocket is subscribed to.
    let mut listener = app.state.broadcaster.subscribe(owner.store_id);
    let mut other_listener = app.state.broadcaster.subscribe(other.store_id);

    let product_id = Uuid::new_v4();
    let sale_id = Uuid::new_v4();
    app.push(
        &owner,
        json!({
            "products": [product(product_id, "Kape")],
            "sales": [sale(sale_id, product_id, 1.0, Utc::now())],
        }),
    )
    .await;

    let mut topics = Vec::new();
    while let Ok(Ok(event)) =
        tokio::time::timeout(Duration::from_millis(200), listener.recv()).await
    {
        topics.push((event.topic, event.entity_id));
    }

    assert!(topics.contains(&(RealtimeTopic::SaleRecorded, Some(sale_id))));
    assert!(
        other_listener.try_recv().is_err(),
        "another store must not hear about this sale"
    );
}

/// Everything above proves the broadcaster fans events out. These prove the
/// socket that carries them to a phone: the handshake, who is let through,
/// what arrives, and when the server hangs up.
mod over_a_real_socket {
    use futures_util::{SinkExt, StreamExt};
    use tokio_tungstenite::connect_async;
    use tokio_tungstenite::tungstenite::Message;

    use super::*;

    /// Reads frames until one is a JSON event, or the wait runs out.
    async fn next_event<S>(socket: &mut S) -> Option<Value>
    where
        S: StreamExt<Item = Result<Message, tokio_tungstenite::tungstenite::Error>> + Unpin,
    {
        let deadline = tokio::time::Instant::now() + Duration::from_secs(5);
        while let Ok(Some(Ok(frame))) = tokio::time::timeout_at(deadline, socket.next()).await {
            if let Message::Text(text) = frame {
                return serde_json::from_str(&text).ok();
            }
        }
        None
    }

    #[sqlx::test(migrations = "./migrations")]
    async fn a_sale_reaches_the_phone_that_is_listening(pool: PgPool) {
        let app = TestApp::new(pool);
        let owner = app.register("socket@example.com").await;
        let served = app.serve().await;

        let (mut socket, response) = connect_async(served.socket_url(owner.store_id, &owner.token))
            .await
            .expect("the handshake should be accepted");
        assert_eq!(response.status().as_u16(), 101, "a real upgrade");

        let product_id = Uuid::new_v4();
        let sale_id = Uuid::new_v4();
        app.push(
            &owner,
            json!({
                "products": [product(product_id, "Kape")],
                "sales": [sale(sale_id, product_id, 1.0, Utc::now())],
            }),
        )
        .await;

        let mut seen = Vec::new();
        while let Some(event) = next_event(&mut socket).await {
            seen.push(event["topic"].as_str().unwrap_or_default().to_owned());
            if seen.iter().any(|topic| topic == "sale_recorded") {
                break;
            }
        }
        assert!(
            seen.iter().any(|topic| topic == "sale_recorded"),
            "the phone should have been told about the sale, got {seen:?}"
        );
    }

    #[sqlx::test(migrations = "./migrations")]
    async fn a_made_up_token_never_gets_a_socket(pool: PgPool) {
        let app = TestApp::new(pool);
        let owner = app.register("socket@example.com").await;
        let served = app.serve().await;

        let refused = connect_async(served.socket_url(owner.store_id, "not-a-token")).await;

        assert!(refused.is_err(), "an unsigned token must not open a socket");
    }

    #[sqlx::test(migrations = "./migrations")]
    async fn a_phone_cannot_listen_to_someone_elses_store(pool: PgPool) {
        let app = TestApp::new(pool);
        let owner = app.register("mine@example.com").await;
        let stranger = app.register("theirs@example.com").await;
        let served = app.serve().await;

        let refused = connect_async(served.socket_url(stranger.store_id, &owner.token)).await;

        assert!(
            refused.is_err(),
            "one owner must not hear another store's sales"
        );
    }

    #[sqlx::test(migrations = "./migrations")]
    async fn a_phone_signed_out_since_it_connected_is_hung_up_on(pool: PgPool) {
        // The check that lets a phone in happens once, when it connects. A
        // socket outlives it, so the owner revoking a lost phone has to reach
        // a connection that is already open.
        let app = TestApp::with_brisk_keepalive(pool);
        let owner = app.register("owner@example.com").await;
        let lost = app.sign_in("owner@example.com", "Lost phone").await;
        let served = app.serve().await;

        let (mut socket, _) = connect_async(served.socket_url(lost.store_id, &lost.token))
            .await
            .expect("the lost phone connects while it is still trusted");

        let (status, _) = app
            .call(
                Method::DELETE,
                &format!("/devices/{}", lost.session_id),
                Some(&owner.token),
                None,
            )
            .await;
        assert_eq!(status, StatusCode::NO_CONTENT);

        let deadline = tokio::time::Instant::now() + Duration::from_secs(5);
        let mut hung_up = false;
        while let Ok(frame) = tokio::time::timeout_at(deadline, socket.next()).await {
            match frame {
                Some(Ok(Message::Close(_))) | None => {
                    hung_up = true;
                    break;
                }
                Some(Err(_)) => {
                    hung_up = true;
                    break;
                }
                Some(Ok(_)) => continue,
            }
        }
        assert!(
            hung_up,
            "a revoked phone must stop hearing the store within a keepalive"
        );
    }

    #[sqlx::test(migrations = "./migrations")]
    async fn a_phone_that_hangs_up_does_not_take_the_server_with_it(pool: PgPool) {
        let app = TestApp::new(pool);
        let owner = app.register("socket@example.com").await;
        let served = app.serve().await;

        let (mut socket, _) = connect_async(served.socket_url(owner.store_id, &owner.token))
            .await
            .unwrap();
        socket.send(Message::Close(None)).await.unwrap();
        drop(socket);

        // The same phone reconnecting is the ordinary case after a tunnel
        // drops, and it has to be served as if nothing happened.
        let (mut again, _) = connect_async(served.socket_url(owner.store_id, &owner.token))
            .await
            .expect("reconnecting after a drop");

        let product_id = Uuid::new_v4();
        app.push(
            &owner,
            json!({
                "products": [product(product_id, "Kape")],
                "sales": [sale(Uuid::new_v4(), product_id, 1.0, Utc::now())],
            }),
        )
        .await;

        assert!(
            next_event(&mut again).await.is_some(),
            "the reconnected phone should hear the store again"
        );
    }
}
