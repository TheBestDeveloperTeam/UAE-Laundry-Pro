class UserModel {
  const UserModel({
    required this.id,
    required this.uuid,
    required this.username,
    required this.fullName,
    required this.email,
    required this.role,
    required this.permissions,
  });

  final int id;
  final String uuid;
  final String username;
  final String fullName;
  final String? email;
  final String role;
  final List<String> permissions;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final permissions = (json['permissions'] as List<dynamic>? ?? [])
        .map((item) => item.toString())
        .toList();

    return UserModel(
      id: json['id'] as int,
      uuid: json['uuid'] as String,
      username: json['username'] as String,
      fullName: json['full_name'] as String,
      email: json['email'] as String?,
      role: json['role'] as String,
      permissions: permissions,
    );
  }

  // ─── Permission Helpers ──────────────────────────────────────────────────

  /// Returns true if this user holds [permission] in their JWT payload.
  bool hasPermission(String permission) => permissions.contains(permission);

  /// Returns true if the user has ANY of the given permissions.
  bool hasAnyPermission(List<String> perms) =>
      perms.any((p) => permissions.contains(p));

  /// Convenience: can this user edit global config paths?
  bool get canEditGlobalConfig => hasPermission('system.config.paths');

  /// Convenience: can this user run/restore backups?
  bool get canRunBackup    => hasPermission('backup.run');
  bool get canRestoreBackup => hasPermission('backup.restore');

  /// Convenience: is this user an admin or system administrator role?
  bool get isAdmin => role == 'admin' || role == 'super_admin' || role == 'system_admin';
}

class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });

  final String accessToken;
  final String refreshToken;
  final int expiresIn;

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      expiresIn: json['expires_in'] as int? ?? 0,
    );
  }
}

class LoginResult {
  const LoginResult({required this.tokens, required this.user});

  final AuthTokens tokens;
  final UserModel user;
}
