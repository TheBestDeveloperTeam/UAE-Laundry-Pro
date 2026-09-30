<!doctype html>
<html lang="en" id="html-root">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title><?= htmlspecialchars($title ?? 'Local Store Admin') ?> - LaundryPro UAE</title>

  <!-- Google Fonts & Bootstrap Icons -->
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@fontsource/source-sans-3@5.0.12/index.css" />
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.13.1/font/bootstrap-icons.min.css" />
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" />

  <style>
    :root {
      --lp-bg-canvas: #0d0f17;
      --lp-bg-surface: #161926;
      --lp-bg-surface-elevated: #1e2235;
      --lp-border: #262a40;
      --lp-primary: #7c3aed;
      --lp-primary-hover: #6d28d9;
      --lp-accent-cyan: #06b6d4;
      --lp-text-primary: #f8fafc;
      --lp-text-muted: #94a3b8;
      --lp-success: #10b981;
      --lp-warning: #f59e0b;
      --lp-danger: #ef4444;
    }
    body {
      background-color: var(--lp-bg-canvas);
      color: var(--lp-text-primary);
      font-family: 'Source Sans 3', system-ui, -apple-system, sans-serif;
      min-height: 100vh;
    }
    .navbar-store {
      background-color: var(--lp-bg-surface);
      border-bottom: 1px solid var(--lp-border);
      padding: 0.75rem 1.5rem;
    }
    .sidebar-store {
      background-color: var(--lp-bg-surface);
      border-right: 1px solid var(--lp-border);
      min-height: calc(100vh - 65px);
      width: 250px;
    }
    .nav-link-custom {
      color: var(--lp-text-muted);
      border-radius: 8px;
      padding: 0.6rem 1rem;
      margin-bottom: 0.25rem;
      display: flex;
      align-items: center;
      gap: 0.75rem;
      text-decoration: none;
      font-weight: 500;
      transition: all 0.2s ease;
    }
    .nav-link-custom:hover {
      background-color: rgba(124, 58, 237, 0.12);
      color: #fff;
    }
    .nav-link-custom.active {
      background: linear-gradient(135deg, var(--lp-primary), var(--lp-primary-hover));
      color: #fff;
      box-shadow: 0 4px 12px rgba(124, 58, 237, 0.35);
    }
    .card-glass {
      background-color: var(--lp-bg-surface);
      border: 1px solid var(--lp-border);
      border-radius: 12px;
      box-shadow: 0 4px 20px rgba(0, 0, 0, 0.25);
    }
    .stat-badge {
      background: rgba(124, 58, 237, 0.15);
      color: #a78bfa;
      border: 1px solid rgba(124, 58, 237, 0.3);
      padding: 0.25rem 0.6rem;
      border-radius: 20px;
      font-size: 0.8rem;
    }
    .btn-purple {
      background-color: var(--lp-primary);
      border-color: var(--lp-primary);
      color: #fff;
      font-weight: 600;
    }
    .btn-purple:hover {
      background-color: var(--lp-primary-hover);
      border-color: var(--lp-primary-hover);
      color: #fff;
    }
    [dir="rtl"] .sidebar-store {
      border-right: none;
      border-left: 1px solid var(--lp-border);
    }
  </style>
</head>
<body>
  <!-- Header Navbar -->
  <header class="navbar-store d-flex align-items-center justify-content-between">
    <div class="d-flex align-items-center gap-3">
      <div class="fw-bold fs-5 text-white d-flex align-items-center gap-2">
        <i class="bi bi-water text-primary fs-4" style="color: var(--lp-accent-cyan) !important;"></i>
        <span>LaundryPro <span class="badge bg-primary ms-1" style="background-color: var(--lp-primary) !important;">Store Node</span></span>
      </div>
      <span class="stat-badge d-none d-md-inline-block">
        <i class="bi bi-hdd-network me-1"></i> Local Station 127.0.0.1:80
      </span>
    </div>

    <div class="d-flex align-items-center gap-3">
      <button class="btn btn-sm btn-outline-secondary text-light border-secondary" onclick="toggleRtl()" id="rtlBtn" title="Switch Language & Direction">
        <i class="bi bi-translate me-1"></i> <span id="langLabel">العربية</span>
      </button>

      <div class="dropdown">
        <button class="btn btn-sm btn-dark dropdown-toggle border-secondary" type="button" data-bs-toggle="dropdown">
          <i class="bi bi-person-circle me-1"></i> Store Manager
        </button>
        <ul class="dropdown-menu dropdown-menu-dark dropdown-menu-end">
          <li><a class="dropdown-item" href="/docs"><i class="bi bi-journal-code me-2"></i>API Documentation</a></li>
          <li><hr class="dropdown-divider border-secondary"></li>
          <li><a class="dropdown-item text-danger" href="/"><i class="bi bi-box-arrow-right me-2"></i>Exit</a></li>
        </ul>
      </div>
    </div>
  </header>

  <!-- App Layout Container -->
  <div class="d-flex">
    <!-- Sidebar -->
    <aside class="sidebar-store p-3 d-none d-md-block">
      <nav class="nav flex-column">
        <div class="text-uppercase text-muted fw-bold small mb-2 px-2" style="font-size: 0.75rem; letter-spacing: 0.05em;">Operations</div>
        <a class="nav-link-custom active" href="/admin">
          <i class="bi bi-speedometer2"></i> <span>Dashboard</span>
        </a>
        <a class="nav-link-custom" href="/docs">
          <i class="bi bi-code-slash"></i> <span>Local Swagger API</span>
        </a>
        <a class="nav-link-custom" href="#sync-section">
          <i class="bi bi-arrow-repeat"></i> <span>Cloud Synchronization</span>
        </a>

        <div class="text-uppercase text-muted fw-bold small mt-4 mb-2 px-2" style="font-size: 0.75rem; letter-spacing: 0.05em;">Store System</div>
        <a class="nav-link-custom" href="#vat-section">
          <i class="bi bi-receipt"></i> <span>UAE 5% VAT Ledger</span>
        </a>
        <a class="nav-link-custom" href="#hardware-section">
          <i class="bi bi-printer"></i> <span>ESC/POS & Peripherals</span>
        </a>
      </nav>
    </aside>

    <!-- Main Content Area -->
    <main class="flex-grow-1 p-4">
      <?= $content ?? '' ?>
    </main>
  </div>

  <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
  <script>
    function toggleRtl() {
      const html = document.getElementById('html-root');
      const currentDir = html.getAttribute('dir');
      const label = document.getElementById('langLabel');
      if (currentDir === 'rtl') {
        html.removeAttribute('dir');
        html.setAttribute('lang', 'en');
        label.innerText = 'العربية';
      } else {
        html.setAttribute('dir', 'rtl');
        html.setAttribute('lang', 'ar');
        label.innerText = 'English';
      }
    }
  </script>
</body>
</html>
