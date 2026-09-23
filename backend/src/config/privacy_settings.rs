use chrono::Duration;

use crate::features::privacy::RetentionPolicy;

use super::parsed;

#[derive(Debug, Clone)]
pub struct PrivacySettings {
    /// How long a deletion can still be called off. Erasure is a right, but a
    /// mis-tap that wiped a year of books on the spot would be its own
    /// disaster, so the account is locked now and emptied later.
    pub deletion_grace: Duration,

    /// How long each kind of record is kept before the sweep removes it.
    pub retention: RetentionPolicy,
}

impl PrivacySettings {
    pub fn from_environment() -> anyhow::Result<Self> {
        Ok(Self {
            deletion_grace: Duration::days(parsed("KITAZA_DELETION_GRACE_DAYS", 30)?),
            retention: RetentionPolicy {
                error_reports: Duration::days(parsed("KITAZA_KEEP_ERROR_REPORTS_DAYS", 90)?),
                activity: Duration::days(parsed("KITAZA_KEEP_ACTIVITY_DAYS", 730)?),
                dormant_sessions: Duration::days(parsed("KITAZA_KEEP_DEVICES_DAYS", 365)?),
                ..RetentionPolicy::default()
            },
        })
    }
}
