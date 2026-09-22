use std::time::Duration;

use super::{parsed, required};

#[derive(Debug, Clone)]
pub struct DatabaseSettings {
    pub url: String,
    pub max_connections: u32,
    pub min_connections: u32,
    pub acquire_timeout: Duration,
    pub run_migrations_on_boot: bool,
}

impl DatabaseSettings {
    pub fn from_environment() -> anyhow::Result<Self> {
        Ok(Self {
            url: required("DATABASE_URL")?,
            max_connections: parsed("DATABASE_MAX_CONNECTIONS", 20)?,
            min_connections: parsed("DATABASE_MIN_CONNECTIONS", 2)?,
            acquire_timeout: Duration::from_secs(parsed("DATABASE_ACQUIRE_TIMEOUT_SECONDS", 8)?),
            run_migrations_on_boot: parsed("DATABASE_AUTO_MIGRATE", true)?,
        })
    }
}
