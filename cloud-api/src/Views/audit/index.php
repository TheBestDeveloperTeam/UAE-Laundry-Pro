<div class="card shadow-sm border-0">
  <div class="card-header bg-body d-flex align-items-center justify-content-between py-3">
    <h5 class="card-title mb-0 fw-bold"><i class="bi bi-shield-lock me-2 text-danger"></i>Security & Operations Audit Trail</h5>
    <span class="badge bg-secondary"><?= count($logs) ?> Recorded Events</span>
  </div>
  <div class="card-body p-0">
    <div class="table-responsive">
      <table class="table table-hover align-middle mb-0">
        <thead class="table-light">
          <tr>
            <th>ID</th>
            <th>Admin</th>
            <th>Related Tenant</th>
            <th>Action Type</th>
            <th>Details</th>
            <th>IP Address</th>
            <th>Timestamp</th>
          </tr>
        </thead>
        <tbody>
          <?php if (empty($logs)): ?>
            <tr><td colspan="7" class="text-center text-muted py-4">No audit logs recorded</td></tr>
          <?php else: ?>
            <?php foreach ($logs as $l): ?>
              <tr>
                <td><span class="badge bg-secondary">#<?= $l['id'] ?></span></td>
                <td class="fw-semibold small"><?= htmlspecialchars($l['admin_name'] ?? 'System') ?></td>
                <td class="small"><?= htmlspecialchars($l['business_name'] ?? '-') ?></td>
                <td><span class="badge bg-dark"><?= htmlspecialchars($l['action']) ?></span></td>
                <td class="small"><?= htmlspecialchars($l['details'] ?? '') ?></td>
                <td class="small font-monospace text-muted"><?= htmlspecialchars($l['ip_address'] ?? '') ?></td>
                <td class="small text-muted"><?= htmlspecialchars($l['created_at']) ?></td>
              </tr>
            <?php endforeach; ?>
          <?php endif; ?>
        </tbody>
      </table>
    </div>
  </div>
</div>
