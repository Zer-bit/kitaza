#![cfg(feature = "integration")]

mod support;

use axum::http::{Method, StatusCode};
use chrono::{Duration, Utc};
use serde_json::json;
use sqlx::PgPool;
use support::{TestApp, movement, product, sale};
use uuid::Uuid;

#[sqlx::test(migrations = "./migrations")]
async fn replaying_a_batch_changes_nothing_the_second_time(pool: PgPool) {
    let app = TestApp::new(pool);
    let owner = app.register("replay@example.com").await;
    let product_id = Uuid::new_v4();
    let start = Utc::now() - Duration::hours(1);

    let batch = json!({
        "products": [product(product_id, "Coke")],
        "stock_movements": [movement(Uuid::new_v4(), product_id, "stock_in", 24.0, start)],
        "sales": [sale(Uuid::new_v4(), product_id, 3.0, start + Duration::minutes(5))],
    });

    // A phone that loses signal after the server commits, but before it hears
    // back, sends exactly this batch again.
    app.push(&owner, batch.clone()).await;
    let second = app.push(&owner, batch).await;

    assert_eq!(second["rejected"], json!([]));
    assert_eq!(app.stock_of(&owner, product_id).await, 21.0);

    let (movements,): (i64,) =
        sqlx::query_as("SELECT COUNT(*) FROM stock_movements WHERE movement = 'stock_in'")
            .fetch_one(&app.pool)
            .await
            .unwrap();
    assert_eq!(
        movements, 1,
        "the ledger must not record the stock-in twice"
    );
}

#[sqlx::test(migrations = "./migrations")]
async fn a_stock_count_lands_in_the_order_it_happened(pool: PgPool) {
    let app = TestApp::new(pool);
    let owner = app.register("timeline@example.com").await;
    let product_id = Uuid::new_v4();
    let t = Utc::now() - Duration::hours(2);

    // Sent deliberately out of order: the device lists sales before counts,
    // but the owner sold 2, then counted 10 on the shelf, then sold 1 more.
    app.push(
        &owner,
        json!({
            "products": [product(product_id, "Rice 1kg")],
            "sales": [
                sale(Uuid::new_v4(), product_id, 1.0, t + Duration::minutes(30)),
                sale(Uuid::new_v4(), product_id, 2.0, t + Duration::minutes(10)),
            ],
            "stock_movements": [
                movement(Uuid::new_v4(), product_id, "stock_in", 20.0, t),
                movement(Uuid::new_v4(), product_id, "adjustment", 10.0, t + Duration::minutes(20)),
            ],
        }),
    )
    .await;

    assert_eq!(app.stock_of(&owner, product_id).await, 9.0);
}

#[sqlx::test(migrations = "./migrations")]
async fn a_counted_total_of_zero_is_allowed(pool: PgPool) {
    let app = TestApp::new(pool);
    let owner = app.register("zero@example.com").await;
    let product_id = Uuid::new_v4();
    let t = Utc::now() - Duration::minutes(30);

    let result = app
        .push(
            &owner,
            json!({
                "products": [product(product_id, "Bread")],
                "stock_movements": [
                    movement(Uuid::new_v4(), product_id, "stock_in", 12.0, t),
                    movement(Uuid::new_v4(), product_id, "adjustment", 0.0, t + Duration::minutes(1)),
                ],
            }),
        )
        .await;

    assert_eq!(result["rejected"], json!([]));
    assert_eq!(app.stock_of(&owner, product_id).await, 0.0);
}

#[sqlx::test(migrations = "./migrations")]
async fn a_void_made_offline_restores_stock_and_is_safe_to_repeat(pool: PgPool) {
    let app = TestApp::new(pool);
    let owner = app.register("void@example.com").await;
    let product_id = Uuid::new_v4();
    let sale_id = Uuid::new_v4();
    let t = Utc::now() - Duration::hours(1);

    app.push(
        &owner,
        json!({
            "products": [product(product_id, "Sardines")],
            "stock_movements": [movement(Uuid::new_v4(), product_id, "stock_in", 10.0, t)],
            "sales": [sale(sale_id, product_id, 4.0, t + Duration::minutes(1))],
        }),
    )
    .await;
    assert_eq!(app.stock_of(&owner, product_id).await, 6.0);

    let deletion = json!({ "deletions": [{ "entity": "sale", "id": sale_id }] });
    let first = app.push(&owner, deletion.clone()).await;
    let second = app.push(&owner, deletion).await;

    assert_eq!(first["applied"][0]["entity"], "deletion");
    assert_eq!(
        second["rejected"],
        json!([]),
        "a repeated deletion is a success"
    );
    assert_eq!(app.stock_of(&owner, product_id).await, 10.0);
}

