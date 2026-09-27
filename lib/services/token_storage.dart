import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _cloudTokenKey = 'cloud_token';
  static const _tenantIdKey = 'tenant_id';

  final FlutterSecureStorage _storage;

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<void> saveCloudTokens({
    required String cloudToken,
    required String tenantId,
  }) async {
    await _storage.write(key: _cloudTokenKey, value: cloudToken);
    await _storage.write(key: _tenantIdKey, value: tenantId);
  }

  Future<String?> readAccessToken() => _storage.read(key: _accessTokenKey);

  Future<String?> readRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<String?> readCloudToken() => _storage.read(key: _cloudTokenKey);

  Future<String?> readTenantId() => _storage.read(key: _tenantIdKey);

  Future<void> clear() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _cloudTokenKey);
    await _storage.delete(key: _tenantIdKey);
  }
}
