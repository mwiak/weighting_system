import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('tr')
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Weighing System'**
  String get appTitle;

  /// Title for weighing operations page
  ///
  /// In en, this message translates to:
  /// **'Weighing Operations'**
  String get weighingOperations;

  /// Title for clients page
  ///
  /// In en, this message translates to:
  /// **'Clients'**
  String get clients;

  /// Title for suppliers page
  ///
  /// In en, this message translates to:
  /// **'Suppliers'**
  String get suppliers;

  /// Title for drivers page
  ///
  /// In en, this message translates to:
  /// **'Drivers'**
  String get drivers;

  /// Title for trucks page
  ///
  /// In en, this message translates to:
  /// **'Trucks'**
  String get trucks;

  /// Title for materials page
  ///
  /// In en, this message translates to:
  /// **'Materials'**
  String get materials;

  /// Title for reports page
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// Title for settings page
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Title for operations history page
  ///
  /// In en, this message translates to:
  /// **'Operations History'**
  String get operationsHistory;

  /// Label for current weight display
  ///
  /// In en, this message translates to:
  /// **'Current Weight'**
  String get currentWeight;

  /// Label for gross weight
  ///
  /// In en, this message translates to:
  /// **'Gross Weight'**
  String get grossWeight;

  /// Label for tare weight
  ///
  /// In en, this message translates to:
  /// **'Tare Weight'**
  String get tareWeight;

  /// Label for net weight
  ///
  /// In en, this message translates to:
  /// **'Net Weight'**
  String get netWeight;

  /// Label for order number
  ///
  /// In en, this message translates to:
  /// **'Order Number'**
  String get orderNumber;

  /// Label for truck plate number
  ///
  /// In en, this message translates to:
  /// **'Truck Plate'**
  String get truckPlate;

  /// Label for driver name
  ///
  /// In en, this message translates to:
  /// **'Driver Name'**
  String get driverName;

  /// Label for operation type
  ///
  /// In en, this message translates to:
  /// **'Operation Type'**
  String get operationType;

  /// Loading operation type
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loading;

  /// Unloading operation type
  ///
  /// In en, this message translates to:
  /// **'Unloading'**
  String get unloading;

  /// Label for client
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get client;

  /// Label for supplier
  ///
  /// In en, this message translates to:
  /// **'Supplier'**
  String get supplier;

  /// Label for material
  ///
  /// In en, this message translates to:
  /// **'Material'**
  String get material;

  /// Label for price
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// Label for total amount
  ///
  /// In en, this message translates to:
  /// **'Total Amount'**
  String get totalAmount;

  /// Save button text
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Cancel button text
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Edit button text
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// Delete button text
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Add button text
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// Label for name field
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// Label for email field
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// Label for phone field
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// Label for mobile field
  ///
  /// In en, this message translates to:
  /// **'Mobile'**
  String get mobile;

  /// Label for city field
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// Label for license number
  ///
  /// In en, this message translates to:
  /// **'License Number'**
  String get licenseNumber;

  /// Label for plate number
  ///
  /// In en, this message translates to:
  /// **'Plate Number'**
  String get plateNumber;

  /// Label for truck model
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get model;

  /// Label for truck capacity
  ///
  /// In en, this message translates to:
  /// **'Capacity'**
  String get capacity;

  /// Label for active status
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// Label for status
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// Label for notes field
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// Label for weigh in time
  ///
  /// In en, this message translates to:
  /// **'Weigh In Time'**
  String get weighInTime;

  /// Label for weigh out time
  ///
  /// In en, this message translates to:
  /// **'Weigh Out Time'**
  String get weighOutTime;

  /// Label for creation date
  ///
  /// In en, this message translates to:
  /// **'Create Date'**
  String get createDate;

  /// Title for Odoo settings section
  ///
  /// In en, this message translates to:
  /// **'Odoo Settings'**
  String get odooSettings;

  /// Label for Odoo server URL
  ///
  /// In en, this message translates to:
  /// **'Odoo URL'**
  String get odooUrl;

  /// Label for Odoo database name
  ///
  /// In en, this message translates to:
  /// **'Database Name'**
  String get odooDatabase;

  /// Label for Odoo username
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get odooUsername;

  /// Label for Odoo password
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get odooPassword;

  /// Test connection button text
  ///
  /// In en, this message translates to:
  /// **'Test Connection'**
  String get testConnection;

  /// Success message for connection test
  ///
  /// In en, this message translates to:
  /// **'Connection successful!'**
  String get connectionSuccessful;

  /// Error message for failed connection
  ///
  /// In en, this message translates to:
  /// **'Connection failed!'**
  String get connectionFailed;

  /// Kilogram unit abbreviation
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get kg;

  /// Tons unit abbreviation
  ///
  /// In en, this message translates to:
  /// **'tons'**
  String get tons;

  /// Title for drivers and trucks screen
  ///
  /// In en, this message translates to:
  /// **'Drivers & Trucks'**
  String get driversAndTrucks;

  /// Add driver button text
  ///
  /// In en, this message translates to:
  /// **'Add Driver'**
  String get addDriver;

  /// Add truck button text
  ///
  /// In en, this message translates to:
  /// **'Add Truck'**
  String get addTruck;

  /// Checkbox to show price on print
  ///
  /// In en, this message translates to:
  /// **'Show Price on Print'**
  String get showPriceOnPrint;

  /// New tab button text
  ///
  /// In en, this message translates to:
  /// **'New Tab'**
  String get newTab;

  /// Close tab button text
  ///
  /// In en, this message translates to:
  /// **'Close Tab'**
  String get closeTab;

  /// Label for unit price
  ///
  /// In en, this message translates to:
  /// **'Unit Price'**
  String get unitPrice;

  /// Label for price per kilogram
  ///
  /// In en, this message translates to:
  /// **'Price per kg'**
  String get pricePerKg;

  /// Message when no items are found
  ///
  /// In en, this message translates to:
  /// **'No items found'**
  String get noItemsFound;

  /// Loading message
  ///
  /// In en, this message translates to:
  /// **'Loading data...'**
  String get loading_data;

  /// Confirm button text
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// Close button text
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Search placeholder text
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// Select client dropdown placeholder
  ///
  /// In en, this message translates to:
  /// **'Select Client'**
  String get selectClient;

  /// Select supplier dropdown placeholder
  ///
  /// In en, this message translates to:
  /// **'Select Supplier'**
  String get selectSupplier;

  /// Select material dropdown placeholder
  ///
  /// In en, this message translates to:
  /// **'Select Material'**
  String get selectMaterial;

  /// Add client button text
  ///
  /// In en, this message translates to:
  /// **'Add Client'**
  String get addClient;

  /// Add supplier button text
  ///
  /// In en, this message translates to:
  /// **'Add Supplier'**
  String get addSupplier;

  /// Add material button text
  ///
  /// In en, this message translates to:
  /// **'Add Material'**
  String get addMaterial;

  /// Edit client button text
  ///
  /// In en, this message translates to:
  /// **'Edit Client'**
  String get editClient;

  /// Edit supplier button text
  ///
  /// In en, this message translates to:
  /// **'Edit Supplier'**
  String get editSupplier;

  /// Edit material button text
  ///
  /// In en, this message translates to:
  /// **'Edit Material'**
  String get editMaterial;

  /// Required field indicator
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// Refresh button text
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// Search drivers placeholder
  ///
  /// In en, this message translates to:
  /// **'Search drivers...'**
  String get searchDrivers;

  /// Search trucks placeholder
  ///
  /// In en, this message translates to:
  /// **'Search trucks...'**
  String get searchTrucks;

  /// Error label
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No drivers found message
  ///
  /// In en, this message translates to:
  /// **'No drivers found matching'**
  String get noDriversFound;

  /// No drivers found with add suggestion
  ///
  /// In en, this message translates to:
  /// **'No drivers found. Add your first driver to get started.'**
  String get noDriversFoundAdd;

  /// No trucks found message
  ///
  /// In en, this message translates to:
  /// **'No trucks found matching'**
  String get noTrucksFound;

  /// No trucks found with add suggestion
  ///
  /// In en, this message translates to:
  /// **'No trucks found. Add your first truck to get started.'**
  String get noTrucksFoundAdd;

  /// License label
  ///
  /// In en, this message translates to:
  /// **'License'**
  String get license;

  /// Inactive status label
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// Driver name field placeholder
  ///
  /// In en, this message translates to:
  /// **'Enter driver name...'**
  String get enterDriverName;

  /// License number placeholder
  ///
  /// In en, this message translates to:
  /// **'Enter license number'**
  String get enterLicenseNumber;

  /// Phone number placeholder
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneNumber;

  /// Mobile number placeholder
  ///
  /// In en, this message translates to:
  /// **'Mobile number'**
  String get mobileNumber;

  /// City placeholder
  ///
  /// In en, this message translates to:
  /// **'Enter city'**
  String get enterCity;

  /// Plate number placeholder
  ///
  /// In en, this message translates to:
  /// **'Enter plate number'**
  String get enterPlateNumber;

  /// Truck model placeholder
  ///
  /// In en, this message translates to:
  /// **'Enter truck model'**
  String get enterTruckModel;

  /// Capacity in kg label
  ///
  /// In en, this message translates to:
  /// **'Capacity (kg)'**
  String get capacityKg;

  /// Capacity placeholder
  ///
  /// In en, this message translates to:
  /// **'Enter capacity in kg'**
  String get enterCapacityKg;

  /// Assigned driver label
  ///
  /// In en, this message translates to:
  /// **'Assigned Driver'**
  String get assignedDriver;

  /// No driver assigned text
  ///
  /// In en, this message translates to:
  /// **'No driver assigned'**
  String get noDriverAssigned;

  /// Driver not assigned text
  ///
  /// In en, this message translates to:
  /// **'Driver: Not assigned'**
  String get driverNotAssigned;

  /// Delete driver dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete Driver'**
  String get deleteDriver;

  /// Delete driver confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete'**
  String get deleteDriverConfirm;

  /// Delete truck dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete Truck'**
  String get deleteTruck;

  /// Delete truck confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete truck'**
  String get deleteTruckConfirm;

  /// Reset scale button text
  ///
  /// In en, this message translates to:
  /// **'Reset Scale'**
  String get resetScale;

  /// Maximum tabs dialog title
  ///
  /// In en, this message translates to:
  /// **'Maximum Tabs Reached'**
  String get maximumTabsReached;

  /// Maximum tabs dialog message
  ///
  /// In en, this message translates to:
  /// **'You can have a maximum of {maxTabs} operations open at once. Please close some tabs before creating new ones.'**
  String maximumTabsMessage(int maxTabs, Object count);

  /// OK button text
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// Tab unsaved changes message
  ///
  /// In en, this message translates to:
  /// **'This tab has unsaved changes. Closing it will create a new empty tab. Continue?'**
  String get tabUnsavedChanges;

  /// Unsaved changes dialog title
  ///
  /// In en, this message translates to:
  /// **'Unsaved Changes'**
  String get unsavedChanges;

  /// Unsaved changes dialog message
  ///
  /// In en, this message translates to:
  /// **'This operation has unsaved changes. Are you sure you want to close it?'**
  String get unsavedChangesMessage;

  /// Close anyway button text
  ///
  /// In en, this message translates to:
  /// **'Close Anyway'**
  String get closeAnyway;

  /// Print button text
  ///
  /// In en, this message translates to:
  /// **'Print'**
  String get print;

  /// Printing message
  ///
  /// In en, this message translates to:
  /// **'Printing operation'**
  String get printing;

  /// Cancel operation dialog title
  ///
  /// In en, this message translates to:
  /// **'Cancel Operation'**
  String get cancelOperation;

  /// Cancel operation confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this operation? All data will be lost.'**
  String get cancelOperationConfirm;

  /// No button text
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// Yes cancel button text
  ///
  /// In en, this message translates to:
  /// **'Yes, Cancel'**
  String get yesCancel;

  /// Reports and analytics title
  ///
  /// In en, this message translates to:
  /// **'Reports & Analytics'**
  String get reportsAndAnalytics;

  /// Export PDF button text
  ///
  /// In en, this message translates to:
  /// **'Export PDF'**
  String get exportPdf;

  /// Export CSV button text
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get exportCsv;

  /// Report types section title
  ///
  /// In en, this message translates to:
  /// **'Report Types'**
  String get reportTypes;

  /// Dashboard report type
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// Orders report type
  ///
  /// In en, this message translates to:
  /// **'Orders Report'**
  String get ordersReport;

  /// Revenue report type
  ///
  /// In en, this message translates to:
  /// **'Revenue Report'**
  String get revenueReport;

  /// Client report type
  ///
  /// In en, this message translates to:
  /// **'Client Report'**
  String get clientReport;

  /// Material report type
  ///
  /// In en, this message translates to:
  /// **'Material Report'**
  String get materialReport;

  /// Filters section title
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// Start date label
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get startDate;

  /// End date label
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get endDate;

  /// Quick range dropdown title
  ///
  /// In en, this message translates to:
  /// **'Quick Range'**
  String get quickRange;

  /// Last 7 days quick filter
  ///
  /// In en, this message translates to:
  /// **'Last 7 Days'**
  String get last7Days;

  /// Last 30 days quick filter
  ///
  /// In en, this message translates to:
  /// **'Last 30 Days'**
  String get last30Days;

  /// Last 90 days option
  ///
  /// In en, this message translates to:
  /// **'Last 90 Days'**
  String get last90Days;

  /// This year option
  ///
  /// In en, this message translates to:
  /// **'This Year'**
  String get thisYear;

  /// Loading with dots message
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loadingDots;

  /// Apply filters button text
  ///
  /// In en, this message translates to:
  /// **'Apply Filters'**
  String get applyFilters;

  /// Clear button text
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// Client filter label
  ///
  /// In en, this message translates to:
  /// **'Client Filter'**
  String get clientFilter;

  /// All clients option
  ///
  /// In en, this message translates to:
  /// **'All Clients'**
  String get allClients;

  /// Status filter label
  ///
  /// In en, this message translates to:
  /// **'Status Filter'**
  String get statusFilter;

  /// All statuses filter option
  ///
  /// In en, this message translates to:
  /// **'All Statuses'**
  String get allStatuses;

  /// Completed status
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// Cancelled status
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// Group by label
  ///
  /// In en, this message translates to:
  /// **'Group By'**
  String get groupBy;

  /// Daily grouping option
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get daily;

  /// Weekly grouping option
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

  /// Monthly grouping option
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// Generating report message
  ///
  /// In en, this message translates to:
  /// **'Generating report...'**
  String get generatingReport;

  /// Unknown error message
  ///
  /// In en, this message translates to:
  /// **'Unknown Error'**
  String get unknownError;

  /// Select report type message
  ///
  /// In en, this message translates to:
  /// **'Select a report type to view data'**
  String get selectReportType;

  /// No dashboard data message
  ///
  /// In en, this message translates to:
  /// **'No dashboard data available'**
  String get noDashboardData;

  /// Total orders label
  ///
  /// In en, this message translates to:
  /// **'Total Orders'**
  String get totalOrders;

  /// Total weight label
  ///
  /// In en, this message translates to:
  /// **'Total Weight'**
  String get totalWeight;

  /// Total revenue label
  ///
  /// In en, this message translates to:
  /// **'Total Revenue'**
  String get totalRevenue;

  /// Active orders label
  ///
  /// In en, this message translates to:
  /// **'Active Orders'**
  String get activeOrders;

  /// Orders by status chart title
  ///
  /// In en, this message translates to:
  /// **'Orders by Status'**
  String get ordersByStatus;

  /// Top clients chart title
  ///
  /// In en, this message translates to:
  /// **'Top Clients by Revenue'**
  String get topClientsByRevenue;

  /// Unknown text
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No report data message
  ///
  /// In en, this message translates to:
  /// **'No report data available'**
  String get noReportData;

  /// Generated label
  ///
  /// In en, this message translates to:
  /// **'Generated'**
  String get generated;

  /// Records text
  ///
  /// In en, this message translates to:
  /// **'records'**
  String get records;

  /// Showing first records message
  ///
  /// In en, this message translates to:
  /// **'Showing first {count} of {total} records. Export to view all data.'**
  String showingFirst(int count, int total);

  /// Export successful message
  ///
  /// In en, this message translates to:
  /// **'Export Successful'**
  String get exportSuccessful;

  /// PDF saved message
  ///
  /// In en, this message translates to:
  /// **'PDF saved to: {path}'**
  String pdfSavedTo(String path);

  /// CSV saved message
  ///
  /// In en, this message translates to:
  /// **'CSV saved to: {path}'**
  String csvSavedTo(String path);

  /// Print templates section title
  ///
  /// In en, this message translates to:
  /// **'Print Templates'**
  String get printTemplates;

  /// No active tabs message
  ///
  /// In en, this message translates to:
  /// **'No Active Tabs'**
  String get noActiveTabs;

  /// Instructions to create new tab
  ///
  /// In en, this message translates to:
  /// **'Click \"New Tab\" to start a new weighing operation'**
  String get clickNewTabToStart;

  /// Reconnect to scale button text
  ///
  /// In en, this message translates to:
  /// **'Reconnect to Scale'**
  String get reconnectToScale;

  /// Select printer dropdown placeholder
  ///
  /// In en, this message translates to:
  /// **'Select Printer'**
  String get selectPrinter;

  /// Save as PDF button text
  ///
  /// In en, this message translates to:
  /// **'Save as PDF'**
  String get saveAsPdf;

  /// Silent print checkbox label
  ///
  /// In en, this message translates to:
  /// **'Silent Print'**
  String get silentPrint;

  /// Export with template button text
  ///
  /// In en, this message translates to:
  /// **'Export with Template'**
  String get exportWithTemplate;

  /// Select template dialog title
  ///
  /// In en, this message translates to:
  /// **'Select Template'**
  String get selectTemplate;

  /// No templates available dialog title
  ///
  /// In en, this message translates to:
  /// **'No Templates Available'**
  String get noTemplatesAvailable;

  /// No templates available dialog message
  ///
  /// In en, this message translates to:
  /// **'No templates are available. Would you like to create a default template?'**
  String get noTemplatesMessage;

  /// Create default template button text
  ///
  /// In en, this message translates to:
  /// **'Create Default'**
  String get createDefault;

  /// Export options dialog title
  ///
  /// In en, this message translates to:
  /// **'Export Options'**
  String get exportOptions;

  /// Print with template option title
  ///
  /// In en, this message translates to:
  /// **'Print with Template'**
  String get printWithTemplate;

  /// Print with template option subtitle
  ///
  /// In en, this message translates to:
  /// **'Print directly using the template'**
  String get printDirectlyUsingTemplate;

  /// Save as PDF option subtitle
  ///
  /// In en, this message translates to:
  /// **'Save template export as PDF file'**
  String get saveTemplateExportAsPdf;

  /// Print weighing ticket button text
  ///
  /// In en, this message translates to:
  /// **'Print Weighing Ticket'**
  String get printWeighingTicket;

  /// Print receipt button text
  ///
  /// In en, this message translates to:
  /// **'Print Receipt'**
  String get printReceipt;

  /// Device connected status
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// Device disconnected status
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get disconnected;

  /// Replug device message
  ///
  /// In en, this message translates to:
  /// **'Replug Device'**
  String get replugDevice;

  /// Device reconnecting status
  ///
  /// In en, this message translates to:
  /// **'Reconnecting'**
  String get reconnecting;

  /// No devices available message
  ///
  /// In en, this message translates to:
  /// **'No Devices Available'**
  String get noDevicesAvailable;

  /// Device scanning status
  ///
  /// In en, this message translates to:
  /// **'Scanning'**
  String get scanning;

  /// Device connecting status
  ///
  /// In en, this message translates to:
  /// **'Connecting'**
  String get connecting;

  /// Title for loading operations history page
  ///
  /// In en, this message translates to:
  /// **'Loading Operations History'**
  String get loadingOperationsHistory;

  /// Material filter placeholder
  ///
  /// In en, this message translates to:
  /// **'Filter by material...'**
  String get filterByMaterial;

  /// Driver filter placeholder
  ///
  /// In en, this message translates to:
  /// **'Filter by driver...'**
  String get filterByDriver;

  /// Truck plate filter placeholder
  ///
  /// In en, this message translates to:
  /// **'Filter by plate...'**
  String get filterByPlate;

  /// Supplier filter placeholder
  ///
  /// In en, this message translates to:
  /// **'Filter by supplier...'**
  String get filterBySupplier;

  /// Client filter placeholder
  ///
  /// In en, this message translates to:
  /// **'Filter by client...'**
  String get filterByClient;

  /// Date and time column header
  ///
  /// In en, this message translates to:
  /// **'Date/Time'**
  String get dateTime;

  /// Net weight field label with unit
  ///
  /// In en, this message translates to:
  /// **'Net Weight (kg)'**
  String get netWeightKg;

  /// Operations found count message
  ///
  /// In en, this message translates to:
  /// **'Operations History ({count} found)'**
  String operationsFound(int count);

  /// Loading operations message
  ///
  /// In en, this message translates to:
  /// **'Loading operations...'**
  String get loadingOperations;

  /// No operations found message
  ///
  /// In en, this message translates to:
  /// **'No operations found for the selected criteria.'**
  String get noOperationsFound;

  /// Completed status option
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// Incomplete status option
  ///
  /// In en, this message translates to:
  /// **'Incomplete'**
  String get statusIncomplete;

  /// In progress status option
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get statusInProgress;

  /// Cancelled status option
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// Empty status option
  ///
  /// In en, this message translates to:
  /// **'Empty'**
  String get statusEmpty;

  /// Clear filters button
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearFilters;

  /// Client management page title
  ///
  /// In en, this message translates to:
  /// **'Client Management'**
  String get clientManagement;

  /// Supplier management page title
  ///
  /// In en, this message translates to:
  /// **'Supplier Management'**
  String get supplierManagement;

  /// New client button text
  ///
  /// In en, this message translates to:
  /// **'New Client'**
  String get newClient;

  /// New supplier button text
  ///
  /// In en, this message translates to:
  /// **'New Supplier'**
  String get newSupplier;

  /// Import button text
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get import;

  /// Export button text
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export;

  /// Total clients statistics label
  ///
  /// In en, this message translates to:
  /// **'Total Clients'**
  String get totalClients;

  /// Active clients statistics label
  ///
  /// In en, this message translates to:
  /// **'Active Clients'**
  String get activeClients;

  /// Total suppliers statistics label
  ///
  /// In en, this message translates to:
  /// **'Total Suppliers'**
  String get totalSuppliers;

  /// Active suppliers statistics label
  ///
  /// In en, this message translates to:
  /// **'Active Suppliers'**
  String get activeSuppliers;

  /// Companies statistics label
  ///
  /// In en, this message translates to:
  /// **'Companies'**
  String get companies;

  /// Individuals statistics label
  ///
  /// In en, this message translates to:
  /// **'Individuals'**
  String get individuals;

  /// Search clients placeholder
  ///
  /// In en, this message translates to:
  /// **'Search clients...'**
  String get searchClients;

  /// Search suppliers placeholder
  ///
  /// In en, this message translates to:
  /// **'Search suppliers...'**
  String get searchSuppliers;

  /// Active only filter checkbox
  ///
  /// In en, this message translates to:
  /// **'Active only'**
  String get activeOnly;

  /// Contact column header
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contact;

  /// Address column header
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// Type column header
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// Actions column header
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actions;

  /// Company type label
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get company;

  /// Individual type label
  ///
  /// In en, this message translates to:
  /// **'Individual'**
  String get individual;

  /// No contact info message
  ///
  /// In en, this message translates to:
  /// **'No contact info'**
  String get noContactInfo;

  /// No clients found message
  ///
  /// In en, this message translates to:
  /// **'No clients found'**
  String get noClientsFound;

  /// Create first client instruction
  ///
  /// In en, this message translates to:
  /// **'Create your first client to get started'**
  String get createFirstClient;

  /// Create client button text
  ///
  /// In en, this message translates to:
  /// **'Create Client'**
  String get createClient;

  /// No suppliers found message
  ///
  /// In en, this message translates to:
  /// **'No suppliers found'**
  String get noSuppliersFound;

  /// Create first supplier instruction
  ///
  /// In en, this message translates to:
  /// **'Create your first supplier to get started'**
  String get createFirstSupplier;

  /// Create supplier button text
  ///
  /// In en, this message translates to:
  /// **'Create Supplier'**
  String get createSupplier;

  /// Delete client dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete Client'**
  String get deleteClient;

  /// Delete client confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"?'**
  String deleteClientConfirm(String name);

  /// Delete supplier dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete Supplier'**
  String get deleteSupplier;

  /// Delete supplier confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"?'**
  String deleteSupplierConfirm(String name);

  /// Import coming soon message
  ///
  /// In en, this message translates to:
  /// **'Import functionality coming soon'**
  String get importFunctionalityComingSoon;

  /// Exported clients success message
  ///
  /// In en, this message translates to:
  /// **'Exported {count} clients'**
  String exportedClients(int count);

  /// Exported suppliers success message
  ///
  /// In en, this message translates to:
  /// **'Exported {count} suppliers'**
  String exportedSuppliers(int count);

  /// VAT label
  ///
  /// In en, this message translates to:
  /// **'VAT'**
  String get vat;

  /// Weight information section
  ///
  /// In en, this message translates to:
  /// **'Weight Information'**
  String get weightInformation;

  /// Empty weight field label
  ///
  /// In en, this message translates to:
  /// **'Empty Weight'**
  String get emptyWeight;

  /// Empty weight field label with unit
  ///
  /// In en, this message translates to:
  /// **'Empty Weight (kg)'**
  String get emptyWeightKg;

  /// Gross weight field label with unit
  ///
  /// In en, this message translates to:
  /// **'Gross Weight (kg)'**
  String get grossWeightKg;

  /// Business information section
  ///
  /// In en, this message translates to:
  /// **'Business Information'**
  String get businessInformation;

  /// Truck plate field label with required indicator
  ///
  /// In en, this message translates to:
  /// **'Truck Plate *'**
  String get truckPlateRequired;

  /// Truck plate field placeholder
  ///
  /// In en, this message translates to:
  /// **'Enter truck plate...'**
  String get enterTruckPlate;

  /// Customer field label for loading operations
  ///
  /// In en, this message translates to:
  /// **'Customer (Loading Operation)'**
  String get customerLoadingOperation;

  /// Customer field placeholder
  ///
  /// In en, this message translates to:
  /// **'Select Customer...'**
  String get selectCustomer;

  /// Supplier field label for unloading operations
  ///
  /// In en, this message translates to:
  /// **'Supplier (Unloading Operation)'**
  String get supplierUnloadingOperation;

  /// Material field label with required indicator
  ///
  /// In en, this message translates to:
  /// **'Material *'**
  String get materialRequired;

  /// Payment status label
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paid;

  /// Complete button text
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get complete;

  /// Incomplete status text
  ///
  /// In en, this message translates to:
  /// **'Incomplete'**
  String get incomplete;

  /// Save PDF button text
  ///
  /// In en, this message translates to:
  /// **'Save PDF'**
  String get savePDF;

  /// In progress status text
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get inProgress;

  /// Empty status text
  ///
  /// In en, this message translates to:
  /// **'Empty'**
  String get empty;

  /// Status label with colon
  ///
  /// In en, this message translates to:
  /// **'Status:'**
  String get statusLabel;

  /// Tab not found error message
  ///
  /// In en, this message translates to:
  /// **'Tab not found'**
  String get tabNotFound;

  /// Template not found error message
  ///
  /// In en, this message translates to:
  /// **'Could not find a template'**
  String get couldNotFindTemplate;

  /// Scale connection warning message
  ///
  /// In en, this message translates to:
  /// **'Scale must be connected before capturing weight'**
  String get scaleMustBeConnected;

  /// Cannot capture weight warning message
  ///
  /// In en, this message translates to:
  /// **'Cannot capture weight while editing field'**
  String get cannotCaptureWhileEditing;

  /// Printing operation message
  ///
  /// In en, this message translates to:
  /// **'Printing {operation}...'**
  String printingOperation(String operation);

  /// Tab cancelled info message
  ///
  /// In en, this message translates to:
  /// **'Tab cancelled'**
  String get tabCancelled;

  /// Tab completion success message
  ///
  /// In en, this message translates to:
  /// **'Tab completed and moved to history'**
  String get tabCompletedAndMoved;

  /// Tab completion error message
  ///
  /// In en, this message translates to:
  /// **'Unable to complete tab. Please fill all required fields.'**
  String get unableToCompleteTab;

  /// Order details dialog title
  ///
  /// In en, this message translates to:
  /// **'Order Details'**
  String get orderDetails;

  /// Basic information section title
  ///
  /// In en, this message translates to:
  /// **'Basic Information'**
  String get basicInformation;

  /// Vehicle information section
  ///
  /// In en, this message translates to:
  /// **'Vehicle Information'**
  String get vehicleInformation;

  /// Business partners section title
  ///
  /// In en, this message translates to:
  /// **'Business Partners'**
  String get businessPartners;

  /// Weight measurements section title
  ///
  /// In en, this message translates to:
  /// **'Weight Measurements'**
  String get weightMeasurements;

  /// Financial information section title
  ///
  /// In en, this message translates to:
  /// **'Financial Information'**
  String get financialInformation;

  /// Print success message
  ///
  /// In en, this message translates to:
  /// **'Print Successful'**
  String get printSuccessful;

  /// PDF save success message
  ///
  /// In en, this message translates to:
  /// **'PDF Saved Successfully'**
  String get pdfSaved;

  /// Login screen title
  ///
  /// In en, this message translates to:
  /// **'Choose User'**
  String get chooseUser;

  /// Login failed dialog title
  ///
  /// In en, this message translates to:
  /// **'Login Failed'**
  String get loginFailed;

  /// Selected user indicator
  ///
  /// In en, this message translates to:
  /// **'Logging in as: {username}'**
  String loggingInAs(String username);

  /// Password field label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Password field placeholder
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterYourPassword;

  /// Continue button text
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continue_;

  /// Back button text
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// Password validation error
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get pleaseEnterPassword;

  /// Incorrect password error
  ///
  /// In en, this message translates to:
  /// **'Incorrect password. Please try again.'**
  String get incorrectPassword;

  /// User not found error
  ///
  /// In en, this message translates to:
  /// **'User not found.'**
  String get userNotFound;

  /// General settings menu item
  ///
  /// In en, this message translates to:
  /// **'General Settings'**
  String get generalSettings;

  /// Users menu item
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get users;

  /// Scale connection section title
  ///
  /// In en, this message translates to:
  /// **'Scale Connection'**
  String get scaleConnection;

  /// Advanced settings button
  ///
  /// In en, this message translates to:
  /// **'Advanced Settings'**
  String get advancedSettings;

  /// Connected status message
  ///
  /// In en, this message translates to:
  /// **'Connected to {port}'**
  String connectedToPort(String port);

  /// Scanning status message
  ///
  /// In en, this message translates to:
  /// **'Scanning for devices...'**
  String get scanningForDevices;

  /// Not connected status
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get notConnected;

  /// Reconnect button
  ///
  /// In en, this message translates to:
  /// **'Reconnect'**
  String get reconnect;

  /// Current weight label prefix
  ///
  /// In en, this message translates to:
  /// **'Current Weight: '**
  String get currentWeightLabel;

  /// Port label prefix
  ///
  /// In en, this message translates to:
  /// **'Port: '**
  String get port;

  /// Baud rate label prefix
  ///
  /// In en, this message translates to:
  /// **'Baud: '**
  String get baud;

  /// User management page title
  ///
  /// In en, this message translates to:
  /// **'User Management'**
  String get userManagement;

  /// Add user button
  ///
  /// In en, this message translates to:
  /// **'Add User'**
  String get addUser;

  /// No users message
  ///
  /// In en, this message translates to:
  /// **'No users found'**
  String get noUsersFound;

  /// Username label
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// Admin user type
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get admin;

  /// Normal user type
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get user;

  /// Delete confirmation dialog title
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete'**
  String get confirmDelete;

  /// Delete user confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete user \"{username}\"?\\n\\nThis action cannot be undone.'**
  String deleteUserConfirm(String username);

  /// Material management page title
  ///
  /// In en, this message translates to:
  /// **'Material Management'**
  String get materialManagement;

  /// New material button
  ///
  /// In en, this message translates to:
  /// **'New Material'**
  String get newMaterial;

  /// Total materials statistics
  ///
  /// In en, this message translates to:
  /// **'Total Materials'**
  String get totalMaterials;

  /// Materials with price statistics
  ///
  /// In en, this message translates to:
  /// **'With Price'**
  String get withPrice;

  /// Pricing section title
  ///
  /// In en, this message translates to:
  /// **'Pricing Overview'**
  String get pricingOverview;

  /// Average price label
  ///
  /// In en, this message translates to:
  /// **'Average Price'**
  String get averagePrice;

  /// Most expensive label
  ///
  /// In en, this message translates to:
  /// **'Most Expensive'**
  String get mostExpensive;

  /// Search materials placeholder
  ///
  /// In en, this message translates to:
  /// **'Search materials...'**
  String get searchMaterials;

  /// Clear filters button
  ///
  /// In en, this message translates to:
  /// **'Clear Filters'**
  String get clearFiltersButton;

  /// No materials message
  ///
  /// In en, this message translates to:
  /// **'No materials found'**
  String get noMaterialsFound;

  /// Create first material instruction
  ///
  /// In en, this message translates to:
  /// **'Create your first material to get started'**
  String get createFirstMaterial;

  /// Create material button
  ///
  /// In en, this message translates to:
  /// **'Create Material'**
  String get createMaterial;

  /// Material code label
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get code;

  /// No price set message
  ///
  /// In en, this message translates to:
  /// **'No price'**
  String get noPrice;

  /// Delete material dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete Material'**
  String get deleteMaterial;

  /// Delete material confirmation
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"?'**
  String deleteMaterialConfirm(String name);

  /// Export success message
  ///
  /// In en, this message translates to:
  /// **'Exported {count} materials'**
  String exportedMaterials(int count);

  /// Drivers and plate numbers page title
  ///
  /// In en, this message translates to:
  /// **'Drivers & Plate Numbers'**
  String get driversAndPlateNumbers;

  /// Add plate number button
  ///
  /// In en, this message translates to:
  /// **'Add Plate Number'**
  String get addPlateNumber;

  /// Edit driver dialog title
  ///
  /// In en, this message translates to:
  /// **'Edit Driver'**
  String get editDriver;

  /// Plate numbers field label
  ///
  /// In en, this message translates to:
  /// **'Plate Numbers'**
  String get plateNumbers;

  /// Plate number field hint
  ///
  /// In en, this message translates to:
  /// **'Enter plate number'**
  String get enterPlateNumberHint;

  /// Plates label prefix
  ///
  /// In en, this message translates to:
  /// **'Plates: '**
  String get plates;

  /// Phone label prefix
  ///
  /// In en, this message translates to:
  /// **'Phone: '**
  String get phonePrefix;

  /// City label prefix
  ///
  /// In en, this message translates to:
  /// **'City: '**
  String get cityPrefix;

  /// No tab selected message
  ///
  /// In en, this message translates to:
  /// **'No tab selected'**
  String get noTabSelected;

  /// Search expander label
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchLabel;

  /// Actions table column
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actionsColumn;

  /// Username validation error
  ///
  /// In en, this message translates to:
  /// **'Username is required'**
  String get usernameRequired;

  /// Password validation error
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// Password mismatch error
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// Validation error dialog title
  ///
  /// In en, this message translates to:
  /// **'Validation Error'**
  String get validationError;

  /// Edit user dialog title
  ///
  /// In en, this message translates to:
  /// **'Edit User'**
  String get editUser;

  /// Add user dialog title
  ///
  /// In en, this message translates to:
  /// **'Add New User'**
  String get addNewUser;

  /// Username field placeholder
  ///
  /// In en, this message translates to:
  /// **'Enter username'**
  String get enterUsername;

  /// User type label
  ///
  /// In en, this message translates to:
  /// **'User Type'**
  String get userType;

  /// Normal user option
  ///
  /// In en, this message translates to:
  /// **'Normal User'**
  String get normalUser;

  /// Password field placeholder
  ///
  /// In en, this message translates to:
  /// **'Enter password'**
  String get enterPassword;

  /// Confirm password label
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// Confirm password placeholder
  ///
  /// In en, this message translates to:
  /// **'Re-enter password'**
  String get reEnterPassword;

  /// Password change hint
  ///
  /// In en, this message translates to:
  /// **'To change password, use the \"Change Password\" button'**
  String get passwordChangeHint;

  /// Update button
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// Create button
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// Change password dialog title
  ///
  /// In en, this message translates to:
  /// **'Change Password for {username}'**
  String changePasswordFor(String username);

  /// New password label
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// New password placeholder
  ///
  /// In en, this message translates to:
  /// **'Enter new password'**
  String get enterNewPassword;

  /// Confirm new password label
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPassword;

  /// Confirm new password placeholder
  ///
  /// In en, this message translates to:
  /// **'Re-enter new password'**
  String get reEnterNewPassword;

  /// Change password button
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// Tab details card header
  ///
  /// In en, this message translates to:
  /// **'Tab Details'**
  String get tabDetails;

  /// No tab selected title
  ///
  /// In en, this message translates to:
  /// **'No Tab Selected'**
  String get noTabSelectedMessage;

  /// Select tab instruction
  ///
  /// In en, this message translates to:
  /// **'Select a tab to view details'**
  String get selectTabToView;

  /// Unsaved status badge
  ///
  /// In en, this message translates to:
  /// **'UNSAVED'**
  String get unsaved;

  /// Truck plate label
  ///
  /// In en, this message translates to:
  /// **'Truck Plate'**
  String get truckPlateLabel;

  /// Not specified placeholder
  ///
  /// In en, this message translates to:
  /// **'Not specified'**
  String get notSpecified;

  /// Not recorded placeholder
  ///
  /// In en, this message translates to:
  /// **'Not recorded'**
  String get notRecorded;

  /// Not calculated placeholder
  ///
  /// In en, this message translates to:
  /// **'Not calculated'**
  String get notCalculated;

  /// Client/Supplier label
  ///
  /// In en, this message translates to:
  /// **'Client/Supplier'**
  String get clientSupplier;

  /// Payment status label
  ///
  /// In en, this message translates to:
  /// **'Payment Status'**
  String get paymentStatus;

  /// Unpaid status
  ///
  /// In en, this message translates to:
  /// **'Unpaid'**
  String get unpaid;

  /// Yes answer
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// Timing information section
  ///
  /// In en, this message translates to:
  /// **'Timing Information'**
  String get timingInformation;

  /// Created at label
  ///
  /// In en, this message translates to:
  /// **'Created At'**
  String get createdAt;

  /// Last updated label
  ///
  /// In en, this message translates to:
  /// **'Last Updated'**
  String get lastUpdated;

  /// Start weighing button
  ///
  /// In en, this message translates to:
  /// **'Start Weighing'**
  String get startWeighing;

  /// Continue weighing button
  ///
  /// In en, this message translates to:
  /// **'Continue Weighing'**
  String get continueWeighing;

  /// Complete tab button
  ///
  /// In en, this message translates to:
  /// **'Complete Tab'**
  String get completeTab;

  /// Reset button
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// Complete tab confirmation
  ///
  /// In en, this message translates to:
  /// **'Mark tab \"{tabTitle}\" as completed?'**
  String completeTabConfirm(String tabTitle);

  /// Tab completed success message
  ///
  /// In en, this message translates to:
  /// **'Tab completed successfully'**
  String get tabCompletedSuccess;

  /// Edit coming soon message
  ///
  /// In en, this message translates to:
  /// **'Tab editing functionality coming soon'**
  String get tabEditingComingSoon;

  /// Print coming soon message
  ///
  /// In en, this message translates to:
  /// **'Print functionality coming soon'**
  String get printFunctionalityComingSoon;

  /// Reset tab dialog title
  ///
  /// In en, this message translates to:
  /// **'Reset Tab'**
  String get resetTab;

  /// Reset tab confirmation
  ///
  /// In en, this message translates to:
  /// **'Reset all data in tab \"{tabTitle}\"? This action cannot be undone.'**
  String resetTabConfirm(String tabTitle);

  /// Tab reset success message
  ///
  /// In en, this message translates to:
  /// **'Tab reset successfully'**
  String get tabResetSuccess;

  /// Cancel tab dialog title
  ///
  /// In en, this message translates to:
  /// **'Cancel Tab'**
  String get cancelTab;

  /// Cancel tab confirmation
  ///
  /// In en, this message translates to:
  /// **'Cancel tab \"{tabTitle}\"?'**
  String cancelTabConfirm(String tabTitle);

  /// Yes cancel tab button
  ///
  /// In en, this message translates to:
  /// **'Yes, Cancel'**
  String get yesCancelTab;

  /// Tab cancelled info message
  ///
  /// In en, this message translates to:
  /// **'Tab cancelled'**
  String get tabCancelledMessage;

  /// Failed to cancel error
  ///
  /// In en, this message translates to:
  /// **'Failed to cancel tab'**
  String get failedToCancelTab;

  /// Ready to complete status
  ///
  /// In en, this message translates to:
  /// **'Ready to Complete'**
  String get readyToComplete;

  /// Not set placeholder
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// Switch tab instruction
  ///
  /// In en, this message translates to:
  /// **'Switch to the weighing tab to start recording weights'**
  String get switchToWeighingTab;

  /// Switch tab continue instruction
  ///
  /// In en, this message translates to:
  /// **'Switch to the weighing tab to continue recording weights'**
  String get switchToWeighingTabContinue;

  /// Print failed error
  ///
  /// In en, this message translates to:
  /// **'Print failed: {error}'**
  String printFailed(String error);

  /// Save PDF failed error
  ///
  /// In en, this message translates to:
  /// **'Save PDF failed: {error}'**
  String savePdfFailed(String error);

  /// Last updated prefix
  ///
  /// In en, this message translates to:
  /// **'Last Updated'**
  String get lastUpdatedLabel;

  /// Paid label
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paidLabel;

  /// Show price label
  ///
  /// In en, this message translates to:
  /// **'Show Price on Print'**
  String get showPriceOnPrintLabel;

  /// Additional info section
  ///
  /// In en, this message translates to:
  /// **'Additional Information'**
  String get additionalInfo;

  /// Unsaved changes label
  ///
  /// In en, this message translates to:
  /// **'Unsaved Changes'**
  String get unsavedChangesLabel;

  /// Completed label
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completedLabel;

  /// Database ID label
  ///
  /// In en, this message translates to:
  /// **'Database ID'**
  String get databaseId;

  /// Unsaved label
  ///
  /// In en, this message translates to:
  /// **'Unsaved'**
  String get unsavedLabel;

  /// Not available label
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get notAvailable;

  /// N/A abbreviation
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get na;

  /// Loading operation type with direction
  ///
  /// In en, this message translates to:
  /// **'Loading (Outgoing)'**
  String get loadingOutgoing;

  /// Unloading operation type with direction
  ///
  /// In en, this message translates to:
  /// **'Unloading (Incoming)'**
  String get unloadingIncoming;

  /// Total tabs statistics
  ///
  /// In en, this message translates to:
  /// **'Total Tabs'**
  String get totalTabs;

  /// Active tabs statistics
  ///
  /// In en, this message translates to:
  /// **'Active Tabs'**
  String get activeTabs;

  /// Top drivers chart title
  ///
  /// In en, this message translates to:
  /// **'Top Drivers by Weight'**
  String get topDriversByWeight;

  /// Maximum tabs message with count
  ///
  /// In en, this message translates to:
  /// **'You can have a maximum of {count} operations open at once. Please close some tabs before creating new ones.'**
  String maximumTabsCount(int count);

  /// Synchronization page title
  ///
  /// In en, this message translates to:
  /// **'Synchronization'**
  String get synchronization;

  /// Sync status section title
  ///
  /// In en, this message translates to:
  /// **'Sync Status'**
  String get syncStatus;

  /// Pending items label
  ///
  /// In en, this message translates to:
  /// **'Pending items'**
  String get pendingItems;

  /// Sync now button
  ///
  /// In en, this message translates to:
  /// **'Sync Now'**
  String get syncNow;

  /// Clear failed button
  ///
  /// In en, this message translates to:
  /// **'Clear Failed'**
  String get clearFailed;

  /// Scale connection settings title
  ///
  /// In en, this message translates to:
  /// **'Scale Connection Settings'**
  String get scaleConnectionSettings;

  /// Connection status label
  ///
  /// In en, this message translates to:
  /// **'Connection Status'**
  String get connectionStatus;

  /// Connected to prefix
  ///
  /// In en, this message translates to:
  /// **'Connected to'**
  String get connectedTo;

  /// Try to connect button
  ///
  /// In en, this message translates to:
  /// **'Try to Connect'**
  String get tryToConnect;

  /// Port configuration section
  ///
  /// In en, this message translates to:
  /// **'Port Configuration'**
  String get portConfiguration;

  /// COM port label
  ///
  /// In en, this message translates to:
  /// **'COM Port'**
  String get comPort;

  /// Auto-detect button
  ///
  /// In en, this message translates to:
  /// **'Auto-detect'**
  String get autoDetect;

  /// Baud rate label
  ///
  /// In en, this message translates to:
  /// **'Baud Rate'**
  String get baudRate;

  /// Data bits label
  ///
  /// In en, this message translates to:
  /// **'Data Bits'**
  String get dataBits;

  /// Stop bits label
  ///
  /// In en, this message translates to:
  /// **'Stop Bits'**
  String get stopBits;

  /// Parity label
  ///
  /// In en, this message translates to:
  /// **'Parity'**
  String get parity;

  /// Scale information section
  ///
  /// In en, this message translates to:
  /// **'Scale Information'**
  String get scaleInformation;

  /// Protocol label
  ///
  /// In en, this message translates to:
  /// **'Protocol'**
  String get protocol;

  /// Serial COM protocol description
  ///
  /// In en, this message translates to:
  /// **'Serial COM - Read Only'**
  String get serialComReadOnly;

  /// Expected format label
  ///
  /// In en, this message translates to:
  /// **'Expected Format'**
  String get expectedFormat;

  /// Weight format example
  ///
  /// In en, this message translates to:
  /// **'(±)(6 digits)(KG)'**
  String get weightFormatExample;

  /// Reading interval label
  ///
  /// In en, this message translates to:
  /// **'Reading Interval'**
  String get readingInterval;

  /// Reading interval value
  ///
  /// In en, this message translates to:
  /// **'100ms'**
  String get readingInterval100ms;

  /// Connection retry label
  ///
  /// In en, this message translates to:
  /// **'Connection Retry'**
  String get connectionRetry;

  /// Connection retry interval
  ///
  /// In en, this message translates to:
  /// **'Every 40ms'**
  String get connectionRetryInterval;

  /// Kilogram unit
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get kgUnit;

  /// Disconnected status message
  ///
  /// In en, this message translates to:
  /// **'Disconnected from scale'**
  String get disconnectedFromScale;

  /// Disconnect button
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get disconnect;

  /// Reconnecting status message
  ///
  /// In en, this message translates to:
  /// **'Attempting to reconnect...'**
  String get attemptingToReconnect;

  /// Print configuration title
  ///
  /// In en, this message translates to:
  /// **'Print Configuration'**
  String get printConfiguration;

  /// Manage print templates button
  ///
  /// In en, this message translates to:
  /// **'Manage Print Templates'**
  String get managePrintTemplates;

  /// Print template system title
  ///
  /// In en, this message translates to:
  /// **'Print Template System'**
  String get printTemplateSystem;

  /// Template configuration description
  ///
  /// In en, this message translates to:
  /// **'Configure print templates for your pre-printed A3 forms:'**
  String get configureTemplatesDescription;

  /// Create custom templates feature
  ///
  /// In en, this message translates to:
  /// **'Create custom templates'**
  String get createCustomTemplates;

  /// Drag drop feature
  ///
  /// In en, this message translates to:
  /// **'Drag & drop field positioning'**
  String get dragDropFieldPositioning;

  /// Configure fonts feature
  ///
  /// In en, this message translates to:
  /// **'Configure fonts and formatting'**
  String get configureFontsFormatting;

  /// Import export feature
  ///
  /// In en, this message translates to:
  /// **'Import/Export templates'**
  String get importExportTemplates;

  /// Test print feature
  ///
  /// In en, this message translates to:
  /// **'Test print alignment'**
  String get testPrintAlignment;

  /// Settings saved success message
  ///
  /// In en, this message translates to:
  /// **'Odoo settings saved successfully!'**
  String get odooSettingsSavedSuccess;

  /// Failed to save error message
  ///
  /// In en, this message translates to:
  /// **'Failed to save settings'**
  String get failedToSaveSettings;

  /// Connection failed with error
  ///
  /// In en, this message translates to:
  /// **'Connection failed'**
  String get connectionFailedWithError;

  /// Odoo settings description
  ///
  /// In en, this message translates to:
  /// **'Configure connection settings for Odoo ERP integration'**
  String get odooSettingsDescription;

  /// Odoo URL placeholder
  ///
  /// In en, this message translates to:
  /// **'https://your-odoo-instance.com'**
  String get odooUrlPlaceholder;

  /// Odoo URL required error
  ///
  /// In en, this message translates to:
  /// **'Odoo URL is required'**
  String get odooUrlRequired;

  /// Valid URL error
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid URL'**
  String get pleaseEnterValidUrl;

  /// Database name label
  ///
  /// In en, this message translates to:
  /// **'Database Name'**
  String get databaseName;

  /// Database name placeholder
  ///
  /// In en, this message translates to:
  /// **'your-database-name'**
  String get databaseNamePlaceholder;

  /// Database name required error
  ///
  /// In en, this message translates to:
  /// **'Database name is required'**
  String get databaseNameRequired;

  /// Admin username placeholder
  ///
  /// In en, this message translates to:
  /// **'admin'**
  String get adminPlaceholder;

  /// Password placeholder
  ///
  /// In en, this message translates to:
  /// **'••••••••'**
  String get passwordPlaceholder;

  /// Testing status
  ///
  /// In en, this message translates to:
  /// **'Testing...'**
  String get testing;

  /// Connection information section
  ///
  /// In en, this message translates to:
  /// **'Connection Information'**
  String get connectionInformation;

  /// Connection requirements title
  ///
  /// In en, this message translates to:
  /// **'Connection Requirements:'**
  String get connectionRequirements;

  /// Odoo requirement 1
  ///
  /// In en, this message translates to:
  /// **'• Ensure your Odoo instance is accessible'**
  String get odooRequirement1;

  /// Odoo requirement 2
  ///
  /// In en, this message translates to:
  /// **'• Verify the database name is correct'**
  String get odooRequirement2;

  /// Odoo requirement 3
  ///
  /// In en, this message translates to:
  /// **'• Use a user with proper access rights'**
  String get odooRequirement3;

  /// Odoo requirement 4
  ///
  /// In en, this message translates to:
  /// **'• Check firewall and network connectivity'**
  String get odooRequirement4;

  /// Supported operations title
  ///
  /// In en, this message translates to:
  /// **'Supported Operations:'**
  String get supportedOperations;

  /// Odoo operation 1
  ///
  /// In en, this message translates to:
  /// **'• Sync clients and suppliers as res.partner'**
  String get odooOperation1;

  /// Odoo operation 2
  ///
  /// In en, this message translates to:
  /// **'• Sync materials as product.product'**
  String get odooOperation2;

  /// Odoo operation 3
  ///
  /// In en, this message translates to:
  /// **'• Create sales orders for loading operations'**
  String get odooOperation3;

  /// Odoo operation 4
  ///
  /// In en, this message translates to:
  /// **'• Create purchase orders for unloading operations'**
  String get odooOperation4;

  /// New template button
  ///
  /// In en, this message translates to:
  /// **'New Template'**
  String get newTemplate;

  /// Test print button
  ///
  /// In en, this message translates to:
  /// **'Test Print'**
  String get testPrint;

  /// Print alignment grid button
  ///
  /// In en, this message translates to:
  /// **'Print Alignment Grid'**
  String get printAlignmentGrid;

  /// Export XPS button
  ///
  /// In en, this message translates to:
  /// **'Export XPS'**
  String get exportXps;

  /// Search templates placeholder
  ///
  /// In en, this message translates to:
  /// **'Search templates...'**
  String get searchTemplates;

  /// Select template message
  ///
  /// In en, this message translates to:
  /// **'Select a template to preview'**
  String get selectTemplateToPreview;

  /// Template preview title
  ///
  /// In en, this message translates to:
  /// **'Template Preview'**
  String get templatePreview;

  /// Print template management title
  ///
  /// In en, this message translates to:
  /// **'Print Template Management'**
  String get printTemplateManagement;

  /// Template details section
  ///
  /// In en, this message translates to:
  /// **'Template Details'**
  String get templateDetails;

  /// Name label with colon
  ///
  /// In en, this message translates to:
  /// **'Name:'**
  String get nameLabel;

  /// Description label with colon
  ///
  /// In en, this message translates to:
  /// **'Description:'**
  String get descriptionLabel;

  /// Paper size label with colon
  ///
  /// In en, this message translates to:
  /// **'Paper Size:'**
  String get paperSizeLabel;

  /// Orientation label with colon
  ///
  /// In en, this message translates to:
  /// **'Orientation:'**
  String get orientationLabel;

  /// Fields label with colon
  ///
  /// In en, this message translates to:
  /// **'Fields:'**
  String get fieldsLabel;

  /// Created label with colon
  ///
  /// In en, this message translates to:
  /// **'Created:'**
  String get createdLabel;

  /// Updated label with colon
  ///
  /// In en, this message translates to:
  /// **'Updated:'**
  String get updatedLabel;

  /// Fields section
  ///
  /// In en, this message translates to:
  /// **'Fields'**
  String get fields;

  /// Font label with colon
  ///
  /// In en, this message translates to:
  /// **'Font:'**
  String get fontLabel;

  /// Point abbreviation
  ///
  /// In en, this message translates to:
  /// **'pt'**
  String get pt;

  /// Bold text style
  ///
  /// In en, this message translates to:
  /// **'Bold'**
  String get bold;

  /// Format label with colon
  ///
  /// In en, this message translates to:
  /// **'Format:'**
  String get formatLabel;

  /// No fields message
  ///
  /// In en, this message translates to:
  /// **'No fields in template'**
  String get noFieldsInTemplate;

  /// Background image not found error
  ///
  /// In en, this message translates to:
  /// **'Background image not found'**
  String get backgroundImageNotFound;

  /// Error loading image error
  ///
  /// In en, this message translates to:
  /// **'Error loading background image'**
  String get errorLoadingBackgroundImage;

  /// Delete template dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete Template'**
  String get deleteTemplate;

  /// Delete template confirmation
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete'**
  String get areYouSureDeleteTemplate;

  /// Failed to delete error
  ///
  /// In en, this message translates to:
  /// **'Failed to delete template'**
  String get failedToDeleteTemplate;

  /// Test print options title
  ///
  /// In en, this message translates to:
  /// **'Test Print Options'**
  String get testPrintOptions;

  /// Choose test print method
  ///
  /// In en, this message translates to:
  /// **'Choose how to test print this template:'**
  String get chooseTestPrintMethod;

  /// Print with XPS option
  ///
  /// In en, this message translates to:
  /// **'PRINT WITH XPS'**
  String get printWithXps;

  /// Silent print option
  ///
  /// In en, this message translates to:
  /// **'Silent Print (Windows Direct)'**
  String get silentPrintWindowsDirect;

  /// Print with dialog option
  ///
  /// In en, this message translates to:
  /// **'Print with Dialog (Preview)'**
  String get printWithDialogPreview;

  /// Silent printing failed error
  ///
  /// In en, this message translates to:
  /// **'Silent printing failed with the following error:'**
  String get silentPrintingFailed;

  /// Possible solutions title
  ///
  /// In en, this message translates to:
  /// **'Possible solutions:'**
  String get possibleSolutions;

  /// Print success title
  ///
  /// In en, this message translates to:
  /// **'Print Success'**
  String get printSuccess;

  /// Template printed success message
  ///
  /// In en, this message translates to:
  /// **'Template printed successfully'**
  String get templatePrintedSuccess;

  /// Add item dialog title
  ///
  /// In en, this message translates to:
  /// **'Add \"{name}\"'**
  String addItem(String name);

  /// Supplier or client question
  ///
  /// In en, this message translates to:
  /// **'Is this a supplier or client?'**
  String get isThisSupplierOrClient;

  /// Add truck plate dialog title
  ///
  /// In en, this message translates to:
  /// **'Add Truck Plate \"{plateNumber}\"'**
  String addTruckPlate(String plateNumber);

  /// Enter driver name prompt
  ///
  /// In en, this message translates to:
  /// **'Please enter the driver name for this truck:'**
  String get pleaseEnterDriverName;

  /// Add driver dialog title
  ///
  /// In en, this message translates to:
  /// **'Add Driver \"{driverName}\"'**
  String addDriverName(String driverName);

  /// Enter truck plate prompt
  ///
  /// In en, this message translates to:
  /// **'Please enter a truck plate for this driver:'**
  String get pleaseEnterTruckPlate;

  /// Start button
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// Continue button
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// Complete tab dialog title
  ///
  /// In en, this message translates to:
  /// **'Complete Tab'**
  String get completeTabTitle;

  /// Complete tab confirmation
  ///
  /// In en, this message translates to:
  /// **'Mark tab \"{tabTitle}\" as completed?'**
  String markTabAsCompleted(String tabTitle);

  /// Tab title with name
  ///
  /// In en, this message translates to:
  /// **'Tab {tabTitle}'**
  String tabTitle(String tabTitle);

  /// Switch to tab option
  ///
  /// In en, this message translates to:
  /// **'Switch to Tab'**
  String get switchToTab;

  /// Print actions option
  ///
  /// In en, this message translates to:
  /// **'Print Actions'**
  String get printActions;

  /// Print options dialog title
  ///
  /// In en, this message translates to:
  /// **'Print Options - {tabTitle}'**
  String printOptions(String tabTitle);

  /// Cancel tab confirmation
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel tab \"{tabTitle}\"?'**
  String areYouSureCancelTab(String tabTitle);

  /// Close tab confirmation
  ///
  /// In en, this message translates to:
  /// **'Close tab \"{tabTitle}\"?'**
  String closeTabConfirm(String tabTitle);

  /// Sign in button
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No document message
  ///
  /// In en, this message translates to:
  /// **'No document to preview'**
  String get noDocumentToPreview;

  /// Fit zoom button
  ///
  /// In en, this message translates to:
  /// **'Fit'**
  String get fit;

  /// Rulers toggle
  ///
  /// In en, this message translates to:
  /// **'Rulers'**
  String get rulers;

  /// Margins toggle
  ///
  /// In en, this message translates to:
  /// **'Margins'**
  String get margins;

  /// Remove button
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// A4 paper size
  ///
  /// In en, this message translates to:
  /// **'A4'**
  String get paperSizeA4;

  /// A5 paper size
  ///
  /// In en, this message translates to:
  /// **'A5'**
  String get paperSizeA5;

  /// Letter paper size
  ///
  /// In en, this message translates to:
  /// **'Letter'**
  String get paperSizeLetter;

  /// Custom paper size
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get paperSizeCustom;

  /// Warning message for unsaved changes
  ///
  /// In en, this message translates to:
  /// **'Warning: This tab has unsaved changes.'**
  String get warningUnsavedChanges;

  /// PDF preview label
  ///
  /// In en, this message translates to:
  /// **'PDF Preview'**
  String get pdfPreview;

  /// Saving status message
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// Per kilogram suffix
  ///
  /// In en, this message translates to:
  /// **'/kg'**
  String get perKg;

  /// Currency symbol
  ///
  /// In en, this message translates to:
  /// **'\$'**
  String get currencySymbol;

  /// Switch user panel title
  ///
  /// In en, this message translates to:
  /// **'Switch User'**
  String get switchUser;

  /// No other users message
  ///
  /// In en, this message translates to:
  /// **'No other users available'**
  String get noOtherUsersAvailable;

  /// Edit client dialog title
  ///
  /// In en, this message translates to:
  /// **'Edit Client'**
  String get editClientTitle;

  /// Create new client dialog title
  ///
  /// In en, this message translates to:
  /// **'Create New Client'**
  String get createNewClient;

  /// Name field with required indicator
  ///
  /// In en, this message translates to:
  /// **'Name *'**
  String get nameRequired;

  /// Client name placeholder
  ///
  /// In en, this message translates to:
  /// **'Client name'**
  String get clientNamePlaceholder;

  /// Name validation error
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get nameIsRequired;

  /// Phone field label
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phoneLabel;

  /// Phone placeholder
  ///
  /// In en, this message translates to:
  /// **'+1 (555) 123-4567'**
  String get phonePlaceholder;

  /// Mobile field label
  ///
  /// In en, this message translates to:
  /// **'Mobile'**
  String get mobileLabel;

  /// Mobile placeholder
  ///
  /// In en, this message translates to:
  /// **'+1 (555) 987-6543'**
  String get mobilePlaceholder;

  /// City field label
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get cityLabel;

  /// City placeholder
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get cityPlaceholder;

  /// Update button text
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get updateButton;

  /// Create button text
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get createButton;

  /// Client update success message
  ///
  /// In en, this message translates to:
  /// **'Client updated successfully'**
  String get clientUpdatedSuccessfully;

  /// Client update error message
  ///
  /// In en, this message translates to:
  /// **'Failed to update client'**
  String get failedToUpdateClient;

  /// Client creation success message
  ///
  /// In en, this message translates to:
  /// **'Client created successfully'**
  String get clientCreatedSuccessfully;

  /// Client creation error message
  ///
  /// In en, this message translates to:
  /// **'Failed to create client'**
  String get failedToCreateClient;

  /// Edit supplier dialog title
  ///
  /// In en, this message translates to:
  /// **'Edit Supplier'**
  String get editSupplierTitle;

  /// Create new supplier dialog title
  ///
  /// In en, this message translates to:
  /// **'Create New Supplier'**
  String get createNewSupplier;

  /// Supplier name placeholder
  ///
  /// In en, this message translates to:
  /// **'Supplier name'**
  String get supplierNamePlaceholder;

  /// Supplier update success message
  ///
  /// In en, this message translates to:
  /// **'Supplier updated successfully'**
  String get supplierUpdatedSuccessfully;

  /// Supplier update error message
  ///
  /// In en, this message translates to:
  /// **'Failed to update supplier'**
  String get failedToUpdateSupplier;

  /// Supplier creation success message
  ///
  /// In en, this message translates to:
  /// **'Supplier created successfully'**
  String get supplierCreatedSuccessfully;

  /// Supplier creation error message
  ///
  /// In en, this message translates to:
  /// **'Failed to create supplier'**
  String get failedToCreateSupplier;

  /// Active operations exist message
  ///
  /// In en, this message translates to:
  /// **'Active operations exist'**
  String get activeOperationsExist;

  /// New operation button text
  ///
  /// In en, this message translates to:
  /// **'New Operation'**
  String get newOperation;

  /// Switch to user dialog title
  ///
  /// In en, this message translates to:
  /// **'Switch to {username}'**
  String switchToUser(String username);

  /// Enter password subtitle
  ///
  /// In en, this message translates to:
  /// **'Enter password to continue'**
  String get enterPasswordToContinue;

  /// Password validation error
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordIsRequired;

  /// Invalid password error
  ///
  /// In en, this message translates to:
  /// **'Invalid password'**
  String get invalidPassword;

  /// Login failed with error
  ///
  /// In en, this message translates to:
  /// **'Login failed: {error}'**
  String loginFailedError(String error);

  /// No description provided for @alreadyThere.
  ///
  /// In en, this message translates to:
  /// **'the name is already there'**
  String get alreadyThere;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
