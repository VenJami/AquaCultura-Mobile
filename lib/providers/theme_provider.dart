import 'package:flutter/material.dart';

// Helper to create MaterialColor from a single color
MaterialColor createMaterialColor(Color color) {
  List strengths = <double>[.05];
  Map<int, Color> swatch = {};
  final int r = color.red, g = color.green, b = color.blue;

  for (int i = 1; i < 10; i++) {
    strengths.add(0.1 * i);
  }
  for (var strength in strengths) {
    final double ds = 0.5 - strength;
    swatch[(strength * 1000).round()] = Color.fromRGBO(
      r + ((ds < 0 ? r : (255 - r)) * ds).round(),
      g + ((ds < 0 ? g : (255 - g)) * ds).round(),
      b + ((ds < 0 ? b : (255 - b)) * ds).round(),
      1,
    );
  }
  return MaterialColor(color.value, swatch);
}

class Palette {
  final ThemeData lightTheme;
  final ThemeData darkTheme;
  final String name;

  Palette({required this.lightTheme, required this.darkTheme, required this.name});
}

class ThemeProvider with ChangeNotifier {
  int _selectedPaletteIndex = 0; // Default to the blue theme
  ThemeMode _themeMode = ThemeMode.system; // Default to system

  int get selectedPaletteIndex => _selectedPaletteIndex;
  ThemeMode get themeMode => _themeMode;

  final List<Palette> _palettes = [
    _createBlueTheme(), // Blue theme first (default)
    _createPalette2(),
    _createPalette3(),
  ];

  ThemeData get currentLightTheme => _palettes[_selectedPaletteIndex].lightTheme;
  ThemeData get currentDarkTheme => _palettes[_selectedPaletteIndex].darkTheme;
  String get currentPaletteName => _palettes[_selectedPaletteIndex].name;

