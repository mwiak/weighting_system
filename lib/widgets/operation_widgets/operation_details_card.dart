import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

class OperationDetailsCard extends StatelessWidget {
  final String label;
  final String value;
  final String svgPath;

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
            SvgPicture.asset(
              svgPath,
              width: 75,
              height: 75,
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
        Text(
          value,
          style: AppTheme.valueStyleBig,
        ),
      ],
    ));
  }
}
