import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/prestador_model.dart';
import '../../localizations/app_localizations.dart';
import 'dart:convert';

class QrCodeView extends StatelessWidget {
  final Prestador prestador;

  const QrCodeView({
    super.key,
    required this.prestador,
  });

  String _gerarCodigoAcesso() {
    final Map<String, dynamic> dadosAcesso = {
      'id': prestador.id,
      'nome': prestador.nome,
      'cpf': prestador.cpf,
      'empresa': prestador.empresa,
      'startDate': prestador.startDate,
      'startTime': prestador.startTime,
      'endDate': prestador.endDate,
      'endTime': prestador.endTime,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    return base64Encode(utf8.encode(json.encode(dadosAcesso)));
  }

  @override
  Widget build(BuildContext context) {
    final codigoAcesso = _gerarCodigoAcesso();
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('qr_code_title')),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Center(
              child: QrImageView(
                data: codigoAcesso,
                version: QrVersions.auto,
                size: 320,
                gapless: false,
                embeddedImage: const AssetImage('assets/icon/app_icon.png'),
                embeddedImageStyle: const QrEmbeddedImageStyle(
                  size: Size(80, 80),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${localizations.translate('service_provider')}: ${prestador.nome}',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${localizations.translate('company')}: ${prestador.empresa}',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${localizations.translate('expected_date')}: ${prestador.startDate}',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${localizations.translate('expected_time')}: ${prestador.startTime}',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${localizations.translate('end_date')}: ${prestador.endDate}',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${localizations.translate('end_time')}: ${prestador.endTime}',
                    style: theme.textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
