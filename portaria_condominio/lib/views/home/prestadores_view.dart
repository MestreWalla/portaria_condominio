import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/prestador_model.dart';
import '../../widgets/avatar_widget.dart';
import '../photo_registration/photo_registration_screen.dart';

import '../../controllers/prestador_controller.dart';
import '../../localizations/app_localizations.dart';
import '../chat/chat_view.dart';
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
  String? expandedIndex;
  final ValueNotifier<List<Prestador>> _prestadoresNotifier = ValueNotifier<List<Prestador>>([]);
  final Map<String, AnimationController> _animationControllers = {};
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final Map<String, bool> _loadingStates = {};

  @override
  void initState() {
    super.initState();
    _loadPrestadores();
  }

  Future<void> _loadPrestadores() async {
    try {
      final prestadores = await _controller.buscarTodosPrestadores();
      _prestadoresNotifier.value = prestadores;
    } catch (e) {
      // Tratar erro se necessário
    }
  }

  Future<void> _handleLiberacaoEntrada(Prestador prestador, AppLocalizations localizations, ColorScheme colorScheme) async {
    _loadingStates[prestador.id] = true;
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
      _prestadoresNotifier.value = prestadores;
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
    }
  }

  Future<void> _handleRevogacaoEntrada(Prestador prestador, AppLocalizations localizations, ColorScheme colorScheme) async {
    _loadingStates[prestador.id] = true;
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
      _prestadoresNotifier.value = prestadores;
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
    }
  }

  @override
  void dispose() {
    for (var controller in _animationControllers.values) {
      controller.dispose();
    }
    _animationControllers.clear();
    _prestadoresNotifier.dispose();
    super.dispose();
  }

  AnimationController _getAnimationController(String prestadorId) {
    return _animationControllers.putIfAbsent(
      prestadorId,
      () => AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('service_providers')),
        actions: [
          IconButton(
            onPressed: () => _mostrarDialogCadastro(null),
            icon: const Icon(Icons.add),
            tooltip: localizations.translate('add_provider'),
          ),
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Row(
                    children: [
                      Icon(
                        Icons.help_outline,
                        color: colorScheme.primary,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        localizations.translate('how_to_use'),
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                  content: Container(
                    width: double.maxFinite,
                    constraints: const BoxConstraints(maxHeight: 500),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            localizations.translate('providers_management'),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildTutorialItem(
                            Icons.add,
                            localizations.translate('add_provider_tutorial'),
                            colorScheme.primary,
                          ),
                          _buildTutorialDivider(),
                          _buildTutorialItem(
                            Icons.check_circle,
                            localizations.translate('allow_entry_tutorial'),
                            Colors.green,
                          ),
                          _buildTutorialDivider(),
                          _buildTutorialItem(
                            Icons.cancel,
                            localizations.translate('revoke_entry_tutorial'),
                            Colors.orange,
                          ),
                          _buildTutorialDivider(),
                          _buildTutorialItem(
                            Icons.qr_code,
                            localizations.translate('qr_code_tutorial'),
                            colorScheme.primary,
                          ),
                          _buildTutorialDivider(),
                          Text(
                            localizations.translate('communication'),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildTutorialItem(
                            Icons.phone,
                            localizations.translate('call_tutorial'),
                            colorScheme.primary,
                          ),
                          _buildTutorialDivider(),
                          _buildTutorialItem(
                            Icons.message,
                            localizations.translate('message_tutorial'),
                            colorScheme.primary,
                          ),
                          _buildTutorialDivider(),
                          _buildTutorialItem(
                            FontAwesomeIcons.whatsapp,
                            localizations.translate('whatsapp_tutorial'),
                            colorScheme.primary,
                          ),
                          _buildTutorialDivider(),
                          Text(
                            localizations.translate('management'),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildTutorialItem(
                            Icons.edit,
                            localizations.translate('edit_tutorial'),
                            colorScheme.primary,
                          ),
                          _buildTutorialDivider(),
                          _buildTutorialItem(
                            Icons.delete,
                            localizations.translate('delete_tutorial'),
                            Colors.red,
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: colorScheme.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    localizations.translate('scroll_hint'),
                                    style: TextStyle(
                                      color: colorScheme.primary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    TextButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.check_circle_outline),
                      label: Text(localizations.translate('understood')),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.help_outline),
            tooltip: localizations.translate('help'),
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
      body: ValueListenableBuilder<List<Prestador>>(
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

              return _buildCard(prestador, localizations, colorScheme);
            },
          );
        },
      ),
    );
  }

  Widget _buildTutorialItem(IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                text,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTutorialDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Divider(
        color: Colors.grey.withOpacity(0.2),
      ),
    );
  }

  Widget _buildCard(Prestador prestador, AppLocalizations localizations, ColorScheme colorScheme) {
    final isExpanded = expandedIndex == prestador.id;
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
                  expandedIndex = isExpanded ? null : prestador.id;
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Hero(
                          tag: 'avatar_${prestador.id}',
                          child: AvatarWidget(
                            photoURL: prestador.photoURL,
                            userName: prestador.nome,
                            radius: 24,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: prestador.liberacaoEntrada ? Colors.green : Colors.orange,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colorScheme.surface,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            prestador.liberacaoEntrada ? Icons.check : Icons.timer,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      ],
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
                          Text(
                            prestador.empresa,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                prestador.liberacaoEntrada ? Icons.check_circle : Icons.access_time,
                                size: 16,
                                color: prestador.liberacaoEntrada ? Colors.green : Colors.orange,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                prestador.liberacaoEntrada 
                                  ? localizations.translate('entry_allowed')
                                  : localizations.translate('scheduled'),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: prestador.liberacaoEntrada ? Colors.green : Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    RotatedBox(
                      quarterTurns: isExpanded ? 1 : 3,
                      child: Icon(
                        Icons.chevron_left,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(Icons.phone, prestador.telefone, localizations.translate('phone'), colorScheme),
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.email, prestador.email, localizations.translate('email'), colorScheme),
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.badge, prestador.cpf, localizations.translate('cpf'), colorScheme),
                  const SizedBox(height: 16),
                  _buildActionButtons(prestador, localizations, colorScheme),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, String label, ColorScheme colorScheme) {
    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons(
    Prestador prestador,
    AppLocalizations localizations,
    ColorScheme colorScheme,
  ) {
    final isLoading = _loadingStates[prestador.id] ?? false;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            if (!prestador.liberacaoEntrada)
              Container(
                height: 40,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onPressed: isLoading ? null : () => _handleLiberacaoEntrada(prestador, localizations, colorScheme),
                    icon: isLoading 
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.check_circle),
                    label: Text(localizations.translate('allow_entry')),
                  ),
                ),
              )
            else
              Container(
                height: 40,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onPressed: isLoading ? null : () => _handleRevogacaoEntrada(prestador, localizations, colorScheme),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isLoading)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        else
                          const Icon(Icons.cancel),
                        const SizedBox(width: 8),
                        Text(localizations.translate('revoke_entry')),
                        const SizedBox(width: 8),
                        Container(
                          height: 24,
                          width: 1,
                          color: Colors.white.withOpacity(0.5),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: isLoading ? null : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => QrCodeView(prestador: prestador),
                              ),
                            );
                          },
                          child: const Icon(Icons.qr_code),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(width: 16),
            IconButton(
              onPressed: isLoading ? null : () => _makePhoneCall(prestador.telefone),
              icon: const Icon(Icons.phone),
              color: colorScheme.primary,
              tooltip: localizations.translate('call'),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: isLoading ? null : () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatView(
                    receiverId: prestador.id,
                    receiverName: prestador.nome,
                  ),
                ),
              ),
              icon: const Icon(Icons.message),
              color: colorScheme.primary,
              tooltip: localizations.translate('message'),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: isLoading ? null : () => _openWhatsApp(prestador.telefone),
              icon: const Icon(FontAwesomeIcons.whatsapp),
              color: colorScheme.primary,
              tooltip: localizations.translate('whatsapp'),
            ),
            const SizedBox(width: 16),
            IconButton(
              onPressed: isLoading ? null : () => _mostrarDialogCadastro(prestador),
              icon: const Icon(Icons.edit),
              color: colorScheme.primary,
              tooltip: localizations.translate('edit'),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: isLoading ? null : () => _confirmarExclusao(prestador),
              icon: const Icon(Icons.delete),
              color: colorScheme.error,
              tooltip: localizations.translate('delete'),
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
        final localizations = AppLocalizations.of(context)!;
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
                            _loadPrestadores();
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
                                  _loadPrestadores();
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
        title: Text(AppLocalizations.of(context)!.translate('confirm_deletion')),
        content: Text(
          AppLocalizations.of(context)!
              .translate('confirm_service_provider_deletion')
              .replaceAll('{name}', prestador.nome),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.translate('cancel')),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _controller.excluirPrestador(prestador.id);
                _loadPrestadores();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocalizations.of(context)!
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
                        '${AppLocalizations.of(context)!.translate('error_deleting_service_provider')}: $e',
                      ),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                }
              }
            },
            child: Text(
              AppLocalizations.of(context)!.translate('delete'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}
