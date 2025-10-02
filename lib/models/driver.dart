import 'package:json_annotation/json_annotation.dart';
import '../utils/arabic_normalize.dart';

part 'driver.g.dart';

/// Driver Model
///
/// Represents a truck driver in the weighing system.
/// Contains personal information and contact details for drivers.
@JsonSerializable()
class Driver {
  /// Unique identifier for the driver
  final int? id;

  /// Full name of the driver
  final String name;

  /// Normalized name for Arabic search tolerance
  final String? normalizedName;
  
  /// List of plate numbers associated with this driver
  final List<String> plateNumbers;
  
  /// Primary phone number
  final String? phone;
  
  /// Mobile phone number
  final String? mobile;
  
  /// City or location where the driver is based
  final String? city;
  
  /// Whether the driver is active
  final bool active;
  
  /// When this driver record was created
  final DateTime? createDate;
  
  /// When this driver record was last updated
  final DateTime? writeDate;

  Driver({
    this.id,
    required this.name,
    String? normalizedName,
    this.plateNumbers = const [],
    this.phone,
    this.mobile,
    this.city,
    this.active = true,
    this.createDate,
    this.writeDate,
  }) : normalizedName = normalizedName ?? normalizeArabic(name);

  /// Creates a copy of this driver with updated fields
  Driver copyWith({
    int? id,
    String? name,
    String? normalizedName,
    List<String>? plateNumbers,
    String? phone,
    String? mobile,
    String? city,
    bool? active,
    DateTime? createDate,
    DateTime? writeDate,
  }) {
    final newName = name ?? this.name;
    return Driver(
      id: id ?? this.id,
      name: newName,
      normalizedName: normalizedName ?? (name != null ? normalizeArabic(newName) : this.normalizedName),
      plateNumbers: plateNumbers ?? this.plateNumbers,
      phone: phone ?? this.phone,
      mobile: mobile ?? this.mobile,
      city: city ?? this.city,
      active: active ?? this.active,
      createDate: createDate ?? this.createDate,
      writeDate: writeDate ?? this.writeDate,
    );
  }

  /// Converts this driver to a Map for database operations
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'normalized_name': normalizedName ?? normalizeArabic(name),
      'phone': phone,
      'mobile': mobile,
      'city': city,
      'active': active ? 1 : 0,
      'create_date': createDate?.toIso8601String(),
      'write_date': writeDate?.toIso8601String(),
    };
  }

  /// Creates a Driver from a database Map (without plate numbers)
  factory Driver.fromMap(Map<String, dynamic> map, {List<String> plateNumbers = const []}) {
    return Driver(
      id: map['id']?.toInt(),
      name: map['name'] ?? '',
      normalizedName: map['normalized_name'],
      plateNumbers: plateNumbers,
      phone: map['phone'],
      mobile: map['mobile'],
      city: map['city'],
      active: (map['active'] ?? 1) == 1,
      createDate: map['create_date'] != null ? DateTime.parse(map['create_date']) : null,
      writeDate: map['write_date'] != null ? DateTime.parse(map['write_date']) : null,
    );
  }

  /// JSON serialization
  factory Driver.fromJson(Map<String, dynamic> json) => _$DriverFromJson(json);
  Map<String, dynamic> toJson() => _$DriverToJson(this);

  /// Gets the primary contact number (mobile first, then phone)
  String? get primaryContact => mobile?.isNotEmpty == true ? mobile : phone;
  
  /// Gets a display-friendly version of the driver's full information
  String get displayInfo {
    final buffer = StringBuffer(name);
    if (plateNumbers.isNotEmpty) {
      buffer.write(' (Plates: ${plateNumbers.join(", ")})');
    }
    if (city?.isNotEmpty == true) {
      buffer.write(' - $city');
    }
    return buffer.toString();
  }
  
  /// Checks if this driver has complete required information
  bool get isComplete => name.isNotEmpty && plateNumbers.isNotEmpty;
  
  /// Checks if this driver has contact information
  bool get hasContact => primaryContact?.isNotEmpty == true;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Driver &&
        other.id == id &&
        other.name == name &&
        other.plateNumbers.toString() == plateNumbers.toString() &&
        other.phone == phone &&
        other.mobile == mobile &&
        other.city == city &&
        other.active == active;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        plateNumbers.hashCode ^
        phone.hashCode ^
        mobile.hashCode ^
        city.hashCode ^
        active.hashCode;
  }

  @override
  String toString() {
    return 'Driver(id: $id, name: $name, plateNumbers: $plateNumbers, active: $active)';
  }
}