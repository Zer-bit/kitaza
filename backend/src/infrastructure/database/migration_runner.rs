use super::PgPool;

pub async fn run_pending_migrations(pool: &PgPool) -> anyhow::Result<()> {
    sqlx::migrate!("./migrations").run(pool).await?;
    tracing::info!("database migrations are up to date");
    Ok(())
}
