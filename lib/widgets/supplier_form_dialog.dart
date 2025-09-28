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
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _mobileController;
  late TextEditingController _streetController;
  late TextEditingController _street2Controller;
  late TextEditingController _cityController;
  late TextEditingController _zipController;
  late TextEditingController _vatController;

  bool _isCompany = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();

    final supplier = widget.supplier;
    _nameController = TextEditingController(text: supplier?.name ?? '');
    _emailController = TextEditingController(text: supplier?.email ?? '');
    _phoneController = TextEditingController(text: supplier?.phone ?? '');
    _mobileController = TextEditingController(text: supplier?.mobile ?? '');
    _streetController = TextEditingController(text: supplier?.street ?? '');
    _street2Controller = TextEditingController(text: supplier?.street2 ?? '');
    _cityController = TextEditingController(text: supplier?.city ?? '');
    _zipController = TextEditingController(text: supplier?.zip ?? '');
    _vatController = TextEditingController(text: supplier?.vat ?? '');

    _isCompany = supplier?.isCompany ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _mobileController.dispose();
    _streetController.dispose();
    _street2Controller.dispose();
    _cityController.dispose();
    _zipController.dispose();
    _vatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      title: Text(widget.isEditing ? 'Edit Supplier' : 'Create New Supplier'),
      content: SizedBox(
        width: 500,
        height: 600,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Supplier Type
                Row(
                  children: [
                    const Text('Supplier Type:'),
                    const SizedBox(width: 16),
                    RadioButton(
                      checked: !_isCompany,
                      onChanged: (value) {
                        if (value == true) {
                          setState(() => _isCompany = false);
                        }
                      },
                      content: const Text('Individual'),
                    ),
                    const SizedBox(width: 16),
                    RadioButton(
                      checked: _isCompany,
                      onChanged: (value) {
                        if (value == true) {
                          setState(() => _isCompany = true);
                        }
                      },
                      content: const Text('Company'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Name
                InfoLabel(
                  label: 'Name *',
                  child: TextFormBox(
                    controller: _nameController,
                    placeholder: _isCompany ? 'Company name' : 'Full name',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Name is required';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Contact Information
                const Text(
                  'Contact Information',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),

                // Email
                InfoLabel(
                  label: 'Email',
                  child: TextFormBox(
                    controller: _emailController,
                    placeholder: 'email@example.com',
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                        if (!emailRegex.hasMatch(value)) {
                          return 'Please enter a valid email address';
                        }
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
                const SizedBox(height: 20),

                // Address Information
                const Text(
                  'Address Information',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),

                // Street
                InfoLabel(
                  label: 'Street Address',
                  child: TextFormBox(
                    controller: _streetController,
                    placeholder: '123 Main Street',
                  ),
                ),
                const SizedBox(height: 16),

                // Street 2
                InfoLabel(
                  label: 'Street Address 2',
                  child: TextFormBox(
                    controller: _street2Controller,
                    placeholder: 'Apt, Suite, Building, etc.',
                  ),
                ),
                const SizedBox(height: 16),

                // City and ZIP
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: InfoLabel(
                        label: 'City',
                        child: TextFormBox(
                          controller: _cityController,
                          placeholder: 'City name',
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 1,
                      child: InfoLabel(
                        label: 'ZIP Code',
                        child: TextFormBox(
                          controller: _zipController,
                          placeholder: '12345',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Tax Information (for companies)
                if (_isCompany) ...[
                  const Text(
                    'Tax Information',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),

                  InfoLabel(
                    label: 'VAT Number',
                    child: TextFormBox(
                      controller: _vatController,
                      placeholder: 'Tax identification number',
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
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
          onPressed: _isSubmitting ? null : _submitForm,
          child: _isSubmitting
              ? const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: ProgressRing(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text('Saving...'),
                  ],
                )
              : Text(widget.isEditing ? 'Update' : 'Create'),
        ),
      ],
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() != true) return;

    setState(() => _isSubmitting = true);

    try {
      final supplierProvider = context.read<SupplierProvider>();

      if (widget.isEditing) {
        // Update existing supplier
        final supplier = widget.supplier;
        if (supplier == null) return;
        final updatedSupplier = supplier.copyWith(
          name: _nameController.text.trim(),
          email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
          phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          mobile: _mobileController.text.trim().isEmpty ? null : _mobileController.text.trim(),
          street: _streetController.text.trim().isEmpty ? null : _streetController.text.trim(),
          street2: _street2Controller.text.trim().isEmpty ? null : _street2Controller.text.trim(),
          city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
          zip: _zipController.text.trim().isEmpty ? null : _zipController.text.trim(),
          vat: _vatController.text.trim().isEmpty ? null : _vatController.text.trim(),
          isCompany: _isCompany,
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
          email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
          phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          mobile: _mobileController.text.trim().isEmpty ? null : _mobileController.text.trim(),
          street: _streetController.text.trim().isEmpty ? null : _streetController.text.trim(),
          street2: _street2Controller.text.trim().isEmpty ? null : _street2Controller.text.trim(),
          city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
          zip: _zipController.text.trim().isEmpty ? null : _zipController.text.trim(),
          vat: _vatController.text.trim().isEmpty ? null : _vatController.text.trim(),
          isCompany: _isCompany,
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