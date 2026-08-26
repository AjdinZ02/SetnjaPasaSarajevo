import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:setnjapasasarajevo_mobile/utils/api_config.dart';

import '../models/pet.dart';
import 'auth_provider.dart';

class PetProvider extends ChangeNotifier {
  static const String _endpoint = '/api/pets';

  List<Pet>? _cachedPets;

  Future<List<Pet>> getMyPets({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedPets != null) {
      return _cachedPets!;
    }

    final token = AuthProvider.accesstoken;
    final url = "${ApiConfig.baseUrl}$_endpoint/my";

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(response.body);
    }

    final decoded = jsonDecode(response.body);

    List<Pet> pets = [];

    if (decoded is List) {
      pets = decoded.map<Pet>((e) => Pet.fromJson(e)).toList();
    } else if (decoded['items'] is List) {
      pets = (decoded['items'] as List)
          .map<Pet>((e) => Pet.fromJson(e))
          .toList();
    }

    _cachedPets = pets;
    return pets;
  }
  Future<void> addPet(Map<String, dynamic> data) async {
  final token = AuthProvider.accesstoken;
  final url = "${ApiConfig.baseUrl}$_endpoint";

  final response = await http.post(
    Uri.parse(url),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode(data),
  );

  if (response.statusCode != 200 && response.statusCode != 201) {
    throw Exception(response.body);
  }

  // ✅ RESET CACHE nakon dodavanja psa
  _cachedPets = null;
  }
  Future<void> clearCache() async {
    _cachedPets = null;
  }
}