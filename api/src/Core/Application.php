<?php

declare(strict_types=1);

namespace LaundryPro\Api\Core;

use LaundryPro\Api\Controllers\AccountingController;
use LaundryPro\Api\Controllers\AnalyticsController;
use LaundryPro\Api\Controllers\AuthController;
use LaundryPro\Api\Controllers\BackupController;
use LaundryPro\Api\Controllers\BranchController;
use LaundryPro\Api\Controllers\BusinessController;
use LaundryPro\Api\Controllers\CatalogController;
use LaundryPro\Api\Controllers\ChallanController;
use LaundryPro\Api\Controllers\ChannelController;
use LaundryPro\Api\Controllers\CustomerController;
use LaundryPro\Api\Controllers\CustomerPortalController;
use LaundryPro\Api\Controllers\DeliveryController;
use LaundryPro\Api\Controllers\DocsController;
use LaundryPro\Api\Controllers\ExpenseController;
use LaundryPro\Api\Controllers\HealthController;
use LaundryPro\Api\Controllers\HrController;
use LaundryPro\Api\Controllers\InstallController;
use LaundryPro\Api\Controllers\InventoryController;
use LaundryPro\Api\Controllers\LanController;
use LaundryPro\Api\Controllers\LicenseController;
use LaundryPro\Api\Controllers\LocalizationController;
use LaundryPro\Api\Controllers\NotificationController;
use LaundryPro\Api\Controllers\PurchaseController;
use LaundryPro\Api\Controllers\ReportsController;
use LaundryPro\Api\Controllers\SalesController;
use LaundryPro\Api\Controllers\SettingsController;
use LaundryPro\Api\Controllers\StorefrontController;
use LaundryPro\Api\Controllers\SyncController;
use LaundryPro\Api\Controllers\TerminalController;
use LaundryPro\Api\Controllers\VendorController;
use LaundryPro\Api\Docs\OpenApiGenerator;
use LaundryPro\Api\Helpers\ApiResponse;
use LaundryPro\Api\Helpers\Logger;
use LaundryPro\Api\Middleware\AuditMiddleware;
use LaundryPro\Api\Middleware\AuthMiddleware;
use LaundryPro\Api\Middleware\CorsMiddleware;
use LaundryPro\Api\Middleware\InstallRateLimitMiddleware;
use LaundryPro\Api\Middleware\MiddlewareInterface;
use LaundryPro\Api\Middleware\PermissionMiddleware;
use LaundryPro\Api\Middleware\RateLimitMiddleware;
use LaundryPro\Api\Repositories\AccountingRepository;
use LaundryPro\Api\Repositories\AnalyticsRepository;
use LaundryPro\Api\Repositories\AttendanceRepository;
use LaundryPro\Api\Repositories\AuditLogRepository;
use LaundryPro\Api\Repositories\BranchRepository;
use LaundryPro\Api\Repositories\BusinessRepository;
use LaundryPro\Api\Repositories\CatalogRepository;
use LaundryPro\Api\Repositories\ChallanRepository;
use LaundryPro\Api\Repositories\ChannelRepository;
use LaundryPro\Api\Repositories\CustomerPortalRepository;
use LaundryPro\Api\Repositories\CustomerRepository;
use LaundryPro\Api\Repositories\DeliveryRepository;
use LaundryPro\Api\Repositories\EmployeeRepository;
use LaundryPro\Api\Repositories\ExpenseRepository;
use LaundryPro\Api\Repositories\InventoryRepository;
use LaundryPro\Api\Repositories\LeaveRepository;
use LaundryPro\Api\Repositories\LocalizationRepository;
use LaundryPro\Api\Repositories\StorefrontRepository;
use LaundryPro\Api\Repositories\TerminalRepository;
use LaundryPro\Api\Repositories\NotificationRepository;
use LaundryPro\Api\Repositories\PayrollRepository;
use LaundryPro\Api\Repositories\PurchaseRepository;
use LaundryPro\Api\Repositories\RefreshTokenRepository;
use LaundryPro\Api\Repositories\SalesRepository;
use LaundryPro\Api\Repositories\SettingsRepository;
use LaundryPro\Api\Repositories\SyncOutboxRepository;
use LaundryPro\Api\Repositories\UserRepository;
use LaundryPro\Api\Repositories\VendorRepository;
use LaundryPro\Api\Security\JwtService;
use LaundryPro\Api\Security\PasswordHasher;
use LaundryPro\Api\Security\PermissionChecker;
use LaundryPro\Api\Security\UmacService;
use LaundryPro\Api\Services\AccountingExportService;
use LaundryPro\Api\Services\AuthService;
use LaundryPro\Api\Services\BackupService;
use LaundryPro\Api\Services\InstallService;
use LaundryPro\Api\Services\LicenseService;
use LaundryPro\Api\Services\MessagingService;
use LaundryPro\Api\Services\MigrationService;
use LaundryPro\Api\Services\SeedService;
use LaundryPro\Api\Services\SyncService;
use PDO;
use Throwable;

