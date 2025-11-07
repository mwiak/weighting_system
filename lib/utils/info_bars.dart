import 'package:fluent_ui/fluent_ui.dart';

void showSuccessDialog(
    {required BuildContext context, String message = 'تمت العملية بنجاح'}) {
  displayInfoBar(
    context,
    builder: (context, close) => InfoBar(
      title: Text(message),
      severity: InfoBarSeverity.info,
    ),
  );
}

void showErrorDialog(
    {required BuildContext context, String message = 'فشلت العملية'}) {
  displayInfoBar(
    context,
    builder: (context, close) => InfoBar(
      title: Text(message),
      severity: InfoBarSeverity.error,
    ),
  );
}
