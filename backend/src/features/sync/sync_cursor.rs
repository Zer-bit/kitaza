use std::collections::BTreeMap;

use chrono::{DateTime, TimeZone, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

/// The tables a device pulls, each paged independently.
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum SyncTable {
    Products,
    Sales,
    Expenses,
    Withdrawals,
    StockMovements,
}

impl SyncTable {
    pub const ALL: [SyncTable; 5] = [
        SyncTable::Products,
        SyncTable::Sales,
        SyncTable::Expenses,
        SyncTable::Withdrawals,
        SyncTable::StockMovements,
    ];
}

/// Position within one table: the last row a device has seen, ordered by
/// `(updated_at, id)`. The id breaks ties between rows written in the same
/// transaction, which share a timestamp.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub struct TableMark {
    pub updated_at: DateTime<Utc>,
    pub id: Uuid,
}

impl TableMark {
    pub fn origin() -> Self {
        Self {
            updated_at: Utc.timestamp_opt(0, 0).single().unwrap_or_else(Utc::now),
            id: Uuid::nil(),
        }
    }
}

/// Where a device is up to, per table. Handed to the client as an opaque
/// string so the format can change without an app release.
#[derive(Debug, Clone, Default, PartialEq, Eq, Serialize, Deserialize)]
pub struct SyncCursor {
    marks: BTreeMap<SyncTable, TableMark>,
}

impl SyncCursor {
    pub fn mark(&self, table: SyncTable) -> TableMark {
        self.marks
            .get(&table)
            .copied()
            .unwrap_or_else(TableMark::origin)
    }

    pub fn advance(&mut self, table: SyncTable, mark: TableMark) {
        self.marks.insert(table, mark);
    }

    pub fn encode(&self) -> String {
        hex::encode(serde_json::to_vec(self).unwrap_or_default())
    }

    /// An unreadable cursor - from an older app version, or corrupted - falls
    /// back to a full download. Every pulled row is an idempotent upsert on
    /// the device, so starting over is slow but never wrong.
    pub fn decode(raw: Option<&str>) -> Self {
        raw.and_then(|value| hex::decode(value).ok())
            .and_then(|bytes| serde_json::from_slice(&bytes).ok())
            .unwrap_or_default()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn a_cursor_survives_a_round_trip() {
        let mut cursor = SyncCursor::default();
        cursor.advance(
            SyncTable::Sales,
            TableMark {
                updated_at: Utc::now(),
                id: Uuid::new_v4(),
            },
        );

        assert_eq!(SyncCursor::decode(Some(&cursor.encode())), cursor);
    }

    #[test]
    fn a_missing_or_garbled_cursor_means_start_from_the_beginning() {
        assert_eq!(SyncCursor::decode(None), SyncCursor::default());
        assert_eq!(
            SyncCursor::decode(Some("2026-09-22T00:00:00Z")),
            SyncCursor::default()
        );
        assert_eq!(
            SyncCursor::decode(None).mark(SyncTable::Products),
            TableMark::origin()
        );
    }
}
