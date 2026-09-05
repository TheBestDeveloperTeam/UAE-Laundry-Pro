import 'package:laundrypro_uae/peripherals/core/remote_sql/mysql_connection_config.dart';

enum RemoteSqlConnectionStatus {
  disconnected,
  connecting,
  connected,
  error,
}

class RemoteSqlState {
  const RemoteSqlState({
    required this.config,
    required this.status,
    this.statusMessage = 'Not Connected',
    this.lastError,
    this.columns = const [],
    this.rows = const [],
    this.querying = false,
  });

  factory RemoteSqlState.initial() {
    return RemoteSqlState(
      config: MySqlConnectionConfig.defaults(),
      status: RemoteSqlConnectionStatus.disconnected,
      statusMessage: 'Not Connected',
    );
  }

  final MySqlConnectionConfig config;
  final RemoteSqlConnectionStatus status;
  final String statusMessage;
  final String? lastError;
  final List<String> columns;
  final List<Map<String, String>> rows;
  final bool querying;

  bool get isConnected => status == RemoteSqlConnectionStatus.connected;

  RemoteSqlState copyWith({
    MySqlConnectionConfig? config,
    RemoteSqlConnectionStatus? status,
    String? statusMessage,
    String? lastError,
    List<String>? columns,
    List<Map<String, String>>? rows,
    bool? querying,
    bool clearError = false,
    bool clearResults = false,
  }) {
    return RemoteSqlState(
      config: config ?? this.config,
      status: status ?? this.status,
      statusMessage: statusMessage ?? this.statusMessage,
      lastError: clearError ? null : (lastError ?? this.lastError),
      columns: clearResults ? const [] : (columns ?? this.columns),
      rows: clearResults ? const [] : (rows ?? this.rows),
      querying: querying ?? this.querying,
    );
  }
}
