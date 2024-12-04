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
      DocumentSnapshot<Map<String, dynamic>> doc = await _prestadoresCollection
          .doc(id)
          .get() as DocumentSnapshot<Map<String, dynamic>>;

      if (doc.exists) {
        return Prestador.fromDocument(doc);
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
      DocumentSnapshot<Map<String, dynamic>> doc = await _prestadoresCollection
          .doc(id)
          .get() as DocumentSnapshot<Map<String, dynamic>>;

      if (doc.exists) {
        return Prestador.fromDocument(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Erro ao buscar prestador: $e');
    }
  }

  /// **READ** - Buscar todos os prestadores do Firestore
  Future<List<Prestador>> buscarTodosPrestadores() async {
    try {
      final QuerySnapshot querySnapshot = await _prestadoresCollection.get();
      return querySnapshot.docs
          .map((doc) => Prestador.fromDocument(doc as DocumentSnapshot<Map<String, dynamic>>))
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar prestadores: $e');
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
}
