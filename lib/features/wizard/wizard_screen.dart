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

  List<Step> get _steps => [
    Step(
      title: const Text('Welcome'),
      isActive: _currentStep >= 0,
      state: _currentStep > 0 ? StepState.complete : StepState.indexed,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Welcome to LaundryPro UAE!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Text('Select your preferred language:'),
          const SizedBox(height: 8),
          Row(
            children: [
              ElevatedButton(onPressed: () {}, child: const Text('English')),
              const SizedBox(width: 16),
              OutlinedButton(onPressed: () {}, child: const Text('العربية')),
            ],
          )
        ],
      ),
    ),
    Step(
      title: const Text('Business Profile'),
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
      title: const Text('Hardware Setup'),
      isActive: _currentStep >= 2,
      state: _currentStep > 2 ? StepState.complete : StepState.indexed,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Printers & Cash Drawers', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.print, color: AppTheme.primaryBlue),
            title: const Text('Epson TM-T88VI (USB)'),
            subtitle: const Text('Status: Connected'),
            trailing: OutlinedButton(onPressed: () {}, child: const Text('Test Print')),
          ),
          const Divider(),
          const Text('Scanners', style: TextStyle(fontWeight: FontWeight.bold)),
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

  @override
  Widget build(BuildContext context) {
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
            if (_currentStep < _steps.length - 1) {
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
          steps: _steps,
        ),
      ),
    );
  }
}
