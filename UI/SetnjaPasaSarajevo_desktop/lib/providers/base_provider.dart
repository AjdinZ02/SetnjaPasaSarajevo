import 'dart:convert';
import 'package:http/http.dart' as http;
import '../providers/auth_provider.dart';

class BaseProvider {
  static const String baseUrl = 'http://127.0.0.1:5126/api/';
  final String endpoint;

  BaseProvider(this.endpoint);

  Map<String, String> get headers {
    final token = AuthProvider.accessToken;
    final headers = <String, String>{'Content-Type': 'application/json'};

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  // ✅ GLAVNI FIX — QUERY SUPPORT
  Uri uri(String path, {Map<String, dynamic>? query}) {
    final fullPath = path.isEmpty ? endpoint : '$endpoint/$path';

    final uri = Uri.parse('$baseUrl$fullPath');

    if (query != null) {
      return uri.replace(
        queryParameters: query.map(
          (key, value) => MapEntry(key, value.toString()),
        ),
      );
    }

    return uri;
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    final response = await http.get(uri(path, query: query), headers: headers);

    return _parseResponse(response);
  }

  Future<dynamic> post(String path, dynamic body) async {
    final response = await http.post(
      uri(path),
      headers: headers,
      body: jsonEncode(body),
    );

    return _parseResponse(response);
  }

  Future<dynamic> put(String path, dynamic body) async {
    final response = await http.put(
      uri(path),
      headers: headers,
      body: jsonEncode(body),
    );

    return _parseResponse(response);
  }

  Future<void> delete(String path) async {
    final response = await http.delete(uri(path), headers: headers);

    if (response.statusCode >= 300) {
      throw Exception('Delete failed: ${response.statusCode} ${response.body}');
    }
  }

  dynamic _parseResponse(http.Response response) {
    if (response.statusCode >= 300) {
      throw Exception(
        'Request failed: ${response.statusCode} ${response.body}',
      );
    }

    if (response.body.isEmpty) {
      return null;
    }

    return jsonDecode(response.body);
  }
}
