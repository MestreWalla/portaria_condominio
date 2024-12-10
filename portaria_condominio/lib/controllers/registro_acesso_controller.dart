import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/registro_acesso_model.dart';

class RegistroAcessoController {
  final CollectionReference _registrosCollection =
      FirebaseFirestore.instance.collection('registros_acesso');

  // Adiciona um novo registro de acesso
  Future<void> adicionarRegistro(RegistroAcesso registro) async {
    try {
      await _registrosCollection.doc(registro.id).set(registro.toMap());
    } catch (e) {
      print('Erro ao adicionar registro de acesso: $e');
      throw Exception('Falha ao registrar acesso');
    }
  }

  // Busca todos os registros de acesso ordenados por data
  Stream<List<RegistroAcesso>> getRegistrosAcesso() {
    return _registrosCollection
        .orderBy('dataHora', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => RegistroAcesso.fromFirestore(doc))
          .toList();
    });
  }

  // Busca registros de acesso por tipo (visitante ou prestador)
  Stream<List<RegistroAcesso>> getRegistrosPorTipo(String tipo) {
    return _registrosCollection
        .where('visitorType', isEqualTo: tipo)
        .orderBy('dataHora', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => RegistroAcesso.fromFirestore(doc))
          .toList();
    });
  }

  // Busca registros por período
  Stream<List<RegistroAcesso>> getRegistrosPorPeriodo(
      DateTime inicio, DateTime fim) {
    return _registrosCollection
        .where('dataHora',
            isGreaterThanOrEqualTo: inicio.toIso8601String(),
            isLessThanOrEqualTo: fim.toIso8601String())
        .orderBy('dataHora', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => RegistroAcesso.fromFirestore(doc))
          .toList();
    });
  }
}
