import 'package:json_annotation/json_annotation.dart';
import 'user.dart';

part 'reservation.g.dart';

@JsonSerializable()
class Reservation {
  final int? id;
  final int? userId;

  final String? firstName;
  final String? lastName;
  final String? address;
  final String? phoneNumber;
  final String? petName;
  final String? petType;
  final String? notes;
  final String? status;
  final bool? isActive;

  final TimeSlot? timeSlot;

  final User? user;

  Reservation({
    this.id,
    this.userId,
    this.firstName,
    this.lastName,
    this.address,
    this.phoneNumber,
    this.petName,
    this.petType,
    this.notes,
    this.isActive,
    this.timeSlot,
    this.user,
    this.status,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) =>
      _$ReservationFromJson(json);

  Map<String, dynamic> toJson() =>
      _$ReservationToJson(this);
}

@JsonSerializable()
class TimeSlot {
  final String? date;
  final String? startTime;

  TimeSlot({this.date, this.startTime});

  factory TimeSlot.fromJson(Map<String, dynamic> json) =>
      _$TimeSlotFromJson(json);

  Map<String, dynamic> toJson() =>
      _$TimeSlotToJson(this);
}