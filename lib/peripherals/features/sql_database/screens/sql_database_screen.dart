import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:laundrypro_uae/peripherals/core/remote_sql/mysql_connection_config.dart';
import 'package:laundrypro_uae/peripherals/core/remote_sql/remote_sql_state.dart';
import 'package:laundrypro_uae/peripherals/features/shared/providers/app_providers.dart';

/// SQL tab: connect release builds to a local MySQL service and query `country`.
class SqlDatabaseScreen extends ConsumerStatefulWidget {
  const SqlDatabaseScreen({super.key});

  @override
  ConsumerState<SqlDatabaseScreen> createState() => _SqlDatabaseScreenState();
}

class _SqlDatabaseScreenState extends ConsumerState<SqlDatabaseScreen> {
  late final TextEditingController _hostController;
  late final TextEditingController _portController;
  late final TextEditingController _nameController;
  late final TextEditingController _userController;
  late final TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    final config = MySqlConnectionConfig.defaults();
    _hostController = TextEditingController(text: config.host);
    _portController = TextEditingController(text: '${config.port}');
    _nameController = TextEditingController(text: config.database);
    _userController = TextEditingController(text: config.user);
    _passwordController = TextEditingController(text: config.password);
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _nameController.dispose();
    _userController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _syncConfigFromFields() {
    final port = int.tryParse(_portController.text.trim()) ?? 3306;
    ref.read(remoteSqlControllerProvider.notifier).updateConfig(
          MySqlConnectionConfig(
            host: _hostController.text.trim().isEmpty
                ? 'localhost'
                : _hostController.text.trim(),
            port: port,
            database: _nameController.text.trim().isEmpty
                ? 'world'
                : _nameController.text.trim(),
            user: _userController.text.trim().isEmpty
                ? 'root'
                : _userController.text.trim(),
            password: _passwordController.text,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final sqlState = ref.watch(remoteSqlControllerProvider);
    final controller = ref.read(remoteSqlControllerProvider.notifier);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'SQL Database',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Connect to a local MySQL service at runtime (release or debug). '
            'Defaults match the MySQL `world` sample database.',
          ),
          const SizedBox(height: 12),
          _connectionStatusBanner(sqlState, theme),
          const SizedBox(height: 12),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _configField(
                    label: 'DB_HOST',
                    controller: _hostController,
                    enabled: !sqlState.isConnected,
                  ),
                  _configField(
                    label: 'DB_PORT',
                    controller: _portController,
                    enabled: !sqlState.isConnected,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  _configField(
                    label: 'DB_NAME',
                    controller: _nameController,
                    enabled: !sqlState.isConnected,
                  ),
                  _configField(
                    label: 'DB_USER',
                    controller: _userController,
                    enabled: !sqlState.isConnected,
                  ),
                  _configField(
                    label: 'DB_PASSWORD',
                    controller: _passwordController,
                    enabled: !sqlState.isConnected,
                    obscureText: true,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: sqlState.isConnected ||
                                sqlState.status ==
                                    RemoteSqlConnectionStatus.connecting
                            ? null
                            : () {
                                _syncConfigFromFields();
                                controller.connect();
                              },
                        icon: const Icon(Icons.link),
                        label: const Text('Connect'),
                      ),
                      OutlinedButton.icon(
                        onPressed: sqlState.isConnected
                            ? () => controller.disconnect()
                            : null,
                        icon: const Icon(Icons.link_off),
                        label: const Text('Disconnect'),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: sqlState.isConnected && !sqlState.querying
                            ? () {
                                _syncConfigFromFields();
                                controller.queryCountry();
                              }
                            : null,
                        icon: sqlState.querying
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.table_chart),
                        label: const Text('Query'),
                      ),
                    ],
                  ),
                  if (sqlState.lastError != null) ...[
                    const SizedBox(height: 12),
                    Material(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          sqlState.lastError!,
                          style: TextStyle(
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _countryResultsGrid(sqlState),
          ),
        ],
      ),
    );
  }

  Widget _connectionStatusBanner(RemoteSqlState sqlState, ThemeData theme) {
    final Color bg;
    final Color fg;
    final IconData icon;

    switch (sqlState.status) {
      case RemoteSqlConnectionStatus.connected:
        bg = theme.colorScheme.primaryContainer;
        fg = theme.colorScheme.onPrimaryContainer;
        icon = Icons.check_circle;
      case RemoteSqlConnectionStatus.connecting:
        bg = theme.colorScheme.tertiaryContainer;
        fg = theme.colorScheme.onTertiaryContainer;
        icon = Icons.sync;
      case RemoteSqlConnectionStatus.error:
        bg = theme.colorScheme.errorContainer;
        fg = theme.colorScheme.onErrorContainer;
        icon = Icons.error_outline;
      case RemoteSqlConnectionStatus.disconnected:
        bg = theme.colorScheme.surfaceContainerHighest;
        fg = theme.colorScheme.onSurfaceVariant;
        icon = Icons.cloud_off;
    }

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: fg),
            const SizedBox(width: 12),
            Text(
              sqlState.statusMessage,
              style: theme.textTheme.titleMedium?.copyWith(
                color: fg,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (sqlState.status == RemoteSqlConnectionStatus.connecting) ...[
              const SizedBox(width: 12),
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _configField({
    required String label,
    required TextEditingController controller,
    bool enabled = true,
    bool obscureText = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: controller,
        enabled: enabled,
        obscureText: obscureText,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        onChanged: (_) => _syncConfigFromFields(),
      ),
    );
  }

  Widget _countryResultsGrid(RemoteSqlState sqlState) {
    if (sqlState.querying) {
      return const Center(child: CircularProgressIndicator());
    }

    if (sqlState.columns.isEmpty) {
      return const Center(
        child: Text(
          'Connect and press Query to load rows from the `country` table.',
          textAlign: TextAlign.center,
        ),
      );
    }

    final columns = sqlState.columns;
    final rowCount = sqlState.rows.length + 1;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'country (${sqlState.rows.length} rows)',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Scrollbar(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(8),
                child: Scrollbar(
                  notificationPredicate: (notification) =>
                      notification.depth == 1,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: (columns.length * 140).toDouble(),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns.length,
                          mainAxisSpacing: 1,
                          crossAxisSpacing: 1,
                          childAspectRatio: 2.4,
                        ),
                        itemCount: columns.length * rowCount,
                        itemBuilder: (context, index) {
                          final col = index % columns.length;
                          final row = index ~/ columns.length;
                          final isHeader = row == 0;
                          final label = columns[col];
                          final value = isHeader
                              ? label
                              : (sqlState.rows[row - 1][label] ?? '');

                          return DecoratedBox(
                            decoration: BoxDecoration(
                              color: isHeader
                                  ? Theme.of(context)
                                      .colorScheme
                                      .secondaryContainer
                                  : (row.isOdd
                                      ? Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerLow
                                      : Theme.of(context)
                                          .colorScheme
                                          .surface),
                              border: Border.all(
                                color: Theme.of(context).dividerColor,
                                width: 0.5,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: Text(
                                value,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                  fontWeight: isHeader
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
