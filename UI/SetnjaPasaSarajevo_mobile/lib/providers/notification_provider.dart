import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:setnjapasasarajevo_mobile/providers/auth_provider.dart';
import 'package:setnjapasasarajevo_mobile/utils/api_config.dart';

class AppNotification {
  final int id;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  AppNotification.fromJson(Map<String, dynamic> json)
    : id = json['id'] as int,
      title = '${json['title'] ?? ''}',
      message = '${json['message'] ?? ''}',
      isRead = json['isRead'] as bool? ?? false,
      createdAt = DateTime.parse(json['createdAt'] as String);
}

class NotificationProvider extends ChangeNotifier {
  Timer? _poller;
  List<AppNotification> items = [];

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${AuthProvider.accesstoken}',
  };

  Future<void> load() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/notifications?limit=50'),
      headers: _headers,
    );
    if (response.statusCode != 200) throw Exception(response.body);
    items = (jsonDecode(response.body) as List)
        .map((item) => AppNotification.fromJson(item))
        .toList();
    notifyListeners();
  }

  Future<void> markAsRead(AppNotification item) async {
    if (item.isRead) return;
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/api/notifications/${item.id}/read'),
      headers: _headers,
    );
    if (response.statusCode != 204) throw Exception(response.body);
    await load();
  }

  void startPolling() {
    _poller ??= Timer.periodic(const Duration(seconds: 30), (_) => load());
  }

  @override
  void dispose() {
    _poller?.cancel();
    super.dispose();
  }
}
