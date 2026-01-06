// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Weighing System';

  @override
  String get weighingOperations => 'Weighing Operations';

  @override
  String get clients => 'Clients';

  @override
  String get suppliers => 'Suppliers';

  @override
  String get drivers => 'Drivers';

  @override
  String get trucks => 'Trucks';

  @override
  String get materials => 'Materials';

  @override
  String get reports => 'Reports';

  @override
  String get settings => 'Settings';

  @override
  String get operationsHistory => 'Operations History';

  @override
  String get currentWeight => 'Current Weight';

  @override
  String get grossWeight => 'Gross Weight';

  @override
  String get tareWeight => 'Tare Weight';

  @override
  String get netWeight => 'Net Weight';

  @override
  String get orderNumber => 'Order Number';

  @override
  String get truckPlate => 'Truck Plate';

  @override
  String get driverName => 'Driver Name';

  @override
  String get operationType => 'Operation Type';

  @override
  String get loading => 'Loading';

  @override
  String get unloading => 'Unloading';

  @override
  String get client => 'Client';

  @override
  String get supplier => 'Supplier';

  @override
  String get material => 'Material';

  @override
  String get price => 'Price';

  @override
  String get totalAmount => 'Total Amount';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get add => 'Add';

  @override
  String get name => 'Name';

  @override
  String get email => 'Email';

  @override
  String get phone => 'Phone';

  @override
  String get mobile => 'Mobile';

  @override
  String get city => 'City';

  @override
  String get licenseNumber => 'License Number';

  @override
  String get plateNumber => 'Plate Number';

  @override
  String get model => 'Model';

  @override
  String get capacity => 'Capacity';

  @override
  String get active => 'Active';

  @override
  String get status => 'Status';

  @override
  String get notes => 'Notes';

  @override
  String get weighInTime => 'Weigh In Time';

  @override
  String get weighOutTime => 'Weigh Out Time';

  @override
  String get createDate => 'Create Date';

  @override
  String get odooSettings => 'Odoo Settings';

  @override
  String get odooUrl => 'Odoo URL';

  @override
  String get odooDatabase => 'Database Name';

  @override
  String get odooUsername => 'Username';

  @override
  String get odooPassword => 'Password';

  @override
  String get testConnection => 'Test Connection';

  @override
  String get connectionSuccessful => 'Connection successful!';

  @override
  String get connectionFailed => 'Connection failed!';

  @override
  String get kg => 'kg';

  @override
  String get tons => 'tons';

  @override
  String get driversAndTrucks => 'Drivers & Trucks';

  @override
  String get addDriver => 'Add Driver';

  @override
  String get addTruck => 'Add Truck';

  @override
  String get showPriceOnPrint => 'Show Price on Print';

  @override
  String get newTab => 'New Tab';

  @override
  String get closeTab => 'Close Tab';

  @override
  String get unitPrice => 'Unit Price';

  @override
  String get pricePerKg => 'Price per kg';

  @override
  String get noItemsFound => 'No items found';

  @override
  String get loading_data => 'Loading data...';

  @override
  String get confirm => 'Confirm';

  @override
  String get close => 'Close';

  @override
  String get search => 'Search';

  @override
  String get selectClient => 'Select Client';

  @override
  String get selectSupplier => 'Select Supplier';

  @override
  String get selectMaterial => 'Select Material';

  @override
  String get addClient => 'Add Client';

  @override
  String get addSupplier => 'Add Supplier';

  @override
  String get addMaterial => 'Add Material';

  @override
  String get editClient => 'Edit Client';

  @override
  String get editSupplier => 'Edit Supplier';

  @override
  String get editMaterial => 'Edit Material';

  @override
  String get required => 'Required';

  @override
  String get refresh => 'Refresh';

  @override
  String get searchDrivers => 'Search drivers...';

  @override
  String get searchTrucks => 'Search trucks...';

  @override
  String get error => 'Error';

  @override
  String get noDriversFound => 'No drivers found matching';

  @override
  String get noDriversFoundAdd =>
      'No drivers found. Add your first driver to get started.';

  @override
  String get noTrucksFound => 'No trucks found matching';

  @override
  String get noTrucksFoundAdd =>
      'No trucks found. Add your first truck to get started.';

  @override
  String get license => 'License';

  @override
  String get inactive => 'Inactive';

  @override
  String get enterDriverName => 'Enter driver name...';

  @override
  String get enterLicenseNumber => 'Enter license number';

  @override
  String get phoneNumber => 'Phone number';

  @override
  String get mobileNumber => 'Mobile number';

  @override
  String get enterCity => 'Enter city';

  @override
  String get enterPlateNumber => 'Enter plate number';

  @override
  String get enterTruckModel => 'Enter truck model';

  @override
  String get capacityKg => 'Capacity (kg)';

  @override
  String get enterCapacityKg => 'Enter capacity in kg';

  @override
  String get assignedDriver => 'Assigned Driver';

  @override
  String get noDriverAssigned => 'No driver assigned';

  @override
  String get driverNotAssigned => 'Driver: Not assigned';

  @override
  String get deleteDriver => 'Delete Driver';

  @override
  String get deleteDriverConfirm => 'Are you sure you want to delete';

  @override
  String get deleteTruck => 'Delete Truck';

  @override
  String get deleteTruckConfirm => 'Are you sure you want to delete truck';

  @override
  String get resetScale => 'Reset Scale';

  @override
  String get maximumTabsReached => 'Maximum Tabs Reached';

  @override
  String maximumTabsMessage(int maxTabs, Object count) {
    return 'You can have a maximum of $maxTabs operations open at once. Please close some tabs before creating new ones.';
  }

  @override
  String get ok => 'OK';

  @override
  String get tabUnsavedChanges =>
      'This tab has unsaved changes. Closing it will create a new empty tab. Continue?';

  @override
  String get unsavedChanges => 'Unsaved Changes';

  @override
  String get unsavedChangesMessage =>
      'This operation has unsaved changes. Are you sure you want to close it?';

  @override
  String get closeAnyway => 'Close Anyway';

  @override
  String get print => 'Print';

  @override
  String get printing => 'Printing operation';

  @override
  String get cancelOperation => 'Cancel Operation';

  @override
  String get cancelOperationConfirm =>
      'Are you sure you want to cancel this operation? All data will be lost.';

  @override
  String get no => 'No';

  @override
  String get yesCancel => 'Yes, Cancel';

  @override
  String get reportsAndAnalytics => 'Reports & Analytics';

  @override
  String get exportPdf => 'Export PDF';

  @override
  String get exportCsv => 'Export CSV';

  @override
  String get reportTypes => 'Report Types';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get ordersReport => 'Orders Report';

  @override
  String get revenueReport => 'Revenue Report';

  @override
  String get clientReport => 'Client Report';

  @override
  String get materialReport => 'Material Report';

  @override
  String get filters => 'Filters';

  @override
  String get startDate => 'Start Date';

  @override
  String get endDate => 'End Date';

  @override
  String get quickRange => 'Quick Range';

  @override
  String get last7Days => 'Last 7 Days';

  @override
  String get last30Days => 'Last 30 Days';

  @override
  String get last90Days => 'Last 90 Days';

  @override
  String get thisYear => 'This Year';

  @override
  String get loadingDots => 'Loading...';

  @override
  String get applyFilters => 'Apply Filters';

  @override
  String get clear => 'Clear';

  @override
  String get clientFilter => 'Client Filter';

  @override
  String get allClients => 'All Clients';

  @override
  String get statusFilter => 'Status Filter';

  @override
  String get allStatuses => 'All Statuses';

  @override
  String get completed => 'Completed';

  @override
  String get cancelled => 'Cancelled';

  @override
  String get groupBy => 'Group By';

  @override
  String get daily => 'Daily';

  @override
  String get weekly => 'Weekly';

  @override
  String get monthly => 'Monthly';

  @override
  String get generatingReport => 'Generating report...';

  @override
  String get unknownError => 'Unknown Error';

  @override
  String get selectReportType => 'Select a report type to view data';

  @override
  String get noDashboardData => 'No dashboard data available';

  @override
  String get totalOrders => 'Total Orders';

  @override
  String get totalWeight => 'Total Weight';

  @override
  String get totalRevenue => 'Total Revenue';

  @override
  String get activeOrders => 'Active Orders';

  @override
  String get ordersByStatus => 'Orders by Status';

  @override
  String get topClientsByRevenue => 'Top Clients by Revenue';

  @override
  String get unknown => 'Unknown';

  @override
  String get noReportData => 'No report data available';

  @override
  String get generated => 'Generated';

  @override
  String get records => 'records';

  @override
  String showingFirst(int count, int total) {
    return 'Showing first $count of $total records. Export to view all data.';
  }

  @override
  String get exportSuccessful => 'Export Successful';

  @override
  String pdfSavedTo(String path) {
    return 'PDF saved to: $path';
  }

  @override
  String csvSavedTo(String path) {
    return 'CSV saved to: $path';
  }

  @override
  String get printTemplates => 'Print Templates';

  @override
  String get noActiveTabs => 'No Active Tabs';

  @override
  String get clickNewTabToStart =>
      'Click \"New Tab\" to start a new weighing operation';

  @override
  String get reconnectToScale => 'Reconnect to Scale';

  @override
  String get selectPrinter => 'Select Printer';

  @override
  String get saveAsPdf => 'Save as PDF';

  @override
  String get silentPrint => 'Silent Print';

  @override
  String get exportWithTemplate => 'Export with Template';

  @override
  String get selectTemplate => 'Select Template';

  @override
  String get noTemplatesAvailable => 'No Templates Available';

  @override
  String get noTemplatesMessage =>
      'No templates are available. Would you like to create a default template?';

  @override
  String get createDefault => 'Create Default';

  @override
  String get exportOptions => 'Export Options';

  @override
  String get printWithTemplate => 'Print with Template';

  @override
  String get printDirectlyUsingTemplate => 'Print directly using the template';

  @override
  String get saveTemplateExportAsPdf => 'Save template export as PDF file';

  @override
  String get printWeighingTicket => 'Print Weighing Ticket';

  @override
  String get printReceipt => 'Print Receipt';

  @override
  String get connected => 'Connected';

  @override
  String get disconnected => 'Disconnected';

  @override
  String get replugDevice => 'Replug Device';

  @override
  String get reconnecting => 'Reconnecting';

  @override
  String get noDevicesAvailable => 'No Devices Available';

  @override
  String get scanning => 'Scanning';

  @override
  String get connecting => 'Connecting';

  @override
  String get loadingOperationsHistory => 'Loading Operations History';

  @override
  String get filterByMaterial => 'Filter by material...';

  @override
  String get filterByDriver => 'Filter by driver...';

  @override
  String get filterByPlate => 'Filter by plate...';

  @override
  String get filterBySupplier => 'Filter by supplier...';

  @override
  String get filterByClient => 'Filter by client...';

  @override
  String get dateTime => 'Date/Time';

  @override
  String get netWeightKg => 'Net Weight (kg)';

  @override
  String operationsFound(int count) {
    return 'Operations History ($count found)';
  }

  @override
  String get loadingOperations => 'Loading operations...';

  @override
  String get noOperationsFound =>
      'No operations found for the selected criteria.';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statusIncomplete => 'Incomplete';

  @override
  String get statusInProgress => 'In Progress';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get statusEmpty => 'Empty';

  @override
  String get clearFilters => 'Clear';

  @override
  String get clientManagement => 'Client Management';

  @override
  String get supplierManagement => 'Supplier Management';

  @override
  String get newClient => 'New Client';

  @override
  String get newSupplier => 'New Supplier';

  @override
  String get import => 'Import';

  @override
  String get export => 'Export';

  @override
  String get totalClients => 'Total Clients';

  @override
  String get activeClients => 'Active Clients';

  @override
  String get totalSuppliers => 'Total Suppliers';

  @override
  String get activeSuppliers => 'Active Suppliers';

  @override
  String get companies => 'Companies';

  @override
  String get individuals => 'Individuals';

  @override
  String get searchClients => 'Search clients...';

  @override
  String get searchSuppliers => 'Search suppliers...';

  @override
  String get activeOnly => 'Active only';

  @override
  String get contact => 'Contact';

  @override
  String get address => 'Address';

  @override
  String get type => 'Type';

  @override
  String get actions => 'Actions';

  @override
  String get company => 'Company';

  @override
  String get individual => 'Individual';

  @override
  String get noContactInfo => 'No contact info';

  @override
  String get noClientsFound => 'No clients found';

  @override
  String get createFirstClient => 'Create your first client to get started';

  @override
  String get createClient => 'Create Client';

  @override
  String get noSuppliersFound => 'No suppliers found';

  @override
  String get createFirstSupplier => 'Create your first supplier to get started';

  @override
  String get createSupplier => 'Create Supplier';

  @override
  String get deleteClient => 'Delete Client';

  @override
  String deleteClientConfirm(String name) {
    return 'Are you sure you want to delete \"$name\"?';
  }

  @override
  String get deleteSupplier => 'Delete Supplier';

  @override
  String deleteSupplierConfirm(String name) {
    return 'Are you sure you want to delete \"$name\"?';
  }

  @override
  String get importFunctionalityComingSoon =>
      'Import functionality coming soon';

  @override
  String exportedClients(int count) {
    return 'Exported $count clients';
  }

  @override
  String exportedSuppliers(int count) {
    return 'Exported $count suppliers';
  }

  @override
  String get vat => 'VAT';

  @override
  String get weightInformation => 'Weight Information';

  @override
  String get emptyWeight => 'Empty Weight';

  @override
  String get emptyWeightKg => 'Empty Weight (kg)';

  @override
  String get grossWeightKg => 'Gross Weight (kg)';

  @override
  String get businessInformation => 'Business Information';

  @override
  String get truckPlateRequired => 'Truck Plate *';

  @override
  String get enterTruckPlate => 'Enter truck plate...';

  @override
  String get customerLoadingOperation => 'Customer (Loading Operation)';

  @override
  String get selectCustomer => 'Select Customer...';

  @override
  String get supplierUnloadingOperation => 'Supplier (Unloading Operation)';

  @override
  String get materialRequired => 'Material *';

  @override
  String get paid => 'Paid';

  @override
  String get complete => 'Complete';

  @override
  String get incomplete => 'Incomplete';

  @override
  String get savePDF => 'Save PDF';

  @override
  String get inProgress => 'In Progress';

  @override
  String get empty => 'Empty';

  @override
  String get statusLabel => 'Status:';

  @override
  String get tabNotFound => 'Tab not found';

  @override
  String get couldNotFindTemplate => 'Could not find a template';

  @override
  String get scaleMustBeConnected =>
      'Scale must be connected before capturing weight';

  @override
  String get cannotCaptureWhileEditing =>
      'Cannot capture weight while editing field';

  @override
  String printingOperation(String operation) {
    return 'Printing $operation...';
  }

  @override
  String get tabCancelled => 'Tab cancelled';

  @override
  String get tabCompletedAndMoved => 'Tab completed and moved to history';

  @override
  String get unableToCompleteTab =>
      'Unable to complete tab. Please fill all required fields.';

  @override
  String get orderDetails => 'Order Details';

  @override
  String get basicInformation => 'Basic Information';

  @override
  String get vehicleInformation => 'Vehicle Information';

  @override
  String get businessPartners => 'Business Partners';

  @override
  String get weightMeasurements => 'Weight Measurements';

  @override
  String get financialInformation => 'Financial Information';

  @override
  String get printSuccessful => 'Print Successful';

  @override
  String get pdfSaved => 'PDF Saved Successfully';

  @override
  String get chooseUser => 'Choose User';

  @override
  String get loginFailed => 'Login Failed';

  @override
  String loggingInAs(String username) {
    return 'Logging in as: $username';
  }

  @override
  String get password => 'Password';

  @override
  String get enterYourPassword => 'Enter your password';

  @override
  String get continue_ => 'Continue';

  @override
  String get back => 'Back';

  @override
  String get pleaseEnterPassword => 'Please enter your password';

  @override
  String get incorrectPassword => 'Incorrect password. Please try again.';

  @override
  String get userNotFound => 'User not found.';

  @override
  String get generalSettings => 'General Settings';

  @override
  String get users => 'Users';

  @override
  String get scaleConnection => 'Scale Connection';

  @override
  String get advancedSettings => 'Advanced Settings';

  @override
  String connectedToPort(String port) {
    return 'Connected to $port';
  }

  @override
  String get scanningForDevices => 'Scanning for devices...';

  @override
  String get notConnected => 'Not connected';

  @override
  String get reconnect => 'Reconnect';

  @override
  String get currentWeightLabel => 'Current Weight: ';

  @override
  String get port => 'Port: ';

  @override
  String get baud => 'Baud: ';

  @override
  String get userManagement => 'User Management';

  @override
  String get addUser => 'Add User';

  @override
  String get noUsersFound => 'No users found';

  @override
  String get username => 'Username';

  @override
  String get admin => 'Admin';

  @override
  String get user => 'User';

  @override
  String get confirmDelete => 'Confirm Delete';

  @override
  String deleteUserConfirm(String username) {
    return 'Are you sure you want to delete user \"$username\"?\\n\\nThis action cannot be undone.';
  }

  @override
  String get materialManagement => 'Material Management';

  @override
  String get newMaterial => 'New Material';

  @override
  String get totalMaterials => 'Total Materials';

  @override
  String get withPrice => 'With Price';

  @override
  String get pricingOverview => 'Pricing Overview';

  @override
  String get averagePrice => 'Average Price';

  @override
  String get mostExpensive => 'Most Expensive';

  @override
  String get searchMaterials => 'Search materials...';

  @override
  String get clearFiltersButton => 'Clear Filters';

  @override
  String get noMaterialsFound => 'No materials found';

  @override
  String get createFirstMaterial => 'Create your first material to get started';

  @override
  String get createMaterial => 'Create Material';

  @override
  String get code => 'Code';

  @override
  String get noPrice => 'No price';

  @override
  String get deleteMaterial => 'Delete Material';

  @override
  String deleteMaterialConfirm(String name) {
    return 'Are you sure you want to delete \"$name\"?';
  }

  @override
  String exportedMaterials(int count) {
    return 'Exported $count materials';
  }

  @override
  String get driversAndPlateNumbers => 'Drivers & Plate Numbers';

  @override
  String get addPlateNumber => 'Add Plate Number';

  @override
  String get editDriver => 'Edit Driver';

  @override
  String get plateNumbers => 'Plate Numbers';

  @override
  String get enterPlateNumberHint => 'Enter plate number';

  @override
  String get plates => 'Plates: ';

  @override
  String get phonePrefix => 'Phone: ';

  @override
  String get cityPrefix => 'City: ';

  @override
  String get noTabSelected => 'No tab selected';

  @override
  String get searchLabel => 'Search';

  @override
  String get actionsColumn => 'Actions';

  @override
  String get usernameRequired => 'Username is required';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get validationError => 'Validation Error';

  @override
  String get editUser => 'Edit User';

  @override
  String get addNewUser => 'Add New User';

  @override
  String get enterUsername => 'Enter username';

  @override
  String get userType => 'User Type';

  @override
  String get normalUser => 'Normal User';

  @override
  String get enterPassword => 'Enter password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get reEnterPassword => 'Re-enter password';

  @override
  String get passwordChangeHint =>
      'To change password, use the \"Change Password\" button';

  @override
  String get update => 'Update';

  @override
  String get create => 'Create';

  @override
  String changePasswordFor(String username) {
    return 'Change Password for $username';
  }

  @override
  String get newPassword => 'New Password';

  @override
  String get enterNewPassword => 'Enter new password';

  @override
  String get confirmNewPassword => 'Confirm New Password';

  @override
  String get reEnterNewPassword => 'Re-enter new password';

  @override
  String get changePassword => 'Change Password';

  @override
  String get tabDetails => 'Tab Details';

  @override
  String get noTabSelectedMessage => 'No Tab Selected';

  @override
  String get selectTabToView => 'Select a tab to view details';

  @override
  String get unsaved => 'UNSAVED';

  @override
  String get truckPlateLabel => 'Truck Plate';

  @override
  String get notSpecified => 'Not specified';

  @override
  String get notRecorded => 'Not recorded';

  @override
  String get notCalculated => 'Not calculated';

  @override
  String get clientSupplier => 'Client/Supplier';

  @override
  String get paymentStatus => 'Payment Status';

  @override
  String get unpaid => 'Unpaid';

  @override
  String get yes => 'Yes';

  @override
  String get timingInformation => 'Timing Information';

  @override
  String get createdAt => 'Created At';

  @override
  String get lastUpdated => 'Last Updated';

  @override
  String get startWeighing => 'Start Weighing';

  @override
  String get continueWeighing => 'Continue Weighing';

  @override
  String get completeTab => 'Complete Tab';

  @override
  String get reset => 'Reset';

  @override
  String completeTabConfirm(String tabTitle) {
    return 'Mark tab \"$tabTitle\" as completed?';
  }

  @override
  String get tabCompletedSuccess => 'Tab completed successfully';

  @override
  String get tabEditingComingSoon => 'Tab editing functionality coming soon';

  @override
  String get printFunctionalityComingSoon => 'Print functionality coming soon';

  @override
  String get resetTab => 'Reset Tab';

  @override
  String resetTabConfirm(String tabTitle) {
    return 'Reset all data in tab \"$tabTitle\"? This action cannot be undone.';
  }

  @override
  String get tabResetSuccess => 'Tab reset successfully';

  @override
  String get cancelTab => 'Cancel Tab';

  @override
  String cancelTabConfirm(String tabTitle) {
    return 'Cancel tab \"$tabTitle\"?';
  }

  @override
  String get yesCancelTab => 'Yes, Cancel';

  @override
  String get tabCancelledMessage => 'Tab cancelled';

  @override
  String get failedToCancelTab => 'Failed to cancel tab';

  @override
  String get readyToComplete => 'Ready to Complete';

  @override
  String get notSet => 'Not set';

  @override
  String get switchToWeighingTab =>
      'Switch to the weighing tab to start recording weights';

  @override
  String get switchToWeighingTabContinue =>
      'Switch to the weighing tab to continue recording weights';

  @override
  String printFailed(String error) {
    return 'Print failed: $error';
  }

  @override
  String savePdfFailed(String error) {
    return 'Save PDF failed: $error';
  }

  @override
  String get lastUpdatedLabel => 'Last Updated';

  @override
  String get paidLabel => 'Paid';

  @override
  String get showPriceOnPrintLabel => 'Show Price on Print';

  @override
  String get additionalInfo => 'Additional Information';

  @override
  String get unsavedChangesLabel => 'Unsaved Changes';

  @override
  String get completedLabel => 'Completed';

  @override
  String get databaseId => 'Database ID';

  @override
  String get unsavedLabel => 'Unsaved';

  @override
  String get notAvailable => 'Not available';

  @override
  String get na => 'N/A';

  @override
  String get loadingOutgoing => 'Loading (Outgoing)';

  @override
  String get unloadingIncoming => 'Unloading (Incoming)';

  @override
  String get totalTabs => 'Total Tabs';

  @override
  String get activeTabs => 'Active Tabs';

  @override
  String get topDriversByWeight => 'Top Drivers by Weight';

  @override
  String maximumTabsCount(int count) {
    return 'You can have a maximum of $count operations open at once. Please close some tabs before creating new ones.';
  }

  @override
  String get synchronization => 'Synchronization';

  @override
  String get syncStatus => 'Sync Status';

  @override
  String get pendingItems => 'Pending items';

  @override
  String get syncNow => 'Sync Now';

  @override
  String get clearFailed => 'Clear Failed';

  @override
  String get scaleConnectionSettings => 'Scale Connection Settings';

  @override
  String get connectionStatus => 'Connection Status';

  @override
  String get connectedTo => 'Connected to';

  @override
  String get tryToConnect => 'Try to Connect';

  @override
  String get portConfiguration => 'Port Configuration';

  @override
  String get comPort => 'COM Port';

  @override
  String get autoDetect => 'Auto-detect';

  @override
  String get baudRate => 'Baud Rate';

  @override
  String get dataBits => 'Data Bits';

  @override
  String get stopBits => 'Stop Bits';

  @override
  String get parity => 'Parity';

  @override
  String get scaleInformation => 'Scale Information';

  @override
  String get protocol => 'Protocol';

  @override
  String get serialComReadOnly => 'Serial COM - Read Only';

  @override
  String get expectedFormat => 'Expected Format';

  @override
  String get weightFormatExample => '(±)(6 digits)(KG)';

  @override
  String get readingInterval => 'Reading Interval';

  @override
  String get readingInterval100ms => '100ms';

  @override
  String get connectionRetry => 'Connection Retry';

  @override
  String get connectionRetryInterval => 'Every 40ms';

  @override
  String get kgUnit => 'kg';

  @override
  String get disconnectedFromScale => 'Disconnected from scale';

  @override
  String get disconnect => 'Disconnect';

  @override
  String get attemptingToReconnect => 'Attempting to reconnect...';

  @override
  String get printConfiguration => 'Print Configuration';

  @override
  String get managePrintTemplates => 'Manage Print Templates';

  @override
  String get printTemplateSystem => 'Print Template System';

  @override
  String get configureTemplatesDescription =>
      'Configure print templates for your pre-printed A3 forms:';

  @override
  String get createCustomTemplates => 'Create custom templates';

  @override
  String get dragDropFieldPositioning => 'Drag & drop field positioning';

  @override
  String get configureFontsFormatting => 'Configure fonts and formatting';

  @override
  String get importExportTemplates => 'Import/Export templates';

  @override
  String get testPrintAlignment => 'Test print alignment';

  @override
  String get odooSettingsSavedSuccess => 'Odoo settings saved successfully!';

  @override
  String get failedToSaveSettings => 'Failed to save settings';

  @override
  String get connectionFailedWithError => 'Connection failed';

  @override
  String get odooSettingsDescription =>
      'Configure connection settings for Odoo ERP integration';

  @override
  String get odooUrlPlaceholder => 'https://your-odoo-instance.com';

  @override
  String get odooUrlRequired => 'Odoo URL is required';

  @override
  String get pleaseEnterValidUrl => 'Please enter a valid URL';

  @override
  String get databaseName => 'Database Name';

  @override
  String get databaseNamePlaceholder => 'your-database-name';

  @override
  String get databaseNameRequired => 'Database name is required';

  @override
  String get adminPlaceholder => 'admin';

  @override
  String get passwordPlaceholder => '••••••••';

  @override
  String get testing => 'Testing...';

  @override
  String get connectionInformation => 'Connection Information';

  @override
  String get connectionRequirements => 'Connection Requirements:';

  @override
  String get odooRequirement1 => '• Ensure your Odoo instance is accessible';

  @override
  String get odooRequirement2 => '• Verify the database name is correct';

  @override
  String get odooRequirement3 => '• Use a user with proper access rights';

  @override
  String get odooRequirement4 => '• Check firewall and network connectivity';

  @override
  String get supportedOperations => 'Supported Operations:';

  @override
  String get odooOperation1 => '• Sync clients and suppliers as res.partner';

  @override
  String get odooOperation2 => '• Sync materials as product.product';

  @override
  String get odooOperation3 => '• Create sales orders for loading operations';

  @override
  String get odooOperation4 =>
      '• Create purchase orders for unloading operations';

  @override
  String get newTemplate => 'New Template';

  @override
  String get testPrint => 'Test Print';

  @override
  String get printAlignmentGrid => 'Print Alignment Grid';

  @override
  String get exportXps => 'Export XPS';

  @override
  String get searchTemplates => 'Search templates...';

  @override
  String get selectTemplateToPreview => 'Select a template to preview';

  @override
  String get templatePreview => 'Template Preview';

  @override
  String get printTemplateManagement => 'Print Template Management';

  @override
  String get templateDetails => 'Template Details';

  @override
  String get nameLabel => 'Name:';

  @override
  String get descriptionLabel => 'Description:';

  @override
  String get paperSizeLabel => 'Paper Size:';

  @override
  String get orientationLabel => 'Orientation:';

  @override
  String get fieldsLabel => 'Fields:';

  @override
  String get createdLabel => 'Created:';

  @override
  String get updatedLabel => 'Updated:';

  @override
  String get fields => 'Fields';

  @override
  String get fontLabel => 'Font:';

  @override
  String get pt => 'pt';

  @override
  String get bold => 'Bold';

  @override
  String get formatLabel => 'Format:';

  @override
  String get noFieldsInTemplate => 'No fields in template';

  @override
  String get backgroundImageNotFound => 'Background image not found';

  @override
  String get errorLoadingBackgroundImage => 'Error loading background image';

  @override
  String get deleteTemplate => 'Delete Template';

  @override
  String get areYouSureDeleteTemplate => 'Are you sure you want to delete';

  @override
  String get failedToDeleteTemplate => 'Failed to delete template';

  @override
  String get testPrintOptions => 'Test Print Options';

  @override
  String get chooseTestPrintMethod => 'Choose how to test print this template:';

  @override
  String get printWithXps => 'PRINT WITH XPS';

  @override
  String get silentPrintWindowsDirect => 'Silent Print (Windows Direct)';

  @override
  String get printWithDialogPreview => 'Print with Dialog (Preview)';

  @override
  String get silentPrintingFailed =>
      'Silent printing failed with the following error:';

  @override
  String get possibleSolutions => 'Possible solutions:';

  @override
  String get printSuccess => 'Print Success';

  @override
  String get templatePrintedSuccess => 'Template printed successfully';

  @override
  String addItem(String name) {
    return 'Add \"$name\"';
  }

  @override
  String get isThisSupplierOrClient => 'Is this a supplier or client?';

  @override
  String addTruckPlate(String plateNumber) {
    return 'Add Truck Plate \"$plateNumber\"';
  }

  @override
  String get pleaseEnterDriverName =>
      'Please enter the driver name for this truck:';

  @override
  String addDriverName(String driverName) {
    return 'Add Driver \"$driverName\"';
  }

  @override
  String get pleaseEnterTruckPlate =>
      'Please enter a truck plate for this driver:';

  @override
  String get start => 'Start';

  @override
  String get continueButton => 'Continue';

  @override
  String get completeTabTitle => 'Complete Tab';

  @override
  String markTabAsCompleted(String tabTitle) {
    return 'Mark tab \"$tabTitle\" as completed?';
  }

  @override
  String tabTitle(String tabTitle) {
    return 'Tab $tabTitle';
  }

  @override
  String get switchToTab => 'Switch to Tab';

  @override
  String get printActions => 'Print Actions';

  @override
  String printOptions(String tabTitle) {
    return 'Print Options - $tabTitle';
  }

  @override
  String areYouSureCancelTab(String tabTitle) {
    return 'Are you sure you want to cancel tab \"$tabTitle\"?';
  }

  @override
  String closeTabConfirm(String tabTitle) {
    return 'Close tab \"$tabTitle\"?';
  }

  @override
  String get signIn => 'Sign In';

  @override
  String get noDocumentToPreview => 'No document to preview';

  @override
  String get fit => 'Fit';

  @override
  String get rulers => 'Rulers';

  @override
  String get margins => 'Margins';

  @override
  String get remove => 'Remove';

  @override
  String get paperSizeA4 => 'A4';

  @override
  String get paperSizeA5 => 'A5';

  @override
  String get paperSizeLetter => 'Letter';

  @override
  String get paperSizeCustom => 'Custom';

  @override
  String get warningUnsavedChanges => 'Warning: This tab has unsaved changes.';

  @override
  String get pdfPreview => 'PDF Preview';

  @override
  String get saving => 'Saving...';

  @override
  String get perKg => '/kg';

  @override
  String get currencySymbol => '\$';

  @override
  String get switchUser => 'Switch User';

  @override
  String get noOtherUsersAvailable => 'No other users available';

  @override
  String get editClientTitle => 'Edit Client';

  @override
  String get createNewClient => 'Create New Client';

  @override
  String get nameRequired => 'Name *';

  @override
  String get clientNamePlaceholder => 'Client name';

  @override
  String get nameIsRequired => 'Name is required';

  @override
  String get phoneLabel => 'Phone';

  @override
  String get phonePlaceholder => '+1 (555) 123-4567';

  @override
  String get mobileLabel => 'Mobile';

  @override
  String get mobilePlaceholder => '+1 (555) 987-6543';

  @override
  String get cityLabel => 'City';

  @override
  String get cityPlaceholder => 'City';

  @override
  String get updateButton => 'Update';

  @override
  String get createButton => 'Create';

  @override
  String get clientUpdatedSuccessfully => 'Client updated successfully';

  @override
  String get failedToUpdateClient => 'Failed to update client';

  @override
  String get clientCreatedSuccessfully => 'Client created successfully';

  @override
  String get failedToCreateClient => 'Failed to create client';

  @override
  String get editSupplierTitle => 'Edit Supplier';

  @override
  String get createNewSupplier => 'Create New Supplier';

  @override
  String get supplierNamePlaceholder => 'Supplier name';

  @override
  String get supplierUpdatedSuccessfully => 'Supplier updated successfully';

  @override
  String get failedToUpdateSupplier => 'Failed to update supplier';

  @override
  String get supplierCreatedSuccessfully => 'Supplier created successfully';

  @override
  String get failedToCreateSupplier => 'Failed to create supplier';

  @override
  String get activeOperationsExist => 'Active operations exist';

  @override
  String get newOperation => 'New Operation';

  @override
  String switchToUser(String username) {
    return 'Switch to $username';
  }

  @override
  String get enterPasswordToContinue => 'Enter password to continue';

  @override
  String get passwordIsRequired => 'Password is required';

  @override
  String get invalidPassword => 'Invalid password';

  @override
  String loginFailedError(String error) {
    return 'Login failed: $error';
  }

  @override
  String get alreadyThere => 'the name is already there';
}
