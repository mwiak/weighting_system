import 'dart:math';
import '/l10n/app_localizations.dart';
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

class OperationDetailsHeader extends StatelessWidget {
  const OperationDetailsHeader({super.key});

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
            child: Text(l10n.emptyWeight, style: AppTheme.headerStyle)),
        SizedBox(
            width: AppTheme.operationsHeaderItemWidthNormal,
            child: Text(l10n.grossWeight, style: AppTheme.headerStyle)),
        SizedBox(
            width: AppTheme.operationsHeaderItemWidthNormal,
            child: Text(l10n.unitPrice, style: AppTheme.headerStyle)),
        SizedBox(
            width: AppTheme.operationsHeaderItemWidthNormal,
            child: Text(l10n.totalAmount, style: AppTheme.headerStyle)),
      ],
    );
  }
}
