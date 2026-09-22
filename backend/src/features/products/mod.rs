mod product_handlers;
mod product_payloads;
mod product_repository;
mod product_routes;
mod product_service;

pub use product_payloads::SaveProductRequest;
pub use product_repository::{ProductRepository, foreign_id};
pub use product_routes::product_routes;
pub use product_service::ProductService;
