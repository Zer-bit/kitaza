use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;
use validator::Validate;

use crate::features::access::Permission;

use super::staff_repository::{StaffListing, StaffRecord};

#[derive(Debug, Deserialize, Validate)]
pub struct SaveStaffRequest {
    #[validate(length(min = 1, max = 40, message = "must be between 1 and 40 characters"))]
    pub display_name: String,

    /// Anything beyond selling. Empty means a plain cashier.
    #[serde(default)]
    pub permissions: Vec<Permission>,
}

#[derive(Debug, Serialize)]
pub struct StaffView {
    pub id: Uuid,
    pub display_name: String,
    pub permissions: Vec<Permission>,
    pub signed_in_devices: i64,
    /// When the last unused join code stops working. Absent if there is none.
    #[serde(skip_serializing_if = "Option::is_none")]
    pub invite_expires_at: Option<DateTime<Utc>>,
    pub created_at: DateTime<Utc>,
}

impl StaffView {
    pub fn from_listing(listing: StaffListing) -> Self {
        Self {
            signed_in_devices: listing.signed_in_devices,
            invite_expires_at: listing.invite_expires_at,
            ..Self::from_record(listing.staff)
        }
    }

    pub fn from_record(staff: StaffRecord) -> Self {
        Self {
            id: staff.id,
            permissions: staff.permissions().to_list(),
            display_name: staff.display_name,
            signed_in_devices: 0,
            invite_expires_at: None,
            created_at: staff.created_at,
        }
    }
}

/// A join code, shown to the owner once. Only its hash is kept.
#[derive(Debug, Serialize)]
pub struct InviteView {
    pub code: String,
    pub expires_at: DateTime<Utc>,
}

#[derive(Debug, Serialize)]
pub struct AddedStaff {
    pub staff: StaffView,
    pub invite: InviteView,
}