#[sqlx::test(migrations = "./migrations")]
async fn one_bad_row_does_not_block_the_rest_of_the_batch(pool: PgPool) {
    let app = TestApp::new(pool);
    let owner = app.register("partial@example.com").await;
    let expense_id = Uuid::new_v4();
    let orphan_sale = Uuid::new_v4();

    let result = app
        .push(
            &owner,
            json!({
                "sales": [sale(orphan_sale, Uuid::new_v4(), 1.0, Utc::now())],
                "expenses": [{ "id": expense_id, "category": "utilities", "amount": 250 }],
                "deletions": [{ "entity": "spaceship", "id": Uuid::new_v4() }],
            }),
        )
        .await;

    let applied: Vec<_> = result["applied"].as_array().unwrap().iter().collect();
    let rejected: Vec<_> = result["rejected"].as_array().unwrap().iter().collect();

    assert_eq!(applied.len(), 1);
    assert_eq!(applied[0]["id"], json!(expense_id));
    assert_eq!(rejected.len(), 2);
    assert!(rejected.iter().any(|row| row["id"] == json!(orphan_sale)
        && row["reason"].as_str().unwrap().contains("product")));
}

#[sqlx::test(migrations = "./migrations")]
async fn a_stock_movement_for_an_unknown_product_is_a_clean_not_found(pool: PgPool) {
    let app = TestApp::new(pool);
    let owner = app.register("unknown@example.com").await;

    let (status, body) = app
        .call(
            Method::POST,
            &format!("/stores/{}/stock-movements", owner.store_id),
            Some(&owner.token),
            Some(movement(
                Uuid::new_v4(),
                Uuid::new_v4(),
                "stock_in",
                5.0,
                Utc::now(),
            )),
        )
        .await;

    assert_eq!(status, StatusCode::NOT_FOUND, "{body}");
}

#[sqlx::test(migrations = "./migrations")]
async fn nobody_can_push_into_another_owners_store(pool: PgPool) {
    let app = TestApp::new(pool);
    let owner = app.register("owner@example.com").await;
    let intruder = app.register("intruder@example.com").await;

    let (status, _) = app
        .call(
            Method::POST,
            &format!("/stores/{}/sync/push", owner.store_id),
            Some(&intruder.token),
            Some(json!({ "expenses": [{ "category": "other", "amount": 1 }] })),
        )
        .await;

    assert_eq!(status, StatusCode::FORBIDDEN);
}

#[sqlx::test(migrations = "./migrations")]
async fn two_devices_trading_offline_converge_on_one_stock_count(pool: PgPool) {
    let app = TestApp::new(pool);
    let owner = app.register("two-devices@example.com").await;
    let product_id = Uuid::new_v4();
    let t = Utc::now() - Duration::hours(3);

    // The counter tablet creates the product and receives stock.
    let tablet_first = json!({
        "products": [product(product_id, "Shampoo sachet")],
        "stock_movements": [movement(Uuid::new_v4(), product_id, "stock_in", 50.0, t)],
    });
    // The owner's phone and the tablet both sell while out of signal.
    let phone_sales: Vec<_> = (0..5)
        .map(|n| {
            sale(
                Uuid::new_v4(),
                product_id,
                2.0,
                t + Duration::minutes(10 + n),
            )
        })
        .collect();
    let tablet_sales: Vec<_> = (0..4)
        .map(|n| {
            sale(
                Uuid::new_v4(),
                product_id,
                3.0,
                t + Duration::minutes(20 + n),
            )
        })
        .collect();

    // Reconnecting in an awkward order, with each device retrying once.
    app.push(&owner, tablet_first.clone()).await;
    app.push(&owner, json!({ "sales": phone_sales.clone() }))
        .await;
    app.push(&owner, json!({ "sales": tablet_sales.clone() }))
        .await;
    app.push(&owner, json!({ "sales": phone_sales })).await;
    app.push(&owner, tablet_first).await;
    app.push(&owner, json!({ "sales": tablet_sales })).await;

    assert_eq!(app.stock_of(&owner, product_id).await, 50.0 - 10.0 - 12.0);

    // Both devices then pull from scratch and must see the same history.
    let phone = app.pull(&owner, None).await;
    let tablet = app.pull(&owner, None).await;
    assert_eq!(phone["sales"].as_array().unwrap().len(), 9);
    assert_eq!(phone["sales"], tablet["sales"]);
}
