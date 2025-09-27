class AppSetting {
  final int? id;
  final String key;
  final String value;
  final String type;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AppSetting({
    this.id,
    required this.key,
    required this.value,
    this.type = 'string',
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  AppSetting copyWith({
    int? id,
    String? key,
    String? value,
    String? type,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppSetting(
      id: id ?? this.id,
      key: key ?? this.key,
      value: value ?? this.value,
      type: type ?? this.type,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'setting_key': key,
      'setting_value': value,
      'setting_type': type,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory AppSetting.fromMap(Map<String, dynamic> map) {
    return AppSetting(
      id: map['id']?.toInt(),
      key: map['setting_key'] ?? '',
      value: map['setting_value'] ?? '',
      type: map['setting_type'] ?? 'string',
      description: map['description'],
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  @override
  String toString() {
    return 'AppSetting{id: $id, key: $key, value: $value, type: $type}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AppSetting &&
        other.id == id &&
        other.key == key &&
        other.value == value &&
        other.type == type;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        key.hashCode ^
        value.hashCode ^
        type.hashCode;
  }

  // Type-specific getters
  bool get boolValue => value == '1' || value.toLowerCase() == 'true';
  int get intValue => int.tryParse(value) ?? 0;
  double get doubleValue => double.tryParse(value) ?? 0.0;
}