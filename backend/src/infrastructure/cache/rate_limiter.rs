use redis::AsyncCommands;

use super::CacheHandle;

/// Fixed-window counter used to slow down credential stuffing on the login
/// endpoint. Fails open when Redis is down - availability beats throttling for
/// a store that needs to ring up a sale.
#[derive(Clone)]
pub struct RateLimiter {
    handle: CacheHandle,
    limit: u32,
    window_seconds: u64,
}

pub enum RateLimitVerdict {
    Allowed,
    Exceeded,
}

impl RateLimiter {
    pub fn new(handle: CacheHandle, limit: u32, window_seconds: u64) -> Self {
        Self {
            handle,
            limit,
            window_seconds,
        }
    }

    pub async fn check(&self, bucket: &str) -> RateLimitVerdict {
        let Some(mut connection) = self.handle.connection() else {
            return RateLimitVerdict::Allowed;
        };

        let key = format!("kitaza:ratelimit:{bucket}");
        let attempts: redis::RedisResult<u32> = connection.incr(&key, 1).await;

        match attempts {
            Ok(1) => {
                let _: redis::RedisResult<()> =
                    connection.expire(&key, self.window_seconds as i64).await;
                RateLimitVerdict::Allowed
            }
            Ok(count) if count > self.limit => RateLimitVerdict::Exceeded,
            Ok(_) => RateLimitVerdict::Allowed,
            Err(_) => RateLimitVerdict::Allowed,
        }
    }

    pub async fn reset(&self, bucket: &str) {
        let Some(mut connection) = self.handle.connection() else {
            return;
        };
        let _: redis::RedisResult<()> = connection.del(format!("kitaza:ratelimit:{bucket}")).await;
    }
}