final class Application
{
  private float $startTime;

  private Container $container;

  private Router $router;

  /** @var array<string, mixed> */
  private array $appConfig;

  /** @var array<string, mixed> */
  private array $securityConfig;

  private function __construct()
  {
    $this->startTime = microtime(true);
    $this->container = new Container();
    $this->router = new Router();
    $this->bootstrapContainer();
    $this->registerRoutes();
  }

  public static function create(): self
  {
    return new self();
  }

  public function run(): void
  {
    $request = Request::capture();
    $originalPath = $request->getPath();
    $request = $this->normalizeRequestPath($request);

    try {
      $globalMiddleware = [
        new CorsMiddleware($this->appConfig['cors_allowed_origins']),
      ];

      $this->runMiddlewareChain($globalMiddleware, $request, function (Request $req) use ($originalPath) {
        $match = $this->router->match($req);
        if ($match === null) {
          $extraMeta = [];
          if ((bool) $this->appConfig['debug']) {
            $extraMeta['resolved_path'] = $req->getPath();
            $extraMeta['original_path'] = $originalPath;
          }

          $this->container->get(ApiResponse::class)->error(
            $req,
            'NOT_FOUND',
            'common.not_found',
            404,
            [],
            null,
            $extraMeta
          );
          return;
        }

        $req = $req->withRouteParams($match['params']);
        $this->container->set('route.meta', $match['meta'] ?? []);
        $routeMiddleware = array_map(
          fn (string $class) => $this->container->get($class),
          $match['middleware']
        );

        $this->runMiddlewareChain($routeMiddleware, $req, function (Request $innerReq) use ($match) {
          [$class, $method] = $match['handler'];
          $controller = $this->container->get($class);
          $controller->{$method}($innerReq, $this->container);
        });
      });
    } catch (Throwable $e) {
      $logger = $this->container->get(Logger::class);
      $logger->error($e->getMessage(), ['trace' => $e->getTraceAsString()]);

      $request = Request::capture();
      $debug = (bool) $this->appConfig['debug'];
      $this->container->get(ApiResponse::class)->error(
        $request,
        'SERVER_ERROR',
        'common.server_error',
        500,
        $debug ? [['field' => 'exception', 'code' => 'SERVER_ERROR', 'message_key' => $e->getMessage()]] : []
      );
    }
  }

