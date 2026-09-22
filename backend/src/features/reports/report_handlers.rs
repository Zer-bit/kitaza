use axum::Json;
use axum::extract::{Query, State};

use crate::application::AppState;
use crate::features::access::Permission;
use crate::features::stores::StoreScope;
use crate::shared::ApiResult;

use super::report_payloads::{
    ExpenseSlice, ProductPerformance, ProfitTrend, ReportQuery, TrendQuery, UnusualExpense,
    WeeklySummary,
};

pub async fn profit_trend(
    State(state): State<AppState>,
    scope: StoreScope,
    Query(query): Query<TrendQuery>,
) -> ApiResult<Json<ProfitTrend>> {
    scope.actor.require(Permission::ViewProfit)?;
    Ok(Json(
        state
            .report_service
            .profit_trend(scope.store_id, query)
            .await?,
    ))
}

pub async fn top_products(
    State(state): State<AppState>,
    scope: StoreScope,
    Query(query): Query<ReportQuery>,
) -> ApiResult<Json<Vec<ProductPerformance>>> {
    scope.actor.require(Permission::ViewProfit)?;
    Ok(Json(
        state
            .report_service
            .top_products(scope.store_id, query)
            .await?,
    ))
}

pub async fn expense_breakdown(
    State(state): State<AppState>,
    scope: StoreScope,
    Query(query): Query<ReportQuery>,
) -> ApiResult<Json<Vec<ExpenseSlice>>> {
    scope.actor.require(Permission::ViewProfit)?;
    Ok(Json(
        state
            .report_service
            .expense_breakdown(scope.store_id, query)
            .await?,
    ))
}

pub async fn unusual_expenses(
    State(state): State<AppState>,
    scope: StoreScope,
) -> ApiResult<Json<Vec<UnusualExpense>>> {
    scope.actor.require(Permission::ViewProfit)?;
    Ok(Json(
        state
            .report_service
            .unusual_expenses(scope.store_id)
            .await?,
    ))
}

pub async fn periodic_summary(
    State(state): State<AppState>,
    scope: StoreScope,
    Query(query): Query<ReportQuery>,
) -> ApiResult<Json<WeeklySummary>> {
    scope.actor.require(Permission::ViewProfit)?;
    Ok(Json(
        state
            .report_service
            .periodic_summary(scope.store_id, query)
            .await?,
    ))
}
