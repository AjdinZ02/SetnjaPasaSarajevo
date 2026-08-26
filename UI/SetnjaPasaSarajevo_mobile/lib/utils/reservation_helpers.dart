String formatReservationDate(Map<String, dynamic>? reservation) {
  if (reservation == null) return '-';

  final ts = reservation['timeSlot'];
  if (ts is! Map) return '-';

  final dateStr = ts['date'] as String?;
  if (dateStr == null || dateStr.isEmpty) return '-';

  final dt = DateTime.tryParse(dateStr);
  if (dt == null) return '-';

  final d = dt.toLocal();
  final day = d.day.toString().padLeft(2, '0');
  final month = d.month.toString().padLeft(2, '0');
  final year = d.year.toString();
  return '$day.$month.$year';
}

String formatReservationTime(Map<String, dynamic>? reservation) {
  if (reservation == null) return '-';

  final ts = reservation['timeSlot'];
  if (ts is! Map) return '-';

  final start = ts['startTime'] as String?;
  if (start == null || start.isEmpty) return '-';

  final parts = start.split(':');
  if (parts.length >= 2) {
    return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
  }

  return start;
}

/// ✅ COUNT TIMES
Map<String, int> _countReservationTimes(List<dynamic>? reservations) {
  if (reservations == null || reservations.isEmpty) return {};

  final map = <String, int>{};

  for (final r in reservations) {
    if (r is! Map) continue;

    final ts = r['timeSlot'];
    if (ts is! Map) continue;

    final start = ts['startTime'];
    if (start == null) continue;

    final parts = start.toString().split(':');
    if (parts.length >= 2) {
      final time = '${parts[0]}:${parts[1]}';
      map[time] = (map[time] ?? 0) + 1;
    }
  }

  return map;
}

/// ✅ FAVORITE TIME
String? _getMostFrequentTime(List<dynamic>? reservations) {
  final counts = _countReservationTimes(reservations);
  if (counts.isEmpty) return null;

  String? best;
  int max = 0;

  for (final e in counts.entries) {
    if (e.value > max) {
      max = e.value;
      best = e.key;
    }
  }

  // ✅ mora imati barem 2 rezervacije
  if (max < 2) return null;

  return best;
}

/// ✅ MAIN FUNCTION
List<dynamic> getRecommendedSlots(
  List<dynamic>? reservations,
  List<dynamic>? availableSlots,
) {
  if (availableSlots == null || availableSlots.isEmpty) return [];

  final now = DateTime.now();
  final favoriteTime = _getMostFrequentTime(reservations);

  /// ✅ HELPER (STRICT FUTURE)
  bool isFuture(Map slot) {
    final start = slot['startTime'];
    final dateStr = slot['date'];

    if (start == null || dateStr == null) return false;

    final parts = start.toString().split(':');
    if (parts.length < 2) return false;

    final date = DateTime.tryParse(dateStr);
    if (date == null) return false;

    final slotDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );

    // ✅ KLJUČ: SAMO budući termini
    return slotDateTime.isAfter(now);
  }

  /// ✅ 1. FAVORITE TIME MATCH
  if (favoriteTime != null) {
    final matching = availableSlots.where((slot) {
      if (slot is! Map) return false;

      final available = slot['isAvailable'] ?? false;
      if (available != true) return false;

      if (!isFuture(slot)) return false;

      final start = slot['startTime'];
      if (start == null) return false;

      final parts = start.toString().split(':');
      if (parts.length < 2) return false;

      final time = '${parts[0]}:${parts[1]}';

      return time == favoriteTime;
    }).toList();

    if (matching.isNotEmpty) {
      matching.sort((a, b) {
        final aDate = DateTime.tryParse(a['date'] ?? '');
        final bDate = DateTime.tryParse(b['date'] ?? '');

        if (aDate == null || bDate == null) return 0;
        return aDate.compareTo(bDate);
      });

      return matching.take(3).toList();
    }
  }

  /// ✅ 2. FUTURE FALLBACK
  List<dynamic> fallback = availableSlots.where((slot) {
    if (slot is! Map) return false;

    final available = slot['isAvailable'] ?? false;
    if (available != true) return false;

    return isFuture(slot);
  }).toList();

  /// ✅ 3. AKO NEMA FUTURE → fallback na sve dostupne
  if (fallback.isEmpty) {
    fallback = availableSlots.where((slot) {
      if (slot is! Map) return false;
      return slot['isAvailable'] == true;
    }).toList();
  }

  fallback.sort((a, b) {
    final aDate = DateTime.tryParse(a['date'] ?? '');
    final bDate = DateTime.tryParse(b['date'] ?? '');

    if (aDate == null || bDate == null) return 0;
    return aDate.compareTo(bDate);
  });

  return fallback.take(3).toList();
}

/// ✅ DEBUG
String getTimePreferenceDebugInfo(List<dynamic>? reservations) {
  final counts = _countReservationTimes(reservations);
  if (counts.isEmpty) return "No data";

  final sorted = counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  return sorted.map((e) => "${e.key} → ${e.value}x").join("\n");
}