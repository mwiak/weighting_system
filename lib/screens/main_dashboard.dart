import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:weighing_system/screens/reports_view.dart';
import 'package:weighing_system/screens/template_management_screen.dart';
import 'package:weighing_system/screens/weighting_operations_view.dart';
import '../providers/weight_provider.dart';
import '../providers/sync_provider.dart';
import '../providers/print_provider.dart';
import '../providers/report_provider.dart';
import '../providers/client_provider.dart';
import '../providers/app_settings_provider.dart';
import '../widgets/weight_display_card.dart';
import '../widgets/weighing_tab_list.dart';
import '../widgets/connection_status_bar.dart';
import '../widgets/weighing_tab_details.dart';
import 'client_management_screen.dart';
import 'material_management_screen.dart';
import 'tabs_screen.dart';
import 'drivers_trucks_screen.dart';
import 'odoo_settings_screen.dart';
import 'scale_settings_screen.dart';

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  int selectedIndex = 0;

  List<PaneItem> navigationItems(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      PaneItem(
        key: const ValueKey('/weighing'),
        icon: const Icon(FluentIcons.scale_volume),
        title: Text(l10n.weighingOperations),
        body: const TabsScreen(),
      ),
      PaneItem(
        key: const ValueKey('/orders'),
        icon: const Icon(FluentIcons.clipboard_list),
        title: Text(l10n.operationsHistory),
        body: const WeightingOperationsView(),
      ),
      PaneItem(
        key: const ValueKey('/clients'),
        icon: const Icon(FluentIcons.contact),
        title: Text(l10n.clients),
        body: const ClientManagementScreen(),
      ),
      PaneItem(
        key: const ValueKey('/materials'),
        icon: const Icon(FluentIcons.package),
        title: Text(l10n.materials),
        body: const MaterialManagementScreen(),
      ),
      PaneItem(
        key: const ValueKey('/drivers-trucks'),
        icon: const Icon(FluentIcons.bus),
        title: Text(l10n.driversAndTrucks),
        body: const DriversTrucksScreen(),
      ),
      PaneItem(
        key: const ValueKey('/reports'),
        icon: const Icon(FluentIcons.chart_series),
        title: Text(l10n.reports),
        body: const ReportsView(),
      ),
      PaneItem(
        key: const ValueKey('/template'),
        icon: const Icon(FluentIcons.chart_series),
        title: Text(l10n.printTemplates),
        body: const TemplateManagementScreen(),
      ),
    ];
  }

  List<PaneItem> footerItems(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      PaneItem(
        key: const ValueKey('/sync'),
        icon: const Icon(FluentIcons.sync),
        title: Text('Sync'), // Keep as is - technical term
        body: const SyncView(),
      ),
      PaneItem(
        key: const ValueKey('/settings'),
        icon: const Icon(FluentIcons.settings),
        title: Text(l10n.settings),
        body: const SettingsView(),
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Weight service starts automatically - no need to manually connect
    });
  }

  @override
  Widget build(BuildContext context) {
    return NavigationView(
      appBar: const NavigationAppBar(
        backgroundColor: Colors.transparent,
        height: 80,
        title: Center(child: WeightDisplayCard()),
        actions: Padding(
          padding: EdgeInsets.all(8.0),
          child: ConnectionStatusBar(),
        ),
      ),
      pane: NavigationPane(
        size: const NavigationPaneSize(openMaxWidth: 170, compactWidth: 50),
        selected: selectedIndex,
        onChanged: (index) => setState(() => selectedIndex = index),
        displayMode: PaneDisplayMode.open,
        items: navigationItems(context),
        footerItems: footerItems(context),
      ),
    );
  }
}

