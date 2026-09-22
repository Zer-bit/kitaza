use std::str::FromStr;

use argon2::password_hash::phc::PasswordHash;
use argon2::{Argon2, PasswordHasher, PasswordVerifier};

use crate::shared::ApiError;

/// Argon2id with the crate's recommended parameters. Hashing is CPU bound, so
/// callers run it on the blocking pool to keep the async runtime responsive.
pub fn hash_password(plain: &str) -> Result<String, ApiError> {
    Argon2::default()
        .hash_password(plain.as_bytes())
        .map(|hash| hash.to_string())
        .map_err(|error| ApiError::Internal(anyhow::anyhow!("password hashing failed: {error}")))
}

pub fn verify_password(plain: &str, encoded_hash: &str) -> bool {
    let Ok(parsed) = PasswordHash::from_str(encoded_hash) else {
        return false;
    };
    Argon2::default()
        .verify_password(plain.as_bytes(), &parsed)
        .is_ok()
}
