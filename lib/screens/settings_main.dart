import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:weighing_system/database/database_helper.dart';
import 'package:weighing_system/services/backup_service.dart';
import 'package:weighing_system/utils/debugging_methods.dart';
import 'package:weighing_system/utils/info_bars.dart';
import '../l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:weighing_system/models/user.dart';
import 'package:weighing_system/providers/user_provider.dart';
import 'package:weighing_system/screens/scale_settings_screen.dart';
import 'package:weighing_system/screens/user_management_screen.dart';

import '../providers/weight_provider.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  int topIndex = 0;
  final PageStorageBucket bucket = PageStorageBucket();

  List<NavigationPaneItem> buildPaneItems(BuildContext context, type) {
    final l10n = AppLocalizations.of(context)!;
    List<NavigationPaneItem> items = [
      PaneItem(
        icon: const SizedBox.shrink(),
        title: Text(l10n.generalSettings),
        body: GeneralSettings(),
      ),
    ];
    List<NavigationPaneItem> adminPanes = [
      PaneItem(
        icon: const SizedBox.shrink(),
        title: Text(l10n.users),
        body: const UserManagementScreen(),
      )
    ];

    if (type == UserRanks.admin) items.addAll(adminPanes);

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final type = Provider.of<UserProvider>(context).activeUser!.type;
    return PageStorage(
      bucket: bucket,
      child: NavigationView(
        pane: NavigationPane(
          displayMode: PaneDisplayMode.top,
          selected: topIndex,
          onChanged: (int i) => setState(() => topIndex = i),
          items: buildPaneItems(context, type) as List<NavigationPaneItem>,
        ),
      ),
    );
  }
}

class GeneralSettings extends StatefulWidget {
  const GeneralSettings({super.key});

  @override
  State<GeneralSettings> createState() => _GeneralSettingsState();
}

class _GeneralSettingsState extends State<GeneralSettings> {
  bool isSubmiting = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ScaffoldPage.scrollable(
      header: PageHeader(
        title: Text(l10n.settings),
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
                          l10n.scaleConnection,
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
                          child: Text(l10n.advancedSettings),
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
                              ? l10n.connectedToPort(
                                  weightProvider.connectedPort ?? '')
                              : weightProvider.isScanning
                                  ? l10n.scanningForDevices
                                  : l10n.notConnected,
                        ),
                        const Spacer(),
                        if (!weightProvider.isConnected)
                          FilledButton(
                            onPressed: () => weightProvider.reconnect(),
                            child: Text(l10n.reconnect),
                          ),
                      ],
                    ),
                    if (weightProvider.isConnected) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(l10n.currentWeightLabel),
                          Text(
                            '${weightProvider.displayWeight} ${l10n.kg}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text('${l10n.port}${weightProvider.selectedPort}'),
                          const SizedBox(width: 16),
                          Text('${l10n.baud}${weightProvider.baudRate}'),
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
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'النسخ الاحتياطي',
                      style: FluentTheme.of(context).typography.subtitle,
                    ),
                    const Spacer(),
                    Button(
                      onPressed: isSubmiting ? null : _handleUpload,
                      child:
                          isSubmiting ? const ProgressRing() : Text('نسخ الان'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
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

  void _handleUpload() async {
    if (isSubmiting) return;

    isSubmiting = true;

    setState(() {});

    try {
      final file = await DatabaseHelper().getDatabaseCopy();
      printd(file.toString());
      if (file != null) {
        final backup = BackupService();
        final response = await backup.uploadToS3WithDio(file);
        if (response == 1) {
          if (!mounted) return;
          showSuccessDialog(context: context);
        } else {
          showErrorDialog(context: context);
        }
      }
    } catch (e) {
      showErrorDialog(context: context, message: '${e.toString()}');
    } finally {
      isSubmiting = false;
      if (mounted) {
        setState(() {});
      }
    }
  }
}
