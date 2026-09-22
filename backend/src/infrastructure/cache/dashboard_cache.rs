use redis::AsyncCommands;
use serde::Serialize;
use serde::de::DeserializeOwned;
use uuid::Uuid;

use super::CacheHandle;

/// Dashboard totals are read far more often than sales are written, so they are
/// cached for a short TTL and invalidated whenever the store's money moves.
#[derive(Clone)]
pub struct DashboardCache {
    handle: CacheHandle,
    ttl_seconds: u64,
}

impl DashboardCache {
    pub fn new(handle: CacheHandle, ttl_seconds: u64) -> Self {
        Self {
            handle,
            ttl_seconds,
        }
    }

    pub async fn read<T: DeserializeOwned>(&self, store_id: Uuid, scope: &str) -> Option<T> {
        let mut connection = self.handle.connection()?;
        let raw: Option<String> = connection.get(entry_key(store_id, scope)).await.ok()?;
        raw.and_then(|value| serde_json::from_str(&value).ok())
    }

    pub async fn write<T: Serialize>(&self, store_id: Uuid, scope: &str, value: &T) {
        let Some(mut connection) = self.handle.connection() else {
            return;
        };
        let Ok(encoded) = serde_json::to_string(value) else {
            return;
        };

        let key = entry_key(store_id, scope);
        let outcome: redis::RedisResult<()> = redis::pipe()
            .atomic()
            .set_ex(&key, encoded, self.ttl_seconds)
            .sadd(index_key(store_id), &key)
            .expire(index_key(store_id), (self.ttl_seconds * 4) as i64)
            .query_async(&mut connection)
            .await;

        if let Err(error) = outcome {
            tracing::debug!(%error, "dashboard cache write skipped");
        }
    }

    /// Called after any write that changes money for a store.
    pub async fn invalidate_store(&self, store_id: Uuid) {
        let Some(mut connection) = self.handle.connection() else {
            return;
        };

        let index = index_key(store_id);
        let members: redis::RedisResult<Vec<String>> = connection.smembers(&index).await;
        let Ok(members) = members else { return };

        let mut pipeline = redis::pipe();
        pipeline.atomic();
        for member in &members {
            pipeline.del(member);
        }
        pipeline.del(&index);

        let _: redis::RedisResult<()> = pipeline.query_async(&mut connection).await;
    }
}

fn entry_key(store_id: Uuid, scope: &str) -> String {
    format!("kitaza:dashboard:{store_id}:{scope}")
}

fn index_key(store_id: Uuid) -> String {
    format!("kitaza:dashboard-index:{store_id}")
}
