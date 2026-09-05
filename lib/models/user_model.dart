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
