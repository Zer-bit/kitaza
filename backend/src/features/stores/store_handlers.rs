use axum::Json;
use axum::extract::State;
use axum::http::StatusCode;
use serde::Deserialize;
use serde_json::json;
use validator::Validate;

use crate::application::AppState;
use crate::features::access::CurrentOwner;
use crate::features::audit::{AuditAction, AuditEntry};
use crate::features::authentication::{StoreRecord, StoreSummary, to_summary};
use crate::shared::{ApiError, ApiResult, ValidatedJson};

use super::store_scope::StoreScope;

const DEFAULT_BUSINESS_TYPE: &str = "sari_sari";

#[derive(Debug, Deserialize, Validate)]
pub struct CreateStoreRequest {
    #[validate(length(min = 2, max = 80, message = "must be between 2 and 80 characters"))]
    pub name: String,

    #[serde(default)]
    pub business_type: Option<String>,
}

#[derive(Debug, Deserialize, Validate)]
pub struct UpdateStoreRequest {
    #[serde(default)]
    #[validate(length(min = 2, max = 80, message = "must be between 2 and 80 characters"))]
    pub name: Option<String>,

    /// Whether this store's figures join the anonymous comparisons.
    #[serde(default)]
    pub share_benchmarks: Option<bool>,
}

/// A second branch, or a carinderia next to the sari-sari store. Each store
/// keeps its own products, sales and staff.
pub async fn create_store(
    State(state): State<AppState>,
    CurrentOwner(owner): CurrentOwner,
    ValidatedJson(request): ValidatedJson<CreateStoreRequest>,
) -> ApiResult<(StatusCode, Json<StoreSummary>)> {
    state.billing_service.check_new_store(&owner).await?;

    let store = sqlx::query_as::<_, StoreRecord>(
        "INSERT INTO stores (owner_id, name, business_type) VALUES ($1, $2, $3)
         RETURNING id, name, business_type, currency_code, share_benchmarks",
    )
    .bind(owner.owner_id)
    .bind(request.name.trim())
    .bind(
        request
            .business_type
            .as_deref()
            .unwrap_or(DEFAULT_BUSINESS_TYPE),
    )
    .fetch_one(&state.pool)
    .await?;

    state
        .audit_trail
        .record(
            &owner,
            AuditEntry::new(
                store.id,
                AuditAction::StoreAdded,
                store.id,
                json!({ "name": store.name }),
            ),
        )
        .await;

    Ok((StatusCode::CREATED, Json(to_summary(&store))))
}

pub async fn update_store(
    State(state): State<AppState>,
    scope: StoreScope,
    ValidatedJson(request): ValidatedJson<UpdateStoreRequest>,
) -> ApiResult<Json<StoreSummary>> {
    scope.actor.require_owner()?;

    let renamed: Option<(String, StoreRecord)> = sqlx::query_as::<_, RenamedStore>(
        // The self-join reads the row as it was before this update. Either
        // field may be left out, and keeps its value.
        "UPDATE stores s SET
             name = COALESCE($2, s.name),
             share_benchmarks = COALESCE($3, s.share_benchmarks),
             updated_at = now()
         FROM stores before
         WHERE s.id = $1 AND before.id = s.id
         RETURNING before.name AS old_name, s.id, s.name, s.business_type, s.currency_code,
                   s.share_benchmarks",
    )
    .bind(scope.store_id)
    .bind(request.name.as_deref().map(str::trim))
    .bind(request.share_benchmarks)
    .fetch_optional(&state.pool)
    .await?
    .map(|row| (row.old_name, row.store));

    let (old_name, store) = renamed.ok_or(ApiError::NotFound("store"))?;

    if old_name != store.name {
        state
            .audit_trail
            .record(
                &scope.actor,
                AuditEntry::new(
                    store.id,
                    AuditAction::StoreRenamed,
                    store.id,
                    json!({ "name": store.name, "old_name": old_name }),
                ),
            )
            .await;
    }

    Ok(Json(to_summary(&store)))
}

#[derive(sqlx::FromRow)]
struct RenamedStore {
    old_name: String,
    #[sqlx(flatten)]
    store: StoreRecord,
}
