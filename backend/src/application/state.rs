use crate::config::AppSettings;
use crate::features::authentication::{AuthService, TokenIssuer};
use crate::features::dashboard::{DashboardRepository, DashboardService};
use crate::features::expenses::{ExpenseRepository, ExpenseService};
use crate::features::inventory::{InventoryService, StockRepository};
use crate::features::products::{ProductRepository, ProductService};
use crate::features::reports::{ReportRepository, ReportService};
use crate::features::sales::{SaleRepository, SaleService};
use crate::features::stores::StoreDirectory;
use crate::features::sync::{SyncRepository, SyncService};
use crate::features::withdrawals::{WithdrawalRepository, WithdrawalService};
use crate::infrastructure::cache::{CacheHandle, DashboardCache, RateLimiter};
use crate::infrastructure::database::PgPool;
use crate::infrastructure::realtime::EventBroadcaster;

/// The dependency graph, wired once at boot. Everything inside is cheap to
/// clone: pools and channels behind `Arc`, never per-request allocation.
#[derive(Clone)]
pub struct AppState {
    pub pool: PgPool,
    pub cache_enabled: bool,
    pub token_issuer: TokenIssuer,
    pub broadcaster: EventBroadcaster,
    pub store_directory: StoreDirectory,
    pub auth_service: AuthService,
    pub product_service: ProductService,
    pub inventory_service: InventoryService,
    pub sale_service: SaleService,
    pub expense_service: ExpenseService,
    pub withdrawal_service: WithdrawalService,
    pub dashboard_service: DashboardService,
    pub report_service: ReportService,
    pub sync_service: SyncService,
}

impl AppState {
    pub fn assemble(settings: &AppSettings, pool: PgPool, cache: CacheHandle) -> Self {
        let dashboard_cache =
            DashboardCache::new(cache.clone(), settings.redis.dashboard_cache_ttl_seconds);
        let rate_limiter = RateLimiter::new(
            cache.clone(),
            settings.redis.login_attempt_limit,
            settings.redis.login_attempt_window_seconds,
        );
        let broadcaster = EventBroadcaster::new(cache.clone());
        let token_issuer = TokenIssuer::new(&settings.security);

        let product_repository = ProductRepository::new(pool.clone());
        let sale_repository = SaleRepository::new(pool.clone());
        let expense_repository = ExpenseRepository::new(pool.clone());
        let withdrawal_repository = WithdrawalRepository::new(pool.clone());
        let dashboard_repository = DashboardRepository::new(pool.clone());
        let report_repository = ReportRepository::new(pool.clone());

        let product_service = ProductService::new(product_repository.clone(), broadcaster.clone());
        let inventory_service = InventoryService::new(
            StockRepository::new(pool.clone()),
            product_repository.clone(),
            dashboard_cache.clone(),
            broadcaster.clone(),
        );
        let sale_service = SaleService::new(
            sale_repository,
            product_repository,
            dashboard_cache.clone(),
            broadcaster.clone(),
        );
        let expense_service = ExpenseService::new(
            expense_repository,
            dashboard_cache.clone(),
            broadcaster.clone(),
        );
        let withdrawal_service = WithdrawalService::new(
            withdrawal_repository,
            dashboard_cache.clone(),
            broadcaster.clone(),
        );
        let sync_service = SyncService::new(
            SyncRepository::new(pool.clone()),
            product_service.clone(),
            sale_service.clone(),
            expense_service.clone(),
            withdrawal_service.clone(),
        );

        Self {
            cache_enabled: cache.is_enabled(),
            auth_service: AuthService::new(
                crate::features::authentication::AuthRepository::new(pool.clone()),
                token_issuer.clone(),
                rate_limiter,
                settings.security.refresh_token_lifetime,
            ),
            store_directory: StoreDirectory::new(pool.clone()),
            dashboard_service: DashboardService::new(dashboard_repository.clone(), dashboard_cache),
            report_service: ReportService::new(report_repository, dashboard_repository),
            product_service,
            inventory_service,
            sale_service,
            expense_service,
            withdrawal_service,
            sync_service,
            token_issuer,
            broadcaster,
            pool,
        }
    }
}
