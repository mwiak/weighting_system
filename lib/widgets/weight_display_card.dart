import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:weighing_system/services/weight_service_t.dart';
import '../providers/weight_provider.dart';
import '../theme/app_theme.dart';
import '../utils/debugging_methods.dart';

class WeightDisplayCard extends StatelessWidget {
  const WeightDisplayCard({super.key});

  String handleError(String? lastError) {
    if (lastError == null) {
      return ' ';
    } else {
      if (lastError == ' ') {
        return ' ';
      } else {
        return '';
      }
    }
  }

  String handleStatus(ConnectionStatus status, AppLocalizations l10n) {
    printd('the current UI is' + status.toString());
    switch (status) {
      case ConnectionStatus.connected:
        return l10n.connected;
      case ConnectionStatus.disconnected:
        return l10n.disconnected;
      case ConnectionStatus.replugError:
        return l10n.replugDevice;
      case ConnectionStatus.hasError:
        return l10n.unknownError;
      case ConnectionStatus.reconnecting:
        return l10n.reconnecting;
      case ConnectionStatus.notFound:
        return l10n.noDevicesAvailable;
      case ConnectionStatus.scanning:
        return l10n.scanning;
      case ConnectionStatus.initial:
        return l10n.connecting;
      default:
        return l10n.unknown;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer<WeightProvider>(
      builder: (context, weightProvider, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: SizedBox(
              height: 80,
              width: 600,
              child: Column(
                children: [
                  // Header
                  Row(
                    children: [
                      if (weightProvider.status ==
                              ConnectionStatus.reconnecting ||
                          weightProvider.status == ConnectionStatus.scanning ||
                          weightProvider.status ==
                              ConnectionStatus.disconnected ||
                          weightProvider.status == ConnectionStatus.notFound ||
                          weightProvider.status == ConnectionStatus.error) ...[
                        FilledButton(
                          onPressed: () => weightProvider.reconnect(),
                          child: Text(l10n.reconnectToScale),
                        ),
                      ],
                      const SizedBox(width: 8),
                      Text(
                        handleStatus(weightProvider.status, l10n),
                        style: TextStyle(
                          color: weightProvider.isConnected
                              ? Colors.green
                              : Colors.yellow.dark,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(weightProvider),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getStatusText(weightProvider, l10n),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Weight Display
                  Column(
                    children: [
                      Text.rich(
                        TextSpan(
                            text: weightProvider.displayWeight.toString(),
                            style: TextStyle(
                              fontSize: 38,
                              fontWeight: FontWeight.bold,
                              color: weightProvider.isConnected
                                  ? Colors.green
                                  : Colors.yellow.dark,
                            ),
                            children: [
                              TextSpan(
                                  text: ' ${l10n.kg}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.secondaryTextColor,
                                  ))
                            ]),
                      ),
                    ],
                  ),

                  // Weight Details
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(WeightProvider weightProvider) {
    if (!weightProvider.isConnected) return AppTheme.errorColor;
    return AppTheme.successColor;
  }

  String _getStatusText(WeightProvider weightProvider, AppLocalizations l10n) {
    if (!weightProvider.isConnected) return l10n.disconnected;
    if (weightProvider.isScanning) return l10n.scanning;
    return l10n.connected;
  }
}
