use chrono::Duration;

use super::{parsed, required};

#[derive(Debug, Clone)]
pub struct SecuritySettings {
    pub jwt_secret: String,
    pub access_token_lifetime: Duration,
    pub refresh_token_lifetime: Duration,
}

impl SecuritySettings {
    pub fn from_environment() -> anyhow::Result<Self> {
        let secret = required("KITAZA_JWT_SECRET")?;
        anyhow::ensure!(
            secret.len() >= 32,
            "KITAZA_JWT_SECRET must be at least 32 characters"
        );

        Ok(Self {
            jwt_secret: secret,
            access_token_lifetime: Duration::minutes(parsed("KITAZA_ACCESS_TOKEN_MINUTES", 60)?),
            refresh_token_lifetime: Duration::days(parsed("KITAZA_REFRESH_TOKEN_DAYS", 180)?),
        })
    }
}
