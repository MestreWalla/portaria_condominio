import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:portaria_condominio/controllers/morador_controller.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/morador_model.dart';
import '../../localizations/app_localizations.dart';
import '../../views/chat/chat_view.dart';
import '../photo_registration/photo_registration_screen.dart';
import 'mapa_view.dart';

class MoradoresView extends StatefulWidget {
  const MoradoresView({super.key});

  @override
  State<MoradoresView> createState() => _MoradoresViewState();
}

class _MoradoresViewState extends State<MoradoresView> with TickerProviderStateMixin {
  final MoradorController _controller = MoradorController();
  int? expandedIndex;
  late Future<List<Morador>> _futureMoradores;
  final Map<int, AnimationController> _animationControllers = {};
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _futureMoradores = _controller.buscarTodosMoradores();
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
        title: Text(localizations.translate('residents')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _mostrarDialogCadastro();
        },
        icon: const Icon(Icons.person_add),
        label: Text(localizations.translate('add_resident')),
        backgroundColor: colorScheme.secondary,
        foregroundColor: colorScheme.onSecondary,
        elevation: 2,
        highlightElevation: 4,
      ),
      body: FutureBuilder<List<Morador>>(
        future: _futureMoradores,
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
              child: Text(localizations.translate('no_residents_found')),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final morador = snapshot.data![index];
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
                  final expansionAnimation = CurvedAnimation(
                    parent: controller,
                    curve: Curves.easeInOut,
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
                                  _buildAvatar(morador.photoURL),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          morador.nome,
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.location_on,
                                              size: 16,
                                              color: colorScheme.primary,
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                morador.endereco.isNotEmpty
                                                    ? '${morador.endereco} - Número ${morador.numeroCasa}'
                                                    : 'Endereço não informado',
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
                                              morador.telefone,
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
                                                morador.cpf,
                                                colorScheme,
                                              ),
                                              const SizedBox(height: 8),
                                              _buildInfoRow(
                                                localizations.translate('email'),
                                                morador.email,
                                                colorScheme,
                                              ),
                                              const SizedBox(height: 16),
                                              _buildActionButtons(
                                                morador,
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

  Widget _buildAvatar(String? photoURL) {
    if (photoURL != null && photoURL.isNotEmpty) {
      try {
        String base64String;
        if (photoURL.startsWith('data:image')) {
          base64String = photoURL.split(',')[1];
        } else {
          base64String = photoURL;
        }

        return Hero(
          tag: 'avatar_${DateTime.now().millisecondsSinceEpoch}',
          child: CircleAvatar(
            radius: 30,
            backgroundImage: MemoryImage(base64Decode(base64String)),
            backgroundColor: Colors.grey[300],
            onBackgroundImageError: (exception, stackTrace) {
              debugPrint('Erro ao carregar imagem: $exception');
              return;
            },
          ),
        );
      } catch (e) {
        debugPrint('Erro ao decodificar base64: $e');
        return _buildDefaultAvatar();
      }
    }
    return _buildDefaultAvatar();
  }

  Widget _buildDefaultAvatar() {
    return Hero(
      tag: 'avatar_default_${DateTime.now().millisecondsSinceEpoch}',
      child: CircleAvatar(
        radius: 30,
        backgroundColor: Colors.grey[300],
        child: Icon(
          Icons.person,
          size: 30,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildLargeAvatar(String? photoURL) {
    if (photoURL != null && photoURL.isNotEmpty) {
      try {
        String base64String;
        if (photoURL.startsWith('data:image')) {
          base64String = photoURL.split(',')[1];
        } else {
          base64String = photoURL;
        }

        return Hero(
          tag: 'avatar_large_${DateTime.now().millisecondsSinceEpoch}',
          child: CircleAvatar(
            radius: 50,
            backgroundImage: MemoryImage(base64Decode(base64String)),
            backgroundColor: Colors.grey[300],
            onBackgroundImageError: (exception, stackTrace) {
              debugPrint('Erro ao carregar imagem grande: $exception');
              return;
            },
          ),
        );
      } catch (e) {
        debugPrint('Erro ao decodificar base64 (imagem grande): $e');
        return _buildLargeDefaultAvatar();
      }
    }
    return _buildLargeDefaultAvatar();
  }

  Widget _buildLargeDefaultAvatar() {
    return Hero(
      tag: 'avatar_large_default_${DateTime.now().millisecondsSinceEpoch}',
      child: CircleAvatar(
        radius: 50,
        backgroundColor: Colors.grey[300],
        child: Icon(
          Icons.person,
          size: 50,
          color: Colors.grey[600],
        ),
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
    Morador morador,
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
            _buildActionButton(
              icon: Icons.phone,
              label: localizations.translate('call'),
              onPressed: () => _makePhoneCall(morador.telefone),
              colorScheme: colorScheme,
            ),
            _buildActionButton(
              icon: Icons.message,
              label: localizations.translate('message'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatView(
                    receiverId: morador.id,
                    receiverName: morador.nome,
                  ),
                ),
              ),
              colorScheme: colorScheme,
            ),
            _buildActionButton(
              icon: Icons.map,
              label: localizations.translate('map'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MapaView(
                      initialAddress: morador.endereco,
                    ),
                  ),
                );
              },
              colorScheme: colorScheme,
            ),
            _buildActionButton(
              icon: FontAwesomeIcons.whatsapp,
              label: localizations.translate('whatsapp'),
              onPressed: () => _openWhatsApp(morador.telefone),
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
              onPressed: () => _mostrarDialogCadastro(morador),
              colorScheme: colorScheme,
            ),
            _buildActionButton(
              icon: Icons.delete,
              label: localizations.translate('delete'),
              onPressed: () => _confirmarExclusao(morador),
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
    final Uri uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _sendSMS(String phoneNumber) async {
    final Uri uri = Uri.parse('sms:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openWhatsApp(String phoneNumber) async {
    String formattedNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    if (!formattedNumber.startsWith('55')) {
      formattedNumber = '55$formattedNumber';
    }
    final url = 'https://wa.me/$formattedNumber';
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _mostrarDialogCadastro([Morador? morador]) async {
    final nomeController = TextEditingController(text: morador?.nome ?? '');
    final cpfController = TextEditingController(text: morador?.cpf ?? '');
    final telefoneController = TextEditingController(text: morador?.telefone ?? '');
    final enderecoController = TextEditingController(text: morador?.endereco ?? '');
    final emailController = TextEditingController(text: morador?.email ?? '');
    final senhaController = TextEditingController();
    final numeroCasaController = TextEditingController(text: morador?.numeroCasa ?? '');
    bool isLoading = false;
    final isEditing = morador != null;

    final dialogResult = await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Cadastro de Morador',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        final slideAnimation = Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          ),
        );

        return SlideTransition(
          position: slideAnimation,
          child: Dialog.fullscreen(
            child: StatefulBuilder(
              builder: (context, setState) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: Scaffold(
                    appBar: AppBar(
                      title: Text(isEditing ? 'Editar Morador' : 'Novo Morador'),
                      leading: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      actions: [
                        FilledButton.icon(
                          onPressed: isLoading
                              ? null
                              : () async {
                                  if (_formKey.currentState!.validate()) {
                                    setState(() => isLoading = true);
                                    
                                    try {
                                      final novoDados = Morador(
                                        id: morador?.id ?? '',
                                        nome: nomeController.text,
                                        cpf: cpfController.text,
                                        telefone: telefoneController.text,
                                        email: emailController.text,
                                        senha: senhaController.text.isEmpty
                                            ? morador?.senha ?? ''
                                            : senhaController.text,
                                        endereco: enderecoController.text,
                                        numeroCasa: numeroCasaController.text,
                                        role: morador?.role ?? 'morador',
                                        photoURL: morador?.photoURL, // Mantém a foto atual
                                      );

                                      if (isEditing) {
                                        // Busca o morador atual para obter a foto mais recente
                                        final moradorAtual = await _controller.buscarMorador(morador!.id);
                                        if (moradorAtual != null) {
                                          // Cria um novo morador com os dados atualizados e a foto mais recente
                                          final moradorAtualizado = Morador(
                                            id: novoDados.id,
                                            nome: novoDados.nome,
                                            cpf: novoDados.cpf,
                                            telefone: novoDados.telefone,
                                            email: novoDados.email,
                                            senha: novoDados.senha,
                                            endereco: novoDados.endereco,
                                            numeroCasa: novoDados.numeroCasa,
                                            role: novoDados.role,
                                            photoURL: moradorAtual.photoURL, // Usa a foto mais recente
                                          );
                                          await _controller.atualizarMorador(moradorAtualizado);
                                        } else {
                                          await _controller.atualizarMorador(novoDados);
                                        }
                                      } else {
                                        await _controller.cadastrarMorador(novoDados);
                                      }

                                      if (!context.mounted) return;
                                      Navigator.of(context).pop(true); // Retorna true para indicar sucesso
                                    } catch (e) {
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Erro ao ${isEditing ? 'atualizar' : 'cadastrar'} morador: $e'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    } finally {
                                      if (mounted) {
                                        setState(() => isLoading = false);
                                      }
                                    }
                                  }
                                },
                          icon: isLoading
                              ? Container(
                                  width: 24,
                                  height: 24,
                                  padding: const EdgeInsets.all(2.0),
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 3,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Icon(Icons.save),
                          label: Text(isLoading ? 'Salvando...' : 'Salvar'),
                        ),
                        const SizedBox(width: 16),
                      ],
                    ),
                    body: SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(
                              child: Stack(
                                children: [
                                  _buildLargeAvatar(morador?.photoURL),
                                  Positioned(
                                    right: -10,
                                    bottom: -10,
                                    child: IconButton(
                                      icon: const Icon(Icons.camera_alt),
                                      onPressed: () async {
                                        if (morador?.id == null) {
                                          // Show message if trying to add photo before saving
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(AppLocalizations.of(context)
                                                  .translate('complete_registration_first')),
                                              backgroundColor: Colors.orange,
                                            ),
                                          );
                                          return;
                                        }

                                        final photoData = await Navigator.push<String>(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => PhotoRegistrationScreen(
                                              userType: 'resident',
                                              userId: morador!.id,
                                              returnPhotoData: true, // Queremos os dados da foto para atualizar o estado
                                            ),
                                          ),
                                        );

                                        if (photoData != null && mounted) {
                                          try {
                                            // Atualiza a foto no banco
                                            await _controller.atualizarFotoMorador(morador!.id, photoData);

                                            // Atualiza o objeto morador com a nova foto
                                            final moradorAtualizado = Morador(
                                              id: morador.id,
                                              nome: morador.nome,
                                              cpf: morador.cpf,
                                              telefone: morador.telefone,
                                              email: morador.email,
                                              senha: morador.senha,
                                              endereco: morador.endereco,
                                              numeroCasa: morador.numeroCasa,
                                              role: morador.role,
                                              photoURL: photoData,
                                            );

                                            // Atualiza o morador no banco com todos os dados
                                            await _controller.atualizarMorador(moradorAtualizado);

                                            // Atualiza a lista de moradores
                                            setState(() {
                                              _futureMoradores = _controller.buscarTodosMoradores();
                                            });

                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Foto atualizada com sucesso!'),
                                                backgroundColor: Colors.green,
                                              ),
                                            );
                                          } catch (e) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Erro ao atualizar foto: $e'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            TextFormField(
                              controller: nomeController,
                              decoration: const InputDecoration(
                                labelText: 'Nome',
                                prefixIcon: Icon(Icons.person),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor, insira o nome';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: cpfController,
                              decoration: const InputDecoration(
                                labelText: 'CPF',
                                prefixIcon: Icon(Icons.badge),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor, insira o CPF';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: telefoneController,
                              decoration: const InputDecoration(
                                labelText: 'Telefone',
                                prefixIcon: Icon(Icons.phone),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor, insira o telefone';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: enderecoController,
                              decoration: const InputDecoration(
                                labelText: 'Endereço',
                                prefixIcon: Icon(Icons.location_on),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor, insira o endereço';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: numeroCasaController,
                              decoration: const InputDecoration(
                                labelText: 'Número da Casa',
                                prefixIcon: Icon(Icons.home),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor, insira o número da casa';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: emailController,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.email),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor, insira o email';
                                }
                                if (!value.contains('@')) {
                                  return 'Por favor, insira um email válido';
                                }
                                return null;
                              },
                            ),
                            if (!isEditing) ...[
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: senhaController,
                                decoration: const InputDecoration(
                                  labelText: 'Senha',
                                  prefixIcon: Icon(Icons.lock),
                                ),
                                obscureText: true,
                                validator: (value) {
                                  if (!isEditing && (value == null || value.isEmpty)) {
                                    return 'Por favor, insira a senha';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );

    // Verifica se o diálogo foi fechado com sucesso
    if (mounted && dialogResult == true) {
      setState(() {
        _futureMoradores = _controller.buscarTodosMoradores();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing 
            ? 'Morador atualizado com sucesso!' 
            : 'Morador cadastrado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _confirmarExclusao(Morador morador) async {
    final localizations = AppLocalizations.of(context);
    final confirmController = TextEditingController();
    bool isConfirmValid = false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(localizations.translate('confirm_delete')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(localizations.translate('delete_resident_confirmation')),
              const SizedBox(height: 16),
              Text(
                'Digite "excluir" para confirmar:',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: confirmController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'excluir',
                ),
                onChanged: (value) {
                  setState(() {
                    isConfirmValid = value.toLowerCase() == 'excluir';
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(localizations.translate('cancel')),
            ),
            TextButton(
              onPressed: isConfirmValid 
                ? () => Navigator.pop(context, true)
                : null,
              child: Text(
                localizations.translate('delete'),
                style: TextStyle(
                  color: isConfirmValid 
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.38),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      try {
        await _controller.excluirMorador(morador.id);
        setState(() {
          _futureMoradores = _controller.buscarTodosMoradores();
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localizations.translate('resident_deleted')),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${localizations.translate('error_deleting_resident')}: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }
}
