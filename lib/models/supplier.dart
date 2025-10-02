import 'package:json_annotation/json_annotation.dart';
import '../utils/arabic_normalize.dart';

part 'supplier.g.dart';

@JsonSerializable()
class Supplier {
  final int? id;
  final String name;
  final String? normalizedName;
  final String? phone;
  final String? mobile;
  final String? city;
  final bool active;
  final String? createDate;
  final String? writeDate;
  final int? odooId;
  final int syncStatus;

  Supplier({
    this.id,
    required this.name,
    String? normalizedName,
    this.phone,
    this.mobile,
    this.city,
    this.active = true,
    this.createDate,
    this.writeDate,
    this.odooId,
    this.syncStatus = 0,
  }) : normalizedName = normalizedName ?? normalizeArabic(name);

  factory Supplier.fromJson(Map<String, dynamic> json) => _$SupplierFromJson(json);
  Map<String, dynamic> toJson() => _$SupplierToJson(this);

  factory Supplier.fromDatabase(Map<String, dynamic> map) {
    return Supplier(
      id: map['id'],
      name: map['name'],
      normalizedName: map['normalized_name'],
      phone: map['phone'],
      mobile: map['mobile'],
      city: map['city'],
      active: (map['active'] ?? 1) == 1,
      createDate: map['create_date'],
      writeDate: map['write_date'],
      odooId: map['odoo_id'],
      syncStatus: map['sync_status'] ?? 0,
    );
  }

  factory Supplier.fromMap(Map<String, dynamic> map) {
    return Supplier.fromDatabase(map);
  }

  Map<String, dynamic> toDatabase() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'normalized_name': normalizedName ?? normalizeArabic(name),
      'phone': phone,
      'mobile': mobile,
      'city': city,
      'active': active ? 1 : 0,
      'create_date': createDate,
      'write_date': writeDate,
      'odoo_id': odooId,
      'sync_status': syncStatus,
    };
  }

  Map<String, dynamic> toMap() {
    return toDatabase();
  }

  Supplier copyWith({
    int? id,
    String? name,
    String? normalizedName,
    String? phone,
    String? mobile,
    String? city,
    bool? active,
    String? createDate,
    String? writeDate,
    int? odooId,
    int? syncStatus,
  }) {
    final newName = name ?? this.name;
    return Supplier(
      id: id ?? this.id,
      name: newName,
      normalizedName: normalizedName ?? (name != null ? normalizeArabic(newName) : this.normalizedName),
      phone: phone ?? this.phone,
      mobile: mobile ?? this.mobile,
      city: city ?? this.city,
      active: active ?? this.active,
      createDate: createDate ?? this.createDate,
      writeDate: writeDate ?? this.writeDate,
      odooId: odooId ?? this.odooId,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  String get displayName {
    return name;
  }

  String get contactInfo {
    final parts = <String>[];
    if (phone?.isNotEmpty == true) parts.add(phone!);
    if (city?.isNotEmpty == true) parts.add(city!);
    return parts.join(' - ');
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Supplier && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Supplier(id: $id, name: $name, phone: $phone, mobile: $mobile, city: $city, active: $active)';
  }
}
