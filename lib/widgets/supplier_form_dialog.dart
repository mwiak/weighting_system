import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../database/database_helper.dart';
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
    final l10n = AppLocalizations.of(context)!;
    return ContentDialog(
      title: Text(
          widget.isEditing ? l10n.editSupplierTitle : l10n.createNewSupplier),
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
                  label: l10n.nameRequired,
                  child: TextFormBox(
                    controller: _nameController,
                    placeholder: l10n.supplierNamePlaceholder,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.nameIsRequired;
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
                        label: l10n.phoneLabel,
                        child: TextFormBox(
                          controller: _phoneController,
                          placeholder: l10n.phonePlaceholder,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: InfoLabel(
                        label: l10n.mobileLabel,
                        child: TextFormBox(
                          controller: _mobileController,
                          placeholder: l10n.mobilePlaceholder,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // City
                InfoLabel(
                  label: l10n.cityLabel,
                  child: TextFormBox(
                    controller: _cityController,
                    placeholder: l10n.cityPlaceholder,
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
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _handleSubmit,
          child: _isSubmitting
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: ProgressRing(strokeWidth: 2),
                )
              : Text(widget.isEditing ? l10n.updateButton : l10n.createButton),
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
      final l10n = AppLocalizations.of(context)!;
      final databaseHelper = DatabaseHelper();

      if (widget.isEditing) {
        // Update existing supplier
        final supplier = widget.supplier;
        if (supplier == null) return;
        final updatedSupplier = supplier.copyWith(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
          mobile: _mobileController.text.trim().isEmpty
              ? null
              : _mobileController.text.trim(),
          city: _cityController.text.trim().isEmpty
              ? null
              : _cityController.text.trim(),
        );

        final success = await supplierProvider.updateSupplier(updatedSupplier);
        if (success) {
          if (mounted) Navigator.of(context).pop();
          if (mounted)
            _showSuccessMessage(context, l10n.supplierUpdatedSuccessfully);
        } else {
          if (mounted)
            _showErrorMessage(context,
                supplierProvider.lastError ?? l10n.failedToUpdateSupplier);
        }
      } else {
        final data = await databaseHelper.query('suppliers',
            where: 'name = ?', whereArgs: [_nameController.text.trim()]);

        if (data.isNotEmpty) {
          if (!mounted) return;
          _showErrorMessage(context, l10n.alreadyThere);
          return;
        }
        // Create new supplier
        final supplier = Supplier(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
          mobile: _mobileController.text.trim().isEmpty
              ? null
              : _mobileController.text.trim(),
          city: _cityController.text.trim().isEmpty
              ? null
              : _cityController.text.trim(),
          createDate: DateTime.now().toIso8601String(),
          writeDate: DateTime.now().toIso8601String(),
        );

        final createdSupplier = await supplierProvider.addSupplier(supplier);
        if (createdSupplier != null) {
          if (mounted) Navigator.of(context).pop();
          if (mounted)
            _showSuccessMessage(context, l10n.supplierCreatedSuccessfully);
        } else {
          if (mounted)
            _showErrorMessage(context,
                supplierProvider.lastError ?? l10n.failedToCreateSupplier);
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
        title: Text(AppLocalizations.of(context)!.error),
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
