import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../controllers/encomenda_controller.dart';
import '../../controllers/morador_controller.dart';
import '../../models/encomenda_model.dart';
import '../../models/morador_model.dart';
import '../../localizations/app_localizations.dart';
import '../../widgets/avatar_widget.dart';

class EncomendasView extends StatefulWidget {
  const EncomendasView({super.key});

  @override
  State<EncomendasView> createState() => _EncomendasViewState();
}

class _EncomendasViewState extends State<EncomendasView> {
  final _formKey = GlobalKey<FormState>();
  final _encomendaController = EncomendaController();
  final _moradorController = MoradorController();
  
  Morador? _moradorSelecionado;
  final _descricaoController = TextEditingController();
  final _remetenteController = TextEditingController();
  bool _isLoading = false;

  Future<void> _cadastrarEncomenda() async {
    if (_formKey.currentState!.validate() && _moradorSelecionado != null) {
      setState(() => _isLoading = true);
      
      try {
        final encomenda = Encomenda(
          id: '',  // Será gerado no controller
          moradorId: _moradorSelecionado!.id,
          moradorNome: _moradorSelecionado!.nome,
          descricao: _descricaoController.text,
          remetente: _remetenteController.text,
          dataChegada: DateTime.now(),
        );

        await _encomendaController.cadastrarEncomenda(encomenda);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context).translate('package_registered'),
              ),
              backgroundColor: Colors.green,
            ),
          );
          _limparFormulario();
          setState(() {});  // Atualiza a lista
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context).translate('error_registering_package'),
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _limparFormulario() {
    _moradorSelecionado = null;
    _descricaoController.clear();
    _remetenteController.clear();
  }

  void _mostrarDialogCadastro() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppLocalizations.of(context).translate('register_package'),
        ),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Seleção do Morador
                FutureBuilder<List<Morador>>(
                  future: _moradorController.buscarTodosMoradores(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Text(
                        AppLocalizations.of(context).translate('no_residents_found'),
                      );
                    }

                    return DropdownButtonFormField<Morador>(
                      value: _moradorSelecionado,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context).translate('resident'),
                      ),
                      items: snapshot.data!.map((morador) {
                        return DropdownMenuItem(
                          value: morador,
                          child: Text(morador.nome),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _moradorSelecionado = value);
                      },
                      validator: (value) {
                        if (value == null) {
                          return AppLocalizations.of(context)
                              .translate('select_resident');
                        }
                        return null;
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
                // Descrição da Encomenda
                TextFormField(
                  controller: _descricaoController,
                  decoration: InputDecoration(
                    labelText:
                        AppLocalizations.of(context).translate('package_description'),
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppLocalizations.of(context)
                          .translate('description_required');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Remetente
                TextFormField(
                  controller: _remetenteController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).translate('sender'),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppLocalizations.of(context)
                          .translate('sender_required');
                    }
                    return null;
                  },
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
            onPressed: _isLoading
                ? null
                : () {
                    _cadastrarEncomenda().then((_) {
                      Navigator.pop(context);
                    });
                  },
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(AppLocalizations.of(context).translate('register')),
          ),
        ],
      ),
    );
  }

  void _showCadastroEncomendaDialog(BuildContext context) {
    _mostrarDialogCadastro();
  }

  void _confirmarRetirada(BuildContext context, Encomenda encomenda) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).translate('confirm_collection')),
        content: Text(AppLocalizations.of(context).translate('confirm_collection_message')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context).translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await _encomendaController.marcarComoRetirada(encomenda.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocalizations.of(context).translate('package_collected'),
                      ),
                    ),
                  );
                  setState(() {});
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        e.toString().contains('Exception: ')
                            ? e.toString().split('Exception: ')[1]
                            : e.toString(),
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text(AppLocalizations.of(context).translate('confirm')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).translate('packages')),
      ),
      body: FutureBuilder<List<Encomenda>>(
        future: _encomendaController.buscarEncomendasPendentes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            String errorMessage = snapshot.error.toString();
            // Remove a parte técnica da mensagem de erro
            if (errorMessage.contains('Exception: ')) {
              errorMessage = errorMessage.split('Exception: ')[1];
            }
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  errorMessage,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final encomendas = snapshot.data ?? [];

          if (encomendas.isEmpty) {
            return Center(
              child: Text(
                AppLocalizations.of(context).translate('no_packages'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            );
          }

          return ListView.builder(
            itemCount: encomendas.length,
            itemBuilder: (context, index) {
              final encomenda = encomendas[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  title: Text(encomenda.descricao),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${AppLocalizations.of(context).translate('sender')}: ${encomenda.remetente}'),
                      Text(
                        '${AppLocalizations.of(context).translate('arrival_date')}: ${DateFormat('dd/MM/yyyy HH:mm').format(encomenda.dataChegada)}',
                      ),
                      Text('${AppLocalizations.of(context).translate('resident')}: ${encomenda.moradorNome}'),
                    ],
                  ),
                  trailing: FutureBuilder<String>(
                    future: _encomendaController.getUserRole(),
                    builder: (context, roleSnapshot) {
                      if (!roleSnapshot.hasData) return const SizedBox.shrink();
                      
                      final role = roleSnapshot.data!;
                      if (role == 'portaria') {
                        return ElevatedButton(
                          onPressed: () => _confirmarRetirada(context, encomenda),
                          child: Text(
                            AppLocalizations.of(context).translate('mark_as_collected'),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  onTap: () async {
                    final role = await _encomendaController.getUserRole();
                    if (role == 'moradores') {
                      _confirmarRetirada(context, encomenda);
                    }
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FutureBuilder<String>(
        future: _encomendaController.getUserRole(),
        builder: (context, snapshot) {
          if (snapshot.data == 'portaria') {
            return FloatingActionButton(
              onPressed: () => _showCadastroEncomendaDialog(context),
              child: const Icon(Icons.add),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  @override
  void dispose() {
    _descricaoController.dispose();
    _remetenteController.dispose();
    super.dispose();
  }
}
