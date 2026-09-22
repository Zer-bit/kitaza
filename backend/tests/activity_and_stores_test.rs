#![cfg(feature = "integration")]

mod support;

use axum::http::{Method, StatusCode};
use chrono::{Duration, Utc};
use serde_json::{Value, json};
use sqlx::PgPool;
use support::{TestApp, ids_of, movement, product, sale};
use uuid::Uuid;

fn actions(log: &Value) -> Vec<String> {
    log["events"]
        .as_array()
        .unwrap()
        .iter()
        .map(|event| event["action"].as_str().unwrap().to_owned())
        .collect()
}

#[sqlx::test(migrations = "./migrations")]
async fn the_log_names_who_did_what_and_counts_retries_once(pool: PgPool) {
    let app = TestApp::new(pool);
    let owner = app.register("log@example.com").await;
    let cashier = app.staff(&owner, "Liza", &[]).await;
    let product_id = Uuid::new_v4();
    let sold_at = Utc::now() - Duration::hours(3);
    app.push(&owner, json!({ "products": [product(product_id, "Coke")] }))
        .await;

    let sale_id = Uuid::new_v4();
    let batch = json!({ "sales": [sale(sale_id, product_id, 1.0, sold_at)] });
    app.push(&cashier, batch.clone()).await;
    app.push(&cashier, batch).await;
    app.push(
        &owner,
        json!({ "deletions": [{ "entity": "sale", "id": sale_id }] }),
    )
    .await;

    let log = app.activity(&owner, "").await;
    assert_eq!(
        actions(&log),
        vec![
            "sale_voided",
            "sale_recorded",
            "product_added",
            "staff_joined",
            "staff_added"
        ]
    );

    let recorded = &log["events"][1];
    assert_eq!(recorded["actor_name"], "Liza");
    assert_eq!(recorded["is_staff"], true);
    assert_eq!(recorded["device_name"], "Counter phone");
    assert_eq!(recorded["details"]["total"], 15.0);
    let occurred: chrono::DateTime<Utc> =
        serde_json::from_value(recorded["occurred_at"].clone()).unwrap();
    assert!(
        (occurred - sold_at).num_seconds().abs() < 1,
        "an offline sale is logged at the time it was made"
    );

    let voided = &log["events"][0];
    assert_eq!(voided["actor_name"], "Test Owner");
    assert_eq!(voided["is_staff"], false);

    let removals = app.activity(&owner, "?filter=removals").await;
    assert_eq!(actions(&removals), vec!["sale_voided"]);
}

#[sqlx::test(migrations = "./migrations")]
async fn a_product_is_logged_only_when_something_changed(pool: PgPool) {
    let app = TestApp::new(pool);
    let owner = app.register("prices@example.com").await;
    let product_id = Uuid::new_v4();

    let original = json!({ "products": [product(product_id, "Coke")] });
    app.push(&owner, original.clone()).await;
    app.push(&owner, original).await;

    let mut raised = product(product_id, "Coke");
    raised["selling_price"] = json!(17);
    app.push(&owner, json!({ "products": [raised] })).await;

    let log = app.activity(&owner, "").await;
    assert_eq!(actions(&log), vec!["product_changed", "product_added"]);
    assert_eq!(
        log["events"][0]["details"]["changes"],
        json!({ "selling_price": [15.0, 17.0] })
    );
}

#[sqlx::test(migrations = "./migrations")]
async fn a_stock_count_records_what_was_found_and_the_difference(pool: PgPool) {
    let app = TestApp::new(pool);
    let owner = app.register("count@example.com").await;
    let product_id = Uuid::new_v4();
    let at = Utc::now() - Duration::hours(1);

    app.push(
        &owner,
        json!({
            "products": [product(product_id, "Rice")],
            "stock_movements": [
                movement(Uuid::new_v4(), product_id, "stock_in", 20.0, at),
                movement(Uuid::new_v4(), product_id, "adjustment", 17.0, at + Duration::minutes(5)),
            ],
        }),
    )
    .await;

    let log = app.activity(&owner, "").await;
    assert_eq!(log["events"][0]["action"], "stock_counted");
    assert_eq!(log["events"][0]["details"]["counted"], 17.0);
    assert_eq!(log["events"][0]["details"]["change"], -3.0);
    assert_eq!(log["events"][1]["action"], "stock_received");
}

#[sqlx::test(migrations = "./migrations")]
async fn the_log_pages_backwards(pool: PgPool) {
    let app = TestApp::new(pool);
    let owner = app.register("pages@example.com").await;
    let products: Vec<Value> = (0..5)
        .map(|n| product(Uuid::new_v4(), &format!("Item {n}")))
        .collect();
    app.push(&owner, json!({ "products": products })).await;

    let first = app.activity(&owner, "?limit=3").await;
    let before = first["next_before"].as_i64().unwrap();
    let second = app
        .activity(&owner, &format!("?limit=3&before={before}"))
        .await;

    assert_eq!(first["events"].as_array().unwrap().len(), 3);
    assert_eq!(second["events"].as_array().unwrap().len(), 2);
    assert!(second.get("next_before").is_none());
}

