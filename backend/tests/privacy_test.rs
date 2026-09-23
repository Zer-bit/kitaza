#![cfg(feature = "integration")]

mod support;

use axum::http::{Method, StatusCode};
use chrono::{Duration, Utc};
use kitaza_server::features::privacy::{LegalDocument, RetentionPolicy, sweep};
use serde_json::{Value, json};
use sqlx::PgPool;
use support::{TestApp, product, sale};
use uuid::Uuid;

/// Registers without agreeing to anything.
async fn register_without_consent(app: &TestApp, body: Value) -> (StatusCode, Value) {
    app.call(Method::POST, "/auth/register", None, Some(body))
        .await
}

#[sqlx::test(migrations = "./migrations")]
async fn an_account_cannot_be_made_without_agreeing_to_anything(pool: PgPool) {
    let app = TestApp::new(pool);

    let (status, body) = register_without_consent(
        &app,
        json!({
            "email": "nobody@example.com",
            "password": "a-good-password",
            "full_name": "Nena Reyes",
            "store_name": "Nena's Store",
        }),
    )
    .await;

    assert_eq!(
        status,
        StatusCode::BAD_REQUEST,
        "there is no lawful basis to hold an account nobody agreed to: {body}"
    );
}

#[sqlx::test(migrations = "./migrations")]
async fn agreeing_to_last_years_notice_is_not_agreeing(pool: PgPool) {
    let app = TestApp::new(pool);

    let (status, _) = register_without_consent(
        &app,
        json!({
            "email": "nobody@example.com",
            "password": "a-good-password",
            "full_name": "Nena Reyes",
            "store_name": "Nena's Store",
            "accepted_privacy_version": "1999-01-01",
            "accepted_terms_version": LegalDocument::Terms.current_version(),
        }),
    )
    .await;

    assert_eq!(status, StatusCode::BAD_REQUEST);
}

#[sqlx::test(migrations = "./migrations")]
async fn what_was_agreed_to_is_written_down(pool: PgPool) {
    let app = TestApp::new(pool);
    let owner = app.register("owner@example.com").await;

    let (status, body) = app
        .call(Method::GET, "/account/privacy", Some(&owner.token), None)
        .await;

    assert_eq!(status, StatusCode::OK);
    assert!(
        body["outstanding"].as_array().unwrap().is_empty(),
        "a new account has agreed to everything in force: {body}"
    );

    let documents: Vec<&str> = body["agreed"]
        .as_array()
        .unwrap()
        .iter()
        .map(|row| row["document"].as_str().unwrap())
        .collect();
    assert!(documents.contains(&"privacy_notice"));
    assert!(documents.contains(&"terms"));
    assert!(body["agreed"][0]["agreed_at"].is_string(), "and when");
}

#[sqlx::test(migrations = "./migrations")]
async fn a_new_version_has_to_be_agreed_to_again(pool: PgPool) {
    let app = TestApp::new(pool);
    let owner = app.register("owner@example.com").await;

    // What raising the version looks like from the owner's side.
    sqlx::query("UPDATE consent_records SET version = 'older' WHERE document = 'privacy_notice'")
        .execute(&app.pool)
        .await
        .unwrap();

    let (_, body) = app
        .call(Method::GET, "/account/privacy", Some(&owner.token), None)
        .await;
    assert_eq!(body["outstanding"][0]["document"], "privacy_notice");

    let (status, _) = app
        .call(
            Method::POST,
            "/account/consent",
            Some(&owner.token),
            Some(json!({
                "document": "privacy_notice",
                "version": LegalDocument::PrivacyNotice.current_version(),
            })),
        )
        .await;
    assert_eq!(status, StatusCode::NO_CONTENT);

    let (_, body) = app
        .call(Method::GET, "/account/privacy", Some(&owner.token), None)
        .await;
    assert!(body["outstanding"].as_array().unwrap().is_empty());
}

#[sqlx::test(migrations = "./migrations")]
async fn an_owner_can_take_a_copy_of_everything_held_about_them(pool: PgPool) {
    let app = TestApp::new(pool);
    let owner = app.register("owner@example.com").await;
    let product_id = Uuid::new_v4();
    app.push(
        &owner,
        json!({
            "products": [product(product_id, "Kape")],
            "sales": [sale(Uuid::new_v4(), product_id, 2.0, Utc::now())],
        }),
    )
    .await;

    let (status, body) = app
        .call(Method::GET, "/account/export", Some(&owner.token), None)
        .await;

    assert_eq!(status, StatusCode::OK);
    assert_eq!(body["account"]["email"], "owner@example.com");
    assert_eq!(body["stores"].as_array().unwrap().len(), 1);
    assert_eq!(body["products"].as_array().unwrap().len(), 1);
    assert_eq!(body["sales"].as_array().unwrap().len(), 1);
    assert!(
        body["sales"][0]["items"].as_array().unwrap().len() == 1,
        "the lines of a sale come with it: {body}"
    );
    assert_eq!(body["consents"].as_array().unwrap().len(), 2);
}

