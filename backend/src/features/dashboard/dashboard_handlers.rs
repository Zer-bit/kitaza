use axum::Json;
use axum::extract::{Query, State};

use crate::application::AppState;
use crate::features::access::Permission;
use crate::features::stores::StoreScope;
use crate::shared::ApiResult;

use super::dashboard_payloads::{DashboardQuery, DashboardSummary};

pub async fn store_summary(
    State(state): State<AppState>,
    scope: StoreScope,
    Query(query): Query<DashboardQuery>,
) -> ApiResult<Json<DashboardSummary>> {
    scope.actor.require(Permission::ViewProfit)?;
    Ok(Json(
        state
            .dashboard_service
            .summary(scope.store_id, query)
            .await?,
    ))
}
