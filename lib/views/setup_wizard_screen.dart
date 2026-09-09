import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:laundrypro_uae/core/localization_extension.dart';
import 'package:laundrypro_uae/providers/locale_provider.dart';
import 'package:laundrypro_uae/services/global_config_service.dart';
import 'package:laundrypro_uae/services/install_service.dart';
import 'package:laundrypro_uae/services/license_service.dart';
import 'package:laundrypro_uae/services/system_guard_service.dart';
import 'package:provider/provider.dart';

class SetupWizardScreen extends StatefulWidget {
  const SetupWizardScreen({
    super.key,
    this.installService,
    this.licenseService,
  });

  final InstallService? installService;
  final LicenseService? licenseService;

  @override
  State<SetupWizardScreen> createState() => _SetupWizardScreenState();
}

class _SetupWizardScreenState extends State<SetupWizardScreen> {
  late final InstallService _install;
  late final LicenseService _license;

  int _currentStep = 0;
  bool _loading = false;
  Map<String, dynamic> _status = {};

  // Form Controllers
  final _businessNameController = TextEditingController(text: 'LaundryPro UAE');
  final _phoneController = TextEditingController(text: '+971 4 123 4567');
  final _emailController = TextEditingController(text: 'contact@laundrypro.ae');
  final _addressController = TextEditingController(text: 'Al Quoz Industrial Area 3, Dubai');
  String _selectedEmirate = 'Dubai';

  // Localization & Currency
  String _selectedLanguage = 'en';
  String _selectedCurrency = 'AED';

  // Sequences
  final _invPrefixController = TextEditingController(text: 'INV-');
  final _recPrefixController = TextEditingController(text: 'REC-');
  final _chlPrefixController = TextEditingController(text: 'CHL-');
  final _grnPrefixController = TextEditingController(text: 'GRN-');

  // Admin Account
  final _adminUsernameController = TextEditingController(text: 'admin');
  final _adminPasswordController = TextEditingController(text: 'admin123');
  final _installSecretController = TextEditingController(text: 'change_this_install_secret_before_production');

  // Backup & Storage
  late final TextEditingController _backupPathController;

  // Hardware & Printers
  String _selectedPrinter = 'thermal_80mm';

  // Terminal & Hardware Identity
  String _machineCode = 'UMAC-CHECKING';

  // License Key
  final _licenseKeyController = TextEditingController();

  final List<String> _emirates = [
    'Abu Dhabi',
    'Dubai',
    'Sharjah',
    'Ajman',
    'Umm Al Quwain',
    'Ras Al Khaimah',
    'Fujairah',
  ];

  @override
  void initState() {
    super.initState();
    _install = widget.installService ?? InstallService();
    _license = widget.licenseService ?? LicenseService();
    _backupPathController = TextEditingController(text: GlobalConfigService().backupPath);
    _loadInitial();
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _invPrefixController.dispose();
    _recPrefixController.dispose();
    _chlPrefixController.dispose();
    _grnPrefixController.dispose();
    _adminUsernameController.dispose();
    _adminPasswordController.dispose();
    _installSecretController.dispose();
    _backupPathController.dispose();
    _licenseKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    setState(() => _loading = true);
    try {
      _status = await _install.status();
      final hw = await SystemGuardService.getHardwareInfo();
      _machineCode = hw.machineCode;
    } catch (_) {}
    if (mounted) {
      setState(() => _loading = false);
      if (_status['locked'] == true) {
        context.go('/login');
      }
    }
  }

