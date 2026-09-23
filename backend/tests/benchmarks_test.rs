#![cfg(feature = "integration")]

mod support;

use axum::http::{Method, StatusCode};
use serde_json::{Value, json};
use sqlx::PgPool;
use support::{Owner, TestApp};
use uuid::Uuid;

/// A month of trading for one store, written straight to the tables: the
/// comparison reads the same rows a real store's sales would leave.
async fn month_of_trading(
    app: &TestApp,
    store_id: Uuid,
    daily_sales: f64,
    margin_percent: f64,
    expense_percent: f64,
) {
    let per_sale = daily_sales / 4.0;
    let cost = per_sale * (1.0 - margin_percent / 100.0);

    for day in 0..30 {
        for _ in 0..4 {
            sqlx::query(
                "INSERT INTO sales (id, store_id, total_amount, cost_amount, occurred_at)
                 VALUES ($1, $2, $3, $4, now() - make_interval(days => $5))",
            )
            .bind(Uuid::new_v4())
            .bind(store_id)
            .bind(per_sale)
            .bind(cost)
            .bind(day)
            .execute(&app.pool)
            .await
            .unwrap();
        }

        sqlx::query(
            "INSERT INTO expenses (id, store_id, category, amount, occurred_at)
             VALUES ($1, $2, 'utilities', $3, now() - make_interval(days => $4))",
        )
        .bind(Uuid::new_v4())
        .bind(store_id)
        .bind(daily_sales * expense_percent / 100.0)
        .bind(day)
        .execute(&app.pool)
        .await
        .unwrap();
    }
}

/// [count] other stores of [business_type], each trading like the rest.
async fn peer_stores(app: &TestApp, count: i32, business_type: &str, daily_sales: f64) {
    for index in 0..count {
        let (owner_id,): (Uuid,) = sqlx::query_as(
            "INSERT INTO owners (email, password_hash, full_name)
             VALUES ($1, 'x', 'Peer') RETURNING id",
        )
        .bind(format!(
            "peer-{business_type}-{index}-{}@example.com",
            Uuid::new_v4()
        ))
        .fetch_one(&app.pool)
        .await
        .unwrap();

        let (store_id,): (Uuid,) = sqlx::query_as(
            "INSERT INTO stores (owner_id, name, business_type) VALUES ($1, 'Peer', $2)
             RETURNING id",
        )
        .bind(owner_id)
        .bind(business_type)
        .fetch_one(&app.pool)
        .await
        .unwrap();

        month_of_trading(app, store_id, daily_sales, 22.0, 6.0).await;
    }
}

async fn benchmarks(app: &TestApp, owner: &Owner) -> Value {
    let (status, body) = app
        .call(
            Method::GET,
            &format!("/stores/{}/benchmarks", owner.store_id),
            Some(&owner.token),
            None,
        )
        .await;
    assert_eq!(status, StatusCode::OK, "{body}");
    body
}

#[sqlx::test(migrations = "./migrations")]
async fn comparisons_appear_once_enough_similar_stores_share(pool: PgPool) {
    let app = TestApp::new(pool);
    let owner = app.register("compare@example.com").await;
    month_of_trading(&app, owner.store_id, 2_000.0, 14.0, 11.0).await;

    let alone = benchmarks(&app, &owner).await;
    assert_eq!(alone["available"], false);
    assert_eq!(alone["unavailable_because"], "not_enough_stores");

    peer_stores(&app, 20, "sari_sari", 2_000.0).await;
    let compared = benchmarks(&app, &owner).await;

    assert_eq!(compared["available"], true);
    assert_eq!(compared["sample_size"], 20);
    assert_eq!(compared["size_band"], "medium", "₱60,000 a month");

    let margin = &compared["comparisons"][0];
    assert_eq!(margin["metric"], "gross_margin_percent");
    assert_eq!(margin["yours"], 14.0);
    assert_eq!(margin["typical"], 22.0, "the middle of the twenty");
    assert_eq!(compared["comparisons"][1]["yours"], 11.0);
    assert_eq!(compared["comparisons"][1]["typical"], 6.0);
}

