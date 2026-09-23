use serde::Serialize;

use super::benchmark_repository::SizeBand;

/// One figure of the store's, beside what similar stores show.
#[derive(Debug, Serialize)]
pub struct Comparison {
    /// `gross_margin_percent`, `expense_percent` or `daily_sales`.
    pub metric: &'static str,
    pub yours: f64,
    pub typical: f64,
}

/// Why there is nothing to show, when there is nothing to show.
#[derive(Debug, Clone, Copy, Serialize)]
pub enum NoComparison {
    /// Fewer than twenty other stores of this kind and size share theirs.
    #[serde(rename = "not_enough_stores")]
    TooFewStores,
    /// This store has not traded enough this month to compare.
    #[serde(rename = "not_enough_history")]
    TooLittleHistory,
    /// The owner turned sharing off, so they see nothing either.
    #[serde(rename = "not_sharing")]
    SharingOff,
}

#[derive(Debug, Serialize)]
pub struct BenchmarkReport {
    pub available: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub unavailable_because: Option<NoComparison>,
    /// How many other stores the middle figures come from.
    pub sample_size: i64,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub business_type: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub size_band: Option<SizeBand>,
    pub comparisons: Vec<Comparison>,
}

impl BenchmarkReport {
    pub fn unavailable(reason: NoComparison) -> Self {
        Self {
            available: false,
            unavailable_because: Some(reason),
            sample_size: 0,
            business_type: None,
            size_band: None,
            comparisons: Vec::new(),
        }
    }
}
