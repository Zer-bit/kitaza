use chrono::{DateTime, Utc};
use sqlx::FromRow;
use uuid::Uuid;

use crate::infrastructure::database::PgPool;
use crate::shared::ApiResult;

#[derive(Debug, FromRow)]
pub struct OwnerRecord {
    pub id: Uuid,
    pub email: String,
    pub password_hash: String,
    pub full_name: String,
}

#[derive(Debug, FromRow)]
pub struct StoreRecord {
    pub id: Uuid,
    pub name: String,
    pub business_type: String,
    pub currency_code: String,
}

#[derive(Debug, FromRow)]
pub struct RefreshTokenRecord {
    pub owner_id: Uuid,
    pub session_id: Uuid,
    pub staff_id: Option<Uuid>,
    pub expires_at: DateTime<Utc>,
    pub revoked_at: Option<DateTime<Utc>>,
    pub rotated_at: Option<DateTime<Utc>>,
    pub session_live: bool,
    pub staff_live: bool,
}

#[derive(Clone)]
pub struct AuthRepository {
    pool: PgPool,
}

impl AuthRepository {
    pub fn new(pool: PgPool) -> Self {
        Self { pool }
    }

    pub async fn find_owner_by_email(&self, email: &str) -> ApiResult<Option<OwnerRecord>> {
        let owner = sqlx::query_as::<_, OwnerRecord>(
            "SELECT id, email, password_hash, full_name FROM owners WHERE lower(email) = lower($1)",
        )
        .bind(email)
        .fetch_optional(&self.pool)
        .await?;

        Ok(owner)
    }

    pub async fn find_owner_by_id(&self, owner_id: Uuid) -> ApiResult<Option<OwnerRecord>> {
        let owner = sqlx::query_as::<_, OwnerRecord>(
            "SELECT id, email, password_hash, full_name FROM owners WHERE id = $1",
        )
        .bind(owner_id)
        .fetch_optional(&self.pool)
        .await?;

        Ok(owner)
    }

    /// Creates the owner, their first store and their trial in one
    /// transaction: an owner without a store cannot record anything, so the
    /// two must never diverge.
    pub async fn create_owner_with_store(
        &self,
        email: &str,
        password_hash: &str,
        full_name: &str,
        store_name: &str,
        business_type: &str,
        trial_ends_at: DateTime<Utc>,
    ) -> ApiResult<(OwnerRecord, StoreRecord)> {
        let mut transaction = self.pool.begin().await?;

        let owner = sqlx::query_as::<_, OwnerRecord>(
            "INSERT INTO owners (email, password_hash, full_name)
             VALUES (lower($1), $2, $3)
             RETURNING id, email, password_hash, full_name",
        )
        .bind(email)
        .bind(password_hash)
        .bind(full_name)
        .fetch_one(&mut *transaction)
        .await?;

        let store = sqlx::query_as::<_, StoreRecord>(
            "INSERT INTO stores (owner_id, name, business_type)
             VALUES ($1, $2, $3)
             RETURNING id, name, business_type, currency_code",
        )
        .bind(owner.id)
        .bind(store_name)
        .bind(business_type)
        .fetch_one(&mut *transaction)
        .await?;

        sqlx::query(
            "INSERT INTO subscriptions (owner_id, plan, trial_ends_at) VALUES ($1, 'pro', $2)",
        )
        .bind(owner.id)
        .bind(trial_ends_at)
        .execute(&mut *transaction)
        .await?;

        transaction.commit().await?;
        Ok((owner, store))
    }

    pub async fn list_stores(&self, owner_id: Uuid) -> ApiResult<Vec<StoreRecord>> {
        let stores = sqlx::query_as::<_, StoreRecord>(
            "SELECT id, name, business_type, currency_code
             FROM stores WHERE owner_id = $1 ORDER BY created_at",
        )
        .bind(owner_id)
        .fetch_all(&self.pool)
        .await?;

        Ok(stores)
    }

    pub async fn find_store(&self, store_id: Uuid) -> ApiResult<Option<StoreRecord>> {
        let store = sqlx::query_as::<_, StoreRecord>(
            "SELECT id, name, business_type, currency_code FROM stores WHERE id = $1",
        )
        .bind(store_id)
        .fetch_optional(&self.pool)
        .await?;

        Ok(store)
    }

