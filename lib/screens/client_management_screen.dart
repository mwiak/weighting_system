import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/client_provider.dart';
import '../providers/supplier_provider.dart';
import '../models/client.dart';
import '../models/supplier.dart';
import '../widgets/client_form_dialog.dart';
import '../widgets/supplier_form_dialog.dart';

class ClientManagementScreen extends StatefulWidget {
  const ClientManagementScreen({super.key});

  @override
  State<ClientManagementScreen> createState() => _ClientManagementScreenState();
}

class _ClientManagementScreenState extends State<ClientManagementScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer2<ClientProvider, SupplierProvider>(
      builder: (context, clientProvider, supplierProvider, child) {
        return ScaffoldPage.scrollable(
          header: PageHeader(
            title: Text(_selectedIndex == 0
                ? l10n.clientManagement
                : l10n.supplierManagement),
            commandBar: CommandBar(
              primaryItems: [
                CommandBarButton(
                  icon: const Icon(FluentIcons.add),
                  label: Text(
                      _selectedIndex == 0 ? l10n.newClient : l10n.newSupplier),
                  onPressed: () => _selectedIndex == 0
                      ? _showCreateClientDialog(context, l10n)
                      : _showCreateSupplierDialog(context, l10n),
                ),
                CommandBarButton(
                  icon: const Icon(FluentIcons.refresh),
                  label: Text(l10n.refresh),
                  onPressed: () => _selectedIndex == 0
                      ? clientProvider.loadClients()
                      : supplierProvider.loadSuppliers(),
                ),
                const CommandBarSeparator(),
                CommandBarButton(
                  icon: const Icon(FluentIcons.download),
                  label: Text(l10n.import),
                  onPressed: () => _showImportDialog(context, l10n),
                ),
                CommandBarButton(
                  icon: const Icon(FluentIcons.upload),
                  label: Text(l10n.export),
                  onPressed: () => _selectedIndex == 0
                      ? _exportClients(context, clientProvider, l10n)
                      : _exportSuppliers(context, supplierProvider, l10n),
                ),
              ],
            ),
          ),
          children: [
            // Tab Navigation
            SizedBox(
              height: 60,
              child: TabView(
                currentIndex: _selectedIndex,
                onChanged: (index) => setState(() => _selectedIndex = index),
                tabs: [
                  Tab(
                    text: Text(l10n.clients),
                    icon: const Icon(FluentIcons.contact),
                    body: const SizedBox.shrink(),
                  ),
                  Tab(
                    text: Text(l10n.suppliers),
                    icon: const Icon(FluentIcons.people),
                    body: const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Content based on selected tab
            if (_selectedIndex == 0)
              ..._buildClientContent(context, clientProvider, l10n)
            else
              ..._buildSupplierContent(context, supplierProvider, l10n),
          ],
        );
      },
    );
  }

  List<Widget> _buildClientContent(BuildContext context,
      ClientProvider clientProvider, AppLocalizations l10n) {
    return [
      // Statistics Cards
      Row(
        children: [
          Expanded(
            child: _buildStatCard(
              context,
              l10n.totalClients,
              '${clientProvider.totalClients}',
              FluentIcons.contact,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              context,
              l10n.activeClients,
              '${clientProvider.activeClients.length}',
              FluentIcons.check_mark,
              Colors.green,
            ),
          ),
          const SizedBox(width: 16),
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

  List<Widget> _buildSupplierContent(BuildContext context,
      SupplierProvider supplierProvider, AppLocalizations l10n) {
    return [
      // Statistics Cards
      Row(
        children: [
          Expanded(
            child: _buildStatCard(
              context,
              l10n.totalSuppliers,
              '${supplierProvider.totalSuppliers}',
              FluentIcons.people,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              context,
              l10n.activeSuppliers,
              '${supplierProvider.activeSuppliers.length}',
              FluentIcons.check_mark,
              Colors.green,
            ),
          ),
          const SizedBox(width: 16),
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
                  placeholder: l10n.searchSuppliers,
                  prefix: const Icon(FluentIcons.search),
                  onChanged: supplierProvider.setSearchQuery,
                ),
              ),
              const SizedBox(width: 16),

              // Active Only Filter
              Checkbox(
                checked: supplierProvider.showActiveOnly,
                onChanged: (value) =>
                    supplierProvider.setShowActiveOnly(value ?? true),
                content: Text(l10n.activeOnly),
              ),
              const Spacer(),

              // Clear Filters
              Button(
                onPressed: supplierProvider.clearFilters,
                child: Text(l10n.clearFilters),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),

      // Supplier List
      if (supplierProvider.isLoading)
        const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: ProgressRing(),
          ),
        )
      else if (supplierProvider.filteredSuppliers.isEmpty)
        _buildEmptySupplierState(context, l10n)
      else
        _buildSupplierList(context, supplierProvider, l10n),

      // Error Display
      if (supplierProvider.lastError != null)
        Padding(
          padding: const EdgeInsets.all(16),
          child: InfoBar(
            title: Text(l10n.error),
            content: Text(supplierProvider.lastError!),
            severity: InfoBarSeverity.error,
          ),
        ),
    ];
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

  void _showCreateSupplierDialog(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => const SupplierFormDialog(),
    );
  }

  void _showEditClientDialog(
      BuildContext context, Client client, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => ClientFormDialog(client: client),
    );
  }

  void _showEditSupplierDialog(
      BuildContext context, Supplier supplier, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => SupplierFormDialog(supplier: supplier),
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

  void _showImportDialog(BuildContext context, AppLocalizations l10n) {
    displayInfoBar(
      context,
      builder: (context, close) => InfoBar(
        title: Text(l10n.importFunctionalityComingSoon),
        severity: InfoBarSeverity.info,
      ),
    );
  }

  void _exportClients(
      BuildContext context, ClientProvider provider, AppLocalizations l10n) {
    final data = provider.exportClientsToJson();
    displayInfoBar(
      context,
      builder: (context, close) => InfoBar(
        title: Text(l10n.exportedClients(data['total_count'])),
        severity: InfoBarSeverity.success,
      ),
    );
  }

  void _exportSuppliers(
      BuildContext context, SupplierProvider provider, AppLocalizations l10n) {
    final data = provider.exportSuppliersToJson();
    displayInfoBar(
      context,
      builder: (context, close) => InfoBar(
        title: Text(l10n.exportedSuppliers(data['total_count'])),
        severity: InfoBarSeverity.success,
      ),
    );
  }

  Widget _buildEmptySupplierState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              FluentIcons.people,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noSuppliersFound,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.createFirstSupplier,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => _showCreateSupplierDialog(context, l10n),
              child: Text(l10n.createSupplier),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupplierList(BuildContext context,
      SupplierProvider supplierProvider, AppLocalizations l10n) {
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

          // Supplier Items
          ...supplierProvider.filteredSuppliers.map((supplier) =>
              _buildSupplierItem(context, supplierProvider, supplier, l10n)),
        ],
      ),
    );
  }

  Widget _buildSupplierItem(
      BuildContext context,
      SupplierProvider supplierProvider,
      Supplier supplier,
      AppLocalizations l10n) {
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
              supplier.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),

          // Contact
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (supplier.phone != null && supplier.phone!.isNotEmpty)
                  Text(supplier.phone!, style: const TextStyle(fontSize: 13)),
                if (supplier.mobile != null && supplier.mobile!.isNotEmpty)
                  Text(supplier.mobile!, style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),

          // Address
          Expanded(
            flex: 2,
            child: Text(
              supplier.contactInfo.isNotEmpty
                  ? supplier.contactInfo
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
                color: supplier.active
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                supplier.active ? l10n.active : l10n.inactive,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: supplier.active ? Colors.green : Colors.red,
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
                  onPressed: () =>
                      _showEditSupplierDialog(context, supplier, l10n),
                ),
                IconButton(
                  icon: Icon(
                    supplier.active
                        ? FluentIcons.blocked
                        : FluentIcons.check_mark,
                    size: 16,
                  ),
                  onPressed: () =>
                      supplierProvider.toggleSupplierStatus(supplier),
                ),
                IconButton(
                  icon: const Icon(FluentIcons.delete, size: 16),
                  onPressed: () => _showDeleteSupplierConfirmation(
                      context, supplierProvider, supplier, l10n),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteSupplierConfirmation(BuildContext context,
      SupplierProvider provider, Supplier supplier, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: Text(l10n.deleteSupplier),
        content: Text(l10n.deleteSupplierConfirm(supplier.name)),
        actions: [
          Button(
            child: Text(l10n.cancel),
            onPressed: () => Navigator.of(context).pop(),
          ),
          FilledButton(
            child: Text(l10n.delete),
            onPressed: () {
              provider.deleteSupplier(supplier.id!);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}
