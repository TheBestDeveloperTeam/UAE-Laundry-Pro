<!doctype html>
<html lang="en">
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Super-Admin Login - LaundryPro Cloud</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@fontsource/source-sans-3@5.0.12/index.css" />
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.13.1/font/bootstrap-icons.min.css" />
    <link rel="stylesheet" href="/assets/css/adminlte.min.css" />
    <style>
      body {
        background: linear-gradient(135deg, #0d0f17 0%, #1b1035 50%, #4c1d95 100%);
        min-height: 100vh;
        display: flex;
        align-items: center;
        justify-content: center;
        font-family: 'Source Sans 3', 'Inter', sans-serif;
      }
      .login-card {
        border-radius: 16px;
        box-shadow: 0 15px 35px rgba(0,0,0,0.5);
        border: 1px solid rgba(255, 255, 255, 0.1);
      }
      .btn-primary {
        background-color: #7c3aed !important;
        border-color: #7c3aed !important;
      }
      .btn-primary:hover {
        background-color: #6d28d9 !important;
        border-color: #6d28d9 !important;
      }
    </style>
  </head>
  <body>
    <div class="login-box" style="width: 420px; max-width: 90%;">
      <div class="card login-card card-outline card-primary bg-white">
        <div class="card-header text-center py-4 border-bottom-0">
          <div class="d-flex align-items-center justify-content-center mb-2">
            <i class="bi bi-cloud-check-fill fs-1 me-2" style="color: #7c3aed;"></i>
            <h2 class="mb-0 fw-bold">Laundry<span style="color: #7c3aed;">Pro</span></h2>
          </div>
          <span class="badge bg-dark text-uppercase px-3 py-1" style="background-color: #1e1145 !important;">Super-Admin Central Cloud</span>
        </div>

        <div class="card-body p-4 pt-2">
          <?php if (!empty($error)): ?>
            <div class="alert alert-danger py-2 px-3 small mb-3">
              <i class="bi bi-exclamation-triangle-fill me-1"></i> <?= htmlspecialchars($error) ?>
            </div>
          <?php endif; ?>

          <p class="login-box-msg text-muted small text-center mb-4">Enter credentials to authenticate into the super-admin console</p>

          <form action="/admin/login" method="POST">
            <?= \LaundryPro\Cloud\Middleware\CsrfMiddleware::field() ?>
            <div class="mb-3">
              <label class="form-label small fw-semibold">Username</label>
              <div class="input-group">
                <input type="text" name="username" class="form-control" placeholder="superadmin" required autofocus />
                <span class="input-group-text"><i class="bi bi-person"></i></span>
              </div>
            </div>

            <div class="mb-4">
              <label class="form-label small fw-semibold">Password</label>
              <div class="input-group">
                <input type="password" name="password" class="form-control" placeholder="••••••••••••" required />
                <span class="input-group-text"><i class="bi bi-lock"></i></span>
              </div>
            </div>

            <button type="submit" class="btn btn-primary w-100 py-2 fw-semibold shadow-sm">
              <i class="bi bi-shield-lock me-1"></i> Sign In to Cloud Portal
            </button>
          </form>

          <div class="text-center mt-4 border-top pt-3">
            <small class="text-muted">&copy; 2026 Magnificent Solution &bull; UAE Laundry Pro</small>
          </div>
        </div>
      </div>
    </div>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.8/dist/js/bootstrap.bundle.min.js"></script>
  </body>
</html>
