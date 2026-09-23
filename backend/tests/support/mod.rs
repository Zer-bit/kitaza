//! Shared harness: a real router over a real, freshly migrated database, driven
//! through HTTP exactly as the app drives it.

#![allow(dead_code)]

use std::net::SocketAddr;
use std::time::Duration;

use axum::Router;
use axum::body::Body;
use axum::http::{Method, Request, StatusCode};
use chrono::{DateTime, Utc};
use http_body_util::BodyExt;
use kitaza_server::application::{AppState, build_router};
use kitaza_server::config::{
    AppSettings, BillingMode, BillingSettings, DatabaseSettings, PrivacySettings, RedisSettings,
    SecuritySettings, ServerSettings, SyncSettings,
};
use kitaza_server::features::privacy::{LegalDocument, RetentionPolicy};
use kitaza_server::infrastructure::cache::CacheHandle;
use serde_json::{Value, json};
use sqlx::PgPool;
use tokio::net::TcpListener;
use tokio::task::JoinHandle;
use tower::ServiceExt;
use uuid::Uuid;

pub struct TestApp {
    router: Router,
    pub state: AppState,
    pub pool: PgPool,
}

/// A signed-in device: the owner's, or a staff member's.
pub struct Owner {
    pub token: String,
    pub refresh_token: String,
    pub session_id: Uuid,
    pub store_id: Uuid,
}

impl Owner {
    fn from_session(body: &Value) -> Self {
        Owner {
            token: body["access_token"].as_str().unwrap().to_owned(),
            refresh_token: body["refresh_token"].as_str().unwrap().to_owned(),
            session_id: body["session_id"].as_str().unwrap().parse().unwrap(),
            store_id: body["stores"][0]["id"].as_str().unwrap().parse().unwrap(),
        }
    }

    /// The same person on another store of theirs.
    pub fn in_store(&self, store_id: Uuid) -> Owner {
        Owner {
            token: self.token.clone(),
            refresh_token: self.refresh_token.clone(),
            session_id: self.session_id,
            store_id,
        }
    }
}

impl TestApp {
    pub fn new(pool: PgPool) -> Self {
        Self::with_page_size(pool, 500)
    }

    /// A small page size lets pagination be tested with a handful of rows
    /// instead of thousands.
    pub fn with_page_size(pool: PgPool, page_size: i64) -> Self {
        Self::build(pool, settings(page_size, BillingMode::Off))
    }

    /// Plans enforced, with the test gateway taking "payments".
    pub fn with_billing(pool: PgPool) -> Self {
        Self::build(pool, settings(500, BillingMode::Test))
    }

    /// Pings realtime sockets many times a second, so a test can watch what
    /// the keepalive does without waiting the production twenty-five.
    pub fn with_brisk_keepalive(pool: PgPool) -> Self {
        let mut settings = settings(500, BillingMode::Off);
        settings.server.realtime_keepalive = Duration::from_millis(100);
        Self::build(pool, settings)
    }

    /// The router on a real TCP port. A websocket cannot be driven through
    /// `oneshot` - only a real connection carries an upgrade - so the socket
    /// tests talk to this instead.
    pub async fn serve(&self) -> ServedApp {
        let listener = TcpListener::bind(SocketAddr::from(([127, 0, 0, 1], 0)))
            .await
            .expect("no free port");
        let address = listener.local_addr().unwrap();
        let router = self.router.clone();
        let server = tokio::spawn(async move {
            let _ = axum::serve(listener, router.into_make_service()).await;
        });
        ServedApp { address, server }
    }

    fn build(pool: PgPool, settings: AppSettings) -> Self {
        let state = AppState::assemble(&settings, pool.clone(), CacheHandle::disabled());
        let router = build_router(state.clone(), &settings.server);
        Self {
            router,
            state,
            pool,
        }
    }

    pub async fn call(
        &self,
        method: Method,
        path: &str,
        token: Option<&str>,
        body: Option<Value>,
    ) -> (StatusCode, Value) {
        self.call_raw(method, &format!("/api/v1{path}"), token, body)
            .await
    }

