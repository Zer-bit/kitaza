use serde::{Deserialize, Serialize};
use uuid::Uuid;
use validator::Validate;

use crate::features::access::{Actor, Permission};
use crate::features::billing::SubscriptionSummary;

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

    /// Shown in the owner's list of signed-in devices, such as
    /// "Samsung SM-A125F".
    #[serde(default)]
    #[validate(length(max = 80, message = "must be at most 80 characters"))]
    pub device_name: Option<String>,
}

#[derive(Debug, Deserialize, Validate)]
pub struct LoginRequest {
    #[validate(email(message = "must be a valid email address"))]
    pub email: String,

    #[validate(length(min = 1, message = "is required"))]
    pub password: String,

    #[serde(default)]
    pub device_tag: Option<String>,

    #[serde(default)]
    #[validate(length(max = 80, message = "must be at most 80 characters"))]
    pub device_name: Option<String>,
}

/// A staff member's phone joining a store with the code the owner shared.
#[derive(Debug, Deserialize, Validate)]
pub struct JoinRequest {
    #[validate(length(min = 1, max = 32, message = "is required"))]
    pub code: String,

    #[serde(default)]
    pub device_tag: Option<String>,

    #[serde(default)]
    #[validate(length(max = 80, message = "must be at most 80 characters"))]
    pub device_name: Option<String>,
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
    pub session_id: Uuid,
    #[serde(flatten)]
    pub account: AccountView,
}

/// Who is signed in and what they can reach: the owner of the data, the
/// stores this session may use, and what it may do in them.
#[derive(Debug, Serialize)]
pub struct AccountView {
    pub owner: OwnerProfile,
    pub stores: Vec<StoreSummary>,
    pub access: AccessSummary,
    pub subscription: SubscriptionSummary,
}

#[derive(Debug, Serialize)]
pub struct OwnerProfile {
    pub id: Uuid,
    /// Left out for staff, who have no business with the owner's login.
    #[serde(skip_serializing_if = "Option::is_none")]
    pub email: Option<String>,
    pub full_name: String,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize)]
#[serde(rename_all = "snake_case")]
pub enum MemberRole {
    Owner,
    Staff,
}

#[derive(Debug, Serialize)]
pub struct AccessSummary {
    pub role: MemberRole,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub staff_id: Option<Uuid>,
    pub display_name: String,
    pub permissions: Vec<Permission>,
}

impl AccessSummary {
    pub fn of(actor: &Actor) -> Self {
        Self {
            role: if actor.is_owner() {
                MemberRole::Owner
            } else {
                MemberRole::Staff
            },
            staff_id: actor.staff_id(),
            display_name: actor.name.clone(),
            permissions: actor.permissions().to_list(),
        }
    }
}

#[derive(Debug, Serialize)]
pub struct StoreSummary {
    pub id: Uuid,
    pub name: String,
    pub business_type: String,
    pub currency_code: String,
    /// Whether this store's figures join the anonymous comparisons.
    pub share_benchmarks: bool,
}
