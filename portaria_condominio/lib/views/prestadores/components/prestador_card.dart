import 'package:flutter/material.dart';
import '../../../models/prestador_model.dart';
import '../../../widgets/avatar_widget.dart';
import '../../../localizations/app_localizations.dart';
import 'prestador_action_buttons.dart';

class PrestadorCard extends StatelessWidget {
  final Prestador prestador;
  final bool isLoading;
  final Function() onAllowEntry;
  final Function() onRevokeEntry;
  final Function() onEdit;
  final Function() onDelete;

  const PrestadorCard({
    super.key,
    required this.prestador,
    required this.isLoading,
    required this.onAllowEntry,
    required this.onRevokeEntry,
    required this.onEdit,
    required this.onDelete,
  });

  Widget _buildHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final localizations = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Hero(
                tag: 'avatar_${prestador.id}',
                child: AvatarWidget(
                  photoURL: prestador.photoURL,
                  userName: prestador.nome,
                  radius: 24,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: prestador.liberacaoEntrada ? Colors.green : Colors.orange,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.surface,
                    width: 2,
                  ),
                ),
                child: Icon(
                  prestador.liberacaoEntrada ? Icons.check : Icons.timer,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prestador.nome,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  prestador.empresa,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      prestador.liberacaoEntrada ? Icons.check_circle : Icons.access_time,
                      size: 16,
                      color: prestador.liberacaoEntrada ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      prestador.liberacaoEntrada 
                        ? localizations.translate('entry_allowed')
                        : localizations.translate('scheduled'),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: prestador.liberacaoEntrada ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String text, String label) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(
            context,
            Icons.phone,
            prestador.telefone,
            localizations.translate('phone'),
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            context,
            Icons.email,
            prestador.email,
            localizations.translate('email'),
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            context,
            Icons.badge,
            prestador.cpf,
            localizations.translate('cpf'),
          ),
          const SizedBox(height: 16),
          PrestadorActionButtons(
            prestador: prestador,
            isLoading: isLoading,
            onAllowEntry: onAllowEntry,
            onRevokeEntry: onRevokeEntry,
            onEdit: onEdit,
            onDelete: onDelete,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          _buildBody(context),
        ],
      ),
    );
  }
}
