use chrono::{Duration, Utc};
use rand::RngExt;
use serde_json::json;
use sha2::{Digest, Sha256};
use uuid::Uuid;

use crate::features::access::{Actor, SessionDirectory};
use crate::features::audit::{AuditAction, AuditEntry, AuditTrail};
use crate::features::billing::BillingService;
use crate::features::staff::{StaffRepository, join_code};
use crate::infrastructure::cache::{RateLimitVerdict, RateLimiter};
use crate::shared::{ApiError, ApiResult};

use super::auth_payloads::{
    AccessSummary, AccountView, AuthenticatedSession, JoinRequest, LoginRequest, OwnerProfile,
    RegisterRequest, StoreSummary,
};
use super::auth_repository::{AuthRepository, OwnerRecord, StoreRecord};
use super::password_hasher::{hash_password, verify_password};
use super::token_issuer::TokenIssuer;

const DEFAULT_BUSINESS_TYPE: &str = "sari_sari";
const REFRESH_TOKEN_BYTES: usize = 32;
const UNKNOWN_DEVICE: &str = "Unknown device";

/// How long a refresh token keeps working after it has been exchanged.
///
/// Without this, a refresh whose response is lost - a jeepney going through a
/// dead zone at the wrong moment - leaves the phone holding a token the
/// server has already retired, and the owner signed out for good. Revoking a
/// device still ends every token it holds at once.
const ROTATION_GRACE: Duration = Duration::hours(24);

pub struct AuthDependencies {
    pub repository: AuthRepository,
    pub staff: StaffRepository,
    pub token_issuer: TokenIssuer,
    pub rate_limiter: RateLimiter,
    pub sessions: SessionDirectory,
    pub audit: AuditTrail,
    pub billing: BillingService,
    pub refresh_lifetime: Duration,
}

#[derive(Clone)]
pub struct AuthService {
    repository: AuthRepository,
    staff: StaffRepository,
    token_issuer: TokenIssuer,
    rate_limiter: RateLimiter,
    sessions: SessionDirectory,
    audit: AuditTrail,
    billing: BillingService,
    refresh_lifetime: Duration,
}

