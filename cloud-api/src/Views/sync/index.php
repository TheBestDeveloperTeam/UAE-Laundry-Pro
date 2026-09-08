<div class="card shadow-sm border-0">
  <div class="card-header bg-body d-flex align-items-center justify-content-between py-3">
    <h5 class="card-title mb-0 fw-bold"><i class="bi bi-arrow-repeat me-2 text-info"></i>Multi-Tenant Sync Stream & Telemetry</h5>
    <span class="badge bg-info text-dark"><?= count($records) ?> Recent Records</span>
  </div>
  <div class="card-body p-0">
    <div class="table-responsive">
      <table class="table table-hover align-middle mb-0">
        <thead class="table-light">
          <tr>
            <th>ID</th>
            <th>Tenant</th>
            <th>Entity Type</th>
            <th>Local Entity ID</th>
            <th>Operation</th>
            <th>Payload Preview</th>
            <th>Received Timestamp</th>
          </tr>
        </thead>
        <tbody>
          <?php if (empty($records)): ?>
            <tr><td colspan="7" class="text-center text-muted py-4">No sync records in stream</td></tr>
          <?php else: ?>
            <?php foreach ($records as $r): ?>
              <tr>
                <td><span class="badge bg-secondary">#<?= $r['id'] ?></span></td>
                <td class="fw-semibold small"><?= htmlspecialchars($r['business_name'] ?? ('Tenant #' . $r['business_owner_id'])) ?></td>
                <td><span class="badge bg-primary-subtle text-primary border"><?= htmlspecialchars($r['entity_type']) ?></span></td>
                <td><span class="badge bg-light text-dark border">#<?= $r['entity_local_id'] ?></span></td>
                <td><span class="badge bg-info-subtle text-info fw-bold"><?= htmlspecialchars(strtoupper($r['operation'])) ?></span></td>
                <td>
                  <code class="small text-muted font-monospace" style="max-width: 320px; display: inline-block; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;">
                    <?= htmlspecialchars(is_string($r['payload']) ? $r['payload'] : json_encode($r['payload'])) ?>
                  </code>
                </td>
                <td class="small text-muted"><?= htmlspecialchars($r['created_at']) ?></td>
              </tr>
            <?php endforeach; ?>
          <?php endif; ?>
        </tbody>
      </table>
    </div>
  </div>
</div>
