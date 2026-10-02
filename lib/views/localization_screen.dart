import 'package:flutter/material.dart';
import 'package:laundrypro_uae/core/localization_extension.dart';
import 'package:laundrypro_uae/core/logger.dart';
import 'package:laundrypro_uae/core/theme.dart';
import 'package:laundrypro_uae/services/localization_service.dart';

class LocalizationScreen extends StatefulWidget {
  const LocalizationScreen({super.key, this.localizationService});
  final LocalizationService? localizationService;

  @override
  State<LocalizationScreen> createState() => _LocalizationScreenState();
}

class _LocalizationScreenState extends State<LocalizationScreen> {
  late final LocalizationService _service;
  List<Map<String, dynamic>> _profiles = [];
  bool _loading = true;
  String _activeCode = 'AE';

  @override
  void initState() {
    super.initState();
    _service = widget.localizationService ?? LocalizationService();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _profiles = await _service.profiles();
      if (_profiles.isNotEmpty) {
        final active = _profiles.firstWhere(
          (p) => p['is_default'] == 1 || p['code'] == 'AE',
          orElse: () => _profiles.first,
        );
        _activeCode = active['code']?.toString() ?? 'AE';
      }
    } catch (e, stack) {
      AppLogger.error('Failed to load localization profiles', tag: 'LocalizationScreen', error: e, stackTrace: stack);
    }
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _select(String code) async {
    setState(() => _loading = true);
    try {
      await _service.setCountry(code);
      _activeCode = code;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.t('country_switch_success')),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e, stack) {
      AppLogger.error('Failed to set country to $code', tag: 'LocalizationScreen', error: e, stackTrace: stack);
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('country_profile')),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Active summary banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryNavy,
                          AppTheme.primaryNavy.withValues(alpha: 0.85),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.public, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.t('country_active'),
                                style: const TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _activeCode == 'AE'
                                    ? 'United Arab Emirates (دولة الإمارات العربية المتحدة)'
                                    : _activeCode == 'SA'
                                        ? 'Kingdom of Saudi Arabia (المملكة العربية السعودية)'
                                        : _activeCode,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Profiles list
                  Text(
                    l10n.t('country_profile'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  ..._profiles.map((p) {
                    final code = p['code']?.toString() ?? '';
                    final isSelected = code == _activeCode;
                    final vatRate = p['vat_rate'] ?? (code == 'AE' ? '5%' : code == 'SA' ? '15%' : '0%');
                    final flag = code == 'AE' ? '🇦🇪' : code == 'SA' ? '🇸🇦' : '🌐';

                    return Card(
                      elevation: isSelected ? 3 : 1,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: isSelected
                            ? const BorderSide(color: AppTheme.accentTeal, width: 2)
                            : BorderSide(color: Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(flag, style: const TextStyle(fontSize: 28)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p['name']?.toString() ?? code,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      Text(
                                        '${p['currency_code']} (${p['currency_symbol']}) • ${p['timezone']}',
                                        style: const TextStyle(color: AppTheme.secondaryGrey, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.accentTeal.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      l10n.t('country_active'),
                                      style: const TextStyle(
                                        color: AppTheme.accentTeal,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.t('country_vat_rate'),
                                      style: const TextStyle(color: AppTheme.secondaryGrey, fontSize: 12),
                                    ),
                                    Text(
                                      '$vatRate',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.t('country_currency'),
                                      style: const TextStyle(color: AppTheme.secondaryGrey, fontSize: 12),
                                    ),
                                    Text(
                                      '${p['currency_code']}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.t('country_timezone'),
                                      style: const TextStyle(color: AppTheme.secondaryGrey, fontSize: 12),
                                    ),
                                    Text(
                                      p['timezone']?.toString().split('/').last ?? 'Asia',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isSelected ? AppTheme.accentTeal : AppTheme.primaryNavy,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: isSelected ? null : () => _select(code),
                                child: Text(isSelected ? l10n.t('country_active') : l10n.t('country_apply')),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }
}
