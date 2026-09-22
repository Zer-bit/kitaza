mod application;
mod config;
mod features;
mod infrastructure;
mod shared;

use config::AppSettings;
use infrastructure::observability::install_tracing;

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    dotenvy::dotenv().ok();
    install_tracing();

    let settings = AppSettings::from_environment()?;
    application::run(settings).await
}
