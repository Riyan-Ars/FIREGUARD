class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorCode;

  const ApiException(this.message, {this.statusCode, this.errorCode});

  @override
  String toString() => 'ApiException(code: $statusCode, error: $errorCode, message: $message)';
}

class NetworkException extends ApiException {
  const NetworkException(super.message, {super.statusCode = 0, super.errorCode = 'NETWORK_ERROR'});
}

class ApiTimeoutException extends ApiException {
  const ApiTimeoutException(super.message, {super.statusCode = 408, super.errorCode = 'TIMEOUT'});
}

class RateLimitException extends ApiException {
  const RateLimitException(super.message, {super.statusCode = 429, super.errorCode = 'RATE_LIMIT'});
}

class DataParsingException extends ApiException {
  const DataParsingException(super.message, {super.statusCode = 0, super.errorCode = 'PARSE_ERROR'});
}
