import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:weighing_system/utils/date_format.dart';

import '../../theme/app_theme.dart';

class OperationEntry extends StatelessWidget {
  final Map<String, dynamic> operation;
  final Function onPressed;

  const OperationEntry(
      {super.key, required this.operation, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey(
          'operation_${operation['id'] ?? operation['tab_id'] ?? DateTime.now().millisecondsSinceEpoch}'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.withOpacity(0.2)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          SizedBox(
              width: AppTheme.operationsHeaderItemWidthNormal,
              child: Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () {
                    onPressed(operation);
                  },
                  child:
                      Text('${operation['id'] ?? operation['tab_id'] ?? ''}'),
                ),
              )),
          SizedBox(
            width: AppTheme.operationsHeaderItemWidthNormal,
            child: Text(_formatDateTime(operation['created_at'])),
          ),
          SizedBox(
            width: AppTheme.operationsHeaderItemWidthNormal,
            child: Text(operation['truck_plate'] ?? ''),
          ),
          SizedBox(
            width: AppTheme.operationsHeaderItemWidthNormal,
            child: Text(operation['driver_name'] ?? ''),
          ),
          SizedBox(
              width: AppTheme.operationsHeaderItemWidthNormal,
              child: Text(operation['client'] ?? '')),
          SizedBox(
              width: AppTheme.operationsHeaderItemWidthNormal,
              child: Text(operation['supplier'] ?? '')),
          SizedBox(
              width: AppTheme.operationsHeaderItemWidthNormal,
              child: Text(_getMaterialName(operation))),
          SizedBox(
            width: AppTheme.operationsHeaderItemWidthNormal,
            child:
                Text('${(operation['net_weight'] ?? 0.0).toStringAsFixed(1)}'),
          ),
          SizedBox(
            width: AppTheme.operationsHeaderItemWidthNormal,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(operation['status']).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      _formatStatus(operation['status'], context),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(operation['status']),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (operation['notes'].isNotEmpty)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Tooltip(
                          message: 'ملاحظات: ' + operation['notes'],
                          child: Icon(FluentIcons.comment_active)),
                    )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(dynamic dateTime) {
    if (dateTime == null) return '';
    try {
      DateTime date = DateTime.parse(dateTime);
      return dateToArabicDatetimeOperationEntry(date);
      final dt = DateTime.parse(dateTime.toString());
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTime.toString();
    }
  }

  String _getMaterialName(Map<String, dynamic> operation) {
    // Handle multiple possible field names for material
    return operation['material'] ??
        operation['material_name'] ??
        operation['product_name'] ??
        'N/A';
  }

  Color _getStatusColor(dynamic status) {
    switch (status?.toString().toLowerCase()) {
      case 'complete':
      case 'completed':
        return Colors.green;
      case 'incomplete':
      case 'pending':
        return Colors.orange;
      case 'active':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatStatus(String status, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (status.toLowerCase()) {
      case 'completed':
        return l10n.statusCompleted;
      case 'in-progress':
      case 'inprogress':
        return l10n.statusInProgress;
      case 'incomplete':
        return l10n.statusIncomplete;
      case 'cancelled':
        return l10n.statusCancelled;
      case 'empty':
        return l10n.statusEmpty;
      default:
        // Fallback: capitalize each word
        return status
            .split('-')
            .map((word) => word[0].toUpperCase() + word.substring(1))
            .join(' ');
    }
  }
}
