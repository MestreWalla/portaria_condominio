import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/visita_model.dart';
import 'package:flutter/foundation.dart'; // Import this line

class VisitaController extends ChangeNotifier { // Modified this line
  final CollectionReference _visitasCollection =
      FirebaseFirestore.instance.collection('visitas');

  /// **CREATE** - Adicionar uma nova visita no Firestore
  Future<void> criarVisita(Visita visita) async {
    try {
      await _visitasCollection.add(visita.toJson());
    } catch (e) {
      throw Exception('Erro ao criar visita: $e');
    }
  }

  /// **READ** - Buscar uma visita pelo ID
  Future<Visita?> buscarVisita(String id) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> doc = await _visitasCollection
          .doc(id)
          .get() as DocumentSnapshot<Map<String, dynamic>>;

      if (doc.exists) {
        return Visita.fromDocument(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Erro ao buscar visita: $e');
    }
  }

  /// **READ** - Buscar todas as visitas
  Future<List<Visita>> buscarTodasVisitas() async {
    try {
      QuerySnapshot<Map<String, dynamic>> snapshot = await _visitasCollection
          .get() as QuerySnapshot<Map<String, dynamic>>;

      return snapshot.docs.map((doc) => Visita.fromDocument(doc)).toList();
    } catch (e) {
      throw Exception('Erro ao buscar visitas: $e');
    }
  }

  /// **UPDATE** - Atualizar os dados de uma visita no Firestore
  Future<void> atualizarVisita(Visita visita) async {
    try {
      await _visitasCollection.doc(visita.id).update(visita.toJson());
    } catch (e) {
      throw Exception('Erro ao atualizar visita: $e');
    }
  }

  /// **DELETE** - Excluir uma visita pelo ID
  Future<void> excluirVisita(String id) async {
    try {
      await _visitasCollection.doc(id).delete();
    } catch (e) {
      throw Exception('Erro ao excluir visita: $e');
    }
  }

  /// **UPDATE** - Liberar entrada de uma visita
  Future<void> liberarEntrada(String id) async {
    try {
      await _visitasCollection.doc(id).update({'liberacaoEntrada': true});
    } catch (e) {
      throw Exception('Erro ao liberar entrada da visita: $e');
    }
  }

  /// **UPDATE** - Revogar entrada de uma visita
  Future<void> revogarEntrada(String id) async {
    try {
      await _visitasCollection.doc(id).update({'liberacaoEntrada': false});
    } catch (e) {
      throw Exception('Erro ao revogar entrada da visita: $e');
    }
  }

  /// **READ** - Buscar visitas por status de liberação
  Future<List<Visita>> buscarVisitasPorLiberacao(bool liberada) async {
    try {
      QuerySnapshot<Map<String, dynamic>> snapshot = await _visitasCollection
          .where('liberacaoEntrada', isEqualTo: liberada)
          .get() as QuerySnapshot<Map<String, dynamic>>;

      return snapshot.docs.map((doc) => Visita.fromDocument(doc)).toList();
    } catch (e) {
      throw Exception('Erro ao buscar visitas por liberação: $e');
    }
  }

  /// **UPDATE** - Processar o QR Code da visita
  Future<bool> processarQRCodeVisita(String qrCode) async {
    try {
      // Decodifica o QR Code para obter o ID da visita
      final visitaId = qrCode.trim();
      
      // Busca a visita no Firestore
      final visitaDoc = await _visitasCollection.doc(visitaId).get();
      
      if (!visitaDoc.exists) {
        return false;
      }

      // Atualiza o status da visita para "liberada"
      await _visitasCollection.doc(visitaId).update({
        'status': 'liberada',
        'dataHoraLiberacao': DateTime.now().toIso8601String(),
      });

      // Notifica os ouvintes sobre a mudança
      // notifyListeners(); // Este método não existe na classe VisitaController
      
      return true;
    } catch (e) {
      print('Erro ao processar QR Code: $e');
      return false;
    }
  }
}
