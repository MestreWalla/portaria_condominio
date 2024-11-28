import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../localizations/app_localizations.dart';
import '../photo_registration/photo_registration_screen.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _cpfController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _enderecoController = TextEditingController();
  final _numeroCasaController = TextEditingController();
  bool _isLoading = true;
  bool _isEditing = false;
  String _role = '';
  String? _photoURL;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _cpfController.dispose();
    _telefoneController.dispose();
    _enderecoController.dispose();
    _numeroCasaController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Primeiro, tenta buscar nos moradores
        var userData = await FirebaseFirestore.instance
            .collection('moradores')
            .doc(user.uid)
            .get();

        // Se não encontrar nos moradores, tenta nas portarias
        if (!userData.exists) {
          userData = await FirebaseFirestore.instance
              .collection('portarias')
              .doc(user.uid)
              .get();
        }

        if (userData.exists) {
          if (mounted) {
            setState(() {
              _nameController.text = userData.data()?['nome'] ?? '';
              _emailController.text = userData.data()?['email'] ?? '';
              _cpfController.text = userData.data()?['cpf'] ?? '';
              _telefoneController.text = userData.data()?['telefone'] ?? '';
              _enderecoController.text = userData.data()?['endereco'] ?? '';
              _numeroCasaController.text = userData.data()?['numeroCasa'] ?? '';
              _role = userData.data()?['role'] ?? 'morador';
              _photoURL = userData.data()?['photoURL'];
              _isLoading = false;
            });
          }
        } else {
          if (mounted) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context).translate('user_not_found'),
                ),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context).translate('not_authenticated'),
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).translate('error_loading_profile'),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // Primeiro, verifica em qual coleção o usuário está
          var userDoc = await FirebaseFirestore.instance
              .collection('moradores')
              .doc(user.uid)
              .get();

          final collection = userDoc.exists ? 'moradores' : 'portarias';

          await FirebaseFirestore.instance
              .collection(collection)
              .doc(user.uid)
              .update({
            'nome': _nameController.text,
            'email': _emailController.text,
            'cpf': _cpfController.text,
            'telefone': _telefoneController.text,
            'endereco': _enderecoController.text,
            'numeroCasa': _numeroCasaController.text,
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context).translate('profile_updated'),
                ),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)
                    .translate('error_updating_profile'),
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isEditing = false;
          });
        }
      }
    }
  }

  Widget _buildAvatar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_photoURL != null && _photoURL!.isNotEmpty) {
      try {
        String base64String;
        if (_photoURL!.startsWith('data:image')) {
          base64String = _photoURL!.split(',')[1];
        } else {
          base64String = _photoURL!;
        }

        return Hero(
          tag: 'profile_avatar',
          child: Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: MemoryImage(base64Decode(base64String)),
                backgroundColor: colorScheme.primaryContainer,
                onBackgroundImageError: (exception, stackTrace) {
                  debugPrint('Erro ao carregar imagem: $exception');
                  return;
                },
              ),
              if (_isEditing)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.camera_alt,
                        color: colorScheme.onPrimary,
                        size: 20,
                      ),
                      onPressed: () => _updatePhoto(context),
                    ),
                  ),
                ),
            ],
          ),
        );
      } catch (e) {
        debugPrint('Erro ao decodificar base64: $e');
        return _buildDefaultAvatar(context);
      }
    }
    return _buildDefaultAvatar(context);
  }

  Widget _buildDefaultAvatar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Hero(
      tag: 'profile_avatar',
      child: Stack(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: colorScheme.primaryContainer,
            child: Text(
              _nameController.text.isNotEmpty
                  ? _nameController.text[0].toUpperCase()
                  : '?',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          if (_isEditing)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.camera_alt,
                    color: colorScheme.onPrimary,
                    size: 20,
                  ),
                  onPressed: () => _updatePhoto(context),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _updatePhoto(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final photoData = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => PhotoRegistrationScreen(
          userType: _role == 'porteiro' ? 'doorman' : 'resident',
          userId: user.uid,
          returnPhotoData: true,
        ),
      ),
    );

    if (photoData != null && mounted) {
      try {
        final collection = _role == 'porteiro' ? 'portarias' : 'moradores';
        await FirebaseFirestore.instance
            .collection(collection)
            .doc(user.uid)
            .update({'photoURL': photoData});

        setState(() => _photoURL = photoData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context).translate('photo_updated'),
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
                AppLocalizations.of(context).translate('error_updating_photo'),
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context).translate('loading_profile'),
                style: theme.textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).translate('profile'),
          style: theme.textTheme.titleLarge,
        ),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveProfile,
              tooltip: AppLocalizations.of(context).translate('save_profile'),
            )
          else
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
              tooltip: AppLocalizations.of(context).translate('edit_profile'),
            ),
        ],
        backgroundColor: colorScheme.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: _buildAvatar(context),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  _role.toUpperCase(),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).translate('name'),
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: _isEditing
                      ? colorScheme.surface
                      : colorScheme.surfaceContainerHighest,
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                enabled: _isEditing,
                style: theme.textTheme.bodyLarge,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppLocalizations.of(context)
                        .translate('name_required');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).translate('email'),
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: _isEditing
                      ? colorScheme.surface
                      : colorScheme.surfaceContainerHighest,
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
                enabled: _isEditing,
                style: theme.textTheme.bodyLarge,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppLocalizations.of(context)
                        .translate('email_required');
                  }
                  if (!value.contains('@')) {
                    return AppLocalizations.of(context)
                        .translate('invalid_email');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cpfController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).translate('cpf'),
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: _isEditing
                      ? colorScheme.surface
                      : colorScheme.surfaceContainerHighest,
                  prefixIcon: const Icon(Icons.badge_outlined),
                ),
                enabled: _isEditing,
                style: theme.textTheme.bodyLarge,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppLocalizations.of(context)
                        .translate('cpf_required');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _telefoneController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).translate('phone'),
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: _isEditing
                      ? colorScheme.surface
                      : colorScheme.surfaceContainerHighest,
                  prefixIcon: const Icon(Icons.phone_outlined),
                ),
                enabled: _isEditing,
                style: theme.textTheme.bodyLarge,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppLocalizations.of(context)
                        .translate('phone_required');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _enderecoController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).translate('address'),
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: _isEditing
                      ? colorScheme.surface
                      : colorScheme.surfaceContainerHighest,
                  prefixIcon: const Icon(Icons.home_outlined),
                ),
                enabled: _isEditing,
                style: theme.textTheme.bodyLarge,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppLocalizations.of(context)
                        .translate('address_required');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _numeroCasaController,
                decoration: InputDecoration(
                  labelText:
                      AppLocalizations.of(context).translate('house_number'),
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: _isEditing
                      ? colorScheme.surface
                      : colorScheme.surfaceContainerHighest,
                  prefixIcon: const Icon(Icons.numbers_outlined),
                ),
                enabled: _isEditing,
                style: theme.textTheme.bodyLarge,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppLocalizations.of(context)
                        .translate('house_number_required');
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
