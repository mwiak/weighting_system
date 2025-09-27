// import 'dart:convert';
//
// import 'package:json_annotation/json_annotation.dart';
// import 'package:json_serializable/json_serializable.dart';
// part 'device_profile.g.dart';
//
// @JsonSerializable()
// class DeviceProfile {
//   /// Unique identifier for the relationship
//   final int? id;
//
//   /// ID of the driver
//   final int driverId;
//
//   /// License plate number
//   final String plateNumber;
//
//   /// Whether this relationship is active
//   final bool active;
//
//   /// When this relationship was created
//   final DateTime? createDate;
//
//   /// When this relationship was last updated
//   final DateTime? writeDate;
//
//   const DeviceProfile({
//     this.id,
//     required this.driverId,
//     required this.plateNumber,
//     this.active = true,
//     this.createDate,
//     this.writeDate,
//   });
//
//   /// Creates a copy of this driver plate with updated fields
//   DeviceProfile copyWith({
//     int? id,
//     int? driverId,
//     String? plateNumber,
//     bool? active,
//     DateTime? createDate,
//     DateTime? writeDate,
//   }) {
//     return DeviceProfile(
//       id: id ?? this.id,
//       driverId: driverId ?? this.driverId,
//       plateNumber: plateNumber ?? this.plateNumber,
//       active: active ?? this.active,
//       createDate: createDate ?? this.createDate,
//       writeDate: writeDate ?? this.writeDate,
//     );
//   }
//
//   /// Converts this driver plate to a Map for database operations
//   Map<String, dynamic> toMap() {
//     return {
//       if (id != null) 'id': id,
//       'driver_id': driverId,
//       'plate_number': plateNumber,
//       'active': active ? 1 : 0,
//       'create_date': createDate?.toIso8601String(),
//       'write_date': writeDate?.toIso8601String(),
//     };
//   }
//
//   /// Creates a DriverPlate from a database Map
//   factory DeviceProfile.fromMap(Map<String, dynamic> map) {
//     return DeviceProfile(
//       id: map['id']?.toInt(),
//       driverId: map['driver_id']?.toInt() ?? 0,
//       plateNumber: map['plate_number'] ?? '',
//       active: (map['active'] ?? 1) == 1,
//       createDate: map['create_date'] != null
//           ? DateTime.parse(map['create_date'])
//           : null,
//       writeDate:
//           map['write_date'] != null ? DateTime.parse(map['write_date']) : null,
//     );
//   }
//
//   /// JSON serialization
//   // factory DeviceProfile.fromJson(Map<String, dynamic> json) =>
//   //     _$DeviceProfile(json);
//   // Map<String, dynamic> toJson() => _$DeviceProfile(this);
//   //
//   // /// Checks if this relationship has complete required information
//   // bool get isComplete => driverId > 0 && plateNumber.isNotEmpty;
//   //
//   // @override
//   // bool operator ==(Object other) {
//   //   if (identical(this, other)) return true;
//   //   return other is DeviceProfile &&
//   //       other.id == id &&
//   //       other.driverId == driverId &&
//   //       other.plateNumber == plateNumber &&
//   //       other.active == active;
//   // }
//   //
//   // @override
//   // int get hashCode {
//   //   return id.hashCode ^
//   //       driverId.hashCode ^
//   //       plateNumber.hashCode ^
//   //       active.hashCode;
//   // }
//   //
//   // @override
//   // String toString() {
//   //   return 'DriverPlate(id: $id, driverId: $driverId, plateNumber: $plateNumber, active: $active)';
//   // }
// }
