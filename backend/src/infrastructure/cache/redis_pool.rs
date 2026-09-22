use redis::aio::ConnectionManager;

use crate::config::RedisSettings;

/// A cloneable multiplexed Redis connection. Kept optional on purpose: Kitaza
/// must still boot and serve traffic when Redis is unavailable, it simply loses
/// caching and rate limiting.
#[derive(Clone)]
pub struct CacheHandle {
    connection: Option<ConnectionManager>,
}

impl CacheHandle {
    pub fn disabled() -> Self {
        Self { connection: None }
    }

    pub fn is_enabled(&self) -> bool {
        self.connection.is_some()
    }

    pub fn connection(&self) -> Option<ConnectionManager> {
        self.connection.clone()
    }
}

pub async fn connect_cache(settings: &RedisSettings) -> CacheHandle {
    match try_connect(&settings.url).await {
        Ok(connection) => {
            tracing::info!("redis cache connected");
            CacheHandle {
                connection: Some(connection),
            }
        }
        Err(error) => {
            tracing::warn!(%error, "redis unavailable, continuing without cache");
            CacheHandle::disabled()
        }
    }
}

async fn try_connect(url: &str) -> anyhow::Result<ConnectionManager> {
    let client = redis::Client::open(url)?;
    Ok(ConnectionManager::new(client).await?)
}
