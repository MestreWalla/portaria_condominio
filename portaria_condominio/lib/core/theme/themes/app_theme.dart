import 'package:flutter/material.dart';

enum ThemePreset {
  defaultLight,
  defaultDark,
  indigoLight,
  indigoDark,
  tealLight,
  tealDark,
  orangeLight,
  orangeDark,
  purpleLight,
  purpleDark,
  greenLight,
  greenDark,
  blueLight,
  blueDark,
  redLight,
  redDark,
}

enum ThemeCategory {
  basic,
  cool,
  warm,
  nature,
}

class AppTheme {
  static const _defaultSeedColor = Color(0xFF1A73E8); // Google Blue
  static const _indigoSeedColor = Color(0xFF3F51B5); // Indigo
  static const _tealSeedColor = Color(0xFF009688); // Teal
  static const _orangeSeedColor = Color(0xFFFF5722); // Deep Orange
  static const _purpleSeedColor = Color(0xFF9C27B0); // Purple
  static const _greenSeedColor = Color(0xFF4CAF50); // Green
  static const _blueSeedColor = Color(0xFF2196F3); // Blue
  static const _redSeedColor = Color(0xFFF44336); // Red

  static ThemeData getThemeByPreset(ThemePreset preset) {
    switch (preset) {
      case ThemePreset.defaultLight:
        return _createTheme(_defaultSeedColor, Brightness.light);
      case ThemePreset.defaultDark:
        return _createTheme(_defaultSeedColor, Brightness.dark);
      case ThemePreset.indigoLight:
        return _createTheme(_indigoSeedColor, Brightness.light);
      case ThemePreset.indigoDark:
        return _createTheme(_indigoSeedColor, Brightness.dark);
      case ThemePreset.tealLight:
        return _createTheme(_tealSeedColor, Brightness.light);
      case ThemePreset.tealDark:
        return _createTheme(_tealSeedColor, Brightness.dark);
      case ThemePreset.orangeLight:
        return _createTheme(_orangeSeedColor, Brightness.light);
      case ThemePreset.orangeDark:
        return _createTheme(_orangeSeedColor, Brightness.dark);
      case ThemePreset.purpleLight:
        return _createTheme(_purpleSeedColor, Brightness.light);
      case ThemePreset.purpleDark:
        return _createTheme(_purpleSeedColor, Brightness.dark);
      case ThemePreset.greenLight:
        return _createTheme(_greenSeedColor, Brightness.light);
      case ThemePreset.greenDark:
        return _createTheme(_greenSeedColor, Brightness.dark);
      case ThemePreset.blueLight:
        return _createTheme(_blueSeedColor, Brightness.light);
      case ThemePreset.blueDark:
        return _createTheme(_blueSeedColor, Brightness.dark);
      case ThemePreset.redLight:
        return _createTheme(_redSeedColor, Brightness.light);
      case ThemePreset.redDark:
        return _createTheme(_redSeedColor, Brightness.dark);
    }
  }

  static ThemeCategory getThemeCategory(ThemePreset preset) {
    switch (preset) {
      case ThemePreset.defaultLight:
      case ThemePreset.defaultDark:
        return ThemeCategory.basic;
      case ThemePreset.indigoLight:
      case ThemePreset.indigoDark:
      case ThemePreset.purpleLight:
      case ThemePreset.purpleDark:
      case ThemePreset.blueLight:
      case ThemePreset.blueDark:
        return ThemeCategory.cool;
      case ThemePreset.orangeLight:
      case ThemePreset.orangeDark:
      case ThemePreset.redLight:
      case ThemePreset.redDark:
        return ThemeCategory.warm;
      case ThemePreset.tealLight:
      case ThemePreset.tealDark:
      case ThemePreset.greenLight:
      case ThemePreset.greenDark:
        return ThemeCategory.nature;
    }
  }

  static String getThemeCategoryName(ThemeCategory category) {
    switch (category) {
      case ThemeCategory.basic:
        return 'Básico';
      case ThemeCategory.cool:
        return 'Tons Frios';
      case ThemeCategory.warm:
        return 'Tons Quentes';
      case ThemeCategory.nature:
        return 'Natureza';
    }
  }

  static IconData getThemeCategoryIcon(ThemeCategory category) {
    switch (category) {
      case ThemeCategory.basic:
        return Icons.palette_outlined;
      case ThemeCategory.cool:
        return Icons.ac_unit_outlined;
      case ThemeCategory.warm:
        return Icons.wb_sunny_outlined;
      case ThemeCategory.nature:
        return Icons.nature_outlined;
    }
  }

