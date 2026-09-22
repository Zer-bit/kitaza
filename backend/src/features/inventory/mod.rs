mod inventory_handlers;
mod inventory_payloads;
mod inventory_routes;
mod inventory_service;
mod stock_repository;

pub use inventory_routes::inventory_routes;
pub use inventory_service::InventoryService;
pub use stock_repository::StockRepository;
