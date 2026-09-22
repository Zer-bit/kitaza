use chrono::Utc;
use uuid::Uuid;

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
}

impl ExpenseService {
    pub fn new(
        repository: ExpenseRepository,
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
        request: RecordExpenseRequest,
    ) -> ApiResult<ExpenseView> {
        let category = ExpenseCategory::parse(&request.category)?;
        let description = request
            .description
            .as_deref()
            .map(str::trim)
            .filter(|value| !value.is_empty());

        let expense = self
            .repository
            .upsert(
                store_id,
                request.id.unwrap_or_else(Uuid::new_v4),
                category.as_str(),
                description,
                money_from_f64(request.amount),
                request.occurred_at.unwrap_or_else(Utc::now),
            )
            .await?;

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

    pub async fn remove(&self, store_id: Uuid, expense_id: Uuid) -> ApiResult<()> {
        if !self.repository.soft_delete(store_id, expense_id).await? {
            return Err(ApiError::NotFound("expense"));
        }

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