#[sqlx::test(migrations = "./migrations")]
async fn nineteen_stores_are_not_enough_to_be_anonymous(pool: PgPool) {
    let app = TestApp::new(pool);
    let owner = app.register("few@example.com").await;
    month_of_trading(&app, owner.store_id, 2_000.0, 14.0, 11.0).await;
    peer_stores(&app, 19, "sari_sari", 2_000.0).await;

    let report = benchmarks(&app, &owner).await;

    assert_eq!(report["available"], false);
    assert_eq!(report["unavailable_because"], "not_enough_stores");
    assert_eq!(report["comparisons"], json!([]));
}

#[sqlx::test(migrations = "./migrations")]
async fn a_store_that_keeps_its_figures_back_sees_none(pool: PgPool) {
    let app = TestApp::new(pool);
    let owner = app.register("private@example.com").await;
    month_of_trading(&app, owner.store_id, 2_000.0, 14.0, 11.0).await;
    peer_stores(&app, 20, "sari_sari", 2_000.0).await;

    let (status, _) = app
        .call(
            Method::PATCH,
            &format!("/stores/{}", owner.store_id),
            Some(&owner.token),
            Some(json!({ "share_benchmarks": false })),
        )
        .await;
    assert_eq!(status, StatusCode::OK);

    let report = benchmarks(&app, &owner).await;
    assert_eq!(report["unavailable_because"], "not_sharing");

    // And its figures are out of everyone else's medians.
    let neighbour = app.register("neighbour@example.com").await;
    month_of_trading(&app, neighbour.store_id, 2_000.0, 14.0, 11.0).await;
    let theirs = benchmarks(&app, &neighbour).await;
    assert_eq!(
        theirs["sample_size"], 20,
        "the 20 peers, not the 21st store"
    );
}

#[sqlx::test(migrations = "./migrations")]
async fn a_carinderia_is_not_compared_with_sari_sari_stores(pool: PgPool) {
    let app = TestApp::new(pool);
    let owner = app.register("kitchen@example.com").await;
    sqlx::query("UPDATE stores SET business_type = 'carinderia' WHERE id = $1")
        .bind(owner.store_id)
        .execute(&app.pool)
        .await
        .unwrap();
    month_of_trading(&app, owner.store_id, 2_000.0, 30.0, 8.0).await;
    peer_stores(&app, 25, "sari_sari", 2_000.0).await;

    let report = benchmarks(&app, &owner).await;
    assert_eq!(report["unavailable_because"], "not_enough_stores");
}

#[sqlx::test(migrations = "./migrations")]
async fn a_much_bigger_store_is_not_compared_with_small_ones(pool: PgPool) {
    let app = TestApp::new(pool);
    let owner = app.register("big@example.com").await;
    month_of_trading(&app, owner.store_id, 20_000.0, 18.0, 7.0).await;
    peer_stores(&app, 25, "sari_sari", 500.0).await;

    let report = benchmarks(&app, &owner).await;
    assert_eq!(report["size_band"], Value::Null);
    assert_eq!(report["unavailable_because"], "not_enough_stores");
}

#[sqlx::test(migrations = "./migrations")]
async fn a_store_that_has_barely_traded_is_not_compared(pool: PgPool) {
    let app = TestApp::new(pool);
    let owner = app.register("new@example.com").await;
    peer_stores(&app, 25, "sari_sari", 2_000.0).await;

    let report = benchmarks(&app, &owner).await;
    assert_eq!(report["unavailable_because"], "not_enough_history");
}

#[sqlx::test(migrations = "./migrations")]
async fn a_cashier_without_profit_access_cannot_see_comparisons(pool: PgPool) {
    let app = TestApp::new(pool);
    let owner = app.register("fenced@example.com").await;
    let cashier = app.staff(&owner, "Liza", &[]).await;

    let (status, _) = app
        .call(
            Method::GET,
            &format!("/stores/{}/benchmarks", owner.store_id),
            Some(&cashier.token),
            None,
        )
        .await;
    assert_eq!(status, StatusCode::FORBIDDEN);
}
