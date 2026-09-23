use std::net::SocketAddr;
use std::time::Duration;

use super::{optional, parsed};

#[derive(Debug, Clone)]
pub struct ServerSettings {
    pub bind_address: SocketAddr,
    pub allowed_origins: Vec<String>,
    pub request_timeout_seconds: u64,
    pub max_body_bytes: usize,

    /// How often an open realtime socket is pinged, and its device re-checked.
    /// Shorten it when a proxy in front of the API closes idle connections
    /// sooner than this.
    pub realtime_keepalive: Duration,
}

impl ServerSettings {
    pub fn from_environment() -> anyhow::Result<Self> {
        let host = optional("KITAZA_HOST", "0.0.0.0");
        let port: u16 = parsed("KITAZA_PORT", 8080)?;

        Ok(Self {
            bind_address: format!("{host}:{port}").parse()?,
            allowed_origins: split_origins(&optional("KITAZA_ALLOWED_ORIGINS", "*")),
            request_timeout_seconds: parsed("KITAZA_REQUEST_TIMEOUT_SECONDS", 20)?,
            max_body_bytes: parsed("KITAZA_MAX_BODY_BYTES", 2 * 1024 * 1024)?,
            realtime_keepalive: Duration::from_secs(parsed(
                "KITAZA_REALTIME_KEEPALIVE_SECONDS",
                25,
            )?),
        })
    }

    pub fn allows_any_origin(&self) -> bool {
        self.allowed_origins.iter().any(|origin| origin == "*")
    }
}

fn split_origins(raw: &str) -> Vec<String> {
    raw.split(',')
        .map(str::trim)
        .filter(|origin| !origin.is_empty())
        .map(str::to_owned)
        .collect()
}
