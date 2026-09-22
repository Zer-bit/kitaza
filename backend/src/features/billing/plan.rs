use chrono::{DateTime, Duration, Months, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;

/// What an owner can pay for. Offline use is free and needs no plan at all.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum Plan {
    /// Cloud backup and sync for one store, on any number of the owner's
    /// own phones.
    Basic,
    /// Up to five stores, and staff accounts.
    Pro,
}

/// A year costs ten months: enough of a reason to pay ahead, which suits
/// owners who would rather settle it once after a good month.
const YEAR_PRICED_AS_MONTHS: i64 = 10;

impl Plan {
    pub fn monthly_centavos(self) -> i64 {
        match self {
            Plan::Basic => 9_900,
            Plan::Pro => 19_900,
        }
    }

    /// The price of [months], in centavos. Only 1 and 12 are offered.
    pub fn price_centavos(self, months: u32) -> i64 {
        let billed = if months == 12 {
            YEAR_PRICED_AS_MONTHS
        } else {
            i64::from(months)
        };
        self.monthly_centavos() * billed
    }

    pub fn store_limit(self) -> i64 {
        match self {
            Plan::Basic => 1,
            Plan::Pro => 5,
        }
    }

    pub fn allows_staff(self) -> bool {
        matches!(self, Plan::Pro)
    }

    pub fn as_str(self) -> &'static str {
        match self {
            Plan::Basic => "basic",
            Plan::Pro => "pro",
        }
    }

    pub fn parse(raw: &str) -> Option<Self> {
        match raw {
            "basic" => Some(Plan::Basic),
            "pro" => Some(Plan::Pro),
            _ => None,
        }
    }

    pub fn label(self) -> &'static str {
        match self {
            Plan::Basic => "Kitaza Basic",
            Plan::Pro => "Kitaza Pro",
        }
    }
}

pub const OFFERED_MONTHS: [u32; 2] = [1, 12];

/// An owner's subscription as stored.
#[derive(Debug, Clone, PartialEq, Eq, FromRow)]
pub struct SubscriptionRecord {
    pub plan: String,
    pub trial_ends_at: Option<DateTime<Utc>>,
    pub paid_through: Option<DateTime<Utc>>,
}

/// Where an account stands on a given day.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Standing {
    /// Billing is switched off on this server.
    Unlimited,
    Trial {
        ends_at: DateTime<Utc>,
    },
    Active {
        plan: Plan,
        until: DateTime<Utc>,
    },
    /// The period ended, but everything keeps working until [until].
    Grace {
        plan: Plan,
        until: DateTime<Utc>,
    },
    /// Uploads wait on the phones until the owner pays. Nothing is deleted,
    /// and everything already in the cloud can still be downloaded.
    Paused {
        since: DateTime<Utc>,
    },
}

impl Standing {
    pub fn of(
        subscription: Option<&SubscriptionRecord>,
        now: DateTime<Utc>,
        grace: Duration,
        enforced: bool,
    ) -> Self {
        if !enforced {
            return Standing::Unlimited;
        }
        let Some(subscription) = subscription else {
            return Standing::Paused {
                since: DateTime::<Utc>::UNIX_EPOCH,
            };
        };
        let plan = Plan::parse(&subscription.plan).unwrap_or(Plan::Basic);

        // A trial runs its course even if the owner pays during it: paying
        // Basic early must not take away the Pro days they were promised.
        if let Some(trial) = subscription.trial_ends_at
            && now < trial
        {
            return Standing::Trial { ends_at: trial };
        }
        if let Some(paid) = subscription.paid_through
            && now < paid
        {
            return Standing::Active { plan, until: paid };
        }

        // Whichever ran out last: a lapsed trial is graced as the trial's
        // plan, a lapsed payment as the plan that was paid for.
        let lapsed = match (subscription.trial_ends_at, subscription.paid_through) {
            (_, Some(paid)) => Some((plan, paid)),
            (Some(trial), None) => Some((Plan::Pro, trial)),
            (None, None) => None,
        };
        let Some((plan, ended)) = lapsed else {
            return Standing::Paused {
                since: DateTime::<Utc>::UNIX_EPOCH,
            };
        };

        let grace_ends = ended + grace;
        if now < grace_ends {
            Standing::Grace {
                plan,
                until: grace_ends,
            }
        } else {
            Standing::Paused { since: grace_ends }
        }
    }

