use chrono::Utc;
use serde_json::json;
use uuid::Uuid;

use crate::features::access::Actor;
use crate::features::audit::{AuditAction, AuditEntry, AuditTrail};
use crate::features::products::foreign_id;
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
    audit: AuditTrail,
}

impl WithdrawalService {
    pub fn new(
        repository: WithdrawalRepository,
        cache: DashboardCache,
        broadcaster: EventBroadcaster,
        audit: AuditTrail,
    ) -> Self {
        Self {
            repository,
            cache,
            broadcaster,
            audit,
        }
    }

    /// Withdrawals are the owner's own money, so only the owner records them.
    pub async fn record(
        &self,
        store_id: Uuid,
        actor: &Actor,
        request: RecordWithdrawalRequest,
    ) -> ApiResult<WithdrawalView> {
        actor.require_owner()?;

        let reason = request
            .reason
            .as_deref()
            .map(str::trim)
            .filter(|value| !value.is_empty());

        let (withdrawal, inserted) = self
            .repository
            .upsert(
                store_id,
                request.id.unwrap_or_else(Uuid::new_v4),
                money_from_f64(request.amount),
                reason,
                request.occurred_at.unwrap_or_else(Utc::now),
            )
            .await?
            .ok_or_else(foreign_id)?;

        if inserted {
            self.audit
                .record(
                    actor,
                    AuditEntry::new(
                        store_id,
                        AuditAction::WithdrawalRecorded,
                        withdrawal.id,
                        json!({ "amount": withdrawal.amount }),
                    )
                    .at(withdrawal.occurred_at),
                )
                .await;
        }

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

    pub async fn remove(
        &self,
        store_id: Uuid,
        actor: &Actor,
        withdrawal_id: Uuid,
    ) -> ApiResult<()> {
        actor.require_owner()?;

        let removed = self
            .repository
            .soft_delete(store_id, withdrawal_id)
            .await?
            .ok_or(ApiError::NotFound("withdrawal"))?;

        self.audit
            .record(
                actor,
                AuditEntry::new(
                    store_id,
                    AuditAction::WithdrawalDeleted,
                    withdrawal_id,
                    json!({ "amount": removed.amount }),
                ),
            )
            .await;

        self.cache.invalidate_store(store_id).await;
        Ok(())
    }
}
