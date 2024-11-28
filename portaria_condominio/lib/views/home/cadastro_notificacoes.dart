import 'package:flutter/material.dart';

import '../../models/notificacao_model.dart';
import '../../controllers/notificacoes_controller.dart';

class NotificationCreationView extends StatefulWidget {
  const NotificationCreationView({super.key});

  @override
  State<NotificationCreationView> createState() =>
      _NotificationCreationViewState();
}

class _NotificationCreationViewState extends State<NotificationCreationView> {
  final NotificationController notificationController =
      NotificationController();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  bool isLoading = false;

  void _sendNotification() async {
    final title = titleController.text.trim();
    final description = descriptionController.text.trim();

    if (title.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, preencha todos os campos.')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    final notification = NotificationModel(
      id: '', // O Firestore gera automaticamente
      title: title,
      description: description,
      timestamp: DateTime.now(),
      status: 'unread',
    );

    try {
      await notificationController.sendNotification(notification);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notificação enviada com sucesso.')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao enviar notificação: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar Notificação')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Título'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Descrição'),
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _sendNotification,
                    child: const Text('Enviar Notificação'),
                  ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }
}
