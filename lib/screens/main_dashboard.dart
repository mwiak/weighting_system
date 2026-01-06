import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import 'package:weighing_system/models/user.dart';
import 'package:weighing_system/providers/user_provider.dart';
import 'package:weighing_system/screens/settings_main.dart';
import 'package:weighing_system/screens/summaries_screen.dart';
import 'package:weighing_system/screens/template_management_screen.dart';
import 'package:weighing_system/screens/weighting_operations_view.dart';
import 'package:weighing_system/widgets/current_user_panel.dart';
import '../providers/sync_provider.dart';
import '../widgets/weight_display_card.dart';
import 'client_management_screen.dart';
import 'material_management_screen.dart';
import 'tabs_screen.dart';
import 'drivers_trucks_screen.dart';

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  int selectedIndex = 0;

  // Cached navigation items to prevent rebuilds on navigation
  List<PaneItem>? _cachedNavigationItems;
  List<PaneItem>? _cachedFooterItems;

  List<PaneItem> navigationItems(BuildContext context) {
    if (_cachedNavigationItems != null) return _cachedNavigationItems!;
    final l10n = AppLocalizations.of(context)!;
    UserRanks type =
        Provider.of<UserProvider>(context, listen: true).activeUser!.type;
    List<PaneItem> adminPanes = [
      PaneItem(
        key: const ValueKey('/summaries'),
        icon: const Icon(FluentIcons.data_flow),
        //TODO localize
        title: Text('الجرد'),
        body: const SummariesScreen(),
      ),
      PaneItem(
        key: const ValueKey('/template'),
        icon: const Icon(FluentIcons.chart_series),
        title: Text(l10n.printTemplates),
        body: const TemplateManagementScreen(),
      ),
    ];

    final items = [
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
      if (type == UserRanks.admin) ...adminPanes
    ];
    _cachedNavigationItems = items;
    return items;
  }

  List<PaneItem> footerItems(BuildContext context) {
    if (_cachedFooterItems != null) return _cachedFooterItems!;
    final l10n = AppLocalizations.of(context)!;
    final items = [
      PaneItem(
        key: const ValueKey('/settings'),
        icon: const Icon(FluentIcons.settings),
        title: Text(l10n.settings),
        body: const SettingsView(),
      ),
    ];
    _cachedFooterItems = items;
    return items;
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
          child: CurrentUserPanel(),
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
    final l10n = AppLocalizations.of(context)!;
    return ScaffoldPage.scrollable(
      header: PageHeader(
        title: Text(l10n.synchronization),
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
                          l10n.syncStatus,
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
                                l10n.unknown),
                          ],
                        ),
                        if (syncProvider.pendingSyncCount > 0) ...[
                          const SizedBox(height: 8),
                          Text(
                              '${l10n.pendingItems}: ${syncProvider.pendingSyncCount}'),
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
                      child: Text(l10n.syncNow),
                    ),
                    const SizedBox(width: 12),
                    Button(
                      onPressed: () => syncProvider.clearFailedSyncItems(),
                      child: Text(l10n.clearFailed),
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
