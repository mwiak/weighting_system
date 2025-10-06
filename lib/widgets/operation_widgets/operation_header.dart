import 'dart:math';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:weighing_system/theme/app_theme.dart';

class OperationHeader extends StatelessWidget {
  const OperationHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        SizedBox(
          width: AppTheme.operationsHeaderItemWidthNormal,
          child: Text(l10n.orderNumber, style: AppTheme.headerStyle),
        ),
        SizedBox(
            width: AppTheme.operationsHeaderItemWidthNormal,
            child: Text(l10n.dateTime, style: AppTheme.headerStyle)),
        SizedBox(
          width: AppTheme.operationsHeaderItemWidthNormal,
          child: Text(
            l10n.truckPlate,
            style: AppTheme.headerStyle,
          ),
        ),
        SizedBox(
          width: AppTheme.operationsHeaderItemWidthNormal,
          child: Text(l10n.driverName, style: AppTheme.headerStyle),
        ),
        SizedBox(
          width: AppTheme.operationsHeaderItemWidthNormal,
          child: Text(l10n.client, style: AppTheme.headerStyle),
        ),
        SizedBox(
          width: AppTheme.operationsHeaderItemWidthNormal,
          child: Text(l10n.supplier, style: AppTheme.headerStyle),
        ),
        SizedBox(
          width: AppTheme.operationsHeaderItemWidthNormal,
          child: Text(l10n.material, style: AppTheme.headerStyle),
        ),
        SizedBox(
          width: AppTheme.operationsHeaderItemWidthNormal,
          child: Text(l10n.netWeightKg, style: AppTheme.headerStyle),
        ),
        SizedBox(
          width: AppTheme.operationsHeaderItemWidthNormal,
          child: Text(l10n.status,
              textAlign: TextAlign.center, style: AppTheme.headerStyle),
        ),
      ],
    );
  }
}
