import '../models/veiculo_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VeiculoController {
  final CollectionReference _veiculosCollection = FirebaseFirestore.instance.collection('veiculos');

  Future<List<Veiculo>> listarVeiculos() async {
    try {
      final querySnapshot = await _veiculosCollection.get();
      return querySnapshot.docs.map((doc) => Veiculo.fromMap(doc.data() as Map<String, dynamic>)).toList();
    } catch (e) {
      print('Error fetching vehicles: $e');
      return [];
    }
  }

  Future<void> cadastrarVeiculo(Veiculo veiculo) async {
    // Simulate saving data to a database or API
    await Future.delayed(const Duration(seconds: 1));
  }

  Future<void> atualizarVeiculo(String placa, Map<String, String> updatedData) async {
    // Simulate updating data in a database or API
    await Future.delayed(const Duration(seconds: 1));
  }

  Future<void> deletarVeiculo(String placa) async {
    // Simulate deleting data from a database or API
    await Future.delayed(const Duration(seconds: 1));
  }
}