class VehicleDriverRelationship {
  final int? id;
  final String vehiclePlate;
  final String driverName;
  final String? driverLicense;
  final DateTime createdAt;
  final int usageCount;

  const VehicleDriverRelationship({
    this.id,
    required this.vehiclePlate,
    required this.driverName,
    this.driverLicense,
    required this.createdAt,
    this.usageCount = 1,
  });

  VehicleDriverRelationship copyWith({
    int? id,
    String? vehiclePlate,
    String? driverName,
    String? driverLicense,
    DateTime? createdAt,
    int? usageCount,
  }) {
    return VehicleDriverRelationship(
      id: id ?? this.id,
      vehiclePlate: vehiclePlate ?? this.vehiclePlate,
      driverName: driverName ?? this.driverName,
      driverLicense: driverLicense ?? this.driverLicense,
      createdAt: createdAt ?? this.createdAt,
      usageCount: usageCount ?? this.usageCount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vehicle_plate': vehiclePlate,
      'driver_name': driverName,
      'driver_license': driverLicense,
      'created_at': createdAt.toIso8601String(),
      'usage_count': usageCount,
    };
  }

  factory VehicleDriverRelationship.fromMap(Map<String, dynamic> map) {
    return VehicleDriverRelationship(
      id: map['id']?.toInt(),
      vehiclePlate: map['vehicle_plate'] ?? '',
      driverName: map['driver_name'] ?? '',
      driverLicense: map['driver_license'],
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      usageCount: map['usage_count']?.toInt() ?? 1,
    );
  }

  @override
  String toString() {
    return 'VehicleDriverRelationship{id: $id, vehiclePlate: $vehiclePlate, driverName: $driverName, usageCount: $usageCount}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is VehicleDriverRelationship &&
        other.id == id &&
        other.vehiclePlate == vehiclePlate &&
        other.driverName == driverName &&
        other.driverLicense == driverLicense;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        vehiclePlate.hashCode ^
        driverName.hashCode ^
        driverLicense.hashCode;
  }
}