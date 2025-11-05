import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/weight_provider.dart';

class ScaleSettingsScreen extends StatefulWidget {
  const ScaleSettingsScreen({super.key});

  @override
  State<ScaleSettingsScreen> createState() => _ScaleSettingsScreenState();
}

class _ScaleSettingsScreenState extends State<ScaleSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ScaffoldPage(
      header: PageHeader(
        title: Text(l10n.scaleConnectionSettings),
        commandBar: CommandBar(
          primaryItems: [
            CommandBarButton(
              icon: const Icon(FluentIcons.back),
              label: Text(l10n.back),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
      content: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Consumer<WeightProvider>(
          builder: (context, weightProvider, child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Connection Status Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              weightProvider.isConnected
                                  ? FluentIcons.accept
                                  : FluentIcons.error_badge,
                              color: weightProvider.isConnected
                                  ? Colors.green
                                  : Colors.red,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l10n.connectionStatus,
                              style:
                                  FluentTheme.of(context).typography.subtitle,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          weightProvider.isConnected
                              ? '${l10n.connectedTo} ${weightProvider.connectedPort}'
                              : weightProvider.isScanning
                                  ? l10n.scanningForDevices
                                  : l10n.notConnected,
                          style: FluentTheme.of(context).typography.body,
                        ),
                        if (!weightProvider.isConnected) ...[
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: () => weightProvider.reconnect(),
                            child: Text(l10n.tryToConnect),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Port Settings
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.portConfiguration,
                          style: FluentTheme.of(context).typography.subtitle,
                        ),
                        const SizedBox(height: 16),

                        // COM Port Selection
                        Row(
                          children: [
                            SizedBox(
                              width: 120,
                              child: Text(l10n.comPort),
                            ),
                            Expanded(
                              child: ComboBox<String>(
                                value: weightProvider.selectedPort,
                                items: weightProvider
                                    .getAvailablePorts()
                                    .map(
                                      (port) => ComboBoxItem<String>(
                                        value: port,
                                        child: Text(port == 'auto'
                                            ? l10n.autoDetect
                                            : port),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    weightProvider.updateSettings(port: value);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Baud Rate
                        Row(
                          children: [
                            SizedBox(
                              width: 120,
                              child: Text(l10n.baudRate),
                            ),
                            Expanded(
                              child: ComboBox<int>(
                                value: weightProvider.baudRate,
                                items: weightProvider
                                    .getAvailableBaudRates()
                                    .map(
                                      (rate) => ComboBoxItem<int>(
                                        value: rate,
                                        child: Text(rate.toString()),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    weightProvider.updateSettings(
                                        baudRate: value);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Data Bits
                        Row(
                          children: [
                            SizedBox(
                              width: 120,
                              child: Text(l10n.dataBits),
                            ),
                            Expanded(
                              child: ComboBox<int>(
                                value: weightProvider.dataBits,
                                items: weightProvider
                                    .getAvailableDataBits()
                                    .map(
                                      (bits) => ComboBoxItem<int>(
                                        value: bits,
                                        child: Text(bits.toString()),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    weightProvider.updateSettings(
                                        dataBits: value);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Stop Bits
                        Row(
                          children: [
                            SizedBox(
                              width: 120,
                              child: Text(l10n.stopBits),
                            ),
                            Expanded(
                              child: ComboBox<int>(
                                value: weightProvider.stopBits,
                                items: weightProvider
                                    .getAvailableStopBits()
                                    .map(
                                      (bits) => ComboBoxItem<int>(
                                        value: bits,
                                        child: Text(bits.toString()),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    weightProvider.updateSettings(
                                        stopBits: value);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Parity
                        Row(
                          children: [
                            SizedBox(
                              width: 120,
                              child: Text(l10n.parity),
                            ),
                            Expanded(
                              child: ComboBox<int>(
                                value: weightProvider.parity,
                                items: weightProvider
                                    .getAvailableParityOptions()
                                    .entries
                                    .map(
                                      (entry) => ComboBoxItem<int>(
                                        value: entry.key,
                                        child: Text(entry.value),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    weightProvider.updateSettings(
                                        parity: value);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Scale Information
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.scaleInformation,
                          style: FluentTheme.of(context).typography.subtitle,
                        ),
                        const SizedBox(height: 16),
                        InfoLabel(
                          label: l10n.protocol,
                          child: Text(l10n.serialComReadOnly),
                        ),
                        const SizedBox(height: 12),
                        InfoLabel(
                          label: l10n.expectedFormat,
                          child: Text(l10n.weightFormatExample),
                        ),
                        const SizedBox(height: 12),
                        InfoLabel(
                          label: l10n.readingInterval,
                          child: Text(l10n.readingInterval100ms),
                        ),
                        const SizedBox(height: 12),
                        InfoLabel(
                          label: l10n.connectionRetry,
                          child: Text(l10n.connectionRetryInterval),
                        ),
                        if (weightProvider.isConnected) ...[
                          const SizedBox(height: 16),
                          InfoLabel(
                            label: l10n.currentWeightLabel,
                            child: Text(
                              '${weightProvider.currentWeight} ${l10n.kgUnit}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Actions
                Row(
                  children: [
                    Button(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l10n.close),
                    ),
                    const SizedBox(width: 12),
                    if (weightProvider.isConnected) ...[
                      Button(
                        onPressed: () {
                          weightProvider.disconnect();
                          _showInfoBar(context, l10n.disconnectedFromScale,
                              InfoBarSeverity.info);
                        },
                        child: Text(l10n.disconnect),
                      ),
                      const SizedBox(width: 12),
                    ],
                    FilledButton(
                      onPressed: () {
                        weightProvider.reconnect();
                        _showInfoBar(context, l10n.attemptingToReconnect,
                            InfoBarSeverity.info);
                      },
                      child: Text(l10n.reconnect),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showInfoBar(
      BuildContext context, String message, InfoBarSeverity severity) {
    displayInfoBar(
      context,
      builder: (context, close) => InfoBar(
        title: Text(message),
        severity: severity,
        action: IconButton(
          icon: const Icon(FluentIcons.clear),
          onPressed: close,
        ),
      ),
    );
  }
}
