import 'package:json_annotation/json_annotation.dart';
import '../utils/arabic_normalize.dart';

part 'client.g.dart';

@JsonSerializable()
class Client {
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

  Client({
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

  factory Client.fromJson(Map<String, dynamic> json) => _$ClientFromJson(json);
  Map<String, dynamic> toJson() => _$ClientToJson(this);

  factory Client.fromDatabase(Map<String, dynamic> map) {
    return Client(
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

  Client copyWith({
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
    return Client(
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
    return other is Client && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Client(id: $id, name: $name, phone: $phone, mobile: $mobile, city: $city, active: $active)';
  }
}
