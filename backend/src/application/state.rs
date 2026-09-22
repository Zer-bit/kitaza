use crate::config::AppSettings;
use crate::features::access::SessionDirectory;
use crate::features::audit::AuditTrail;
use crate::features::authentication::{AuthDependencies, AuthRepository, AuthService, TokenIssuer};
use crate::features::dashboard::{DashboardRepository, DashboardService};
use crate::features::devices::DeviceRepository;
use crate::features::diagnostics::{DiagnosticsRepository, DiagnosticsService};
use crate::features::expenses::{ExpenseRepository, ExpenseService};
use crate::features::inventory::{InventoryService, StockRepository};
use crate::features::products::{ProductRepository, ProductService};
use crate::features::reports::{ReportRepository, ReportService};
use crate::features::sales::{SaleRepository, SaleService};
use crate::features::staff::{StaffRepository, StaffService};
use crate::features::stores::StoreDirectory;
use crate::features::sync::{SyncDependencies, SyncRepository, SyncService};
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
    pub session_directory: SessionDirectory,
    pub audit_trail: AuditTrail,
    pub auth_service: AuthService,
    pub staff_service: StaffService,
    pub device_repository: DeviceRepository,
    pub product_service: ProductService,
    pub inventory_service: InventoryService,
    pub sale_service: SaleService,
    pub expense_service: ExpenseService,
    pub withdrawal_service: WithdrawalService,
    pub dashboard_service: DashboardService,
    pub report_service: ReportService,
    pub sync_service: SyncService,
    pub diagnostics_service: DiagnosticsService,
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
        let session_directory = SessionDirectory::new(pool.clone());
        let audit_trail = AuditTrail::new(pool.clone());
        let staff_repository = StaffRepository::new(pool.clone());

        let product_repository = ProductRepository::new(pool.clone());
        let sale_repository = SaleRepository::new(pool.clone());
        let expense_repository = ExpenseRepository::new(pool.clone());
        let withdrawal_repository = WithdrawalRepository::new(pool.clone());
        let dashboard_repository = DashboardRepository::new(pool.clone());
        let report_repository = ReportRepository::new(pool.clone());

        let product_service = ProductService::new(
            product_repository.clone(),
            broadcaster.clone(),
            audit_trail.clone(),
        );
        let inventory_service = InventoryService::new(
            StockRepository::new(pool.clone()),
            dashboard_cache.clone(),
            broadcaster.clone(),
            audit_trail.clone(),
        );
        let sale_service = SaleService::new(
            sale_repository,
            product_repository,
            dashboard_cache.clone(),
            broadcaster.clone(),
            audit_trail.clone(),
        );
        let expense_service = ExpenseService::new(
            expense_repository,
            dashboard_cache.clone(),
            broadcaster.clone(),
            audit_trail.clone(),
        );
        let withdrawal_service = WithdrawalService::new(
            withdrawal_repository,
            dashboard_cache.clone(),
            broadcaster.clone(),
            audit_trail.clone(),
        );
        let staff_service = StaffService::new(
            staff_repository.clone(),
            session_directory.clone(),
            audit_trail.clone(),
            broadcaster.clone(),
        );
        let sync_service = SyncService::new(
            SyncRepository::new(pool.clone(), settings.sync.settle_window),
            settings.sync.page_size,
            SyncDependencies {
                products: product_service.clone(),
                inventory: inventory_service.clone(),
                sales: sale_service.clone(),
                expenses: expense_service.clone(),
                withdrawals: withdrawal_service.clone(),
            },
        );

        // Separate from login throttling: a phone in a crash loop must not
        // be able to lock its owner out of signing in.
        let diagnostics_service = DiagnosticsService::new(
            DiagnosticsRepository::new(pool.clone()),
            RateLimiter::new(cache.clone(), 30, 3600),
        );

        Self {
            cache_enabled: cache.is_enabled(),
            diagnostics_service,
            auth_service: AuthService::new(AuthDependencies {
                repository: AuthRepository::new(pool.clone()),
                staff: staff_repository,
                token_issuer: token_issuer.clone(),
                rate_limiter,
                sessions: session_directory.clone(),
                audit: audit_trail.clone(),
                refresh_lifetime: settings.security.refresh_token_lifetime,
            }),
            staff_service,
            device_repository: DeviceRepository::new(pool.clone()),
            session_directory,
            audit_trail,
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
