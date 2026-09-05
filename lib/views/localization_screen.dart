import 'package:flutter/material.dart';
import 'package:laundrypro_uae/core/localization_extension.dart';
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
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _select(String code) async {
    await _service.setCountry(code);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.t('saved'))));
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.t('country_profile'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _profiles.length,
              itemBuilder: (_, i) {
                final p = _profiles[i];
                return ListTile(
                  leading: Text(p['currency_symbol']?.toString() ?? '', style: const TextStyle(fontSize: 20)),
                  title: Text(p['name']?.toString() ?? ''),
                  subtitle: Text('${p['currency_code']} • ${p['timezone']}'),
                  trailing: ElevatedButton(onPressed: () => _select(p['code']?.toString() ?? ''), child: Text(l10n.t('select'))),
                );
              },
            ),
    );
  }
}
