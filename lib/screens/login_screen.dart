import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import 'package:weighing_system/providers/user_provider.dart';
import 'package:weighing_system/screens/main_dashboard.dart';
import 'package:weighing_system/utils/navigator_methods.dart';
import 'package:weighing_system/widgets/user_login_avatar.dart';

import '../models/user.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isShowingPasswordPanel = false;
  List<User> users = [];
  String usernameToLog = '';
  TextEditingController passWordController = TextEditingController();
  bool hidePassword = true;
  late VoidCallback _listener;
  late UserProvider provider;

  void attemptLogin(UserProvider provider) {}

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      provider = context.read<UserProvider>();
      provider.getAllUsers();
      _listener = () {
        userListener(provider);
      };

      provider.addListener(_listener);
    });
  }

  void userListener(UserProvider provider) {
    if (provider.activeUser != null) {
      navigateToWithReplacement(MainDashboard(), context);
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    passWordController.dispose();
    provider.removeListener(_listener);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (BuildContext context, UserProvider value, Widget? child) {
        if (value.isInitializing) {
          return ScaffoldPage(content: const ProgressRing());
        }
        users = value.allUsers;

        return ScaffoldPage(
          content: Center(
            child: Column(
              children: [
                Text('اختر مستخدم'),
                SizedBox(
                  height: 15,
                ),
                ...value.allUsers.map((user) => UserLoginAvatar(
                      onPressed: (v) {
                        setState(() {
                          usernameToLog = v;
                          isShowingPasswordPanel = true;
                        });
                      },
                      user: user,
                    )),
                SizedBox(
                  height: 20,
                ),
                showPasswordPanel(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget showPasswordPanel() {
    return isShowingPasswordPanel
        ? Column(
            children: [
              SizedBox(
                  width: 200,
                  child: TextBox(
                    textDirection: TextDirection.ltr,
                    suffix: IconButton(
                      icon: Icon(FluentIcons.partly_sunny_showers_day),
                      onPressed: () {
                        setState(() {
                          hidePassword = !hidePassword;
                        });
                      },
                    ),
                    obscureText: hidePassword,
                    controller: passWordController,
                  )),
              SizedBox(
                height: 20,
              ),
              Button(
                  child: Text('متابعة'),
                  onPressed: () {
                    context.read<UserProvider>().attemptLogin(
                        usernameToLog, passWordController.text.trim(), null);
                  })
            ],
          )
        : SizedBox.shrink();
  }

  void navigateToMain() {
    Navigator.of(context).pushReplacement(
        FluentPageRoute(builder: (context) => MainDashboard()));
  }
}
