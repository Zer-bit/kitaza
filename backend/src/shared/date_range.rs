use chrono::{DateTime, Datelike, Duration, NaiveDate, Utc};
use serde::{Deserialize, Serialize};

/// The reporting windows the dashboard offers. Kept deliberately small: store
/// owners think in "today", "this week", "this month".
#[derive(Debug, Clone, Copy, Default, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum ReportPeriod {
    #[default]
    Today,
    Week,
    Month,
}

impl ReportPeriod {
    pub fn as_cache_key(self) -> &'static str {
        match self {
            Self::Today => "today",
            Self::Week => "week",
            Self::Month => "month",
        }
    }
}

#[derive(Debug, Clone, Copy, Serialize)]
pub struct DateRange {
    pub start: DateTime<Utc>,
    pub end: DateTime<Utc>,
}

impl DateRange {
    /// Resolves a period against the owner's local day boundary. The offset is
    /// minutes east of UTC, sent by the client so reports match the wall clock
    /// above the counter rather than the server's timezone.
    pub fn for_period(period: ReportPeriod, utc_offset_minutes: i32, now: DateTime<Utc>) -> Self {
        let offset = Duration::minutes(i64::from(utc_offset_minutes));
        let local_now = now + offset;
        let local_today = local_now.date_naive();

        let local_start = match period {
            ReportPeriod::Today => local_today,
            ReportPeriod::Week => {
                local_today
                    - Duration::days(i64::from(local_today.weekday().num_days_from_monday()))
            }
            ReportPeriod::Month => {
                NaiveDate::from_ymd_opt(local_today.year(), local_today.month(), 1)
                    .unwrap_or(local_today)
            }
        };

        let start = local_start
            .and_hms_opt(0, 0, 0)
            .expect("midnight is always a valid time")
            .and_utc()
            - offset;

        Self { start, end: now }
    }

    pub fn previous_window(&self) -> Self {
        let span = self.end - self.start;
        Self {
            start: self.start - span,
            end: self.start,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use chrono::TimeZone;

    /// Manila time, the timezone almost every Kitaza store is in.
    const PH_OFFSET_MINUTES: i32 = 8 * 60;

    fn at(year: i32, month: u32, day: u32, hour: u32) -> DateTime<Utc> {
        Utc.with_ymd_and_hms(year, month, day, hour, 0, 0).unwrap()
    }

    #[test]
    fn today_starts_at_local_midnight_not_utc_midnight() {
        // 02:00 UTC on 22 September is already 10:00 on the 22nd in Manila,
        // so "today" must start at 16:00 UTC on the 21st.
        let now = at(2026, 9, 22, 2);
        let range = DateRange::for_period(ReportPeriod::Today, PH_OFFSET_MINUTES, now);

        assert_eq!(range.start, at(2026, 9, 21, 16));
        assert_eq!(range.end, now);
    }

    #[test]
    fn a_late_evening_sale_still_counts_as_today() {
        // 15:00 UTC is 23:00 in Manila on the same local day.
        let now = at(2026, 9, 22, 15);
        let range = DateRange::for_period(ReportPeriod::Today, PH_OFFSET_MINUTES, now);

        assert_eq!(range.start, at(2026, 9, 21, 16));
    }

    #[test]
    fn a_week_starts_on_monday() {
        // 24 September 2026 is a Thursday.
        let now = at(2026, 9, 24, 6);
        let range = DateRange::for_period(ReportPeriod::Week, PH_OFFSET_MINUTES, now);

        // Monday 21 September, local midnight.
        assert_eq!(range.start, at(2026, 9, 20, 16));
    }

    #[test]
    fn a_month_starts_on_the_first() {
        let now = at(2026, 9, 24, 6);
        let range = DateRange::for_period(ReportPeriod::Month, PH_OFFSET_MINUTES, now);

        assert_eq!(range.start, at(2026, 8, 31, 16));
    }

    #[test]
    fn the_previous_window_is_the_same_length_ending_where_this_one_starts() {
        let now = at(2026, 9, 22, 12);
        let range = DateRange::for_period(ReportPeriod::Today, PH_OFFSET_MINUTES, now);
        let previous = range.previous_window();

        assert_eq!(previous.end, range.start);
        assert_eq!(previous.end - previous.start, range.end - range.start);
    }

    #[test]
    fn utc_devices_are_handled_too() {
        let now = at(2026, 9, 22, 9);
        let range = DateRange::for_period(ReportPeriod::Today, 0, now);

        assert_eq!(range.start, at(2026, 9, 22, 0));
    }
}
