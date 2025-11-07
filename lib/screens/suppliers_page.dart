import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import '../providers/supplier_provider.dart';
import '../l10n/app_localizations.dart';
import '../models/supplier.dart';
import '../widgets/supplier_form_dialog.dart';

class SuppliersPage extends StatefulWidget {
  const SuppliersPage({super.key});

  @override
  State<SuppliersPage> createState() => _SuppliersPageState();
}

class _SuppliersPageState extends State<SuppliersPage> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer<SupplierProvider>(
        builder: (context, supplierProvider, child) {
      return ScaffoldPage.scrollable(
          padding: EdgeInsets.zero,
          header: CommandBar(
            primaryItems: [
              CommandBarButton(
                icon: const Icon(FluentIcons.add),
                label: Text(l10n.newSupplier),
                onPressed: () => _showCreateSupplierDialog(context, l10n),
              ),
              CommandBarButton(
                icon: const Icon(FluentIcons.refresh),
                label: Text(l10n.refresh),
                onPressed: () => supplierProvider.loadSuppliers(),
              ),
              const CommandBarSeparator(),
            ],
          ),
          children: _buildSupplierContent2(context, supplierProvider, l10n));
    });
  }

  List<Widget> _buildSupplierContent(BuildContext context,
      SupplierProvider supplierProvider, AppLocalizations l10n) {
    return [
      // Statistics Cards
      Row(
        children: [
          Expanded(
            child: _buildStatCard(
              context: context,
              title: l10n.totalSuppliers,
              value: '${supplierProvider.totalSuppliers}',
              secondTitle: '',
              secondValue: '',
              icon: FluentIcons.people,
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 16),
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

  List<Widget> _buildSupplierContent2(BuildContext context,
      SupplierProvider supplierProvider, AppLocalizations l10n) {
    return [
      // Statistics Cards
      Card(
        child: Row(
          children: [
            _buildStatCard(
              context: context,
              title: l10n.totalSuppliers,
              value: '${supplierProvider.totalSuppliers}',
              icon: FluentIcons.contact,
              color: Colors.blue,
              secondTitle: l10n.activeSuppliers,
              secondValue: '${supplierProvider.activeSuppliers.length}',
            ),
            const SizedBox(width: 16),
            const Spacer(),
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
      const SizedBox(height: 12),
      // Client List
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

  void _showCreateSupplierDialog(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => const SupplierFormDialog(),
    );
  }

  void _showEditSupplierDialog(
      BuildContext context, Supplier supplier, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => SupplierFormDialog(supplier: supplier),
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
