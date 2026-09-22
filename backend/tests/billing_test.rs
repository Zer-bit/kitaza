#![cfg(feature = "integration")]

mod support;

use axum::http::{Method, StatusCode};
use serde_json::{Value, json};
use sqlx::PgPool;
use support::{Owner, TestApp, product};
use uuid::Uuid;

async fn account(app: &TestApp, device: &Owner) -> Value {
    let (status, body) = app
        .call(Method::GET, "/auth/me", Some(&device.token), None)
        .await;
    assert_eq!(status, StatusCode::OK, "{body}");
    body
}

async fn try_push(app: &TestApp, device: &Owner, store_id: Uuid) -> (StatusCode, Value) {
    app.call(
        Method::POST,
        &format!("/stores/{store_id}/sync/push"),
        Some(&device.token),
        Some(json!({ "products": [product(Uuid::new_v4(), "Coke")] })),
    )
    .await
}

/// Moves the trial's end [days_ago] into the past, as if time had passed.
async fn trial_ended(app: &TestApp, days_ago: i32) {
    sqlx::query("UPDATE subscriptions SET trial_ends_at = now() - make_interval(days => $1)")
        .bind(days_ago)
        .execute(&app.pool)
        .await
        .unwrap();
    app.state.session_directory.forget_all();
}

/// Opens a checkout and presses the test gateway's pay button.
async fn pay(app: &TestApp, owner: &Owner, plan: &str, months: u32) -> Uuid {
    let (status, checkout) = app
        .call(
            Method::POST,
            "/billing/checkout",
            Some(&owner.token),
            Some(json!({ "plan": plan, "months": months })),
        )
        .await;
    assert_eq!(status, StatusCode::CREATED, "{checkout}");
    let payment_id: Uuid = checkout["payment_id"].as_str().unwrap().parse().unwrap();
    assert!(
        checkout["checkout_url"]
            .as_str()
            .unwrap()
            .ends_with(&format!("/billing/test-checkout/{payment_id}"))
    );

    let (paid, _) = app
        .call_raw(
            Method::POST,
            &format!("/billing/test-checkout/{payment_id}"),
            None,
            None,
        )
        .await;
    assert_eq!(paid, StatusCode::OK);
    payment_id
}

#[sqlx::test(migrations = "./migrations")]
async fn a_new_account_starts_on_a_pro_trial(pool: PgPool) {
    let app = TestApp::with_billing(pool);
    let owner = app.register("trial@example.com").await;

    let me = account(&app, &owner).await;
    let subscription = &me["subscription"];

    assert_eq!(subscription["status"], "trial");
    assert_eq!(subscription["plan"], "pro");
    assert_eq!(subscription["allows_staff"], true);
    assert_eq!(subscription["store_limit"], 5);
    let ends: chrono::DateTime<chrono::Utc> =
        serde_json::from_value(subscription["period_ends_at"].clone()).unwrap();
    let days = (ends - chrono::Utc::now()).num_days();
    assert!((29..=30).contains(&days), "{days} days");
}

#[sqlx::test(migrations = "./migrations")]
async fn an_unpaid_account_keeps_working_through_grace_then_pauses(pool: PgPool) {
    let app = TestApp::with_billing(pool);
    let owner = app.register("lapse@example.com").await;
    let (status, _) = try_push(&app, &owner, owner.store_id).await;
    assert_eq!(status, StatusCode::OK);

    trial_ended(&app, 3).await;
    assert_eq!(
        account(&app, &owner).await["subscription"]["status"],
        "grace"
    );
    assert_eq!(
        try_push(&app, &owner, owner.store_id).await.0,
        StatusCode::OK
    );

    trial_ended(&app, 8).await;
    assert_eq!(
        account(&app, &owner).await["subscription"]["status"],
        "paused"
    );

    let (status, refused) = try_push(&app, &owner, owner.store_id).await;
    assert_eq!(status, StatusCode::PAYMENT_REQUIRED);
    assert_eq!(refused["error"]["code"], "subscription_required");

    // Nothing is held back: every record already in the cloud still comes
    // down, to this phone or a new one.
    let pulled = app.pull(&owner, None).await;
    assert_eq!(pulled["products"].as_array().unwrap().len(), 2);
}

#[sqlx::test(migrations = "./migrations")]
async fn a_paused_owner_can_still_take_someones_access_away(pool: PgPool) {
    let app = TestApp::with_billing(pool);
    let owner = app.register("remove-paused@example.com").await;
    let (staff_id, _) = app.add_staff(&owner, "Liza", &[]).await;
    trial_ended(&app, 30).await;

    let (status, body) = app
        .call(
            Method::DELETE,
            &format!("/stores/{}/staff/{staff_id}", owner.store_id),
            Some(&owner.token),
            None,
        )
        .await;
    assert_eq!(status, StatusCode::NO_CONTENT, "{body}");
}

