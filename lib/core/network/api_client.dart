import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'api_exceptions.dart';

class ApiClient {
  final http.Client _client;
  final String baseUrl;

  ApiClient({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        baseUrl = baseUrl ?? AppConfig.defaultBaseUrl;

  /// Perform a GET request with typed envelope parsing, timeouts, and automatic retry
  Future<dynamic> get(
    String path, {
    Map<String, String>? queryParams,
    Map<String, String>? headers,
    int retries = AppConfig.maxRetries,
  }) async {
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse('$baseUrl$cleanPath').replace(queryParameters: queryParams);

    final requestHeaders = {
      'Accept': 'application/json',
      'User-Agent': 'FIREGUARD-Flutter/1.0',
      ...?headers,
    };

    var attempt = 0;
    while (true) {
      attempt++;
      try {
        final response = await _client
            .get(uri, headers: requestHeaders)
            .timeout(AppConfig.requestTimeout);

        return _processResponse(response);
      } on SocketException catch (e) {
        if (attempt <= retries) {
          await Future.delayed(Duration(milliseconds: 300 * attempt));
          continue;
        }
        throw NetworkException('Cannot connect to server at $baseUrl: ${e.message}');
      } on TimeoutException {
        if (attempt <= retries) {
          await Future.delayed(Duration(milliseconds: 300 * attempt));
          continue;
        }
        throw const ApiTimeoutException('Connection timed out. Please check your internet connection.');
      } on http.ClientException catch (e) {
        if (attempt <= retries) {
          await Future.delayed(Duration(milliseconds: 300 * attempt));
          continue;
        }
        throw NetworkException('Network client error: ${e.message}');
      } catch (e) {
        if (e is ApiException) rethrow;
        throw ApiException('Unexpected communication error: $e');
      }
    }
  }

  dynamic _processResponse(http.Response response) {
    dynamic decoded;
    try {
      decoded = json.decode(response.body);
    } catch (e) {
      throw DataParsingException(
        'Failed to decode server response: $e',
        statusCode: response.statusCode,
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
        return decoded['data'];
      }
      return decoded;
    }

    // Handle error payloads
    String errorMessage = 'Request failed with status ${response.statusCode}';
    String? errorCode;
    if (decoded is Map<String, dynamic>) {
      if (decoded['error'] is Map) {
        errorMessage = decoded['error']['message'] ?? errorMessage;
        errorCode = decoded['error']['code'];
      } else if (decoded['message'] is String) {
        errorMessage = decoded['message'];
      }
    }

    if (response.statusCode == 429) {
      throw RateLimitException(errorMessage, errorCode: errorCode);
    }

    throw ApiException(
      errorMessage,
      statusCode: response.statusCode,
      errorCode: errorCode,
    );
  }

  void close() {
    _client.close();
  }
}

final apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient();
  ref.onDispose(() => client.close());
  return client;
});
