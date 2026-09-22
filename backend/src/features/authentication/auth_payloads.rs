use serde::{Deserialize, Serialize};
use uuid::Uuid;
use validator::Validate;

#[derive(Debug, Deserialize, Validate)]
pub struct RegisterRequest {
    #[validate(email(message = "must be a valid email address"))]
    pub email: String,

    #[validate(length(min = 8, message = "must be at least 8 characters"))]
    pub password: String,

    #[validate(length(min = 2, max = 80, message = "must be between 2 and 80 characters"))]
    pub full_name: String,

    #[validate(length(min = 2, max = 80, message = "must be between 2 and 80 characters"))]
    pub store_name: String,

    #[serde(default)]
    pub business_type: Option<String>,

    #[serde(default)]
    pub device_tag: Option<String>,
}

#[derive(Debug, Deserialize, Validate)]
pub struct LoginRequest {
    #[validate(email(message = "must be a valid email address"))]
    pub email: String,

    #[validate(length(min = 1, message = "is required"))]
    pub password: String,

    #[serde(default)]
    pub device_tag: Option<String>,
}

#[derive(Debug, Deserialize, Validate)]
pub struct RefreshRequest {
    #[validate(length(min = 1, message = "is required"))]
    pub refresh_token: String,
}

#[derive(Debug, Serialize)]
pub struct AuthenticatedSession {
    pub access_token: String,
    pub refresh_token: String,
    pub expires_in_seconds: i64,
    pub owner: OwnerProfile,
    pub stores: Vec<StoreSummary>,
}

#[derive(Debug, Serialize)]
pub struct OwnerProfile {
    pub id: Uuid,
    pub email: String,
    pub full_name: String,
}

#[derive(Debug, Serialize)]
pub struct StoreSummary {
    pub id: Uuid,
    pub name: String,
    pub business_type: String,
    pub currency_code: String,
}