#[sqlx::test(migrations = "./migrations")]
async fn one_owners_export_never_contains_anothers(pool: PgPool) {
    let app = TestApp::new(pool);
    let mine = app.register("mine@example.com").await;
    let theirs = app.register("theirs@example.com").await;

    let product_id = Uuid::new_v4();
    app.push(
        &theirs,
        json!({ "products": [product(product_id, "Not mine")] }),
    )
    .await;

    let (_, body) = app
        .call(Method::GET, "/account/export", Some(&mine.token), None)
        .await;

    assert_eq!(body["products"].as_array().unwrap().len(), 0);
    assert_eq!(body["stores"].as_array().unwrap().len(), 1);
    assert_eq!(body["account"]["email"], "mine@example.com");
}

#[sqlx::test(migrations = "./migrations")]
async fn a_cashier_cannot_export_their_employers_account(pool: PgPool) {
    let app = TestApp::new(pool);
    let owner = app.register("owner@example.com").await;
    let cashier = app.staff(&owner, "Liza", &[]).await;

    let (status, _) = app
        .call(Method::GET, "/account/export", Some(&cashier.token), None)
        .await;

    assert_eq!(status, StatusCode::FORBIDDEN);
}

#[sqlx::test(migrations = "./migrations")]
async fn deletion_is_asked_for_now_and_done_later(pool: PgPool) {
    let app = TestApp::new(pool);
    let owner = app.register("owner@example.com").await;

    let (status, body) = app
        .call(Method::POST, "/account/deletion", Some(&owner.token), None)
        .await;

    assert_eq!(status, StatusCode::OK);
    assert!(body["deletes_at"].is_string(), "with a date: {body}");

    // Nothing is gone yet, and a sweep today must not take it.
    let swept = sweep(&app.pool, RetentionPolicy::default()).await.unwrap();
    assert_eq!(swept.accounts_deleted, 0, "the grace period is the point");

    let (_, body) = app
        .call(Method::GET, "/account/privacy", Some(&owner.token), None)
        .await;
    assert!(body["deletion"]["requested_at"].is_string());
}

#[sqlx::test(migrations = "./migrations")]
async fn a_deletion_can_be_called_off(pool: PgPool) {
    let app = TestApp::new(pool);
    let owner = app.register("owner@example.com").await;

    app.call(Method::POST, "/account/deletion", Some(&owner.token), None)
        .await;
    let (status, _) = app
        .call(
            Method::DELETE,
            "/account/deletion",
            Some(&owner.token),
            None,
        )
        .await;
    assert_eq!(status, StatusCode::NO_CONTENT);

    let (_, body) = app
        .call(Method::GET, "/account/privacy", Some(&owner.token), None)
        .await;
    assert!(body["deletion"].is_null(), "and the account carries on");
}

#[sqlx::test(migrations = "./migrations")]
async fn once_the_grace_period_is_over_everything_goes(pool: PgPool) {
    let app = TestApp::new(pool);
    let owner = app.register("owner@example.com").await;
    let product_id = Uuid::new_v4();
    app.push(
        &owner,
        json!({
            "products": [product(product_id, "Kape")],
            "sales": [sale(Uuid::new_v4(), product_id, 1.0, Utc::now())],
        }),
    )
    .await;

    app.call(Method::POST, "/account/deletion", Some(&owner.token), None)
        .await;
    // The day the grace period runs out.
    sqlx::query("UPDATE owners SET delete_after = now() - INTERVAL '1 minute'")
        .execute(&app.pool)
        .await
        .unwrap();

    let swept = sweep(&app.pool, RetentionPolicy::default()).await.unwrap();
    assert_eq!(swept.accounts_deleted, 1);

    // Everything hangs off the owner row, so erasure has to leave nothing
    // behind in any of it.
    assert_eq!(count_owners(&app.pool).await, 0);
    assert_eq!(count_stores(&app.pool).await, 0);
    assert_eq!(count_products(&app.pool).await, 0);
    assert_eq!(count_sales(&app.pool).await, 0);
    assert_eq!(count_sessions(&app.pool).await, 0);
    assert_eq!(count_consents(&app.pool).await, 0);
    assert_eq!(count_activity(&app.pool).await, 0);
}

