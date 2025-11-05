import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/driver_plate_provider.dart';
import '../models/driver.dart';
import '../providers/tabs_provider.dart';
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
    final l10n = AppLocalizations.of(context)!;

    return ScaffoldPage.scrollable(
      header: PageHeader(
        title: Row(
          children: [
            const Icon(FluentIcons.contact),
            const SizedBox(width: 12),
            Text(l10n.driversAndPlateNumbers),
          ],
        ),
        commandBar: CommandBar(
          primaryItems: [
            CommandBarButton(
              icon: const Icon(FluentIcons.refresh),
              label: Text(l10n.refresh),
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
    final l10n = AppLocalizations.of(context)!;

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
                      placeholder: l10n.searchDrivers,
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
                        Text(l10n.addDriver),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Error Display
              if (driverPlateProvider.error != null) ...[
                InfoBar(
                  title: Text(l10n.error),
                  content: Text(driverPlateProvider.error!),
                  severity: InfoBarSeverity.error,
                ),
                const SizedBox(height: 16),
              ],

              // Loading State
              if (driverPlateProvider.isLoading)
                Center(
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
                        l10n.noDriversFoundAdd,
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
    final l10n = AppLocalizations.of(context)!;

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
                  Text('${l10n.plates}: ${driver.plateNumbers.join(", ")}'),
                if (driver.primaryContact?.isNotEmpty == true)
                  Text('${l10n.phonePrefix}: ${driver.primaryContact}'),
                if (driver.city?.isNotEmpty == true)
                  Text('${l10n.cityPrefix}: ${driver.city}'),
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
                    child: Text(
                      l10n.inactive,
                      style: const TextStyle(fontSize: 12, color: Colors.white),
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
    final l10n = AppLocalizations.of(context)!;
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
          title:
              Text(existingDriver == null ? l10n.addDriver : l10n.editDriver),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomInfoLabel(
                    label: l10n.name,
                    isRequired: true,
                    child: TextBox(
                      controller: nameController,
                      placeholder: l10n.enterDriverName,
                    ),
                  ),
                  const SizedBox(height: 16),
                  CustomInfoLabel(
                    label: l10n.plateNumbers,
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
                                    placeholder: l10n.enterPlateNumberHint,
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
                              Text(l10n.addPlateNumber),
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
                          label: l10n.phone,
                          child: TextBox(
                            controller: phoneController,
                            placeholder: l10n.phoneNumber,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomInfoLabel(
                          label: l10n.mobile,
                          child: TextBox(
                            controller: mobileController,
                            placeholder: l10n.mobileNumber,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  CustomInfoLabel(
                    label: l10n.city,
                    child: TextBox(
                      controller: cityController,
                      placeholder: l10n.enterCity,
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
                      Text(l10n.active),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            Button(
              child: Text(l10n.cancel),
              onPressed: () => Navigator.of(context).pop(),
            ),
            FilledButton(
              child: Text(l10n.save),
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
    bool? isNameModified;
    if (existingDriver == null) {
      success = await driverPlateProvider.addDriverWithPlates(
        name.trim(),
        plateNumbers,
        phone: phone.trim().isEmpty ? null : phone.trim(),
        mobile: mobile.trim().isEmpty ? null : mobile.trim(),
        city: city.trim().isEmpty ? null : city.trim(),
      );
    } else {
      isNameModified = existingDriver.name != name.trim();
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
      if (isNameModified != null && isNameModified == true) {
        await context
            .read<TabsProvider>()
            .updateTabsWith('driver_name', existingDriver!.name, name.trim());
      }
      Navigator.of(context).pop();
    }
  }

  void _showDeleteDriverConfirmation(BuildContext context, Driver driver) {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: Text(l10n.deleteDriver),
        content: Text('${l10n.deleteDriverConfirm} ${driver.name}?'),
        actions: [
          Button(
            child: Text(l10n.cancel),
            onPressed: () => Navigator.of(context).pop(),
          ),
          FilledButton(
            child: Text(l10n.delete),
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
