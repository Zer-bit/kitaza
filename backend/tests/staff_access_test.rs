#![cfg(feature = "integration")]

mod support;

use axum::http::{Method, StatusCode};
use chrono::{Duration, Utc};
use serde_json::{Value, json};
use sqlx::PgPool;
use support::{TestApp, movement, product, sale};
use uuid::Uuid;

/// An owner with one product in stock and a sale, expense and withdrawal
/// already recorded: enough for every table a staff phone might pull.
async fn stocked_store(app: &TestApp, email: &str) -> (support::Owner, Uuid) {
    let owner = app.register(email).await;
    let product_id = Uuid::new_v4();
    let at = Utc::now() - Duration::hours(2);

    app.push(
        &owner,
        json!({
            "products": [product(product_id, "Coke")],
            "stock_movements": [movement(Uuid::new_v4(), product_id, "stock_in", 24.0, at)],
            "sales": [sale(Uuid::new_v4(), product_id, 2.0, at + Duration::minutes(1))],
            "expenses": [{ "id": Uuid::new_v4(), "category": "utilities", "amount": 350 }],
            "withdrawals": [{ "id": Uuid::new_v4(), "amount": 500 }],
        }),
    )
    .await;

    (owner, product_id)
}

fn entities(rejected: &[String]) -> Vec<&str> {
    rejected
        .iter()
        .map(|pair| pair.split(':').next().unwrap())
        .collect()
}

#[sqlx::test(migrations = "./migrations")]
async fn a_join_code_works_once_however_it_is_typed(pool: PgPool) {
    let app = TestApp::new(pool);
    let owner = app.register("join@example.com").await;
    let (_, code) = app.add_staff(&owner, "Liza", &[]).await;

    let typed = code.to_lowercase().replace('-', " ");
    let (status, session) = app.try_join(&typed).await;

    assert_eq!(status, StatusCode::OK, "{session}");
    assert_eq!(session["access"]["role"], "staff");
    assert_eq!(session["access"]["display_name"], "Liza");
    assert_eq!(session["access"]["permissions"], json!([]));
    assert_eq!(session["stores"][0]["id"], owner.store_id.to_string());
    assert!(
        session["owner"].get("email").is_none(),
        "staff are not shown the owner's login"
    );

    let (again, _) = app.try_join(&code).await;
    assert_eq!(again, StatusCode::UNAUTHORIZED, "a code is single use");
}

#[sqlx::test(migrations = "./migrations")]
async fn only_the_newest_unexpired_code_works(pool: PgPool) {
    let app = TestApp::new(pool);
    let owner = app.register("codes@example.com").await;
    let (staff_id, first) = app.add_staff(&owner, "Liza", &[]).await;

    let (status, invite) = app
        .call(
            Method::POST,
            &format!("/stores/{}/staff/{staff_id}/invite", owner.store_id),
            Some(&owner.token),
            None,
        )
        .await;
    assert_eq!(status, StatusCode::CREATED);
    let second = invite["code"].as_str().unwrap().to_owned();

    assert_eq!(app.try_join(&first).await.0, StatusCode::UNAUTHORIZED);

    sqlx::query("UPDATE staff_invites SET expires_at = now() - interval '1 minute'")
        .execute(&app.pool)
        .await
        .unwrap();
    assert_eq!(app.try_join(&second).await.0, StatusCode::UNAUTHORIZED);
}

#[sqlx::test(migrations = "./migrations")]
async fn a_cashier_can_sell_and_nothing_else(pool: PgPool) {
    let app = TestApp::new(pool);
    let (owner, product_id) = stocked_store(&app, "cashier@example.com").await;
    let cashier = app.staff(&owner, "Liza", &[]).await;
    let owners_sale: String = sqlx::query_scalar("SELECT id::text FROM sales LIMIT 1")
        .fetch_one(&app.pool)
        .await
        .unwrap();
    let now = Utc::now();
    let own_sale = Uuid::new_v4();

    let (applied, rejected) = app
        .push_verdicts(
            &cashier,
            json!({
                "sales": [sale(own_sale, product_id, 1.0, now)],
                "products": [product(product_id, "Coke Zero")],
                "stock_movements": [movement(Uuid::new_v4(), product_id, "adjustment", 99.0, now)],
                "expenses": [{ "id": Uuid::new_v4(), "category": "utilities", "amount": 1 }],
                "withdrawals": [{ "id": Uuid::new_v4(), "amount": 1000 }],
                "deletions": [{ "entity": "sale", "id": owners_sale }],
            }),
        )
        .await;

    assert_eq!(applied, vec![format!("sale:{own_sale}")]);
    assert_eq!(
        entities(&rejected),
        vec![
            "product",
            "stock_movement",
            "expense",
            "withdrawal",
            "deletion"
        ]
    );

    // 24 in, 2 sold by the owner, 1 by the cashier. The count of 99 and the
    // rename were refused, and the owner's sale still stands.
    assert_eq!(app.stock_of(&owner, product_id).await, 21.0);
    let (voided,): (i64,) =
        sqlx::query_as("SELECT count(*) FROM sales WHERE deleted_at IS NOT NULL")
            .fetch_one(&app.pool)
            .await
            .unwrap();
    assert_eq!(voided, 0);
}

