import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/encomenda_model.dart';

class EncomendaController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CollectionReference _encomendasCollection =
      FirebaseFirestore.instance.collection('encomendas');

  // Cadastrar nova encomenda
  Future<void> cadastrarEncomenda(Encomenda encomenda) async {
    try {
      final userRole = await getUserRole();
      if (userRole != 'portaria') {
        throw Exception('Apenas porteiros podem cadastrar encomendas');
      }

      final docRef = _encomendasCollection.doc();
      final novaEncomenda = Encomenda(
        id: docRef.id,
        moradorId: encomenda.moradorId,
        moradorNome: encomenda.moradorNome,
        descricao: encomenda.descricao,
        remetente: encomenda.remetente,
        dataChegada: encomenda.dataChegada,
      );

      await docRef.set(novaEncomenda.toJson());
      await _notificarMorador(novaEncomenda);
    } catch (e) {
      throw Exception('Erro ao cadastrar encomenda: $e');
    }
  }

  // Verificar papel do usuário atual
  Future<String> getUserRole() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return '';

      final userDoc = await _firestore
          .collection('moradores')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) return '';

      final userData = userDoc.data() as Map<String, dynamic>;
      return userData['role'] ?? '';
    } catch (e) {
      print('Erro ao obter role do usuário: $e');
      return '';
    }
  }

  // Buscar encomendas baseado no papel do usuário
  Future<List<Encomenda>> buscarEncomendasPendentes() async {
    try {
      final userRole = await getUserRole();
      final user = _auth.currentUser;
      
      if (user == null) throw Exception('Usuário não autenticado');

      Query query = _encomendasCollection
          .where('retirada', isEqualTo: false)
          .orderBy('dataChegada', descending: true);

      // Se for morador, filtra apenas suas encomendas
      if (userRole == 'morador') {
        query = query.where('moradorId', isEqualTo: user.uid);
      } else if (userRole == 'portaria') {
        // Porteiros veem todas as encomendas
      } else {
        throw Exception('Usuário sem permissão para ver encomendas');
      }

      final querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) => Encomenda.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar encomendas pendentes: $e');
    }
  }

  // Buscar histórico de encomendas do morador
  Future<List<Encomenda>> buscarHistoricoEncomendas() async {
    try {
      final userRole = await getUserRole();
      final user = _auth.currentUser;
      
      if (user == null) throw Exception('Usuário não autenticado');

      Query query = _encomendasCollection
          .orderBy('dataChegada', descending: true);

      // Se for morador, filtra apenas suas encomendas
      if (userRole == 'morador') {
        query = query.where('moradorId', isEqualTo: user.uid);
      } else if (userRole == 'portaria') {
        // Porteiros veem todas as encomendas
      } else {
        throw Exception('Usuário sem permissão para ver encomendas');
      }

      final querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) => Encomenda.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar histórico de encomendas: $e');
    }
  }

  // Marcar encomenda como retirada
  Future<void> marcarComoRetirada(String encomendaId) async {
    try {
      final userRole = await getUserRole();
      final user = _auth.currentUser;
      
      if (user == null) throw Exception('Usuário não autenticado');

      // Busca a encomenda
      final encomendaDoc = await _encomendasCollection.doc(encomendaId).get();
      if (!encomendaDoc.exists) {
        throw Exception('Encomenda não encontrada');
      }

      final encomendaData = encomendaDoc.data() as Map<String, dynamic>;

      // Verifica se o usuário tem permissão
      if (userRole == 'portaria' || 
         (userRole == 'morador' && encomendaData['moradorId'] == user.uid)) {
        
        await _encomendasCollection.doc(encomendaId).update({
          'retirada': true,
          'dataRetirada': FieldValue.serverTimestamp(),
          'retiradaPor': userRole == 'portaria' ? 'portaria' : 'morador',
          'usuarioRetirada': user.uid,
        });

        // Notifica a portaria se foi o morador que retirou
        if (userRole == 'morador') {
          await _notificarPortaria(encomendaData['moradorNome']);
        }
      } else {
        throw Exception('Você não tem permissão para marcar esta encomenda como retirada');
      }
    } catch (e) {
      throw Exception('Erro ao marcar encomenda como retirada: $e');
    }
  }

  // Notificar morador sobre nova encomenda
  Future<void> _notificarMorador(Encomenda encomenda) async {
    try {
      await _firestore
          .collection('notificacoes')
          .doc()
          .set({
            'tipo': 'encomenda',
            'moradorId': encomenda.moradorId,
            'titulo': 'Nova Encomenda',
            'mensagem':
                'Você tem uma nova encomenda de ${encomenda.remetente} na portaria.',
            'data': FieldValue.serverTimestamp(),
            'lida': false,
          });
    } catch (e) {
      print('Erro ao enviar notificação: $e');
    }
  }

  // Notificar a portaria sobre retirada pelo morador
  Future<void> _notificarPortaria(String moradorNome) async {
    try {
      await _firestore
          .collection('notificacoes')
          .doc()
          .set({
            'tipo': 'encomenda_retirada',
            'titulo': 'Encomenda Retirada',
            'mensagem': 'O morador $moradorNome confirmou a retirada da encomenda',
            'data': FieldValue.serverTimestamp(),
            'lida': false,
            'paraPortaria': true,
          });
    } catch (e) {
      print('Erro ao enviar notificação para portaria: $e');
    }
  }
}
