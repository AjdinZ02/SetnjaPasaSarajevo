import 'package:setnjapasasarajevo_mobile/models/user.dart';
import 'package:json_annotation/json_annotation.dart';

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
  final DateTime? reservationDateTime;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool? isActive;
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
    this.reservationDateTime,
    this.createdAt,
    this.updatedAt,
    this.isActive,
    this.user,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) =>
      _$ReservationFromJson(json);

  Map<String, dynamic> toJson() => _$ReservationToJson(this);
}
