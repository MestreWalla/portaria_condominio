import 'package:flutter/material.dart';
import '../../controllers/visita_controller.dart';
import '../../models/visita_model.dart';
import '../../localizations/app_localizations.dart';
import '../../controllers/morador_controller.dart';
import '../../models/morador_model.dart';
import 'qr_code_generator_view.dart';

class VisitasView extends StatefulWidget {
  const VisitasView({super.key});

  @override
  State<VisitasView> createState() => _VisitasViewState();
}

class _VisitasViewState extends State<VisitasView> with TickerProviderStateMixin {
  final VisitaController _controller = VisitaController();
  final MoradorController _moradorController = MoradorController();
  int? expandedIndex;
  late Future<List<Visita>> _futureVisitas;
  final Map<int, AnimationController> _animationControllers = {};
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late AppLocalizations localizations;
  List<Morador> _moradores = [];
  String? _selectedMoradorId;

  @override
  void initState() {
    super.initState();
    _futureVisitas = _controller.buscarTodasVisitas();
    _carregarMoradores();
  }

  Future<void> _carregarMoradores() async {
    try {
      _moradores = await _moradorController.buscarTodosMoradores();
      setState(() {});
    } catch (e) {
      print('Erro ao carregar moradores: $e');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    localizations = AppLocalizations.of(context);
  }

  @override
  void dispose() {
    for (var controller in _animationControllers.values) {
      controller.dispose();
    }
    super.dispose();
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

  Future<void> _selectTime(BuildContext context, TextEditingController controller) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      controller.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      controller.text = '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('visits')),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () => Navigator.pushNamed(context, '/qr-scanner'),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _mostrarDialogCadastro(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _mostrarDialogCadastro();
        },
        icon: const Icon(Icons.person_add),
        label: Text(localizations.translate('add_visit')),
        backgroundColor: colorScheme.secondary,
        foregroundColor: colorScheme.onSecondary,
        elevation: 2,
        highlightElevation: 4,
      ),
      body: FutureBuilder<List<Visita>>(
        future: _futureVisitas,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                '${localizations.translate('error')}: ${snapshot.error}',
                style: TextStyle(color: colorScheme.error),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(localizations.translate('no_visits_found')),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final visita = snapshot.data![index];
              final isExpanded = index == expandedIndex;

              return AnimatedBuilder(
                animation: _getAnimationController(index),
                builder: (context, child) {
                  final controller = _getAnimationController(index);
                  final elevationAnimation = Tween<double>(begin: 1, end: 8).animate(
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
                    elevation: elevationAnimation.value,
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
                                  Hero(
                                    tag: 'avatar_${visita.id}',
                                    child: CircleAvatar(
                                      backgroundColor: visita.liberacaoEntrada
                                          ? colorScheme.primary
                                          : colorScheme.error,
                                      child: Text(
                                        visita.nome[0].toUpperCase(),
                                        style: TextStyle(color: colorScheme.onPrimary),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          visita.nome,
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              visita.liberacaoEntrada
                                                  ? Icons.check_circle
                                                  : Icons.pending,
                                              size: 16,
                                              color: visita.liberacaoEntrada
                                                  ? Colors.green
                                                  : Colors.orange,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              visita.status == 'agendado'
                                                  ? localizations.translate('scheduled')
                                                  : visita.status == 'liberado'
                                                  ? localizations.translate('entry_allowed')
                                                  : visita.status == 'cancelado'
                                                  ? localizations.translate('cancelled')
                                                  : visita.status == 'realizado'
                                                  ? localizations.translate('realized')
                                                  : localizations.translate('unknown_status'),
                                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                color: visita.status == 'agendado'
                                                    ? Colors.orange
                                                    : visita.status == 'liberado'
                                                    ? Colors.green
                                                    : visita.status == 'cancelado'
                                                    ? Colors.red
                                                    : visita.status == 'realizado'
                                                    ? Colors.blue
                                                    : Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    isExpanded ? Icons.expand_less : Icons.expand_more,
                                    color: colorScheme.primary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (isExpanded) ...[
                          const Divider(),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildInfoRow(localizations.translate('name'), visita.nome, colorScheme),
                                const SizedBox(height: 8),
                                _buildInfoRow(localizations.translate('expected_date'), visita.dataPrevista, colorScheme),
                                const SizedBox(height: 8),
                                _buildInfoRow(localizations.translate('expected_time'), visita.horaPrevista, colorScheme),
                                const SizedBox(height: 8),
                                _buildInfoRow(localizations.translate('house_number'), visita.apartamento, colorScheme),
                                const SizedBox(height: 8),
                                _buildInfoRow(localizations.translate('observations'), visita.observacoes, colorScheme),
                                const SizedBox(height: 16),
                                _buildActionButtons(visita, localizations, colorScheme),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, ColorScheme colorScheme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: colorScheme.onSurface),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(Visita visita, AppLocalizations localizations, ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        if (!visita.liberacaoEntrada)
          ElevatedButton.icon(
            onPressed: () async {
              try {
                await _controller.liberarEntrada(visita.id);
                setState(() {
                  _futureVisitas = _controller.buscarTodasVisitas();
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(localizations.translate('entry_allowed')),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(localizations.translate('error_allowing_entry')),
                      backgroundColor: colorScheme.error,
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.check_circle),
            label: Text(localizations.translate('allow_entry')),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          )
        else
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () async {
                  try {
                    await _controller.revogarEntrada(visita.id);
                    setState(() {
                      _futureVisitas = _controller.buscarTodasVisitas();
                    });
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(localizations.translate('entry_revoked')),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(localizations.translate('error_revoking_entry')),
                          backgroundColor: colorScheme.error,
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.cancel),
                label: Text(localizations.translate('revoke_entry')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => QrCodeView(visita: visita),
                    ),
                  );
                },
                icon: const Icon(Icons.qr_code),
                color: colorScheme.primary,
                tooltip: localizations.translate('generate_qr_code'),
              ),
            ],
          ),
        IconButton(
          onPressed: () {
            _mostrarDialogEdicao(visita);
          },
          icon: const Icon(Icons.edit),
          color: colorScheme.primary,
          tooltip: localizations.translate('edit'),
        ),
        IconButton(
          onPressed: () {
            _confirmarExclusao(visita);
          },
          icon: const Icon(Icons.delete),
          color: colorScheme.error,
          tooltip: localizations.translate('delete'),
        ),
      ],
    );
  }

  void _mostrarDialogEdicao(Visita visita) {
    final TextEditingController nomeController = TextEditingController(text: visita.nome);
    final TextEditingController cpfController = TextEditingController(text: visita.cpf);
    final TextEditingController dataController = TextEditingController(text: visita.dataPrevista);
    final TextEditingController horaController = TextEditingController(text: visita.horaPrevista);
    final TextEditingController observacoesController = TextEditingController(text: visita.observacoes);

    showDialog(
      context: context,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return Dialog(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.translate('edit_visit'),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: nomeController,
                    decoration: InputDecoration(
                      labelText: localizations.translate('name'),
                      prefixIcon: const Icon(Icons.person_outline),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return localizations.translate('name_required');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: cpfController,
                    decoration: InputDecoration(
                      labelText: localizations.translate('cpf'),
                      prefixIcon: const Icon(Icons.badge_outlined),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return localizations.translate('cpf_required');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: dataController,
                          readOnly: true,
                          onTap: () => _selectDate(context, dataController),
                          decoration: InputDecoration(
                            labelText: localizations.translate('expected_date'),
                            prefixIcon: const Icon(Icons.calendar_today),
                            border: const OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return localizations.translate('date_required');
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: horaController,
                          readOnly: true,
                          onTap: () => _selectTime(context, horaController),
                          decoration: InputDecoration(
                            labelText: localizations.translate('expected_time'),
                            prefixIcon: const Icon(Icons.access_time),
                            border: const OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return localizations.translate('time_required');
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedMoradorId,
                    decoration: InputDecoration(
                      labelText: localizations.translate('resident'),
                      prefixIcon: const Icon(Icons.home),
                      border: const OutlineInputBorder(),
                    ),
                    items: _moradores.map((morador) {
                      return DropdownMenuItem<String>(
                        value: morador.id,
                        child: Text('${morador.nome} - ${morador.endereco}, ${morador.numeroCasa}'),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedMoradorId = newValue;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return localizations.translate('resident_required');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: observacoesController,
                    decoration: InputDecoration(
                      labelText: localizations.translate('observations'),
                      prefixIcon: const Icon(Icons.note_outlined),
                      border: const OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text(localizations.translate('cancel')),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            try {
                              final updatedVisita = Visita(
                                id: visita.id,
                                nome: nomeController.text,
                                cpf: cpfController.text,
                                liberacaoEntrada: visita.liberacaoEntrada,
                                dataPrevista: dataController.text,
                                horaPrevista: horaController.text,
                                apartamento: '${_moradores.firstWhere((m) => m.id == _selectedMoradorId).endereco}, ${_moradores.firstWhere((m) => m.id == _selectedMoradorId).numeroCasa}',
                                observacoes: observacoesController.text,
                                status: visita.status,
                                role: visita.role,
                              );
                              await _controller.atualizarVisita(updatedVisita);
                              if (mounted) {
                                Navigator.of(context).pop();
                                setState(() {
                                  _futureVisitas = _controller.buscarTodasVisitas();
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(localizations.translate('visit_updated')),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(localizations.translate('error_updating_visit')),
                                    backgroundColor: colorScheme.error,
                                  ),
                                );
                              }
                            }
                          }
                        },
                        icon: const Icon(Icons.save),
                        label: Text(localizations.translate('save')),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _mostrarDialogCadastro() {
    final TextEditingController nomeController = TextEditingController();
    final TextEditingController cpfController = TextEditingController();
    final TextEditingController dataController = TextEditingController();
    final TextEditingController horaController = TextEditingController();
    final TextEditingController observacoesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return Dialog(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localizations.translate('add_visit'),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: nomeController,
                      decoration: InputDecoration(
                        labelText: localizations.translate('name'),
                        prefixIcon: const Icon(Icons.person_outline),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return localizations.translate('name_required');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: cpfController,
                      decoration: InputDecoration(
                        labelText: localizations.translate('cpf'),
                        prefixIcon: const Icon(Icons.badge_outlined),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return localizations.translate('cpf_required');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: dataController,
                            readOnly: true,
                            onTap: () => _selectDate(context, dataController),
                            decoration: InputDecoration(
                              labelText: localizations.translate('expected_date'),
                              prefixIcon: const Icon(Icons.calendar_today),
                              border: const OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return localizations.translate('date_required');
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: horaController,
                            readOnly: true,
                            onTap: () => _selectTime(context, horaController),
                            decoration: InputDecoration(
                              labelText: localizations.translate('expected_time'),
                              prefixIcon: const Icon(Icons.access_time),
                              border: const OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return localizations.translate('time_required');
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedMoradorId,
                      decoration: InputDecoration(
                        labelText: localizations.translate('resident'),
                        prefixIcon: const Icon(Icons.home),
                        border: const OutlineInputBorder(),
                      ),
                      items: _moradores.map((morador) {
                        return DropdownMenuItem<String>(
                          value: morador.id,
                          child: Text('${morador.nome} - ${morador.endereco}, ${morador.numeroCasa}'),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedMoradorId = newValue;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return localizations.translate('resident_required');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: observacoesController,
                      decoration: InputDecoration(
                        labelText: localizations.translate('observations'),
                        prefixIcon: const Icon(Icons.note_outlined),
                        border: const OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text(localizations.translate('cancel')),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              try {
                                final novaVisita = Visita(
                                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                                  nome: nomeController.text,
                                  cpf: cpfController.text,
                                  liberacaoEntrada: false,
                                  dataPrevista: dataController.text,
                                  horaPrevista: horaController.text,
                                  apartamento: '${_moradores.firstWhere((m) => m.id == _selectedMoradorId).endereco}, ${_moradores.firstWhere((m) => m.id == _selectedMoradorId).numeroCasa}',
                                  observacoes: observacoesController.text,
                                  status: 'agendado',
                                  role: 'visitante',
                                );
                                await _controller.criarVisita(novaVisita);
                                if (mounted) {
                                  Navigator.of(context).pop();
                                  setState(() {
                                    _futureVisitas = _controller.buscarTodasVisitas();
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(localizations.translate('visit_added')),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(localizations.translate('error_adding_visit')),
                                      backgroundColor: colorScheme.error,
                                    ),
                                  );
                                }
                              }
                            }
                          },
                          icon: const Icon(Icons.add),
                          label: Text(localizations.translate('add')),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _confirmarExclusao(Visita visita) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.translate('confirm_deletion')),
        content: Text(
          localizations.translate('confirm_visit_deletion')
              .replaceAll('{name}', visita.nome),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.translate('cancel')),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _controller.excluirVisita(visita.id);
                setState(() {
                  _futureVisitas = _controller.buscarTodasVisitas();
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        localizations.translate('visit_deleted'),
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${localizations.translate('error_deleting_visit')}: $e',
                      ),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                }
              }
            },
            child: Text(
              localizations.translate('delete'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}
