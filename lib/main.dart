import 'package:flutter/material.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:weighing_system/providers/user_provider.dart';
import 'package:weighing_system/screens/login_screen.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'providers/weight_provider.dart';
import 'providers/sync_provider.dart';
import 'providers/client_provider.dart';
import 'providers/material_provider.dart';
import 'providers/supplier_provider.dart';
import 'providers/print_provider.dart';
import 'providers/report_provider.dart';
import 'providers/vehicle_driver_provider.dart';
import 'providers/app_settings_provider.dart';
import 'providers/driver_provider.dart';
import 'providers/driver_plate_provider.dart';
import 'providers/tabs_provider.dart';
import 'screens/main_dashboard.dart';
import 'theme/app_theme.dart';

void main() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  WidgetsFlutterBinding.ensureInitialized();

  // Initialize window manager for desktop
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(1100, 750),
    minimumSize: Size(900, 650),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
    title: 'Truck Weighing System',
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const WeighingSystemApp());
}

class WeighingSystemApp extends StatelessWidget {
  const WeighingSystemApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WeightProvider()),
        ChangeNotifierProvider(create: (_) => SyncProvider()),
        ChangeNotifierProvider(create: (_) => ClientProvider()),
        ChangeNotifierProvider(create: (_) => MaterialProvider()),
        ChangeNotifierProvider(create: (_) => SupplierProvider()),
        ChangeNotifierProvider(create: (_) => PrintProvider()),
        ChangeNotifierProvider(create: (_) => ReportProvider()),
        ChangeNotifierProvider(create: (_) => VehicleDriverProvider()),
        ChangeNotifierProvider(create: (_) => AppSettingsProvider()),
        ChangeNotifierProvider(create: (_) => DriverProvider()),
        ChangeNotifierProvider(create: (_) => DriverPlateProvider()),
        ChangeNotifierProvider(create: (_) => TabsProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: fluent.FluentApp(
        title: 'Truck Weighing System',
        theme: AppTheme.lightTheme,
        home: const LoginScreen(),
        debugShowCheckedModeBanner: false,
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('ar'), // Arabic
          Locale('en'), // English
        ],
        locale: const Locale('ar'), // Default to Arabic
      ),
    );
  }
}