  private function bootstrapContainer(): void
  {
    $this->appConfig = require API_ROOT . '/config/app.php';
    $dbConfig = require API_ROOT . '/config/database.php';
    $this->securityConfig = require API_ROOT . '/config/security.php';

    $this->container->singleton(PDO::class, fn () => PdoFactory::create($dbConfig));
    $this->container->singleton(Logger::class, fn () => new Logger(API_ROOT . '/storage/logs'));
    $this->container->singleton(ApiResponse::class, fn () => new ApiResponse($this->appConfig['version']));
    $this->container->singleton(JwtService::class, fn () => new JwtService(
      (string) $this->securityConfig['jwt_secret'],
      (int) $this->securityConfig['jwt_access_ttl'],
      (int) $this->securityConfig['jwt_refresh_ttl'],
    ));
    $this->container->singleton(PasswordHasher::class, fn () => new PasswordHasher());
    $this->container->singleton(UserRepository::class, fn (Container $c) => new UserRepository($c->pdo()));
    $this->container->singleton(RefreshTokenRepository::class, fn (Container $c) => new RefreshTokenRepository($c->pdo()));
    $this->container->singleton(SettingsRepository::class, fn (Container $c) => new SettingsRepository($c->pdo()));
    $this->container->singleton(AuditLogRepository::class, fn (Container $c) => new AuditLogRepository($c->pdo()));
    $this->container->singleton(AuthService::class, fn (Container $c) => new AuthService(
      $c->get(UserRepository::class),
      $c->get(RefreshTokenRepository::class),
      $c->get(JwtService::class),
      $c->get(PasswordHasher::class),
      (int) $this->securityConfig['jwt_access_ttl'],
      (int) $this->securityConfig['jwt_refresh_ttl'],
    ));
    $this->container->singleton(HealthController::class, fn (Container $c) => new HealthController(
      $c->get(ApiResponse::class),
      $c->pdo(),
      $this->appConfig['version'],
      $this->startTime,
    ));
    $this->container->singleton(AuthController::class, fn (Container $c) => new AuthController(
      $c->get(ApiResponse::class),
      $c->get(AuthService::class),
      $c->get(AuditLogRepository::class),
    ));
    $this->container->singleton(SettingsController::class, fn (Container $c) => new SettingsController(
      $c->get(ApiResponse::class),
      $c->get(SettingsRepository::class),
      $c->get(AuditLogRepository::class),
    ));
    $this->container->singleton(MigrationService::class, fn (Container $c) => new MigrationService(
      $c->pdo(),
      API_ROOT . '/database/migrations',
    ));
    $this->container->singleton(SeedService::class, fn (Container $c) => new SeedService(
      $c->pdo(),
      API_ROOT . '/database/seeds',
      $c->get(PasswordHasher::class),
    ));
    $this->container->singleton(InstallService::class, fn () => new InstallService(
      API_ROOT . '/storage/installed.lock',
      (string) $this->securityConfig['install_secret'],
      (string) $this->appConfig['version'],
      API_ROOT . '/database/migrations',
      API_ROOT . '/database/seeds',
      $this->container->get(PasswordHasher::class),
    ));
    $serverUrl = rtrim((string) $this->appConfig['url'], '/') . '/api/v1';
    $this->container->singleton(OpenApiGenerator::class, fn () => new OpenApiGenerator(
      'LaundryPro UAE API',
      (string) $this->appConfig['version'],
      $serverUrl,
    ));
    $this->container->singleton(DocsController::class, fn (Container $c) => new DocsController(
      $c->get(OpenApiGenerator::class),
      API_ROOT . '/public/docs',
    ));
    $this->container->singleton(InstallController::class, fn (Container $c) => new InstallController(
      $c->get(ApiResponse::class),
      $c->get(InstallService::class),
      $c->get(AuditLogRepository::class),
    ));
    $this->container->singleton(CustomerRepository::class, fn (Container $c) => new CustomerRepository($c->pdo()));
    $this->container->singleton(EmployeeRepository::class, fn (Container $c) => new EmployeeRepository($c->pdo()));
    $this->container->singleton(AttendanceRepository::class, fn (Container $c) => new AttendanceRepository($c->pdo()));
    $this->container->singleton(LeaveRepository::class, fn (Container $c) => new LeaveRepository($c->pdo()));
    $this->container->singleton(PayrollRepository::class, fn (Container $c) => new PayrollRepository($c->pdo()));
    $this->container->singleton(ExpenseRepository::class, fn (Container $c) => new ExpenseRepository($c->pdo()));
    $this->container->singleton(DeliveryRepository::class, fn (Container $c) => new DeliveryRepository($c->pdo()));
    $this->container->singleton(ChallanRepository::class, fn (Container $c) => new ChallanRepository($c->pdo()));
    $this->container->singleton(PurchaseRepository::class, fn (Container $c) => new PurchaseRepository(
      $c->pdo(),
      $c->get(InventoryRepository::class),
    ));
    $this->container->singleton(NotificationRepository::class, fn (Container $c) => new NotificationRepository($c->pdo()));
    $this->container->singleton(BusinessRepository::class, fn (Container $c) => new BusinessRepository($c->pdo()));
    $this->container->singleton(VendorRepository::class, fn (Container $c) => new VendorRepository($c->pdo()));
    $this->container->singleton(CatalogRepository::class, fn (Container $c) => new CatalogRepository($c->pdo()));
    $this->container->singleton(InventoryRepository::class, fn (Container $c) => new InventoryRepository($c->pdo()));
    $this->container->singleton(SalesRepository::class, fn (Container $c) => new SalesRepository(
      $c->pdo(),
      $c->get(CatalogRepository::class),
      $c->get(InventoryRepository::class),
    ));
    $this->container->singleton(SyncOutboxRepository::class, fn (Container $c) => new SyncOutboxRepository($c->pdo()));
    $this->container->singleton(SyncService::class, fn (Container $c) => new SyncService($c->pdo(), $c->get(SyncOutboxRepository::class)));
    $this->container->singleton(UmacService::class, fn () => new UmacService());
    $this->container->singleton(LicenseService::class, fn (Container $c) => new LicenseService(
      $c->pdo(),
      $c->get(UmacService::class),
      $c->get(SyncService::class),
    ));
    $this->container->singleton(BackupService::class, fn () => new BackupService(
      API_ROOT . '/storage/backups',
      (string) $dbConfig['database'],
      (string) $dbConfig['username'],
      (string) $dbConfig['password'],
      (string) $dbConfig['host'],
    ));
    $this->container->singleton(CustomerController::class, fn (Container $c) => new CustomerController(
      $c->get(ApiResponse::class), $c->get(CustomerRepository::class), $c->get(AuditLogRepository::class), $c->get(SyncService::class),
    ));
    $this->container->singleton(BusinessController::class, fn (Container $c) => new BusinessController(
      $c->get(ApiResponse::class), $c->get(BusinessRepository::class), $c->get(AuditLogRepository::class),
    ));
    $this->container->singleton(VendorController::class, fn (Container $c) => new VendorController(
      $c->get(ApiResponse::class), $c->get(VendorRepository::class), $c->get(AuditLogRepository::class), $c->get(SyncService::class),
    ));
    $this->container->singleton(InventoryController::class, fn (Container $c) => new InventoryController(
      $c->get(ApiResponse::class), $c->get(InventoryRepository::class),
    ));
    $this->container->singleton(CatalogController::class, fn (Container $c) => new CatalogController(
      $c->get(ApiResponse::class), $c->get(CatalogRepository::class),
    ));
    $this->container->singleton(SalesController::class, fn (Container $c) => new SalesController(
      $c->get(ApiResponse::class),
      $c->get(SalesRepository::class),
      $c->get(DeliveryRepository::class),
      $c->get(AuditLogRepository::class),
      $c->get(SyncService::class),
    ));
    $this->container->singleton(ReportsController::class, fn (Container $c) => new ReportsController(
      $c->get(ApiResponse::class),
      $c->get(SalesRepository::class),
      $c->get(ExpenseRepository::class),
      $c->get(PayrollRepository::class),
      $c->get(InventoryRepository::class),
      $c->get(DeliveryRepository::class),
      $c->get(PurchaseRepository::class),
    ));
    $this->container->singleton(HrController::class, fn (Container $c) => new HrController(
      $c->get(ApiResponse::class),
      $c->get(EmployeeRepository::class),
      $c->get(AttendanceRepository::class),
      $c->get(LeaveRepository::class),
      $c->get(PayrollRepository::class),
      $c->get(AuditLogRepository::class),
    ));
    $this->container->singleton(ExpenseController::class, fn (Container $c) => new ExpenseController(
      $c->get(ApiResponse::class),
      $c->get(ExpenseRepository::class),
      $c->get(AuditLogRepository::class),
    ));
    $this->container->singleton(DeliveryController::class, fn (Container $c) => new DeliveryController(
      $c->get(ApiResponse::class),
      $c->get(DeliveryRepository::class),
      $c->get(AuditLogRepository::class),
    ));
    $this->container->singleton(ChallanController::class, fn (Container $c) => new ChallanController(
      $c->get(ApiResponse::class),
      $c->get(ChallanRepository::class),
      $c->get(AuditLogRepository::class),
    ));
    $this->container->singleton(PurchaseController::class, fn (Container $c) => new PurchaseController(
      $c->get(ApiResponse::class),
      $c->get(PurchaseRepository::class),
      $c->get(AuditLogRepository::class),
    ));
    $this->container->singleton(NotificationController::class, fn (Container $c) => new NotificationController(
      $c->get(ApiResponse::class),
      $c->get(NotificationRepository::class),
      $c->get(AuditLogRepository::class),
    ));
    $this->container->singleton(BranchRepository::class, fn (Container $c) => new BranchRepository($c->pdo()));
    $this->container->singleton(TerminalRepository::class, fn (Container $c) => new TerminalRepository($c->pdo()));
    $this->container->singleton(AnalyticsRepository::class, fn (Container $c) => new AnalyticsRepository($c->pdo()));
    $this->container->singleton(ChannelRepository::class, fn (Container $c) => new ChannelRepository($c->pdo()));
    $this->container->singleton(AccountingRepository::class, fn (Container $c) => new AccountingRepository($c->pdo()));
    $this->container->singleton(StorefrontRepository::class, fn (Container $c) => new StorefrontRepository($c->pdo()));
    $this->container->singleton(CustomerPortalRepository::class, fn (Container $c) => new CustomerPortalRepository($c->pdo()));
    $this->container->singleton(LocalizationRepository::class, fn (Container $c) => new LocalizationRepository($c->pdo()));
    $this->container->singleton(MessagingService::class, fn (Container $c) => new MessagingService($c->get(ChannelRepository::class)));
    $this->container->singleton(AccountingExportService::class, fn (Container $c) => new AccountingExportService(
      $c->get(AccountingRepository::class),
      $c->pdo(),
    ));
    $this->container->singleton(BranchController::class, fn (Container $c) => new BranchController(
      $c->get(ApiResponse::class), $c->get(BranchRepository::class), $c->get(AuditLogRepository::class),
    ));
    $this->container->singleton(TerminalController::class, fn (Container $c) => new TerminalController(
      $c->get(ApiResponse::class), $c->get(TerminalRepository::class), $c->get(BranchRepository::class), $c->get(AuditLogRepository::class),
    ));
    $this->container->singleton(AnalyticsController::class, fn (Container $c) => new AnalyticsController(
      $c->get(ApiResponse::class), $c->get(AnalyticsRepository::class),
    ));
    $this->container->singleton(ChannelController::class, fn (Container $c) => new ChannelController(
      $c->get(ApiResponse::class), $c->get(ChannelRepository::class), $c->get(MessagingService::class), $c->get(AuditLogRepository::class),
    ));
    $this->container->singleton(AccountingController::class, fn (Container $c) => new AccountingController(
      $c->get(ApiResponse::class), $c->get(AccountingRepository::class), $c->get(AccountingExportService::class), $c->get(AuditLogRepository::class),
    ));
    $this->container->singleton(StorefrontController::class, fn (Container $c) => new StorefrontController(
      $c->get(ApiResponse::class), $c->get(StorefrontRepository::class), $c->get(CatalogRepository::class),
      $c->get(SalesRepository::class), $c->get(AuditLogRepository::class),
    ));
    $this->container->singleton(CustomerPortalController::class, fn (Container $c) => new CustomerPortalController(
      $c->get(ApiResponse::class), $c->get(CustomerPortalRepository::class), $c->get(SalesRepository::class),
    ));
    $this->container->singleton(LocalizationController::class, fn (Container $c) => new LocalizationController(
      $c->get(ApiResponse::class), $c->get(LocalizationRepository::class), $c->get(AuditLogRepository::class),
    ));
    $this->container->singleton(LanController::class, fn (Container $c) => new LanController($c->get(ApiResponse::class)));
    $this->container->singleton(SyncController::class, fn (Container $c) => new SyncController(
      $c->get(ApiResponse::class), $c->get(SyncService::class),
    ));
    $this->container->singleton(LicenseController::class, fn (Container $c) => new LicenseController(
      $c->get(ApiResponse::class), $c->get(LicenseService::class),
    ));
    $this->container->singleton(BackupController::class, fn (Container $c) => new BackupController(
      $c->get(ApiResponse::class), $c->get(BackupService::class),
    ));
    $this->container->singleton(PermissionChecker::class, fn () => new PermissionChecker());
    $this->container->singleton(AuthMiddleware::class, fn () => new AuthMiddleware());
    $this->container->singleton(PermissionMiddleware::class, fn (Container $c) => new PermissionMiddleware($c->get(PermissionChecker::class)));
    $this->container->singleton(RateLimitMiddleware::class, fn () => new RateLimitMiddleware(
      API_ROOT . '/storage/rate_limits',
      (int) $this->securityConfig['login_rate_limit'],
      (int) $this->securityConfig['login_rate_window'],
    ));
    $this->container->singleton(InstallRateLimitMiddleware::class, fn () => new InstallRateLimitMiddleware(
      API_ROOT . '/storage/rate_limits',
      (int) $this->securityConfig['install_rate_limit'],
      (int) $this->securityConfig['install_rate_window'],
    ));
    $this->container->singleton(\LaundryPro\Api\Middleware\InstallTokenMiddleware::class, fn () => new \LaundryPro\Api\Middleware\InstallTokenMiddleware());
    $this->container->singleton(AuditMiddleware::class, fn (Container $c) => new AuditMiddleware());
  }

  public function router(): Router
  {
    return $this->router;
  }

  private function registerRoutes(): void
  {
    require API_ROOT . '/routes/api.php';
    register_api_routes($this->router);
  }

  /** @param array<int, MiddlewareInterface> $middleware */
  private function runMiddlewareChain(array $middleware, Request $request, callable $destination): void
  {
    $runner = array_reduce(
      array_reverse($middleware),
      fn (callable $next, MiddlewareInterface $mw) => fn (Request $req) => $mw->handle($req, $this->container, fn () => $next($req)),
      $destination
    );

    $runner($request);
  }

  private function normalizeRequestPath(Request $request): Request
  {
    $resolved = RequestPathResolver::resolve(
      $request->getPath(),
      (string) ($this->appConfig['base_path'] ?? ''),
    );

    return $request->withPath($resolved);
  }
}
