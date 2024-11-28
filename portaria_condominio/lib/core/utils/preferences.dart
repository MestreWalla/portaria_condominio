import 'package:shared_preferences/shared_preferences.dart';

class Preferences {
  static const _themePresetKey = 'theme_preset';
  static const _localeKey = 'locale';
  static const _emailKey = 'email';
  static const _rememberEmailKey = 'rememberEmail';

  /// **Salvar Tema**
  static Future<void> saveThemePreset(int presetIndex) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themePresetKey, presetIndex);
  }

  /// **Carregar Tema**
  static Future<int> loadThemePreset() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_themePresetKey) ?? 0; // Default to first preset
  }

  /// **Salvar Idioma**
  static Future<void> saveLocale(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, languageCode);
  }

  /// **Carregar Idioma**
  static Future<String> loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_localeKey) ?? 'pt'; // Default to Portuguese
  }

  /// **Salvar Email**
  static Future<void> saveEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_emailKey, email);
  }

  /// **Carregar Email**
  static Future<String?> loadEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey);
  }

  /// **Salvar Preferência de Lembrar Email**
  static Future<void> saveRememberEmail(bool remember) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberEmailKey, remember);
  }

  /// **Carregar Preferência de Lembrar Email**
  static Future<bool> loadRememberEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_rememberEmailKey) ?? false;
  }

  /// **Limpar Preferências**
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
