use chrono::{Duration, Utc};
use serde_json::json;
use uuid::Uuid;

use crate::features::access::{Actor, Permissions, SessionDirectory};
use crate::features::audit::{AuditAction, AuditEntry, AuditTrail};
use crate::features::billing::BillingService;
use crate::infrastructure::realtime::{EventBroadcaster, RealtimeEvent, RealtimeTopic};
use crate::shared::{ApiError, ApiResult};

use super::join_code;
use super::staff_payloads::{AddedStaff, InviteView, SaveStaffRequest, StaffView};
use super::staff_repository::{StaffRecord, StaffRepository};

/// Long enough to hand a code over tomorrow morning, short enough that a
/// code photographed off a screen is soon useless.
const INVITE_LIFETIME: Duration = Duration::hours(24);

/// The owner's side of staff accounts. Every method here is owner-only; the
/// handlers enforce that before calling in.
#[derive(Clone)]
pub struct StaffService {
    repository: StaffRepository,
    sessions: SessionDirectory,
    audit: AuditTrail,
    broadcaster: EventBroadcaster,
    billing: BillingService,
}

impl StaffService {
    pub fn new(
        repository: StaffRepository,
        sessions: SessionDirectory,
        audit: AuditTrail,
        broadcaster: EventBroadcaster,
        billing: BillingService,
    ) -> Self {
        Self {
            repository,
            sessions,
            audit,
            broadcaster,
            billing,
        }
    }

    pub async fn list(&self, store_id: Uuid) -> ApiResult<Vec<StaffView>> {
        let staff = self.repository.list(store_id).await?;
        Ok(staff.into_iter().map(StaffView::from_listing).collect())
    }

    pub async fn add(
        &self,
        store_id: Uuid,
        actor: &Actor,
        request: SaveStaffRequest,
    ) -> ApiResult<AddedStaff> {
        self.billing.check_staff(actor.subscription.as_ref())?;
        let permissions = Permissions::from_list(&request.permissions);
        let staff = self
            .repository
            .create(store_id, request.display_name.trim(), permissions)
            .await?;
        let invite = self.new_invite(staff.id).await?;

        self.log(actor, &staff, AuditAction::StaffAdded).await;

        Ok(AddedStaff {
            staff: StaffView::from_record(staff),
            invite,
        })
    }

    pub async fn update(
        &self,
        store_id: Uuid,
        actor: &Actor,
        staff_id: Uuid,
        request: SaveStaffRequest,
    ) -> ApiResult<StaffView> {
        let staff = self
            .repository
            .update(
                store_id,
                staff_id,
                request.display_name.trim(),
                Permissions::from_list(&request.permissions),
            )
            .await?
            .ok_or(ApiError::NotFound("staff member"))?;

        self.log(actor, &staff, AuditAction::StaffChanged).await;
        self.access_changed(store_id).await;

        Ok(StaffView::from_record(staff))
    }

    /// Their phones are signed out in the same step.
    pub async fn remove(&self, store_id: Uuid, actor: &Actor, staff_id: Uuid) -> ApiResult<()> {
        let staff = self
            .repository
            .remove(store_id, staff_id)
            .await?
            .ok_or(ApiError::NotFound("staff member"))?;

        self.log(actor, &staff, AuditAction::StaffRemoved).await;
        self.access_changed(store_id).await;
        Ok(())
    }

    /// For a staff member's new or replaced phone. Any earlier unused code
    /// stops working.
    pub async fn reinvite(
        &self,
        store_id: Uuid,
        actor: &Actor,
        staff_id: Uuid,
    ) -> ApiResult<InviteView> {
        self.billing.check_staff(actor.subscription.as_ref())?;
        let staff = self
            .repository
            .find(store_id, staff_id)
            .await?
            .ok_or(ApiError::NotFound("staff member"))?;
        let invite = self.new_invite(staff.id).await?;

        self.log(actor, &staff, AuditAction::StaffInvited).await;
        Ok(invite)
    }

    async fn new_invite(&self, staff_id: Uuid) -> ApiResult<InviteView> {
        let code = join_code::generate();
        let expires_at = Utc::now() + INVITE_LIFETIME;

        self.repository
            .replace_invite(staff_id, &join_code::fingerprint(&code), expires_at)
            .await?;

        Ok(InviteView { code, expires_at })
    }

    async fn log(&self, actor: &Actor, staff: &StaffRecord, action: AuditAction) {
        self.audit
            .record(
                actor,
                AuditEntry::new(
                    staff.store_id,
                    action,
                    staff.id,
                    json!({
                        "name": staff.display_name,
                        "permissions": staff.permissions().to_list(),
                    }),
                ),
            )
            .await;
    }

    /// Makes the change bite now: this instance stops trusting what it
    /// remembered, and the store's phones are told to re-read their access.
    async fn access_changed(&self, store_id: Uuid) {
        self.sessions.forget_all();
        self.broadcaster
            .publish(RealtimeEvent::new(
                store_id,
                RealtimeTopic::AccessChanged,
                None,
            ))
            .await;
    }
}
