import 'package:json_annotation/json_annotation.dart';

part 'supplier.g.dart';

@JsonSerializable()
class Supplier {
  final int? id;
  final String name;
  final String? email;
  final String? phone;
  final String? mobile;
  final String? street;
  final String? street2;
  final String? city;
  final String? zip;
  final String? vat;
  final bool isCompany;
  final bool active;
  final int supplierRank;
  final int customerRank;
  final int? odooId;
  final int syncStatus;
  final String? createDate;
  final String? writeDate;

  Supplier({
    this.id,
    required this.name,
    this.email,
    this.phone,
    this.mobile,
    this.street,
    this.street2,
    this.city,
    this.zip,
    this.vat,
    this.isCompany = false,
    this.active = true,
    this.supplierRank = 1,
    this.customerRank = 0,
    this.odooId,
    this.syncStatus = 0,
    this.createDate,
    this.writeDate,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) => _$SupplierFromJson(json);
  Map<String, dynamic> toJson() => _$SupplierToJson(this);

  factory Supplier.fromDatabase(Map<String, dynamic> map) {
    return Supplier(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      phone: map['phone'],
      mobile: map['mobile'],
      street: map['street'],
      street2: map['street2'],
      city: map['city'],
      zip: map['zip'],
      vat: map['vat'],
      isCompany: (map['is_company'] ?? 0) == 1,
      active: (map['active'] ?? 1) == 1,
      supplierRank: map['supplier_rank'] ?? 1,
      customerRank: map['customer_rank'] ?? 0,
      odooId: map['odoo_id'],
      syncStatus: map['sync_status'] ?? 0,
      createDate: map['create_date'],
      writeDate: map['write_date'],
    );
  }

  factory Supplier.fromMap(Map<String, dynamic> map) {
    return Supplier.fromDatabase(map);
  }

  Map<String, dynamic> toDatabase() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'mobile': mobile,
      'street': street,
      'street2': street2,
      'city': city,
      'zip': zip,
      'vat': vat,
      'is_company': isCompany ? 1 : 0,
      'active': active ? 1 : 0,
      'supplier_rank': supplierRank,
      'customer_rank': customerRank,
      'odoo_id': odooId,
      'sync_status': syncStatus,
      'create_date': createDate,
      'write_date': writeDate,
    };
  }

  Map<String, dynamic> toMap() {
    return toDatabase();
  }

  Supplier copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? mobile,
    String? street,
    String? street2,
    String? city,
    String? zip,
    String? vat,
    bool? isCompany,
    bool? active,
    int? supplierRank,
    int? customerRank,
    int? odooId,
    int? syncStatus,
    String? createDate,
    String? writeDate,
  }) {
    return Supplier(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      mobile: mobile ?? this.mobile,
      street: street ?? this.street,
      street2: street2 ?? this.street2,
      city: city ?? this.city,
      zip: zip ?? this.zip,
      vat: vat ?? this.vat,
      isCompany: isCompany ?? this.isCompany,
      active: active ?? this.active,
      supplierRank: supplierRank ?? this.supplierRank,
      customerRank: customerRank ?? this.customerRank,
      odooId: odooId ?? this.odooId,
      syncStatus: syncStatus ?? this.syncStatus,
      createDate: createDate ?? this.createDate,
      writeDate: writeDate ?? this.writeDate,
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
    return 'Supplier(id: $id, name: $name, email: $email, phone: $phone, mobile: $mobile, city: $city, active: $active)';
  }
}