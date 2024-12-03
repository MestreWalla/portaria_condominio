import 'package:cloud_firestore/cloud_firestore.dart';

class Encomenda {
  final String id;
  final String moradorId;
  final String moradorNome;
  final String descricao;
  final String remetente;
  final DateTime dataChegada;
  final bool retirada;
  final DateTime? dataRetirada;

  Encomenda({
    required this.id,
    required this.moradorId,
    required this.moradorNome,
    required this.descricao,
    required this.remetente,
    required this.dataChegada,
    this.retirada = false,
    this.dataRetirada,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'moradorId': moradorId,
      'moradorNome': moradorNome,
      'descricao': descricao,
      'remetente': remetente,
      'dataChegada': dataChegada,
      'retirada': retirada,
      'dataRetirada': dataRetirada,
    };
  }

  factory Encomenda.fromJson(Map<String, dynamic> json) {
    return Encomenda(
      id: json['id'] ?? '',
      moradorId: json['moradorId'] ?? '',
      moradorNome: json['moradorNome'] ?? '',
      descricao: json['descricao'] ?? '',
      remetente: json['remetente'] ?? '',
      dataChegada: (json['dataChegada'] as Timestamp).toDate(),
      retirada: json['retirada'] ?? false,
      dataRetirada: json['dataRetirada'] != null
          ? (json['dataRetirada'] as Timestamp).toDate()
          : null,
    );
  }
}
