import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:laundrypro_uae/core/localization_extension.dart';
import 'package:laundrypro_uae/providers/auth_provider.dart';
import 'package:laundrypro_uae/services/install_service.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.installService});

  final InstallService? installService;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final install = widget.installService ?? InstallService();
      final auth = context.read<AuthProvider>();
      try {
        final status = await install.status();
        if (!mounted) return;
        if (status['locked'] != true) {
          context.go('/setup');
          return;
        }
      } catch (_) {}

      if (!mounted) return;
      await auth.bootstrap();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.local_laundry_service, size: 72),
            const SizedBox(height: 16),
            Text(l10n.t('app_name'), style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text(l10n.t('loading')),
          ],
        ),
      ),
    );
  }
}
