/// Runtime MySQL connection parameters (e.g. local `world` sample database).
class MySqlConnectionConfig {
  const MySqlConnectionConfig({
    required this.host,
    required this.port,
    required this.database,
    required this.user,
    required this.password,
  });

  factory MySqlConnectionConfig.defaults() {
    return const MySqlConnectionConfig(
      host: 'localhost',
      port: 3306,
      database: 'world',
      user: 'root',
      password: 'pass',
    );
  }

  final String host;
  final int port;
  final String database;
  final String user;
  final String password;

  MySqlConnectionConfig copyWith({
    String? host,
    int? port,
    String? database,
    String? user,
    String? password,
  }) {
    return MySqlConnectionConfig(
      host: host ?? this.host,
      port: port ?? this.port,
      database: database ?? this.database,
      user: user ?? this.user,
      password: password ?? this.password,
    );
  }
}
