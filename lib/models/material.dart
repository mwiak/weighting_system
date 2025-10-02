import 'package:json_annotation/json_annotation.dart';
import '../utils/arabic_normalize.dart';

part 'material.g.dart';

@JsonSerializable()
class Material {
  final int? id;
  final String name;
  final String? normalizedName;
  final double? price; // Optional price per kilogram
  final String? description;
  final bool active;
  final DateTime? createDate;
  final DateTime? writeDate;
  final int? odooId;
  final int syncStatus; // 0: pending, 1: synced, 2: error

  Material({
    this.id,
    required this.name,
    String? normalizedName,
    this.price,
    this.description,
    this.active = true,
    this.createDate,
    this.writeDate,
    this.odooId,
    this.syncStatus = 0,
  }) : normalizedName = normalizedName ?? normalizeArabic(name);

  factory Material.fromJson(Map<String, dynamic> json) => _$MaterialFromJson(json);
  Map<String, dynamic> toJson() => _$MaterialToJson(this);

  factory Material.fromDatabase(Map<String, dynamic> map) {
    return Material(
      id: map['id'],
      name: map['name'],
      normalizedName: map['normalized_name'],
      price: (map['price'] as num?)?.toDouble(),
      description: map['description'],
      active: (map['active'] as int?) == 1,
      createDate: map['create_date'] != null
          ? DateTime.parse(map['create_date'])
          : null,
      writeDate: map['write_date'] != null
          ? DateTime.parse(map['write_date'])
          : null,
      odooId: map['odoo_id'],
      syncStatus: map['sync_status'] ?? 0,
    );
  }

  Map<String, dynamic> toDatabase() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'normalized_name': normalizedName ?? normalizeArabic(name),
      'price': price,
      'description': description,
      'active': active ? 1 : 0,
      'create_date': (createDate ?? DateTime.now()).toIso8601String(),
      'write_date': (writeDate ?? DateTime.now()).toIso8601String(),
      'odoo_id': odooId,
      'sync_status': syncStatus,
    };
  }

  Material copyWith({
    int? id,
    String? name,
    String? normalizedName,
    double? price,
    String? description,
    bool? active,
    DateTime? createDate,
    DateTime? writeDate,
    int? odooId,
    int? syncStatus,
  }) {
    final newName = name ?? this.name;
    return Material(
      id: id ?? this.id,
      name: newName,
      normalizedName: normalizedName ?? (name != null ? normalizeArabic(newName) : this.normalizedName),
      price: price ?? this.price,
      description: description ?? this.description,
      active: active ?? this.active,
      createDate: createDate ?? this.createDate,
      writeDate: writeDate ?? this.writeDate,
      odooId: odooId ?? this.odooId,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  String get displayName => name;

  String get priceDisplay {
    if (price != null && price! > 0) {
      return '\$${price!.toStringAsFixed(2)}/kg';
    }
    return 'No price set';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Material && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Material(id: $id, name: $name, price: $price)';
  }
}