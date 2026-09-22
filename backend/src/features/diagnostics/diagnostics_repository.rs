use uuid::Uuid;

use crate::infrastructure::database::PgPool;
use crate::shared::ApiResult;

use super::diagnostics_payloads::ErrorReportPayload;

/// How long reports are kept. Long enough to see a bug across a couple of
/// releases, short enough that the table never becomes an archive.
const RETENTION_DAYS: i32 = 90;

#[derive(Clone)]
pub struct DiagnosticsRepository {
    pool: PgPool,
}

impl DiagnosticsRepository {
    pub fn new(pool: PgPool) -> Self {
        Self { pool }
    }

    /// A report the phone sends again - it may retry after a dropped
    /// connection - adds to the existing row rather than duplicating it.
    pub async fn record(&self, owner_id: Uuid, reports: &[ErrorReportPayload]) -> ApiResult<()> {
        let mut transaction = self.pool.begin().await?;

        for report in reports {
            sqlx::query(
                "INSERT INTO client_error_reports
                     (owner_id, fingerprint, error_type, message, stack, occurrences,
                      first_seen, last_seen, app_version, platform)
                 VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
                 ON CONFLICT (owner_id, fingerprint, app_version) DO UPDATE SET
                     occurrences = client_error_reports.occurrences + EXCLUDED.occurrences,
                     first_seen  = LEAST(client_error_reports.first_seen, EXCLUDED.first_seen),
                     last_seen   = GREATEST(client_error_reports.last_seen, EXCLUDED.last_seen),
                     message     = EXCLUDED.message,
                     stack       = COALESCE(EXCLUDED.stack, client_error_reports.stack),
                     received_at = now()",
            )
            .bind(owner_id)
            .bind(&report.fingerprint)
            .bind(&report.error_type)
            .bind(&report.message)
            .bind(report.stack.as_deref())
            .bind(report.occurrences)
            .bind(report.first_seen)
            .bind(report.last_seen)
            .bind(&report.app_version)
            .bind(&report.platform)
            .execute(&mut *transaction)
            .await?;
        }

        sqlx::query(
            "DELETE FROM client_error_reports
             WHERE last_seen < now() - make_interval(days => $1)",
        )
        .bind(RETENTION_DAYS)
        .execute(&mut *transaction)
        .await?;

        transaction.commit().await?;
        Ok(())
    }
}
