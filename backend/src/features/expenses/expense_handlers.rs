use axum::Json;
use axum::extract::{Path, Query, State};
use axum::http::StatusCode;
use uuid::Uuid;

use crate::application::AppState;
use crate::features::stores::StoreScope;
use crate::shared::{ApiResult, PageRequest, ValidatedJson};

use super::expense_payloads::{ExpenseFilter, ExpenseView, RecordExpenseRequest};

pub async fn record_expense(
    State(state): State<AppState>,
    scope: StoreScope,
    ValidatedJson(request): ValidatedJson<RecordExpenseRequest>,
) -> ApiResult<(StatusCode, Json<ExpenseView>)> {
    let expense = state
        .expense_service
        .record(scope.store_id, request)
        .await?;
    Ok((StatusCode::CREATED, Json(expense)))
}

pub async fn list_expenses(
    State(state): State<AppState>,
    scope: StoreScope,
    Query(filter): Query<ExpenseFilter>,
    Query(page): Query<PageRequest>,
) -> ApiResult<Json<Vec<ExpenseView>>> {
    Ok(Json(
        state
            .expense_service
            .list(scope.store_id, filter, page)
            .await?,
    ))
}

pub async fn delete_expense(
    State(state): State<AppState>,
    scope: StoreScope,
    Path((_store_id, expense_id)): Path<(Uuid, Uuid)>,
) -> ApiResult<StatusCode> {
    state
        .expense_service
        .remove(scope.store_id, expense_id)
        .await?;
    Ok(StatusCode::NO_CONTENT)
}

pub async fn list_categories(State(state): State<AppState>) -> Json<Vec<&'static str>> {
    Json(state.expense_service.categories())
}
