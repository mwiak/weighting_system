import 'package:fluent_ui/fluent_ui.dart';

enum UserRanks { normal, admin }

UserRanks typeFromMap(input) {
  switch (input) {
    case 'admin':
      return UserRanks.admin;
    case 'normal':
      return UserRanks.normal;
    default:
      return UserRanks.normal;
  }
}

String typeToMap(UserRanks input) {
  switch (input) {
    case UserRanks.admin:
      return 'admin';
    case UserRanks.normal:
      return 'normal';
    default:
      return 'normal';
  }
}

class User {
  // Database ID (null until persisted)
  User();
  // Default constructor
  int? id;

  // Weight fields
  String username = '';
  String password = '';
  UserRanks type = UserRanks.normal;

  void reset() {}

  Map<String, dynamic> toMap() {
    return {
      'id': id, // Only include for updates, null for inserts
      'username': username,
      'password': password,
      'type': typeToMap(type),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    final user = User();
    user.id = map['id'] as int?;
    user.username = (map['username'] as String?) ?? '';
    user.password = (map['password'] as String?) ?? '';
    user.type = typeFromMap((map['type'] as String?) ?? '');
    return user;
  }

  @override
  String toString() {
    return 'User{id: $id, username: $username, password: $password, type: $type}';
  }
}
