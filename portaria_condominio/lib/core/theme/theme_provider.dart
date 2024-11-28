import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'themes/app_theme.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'app_theme';
  final SharedPreferences _prefs;
  ThemePreset _currentPreset;

  ThemeProvider(this._prefs) : _currentPreset = ThemePreset.defaultLight {
    _loadTheme();
  }

  ThemePreset get currentPreset => _currentPreset;
  ThemeData get currentTheme => AppTheme.getThemeByPreset(_currentPreset);

  void _loadTheme() {
    final savedTheme = _prefs.getString(_themeKey);
    if (savedTheme != null) {
      _currentPreset = ThemePreset.values.firstWhere(
        (preset) => preset.toString() == savedTheme,
        orElse: () => ThemePreset.defaultLight,
      );
      notifyListeners();
    }
  }

  Future<void> setThemePreset(ThemePreset preset) async {
    if (_currentPreset != preset) {
      await _prefs.setString(_themeKey, preset.toString());
      _currentPreset = preset;
      notifyListeners();
    }
  }
}
