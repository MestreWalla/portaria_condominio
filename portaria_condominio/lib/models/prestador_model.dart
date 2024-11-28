import 'package:cloud_firestore/cloud_firestore.dart';

class Prestador {
  final String id; // ID do documento no Firestore
  final String nome; // Nome do prestador
  final String cpf; // CPF do prestador
  final String empresa; // Empresa associada
  final String telefone; // Telefone do prestador
  final String email; // Email usado para login no Firebase Authentication
  final String senha; // Senha usada para login no Firebase Authentication
  final bool liberacaoCadastro; // Indica se a entrada foi liberada
  final String role;
  final String? photoURL; // Adicionado campo para foto do prestador

  // Construtor
  Prestador({
    required this.id,
    required this.nome,
    required this.cpf,
    required this.empresa,
    required this.telefone,
    required this.email,
    required this.senha,
    required this.liberacaoCadastro,
    this.role = 'prestador',
    this.photoURL, // Adicionado ao construtor
  });

  // Construtor para criar um Prestador a partir de um documento Firestore
  factory Prestador.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Prestador(
      id: doc.id,
      nome: data['nome'] ?? '',
      cpf: data['cpf'] ?? '',
      empresa: data['empresa'] ?? '',
      telefone: data['telefone'] ?? '',
      email: data['email'] ?? '',
      senha: data['senha'] ?? '',
      liberacaoCadastro: data['liberacaoCadastro'] ?? false,
      role: data['role'] ?? 'prestador',
      photoURL: data['photoURL'], // Adicionado ao factory
    );
  }

  // Método para converter um Prestador em JSON para salvar no Firestore
  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'cpf': cpf,
      'empresa': empresa,
      'telefone': telefone,
      'email': email,
      'senha': senha,
      'liberacaoCadastro': liberacaoCadastro,
      'role': role,
      'photoURL': photoURL, // Adicionado ao toJson
    };
  }
}
