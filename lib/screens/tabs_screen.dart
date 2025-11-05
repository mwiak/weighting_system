import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import 'package:weighing_system/models/user.dart';
import 'package:weighing_system/providers/user_provider.dart';
import 'package:weighing_system/widgets/admin_weighting_tab_content.dart';
import '../providers/tabs_provider.dart';
import '../widgets/weighing_tab_content.dart';
import '../widgets/weight_display_card.dart';

class TabsScreen extends StatefulWidget {
  const TabsScreen({super.key});

  @override
  State<TabsScreen> createState() => _TabsScreenState();
}

class _TabsScreenState extends State<TabsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TabsProvider>().initialize();
    });
  }

  void _createNewTab() async {
    final provider = context.read<TabsProvider>();
    final success = await provider.createNewTab();
    if (!success) {
      _showMaxTabsReachedDialog();
    }
  }

  void _closeTab(int index) async {
    final provider = context.read<TabsProvider>();
    final tab = provider.tabs[index];

    // Check if tab has data and warn user
    if (tab.hasData) {
      _showCloseTabConfirmation(index);
      return;
    }

    // Close tab without warning if it has no data
    await provider.forceCloseTab(index);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Consumer<TabsProvider>(
      builder: (context, provider, child) {
        return ScaffoldPage(
          padding: EdgeInsets.symmetric(vertical: 0, horizontal: 5),
          content: Column(
            children: [
              // Command Bar
              SizedBox(
                height: 35,
                child: Consumer<UserProvider>(
                  builder: (context, value, child) {
                    return CommandBar(
                      primaryItems: [
                        CommandBarButton(
                          icon: const Icon(FluentIcons.add),
                          label: Text(l10n.newTab),
                          onPressed:
                              provider.canCreateNewTab() ? _createNewTab : null,
                        ),
                        if (value.activeUser!.type == UserRanks.admin)
                          CommandBarButton(
                            icon:
                                const Icon(FluentIcons.admin_d_logo_inverse32),
                            label: Text('إضافة يدوية'),
                            onPressed: () {
                              _showManualAddDialog();
                            },
                          ),
                      ],
                    );
                  },
                ),
              ),

              // Loading indicator
              if (provider.isLoading) const ProgressBar(),

              // Custom Tab Bar using Fluent UI
              if (provider.hasActiveTabs)
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.grey[20],
                    border: Border(
                        bottom:
                            BorderSide(color: Colors.grey[60] ?? Colors.grey)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: provider.tabs.length,
                          itemBuilder: (context, index) {
                            final tab = provider.tabs[index];
                            final isActive = index == provider.currentTabIndex;

                            return GestureDetector(
                              onTap: () => provider.switchToTab(index),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 2, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? Colors.white
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(4),
                                  border: isActive
                                      ? Border.all(color: Colors.blue)
                                      : null,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Status indicator

                                    const SizedBox(width: 8),
                                    Text(
                                      tab.tabTitle,
                                      style: TextStyle(
                                        fontWeight: isActive
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

              // Tab Content - Scrollable or Empty State
              Expanded(
                child: !provider.hasActiveTabs
                    ? _buildEmptyState(context)
                    : provider.currentTabIndex >= 0
                        ? SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            child: WeighingTabContent(
                              key: ValueKey(
                                  'tab_content_${provider.currentTabIndex}'),
                              tabIndex: provider.currentTabIndex,
                            ),
                          )
                        : Center(
                            child: Text(l10n
                                .activeOperationsExist)), // Keep as fallback
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMaxTabsReachedDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: Text(l10n.maximumTabsReached),
        content: Text(l10n.maximumTabsMessage(15, Object())),
        actions: [
          FilledButton(
            child: Text(l10n.ok),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _showCloseTabConfirmation(int index) {
    final provider = context.read<TabsProvider>();
    final tab = provider.tabs[index];
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: Text(l10n.closeTab),
        content: Text(l10n.tabUnsavedChanges),
        actions: [
          Button(
            child: Text(l10n.cancel),
            onPressed: () => Navigator.of(context).pop(),
          ),
          FilledButton(
            child: Text(l10n.closeTab),
            onPressed: () {
              Navigator.of(context).pop();
              provider.forceCloseTab(index);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              FluentIcons.scale_volume,
              size: 64,
              color: Colors.grey[80],
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noActiveTabs,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[100],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.clickNewTabToStart,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[80],
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _createNewTab,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(FluentIcons.add, size: 16),
                  const SizedBox(width: 8),
                  Text(l10n.newOperation),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showManualAddDialog() async {
    context.read<TabsProvider>().createInMemoryManualTab();
    showDialog(
        context: context,
        builder: (context) {
          //TODO
          return AdminWeightingTabContent();
        });
  }
}