    /// The plan whose features apply right now. None while paused.
    pub fn plan(self) -> Option<Plan> {
        match self {
            Standing::Unlimited | Standing::Trial { .. } => Some(Plan::Pro),
            Standing::Active { plan, .. } | Standing::Grace { plan, .. } => Some(plan),
            Standing::Paused { .. } => None,
        }
    }

    pub fn can_upload(self) -> bool {
        self.plan().is_some()
    }

    pub fn allows_staff(self) -> bool {
        self.plan().is_some_and(Plan::allows_staff)
    }

    /// How many stores may take new entries. Stores past the limit - left
    /// from a bigger plan - stay readable.
    pub fn store_limit(self) -> Option<i64> {
        match self {
            Standing::Unlimited => None,
            other => Some(other.plan().map_or(0, Plan::store_limit)),
        }
    }

    pub fn status(self) -> &'static str {
        match self {
            Standing::Unlimited => "unlimited",
            Standing::Trial { .. } => "trial",
            Standing::Active { .. } => "active",
            Standing::Grace { .. } => "grace",
            Standing::Paused { .. } => "paused",
        }
    }
}

/// When a payment for [months] of [plan] leaves the subscription paid
/// through.
///
/// Nothing already bought is lost. Paying during a trial starts after the
/// trial; paying before a period ends adds to it; and time left on one plan
/// is converted to the other at their price ratio, so moving from Pro to
/// Basic with ten days left gives about twenty days of Basic.
pub fn paid_through_after(
    current: Option<&SubscriptionRecord>,
    plan: Plan,
    months: u32,
    now: DateTime<Utc>,
) -> DateTime<Utc> {
    let mut start = now;

    if let Some(current) = current {
        // Paid time only starts once the trial is over; trial days are
        // credited as they are, never converted.
        let paid_from = current.trial_ends_at.map_or(now, |trial| trial.max(now));
        start = paid_from;

        if let Some(paid) = current.paid_through
            && paid > paid_from
        {
            let remaining = paid - paid_from;
            let old = Plan::parse(&current.plan).unwrap_or(plan);
            let converted = if old == plan {
                remaining
            } else {
                Duration::seconds(
                    remaining.num_seconds() * old.monthly_centavos() / plan.monthly_centavos(),
                )
            };
            start = paid_from + converted;
        }
    }

    start
        .checked_add_months(Months::new(months))
        .unwrap_or(start + Duration::days(30 * i64::from(months)))
}

#[cfg(test)]
mod tests {
    use super::*;
    use chrono::TimeZone;

    fn day(d: u32) -> DateTime<Utc> {
        Utc.with_ymd_and_hms(2026, 9, d, 8, 0, 0).unwrap()
    }

    fn record(
        plan: Plan,
        trial: Option<DateTime<Utc>>,
        paid: Option<DateTime<Utc>>,
    ) -> SubscriptionRecord {
        SubscriptionRecord {
            plan: plan.as_str().to_owned(),
            trial_ends_at: trial,
            paid_through: paid,
        }
    }

    const GRACE: Duration = Duration::days(7);

    #[test]
    fn prices_are_in_centavos_and_a_year_costs_ten_months() {
        assert_eq!(Plan::Basic.price_centavos(1), 9_900);
        assert_eq!(Plan::Pro.price_centavos(1), 19_900);
        assert_eq!(Plan::Basic.price_centavos(12), 99_000);
        assert_eq!(Plan::Pro.price_centavos(12), 199_000);
    }

    #[test]
    fn a_trial_is_pro_until_it_ends_then_graced_then_paused() {
        let trial = record(Plan::Pro, Some(day(10)), None);

        let during = Standing::of(Some(&trial), day(9), GRACE, true);
        assert_eq!(during, Standing::Trial { ends_at: day(10) });
        assert_eq!(during.plan(), Some(Plan::Pro));

        let after = Standing::of(Some(&trial), day(12), GRACE, true);
        assert_eq!(
            after,
            Standing::Grace {
                plan: Plan::Pro,
                until: day(17)
            }
        );
        assert!(after.can_upload(), "grace keeps everything working");

        let paused = Standing::of(Some(&trial), day(17), GRACE, true);
        assert_eq!(paused, Standing::Paused { since: day(17) });
        assert!(!paused.can_upload());
        assert!(!paused.allows_staff());
        assert_eq!(paused.store_limit(), Some(0));
    }

