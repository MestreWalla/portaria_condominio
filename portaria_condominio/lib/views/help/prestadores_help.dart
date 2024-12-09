import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../localizations/app_localizations.dart';

class PrestadoresHelp extends StatelessWidget {
  const PrestadoresHelp({super.key});

  Widget _buildTutorialItem(IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTutorialDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: Divider(height: 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.help_outline,
            color: colorScheme.primary,
            size: 28,
          ),
          const SizedBox(width: 12),
          Text(
            localizations.translate('how_to_use'),
            style: TextStyle(
              color: colorScheme.primary,
              fontSize: 20,
            ),
          ),
        ],
      ),
      content: Container(
        width: double.maxFinite,
        constraints: const BoxConstraints(maxHeight: 500),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                localizations.translate('providers_management'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildTutorialItem(
                Icons.add,
                localizations.translate('add_provider_tutorial'),
                colorScheme.primary,
              ),
              _buildTutorialDivider(),
              _buildTutorialItem(
                Icons.check_circle,
                localizations.translate('allow_entry_tutorial'),
                Colors.green,
              ),
              _buildTutorialDivider(),
              _buildTutorialItem(
                Icons.cancel,
                localizations.translate('revoke_entry_tutorial'),
                Colors.orange,
              ),
              _buildTutorialDivider(),
              _buildTutorialItem(
                Icons.qr_code,
                localizations.translate('qr_code_tutorial'),
                colorScheme.primary,
              ),
              _buildTutorialDivider(),
              Text(
                localizations.translate('communication'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildTutorialItem(
                Icons.phone,
                localizations.translate('call_tutorial'),
                colorScheme.primary,
              ),
              _buildTutorialDivider(),
              _buildTutorialItem(
                Icons.message,
                localizations.translate('message_tutorial'),
                colorScheme.primary,
              ),
              _buildTutorialDivider(),
              _buildTutorialItem(
                FontAwesomeIcons.whatsapp,
                localizations.translate('whatsapp_tutorial'),
                colorScheme.primary,
              ),
              _buildTutorialDivider(),
              Text(
                localizations.translate('management'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildTutorialItem(
                Icons.edit,
                localizations.translate('edit_tutorial'),
                colorScheme.primary,
              ),
              _buildTutorialDivider(),
              _buildTutorialItem(
                Icons.delete,
                localizations.translate('delete_tutorial'),
                Colors.red,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        localizations.translate('scroll_hint'),
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
