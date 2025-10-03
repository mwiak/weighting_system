import 'package:fluent_ui/fluent_ui.dart';
import 'package:weighing_system/database/database_helper.dart';
import 'package:weighing_system/utils/debugging_methods.dart';

import '../models/user.dart';

class UserProvider extends ChangeNotifier {
  User? activeUser;
  bool isInitializing = true;
  DatabaseHelper databaseHelper = DatabaseHelper();

  UserRanks? get state => activeUser?.type;

  List<User> allUsers = [];

  List<User> otherUsers = [];

  Future<void> attemptLogin(
      String username, String password, BuildContext? context) async {
    List<Map<String, dynamic>> data = await databaseHelper
        .query('users', where: 'username = ?', whereArgs: [username]);

    if (data.isNotEmpty) {
      final actualPassword = data[0]['password'] ?? '';
      if (password == actualPassword) {
        activeUser = User.fromMap(data[0]);
        await getOtherUsers();
        notifyListeners();
        printd('user $activeUser is logged');
      } else {
        //TODO
      }
    } else {
      //TODO
    }
  }

  void getAllUsers() async {
    List<Map<String, dynamic>> data = await databaseHelper.query('users');

    if (data.isEmpty) return;

    allUsers = data.map((d) => User.fromMap(d)).toList();
    printd(allUsers.toString());
    isInitializing = false;
    notifyListeners();
  }

  Future<void> getOtherUsers() async {
    List<Map<String, dynamic>> data = await databaseHelper.query('users');

    if (data.isEmpty) return;

    final allUsers = data.map((d) => User.fromMap(d)).toList();

    allUsers.removeWhere((user) => user.username == activeUser!.username);

    otherUsers = allUsers;
    notifyListeners();
  }

  // Count admin users in database
  Future<int> countAdmins() async {
    List<Map<String, dynamic>> data = await databaseHelper.query(
      'users',
      where: 'type = ?',
      whereArgs: ['admin'],
    );
    return data.length;
  }

  // Check if a user can be deleted (at least 1 admin must remain)
  Future<bool> canDeleteUser(int userId) async {
    // Get the user to check if they're an admin
    List<Map<String, dynamic>> userData = await databaseHelper.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );

    if (userData.isEmpty) return false;

    final user = User.fromMap(userData[0]);

    // If user is not admin, can always delete
    if (user.type != UserRanks.admin) return true;