#[sqlx::test(migrations = "./migrations")]
async fn a_second_store_keeps_its_own_records(pool: PgPool) {
    let app = TestApp::new(pool);
    let owner = app.register("branches@example.com").await;

    let (status, created) = app
        .call(
            Method::POST,
            "/stores",
            Some(&owner.token),
            Some(json!({ "name": "Carinderia", "business_type": "carinderia" })),
        )
        .await;
    assert_eq!(status, StatusCode::CREATED, "{created}");
    let branch = owner.in_store(created["id"].as_str().unwrap().parse().unwrap());

    let rice = Uuid::new_v4();
    app.push(&branch, json!({ "products": [product(rice, "Rice meal")] }))
        .await;

    assert_eq!(
        ids_of(&app.pull(&branch, None).await["products"]),
        vec![rice.to_string()]
    );
    assert_eq!(app.pull(&owner, None).await["products"], json!([]));

    let (_, me) = app
        .call(Method::GET, "/auth/me", Some(&owner.token), None)
        .await;
    assert_eq!(me["stores"].as_array().unwrap().len(), 2);
    assert_eq!(me["stores"][1]["business_type"], "carinderia");

    let (status, renamed) = app
        .call(
            Method::PATCH,
            &format!("/stores/{}", branch.store_id),
            Some(&owner.token),
            Some(json!({ "name": "Nena's Carinderia" })),
        )
        .await;
    assert_eq!(status, StatusCode::OK);
    assert_eq!(renamed["name"], "Nena's Carinderia");
    let log = app.activity(&branch, "").await;
    assert_eq!(log["events"][0]["details"]["old_name"], "Carinderia");
}

#[sqlx::test(migrations = "./migrations")]
async fn an_id_from_another_store_cannot_be_overwritten(pool: PgPool) {
    let app = TestApp::new(pool);
    let nena = app.register("nena@example.com").await;
    let mallory = app.register("mallory@example.com").await;
    let product_id = Uuid::new_v4();
    let sale_id = Uuid::new_v4();
    let at = Utc::now() - Duration::hours(1);

    app.push(
        &nena,
        json!({
            "products": [product(product_id, "Coke")],
            "stock_movements": [movement(Uuid::new_v4(), product_id, "stock_in", 10.0, at)],
            "sales": [sale(sale_id, product_id, 1.0, at + Duration::minutes(1))],
        }),
    )
    .await;

    let mut hijack = product(product_id, "Mine now");
    hijack["selling_price"] = json!(1);
    hijack["cost_price"] = json!(0);
    let (applied, rejected) = app
        .push_verdicts(
            &mallory,
            json!({
                "products": [hijack],
                "sales": [{ "id": sale_id, "items": [{ "unit_price": 1, "quantity": 1 }] }],
            }),
        )
        .await;

    assert!(applied.is_empty(), "{applied:?}");
    assert_eq!(rejected.len(), 2);
    let (name,): (String,) = sqlx::query_as("SELECT name FROM products WHERE id = $1")
        .bind(product_id)
        .fetch_one(&app.pool)
        .await
        .unwrap();
    assert_eq!(name, "Coke");
    assert_eq!(app.stock_of(&nena, product_id).await, 9.0);
}

#[sqlx::test(migrations = "./migrations")]
async fn a_voided_sale_sent_again_stays_voided_and_off_the_stock_ledger(pool: PgPool) {
    let app = TestApp::new(pool);
    let owner = app.register("final@example.com").await;
    let product_id = Uuid::new_v4();
    let sale_id = Uuid::new_v4();
    let at = Utc::now() - Duration::hours(1);
    let sold = json!({ "sales": [sale(sale_id, product_id, 2.0, at + Duration::minutes(1))] });

    app.push(
        &owner,
        json!({
            "products": [product(product_id, "Coke")],
            "stock_movements": [movement(Uuid::new_v4(), product_id, "stock_in", 10.0, at)],
        }),
    )
    .await;
    app.push(&owner, sold.clone()).await;
    app.push(
        &owner,
        json!({ "deletions": [{ "entity": "sale", "id": sale_id }] }),
    )
    .await;
    assert_eq!(app.stock_of(&owner, product_id).await, 10.0);

    // A second phone that recorded nothing new retries its old push.
    let replay = app.push(&owner, sold).await;

    assert_eq!(replay["rejected"], json!([]), "not an error for the phone");
    assert_eq!(app.stock_of(&owner, product_id).await, 10.0);
    let (voided,): (bool,) =
        sqlx::query_as("SELECT deleted_at IS NOT NULL FROM sales WHERE id = $1")
            .bind(sale_id)
            .fetch_one(&app.pool)
            .await
            .unwrap();
    assert!(voided);

    // The ledger must agree with the count: a voided sale takes nothing.
    let (live,): (i64,) = sqlx::query_as(
        "SELECT count(*) FROM stock_movements WHERE note = $1 AND deleted_at IS NULL",
    )
    .bind(format!("sale {sale_id}"))
    .fetch_one(&app.pool)
    .await
    .unwrap();
    assert_eq!(live, 0, "a voided sale left a live deduction in the ledger");
}
