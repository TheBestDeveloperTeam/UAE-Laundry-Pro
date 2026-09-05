import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:laundrypro_uae/core/localization_extension.dart';
import 'package:laundrypro_uae/peripherals/features/printer/widgets/print_queue_panel.dart';
import 'package:laundrypro_uae/peripherals/features/printer/widgets/printer_panel.dart';
import 'package:laundrypro_uae/peripherals/features/scanner/screens/scanner_screen.dart';
import 'package:laundrypro_uae/peripherals/features/shared/providers/app_providers.dart';
import 'package:laundrypro_uae/peripherals/features/sql_database/screens/sql_database_screen.dart';

class PeripheralsScreen extends ConsumerStatefulWidget {
  const PeripheralsScreen({super.key});

  @override
  ConsumerState<PeripheralsScreen> createState() => _PeripheralsScreenState();
}

class _PeripheralsScreenState extends ConsumerState<PeripheralsScreen> {
  int _index = 0;
  final FocusNode _focusNode = FocusNode(debugLabel: 'peripherals-scanner-wedge');
  String _scaleJson = '{}';

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _navigateTo(int index) {
    if (_index == index) return;
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pages = <Widget>[
      _overviewPanel(l10n),
      const ScannerScreen(),
      _scalePanel(l10n),
      const PrinterPanel(),
      const PrintQueuePanel(),
      _cashDrawerPanel(l10n),
      _machineIdentityPanel(l10n),
      _logsPanel(),
      const SqlDatabaseScreen(),
    ];

    return KeyboardListener(
      autofocus: true,
      focusNode: _focusNode,
      onKeyEvent: ref.read(scannerControllerProvider),
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.t('peripherals'))),
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _index,
              onDestinationSelected: _navigateTo,
              labelType: NavigationRailLabelType.all,
              destinations: [
                NavigationRailDestination(
                  icon: const Icon(Icons.dashboard),
                  label: Text(l10n.t('peripherals_overview')),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.qr_code_scanner),
                  label: Text(l10n.t('peripherals_scanner')),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.scale),
                  label: Text(l10n.t('peripherals_scale')),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.print),
                  label: Text(l10n.t('peripherals_printer')),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.queue),
                  label: Text(l10n.t('peripherals_queue')),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.point_of_sale),
                  label: Text(l10n.t('peripherals_drawer')),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.memory),
                  label: Text(l10n.t('peripherals_identity')),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.list_alt),
                  label: Text(l10n.t('peripherals_logs')),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.storage),
                  label: Text(l10n.t('peripherals_sql')),
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

  Widget _overviewPanel(dynamic l10n) {
    final printers = ref.watch(printersProvider);
    final identity = ref.watch(machineIdentityProvider);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          l10n.t('peripherals_dev_note'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _statusCard(
              destinationIndex: 1,
              title: l10n.t('peripherals_scanner'),
              subtitle: l10n.t('peripherals_scanner_hint'),
              icon: Icons.qr_code_scanner,
            ),
            _statusCard(
              destinationIndex: 2,
              title: l10n.t('peripherals_scale'),
              subtitle: l10n.t('peripherals_scale_hint'),
              icon: Icons.scale,
            ),
            _statusCard(
              destinationIndex: 3,
              title: l10n.t('peripherals_printer'),
              subtitle: l10n.t('peripherals_printer_hint'),
              icon: Icons.print,
            ),
            _statusCard(
              destinationIndex: 4,
              title: l10n.t('peripherals_queue'),
              subtitle: l10n.t('peripherals_queue_hint'),
              icon: Icons.queue,
            ),
            _statusCard(
              destinationIndex: 5,
              title: l10n.t('peripherals_drawer'),
              subtitle: l10n.t('peripherals_drawer_hint'),
              icon: Icons.point_of_sale,
            ),
            _statusCard(
              destinationIndex: 8,
              title: l10n.t('peripherals_sql'),
              subtitle: l10n.t('peripherals_sql_hint'),
              icon: Icons.storage,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _navCard(
          destinationIndex: 3,
          title: l10n.t('peripherals_discovered_printers'),
          subtitle: printers.when(
            data: (items) => Text('${items.length}'),
            loading: () => Text(l10n.t('loading')),
            error: (e, _) => Text('$e'),
          ),
          icon: Icons.print,
        ),
        _navCard(
          destinationIndex: 6,
          title: l10n.t('peripherals_identity'),
          subtitle: identity.when(
            data: (value) => Text(value['fingerprintSha256']?.toString() ?? 'n/a'),
            loading: () => Text(l10n.t('loading')),
            error: (e, _) => Text('$e'),
          ),
          icon: Icons.memory,
        ),
      ],
    );
  }

  Widget _scalePanel(dynamic l10n) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          l10n.t('peripherals_scale_test'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        TextField(
          onSubmitted: (value) {
            final bytes = utf8.encode(value);
            final parsed = ref.read(scaleParserProvider).parse(bytes);
            final encoded = ref.read(rawJsonEncoderProvider).convert(parsed.toJson());
            setState(() => _scaleJson = encoded);
          },
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: l10n.t('peripherals_scale_input'),
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

  Widget _cashDrawerPanel(dynamic l10n) {
    final selectedPrinter = ref.watch(selectedPrinterProvider);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          l10n.t('peripherals_drawer'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          selectedPrinter == null
              ? l10n.t('peripherals_drawer_no_printer')
              : l10n.t('peripherals_drawer_ready').replaceAll('{printer}', selectedPrinter),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          icon: const Icon(Icons.point_of_sale),
          label: Text(l10n.t('peripherals_open_drawer')),
          onPressed: selectedPrinter == null
              ? null
              : () async {
                  final manager = ref.read(printerManagerProvider);
                  try {
                    await manager.printToInstalledPrinter(
                      printerName: selectedPrinter,
                      payload: manager.cashDrawerPulse(),
                    );
                    _toast(l10n.t('peripherals_drawer_sent'));
                  } catch (error) {
                    _toast('${l10n.t('peripherals_drawer_failed')}: $error');
                  }
                },
        ),
      ],
    );
  }

  Widget _machineIdentityPanel(dynamic l10n) {
    final identity = ref.watch(machineIdentityProvider);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          l10n.t('peripherals_identity'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        identity.when(
          data: (value) => Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SelectableText(const JsonEncoder.withIndent('  ').convert(value)),
            ),
          ),
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text('$e'),
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
      error: (e, _) => Center(child: Text('$e')),
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
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }
}