    // If user is admin, check if there's at least one other admin
    final adminCount = await countAdmins();
    return adminCount > 1;
  }

  // Create new user
  Future<bool> createNewUser(User user, BuildContext? context) async {
    try {
      // Check if username already exists
      List<Map<String, dynamic>> existing = await databaseHelper.query(
        'users',
        where: 'username = ?',
        whereArgs: [user.username],
      );

      if (existing.isNotEmpty) {
        if (context != null && context.mounted) {
          displayInfoBar(context, builder: (context, close) {
            return InfoBar(
              title: const Text('Error'),
              content: const Text('Username already exists'),
              severity: InfoBarSeverity.error,
            );
          });
        }
        return false;
      }

      // Insert user
      await databaseHelper.insert('users', user.toMap());

      // Refresh user list
      getAllUsers();

      if (context != null && context.mounted) {
        displayInfoBar(context, builder: (context, close) {
          return InfoBar(
            title: const Text('Success'),
            content: const Text('User created successfully'),
            severity: InfoBarSeverity.success,
          );
        });
      }

      return true;
    } catch (e) {
      debugPrint('Error creating user: $e');
      if (context != null && context.mounted) {
        displayInfoBar(context, builder: (context, close) {
          return InfoBar(
            title: const Text('Error'),
            content: Text('Failed to create user: $e'),
            severity: InfoBarSeverity.error,
          );
        });
      }
      return false;
    }
  }

  // Update existing user (username and/or type)
  Future<bool> updateUser(User user, BuildContext? context) async {
    try {
      // Check if new username conflicts with existing user
      List<Map<String, dynamic>> existing = await databaseHelper.query(
        'users',
        where: 'username = ? AND id != ?',
        whereArgs: [user.username, user.id],
      );

      if (existing.isNotEmpty) {
        if (context != null && context.mounted) {
          displayInfoBar(context, builder: (context, close) {
            return InfoBar(
              title: const Text('Error'),
              content: const Text('Username already exists'),
              severity: InfoBarSeverity.error,
            );
          });
        }
        return false;
      }

      // If changing from admin to normal, check admin count
      List<Map<String, dynamic>> currentData = await databaseHelper.query(
        'users',
        where: 'id = ?',
        whereArgs: [user.id],
      );

      if (currentData.isNotEmpty) {
        final currentUser = User.fromMap(currentData[0]);
        if (currentUser.type == UserRanks.admin &&
            user.type == UserRanks.normal) {
          final adminCount = await countAdmins();
          if (adminCount <= 1) {
            if (context != null && context.mounted) {
              displayInfoBar(context, builder: (context, close) {
                return InfoBar(
                  title: const Text('Error'),
                  content: const Text('Cannot change type: at least one admin must remain'),
                  severity: InfoBarSeverity.error,
                );
              });
            }
            return false;
          }
        }
      }

      // Update user
      await databaseHelper.update(
        'users',
        user.toMap(),
        where: 'id = ?',
        whereArgs: [user.id],
      );

      // Refresh user list
      getAllUsers();

      // Update active user if it's the same user
      if (activeUser?.id == user.id) {
        activeUser = user;
        await getOtherUsers();
      }

      if (context != null && context.mounted) {
        displayInfoBar(context, builder: (context, close) {
          return InfoBar(
            title: const Text('Success'),
            content: const Text('User updated successfully'),
            severity: InfoBarSeverity.success,
          );
        });
      }

      return true;
    } catch (e) {
      debugPrint('Error updating user: $e');
      if (context != null && context.mounted) {
        displayInfoBar(context, builder: (context, close) {
          return InfoBar(
            title: const Text('Error'),
            content: Text('Failed to update user: $e'),
            severity: InfoBarSeverity.error,
          );
        });
      }
      return false;
    }
  }

  // Change user password
  Future<bool> changePassword(int userId, String newPassword, BuildContext? context) async {
    try {
      await databaseHelper.update(
        'users',
        {'password': newPassword},
        where: 'id = ?',
        whereArgs: [userId],
      );

      // Update active user password if it's the same user
      if (activeUser?.id == userId) {
        activeUser!.password = newPassword;
      }

      if (context != null && context.mounted) {
        displayInfoBar(context, builder: (context, close) {
          return InfoBar(
            title: const Text('Success'),
            content: const Text('Password changed successfully'),
            severity: InfoBarSeverity.success,
          );
        });
      }

      return true;
    } catch (e) {
      debugPrint('Error changing password: $e');
      if (context != null && context.mounted) {
        displayInfoBar(context, builder: (context, close) {
          return InfoBar(
            title: const Text('Error'),
            content: Text('Failed to change password: $e'),
            severity: InfoBarSeverity.error,
          );
        });
      }
      return false;
    }
  }

  // Delete user (with admin validation)
  Future<bool> deleteUser(int userId, BuildContext? context) async {
    try {
      // Check if user can be deleted
      final canDelete = await canDeleteUser(userId);

      if (!canDelete) {
        if (context != null && context.mounted) {
          displayInfoBar(context, builder: (context, close) {
            return InfoBar(
              title: const Text('Error'),
              content: const Text('Cannot delete: at least one admin must remain'),
              severity: InfoBarSeverity.error,
            );
          });
        }
        return false;
      }

      // Delete user
      await databaseHelper.delete(
        'users',
        where: 'id = ?',
        whereArgs: [userId],
      );

      // Refresh user list
      getAllUsers();

      if (context != null && context.mounted) {
        displayInfoBar(context, builder: (context, close) {
          return InfoBar(
            title: const Text('Success'),
            content: const Text('User deleted successfully'),
            severity: InfoBarSeverity.success,
          );
        });
      }

      return true;
    } catch (e) {
      debugPrint('Error deleting user: $e');
      if (context != null && context.mounted) {
        displayInfoBar(context, builder: (context, close) {
          return InfoBar(
            title: const Text('Error'),
            content: Text('Failed to delete user: $e'),
            severity: InfoBarSeverity.error,
          );
        });
      }
      return false;
    }
  }
}
