<div class="row g-4">
  <!-- Issue License Card -->
  <div class="col-12 col-xl-4">
    <div class="card shadow-sm border-0 h-100">
      <div class="card-header bg-primary text-white py-3">
        <h5 class="card-title mb-0 fw-bold"><i class="bi bi-patch-check-fill me-2"></i>Issue / Sign License</h5>
      </div>
      <div class="card-body p-4">
        <form action="/admin/licenses/issue" method="POST">
          <div class="mb-3">
            <label class="form-label small fw-semibold">Target Tenant</label>
            <select name="tenant_id" class="form-select" required>
              <option value="">-- Select Laundry Business --</option>
              <?php foreach ($tenants as $t): ?>
                <option value="<?= $t['id'] ?>"><?= htmlspecialchars($t['name']) ?> (#<?= $t['id'] ?>)</option>
              <?php endforeach; ?>
            </select>
          </div>

          <div class="mb-3">
            <label class="form-label small fw-semibold">Plan Type</label>
            <select name="plan_type" class="form-select">
              <option value="standard">Standard Commercial (1 Year)</option>
              <option value="enterprise">Enterprise Multi-Branch</option>
              <option value="trial_extended">Extended Evaluation (30 Days)</option>
            </select>
          </div>

          <div class="mb-3">
            <label class="form-label small fw-semibold">Hardware Fingerprint (UMAC)</label>
            <input type="text" name="umac" class="form-control font-monospace" placeholder="Optional or paste from .lic req" />
            <div class="form-text small">Lock license to specific physical workstation hardware.</div>
          </div>

          <div class="mb-4">
            <label class="form-label small fw-semibold">Validity Period (Days)</label>
            <input type="number" name="valid_days" class="form-control" value="365" min="1" max="1825" />
          </div>

          <button type="submit" class="btn btn-success w-100 py-2 fw-semibold">
            <i class="bi bi-shield-check me-1"></i> Generate & Sign License
          </button>
        </form>
      </div>
    </div>
  </div>

  <!-- Licenses List -->
  <div class="col-12 col-xl-8">
    <div class="card shadow-sm border-0 h-100">
      <div class="card-header bg-body d-flex align-items-center justify-content-between py-3">
        <h5 class="card-title mb-0 fw-bold"><i class="bi bi-key-fill me-2 text-primary"></i>Issued Cryptographic Licenses</h5>
        <span class="badge bg-secondary"><?= count($licenses) ?> Total</span>
      </div>
      <div class="card-body p-0">
        <div class="table-responsive">
          <table class="table table-hover align-middle mb-0">
            <thead class="table-light">
              <tr>
                <th>License Key</th>
                <th>Tenant</th>
                <th>Plan</th>
                <th>Expires</th>
                <th>Status</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              <?php if (empty($licenses)): ?>
                <tr><td colspan="6" class="text-center text-muted py-4">No licenses issued yet</td></tr>
              <?php else: ?>
                <?php foreach ($licenses as $l): ?>
                  <tr>
                    <td><code class="fw-bold text-primary"><?= htmlspecialchars($l['license_key']) ?></code></td>
                    <td class="fw-semibold small"><?= htmlspecialchars($l['business_name'] ?? ('ID #' . $l['tenant_id'])) ?></td>
                    <td><span class="badge bg-secondary text-uppercase"><?= htmlspecialchars($l['plan_type']) ?></span></td>
                    <td class="small"><?= htmlspecialchars(substr($l['expires_at'] ?? 'Lifetime', 0, 10)) ?></td>
                    <td>
                      <span class="badge bg-<?= ($l['status'] === 'active') ? 'success' : 'danger' ?>">
                        <?= htmlspecialchars(strtoupper($l['status'])) ?>
                      </span>
                    </td>
                    <td>
                      <?php if ($l['status'] === 'active'): ?>
                        <form action="/admin/licenses/revoke/<?= $l['id'] ?>" method="POST" onsubmit="return confirm('Revoke this license immediately? Client workstation will be locked out.');">
                          <button type="submit" class="btn btn-sm btn-outline-danger">
                            <i class="bi bi-slash-circle me-1"></i> Revoke
                          </button>
                        </form>
                      <?php else: ?>
                        <span class="text-muted small">Locked</span>
                      <?php endif; ?>
                    </td>
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