    #[test]
    fn a_paid_basic_account_has_one_store_and_no_staff() {
        let basic = record(Plan::Basic, Some(day(1)), Some(day(30)));
        let standing = Standing::of(Some(&basic), day(15), GRACE, true);

        assert_eq!(
            standing,
            Standing::Active {
                plan: Plan::Basic,
                until: day(30)
            }
        );
        assert_eq!(standing.store_limit(), Some(1));
        assert!(!standing.allows_staff());
    }

    #[test]
    fn with_billing_off_everything_is_allowed() {
        let standing = Standing::of(None, day(1), GRACE, false);
        assert_eq!(standing, Standing::Unlimited);
        assert!(standing.allows_staff());
        assert_eq!(standing.store_limit(), None);
    }

    #[test]
    fn paying_basic_during_a_trial_keeps_the_trial_to_its_end() {
        let paid_early = record(Plan::Basic, Some(day(20)), Some(day(28)));
        assert_eq!(
            Standing::of(Some(&paid_early), day(10), GRACE, true).plan(),
            Some(Plan::Pro)
        );
        assert_eq!(
            Standing::of(Some(&paid_early), day(22), GRACE, true).plan(),
            Some(Plan::Basic)
        );
    }

    #[test]
    fn paying_during_a_trial_starts_when_the_trial_ends() {
        let trial = record(Plan::Pro, Some(day(20)), None);
        let through = paid_through_after(Some(&trial), Plan::Pro, 1, day(5));
        assert_eq!(
            through,
            Utc.with_ymd_and_hms(2026, 10, 20, 8, 0, 0).unwrap()
        );
    }

    #[test]
    fn a_second_payment_during_a_trial_converts_only_the_paid_time() {
        // Trial to the 20th, then a month of Pro bought: paid to Oct 20.
        // Switching to Basic converts that month, not the trial days.
        let paid_in_trial = record(
            Plan::Pro,
            Some(day(20)),
            Some(Utc.with_ymd_and_hms(2026, 10, 20, 8, 0, 0).unwrap()),
        );
        let through = paid_through_after(Some(&paid_in_trial), Plan::Basic, 1, day(5));

        let pro_month = Duration::days(30);
        let expected = day(20)
            + Duration::seconds(pro_month.num_seconds() * 19_900 / 9_900)
            + Duration::days(31);
        assert!((through - expected).num_hours().abs() <= 26, "{through}");
    }

    #[test]
    fn paying_early_adds_to_the_time_already_bought() {
        let paid = record(Plan::Basic, None, Some(day(25)));
        let through = paid_through_after(Some(&paid), Plan::Basic, 1, day(20));
        assert_eq!(
            through,
            Utc.with_ymd_and_hms(2026, 10, 25, 8, 0, 0).unwrap()
        );
    }

    #[test]
    fn paying_late_starts_from_today() {
        let lapsed = record(Plan::Basic, None, Some(day(1)));
        let through = paid_through_after(Some(&lapsed), Plan::Basic, 12, day(20));
        assert_eq!(through, Utc.with_ymd_and_hms(2027, 9, 20, 8, 0, 0).unwrap());
    }

    #[test]
    fn switching_plans_converts_the_time_left_at_the_price_ratio() {
        // Ten days of Pro left, bought at 199 a month, become about twenty
        // days of Basic at 99 before the new month starts.
        let pro = record(Plan::Pro, None, Some(day(11)));
        let through = paid_through_after(Some(&pro), Plan::Basic, 1, day(1));

        let credited = through - Utc.with_ymd_and_hms(2026, 10, 1, 8, 0, 0).unwrap();
        assert!(
            (credited - Duration::days(20)).num_hours().abs() <= 2,
            "credited {credited:?}"
        );
    }
}
