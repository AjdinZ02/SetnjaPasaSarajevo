import 'package:flutter/material.dart';

import '../models/search_result.dart';
import '../models/user.dart';
import 'base_provider.dart';

class UserProvider extends ChangeNotifier {
  final BaseProvider _provider = BaseProvider('Users');
  SearchResult<User> result = SearchResult<User>();

  Future<SearchResult<User>> get({Map<String, dynamic>? filter}) async {
    
    // ✅ KLJUČNI FIX — koristi endpoint koji backend ima
    final response = await _provider.get(''); 

    if (response is Map<String, dynamic>) {
      final items = (response['items'] as List<dynamic>?)
              ?.map((item) =>
                  User.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [];

      result.totalCount = response['totalCount'] as int?;
      result.items = items;

    } else if (response is List) {

      result.items = response
          .map((item) =>
              User.fromJson(item as Map<String, dynamic>))
          .toList();

      result.totalCount = result.items?.length;

    } else {

      result.items = [];
      result.totalCount = 0;
    }

    notifyListeners();
    return result;
  }

  Future<User> insert(Map<String, dynamic> data) async {
    final response = await _provider.post('', data);
    return User.fromJson(response as Map<String, dynamic>);
  }

  Future<User> update(int id, Map<String, dynamic> data) async {
    final response = await _provider.put(id.toString(), data);
    return User.fromJson(response as Map<String, dynamic>);
  }

  Future<void> remove(int id) async {
    await _provider.delete(id.toString());
  }
}