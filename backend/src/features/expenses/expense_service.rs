use chrono::Utc;
use serde_json::json;
use uuid::Uuid;

use crate::features::access::{Actor, Permission};
use crate::features::audit::{AuditAction, AuditEntry, AuditTrail};
use crate::infrastructure::cache::DashboardCache;
use crate::infrastructure::realtime::{EventBroadcaster, RealtimeEvent, RealtimeTopic};
use crate::shared::{ApiError, ApiResult, PageRequest, money_from_f64};

use super::expense_category::ExpenseCategory;
use super::expense_payloads::{ExpenseFilter, ExpenseView, RecordExpenseRequest};
use super::expense_repository::ExpenseRepository;

#[derive(Clone)]
pub struct ExpenseService {
    repository: ExpenseRepository,
    cache: DashboardCache,
    broadcaster: EventBroadcaster,
    audit: AuditTrail,
}

impl ExpenseService {
    pub fn new(
        repository: ExpenseRepository,
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

    pub async fn record(
        &self,
        store_id: Uuid,
        actor: &Actor,
        request: RecordExpenseRequest,
    ) -> ApiResult<ExpenseView> {
        actor.require(Permission::RecordExpenses)?;

        let category = ExpenseCategory::parse(&request.category)?;
        let description = request
            .description
            .as_deref()
            .map(str::trim)
            .filter(|value| !value.is_empty());

        let saved = self
            .repository
            .upsert(
                store_id,
                request.id.unwrap_or_else(Uuid::new_v4),
                category.as_str(),
                description,
                money_from_f64(request.amount),
                request.occurred_at.unwrap_or_else(Utc::now),
                actor.staff_id(),
                actor.is_owner(),
            )
            .await?
            .ok_or_else(|| {
                ApiError::Forbidden(
                    "only the owner can change an expense someone else recorded".into(),
                )
            })?;
        let expense = saved.expense;

        if saved.inserted {
            self.audit
                .record(
                    actor,
                    AuditEntry::new(
                        store_id,
                        AuditAction::ExpenseRecorded,
                        expense.id,
                        json!({ "amount": expense.amount, "category": expense.category }),
                    )
                    .at(expense.occurred_at),
                )
                .await;
        }

        self.cache.invalidate_store(store_id).await;
        self.broadcaster
            .publish(RealtimeEvent::new(
                store_id,
                RealtimeTopic::ExpenseRecorded,
                Some(expense.id),
            ))
            .await;

        Ok(expense)
    }

    pub async fn list(
        &self,
        store_id: Uuid,
        filter: ExpenseFilter,
        page: PageRequest,
    ) -> ApiResult<Vec<ExpenseView>> {
        self.repository.list(store_id, &filter, page).await
    }

    pub async fn remove(&self, store_id: Uuid, actor: &Actor, expense_id: Uuid) -> ApiResult<()> {
        actor.require(Permission::DeleteRecords)?;

        let removed = self
            .repository
            .soft_delete(store_id, expense_id)
            .await?
            .ok_or(ApiError::NotFound("expense"))?;

        self.audit
            .record(
                actor,
                AuditEntry::new(
                    store_id,
                    AuditAction::ExpenseDeleted,
                    expense_id,
                    json!({ "amount": removed.amount, "category": removed.category }),
                ),
            )
            .await;

        self.cache.invalidate_store(store_id).await;
        self.broadcaster
            .publish(RealtimeEvent::new(
                store_id,
                RealtimeTopic::ExpenseRemoved,
                Some(expense_id),
            ))
            .await;

        Ok(())
    }

    pub fn categories(&self) -> Vec<&'static str> {
        ExpenseCategory::all().iter().map(|c| c.as_str()).collect()
    }
}
