<!doctype html>
<html lang="en">
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title><?= htmlspecialchars($pageTitle ?? 'Dashboard') ?> - LaundryPro Cloud Super-Admin</title>

    <!-- Google Fonts & Bootstrap Icons -->
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@fontsource/source-sans-3@5.0.12/index.css" />
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.13.1/font/bootstrap-icons.min.css" />

    <!-- AdminLTE CSS -->
    <link rel="stylesheet" href="/assets/css/adminlte.min.css" />
    <style>
      .brand-image-custom {
        max-height: 36px;
        filter: drop-shadow(0 2px 4px rgba(0,0,0,0.15));
      }
      .app-sidebar {
        background-color: #112233 !important;
      }
      .nav-link.active {
        background-color: #0D6E6E !important;
        color: #fff !important;
      }
    </style>
  </head>
  <body class="layout-fixed sidebar-expand-lg bg-body-tertiary">
    <div class="app-wrapper">
      <!-- Navbar -->
      <nav class="app-header navbar navbar-expand bg-body">
        <div class="container-fluid">
          <ul class="navbar-nav">
            <li class="nav-item">
              <a class="nav-link" data-lte-toggle="sidebar" href="#" role="button"><i class="bi bi-list fs-4"></i></a>
            </li>
            <li class="nav-item d-none d-md-block">
              <span class="navbar-text fw-bold text-teal">Central Cloud Portal &bull; Multi-Tenant Core</span>
            </li>
          </ul>

          <ul class="navbar-nav ms-auto align-items-center">
            <li class="nav-item me-3">
              <span class="badge bg-success-subtle text-success border border-success-subtle px-2 py-1">
                <i class="bi bi-shield-check me-1"></i>Production Ready
              </span>
            </li>
            <li class="nav-item dropdown user-menu">
              <a href="#" class="nav-link dropdown-toggle" data-bs-toggle="dropdown">
                <i class="bi bi-person-circle fs-5 text-primary"></i>
                <span class="d-none d-md-inline ms-1 fw-bold"><?= htmlspecialchars($user['full_name'] ?? 'Super Admin') ?></span>
              </a>
              <ul class="dropdown-menu dropdown-menu-end shadow">
                <li class="user-header bg-primary text-white p-3 text-center">
                  <p class="mb-0 fw-bold"><?= htmlspecialchars($user['username'] ?? 'superadmin') ?></p>
                  <small class="text-white-50">Role: <?= htmlspecialchars($user['role'] ?? 'super_admin') ?></small>
                </li>
                <li class="p-2 text-center">
                  <form action="/admin/logout" method="POST">
                    <button type="submit" class="btn btn-outline-danger btn-sm w-100"><i class="bi bi-box-arrow-right me-1"></i>Sign Out</button>
                  </form>
                </li>
              </ul>
            </li>
          </ul>
        </div>
      </nav>

      <!-- Sidebar -->
      <aside class="app-sidebar shadow" data-bs-theme="dark">
        <div class="sidebar-brand p-3 d-flex align-items-center justify-content-between border-bottom border-secondary">
          <a href="/admin" class="brand-link text-decoration-none text-white d-flex align-items-center">
            <i class="bi bi-cloud-check-fill fs-3 text-info me-2"></i>
            <span class="brand-text fw-bold fs-5">LaundryPro <span class="badge bg-info ms-1">Cloud</span></span>
          </a>
        </div>

        <div class="sidebar-wrapper p-2">
          <nav class="mt-2">
            <ul class="nav nav-pills flex-column gap-1" data-lte-toggle="treeview" role="menu">
              <li class="nav-item">
                <a href="/admin" class="nav-link <?= ($pageTitle === 'Super-Admin Dashboard') ? 'active' : '' ?>">
                  <i class="nav-icon bi bi-speedometer2"></i>
                  <p>Dashboard</p>
                </a>
              </li>
              <li class="nav-item">
                <a href="/admin/tenants" class="nav-link <?= ($pageTitle === 'Tenant Workstations') ? 'active' : '' ?>">
                  <i class="nav-icon bi bi-buildings"></i>
                  <p>Tenants / Nodes</p>
                </a>
              </li>
              <li class="nav-item">
                <a href="/admin/licenses" class="nav-link <?= ($pageTitle === 'Licenses & Anti-Tamper Keys') ? 'active' : '' ?>">
                  <i class="nav-icon bi bi-key"></i>
                  <p>License Center</p>
                </a>
              </li>
              <li class="nav-item">
                <a href="/admin/sync" class="nav-link <?= ($pageTitle === 'Sync Telemetry & Inspector') ? 'active' : '' ?>">
                  <i class="nav-icon bi bi-arrow-repeat"></i>
                  <p>Sync Telemetry</p>
                </a>
              </li>
              <li class="nav-item">
                <a href="/admin/audit" class="nav-link <?= ($pageTitle === 'Security Audit Trail') ? 'active' : '' ?>">
                  <i class="nav-icon bi bi-journal-text"></i>
                  <p>Audit Trail</p>
                </a>
              </li>
            </ul>
          </nav>
        </div>
      </aside>

      <!-- Main Content -->
      <main class="app-main p-4">
        <div class="app-content-header mb-4">
          <div class="container-fluid">
            <div class="row align-items-center">
              <div class="col-sm-6">
                <h3 class="mb-0 fw-bold"><?= htmlspecialchars($pageTitle ?? 'Overview') ?></h3>
              </div>
              <div class="col-sm-6">
                <ol class="breadcrumb float-sm-end mb-0">
                  <li class="breadcrumb-item"><a href="/admin">Cloud Admin</a></li>
                  <li class="breadcrumb-item active" aria-current="page"><?= htmlspecialchars($pageTitle ?? 'Overview') ?></li>
                </ol>
              </div>
            </div>
          </div>
        </div>

        <div class="app-content">
          <div class="container-fluid">
            <?= $content ?? '' ?>
          </div>
        </div>
      </main>

      <!-- Footer -->
      <footer class="app-footer text-muted py-3 px-4 border-top">
        <div class="float-end d-none d-sm-inline">LaundryPro UAE Cloud v1.2.0</div>
        <strong>Copyright &copy; 2026 <a href="https://www.magnificentsolution.co.in" target="_blank">Magnificent Solution</a>.</strong> All rights reserved.
      </footer>
    </div>

    <!-- Bootstrap 5 Bundle JS -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.8/dist/js/bootstrap.bundle.min.js"></script>
    <!-- AdminLTE JS -->
    <script src="/assets/js/adminlte.min.js"></script>
  </body>
</html>
