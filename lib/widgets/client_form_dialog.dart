import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:weighing_system/database/database_helper.dart';
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
  late TextEditingController _phoneController;
  late TextEditingController _mobileController;
  late TextEditingController _cityController;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();

    final client = widget.client;
    _nameController = TextEditingController(text: client?.name ?? '');
    _phoneController = TextEditingController(text: client?.phone ?? '');
    _mobileController = TextEditingController(text: client?.mobile ?? '');
    _cityController = TextEditingController(text: client?.city ?? '');
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
      title:
          Text(widget.isEditing ? l10n.editClientTitle : l10n.createNewClient),
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
                    placeholder: l10n.clientNamePlaceholder,
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
      final clientProvider = context.read<ClientProvider>();
      final l10n = AppLocalizations.of(context)!;
      final databaseHelper = DatabaseHelper();

      if (widget.isEditing) {
        // Update existing client
        final client = widget.client;
        if (client == null) return;

        final updatedClient = client.copyWith(
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

        final success = await clientProvider.updateClient(updatedClient);
        if (success) {
          if (mounted) Navigator.of(context).pop();
          if (mounted)
            _showSuccessMessage(context, l10n.clientUpdatedSuccessfully);
        } else {
          if (mounted)
            _showErrorMessage(
                context, clientProvider.lastError ?? l10n.failedToUpdateClient);
        }
      } else {
        final data = await databaseHelper.query('clients',
            where: 'name = ?', whereArgs: [_nameController.text.trim()]);

        if (data.isNotEmpty) {
          if (!mounted) return;
          _showErrorMessage(context, l10n.alreadyThere);
          return;
        }
        // Create new client
        final client = await clientProvider.createClient(
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

        if (client != null) {
          if (mounted) Navigator.of(context).pop();
          if (mounted)
            _showSuccessMessage(context, l10n.clientCreatedSuccessfully);
        } else {
          if (mounted)
            _showErrorMessage(
                context, clientProvider.lastError ?? l10n.failedToCreateClient);
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
