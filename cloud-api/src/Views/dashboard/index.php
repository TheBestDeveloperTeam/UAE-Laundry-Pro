<div class="row g-3 mb-4">
  <div class="col-12 col-sm-6 col-xl-4">
    <div class="card shadow-sm border-0 border-start border-primary border-4 h-100">
      <div class="card-body">
        <div class="d-flex align-items-center justify-content-between">
          <div>
            <h6 class="text-muted text-uppercase mb-1 small fw-bold">Active Tenants</h6>
            <h3 class="mb-0 fw-bold"><?= number_format($stats['tenants_count'] ?? 0) ?></h3>
          </div>
          <div class="p-3 bg-primary-subtle text-primary rounded-circle">
            <i class="bi bi-buildings fs-3"></i>
          </div>
        </div>
      </div>
    </div>
  </div>

  <div class="col-12 col-sm-6 col-xl-4">
    <div class="card shadow-sm border-0 border-start border-success border-4 h-100">
      <div class="card-body">
        <div class="d-flex align-items-center justify-content-between">
          <div>
            <h6 class="text-muted text-uppercase mb-1 small fw-bold">Issued Licenses</h6>
            <h3 class="mb-0 fw-bold"><?= number_format($stats['active_licenses'] ?? 0) ?></h3>
          </div>
          <div class="p-3 bg-success-subtle text-success rounded-circle">
            <i class="bi bi-key-fill fs-3"></i>
          </div>
        </div>
      </div>
    </div>
  </div>

  <div class="col-12 col-sm-6 col-xl-4">
    <div class="card shadow-sm border-0 border-start border-info border-4 h-100">
      <div class="card-body">
        <div class="d-flex align-items-center justify-content-between">
          <div>
            <h6 class="text-muted text-uppercase mb-1 small fw-bold">Total Ingested Syncs</h6>
            <h3 class="mb-0 fw-bold"><?= number_format($stats['sync_records_count'] ?? 0) ?></h3>
          </div>
          <div class="p-3 bg-info-subtle text-info rounded-circle">
            <i class="bi bi-arrow-repeat fs-3"></i>
          </div>
        </div>
      </div>
    </div>
  </div>
</div>

<div class="row g-4">
  <!-- Recent Tenants -->
  <div class="col-12 col-lg-6">
    <div class="card shadow-sm border-0 h-100">
      <div class="card-header bg-body d-flex align-items-center justify-content-between">
        <h5 class="card-title mb-0 fw-bold"><i class="bi bi-shop me-2 text-primary"></i>Recently Registered Laundry Nodes</h5>
        <a href="/admin/tenants" class="btn btn-sm btn-outline-primary">View All</a>
      </div>
      <div class="card-body p-0">
        <div class="table-responsive">
          <table class="table table-hover align-middle mb-0">
            <thead class="table-light">
              <tr>
                <th>ID</th>
                <th>Business Name</th>
                <th>Status</th>
                <th>Registered</th>
              </tr>
            </thead>
            <tbody>
              <?php if (empty($stats['recent_tenants'])): ?>
                <tr><td colspan="4" class="text-center text-muted py-3">No tenants registered yet</td></tr>
              <?php else: ?>
                <?php foreach ($stats['recent_tenants'] as $t): ?>
                  <tr>
                    <td><span class="badge bg-secondary">#<?= $t['id'] ?></span></td>
                    <td class="fw-semibold"><?= htmlspecialchars($t['name']) ?></td>
                    <td>
                      <span class="badge bg-<?= ($t['status'] === 'active') ? 'success' : 'warning' ?>">
                        <?= htmlspecialchars($t['status']) ?>
                      </span>
                    </td>
                    <td class="small text-muted"><?= htmlspecialchars(substr($t['created_at'], 0, 10)) ?></td>
                  </tr>
                <?php endforeach; ?>
              <?php endif; ?>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  </div>

  <!-- Recent Sync Activity -->
  <div class="col-12 col-lg-6">
    <div class="card shadow-sm border-0 h-100">
      <div class="card-header bg-body d-flex align-items-center justify-content-between">
        <h5 class="card-title mb-0 fw-bold"><i class="bi bi-cloud-arrow-down-fill me-2 text-success"></i>Latest Sync Telemetry</h5>
        <a href="/admin/sync" class="btn btn-sm btn-outline-success">Inspect All</a>
      </div>
      <div class="card-body p-0">
        <div class="table-responsive">
          <table class="table table-hover align-middle mb-0">
            <thead class="table-light">
              <tr>
                <th>Tenant</th>
                <th>Entity</th>
                <th>Operation</th>
                <th>Timestamp</th>
              </tr>
            </thead>
            <tbody>
              <?php if (empty($stats['recent_sync'])): ?>
                <tr><td colspan="4" class="text-center text-muted py-3">No sync packets received yet</td></tr>
              <?php else: ?>
                <?php foreach ($stats['recent_sync'] as $s): ?>
                  <tr>
                    <td class="fw-semibold small"><?= htmlspecialchars($s['business_name'] ?? ('ID #' . $s['business_owner_id'])) ?></td>
                    <td><span class="badge bg-primary-subtle text-primary border"><?= htmlspecialchars($s['entity_type']) ?></span></td>
                    <td><span class="badge bg-info-subtle text-info"><?= htmlspecialchars($s['operation']) ?></span></td>
                    <td class="small text-muted"><?= htmlspecialchars(substr($s['created_at'], 11, 8)) ?></td>
                  </tr>
                <?php endforeach; ?>
              <?php endif; ?>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  </div>
</div>
