import 'package:cloud_firestore/cloud_firestore.dart';

class Morador {
  final String id; // ID do documento Firestore
  final String nome; // Nome do morador
  final String cpf; // CPF do morador
  final String telefone; // Telefone do morador
  final String email; // Email usado para login no Firebase Authentication
  final String senha; // Senha usada para login no Firebase Authentication
  final String endereco;
  final String numeroCasa; // Número da casa no condomínio
  final String role;
  final String? photoURL; // URL da foto do morador

  // Construtor
  Morador({
    required this.id,
    required this.nome,
    required this.cpf,
    required this.telefone,
    required this.email,
    required this.senha,
    required this.endereco,
    required this.numeroCasa,
    this.role = 'morador',
    this.photoURL,
  });

  // Construtor para criar um Morador a partir de um documento Firestore
  factory Morador.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Morador(
      id: doc.id,
      nome: data['nome'] ?? '',
      cpf: data['cpf'] ?? '',
      telefone: data['telefone'] ?? '',
      email: data['email'] ?? '',
      senha: data['senha'] ?? '',
      endereco: data['endereco'] ?? '',
      numeroCasa: data['numeroCasa'] ?? '',
      role: data['role'] ?? 'morador',
      photoURL: data['photoURL'],
    );
  }

  // Método para converter o Morador em um mapa (JSON) para salvar no Firestore
  Map<String, dynamic> toJson() {
    print('Convertendo Morador para JSON');
    print('photoURL presente? ${photoURL != null ? 'Sim' : 'Não'}');
    if (photoURL != null) {
      print('Tamanho do photoURL: ${photoURL!.length} caracteres');
    }

    final json = {
      'nome': nome,
      'cpf': cpf,
      'telefone': telefone,
      'email': email,
      'senha': senha,
      'endereco': endereco,
      'numeroCasa': numeroCasa,
      'role': role,
      'photoURL': photoURL,
    };

    print('JSON gerado com os seguintes campos:');
    json.forEach((key, value) {
      if (key != 'photoURL' && key != 'senha') {
        print('$key: $value');
      } else if (key == 'photoURL') {
        print('photoURL: ${value != null ? '${value.toString().length} caracteres' : 'null'}');
      } else {
        print('$key: ***');
      }
    });

    return json;
  }
}
