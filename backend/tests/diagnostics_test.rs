#![cfg(feature = "integration")]

mod support;

use axum::http::{Method, StatusCode};
use chrono::Utc;
use serde_json::{Value, json};
use sqlx::PgPool;
use support::TestApp;

fn report(fingerprint: &str, occurrences: i64) -> Value {
    json!({
        "fingerprint": fingerprint,
        "error_type": "StateError",
        "message": "Bad state: No element",
        "stack": "#0 main (package:kitaza_app/main.dart:10)",
        "occurrences": occurrences,
        "first_seen": Utc::now(),
        "last_seen": Utc::now(),
        "app_version": "1.0.0+1",
        "platform": "android 14",
    })
}

async fn send(app: &TestApp, token: Option<&str>, reports: Value) -> (StatusCode, Value) {
    app.call(
        Method::POST,
        "/diagnostics/errors",
        token,
        Some(json!({ "reports": reports })),
    )
    .await
}

#[sqlx::test(migrations = "./migrations")]
async fn reports_from_a_phone_are_stored(pool: PgPool) {
    let app = TestApp::new(pool);
    let owner = app.register("crashy@example.com").await;

    let (status, body) = send(
        &app,
        Some(&owner.token),
        json!([report("aa11", 3), report("bb22", 1)]),
    )
    .await;

    assert_eq!(status, StatusCode::ACCEPTED, "{body}");
    assert_eq!(body["accepted"], 2);
    let (rows,): (i64,) = sqlx::query_as("SELECT COUNT(*) FROM client_error_reports")
        .fetch_one(&app.pool)
        .await
        .unwrap();
    assert_eq!(rows, 2);
}

#[sqlx::test(migrations = "./migrations")]
async fn the_same_error_sent_twice_is_counted_not_duplicated(pool: PgPool) {
    let app = TestApp::new(pool);
    let owner = app.register("retry@example.com").await;

    // A phone that loses signal after the server stored its reports sends
    // them again, and meanwhile the same error happened twice more.
    send(&app, Some(&owner.token), json!([report("cc33", 5)])).await;
    send(&app, Some(&owner.token), json!([report("cc33", 2)])).await;

    let (rows, occurrences): (i64, i64) =
        sqlx::query_as("SELECT COUNT(*), SUM(occurrences)::bigint FROM client_error_reports")
            .fetch_one(&app.pool)
            .await
            .unwrap();
    assert_eq!(rows, 1);
    assert_eq!(occurrences, 7);
}

#[sqlx::test(migrations = "./migrations")]
async fn a_batch_is_bounded_in_count_and_size(pool: PgPool) {
    let app = TestApp::new(pool);
    let owner = app.register("big@example.com").await;

    let too_many: Vec<Value> = (0..21).map(|n| report(&format!("f{n}"), 1)).collect();
    let (status, _) = send(&app, Some(&owner.token), json!(too_many)).await;
    assert_eq!(status, StatusCode::BAD_REQUEST);

    let mut huge = report("dd44", 1);
    huge["message"] = json!("x".repeat(5000));
    let (status, _) = send(&app, Some(&owner.token), json!([huge])).await;
    assert_eq!(status, StatusCode::BAD_REQUEST);

    let (status, _) = send(&app, Some(&owner.token), json!([])).await;
    assert_eq!(status, StatusCode::BAD_REQUEST);
}

#[sqlx::test(migrations = "./migrations")]
async fn only_signed_in_phones_can_report(pool: PgPool) {
    let app = TestApp::new(pool);

    let (status, _) = send(&app, None, json!([report("ee55", 1)])).await;

    assert_eq!(status, StatusCode::UNAUTHORIZED);
}
