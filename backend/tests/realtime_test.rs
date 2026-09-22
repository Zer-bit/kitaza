#![cfg(feature = "integration")]

mod support;

use std::time::Duration;

use chrono::Utc;
use kitaza_server::infrastructure::realtime::RealtimeTopic;
use serde_json::json;
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
