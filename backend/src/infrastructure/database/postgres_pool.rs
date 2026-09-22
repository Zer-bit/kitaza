use sqlx::postgres::PgPoolOptions;

use crate::config::DatabaseSettings;

pub type PgPool = sqlx::PgPool;

pub async fn build_pool(settings: &DatabaseSettings) -> anyhow::Result<PgPool> {
    let pool = PgPoolOptions::new()
        .max_connections(settings.max_connections)
        .min_connections(settings.min_connections)
        .acquire_timeout(settings.acquire_timeout)
        .connect(&settings.url)
        .await?;

    tracing::info!(
        max_connections = settings.max_connections,
        "postgres pool ready"
    );
    Ok(pool)
}
