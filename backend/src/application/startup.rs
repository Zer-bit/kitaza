use tokio::net::TcpListener;
use tokio::signal;

use crate::config::AppSettings;
use crate::features::privacy::spawn_retention_sweeper;
use crate::infrastructure::cache::connect_cache;
use crate::infrastructure::database::{build_pool, run_pending_migrations};
use crate::infrastructure::realtime::spawn_cross_instance_bridge;

use super::{AppState, build_router};

pub async fn run(settings: AppSettings) -> anyhow::Result<()> {
    let pool = build_pool(&settings.database).await?;

    if settings.database.run_migrations_on_boot {
        run_pending_migrations(&pool).await?;
    }

    let cache = connect_cache(&settings.redis).await;
    let state = AppState::assemble(&settings, pool.clone(), cache.clone());

    // Carries out deletions whose grace period has run out, and drops records
    // that are past the age they are kept for.
    spawn_retention_sweeper(pool, settings.privacy.retention);

    if cache.is_enabled() {
        spawn_cross_instance_bridge(state.broadcaster.clone(), settings.redis.url.clone());
    }

    let listener = TcpListener::bind(settings.server.bind_address).await?;
    tracing::info!(address = %settings.server.bind_address, "kitaza api listening");

    axum::serve(listener, build_router(state, &settings.server))
        .with_graceful_shutdown(shutdown_signal())
        .await?;

    Ok(())
}

/// Lets in-flight sales finish writing before the process exits.
async fn shutdown_signal() {
    let interrupt = async {
        signal::ctrl_c().await.expect("failed to listen for ctrl-c");
    };

    #[cfg(unix)]
    let terminate = async {
        signal::unix::signal(signal::unix::SignalKind::terminate())
            .expect("failed to listen for SIGTERM")
            .recv()
            .await;
    };

    #[cfg(not(unix))]
    let terminate = std::future::pending::<()>();

    tokio::select! {
        _ = interrupt => {}
        _ = terminate => {}
    }

    tracing::info!("shutdown signal received, draining connections");
}
