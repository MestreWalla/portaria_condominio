import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../localizations/app_localizations.dart';
import '../../controllers/veiculo_controller.dart';
import '../../models/veiculo_model.dart';

class CadastroVeiculosView extends StatefulWidget {
  const CadastroVeiculosView({super.key});

  @override
  _CadastroVeiculosViewState createState() => _CadastroVeiculosViewState();
}

class _CadastroVeiculosViewState extends State<CadastroVeiculosView> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _marcaController = TextEditingController();
  final TextEditingController _modeloController = TextEditingController();
  final TextEditingController _placaController = TextEditingController();
  final TextEditingController _corController = TextEditingController();
  final TextEditingController _anoController = TextEditingController();
  final TextEditingController _cpfController = TextEditingController();
  final TextEditingController _proprietarioController = TextEditingController();
  List<Map<String, String>> _veiculosCadastrados = [];
  List<Map<String, dynamic>> _moradores = [];
  List<Map<String, dynamic>> _prestadores = [];
  final VeiculoController _veiculoController = VeiculoController();
  final Map<int, AnimationController> _animationControllers = {};
  int? expandedIndex;
  String _tipoProprietario = 'morador';
  String? _selectedProprietarioId;

  void _mostrarDialogCadastro() {
    showDialog(
      context: context,
      builder: (context) {
        final localizations = AppLocalizations.of(context);
        return Dialog(
          insetPadding: EdgeInsets.zero,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.directions_car,
                      size: 28,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      localizations.translate('vehicle_registration'),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildProprietarioDropdown(),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              _marcaController,
                              localizations.translate('marca'),
                              Icons.directions_car,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              _modeloController,
                              localizations.translate('modelo'),
                              Icons.car_repair,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              _placaController,
                              localizations.translate('placa'),
                              Icons.pin,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              _corController,
                              localizations.translate('cor'),
                              Icons.color_lens,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildYearDropdown(),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(localizations.translate('cancel')),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: _submitForm,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                            child: Text(localizations.translate('register')),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildYearDropdown() {
    final currentYear = DateTime.now().year;
    final years = List.generate(50, (index) => (currentYear - index).toString());

    return DropdownButtonFormField<String>(
      value: _anoController.text.isEmpty ? currentYear.toString() : _anoController.text,
      items: years.map((year) {
        return DropdownMenuItem<String>(
          value: year,
          child: Text(year),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _anoController.text = value!;
        });
      },
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context).translate('year'),
        prefixIcon: const Icon(Icons.calendar_today),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return AppLocalizations.of(context).translate('field_required');
        }
        return null;
      },
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return AppLocalizations.of(context).translate('field_required');
        }
        return null;
      },
    );
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
        return Dialog(
          insetPadding: EdgeInsets.zero,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.directions_car,
                      size: 28,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      AppLocalizations.of(context).translate('edit_vehicle'),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
                          labelText: AppLocalizations.of(context).translate('owner_type'),
                          prefixIcon: const Icon(Icons.category),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildProprietarioDropdown(),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              _marcaController,
                              AppLocalizations.of(context).translate('marca'),
                              Icons.directions_car,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              _modeloController,
                              AppLocalizations.of(context).translate('modelo'),
                              Icons.car_repair,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              _placaController,
                              AppLocalizations.of(context).translate('placa'),
                              Icons.pin,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              _corController,
                              AppLocalizations.of(context).translate('cor'),
                              Icons.color_lens,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildYearDropdown(),
                      const SizedBox(height: 16),
                      _buildTextField(
                        _proprietarioController,
                        AppLocalizations.of(context).translate('Nome do Proprietário'),
                        Icons.person,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(AppLocalizations.of(context).translate('cancel')),
                          ),
                          const SizedBox(width: 16),
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
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                            child: Text(AppLocalizations.of(context).translate('save')),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
            child: Text(
              AppLocalizations.of(context).translate('delete'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
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

  Future<void> _carregarVeiculos() async {
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

  Future<void> _carregarProprietarios() async {
    try {
      // Carregar moradores e prestadores do Firestore
      final moradoresSnapshot = await FirebaseFirestore.instance.collection('moradores').get();
      final prestadoresSnapshot = await FirebaseFirestore.instance.collection('prestadores').get();

      setState(() {
        _moradores = moradoresSnapshot.docs.map((doc) => {
          'id': doc.id,
          'nome': doc['nome'],
          'cpf': doc['cpf'],
          'tipo': 'morador'
        }).toList();

        _prestadores = prestadoresSnapshot.docs.map((doc) => {
          'id': doc.id,
          'nome': doc['nome'],
          'cpf': doc['cpf'],
          'tipo': 'prestador'
        }).toList();
      });
    } catch (e) {
      print('Erro ao carregar proprietários: $e');
    }
  }

  Widget _buildProprietarioDropdown() {
    // Combina moradores e prestadores em uma única lista
    List<Map<String, dynamic>> proprietariosDisponiveis = [..._moradores, ..._prestadores];

    return SearchAnchor(
      builder: (BuildContext context, SearchController controller) {
        return SearchBar(
          controller: controller,
          padding: const WidgetStatePropertyAll<EdgeInsets>(
            EdgeInsets.symmetric(horizontal: 16.0),
          ),
          onTap: () {
            controller.openView();
          },
          leading: const Icon(Icons.person),
          trailing: [
            if (_proprietarioController.text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  setState(() {
                    _selectedProprietarioId = null;
                    _proprietarioController.text = '';
                    _cpfController.text = '';
                    _tipoProprietario = '';
                  });
                  controller.clear();
                },
              ),
          ],
          hintText: _proprietarioController.text.isEmpty
              ? AppLocalizations.of(context).translate('Nome do Proprietário')
              : _proprietarioController.text,
          constraints: const BoxConstraints(
            minHeight: 56,
          ),
        );
      },
      suggestionsBuilder: (BuildContext context, SearchController controller) {
        final String searchText = controller.text.toLowerCase();
        
        List<Widget> suggestions = [];

        // Adiciona os proprietários cadastrados
        suggestions.addAll(
          proprietariosDisponiveis
              .where((proprietario) =>
                  proprietario['nome'].toString().toLowerCase().contains(searchText))
              .map((proprietario) {
                String prefixo = proprietario['tipo'] == 'morador' ? '🏠 ' : '🛠️ ';
                return ListTile(
                  leading: Icon(
                    proprietario['tipo'] == 'morador' ? Icons.home : Icons.build,
                    color: Theme.of(context).primaryColor,
                  ),
                  title: Text('$prefixo${proprietario['nome']}'),
                  subtitle: Text(proprietario['cpf']),
                  onTap: () {
                    setState(() {
                      _selectedProprietarioId = proprietario['id'];
                      _proprietarioController.text = proprietario['nome'];
                      _cpfController.text = proprietario['cpf'];
                      _tipoProprietario = proprietario['tipo'];
                    });
                    controller.closeView(proprietario['nome']);
                  },
                );
              })
        );

        // Adiciona opção de visitante se houver texto digitado
        if (searchText.isNotEmpty) {
          suggestions.add(
            ListTile(
              leading: Icon(
                Icons.person_outline,
                color: Theme.of(context).primaryColor,
              ),
              title: Text('👥 ${controller.text} (${AppLocalizations.of(context).translate('visitor')})'),
              onTap: () {
                setState(() {
                  _selectedProprietarioId = null;
                  _proprietarioController.text = controller.text;
                  _cpfController.text = '';
                  _tipoProprietario = 'visitante';
                });
                controller.closeView(controller.text);
              },
            ),
          );
        }

        return suggestions;
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _carregarVeiculos();
    _carregarProprietarios();
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

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('vehicle_registration')),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: VeiculoSearchDelegate(_veiculosCadastrados, colorScheme),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarDialogCadastro,
        icon: const Icon(Icons.add),
        label: Text(localizations.translate('add_vehicle')),
      ),
      body: _veiculosCadastrados.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.directions_car_outlined,
                    size: 64,
                    color: colorScheme.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    localizations.translate('no_vehicles'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                  ),
                ],
              ),
            )
          : ListView.builder(
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
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: colorScheme.outlineVariant.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
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
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primaryContainer,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        _getVehicleIcon(veiculo['tipo_proprietario']!),
                                        size: 24,
                                        color: colorScheme.onPrimaryContainer,
                                      ),
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
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: colorScheme.secondaryContainer,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  veiculo['placa']!,
                                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                        color: colorScheme.onSecondaryContainer,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                veiculo['cor']!,
                                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                      color: colorScheme.onSurfaceVariant,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    RotationTransition(
                                      turns: Tween(begin: 0.0, end: 0.5).animate(controller),
                                      child: Icon(
                                        Icons.expand_more,
                                        color: colorScheme.primary,
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
                                    ? Container(
                                        decoration: BoxDecoration(
                                          color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                                          borderRadius: const BorderRadius.only(
                                            bottomLeft: Radius.circular(12),
                                            bottomRight: Radius.circular(12),
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            const Divider(height: 1),
                                            Padding(
                                              padding: const EdgeInsets.all(16.0),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  _buildInfoRow(
                                                    localizations.translate('year'),
                                                    veiculo['ano']!,
                                                    colorScheme,
                                                  ),
                                                  const SizedBox(height: 8),
                                                  _buildInfoRow(
                                                    localizations.translate('Nome do Proprietário'),
                                                    veiculo['proprietario']!,
                                                    colorScheme,
                                                  ),
                                                  const SizedBox(height: 8),
                                                  _buildInfoRow(
                                                    localizations.translate('owner_type'),
                                                    _getTipoProprietarioLabel(veiculo['tipo_proprietario']!, localizations),
                                                    colorScheme,
                                                  ),
                                                  const SizedBox(height: 16),
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.end,
                                                    children: [
                                                      TextButton.icon(
                                                        icon: const Icon(Icons.edit_outlined),
                                                        label: Text(localizations.translate('edit')),
                                                        onPressed: () => _editVeiculo(veiculo),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      TextButton.icon(
                                                        icon: Icon(Icons.delete_outline, color: colorScheme.error),
                                                        label: Text(
                                                          localizations.translate('delete'),
                                                          style: TextStyle(color: colorScheme.error),
                                                        ),
                                                        onPressed: () => _deleteVeiculo(veiculo),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
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

  IconData _getVehicleIcon(String tipoProprietario) {
    switch (tipoProprietario) {
      case 'morador':
        return Icons.home;
      case 'visitante':
        return Icons.person_outline;
      case 'prestador':
        return Icons.work_outline;
      default:
        return Icons.directions_car;
    }
  }

  String _getTipoProprietarioLabel(String tipo, AppLocalizations localizations) {
    switch (tipo) {
      case 'morador':
        return localizations.translate('resident');
      case 'visitante':
        return localizations.translate('visitor');
      case 'prestador':
        return localizations.translate('prestador_de_servico');
      default:
        return tipo;
    }
  }

  Widget _buildInfoRow(String label, String value, ColorScheme colorScheme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            '$label:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
      ],
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

class VeiculoSearchDelegate extends SearchDelegate<String> {
  final List<Map<String, String>> veiculos;
  final ColorScheme colorScheme;

  VeiculoSearchDelegate(this.veiculos, this.colorScheme);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: AnimatedIcon(
        icon: AnimatedIcons.menu_arrow,
        progress: transitionAnimation,
      ),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    final results = veiculos.where((veiculo) {
      final searchQuery = query.toLowerCase();
      return veiculo['placa']!.toLowerCase().contains(searchQuery) ||
          veiculo['marca']!.toLowerCase().contains(searchQuery) ||
          veiculo['modelo']!.toLowerCase().contains(searchQuery) ||
          veiculo['proprietario']!.toLowerCase().contains(searchQuery);
    }).toList();

    if (query.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Digite para buscar',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
            ),
          ],
        ),
      );
    }

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum resultado encontrado',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final veiculo = results[index];
        return ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.directions_car,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          title: Text('${veiculo['marca']} ${veiculo['modelo']}'),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      veiculo['placa']!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSecondaryContainer,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    veiculo['proprietario']!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
          onTap: () {
            close(context, veiculo['placa']!);
          },
        );
      },
    );
  }
}
