use uuid::Uuid;

use crate::shared::{ApiError, ApiResult};

use super::permission::{Permission, Permissions};

/// Who is making a request: the owner, or one of their staff, on a particular
/// signed-in device. Every write carries one, which is how the audit log knows
/// who did what.
#[derive(Debug, Clone)]
pub struct Actor {
    /// The account the data belongs to. For staff, their store's owner.
    pub owner_id: Uuid,
    pub session_id: Uuid,
    pub name: String,
    pub device_name: String,
    pub staff: Option<StaffGrant>,
}

/// What a staff member's session is limited to: one store, and whatever the
/// owner switched on.
#[derive(Debug, Clone, Copy)]
pub struct StaffGrant {
    pub staff_id: Uuid,
    pub store_id: Uuid,
    pub permissions: Permissions,
}

impl Actor {
    pub fn is_owner(&self) -> bool {
        self.staff.is_none()
    }

    pub fn staff_id(&self) -> Option<Uuid> {
        self.staff.map(|grant| grant.staff_id)
    }

    pub fn permissions(&self) -> Permissions {
        self.staff
            .map(|grant| grant.permissions)
            .unwrap_or(Permissions::ALL)
    }

    pub fn can(&self, permission: Permission) -> bool {
        self.permissions().allows(permission)
    }

    pub fn require(&self, permission: Permission) -> ApiResult<()> {
        if self.can(permission) {
            Ok(())
        } else {
            Err(ApiError::Forbidden(permission.refusal().into()))
        }
    }

    pub fn require_owner(&self) -> ApiResult<()> {
        if self.is_owner() {
            Ok(())
        } else {
            Err(ApiError::Forbidden("only the owner can do this".into()))
        }
    }

    /// Whether this actor may change a record someone already saved. Owners
    /// may change anything; staff only what they recorded themselves, which
    /// is what lets a phone safely retry its own push.
    pub fn may_amend(&self, recorded_by: Option<Uuid>) -> bool {
        match self.staff_id() {
            None => true,
            Some(staff_id) => recorded_by == Some(staff_id),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn staff(permissions: Permissions) -> Actor {
        Actor {
            owner_id: Uuid::new_v4(),
            session_id: Uuid::new_v4(),
            name: "Liza".into(),
            device_name: "Counter phone".into(),
            staff: Some(StaffGrant {
                staff_id: Uuid::new_v4(),
                store_id: Uuid::new_v4(),
                permissions,
            }),
        }
    }

    #[test]
    fn an_owner_can_do_everything() {
        let owner = Actor {
            staff: None,
            ..staff(Permissions::default())
        };

        assert!(Permission::ALL.iter().all(|p| owner.can(*p)));
        assert!(owner.require_owner().is_ok());
        assert!(owner.may_amend(Some(Uuid::new_v4())));
    }

    #[test]
    fn staff_are_held_to_their_grant() {
        let cashier = staff(Permissions {
            record_expenses: true,
            ..Permissions::default()
        });

        assert!(cashier.require(Permission::RecordExpenses).is_ok());
        assert!(matches!(
            cashier.require(Permission::DeleteRecords),
            Err(ApiError::Forbidden(_))
        ));
        assert!(cashier.require_owner().is_err());
    }

    #[test]
    fn staff_may_only_amend_their_own_records() {
        let cashier = staff(Permissions::default());
        let own = cashier.staff_id();

        assert!(cashier.may_amend(own));
        assert!(!cashier.may_amend(None), "the owner's record");
        assert!(!cashier.may_amend(Some(Uuid::new_v4())), "a colleague's");
    }
}
