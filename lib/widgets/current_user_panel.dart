import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import 'package:weighing_system/utils/navigator_methods.dart';

import '../models/user.dart';
import '../providers/user_provider.dart';

class CurrentUserPanel extends StatefulWidget {
  const CurrentUserPanel({super.key});

  @override
  State<CurrentUserPanel> createState() => _CurrentUserPanelState();
}

class _CurrentUserPanelState extends State<CurrentUserPanel> {
  final GlobalKey _parentKey = GlobalKey();
  late User user;
  Color avatarColor = Colors.blue.withOpacity(0.6);
  final overlayPortalController = OverlayPortalController();

  void _toggleOverlay() {
    if (overlayPortalController.isShowing) {
      overlayPortalController.hide();
    } else {
      overlayPortalController.show();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<UserProvider>();
      user = provider.activeUser!;
      provider.addListener(() {
        if (provider.activeUser != null) {
          user = provider.activeUser!;
        }
      });
      setState(() {}); // trigger rebuild once user is loaded
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, value, child) {
        // ✅ Only render once user is available
        if (value.activeUser == null) {
          return CircleAvatar(
            radius: 30,
            backgroundColor: avatarColor,
            child: const Text("..."),
          );
        }

        return MouseRegion(
          onHover: (_) {
            setState(() {
              avatarColor = Colors.blue.withOpacity(0.45);
            });
          },
          onExit: (_) {
            setState(() {
              avatarColor = Colors.blue.withOpacity(0.6);
            });
          },
          child: GestureDetector(
            onTap: () {
              _toggleOverlay();
              setState(() {
                avatarColor = Colors.blue.withOpacity(0.8);
              });
            },
            child: CircleAvatar(
              key: _parentKey,
              radius: 30,
              backgroundColor: avatarColor,
              child: OverlayPortal(
                controller: overlayPortalController,
                overlayChildBuilder: (context) {
                  final RenderBox targetBox = _parentKey.currentContext
                      ?.findRenderObject() as RenderBox;
                  final Offset position = targetBox.localToGlobal(Offset.zero);
                  return Positioned(
                    top: position.dy + 80,
                    left: position.dx,
                    child: Consumer<UserProvider>(
                      builder: (context, value, child) {
                        if (value.otherUsers.isNotEmpty) {
                          return Container(
                              width: 180,
                              height: 250,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  Text('تبديل المستخدم'),
                                  SizedBox(
                                    height: 10,
                                  ),
                                  ...value.otherUsers.map((user) => Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: GestureDetector(
                                          onTap: () {
                                            _toggleOverlay();
                                            showSwitchUserDialog(user);
                                          },
                                          child: CircleAvatar(
                                            radius: 20,
                                            child: Text(
                                              user.username,
                                              style: TextStyle(fontSize: 7),
                                            ),
                                          ),
                                        ),
                                      ))
                                ],
                              ));
                        }
                        return Container(
                            width: 180,
                            height: 200,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text('لا يوجد مستخدمين أخرون'),
                            ));
                      },
                    ),
                  );
                },
                child: Text(
                  value.activeUser!.username.characters.first.toUpperCase(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void showSwitchUserDialog(User user) {
    final username = user.username;

    showDialog(
        context: context,
        builder: (context) => SwitchUserDialog(
              username: username,
            ));
  }
}

class SwitchUserDialog extends StatefulWidget {
  final String username;
  const SwitchUserDialog({super.key, required this.username});

  @override
  State<SwitchUserDialog> createState() => _SwitchUserDialogState();
}

class _SwitchUserDialogState extends State<SwitchUserDialog> {
  TextEditingController passwordController = TextEditingController();
  bool hidePassword = true;

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    passwordController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      title: Text('log in as ${widget.username}'),
      content: SizedBox(
        width: 200,
        height: 200,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                    controller: passwordController,
                  )),
            ],
          ),
        ),
      ),
      actions: [
        Button(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () async {
            if (passwordController.text.isNotEmpty) {
              final navigator = Navigator.of(context);
              await context
                  .read<UserProvider>()
                  .attemptLogin(widget.username, passwordController.text, null);
              if (mounted) {
                navigator.pop();
              }
            }
          },
          child: Text('Continue'),
        ),
      ],
    );
  }
}
