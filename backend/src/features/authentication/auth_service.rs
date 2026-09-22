use chrono::{Duration, Utc};
use rand::RngExt;
use sha2::{Digest, Sha256};
use uuid::Uuid;

use crate::infrastructure::cache::{RateLimitVerdict, RateLimiter};
use crate::shared::{ApiError, ApiResult};

use super::auth_payloads::{
    AuthenticatedSession, LoginRequest, OwnerProfile, RegisterRequest, StoreSummary,
};
use super::auth_repository::{AuthRepository, OwnerRecord, StoreRecord};
use super::password_hasher::{hash_password, verify_password};
use super::token_issuer::TokenIssuer;

const DEFAULT_BUSINESS_TYPE: &str = "sari_sari";
const REFRESH_TOKEN_BYTES: usize = 32;

#[derive(Clone)]
pub struct AuthService {
    repository: AuthRepository,
    token_issuer: TokenIssuer,
    rate_limiter: RateLimiter,
    refresh_lifetime: Duration,
}

impl AuthService {
    pub fn new(
        repository: AuthRepository,
        token_issuer: TokenIssuer,
        rate_limiter: RateLimiter,
        refresh_lifetime: Duration,
    ) -> Self {
        Self {
            repository,
            token_issuer,
            rate_limiter,
            refresh_lifetime,
        }
    }

    pub async fn register(&self, request: RegisterRequest) -> ApiResult<AuthenticatedSession> {
        let email = request.email.trim().to_lowercase();

        if self.repository.find_owner_by_email(&email).await?.is_some() {
            return Err(ApiError::Conflict(
                "an account already uses this email address".into(),
            ));
        }

        let password_hash = hash_on_blocking_pool(request.password).await?;
        let business_type = request
            .business_type
            .unwrap_or_else(|| DEFAULT_BUSINESS_TYPE.to_owned());

        let (owner, store) = self
            .repository
            .create_owner_with_store(
                &email,
                &password_hash,
                request.full_name.trim(),
                request.store_name.trim(),
                &business_type,
            )
            .await?;

        self.build_session(owner, vec![store], request.device_tag)
            .await
    }

    pub async fn login(&self, request: LoginRequest) -> ApiResult<AuthenticatedSession> {
        let email = request.email.trim().to_lowercase();
        let bucket = format!("login:{email}");

        if matches!(
            self.rate_limiter.check(&bucket).await,
            RateLimitVerdict::Exceeded
        ) {
            return Err(ApiError::TooManyRequests);
        }

        let owner = self.repository.find_owner_by_email(&email).await?;
        let Some(owner) = owner else {
            // Same error and roughly the same cost as a wrong password, so the
            // response does not reveal which emails are registered.
            let _ = hash_on_blocking_pool(request.password).await;
            return Err(invalid_credentials());
        };

        let stored_hash = owner.password_hash.clone();
        let candidate = request.password;
        let matches =
            tokio::task::spawn_blocking(move || verify_password(&candidate, &stored_hash))
                .await
                .map_err(|error| ApiError::Internal(error.into()))?;

        if !matches {
            return Err(invalid_credentials());
        }

        self.rate_limiter.reset(&bucket).await;
        self.repository.purge_expired_tokens(owner.id).await?;

        let stores = self.repository.list_stores(owner.id).await?;
        self.build_session(owner, stores, request.device_tag).await
    }

    /// Exchanges a refresh token for a fresh pair. The old token is revoked on
    /// use, so a stolen token stops working as soon as the real device
    /// refreshes.
    pub async fn refresh(&self, refresh_token: &str) -> ApiResult<AuthenticatedSession> {
        let token_hash = fingerprint(refresh_token);
        let record = self
            .repository
            .find_refresh_token(&token_hash)
            .await?
            .ok_or_else(|| ApiError::Unauthorized("please sign in again".into()))?;

        if record.revoked_at.is_some() || record.expires_at <= Utc::now() {
            return Err(ApiError::Unauthorized("please sign in again".into()));
        }

        self.repository.revoke_refresh_token(&token_hash).await?;

        let owner = self
            .repository
            .find_owner_by_id(record.owner_id)
            .await?
            .ok_or_else(|| ApiError::Unauthorized("please sign in again".into()))?;

        let stores = self.repository.list_stores(owner.id).await?;
        self.build_session(owner, stores, None).await
    }

    pub async fn logout(&self, refresh_token: &str) -> ApiResult<()> {
        self.repository
            .revoke_refresh_token(&fingerprint(refresh_token))
            .await
    }

    pub async fn profile(&self, owner_id: Uuid) -> ApiResult<(OwnerProfile, Vec<StoreSummary>)> {
        let owner = self
            .repository
            .find_owner_by_id(owner_id)
            .await?
            .ok_or(ApiError::NotFound("account"))?;
        let stores = self.repository.list_stores(owner_id).await?;

        Ok((to_profile(&owner), stores.iter().map(to_summary).collect()))
    }

    async fn build_session(
        &self,
        owner: OwnerRecord,
        stores: Vec<StoreRecord>,
        device_tag: Option<String>,
    ) -> ApiResult<AuthenticatedSession> {
        let access_token = self
            .token_issuer
            .issue_access_token(owner.id, &owner.email)?;
        let refresh_token = generate_refresh_token();

        self.repository
            .store_refresh_token(
                owner.id,
                &fingerprint(&refresh_token),
                device_tag.as_deref().unwrap_or("unknown"),
                Utc::now() + self.refresh_lifetime,
            )
            .await?;

        Ok(AuthenticatedSession {
            access_token,
            refresh_token,
            expires_in_seconds: self.token_issuer.access_lifetime_seconds(),
            owner: to_profile(&owner),
            stores: stores.iter().map(to_summary).collect(),
        })
    }
}

fn invalid_credentials() -> ApiError {
    ApiError::Unauthorized("email or password is incorrect".into())
}

async fn hash_on_blocking_pool(password: String) -> ApiResult<String> {
    tokio::task::spawn_blocking(move || hash_password(&password))
        .await
        .map_err(|error| ApiError::Internal(error.into()))?
}

fn generate_refresh_token() -> String {
    let mut bytes = [0u8; REFRESH_TOKEN_BYTES];
    rand::rng().fill(&mut bytes);
    hex::encode(bytes)
}

/// Refresh tokens are stored as SHA-256 digests. They are high-entropy random
/// strings, so a fast digest is enough and keeps refresh cheap.
fn fingerprint(token: &str) -> String {
    hex::encode(Sha256::digest(token.as_bytes()))
}

fn to_profile(owner: &OwnerRecord) -> OwnerProfile {
    OwnerProfile {
        id: owner.id,
        email: owner.email.clone(),
        full_name: owner.full_name.clone(),
    }
}

fn to_summary(store: &StoreRecord) -> StoreSummary {
    StoreSummary {
        id: store.id,
        name: store.name.clone(),
        business_type: store.business_type.clone(),
        currency_code: store.currency_code.clone(),
    }
}
