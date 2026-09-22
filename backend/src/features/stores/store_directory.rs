use std::collections::HashSet;
use std::sync::{Arc, RwLock};

use uuid::Uuid;

use crate::infrastructure::database::PgPool;
use crate::shared::{ApiError, ApiResult};

/// Answers "may this owner touch this store?" for every scoped request.
/// Confirmed pairs are memoised because ownership never changes for the life of
/// a store, which keeps the check off the hot path.
#[derive(Clone)]
pub struct StoreDirectory {
    pool: PgPool,
    confirmed: Arc<RwLock<HashSet<(Uuid, Uuid)>>>,
}

impl StoreDirectory {
    pub fn new(pool: PgPool) -> Self {
        Self {
            pool,
            confirmed: Arc::new(RwLock::new(HashSet::new())),
        }
    }

    pub async fn assert_owner_of(&self, owner_id: Uuid, store_id: Uuid) -> ApiResult<()> {
        if self.is_memoised(owner_id, store_id) {
            return Ok(());
        }

        let exists: Option<(Uuid,)> =
            sqlx::query_as("SELECT id FROM stores WHERE id = $1 AND owner_id = $2")
                .bind(store_id)
                .bind(owner_id)
                .fetch_optional(&self.pool)
                .await?;

        if exists.is_none() {
            return Err(ApiError::Forbidden(
                "this store does not belong to you".into(),
            ));
        }

        self.confirmed
            .write()
            .expect("store directory poisoned")
            .insert((owner_id, store_id));

        Ok(())
    }

    fn is_memoised(&self, owner_id: Uuid, store_id: Uuid) -> bool {
        self.confirmed
            .read()
            .expect("store directory poisoned")
            .contains(&(owner_id, store_id))
    }
}
