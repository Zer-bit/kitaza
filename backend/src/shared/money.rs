use rust_decimal::Decimal;
use rust_decimal::prelude::FromPrimitive;

/// Peso amounts. Stored as `NUMERIC(14,2)` so no floating point rounding ever
/// reaches a business total.
pub type Money = Decimal;

/// Product quantities. `NUMERIC(14,3)` allows selling by weight or volume.
pub type Quantity = Decimal;

const MONEY_SCALE: u32 = 2;
const QUANTITY_SCALE: u32 = 3;

pub fn money_zero() -> Money {
    Decimal::ZERO
}

/// JSON carries numbers as f64. Converting at the edge keeps every downstream
/// calculation in exact decimal arithmetic.
pub fn money_from_f64(value: f64) -> Money {
    Decimal::from_f64(value)
        .unwrap_or(Decimal::ZERO)
        .round_dp(MONEY_SCALE)
}

pub fn quantity_from_f64(value: f64) -> Quantity {
    Decimal::from_f64(value)
        .unwrap_or(Decimal::ZERO)
        .round_dp(QUANTITY_SCALE)
}
