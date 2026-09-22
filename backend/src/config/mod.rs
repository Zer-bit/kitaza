mod database_settings;
mod redis_settings;
mod security_settings;
mod server_settings;
mod sync_settings;

pub use database_settings::DatabaseSettings;
pub use redis_settings::RedisSettings;
pub use security_settings::SecuritySettings;
pub use server_settings::ServerSettings;
pub use sync_settings::SyncSettings;

use anyhow::Context;

#[derive(Debug, Clone)]
pub struct AppSettings {
    pub server: ServerSettings,
    pub database: DatabaseSettings,
    pub redis: RedisSettings,
    pub security: SecuritySettings,
    pub sync: SyncSettings,
}

impl AppSettings {
    pub fn from_environment() -> anyhow::Result<Self> {
        Ok(Self {
            server: ServerSettings::from_environment()?,
            database: DatabaseSettings::from_environment()?,
            redis: RedisSettings::from_environment()?,
            security: SecuritySettings::from_environment()?,
            sync: SyncSettings::from_environment()?,
        })
    }
}

pub(crate) fn required(key: &str) -> anyhow::Result<String> {
    std::env::var(key).with_context(|| format!("missing required environment variable {key}"))
}

pub(crate) fn optional(key: &str, fallback: &str) -> String {
    std::env::var(key)
        .ok()
        .filter(|value| !value.trim().is_empty())
        .unwrap_or_else(|| fallback.to_owned())
}

pub(crate) fn parsed<T>(key: &str, fallback: T) -> anyhow::Result<T>
where
    T: std::str::FromStr,
    T::Err: std::fmt::Display,
{
    match std::env::var(key) {
        Err(_) => Ok(fallback),
        Ok(raw) if raw.trim().is_empty() => Ok(fallback),
        Ok(raw) => raw
            .trim()
            .parse::<T>()
            .map_err(|error| anyhow::anyhow!("invalid value for {key}: {error}")),
    }
}
