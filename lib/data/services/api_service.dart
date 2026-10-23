import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  ApiException(this.statusCode, this.message);
  final int statusCode;
  final String message;
  @override
  String toString() => message;
}

class ApiService {
  ApiService({String? baseUrl}) : _baseUrl = baseUrl ?? _defaultBaseUrl;

  static String get _defaultBaseUrl {
    if (kIsWeb) return 'http://192.168.3.15:3000/api';
    return 'http://192.168.3.15:3000/api';
  }

  final String _baseUrl;
  String? authToken;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      };

  Future<dynamic> get(String endpoint) async {
    try {
      debugPrint('🌐 GET $_baseUrl$endpoint');
      final response = await http
          .get(Uri.parse('$_baseUrl$endpoint'), headers: _headers)
          .timeout(const Duration(seconds: 15));
      return _processResponse(response);
    } catch (e) {
      debugPrint('❌ Erro HTTP GET [$endpoint]: $e');
      rethrow;
    }
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    try {
      debugPrint('🌐 POST $_baseUrl$endpoint');
      final response = await http
          .post(
            Uri.parse('$_baseUrl$endpoint'),
            headers: _headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));
      return _processResponse(response);
    } catch (e) {
      debugPrint('❌ Erro HTTP POST [$endpoint]: $e');
      rethrow;
    }
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    try {
      debugPrint('🌐 PUT $_baseUrl$endpoint');
      final response = await http
          .put(
            Uri.parse('$_baseUrl$endpoint'),
            headers: _headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));
      return _processResponse(response);
    } catch (e) {
      debugPrint('❌ Erro HTTP PUT [$endpoint]: $e');
      rethrow;
    }
  }

  Future<dynamic> delete(String endpoint) async {
    try {
      debugPrint('🌐 DELETE $_baseUrl$endpoint');
      final response = await http
          .delete(Uri.parse('$_baseUrl$endpoint'), headers: _headers)
          .timeout(const Duration(seconds: 15));
      return _processResponse(response);
    } catch (e) {
      debugPrint('❌ Erro HTTP DELETE [$endpoint]: $e');
      rethrow;
    }
  }

  dynamic _processResponse(http.Response response) {
    debugPrint(
        '📥 Response [${response.statusCode}] for URL ${response.request?.url}');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    }
    dynamic errorBody;
    try {
      errorBody = jsonDecode(response.body);
    } catch (_) {}
    final message = errorBody is Map
        ? errorBody['error'] ?? 'Erro na requisição'
        : 'Erro ${response.statusCode}';
    throw ApiException(response.statusCode, message.toString());
  }
}
