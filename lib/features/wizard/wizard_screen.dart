import 'package:laundrypro_uae/core/localization_extension.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';

class WizardScreen extends StatefulWidget {
  const WizardScreen({super.key});

  @override
  State<WizardScreen> createState() => _WizardScreenState();
}

class _WizardScreenState extends State<WizardScreen> {
  int _currentStep = 0;

  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _trnController = TextEditingController();

  List<Step> _steps(BuildContext context) {
    final l10n = context.l10n;
    return [
    Step(
      title: Text(l10n.t('wizard_welcome')),
      isActive: _currentStep >= 0,
      state: _currentStep > 0 ? StepState.complete : StepState.indexed,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.t('wizard_welcome_msg'), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text(l10n.t('wizard_select_language')),
          const SizedBox(height: 8),
          Row(
            children: [
              ElevatedButton(onPressed: () {}, child: Text(l10n.t('english'))),
              const SizedBox(width: 16),
              OutlinedButton(onPressed: () {}, child: const Text('العربية')),
            ],
          )
        ],
      ),
    ),
    Step(
      title: Text(l10n.t('wizard_business_profile')),
      isActive: _currentStep >= 1,
      state: _currentStep > 1 ? StepState.complete : StepState.indexed,
      content: Column(
        children: [
          TextField(
            controller: _businessNameController,
            decoration: const InputDecoration(labelText: 'Business Name (e.g., Al Noor Laundry)'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _trnController,
            decoration: const InputDecoration(labelText: 'Tax Registration Number (TRN)'),
          ),
        ],
      ),
    ),
    Step(
      title: Text(l10n.t('wizard_hardware_setup')),
      isActive: _currentStep >= 2,
      state: _currentStep > 2 ? StepState.complete : StepState.indexed,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.t('wizard_printers_drawers'), style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.print, color: AppTheme.primaryBlue),
            title: const Text('Epson TM-T88VI (USB)'),
            subtitle: Text(l10n.t('wizard_status_connected')),
            trailing: OutlinedButton(onPressed: () {}, child: Text(l10n.t('wizard_test_print'))),
          ),
          const Divider(),
          Text(l10n.t('wizard_scanners'), style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.qr_code_scanner, color: AppTheme.primaryBlue),
            title: const Text('Zebra DS2208 (USB Keyboard)'),
            subtitle: const Text('Status: Connected'),
            trailing: OutlinedButton(onPressed: () {}, child: const Text('Test Scan')),
          )
        ],
      ),
    ),
    Step(
      title: const Text('Admin Account'),
      isActive: _currentStep >= 3,
      state: _currentStep == 3 ? StepState.editing : StepState.indexed,
      content: const Column(
        children: [
          TextField(
            decoration: InputDecoration(labelText: 'Admin Username / Email'),
          ),
          SizedBox(height: 16),
          TextField(
            obscureText: true,
            decoration: InputDecoration(labelText: 'Password'),
          ),
        ],
      ),
    ),
  ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: const Text('LaundryPro Setup Wizard'),
        centerTitle: false,
      ),
      body: Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: AppTheme.primaryBlue,
          ),
        ),
        child: Stepper(
          type: StepperType.horizontal,
          currentStep: _currentStep,
          onStepContinue: () {
            if (_currentStep < _steps(context).length - 1) {
              setState(() => _currentStep += 1);
            } else {
              // Finalize and navigate to POS
              context.go('/pos');
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) {
              setState(() => _currentStep -= 1);
            }
          },
          steps: _steps(context),
        ),
      ),
    );
  }
}