class SyncView extends StatelessWidget {
  const SyncView({super.key});

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage.scrollable(
      header: const PageHeader(
        title: Text('Synchronization'),
      ),
      children: [
        Consumer<SyncProvider>(
          builder: (context, syncProvider, child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sync Status',
                          style: FluentTheme.of(context).typography.subtitle,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              syncProvider.isOnline
                                  ? FluentIcons.sync
                                  : FluentIcons.offline_storage,
                              color: syncProvider.isOnline
                                  ? Colors.green
                                  : Colors.red,
                            ),
                            const SizedBox(width: 8),
                            Text(syncProvider.getConnectionStatusText() ??
                                'Unknown'),
                          ],
                        ),
                        if (syncProvider.pendingSyncCount > 0) ...[
                          const SizedBox(height: 8),
                          Text(
                              'Pending items: ${syncProvider.pendingSyncCount}'),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    FilledButton(
                      onPressed: syncProvider.canSync
                          ? () => syncProvider.performFullSync()
                          : null,
                      child: const Text('Sync Now'),
                    ),
                    const SizedBox(width: 12),
                    Button(
                      onPressed: () => syncProvider.clearFailedSyncItems(),
                      child: const Text('Clear Failed'),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage.scrollable(
      header: const PageHeader(
        title: Text('Settings'),
      ),
      children: [
        // Scale Connection Settings
        Consumer<WeightProvider>(
          builder: (context, weightProvider, child) {
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Scale Connection',
                          style: FluentTheme.of(context).typography.subtitle,
                        ),
                        const Spacer(),
                        Button(
                          onPressed: () {
                            Navigator.of(context).push(
                              FluentPageRoute(
                                builder: (context) =>
                                    const ScaleSettingsScreen(),
                              ),
                            );
                          },
                          child: const Text('Advanced Settings'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
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
                          weightProvider.isConnected
                              ? 'Connected to ${weightProvider.connectedPort}'
                              : weightProvider.isScanning
                                  ? 'Scanning for devices...'
                                  : 'Not connected',
                        ),
                        const Spacer(),
                        if (!weightProvider.isConnected)
                          FilledButton(
                            onPressed: () => weightProvider.reconnect(),
                            child: const Text('Reconnect'),
                          ),
                      ],
                    ),
                    if (weightProvider.isConnected) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text('Current Weight: '),
                          Text(
                            '${weightProvider.displayWeight} kg',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text('Port: ${weightProvider.selectedPort}'),
                          const SizedBox(width: 16),
                          Text('Baud: ${weightProvider.baudRate}'),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),

        // Print Settings
        // Consumer<PrintProvider>(
        //   builder: (context, printProvider, child) {
        //     return Card(
        //       child: Padding(
        //         padding: const EdgeInsets.all(16),
        //         child: Column(
        //           crossAxisAlignment: CrossAxisAlignment.start,
        //           children: [
        //             Text(
        //               'Print Settings',
        //               style: FluentTheme.of(context).typography.subtitle,
        //             ),
        //             const SizedBox(height: 16),
        //
        //             // Printer Status
        //             Row(
        //               children: [
        //                 const Icon(FluentIcons.print, size: 16),
        //                 const SizedBox(width: 8),
        //                 const Text('Printer Status:'),
        //                 const SizedBox(width: 12),
        //                 FutureBuilder<bool>(
        //                   future: printProvider.checkPrinterAvailability(),
        //                   builder: (context, snapshot) {
        //                     if (snapshot.connectionState ==
        //                         ConnectionState.waiting) {
        //                       return const SizedBox(
        //                         width: 16,
        //                         height: 16,
        //                         child: ProgressRing(strokeWidth: 2),
        //                       );
        //                     }
        //
        //                     final canPrint = snapshot.data ?? false;
        //                     return Row(
        //                       children: [
        //                         Icon(
        //                           canPrint
        //                               ? FluentIcons.accept
        //                               : FluentIcons.error,
        //                           color: canPrint ? Colors.green : Colors.red,
        //                           size: 16,
        //                         ),
        //                         const SizedBox(width: 4),
        //                         Text(canPrint ? 'Available' : 'Not Available'),
        //                       ],
        //                     );
        //                   },
        //                 ),
        //               ],
        //             ),
        //             const SizedBox(height: 16),
        //
        //             // Company Name Setting
        //             Row(
        //               children: [
        //                 Expanded(
        //                   child: InfoLabel(
        //                     label: 'Company Name',
        //                     child: TextFormBox(
        //                       placeholder: 'Enter company name for documents',
        //                       onChanged: (value) {
        //                         // TODO: Implement company info update
        //                         // printProvider.updateCompanyInfo({'name': value});
        //                       },
        //                     ),
        //                   ),
        //                 ),
        //                 const SizedBox(width: 12),
        //                 Button(
        //                   onPressed: () {
        //                     displayInfoBar(
        //                       context,
        //                       builder: (context, close) => InfoBar(
        //                         title: const Text('Print test coming soon'),
        //                         severity: InfoBarSeverity.info,
        //                         action: IconButton(
        //                           icon: const Icon(FluentIcons.clear),
        //                           onPressed: close,
        //                         ),
        //                       ),
        //                     );
        //                   },
        //                   child: const Text('Test Print'),
        //                 ),
        //               ],
        //             ),
        //
        //             if (printProvider.lastPrintedDocument != null) ...[
        //               const SizedBox(height: 12),
        //               InfoBar(
        //                 title: const Text('Last Action'),
        //                 content: Text(
        //                     printProvider.lastPrintedDocument ?? 'No document'),
        //                 severity: InfoBarSeverity.info,
        //                 action: Button(
        //                   onPressed: () {
        //                     // TODO: Implement clear last printed document
        //                     // printProvider.clearLastPrintedDocument();
        //                   },
        //                   child: const Text('Clear'),
        //                 ),
        //               ),
        //             ],
        //           ],
        //         ),
        //       ),
        //     );
        //   },
        // ),
        const SizedBox(height: 16),

        // Odoo Integration Settings
        // Consumer<AppSettingsProvider>(
        //   builder: (context, settingsProvider, child) {
        //     return Card(
        //       child: Padding(
        //         padding: const EdgeInsets.all(16),
        //         child: Column(
        //           crossAxisAlignment: CrossAxisAlignment.start,
        //           children: [
        //             Text(
        //               'Odoo Integration',
        //               style: FluentTheme.of(context).typography.subtitle,
        //             ),
        //             const SizedBox(height: 16),
        //
        //             // Connection Status
        //             Row(
        //               children: [
        //                 const Icon(FluentIcons.cloud, size: 16),
        //                 const SizedBox(width: 8),
        //                 const Text('Status:'),
        //                 const SizedBox(width: 12),
        //                 FutureBuilder<String?>(
        //                   future: Future.value(
        //                       settingsProvider.getSetting('odoo_url')?.value),
        //                   builder: (context, snapshot) {
        //                     final hasUrl = snapshot.data?.isNotEmpty ?? false;
        //                     return Row(
        //                       children: [
        //                         Icon(
        //                           hasUrl
        //                               ? FluentIcons.cloud_upload
        //                               : FluentIcons.plug_disconnected,
        //                           color: hasUrl ? Colors.blue : Colors.grey,
        //                           size: 16,
        //                         ),
        //                         const SizedBox(width: 4),
        //                         Text(hasUrl ? 'Configured' : 'Not Configured'),
        //                       ],
        //                     );
        //                   },
        //                 ),
        //               ],
        //             ),
        //             const SizedBox(height: 16),
        //
        //             // Configuration Button
        //             Button(
        //               onPressed: () {
        //                 Navigator.push(
        //                   context,
        //                   FluentPageRoute(
        //                     builder: (context) => const OdooSettingsScreen(),
        //                   ),
        //                 );
        //               },
        //               child: const Text('Configure Odoo Settings'),
        //             ),
        //
        //             const SizedBox(height: 12),
        //
        //             Text(
        //               'Configure connection to Odoo ERP for automatic synchronization of clients, suppliers, materials, and orders.',
        //               style: TextStyle(
        //                 color: Colors.grey[120],
        //                 fontSize: 12,
        //               ),
        //             ),
        //           ],
        //         ),
        //       ),
        //     );
        //   },
        // ),
      ],
    );
  }
}
