import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:laundrypro_uae/core/logger.dart';
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
    final l10n = context.l10n;
    setState(() => _loading = true);
    try {
      _status = await _install.status();
      final hw = await SystemGuardService.getHardwareInfo();
      _machineCode = hw.machineCode;
    } catch (e, stack) {
      AppLogger.warning('Failed to inspect initial setup status or hardware code', tag: 'SetupWizardScreen', error: e, stackTrace: stack);
    }
    if (mounted) {
      setState(() => _loading = false);
      if (_status['locked'] == true) {
        context.go('/login');
      }
    }
  }

  Future<void> _executeInstallPipeline() async {
    final l10n = context.l10n;
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
        } catch (e, stack) {
          AppLogger.warning('License activation failed during initial setup', tag: 'SetupWizardScreen', error: e, stackTrace: stack);
        }
      }

      // 5. Lock installer
      await _install.complete(installToken: secret);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Color(0xFF0D6E6E),
          content: Text(l10n.t('wizard_install_complete')),
        ),
      );
      context.go('/login');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade800,
            content: Text(l10n.t('wizard_install_error').replaceAll('{error}', e.toString())),
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
                  title: Text(l10n.t('wizard_step_business')),
                  isActive: _currentStep >= 0,
                  content: Column(
                    children: [
                      TextField(
                        controller: _businessNameController,
                        decoration: InputDecoration(labelText: l10n.t('business_name')),
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _phoneController,
                              decoration: InputDecoration(labelText: l10n.t('phone')),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _emailController,
                              decoration: InputDecoration(labelText: l10n.t('wizard_email_label')),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedEmirate,
                        decoration: InputDecoration(labelText: l10n.t('wizard_emirate_label')),
                        items: _emirates.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedEmirate = val);
                        },
                      ),
                      SizedBox(height: 12),
                      TextField(
                        controller: _addressController,
                        decoration: InputDecoration(labelText: l10n.t('wizard_address_label')),
                      ),
                    ],
                  ),
                ),

                // Step 2: Language & Currency
                Step(
                  title: Text(l10n.t('wizard_step_locale')),
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
                      SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedCurrency,
                        decoration: InputDecoration(labelText: l10n.t('wizard_currency_label')),
                        items: [DropdownMenuItem(value: 'AED', child: Text(l10n.t('wizard_currency_aed'))),
                          DropdownMenuItem(value: 'SAR', child: Text(l10n.t('wizard_currency_sar'))),
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
                  title: Text(l10n.t('wizard_step_prefixes')),
                  isActive: _currentStep >= 2,
                  content: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _invPrefixController,
                              decoration: InputDecoration(labelText: l10n.t('wizard_invoice_prefix')),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _recPrefixController,
                              decoration: InputDecoration(labelText: l10n.t('wizard_receipt_prefix')),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _chlPrefixController,
                              decoration: InputDecoration(labelText: l10n.t('wizard_challan_prefix')),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _grnPrefixController,
                              decoration: InputDecoration(labelText: l10n.t('wizard_grn_prefix')),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Step 4: Administrator Account
                Step(
                  title: Text(l10n.t('wizard_step_admin')),
                  isActive: _currentStep >= 3,
                  content: Column(
                    children: [
                      TextField(
                        controller: _adminUsernameController,
                        decoration: InputDecoration(labelText: l10n.t('username')),
                      ),
                      SizedBox(height: 12),
                      TextField(
                        controller: _adminPasswordController,
                        obscureText: true,
                        decoration: InputDecoration(labelText: l10n.t('password')),
                      ),
                      SizedBox(height: 12),
                      TextField(
                        controller: _installSecretController,
                        decoration: InputDecoration(labelText: l10n.t('wizard_api_secret'),
                          helperText: 'Required to authorize database migrations and initial locks',
                        ),
                      ),
                    ],
                  ),
                ),

                // Step 5: Backup Location
                Step(
                  title: Text(context.l10n.t('backup')),
                  isActive: _currentStep >= 4,
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _backupPathController,
                        decoration: InputDecoration(labelText: l10n.t('wizard_backup_dir'),
                          helperText: 'Defaults to C:/LaundryPro/backups/ with automatic write verification',
                        ),
                      ),
                    ],
                  ),
                ),

                // Step 6: Printer Defaults
                Step(
                  title: Text(l10n.t('wizard_step_printers')),
                  isActive: _currentStep >= 5,
                  content: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: _selectedPrinter,
                        decoration: InputDecoration(labelText: l10n.t('wizard_printer_label')),
                        items: [DropdownMenuItem(value: 'thermal_80mm', child: Text(l10n.t('wizard_printer_80mm'))),
                          DropdownMenuItem(value: 'thermal_58mm', child: Text(l10n.t('wizard_printer_58mm'))),
                          DropdownMenuItem(value: 'a4_laser', child: Text(l10n.t('wizard_printer_a4'))),
                          DropdownMenuItem(value: 'dot_matrix', child: Text(l10n.t('wizard_printer_dot'))),
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
                  title: Text(l10n.t('wizard_step_terminal')),
                  isActive: _currentStep >= 6,
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hardware Binding & Installation Identification:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: SelectableText(
                          _machineCode,
                          style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),

                // Step 8: License Activation
                Step(
                  title: Text(l10n.t('wizard_step_license')),
                  isActive: _currentStep >= 7,
                  content: Column(
                    children: [
                      TextField(
                        controller: _licenseKeyController,
                        decoration: InputDecoration(
                          labelText: l10n.t('license_key'),
                          hintText: l10n.t('wizard_license_hint'),
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
