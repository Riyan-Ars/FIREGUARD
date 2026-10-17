import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:fireguard/core/network/api_client.dart';
import 'package:fireguard/core/network/api_exceptions.dart';

void main() {
  group('ApiClient Tests', () {
    test('Processes successful JSON response envelope with data field', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          '{"success": true, "source": "NASA FIRMS", "data": [{"id": "HS-01"}]}',
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(client: mockClient, baseUrl: 'http://test.local');
      final result = await apiClient.get('/hotspots');

      expect(result, isA<List>());
      expect((result as List).first['id'], 'HS-01');
    });

    test('Throws RateLimitException on 429 response', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          '{"error": {"code": "RATE_LIMIT", "message": "Too many requests"}}',
          429,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(client: mockClient, baseUrl: 'http://test.local');
      expect(
        () => apiClient.get('/hotspots', retries: 0),
        throwsA(isA<RateLimitException>()),
      );
    });

    test('Throws DataParsingException on invalid JSON', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          '<html>Not JSON</html>',
          200,
          headers: {'content-type': 'text/html'},
        );
      });

      final apiClient = ApiClient(client: mockClient, baseUrl: 'http://test.local');
      expect(
        () => apiClient.get('/hotspots', retries: 0),
        throwsA(isA<DataParsingException>()),
      );
    });
  });
}
