use serde::{Deserialize, Serialize};

use crate::shared::ApiError;

/// A closed list keeps reporting meaningful. "Other" exists so nobody is ever
/// blocked from recording a real expense.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum ExpenseCategory {
    Inventory,
    Utilities,
    Salary,
    Transportation,
    Rent,
    Supplies,
    Repairs,
    TaxesPermits,
    Other,
}

impl ExpenseCategory {
    pub fn as_str(self) -> &'static str {
        match self {
            Self::Inventory => "inventory",
            Self::Utilities => "utilities",
            Self::Salary => "salary",
            Self::Transportation => "transportation",
            Self::Rent => "rent",
            Self::Supplies => "supplies",
            Self::Repairs => "repairs",
            Self::TaxesPermits => "taxes_permits",
            Self::Other => "other",
        }
    }

    pub fn parse(raw: &str) -> Result<Self, ApiError> {
        match raw.trim().to_lowercase().as_str() {
            "inventory" => Ok(Self::Inventory),
            "utilities" => Ok(Self::Utilities),
            "salary" => Ok(Self::Salary),
            "transportation" => Ok(Self::Transportation),
            "rent" => Ok(Self::Rent),
            "supplies" => Ok(Self::Supplies),
            "repairs" => Ok(Self::Repairs),
            "taxes_permits" => Ok(Self::TaxesPermits),
            "other" => Ok(Self::Other),
            unknown => Err(ApiError::BadRequest(format!(
                "unknown expense category '{unknown}'"
            ))),
        }
    }

    pub fn all() -> &'static [ExpenseCategory] {
        &[
            Self::Inventory,
            Self::Utilities,
            Self::Salary,
            Self::Transportation,
            Self::Rent,
            Self::Supplies,
            Self::Repairs,
            Self::TaxesPermits,
            Self::Other,
        ]
    }
}
