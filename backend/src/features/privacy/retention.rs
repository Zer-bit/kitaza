use std::time::Duration as StdDuration;

use chrono::Duration;
use sqlx::PgPool;

/// How long each kind of record is kept.
///
/// Holding data "just in case" is the thing the Data Privacy Act asks a
/// controller not to do, so every table that grows without an owner deleting
/// anything has a limit here, and a sweep that enforces it.
#[derive(Debug, Clone, Copy)]
pub struct RetentionPolicy {
    /// A crash report is useful while the build it came from is still around.
    pub error_reports: Duration,

    /// Who did what in the store. Long enough to settle a dispute about last
    /// year's takings, not forever.
    pub activity: Duration,

    /// A device that has not been seen in this long is not coming back.
    pub dormant_sessions: Duration,

    /// How often the sweep runs.
    pub sweep_every: StdDuration,
}

impl Default for RetentionPolicy {
    fn default() -> Self {
        Self {
            error_reports: Duration::days(90),
            activity: Duration::days(730),
            dormant_sessions: Duration::days(365),
            sweep_every: StdDuration::from_secs(6 * 60 * 60),
        }
    }
}

#[derive(Debug, Default, PartialEq, Eq)]
pub struct SweepResult {
    pub accounts_deleted: u64,
    pub error_reports_deleted: u64,
    pub activity_deleted: u64,
    pub sessions_deleted: u64,
}

/// Deletes what is past its date. Safe to run at any time, and safe to run
/// twice.
pub async fn sweep(pool: &PgPool, policy: RetentionPolicy) -> sqlx::Result<SweepResult> {
    let accounts_deleted = purge_accounts(pool).await?;

    let error_reports_deleted =
        sqlx::query("DELETE FROM client_error_reports WHERE last_seen < now() - $1")
            .bind(policy.error_reports)
            .execute(pool)
            .await?
            .rows_affected();

    let activity_deleted = sqlx::query("DELETE FROM audit_events WHERE recorded_at < now() - $1")
        .bind(policy.activity)
        .execute(pool)
        .await?
        .rows_affected();

    let sessions_deleted = sqlx::query(
        "DELETE FROM device_sessions
         WHERE revoked_at IS NOT NULL AND last_seen_at < now() - $1",
    )
    .bind(policy.dormant_sessions)
    .execute(pool)
    .await?
    .rows_affected();

    Ok(SweepResult {
        accounts_deleted,
        error_reports_deleted,
        activity_deleted,
        sessions_deleted,
    })
}

/// Carries out the deletions whose grace period has run out.
///
/// The payment amounts are copied out first, stripped of who paid them: a
/// business has to be able to account for money it received, and that copy
/// names nobody. Everything else goes with the owner row, by cascade.
async fn purge_accounts(pool: &PgPool) -> sqlx::Result<u64> {
    let mut transaction = pool.begin().await?;

    sqlx::query(
        "INSERT INTO accounting_records
             (id, plan, months, amount, currency, provider, provider_reference, paid_at)
         SELECT p.id, p.plan, p.months, p.amount, p.currency, p.provider,
                p.provider_reference, p.paid_at
         FROM payments p
         JOIN owners o ON o.id = p.owner_id
         WHERE o.delete_after IS NOT NULL AND o.delete_after <= now()
           AND p.status = 'paid'
         ON CONFLICT (id) DO NOTHING",
    )
    .execute(&mut *transaction)
    .await?;

    let deleted =
        sqlx::query("DELETE FROM owners WHERE delete_after IS NOT NULL AND delete_after <= now()")
            .execute(&mut *transaction)
            .await?
            .rows_affected();

    transaction.commit().await?;
    Ok(deleted)
}

/// Runs the sweep on a timer for as long as the server is up.
pub fn spawn_retention_sweeper(pool: PgPool, policy: RetentionPolicy) {
    tokio::spawn(async move {
        let mut ticker = tokio::time::interval(policy.sweep_every);
        loop {
            ticker.tick().await;
            match sweep(&pool, policy).await {
                Ok(result) if result != SweepResult::default() => {
                    tracing::info!(?result, "retention sweep removed expired records");
                }
                Ok(_) => tracing::debug!("retention sweep found nothing to remove"),
                Err(error) => tracing::warn!(%error, "retention sweep failed"),
            }
        }
    });
}
