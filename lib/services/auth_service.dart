import 'package:laundrypro_uae/core/errors/api_exception.dart';
import 'package:laundrypro_uae/models/user_model.dart';
import 'package:laundrypro_uae/services/api_client.dart';
import 'package:laundrypro_uae/services/token_storage.dart';

class AuthService {
  AuthService({
    ApiClient? apiClient,
    TokenStorage? tokenStorage,
  })  : _apiClient = apiClient ?? ApiClient(),
        _tokenStorage = tokenStorage ?? TokenStorage();

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<Map<String, dynamic>> health() async {
    final response = await _apiClient.get('/health', auth: false);
    return response['data'] as Map<String, dynamic>? ?? {};
  }

  Future<LoginResult> login(String username, String password) async {
    final response = await _apiClient.post(
      '/auth/login',
      auth: false,
      body: {
        'username': username,
        'password': password,
      },
    );

    final data = response['data'] as Map<String, dynamic>? ?? {};
    final tokens = AuthTokens.fromJson(data);
    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);

    await _tokenStorage.saveTokens(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    );

    return LoginResult(tokens: tokens, user: user);
  }

  Future<UserModel> me() async {
    final response = await _apiClient.get('/auth/me');
    final data = response['data'] as Map<String, dynamic>? ?? {};
    return UserModel.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<void> logout() async {
    final refreshToken = await _tokenStorage.readRefreshToken();
    try {
      if (refreshToken != null) {
        await _apiClient.post(
          '/auth/logout',
          body: {'refresh_token': refreshToken},
        );
      }
    } on ApiException {
      // Local session should still be cleared.
    } finally {
      await _tokenStorage.clear();
    }
  }

  Future<bool> hasStoredSession() async {
    final token = await _tokenStorage.readAccessToken();
    return token != null && token.isNotEmpty;
  }
}
