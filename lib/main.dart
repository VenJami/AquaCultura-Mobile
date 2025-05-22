import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/attendance_provider.dart';
import 'providers/batch_provider.dart';
import 'providers/task_provider.dart';
import 'providers/seedling_provider.dart';
import 'providers/transplant_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/due_items_notification_provider.dart';
import 'providers/main_screen_tab_provider.dart';
import 'providers/general_notification_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login.dart';
import 'screens/home.dart';
import 'screens/main_screen.dart';
import 'screens/attendance_log_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/tasks_screen.dart';
import 'screens/seedling_insights.dart';
import 'screens/transplant_insights_screen.dart';
import 'screens/transplant_details_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/change_password_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (ctx) => AuthProvider()),
        ChangeNotifierProvider(create: (ctx) => TransplantProvider()),
        ChangeNotifierProvider(create: (_) => AttendanceProvider()),
        ChangeNotifierProvider(create: (_) => BatchProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => SeedlingProvider()),
        ChangeNotifierProvider(create: (ctx) => ThemeProvider()),
        ChangeNotifierProvider(create: (ctx) => DueItemsNotificationProvider()),
        ChangeNotifierProvider(create: (ctx) => MainScreenTabProvider()),
        ChangeNotifierProxyProvider<AuthProvider, GeneralNotificationProvider>(
          create: (ctx) => GeneralNotificationProvider(null),
          update: (ctx, auth, previousGeneralNotifications) =>
              GeneralNotificationProvider(auth),
        ),
      ],
      child: Consumer<AuthProvider>(
        builder: (ctx, auth, _) => Consumer<ThemeProvider>(
          builder: (context, themeProvider, _) => MaterialApp(
            title: 'AquaCultura',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.currentLightTheme,
            darkTheme: themeProvider.currentDarkTheme,
            themeMode: themeProvider.themeMode,
            home: auth.isAuth
                ? const MainScreen()
                : FutureBuilder(
                    future: auth.tryAutoLogin(),
                    builder: (ctx, authResultSnapshot) =>
                        authResultSnapshot.connectionState ==
                                ConnectionState.waiting
                            ? const SplashScreen()
                            : const LoginPage(),
                  ),
            routes: {
              '/login': (context) => const LoginPage(),
              '/home': (context) => const MainScreen(),
              '/attendance': (context) => const AttendanceLogScreen(),
              '/calendar': (context) => const CalendarScreen(),
              '/tasks': (context) => const TasksScreen(),
              '/seedling-insights': (context) => const SeedlingsInsightsScreen(),
              '/transplant-insights': (context) =>
                  const TransplantInsightsScreen(),
              '/transplant-details': (context) =>
                  const TransplantDetailsScreen(transplantId: '1'),
              '/settings': (context) => const SettingsScreen(),
              '/change-password': (context) => const ChangePasswordScreen(),
            },
          ),
        ),
      ),
    );
  }
}