#[sqlx::test(migrations = "./migrations")]
async fn a_purge_keeps_the_money_and_forgets_who_paid_it(pool: PgPool) {
    let app = TestApp::new(pool);
    let owner = app.register("owner@example.com").await;

    sqlx::query(
        "INSERT INTO payments (id, owner_id, plan, months, amount, currency,
                               provider, provider_reference, status, paid_at)
         VALUES ($1, $2, 'pro', 1, 199, 'PHP', 'paymongo', 'pm_test', 'paid', now())",
    )
    .bind(Uuid::new_v4())
    .bind(owner_id_of(&app, "owner@example.com").await)
    .execute(&app.pool)
    .await
    .unwrap();

    app.call(Method::POST, "/account/deletion", Some(&owner.token), None)
        .await;
    sqlx::query("UPDATE owners SET delete_after = now() - INTERVAL '1 minute'")
        .execute(&app.pool)
        .await
        .unwrap();
    sweep(&app.pool, RetentionPolicy::default()).await.unwrap();

    // The business still has to account for ₱199 it was paid; the record that
    // survives names nobody.
    assert_eq!(count_accounting(&app.pool).await, 1);

    let columns: Vec<String> = sqlx::query_scalar(
        "SELECT column_name::text FROM information_schema.columns
         WHERE table_name = 'accounting_records'",
    )
    .fetch_all(&app.pool)
    .await
    .unwrap();
    assert!(
        !columns.iter().any(|name| name.contains("owner")),
        "nothing about the person may be kept: {columns:?}"
    );
}

#[sqlx::test(migrations = "./migrations")]
async fn records_past_the_age_they_are_kept_for_are_dropped(pool: PgPool) {
    let app = TestApp::new(pool);
    let owner = app.register("owner@example.com").await;
    // Something for the activity log to hold.
    app.push(
        &owner,
        json!({ "products": [product(Uuid::new_v4(), "Kape")] }),
    )
    .await;

    app.call(
        Method::POST,
        "/diagnostics/errors",
        Some(&owner.token),
        Some(json!({
            "reports": [{
                "fingerprint": "abc",
                "error_type": "StateError",
                "message": "went wrong",
                "occurrences": 1,
                "first_seen": Utc::now(),
                "last_seen": Utc::now(),
                "app_version": "1.0.0+1",
                "platform": "android 14",
            }],
        })),
    )
    .await;

    sqlx::query("UPDATE client_error_reports SET last_seen = now() - INTERVAL '120 days'")
        .execute(&app.pool)
        .await
        .unwrap();
    sqlx::query("UPDATE audit_events SET recorded_at = now() - INTERVAL '900 days'")
        .execute(&app.pool)
        .await
        .unwrap();

    let swept = sweep(&app.pool, RetentionPolicy::default()).await.unwrap();

    assert_eq!(swept.error_reports_deleted, 1);
    assert!(swept.activity_deleted >= 1, "old activity goes too");
    assert_eq!(
        count_owners(&app.pool).await,
        1,
        "the account itself is untouched"
    );
}

#[sqlx::test(migrations = "./migrations")]
async fn a_sweep_leaves_records_that_are_still_within_their_life(pool: PgPool) {
    let app = TestApp::new(pool);
    let owner = app.register("owner@example.com").await;
    app.push(
        &owner,
        json!({ "products": [product(Uuid::new_v4(), "Kape")] }),
    )
    .await;

    let swept = sweep(
        &app.pool,
        RetentionPolicy {
            activity: Duration::days(730),
            ..RetentionPolicy::default()
        },
    )
    .await
    .unwrap();

    assert_eq!(swept.activity_deleted, 0);
    assert_eq!(swept.accounts_deleted, 0);
    assert!(count_activity(&app.pool).await > 0);
}

async fn count_owners(pool: &PgPool) -> i64 {
    scalar(pool, "SELECT count(*) FROM owners").await
}

async fn count_stores(pool: &PgPool) -> i64 {
    scalar(pool, "SELECT count(*) FROM stores").await
}

async fn count_products(pool: &PgPool) -> i64 {
    scalar(pool, "SELECT count(*) FROM products").await
}

async fn count_sales(pool: &PgPool) -> i64 {
    scalar(pool, "SELECT count(*) FROM sales").await
}

async fn count_sessions(pool: &PgPool) -> i64 {
    scalar(pool, "SELECT count(*) FROM device_sessions").await
}

async fn count_consents(pool: &PgPool) -> i64 {
    scalar(pool, "SELECT count(*) FROM consent_records").await
}

async fn count_activity(pool: &PgPool) -> i64 {
    scalar(pool, "SELECT count(*) FROM audit_events").await
}

async fn count_accounting(pool: &PgPool) -> i64 {
    scalar(pool, "SELECT count(*) FROM accounting_records").await
}

async fn scalar(pool: &PgPool, sql: &'static str) -> i64 {
    sqlx::query_scalar(sql).fetch_one(pool).await.unwrap()
}

async fn owner_id_of(app: &TestApp, email: &str) -> Uuid {
    sqlx::query_scalar("SELECT id FROM owners WHERE email = $1")
        .bind(email)
        .fetch_one(&app.pool)
        .await
        .unwrap()
}
