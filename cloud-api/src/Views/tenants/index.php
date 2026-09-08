<div class="card shadow-sm border-0">
  <div class="card-header bg-body d-flex align-items-center justify-content-between py-3">
    <h5 class="card-title mb-0 fw-bold"><i class="bi bi-buildings me-2 text-primary"></i>Registered Laundry Business Nodes</h5>
    <span class="badge bg-primary fs-6"><?= count($tenants) ?> Total</span>
  </div>
  <div class="card-body p-0">
    <div class="table-responsive">
      <table class="table table-hover align-middle mb-0">
        <thead class="table-light">
          <tr>
            <th>ID</th>
            <th>Laundry Name</th>
            <th>City / Country</th>
            <th>Active License Key</th>
            <th>Master Cloud Token</th>
            <th>Sync Ingested</th>
            <th>Node Status</th>
            <th>Created</th>
          </tr>
        </thead>
        <tbody>
          <?php if (empty($tenants)): ?>
            <tr><td colspan="8" class="text-center text-muted py-4">No business nodes registered yet</td></tr>
          <?php else: ?>
            <?php foreach ($tenants as $t): ?>
              <tr>
                <td><span class="badge bg-secondary">#<?= $t['id'] ?></span></td>
                <td class="fw-bold text-dark"><?= htmlspecialchars($t['name']) ?></td>
                <td><?= htmlspecialchars($t['city'] ?? 'Dubai') ?>, <?= htmlspecialchars($t['country_code'] ?? 'AE') ?></td>
                <td>
                  <?php if (!empty($t['license_key'])): ?>
                    <code class="text-primary fw-semibold"><?= htmlspecialchars($t['license_key']) ?></code>
                  <?php else: ?>
                    <span class="badge bg-warning text-dark">Trial / Unassigned</span>
                  <?php endif; ?>
                </td>
                <td>
                  <span class="font-monospace small text-muted" title="<?= htmlspecialchars($t['cloud_token']) ?>">
                    <?= htmlspecialchars(substr($t['cloud_token'], 0, 12)) ?>...
                  </span>
                </td>
                <td><span class="badge bg-info text-dark fw-bold"><?= number_format($t['sync_count'] ?? 0) ?></span></td>
                <td>
                  <span class="badge bg-<?= ($t['status'] === 'active') ? 'success' : 'danger' ?>">
                    <?= htmlspecialchars(strtoupper($t['status'])) ?>
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
