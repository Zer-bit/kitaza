use std::time::Duration;

use super::parsed;

#[derive(Debug, Clone)]
pub struct SyncSettings {
    /// Rows younger than this are held back from a pull. `updated_at` is set
    /// when a transaction starts, not when it commits, so without a margin a
    /// slow transaction could commit behind a cursor that has already moved
    /// past it, and that row would never be pulled.
    pub settle_window: Duration,

    /// Maximum rows per table in one pull. The client keeps pulling while the
    /// server reports `has_more`.
    pub page_size: i64,
}

impl SyncSettings {
    pub fn from_environment() -> anyhow::Result<Self> {
        Ok(Self {
            settle_window: Duration::from_millis(parsed("KITAZA_SYNC_SETTLE_MS", 2_000)?),
            page_size: parsed("KITAZA_SYNC_PAGE_SIZE", 500)?,
        })
    }
}
