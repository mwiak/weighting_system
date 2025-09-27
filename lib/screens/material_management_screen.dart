import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import '../providers/material_provider.dart';
import '../models/material.dart';
import '../widgets/material_form_dialog.dart';

class MaterialManagementScreen extends StatelessWidget {
  const MaterialManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MaterialProvider>(
      builder: (context, materialProvider, child) {
        return ScaffoldPage.scrollable(
          header: PageHeader(
            title: const Text('Material Management'),
            commandBar: CommandBar(
              primaryItems: [
                CommandBarButton(
                  icon: const Icon(FluentIcons.add),
                  label: const Text('New Material'),
                  onPressed: () => _showCreateMaterialDialog(context),
                ),
                CommandBarButton(
                  icon: const Icon(FluentIcons.refresh),
                  label: const Text('Refresh'),
                  onPressed: () => materialProvider.loadMaterials(),
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
                  onPressed: () => _exportMaterials(context, materialProvider),
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
                    'Total Materials',
                    '${materialProvider.totalMaterials}',
                    FluentIcons.package,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'With Price',
                    '${materialProvider.materials.where((m) => m.price != null && m.price! > 0).length}',
                    FluentIcons.money,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Average Price Card
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(FluentIcons.money, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Pricing Overview',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Average Price', style: TextStyle(color: Colors.grey)),
                                    Text(
                                      '\$${materialProvider.averagePrice.toStringAsFixed(2)}',
                                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Most Expensive', style: TextStyle(color: Colors.grey)),
                                    Text(
                                      materialProvider.mostExpensive?.name ?? 'None',
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      '\$${materialProvider.mostExpensive?.price?.toStringAsFixed(2) ?? '0.00'}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
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
                        placeholder: 'Search materials...',
                        prefix: const Icon(FluentIcons.search),
                        onChanged: materialProvider.setSearchQuery,
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Active Only Filter
                    Checkbox(
                      checked: materialProvider.showActiveOnly,
                      onChanged: (value) => 
                          materialProvider.setShowActiveOnly(value ?? true),
                      content: const Text('Active only'),
                    ),
                    const Spacer(),
                    
                    // Clear Filters
                    Button(
                      onPressed: materialProvider.clearFilters,
                      child: const Text('Clear Filters'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Material List
            if (materialProvider.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: ProgressRing(),
                ),
              )
            else if (materialProvider.filteredMaterials.isEmpty)
              _buildEmptyState(context)
            else
              _buildMaterialList(context, materialProvider),
              
            // Error Display
            if (materialProvider.lastError != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: InfoBar(
                  title: const Text('Error'),
                  content: Text(materialProvider.lastError!),
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
              FluentIcons.package,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'No materials found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create your first material to get started',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => _showCreateMaterialDialog(context),
              child: const Text('Create Material'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaterialList(BuildContext context, MaterialProvider materialProvider) {
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
                Expanded(flex: 3, child: Text('Name', style: TextStyle(fontWeight: FontWeight.w600))),
                Expanded(flex: 1, child: Text('Code', style: TextStyle(fontWeight: FontWeight.w600))),
                Expanded(flex: 1, child: Text('Type', style: TextStyle(fontWeight: FontWeight.w600))),
                Expanded(flex: 1, child: Text('Price', style: TextStyle(fontWeight: FontWeight.w600))),
                Expanded(flex: 1, child: Text('Status', style: TextStyle(fontWeight: FontWeight.w600))),
                SizedBox(width: 120, child: Text('Actions', style: TextStyle(fontWeight: FontWeight.w600))),
              ],
            ),
          ),
          
          // Material Items
          ...materialProvider.filteredMaterials.map((material) => 
            _buildMaterialItem(context, materialProvider, material)
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialItem(BuildContext context, MaterialProvider materialProvider, Material material) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.withOpacity(0.2)),
        ),
      ),
      child: Row(
        children: [
          // Name and Description
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  material.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (material.description != null && material.description!.isNotEmpty)
                  Text(
                    material.description!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[100],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          
          // Price
          Expanded(
            flex: 1,
            child: Text(
              material.price != null && material.price! > 0 
                  ? '\$${material.price!.toStringAsFixed(2)}/kg'
                  : 'No price',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          
          // Status
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: material.active ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                material.active ? 'Active' : 'Inactive',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: material.active ? Colors.green : Colors.red,
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
                  onPressed: () => _showEditMaterialDialog(context, material),
                ),
                IconButton(
                  icon: Icon(
                    material.active ? FluentIcons.blocked : FluentIcons.check_mark,
                    size: 16,
                  ),
                  onPressed: () => materialProvider.toggleMaterialStatus(material),
                ),
                IconButton(
                  icon: const Icon(FluentIcons.delete, size: 16),
                  onPressed: () => _showDeleteConfirmation(context, materialProvider, material),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Method removed - no longer needed with simplified model

  void _showCreateMaterialDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const MaterialFormDialog(),
    );
  }

  void _showEditMaterialDialog(BuildContext context, Material material) {
    showDialog(
      context: context,
      builder: (context) => MaterialFormDialog(material: material),
    );
  }

  void _showDeleteConfirmation(BuildContext context, MaterialProvider provider, Material material) {
    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Delete Material'),
        content: Text('Are you sure you want to delete "${material.name}"?'),
        actions: [
          Button(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          FilledButton(
            child: const Text('Delete'),
            onPressed: () {
              provider.deleteMaterial(material);
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

  void _exportMaterials(BuildContext context, MaterialProvider provider) {
    final data = provider.exportMaterialsToJson();
    displayInfoBar(
      context,
      builder: (context, close) => InfoBar(
        title: Text('Exported ${data['total_count']} materials'),
        severity: InfoBarSeverity.success,
      ),
    );
  }
}