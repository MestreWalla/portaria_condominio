import 'dart:async';

import 'package:flutter/material.dart';
import '../../models/prestador_model.dart';
import '../../controllers/prestador_controller.dart';
import '../../localizations/app_localizations.dart';
import '../help/prestadores_help.dart';
import '../prestadores/components/prestador_card.dart';
import '../prestadores/components/prestador_filters.dart';
import '../prestadores/dialogs/prestador_form_dialog.dart';

class PrestadoresView extends StatefulWidget {
  final String currentUserId;

  const PrestadoresView({
    super.key,
    required this.currentUserId,
  });

  @override
  State<PrestadoresView> createState() => _PrestadoresViewState();
}

class _PrestadoresViewState extends State<PrestadoresView> with TickerProviderStateMixin {
  final PrestadorController _controller = PrestadorController();
  final ValueNotifier<List<Prestador>> _prestadoresNotifier = ValueNotifier<List<Prestador>>([]);
  final Map<String, bool> _loadingStates = {};
  
  // Filtros
  String _filtroAtual = 'todos';
  DateTime? _dataSelecionada;

  @override
  void initState() {
    super.initState();
    _loadPrestadores();
  }

  Future<void> _loadPrestadores() async {
    try {
      final prestadores = await _controller.buscarTodosPrestadores();
      _prestadoresNotifier.value = _aplicarFiltros(prestadores);
    } catch (e) {
      // Tratar erro se necessário
    }
  }

  List<Prestador> _aplicarFiltros(List<Prestador> prestadores) {
    return prestadores.where((prestador) {
      // Filtro por data
      if (_dataSelecionada != null) {
        final dataRegistro = DateTime.parse(prestador.dataRegistro);
        if (!_mesmosDia(dataRegistro, _dataSelecionada!)) {
          return false;
        }
      }

      // Filtros de status
      switch (_filtroAtual) {
        case 'liberados':
          return prestador.liberacaoEntrada;
        case 'pendentes':
          return !prestador.liberacaoEntrada;
        default: // 'todos'
          return true;
      }
    }).toList();
  }

  bool _mesmosDia(DateTime data1, DateTime data2) {
    return data1.year == data2.year && 
           data1.month == data2.month && 
           data1.day == data2.day;
  }

  Future<void> _handleLiberacaoEntrada(Prestador prestador, AppLocalizations localizations, ColorScheme colorScheme) async {
    _loadingStates[prestador.id] = true;
    setState(() {});
    try {
      await _controller.liberarEntrada(prestador.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.translate('entry_allowed')),
            backgroundColor: Colors.green,
          ),
        );
      }
      final prestadores = await _controller.buscarTodosPrestadores();
      _prestadoresNotifier.value = _aplicarFiltros(prestadores);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.translate('error_allowing_entry')),
            backgroundColor: colorScheme.error,
          ),
        );
      }
    } finally {
      _loadingStates[prestador.id] = false;
      setState(() {});
    }
  }

  Future<void> _handleRevogacaoEntrada(Prestador prestador, AppLocalizations localizations, ColorScheme colorScheme) async {
    _loadingStates[prestador.id] = true;
    setState(() {});
    try {
      await _controller.revogarEntrada(prestador.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.translate('entry_revoked')),
            backgroundColor: Colors.orange,
          ),
        );
      }
      final prestadores = await _controller.buscarTodosPrestadores();
      _prestadoresNotifier.value = _aplicarFiltros(prestadores);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.translate('error_revoking_entry')),
            backgroundColor: colorScheme.error,
          ),
        );
      }
    } finally {
      _loadingStates[prestador.id] = false;
      setState(() {});
    }
  }

  Future<void> _mostrarDialogCadastro([Prestador? prestador]) async {
    showDialog(
      context: context,
      builder: (context) => PrestadorFormDialog(
        prestador: prestador,
        onSave: (nome, cpf, empresa, telefone, email, senha) async {
          try {
            if (prestador != null) {
              await _controller.editarPrestador(
                Prestador(
                  id: prestador.id,
                  nome: nome,
                  cpf: cpf,
                  empresa: empresa,
                  telefone: telefone,
                  email: email,
                  senha: senha,
                  liberacaoCadastro: prestador.liberacaoCadastro,
                  role: prestador.role,
                ),
              );
            } else {
              await _controller.criarPrestador(
                Prestador(
                  id: '',
                  nome: nome,
                  cpf: cpf,
                  empresa: empresa,
                  telefone: telefone,
                  email: email,
                  senha: senha,
                  liberacaoCadastro: true,
                  role: 'prestador',
                ),
              );
            }
            _loadPrestadores();
          } catch (e) {
            // Tratar erro se necessário
          }
        },
        onPhotoUpdated: _loadPrestadores,
      ),
    );
  }

  Future<void> _confirmarExclusao(Prestador prestador) async {
    final localizations = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.translate('confirm_deletion')),
        content: Text(localizations.translate('confirm_delete_provider')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(localizations.translate('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
            ),
            child: Text(localizations.translate('delete')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _controller.excluirPrestador(prestador.id);
        _loadPrestadores();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localizations.translate('provider_deleted')),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localizations.translate('error_deleting_provider')),
              backgroundColor: colorScheme.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('service_providers')),
        actions: [
          IconButton(
            onPressed: () => _mostrarDialogCadastro(),
            icon: const Icon(Icons.add),
            tooltip: localizations.translate('add_provider'),
          ),
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const PrestadoresHelp(),
              );
            },
            icon: const Icon(Icons.help_outline),
            tooltip: localizations.translate('help'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarDialogCadastro(),
        icon: const Icon(Icons.person_add),
        label: Text(localizations.translate('add_service_provider')),
        backgroundColor: colorScheme.secondary,
        foregroundColor: colorScheme.onSecondary,
        elevation: 2,
        highlightElevation: 4,
      ),
      body: Column(
        children: [
          PrestadorFilters(
            filtroAtual: _filtroAtual,
            dataSelecionada: _dataSelecionada,
            onFiltroChanged: (filtro) {
              setState(() {
                _filtroAtual = filtro;
                _dataSelecionada = null;
              });
              _loadPrestadores();
            },
            onDataChanged: (data) {
              setState(() {
                _dataSelecionada = data;
              });
              _loadPrestadores();
            },
          ),
          Expanded(
            child: ValueListenableBuilder<List<Prestador>>(
              valueListenable: _prestadoresNotifier,
              builder: (context, prestadores, child) {
                if (prestadores.isEmpty) {
                  return Center(
                    child: Text(localizations.translate('no_service_providers_found')),
                  );
                }

                return ListView.builder(
                  itemCount: prestadores.length,
                  itemBuilder: (context, index) {
                    final prestador = prestadores[index];
                    return PrestadorCard(
                      prestador: prestador,
                      isLoading: _loadingStates[prestador.id] ?? false,
                      onAllowEntry: () => _handleLiberacaoEntrada(prestador, localizations, colorScheme),
                      onRevokeEntry: () => _handleRevogacaoEntrada(prestador, localizations, colorScheme),
                      onEdit: () => _mostrarDialogCadastro(prestador),
                      onDelete: () => _confirmarExclusao(prestador),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
