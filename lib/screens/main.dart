import 'package:flutter/material.dart';
// import 'package:video_player/video_player.dart'; // Removed
import 'login.dart';
import 'home.dart';
// import 'app_splash_screen.dart'; // Removed as file was deleted
import '../config/theme.dart'; // Import AppTheme

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // --- Replicate AppTheme.lightTheme definition directly --- 
    const int _primaryColorHex = 0xFF4CA6E9;
    const Color _primaryColor = Color(_primaryColorHex);
    const MaterialColor _primarySwatch = MaterialColor(
      _primaryColorHex,
      <int, Color>{
        50: const Color(0xFFF3F9FD),
        100: const Color(0xFFE0EDFA),
        200: const Color(0xFFC5DCF1),
        300: const Color(0xFFA1C9F0),
        400: const Color(_primaryColorHex),
        500: const Color(0xFF2E8FDD),
        600: const Color(0xFF237CCA),
        700: const Color(0xFF1A69B8),
        800: const Color(0xFF1256A5),
        900: const Color(0xFF0A4393),
      },
    );
    final ColorScheme blueColorScheme = ColorScheme.light(
      primary: _primaryColor,
      onPrimary: Colors.white,
      secondary: _primarySwatch[200]!,
      onSecondary: Colors.black,
      surface: Colors.white,
      onSurface: Colors.black87,
      background: Colors.white,
      onBackground: Colors.black87,
      error: Colors.redAccent[700]!,
      onError: Colors.white,
      brightness: Brightness.light,
    );
    final ThemeData directLightTheme = ThemeData(
      colorScheme: blueColorScheme,
      primarySwatch: _primarySwatch, 
      scaffoldBackgroundColor: blueColorScheme.background, 
      appBarTheme: AppBarTheme(
        backgroundColor: blueColorScheme.primary, 
        foregroundColor: blueColorScheme.onPrimary,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: blueColorScheme.primary, 
          foregroundColor: blueColorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: blueColorScheme.onSurface.withOpacity(0.2)), 
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: blueColorScheme.onSurface.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: blueColorScheme.primary, width: 1.5), 
        ),
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        color: blueColorScheme.surface,
      ),
    );
    // --- End Theme Definition ---

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AquaCultura App',
      theme: directLightTheme, 
      home: const LoginPage(), 
      routes: {
        // '/': (context) => const LoginPage(), // Define '/' if needed for navigation, but home handles start
        '/login': (context) => const LoginPage(),
        '/home': (context) => HomeScreen(),
        // Define other routes if needed
      },
    );
  }
}

// Old video SplashScreen removed
