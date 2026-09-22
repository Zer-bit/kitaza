#![cfg(feature = "integration")]

mod support;

use axum::http::{Method, StatusCode};
use serde_json::Value;
use sqlx::PgPool;
use support::TestApp;

async fn devices(app: &TestApp, owner: &support::Owner) -> Vec<Value> {
    let (status, body) = app
        .call(Method::GET, "/devices", Some(&owner.token), None)
        .await;
    assert_eq!(status, StatusCode::OK, "{body}");
    body.as_array().unwrap().clone()
}

#[sqlx::test(migrations = "./migrations")]
async fn every_signed_in_phone_is_listed_and_this_one_is_marked(pool: PgPool) {
    let app = TestApp::new(pool);
    let email = "phones@example.com";
    let owner = app.register(email).await;
    let tablet = app.sign_in(email, "Counter tablet").await;
    app.staff(&owner, "Liza", &[]).await;

    let listed = devices(&app, &tablet).await;

    assert_eq!(listed.len(), 3);
    let current: Vec<&Value> = listed
        .iter()
        .filter(|device| device["is_current"] == true)
        .collect();
    assert_eq!(current.len(), 1);
    assert_eq!(current[0]["device_name"], "Counter tablet");

    let staff_phone = listed
        .iter()
        .find(|device| device["is_staff"] == true)
        .unwrap();
    assert_eq!(staff_phone["member_name"], "Liza");
    assert_eq!(staff_phone["device_name"], "Counter phone");
}

#[sqlx::test(migrations = "./migrations")]
async fn a_revoked_phone_stops_at_once(pool: PgPool) {
    let app = TestApp::new(pool);
    let email = "lost@example.com";
    let owner = app.register(email).await;
    let lost = app.sign_in(email, "Lost phone").await;

    let (status, _) = app
        .call(
            Method::DELETE,
            &format!("/devices/{}", lost.session_id),
            Some(&owner.token),
            None,
        )
        .await;
    assert_eq!(status, StatusCode::NO_CONTENT);

    // Its access token has most of an hour left, and still does nothing.
    let (pull, _) = app
        .call(
            Method::GET,
            &format!("/stores/{}/sync/pull", lost.store_id),
            Some(&lost.token),
            None,
        )
        .await;
    assert_eq!(pull, StatusCode::UNAUTHORIZED);
    assert_eq!(
        app.refresh(&lost.refresh_token).await.0,
        StatusCode::UNAUTHORIZED
    );

    assert_eq!(devices(&app, &owner).await.len(), 1);
    let log = app.activity(&owner, "").await;
    assert_eq!(log["events"][0]["action"], "device_signed_out");
    assert_eq!(log["events"][0]["details"]["device"], "Lost phone");
}

#[sqlx::test(migrations = "./migrations")]
async fn a_refresh_whose_answer_was_lost_can_be_retried(pool: PgPool) {
    let app = TestApp::new(pool);
    let owner = app.register("dropped@example.com").await;

    let (first, first_body) = app.refresh(&owner.refresh_token).await;
    // The phone never heard that answer, so it tries the same token again.
    let (second, second_body) = app.refresh(&owner.refresh_token).await;

    assert_eq!(first, StatusCode::OK);
    assert_eq!(second, StatusCode::OK);
    assert_eq!(first_body["session_id"], owner.session_id.to_string());
    assert_eq!(second_body["session_id"], owner.session_id.to_string());
    assert_eq!(devices(&app, &owner).await.len(), 1, "still one phone");

    // Signing out ends every token the session ever held.
    let newest = second_body["refresh_token"].as_str().unwrap();
    let (status, _) = app
        .call(
            Method::POST,
            "/auth/logout",
            None,
            Some(serde_json::json!({ "refresh_token": newest })),
        )
        .await;
    assert_eq!(status, StatusCode::NO_CONTENT);
    assert_eq!(
        app.refresh(&owner.refresh_token).await.0,
        StatusCode::UNAUTHORIZED
    );
}

#[sqlx::test(migrations = "./migrations")]
async fn a_token_exchanged_long_ago_is_refused(pool: PgPool) {
    let app = TestApp::new(pool);
    let owner = app.register("stale@example.com").await;
    assert_eq!(app.refresh(&owner.refresh_token).await.0, StatusCode::OK);

    sqlx::query("UPDATE refresh_tokens SET rotated_at = now() - interval '2 days' WHERE rotated_at IS NOT NULL")
        .execute(&app.pool)
        .await
        .unwrap();

    assert_eq!(
        app.refresh(&owner.refresh_token).await.0,
        StatusCode::UNAUTHORIZED
    );
}

#[sqlx::test(migrations = "./migrations")]
async fn an_owner_cannot_revoke_someone_elses_phone(pool: PgPool) {
    let app = TestApp::new(pool);
    let nena = app.register("nena@example.com").await;
    let other = app.register("other@example.com").await;

    let (status, _) = app
        .call(
            Method::DELETE,
            &format!("/devices/{}", other.session_id),
            Some(&nena.token),
            None,
        )
        .await;
    assert_eq!(status, StatusCode::NOT_FOUND);
    assert_eq!(
        app.refresh(&other.refresh_token).await.0,
        StatusCode::OK,
        "untouched"
    );
}
