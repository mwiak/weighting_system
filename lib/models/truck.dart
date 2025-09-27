import 'package:json_annotation/json_annotation.dart';

part 'truck.g.dart';

/// Truck Model
/// 
/// Represents a truck/vehicle in the weighing system.
/// Contains vehicle information and assigned driver details.
@JsonSerializable()
class Truck {
  /// Unique identifier for the truck
  final int? id;
  
  /// License plate number (unique identifier)
  final String plateNumber;
  
  /// Vehicle model/make
  final String? model;
  
  /// Load capacity in kg
  final double? capacity;
  
  /// ID of the assigned driver
  final int? driverId;
  
  /// Whether the truck is active
  final bool active;
  
  /// When this truck record was created
  final DateTime? createDate;
  
  /// When this truck record was last updated
  final DateTime? writeDate;

  const Truck({
    this.id,
    required this.plateNumber,
    this.model,
    this.capacity,
    this.driverId,
    this.active = true,
    this.createDate,
    this.writeDate,
  });

  /// Creates a copy of this truck with updated fields
  Truck copyWith({
    int? id,
    String? plateNumber,
    String? model,
    double? capacity,
    int? driverId,
    bool? active,
    DateTime? createDate,
    DateTime? writeDate,
  }) {
    return Truck(
      id: id ?? this.id,
      plateNumber: plateNumber ?? this.plateNumber,
      model: model ?? this.model,
      capacity: capacity ?? this.capacity,
      driverId: driverId ?? this.driverId,
      active: active ?? this.active,
      createDate: createDate ?? this.createDate,
      writeDate: writeDate ?? this.writeDate,
    );
  }

  /// Converts this truck to a Map for database operations
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'plate_number': plateNumber,
      'model': model,
      'capacity': capacity,
      'driver_id': driverId,
      'active': active ? 1 : 0,
      'create_date': createDate?.toIso8601String(),
      'write_date': writeDate?.toIso8601String(),
    };
  }

  /// Creates a Truck from a database Map
  factory Truck.fromMap(Map<String, dynamic> map) {
    return Truck(
      id: map['id']?.toInt(),
      plateNumber: map['plate_number'] ?? '',
      model: map['model'],
      capacity: map['capacity']?.toDouble(),
      driverId: map['driver_id']?.toInt(),
      active: (map['active'] ?? 1) == 1,
      createDate: map['create_date'] != null ? DateTime.parse(map['create_date']) : null,
      writeDate: map['write_date'] != null ? DateTime.parse(map['write_date']) : null,
    );
  }

  /// JSON serialization
  factory Truck.fromJson(Map<String, dynamic> json) => _$TruckFromJson(json);
  Map<String, dynamic> toJson() => _$TruckToJson(this);

  /// Gets a display-friendly version of the truck's information
  String get displayInfo {
    final buffer = StringBuffer(plateNumber);
    if (model?.isNotEmpty == true) {
      buffer.write(' ($model)');
    }
    if (capacity != null && capacity! > 0) {
      buffer.write(' - ${capacity!.toStringAsFixed(0)}kg capacity');
    }
    return buffer.toString();
  }
  
  /// Checks if this truck has complete required information
  bool get isComplete => plateNumber.isNotEmpty;
  
  /// Gets formatted capacity string
  String get formattedCapacity {
    if (capacity == null || capacity! <= 0) return 'Not specified';
    if (capacity! >= 1000) {
      return '${(capacity! / 1000).toStringAsFixed(1)}t';
    }
    return '${capacity!.toStringAsFixed(0)}kg';
  }
  
  /// Checks if this truck has an assigned driver
  bool get hasDriver => driverId != null;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Truck &&
        other.id == id &&
        other.plateNumber == plateNumber &&
        other.model == model &&
        other.capacity == capacity &&
        other.driverId == driverId &&
        other.active == active;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        plateNumber.hashCode ^
        model.hashCode ^
        capacity.hashCode ^
        driverId.hashCode ^
        active.hashCode;
  }

  @override
  String toString() {
    return 'Truck(id: $id, plateNumber: $plateNumber, model: $model, driverId: $driverId, active: $active)';
  }
}