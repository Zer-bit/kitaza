use super::{optional, parsed};

#[derive(Debug, Clone)]
pub struct RedisSettings {
    pub url: String,
    pub dashboard_cache_ttl_seconds: u64,
    pub login_attempt_limit: u32,
    pub login_attempt_window_seconds: u64,
}

impl RedisSettings {
    pub fn from_environment() -> anyhow::Result<Self> {
        Ok(Self {
            url: optional("REDIS_URL", "redis://127.0.0.1:6379"),
            dashboard_cache_ttl_seconds: parsed("REDIS_DASHBOARD_TTL_SECONDS", 30)?,
            login_attempt_limit: parsed("REDIS_LOGIN_ATTEMPT_LIMIT", 10)?,
            login_attempt_window_seconds: parsed("REDIS_LOGIN_ATTEMPT_WINDOW_SECONDS", 300)?,
        })
    }
}