    pub async fn open_session(
        &self,
        owner_id: Uuid,
        staff_id: Option<Uuid>,
        device_name: &str,
    ) -> ApiResult<Uuid> {
        let (id,): (Uuid,) = sqlx::query_as(
            "INSERT INTO device_sessions (owner_id, staff_id, device_name)
             VALUES ($1, $2, $3) RETURNING id",
        )
        .bind(owner_id)
        .bind(staff_id)
        .bind(device_name)
        .fetch_one(&self.pool)
        .await?;

        Ok(id)
    }

    pub async fn touch_session(&self, session_id: Uuid) -> ApiResult<()> {
        sqlx::query("UPDATE device_sessions SET last_seen_at = now() WHERE id = $1")
            .bind(session_id)
            .execute(&self.pool)
            .await?;

        Ok(())
    }

    pub async fn store_refresh_token(
        &self,
        owner_id: Uuid,
        session_id: Uuid,
        token_hash: &str,
        expires_at: DateTime<Utc>,
    ) -> ApiResult<()> {
        sqlx::query(
            "INSERT INTO refresh_tokens (owner_id, session_id, token_hash, expires_at)
             VALUES ($1, $2, $3, $4)",
        )
        .bind(owner_id)
        .bind(session_id)
        .bind(token_hash)
        .bind(expires_at)
        .execute(&self.pool)
        .await?;

        Ok(())
    }

    pub async fn find_refresh_token(
        &self,
        token_hash: &str,
    ) -> ApiResult<Option<RefreshTokenRecord>> {
        let record = sqlx::query_as::<_, RefreshTokenRecord>(
            "SELECT t.owner_id, t.session_id, s.staff_id, t.expires_at, t.revoked_at,
                    t.rotated_at,
                    s.revoked_at IS NULL AS session_live,
                    COALESCE(st.removed_at IS NULL, TRUE) AS staff_live
             FROM refresh_tokens t
             JOIN device_sessions s ON s.id = t.session_id
             LEFT JOIN staff_members st ON st.id = s.staff_id
             WHERE t.token_hash = $1",
        )
        .bind(token_hash)
        .fetch_optional(&self.pool)
        .await?;

        Ok(record)
    }

    pub async fn mark_rotated(&self, token_hash: &str) -> ApiResult<()> {
        sqlx::query(
            "UPDATE refresh_tokens SET rotated_at = now()
             WHERE token_hash = $1 AND rotated_at IS NULL",
        )
        .bind(token_hash)
        .execute(&self.pool)
        .await?;

        Ok(())
    }

    /// Signing out ends the whole device session, not just the one token.
    pub async fn end_session_for_token(&self, token_hash: &str) -> ApiResult<()> {
        sqlx::query(
            "WITH ended AS (
                 UPDATE device_sessions SET revoked_at = now()
                 WHERE revoked_at IS NULL
                   AND id = (SELECT session_id FROM refresh_tokens WHERE token_hash = $1)
                 RETURNING id
             )
             UPDATE refresh_tokens SET revoked_at = now()
             WHERE revoked_at IS NULL AND session_id IN (SELECT id FROM ended)",
        )
        .bind(token_hash)
        .execute(&self.pool)
        .await?;

        Ok(())
    }

    /// Housekeeping on sign-in: nothing here can ever be used again.
    pub async fn purge_dead_sessions(&self, owner_id: Uuid) -> ApiResult<()> {
        sqlx::query(
            "DELETE FROM refresh_tokens
             WHERE owner_id = $1
               AND (expires_at < now()
                    OR revoked_at < now() - INTERVAL '7 days'
                    OR rotated_at < now() - INTERVAL '7 days')",
        )
        .bind(owner_id)
        .execute(&self.pool)
        .await?;

        sqlx::query(
            "DELETE FROM device_sessions s
             WHERE s.owner_id = $1
               AND s.created_at < now() - INTERVAL '1 day'
               AND NOT EXISTS (SELECT 1 FROM refresh_tokens t WHERE t.session_id = s.id)",
        )
        .bind(owner_id)
        .execute(&self.pool)
        .await?;

        Ok(())
    }
}
