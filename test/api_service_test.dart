import 'package:flutter_test/flutter_test.dart';
import 'package:lume/data/services/api_service.dart';

void main() {
  group('ApiService baseUrl configuration', () {
    test('normalizes baseUrl ending with /api', () {
      final api = ApiService(baseUrl: 'http://custom-host:8080/api');
      expect(api.baseUrl, 'http://custom-host:8080/api');
    });

    test('normalizes baseUrl without /api by appending it', () {
      final api = ApiService(baseUrl: 'http://custom-host:8080');
      expect(api.baseUrl, 'http://custom-host:8080/api');
    });

    test('strips trailing slashes before appending /api', () {
      final api = ApiService(baseUrl: 'http://custom-host:8080///');
      expect(api.baseUrl, 'http://custom-host:8080/api');
    });

    test('strips trailing slash when /api/ is given', () {
      final api = ApiService(baseUrl: 'http://custom-host:8080/api/');
      expect(api.baseUrl, 'http://custom-host:8080/api');
    });

    test('defaults to default url when baseUrl is null', () {
      final api = ApiService();
      expect(api.baseUrl, contains('/api'));
    });
  });
}
