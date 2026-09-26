<?php
$title = "Local Master Dashboard";
ob_start();
?>
<div class="row">
  <div class="col-lg-3 col-6">
    <div class="small-box bg-purple" style="background-color: #6a1b9a !important;">
      <div class="inner">
        <h3><?php echo $newOrders ?? 0; ?></h3>
        <p>New Orders (Today)</p>
      </div>
      <div class="icon">
        <i class="fas fa-shopping-cart"></i>
      </div>
      <a href="#" class="small-box-footer">More info <i class="fas fa-arrow-circle-right"></i></a>
    </div>
  </div>
  <div class="col-lg-3 col-6">
    <div class="small-box bg-info">
      <div class="inner">
        <h3><?php echo $syncStatus ?? 100; ?><sup style="font-size: 20px">%</sup></h3>
        <p>Sync Status</p>
      </div>
      <div class="icon">
        <i class="fas fa-sync"></i>
      </div>
      <a href="#" class="small-box-footer">More info <i class="fas fa-arrow-circle-right"></i></a>
    </div>
  </div>
</div>
<?php
$content = ob_get_clean();
require __DIR__ . '/layout.php';
