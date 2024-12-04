import 'package:flutter/material.dart';
import '../../localizations/app_localizations.dart';
import '../../controllers/veiculo_controller.dart';
import '../../models/veiculo_model.dart';

class CadastroVeiculosView extends StatefulWidget {
  @override
  _CadastroVeiculosViewState createState() => _CadastroVeiculosViewState();
}

class _CadastroVeiculosViewState extends State<CadastroVeiculosView> with TickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _marcaController = TextEditingController();
  final TextEditingController _modeloController = TextEditingController();
  final TextEditingController _placaController = TextEditingController();
  final TextEditingController _corController = TextEditingController();
  final TextEditingController _anoController = TextEditingController();
  final TextEditingController _cpfController = TextEditingController();
  final TextEditingController _proprietarioController = TextEditingController();
  List<Map<String, String>> _veiculosCadastrados = [];
  final VeiculoController _veiculoController = VeiculoController();
  Map<int, AnimationController> _animationControllers = {};
  int? expandedIndex;
  String _tipoProprietario = 'morador'; // Default value

  void _mostrarDialogCadastro() {
    showDialog(
      context: context,
      builder: (context) {
        final localizations = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(localizations.translate('vehicle_registration')),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildTextField(_marcaController,
                      localizations.translate('brand'), Icons.directions_car),
                  _buildTextField(_modeloController,
                      localizations.translate('model'), Icons.directions_car),
                  _buildTextField(
                      _placaController,
                      localizations.translate('license_plate'),
                      Icons.confirmation_number),
                  _buildTextField(_corController,
                      localizations.translate('color'), Icons.color_lens),
                  _buildTextField(_anoController,
                      localizations.translate('year'), Icons.calendar_today),
                  _buildTextField(_cpfController,
                      localizations.translate('cpf'), Icons.badge),
                  _buildTextField(_proprietarioController,
                      localizations.translate('Nome do Proprietário'), Icons.person),
                  DropdownButtonFormField<String>(
                    value: _tipoProprietario,
                    items: [
                      DropdownMenuItem(
                        value: 'morador',
                        child: Text(localizations.translate('resident')),
                      ),
                      DropdownMenuItem(
                        value: 'visitante',
                        child: Text(localizations.translate('visitor')),
                      ),
                      DropdownMenuItem(
                        value: 'prestador',
                        child: Text(localizations.translate('prestador_de_servico')),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _tipoProprietario = value!;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: localizations.translate('Tipo Proprietario'),
                      icon: Icon(Icons.category),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(localizations.translate('cancel')),
            ),
            ElevatedButton(
              onPressed: _submitForm,
              child: Text(localizations.translate('register')),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchVeiculos();
  }

  Future<void> _fetchVeiculos() async {
    try {
      final veiculos = await _veiculoController.listarVeiculos();
      setState(() {
        _veiculosCadastrados = veiculos.map((veiculo) => {
          'marca': veiculo.marca,
          'modelo': veiculo.modelo,
          'placa': veiculo.placa,
          'cor': veiculo.cor,
          'ano': veiculo.ano,
          'cpf': veiculo.cpf,
          'proprietario': veiculo.proprietario,
          'tipo_proprietario': veiculo.tipoProprietario,
        }).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).translate('error_fetching_data'))),
      );
    }
  }

  AnimationController _getAnimationController(int index) {
    if (!_animationControllers.containsKey(index)) {
      _animationControllers[index] = AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      );
    }
    return _animationControllers[index]!;
  }

  void _editVeiculo(Map<String, String> veiculo) {
    _marcaController.text = veiculo['marca']!;
    _modeloController.text = veiculo['modelo']!;
    _placaController.text = veiculo['placa']!;
    _corController.text = veiculo['cor']!;
    _anoController.text = veiculo['ano']!;
    _cpfController.text = veiculo['cpf']!;
    _proprietarioController.text = veiculo['proprietario']!;
    _tipoProprietario = veiculo['tipo_proprietario'] ?? 'morador';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context).translate('edit_vehicle')),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildTextField(_marcaController,
                      AppLocalizations.of(context).translate('brand'), Icons.directions_car),
                  _buildTextField(_modeloController,
                      AppLocalizations.of(context).translate('model'), Icons.directions_car),
                  _buildTextField(
                      _placaController,
                      AppLocalizations.of(context).translate('license_plate'),
                      Icons.confirmation_number),
                  _buildTextField(_corController,
                      AppLocalizations.of(context).translate('color'), Icons.color_lens),
                  _buildTextField(_anoController,
                      AppLocalizations.of(context).translate('year'), Icons.calendar_today),
                  _buildTextField(_cpfController,
                      AppLocalizations.of(context).translate('cpf'), Icons.badge),
                  _buildTextField(_proprietarioController,
                      AppLocalizations.of(context).translate('Nome do Proprietário'), Icons.person),
                  DropdownButtonFormField<String>(
                    value: _tipoProprietario,
                    items: [
                      DropdownMenuItem(
                        value: 'morador',
                        child: Text(AppLocalizations.of(context).translate('resident')),
                      ),
                      DropdownMenuItem(
                        value: 'visitante',
                        child: Text(AppLocalizations.of(context).translate('visitor')),
                      ),
                      DropdownMenuItem(
                        value: 'prestador',
                        child: Text(AppLocalizations.of(context).translate('prestador_de_servico')),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _tipoProprietario = value!;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context).translate('Tipo Proprietario'),
                      icon: Icon(Icons.category),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context).translate('cancel')),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  // Update vehicle in Firestore
                  await _veiculoController.atualizarVeiculo(veiculo['placa']!, {
                    'marca': _marcaController.text,
                    'modelo': _modeloController.text,
                    'placa': _placaController.text,
                    'cor': _corController.text,
                    'ano': _anoController.text,
                    'cpf': _cpfController.text,
                    'proprietario': _proprietarioController.text,
                    'tipo_proprietario': _tipoProprietario,
                  });

                  // Update UI
                  setState(() {
                    int index = _veiculosCadastrados.indexWhere((v) => v['placa'] == veiculo['placa']);
                    if (index != -1) {
                      _veiculosCadastrados[index] = {
                        'marca': _marcaController.text,
                        'modelo': _modeloController.text,
                        'placa': _placaController.text,
                        'cor': _corController.text,
                        'ano': _anoController.text,
                        'cpf': _cpfController.text,
                        'proprietario': _proprietarioController.text,
                        'tipo_proprietario': _tipoProprietario,
                      };
                    }
                  });

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppLocalizations.of(context).translate('vehicle_updated'))),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppLocalizations.of(context).translate('error_updating_vehicle'))),
                  );
                }
              },
              child: Text(AppLocalizations.of(context).translate('save')),
            ),
          ],
        );
      },
    );
  }

  void _deleteVeiculo(Map<String, String> veiculo) async {
    bool? confirmDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).translate('confirm_delete')),
        content: Text(AppLocalizations.of(context).translate('confirm_delete_vehicle')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context).translate('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context).translate('delete')),
          ),
        ],
      ),
    );

    if (confirmDelete == true) {
      try {
        await _veiculoController.deletarVeiculo(veiculo['placa']!);
        setState(() {
          _veiculosCadastrados.removeWhere((v) => v['placa'] == veiculo['placa']);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).translate('vehicle_deleted'))),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).translate('error_deleting_vehicle'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('vehicle_registration')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarDialogCadastro,
        child: Icon(Icons.add),
      ),
      body: ListView.builder(
        itemCount: _veiculosCadastrados.length,
        itemBuilder: (context, index) {
          final veiculo = _veiculosCadastrados[index];
          final isExpanded = index == expandedIndex;

          return AnimatedBuilder(
            animation: _getAnimationController(index),
            builder: (context, child) {
              final controller = _getAnimationController(index);
              final expansionAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(
                  parent: controller,
                  curve: Curves.easeInOut,
                ),
              );

              if (isExpanded) {
                controller.forward();
              } else {
                controller.reverse();
              }

              return Card(
                margin: const EdgeInsets.all(8.0),
                elevation: 8,
                child: Column(
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            expandedIndex = isExpanded ? null : index;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              Icon(
                                Icons.directions_car,
                                size: 40,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${veiculo['marca']} ${veiculo['modelo']}',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      veiculo['placa']!,
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    ClipRect(
                      child: AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child: SizeTransition(
                          sizeFactor: expansionAnimation,
                          child: isExpanded
                              ? Column(
                                  children: [
                                    const Divider(),
                                    Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          _buildInfoRow(
                                            localizations.translate('color'),
                                            veiculo['cor']!,
                                            colorScheme,
                                          ),
                                          _buildInfoRow(
                                            localizations.translate('year'),
                                            veiculo['ano']!,
                                            colorScheme,
                                          ),
                                          _buildInfoRow(
                                            localizations.translate('cpf'),
                                            veiculo['cpf']!,
                                            colorScheme,
                                          ),
                                          _buildInfoRow(
                                            localizations.translate('Nome do Proprietário'),
                                            veiculo['proprietario']!,
                                            colorScheme,
                                          ),
                                          _buildInfoRow(
                                            localizations.translate('tipo_proprietario'),
                                            veiculo['tipo_proprietario']!,
                                            colorScheme,
                                          ),
                                          const SizedBox(height: 16),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              IconButton(
                                                icon: Icon(Icons.edit, color: colorScheme.primary),
                                                onPressed: () => _editVeiculo(veiculo),
                                              ),
                                              IconButton(
                                                icon: Icon(Icons.delete, color: colorScheme.error),
                                                onPressed: () => _deleteVeiculo(veiculo),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                              : const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, ColorScheme colorScheme) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return AppLocalizations.of(context).translate('field_required');
          }
          return null;
        },
      ),
    );
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final veiculo = Veiculo(
        marca: _marcaController.text,
        modelo: _modeloController.text,
        placa: _placaController.text,
        cor: _corController.text,
        ano: _anoController.text,
        cpf: _cpfController.text,
        proprietario: _proprietarioController.text,
        tipoProprietario: _tipoProprietario,
      );

      try {
        await _veiculoController.cadastrarVeiculo(veiculo);
        setState(() {
          _veiculosCadastrados.add(veiculo.toMap());
        });
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).translate('vehicle_registered'))),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).translate('error_registering_vehicle'))),
        );
      }
    }
  }
}
