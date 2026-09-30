<?php
$title = "Store Management Dashboard";
ob_start();
?>
<div class="container-fluid p-0">
  <!-- Page Header -->
  <div class="d-flex align-items-center justify-content-between mb-4">
    <div>
      <h3 class="fw-bold mb-1" style="color: var(--lp-text-primary);">Store Node Dashboard</h3>
      <p class="text-muted small mb-0">Real-time local POS, inventory & central cloud synchronization state</p>
    </div>
    <div class="d-flex gap-2">
      <a href="/docs" class="btn btn-outline-secondary text-light btn-sm d-flex align-items-center gap-1 border-secondary">
        <i class="bi bi-code-slash"></i> <span>OpenAPI Docs</span>
      </a>
      <a href="/admin" class="btn btn-purple btn-sm d-flex align-items-center gap-1">
        <i class="bi bi-arrow-clockwise"></i> <span>Refresh Node</span>
      </a>
    </div>
  </div>

  <!-- KPI Row -->
  <div class="row g-3 mb-4">
    <!-- Today Orders -->
    <div class="col-sm-6 col-xl-3">
      <div class="card-glass p-3 h-100">
        <div class="d-flex justify-content-between align-items-center mb-2">
          <span class="text-muted small fw-semibold">TODAY'S ORDERS</span>
          <span class="badge rounded-pill" style="background: rgba(124, 58, 237, 0.15); color: #a78bfa;">Active</span>
        </div>
        <div class="d-flex align-items-baseline gap-2">
          <h2 class="fw-bold mb-0 text-white"><?= number_format($newOrders ?? 0) ?></h2>
          <span class="text-muted small">orders</span>
        </div>
        <div class="small text-muted mt-2">
          <i class="bi bi-bag-check text-success me-1"></i> POS counter intake today
        </div>
      </div>
    </div>

    <!-- Today Sales -->
    <div class="col-sm-6 col-xl-3">
      <div class="card-glass p-3 h-100">
        <div class="d-flex justify-content-between align-items-center mb-2">
          <span class="text-muted small fw-semibold">TODAY'S REVENUE</span>
          <span class="badge rounded-pill bg-success-subtle text-success">Gross Sales</span>
        </div>
        <div class="d-flex align-items-baseline gap-2">
          <h2 class="fw-bold mb-0 text-white"><?= number_format($todaySales ?? 0.0, 2) ?></h2>
          <span class="text-muted small">AED</span>
        </div>
        <div class="small text-muted mt-2">
          <i class="bi bi-cash-stack text-success me-1"></i> Invoiced locally
        </div>
      </div>
    </div>

    <!-- UAE 5% VAT -->
    <div class="col-sm-6 col-xl-3">
      <div class="card-glass p-3 h-100">
        <div class="d-flex justify-content-between align-items-center mb-2">
          <span class="text-muted small fw-semibold">UAE 5% VAT</span>
          <span class="badge rounded-pill" style="background: rgba(6, 182, 212, 0.15); color: #22d3ee;">FTA Tax</span>
        </div>
        <div class="d-flex align-items-baseline gap-2">
          <h2 class="fw-bold mb-0 text-white"><?= number_format($todayVat ?? 0.0, 2) ?></h2>
          <span class="text-muted small">AED</span>
        </div>
        <div class="small text-muted mt-2">
          <i class="bi bi-shield-check text-info me-1"></i> 5.00% standard tax rate
        </div>
      </div>
    </div>

    <!-- Sync Health -->
    <div class="col-sm-6 col-xl-3">
      <div class="card-glass p-3 h-100">
        <div class="d-flex justify-content-between align-items-center mb-2">
          <span class="text-muted small fw-semibold">CLOUD SYNC</span>
          <span class="badge rounded-pill <?= ($pendingSync ?? 0) === 0 ? 'bg-success-subtle text-success' : 'bg-warning-subtle text-warning' ?>">
            <?= ($pendingSync ?? 0) === 0 ? 'Synchronized' : 'Queued' ?>
          </span>
        </div>
        <div class="d-flex align-items-baseline gap-2">
          <h2 class="fw-bold mb-0 text-white"><?= (int) ($syncStatus ?? 100) ?>%</h2>
          <span class="text-muted small">(<?= (int) ($pendingSync ?? 0) ?> pending)</span>
        </div>
        <div class="progress mt-2" style="height: 6px; background-color: var(--lp-border);">
          <div class="progress-bar" role="progressbar" style="width: <?= (int) ($syncStatus ?? 100) ?>%; background: linear-gradient(90deg, #7c3aed, #06b6d4);"></div>
        </div>
      </div>
    </div>
  </div>

  <!-- Operational Status Row -->
  <div class="row g-4">
    <!-- Cloud Gateway Synchronization -->
    <div class="col-lg-7" id="sync-section">
      <div class="card-glass p-4 h-100">
        <div class="d-flex justify-content-between align-items-center mb-3">
          <h5 class="fw-bold mb-0 text-white d-flex align-items-center gap-2">
            <i class="bi bi-cloud-arrow-up text-primary" style="color: var(--lp-primary) !important;"></i>
            <span>Central Cloud Synchronization</span>
          </h5>
          <span class="badge bg-secondary-subtle text-light border border-secondary">
            Node: 127.0.0.1
          </span>
        </div>

        <div class="p-3 rounded mb-3" style="background-color: var(--lp-bg-surface-elevated); border: 1px solid var(--lp-border);">
          <div class="row text-center">
            <div class="col-4 border-end border-secondary">
              <div class="small text-muted">Outbox Queue</div>
              <div class="fs-4 fw-bold text-white"><?= number_format($pendingSync ?? 0) ?></div>
            </div>
            <div class="col-4 border-end border-secondary">
              <div class="small text-muted">Registered Customers</div>
              <div class="fs-4 fw-bold text-white"><?= number_format($totalCustomers ?? 0) ?></div>
            </div>
            <div class="col-4">
              <div class="small text-muted">Cloud Destination</div>
              <div class="fs-6 fw-bold text-info mt-1">cloud-api/public</div>
            </div>
          </div>
        </div>

        <div class="d-flex align-items-center justify-content-between text-muted small">
          <span><i class="bi bi-check2-circle text-success me-1"></i> Autonomous background push/pull daemon enabled</span>
          <span class="text-white fw-medium">Protocol: HTTP/JSON Outbox</span>
        </div>
      </div>
    </div>

    <!-- UAE FTA Compliance -->
    <div class="col-lg-5" id="vat-section">
      <div class="card-glass p-4 h-100">
        <h5 class="fw-bold mb-3 text-white d-flex align-items-center gap-2">
          <i class="bi bi-file-earmark-text text-info" style="color: var(--lp-accent-cyan) !important;"></i>
          <span>UAE FTA E-Invoice Compliance</span>
        </h5>

        <ul class="list-group list-group-flush mb-3" style="background: transparent;">
          <li class="list-group-item d-flex justify-content-between align-items-center px-0 text-light" style="background: transparent; border-color: var(--lp-border);">
            <span class="text-muted small">Mandatory VAT Rate</span>
            <span class="badge bg-info-subtle text-info fw-bold">5.00% Standard Rate</span>
          </li>
          <li class="list-group-item d-flex justify-content-between align-items-center px-0 text-light" style="background: transparent; border-color: var(--lp-border);">
            <span class="text-muted small">QR Code Standard</span>
            <span class="badge bg-success-subtle text-success">ZATCA/FTA Base64 TLV</span>
          </li>
          <li class="list-group-item d-flex justify-content-between align-items-center px-0 text-light" style="background: transparent; border-color: var(--lp-border);">
            <span class="text-muted small">WPS SIF Payroll Standard</span>
            <span class="badge bg-primary-subtle text-primary">CBUAE SIF 3.0</span>
          </li>
          <li class="list-group-item d-flex justify-content-between align-items-center px-0 text-light" style="background: transparent; border-color: var(--lp-border);">
            <span class="text-muted small">Currency Code</span>
            <span class="text-white fw-bold">AED (د.إ)</span>
          </li>
        </ul>

        <div class="alert alert-dark border-secondary small mb-0 py-2" role="alert" style="background-color: var(--lp-bg-surface-elevated);">
          <i class="bi bi-info-circle me-1 text-info"></i> Compliant with Federal Tax Authority (FTA) Executive Regulations.
        </div>
      </div>
    </div>
  </div>
</div>
<?php
$content = ob_get_clean();
require __DIR__ . '/layout.php';
?>
