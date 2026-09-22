use uuid::Uuid;

use crate::infrastructure::cache::{RateLimitVerdict, RateLimiter};
use crate::shared::{ApiError, ApiResult};

use super::diagnostics_payloads::{ReportErrorsRequest, ReportErrorsResponse};
use super::diagnostics_repository::DiagnosticsRepository;

#[derive(Clone)]
pub struct DiagnosticsService {
    repository: DiagnosticsRepository,
    rate_limiter: RateLimiter,
}

impl DiagnosticsService {
    pub fn new(repository: DiagnosticsRepository, rate_limiter: RateLimiter) -> Self {
        Self {
            repository,
            rate_limiter,
        }
    }

    /// Rate limited per owner, so a phone stuck in a crash loop cannot flood
    /// the table. Like login throttling it fails open when Redis is down.
    pub async fn report(
        &self,
        owner_id: Uuid,
        request: ReportErrorsRequest,
    ) -> ApiResult<ReportErrorsResponse> {
        if matches!(
            self.rate_limiter
                .check(&format!("diagnostics:{owner_id}"))
                .await,
            RateLimitVerdict::Exceeded
        ) {
            return Err(ApiError::TooManyRequests);
        }

        self.repository.record(owner_id, &request.reports).await?;
        Ok(ReportErrorsResponse {
            accepted: request.reports.len(),
        })
    }
}
