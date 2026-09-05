import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:laundrypro_uae/core/constants.dart';
import 'package:laundrypro_uae/core/errors/api_exception.dart';
import 'package:laundrypro_uae/services/token_storage.dart';

class ApiClient {
  ApiClient({
    http.Client? client,
    TokenStorage? tokenStorage,
    String? baseUrl,
  })  : _client = client ?? http.Client(),
        _tokenStorage = tokenStorage ?? TokenStorage(),
        _baseUrl = baseUrl ?? kApiBaseUrl;

  final http.Client _client;
  final TokenStorage _tokenStorage;
  final String _baseUrl;

  Future<Map<String, dynamic>> get(
    String path, {
    bool auth = true,
  }) {
    return _request('GET', path, auth: auth);
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) {
    return _request('POST', path, body: body, auth: auth);
  }

  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) {
    return _request('PUT', path, body: body, auth: auth);
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) {
    return _request('PATCH', path, body: body, auth: auth);
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
    bool retried = false,
  }) async {
    final uri = Uri.parse('$_baseUrl$path');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (auth) {
      final token = await _tokenStorage.readAccessToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    late http.Response response;
    switch (method) {
      case 'GET':
        response = await _client.get(uri, headers: headers);
      case 'POST':
        response = await _client.post(
          uri,
          headers: headers,
          body: body == null ? null : json.encode(body),
        );
      case 'PUT':
        response = await _client.put(
          uri,
          headers: headers,
          body: body == null ? null : json.encode(body),
        );
      case 'PATCH':
        response = await _client.send(
          http.Request('PATCH', uri)
            ..headers.addAll(headers)
            ..body = body == null ? '' : json.encode(body),
        ).then(http.Response.fromStream);
      default:
        throw ApiException('UNSUPPORTED_METHOD', 'common.unsupported_method');
    }

    if (response.statusCode == 401 && auth && !retried) {
      final refreshed = await _tryRefreshToken();
      if (refreshed) {
        return _request(method, path, body: body, auth: auth, retried: true);
      }
    }

    return _decodeResponse(response);
  }

  Future<bool> _tryRefreshToken() async {
    final refreshToken = await _tokenStorage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return false;
    }

    try {
      final uri = Uri.parse('$_baseUrl/auth/refresh');
      final response = await _client.post(
        uri,
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({'refresh_token': refreshToken}),
      );

      final decoded = _decodeResponse(response, allowUnauthorized: true);
      final data = decoded['data'] as Map<String, dynamic>? ?? {};
      final access = data['access_token'] as String?;
      final refresh = data['refresh_token'] as String?;
      if (access == null || refresh == null) {
        return false;
      }

      await _tokenStorage.saveTokens(accessToken: access, refreshToken: refresh);
      return true;
    } catch (_) {
      return false;
    }
  }

  Map<String, dynamic> _decodeResponse(
    http.Response response, {
    bool allowUnauthorized = false,
  }) {
    Map<String, dynamic> decoded = {};
    if (response.body.isNotEmpty) {
      final parsed = json.decode(response.body);
      if (parsed is Map<String, dynamic>) {
        decoded = parsed;
      }
    }

    final success = decoded['success'] == true;
    if (!success && (response.statusCode >= 400 || !allowUnauthorized)) {
      throw ApiException(
        decoded['code']?.toString() ?? 'API_ERROR',
        decoded['message_key']?.toString() ?? 'common.error',
        statusCode: response.statusCode,
      );
    }

    return decoded;
  }
}
