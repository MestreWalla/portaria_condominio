import 'package:cloud_firestore/cloud_firestore.dart';

class Prestador {
  final String id; // ID do documento no Firestore
  final String nome; // Nome do prestador
  final String cpf; // CPF do prestador
  final String empresa; // Empresa associada
  final String telefone; // Telefone do prestador
  final String email; // Email usado para login no Firebase Authentication
  final String senha; // Senha usada para login no Firebase Authentication
  final bool? liberacaoCadastro; // Indica se a entrada foi liberada
  final String role;
  final String? photoURL; // Adicionado campo para foto do prestador
  bool liberacaoEntrada; // Novo campo
  String status; // Novo campo
  String startDate; // Novo campo
  String startTime; // Novo campo
  String endDate; // Novo campo
  String endTime; // Novo campo
  String observacoes; // Novo campo
  final String dataRegistro; // Novo campo

  // Construtor
  Prestador({
    required this.id,
    required this.nome,
    required this.cpf,
    required this.empresa,
    required this.telefone,
    required this.email,
    required this.senha,
    this.liberacaoCadastro,
    this.role = 'prestador',
    this.photoURL,
    this.liberacaoEntrada = false, // Valor padrão
    this.status = 'agendado', // Valor padrão
    this.startDate = '',
    this.startTime = '',
    this.endDate = '',
    this.endTime = '',
    this.observacoes = '',
    String? dataRegistro,
  }) : dataRegistro = dataRegistro ?? DateTime.now().toIso8601String();

  // Construtor para criar um Prestador a partir de um documento Firestore
  factory Prestador.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Prestador(
      id: doc.id,
      nome: data['nome'] ?? '',
      cpf: data['cpf'] ?? '',
      empresa: data['empresa'] ?? '',
      telefone: data['telefone'] ?? '',
      email: data['email'] ?? '',
      senha: data['senha'] ?? '',
      liberacaoCadastro: data['liberacaoCadastro'],
      role: data['role'] ?? 'prestador',
      photoURL: data['photoURL'],
      liberacaoEntrada: data['liberacaoEntrada'] ?? false,
      status: data['status'] ?? 'agendado',
      startDate: data['startDate'] ?? '',
      startTime: data['startTime'] ?? '',
      endDate: data['endDate'] ?? '',
      endTime: data['endTime'] ?? '',
      observacoes: data['observacoes'] ?? '',
      dataRegistro: data['dataRegistro'],
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
      'photoURL': photoURL,
      'liberacaoEntrada': liberacaoEntrada,
      'status': status,
      'startDate': startDate,
      'startTime': startTime,
      'endDate': endDate,
      'endTime': endTime,
      'observacoes': observacoes,
      'dataRegistro': dataRegistro,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'cpf': cpf,
      'empresa': empresa,
      'telefone': telefone,
      'email': email,
      'photoURL': photoURL,
      'liberacaoEntrada': liberacaoEntrada,
      'status': status,
      'startDate': startDate,
      'startTime': startTime,
      'endDate': endDate,
      'endTime': endTime,
      'observacoes': observacoes,
      'dataRegistro': dataRegistro,
    };
  }

  factory Prestador.fromMap(Map<String, dynamic> map) {
    return Prestador(
      id: map['id'] ?? '',
      nome: map['nome'] ?? '',
      cpf: map['cpf'] ?? '',
      empresa: map['empresa'] ?? '',
      telefone: map['telefone'] ?? '',
      email: map['email'] ?? '',
      photoURL: map['photoURL'],
      liberacaoEntrada: map['liberacaoEntrada'] ?? false,
      status: map['status'] ?? 'agendado',
      startDate: map['startDate'] ?? '',
      startTime: map['startTime'] ?? '',
      endDate: map['endDate'] ?? '',
      endTime: map['endTime'] ?? '',
      observacoes: map['observacoes'] ?? '',
      senha: '',
      liberacaoCadastro: null,
      dataRegistro: map['dataRegistro'],
    );
  }
}
