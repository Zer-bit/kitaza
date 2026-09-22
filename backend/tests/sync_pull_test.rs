#![cfg(feature = "integration")]

mod support;

use std::collections::HashSet;

use chrono::{Duration, Utc};
use serde_json::{Value, json};
use sqlx::PgPool;
use support::{Owner, TestApp, ids_of, product, sale};
use uuid::Uuid;

/// Pulls until the server says there is nothing left, as the app does.
async fn pull_everything(
    app: &TestApp,
    owner: &Owner,
    cursor: Option<String>,
) -> (Vec<Value>, String) {
    let mut pages = Vec::new();
    let mut cursor = cursor;

    for _ in 0..50 {
        let page = app.pull(owner, cursor.as_deref()).await;
        cursor = Some(page["cursor"].as_str().unwrap().to_owned());
        let more = page["has_more"].as_bool().unwrap();
        pages.push(page);
        if !more {
            return (pages, cursor.unwrap());
        }
    }
    panic!("pull never finished");
}

fn collect(pages: &[Value], table: &str) -> Vec<String> {
    pages.iter().flat_map(|page| ids_of(&page[table])).collect()
}

async fn record_expenses(app: &TestApp, owner: &Owner, count: usize) -> HashSet<String> {
    let rows: Vec<Value> = (0..count)
        .map(|n| json!({ "id": Uuid::new_v4(), "category": "supplies", "amount": 10 + n }))
        .collect();
    let ids = rows
        .iter()
        .map(|row| row["id"].as_str().unwrap().to_owned())
        .collect();
    app.push(owner, json!({ "expenses": rows })).await;
    ids
}

#[sqlx::test(migrations = "./migrations")]
async fn a_new_device_receives_every_row_however_many_pages_it_takes(pool: PgPool) {
    let app = TestApp::with_page_size(pool, 3);
    let owner = app.register("pages@example.com").await;
    let written = record_expenses(&app, &owner, 8).await;

    let (pages, _) = pull_everything(&app, &owner, None).await;
    let received = collect(&pages, "expenses");

    assert!(pages.len() >= 3, "8 rows at 3 per page needs several pulls");
    assert_eq!(received.len(), 8, "no duplicates across pages");
    assert_eq!(received.into_iter().collect::<HashSet<_>>(), written);
}

#[sqlx::test(migrations = "./migrations")]
async fn rows_sharing_a_timestamp_are_not_lost_at_a_page_boundary(pool: PgPool) {
    let app = TestApp::with_page_size(pool, 4);
    let owner = app.register("same-instant@example.com").await;

    // One transaction: every row gets the identical `now()`. A timestamp-only
    // cursor would jump past the rest of the group after the first page.
    let mut transaction = app.pool.begin().await.unwrap();
    for n in 0..10 {
        sqlx::query(
            "INSERT INTO expenses (id, store_id, category, amount) VALUES ($1, $2, 'other', $3)",
        )
        .bind(Uuid::new_v4())
        .bind(owner.store_id)
        .bind(n as i64)
        .execute(&mut *transaction)
        .await
        .unwrap();
    }
    transaction.commit().await.unwrap();

    let (pages, _) = pull_everything(&app, &owner, None).await;
    let received: HashSet<_> = collect(&pages, "expenses").into_iter().collect();

    assert_eq!(received.len(), 10);
}

#[sqlx::test(migrations = "./migrations")]
async fn after_catching_up_only_changed_rows_come_back(pool: PgPool) {
    let app = TestApp::new(pool);
    let owner = app.register("incremental@example.com").await;
    record_expenses(&app, &owner, 3).await;
    let (_, cursor) = pull_everything(&app, &owner, None).await;

    let quiet = app.pull(&owner, Some(&cursor)).await;
    assert_eq!(quiet["expenses"], json!([]));

    let edited = Uuid::new_v4();
    app.push(
        &owner,
        json!({ "expenses": [{ "id": edited, "category": "rent", "amount": 5000 }] }),
    )
    .await;

    let next = app.pull(&owner, Some(&cursor)).await;
    assert_eq!(ids_of(&next["expenses"]), vec![edited.to_string()]);
}

#[sqlx::test(migrations = "./migrations")]
async fn a_sale_arrives_with_all_of_its_lines_under_the_devices_ids(pool: PgPool) {
    let app = TestApp::new(pool);
    let owner = app.register("lines@example.com").await;
    let product_id = Uuid::new_v4();
    let line_a = Uuid::new_v4();
    let line_b = Uuid::new_v4();

    app.push(
        &owner,
        json!({
            "products": [product(product_id, "Pandesal")],
            "sales": [{
                "id": Uuid::new_v4(),
                "items": [
                    { "id": line_a, "product_id": product_id, "quantity": 2 },
                    { "id": line_b, "quantity": 1, "unit_price": 30 },
                ],
            }],
        }),
    )
    .await;

    let page = app.pull(&owner, None).await;
    let mut lines = ids_of(&page["sale_items"]);
    lines.sort();
    let mut expected = vec![line_a.to_string(), line_b.to_string()];
    expected.sort();

    assert_eq!(lines, expected);
}

#[sqlx::test(migrations = "./migrations")]
async fn an_unreadable_cursor_falls_back_to_a_full_download(pool: PgPool) {
    let app = TestApp::new(pool);
    let owner = app.register("stale-cursor@example.com").await;
    record_expenses(&app, &owner, 2).await;

    // What an older build of the app stored: a bare timestamp.
    let page = app.pull(&owner, Some("2026-01-01T00:00:00Z")).await;

    assert_eq!(page["expenses"].as_array().unwrap().len(), 2);
}

#[sqlx::test(migrations = "./migrations")]
async fn a_pull_never_contains_another_stores_rows(pool: PgPool) {
    let app = TestApp::new(pool);
    let mine = app.register("mine@example.com").await;
    let theirs = app.register("theirs@example.com").await;
    record_expenses(&app, &mine, 2).await;
    let t = Utc::now() - Duration::minutes(5);
    let product_id = Uuid::new_v4();
    app.push(
        &theirs,
        json!({
            "products": [product(product_id, "Theirs")],
            "sales": [sale(Uuid::new_v4(), product_id, 1.0, t)],
        }),
    )
    .await;

    let page = app.pull(&mine, None).await;

    assert_eq!(page["expenses"].as_array().unwrap().len(), 2);
    assert_eq!(page["products"], json!([]));
    assert_eq!(page["sales"], json!([]));
}
