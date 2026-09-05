class ApiException implements Exception {
  ApiException(this.code, this.messageKey, {this.statusCode = 400});

  final String code;
  final String messageKey;
  final int statusCode;

  @override
  String toString() => 'ApiException($code, $messageKey, $statusCode)';
}