impl AuthService {
    pub fn new(dependencies: AuthDependencies) -> Self {
        Self {
            repository: dependencies.repository,
            staff: dependencies.staff,
            token_issuer: dependencies.token_issuer,
            rate_limiter: dependencies.rate_limiter,
            sessions: dependencies.sessions,
            audit: dependencies.audit,
            billing: dependencies.billing,
            refresh_lifetime: dependencies.refresh_lifetime,
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

        let (owner, _) = self
            .repository
            .create_owner_with_store(
                &email,
                &password_hash,
                request.full_name.trim(),
                request.store_name.trim(),
                &business_type,
                Utc::now() + self.billing.trial_length(),
            )
            .await?;

        let device = device_name(request.device_name, request.device_tag);
        self.open_owner_session(owner, device).await
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
        self.repository.purge_dead_sessions(owner.id).await?;

        let device = device_name(request.device_name, request.device_tag);
        self.open_owner_session(owner, device).await
    }

    /// A staff member's phone joining with the code their owner shared. The
    /// code is used up: a second phone needs a new one.
    pub async fn join(&self, request: JoinRequest) -> ApiResult<AuthenticatedSession> {
        let code_hash = join_code::fingerprint(&request.code);

        // Checked before the code is used up, so an owner who upgrades can
        // hand over the same code.
        if let Some(owner_id) = self.staff.owner_of_code(&code_hash).await? {
            let subscription = self.billing.subscription_of(owner_id).await?;
            self.billing.check_staff(subscription.as_ref())?;
        }

        let redeemed = self.staff.redeem(&code_hash).await?.ok_or_else(|| {
            ApiError::Unauthorized("this code is not valid or has expired".into())
        })?;

        let device = device_name(request.device_name, request.device_tag);
        let session_id = self
            .repository
            .open_session(redeemed.owner_id, Some(redeemed.staff.id), &device)
            .await?;
        let actor = self.actor_for(session_id).await?;

        self.audit
            .record(
                &actor,
                AuditEntry::new(
                    redeemed.staff.store_id,
                    AuditAction::StaffJoined,
                    redeemed.staff.id,
                    json!({ "name": actor.name, "device": actor.device_name }),
                ),
            )
            .await;

        self.issue(&actor).await
    }

    /// Exchanges a refresh token for a fresh pair within the same device
    /// session.
    pub async fn refresh(&self, refresh_token: &str) -> ApiResult<AuthenticatedSession> {
        let token_hash = fingerprint(refresh_token);
        let record = self
            .repository
            .find_refresh_token(&token_hash)
            .await?
            .ok_or_else(sign_in_again)?;

        let now = Utc::now();
        let rotated_long_ago = record
            .rotated_at
            .is_some_and(|rotated| rotated + ROTATION_GRACE <= now);

        if record.revoked_at.is_some()
            || record.expires_at <= now
            || rotated_long_ago
            || !record.session_live
            || !record.staff_live
        {
            return Err(sign_in_again());
        }

        self.repository.mark_rotated(&token_hash).await?;
        self.repository.touch_session(record.session_id).await?;

        let actor = self
            .sessions
            .resolve(record.session_id)
            .await?
            .ok_or_else(sign_in_again)?;

        debug_assert_eq!(actor.owner_id, record.owner_id);
        debug_assert_eq!(actor.staff_id(), record.staff_id);
        self.issue(&actor).await
    }

    /// Signing out ends this device's session outright.
    pub async fn logout(&self, refresh_token: &str) -> ApiResult<()> {
        self.repository
            .end_session_for_token(&fingerprint(refresh_token))
            .await?;
        self.sessions.forget_all();
        Ok(())
    }

    pub async fn account(&self, actor: &Actor) -> ApiResult<AccountView> {
        let owner = self
            .repository
            .find_owner_by_id(actor.owner_id)
            .await?
            .ok_or(ApiError::NotFound("account"))?;

        let (email, stores) = match actor.staff {
            None => (
                Some(owner.email.clone()),
                self.repository.list_stores(owner.id).await?,
            ),
            Some(grant) => (
                None,
                self.repository
                    .find_store(grant.store_id)
                    .await?
                    .into_iter()
                    .collect(),
            ),
        };

        Ok(AccountView {
            owner: OwnerProfile {
                id: owner.id,
                email,
                full_name: owner.full_name,
            },
            stores: stores.iter().map(to_summary).collect(),
            access: AccessSummary::of(actor),
            subscription: self.billing.summary(actor.subscription.as_ref()),
        })
    }

    async fn open_owner_session(
        &self,
        owner: OwnerRecord,
        device: String,
    ) -> ApiResult<AuthenticatedSession> {
        let session_id = self
            .repository
            .open_session(owner.id, None, &device)
            .await?;
        let actor = self.actor_for(session_id).await?;
        self.issue(&actor).await
    }

    /// The actor behind a session just opened, subscription and all.
    async fn actor_for(&self, session_id: Uuid) -> ApiResult<Actor> {
        self.sessions
            .resolve(session_id)
            .await?
            .ok_or_else(|| ApiError::Internal(anyhow::anyhow!("a new session did not resolve")))
    }

    async fn issue(&self, actor: &Actor) -> ApiResult<AuthenticatedSession> {
        let access_token = self
            .token_issuer
            .issue_access_token(actor.owner_id, actor.session_id)?;
        let refresh_token = generate_refresh_token();

        self.repository
            .store_refresh_token(
                actor.owner_id,
                actor.session_id,
                &fingerprint(&refresh_token),
                Utc::now() + self.refresh_lifetime,
            )
            .await?;

        Ok(AuthenticatedSession {
            access_token,
            refresh_token,
            expires_in_seconds: self.token_issuer.access_lifetime_seconds(),
            session_id: actor.session_id,
            account: self.account(actor).await?,
        })
    }
}

fn invalid_credentials() -> ApiError {
    ApiError::Unauthorized("email or password is incorrect".into())
}

fn sign_in_again() -> ApiError {
    ApiError::Unauthorized("please sign in again".into())
}

fn device_name(name: Option<String>, tag: Option<String>) -> String {
    name.or(tag)
        .map(|value| value.trim().chars().take(80).collect::<String>())
        .filter(|value| !value.is_empty())
        .unwrap_or_else(|| UNKNOWN_DEVICE.to_owned())
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

pub fn to_summary(store: &StoreRecord) -> StoreSummary {
    StoreSummary {
        id: store.id,
        name: store.name.clone(),
        business_type: store.business_type.clone(),
        currency_code: store.currency_code.clone(),
        share_benchmarks: store.share_benchmarks,
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn a_device_is_named_by_its_model_then_its_tag() {
        assert_eq!(
            device_name(Some("Samsung SM-A125F".into()), Some("android".into())),
            "Samsung SM-A125F"
        );
        assert_eq!(device_name(None, Some("android".into())), "android");
        assert_eq!(device_name(Some("   ".into()), None), UNKNOWN_DEVICE);
        assert_eq!(device_name(Some("x".repeat(200)), None).len(), 80);
    }
}
