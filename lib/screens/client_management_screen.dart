import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import '../providers/client_provider.dart';
import '../models/client.dart';
import '../widgets/client_form_dialog.dart';

class ClientManagementScreen extends StatelessWidget {
  const ClientManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ClientProvider>(
      builder: (context, clientProvider, child) {
        return ScaffoldPage.scrollable(
          header: PageHeader(
            title: const Text('Client Management'),
            commandBar: CommandBar(
              primaryItems: [
                CommandBarButton(
                  icon: const Icon(FluentIcons.add),
                  label: const Text('New Client'),
                  onPressed: () => _showCreateClientDialog(context),
                ),
                CommandBarButton(
                  icon: const Icon(FluentIcons.refresh),
                  label: const Text('Refresh'),
                  onPressed: () => clientProvider.loadClients(),
                ),
                CommandBarSeparator(),
                CommandBarButton(
                  icon: const Icon(FluentIcons.download),
                  label: const Text('Import'),
                  onPressed: () => _showImportDialog(context),
                ),
                CommandBarButton(
                  icon: const Icon(FluentIcons.upload),
                  label: const Text('Export'),
                  onPressed: () => _exportClients(context, clientProvider),
                ),
              ],
            ),
          ),
          children: [
            // Statistics Cards
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Total Clients',
                    '${clientProvider.totalClients}',
                    FluentIcons.contact,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Active Clients',
                    '${clientProvider.activeClients.length}',
                    FluentIcons.check_mark,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Companies',
                    '${clientProvider.clients.where((c) => c.isCompany).length}',
                    FluentIcons.city_next,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Individuals',
                    '${clientProvider.clients.where((c) => !c.isCompany).length}',
                    FluentIcons.people,
                    Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Filters and Search
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Search Box
                    SizedBox(
                      width: 300,
                      child: TextBox(
                        placeholder: 'Search clients...',
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
                      content: const Text('Active only'),
                    ),
                    const Spacer(),

                    // Clear Filters
                    Button(
                      onPressed: clientProvider.clearFilters,
                      child: const Text('Clear Filters'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Client List
            if (clientProvider.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: ProgressRing(),
                ),
              )
            else if (clientProvider.filteredClients.isEmpty)
              _buildEmptyState(context)
            else
              _buildClientList(context, clientProvider),

            // Error Display
            if (clientProvider.lastError != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: InfoBar(
                  title: const Text('Error'),
                  content: Text(clientProvider.lastError!),
                  severity: InfoBarSeverity.error,
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    AccentColor color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
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
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
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
            const Text(
              'No clients found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create your first client to get started',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => _showCreateClientDialog(context),
              child: const Text('Create Client'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientList(BuildContext context, ClientProvider clientProvider) {
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
            child: const Row(
              children: [
                Expanded(
                    flex: 3,
                    child: Text('Name',
                        style: TextStyle(fontWeight: FontWeight.w600))),
                Expanded(
                    flex: 2,
                    child: Text('Contact',
                        style: TextStyle(fontWeight: FontWeight.w600))),
                Expanded(
                    flex: 2,
                    child: Text('Address',
                        style: TextStyle(fontWeight: FontWeight.w600))),
                Expanded(
                    flex: 1,
                    child: Text('Type',
                        style: TextStyle(fontWeight: FontWeight.w600))),
                Expanded(
                    flex: 1,
                    child: Text('Status',
                        style: TextStyle(fontWeight: FontWeight.w600))),
                SizedBox(
                    width: 120,
                    child: Text('Actions',
                        style: TextStyle(fontWeight: FontWeight.w600))),
              ],
            ),
          ),

          // Client Items
          ...clientProvider.filteredClients.map(
              (client) => _buildClientItem(context, clientProvider, client)),
        ],
      ),
    );
  }

  Widget _buildClientItem(
      BuildContext context, ClientProvider clientProvider, Client client) {
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  client.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (client.vat != null && client.vat!.isNotEmpty)
                  Text(
                    'VAT: ${client.vat}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[100],
                    ),
                  ),
              ],
            ),
          ),

          // Contact
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (client.email != null && client.email!.isNotEmpty)
                  Text(client.email!, style: const TextStyle(fontSize: 13)),
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
                  : 'No contact info',
              style: const TextStyle(fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Type
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: client.isCompany
                    ? Colors.blue.withOpacity(0.1)
                    : Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                client.isCompany ? 'Company' : 'Individual',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: client.isCompany ? Colors.blue : Colors.green,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

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
                client.active ? 'Active' : 'Inactive',
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
                  onPressed: () => _showEditClientDialog(context, client),
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
                  onPressed: () =>
                      _showDeleteConfirmation(context, clientProvider, client),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateClientDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const ClientFormDialog(),
    );
  }

  void _showEditClientDialog(BuildContext context, Client client) {
    showDialog(
      context: context,
      builder: (context) => ClientFormDialog(client: client),
    );
  }

  void _showDeleteConfirmation(
      BuildContext context, ClientProvider provider, Client client) {
    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Delete Client'),
        content: Text('Are you sure you want to delete "${client.name}"?'),
        actions: [
          Button(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          FilledButton(
            child: const Text('Delete'),
            onPressed: () {
              provider.deleteClient(client);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  void _showImportDialog(BuildContext context) {
    displayInfoBar(
      context,
      builder: (context, close) => const InfoBar(
        title: Text('Import functionality coming soon'),
        severity: InfoBarSeverity.info,
      ),
    );
  }

  void _exportClients(BuildContext context, ClientProvider provider) {
    final data = provider.exportClientsToJson();
    displayInfoBar(
      context,
      builder: (context, close) => InfoBar(
        title: Text('Exported ${data['total_count']} clients'),
        severity: InfoBarSeverity.success,
      ),
    );
  }
}
