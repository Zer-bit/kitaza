use chrono::{DateTime, Utc};
use sqlx::FromRow;
use uuid::Uuid;

use crate::features::access::Permissions;
use crate::infrastructure::database::PgPool;
use crate::shared::ApiResult;

#[derive(Debug, Clone, FromRow)]
pub struct StaffRecord {
    pub id: Uuid,
    pub store_id: Uuid,
    pub display_name: String,
    pub can_manage_products: bool,
    pub can_record_expenses: bool,
    pub can_view_profit: bool,
    pub can_delete_records: bool,
    pub created_at: DateTime<Utc>,
}

impl StaffRecord {
    pub fn permissions(&self) -> Permissions {
        Permissions {
            manage_products: self.can_manage_products,
            record_expenses: self.can_record_expenses,
            view_profit: self.can_view_profit,
            delete_records: self.can_delete_records,
        }
    }
}

/// A staff member as the owner's staff list shows them.
#[derive(Debug, FromRow)]
pub struct StaffListing {
    #[sqlx(flatten)]
    pub staff: StaffRecord,
    pub signed_in_devices: i64,
    pub invite_expires_at: Option<DateTime<Utc>>,
}

/// Everything needed to open a session for someone who just used a join code.
#[derive(Debug, FromRow)]
pub struct RedeemedInvite {
    #[sqlx(flatten)]
    pub staff: StaffRecord,
    pub owner_id: Uuid,
}

#[derive(Clone)]
pub struct StaffRepository {
    pool: PgPool,
}

impl StaffRepository {
    pub fn new(pool: PgPool) -> Self {
        Self { pool }
    }

    pub async fn create(
        &self,
        store_id: Uuid,
        display_name: &str,
        permissions: Permissions,
    ) -> ApiResult<StaffRecord> {
        let staff = sqlx::query_as::<_, StaffRecord>(
            "INSERT INTO staff_members
                 (store_id, display_name, can_manage_products, can_record_expenses,
                  can_view_profit, can_delete_records)
             VALUES ($1, $2, $3, $4, $5, $6)
             RETURNING id, store_id, display_name, can_manage_products, can_record_expenses,
                       can_view_profit, can_delete_records, created_at",
        )
        .bind(store_id)
        .bind(display_name)
        .bind(permissions.manage_products)
        .bind(permissions.record_expenses)
        .bind(permissions.view_profit)
        .bind(permissions.delete_records)
        .fetch_one(&self.pool)
        .await?;

        Ok(staff)
    }

    pub async fn list(&self, store_id: Uuid) -> ApiResult<Vec<StaffListing>> {
        let staff = sqlx::query_as::<_, StaffListing>(
            "SELECT st.id, st.store_id, st.display_name, st.can_manage_products,
                    st.can_record_expenses, st.can_view_profit, st.can_delete_records,
                    st.created_at,
                    (SELECT count(*) FROM device_sessions s
                      WHERE s.staff_id = st.id AND s.revoked_at IS NULL) AS signed_in_devices,
                    (SELECT max(i.expires_at) FROM staff_invites i
                      WHERE i.staff_id = st.id AND i.redeemed_at IS NULL
                        AND i.expires_at > now()) AS invite_expires_at
             FROM staff_members st
             WHERE st.store_id = $1 AND st.removed_at IS NULL
             ORDER BY st.created_at",
        )
        .bind(store_id)
        .fetch_all(&self.pool)
        .await?;

        Ok(staff)
    }

    pub async fn find(&self, store_id: Uuid, staff_id: Uuid) -> ApiResult<Option<StaffRecord>> {
        let staff = sqlx::query_as::<_, StaffRecord>(
            "SELECT id, store_id, display_name, can_manage_products, can_record_expenses,
                    can_view_profit, can_delete_records, created_at
             FROM staff_members
             WHERE store_id = $1 AND id = $2 AND removed_at IS NULL",
        )
        .bind(store_id)
        .bind(staff_id)
        .fetch_optional(&self.pool)
        .await?;

        Ok(staff)
    }

    pub async fn update(
        &self,
        store_id: Uuid,
        staff_id: Uuid,
        display_name: &str,
        permissions: Permissions,
    ) -> ApiResult<Option<StaffRecord>> {
        let staff = sqlx::query_as::<_, StaffRecord>(
            "UPDATE staff_members SET
                 display_name = $3, can_manage_products = $4, can_record_expenses = $5,
                 can_view_profit = $6, can_delete_records = $7, updated_at = now()
             WHERE store_id = $1 AND id = $2 AND removed_at IS NULL
             RETURNING id, store_id, display_name, can_manage_products, can_record_expenses,
                       can_view_profit, can_delete_records, created_at",
        )
        .bind(store_id)
        .bind(staff_id)
        .bind(display_name)
        .bind(permissions.manage_products)
        .bind(permissions.record_expenses)
        .bind(permissions.view_profit)
        .bind(permissions.delete_records)
        .fetch_optional(&self.pool)
        .await?;

        Ok(staff)
    }

