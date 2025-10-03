import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../providers/tabs_provider.dart';
import '../models/weighing_tab.dart';
import 'weighing_tab_print_actions.dart';

class WeighingTabList extends StatelessWidget {
  const WeighingTabList({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer<TabsProvider>(
      builder: (context, tabsProvider, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    const Icon(FluentIcons.tab, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      l10n.activeTabs,
                      style: FluentTheme.of(context).typography.subtitle,
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${tabsProvider.tabCount}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Search Box
                    SizedBox(
                      width: 200,
                      child: TextBox(
                        placeholder: l10n.search,
                        prefix: const Icon(FluentIcons.search),
                        onChanged: (value) {
                          // TODO: Implement search functionality
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Tab List
                Expanded(
                  child: tabsProvider.isLoading
                      ? const Center(child: ProgressRing())
                      : tabsProvider.tabs.isEmpty
                          ? _buildEmptyState()
                          : _buildTabsList(context, tabsProvider),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            FluentIcons.tab,
            size: 48,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'No Active Tabs',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Create a new tab to get started',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildTabsList(BuildContext context, TabsProvider tabsProvider) {
    final tabs = tabsProvider.tabs;
    final l10n = AppLocalizations.of(context)!;

    return ListView.builder(
      itemCount: tabs.length,
      itemBuilder: (context, index) {
        final tab = tabs[index];
        final isSelected = tabsProvider.currentTabIndex == index;

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          child: ListTile.selectable(
            selected: isSelected,
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getStatusColor(tab).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getTabIcon(tab),
                color: _getStatusColor(tab),
                size: 20,
              ),
            ),
            title: Row(
              children: [
                Text(
                  tab.tabTitle,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getStatusColor(tab).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getStatusDisplay(tab, context),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(tab),
                    ),
                  ),
                ),
                if (tab.hasUnsavedChanges)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (tab.truckPlate.isNotEmpty) ...[
                      const Icon(FluentIcons.bus, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        tab.truckPlate,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                    if (tab.driverName.isNotEmpty) ...[
                      const SizedBox(width: 16),
                      const Icon(FluentIcons.contact, size: 14),
                      const SizedBox(width: 4),
                      Text(tab.driverName),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                if (tab.netWeight > 0)
                  Row(
                    children: [
                      const Icon(FluentIcons.scale_volume, size: 14),
                      const SizedBox(width: 4),
                      Text('${tab.netWeight.toStringAsFixed(0)} kg'),
                      const SizedBox(width: 16),
                      // Operation type removed from schema
                    ],
                  ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!tab.hasData)
                  FilledButton(
                    style: ButtonStyle(
                      padding: WidgetStateProperty.all(
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                    ),
                    onPressed: () => _startWeighing(context, tabsProvider, tab),
                    child: Text(l10n.start),
                  )
                else if (tab.isInProgress)
                  FilledButton(
                    style: ButtonStyle(
                      padding: WidgetStateProperty.all(
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                    ),
                    onPressed: () => _continueWeighing(context, tabsProvider, tab),
                    child: Text(l10n.continueButton),
                  )
                else if (tab.isComplete)
                  Button(
                    style: ButtonStyle(
                      padding: WidgetStateProperty.all(
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                    ),
                    onPressed: () => _completeTab(context, tabsProvider, tab),
                    child: Text(l10n.complete),
                  ),
                const SizedBox(width: 8),
                Button(
                  style: ButtonStyle(
                    padding: WidgetStateProperty.all(const EdgeInsets.all(8)),
                  ),
                  onPressed: () => _showTabActions(context, tabsProvider, tab),
                  child: const Icon(FluentIcons.more_vertical, size: 16),
                ),
              ],
            ),
            onSelectionChange: (selected) {
              if (selected) {
                tabsProvider.switchToTab(index);
              }
            },
          ),
        );
      },
    );
  }

  Color _getStatusColor(WeighingTab tab) {
    if (tab.isCompleted) return Colors.green;
    if (tab.isCancelled) return Colors.red;
    if (tab.isComplete) return Colors.blue;
    if (tab.isInProgress) return Colors.orange;
    return Colors.grey;
  }

  IconData _getTabIcon(WeighingTab tab) {
    if (tab.isCompleted) return FluentIcons.completed;
    if (tab.isCancelled) return FluentIcons.cancel;
    if (tab.isComplete) return FluentIcons.accept;
    if (tab.isInProgress) return FluentIcons.progress_ring_dots;
    return FluentIcons.add;
  }

  // _getOperationIcon method removed - operation type no longer used

  String _getStatusDisplay(WeighingTab tab, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (!tab.hasData) return l10n.empty;
    if (tab.isInProgress) return l10n.inProgress;
    if (tab.isComplete) return l10n.readyToComplete;
    if (tab.isCompleted) return l10n.completed;
    if (tab.isCancelled) return l10n.cancelled;
    return tab.status.toUpperCase();
  }

  void _startWeighing(BuildContext context, TabsProvider tabsProvider, WeighingTab tab) {
    // Switch to this tab to start working on it
    final tabIndex = tabsProvider.tabs.indexOf(tab);
    if (tabIndex != -1) {
      tabsProvider.switchToTab(tabIndex);
    }
  }

  void _continueWeighing(BuildContext context, TabsProvider tabsProvider, WeighingTab tab) {
    // Switch to this tab to continue working on it
    final tabIndex = tabsProvider.tabs.indexOf(tab);
    if (tabIndex != -1) {
      tabsProvider.switchToTab(tabIndex);
    }
  }

  void _completeTab(BuildContext context, TabsProvider tabsProvider, WeighingTab tab) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: Text(l10n.completeTabTitle),
        content: Text(l10n.markTabAsCompleted(tab.tabTitle)),
        actions: [
          Button(
            child: Text(l10n.cancel),
            onPressed: () => Navigator.of(context).pop(),
          ),
          FilledButton(
            child: Text(l10n.complete),
            onPressed: () {
              tab.completeTab();
              tabsProvider.saveTab(tab);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  void _showTabActions(BuildContext context, TabsProvider tabsProvider, WeighingTab tab) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: Text(l10n.tabTitle(tab.tabTitle)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Button(
              child: Row(
                children: [
                  const Icon(FluentIcons.edit),
                  const SizedBox(width: 8),
                  Text(l10n.switchToTab),
                ],
              ),
              onPressed: () {
                final tabIndex = tabsProvider.tabs.indexOf(tab);
                if (tabIndex != -1) {
                  tabsProvider.switchToTab(tabIndex);
                }
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: 8),
            Button(
              child: Row(
                children: [
                  const Icon(FluentIcons.print),
                  const SizedBox(width: 8),
                  Text(l10n.printActions),
                ],
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _showPrintActions(context, tab);
              },
            ),
            const SizedBox(height: 8),
            if (tab.isComplete && !tab.isCompleted)
              Button(
                child: Row(
                  children: [
                    const Icon(FluentIcons.accept),
                    const SizedBox(width: 8),
                    Text(l10n.completeTab),
                  ],
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  _completeTab(context, tabsProvider, tab);
                },
              ),
            const SizedBox(height: 8),
            Button(
              child: Row(
                children: [
                  const Icon(FluentIcons.cancel),
                  const SizedBox(width: 8),
                  Text(l10n.cancelTab),
                ],
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _cancelTab(context, tabsProvider, tab);
              },
            ),
            if (tab.hasData) ...[
              const SizedBox(height: 8),
              Button(
                child: Row(
                  children: [
                    const Icon(FluentIcons.delete),
                    const SizedBox(width: 8),
                    Text(l10n.closeTab),
                  ],
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  _closeTab(context, tabsProvider, tab);
                },
              ),
            ],
          ],
        ),
        actions: [
          Button(
            child: Text(l10n.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _showPrintActions(BuildContext context, WeighingTab tab) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: Text(l10n.printOptions(tab.tabTitle)),
        content: SizedBox(
          width: 400,
          child: WeighingTabPrintActionsWidget(
            tab: tab,
            showReceiptOption: true,
            showSaveOption: true,
          ),
        ),
        actions: [
          Button(
            child: Text(l10n.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _cancelTab(BuildContext context, TabsProvider tabsProvider, WeighingTab tab) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: Text(l10n.cancelTab),
        content: Text(l10n.areYouSureCancelTab(tab.tabTitle)),
        actions: [
          Button(
            child: Text(l10n.no),
            onPressed: () => Navigator.of(context).pop(),
          ),
          FilledButton(
            child: Text(l10n.yesCancel),
            onPressed: () async {
              Navigator.of(context).pop();
              // Use unified cancellation logic from TabsProvider
              final success = await tabsProvider.cancelTab(tabsProvider.tabs.indexOf(tab));
              if (!success) {
                // Show error if cancellation failed
                debugPrint('Failed to cancel tab');
              }
            },
          ),
        ],
      ),
    );
  }

  void _closeTab(BuildContext context, TabsProvider tabsProvider, WeighingTab tab) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: Text(l10n.closeTab),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.closeTabConfirm(tab.tabTitle)),
            if (tab.hasUnsavedChanges)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  l10n.warningUnsavedChanges,
                  style: TextStyle(color: Colors.orange),
                ),
              ),
          ],
        ),
        actions: [
          Button(
            child: Text(l10n.cancel),
            onPressed: () => Navigator.of(context).pop(),
          ),
          FilledButton(
            child: Text(l10n.close),
            onPressed: () {
              final tabIndex = tabsProvider.tabs.indexOf(tab);
              if (tabIndex != -1) {
                tabsProvider.closeTab(tabIndex);
              }
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}