use std::collections::HashMap;

use rust_decimal::Decimal;
use rust_decimal::prelude::ToPrimitive;

use crate::shared::Money;

use super::report_payloads::{ExpenseSample, UnusualExpense};

/// An expense must be at least this many times its category average, and the
/// category must have at least this many entries, before it is worth flagging.
const OUTLIER_MULTIPLIER: f64 = 2.5;
const MINIMUM_SAMPLES: usize = 4;
const MAX_FLAGGED: usize = 5;

/// Flags spending that is out of line with the store's own history. Deliberately
/// a transparent rule rather than a model: the owner can check the arithmetic,
/// and it works from day one with no training data.
pub fn detect_unusual_expenses(samples: &[ExpenseSample]) -> Vec<UnusualExpense> {
    let mut by_category: HashMap<&str, Vec<&ExpenseSample>> = HashMap::new();
    for sample in samples {
        by_category
            .entry(sample.category.as_str())
            .or_default()
            .push(sample);
    }

    let mut flagged: Vec<UnusualExpense> = Vec::new();

    for (category, entries) in by_category {
        if entries.len() < MINIMUM_SAMPLES {
            continue;
        }

        let average = mean(&entries);
        if average.is_zero() {
            continue;
        }

        for entry in entries {
            let ratio = ratio_of(entry.amount, average);
            if ratio < OUTLIER_MULTIPLIER {
                continue;
            }

            flagged.push(UnusualExpense {
                expense: (*entry).clone(),
                category_average: average.round_dp(2),
                times_above_average: (ratio * 10.0).round() / 10.0,
                explanation: format!(
                    "This {} expense is {:.1}x your usual {} spending of PHP {:.2}.",
                    category.replace('_', " "),
                    ratio,
                    category.replace('_', " "),
                    average
                ),
            });
        }
    }

    flagged.sort_by(|left, right| {
        right
            .times_above_average
            .partial_cmp(&left.times_above_average)
            .unwrap_or(std::cmp::Ordering::Equal)
    });
    flagged.truncate(MAX_FLAGGED);
    flagged
}

fn mean(entries: &[&ExpenseSample]) -> Money {
    let total: Decimal = entries.iter().map(|entry| entry.amount).sum();
    total / Decimal::from(entries.len() as i64)
}

fn ratio_of(amount: Money, average: Money) -> f64 {
    (amount / average).to_f64().unwrap_or(0.0)
}

#[cfg(test)]
mod tests {
    use chrono::Utc;
    use uuid::Uuid;

    use super::*;

    fn sample(category: &str, amount: i64) -> ExpenseSample {
        ExpenseSample {
            id: Uuid::new_v4(),
            category: category.to_owned(),
            description: None,
            amount: Decimal::from(amount),
            occurred_at: Utc::now(),
        }
    }

    #[test]
    fn a_thin_history_is_never_flagged() {
        let flagged =
            detect_unusual_expenses(&[sample("utilities", 100), sample("utilities", 5_000)]);

        assert!(flagged.is_empty());
    }

    #[test]
    fn spending_far_above_the_category_average_is_flagged() {
        let flagged = detect_unusual_expenses(&[
            sample("utilities", 100),
            sample("utilities", 110),
            sample("utilities", 95),
            sample("utilities", 105),
            sample("utilities", 2_000),
        ]);

        assert_eq!(flagged.len(), 1);
        assert_eq!(flagged[0].expense.amount, Decimal::from(2_000));
    }

    #[test]
    fn consistent_spending_is_left_alone() {
        let flagged = detect_unusual_expenses(&[
            sample("transportation", 200),
            sample("transportation", 210),
            sample("transportation", 190),
            sample("transportation", 205),
        ]);

        assert!(flagged.is_empty());
    }

    #[test]
    fn each_category_is_judged_against_its_own_history() {
        // Inventory dwarfs utilities in absolute terms but is normal for
        // inventory, so neither category produces a flag.
        let flagged = detect_unusual_expenses(&[
            sample("utilities", 100),
            sample("utilities", 100),
            sample("utilities", 100),
            sample("utilities", 100),
            sample("inventory", 5_000),
            sample("inventory", 5_200),
            sample("inventory", 4_800),
            sample("inventory", 5_100),
        ]);

        assert!(flagged.is_empty());
    }

    #[test]
    fn at_most_five_are_reported_worst_first() {
        let mut samples: Vec<ExpenseSample> = (0..4).map(|_| sample("other", 10)).collect();
        samples.extend((1..=7).map(|n| sample("other", n * 100)));

        let flagged = detect_unusual_expenses(&samples);

        assert!(flagged.len() <= 5);
        assert!(flagged[0].times_above_average >= flagged[flagged.len() - 1].times_above_average);
    }
}