  static String getThemeName(ThemePreset preset) {
    switch (preset) {
      case ThemePreset.defaultLight:
        return 'Padrão Claro';
      case ThemePreset.defaultDark:
        return 'Padrão Escuro';
      case ThemePreset.indigoLight:
        return 'Índigo Claro';
      case ThemePreset.indigoDark:
        return 'Índigo Escuro';
      case ThemePreset.tealLight:
        return 'Teal Claro';
      case ThemePreset.tealDark:
        return 'Teal Escuro';
      case ThemePreset.orangeLight:
        return 'Laranja Claro';
      case ThemePreset.orangeDark:
        return 'Laranja Escuro';
      case ThemePreset.purpleLight:
        return 'Roxo Claro';
      case ThemePreset.purpleDark:
        return 'Roxo Escuro';
      case ThemePreset.greenLight:
        return 'Verde Claro';
      case ThemePreset.greenDark:
        return 'Verde Escuro';
      case ThemePreset.blueLight:
        return 'Azul Claro';
      case ThemePreset.blueDark:
        return 'Azul Escuro';
      case ThemePreset.redLight:
        return 'Vermelho Claro';
      case ThemePreset.redDark:
        return 'Vermelho Escuro';
    }
  }

  static IconData getThemeIcon(ThemePreset preset) {
    switch (preset) {
      case ThemePreset.defaultLight:
      case ThemePreset.defaultDark:
        return Icons.palette_outlined;
      case ThemePreset.indigoLight:
      case ThemePreset.indigoDark:
        return Icons.color_lens_outlined;
      case ThemePreset.tealLight:
      case ThemePreset.tealDark:
        return Icons.brush_outlined;
      case ThemePreset.orangeLight:
      case ThemePreset.orangeDark:
        return Icons.format_paint_outlined;
      case ThemePreset.purpleLight:
      case ThemePreset.purpleDark:
        return Icons.colorize_outlined;
      case ThemePreset.greenLight:
      case ThemePreset.greenDark:
        return Icons.eco_outlined;
      case ThemePreset.blueLight:
      case ThemePreset.blueDark:
        return Icons.water_outlined;
      case ThemePreset.redLight:
      case ThemePreset.redDark:
        return Icons.local_fire_department_outlined;
    }
  }

  static ThemeData _createTheme(Color seedColor, Brightness brightness) {
    // Create the base color scheme from seed color
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );

    // Adjust surface colors with tonal elevation
    final surfaceTint = colorScheme.primary.withOpacity(0.05);
    final elevatedSurface = Color.alphaBlend(surfaceTint, colorScheme.surface);
    
    // Create adjusted color scheme with custom surface colors
    final adjustedColorScheme = colorScheme.copyWith(
      surface: colorScheme.surface,
      surfaceContainerHighest: colorScheme.surfaceContainerHighest.withOpacity(0.9),
      inverseSurface: colorScheme.inverseSurface,
      surfaceTint: colorScheme.primary.withOpacity(0.05),
      // Adjust primary container for better contrast
      primaryContainer: colorScheme.primaryContainer.withOpacity(0.8),
      // Enhance secondary colors
      secondaryContainer: colorScheme.secondaryContainer.withOpacity(0.85),
      // Adjust tertiary colors for better harmony
      tertiaryContainer: colorScheme.tertiaryContainer.withOpacity(0.9),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: adjustedColorScheme,
      brightness: brightness,
      
      // AppBar with surface tinting
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: elevatedSurface,
        elevation: 0,
        scrolledUnderElevation: 2,
        surfaceTintColor: adjustedColorScheme.surfaceTint,
      ),

      // Cards with surface tinting
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        surfaceTintColor: adjustedColorScheme.surfaceTint,
      ),

      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // Filled Button
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: adjustedColorScheme.surfaceContainerHighest.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: adjustedColorScheme.outline.withOpacity(0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: adjustedColorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: adjustedColorScheme.error,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: adjustedColorScheme.error,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),

      // Dialog
      dialogTheme: DialogTheme(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),

      // Bottom Sheet
      bottomSheetTheme: const BottomSheetThemeData(
        showDragHandle: true,
        dragHandleColor: Colors.grey,
        backgroundColor: Colors.transparent,
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // List Tile
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // Drawer
      drawerTheme: const DrawerThemeData(
        elevation: 0,
      ),

      // Navigation Bar
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        height: 80,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // Navigation Rail
      navigationRailTheme: const NavigationRailThemeData(
        elevation: 0,
        labelType: NavigationRailLabelType.all,
      ),

      // Floating Action Button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