#[sqlx::test(migrations = "./migrations")]
async fn paying_unpauses_at_once_and_a_repeated_confirmation_counts_once(pool: PgPool) {
    let app = TestApp::with_billing(pool);
    let owner = app.register("pay@example.com").await;
    trial_ended(&app, 30).await;
    assert_eq!(
        try_push(&app, &owner, owner.store_id).await.0,
        StatusCode::PAYMENT_REQUIRED
    );

    let payment_id = pay(&app, &owner, "basic", 1).await;

    assert_eq!(
        try_push(&app, &owner, owner.store_id).await.0,
        StatusCode::OK
    );
    let subscription = account(&app, &owner).await["subscription"].clone();
    assert_eq!(subscription["status"], "active");
    assert_eq!(subscription["plan"], "basic");

    // The gateway says so again: nothing more is added.
    let (again, _) = app
        .call_raw(
            Method::POST,
            &format!("/billing/test-checkout/{payment_id}"),
            None,
            None,
        )
        .await;
    assert_eq!(again, StatusCode::NOT_FOUND);

    let (_, overview) = app
        .call(Method::GET, "/billing", Some(&owner.token), None)
        .await;
    let payments = overview["payments"].as_array().unwrap();
    assert_eq!(payments.len(), 1);
    assert_eq!(payments[0]["amount"], 99.0);
    assert_eq!(payments[0]["method"], "test");
    assert_eq!(overview["plans"][1]["monthly_price"], 199.0);
    assert_eq!(overview["plans"][1]["yearly_price"], 1990.0);

    let log = app.activity(&owner, "").await;
    let paid = log["events"]
        .as_array()
        .unwrap()
        .iter()
        .find(|event| event["action"] == "subscription_paid")
        .expect("the payment is in the activity log");
    assert_eq!(paid["details"]["plan"], "basic");
    assert_eq!(paid["device_name"], "test", "paid with");
}

#[sqlx::test(migrations = "./migrations")]
async fn basic_covers_one_store_and_no_staff(pool: PgPool) {
    let app = TestApp::with_billing(pool);
    let owner = app.register("basic@example.com").await;

    // During the Pro trial: a second store and a cashier.
    let (_, branch) = app
        .call(
            Method::POST,
            "/stores",
            Some(&owner.token),
            Some(json!({ "name": "Branch" })),
        )
        .await;
    let branch_id: Uuid = branch["id"].as_str().unwrap().parse().unwrap();
    let cashier = app.staff(&owner, "Liza", &[]).await;

    trial_ended(&app, 30).await;
    pay(&app, &owner, "basic", 1).await;

    // The first store carries on; the second is read-only until Pro.
    assert_eq!(
        try_push(&app, &owner, owner.store_id).await.0,
        StatusCode::OK
    );
    let (status, refused) = try_push(&app, &owner, branch_id).await;
    assert_eq!(status, StatusCode::PAYMENT_REQUIRED);
    assert_eq!(refused["error"]["code"], "upgrade_required");
    let (read, _) = app
        .call(
            Method::GET,
            &format!("/stores/{branch_id}/sync/pull"),
            Some(&owner.token),
            None,
        )
        .await;
    assert_eq!(read, StatusCode::OK);

    let (status, _) = app
        .call(
            Method::POST,
            "/stores",
            Some(&owner.token),
            Some(json!({ "name": "Third" })),
        )
        .await;
    assert_eq!(status, StatusCode::PAYMENT_REQUIRED);

    let (status, _) = app
        .call(
            Method::POST,
            &format!("/stores/{}/staff", owner.store_id),
            Some(&owner.token),
            Some(json!({ "display_name": "Ben" })),
        )
        .await;
    assert_eq!(status, StatusCode::PAYMENT_REQUIRED);

    let (status, _) = app
        .call(
            Method::GET,
            &format!("/stores/{}/sync/pull", owner.store_id),
            Some(&cashier.token),
            None,
        )
        .await;
    assert_eq!(
        status,
        StatusCode::PAYMENT_REQUIRED,
        "the cashier's phone waits"
    );

    // Removing someone is never held up by a plan.
    let (_, staff) = app
        .call(
            Method::GET,
            &format!("/stores/{}/staff", owner.store_id),
            Some(&owner.token),
            None,
        )
        .await;
    let liza = staff[0]["id"].as_str().unwrap();
    let (status, _) = app
        .call(
            Method::DELETE,
            &format!("/stores/{}/staff/{liza}", owner.store_id),
            Some(&owner.token),
            None,
        )
        .await;
    assert_eq!(status, StatusCode::NO_CONTENT);
}

#[sqlx::test(migrations = "./migrations")]
async fn upgrading_to_pro_mid_month_reopens_everything(pool: PgPool) {
    let app = TestApp::with_billing(pool);
    let owner = app.register("upgrade@example.com").await;
    let (_, code) = app.add_staff(&owner, "Liza", &[]).await;
    trial_ended(&app, 30).await;
    pay(&app, &owner, "basic", 1).await;

    // The code is refused but not used up, so it still works after paying.
    let (status, _) = app.try_join(&code).await;
    assert_eq!(status, StatusCode::PAYMENT_REQUIRED);

    pay(&app, &owner, "pro", 1).await;
    let (status, _) = app.try_join(&code).await;
    assert_eq!(status, StatusCode::OK);

    // A month of Basic already paid became about two weeks of Pro on top.
    let subscription = account(&app, &owner).await["subscription"].clone();
    assert_eq!(subscription["plan"], "pro");
    let ends: chrono::DateTime<chrono::Utc> =
        serde_json::from_value(subscription["period_ends_at"].clone()).unwrap();
    let days = (ends - chrono::Utc::now()).num_days();
    assert!((43..=47).contains(&days), "{days} days");
}

#[sqlx::test(migrations = "./migrations")]
async fn with_billing_off_nothing_is_limited(pool: PgPool) {
    let app = TestApp::new(pool);
    let owner = app.register("free@example.com").await;
    trial_ended(&app, 365).await;

    assert_eq!(
        account(&app, &owner).await["subscription"]["status"],
        "unlimited"
    );
    assert_eq!(
        try_push(&app, &owner, owner.store_id).await.0,
        StatusCode::OK
    );
    let (status, _) = app
        .call(
            Method::POST,
            "/billing/checkout",
            Some(&owner.token),
            Some(json!({ "plan": "pro", "months": 1 })),
        )
        .await;
    assert_eq!(status, StatusCode::BAD_REQUEST);
}
