import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/themes/app_theme.dart';
import '../../controllers/configuracoes_controller.dart';
import '../../localizations/app_localizations.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../routes/app_routes.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('SettingsView: Building...');
    final colorScheme = Theme.of(context).colorScheme;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final configController = Provider.of<ConfiguracoesController>(context);
    final localizations = AppLocalizations.of(context);

    // Organiza os temas por categoria
    final themesByCategory = <ThemeCategory, List<ThemePreset>>{};
    for (final category in ThemeCategory.values) {
      themesByCategory[category] = ThemePreset.values
          .where((preset) => AppTheme.getThemeCategory(preset) == category)
          .toList();
    }

    // Lista de idiomas suportados
    final supportedLanguages = [
      {'code': 'pt', 'name': 'Português', 'nativeName': 'Português'},
      {'code': 'en', 'name': 'English', 'nativeName': 'English'},
      {'code': 'ar', 'name': 'Arabic', 'nativeName': 'العربية'},
      {'code': 'zh', 'name': 'Chinese', 'nativeName': '中文'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('settings')),
      ),
      body: ListView(
        children: [
          // Seção de Idioma
          ExpansionTile(
            leading: const Icon(Icons.language),
            title: Text(localizations.translate('language')),
            children: [
              for (final language in supportedLanguages)
                RadioListTile<String>(
                  title: Text(language['nativeName']!),
                  subtitle: Text(language['name']!),
                  value: language['code']!,
                  groupValue: configController.locale.languageCode,
                  onChanged: (value) {
                    if (value != null) configController.changeLanguage(value);
                  },
                ),
            ],
          ),

          const Divider(),

          // Seção de Temas
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              localizations.translate('appearance'),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Lista de temas por categoria
          for (final category in ThemeCategory.values) ...[
            ExpansionTile(
              leading: Icon(
                AppTheme.getThemeCategoryIcon(category),
                color: colorScheme.primary,
              ),
              title: Text(AppTheme.getThemeCategoryName(category)),
              children: [
                for (final preset in themesByCategory[category]!)
                  ListTile(
                    leading: Icon(
                      AppTheme.getThemeIcon(preset),
                      color: preset == themeProvider.currentPreset
                          ? colorScheme.primary
                          : null,
                    ),
                    title: Text(AppTheme.getThemeName(preset)),
                    trailing: preset == themeProvider.currentPreset
                        ? Icon(
                            Icons.check_circle,
                            color: colorScheme.primary,
                          )
                        : null,
                    selected: preset == themeProvider.currentPreset,
                    onTap: () => themeProvider.setThemePreset(preset),
                  ),
              ],
            ),
          ],

          const Divider(),

          // Botão para restaurar configurações padrão
          ListTile(
            leading: Icon(Icons.restore, color: colorScheme.primary),
            title: Text(localizations.translate('restore_defaults')),
            onTap: () {
              configController.resetToDefaults();
              themeProvider.setThemePreset(ThemePreset.defaultLight);
            },
          ),

          const Divider(),

          // Botão de Logout
          ListTile(
            leading: Icon(Icons.logout, color: colorScheme.error),
            title: Text(
              localizations.translate('logout'),
              style: TextStyle(
                color: colorScheme.error,
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text(localizations.translate('logout_confirmation')),
                    content: Text(localizations.translate('logout_message')),
                    actions: <Widget>[
                      TextButton(
                        child: Text(localizations.translate('cancel')),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      TextButton(
                        child: Text(
                          localizations.translate('logout'),
                          style: TextStyle(color: colorScheme.error),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            AppRoutes.login,
                            (route) => false,
                          );
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),

          const SizedBox(height: 16), // Espaço adicional no final da lista
        ],
      ),
    );
  }
}
