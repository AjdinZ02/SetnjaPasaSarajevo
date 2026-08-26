enum ReservationStatus { available, partiallyBooked, fullyBooked }

class ReservationDayModel {
  final DateTime date;
  final int bookedSlots;
  final int totalSlots;

  ReservationDayModel({
    required this.date,
    required this.bookedSlots,
    this.totalSlots = 15,
  });

  bool get isFullyBooked => bookedSlots >= totalSlots;
  bool get hasAvailability => bookedSlots < totalSlots;

  ReservationStatus get status {
    if (isFullyBooked) return ReservationStatus.fullyBooked;
    if (bookedSlots == 0) return ReservationStatus.available;
    return ReservationStatus.partiallyBooked;
  }
}
