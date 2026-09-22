use std::collections::HashMap;
use std::sync::{Arc, RwLock};
use std::time::{Duration, Instant};

use sqlx::FromRow;
use uuid::Uuid;

use crate::infrastructure::database::PgPool;
use crate::shared::ApiResult;

use crate::features::billing::SubscriptionRecord;

use super::actor::{Actor, StaffGrant};
use super::permission::Permissions;

/// How long a resolved session is trusted before being looked up again. This
/// bounds how long a revoked device or a changed permission can go unnoticed
/// by another server instance; revoking through this instance is immediate.
const TRUST_WINDOW: Duration = Duration::from_secs(20);

/// Past this many remembered sessions the memory is simply cleared; the cost
/// is one lookup per active device.
const MAX_REMEMBERED: usize = 10_000;

/// When each session was looked up, and who it turned out to be.
type Remembered = HashMap<Uuid, (Instant, Option<Actor>)>;

#[derive(FromRow)]
struct SessionRow {
    owner_id: Uuid,
    owner_name: String,
    device_name: String,
    session_live: bool,
    staff_id: Option<Uuid>,
    staff_name: Option<String>,
    staff_store_id: Option<Uuid>,
    staff_live: Option<bool>,
    can_manage_products: Option<bool>,
    can_record_expenses: Option<bool>,
    can_view_profit: Option<bool>,
    can_delete_records: Option<bool>,
    plan: Option<String>,
    trial_ends_at: Option<chrono::DateTime<chrono::Utc>>,
    paid_through: Option<chrono::DateTime<chrono::Utc>>,
}

/// Turns a session id from an access token into the person behind it, or
/// nothing if that device has been signed out or that staff member removed.
///
/// Checked on every request rather than trusted from the token: an access
/// token lives for an hour, and "I revoked the stolen phone but it kept
/// selling for an hour" is not an acceptable answer.
#[derive(Clone)]
pub struct SessionDirectory {
    pool: PgPool,
    resolved: Arc<RwLock<Remembered>>,
}

impl SessionDirectory {
    pub fn new(pool: PgPool) -> Self {
        Self {
            pool,
            resolved: Arc::new(RwLock::new(HashMap::new())),
        }
    }

    pub async fn resolve(&self, session_id: Uuid) -> ApiResult<Option<Actor>> {
        if let Some(actor) = self.remembered(session_id) {
            return Ok(actor);
        }

        let row = sqlx::query_as::<_, SessionRow>(
            "SELECT s.owner_id, o.full_name AS owner_name, s.device_name,
                    s.revoked_at IS NULL AS session_live,
                    st.id AS staff_id, st.display_name AS staff_name,
                    st.store_id AS staff_store_id,
                    st.removed_at IS NULL AS staff_live,
                    st.can_manage_products, st.can_record_expenses,
                    st.can_view_profit, st.can_delete_records,
                    sub.plan, sub.trial_ends_at, sub.paid_through
             FROM device_sessions s
             JOIN owners o ON o.id = s.owner_id
             LEFT JOIN staff_members st ON st.id = s.staff_id
             LEFT JOIN subscriptions sub ON sub.owner_id = s.owner_id
             WHERE s.id = $1",
        )
        .bind(session_id)
        .fetch_optional(&self.pool)
        .await?;

        let actor = row.and_then(|row| into_actor(session_id, row));
        let mut resolved = self.resolved.write().expect("session directory poisoned");
        if resolved.len() >= MAX_REMEMBERED {
            resolved.clear();
        }
        resolved.insert(session_id, (Instant::now(), actor.clone()));

        Ok(actor)
    }

    /// Drops everything remembered, after a revoke or a permission change,
    /// so this instance sees it on the very next request.
    pub fn forget_all(&self) {
        self.resolved
            .write()
            .expect("session directory poisoned")
            .clear();
    }

    fn remembered(&self, session_id: Uuid) -> Option<Option<Actor>> {
        let resolved = self.resolved.read().expect("session directory poisoned");
        let (at, actor) = resolved.get(&session_id)?;
        (at.elapsed() < TRUST_WINDOW).then(|| actor.clone())
    }
}

fn into_actor(session_id: Uuid, row: SessionRow) -> Option<Actor> {
    if !row.session_live {
        return None;
    }

    let staff = match row.staff_id {
        None => None,
        Some(staff_id) => {
            if row.staff_live != Some(true) {
                return None;
            }
            Some(StaffGrant {
                staff_id,
                store_id: row.staff_store_id?,
                permissions: Permissions {
                    manage_products: row.can_manage_products.unwrap_or(false),
                    record_expenses: row.can_record_expenses.unwrap_or(false),
                    view_profit: row.can_view_profit.unwrap_or(false),
                    delete_records: row.can_delete_records.unwrap_or(false),
                },
            })
        }
    };

    let subscription = row.plan.map(|plan| SubscriptionRecord {
        plan,
        trial_ends_at: row.trial_ends_at,
        paid_through: row.paid_through,
    });

    Some(Actor {
        owner_id: row.owner_id,
        session_id,
        name: row.staff_name.unwrap_or(row.owner_name),
        device_name: row.device_name,
        staff,
        subscription,
    })
}
