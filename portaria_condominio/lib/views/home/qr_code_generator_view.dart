// ignore_for_file: use_key_in_widgets

import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/material.dart';
import '../../models/visita_model.dart';
import '../../localizations/app_localizations.dart';
import 'dart:convert';

class QrCodeView extends StatelessWidget {
  final Visita visita;

  const QrCodeView({super.key, required this.visita});

  String _gerarCodigoAcesso() {
    // Cria um mapa com os dados relevantes da visita
    final Map<String, dynamic> dadosAcesso = {
      'id': visita.id,
      'nome': visita.nome,
      'cpf': visita.cpf,
      'casa':
          visita.apartamento, // mantendo o nome do campo por compatibilidade
      'startDate': visita.startDate,
      'startTime': visita.startTime,
      'endDate': visita.endDate,
      'endTime': visita.endTime,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    // Converte o mapa para JSON e depois para base64
    return base64Encode(utf8.encode(json.encode(dadosAcesso)));
  }

  @override
  Widget build(BuildContext context) {
    final codigoAcesso = _gerarCodigoAcesso();
    final localizations = AppLocalizations.of(context);

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
                    '${localizations.translate('visitor')}: ${visita.nome}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${localizations.translate('house_number')}: ${visita.apartamento}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${localizations.translate('expected_date')}: ${visita.startDate}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${localizations.translate('expected_time')}: ${visita.startTime}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${localizations.translate('end_date')}: ${visita.endDate}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${localizations.translate('end_time')}: ${visita.endTime}',
                    style: Theme.of(context).textTheme.bodyLarge,
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