  void cyclePalette() {
    _selectedPaletteIndex = (_selectedPaletteIndex + 1) % _palettes.length;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  // --- Palette Definitions ---

  static Palette _createBlueTheme() {
    const primaryColor = Color(0xFF4CA6E9); // Blue
    const secondaryColor = Color(0xFF2E8FDD); // Darker Blue
    const accentColor = Color(0xFFA1C9F0); // Lighter Blue

    final lightTheme = ThemeData(
      brightness: Brightness.light,
      primarySwatch: createMaterialColor(primaryColor),
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: Color(0xFFFAFAFA), // Surface
        background: Color(0xFFFFFFFF), // Background
        error: Colors.redAccent,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Color(0xFF212121), // Text on Surface/Background
        onBackground: Color(0xFF212121),
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: const Color(0xFFFFFFFF),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor, // Use primary for buttons
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor),
        ),
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        color: const Color(0xFFFAFAFA), // Surface color for cards
      ),
      dividerColor: Colors.grey.shade300,
    );

    final darkTheme = ThemeData(
      brightness: Brightness.dark,
      primarySwatch: createMaterialColor(primaryColor),
      colorScheme: const ColorScheme.dark(
        primary: primaryColor, // Keep primary consistent
        secondary: secondaryColor, // Keep secondary consistent
        surface: Color(0xFF303030), // Dark Surface
        background: Color(0xFF212121), // Dark Background
        error: Colors.redAccent,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Color(0xFFFAFAFA), // Text on Dark Surface/Background
        onBackground: Color(0xFFFAFAFA),
        onError: Colors.black,
      ),
      scaffoldBackgroundColor: const Color(0xFF212121),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF303030), // Darker App Bar
        foregroundColor: Color(0xFFFAFAFA),
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor, // Use primary for buttons
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor), // Use primary for focus
        ),
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        color: const Color(0xFF303030), // Dark Surface for cards
      ),
      dividerColor: Colors.grey.shade700,
    );

    return Palette(lightTheme: lightTheme, darkTheme: darkTheme, name: "Modern Blue");
  }

  static Palette _createPalette2() {
    const primaryColor = Color(0xFF558B2F); // Olive Green
    const secondaryColor = Color(0xFFA1887F); // Muted Brown/Taupe
    const accentColor = Color(0xFF8BC34A); // Brighter Light Green

    final lightTheme = ThemeData(
      brightness: Brightness.light,
      primarySwatch: createMaterialColor(primaryColor),
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: Color(0xFFFFFFFF),
        background: Color(0xFFF5F5F5),
        error: Colors.deepOrange,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Color(0xFF3E2723), // Dark Brown Text
        onBackground: Color(0xFF3E2723),
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Color(0xFF3E2723), // Dark text on light green
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
       inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor),
        ),
      ),
       cardTheme: CardTheme(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        color: const Color(0xFFFFFFFF), // White cards
      ),
       dividerColor: Colors.brown.shade100,
    );

    final darkTheme = ThemeData(
      brightness: Brightness.dark,
      primarySwatch: createMaterialColor(primaryColor),
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: Color(0xFF4E342E), // Dark Brown Surface
        background: Color(0xFF3E2723), // Dark Brown Background
        error: Colors.orangeAccent,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: Color(0xFFEFEBE9), // Light Beige Text
        onBackground: Color(0xFFEFEBE9),
        onError: Colors.black,
      ),
      scaffoldBackgroundColor: const Color(0xFF3E2723),
       appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF4E342E), // Darker Brown App Bar
        foregroundColor: Color(0xFFEFEBE9),
        elevation: 0,
      ),
       elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Color(0xFF3E2723), // Dark text on light green
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: accentColor),
        ),
      ),
       cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        color: const Color(0xFF4E342E), // Dark Brown Surface for cards
      ),
       dividerColor: Colors.brown.shade800,
    );

    return Palette(lightTheme: lightTheme, darkTheme: darkTheme, name: "Natural & Grounded");
  }

  static Palette _createPalette3() {
    const primaryColor = Color(0xFF43A047); // Crisp Green
    const secondaryColor = Color(0xFF757575); // Medium Grey
    const accentColor = Color(0xFF66BB6A); // Lighter Green
    // const accentColor2 = Color(0xFF1976D2); // Optional Blue

    final lightTheme = ThemeData(
      brightness: Brightness.light,
      primarySwatch: createMaterialColor(primaryColor),
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: Color(0xFFF5F5F5), // Light Grey Surface
        background: Color(0xFFFFFFFF), // White Background
        error: Colors.red,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.black, // Black Text
        onBackground: Colors.black,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: const Color(0xFFFFFFFF),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor),
        ),
      ),
      cardTheme: CardTheme(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        color: const Color(0xFFF5F5F5), // Light Grey Surface for cards
      ),
      dividerColor: Colors.grey.shade300,
    );

    final darkTheme = ThemeData(
      brightness: Brightness.dark,
      primarySwatch: createMaterialColor(primaryColor),
      colorScheme: const ColorScheme.dark(
        primary: primaryColor, // Keep primary consistent
        secondary: secondaryColor, // Keep secondary consistent
        surface: Color(0xFF1E1E1E), // Dark Grey Surface
        background: Color(0xFF121212), // Very Dark Background
        error: Colors.redAccent,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white, // White Text
        onBackground: Colors.white,
        onError: Colors.black,
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E), // Dark Surface App Bar
        foregroundColor: Colors.white,
        elevation: 0,
      ),
       elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: accentColor), // Lighter green focus
        ),
      ),
       cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        color: const Color(0xFF1E1E1E), // Dark Surface for cards
      ),
      dividerColor: Colors.grey.shade800,
    );

    return Palette(lightTheme: lightTheme, darkTheme: darkTheme, name: "Crisp & Focused");
  }
}

// You might want to move the AppTheme class from theme.dart here or remove it
// if ThemeProvider fully replaces its role. For now, we leave it.
// class AppTheme { ... } // Original AppTheme class 