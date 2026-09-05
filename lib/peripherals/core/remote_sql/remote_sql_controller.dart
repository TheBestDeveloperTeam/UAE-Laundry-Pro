import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:laundrypro_uae/peripherals/core/remote_sql/mysql_connection_config.dart';
import 'package:laundrypro_uae/peripherals/core/remote_sql/remote_sql_service.dart';
import 'package:laundrypro_uae/peripherals/core/remote_sql/remote_sql_state.dart';

class RemoteSqlController extends StateNotifier<RemoteSqlState> {
  RemoteSqlController(this._service) : super(RemoteSqlState.initial());

  final RemoteSqlService _service;

  void updateConfig(MySqlConnectionConfig config) {
    state = state.copyWith(config: config);
  }

  Future<void> connect() async {
    state = state.copyWith(
      status: RemoteSqlConnectionStatus.connecting,
      statusMessage: 'Connecting...',
      clearError: true,
      clearResults: true,
    );
    try {
      await _service.connect(state.config);
      state = state.copyWith(
        status: RemoteSqlConnectionStatus.connected,
        statusMessage: 'Connected',
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        status: RemoteSqlConnectionStatus.error,
        statusMessage: 'Not Connected',
        lastError: error.toString(),
        clearResults: true,
      );
    }
  }

  Future<void> disconnect() async {
    await _service.disconnect();
    state = state.copyWith(
      status: RemoteSqlConnectionStatus.disconnected,
      statusMessage: 'Not Connected',
      clearResults: true,
      clearError: true,
    );
  }

  Future<void> queryCountry() async {
    if (!state.isConnected && !_service.isConnected) {
      state = state.copyWith(
        lastError: 'Connect to the database before running a query.',
      );
      return;
    }

    state = state.copyWith(querying: true, clearError: true);
    try {
      final result = await _service.queryCountry();
      state = state.copyWith(
        querying: false,
        columns: result.columns,
        rows: result.rows,
      );
    } catch (error) {
      state = state.copyWith(
        querying: false,
        lastError: error.toString(),
      );
    }
  }
}
