use chrono::Utc;
use uuid::Uuid;

use crate::infrastructure::cache::DashboardCache;
use crate::infrastructure::realtime::{EventBroadcaster, RealtimeEvent, RealtimeTopic};
use crate::shared::{ApiError, ApiResult, PageRequest, money_from_f64};

use super::withdrawal_payloads::{RecordWithdrawalRequest, WithdrawalView};
use super::withdrawal_repository::WithdrawalRepository;

/// Money the owner takes out for personal use. Tracked separately from
/// expenses so profit stays honest: a withdrawal reduces cash, not profit.
#[derive(Clone)]
pub struct WithdrawalService {
    repository: WithdrawalRepository,
    cache: DashboardCache,
    broadcaster: EventBroadcaster,
}

impl WithdrawalService {
    pub fn new(
        repository: WithdrawalRepository,
        cache: DashboardCache,
        broadcaster: EventBroadcaster,
    ) -> Self {
        Self {
            repository,
            cache,
            broadcaster,
        }
    }

    pub async fn record(
        &self,
        store_id: Uuid,
        request: RecordWithdrawalRequest,
    ) -> ApiResult<WithdrawalView> {
        let reason = request
            .reason
            .as_deref()
            .map(str::trim)
            .filter(|value| !value.is_empty());

        let withdrawal = self
            .repository
            .upsert(
                store_id,
                request.id.unwrap_or_else(Uuid::new_v4),
                money_from_f64(request.amount),
                reason,
                request.occurred_at.unwrap_or_else(Utc::now),
            )
            .await?;

        self.cache.invalidate_store(store_id).await;
        self.broadcaster
            .publish(RealtimeEvent::new(
                store_id,
                RealtimeTopic::WithdrawalRecorded,
                Some(withdrawal.id),
            ))
            .await;

        Ok(withdrawal)
    }

    pub async fn list(&self, store_id: Uuid, page: PageRequest) -> ApiResult<Vec<WithdrawalView>> {
        self.repository.list(store_id, page).await
    }

    pub async fn remove(&self, store_id: Uuid, withdrawal_id: Uuid) -> ApiResult<()> {
        if !self.repository.soft_delete(store_id, withdrawal_id).await? {
            return Err(ApiError::NotFound("withdrawal"));
        }

        self.cache.invalidate_store(store_id).await;
        Ok(())
    }
}
