use tracing_subscriber::EnvFilter;
use tracing_subscriber::layer::SubscriberExt;
use tracing_subscriber::util::SubscriberInitExt;

pub fn install_tracing() {
    let filter = EnvFilter::try_from_env("KITAZA_LOG")
        .unwrap_or_else(|_| EnvFilter::new("info,kitaza_server=debug,tower_http=info"));

    let json_output = std::env::var("KITAZA_LOG_FORMAT")
        .map(|format| format.eq_ignore_ascii_case("json"))
        .unwrap_or(false);

    let registry = tracing_subscriber::registry().with(filter);

    if json_output {
        registry
            .with(tracing_subscriber::fmt::layer().json())
            .init();
    } else {
        registry
            .with(tracing_subscriber::fmt::layer().compact())
            .init();
    }
}
