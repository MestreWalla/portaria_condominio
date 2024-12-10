import 'package:cloud_firestore/cloud_firestore.dart';

class RegistroAcesso {
  final String id;
  final String visitorId;      // ID do visitante ou prestador
  final String visitorName;    // Nome do visitante ou prestador
  final String visitorType;    // 'visitante' ou 'prestador'
  final String scannedBy;      // ID do usuário que escaneou
  final String scannedByName;  // Nome do usuário que escaneou
  final String apartamento;    // Número do apartamento (se for visitante)
  final String empresa;        // Nome da empresa (se for prestador)
  final DateTime dataHora;     // Data e hora do acesso

  RegistroAcesso({
    required this.id,
    required this.visitorId,
    required this.visitorName,
    required this.visitorType,
    required this.scannedBy,
    required this.scannedByName,
    required this.dataHora,
    this.apartamento = '',
    this.empresa = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'visitorId': visitorId,
      'visitorName': visitorName,
      'visitorType': visitorType,
      'scannedBy': scannedBy,
      'scannedByName': scannedByName,
      'apartamento': apartamento,
      'empresa': empresa,
      'dataHora': dataHora.toIso8601String(),
    };
  }

  factory RegistroAcesso.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RegistroAcesso(
      id: doc.id,
      visitorId: data['visitorId'] ?? '',
      visitorName: data['visitorName'] ?? '',
      visitorType: data['visitorType'] ?? '',
      scannedBy: data['scannedBy'] ?? '',
      scannedByName: data['scannedByName'] ?? '',
      apartamento: data['apartamento'] ?? '',
      empresa: data['empresa'] ?? '',
      dataHora: DateTime.parse(data['dataHora'] as String),
    );
  }
}
