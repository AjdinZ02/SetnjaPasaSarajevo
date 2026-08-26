import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:setnjapasasarajevo_mobile/models/reservation_day_model.dart';
import 'package:setnjapasasarajevo_mobile/models/time_slot_model.dart';
import 'package:setnjapasasarajevo_mobile/utils/api_config.dart'; // ✅ BITNO
import 'package:setnjapasasarajevo_mobile/providers/auth_provider.dart';

class ReservationProvider extends ChangeNotifier {
  // ✅ koristi ApiConfig (NE localhost)
  static String get baseUrl => ApiConfig.baseUrl;

  static const List<String> availableSlots = [
    '08:00',
    '09:00',
    '10:00',
    '11:00',
    '12:00',
    '13:00',
    '14:00',
    '15:00',
    '16:00',
    '17:00',
    '18:00',
    '19:00',
    '20:00',
    '21:00',
    '22:00',
  ];

  Future<List<TimeSlotModel>> fetchRecommendedTimeSlots() async {
    final response = await http.get(
      Uri.parse(
        '${ApiConfig.getFullUrl('/api/recommendations')}/time-slots?limit=3',
      ),
      headers: {
        'Content-Type': 'application/json',
        if (AuthProvider.accesstoken != null)
          'Authorization': 'Bearer ${AuthProvider.accesstoken}',
      },
    );
    if (response.statusCode != 200) {
      throw Exception(
        'Preporuke HTTP ${response.statusCode}: ${response.body}',
      );
    }
    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded
        .map((item) => TimeSlotModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  // ✅ CREATE RESERVATION
  Future<void> createReservation(Map<String, dynamic> data) async {
    var token = AuthProvider.accesstoken;

    var url = "${ApiConfig.getFullUrl(ApiConfig.reservationsEndpoint)}";

    var response = await http.post(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(data),
    );

    print("CREATE STATUS: ${response.statusCode}");
    print("CREATE RESPONSE: ${response.body}");

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(response.body);
    }
  }

  // ✅ FETCH RESERVATIONS
  Future<List<dynamic>> fetchReservations() async {
    return await getMyReservations();
  }

  // ADMIN: get all reservations (backend enforces admin role)
  Future<List<dynamic>> getAllReservations() async {
    var token = AuthProvider.accesstoken;

    var url = "${ApiConfig.getFullUrl(ApiConfig.reservationsEndpoint)}/all";

    var response = await http.get(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    print("ALL RES STATUS: ${response.statusCode}");
    print("ALL RES BODY: ${response.body}");

    if (response.statusCode != 200) {
      throw Exception(response.body);
    }

    final decoded = jsonDecode(response.body);

    if (decoded is List) return decoded;
    if (decoded is Map && decoded.containsKey('items')) {
      return decoded['items'] as List<dynamic>;
    }

    return [];
  }

  // USER: get my reservations (backend returns only user's reservations)
  Future<List<dynamic>> getMyReservations() async {
    var token = AuthProvider.accesstoken;

    var url = "${ApiConfig.getFullUrl(ApiConfig.reservationsEndpoint)}/my";

    var response = await http.get(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    print("MY RES STATUS: ${response.statusCode}");
    print("MY RES BODY: ${response.body}");

    if (response.statusCode != 200) {
      throw Exception(response.body);
    }

    final decoded = jsonDecode(response.body);

    // ✅ Najsigurnije parsiranje
    if (decoded is List) return decoded;
    if (decoded is Map && decoded.containsKey('items')) {
      return decoded['items'] as List<dynamic>;
    }

    return [];
  }

  Future<List<ReservationDayModel>> fetchReservationDaysForMonth(
    int year,
    int month,
  ) async {
    List<dynamic> reservations = [];
    try {
      reservations = await getAllReservations();
    } catch (e) {
      reservations = await getMyReservations();
    }

    final counts = <DateTime, int>{};

    for (final reservation in reservations) {
      try {
        // CORRECTED: Use nested timeSlot structure instead of ReservationDateTime
        final timeSlotObj = reservation is Map ? reservation['timeSlot'] : null;
        if (timeSlotObj is Map) {
          final dateStr = timeSlotObj['date'] as String?;
          if (dateStr != null) {
            try {
              final date = DateTime.parse(dateStr);
              if (date.year != year || date.month != month) continue;

              final key = DateTime(date.year, date.month, date.day);
              counts[key] = (counts[key] ?? 0) + 1;
            } catch (_) {
              // Skip invalid dates
            }
          }
        }
      } catch (e) {
        print("Warning: Could not parse reservation date: $e");
      }
    }

    final totalDays = DateUtils.getDaysInMonth(year, month);
    return List.generate(totalDays, (index) {
      final date = DateTime(year, month, index + 1);
      final bookedSlots = counts[date] ?? 0;
      return ReservationDayModel(date: date, bookedSlots: bookedSlots);
    });
  }

  Future<List<TimeSlotModel>> fetchTimeSlotsForDate(DateTime date) async {
    var token = AuthProvider.accesstoken;

    // Fetch all available TimeSlots for this date from backend
    var url =
        "${ApiConfig.getFullUrl("/api/timeslots")}?date=${date.toIso8601String().split('T')[0]}";

    var slotsResponse = await http.get(
      Uri.parse(url),
      headers: {"Authorization": "Bearer $token"},
    );

    if (slotsResponse.statusCode != 200) {
      throw Exception("Failed to fetch time slots: ${slotsResponse.body}");
    }

    final List<dynamic> slotsData = jsonDecode(slotsResponse.body);
    var timeSlots = slotsData.map((e) => TimeSlotModel.fromJson(e)).toList();

    // Fetch all reservations to mark booked slots
    List<dynamic> allReservations = [];

    try {
      allReservations = await getMyReservations();
    } catch (e) {
      print("ERROR FETCHING MY RESERVATIONS: $e");
    }

    // Mark TimeSlots as booked using nested timeSlot object
    final bookedTimeSlotIds = <int>{};
    for (final reservation in allReservations) {
      try {
        // CORRECTED: Use nested timeSlot structure
        final timeSlotObj = reservation is Map ? reservation['timeSlot'] : null;
        if (timeSlotObj is Map) {
          final timeSlotId = timeSlotObj['id'] as int?;
          final reservationDate = timeSlotObj['date'] as String?;

          if (timeSlotId != null && reservationDate != null) {
            try {
              final resDate = DateTime.parse(reservationDate);
              if (_isSameDay(resDate, date)) {
                bookedTimeSlotIds.add(timeSlotId);
              }
            } catch (_) {
              // Skip invalid dates
            }
          }
        }
      } catch (e) {
        print("Warning: Could not parse reservation: $e");
      }
    }

    // Return TimeSlots with isBooked flag set
    return timeSlots.map((slot) {
      return TimeSlotModel(
        id: slot.id,
        date: slot.date,
        startTime: slot.startTime,
        endTime: slot.endTime,
        isBooked: bookedTimeSlotIds.contains(slot.id),
      );
    }).toList();
  }

  /// Helper to check if two dates are the same day
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  Future<void> updateStatus(int id, String status) async {
    var token = AuthProvider.accesstoken;

    var url =
        "${ApiConfig.getFullUrl(ApiConfig.reservationsEndpoint)}/$id/status";

    var response = await http.put(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"status": status}), // ✅ FIX
    );

    print("UPDATE STATUS: $id -> $status");
    print("RESPONSE: ${response.statusCode} ${response.body}");

    if (response.statusCode != 200) {
      throw Exception(response.body);
    }
  }

  Future<void> deleteReservation(int id) async {
    var token = AuthProvider.accesstoken;

    var url = "${ApiConfig.getFullUrl(ApiConfig.reservationsEndpoint)}/$id";

    var response = await http.delete(
      Uri.parse(url),
      headers: {"Authorization": "Bearer $token"},
    );

    print("DELETE STATUS: ${response.statusCode}");

    if (response.statusCode != 200) {
      throw Exception(response.body);
    }
  }

  DateTime? _parseReservationDate(dynamic reservation) {
    if (reservation is Map) {
      final ts = reservation['timeSlot'];
      if (ts is Map) {
        final dateStr = ts['date'] as String?;
        if (dateStr != null && dateStr.isNotEmpty) {
          try {
            return DateTime.parse(dateStr).toLocal();
          } catch (_) {
            return null;
          }
        }
      }
    }

    return null;
  }

  String _hourLabel(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    return '$hour:00';
  }
}
