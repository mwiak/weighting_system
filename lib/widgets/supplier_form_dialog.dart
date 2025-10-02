import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import '../providers/supplier_provider.dart';
import '../models/supplier.dart';

class SupplierFormDialog extends StatefulWidget {
  final Supplier? supplier;

  const SupplierFormDialog({super.key, this.supplier});

  bool get isEditing => supplier != null;

  @override
  State<SupplierFormDialog> createState() => _SupplierFormDialogState();
}

class _SupplierFormDialogState extends State<SupplierFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _mobileController;
  late TextEditingController _cityController;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();

    final supplier = widget.supplier;
    _nameController = TextEditingController(text: supplier?.name ?? '');
    _phoneController = TextEditingController(text: supplier?.phone ?? '');
    _mobileController = TextEditingController(text: supplier?.mobile ?? '');
    _cityController = TextEditingController(text: supplier?.city ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _mobileController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      title: Text(widget.isEditing ? 'Edit Supplier' : 'Create New Supplier'),
      content: SizedBox(
        width: 400,
        height: 350,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                InfoLabel(
                  label: 'Name *',
                  child: TextFormBox(
                    controller: _nameController,
                    placeholder: 'Supplier name',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Name is required';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Phone and Mobile
                Row(
                  children: [
                    Expanded(
                      child: InfoLabel(
                        label: 'Phone',
                        child: TextFormBox(
                          controller: _phoneController,
                          placeholder: '+1 (555) 123-4567',
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: InfoLabel(
                        label: 'Mobile',
                        child: TextFormBox(
                          controller: _mobileController,
                          placeholder: '+1 (555) 987-6543',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // City
                InfoLabel(
                  label: 'City',
                  child: TextFormBox(
                    controller: _cityController,
                    placeholder: 'City',
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
      actions: [
        Button(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _handleSubmit,
          child: _isSubmitting
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: ProgressRing(strokeWidth: 2),
                )
              : Text(widget.isEditing ? 'Update' : 'Create'),
        ),
      ],
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final supplierProvider = context.read<SupplierProvider>();

      if (widget.isEditing) {
        // Update existing supplier
        final supplier = widget.supplier;
        if (supplier == null) return;
        final updatedSupplier = supplier.copyWith(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          mobile: _mobileController.text.trim().isEmpty ? null : _mobileController.text.trim(),
          city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
        );

        final success = await supplierProvider.updateSupplier(updatedSupplier);
        if (success) {
          if (mounted) Navigator.of(context).pop();
          if (mounted) _showSuccessMessage(context, 'Supplier updated successfully');
        } else {
          if (mounted) _showErrorMessage(context, supplierProvider.lastError ?? 'Failed to update supplier');
        }
      } else {
        // Create new supplier
        final supplier = Supplier(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          mobile: _mobileController.text.trim().isEmpty ? null : _mobileController.text.trim(),
          city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
          createDate: DateTime.now().toIso8601String(),
          writeDate: DateTime.now().toIso8601String(),
        );

        final createdSupplier = await supplierProvider.addSupplier(supplier);
        if (createdSupplier != null) {
          if (mounted) Navigator.of(context).pop();
          if (mounted) _showSuccessMessage(context, 'Supplier created successfully');
        } else {
          if (mounted) _showErrorMessage(context, supplierProvider.lastError ?? 'Failed to create supplier');
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showSuccessMessage(BuildContext context, String message) {
    displayInfoBar(
      context,
      builder: (context, close) => InfoBar(
        title: Text(message),
        severity: InfoBarSeverity.success,
        action: IconButton(
          icon: const Icon(FluentIcons.clear),
          onPressed: close,
        ),
      ),
    );
  }

  void _showErrorMessage(BuildContext context, String message) {
    displayInfoBar(
      context,
      builder: (context, close) => InfoBar(
        title: const Text('Error'),
        content: Text(message),
        severity: InfoBarSeverity.error,
        action: IconButton(
          icon: const Icon(FluentIcons.clear),
          onPressed: close,
        ),
      ),
    );
  }
}
