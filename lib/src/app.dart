import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/admin_setup_screen.dart';
import 'settings/settings_controller.dart';
import 'settings/settings_view.dart';
import 'controllers/auth_controller.dart';
import 'controllers/product_controller.dart';
import 'controllers/order_controller.dart';
import 'controllers/customer_controller.dart';
import 'controllers/inventory_controller.dart';
import 'controllers/ingredient_controller.dart';
import 'controllers/product_inventory_controller.dart';
import 'controllers/business_profile_controller.dart';
import 'controllers/user_management_controller.dart';
import 'services/auth_service.dart';
import 'localization/app_localizations.dart';

/// The Widget that configures your application.
class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.settingsController,
  });

  final SettingsController settingsController;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthController()),
        ChangeNotifierProvider(create: (context) => ProductController()),
        ChangeNotifierProvider(create: (context) => OrderController()),
        ChangeNotifierProvider(create: (context) => CustomerController()),
        ChangeNotifierProvider(create: (context) => InventoryController()),
        ChangeNotifierProvider(create: (context) => IngredientController()),
        ChangeNotifierProvider(create: (context) => ProductInventoryController()),
        ChangeNotifierProvider(create: (context) => BusinessProfileController()),
        ChangeNotifierProvider(create: (context) => UserManagementController()),
      ],
      child: ListenableBuilder(
        listenable: settingsController,
        builder: (BuildContext context, Widget? child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            restorationScopeId: 'app',
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en', ''),
            ],
            onGenerateTitle: (BuildContext context) =>
                AppLocalizations.of(context)!.appTitle,
            theme: ThemeData(
              primarySwatch: Colors.brown,
              primaryColor: const Color(0xFF6D4C41),
              scaffoldBackgroundColor: const Color(0xFFF5F5DC),
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFF6D4C41),
                foregroundColor: Colors.white,
                elevation: 2,
              ),
              cardTheme: const CardThemeData(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6D4C41),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              primarySwatch: Colors.brown,
              primaryColor: const Color(0xFF8D6E63),
              scaffoldBackgroundColor: const Color(0xFF2E2E2E),
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFF8D6E63),
                foregroundColor: Colors.white,
                elevation: 2,
              ),
              cardTheme: const CardThemeData(
                color: Color(0xFF424242),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8D6E63),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            themeMode: settingsController.themeMode,
            home: StreamBuilder<User?>(
              stream: AuthService.authStateChanges,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                
                if (snapshot.hasData) {
                  return const MainScreen();
                } else {
                  return const LoginScreen();
                }
              },
            ),
            onGenerateRoute: (RouteSettings routeSettings) {
              return MaterialPageRoute<void>(
                settings: routeSettings,
                builder: (BuildContext context) {
                  switch (routeSettings.name) {
                    case SettingsView.routeName:
                      return SettingsView(controller: settingsController);
                    case MainScreen.routeName:
                      return const MainScreen();
                    case '/admin-setup':
                      return const AdminSetupScreen();
                    case LoginScreen.routeName:
                    default:
                      return const LoginScreen();
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
