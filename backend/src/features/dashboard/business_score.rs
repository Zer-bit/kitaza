use rust_decimal::Decimal;
use serde::{Deserialize, Serialize};

use crate::shared::Money;

/// Traffic-light health rating. Always paired with a written reason: colour
/// alone is unreadable for colour-blind owners and meaningless without
/// context.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum HealthRating {
    Green,
    Yellow,
    Red,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BusinessHealth {
    pub rating: HealthRating,
    pub score: i32,
    pub headline: String,
    pub reasons: Vec<String>,
}

pub struct HealthInputs {
    pub sales_total: Money,
    pub net_profit: Money,
    pub previous_net_profit: Money,
    pub withdrawals_total: Money,
    pub low_stock_count: i64,
}

const HEALTHY_MARGIN_PERCENT: i64 = 15;
const THIN_MARGIN_PERCENT: i64 = 5;

/// Scores out of 100 from four signals an owner can act on: are you
/// profitable, is the margin healthy, are you trending up, and are you taking
/// out more than you earn.
pub fn evaluate(inputs: &HealthInputs) -> BusinessHealth {
    let mut score = 50i32;
    let mut reasons = Vec::new();

    if inputs.sales_total.is_zero() {
        return BusinessHealth {
            rating: HealthRating::Yellow,
            score: 50,
            headline: "No sales recorded yet".to_owned(),
            reasons: vec!["Record your first sale to see how your store is doing.".to_owned()],
        };
    }

    if inputs.net_profit > Decimal::ZERO {
        score += 25;
        reasons.push(format!(
            "You earned a profit of {}.",
            peso(inputs.net_profit)
        ));
    } else {
        score -= 30;
        reasons.push(format!(
            "You spent {} more than you sold.",
            peso(-inputs.net_profit)
        ));
    }

    let margin = margin_percent(inputs.net_profit, inputs.sales_total);
    if margin >= HEALTHY_MARGIN_PERCENT {
        score += 15;
        reasons.push(format!("Healthy margin: {margin}% of sales is profit."));
    } else if margin >= THIN_MARGIN_PERCENT {
        reasons.push(format!("Thin margin: only {margin}% of sales is profit."));
    } else if margin > 0 {
        score -= 10;
        reasons.push(format!("Very thin margin: {margin}% of sales is profit."));
    }

    if inputs.previous_net_profit != Decimal::ZERO {
        if inputs.net_profit > inputs.previous_net_profit {
            score += 10;
            reasons.push("Profit is higher than the previous period.".to_owned());
        } else if inputs.net_profit < inputs.previous_net_profit {
            score -= 10;
            reasons.push("Profit is lower than the previous period.".to_owned());
        }
    }

    if inputs.withdrawals_total > inputs.net_profit && inputs.withdrawals_total > Decimal::ZERO {
        score -= 15;
        reasons.push(format!(
            "You withdrew {}, more than the profit you made.",
            peso(inputs.withdrawals_total)
        ));
    }

    if inputs.low_stock_count > 0 {
        score -= 5;
        reasons.push(format!(
            "{} product(s) need restocking.",
            inputs.low_stock_count
        ));
    }

    let score = score.clamp(0, 100);
    let rating = match score {
        70..=100 => HealthRating::Green,
        40..=69 => HealthRating::Yellow,
        _ => HealthRating::Red,
    };

    BusinessHealth {
        rating,
        score,
        headline: headline_for(rating),
        reasons,
    }
}

fn headline_for(rating: HealthRating) -> String {
    match rating {
        HealthRating::Green => "Your store is doing well",
        HealthRating::Yellow => "Keep an eye on your numbers",
        HealthRating::Red => "Your store needs attention",
    }
    .to_owned()
}

fn margin_percent(net_profit: Money, sales_total: Money) -> i64 {
    if sales_total.is_zero() {
        return 0;
    }
    ((net_profit / sales_total) * Decimal::ONE_HUNDRED)
        .round()
        .try_into()
        .unwrap_or(0)
}

fn peso(amount: Money) -> String {
    format!("PHP {:.2}", amount)
}

#[cfg(test)]
mod tests {
    use super::*;

    fn inputs() -> HealthInputs {
        HealthInputs {
            sales_total: Decimal::from(10_000),
            net_profit: Decimal::from(2_000),
            previous_net_profit: Decimal::from(1_500),
            withdrawals_total: Decimal::ZERO,
            low_stock_count: 0,
        }
    }

    #[test]
    fn a_store_with_no_sales_is_not_judged() {
        let health = evaluate(&HealthInputs {
            sales_total: Decimal::ZERO,
            ..inputs()
        });

        assert_eq!(health.rating, HealthRating::Yellow);
        assert!(health.headline.contains("No sales"));
    }

    #[test]
    fn a_profitable_improving_store_rates_green() {
        let health = evaluate(&inputs());

        assert_eq!(health.rating, HealthRating::Green);
        assert!(health.score >= 70);
    }

    #[test]
    fn a_loss_rates_red() {
        let health = evaluate(&HealthInputs {
            net_profit: Decimal::from(-1_200),
            ..inputs()
        });

        assert_eq!(health.rating, HealthRating::Red);
        assert!(
            health
                .reasons
                .iter()
                .any(|r| r.contains("more than you sold"))
        );
    }

    #[test]
    fn withdrawing_more_than_the_profit_is_called_out() {
        let health = evaluate(&HealthInputs {
            withdrawals_total: Decimal::from(5_000),
            ..inputs()
        });

        assert!(health.reasons.iter().any(|r| r.contains("withdrew")));
    }

    #[test]
    fn the_score_never_leaves_its_range() {
        let health = evaluate(&HealthInputs {
            sales_total: Decimal::from(1_000),
            net_profit: Decimal::from(-50_000),
            previous_net_profit: Decimal::from(9_000),
            withdrawals_total: Decimal::from(20_000),
            low_stock_count: 40,
        });

        assert!((0..=100).contains(&health.score));
    }
}
