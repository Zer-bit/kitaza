use axum::Json;
use axum::body::Bytes;
use axum::extract::{Path, Query, State};
use axum::http::{HeaderMap, StatusCode};
use axum::response::Html;
use serde::Deserialize;
use uuid::Uuid;

use crate::application::AppState;
use crate::features::access::CurrentOwner;
use crate::shared::{ApiError, ApiResult, ValidatedJson};

use super::billing_pages;
use super::billing_payloads::{BillingOverview, CheckoutRequestBody, CheckoutView};

pub async fn overview(
    State(state): State<AppState>,
    CurrentOwner(owner): CurrentOwner,
) -> ApiResult<Json<BillingOverview>> {
    Ok(Json(state.billing_service.overview(owner.owner_id).await?))
}

pub async fn checkout(
    State(state): State<AppState>,
    CurrentOwner(owner): CurrentOwner,
    ValidatedJson(request): ValidatedJson<CheckoutRequestBody>,
) -> ApiResult<(StatusCode, Json<CheckoutView>)> {
    let checkout = state
        .billing_service
        .checkout(&owner, request.plan, request.months)
        .await?;
    Ok((StatusCode::CREATED, Json(checkout)))
}

/// Takes the raw body: the signature covers the exact bytes sent, which a
/// re-serialised JSON value would not reproduce.
pub async fn paymongo_webhook(
    State(state): State<AppState>,
    headers: HeaderMap,
    body: Bytes,
) -> ApiResult<StatusCode> {
    let signature = headers
        .get("paymongo-signature")
        .and_then(|value| value.to_str().ok())
        .ok_or_else(|| ApiError::Unauthorized("missing webhook signature".into()))?;

    state
        .billing_service
        .paymongo_webhook(signature, &body)
        .await?;
    Ok(StatusCode::OK)
}

#[derive(Deserialize)]
pub struct ReturnQuery {
    #[serde(default)]
    paid: Option<String>,
}

/// Where the gateway sends the owner's browser afterwards.
pub async fn checkout_return(Query(query): Query<ReturnQuery>) -> Html<String> {
    Html(billing_pages::returned(query.paid.is_some()))
}

pub async fn test_checkout_page(
    State(state): State<AppState>,
    Path(payment_id): Path<Uuid>,
) -> ApiResult<Html<String>> {
    let amount = state
        .billing_service
        .test_checkout_amount(payment_id)
        .await?
        .ok_or(ApiError::NotFound("checkout"))?;
    Ok(Html(billing_pages::test_checkout(payment_id, &amount)))
}

pub async fn test_checkout_pay(
    State(state): State<AppState>,
    Path(payment_id): Path<Uuid>,
) -> ApiResult<Html<String>> {
    state.billing_service.pay_test_checkout(payment_id).await?;
    Ok(Html(billing_pages::returned(true)))
}
