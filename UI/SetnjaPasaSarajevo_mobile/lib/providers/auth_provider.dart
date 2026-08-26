import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:setnjapasasarajevo_mobile/utils/api_config.dart';
import 'package:provider/provider.dart';
import 'package:setnjapasasarajevo_mobile/providers/user_provider.dart';
import 'package:setnjapasasarajevo_mobile/providers/pet_provider.dart';

class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;

  static String? _accesstoken;
  String? _refreshtoken;
  static Map<String, dynamic>? _accessTokenDecoded;

  static String? get accesstoken => _accesstoken;
  String? get refreshtoken => _refreshtoken;
  static Map<String, dynamic>? get accessTokenDecoded => _accessTokenDecoded;

  static String get role =>
      _accessTokenDecoded?['role'] ?? _accessTokenDecoded?['Role'] ?? '';

  static bool get isAdmin => role == 'Admin';

  bool get isAuthenticated => _isAuthenticated;

  Future login(String username, String password) async {
    var url = "${ApiConfig.getFullUrl(ApiConfig.accessEndpoint)}/login";
    var uri = Uri.parse(url);

    var body = jsonEncode({"username": username, "password": password});

    http.Response response = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: body,
    );

    if (isValidResponse(response)) {
      var data = jsonDecode(response.body);

      _accesstoken = data['accesstoken'];
      _refreshtoken = data['refreshtoken'];
      _isAuthenticated = true;

      if (_accesstoken != null && _accesstoken!.isNotEmpty) {
        try {
          _accessTokenDecoded = JwtDecoder.decode(_accesstoken!);
        } catch (_) {
          _accessTokenDecoded = null;
        }
      }

      notifyListeners();
    } else {
      throw Exception("Login failed");
    }
  }

  Future<void> register(Map<String, dynamic> data) async {
    var url = "${ApiConfig.getFullUrl(ApiConfig.accessEndpoint)}/Register";
    var uri = Uri.parse(url);

    var response = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    if (response.statusCode == 400 || response.statusCode == 409) {
      throw Exception(response.body);
    }

    throw Exception("Server error");
  }

  bool isValidResponse(http.Response response) {
    if (response.statusCode < 299) {
      return true;
    } else if (response.statusCode == 401) {
      throw Exception("Unauthorized");
    } else {
      throw Exception("Server error");
    }
  }

  void logout(BuildContext context) {
    _isAuthenticated = false;
    _accesstoken = null;
    _refreshtoken = null;
    _accessTokenDecoded = null;

    // ✅ CLEAR CACHE
    context.read<UserProvider>().clearCache();
    context.read<PetProvider>().clearCache();

    notifyListeners();
  }

  Map<String, String> createHeaders() {
    return {
      "Content-Type": "application/json",
      if (_accesstoken != null) "Authorization": "Bearer $_accesstoken",
    };
  }
}
