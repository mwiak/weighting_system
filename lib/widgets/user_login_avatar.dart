import 'package:fluent_ui/fluent_ui.dart';

import '../models/user.dart';

class UserLoginAvatar extends StatefulWidget {
  final Function onPressed;
  final User user;

  const UserLoginAvatar(
      {super.key, required this.onPressed, required this.user});

  @override
  State<UserLoginAvatar> createState() => _UserLoginAvatarState();
}

class _UserLoginAvatarState extends State<UserLoginAvatar> {
  Color avatarColor = Colors.blue.withOpacity(0.6);

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (e) {
        setState(() {
          avatarColor = Colors.blue.withOpacity(0.45);
        });
      },
      onExit: (e) {
        setState(() {
          avatarColor = Colors.blue.withOpacity(0.6);
        });
      },
      child: GestureDetector(
        onTap: () {
          setState(() {
            avatarColor = Colors.blue.withOpacity(0.8);
          });
          widget.onPressed(widget.user.username);
        },
        child: CircleAvatar(
          radius: 60,
          backgroundColor: avatarColor,
          child: Text(widget.user.username),
        ),
      ),
    );
  }
}
