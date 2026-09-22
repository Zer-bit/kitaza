use axum::Json;
use axum::extract::State;
use axum::http::StatusCode;

use crate::application::AppState;
use crate::features::access::CurrentActor;
use crate::shared::{ApiResult, ValidatedJson};

use super::diagnostics_payloads::{ReportErrorsRequest, ReportErrorsResponse};

pub async fn report_errors(
    State(state): State<AppState>,
    CurrentActor(actor): CurrentActor,
    ValidatedJson(request): ValidatedJson<ReportErrorsRequest>,
) -> ApiResult<(StatusCode, Json<ReportErrorsResponse>)> {
    let response = state
        .diagnostics_service
        .report(actor.owner_id, request)
        .await?;
    Ok((StatusCode::ACCEPTED, Json(response)))
}
