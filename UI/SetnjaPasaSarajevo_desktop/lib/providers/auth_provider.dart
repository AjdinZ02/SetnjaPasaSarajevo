import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AuthProvider extends ChangeNotifier {
  // ✅ Global token
  static String? accessToken;

  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;

  // ✅ API URL
  static const String _loginUrl = 'http://127.0.0.1:5126/Access/login';

  // ✅ LOGIN
  Future<void> login(String username, String password) async {
    final uri = Uri.parse(_loginUrl);

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    // ✅ DEBUG (ostaljemo da vidiš ako opet nešto zeza)
    if (response.statusCode >= 300) {
      throw Exception('Login failed: ${response.body}');
    }

    final json = jsonDecode(response.body);

    // ✅ KLJUČNI FIX — podržava SVE varijante
    accessToken =
        json['accesstoken'] ??
        json['accessToken'] ??
        json['token'] ??
        json['access_token'];

    if (accessToken == null || accessToken!.isEmpty) {
      throw Exception('Token nije došao iz backenda');
    }

    _isAuthenticated = true;
    notifyListeners();
  }

  // ✅ LOGOUT
  void logout() {
    accessToken = null;
    _isAuthenticated = false;
    notifyListeners();
  }
}
