class TimeSlotModel {
  final int id;
  final DateTime date;
  final String startTime;
  final String endTime;
  final bool isBooked;

  TimeSlotModel({
    required this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.isBooked = false,
  });

  factory TimeSlotModel.fromJson(Map<String, dynamic> json) {
    // Safe DateTime parsing with fallback
    DateTime parsedDate;
    try {
      final dateStr = json['date'] as String?;
      parsedDate = dateStr != null ? DateTime.parse(dateStr) : DateTime.now();
    } catch (_) {
      parsedDate = DateTime.now();
    }

    return TimeSlotModel(
      id: json['id'] as int? ?? 0,
      date: parsedDate,
      startTime: _formatTimeSpan(json['startTime']),
      endTime: _formatTimeSpan(json['endTime']),
      isBooked: json['isBooked'] as bool? ?? false,
    );
  }

  /// Converts TimeSpan format "HH:MM:SS" to "HH:MM"
  static String _formatTimeSpan(dynamic timeSpan) {
    if (timeSpan == null) return "00:00";
    final str = timeSpan.toString().trim();
    if (str.contains(':')) {
      final parts = str.split(':');
      return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
    }
    return str;
  }

  String get display => startTime;

  String get timeRange => '$startTime - $endTime';

  @override
  String toString() =>
      'TimeSlot(id: $id, date: $date, $timeRange, booked: $isBooked)';
}