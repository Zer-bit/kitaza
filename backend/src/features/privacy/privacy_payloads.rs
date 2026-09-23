use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use serde_json::Value;
use validator::Validate;

/// A document an owner agrees to. Both are versioned: agreeing to one version
/// says nothing about a later one, which is why the version is stored rather
/// than a bare "yes".
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum LegalDocument {
    PrivacyNotice,
    Terms,
}

impl LegalDocument {
    pub const ALL: [LegalDocument; 2] = [LegalDocument::PrivacyNotice, LegalDocument::Terms];

    pub fn column_value(self) -> &'static str {
        match self {
            LegalDocument::PrivacyNotice => "privacy_notice",
            LegalDocument::Terms => "terms",
        }
    }

    /// The version an account must have agreed to. Raising one of these asks
    /// every owner to read the change and agree again.
    pub fn current_version(self) -> &'static str {
        match self {
            LegalDocument::PrivacyNotice => "2026-09-01",
            LegalDocument::Terms => "2026-09-01",
        }
    }
}

/// One agreement on record.
#[derive(Debug, Clone, Serialize)]
pub struct ConsentGiven {
    pub document: LegalDocument,
    pub version: String,
    pub agreed_at: DateTime<Utc>,
}

/// A document this account has not agreed to at its current version.
#[derive(Debug, Clone, Serialize)]
pub struct RequiredConsent {
    pub document: LegalDocument,
    pub version: String,
}

#[derive(Debug, Deserialize, Validate)]
pub struct RecordConsentRequest {
    pub document: LegalDocument,

    #[validate(length(min = 1, max = 40, message = "is required"))]
    pub version: String,
}

/// What the account screen needs: what was agreed, what still needs agreeing,
/// and whether a deletion is running.
#[derive(Debug, Serialize)]
pub struct PrivacyState {
    pub agreed: Vec<ConsentGiven>,
    pub outstanding: Vec<RequiredConsent>,
    pub deletion: Option<DeletionState>,
}

#[derive(Debug, Clone, Serialize)]
pub struct DeletionState {
    pub requested_at: DateTime<Utc>,

    /// After this moment nothing can be recovered.
    pub deletes_at: DateTime<Utc>,
}

/// Everything the server holds about one account, in one file.
///
/// The right to data portability asks for a copy in a form the person can
/// actually use, so this is plain JSON rather than a database dump.
#[derive(Debug, Serialize)]
pub struct AccountExport {
    pub exported_at: DateTime<Utc>,
    pub format: &'static str,
    pub account: Value,
    pub stores: Vec<Value>,
    pub staff: Vec<Value>,
    pub devices: Vec<Value>,
    pub products: Vec<Value>,
    pub sales: Vec<Value>,
    pub expenses: Vec<Value>,
    pub withdrawals: Vec<Value>,
    pub stock_movements: Vec<Value>,
    pub activity: Vec<Value>,
    pub consents: Vec<Value>,
    pub payments: Vec<Value>,
    pub error_reports: Vec<Value>,
}