    /// For the plain pages outside the API prefix. Non-JSON bodies come back
    /// as `Value::Null`.
    pub async fn call_raw(
        &self,
        method: Method,
        path: &str,
        token: Option<&str>,
        body: Option<Value>,
    ) -> (StatusCode, Value) {
        let mut request = Request::builder()
            .method(method)
            .uri(path)
            .header("content-type", "application/json");
        if let Some(token) = token {
            request = request.header("authorization", format!("Bearer {token}"));
        }

        let body = body
            .map(|value| Body::from(value.to_string()))
            .unwrap_or_default();
        let response = self
            .router
            .clone()
            .oneshot(request.body(body).unwrap())
            .await
            .unwrap();

        let status = response.status();
        let bytes = response.into_body().collect().await.unwrap().to_bytes();
        let value = if bytes.is_empty() {
            Value::Null
        } else {
            serde_json::from_slice(&bytes).unwrap_or(Value::Null)
        };
        (status, value)
    }

    pub async fn register(&self, email: &str) -> Owner {
        let (status, body) = self
            .call(
                Method::POST,
                "/auth/register",
                None,
                Some(json!({
                    "email": email,
                    "password": "a-good-password",
                    "full_name": "Test Owner",
                    "store_name": "Test Store",
                    "accepted_privacy_version":
                        LegalDocument::PrivacyNotice.current_version(),
                    "accepted_terms_version": LegalDocument::Terms.current_version(),
                })),
            )
            .await;
        assert_eq!(status, StatusCode::CREATED, "register failed: {body}");
        Owner::from_session(&body)
    }

    /// The same owner signing in on another phone.
    pub async fn sign_in(&self, email: &str, device_name: &str) -> Owner {
        let (status, body) = self
            .call(
                Method::POST,
                "/auth/login",
                None,
                Some(json!({
                    "email": email,
                    "password": "a-good-password",
                    "device_name": device_name,
                })),
            )
            .await;
        assert_eq!(status, StatusCode::OK, "sign-in failed: {body}");
        Owner::from_session(&body)
    }

    /// Adds a staff member and returns their id and join code.
    pub async fn add_staff(
        &self,
        owner: &Owner,
        name: &str,
        permissions: &[&str],
    ) -> (Uuid, String) {
        let (status, body) = self
            .call(
                Method::POST,
                &format!("/stores/{}/staff", owner.store_id),
                Some(&owner.token),
                Some(json!({ "display_name": name, "permissions": permissions })),
            )
            .await;
        assert_eq!(status, StatusCode::CREATED, "adding staff failed: {body}");
        (
            body["staff"]["id"].as_str().unwrap().parse().unwrap(),
            body["invite"]["code"].as_str().unwrap().to_owned(),
        )
    }

    pub async fn try_join(&self, code: &str) -> (StatusCode, Value) {
        self.call(
            Method::POST,
            "/auth/join",
            None,
            Some(json!({ "code": code, "device_name": "Counter phone" })),
        )
        .await
    }

    /// A staff member's phone joining with a code.
    pub async fn join(&self, code: &str) -> Owner {
        let (status, body) = self.try_join(code).await;
        assert_eq!(status, StatusCode::OK, "join failed: {body}");
        Owner::from_session(&body)
    }

    /// A staff member with the given permissions, already signed in.
    pub async fn staff(&self, owner: &Owner, name: &str, permissions: &[&str]) -> Owner {
        let (_, code) = self.add_staff(owner, name, permissions).await;
        self.join(&code).await
    }

    pub async fn refresh(&self, refresh_token: &str) -> (StatusCode, Value) {
        self.call(
            Method::POST,
            "/auth/refresh",
            None,
            Some(json!({ "refresh_token": refresh_token })),
        )
        .await
    }

    pub async fn push(&self, owner: &Owner, batch: Value) -> Value {
        let (status, body) = self
            .call(
                Method::POST,
                &format!("/stores/{}/sync/push", owner.store_id),
                Some(&owner.token),
                Some(batch),
            )
            .await;
        assert_eq!(status, StatusCode::OK, "push failed: {body}");
        body
    }

    /// The server's verdict on each row, as `(entity, id)` pairs.
    pub async fn push_verdicts(&self, device: &Owner, batch: Value) -> (Vec<String>, Vec<String>) {
        let result = self.push(device, batch).await;
        let pairs = |key: &str| {
            result[key]
                .as_array()
                .unwrap()
                .iter()
                .map(|row| {
                    format!(
                        "{}:{}",
                        row["entity"].as_str().unwrap(),
                        row["id"].as_str().unwrap_or("-")
                    )
                })
                .collect::<Vec<_>>()
        };
        (pairs("applied"), pairs("rejected"))
    }

