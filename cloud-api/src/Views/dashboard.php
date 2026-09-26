<?php
$title = "Super-Admin Global Dashboard";
ob_start();
?>
<div class="row">
  <div class="col-lg-3 col-6">
    <div class="small-box bg-purple" style="background-color: #6a1b9a !important;">
      <div class="inner">
        <h3><?php echo $stats['tenants_count'] ?? 0; ?></h3>
        <p>Active Tenants / Nodes</p>
      </div>
      <div class="icon">
        <i class="fas fa-network-wired"></i>
      </div>
      <a href="#" class="small-box-footer">View nodes <i class="fas fa-arrow-circle-right"></i></a>
    </div>
  </div>
  <div class="col-lg-3 col-6">
    <div class="small-box bg-success">
      <div class="inner">
        <h3><?php echo number_format($stats['sync_records_count'] ?? 0); ?></h3>
        <p>Total Sync Packets Processed</p>
      </div>
      <div class="icon">
        <i class="fas fa-server"></i>
      </div>
      <a href="#" class="small-box-footer">View engine <i class="fas fa-arrow-circle-right"></i></a>
    </div>
  </div>
</div>
<?php
$content = ob_get_clean();
require __DIR__ . '/layout.php';
