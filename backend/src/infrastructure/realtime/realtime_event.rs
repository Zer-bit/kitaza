use serde::{Deserialize, Serialize};
use uuid::Uuid;

/// What changed. The client uses the topic to decide which local cache to
/// refresh without re-fetching the whole dashboard.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum RealtimeTopic {
    SaleRecorded,
    SaleVoided,
    ExpenseRecorded,
    ExpenseRemoved,
    WithdrawalRecorded,
    ProductChanged,
    StockLow,
    DashboardStale,
    /// A staff member's permissions changed or they were removed: phones in
    /// the store should re-read what they may do.
    AccessChanged,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RealtimeEvent {
    pub store_id: Uuid,
    pub topic: RealtimeTopic,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub entity_id: Option<Uuid>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub message: Option<String>,
    pub emitted_at: chrono::DateTime<chrono::Utc>,
}

impl RealtimeEvent {
    pub fn new(store_id: Uuid, topic: RealtimeTopic, entity_id: Option<Uuid>) -> Self {
        Self {
            store_id,
            topic,
            entity_id,
            message: None,
            emitted_at: chrono::Utc::now(),
        }
    }

    pub fn with_message(mut self, message: impl Into<String>) -> Self {
        self.message = Some(message.into());
        self
    }
}
