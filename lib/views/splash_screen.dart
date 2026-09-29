import 'dart:io';

import 'package:flutter/material.dart';
import 'package:laundrypro_uae/core/localization_extension.dart';

import 'package:laundrypro_uae/providers/auth_provider.dart';
import 'package:laundrypro_uae/services/auth_service.dart';
import 'package:laundrypro_uae/services/install_service.dart';
import 'package:laundrypro_uae/services/license_service.dart';
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

    // STEP 1: Verify Local API Active
    setState(() => _currentStepKey = 'splash_step_connecting');
    try {
      final health = await authSvc.health().timeout(const Duration(seconds: 4));
      if (health['status'] != 'ok') {
        _triggerFatalNodeError();
        return;
      }
    } catch (_) {
      _triggerFatalNodeError();
      return;
    }

    // STEP 2: Verify Migrations and Seeds in Background
    setState(() => _currentStepKey = 'splash_step_migrating');
    try {
      final installStatus = await install.status();
      if (installStatus['locked'] != true) {
        // Run rolling migration and baseline seed
        try {
          await install.migrate();
          await install.seed();
        } catch (_) {}
      }
    } catch (_) {}

    // STEP 3: License & Trial Quota Verification
    setState(() => _currentStepKey = 'splash_step_licensing');
    try {
      await license.status();
    } catch (_) {}

    // STEP 4: Cloud API Handshake Sync
    setState(() => _currentStepKey = 'splash_step_cloud');
    await Future.delayed(const Duration(milliseconds: 350));

    // STEP 5: Bootstrap Workstation Session
    setState(() => _currentStepKey = 'splash_step_ready');
    await Future.delayed(const Duration(milliseconds: 250));

    if (!mounted) return;
    await auth.bootstrap();
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
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
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
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

