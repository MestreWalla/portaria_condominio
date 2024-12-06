import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../models/prestador_model.dart';
import '../../../localizations/app_localizations.dart';
import '../../../utils/communication_utils.dart';
import '../../chat/chat_view.dart';
import '../../qr_code/qr_code_view.dart';

class PrestadorActionButtons extends StatelessWidget {
  final Prestador prestador;
  final bool isLoading;
  final Function() onAllowEntry;
  final Function() onRevokeEntry;
  final Function() onEdit;
  final Function() onDelete;

  const PrestadorActionButtons({
    super.key,
    required this.prestador,
    required this.isLoading,
    required this.onAllowEntry,
    required this.onRevokeEntry,
    required this.onEdit,
    required this.onDelete,
  });

  Widget _buildActionButton(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    if (!prestador.liberacaoEntrada) {
      return _buildAllowEntryButton(context);
    } else {
      return _buildRevokeEntryButton(context);
    }
  }

  Widget _buildAllowEntryButton(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    
    return SizedBox(
      height: 40,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          onPressed: isLoading ? null : onAllowEntry,
          icon: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.check_circle),
          label: Text(localizations.translate('allow_entry')),
        ),
      ),
    );
  }

  Widget _buildRevokeEntryButton(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    
    return SizedBox(
      height: 40,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          onPressed: isLoading ? null : onRevokeEntry,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              else
                const Icon(Icons.cancel),
              const SizedBox(width: 8),
              Text(localizations.translate('revoke_entry')),
              const SizedBox(width: 8),
              Container(
                height: 24,
                width: 1,
                color: Colors.white.withOpacity(0.5),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: isLoading
                  ? null
                  : () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => QrCodeView(prestador: prestador),
                    ),
                  ),
                child: const Icon(Icons.qr_code),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommunicationButtons(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        IconButton(
          onPressed: isLoading
            ? null
            : () => CommunicationUtils.makePhoneCall(prestador.telefone),
          icon: const Icon(Icons.phone),
          color: colorScheme.primary,
          tooltip: localizations.translate('call'),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: isLoading
            ? null
            : () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatView(
                    receiverId: prestador.id,
                    receiverName: prestador.nome,
                  ),
                ),
              ),
          icon: const Icon(Icons.message),
          color: colorScheme.primary,
          tooltip: localizations.translate('message'),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: isLoading
            ? null
            : () => CommunicationUtils.openWhatsApp(prestador.telefone),
          icon: const Icon(FontAwesomeIcons.whatsapp),
          color: colorScheme.primary,
          tooltip: localizations.translate('whatsapp'),
        ),
      ],
    );
  }

  Widget _buildManagementButtons(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        IconButton(
          onPressed: isLoading ? null : onEdit,
          icon: const Icon(Icons.edit),
          color: colorScheme.primary,
          tooltip: localizations.translate('edit'),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: isLoading ? null : onDelete,
          icon: const Icon(Icons.delete),
          color: colorScheme.error,
          tooltip: localizations.translate('delete'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _buildActionButton(context),
              const SizedBox(width: 16),
              _buildCommunicationButtons(context),
              const SizedBox(width: 16),
              _buildManagementButtons(context),
            ],
          ),
        ),
      ],
    );
  }
}
