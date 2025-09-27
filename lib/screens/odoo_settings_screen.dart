import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
// import 'package:weighing_system/gen_l10n/app_localizations.dart';
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
        displayInfoBar(
          context,
          builder: (context, close) => InfoBar(
            title: const Text('Save'),
            content: const Text('Odoo settings saved successfully!'),
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
        displayInfoBar(
          context,
          builder: (context, close) => InfoBar(
            title: const Text('Error'),
            content: Text('Failed to save settings: $e'),
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
      
      setState(() {
        _connectionSuccessful = success;
        _connectionTestResult = success 
            ? 'Connection successful!'
            : 'Connection failed!';
      });
      
    } catch (e) {
      setState(() {
        _connectionSuccessful = false;
        _connectionTestResult = 'Connection failed: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isTestingConnection = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // final l10n = AppLocalizations.of(context);
    
    return ScaffoldPage.scrollable(
      header: PageHeader(
        title: const Text('Odoo Settings'),
        commandBar: CommandBar(
          primaryItems: [
            CommandBarButton(
              icon: const Icon(FluentIcons.back),
              label: const Text('Back'),
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
                    'Odoo Settings',
                    style: FluentTheme.of(context).typography.subtitle,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Configure connection settings for Odoo ERP integration',
                    style: TextStyle(
                      color: Colors.grey[120],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Odoo URL
                  CustomInfoLabel(
                    label: 'Odoo URL',
                    isRequired: true,
                    child: TextFormBox(
                      controller: _urlController,
                      placeholder: 'https://your-odoo-instance.com',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Odoo URL is required';
                        }
                        final uri = Uri.tryParse(value.trim());
                        if (uri == null || !uri.hasScheme) {
                          return 'Please enter a valid URL';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Database Name
                  CustomInfoLabel(
                    label: 'Database Name',
                    isRequired: true,
                    child: TextFormBox(
                      controller: _databaseController,
                      placeholder: 'your-database-name',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Database name is required';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Username
                  CustomInfoLabel(
                    label: 'Username',
                    isRequired: true,
                    child: TextFormBox(
                      controller: _usernameController,
                      placeholder: 'admin',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Username is required';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Password
                  CustomInfoLabel(
                    label: 'Password',
                    isRequired: true,
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormBox(
                            controller: _passwordController,
                            placeholder: '••••••••',
                            obscureText: !_showPassword,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Password is required';
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
                      title: const Text('Test Connection'),
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
                                  const Text('Testing...'),
                                ],
                              )
                            : const Text('Test Connection'),
                      ),
                      const SizedBox(width: 12),
                      Button(
                        onPressed: _saveSettings,
                        child: const Text('Save'),
                      ),
                      const SizedBox(width: 12),
                      Button(
                        onPressed: _loadCurrentSettings,
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Information section
                  Expander(
                    header: const Text('Connection Information'),
                    content: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Connection Requirements:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text('• Ensure your Odoo instance is accessible'),
                          const Text('• Verify the database name is correct'),
                          const Text('• Use a user with proper access rights'),
                          const Text('• Check firewall and network connectivity'),
                          const SizedBox(height: 16),
                          const Text(
                            'Supported Operations:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text('• Sync clients and suppliers as res.partner'),
                          const Text('• Sync materials as product.product'),
                          const Text('• Create sales orders for loading operations'),
                          const Text('• Create purchase orders for unloading operations'),
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