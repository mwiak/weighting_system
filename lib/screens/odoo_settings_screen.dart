import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../providers/app_settings_provider.dart';
import '../services/odoo_service.dart';
import '../widgets/custom_info_label.dart';

/// Odoo Configuration Settings Screen
/// 
/// Allows users to configure Odoo connection credentials including:
/// - Server URL
/// - Database name  
/// - Username and password
/// - Test connection functionality
class OdooSettingsScreen extends StatefulWidget {
  const OdooSettingsScreen({super.key});

  @override
  State<OdooSettingsScreen> createState() => _OdooSettingsScreenState();
}

class _OdooSettingsScreenState extends State<OdooSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  final _databaseController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isTestingConnection = false;
  bool _showPassword = false;
  String? _connectionTestResult;
  bool _connectionSuccessful = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _databaseController.dispose(); 
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Load current Odoo settings from the settings provider
  void _loadCurrentSettings() async {
    final settingsProvider = context.read<AppSettingsProvider>();
    await settingsProvider.loadSettings();
    
    if (mounted) {
      setState(() {
        _urlController.text = settingsProvider.getSetting('odoo_url')?.value ?? '';
        _databaseController.text = settingsProvider.getSetting('odoo_database')?.value ?? '';
        _usernameController.text = settingsProvider.getSetting('odoo_username')?.value ?? '';
        _passwordController.text = settingsProvider.getSetting('odoo_password')?.value ?? '';
      });
    }
  }

  /// Save Odoo settings to the database
  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;
    
    final settingsProvider = context.read<AppSettingsProvider>();
    
    try {
      await settingsProvider.updateSetting(key: 'odoo_url', value: _urlController.text.trim());
      await settingsProvider.updateSetting(key: 'odoo_database', value: _databaseController.text.trim());
      await settingsProvider.updateSetting(key: 'odoo_username', value: _usernameController.text.trim());
      await settingsProvider.updateSetting(key: 'odoo_password', value: _passwordController.text.trim());

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        displayInfoBar(
          context,
          builder: (context, close) => InfoBar(
            title: Text(l10n.save),
            content: Text(l10n.odooSettingsSavedSuccess),
            severity: InfoBarSeverity.success,
            action: IconButton(
              icon: const Icon(FluentIcons.clear),
              onPressed: close,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        displayInfoBar(
          context,
          builder: (context, close) => InfoBar(
            title: Text(l10n.error),
            content: Text('${l10n.failedToSaveSettings}: $e'),
            severity: InfoBarSeverity.error,
            action: IconButton(
              icon: const Icon(FluentIcons.clear),
              onPressed: close,
            ),
          ),
        );
      }
    }
  }

  /// Test the Odoo connection with current settings
  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isTestingConnection = true;
      _connectionTestResult = null;
    });

    try {
      final odooService = OdooService();
      
      // Configure the service with current form values
      final config = OdooConfig(
        baseUrl: _urlController.text.trim(),
        database: _databaseController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text.trim(),
      );
      odooService.configure(config);
      
      // Test authentication
      final success = await odooService.authenticate();
      
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _connectionSuccessful = success;
        _connectionTestResult = success
            ? l10n.connectionSuccessful
            : l10n.connectionFailed;
      });

    } catch (e) {
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _connectionSuccessful = false;
        _connectionTestResult = '${l10n.connectionFailedWithError}: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isTestingConnection = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ScaffoldPage.scrollable(
      header: PageHeader(
        title: Text(l10n.odooSettings),
        commandBar: CommandBar(
          primaryItems: [
            CommandBarButton(
              icon: const Icon(FluentIcons.back),
              label: Text(l10n.back),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.odooSettings,
                    style: FluentTheme.of(context).typography.subtitle,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.odooSettingsDescription,
                    style: TextStyle(
                      color: Colors.grey[120],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Odoo URL
                  CustomInfoLabel(
                    label: l10n.odooUrl,
                    isRequired: true,
                    child: TextFormBox(
                      controller: _urlController,
                      placeholder: l10n.odooUrlPlaceholder,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return l10n.odooUrlRequired;
                        }
                        final uri = Uri.tryParse(value.trim());
                        if (uri == null || !uri.hasScheme) {
                          return l10n.pleaseEnterValidUrl;
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Database Name
                  CustomInfoLabel(
                    label: l10n.databaseName,
                    isRequired: true,
                    child: TextFormBox(
                      controller: _databaseController,
                      placeholder: l10n.databaseNamePlaceholder,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return l10n.databaseNameRequired;
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Username
                  CustomInfoLabel(
                    label: l10n.odooUsername,
                    isRequired: true,
                    child: TextFormBox(
                      controller: _usernameController,
                      placeholder: l10n.adminPlaceholder,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return l10n.usernameRequired;
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Password
                  CustomInfoLabel(
                    label: l10n.odooPassword,
                    isRequired: true,
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormBox(
                            controller: _passwordController,
                            placeholder: l10n.passwordPlaceholder,
                            obscureText: !_showPassword,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return l10n.passwordRequired;
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        ToggleButton(
                          checked: _showPassword,
                          onChanged: (value) => setState(() => _showPassword = value),
                          child: Icon(
                            _showPassword ? FluentIcons.hide : FluentIcons.view,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Connection Test Result
                  if (_connectionTestResult != null) ...[
                    InfoBar(
                      title: Text(l10n.testConnection),
                      content: Text(_connectionTestResult!),
                      severity: _connectionSuccessful
                          ? InfoBarSeverity.success
                          : InfoBarSeverity.error,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Action Buttons
                  Row(
                    children: [
                      FilledButton(
                        onPressed: _isTestingConnection ? null : _testConnection,
                        child: _isTestingConnection
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: ProgressRing(strokeWidth: 2),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(l10n.testing),
                                ],
                              )
                            : Text(l10n.testConnection),
                      ),
                      const SizedBox(width: 12),
                      Button(
                        onPressed: _saveSettings,
                        child: Text(l10n.save),
                      ),
                      const SizedBox(width: 12),
                      Button(
                        onPressed: _loadCurrentSettings,
                        child: Text(l10n.reset),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Information section
                  Expander(
                    header: Text(l10n.connectionInformation),
                    content: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.connectionRequirements,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(l10n.odooRequirement1),
                          Text(l10n.odooRequirement2),
                          Text(l10n.odooRequirement3),
                          Text(l10n.odooRequirement4),
                          const SizedBox(height: 16),
                          Text(
                            l10n.supportedOperations,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(l10n.odooOperation1),
                          Text(l10n.odooOperation2),
                          Text(l10n.odooOperation3),
                          Text(l10n.odooOperation4),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}