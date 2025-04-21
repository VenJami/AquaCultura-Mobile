import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/attendance_provider.dart';
import 'providers/batch_provider.dart';
import 'providers/task_provider.dart';
import 'providers/seedling_provider.dart';
import 'providers/transplant_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login.dart';
import 'screens/home.dart';
import 'screens/attendance_log_screen.dart';
import 'screens/batch_details_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/tasks_screen.dart';
import 'screens/seedling_insights.dart';
import 'screens/transplant_insights_screen.dart';
import 'screens/transplant_details_screen.dart';
import 'config/theme.dart';

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
      ],
      child: Consumer<AuthProvider>(
        builder: (ctx, auth, _) => MaterialApp(
          title: 'Jencap',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system,
          home: auth.isAuth
              ? const HomeScreen()
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
            '/home': (context) => const HomeScreen(),
            '/attendance': (context) => const AttendanceLogScreen(),
            '/calendar': (context) => const CalendarScreen(),
            '/tasks': (context) => const TasksScreen(),
            '/seedling-insights': (context) => const SeedlingsInsightsScreen(),
            '/transplant-insights': (context) =>
                const TransplantInsightsScreen(),
            '/transplant-details': (context) =>
                const TransplantDetailsScreen(transplantId: '1'),
          },
        ),
      ),
    );
  }
}
