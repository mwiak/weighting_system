import 'package:fluent_ui/fluent_ui.dart';
import 'package:weighing_system/screens/clients_page.dart';
import 'package:weighing_system/screens/suppliers_page.dart';
import '../l10n/app_localizations.dart';

class ClientManagementScreen extends StatefulWidget {
  const ClientManagementScreen({super.key});

  @override
  State<ClientManagementScreen> createState() => _ClientManagementScreenState();
}

class _ClientManagementScreenState extends State<ClientManagementScreen> {
  int topIndex = 0;
  final PageStorageBucket bucket = PageStorageBucket();

  @override
  Widget build(BuildContext context) {
    return altBuild(context);
  }

  Widget altBuild(BuildContext context) {
    return PageStorage(
      bucket: bucket,
      child: NavigationView(
        pane: NavigationPane(
          displayMode: PaneDisplayMode.top,
          selected: topIndex,
          onChanged: (int i) => setState(() => topIndex = i),
          items: buildPaneItems(context),
        ),
      ),
    );
  }

  List<NavigationPaneItem> buildPaneItems(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    List<NavigationPaneItem> items = [
      PaneItem(
        icon: const SizedBox.shrink(),
        title: Text(l10n.clients),
        body: ClientsPage(),
      ),
      PaneItem(
        icon: const SizedBox.shrink(),
        title: Text(l10n.suppliers),
        body: SuppliersPage(),
      ),
    ];

    return items;
  }
}
