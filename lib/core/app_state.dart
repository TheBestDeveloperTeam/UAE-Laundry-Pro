import 'package:flutter/foundation.dart';

class AppState extends ChangeNotifier {
  bool _isAuthenticated = false;
  String _tenantToken = '';

  bool get isAuthenticated => _isAuthenticated;
  String get tenantToken => _tenantToken;

  void authenticate(String token) {
    _tenantToken = token;
    _isAuthenticated = true;
    notifyListeners();
  }

  void logout() {
    _tenantToken = '';
    _isAuthenticated = false;
    notifyListeners();
  }
}
