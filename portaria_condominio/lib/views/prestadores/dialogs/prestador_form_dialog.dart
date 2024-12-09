import 'package:flutter/material.dart';
import '../../../models/prestador_model.dart';
import '../../../localizations/app_localizations.dart';
import '../../../widgets/avatar_widget.dart';
import '../../photo_registration/photo_registration_screen.dart';

class PrestadorFormDialog extends StatefulWidget {
  final Prestador? prestador;
  final Function(String nome, String cpf, String empresa, String telefone, String email, String senha) onSave;
  final Function() onPhotoUpdated;

  const PrestadorFormDialog({
    super.key,
    this.prestador,
    required this.onSave,
    required this.onPhotoUpdated,
  });

  @override
  State<PrestadorFormDialog> createState() => _PrestadorFormDialogState();
}

class _PrestadorFormDialogState extends State<PrestadorFormDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController nomeController;
  late final TextEditingController cpfController;
  late final TextEditingController empresaController;
  late final TextEditingController telefoneController;
  late final TextEditingController emailController;
  late final TextEditingController senhaController;

  @override
  void initState() {
    super.initState();
    nomeController = TextEditingController(text: widget.prestador?.nome);
    cpfController = TextEditingController(text: widget.prestador?.cpf);
    empresaController = TextEditingController(text: widget.prestador?.empresa);
    telefoneController = TextEditingController(text: widget.prestador?.telefone);
    emailController = TextEditingController(text: widget.prestador?.email);
    senhaController = TextEditingController(text: widget.prestador?.senha);
  }

  @override
  void dispose() {
    nomeController.dispose();
    cpfController.dispose();
    empresaController.dispose();
    telefoneController.dispose();
    emailController.dispose();
    senhaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  widget.prestador != null
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
                            userId: widget.prestador?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                            returnPhotoData: false,
                          ),
                        ),
                      );
                      if (result == true) {
                        widget.onPhotoUpdated();
                      }
                    },
                    child: Stack(
                      children: [
                        AvatarWidget(
                          photoURL: widget.prestador?.photoURL,
                          userName: widget.prestador?.nome ?? '',
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
                    prefixIcon: const Icon(Icons.business_outlined),
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
                    prefixIcon: const Icon(Icons.phone_outlined),
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
                    prefixIcon: const Icon(Icons.email_outlined),
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
                  decoration: InputDecoration(
                    labelText: localizations.translate('password'),
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(),
                  ),
                  obscureText: true,
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
                      onPressed: () => Navigator.pop(context),
                      child: Text(localizations.translate('cancel')),
                    ),
                    const SizedBox(width: 16),
                    FilledButton.icon(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          widget.onSave(
                            nomeController.text,
                            cpfController.text,
                            empresaController.text,
                            telefoneController.text,
                            emailController.text,
                            senhaController.text,
                          );
                          Navigator.pop(context);
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
      ),
    );
  }
}
