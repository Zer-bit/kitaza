use chrono::{Duration, Utc};
use jsonwebtoken::{Algorithm, DecodingKey, EncodingKey, Header, Validation, decode, encode};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

use crate::config::SecuritySettings;
use crate::shared::ApiError;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AccessClaims {
    pub sub: String,
    pub email: String,
    pub iat: i64,
    pub exp: i64,
}

impl AccessClaims {
    pub fn owner_id(&self) -> Uuid {
        Uuid::parse_str(&self.sub).unwrap_or_default()
    }
}

/// Signs and verifies the short-lived access token. Refresh tokens are opaque
/// random strings handled by `AuthService`, never JWTs, so they can be revoked.
#[derive(Clone)]
pub struct TokenIssuer {
    encoding_key: EncodingKey,
    decoding_key: DecodingKey,
    validation: Validation,
    access_lifetime: Duration,
}

impl TokenIssuer {
    pub fn new(settings: &SecuritySettings) -> Self {
        let secret = settings.jwt_secret.as_bytes();
        Self {
            encoding_key: EncodingKey::from_secret(secret),
            decoding_key: DecodingKey::from_secret(secret),
            validation: Validation::new(Algorithm::HS256),
            access_lifetime: settings.access_token_lifetime,
        }
    }

    pub fn access_lifetime_seconds(&self) -> i64 {
        self.access_lifetime.num_seconds()
    }

    pub fn issue_access_token(&self, owner_id: Uuid, email: &str) -> Result<String, ApiError> {
        let issued_at = Utc::now();
        let claims = AccessClaims {
            sub: owner_id.to_string(),
            email: email.to_owned(),
            iat: issued_at.timestamp(),
            exp: (issued_at + self.access_lifetime).timestamp(),
        };

        encode(&Header::new(Algorithm::HS256), &claims, &self.encoding_key)
            .map_err(|error| ApiError::Internal(error.into()))
    }

    pub fn verify_access_token(&self, token: &str) -> Result<AccessClaims, ApiError> {
        decode::<AccessClaims>(token, &self.decoding_key, &self.validation)
            .map(|data| data.claims)
            .map_err(|_| ApiError::Unauthorized("your session has expired, please sign in".into()))
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn issuer() -> TokenIssuer {
        TokenIssuer::new(&SecuritySettings {
            jwt_secret: "a-test-secret-that-is-comfortably-over-32-chars".into(),
            access_token_lifetime: Duration::minutes(5),
            refresh_token_lifetime: Duration::days(1),
        })
    }

    /// Guards the crypto backend: jsonwebtoken 11 panics at runtime, not at
    /// compile time, when no provider feature is enabled.
    #[test]
    fn an_issued_token_verifies_and_names_its_owner() {
        let issuer = issuer();
        let owner_id = Uuid::new_v4();

        let token = issuer
            .issue_access_token(owner_id, "nena@example.com")
            .unwrap();
        let claims = issuer.verify_access_token(&token).unwrap();

        assert_eq!(claims.owner_id(), owner_id);
        assert_eq!(claims.email, "nena@example.com");
    }

    #[test]
    fn a_token_signed_with_another_secret_is_rejected() {
        let foreign = TokenIssuer::new(&SecuritySettings {
            jwt_secret: "a-completely-different-secret-over-32-characters".into(),
            access_token_lifetime: Duration::minutes(5),
            refresh_token_lifetime: Duration::days(1),
        });
        let token = foreign
            .issue_access_token(Uuid::new_v4(), "x@example.com")
            .unwrap();

        assert!(issuer().verify_access_token(&token).is_err());
    }

    #[test]
    fn a_tampered_token_is_rejected() {
        let issuer = issuer();
        let mut token = issuer
            .issue_access_token(Uuid::new_v4(), "x@example.com")
            .unwrap();
        token.push('x');

        assert!(issuer.verify_access_token(&token).is_err());
    }
}
