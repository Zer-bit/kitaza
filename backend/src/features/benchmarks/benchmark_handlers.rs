use axum::Json;
use axum::extract::State;

use crate::application::AppState;
use crate::features::access::Permission;
use crate::features::stores::StoreScope;
use crate::shared::ApiResult;

use super::benchmark_payloads::BenchmarkReport;

pub async fn compare(
    State(state): State<AppState>,
    scope: StoreScope,
) -> ApiResult<Json<BenchmarkReport>> {
    scope.actor.require(Permission::ViewProfit)?;

    let shares = state
        .store_directory
        .shares_benchmarks(scope.store_id)
        .await?;
    Ok(Json(
        state
            .benchmark_service
            .compare(scope.store_id, shares)
            .await?,
    ))
}
