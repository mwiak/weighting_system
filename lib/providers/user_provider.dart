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

  void createNewUser() {}

  void updateUser() {}

  void deleteUser() {}
}
