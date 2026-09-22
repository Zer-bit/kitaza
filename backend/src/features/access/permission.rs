use serde::{Deserialize, Serialize};

/// Something an owner can let a staff member do. Recording a sale is not on
/// the list: every staff member can sell, since that is why they exist.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum Permission {
    /// Add and edit products and prices, record deliveries and stock counts.
    ManageProducts,
    RecordExpenses,
    /// Cost prices, profit, expenses, withdrawals and the business health
    /// score. Without it a device never receives cost figures at all.
    ViewProfit,
    /// Void sales and delete expenses or products: rewriting history.
    DeleteRecords,
}

impl Permission {
    pub const ALL: [Permission; 4] = [
        Permission::ManageProducts,
        Permission::RecordExpenses,
        Permission::ViewProfit,
        Permission::DeleteRecords,
    ];

    /// What a staff member is told when a device tries this without it.
    pub fn refusal(self) -> &'static str {
        match self {
            Permission::ManageProducts => "only the owner can change products and stock",
            Permission::RecordExpenses => "only the owner can record expenses",
            Permission::ViewProfit => "only the owner can see profit and costs",
            Permission::DeleteRecords => "only the owner can void or delete records",
        }
    }
}

#[derive(Debug, Clone, Copy, Default, PartialEq, Eq)]
pub struct Permissions {
    pub manage_products: bool,
    pub record_expenses: bool,
    pub view_profit: bool,
    pub delete_records: bool,
}

impl Permissions {
    pub const ALL: Permissions = Permissions {
        manage_products: true,
        record_expenses: true,
        view_profit: true,
        delete_records: true,
    };

    pub fn allows(self, permission: Permission) -> bool {
        match permission {
            Permission::ManageProducts => self.manage_products,
            Permission::RecordExpenses => self.record_expenses,
            Permission::ViewProfit => self.view_profit,
            Permission::DeleteRecords => self.delete_records,
        }
    }

    pub fn from_list(list: &[Permission]) -> Self {
        Self {
            manage_products: list.contains(&Permission::ManageProducts),
            record_expenses: list.contains(&Permission::RecordExpenses),
            view_profit: list.contains(&Permission::ViewProfit),
            delete_records: list.contains(&Permission::DeleteRecords),
        }
    }

    pub fn to_list(self) -> Vec<Permission> {
        Permission::ALL
            .into_iter()
            .filter(|permission| self.allows(*permission))
            .collect()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn a_list_round_trips_through_the_flags() {
        let granted = [Permission::ViewProfit, Permission::ManageProducts];
        let permissions = Permissions::from_list(&granted);

        assert!(permissions.allows(Permission::ManageProducts));
        assert!(permissions.allows(Permission::ViewProfit));
        assert!(!permissions.allows(Permission::RecordExpenses));
        assert!(!permissions.allows(Permission::DeleteRecords));
        assert_eq!(
            permissions.to_list(),
            vec![Permission::ManageProducts, Permission::ViewProfit]
        );
    }

    #[test]
    fn new_staff_can_do_nothing_beyond_selling() {
        let fresh = Permissions::default();
        assert!(Permission::ALL.iter().all(|p| !fresh.allows(*p)));
    }
}
