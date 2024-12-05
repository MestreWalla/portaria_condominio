import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/prestador_model.dart';

class PrestadorController {
  // Referência à coleção 'prestadores' no Firestore
  final CollectionReference _prestadoresCollection =
      FirebaseFirestore.instance.collection('prestadores');

  /// **CREATE** - Adicionar um novo prestador no Firestore
  Future<void> criarPrestador(Prestador prestador) async {
    try {
      await _prestadoresCollection.add(prestador.toJson());
    } catch (e) {
      throw Exception('Erro ao criar prestador: $e');
    }
  }

  Future<void> criarSolicitacao(Prestador prestador) async {
    final CollectionReference solicitacoesCollection =
        FirebaseFirestore.instance.collection('solicitacoes');

    try {
      // Criar uma solicitação com status "pendente"
      await solicitacoesCollection.add({
        'nome': prestador.nome,
        'cpf': prestador.cpf,
        'empresa': prestador.empresa,
        'telefone': prestador.telefone,
        'email': prestador.email,
        'senha': prestador.senha,
        'liberacaoCadastro': prestador.liberacaoCadastro,
        'role': prestador.role,
      });
    } catch (e) {
      throw Exception('Erro ao criar solicitação de acesso: $e');
    }
  }

  Future<List<Map<String, dynamic>>> listarSolicitacoesPendentes() async {
    final CollectionReference solicitacoesCollection =
        FirebaseFirestore.instance.collection('solicitacoes');

    try {
      QuerySnapshot<Object?> snapshot = await solicitacoesCollection
          .where('liberacaoCadastro', isEqualTo: 'false')
          .get();

      // Retorna uma lista de mapas contendo as solicitações
      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'nome': doc['nome'],
          'cpf': doc['cpf'],
          'empresa': doc['empresa'],
          'telefone': doc['telefone'],
          'email': doc['email'],
          'senha': doc['senha'],
          'liberacaoCadastro': doc['liberacaoCadastro'],
          'role': doc['role'],
        };
      }).toList();
    } catch (e) {
      throw Exception('Erro ao listar solicitações pendentes: $e');
    }
  }

  Future<void> avaliarSolicitacao(String solicitacaoId, String status,
      {String? portariaId}) async {
    final CollectionReference solicitacoesCollection =
        FirebaseFirestore.instance.collection('solicitacoes');

    try {
      // Atualizar o status da solicitação (aprovado ou rejeitado)
      await solicitacoesCollection.doc(solicitacaoId).update({
        'liberacaoCadastro': status == 'aprovado' ? true : false,
        'portariaId': portariaId, // ID da portaria que avaliou (opcional)
      });

      // Se aprovado, criar o prestador na coleção 'prestadores'
      if (status == 'aprovado') {
        DocumentSnapshot<Object?> solicitacao =
            await solicitacoesCollection.doc(solicitacaoId).get();

        final prestador = Prestador(
          id: '',
          nome: solicitacao['nome'],
          cpf: solicitacao['cpf'],
          empresa: solicitacao['empresa'],
          telefone: solicitacao['telefone'],
          email: solicitacao['email'],
          senha: solicitacao['senha'],
          liberacaoCadastro: true,
          role: solicitacao['role'],
        );

        await criarPrestador(prestador);
      }
    } catch (e) {
      throw Exception('Erro ao avaliar solicitação: $e');
    }
  }

  /// **READ** - Buscar um prestador pelo ID
  Future<Prestador?> buscarPrestadorPorId(String id) async {
    try {
      final doc = await _prestadoresCollection.doc(id).get();
      if (doc.exists) {
        return Prestador.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Erro ao buscar prestador: $e');
      return null;
    }
  }

  /// **READ** - Buscar um prestador por critérios
  Future<Prestador?> buscarPrestador(String id) async {
    try {
      final doc = await _prestadoresCollection.doc(id).get();
      if (doc.exists) {
        return Prestador.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Erro ao buscar prestador: $e');
    }
  }

  /// **READ** - Buscar todos os prestadores do Firestore
  Future<List<Prestador>> buscarTodosPrestadores() async {
    try {
      final querySnapshot = await _prestadoresCollection.get();
      return querySnapshot.docs
          .map((doc) => Prestador.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar prestadores: $e');
    }
  }

  Future<List<Prestador>> buscarPrestadoresPorNome(String nome) async {
    try {
      final querySnapshot = await _prestadoresCollection
          .where('nome', isGreaterThanOrEqualTo: nome)
          .where('nome', isLessThanOrEqualTo: nome + '\uf8ff')
          .get();
      return querySnapshot.docs
          .map((doc) => Prestador.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Erro ao buscar prestadores por nome: $e');
      return [];
    }
  }

  Future<Prestador?> buscarPrestadorPorEmail(String email) async {
    try {
      final querySnapshot = await _prestadoresCollection
          .where('email', isEqualTo: email)
          .get();
      if (querySnapshot.docs.isNotEmpty) {
        return Prestador.fromFirestore(querySnapshot.docs.first);
      }
      return null;
    } catch (e) {
      print('Erro ao buscar prestador por email: $e');
      return null;
    }
  }

  Future<Prestador?> buscarPrestadorPorCpf(String cpf) async {
    try {
      final querySnapshot = await _prestadoresCollection
          .where('cpf', isEqualTo: cpf)
          .get();
      if (querySnapshot.docs.isNotEmpty) {
        return Prestador.fromFirestore(querySnapshot.docs.first);
      }
      return null;
    } catch (e) {
      print('Erro ao buscar prestador por CPF: $e');
      return null;
    }
  }

  /// **UPDATE** - Atualizar um prestador existente no Firestore
  Future<void> editarPrestador(Prestador prestador) async {
    try {
      await _prestadoresCollection.doc(prestador.id).update({
        'nome': prestador.nome,
        'cpf': prestador.cpf,
        'empresa': prestador.empresa,
        'telefone': prestador.telefone,
        'email': prestador.email,
        'senha': prestador.senha,
        'liberacaoCadastro': prestador.liberacaoCadastro,
        'role': prestador.role,
      });
    } catch (e) {
      throw Exception('Erro ao atualizar prestador: $e');
    }
  }

  /// **UPDATE** - Atualizar a foto do prestador
  Future<void> atualizarFotoPrestador(String id, String fotoBase64) async {
    try {
      print('Tentando atualizar foto do prestador: $id');
      print('Tamanho da foto em base64: ${fotoBase64.length} caracteres');
      
      await _prestadoresCollection.doc(id).update({
        'photoURL': fotoBase64,
      });
      
      // Verifica se a foto foi salva corretamente
      final docSnapshot = await _prestadoresCollection.doc(id).get();
      final data = docSnapshot.data() as Map<String, dynamic>?;
      final savedPhotoURL = data?['photoURL'] as String?;
      
      if (savedPhotoURL == null) {
        print('ERRO: Foto não foi salva no banco');
        throw Exception('Foto não foi salva no banco');
      } else if (savedPhotoURL.length != fotoBase64.length) {
        print('ERRO: Foto salva com tamanho diferente');
        print('Tamanho original: ${fotoBase64.length}');
        print('Tamanho salvo: ${savedPhotoURL.length}');
        throw Exception('Foto salva com tamanho diferente');
      } else {
        print('Foto salva com sucesso!');
      }
    } catch (e) {
      print('ERRO ao atualizar foto do prestador: $e');
      throw Exception('Erro ao atualizar foto do prestador: $e');
    }
  }

  /// **DELETE** - Remover um prestador do Firestore
  Future<void> excluirPrestador(String prestadorId) async {
    try {
      await _prestadoresCollection.doc(prestadorId).delete();
    } catch (e) {
      throw Exception('Erro ao excluir prestador: $e');
    }
  }

  // Liberar entrada do prestador
  Future<void> liberarEntrada(String prestadorId) async {
    try {
      final prestadorRef = _prestadoresCollection.doc(prestadorId);
      await prestadorRef.update({
        'liberacaoEntrada': true,
        'status': 'em_andamento',
      });
    } catch (e) {
      throw Exception('Erro ao liberar entrada: $e');
    }
  }

  // Revogar entrada do prestador
  Future<void> revogarEntrada(String prestadorId) async {
    try {
      final prestadorRef = _prestadoresCollection.doc(prestadorId);
      await prestadorRef.update({
        'liberacaoEntrada': false,
        'status': 'agendado',
      });
    } catch (e) {
      throw Exception('Erro ao revogar entrada: $e');
    }
  }

  // Finalizar visita do prestador
  Future<void> finalizarVisita(String prestadorId) async {
    try {
      final prestadorRef = _prestadoresCollection.doc(prestadorId);
      await prestadorRef.update({
        'liberacaoEntrada': false,
        'status': 'finalizado',
      });
    } catch (e) {
      throw Exception('Erro ao finalizar visita: $e');
    }
  }

  // Processar QR Code do prestador
  Future<bool> processarQRCodePrestador(String prestadorId) async {
    try {
      final prestadorDoc = await _prestadoresCollection.doc(prestadorId).get();
      
      if (!prestadorDoc.exists) {
        return false;
      }

      final prestador = Prestador.fromFirestore(prestadorDoc);
      
      // Verifica se a visita está agendada para hoje
      final hoje = DateTime.now();
      final dataVisita = _parseDate(prestador.startDate);
      
      if (dataVisita.year == hoje.year && 
          dataVisita.month == hoje.month && 
          dataVisita.day == hoje.day) {
        await liberarEntrada(prestadorId);
        return true;
      }
      
      return false;
    } catch (e) {
      print('Erro ao processar QR Code: $e');
      return false;
    }
  }

  DateTime _parseDate(String date) {
    final parts = date.split('/');
    return DateTime(
      int.parse(parts[2]), // ano
      int.parse(parts[1]), // mês
      int.parse(parts[0]), // dia
    );
  }
}
