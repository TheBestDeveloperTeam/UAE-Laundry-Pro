import 'package:flutter/material.dart';
import 'package:laundrypro_uae/core/errors/api_exception.dart';
import 'package:laundrypro_uae/models/user_model.dart';
import 'package:laundrypro_uae/services/auth_service.dart';
import 'package:laundrypro_uae/services/license_service.dart';

enum AuthStatus {
  unknown,
  authenticated,
  unauthenticated,
}

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._authService, {LicenseService? licenseService})
      : _licenseService = licenseService ?? LicenseService();

  final AuthService _authService;
  final LicenseService _licenseService;

  AuthStatus status = AuthStatus.unknown;
  UserModel? user;
  String? errorMessageKey;
  bool isLoading = false;
  bool apiHealthy = false;
  bool licenseActive = true;
  bool licenseChecked = false;
  bool licenseBypass = false;
  String? licenseUmac;

  Future<void> bootstrap() async {
    isLoading = true;
    notifyListeners();

    try {
      final health = await _authService.health();
      apiHealthy = health['status'] == 'healthy' || health['database'] == 'ok';
    } catch (_) {
      apiHealthy = false;
    }

    if (!apiHealthy) {
      licenseBypass = true;
      licenseActive = true;
      licenseChecked = true;
      status = AuthStatus.unauthenticated;
      isLoading = false;
      notifyListeners();
      return;
    }

    final hasSession = await _authService.hasStoredSession();
    if (!hasSession) {
      status = AuthStatus.unauthenticated;
      isLoading = false;
      notifyListeners();
      return;
    }

    try {
      user = await _authService.me();
      status = AuthStatus.authenticated;
      await checkLicense();
    } catch (_) {
      await _authService.logout();
      status = AuthStatus.unauthenticated;
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> checkLicense() async {
    if (!apiHealthy) {
      licenseBypass = true;
      licenseActive = true;
      licenseChecked = true;
      notifyListeners();
      return;
    }

    try {
      final data = await _licenseService.status();
      licenseActive = data['active'] == true;
      licenseUmac = data['umac']?.toString();
      licenseBypass = false;
    } catch (_) {
      licenseBypass = true;
      licenseActive = true;
    }
    licenseChecked = true;
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    isLoading = true;
    errorMessageKey = null;
    notifyListeners();

    try {
      final result = await _authService.login(username, password);
      user = result.user;
      status = AuthStatus.authenticated;
      await checkLicense();
      isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      errorMessageKey = _mapErrorKey(e);
      status = AuthStatus.unauthenticated;
      isLoading = false;
      notifyListeners();
      return false;
    } catch (_) {
      errorMessageKey = 'api_unavailable';
      status = AuthStatus.unauthenticated;
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    user = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  String _mapErrorKey(ApiException exception) {
    switch (exception.code) {
      case 'AUTH_INVALID_CREDENTIALS':
        return 'invalid_credentials';
      case 'AUTH_SESSION_EXPIRED':
        return 'session_expired';
      default:
        return 'api_unavailable';
    }
  }
}
