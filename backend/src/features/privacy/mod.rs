mod consent_repository;
mod privacy_handlers;
mod privacy_payloads;
mod privacy_routes;
mod privacy_service;
mod retention;

pub use consent_repository::ConsentRepository;
pub use privacy_payloads::{LegalDocument, RequiredConsent};
pub use privacy_routes::privacy_routes;
pub use privacy_service::PrivacyService;
pub use retention::{RetentionPolicy, spawn_retention_sweeper, sweep};
