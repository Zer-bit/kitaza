use std::collections::HashMap;
use std::sync::{Arc, RwLock};

use futures_util::StreamExt;
use tokio::sync::broadcast;
use uuid::Uuid;

use crate::infrastructure::cache::CacheHandle;

use super::RealtimeEvent;

const CHANNEL_CAPACITY: usize = 128;
const REDIS_CHANNEL: &str = "kitaza:realtime";

/// Fans events out to every websocket attached to a store. Each store gets its
/// own channel so a busy store never wakes another store's listeners.
#[derive(Clone)]
pub struct EventBroadcaster {
    channels: Arc<RwLock<HashMap<Uuid, broadcast::Sender<RealtimeEvent>>>>,
    cache: CacheHandle,
}

impl EventBroadcaster {
    pub fn new(cache: CacheHandle) -> Self {
        Self {
            channels: Arc::new(RwLock::new(HashMap::new())),
            cache,
        }
    }

    pub fn subscribe(&self, store_id: Uuid) -> broadcast::Receiver<RealtimeEvent> {
        self.channel_for(store_id).subscribe()
    }

    /// Publishes locally and, when Redis is available, to sibling instances.
    pub async fn publish(&self, event: RealtimeEvent) {
        self.publish_locally(event.clone());

        let Some(mut connection) = self.cache.connection() else {
            return;
        };
        let Ok(encoded) = serde_json::to_string(&event) else {
            return;
        };

        let outcome: redis::RedisResult<()> = redis::cmd("PUBLISH")
            .arg(REDIS_CHANNEL)
            .arg(encoded)
            .query_async(&mut connection)
            .await;

        if let Err(error) = outcome {
            tracing::debug!(%error, "realtime fan-out to redis failed");
        }
    }

    pub fn publish_locally(&self, event: RealtimeEvent) {
        let sender = self.channel_for(event.store_id);
        // An error here only means nobody is listening right now.
        let _ = sender.send(event);
    }

    fn channel_for(&self, store_id: Uuid) -> broadcast::Sender<RealtimeEvent> {
        if let Some(sender) = self
            .channels
            .read()
            .expect("channel map poisoned")
            .get(&store_id)
        {
            return sender.clone();
        }

        let mut channels = self.channels.write().expect("channel map poisoned");
        channels
            .entry(store_id)
            .or_insert_with(|| broadcast::channel(CHANNEL_CAPACITY).0)
            .clone()
    }
}

/// Mirrors events published by other server instances into this one. Without
/// it, two replicas behind a load balancer would each only see their own
/// writes.
pub fn spawn_cross_instance_bridge(broadcaster: EventBroadcaster, redis_url: String) {
    tokio::spawn(async move {
        let Ok(client) = redis::Client::open(redis_url) else {
            return;
        };
        let Ok(mut pubsub) = client.get_async_pubsub().await else {
            tracing::warn!("realtime bridge disabled: cannot open redis pubsub");
            return;
        };
        if pubsub.subscribe(REDIS_CHANNEL).await.is_err() {
            return;
        }

        tracing::info!("realtime cross-instance bridge listening");
        let mut stream = pubsub.into_on_message();
        while let Some(message) = stream.next().await {
            let Ok(payload) = message.get_payload::<String>() else {
                continue;
            };
            if let Ok(event) = serde_json::from_str::<RealtimeEvent>(&payload) {
                broadcaster.publish_locally(event);
            }
        }
    });
}
