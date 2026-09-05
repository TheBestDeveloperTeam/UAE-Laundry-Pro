import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:laundrypro_uae/peripherals/features/printer/widgets/print_queue_panel.dart';
import 'package:laundrypro_uae/peripherals/features/printer/widgets/printer_panel.dart';
import 'package:laundrypro_uae/peripherals/features/scanner/screens/scanner_screen.dart';
import 'package:laundrypro_uae/peripherals/features/shared/providers/app_providers.dart';
import 'package:laundrypro_uae/peripherals/features/sql_database/screens/sql_database_screen.dart';

class DashboardShellScreen extends ConsumerStatefulWidget {
  const DashboardShellScreen({super.key});

  @override
  ConsumerState<DashboardShellScreen> createState() =>
      _DashboardShellScreenState();
}

class _DashboardShellScreenState extends ConsumerState<DashboardShellScreen> {
  int _index = 0;
  final FocusNode _focusNode = FocusNode(debugLabel: 'global-scanner-wedge');
  String _scaleJson = '{}';

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _navigateTo(int index) {
    if (_index == index) {
      return;
    }
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      _overviewPanel(),
      const ScannerScreen(),
      _scalePanel(),
      const PrinterPanel(),
      const PrintQueuePanel(),
      _cashDrawerPanel(),
      _machineIdentityPanel(),
      _logsPanel(),
      const SqlDatabaseScreen(),
    ];

    return KeyboardListener(
      autofocus: true,
      focusNode: _focusNode,
      onKeyEvent: ref.read(scannerControllerProvider),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Peripheral Framework Console'),
        ),
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _index,
              onDestinationSelected: _navigateTo,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.dashboard),
                  label: Text('Dashboard'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.qr_code_scanner),
                  label: Text('Scanner'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.scale),
                  label: Text('Scale'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.print),
                  label: Text('Printer'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.queue),
                  label: Text('Queue'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.point_of_sale),
                  label: Text('Drawer'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.memory),
                  label: Text('Identity'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.list_alt),
                  label: Text('Logs'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.storage),
                  label: Text('SQL'),
                ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: pages[_index]),
          ],
        ),
      ),
    );
  }

  Widget _overviewPanel() {
    final printers = ref.watch(printersProvider);
    final identity = ref.watch(machineIdentityProvider);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _statusCard(
              destinationIndex: 1,
              title: 'Scanner',
              subtitle: 'Live keyboard wedge listener active',
              icon: Icons.qr_code_scanner,
            ),
            _statusCard(
              destinationIndex: 2,
              title: 'Scale',
              subtitle: 'Protocol parser ready (STX/ETX capable)',
              icon: Icons.scale,
            ),
            _statusCard(
              destinationIndex: 3,
              title: 'Printer',
              subtitle: 'Spooler + TCP · QR/BC/HR · templates',
              icon: Icons.print,
            ),
            _statusCard(
              destinationIndex: 4,
              title: 'Queue',
              subtitle: 'Live print queue + retry/delete',
              icon: Icons.queue,
            ),
            _statusCard(
              destinationIndex: 5,
              title: 'Cash Drawer',
              subtitle: 'ESC/POS pulse via selected printer',
              icon: Icons.point_of_sale,
            ),
            _statusCard(
              destinationIndex: 8,
              title: 'SQL Database',
              subtitle: 'MySQL runtime connection & country query',
              icon: Icons.storage,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _navCard(
          destinationIndex: 3,
          title: 'Discovered Printers',
          subtitle: printers.when(
            data: (items) => Text('${items.length} printer(s) detected'),
            loading: () => const Text('Detecting...'),
            error: (e, _) => Text('Error: $e'),
          ),
          icon: Icons.print,
        ),
        _navCard(
          destinationIndex: 6,
          title: 'Machine Fingerprint',
          subtitle: identity.when(
            data: (value) =>
                Text(value['fingerprintSha256']?.toString() ?? 'n/a'),
            loading: () => const Text('Collecting...'),
            error: (e, _) => Text('Error: $e'),
          ),
          icon: Icons.memory,
        ),
      ],
    );
  }

  Widget _scalePanel() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Scale Protocol Test',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextField(
          onSubmitted: (value) {
            final bytes = utf8.encode(value);
            final parsed = ref.read(scaleParserProvider).parse(bytes);
            final encoded =
                ref.read(rawJsonEncoderProvider).convert(parsed.toJson());
            setState(() {
              _scaleJson = encoded;
            });
          },
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Paste raw scale packet and press Enter',
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: SelectableText(_scaleJson),
          ),
        ),
      ],
    );
  }

  Widget _cashDrawerPanel() {
    final selectedPrinter = ref.watch(selectedPrinterProvider);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Cash Drawer',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          selectedPrinter == null
              ? 'Select a printer first from the Printer panel.'
              : 'Pulse will be sent through "$selectedPrinter" via the '
                  'Windows Spooler (ESC/POS drawer kick command).',
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          icon: const Icon(Icons.point_of_sale),
          label: const Text('OPEN DRAWER'),
          onPressed: selectedPrinter == null
              ? null
              : () async {
                  final manager = ref.read(printerManagerProvider);
                  try {
                    await manager.printToInstalledPrinter(
                      printerName: selectedPrinter,
                      payload: manager.cashDrawerPulse(),
                    );
                    _toast('Drawer pulse sent via $selectedPrinter');
                  } catch (error) {
                    _toast('Drawer trigger failed: $error');
                  }
                },
        ),
      ],
    );
  }

  Widget _machineIdentityPanel() {
    final identity = ref.watch(machineIdentityProvider);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Machine Identity JSON',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        identity.when(
          data: (value) => Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SelectableText(
                const JsonEncoder.withIndent('  ').convert(value),
              ),
            ),
          ),
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text('Machine info failed: $e'),
        ),
      ],
    );
  }

  Widget _logsPanel() {
    final logs = ref.watch(logsProvider);
    return logs.when(
      data: (rows) => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: rows.length,
        itemBuilder: (context, index) {
          final row = rows[index];
          return Card(
            child: ListTile(
              title: Text('${row['level']} [${row['scope']}]'),
              subtitle: Text(row['message'].toString()),
              trailing: Text(row['createdAt'].toString().split('T').last),
            ),
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Log stream failed: $e')),
    );
  }

  Widget _statusCard({
    required int destinationIndex,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return SizedBox(
      width: 280,
      child: _navCard(
        destinationIndex: destinationIndex,
        title: title,
        subtitle: Text(subtitle),
        icon: icon,
      ),
    );
  }

  Widget _navCard({
    required int destinationIndex,
    required String title,
    required Widget subtitle,
    required IconData icon,
  }) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _navigateTo(destinationIndex),
        child: ListTile(
          leading: Icon(icon),
          title: Text(title),
          subtitle: subtitle,
          trailing: const Icon(Icons.chevron_right),
        ),
      ),
    );
  }

  void _toast(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }
}
