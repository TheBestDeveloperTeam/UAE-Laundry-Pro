import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:laundrypro_uae/core/constants.dart';
import 'package:laundrypro_uae/core/errors/api_exception.dart';
import 'package:laundrypro_uae/services/token_storage.dart';

class ApiClient {
  ApiClient({
    Dio? dio,
    TokenStorage? tokenStorage,
    String? baseUrl,
  })  : _dio = dio ?? Dio(BaseOptions(
          baseUrl: baseUrl ?? kApiBaseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        )),
        _tokenStorage = tokenStorage ?? TokenStorage() {
    
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final auth = options.extra['auth'] ?? true;
        if (auth) {
          final token = await _tokenStorage.readAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        final response = e.response;
        final options = e.requestOptions;
        final auth = options.extra['auth'] ?? true;
        final retried = options.extra['retried'] ?? false;

        if (response?.statusCode == 401 && auth && !retried) {
          final refreshed = await _tryRefreshToken();
          if (refreshed) {
            options.extra['retried'] = true;
            try {
              final newResponse = await _dio.fetch(options);
              return handler.resolve(newResponse);
            } catch (err) {
              return handler.next(e);
            }
          } else {
            await _tokenStorage.clear();
          }
        }
        return handler.next(e);
      }
    ));
  }

  final Dio _dio;
  final TokenStorage _tokenStorage;

  Future<Map<String, dynamic>> get(
    String path, {
    bool auth = true,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: Options(extra: {'auth': auth}),
      );
      return _decodeResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: body,
        options: Options(extra: {'auth': auth}),
      );
      return _decodeResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: body,
        options: Options(extra: {'auth': auth}),
      );
      return _decodeResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) async {
    try {
      final response = await _dio.patch(
        path,
        data: body,
        options: Options(extra: {'auth': auth}),
      );
      return _decodeResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> postMultipart(
    String path,
    String filePath, {
    String fieldName = 'file',
    bool auth = true,
  }) async {
    try {
      final formData = FormData.fromMap({
        fieldName: await MultipartFile.fromFile(filePath),
      });

      final response = await _dio.post(
        path,
        data: formData,
        options: Options(extra: {'auth': auth}),
      );
      return _decodeResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<bool> _tryRefreshToken() async {
    final refreshToken = await _tokenStorage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return false;
    }

    try {
      // Create a new Dio instance to avoid interceptor loops
      final refreshDio = Dio(BaseOptions(baseUrl: _dio.options.baseUrl));
      final response = await refreshDio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      final data = response.data['data'] as Map<String, dynamic>? ?? {};
      final access = data['access_token'] as String?;
      final refresh = data['refresh_token'] as String?;
      if (access == null || refresh == null) {
        return false;
      }

      await _tokenStorage.saveTokens(accessToken: access, refreshToken: refresh);
      return true;
    } catch (_) {
      await _tokenStorage.clear();
      return false;
    }
  }

  Map<String, dynamic> _decodeResponse(Response response) {
    if (response.data is Map<String, dynamic>) {
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == false) {
        throw ApiException(
          data['code']?.toString() ?? 'API_ERROR',
          data['message_key']?.toString() ?? 'common.error',
          statusCode: response.statusCode ?? 500,
        );
      }
      return data;
    }
    return {};
  }

  ApiException _handleError(DioException e) {
    if (e.response != null && e.response?.data is Map<String, dynamic>) {
      final data = e.response?.data as Map<String, dynamic>;
      return ApiException(
        data['code']?.toString() ?? 'API_ERROR',
        data['message_key']?.toString() ?? 'common.error',
        statusCode: e.response?.statusCode ?? 500,
      );
    }
    return ApiException(
      'NETWORK_ERROR',
      e.message ?? 'Unknown network error',
      statusCode: e.response?.statusCode ?? 500,
    );
  }
}
