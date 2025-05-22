import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart'; // google_fonts might not be used directly in this theme file

class AppTheme {
  static const int _primaryColorHex = 0xFF4CA6E9;
  static const Color _primaryColor = Color(_primaryColorHex);

  static const MaterialColor _primarySwatch = MaterialColor(
    _primaryColorHex, // Use the hex value of the primary color (shade 400 from user)
    <int, Color>{
      50: const Color(0xFFF3F9FD),
      100: const Color(0xFFE0EDFA),
      200: const Color(0xFFC5DCF1), // Corrected shade 200
      300: const Color(0xFFA1C9F0),
      400: const Color(_primaryColorHex), // User's provided color
      500: const Color(0xFF2E8FDD), // Derived shade 500, slightly darker than 400
      600: const Color(0xFF237CCA),
      700: const Color(0xFF1A69B8),
      800: const Color(0xFF1256A5),
      900: const Color(0xFF0A4393),
    },
  );

  static ThemeData get lightTheme {
    // Define a ColorScheme using the primary blue color
    final ColorScheme blueColorScheme = ColorScheme.light(
      primary: _primaryColor, // Your blue 0xFF4CA6E9
      onPrimary: Colors.white, // White text on blue
      secondary: _primarySwatch[200]!, // A lighter blue shade for secondary
      onSecondary: Colors.black, // Black text on light blue
      surface: Colors.white, // White surfaces
      onSurface: Colors.black87, // Slightly softer black text on white surfaces
      background: Colors.white, // White background
      onBackground: Colors.black87, // Slightly softer black text on white background
      error: Colors.redAccent[700]!, // Standard error color
      onError: Colors.white,
      brightness: Brightness.light,
      // Define other colors as needed or let them default
    );

    return ThemeData(
      // Use the explicitly defined ColorScheme
      colorScheme: blueColorScheme,
      // Keep primarySwatch for compatibility if needed, but colorScheme is primary now
      primarySwatch: _primarySwatch, 
      // Use colors from the scheme
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
          // Use a subtle border color from the theme
          borderSide: BorderSide(color: blueColorScheme.onSurface.withOpacity(0.2)), 
        ),
        enabledBorder: OutlineInputBorder( // Define enabled border explicitly for consistency
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: blueColorScheme.onSurface.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          // Use primary color for focus border
          borderSide: BorderSide(color: blueColorScheme.primary, width: 1.5), 
        ),
        // Define fill color and hint style if desired for consistency
        // fillColor: blueColorScheme.surface.withOpacity(0.05), 
        // filled: true,
        // hintStyle: TextStyle(color: blueColorScheme.onSurface.withOpacity(0.5)),
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        color: blueColorScheme.surface, // Use surface color for cards
      ),
      // Define text themes if needed
      // textTheme: GoogleFonts.latoTextTheme(ThemeData.light().textTheme),
    );
  }

  static ThemeData get darkTheme {
    // Define an explicit dark ColorScheme
    final ColorScheme blueDarkColorScheme = ColorScheme.dark(
      primary: _primaryColor, // Keep the blue primary
      onPrimary: Colors.white,
      secondary: _primarySwatch[300]!, // Lighter blue for secondary in dark
      onSecondary: Colors.black,
      surface: Colors.grey[850]!, // Dark surface
      onSurface: Colors.white,
      background: Colors.grey[900]!, // Dark background
      onBackground: Colors.white,
      error: Colors.redAccent[200]!, // Lighter error for dark mode
      onError: Colors.black,
      brightness: Brightness.dark,
    );

    return ThemeData(
      colorScheme: blueDarkColorScheme,
      primarySwatch: _primarySwatch, // Keep for compatibility
      brightness: Brightness.dark,
      scaffoldBackgroundColor: blueDarkColorScheme.background,
      appBarTheme: AppBarTheme(
        backgroundColor: blueDarkColorScheme.surface, // Use surface for dark AppBar
        foregroundColor: blueDarkColorScheme.onSurface,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: blueDarkColorScheme.primary, // Use primaryColor for buttons in dark mode
          foregroundColor: blueDarkColorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: blueDarkColorScheme.onSurface.withOpacity(0.3)),
        ),
         enabledBorder: OutlineInputBorder( // Define enabled border explicitly for consistency
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: blueDarkColorScheme.onSurface.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: blueDarkColorScheme.primary), // Use primaryColor for focus
        ),
         // fillColor: blueDarkColorScheme.surface.withOpacity(0.1),
         // filled: true,
         // hintStyle: TextStyle(color: blueDarkColorScheme.onSurface.withOpacity(0.5)),
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        color: blueDarkColorScheme.surface, // Use surface for card background
      ),
    );
  }
} 