    /// Removes a staff member and signs out every device they use, in one
    /// transaction: a removed cashier must not keep a working phone.
    pub async fn remove(&self, store_id: Uuid, staff_id: Uuid) -> ApiResult<Option<StaffRecord>> {
        let mut transaction = self.pool.begin().await?;

        let removed = sqlx::query_as::<_, StaffRecord>(
            "UPDATE staff_members SET removed_at = now(), updated_at = now()
             WHERE store_id = $1 AND id = $2 AND removed_at IS NULL
             RETURNING id, store_id, display_name, can_manage_products, can_record_expenses,
                       can_view_profit, can_delete_records, created_at",
        )
        .bind(store_id)
        .bind(staff_id)
        .fetch_optional(&mut *transaction)
        .await?;

        if removed.is_some() {
            sqlx::query(
                "UPDATE device_sessions SET revoked_at = now()
                 WHERE staff_id = $1 AND revoked_at IS NULL",
            )
            .bind(staff_id)
            .execute(&mut *transaction)
            .await?;

            sqlx::query(
                "UPDATE refresh_tokens SET revoked_at = now()
                 WHERE revoked_at IS NULL
                   AND session_id IN (SELECT id FROM device_sessions WHERE staff_id = $1)",
            )
            .bind(staff_id)
            .execute(&mut *transaction)
            .await?;

            sqlx::query("DELETE FROM staff_invites WHERE staff_id = $1 AND redeemed_at IS NULL")
                .bind(staff_id)
                .execute(&mut *transaction)
                .await?;
        }

        transaction.commit().await?;
        Ok(removed)
    }

    /// Issuing a code cancels any earlier one that was never used, so only
    /// the code the owner most recently shared works.
    pub async fn replace_invite(
        &self,
        staff_id: Uuid,
        code_hash: &str,
        expires_at: DateTime<Utc>,
    ) -> ApiResult<()> {
        let mut transaction = self.pool.begin().await?;

        sqlx::query("DELETE FROM staff_invites WHERE staff_id = $1 AND redeemed_at IS NULL")
            .bind(staff_id)
            .execute(&mut *transaction)
            .await?;

        sqlx::query(
            "INSERT INTO staff_invites (staff_id, code_hash, expires_at) VALUES ($1, $2, $3)",
        )
        .bind(staff_id)
        .bind(code_hash)
        .bind(expires_at)
        .execute(&mut *transaction)
        .await?;

        transaction.commit().await?;
        Ok(())
    }

    /// The owner of the store a live code joins, without using the code up.
    pub async fn owner_of_code(&self, code_hash: &str) -> ApiResult<Option<Uuid>> {
        let owner: Option<(Uuid,)> = sqlx::query_as(
            "SELECT s.owner_id FROM staff_invites i
             JOIN staff_members st ON st.id = i.staff_id
             JOIN stores s ON s.id = st.store_id
             WHERE i.code_hash = $1 AND i.redeemed_at IS NULL AND i.expires_at > now()",
        )
        .bind(code_hash)
        .fetch_optional(&self.pool)
        .await?;

        Ok(owner.map(|(id,)| id))
    }

    /// Uses up a join code. Single use: the row is locked and marked in the
    /// same transaction, so two phones typing the same code cannot both join.
    pub async fn redeem(&self, code_hash: &str) -> ApiResult<Option<RedeemedInvite>> {
        let mut transaction = self.pool.begin().await?;

        let invite: Option<(Uuid, Uuid)> = sqlx::query_as(
            "SELECT i.id, i.staff_id FROM staff_invites i
             JOIN staff_members st ON st.id = i.staff_id
             WHERE i.code_hash = $1 AND i.redeemed_at IS NULL
               AND i.expires_at > now() AND st.removed_at IS NULL
             FOR UPDATE OF i",
        )
        .bind(code_hash)
        .fetch_optional(&mut *transaction)
        .await?;

        let Some((invite_id, staff_id)) = invite else {
            return Ok(None);
        };

        sqlx::query("UPDATE staff_invites SET redeemed_at = now() WHERE id = $1")
            .bind(invite_id)
            .execute(&mut *transaction)
            .await?;

        let redeemed = sqlx::query_as::<_, RedeemedInvite>(
            "SELECT st.id, st.store_id, st.display_name, st.can_manage_products,
                    st.can_record_expenses, st.can_view_profit, st.can_delete_records,
                    st.created_at, s.owner_id
             FROM staff_members st JOIN stores s ON s.id = st.store_id
             WHERE st.id = $1",
        )
        .bind(staff_id)
        .fetch_one(&mut *transaction)
        .await?;

        transaction.commit().await?;
        Ok(Some(redeemed))
    }

    pub async fn find_any(&self, staff_id: Uuid) -> ApiResult<Option<StaffRecord>> {
        let staff = sqlx::query_as::<_, StaffRecord>(
            "SELECT id, store_id, display_name, can_manage_products, can_record_expenses,
                    can_view_profit, can_delete_records, created_at
             FROM staff_members WHERE id = $1 AND removed_at IS NULL",
        )
        .bind(staff_id)
        .fetch_optional(&self.pool)
        .await?;

        Ok(staff)
    }
}
