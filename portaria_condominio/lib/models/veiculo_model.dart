class Veiculo {
  final String marca;
  final String modelo;
  final String placa;
  final String cor;
  final String ano;
  final String cpf;
  final String proprietario;
  final String tipoProprietario;

  Veiculo({
    required this.marca,
    required this.modelo,
    required this.placa,
    required this.cor,
    required this.ano,
    required this.cpf,
    required this.proprietario,
    required this.tipoProprietario,
  });

  factory Veiculo.fromMap(Map<String, dynamic> map) {
    return Veiculo(
      marca: map['marca'] ?? '',
      modelo: map['modelo'] ?? '',
      placa: map['placa'] ?? '',
      cor: map['cor'] ?? '',
      ano: map['ano'] ?? '',
      cpf: map['cpf'] ?? '',
      proprietario: map['proprietario'] ?? '',
      tipoProprietario: map['tipo_proprietario'] ?? 'morador',
    );
  }

  Map<String, String> toMap() {
    return {
      'marca': marca,
      'modelo': modelo,
      'placa': placa,
      'cor': cor,
      'ano': ano,
      'cpf': cpf,
      'proprietario': proprietario,
      'tipo_proprietario': tipoProprietario,
    };
  }
}