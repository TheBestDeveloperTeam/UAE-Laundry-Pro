import 'package:mysql1/mysql1.dart';

import 'package:laundrypro_uae/peripherals/core/logging/app_logger.dart';
import 'package:laundrypro_uae/peripherals/core/remote_sql/mysql_connection_config.dart';

/// Manages a single runtime MySQL client connection for the SQL tab.
class RemoteSqlService {
  RemoteSqlService({required AppLogger logger}) : _logger = logger;

  final AppLogger _logger;
  MySqlConnection? _connection;

  bool get isConnected => _connection != null;

  Future<void> connect(MySqlConnectionConfig config) async {
    await disconnect();
    _connection = await MySqlConnection.connect(
      ConnectionSettings(
        host: config.host,
        port: config.port,
        user: config.user,
        password: config.password,
        db: config.database,
        timeout: const Duration(seconds: 15),
      ),
    );
    await _logger.info(
      'MySQL connected',
      scope: 'remote_sql',
      payload: {
        'host': config.host,
        'port': config.port,
        'database': config.database,
      },
    );
  }

  Future<void> disconnect() async {
    final conn = _connection;
    _connection = null;
    if (conn != null) {
      await conn.close();
      await _logger.info('MySQL disconnected', scope: 'remote_sql');
    }
  }

  /// Runs `SELECT * FROM country` (MySQL `world` sample schema).
  Future<({List<String> columns, List<Map<String, String>> rows})> queryCountry({
    int limit = 250,
  }) async {
    final conn = _connection;
    if (conn == null) {
      throw StateError('Not connected to MySQL.');
    }

    final safeLimit = limit.clamp(1, 1000);
    final result = await conn.query(
      'SELECT * FROM country ORDER BY Code LIMIT $safeLimit',
    );

    final columns = _columnNames(result);
    if (result.isEmpty) {
      return (columns: columns, rows: const <Map<String, String>>[]);
    }

    final rows = <Map<String, String>>[];
    for (final row in result) {
      final map = <String, String>{};
      for (final column in columns) {
        map[column] = _cellToString(row[column]);
      }
      rows.add(map);
    }

    return (columns: columns, rows: rows);
  }

  List<String> _columnNames(Results result) {
    if (result.fields.isNotEmpty) {
      return result.fields
          .map((f) => f.name ?? '')
          .where((name) => name.isNotEmpty)
          .toList();
    }
    if (result.isNotEmpty) {
      return result.first.fields.keys.toList();
    }
    return const [];
  }

  String _cellToString(dynamic value) {
    if (value == null) return '';
    if (value is List<int>) {
      return String.fromCharCodes(value);
    }
    return value.toString();
  }
}
