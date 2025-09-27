import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import '../providers/client_provider.dart';
import '../models/client.dart';

class ClientFormDialog extends StatefulWidget {
  final Client? client;

  const ClientFormDialog({super.key, this.client});

  bool get isEditing => client != null;

  @override
  State<ClientFormDialog> createState() => _ClientFormDialogState();
}

class _ClientFormDialogState extends State<ClientFormDialog> {
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
    
    final client = widget.client;
    _nameController = TextEditingController(text: client?.name ?? '');
    _emailController = TextEditingController(text: client?.email ?? '');
    _phoneController = TextEditingController(text: client?.phone ?? '');
    _mobileController = TextEditingController(text: client?.mobile ?? '');
    _streetController = TextEditingController(text: client?.street ?? '');
    _street2Controller = TextEditingController(text: client?.street2 ?? '');
    _cityController = TextEditingController(text: client?.city ?? '');
    _zipController = TextEditingController(text: client?.zip ?? '');
    _vatController = TextEditingController(text: client?.vat ?? '');
    
    _isCompany = client?.isCompany ?? false;
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
      title: Text(widget.isEditing ? 'Edit Client' : 'Create New Client'),
      content: SizedBox(
        width: 500,
        height: 600,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Client Type
                Row(
                  children: [
                    const Text('Client Type:'),
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
      final clientProvider = context.read<ClientProvider>();
      
      if (widget.isEditing) {
        // Update existing client
        final client = widget.client;
        if (client == null) return;
        final updatedClient = client.copyWith(
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
        
        final success = await clientProvider.updateClient(updatedClient);
        if (success) {
          Navigator.of(context).pop();
          _showSuccessMessage(context, 'Client updated successfully');
        } else {
          _showErrorMessage(context, clientProvider.lastError ?? 'Failed to update client');
        }
      } else {
        // Create new client
        final client = await clientProvider.createClient(
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
        
        if (client != null) {
          Navigator.of(context).pop();
          _showSuccessMessage(context, 'Client created successfully');
        } else {
          _showErrorMessage(context, clientProvider.lastError ?? 'Failed to create client');
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