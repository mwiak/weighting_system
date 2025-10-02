import 'package:fluent_ui/fluent_ui.dart';

void navigateToWithReplacement(Widget route, BuildContext context) {
  Navigator.of(context)
      .pushReplacement(FluentPageRoute(builder: (context) => route));
}

void safePop(BuildContext context) {
  if (Navigator.of(context).canPop()) {
    Navigator.of(context).pop();
  }
}
