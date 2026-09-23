use chrono::{Duration, Utc};
use uuid::Uuid;

use crate::shared::{ApiError, ApiResult};

use super::consent_repository::ConsentRepository;
use super::privacy_payloads::{
    AccountExport, DeletionState, LegalDocument, PrivacyState, RequiredConsent,
};

#[derive(Clone)]
pub struct PrivacyService {
    repository: ConsentRepository,
    deletion_grace: Duration,
}

impl PrivacyService {
    pub fn new(repository: ConsentRepository, deletion_grace: Duration) -> Self {
        Self {
            repository,
            deletion_grace,
        }
    }

    /// Checks what a new account says it agreed to. Registration is refused
    /// rather than recorded with a shrug: an account created without consent
    /// is one whose data there is no lawful basis to hold.
    pub fn check_registration_consent(
        &self,
        privacy_version: Option<&str>,
        terms_version: Option<&str>,
    ) -> ApiResult<()> {
        for (document, given) in [
            (LegalDocument::PrivacyNotice, privacy_version),
            (LegalDocument::Terms, terms_version),
        ] {
            let expected = document.current_version();
            match given {
                Some(version) if version == expected => {}
                _ => {
                    return Err(ApiError::BadRequest(format!(
                        "{} version {expected} must be agreed to",
                        document.column_value()
                    )));
                }
            }
        }
        Ok(())
    }

    pub async fn record_registration_consent(&self, owner_id: Uuid) -> ApiResult<()> {
        for document in LegalDocument::ALL {
            self.repository
                .record(owner_id, document, document.current_version())
                .await?;
        }
        Ok(())
    }

    pub async fn record(
        &self,
        owner_id: Uuid,
        document: LegalDocument,
        version: &str,
    ) -> ApiResult<()> {
        if version != document.current_version() {
            return Err(ApiError::BadRequest(
                "that is not the version in force".into(),
            ));
        }
        self.repository.record(owner_id, document, version).await
    }

    pub async fn state(&self, owner_id: Uuid) -> ApiResult<PrivacyState> {
        let agreed = self.repository.given_by(owner_id).await?;
        let outstanding = LegalDocument::ALL
            .into_iter()
            .filter(|document| {
                !agreed.iter().any(|given| {
                    given.document == *document && given.version == document.current_version()
                })
            })
            .map(|document| RequiredConsent {
                document,
                version: document.current_version().to_owned(),
            })
            .collect();

        Ok(PrivacyState {
            agreed,
            outstanding,
            deletion: self.repository.deletion_state(owner_id).await?,
        })
    }

    pub async fn request_deletion(&self, owner_id: Uuid) -> ApiResult<DeletionState> {
        self.repository
            .request_deletion(owner_id, self.deletion_grace)
            .await
    }

    pub async fn cancel_deletion(&self, owner_id: Uuid) -> ApiResult<()> {
        self.repository.cancel_deletion(owner_id).await
    }

    pub async fn export(&self, owner_id: Uuid) -> ApiResult<AccountExport> {
        let tables = self.repository.export(owner_id).await?;
        Ok(AccountExport {
            exported_at: Utc::now(),
            format: "kitaza.account-export.v1",
            account: tables.account,
            stores: tables.stores,
            staff: tables.staff,
            devices: tables.devices,
            products: tables.products,
            sales: tables.sales,
            expenses: tables.expenses,
            withdrawals: tables.withdrawals,
            stock_movements: tables.stock_movements,
            activity: tables.activity,
            consents: tables.consents,
            payments: tables.payments,
            error_reports: tables.error_reports,
        })
    }
}
