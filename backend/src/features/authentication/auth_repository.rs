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
    pub expires_at: DateTime<Utc>,
    pub revoked_at: Option<DateTime<Utc>>,
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

    /// Creates the owner and their first store in one transaction: an owner
    /// without a store cannot record anything, so the two must never diverge.
    pub async fn create_owner_with_store(
        &self,
        email: &str,
        password_hash: &str,
        full_name: &str,
        store_name: &str,
        business_type: &str,
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

    pub async fn store_refresh_token(
        &self,
        owner_id: Uuid,
        token_hash: &str,
        device_tag: &str,
        expires_at: DateTime<Utc>,
    ) -> ApiResult<()> {
        sqlx::query(
            "INSERT INTO refresh_tokens (owner_id, token_hash, device_tag, expires_at)
             VALUES ($1, $2, $3, $4)",
        )
        .bind(owner_id)
        .bind(token_hash)
        .bind(device_tag)
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
            "SELECT owner_id, expires_at, revoked_at
             FROM refresh_tokens WHERE token_hash = $1",
        )
        .bind(token_hash)
        .fetch_optional(&self.pool)
        .await?;

        Ok(record)
    }

    pub async fn revoke_refresh_token(&self, token_hash: &str) -> ApiResult<()> {
        sqlx::query(
            "UPDATE refresh_tokens SET revoked_at = now()
             WHERE token_hash = $1 AND revoked_at IS NULL",
        )
        .bind(token_hash)
        .execute(&self.pool)
        .await?;

        Ok(())
    }

    pub async fn purge_expired_tokens(&self, owner_id: Uuid) -> ApiResult<()> {
        sqlx::query(
            "DELETE FROM refresh_tokens
             WHERE owner_id = $1 AND (expires_at < now() OR revoked_at < now() - INTERVAL '7 days')",
        )
        .bind(owner_id)
        .execute(&self.pool)
        .await?;

        Ok(())
    }
}
