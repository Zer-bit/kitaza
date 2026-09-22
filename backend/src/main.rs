use kitaza_server::application;
use kitaza_server::config::AppSettings;
use kitaza_server::infrastructure::observability::install_tracing;

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    dotenvy::dotenv().ok();
    install_tracing();

    let settings = AppSettings::from_environment()?;
    application::run(settings).await
}
