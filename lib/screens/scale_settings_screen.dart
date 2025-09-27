import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import '../providers/weight_provider.dart';

class ScaleSettingsScreen extends StatefulWidget {
  const ScaleSettingsScreen({super.key});

  @override
  State<ScaleSettingsScreen> createState() => _ScaleSettingsScreenState();
}

class _ScaleSettingsScreenState extends State<ScaleSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: PageHeader(
        title: const Text('Scale Connection Settings'),
        commandBar: CommandBar(
          primaryItems: [
            CommandBarButton(
              icon: const Icon(FluentIcons.back),
              label: const Text('Back'),
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
                              'Connection Status',
                              style: FluentTheme.of(context).typography.subtitle,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          weightProvider.isConnected
                              ? 'Connected to ${weightProvider.connectedPort}'
                              : weightProvider.isScanning
                                  ? 'Scanning for devices...'
                                  : 'Not connected',
                          style: FluentTheme.of(context).typography.body,
                        ),
                        if (!weightProvider.isConnected) ...[
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: () => weightProvider.reconnect(),
                            child: const Text('Try to Connect'),
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
                          'Port Configuration',
                          style: FluentTheme.of(context).typography.subtitle,
                        ),
                        const SizedBox(height: 16),

                        // COM Port Selection
                        Row(
                          children: [
                            const SizedBox(
                              width: 120,
                              child: Text('COM Port:'),
                            ),
                            Expanded(
                              child: ComboBox<String>(
                                value: weightProvider.selectedPort,
                                items: weightProvider.getAvailablePorts().map(
                                  (port) => ComboBoxItem<String>(
                                    value: port,
                                    child: Text(port == 'auto' ? 'Auto-detect' : port),
                                  ),
                                ).toList(),
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
                            const SizedBox(
                              width: 120,
                              child: Text('Baud Rate:'),
                            ),
                            Expanded(
                              child: ComboBox<int>(
                                value: weightProvider.baudRate,
                                items: weightProvider.getAvailableBaudRates().map(
                                  (rate) => ComboBoxItem<int>(
                                    value: rate,
                                    child: Text(rate.toString()),
                                  ),
                                ).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    weightProvider.updateSettings(baudRate: value);
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
                            const SizedBox(
                              width: 120,
                              child: Text('Data Bits:'),
                            ),
                            Expanded(
                              child: ComboBox<int>(
                                value: weightProvider.dataBits,
                                items: weightProvider.getAvailableDataBits().map(
                                  (bits) => ComboBoxItem<int>(
                                    value: bits,
                                    child: Text(bits.toString()),
                                  ),
                                ).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    weightProvider.updateSettings(dataBits: value);
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
                            const SizedBox(
                              width: 120,
                              child: Text('Stop Bits:'),
                            ),
                            Expanded(
                              child: ComboBox<int>(
                                value: weightProvider.stopBits,
                                items: weightProvider.getAvailableStopBits().map(
                                  (bits) => ComboBoxItem<int>(
                                    value: bits,
                                    child: Text(bits.toString()),
                                  ),
                                ).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    weightProvider.updateSettings(stopBits: value);
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
                            const SizedBox(
                              width: 120,
                              child: Text('Parity:'),
                            ),
                            Expanded(
                              child: ComboBox<int>(
                                value: weightProvider.parity,
                                items: weightProvider.getAvailableParityOptions().entries.map(
                                  (entry) => ComboBoxItem<int>(
                                    value: entry.key,
                                    child: Text(entry.value),
                                  ),
                                ).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    weightProvider.updateSettings(parity: value);
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
                          'Scale Information',
                          style: FluentTheme.of(context).typography.subtitle,
                        ),
                        const SizedBox(height: 16),
                        
                        InfoLabel(
                          label: 'Protocol:',
                          child: const Text('Serial COM - Read Only'),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        InfoLabel(
                          label: 'Expected Format:',
                          child: const Text('(±)(6 digits)(KG)'),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        InfoLabel(
                          label: 'Reading Interval:',
                          child: const Text('100ms'),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        InfoLabel(
                          label: 'Connection Retry:',
                          child: const Text('Every 40ms'),
                        ),
                        
                        if (weightProvider.isConnected) ...[
                          const SizedBox(height: 16),
                          
                          InfoLabel(
                            label: 'Current Weight:',
                            child: Text(
                              '${weightProvider.currentWeight} kg',
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
                      child: const Text('Close'),
                    ),
                    const SizedBox(width: 12),
                    if (weightProvider.isConnected) ...[
                      Button(
                        onPressed: () {
                          weightProvider.disconnect();
                          _showInfoBar(context, 'Disconnected from scale', InfoBarSeverity.info);
                        },
                        child: const Text('Disconnect'),
                      ),
                      const SizedBox(width: 12),
                    ],
                    FilledButton(
                      onPressed: () {
                        weightProvider.reconnect();
                        _showInfoBar(context, 'Attempting to reconnect...', InfoBarSeverity.info);
                      },
                      child: const Text('Reconnect'),
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

  void _showInfoBar(BuildContext context, String message, InfoBarSeverity severity) {
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