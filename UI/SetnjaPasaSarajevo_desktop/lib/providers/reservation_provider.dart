import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/reservation.dart';
import 'auth_provider.dart';

class ReservationProvider extends ChangeNotifier {
  final String _baseUrl = "http://127.0.0.1:5126/api/Reservations";

  List<Reservation> reservations = [];

  /// ✅ GET ALL
  Future<List<Reservation>> getReservations() async {
    var response = await http.get(
      Uri.parse("$_baseUrl/all"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer ${AuthProvider.accessToken}",
      },
    );

    if (response.statusCode >= 300) {
      throw Exception("Error fetching reservations");
    }

    var data = jsonDecode(response.body);

    if (data is List) {
      reservations = data.map((e) => Reservation.fromJson(e)).toList();
    } else {
      reservations = [];
    }

    notifyListeners();
    return reservations;
  }

  /// ✅ UPDATE STATUS
  Future<void> updateStatus(int id, String status) async {
    var response = await http.put(
      Uri.parse("$_baseUrl/$id/status"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer ${AuthProvider.accessToken}",
      },
      body: jsonEncode({"status": status}),
    );

    if (response.statusCode >= 300) {
      throw Exception("Error updating status");
    }
  }

  /// ✅ DELETE
  Future<void> deleteReservation(int id) async {
    var response = await http.delete(
      Uri.parse("$_baseUrl/$id"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer ${AuthProvider.accessToken}",
      },
    );

    if (response.statusCode >= 300) {
      throw Exception("Error deleting reservation");
    }
  }
}
