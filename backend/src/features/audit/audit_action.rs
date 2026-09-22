use serde::{Deserialize, Serialize};

/// Everything the activity log records. Stored as its snake_case name; the
/// app turns each into a sentence in the owner's language.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum AuditAction {
    SaleRecorded,
    SaleVoided,
    ExpenseRecorded,
    ExpenseDeleted,
    WithdrawalRecorded,
    WithdrawalDeleted,
    ProductAdded,
    ProductChanged,
    ProductRemoved,
    StockReceived,
    StockRemoved,
    StockCounted,
    StockSpoiled,
    StaffAdded,
    StaffChanged,
    StaffRemoved,
    StaffInvited,
    StaffJoined,
    DeviceSignedOut,
    StoreAdded,
    StoreRenamed,
}

impl AuditAction {
    /// The actions that take something away. An owner checking for a
    /// missing ₱500 looks here first, so the log can be filtered to them.
    pub const REMOVALS: [AuditAction; 4] = [
        AuditAction::SaleVoided,
        AuditAction::ExpenseDeleted,
        AuditAction::WithdrawalDeleted,
        AuditAction::ProductRemoved,
    ];

    pub fn as_str(self) -> &'static str {
        match self {
            AuditAction::SaleRecorded => "sale_recorded",
            AuditAction::SaleVoided => "sale_voided",
            AuditAction::ExpenseRecorded => "expense_recorded",
            AuditAction::ExpenseDeleted => "expense_deleted",
            AuditAction::WithdrawalRecorded => "withdrawal_recorded",
            AuditAction::WithdrawalDeleted => "withdrawal_deleted",
            AuditAction::ProductAdded => "product_added",
            AuditAction::ProductChanged => "product_changed",
            AuditAction::ProductRemoved => "product_removed",
            AuditAction::StockReceived => "stock_received",
            AuditAction::StockRemoved => "stock_removed",
            AuditAction::StockCounted => "stock_counted",
            AuditAction::StockSpoiled => "stock_spoiled",
            AuditAction::StaffAdded => "staff_added",
            AuditAction::StaffChanged => "staff_changed",
            AuditAction::StaffRemoved => "staff_removed",
            AuditAction::StaffInvited => "staff_invited",
            AuditAction::StaffJoined => "staff_joined",
            AuditAction::DeviceSignedOut => "device_signed_out",
            AuditAction::StoreAdded => "store_added",
            AuditAction::StoreRenamed => "store_renamed",
        }
    }

    /// The log entry for a stock movement kind, as the ledger names them.
    pub fn for_movement(movement: &str) -> Option<Self> {
        match movement {
            "stock_in" => Some(AuditAction::StockReceived),
            "stock_out" => Some(AuditAction::StockRemoved),
            "adjustment" => Some(AuditAction::StockCounted),
            "spoilage" => Some(AuditAction::StockSpoiled),
            _ => None,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn the_stored_name_matches_the_wire_name() {
        for action in [
            AuditAction::SaleVoided,
            AuditAction::StockCounted,
            AuditAction::DeviceSignedOut,
        ] {
            let wire = serde_json::to_value(action).unwrap();
            assert_eq!(wire, action.as_str());
        }
    }
}
