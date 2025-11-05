import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../database/database_helper.dart';
import '../providers/material_provider.dart';
import '../models/material.dart';
import '../providers/tabs_provider.dart';

class MaterialFormDialog extends StatefulWidget {
  final Material? material;

  const MaterialFormDialog({super.key, this.material});

  bool get isEditing => material != null;

  @override
  State<MaterialFormDialog> createState() => _MaterialFormDialogState();
}

class _MaterialFormDialogState extends State<MaterialFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();

    final material = widget.material;
    _nameController = TextEditingController(text: material?.name ?? '');
    _priceController =
        TextEditingController(text: material?.price?.toString() ?? '');
    _descriptionController =
        TextEditingController(text: material?.description ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ContentDialog(
      title: Text(widget.isEditing ? l10n.editMaterial : l10n.addMaterial),
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
                  label: l10n.name,
                  child: TextFormBox(
                    controller: _nameController,
                    placeholder: 'اسم المادة',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.required;
                      }
                      return null;
                    },
                  ),
                ),

                // Price per kg (optional)
                InfoLabel(
                  label: l10n.unitPrice,
                  child: TextFormBox(
                    controller: _priceController,
                    placeholder: '0.000',
                    prefix: Text(
                        '${AppLocalizations.of(context)!.currencySymbol} '),
                    suffix: Text(AppLocalizations.of(context)!.perKg),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final price = double.tryParse(value);
                        if (price == null || price < 0) {
                          return l10n.validationError;
                        }
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Description
                InfoLabel(
                  label: l10n.notes,
                  child: TextFormBox(
                    controller: _descriptionController,
                    placeholder: l10n.notes,
                    minLines: 3,
                    maxLines: 5,
                  ),
                ),
                const SizedBox(height: 16),
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
          onPressed: _isSubmitting ? null : _submitForm,
          child: _isSubmitting
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: ProgressRing(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    Text(AppLocalizations.of(context)!.saving),
                  ],
                )
              : Text(widget.isEditing ? l10n.save : l10n.add),
        ),
      ],
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() != true) return;

    setState(() => _isSubmitting = true);

    try {
      final materialProvider = context.read<MaterialProvider>();
      final databaseHelper = DatabaseHelper();
      final l10n = AppLocalizations.of(context)!;

      final price = _priceController.text.trim().isEmpty
          ? null
          : double.tryParse(_priceController.text.trim());

      if (widget.isEditing) {
        // Update existing material
        final material = widget.material;
        if (material == null) return;
        final updatedMaterial = material.copyWith(
          name: _nameController.text.trim(),
          price: price,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
        );
        bool hasNameChanged = material.name != _nameController.text.trim();
        final success = await materialProvider.updateMaterial(updatedMaterial);
        if (success) {
          if (hasNameChanged) {
            await context.read<TabsProvider>().updateTabsWith(
                'material', material.name, updatedMaterial.name);
          }
          Navigator.of(context).pop();
          _showSuccessMessage(context, '');
        } else {
          _showErrorMessage(context, materialProvider.lastError ?? l10n.error);
        }
      } else {
        final data = await databaseHelper.query('materials',
            where: 'name = ?', whereArgs: [_nameController.text.trim()]);

        if (data.isNotEmpty) {
          if (!mounted) return;
          _showErrorMessage(context, l10n.alreadyThere);
          return;
        }
        // Create new material
        final material = Material(
          name: _nameController.text.trim(),
          price: price,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
        );

        final success = await materialProvider.addMaterial(material);
        if (success) {
          Navigator.of(context).pop();
          _showSuccessMessage(context, 'تم');
        } else {
          _showErrorMessage(context, materialProvider.lastError ?? l10n.error);
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
