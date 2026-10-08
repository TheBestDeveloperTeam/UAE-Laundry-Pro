<?php
// LaundryPro UAE - Local Store Administration Web Portal
declare(strict_types=1);

$apiBaseUrl = getenv('LOCAL_API_URL') ?: 'http://localhost/laundrypro-api/public/api/v1';
?>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>LaundryPro UAE | Local Node Operations</title>
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/admin-lte@3.2/dist/css/adminlte.min.css">
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
</head>
<body class="hold-transition sidebar-mini">
<div class="wrapper">
  <!-- Navbar -->
  <nav class="main-header navbar navbar-expand navbar-white navbar-light">
    <ul class="navbar-nav">
      <li class="nav-item">
        <a class="nav-link" data-widget="pushmenu" href="#" role="button"><i class="fas fa-bars"></i></a>
      </li>
      <li class="nav-item d-none d-sm-inline-block">
        <a href="index.php" class="nav-link">Workstation Node Dashboard</a>
      </li>
    </ul>
  </nav>

  <!-- Main Sidebar -->
  <aside class="main-sidebar sidebar-dark-primary elevation-4">
    <a href="index.php" class="brand-link">
      <span class="brand-text font-weight-light"><b>LaundryPro</b> UAE</span>
    </a>
    <div class="sidebar">
      <nav class="mt-2">
        <ul class="nav nav-pills nav-sidebar flex-column" data-widget="treeview" role="menu">
          <li class="nav-item">
            <a href="index.php" class="nav-link active">
              <i class="nav-icon fas fa-tachometer-alt"></i>
              <p>Node Status & Sync</p>
            </a>
          </li>
        </ul>
      </nav>
    </div>
  </aside>

  <!-- Content Wrapper -->
  <div class="content-wrapper">
    <section class="content-header">
      <div class="container-fluid">
        <div class="row mb-2">
          <div class="col-sm-6">
            <h1>Local Node Operations</h1>
          </div>
        </div>
      </div>
    </section>

    <!-- Main content -->
    <section class="content">
      <div class="container-fluid">
        <div class="row">
          <div class="col-lg-3 col-6">
            <div class="small-box bg-info">
              <div class="inner">
                <h3 id="sync-status">Active</h3>
                <p>Sync Engine Mode</p>
              </div>
              <div class="icon">
                <i class="fas fa-sync"></i>
              </div>
            </div>
          </div>
          <div class="col-lg-3 col-6">
            <div class="small-box bg-success">
              <div class="inner">
                <h3 id="license-status">Verified</h3>
                <p>Local License State</p>
              </div>
              <div class="icon">
                <i class="fas fa-certificate"></i>
              </div>
            </div>
          </div>
        </div>

        <div class="card card-primary card-outline">
          <div class="card-header">
            <h3 class="card-title">Outbox & Sync Telemetry</h3>
          </div>
          <div class="card-body">
            <p>Target Local Endpoint: <code><?= htmlspecialchars($apiBaseUrl) ?></code></p>
            <button class="btn btn-primary" onclick="triggerManualSync()"><i class="fas fa-play mr-1"></i> Trigger Outbox Push & Pull</button>
            <div id="sync-output" class="mt-3 p-3 bg-light rounded" style="display:none;"></div>
          </div>
        </div>
      </div>
    </section>
  </div>

  <footer class="main-footer">
    <strong>LaundryPro UAE &copy; 2026.</strong> Local Store Portal.
  </footer>
</div>

<script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/admin-lte@3.2/dist/js/adminlte.min.js"></script>
<script>
function triggerManualSync() {
  $('#sync-output').show().html('<i class="fas fa-spinner fa-spin"></i> Triggering synchronization...');
  fetch('<?= $apiBaseUrl ?>/sync/push', { method: 'POST' })
    .then(r => r.json())
    .then(data => {
      $('#sync-output').html('<b>Sync Push Result:</b> ' + JSON.stringify(data));
    })
    .catch(err => {
      $('#sync-output').html('<span class="text-danger">Failed to sync: ' + err.message + '</span>');
    });
}
</script>
</body>
</html>
