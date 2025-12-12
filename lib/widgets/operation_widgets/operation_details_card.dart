import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:weighing_system/utils/debugging_methods.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

class OperationDetailsCard extends StatelessWidget {
  final String label;
  final String value;
  final dynamic svgPath;

  const OperationDetailsCard(
      {super.key,
      required this.label,
      required this.value,
      required this.svgPath});

  @override
  Widget build(BuildContext context) {
    return Card(
        child: Column(
      children: [
        Row(
          children: [
            svgPath is String
                ? SvgPicture.asset(
                    svgPath,
                    width: 75,
                    height: 75,
                  )
                : Icon(
                    svgPath,
                    size: 75,
                  ),
            SizedBox(
              width: 4,
            ),
            Text(
              style: AppTheme.headerStyleBig,
              label,
            ),
          ],
        ),
        SizedBox(
          height: 6,
        ),
        Text(
          value,
          style: AppTheme.valueStyleBig,
        ),
      ],
    ));
  }
}

class OperationDetailsStatusCard extends OperationDetailsCard {
  const OperationDetailsStatusCard(
      {super.key,
      required super.label,
      required super.value,
      required super.svgPath});

  Widget parseStatus() {
    switch (value) {
      case 'مكتملة':
        return Icon(
          color: Colors.green,
          FluentIcons.check_mark,
          size: 75,
        );
      case 'ملغية':
        return Icon(
          color: Colors.red,
          FluentIcons.cancel,
          size: 75,
        );
      default:
        return Icon(
          color: Colors.blue,
          FluentIcons.sync,
          size: 75,
        );
    }
  }

  Color parseStatusColor() {
    switch (value) {
      case 'مكتملة':
        return Colors.green;
      case 'ملغية':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    printd(value);
    return Card(
        child: Column(
      children: [
        Row(
          children: [
            parseStatus(),
          ],
        ),
        SizedBox(
          height: 6,
        ),
        Text(
          value,
          style: AppTheme.valueStyleBig.copyWith(color: parseStatusColor()),
        ),
      ],
    ));
  }
}
