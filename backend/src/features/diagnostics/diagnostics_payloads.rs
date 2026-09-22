use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use validator::Validate;

#[derive(Debug, Deserialize, Validate)]
pub struct ReportErrorsRequest {
    /// At most twenty per request. A phone holds at most fifty, so that is a
    /// few requests at worst, and it bounds the work any one request can do.
    #[validate(length(min = 1, max = 20, message = "must hold between 1 and 20 reports"))]
    #[validate(nested)]
    pub reports: Vec<ErrorReportPayload>,
}

// `Serialize` is required by validator to report which report failed.
#[derive(Debug, Serialize, Deserialize, Validate)]
pub struct ErrorReportPayload {
    #[validate(length(min = 1, max = 32, message = "is required"))]
    pub fingerprint: String,

    #[validate(length(min = 1, max = 200, message = "must be under 200 characters"))]
    pub error_type: String,

    #[validate(length(max = 2000, message = "must be under 2000 characters"))]
    pub message: String,

    #[serde(default)]
    #[validate(length(max = 16000, message = "must be under 16000 characters"))]
    pub stack: Option<String>,

    #[validate(range(min = 1, max = 1_000_000, message = "must be a positive count"))]
    pub occurrences: i64,

    pub first_seen: DateTime<Utc>,
    pub last_seen: DateTime<Utc>,

    #[validate(length(min = 1, max = 64, message = "is required"))]
    pub app_version: String,

    #[validate(length(min = 1, max = 128, message = "is required"))]
    pub platform: String,
}

#[derive(Debug, Serialize)]
pub struct ReportErrorsResponse {
    pub accepted: usize,
}
