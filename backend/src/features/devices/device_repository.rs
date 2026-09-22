use chrono::{DateTime, Utc};
use serde::Serialize;
use sqlx::FromRow;
use uuid::Uuid;

use crate::infrastructure::database::PgPool;
use crate::shared::ApiResult;

#[derive(Debug, Serialize, FromRow)]
pub struct DeviceView {
    pub id: Uuid,
    pub device_name: String,
    /// The owner's name, or the staff member's.
    pub member_name: String,
    pub is_staff: bool,
    pub store_id: Option<Uuid>,
    pub signed_in_at: DateTime<Utc>,
    pub last_seen_at: DateTime<Utc>,
    #[sqlx(default)]
    pub is_current: bool,
}

#[derive(Debug, FromRow)]
pub struct RevokedDevice {
    pub device_name: String,
    pub member_name: String,
    pub store_id: Option<Uuid>,
}

#[derive(Clone)]
pub struct DeviceRepository {
    pool: PgPool,
}

impl DeviceRepository {
    pub fn new(pool: PgPool) -> Self {
        Self { pool }
    }

    /// Devices that could still sync right now: not signed out, and holding
    /// a refresh token that has not expired.
    pub async fn list(&self, owner_id: Uuid) -> ApiResult<Vec<DeviceView>> {
        let devices = sqlx::query_as::<_, DeviceView>(
            "SELECT s.id, s.device_name,
                    COALESCE(st.display_name, o.full_name) AS member_name,
                    s.staff_id IS NOT NULL AS is_staff,
                    st.store_id,
                    s.created_at AS signed_in_at, s.last_seen_at
             FROM device_sessions s
             JOIN owners o ON o.id = s.owner_id
             LEFT JOIN staff_members st ON st.id = s.staff_id
             WHERE s.owner_id = $1 AND s.revoked_at IS NULL
               AND (st.id IS NULL OR st.removed_at IS NULL)
               AND EXISTS (SELECT 1 FROM refresh_tokens t
                           WHERE t.session_id = s.id AND t.revoked_at IS NULL
                             AND t.expires_at > now())
             ORDER BY s.last_seen_at DESC",
        )
        .bind(owner_id)
        .fetch_all(&self.pool)
        .await?;

        Ok(devices)
    }

    pub async fn revoke(
        &self,
        owner_id: Uuid,
        session_id: Uuid,
    ) -> ApiResult<Option<RevokedDevice>> {
        let mut transaction = self.pool.begin().await?;

        let revoked = sqlx::query_as::<_, RevokedDevice>(
            "UPDATE device_sessions s SET revoked_at = now()
             FROM owners o
             WHERE s.id = $1 AND s.owner_id = $2 AND s.revoked_at IS NULL AND o.id = s.owner_id
             RETURNING s.device_name,
                       COALESCE((SELECT display_name FROM staff_members WHERE id = s.staff_id),
                                o.full_name) AS member_name,
                       (SELECT store_id FROM staff_members WHERE id = s.staff_id) AS store_id",
        )
        .bind(session_id)
        .bind(owner_id)
        .fetch_optional(&mut *transaction)
        .await?;

        if revoked.is_some() {
            sqlx::query(
                "UPDATE refresh_tokens SET revoked_at = now()
                 WHERE session_id = $1 AND revoked_at IS NULL",
            )
            .bind(session_id)
            .execute(&mut *transaction)
            .await?;
        }

        transaction.commit().await?;
        Ok(revoked)
    }
}
