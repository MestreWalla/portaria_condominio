import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/prestador_model.dart';
import '../../widgets/avatar_widget.dart';
import '../photo_registration/photo_registration_screen.dart';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../controllers/prestador_controller.dart';
import '../../models/prestador_model.dart';
import '../../localizations/app_localizations.dart';
import '../chat/chat_view.dart';
import 'package:portaria_condominio/widgets/avatar_widget.dart';
import '../photo_registration/photo_registration_screen.dart';
import '../qr_code/qr_code_view.dart';

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
  int? expandedIndex;
  late Future<List<Prestador>> _futurePrestadores;
  final Map<int, AnimationController> _animationControllers = {};
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  // Adicionar variáveis para controle dos filtros
  bool _sortAlfabetico = false;
  String _filtroStatus = 'todos'; // 'todos', 'liberados', 'pendentes'
  
  List<Prestador> _aplicarFiltros(List<Prestador> prestadores) {
    List<Prestador> prestadoresFiltrados = List.from(prestadores);
    
    // Aplicar filtro por status
    if (_filtroStatus == 'liberados') {
      prestadoresFiltrados = prestadoresFiltrados.where((p) => p.liberacaoEntrada).toList();
    } else if (_filtroStatus == 'pendentes') {
      prestadoresFiltrados = prestadoresFiltrados.where((p) => !p.liberacaoEntrada).toList();
    }
    
    // Aplicar ordenação alfabética
    if (_sortAlfabetico) {
      prestadoresFiltrados.sort((a, b) => a.nome.compareTo(b.nome));
    }
    
    return prestadoresFiltrados;
  }

  @override
  void initState() {
    super.initState();
    _futurePrestadores = _controller.buscarTodosPrestadores();
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

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('service_providers')),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (String value) {
              setState(() {
                if (value == 'alfabetico') {
                  _sortAlfabetico = !_sortAlfabetico;
                } else {
                  _filtroStatus = value;
                }
              });
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              CheckedPopupMenuItem<String>(
                checked: _sortAlfabetico,
                value: 'alfabetico',
                child: Text('Ordem Alfabética'),
              ),
              const PopupMenuDivider(),
              CheckedPopupMenuItem<String>(
                checked: _filtroStatus == 'todos',
                value: 'todos',
                child: Text('Todos'),
              ),
              CheckedPopupMenuItem<String>(
                checked: _filtroStatus == 'liberados',
                value: 'liberados',
                child: Text('Liberados'),
              ),
              CheckedPopupMenuItem<String>(
                checked: _filtroStatus == 'pendentes',
                value: 'pendentes',
                child: Text('Pendentes'),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _mostrarDialogCadastro();
        },
        icon: const Icon(Icons.person_add),
        label: Text(localizations.translate('add_service_provider')),
        backgroundColor: colorScheme.secondary,
        foregroundColor: colorScheme.onSecondary,
        elevation: 2,
        highlightElevation: 4,
      ),
      body: FutureBuilder<List<Prestador>>(
        future: _futurePrestadores,
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
              child: Text(localizations.translate('no_service_providers')),
            );
          }

          final prestadoresFiltrados = _aplicarFiltros(snapshot.data!);

          return ListView.builder(
            itemCount: prestadoresFiltrados.length,
            itemBuilder: (context, index) {
              final prestador = prestadoresFiltrados[index];
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
                                  Hero(
                                    tag: 'avatar_${prestador.id}',
                                    child: AvatarWidget(
                                      photoURL: prestador.photoURL,
                                      userName: prestador.nome,
                                      radius: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          prestador.nome,
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.business,
                                              size: 16,
                                              color: colorScheme.primary,
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                prestador.empresa,
                                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                  color: colorScheme.primary,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.phone,
                                              size: 16,
                                              color: colorScheme.onSurfaceVariant,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              prestador.telefone,
                                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                color: colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  RotationTransition(
                                    turns: Tween(begin: 0.0, end: 0.5)
                                        .animate(expansionAnimation),
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
                                  ? Column(
                                      children: [
                                        const Divider(),
                                        Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              _buildInfoRow(
                                                localizations.translate('cpf'),
                                                prestador.cpf,
                                                colorScheme,
                                              ),
                                              const SizedBox(height: 8),
                                              _buildInfoRow(
                                                localizations.translate('email'),
                                                prestador.email,
                                                colorScheme,
                                              ),
                                              const SizedBox(height: 16),
                                              _buildActionButtons(
                                                prestador,
                                                localizations,
                                                colorScheme,
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
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
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

  Widget _buildActionButtons(
    Prestador prestador,
    AppLocalizations localizations,
    ColorScheme colorScheme,
  ) {
    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.spaceEvenly,
          spacing: 8.0,
          runSpacing: 8.0,
          children: [
            if (!prestador.liberacaoEntrada)
              _buildActionButton(
                icon: Icons.check_circle,
                label: localizations.translate('allow_entry'),
                onPressed: () async {
                  try {
                    await _controller.liberarEntrada(prestador.id);
                    setState(() {
                      _futurePrestadores = _controller.buscarTodosPrestadores();
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
                colorScheme: colorScheme,
              )
            else
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildActionButton(
                    icon: Icons.cancel,
                    label: localizations.translate('revoke_entry'),
                    onPressed: () async {
                      try {
                        await _controller.revogarEntrada(prestador.id);
                        setState(() {
                          _futurePrestadores = _controller.buscarTodosPrestadores();
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
                    colorScheme: colorScheme,
                  ),
                  const SizedBox(width: 8),
                  _buildActionButton(
                    icon: Icons.qr_code,
                    label: localizations.translate('qr_code'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => QrCodeView(prestador: prestador),
                        ),
                      );
                    },
                    colorScheme: colorScheme,
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildActionButton(
              icon: Icons.phone,
              label: localizations.translate('call'),
              onPressed: () => _makePhoneCall(prestador.telefone),
              colorScheme: colorScheme,
            ),
            _buildActionButton(
              icon: Icons.message,
              label: localizations.translate('message'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatView(
                    receiverId: prestador.id,
                    receiverName: prestador.nome,
                  ),
                ),
              ),
              colorScheme: colorScheme,
            ),
            _buildActionButton(
              icon: FontAwesomeIcons.whatsapp,
              label: localizations.translate('whatsapp'),
              onPressed: () => _openWhatsApp(prestador.telefone),
              colorScheme: colorScheme,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildActionButton(
              icon: Icons.edit,
              label: localizations.translate('edit'),
              onPressed: () => _mostrarDialogCadastro(prestador),
              colorScheme: colorScheme,
            ),
            _buildActionButton(
              icon: Icons.delete,
              label: localizations.translate('delete'),
              onPressed: () => _confirmarExclusao(prestador),
              colorScheme: colorScheme,
              isDestructive: true,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required ColorScheme colorScheme,
    bool isDestructive = false,
  }) {
    return SizedBox(
      width: 85,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: isDestructive ? colorScheme.error : colorScheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isDestructive ? colorScheme.error : colorScheme.primary,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isDestructive ? colorScheme.error : colorScheme.primary,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri url = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> _openWhatsApp(String phoneNumber) async {
    final Uri url = Uri.parse('https://wa.me/$phoneNumber');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  void _mostrarDialogCadastro([Prestador? prestador]) {
    final TextEditingController nomeController = TextEditingController();
    final TextEditingController cpfController = TextEditingController();
    final TextEditingController empresaController = TextEditingController();
    final TextEditingController telefoneController = TextEditingController();
    final TextEditingController emailController = TextEditingController();
    final TextEditingController senhaController = TextEditingController();

    if (prestador != null) {
      nomeController.text = prestador.nome;
      cpfController.text = prestador.cpf;
      empresaController.text = prestador.empresa;
      telefoneController.text = prestador.telefone;
      emailController.text = prestador.email;
      senhaController.text = prestador.senha;
    }

    showDialog(
      context: context,
      builder: (context) {
        final localizations = AppLocalizations.of(context);
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
                      prestador != null
                          ? localizations.translate('edit_service_provider')
                          : localizations.translate('add_service_provider'),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: GestureDetector(
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PhotoRegistrationScreen(
                                userType: 'prestador',
                                userId: prestador?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                                returnPhotoData: false,
                              ),
                            ),
                          );
                          if (result == true) {
                            // Recarregar a lista de prestadores para mostrar a foto atualizada
                            setState(() {
                              _futurePrestadores = _controller.buscarTodosPrestadores();
                            });
                          }
                        },
                        child: Stack(
                          children: [
                            AvatarWidget(
                              photoURL: prestador?.photoURL,
                              userName: prestador?.nome ?? '',
                              radius: 50,
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.camera_alt,
                                  size: 20,
                                  color: colorScheme.onPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
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
                    TextFormField(
                      controller: empresaController,
                      decoration: InputDecoration(
                        labelText: localizations.translate('company'),
                        prefixIcon: const Icon(Icons.business),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return localizations.translate('company_required');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: telefoneController,
                      decoration: InputDecoration(
                        labelText: localizations.translate('phone'),
                        prefixIcon: const Icon(Icons.phone),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return localizations.translate('phone_required');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: localizations.translate('email'),
                        prefixIcon: const Icon(Icons.email),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return localizations.translate('email_required');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: senhaController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: localizations.translate('password'),
                        prefixIcon: const Icon(Icons.lock),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return localizations.translate('password_required');
                        }
                        return null;
                      },
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
                                final novoPrestador = Prestador(
                                  id: prestador != null ? prestador.id : DateTime.now().millisecondsSinceEpoch.toString(),
                                  nome: nomeController.text,
                                  cpf: cpfController.text,
                                  empresa: empresaController.text,
                                  telefone: telefoneController.text,
                                  email: emailController.text,
                                  senha: senhaController.text,
                                  liberacaoCadastro: false,
                                  role: 'prestador',
                                );
                                if (prestador != null) {
                                  await _controller.editarPrestador(novoPrestador);
                                } else {
                                  await _controller.criarPrestador(novoPrestador);
                                }
                                if (mounted) {
                                  Navigator.of(context).pop();
                                  setState(() {
                                    _futurePrestadores = _controller.buscarTodosPrestadores();
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        prestador != null
                                            ? localizations.translate('service_provider_updated')
                                            : localizations.translate('service_provider_added'),
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        prestador != null
                                            ? localizations.translate('error_updating_service_provider')
                                            : localizations.translate('error_adding_service_provider'),
                                      ),
                                      backgroundColor: colorScheme.error,
                                    ),
                                  );
                                }
                              }
                            }
                          },
                          icon: const Icon(Icons.add),
                          label: Text(
                            prestador != null
                                ? localizations.translate('update')
                                : localizations.translate('add'),
                          ),
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

  void _confirmarExclusao(Prestador prestador) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).translate('confirm_deletion')),
        content: Text(
          AppLocalizations.of(context)
              .translate('confirm_service_provider_deletion')
              .replaceAll('{name}', prestador.nome),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).translate('cancel')),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _controller.excluirPrestador(prestador.id);
                setState(() {
                  _futurePrestadores = _controller.buscarTodosPrestadores();
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocalizations.of(context)
                            .translate('service_provider_deleted_successfully'),
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${AppLocalizations.of(context).translate('error_deleting_service_provider')}: $e',
                      ),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                }
              }
            },
            child: Text(
              AppLocalizations.of(context).translate('delete'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}
