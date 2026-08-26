// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reservation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Reservation _$ReservationFromJson(Map<String, dynamic> json) => Reservation(
  id: (json['id'] as num?)?.toInt(),
  userId: (json['userId'] as num?)?.toInt(),
  firstName: json['firstName'] as String?,
  lastName: json['lastName'] as String?,
  address: json['address'] as String?,
  phoneNumber: json['phoneNumber'] as String?,
  petName: json['petName'] as String?,
  petType: json['petType'] as String?,
  notes: json['notes'] as String?,
  reservationDateTime: json['reservationDateTime'] == null
      ? null
      : DateTime.parse(json['reservationDateTime'] as String),
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
  isActive: json['isActive'] as bool?,
  user: json['user'] == null
      ? null
      : User.fromJson(json['user'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ReservationToJson(Reservation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'address': instance.address,
      'phoneNumber': instance.phoneNumber,
      'petName': instance.petName,
      'petType': instance.petType,
      'notes': instance.notes,
      'reservationDateTime': instance.reservationDateTime?.toIso8601String(),
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'isActive': instance.isActive,
      'user': instance.user,
    };
