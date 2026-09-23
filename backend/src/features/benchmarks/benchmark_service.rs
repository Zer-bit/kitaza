use std::collections::HashMap;
use std::sync::{Arc, RwLock};
use std::time::{Duration, Instant};

use uuid::Uuid;

use crate::shared::ApiResult;

use super::benchmark_payloads::{BenchmarkReport, Comparison, NoComparison};
use super::benchmark_repository::{BenchmarkRepository, PeerMedians, SizeBand, StoreMonth};

/// No comparison is shown until this many other stores stand behind it. A
/// median of three stores is not anonymous, and it is not typical either.
const MINIMUM_PEERS: i64 = 20;

/// Medians move slowly, and the query reads every sharing store's month.
const MEDIAN_FRESH_FOR: Duration = Duration::from_secs(6 * 60 * 60);

type Cached = HashMap<(String, &'static str), (Instant, PeerMedians)>;

/// "Stores your size keep 18% margin." Built only from stores that share
/// their figures, only as medians, and only over at least twenty of them, so
/// no single store can be read out of it.
#[derive(Clone)]
pub struct BenchmarkService {
    repository: BenchmarkRepository,
    medians: Arc<RwLock<Cached>>,
}

impl BenchmarkService {
    pub fn new(repository: BenchmarkRepository) -> Self {
        Self {
            repository,
            medians: Arc::new(RwLock::new(HashMap::new())),
        }
    }

    pub async fn compare(&self, store_id: Uuid, shares: bool) -> ApiResult<BenchmarkReport> {
        // Comparisons are a trade, not a service: a store that keeps its own
        // figures back is not shown everyone else's.
        if !shares {
            return Ok(BenchmarkReport::unavailable(NoComparison::SharingOff));
        }

        let month = self.repository.store_month(store_id).await?;
        if !month.is_trading() {
            return Ok(BenchmarkReport::unavailable(NoComparison::TooLittleHistory));
        }

        let business_type = self.repository.business_type_of(store_id).await?;
        let band = SizeBand::of(month.sales_total);
        let medians = self.medians_for(store_id, &business_type, band).await?;

        if medians.sample_size < MINIMUM_PEERS {
            return Ok(BenchmarkReport::unavailable(NoComparison::TooFewStores));
        }

        Ok(BenchmarkReport {
            available: true,
            unavailable_because: None,
            sample_size: medians.sample_size,
            business_type: Some(business_type),
            size_band: Some(band),
            comparisons: comparisons(&month, &medians),
        })
    }

    async fn medians_for(
        &self,
        store_id: Uuid,
        business_type: &str,
        band: SizeBand,
    ) -> ApiResult<PeerMedians> {
        let key = (business_type.to_owned(), band.as_str());
        if let Some(medians) = self.remembered(&key) {
            return Ok(medians);
        }

        let medians = self
            .repository
            .peer_medians(store_id, business_type, band)
            .await?;

        // A pool too small to publish is not worth remembering: it is cheap
        // to ask again, and the comparison should appear as soon as enough
        // stores are sharing.
        if medians.sample_size >= MINIMUM_PEERS {
            self.medians
                .write()
                .expect("benchmark cache poisoned")
                .insert(key, (Instant::now(), medians));
        }

        Ok(medians)
    }

    fn remembered(&self, key: &(String, &'static str)) -> Option<PeerMedians> {
        let cache = self.medians.read().expect("benchmark cache poisoned");
        let (at, medians) = cache.get(key)?;
        (at.elapsed() < MEDIAN_FRESH_FOR).then_some(*medians)
    }
}

fn comparisons(month: &StoreMonth, medians: &PeerMedians) -> Vec<Comparison> {
    let rounded = |value: f64| (value * 10.0).round() / 10.0;

    [
        (
            "gross_margin_percent",
            month.margin_percent(),
            medians.margin_percent,
        ),
        (
            "expense_percent",
            month.expense_percent(),
            medians.expense_percent,
        ),
        (
            "daily_sales",
            Some(month.daily_sales()),
            medians.daily_sales,
        ),
    ]
    .into_iter()
    .filter_map(|(metric, yours, typical)| {
        Some(Comparison {
            metric,
            yours: rounded(yours?),
            typical: rounded(typical?),
        })
    })
    .collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    fn month(sales: f64, cost: f64, expenses: f64) -> StoreMonth {
        StoreMonth {
            sales_total: sales,
            cost_total: cost,
            expense_total: expenses,
            sale_count: 120,
        }
    }

    #[test]
    fn a_store_is_sized_by_what_it_sells_in_a_month() {
        assert_eq!(SizeBand::of(12_000.0), SizeBand::Small);
        assert_eq!(SizeBand::of(60_000.0), SizeBand::Medium);
        assert_eq!(SizeBand::of(400_000.0), SizeBand::Large);
    }

    #[test]
    fn a_quiet_month_is_not_compared() {
        let barely_open = StoreMonth {
            sale_count: 3,
            ..month(900.0, 700.0, 0.0)
        };
        assert!(!barely_open.is_trading());
        assert!(month(60_000.0, 48_000.0, 4_000.0).is_trading());
    }

    #[test]
    fn the_figures_line_up_with_the_middle_of_the_pack() {
        let mine = month(60_000.0, 48_000.0, 6_000.0);
        let peers = PeerMedians {
            sample_size: 31,
            margin_percent: Some(21.53),
            expense_percent: Some(6.21),
            daily_sales: Some(2_400.0),
        };

        let lines = comparisons(&mine, &peers);

        assert_eq!(lines[0].metric, "gross_margin_percent");
        assert_eq!(lines[0].yours, 20.0);
        assert_eq!(lines[0].typical, 21.5);
        assert_eq!(lines[1].yours, 10.0);
        assert_eq!(lines[2].yours, 2_000.0);
    }

    #[test]
    fn a_store_with_no_sales_has_no_percentages_to_compare() {
        let empty = month(0.0, 0.0, 0.0);
        let peers = PeerMedians {
            sample_size: 40,
            margin_percent: Some(20.0),
            expense_percent: Some(6.0),
            daily_sales: Some(1_000.0),
        };

        let lines = comparisons(&empty, &peers);
        assert_eq!(lines.len(), 1, "only the daily average, which is zero");
        assert_eq!(lines[0].metric, "daily_sales");
    }
}