    pub async fn activity(&self, owner: &Owner, query: &str) -> Value {
        let (status, body) = self
            .call(
                Method::GET,
                &format!("/stores/{}/activity{query}", owner.store_id),
                Some(&owner.token),
                None,
            )
            .await;
        assert_eq!(status, StatusCode::OK, "activity failed: {body}");
        body
    }

    pub async fn pull(&self, owner: &Owner, cursor: Option<&str>) -> Value {
        let path = match cursor {
            Some(cursor) => format!("/stores/{}/sync/pull?cursor={cursor}", owner.store_id),
            None => format!("/stores/{}/sync/pull", owner.store_id),
        };
        let (status, body) = self
            .call(Method::GET, &path, Some(&owner.token), None)
            .await;
        assert_eq!(status, StatusCode::OK, "pull failed: {body}");
        body
    }

    pub async fn stock_of(&self, owner: &Owner, product_id: Uuid) -> f64 {
        let (status, body) = self
            .call(
                Method::GET,
                &format!("/stores/{}/products/{product_id}", owner.store_id),
                Some(&owner.token),
                None,
            )
            .await;
        assert_eq!(status, StatusCode::OK, "product lookup failed: {body}");
        body["stock_quantity"].as_f64().unwrap()
    }
}

/// The test router listening on a loopback port for as long as it is held.
pub struct ServedApp {
    pub address: SocketAddr,
    server: JoinHandle<()>,
}

impl ServedApp {
    /// The websocket URL a phone would open for a store.
    pub fn socket_url(&self, store_id: Uuid, token: &str) -> String {
        format!("ws://{}/ws/store/{store_id}?token={token}", self.address)
    }
}

impl Drop for ServedApp {
    fn drop(&mut self) {
        self.server.abort();
    }
}

/// A product as a device sends it: stock always starts at zero and arrives
/// through the ledger.
pub fn product(id: Uuid, name: &str) -> Value {
    json!({
        "id": id, "name": name, "cost_price": 10, "selling_price": 15,
        "opening_stock": 0, "reorder_level": 2,
    })
}

pub fn movement(id: Uuid, product_id: Uuid, kind: &str, quantity: f64, at: DateTime<Utc>) -> Value {
    json!({
        "id": id, "product_id": product_id, "movement": kind,
        "quantity": quantity, "occurred_at": at,
    })
}

pub fn sale(id: Uuid, product_id: Uuid, quantity: f64, at: DateTime<Utc>) -> Value {
    json!({
        "id": id, "occurred_at": at,
        "items": [{ "id": Uuid::new_v4(), "product_id": product_id, "quantity": quantity }],
    })
}

pub fn ids_of(rows: &Value) -> Vec<String> {
    rows.as_array()
        .unwrap()
        .iter()
        .map(|row| row["id"].as_str().unwrap().to_owned())
        .collect()
}

fn settings(page_size: i64, billing: BillingMode) -> AppSettings {
    AppSettings {
        server: ServerSettings {
            bind_address: SocketAddr::from(([127, 0, 0, 1], 0)),
            allowed_origins: vec!["*".into()],
            request_timeout_seconds: 30,
            max_body_bytes: 4 * 1024 * 1024,
            realtime_keepalive: Duration::from_secs(25),
        },
        database: DatabaseSettings {
            url: String::new(),
            max_connections: 5,
            min_connections: 0,
            acquire_timeout: Duration::from_secs(5),
            run_migrations_on_boot: false,
        },
        redis: RedisSettings {
            url: String::new(),
            dashboard_cache_ttl_seconds: 30,
            login_attempt_limit: 100,
            login_attempt_window_seconds: 60,
        },
        security: SecuritySettings {
            jwt_secret: "integration-tests-secret-comfortably-over-32-chars".into(),
            access_token_lifetime: chrono::Duration::minutes(10),
            refresh_token_lifetime: chrono::Duration::days(1),
        },
        // Rows are visible to a pull as soon as they are written; the settle
        // window is a production safeguard against in-flight transactions.
        sync: SyncSettings {
            settle_window: Duration::ZERO,
            page_size,
        },
        privacy: PrivacySettings {
            deletion_grace: chrono::Duration::days(30),
            retention: RetentionPolicy::default(),
        },
        billing: BillingSettings {
            mode: billing,
            public_url: "http://kitaza.test".into(),
            trial: chrono::Duration::days(30),
            grace: chrono::Duration::days(7),
        },
    }
}
