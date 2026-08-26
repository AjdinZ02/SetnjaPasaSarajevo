import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:setnjapasasarajevo_mobile/providers/auth_provider.dart';
import 'package:setnjapasasarajevo_mobile/utils/api_config.dart';

import '../models/user.dart';

class UserProvider extends ChangeNotifier {
  User? _cachedUser;

  Map<String, String> _headers() {
    final token = AuthProvider.accesstoken;
    return {
      "Content-Type": "application/json",
      if (token != null && token.isNotEmpty) "Authorization": "Bearer $token",
    };
  }

  Future<User> getById(int id, {bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedUser != null) return _cachedUser!;

    final response = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/api/users/$id"),
      headers: _headers(),
    );
    if (response.statusCode != 200) throw Exception(response.body);

    final user = User.fromJson(jsonDecode(response.body));
    _cachedUser = user;
    return user;
  }

  Future<void> update(int id, Map data) async {
    final response = await http.put(
      Uri.parse("${ApiConfig.baseUrl}/api/users/$id"),
      headers: _headers(),
      body: jsonEncode(data),
    );
    if (response.statusCode != 200) throw Exception(response.body);
  }

  Future<void> changePassword(Map data) async {
    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/api/users/change-password"),
      headers: _headers(),
      body: jsonEncode(data),
    );
    if (response.statusCode != 200) throw Exception(response.body);
  }

  Future<void> uploadImage(Map data) async {
    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/api/users/upload-image"),
      headers: _headers(),
      body: jsonEncode({"image": data["image"]}),
    );
    if (response.statusCode != 200) throw Exception(response.body);
  }

  Future<void> updateMyProfile(Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse("${ApiConfig.baseUrl}/api/users/me"),
      headers: _headers(),
      body: jsonEncode(data),
    );
    if (response.statusCode != 200) throw Exception(response.body);

    _cachedUser = User.fromJson(jsonDecode(response.body));
    notifyListeners();
  }

  Future<void> clearCache() async {
    _cachedUser = null;
    notifyListeners();
  }
}
