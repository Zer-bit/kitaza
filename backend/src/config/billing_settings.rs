use chrono::Duration;

use super::{optional, parsed, required};

/// Who takes the money, if anyone.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum BillingMode {
    /// Every cloud account has every feature. For self-hosting and for tests
    /// that are not about billing.
    Off,
    /// Plans are enforced, and checkout is a page on this server with a
    /// "pay" button. For development and demos; never in production.
    Test,
    /// Plans are enforced and paid through PayMongo (GCash, Maya, cards).
    PayMongo {
        secret_key: String,
        webhook_secret: String,
    },
}

#[derive(Debug, Clone)]
pub struct BillingSettings {
    pub mode: BillingMode,
    /// Where this server is reached from a phone's browser, for the pages a
    /// checkout returns to.
    pub public_url: String,
    pub trial: Duration,
    /// How long after a paid period ends before uploads pause. Long enough to
    /// cover a payday that falls late, or a week without load.
    pub grace: Duration,
}

impl BillingSettings {
    pub fn from_environment() -> anyhow::Result<Self> {
        let mode = match optional("KITAZA_BILLING", "off").to_lowercase().as_str() {
            "off" => BillingMode::Off,
            "test" => BillingMode::Test,
            "paymongo" => BillingMode::PayMongo {
                secret_key: required("KITAZA_PAYMONGO_SECRET_KEY")?,
                webhook_secret: required("KITAZA_PAYMONGO_WEBHOOK_SECRET")?,
            },
            other => anyhow::bail!("KITAZA_BILLING must be off, test or paymongo, not {other}"),
        };

        Ok(Self {
            mode,
            public_url: optional("KITAZA_PUBLIC_URL", "http://localhost:8080")
                .trim_end_matches('/')
                .to_owned(),
            trial: Duration::days(parsed("KITAZA_TRIAL_DAYS", 30)?),
            grace: Duration::days(parsed("KITAZA_GRACE_DAYS", 7)?),
        })
    }

    pub fn enforced(&self) -> bool {
        self.mode != BillingMode::Off
    }
}
