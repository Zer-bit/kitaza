//! Kitaza API. Built as a library so the integration tests in `tests/` can
//! drive the real router against a real database.

pub mod application;
pub mod config;
pub mod features;
pub mod infrastructure;
pub mod shared;
