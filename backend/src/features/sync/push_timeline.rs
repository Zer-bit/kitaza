use chrono::{DateTime, Utc};

use crate::features::inventory::RecordMovementRequest;
use crate::features::sales::RecordSaleRequest;

/// A queued change that moves stock.
pub enum StockEvent {
    Sale(RecordSaleRequest),
    Movement(RecordMovementRequest),
}

impl StockEvent {
    fn occurred_at(&self, fallback: DateTime<Utc>) -> DateTime<Utc> {
        match self {
            Self::Sale(sale) => sale.occurred_at.unwrap_or(fallback),
            Self::Movement(movement) => movement.occurred_at.unwrap_or(fallback),
        }
    }
}

/// Orders sales and stock movements by when they happened on the device.
///
/// Order matters because an adjustment records a counted total. If an owner
/// sells two, then counts ten on the shelf, the count must land after the
/// sale; applied the other way round the server would end at eight.
pub fn into_timeline(
    sales: Vec<RecordSaleRequest>,
    movements: Vec<RecordMovementRequest>,
) -> Vec<StockEvent> {
    let now = Utc::now();

    let mut events: Vec<StockEvent> = sales
        .into_iter()
        .map(StockEvent::Sale)
        .chain(movements.into_iter().map(StockEvent::Movement))
        .collect();

    events.sort_by_key(|event| event.occurred_at(now));
    events
}

#[cfg(test)]
mod tests {
    use chrono::Duration;
    use uuid::Uuid;

    use super::*;

    fn sale_at(at: DateTime<Utc>) -> RecordSaleRequest {
        serde_json::from_value(serde_json::json!({
            "occurred_at": at,
            "items": [{ "quantity": 1, "unit_price": 10 }]
        }))
        .unwrap()
    }

    fn count_at(at: DateTime<Utc>) -> RecordMovementRequest {
        serde_json::from_value(serde_json::json!({
            "product_id": Uuid::new_v4(),
            "movement": "adjustment",
            "quantity": 10,
            "occurred_at": at,
        }))
        .unwrap()
    }

    #[test]
    fn events_are_replayed_in_the_order_they_happened() {
        let start = Utc::now() - Duration::hours(1);

        let timeline = into_timeline(
            vec![sale_at(start + Duration::minutes(30)), sale_at(start)],
            vec![count_at(start + Duration::minutes(10))],
        );

        let kinds: Vec<&str> = timeline
            .iter()
            .map(|event| match event {
                StockEvent::Sale(_) => "sale",
                StockEvent::Movement(_) => "count",
            })
            .collect();

        assert_eq!(kinds, ["sale", "count", "sale"]);
    }
}