#[sqlx::test(migrations = "./migrations")]
async fn a_phone_without_profit_access_never_receives_costs(pool: PgPool) {
    let app = TestApp::new(pool);
    let (owner, _) = stocked_store(&app, "costs@example.com").await;
    let cashier = app.staff(&owner, "Liza", &[]).await;

    let pulled = app.pull(&cashier, None).await;

    assert_eq!(pulled["products"][0]["cost_price"], 0);
    assert_eq!(pulled["sales"][0]["cost_amount"], 0);
    assert_eq!(pulled["sale_items"][0]["unit_cost"], 0);
    assert!(
        pulled["stock_movements"]
            .as_array()
            .unwrap()
            .iter()
            .all(|row| row["unit_cost"] == 0)
    );
    assert_eq!(pulled["expenses"], json!([]));
    assert_eq!(pulled["withdrawals"], json!([]));
    // Selling needs the price, so that still arrives.
    assert_eq!(pulled["products"][0]["selling_price"], 15.0);

    let (status, _) = app
        .call(
            Method::GET,
            &format!("/stores/{}/dashboard", owner.store_id),
            Some(&cashier.token),
            None,
        )
        .await;
    assert_eq!(status, StatusCode::FORBIDDEN);
}

#[sqlx::test(migrations = "./migrations")]
async fn a_cashiers_sale_is_costed_from_the_catalogue(pool: PgPool) {
    let app = TestApp::new(pool);
    let (owner, product_id) = stocked_store(&app, "costing@example.com").await;
    let cashier = app.staff(&owner, "Liza", &[]).await;
    let sale_id = Uuid::new_v4();

    // The cashier's phone only ever saw a cost of zero, and says so.
    app.push(
        &cashier,
        json!({ "sales": [{
            "id": sale_id,
            "items": [{ "id": Uuid::new_v4(), "product_id": product_id,
                        "quantity": 3, "unit_price": 15, "unit_cost": 0 }],
        }]}),
    )
    .await;

    let (_, detail) = app
        .call(
            Method::GET,
            &format!("/stores/{}/sales/{sale_id}", owner.store_id),
            Some(&owner.token),
            None,
        )
        .await;
    assert_eq!(detail["cost_amount"], 30.0, "3 at the catalogue cost of 10");
    assert_eq!(detail["profit_amount"], 15.0);
}

#[sqlx::test(migrations = "./migrations")]
async fn staff_may_retry_their_own_sale_but_not_rewrite_anyone_elses(pool: PgPool) {
    let app = TestApp::new(pool);
    let (owner, product_id) = stocked_store(&app, "rewrite@example.com").await;
    let cashier = app.staff(&owner, "Liza", &[]).await;
    let owners_sale: Uuid = sqlx::query_scalar("SELECT id FROM sales LIMIT 1")
        .fetch_one(&app.pool)
        .await
        .unwrap();
    let own_sale = Uuid::new_v4();
    let now = Utc::now();

    let batch = json!({ "sales": [sale(own_sale, product_id, 1.0, now)] });
    app.push(&cashier, batch.clone()).await;
    let (applied, _) = app.push_verdicts(&cashier, batch).await;
    assert_eq!(applied, vec![format!("sale:{own_sale}")], "a retry is fine");

    let (_, rejected) = app
        .push_verdicts(
            &cashier,
            json!({ "sales": [sale(owners_sale, product_id, 0.5, now)] }),
        )
        .await;
    assert_eq!(rejected, vec![format!("sale:{owners_sale}")]);

    let (quantity,): (f64,) =
        sqlx::query_as("SELECT quantity::float8 FROM sale_items WHERE sale_id = $1")
            .bind(owners_sale)
            .fetch_one(&app.pool)
            .await
            .unwrap();
    assert_eq!(quantity, 2.0, "the owner's sale is untouched");
}

