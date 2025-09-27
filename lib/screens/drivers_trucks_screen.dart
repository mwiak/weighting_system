import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
// import 'package:weighing_system/gen_l10n/app_localizations.dart'; // Commented out - localization not available
import '../providers/driver_plate_provider.dart';
import '../models/driver.dart';
import '../widgets/custom_info_label.dart';

/// Drivers Management Screen
///
/// Management interface for drivers and their associated plate numbers in the weighing system.
/// Each driver can be associated with multiple plate numbers.
class DriversTrucksScreen extends StatefulWidget {
  const DriversTrucksScreen({super.key});

  @override
  State<DriversTrucksScreen> createState() => _DriversTrucksScreenState();
}

class _DriversTrucksScreenState extends State<DriversTrucksScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    context.read<DriverPlateProvider>().loadDriverPlates();
  }

  @override
  Widget build(BuildContext context) {
    // final l10n = AppLocalizations.of(context)!; // Commented out - localization not available

    return ScaffoldPage.scrollable(
      header: PageHeader(
        title: Row(
          children: [
            const Icon(FluentIcons.contact),
            const SizedBox(width: 12),
            Text('Drivers & Plate Numbers'),
          ],
        ),
        commandBar: CommandBar(
          primaryItems: [
            CommandBarButton(
              icon: const Icon(FluentIcons.refresh),
              label: const Text('Refresh'),
              onPressed: _loadData,
            ),
          ],
        ),
      ),
      children: [
        SizedBox(height: 750, child: _buildDriversSection(context)),
      ],
    );
  }

  Widget _buildDriversSection(BuildContext context) {
    return Consumer<DriverPlateProvider>(
      builder: (context, driverPlateProvider, child) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Search and Actions Row
              Row(
                children: [
                  Expanded(
                    child: TextBox(
                      placeholder: 'Search drivers...',
                      onChanged: (query) => {}, // TODO: Implement search
                      prefix: const Icon(FluentIcons.search),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: () => _showAddDriverDialog(context),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(FluentIcons.add, size: 16),
                        const SizedBox(width: 4),
                        Text('Add Driver'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Error Display
              if (driverPlateProvider.error != null) ...[
                InfoBar(
                  title: Text('Error'),
                  content: Text(driverPlateProvider.error!),
                  severity: InfoBarSeverity.error,
                ),
                const SizedBox(height: 16),
              ],

              // Loading State
              if (driverPlateProvider.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: ProgressRing(),
                  ),
                )
              else if (driverPlateProvider.driversWithPlates.isEmpty)
                Center(
                  child: Column(
                    children: [
                      const SizedBox(height: 32),
                      const Icon(FluentIcons.contact, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        'No drivers found. Add your first driver to get started.',
                        style: FluentTheme.of(context).typography.body,
                      ),
                    ],
                  ),
                )
              else
                Expanded(
                  child: _buildDriversList(
                      context, driverPlateProvider.driversWithPlates),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDriversList(BuildContext context, List<Driver> drivers) {
    return ListView.builder(
      itemCount: drivers.length,
      itemBuilder: (context, index) {
        final driver = drivers[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(
              driver.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (driver.plateNumbers.isNotEmpty)
                  Text('Plates: ${driver.plateNumbers.join(", ")}'),
                if (driver.primaryContact?.isNotEmpty == true)
                  Text('Phone: ${driver.primaryContact}'),
                if (driver.city?.isNotEmpty == true)
                  Text('City: ${driver.city}'),
              ],
            ),
            leading: CircleAvatar(
              backgroundColor: driver.active ? Colors.green : Colors.grey,
              child: Text(
                driver.name.isNotEmpty ? driver.name[0].toUpperCase() : 'D',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!driver.active)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Inactive',
                      style: TextStyle(fontSize: 12, color: Colors.white),
                    ),
                  ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(FluentIcons.edit),
                  onPressed: () => _showEditDriverDialog(context, driver),
                ),
                IconButton(
                  icon: const Icon(FluentIcons.delete),
                  onPressed: () =>
                      _showDeleteDriverConfirmation(context, driver),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddDriverDialog(BuildContext context) {
    _showDriverDialog(context, null);
  }

  void _showEditDriverDialog(BuildContext context, Driver driver) {
    _showDriverDialog(context, driver);
  }

  void _showDriverDialog(BuildContext context, Driver? existingDriver) {
    final nameController =
        TextEditingController(text: existingDriver?.name ?? '');
    final phoneController =
        TextEditingController(text: existingDriver?.phone ?? '');
    final mobileController =
        TextEditingController(text: existingDriver?.mobile ?? '');
    final cityController =
        TextEditingController(text: existingDriver?.city ?? '');
    List<String> plateNumbers =
        List<String>.from(existingDriver?.plateNumbers ?? ['']);
    bool isActive = existingDriver?.active ?? true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => ContentDialog(
          title: Text(existingDriver == null ? 'Add Driver' : 'Edit Driver'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomInfoLabel(
                    label: 'Name',
                    isRequired: true,
                    child: TextBox(
                      controller: nameController,
                      placeholder: 'Enter driver name',
                    ),
                  ),
                  const SizedBox(height: 16),
                  CustomInfoLabel(
                    label: 'Plate Numbers',
                    isRequired: true,
                    child: Column(
                      children: [
                        for (int i = 0; i < plateNumbers.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextBox(
                                    controller: TextEditingController(
                                        text: plateNumbers[i]),
                                    placeholder: 'Enter plate number',
                                    onChanged: (value) =>
                                        plateNumbers[i] = value,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (plateNumbers.length > 1)
                                  IconButton(
                                    icon: const Icon(FluentIcons.remove),
                                    onPressed: () => setState(
                                        () => plateNumbers.removeAt(i)),
                                  ),
                              ],
                            ),
                          ),
                        Button(
                          onPressed: () => setState(() => plateNumbers.add('')),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(FluentIcons.add, size: 16),
                              const SizedBox(width: 4),
                              const Text('Add Plate Number'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: CustomInfoLabel(
                          label: 'Phone',
                          child: TextBox(
                            controller: phoneController,
                            placeholder: 'Phone number',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomInfoLabel(
                          label: 'Mobile',
                          child: TextBox(
                            controller: mobileController,
                            placeholder: 'Mobile number',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  CustomInfoLabel(
                    label: 'City',
                    child: TextBox(
                      controller: cityController,
                      placeholder: 'Enter city',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Checkbox(
                        checked: isActive,
                        onChanged: (value) =>
                            setState(() => isActive = value ?? true),
                      ),
                      const SizedBox(width: 8),
                      const Text('Active'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            Button(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            FilledButton(
              child: const Text('Save'),
              onPressed: () => _saveDriver(
                context,
                existingDriver,
                nameController.text,
                plateNumbers.where((p) => p.trim().isNotEmpty).toList(),
                phoneController.text,
                mobileController.text,
                cityController.text,
                isActive,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveDriver(
    BuildContext context,
    Driver? existingDriver,
    String name,
    List<String> plateNumbers,
    String phone,
    String mobile,
    String city,
    bool isActive,
  ) async {
    final driverPlateProvider = context.read<DriverPlateProvider>();
    bool success;

    if (existingDriver == null) {
      success = await driverPlateProvider.addDriverWithPlates(
        name.trim(),
        plateNumbers,
        phone: phone.trim().isEmpty ? null : phone.trim(),
        mobile: mobile.trim().isEmpty ? null : mobile.trim(),
        city: city.trim().isEmpty ? null : city.trim(),
      );
    } else {
      success = await driverPlateProvider.updateDriverWithPlates(
        existingDriver.id!,
        name.trim(),
        plateNumbers,
        phone: phone.trim().isEmpty ? null : phone.trim(),
        mobile: mobile.trim().isEmpty ? null : mobile.trim(),
        city: city.trim().isEmpty ? null : city.trim(),
      );
    }

    if (success && mounted) {
      Navigator.of(context).pop();
    }
  }

  void _showDeleteDriverConfirmation(BuildContext context, Driver driver) {
    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Delete Driver'),
        content: Text('Are you sure you want to delete ${driver.name}?'),
        actions: [
          Button(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          FilledButton(
            child: const Text('Delete'),
            onPressed: () async {
              Navigator.of(context).pop();
              if (driver.id != null) {
                await context
                    .read<DriverPlateProvider>()
                    .deleteDriver(driver.id!);
              }
            },
          ),
        ],
      ),
    );
  }
}