  Future<void> _executeInstallPipeline() async {
    setState(() => _loading = true);
    final secret = _installSecretController.text.trim();
    final adminPass = _adminPasswordController.text.trim();

    try {
      // 1. Run migrations if pending
      if (_status['migrations_pending'] != 0) {
        await _install.migrate(installToken: secret);
      }

      // 2. Seed database & create default users
      await _install.seed(adminPassword: adminPass.isNotEmpty ? adminPass : 'admin123', installToken: secret);

      // 3. Update paths via GlobalConfigService
      await GlobalConfigService().updatePath('BACKUP_PATH', _backupPathController.text.trim());

      // 4. Activate license if provided
      final licenseKey = _licenseKeyController.text.trim();
      if (licenseKey.isNotEmpty) {
        try {
          await _license.activate(licenseKey);
        } catch (_) {}
      }

      // 5. Lock installer
      await _install.complete(installToken: secret);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF0D6E6E),
          content: Text('Installation & initial setup completed successfully!'),
        ),
      );
      context.go('/login');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade800,
            content: Text('Installation error: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('setup_wizard')),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(
                'Workstation ID: $_machineCode',
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Stepper(
              type: StepperType.horizontal,
              currentStep: _currentStep,
              onStepContinue: () {
                if (_currentStep < 7) {
                  setState(() => _currentStep += 1);
                } else {
                  _executeInstallPipeline();
                }
              },
              onStepCancel: () {
                if (_currentStep > 0) {
                  setState(() => _currentStep -= 1);
                }
              },
              steps: [
                // Step 1: Business Profile
                Step(
                  title: const Text('Business'),
                  isActive: _currentStep >= 0,
                  content: Column(
                    children: [
                      TextField(
                        controller: _businessNameController,
                        decoration: InputDecoration(labelText: l10n.t('business_name')),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _phoneController,
                              decoration: InputDecoration(labelText: l10n.t('phone')),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _emailController,
                              decoration: const InputDecoration(labelText: 'Email'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedEmirate,
                        decoration: const InputDecoration(labelText: 'Emirate'),
                        items: _emirates.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedEmirate = val);
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _addressController,
                        decoration: const InputDecoration(labelText: 'Physical Address'),
                      ),
                    ],
                  ),
                ),

                // Step 2: Language & Currency
                Step(
                  title: const Text('Locale'),
                  isActive: _currentStep >= 1,
                  content: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: _selectedLanguage,
                        decoration: InputDecoration(labelText: l10n.t('language')),
                        items: [
                          DropdownMenuItem(value: 'en', child: Text(l10n.t('english'))),
                          DropdownMenuItem(value: 'ar', child: Text(l10n.t('arabic'))),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedLanguage = val);
                            context.read<LocaleProvider>().setLocale(val);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedCurrency,
                        decoration: const InputDecoration(labelText: 'Currency'),
                        items: const [
                          DropdownMenuItem(value: 'AED', child: Text('UAE Dirham (AED / Fils)')),
                          DropdownMenuItem(value: 'SAR', child: Text('Saudi Riyal (SAR / Halala)')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedCurrency = val);
                        },
                      ),
                    ],
                  ),
                ),

                // Step 3: Document Number Prefixes
                Step(
                  title: const Text('Prefixes'),
                  isActive: _currentStep >= 2,
                  content: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _invPrefixController,
                              decoration: const InputDecoration(labelText: 'Invoice Prefix (e.g. INV-)'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _recPrefixController,
                              decoration: const InputDecoration(labelText: 'Receipt Prefix (e.g. REC-)'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _chlPrefixController,
                              decoration: const InputDecoration(labelText: 'Challan Prefix (e.g. CHL-)'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _grnPrefixController,
                              decoration: const InputDecoration(labelText: 'GRN Prefix (e.g. GRN-)'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Step 4: Administrator Account
                Step(
                  title: const Text('Admin'),
                  isActive: _currentStep >= 3,
                  content: Column(
                    children: [
                      TextField(
                        controller: _adminUsernameController,
                        decoration: InputDecoration(labelText: l10n.t('username')),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _adminPasswordController,
                        obscureText: true,
                        decoration: InputDecoration(labelText: l10n.t('password')),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _installSecretController,
                        decoration: const InputDecoration(
                          labelText: 'API Installation Secret (from api/.env)',
                          helperText: 'Required to authorize database migrations and initial locks',
                        ),
                      ),
                    ],
                  ),
                ),

                // Step 5: Backup Location
                Step(
                  title: const Text('Backup'),
                  isActive: _currentStep >= 4,
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _backupPathController,
                        decoration: const InputDecoration(
                          labelText: 'Canonical Backup Directory (BACKUP_PATH)',
                          helperText: 'Defaults to C:/LaundryPro/backups/ with automatic write verification',
                        ),
                      ),
                    ],
                  ),
                ),

                // Step 6: Printer Defaults
                Step(
                  title: const Text('Printers'),
                  isActive: _currentStep >= 5,
                  content: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: _selectedPrinter,
                        decoration: const InputDecoration(labelText: 'Primary Slip Printer Default'),
                        items: const [
                          DropdownMenuItem(value: 'thermal_80mm', child: Text('Thermal Roll Paper (80mm / 48 chars)')),
                          DropdownMenuItem(value: 'thermal_58mm', child: Text('Thermal Roll Paper (58mm / 32 chars)')),
                          DropdownMenuItem(value: 'a4_laser', child: Text('Laser/Inkjet A4 Standard')),
                          DropdownMenuItem(value: 'dot_matrix', child: Text('Dot-Matrix 80-Col (Carbon Copy)')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedPrinter = val);
                        },
                      ),
                    ],
                  ),
                ),

                // Step 7: Workstation & Terminal
                Step(
                  title: const Text('Terminal'),
                  isActive: _currentStep >= 6,
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Hardware Binding & Installation Identification:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: SelectableText(
                          _machineCode,
                          style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),

                // Step 8: License Activation
                Step(
                  title: const Text('License'),
                  isActive: _currentStep >= 7,
                  content: Column(
                    children: [
                      TextField(
                        controller: _licenseKeyController,
                        decoration: InputDecoration(
                          labelText: l10n.t('license_key'),
                          hintText: 'Optional: Enter activation key or leave blank for 7-day evaluation',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