#[sqlx::test(migrations = "./migrations")]
async fn staff_editing_products_cannot_wipe_a_cost_they_cannot_see(pool: PgPool) {
    let app = TestApp::new(pool);
    let (owner, product_id) = stocked_store(&app, "keepcost@example.com").await;
    let stocker = app.staff(&owner, "Ben", &["manage_products"]).await;

    let mut edited = product(product_id, "Coke 1.5L");
    edited["cost_price"] = json!(0);
    edited["selling_price"] = json!(18);
    let (applied, rejected) = app
        .push_verdicts(&stocker, json!({ "products": [edited] }))
        .await;
    assert!(rejected.is_empty(), "{rejected:?}");
    assert_eq!(applied.len(), 1);

    let (_, saved) = app
        .call(
            Method::GET,
            &format!("/stores/{}/products/{product_id}", owner.store_id),
            Some(&owner.token),
            None,
        )
        .await;
    assert_eq!(saved["selling_price"], 18.0);
    assert_eq!(saved["cost_price"], 10.0, "the cost the owner set survives");
}

#[sqlx::test(migrations = "./migrations")]
async fn a_granted_permission_applies_without_signing_out(pool: PgPool) {
    let app = TestApp::new(pool);
    let (owner, _) = stocked_store(&app, "grant@example.com").await;
    let (staff_id, code) = app.add_staff(&owner, "Liza", &[]).await;
    let cashier = app.join(&code).await;

    let before = app.pull(&cashier, None).await;
    assert_eq!(before["expenses"], json!([]));

    let (status, _) = app
        .call(
            Method::PATCH,
            &format!("/stores/{}/staff/{staff_id}", owner.store_id),
            Some(&owner.token),
            Some(json!({ "display_name": "Liza", "permissions": ["view_profit"] })),
        )
        .await;
    assert_eq!(status, StatusCode::OK);

    // Carrying on from the old cursor still brings the tables that were
    // withheld, from the beginning.
    let after = app.pull(&cashier, before["cursor"].as_str()).await;
    assert_eq!(after["expenses"].as_array().unwrap().len(), 1);
    assert_eq!(after["withdrawals"].as_array().unwrap().len(), 1);

    let (_, me) = app
        .call(Method::GET, "/auth/me", Some(&cashier.token), None)
        .await;
    assert_eq!(me["access"]["permissions"], json!(["view_profit"]));
}

#[sqlx::test(migrations = "./migrations")]
async fn removing_a_staff_member_signs_out_their_phone(pool: PgPool) {
    let app = TestApp::new(pool);
    let owner = app.register("remove@example.com").await;
    let (staff_id, code) = app.add_staff(&owner, "Liza", &[]).await;
    let cashier = app.join(&code).await;

    let (status, _) = app
        .call(
            Method::DELETE,
            &format!("/stores/{}/staff/{staff_id}", owner.store_id),
            Some(&owner.token),
            None,
        )
        .await;
    assert_eq!(status, StatusCode::NO_CONTENT);

    let (pull, _) = app
        .call(
            Method::GET,
            &format!("/stores/{}/sync/pull", owner.store_id),
            Some(&cashier.token),
            None,
        )
        .await;
    assert_eq!(pull, StatusCode::UNAUTHORIZED);
    assert_eq!(
        app.refresh(&cashier.refresh_token).await.0,
        StatusCode::UNAUTHORIZED
    );

    let (_, staff) = app
        .call(
            Method::GET,
            &format!("/stores/{}/staff", owner.store_id),
            Some(&owner.token),
            None,
        )
        .await;
    assert_eq!(staff, json!([]));
}

#[sqlx::test(migrations = "./migrations")]
async fn staff_stay_inside_their_store_and_out_of_owner_settings(pool: PgPool) {
    let app = TestApp::new(pool);
    let owner = app.register("fence@example.com").await;
    let cashier = app
        .staff(&owner, "Liza", &["view_profit", "manage_products"])
        .await;

    let (_, second) = app
        .call(
            Method::POST,
            "/stores",
            Some(&owner.token),
            Some(json!({ "name": "Branch 2" })),
        )
        .await;
    let other_store = second["id"].as_str().unwrap();

    let forbidden: Vec<(Method, String)> = vec![
        (Method::GET, format!("/stores/{other_store}/sync/pull")),
        (Method::GET, format!("/stores/{}/staff", owner.store_id)),
        (Method::GET, format!("/stores/{}/activity", owner.store_id)),
        (Method::GET, "/devices".to_owned()),
    ];
    for (method, path) in forbidden {
        let (status, body) = app.call(method, &path, Some(&cashier.token), None).await;
        assert_eq!(status, StatusCode::FORBIDDEN, "{path}: {body}");
    }

    let (status, _): (StatusCode, Value) = app
        .call(
            Method::POST,
            "/stores",
            Some(&cashier.token),
            Some(json!({ "name": "Liza's own store" })),
        )
        .await;
    assert_eq!(status, StatusCode::FORBIDDEN);
}
