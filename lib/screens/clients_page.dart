import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/client.dart';
import '../providers/client_provider.dart';
import '../widgets/client_form_dialog.dart';

class ClientsPage extends StatefulWidget {
  const ClientsPage({super.key});

  @override
  State<ClientsPage> createState() => _ClientsPageState();
}

class _ClientsPageState extends State<ClientsPage> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer<ClientProvider>(builder: (context, clientProvider, child) {
      return ScaffoldPage.scrollable(
          padding: EdgeInsets.zero,
          header: CommandBar(
            primaryItems: [
              CommandBarButton(
                icon: const Icon(FluentIcons.add),
                label: Text(l10n.newClient),
                onPressed: () => _showCreateClientDialog(context, l10n),
              ),
              CommandBarButton(
                icon: const Icon(FluentIcons.refresh),
                label: Text(l10n.refresh),
                onPressed: () => clientProvider.loadClients(),
              ),
              const CommandBarSeparator(),
            ],
          ),
          children: _buildClientContent(context, clientProvider, l10n));
    });
  }

  List<Widget> _buildClientContent(BuildContext context,
      ClientProvider clientProvider, AppLocalizations l10n) {
    return [
      // Statistics Cards
      Card(
        child: Row(
          children: [
            _buildStatCard(
              context: context,
              title: l10n.totalClients,
              value: '${clientProvider.totalClients}',
              icon: FluentIcons.contact,
              color: Colors.blue,
              secondTitle: l10n.activeClients,
              secondValue: '${clientProvider.activeClients.length}',
            ),
            const SizedBox(width: 16),
            const Spacer(),
            SizedBox(
              width: 300,
              child: TextBox(
                placeholder: l10n.searchClients,
                prefix: const Icon(FluentIcons.search),
                onChanged: clientProvider.setSearchQuery,
              ),
            ),
            const SizedBox(width: 16),

            // Active Only Filter
            Checkbox(
              checked: clientProvider.showActiveOnly,
              onChanged: (value) =>
                  clientProvider.setShowActiveOnly(value ?? true),
              content: Text(l10n.activeOnly),
            ),
            const Spacer(),

            // Clear Filters
            Button(
              onPressed: clientProvider.clearFilters,
              child: Text(l10n.clearFilters),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      // Client List
      if (clientProvider.isLoading)
        const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: ProgressRing(),
          ),
        )
      else if (clientProvider.filteredClients.isEmpty)
        _buildEmptyState(context, l10n)
      else
        _buildClientList(context, clientProvider, l10n),

      // Error Display
      if (clientProvider.lastError != null)
        Padding(
          padding: const EdgeInsets.all(16),
          child: InfoBar(
            title: Text(l10n.error),
            content: Text(clientProvider.lastError!),
            severity: InfoBarSeverity.error,
          ),
        ),
    ];
  }

  Widget _buildStatCard({
    required BuildContext context,
    required String title,
    required String value,
    required String secondTitle,
    required String secondValue,
    required IconData icon,
    required AccentColor color,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(
            width: 30,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    secondTitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                secondValue,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              FluentIcons.contact,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noClientsFound,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.createFirstClient,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => _showCreateClientDialog(context, l10n),
              child: Text(l10n.createClient),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientList(BuildContext context, ClientProvider clientProvider,
      AppLocalizations l10n) {
    return Card(
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                    flex: 3,
                    child: Text(l10n.name,
                        style: TextStyle(fontWeight: FontWeight.w600))),
                Expanded(
                    flex: 2,
                    child: Text(l10n.contact,
                        style: TextStyle(fontWeight: FontWeight.w600))),
                Expanded(
                    flex: 2,
                    child: Text(l10n.address,
                        style: TextStyle(fontWeight: FontWeight.w600))),
                Expanded(
                    flex: 1,
                    child: Text(l10n.type,
                        style: TextStyle(fontWeight: FontWeight.w600))),
                Expanded(
                    flex: 1,
                    child: Text(l10n.status,
                        style: TextStyle(fontWeight: FontWeight.w600))),
                SizedBox(
                    width: 120,
                    child: Text(l10n.actions,
                        style: TextStyle(fontWeight: FontWeight.w600))),
              ],
            ),
          ),

          // Client Items
          ...clientProvider.filteredClients.map((client) =>
              _buildClientItem(context, clientProvider, client, l10n)),
        ],
      ),
    );
  }

  Widget _buildClientItem(BuildContext context, ClientProvider clientProvider,
      Client client, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.withOpacity(0.2)),
        ),
      ),
      child: Row(
        children: [
          // Name
          Expanded(
            flex: 3,
            child: Text(
              client.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),

          // Contact
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (client.phone != null && client.phone!.isNotEmpty)
                  Text(client.phone!, style: const TextStyle(fontSize: 13)),
                if (client.mobile != null && client.mobile!.isNotEmpty)
                  Text(client.mobile!, style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),

          // Address
          Expanded(
            flex: 2,
            child: Text(
              client.contactInfo.isNotEmpty
                  ? client.contactInfo
                  : l10n.noContactInfo,
              style: const TextStyle(fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Type
          // Status
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: client.active
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                client.active ? l10n.active : l10n.inactive,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: client.active ? Colors.green : Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // Actions
          SizedBox(
            width: 120,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(FluentIcons.edit, size: 16),
                  onPressed: () => _showEditClientDialog(context, client, l10n),
                ),
                IconButton(
                  icon: Icon(
                    client.active
                        ? FluentIcons.blocked
                        : FluentIcons.check_mark,
                    size: 16,
                  ),
                  onPressed: () => clientProvider.toggleClientStatus(client),
                ),
                IconButton(
                  icon: const Icon(FluentIcons.delete, size: 16),
                  onPressed: () => _showDeleteConfirmation(
                      context, clientProvider, client, l10n),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateClientDialog(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => const ClientFormDialog(),
    );
  }

  void _showEditClientDialog(
      BuildContext context, Client client, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => ClientFormDialog(client: client),
    );
  }

  void _showDeleteConfirmation(BuildContext context, ClientProvider provider,
      Client client, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: Text(l10n.deleteClient),
        content: Text(l10n.deleteClientConfirm(client.name)),
        actions: [
          Button(
            child: Text(l10n.cancel),
            onPressed: () => Navigator.of(context).pop(),
          ),
          FilledButton(
            child: Text(l10n.delete),
            onPressed: () {
              provider.deleteClient(client);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}
