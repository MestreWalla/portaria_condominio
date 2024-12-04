import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../controllers/encomenda_controller.dart';
import '../../controllers/morador_controller.dart';
import '../../models/encomenda_model.dart';
import '../../models/morador_model.dart';
import '../../localizations/app_localizations.dart';

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

  void _mostrarHistoricoEncomendas() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, controller) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context).translate('package_history'),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder<List<Encomenda>>(
                  future: _encomendaController.buscarHistoricoEncomendas(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      String errorMessage = snapshot.error.toString();
                      if (errorMessage.contains('Exception: ')) {
                        errorMessage = errorMessage.split('Exception: ')[1];
                      }
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
                            const SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                errorMessage,
                                style: TextStyle(color: Theme.of(context).colorScheme.error),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final encomendas = snapshot.data ?? [];
                    if (encomendas.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 64,
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              AppLocalizations.of(context).translate('no_packages'),
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: encomendas.length,
                      itemBuilder: (context, index) {
                        final encomenda = encomendas[index];
                        final colorScheme = Theme.of(context).colorScheme;
                        
                        return Card(
                          elevation: 1,
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: encomenda.retirada
                                            ? colorScheme.primaryContainer
                                            : colorScheme.secondaryContainer,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        encomenda.retirada
                                            ? Icons.check_circle_outline
                                            : Icons.inventory_2_outlined,
                                        color: encomenda.retirada
                                            ? colorScheme.onPrimaryContainer
                                            : colorScheme.onSecondaryContainer,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            encomenda.descricao,
                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            encomenda.moradorNome,
                                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                              color: colorScheme.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.local_shipping_outlined,
                                      size: 16,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      encomenda.remetente,
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today_outlined,
                                      size: 16,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${AppLocalizations.of(context).translate('arrival')}: ${DateFormat('dd/MM/yyyy HH:mm').format(encomenda.dataChegada)}',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                                if (encomenda.retirada && encomenda.dataRetirada != null) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle_outline,
                                        size: 16,
                                        color: colorScheme.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${AppLocalizations.of(context).translate('collected')}: ${DateFormat('dd/MM/yyyy HH:mm').format(encomenda.dataRetirada!)}',
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: colorScheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.person_outline,
                                        size: 16,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        AppLocalizations.of(context).translate(
                                          encomenda.retiradaPor == 'portaria'
                                              ? 'collected_by_doorman'
                                              : 'collected_by_resident'
                                        ),
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).translate('packages')),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _mostrarHistoricoEncomendas,
            tooltip: AppLocalizations.of(context).translate('view_history'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCadastroEncomendaDialog(context),
        icon: const Icon(Icons.add),
        label: Text(AppLocalizations.of(context).translate('register_package')),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: FutureBuilder<List<Encomenda>>(
        future: _encomendaController.buscarEncomendasPendentes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            String errorMessage = snapshot.error.toString();
            if (errorMessage.contains('Exception: ')) {
              errorMessage = errorMessage.split('Exception: ')[1];
            }
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      errorMessage,
                      style: TextStyle(color: colorScheme.error),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            );
          }

          final encomendas = snapshot.data ?? [];
          if (encomendas.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 64,
                    color: colorScheme.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context).translate('no_packages'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colorScheme.primary.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showCadastroEncomendaDialog(context),
                    icon: const Icon(Icons.add),
                    label: Text(AppLocalizations.of(context).translate('register_package')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: encomendas.length,
              itemBuilder: (context, index) {
                final encomenda = encomendas[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _confirmarRetirada(context, encomenda),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.inventory_2_outlined,
                                  color: colorScheme.onPrimaryContainer,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      encomenda.descricao,
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      encomenda.moradorNome,
                                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Icon(
                                Icons.local_shipping_outlined,
                                size: 16,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                encomenda.remetente,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                Icons.access_time,
                                size: 16,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                DateFormat('dd/MM/yyyy HH:mm').format(encomenda.dataChegada),
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
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
