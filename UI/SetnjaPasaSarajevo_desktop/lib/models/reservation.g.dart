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
  isActive: json['isActive'] as bool?,
  timeSlot: json['timeSlot'] == null
      ? null
      : TimeSlot.fromJson(json['timeSlot'] as Map<String, dynamic>),
  user: json['user'] == null
      ? null
      : User.fromJson(json['user'] as Map<String, dynamic>),
  status: json['status'] as String?,
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
      'status': instance.status,
      'isActive': instance.isActive,
      'timeSlot': instance.timeSlot,
      'user': instance.user,
    };

TimeSlot _$TimeSlotFromJson(Map<String, dynamic> json) => TimeSlot(
  date: json['date'] as String?,
  startTime: json['startTime'] as String?,
);

Map<String, dynamic> _$TimeSlotToJson(TimeSlot instance) => <String, dynamic>{
  'date': instance.date,
  'startTime': instance.startTime,
};
