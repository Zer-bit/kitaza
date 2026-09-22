use axum::Json;
use axum::extract::{Query, State};
use serde::{Deserialize, Serialize};

use crate::application::AppState;
use crate::features::stores::StoreScope;
use crate::shared::ApiResult;

use super::audit_trail::{AuditEventView, AuditFilter};

const DEFAULT_PAGE: i64 = 50;

#[derive(Debug, Deserialize)]
pub struct ActivityQuery {
    #[serde(default)]
    pub before: Option<i64>,
    #[serde(default)]
    pub limit: Option<i64>,
    #[serde(default)]
    pub filter: AuditFilter,
}

#[derive(Debug, Serialize)]
pub struct ActivityPage {
    pub events: Vec<AuditEventView>,
    /// Pass as `before` for the next, older page. Absent on the last page.
    #[serde(skip_serializing_if = "Option::is_none")]
    pub next_before: Option<i64>,
}

pub async fn list_activity(
    State(state): State<AppState>,
    scope: StoreScope,
    Query(query): Query<ActivityQuery>,
) -> ApiResult<Json<ActivityPage>> {
    scope.actor.require_owner()?;

    let limit = query.limit.unwrap_or(DEFAULT_PAGE);
    let events = state
        .audit_trail
        .page(
            scope.actor.owner_id,
            scope.store_id,
            query.filter,
            query.before,
            limit,
        )
        .await?;

    let next_before = (events.len() as i64 >= limit.clamp(1, 100))
        .then(|| events.last().map(|event| event.seq))
        .flatten();

    Ok(Json(ActivityPage {
        events,
        next_before,
    }))
}
