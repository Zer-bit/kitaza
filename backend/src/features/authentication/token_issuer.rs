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
