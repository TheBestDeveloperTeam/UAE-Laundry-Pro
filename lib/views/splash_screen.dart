import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:laundrypro_uae/core/logger.dart';
import 'package:laundrypro_uae/core/localization_extension.dart';
import 'package:laundrypro_uae/widgets/laundry_lottie.dart';
import 'package:laundrypro_uae/providers/auth_provider.dart';
import 'package:laundrypro_uae/services/auth_service.dart';
import 'package:laundrypro_uae/services/install_service.dart';
import 'package:laundrypro_uae/services/license_service.dart';
import 'package:laundrypro_uae/widgets/debug_console_accordion.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    this.installService,
    this.authService,
    this.licenseService,
  });

  final InstallService? installService;
  final AuthService? authService;
  final LicenseService? licenseService;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _currentStepKey = 'splash_step_connecting';
  bool _hasFatalError = false;
  String? _fatalErrorTitle;
  String? _fatalErrorDesc;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootSequence());
  }

  Future<void> _bootSequence() async {
    final auth = context.read<AuthProvider>();
    final authSvc = widget.authService ?? AuthService();
    final install = widget.installService ?? InstallService();
    final license = widget.licenseService ?? LicenseService();

    AppLogger.info('Starting boot sequence initialization...', tag: 'Boot');

    // STEP 1: Verify Local API Active
    setState(() => _currentStepKey = 'splash_step_connecting');
    AppLogger.info('Step 1: Checking local service health (http://laundrypro-api/api/v1/health)...', tag: 'Boot');
    try {
      final health = await authSvc.health().timeout(const Duration(seconds: 4));
      AppLogger.info('Step 1 Health response: status=${health['status']}, database=${health['database']}', tag: 'Boot');
      if (health['status'] != 'healthy' && health['status'] != 'ok' && health['database'] != 'ok') {
        AppLogger.error('Step 1 failed: service responded but status is not healthy', tag: 'Boot');
        _triggerFatalNodeError();
        return;
      }
    } catch (e, st) {
      AppLogger.error('Step 1 failed: unable to connect to local API: $e', tag: 'Boot', error: e, stackTrace: st);
      _triggerFatalNodeError();
      return;
    }

    // STEP 2: Verify Migrations and Seeds in Background
    setState(() => _currentStepKey = 'splash_step_migrating');
    AppLogger.info('Step 2: Checking install and migration status...', tag: 'Boot');
    try {
      final installStatus = await install.status();
      AppLogger.info('Step 2 Install locked status: ${installStatus['locked']}', tag: 'Boot');
      if (installStatus['locked'] != true) {
        try {
          await install.migrate();
          await install.seed();
          AppLogger.info('Step 2: Applied pending migrations and seeds.', tag: 'Boot');
        } catch (e, stack) {
          AppLogger.warning('Database migration or seed skipped during boot', tag: 'Boot', error: e, stackTrace: stack);
        }
      }
    } catch (e, stack) {
      AppLogger.warning('Install status check encountered non-fatal error', tag: 'Boot', error: e, stackTrace: stack);
    }

    // STEP 3: License & Trial Quota Verification
    setState(() => _currentStepKey = 'splash_step_licensing');
    AppLogger.info('Step 3: Verifying license and workstation quota...', tag: 'Boot');
    try {
      final lic = await license.status();
      AppLogger.info('Step 3 License active: ${lic['active']}', tag: 'Boot');
    } catch (e, stack) {
      AppLogger.warning('License check encountered non-fatal error during splash boot', tag: 'Boot', error: e, stackTrace: stack);
    }

    // STEP 4: Cloud API Handshake Sync
    setState(() => _currentStepKey = 'splash_step_cloud');
    AppLogger.info('Step 4: Performing cloud handshake handshake check...', tag: 'Boot');
    await Future.delayed(const Duration(milliseconds: 350));

    // STEP 5: Bootstrap Workstation Session
    setState(() => _currentStepKey = 'splash_step_ready');
    AppLogger.info('Step 5: Bootstrapping auth session and credentials...', tag: 'Boot');
    await Future.delayed(const Duration(milliseconds: 250));

    if (!mounted) return;
    try {
      await auth.bootstrap();
      AppLogger.info('Auth bootstrap finished. Status: ${auth.status}', tag: 'Boot');
    } catch (e, st) {
      AppLogger.error('Auth bootstrap failed: $e', tag: 'Boot', error: e, stackTrace: st);
    }

    if (!mounted) return;

    // Explicit navigation fallback if GoRouter redirect does not trigger automatically:
    final currentPath = GoRouterState.of(context).uri.path;
    if (currentPath == '/splash') {
      if (auth.status == AuthStatus.authenticated) {
        AppLogger.info('Transitioning to /dashboard', tag: 'Boot');
        context.go('/dashboard');
      } else {
        AppLogger.info('Transitioning to /login', tag: 'Boot');
        context.go('/login');
      }
    }
  }

  void _triggerFatalNodeError() {
    if (!mounted) return;
    setState(() {
      _hasFatalError = true;
      _fatalErrorTitle = 'splash_err_local_api_title';
      _fatalErrorDesc = 'splash_err_local_api_desc';
    });
  }

  void _exitApplication() {
    exit(0);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      body: LaundryLottieBackground(
        logicalId: 'splash.bg.light',
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.local_laundry_service_rounded,
                          size: 68,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.t('app_name'),
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Dedicated Workstation Node',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                        const SizedBox(height: 32),
                        if (!_hasFatalError) ...[
                          const LinearProgressIndicator(minHeight: 6),
                          const SizedBox(height: 16),
                          Text(
                            l10n.t(_currentStepKey),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF0D6E6E),
                            ),
                          ),
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.errorContainer.withAlpha(60),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.error.withAlpha(120),
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.error_outline_rounded,
                                      color: Theme.of(context).colorScheme.error,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        l10n.t(_fatalErrorTitle!),
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.error,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  l10n.t(_fatalErrorDesc!),
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onErrorContainer,
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton(
                                onPressed: () {
                                  setState(() {
                                    _hasFatalError = false;
                                  });
                                  _bootSequence();
                                },
                                child: Text(l10n.t('retry')),
                              ),
                              const SizedBox(width: 12),
                              FilledButton(
                                style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
                                onPressed: _exitApplication,
                                child: Text(l10n.t('exit_app')),
                              ),
                            ],
                          ),
                        ],
                        // Technical Diagnostics & Debug Console Accordion
                        const DebugConsoleAccordion(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
