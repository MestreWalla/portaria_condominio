import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:convert';
import '../../controllers/chat_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../models/message_model.dart';
import 'chat_input_field.dart';

class ChatView extends StatefulWidget {
  final String receiverId;
  final String receiverName;
  final String? photoURL;

  const ChatView({
    super.key,
    required this.receiverId,
    required this.receiverName,
    this.photoURL,
  });

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final chatController = ChatController();
  final authController = AuthController();
  StreamSubscription<List<Message>>? _messageSubscription;

  @override
  void initState() {
    super.initState();
    final userId = authController.currentUser?.uid;
    if (userId != null) {
      // Marca as mensagens como lidas assim que o chat é aberto
      _updateMessageStatus(widget.receiverId, userId);
      
      // Escuta novas mensagens e marca como lida automaticamente
      _messageSubscription = chatController
          .getMessages(userId, widget.receiverId)
          .listen((messages) {
        final unreadMessages = messages.where((msg) => 
          msg.senderId == widget.receiverId && 
          msg.receiverId == userId &&
          msg.status != MessageStatus.read
        );
        
        if (unreadMessages.isNotEmpty) {
          _updateMessageStatus(widget.receiverId, userId);
        }
      });
    }
  }

  void _updateMessageStatus(String receiverId, String userId) async {
    try {
      await chatController.markAllAsDelivered(receiverId, userId);
      await chatController.markAllAsRead(receiverId, userId);
    } catch (e) {
      debugPrint('Erro ao atualizar status das mensagens: $e');
    }
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    super.dispose();
  }

  Widget _buildAvatar(String? photoURL, ColorScheme colorScheme, String userName) {
    debugPrint('Building avatar for user: $userName');
    debugPrint('Photo URL present: ${photoURL != null}');
    if (photoURL != null) {
      debugPrint('Photo URL length: ${photoURL.length}');
      debugPrint('Photo URL start: ${photoURL.substring(0, photoURL.length.clamp(0, 50))}...');
    }

    if (photoURL != null && photoURL.isNotEmpty) {
      try {
        String base64String;
        
        // Remover cabeçalho data:image se presente
        if (photoURL.startsWith('data:image')) {
          debugPrint('Foto contém cabeçalho data:image, removendo...');
          base64String = photoURL.split(',')[1];
        } else {
          debugPrint('Usando string base64 diretamente');
          base64String = photoURL;
        }

        // Remover espaços em branco e quebras de linha
        base64String = base64String.trim().replaceAll(RegExp(r'[\n\r\s]'), '');
        debugPrint('Base64 string length após limpeza: ${base64String.length}');

        // Validar se é uma string base64 válida
        try {
          final decoded = base64Decode(base64String);
          debugPrint('Base64 decodificado com sucesso: ${decoded.length} bytes');

          return Hero(
            tag: 'avatar_${widget.receiverId}',
            child: CircleAvatar(
              radius: 20,
              backgroundImage: MemoryImage(decoded),
              backgroundColor: colorScheme.surfaceContainerHighest,
              onBackgroundImageError: (exception, stackTrace) {
                debugPrint('Erro ao carregar imagem: $exception');
                debugPrint('Stack trace: $stackTrace');
                return;
              },
            ),
          );
        } catch (e) {
          debugPrint('Erro ao decodificar base64: $e');
          return _buildDefaultAvatar(colorScheme, userName);
        }
      } catch (e) {
        debugPrint('Erro ao processar imagem: $e');
        return _buildDefaultAvatar(colorScheme, userName);
      }
    }

    debugPrint('Usando avatar padrão para $userName');
    return _buildDefaultAvatar(colorScheme, userName);
  }

  Widget _buildDefaultAvatar(ColorScheme colorScheme, String userName) {
    return Hero(
      tag: 'avatar_default_${widget.receiverId}',
      child: CircleAvatar(
        radius: 20,
        backgroundColor: colorScheme.primary,
        child: Text(
          userName.isNotEmpty ? userName[0].toUpperCase() : '?',
          style: TextStyle(
            color: colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = authController.currentUser?.uid;
    final colorScheme = Theme.of(context).colorScheme;

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Chat com ${widget.receiverName}')),
        body: const Center(child: Text('Usuário não autenticado.')),
      );
    }

    _generateChatId(userId, widget.receiverId);

    return PopScope(
      canPop: true,
      onPopInvoked: (bool didPop) async {
        if (didPop) {
          // Handle the pop if needed
          return;
        }
        final NavigatorState navigator = Navigator.of(context);
        navigator.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          titleSpacing: 0,
          title: Row(
            children: [
              _buildAvatar(widget.photoURL, colorScheme, widget.receiverName),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.receiverName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<Message>>(
                stream: chatController.getMessages(userId, widget.receiverId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('Nenhuma mensagem ainda.'));
                  }

                  final messages = snapshot.data!;

                  return ListView.builder(
                    reverse: true,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isSentByUser = message.senderId == userId;

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 16,
                        ),
                        child: Row(
                          mainAxisAlignment: isSentByUser
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                          children: [
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isSentByUser
                                      ? Colors.blueAccent
                                      : Colors.grey[300],
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(12),
                                    topRight: const Radius.circular(12),
                                    bottomLeft: isSentByUser
                                        ? const Radius.circular(12)
                                        : const Radius.circular(0),
                                    bottomRight: isSentByUser
                                        ? const Radius.circular(0)
                                        : const Radius.circular(12),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      message.content,
                                      style: TextStyle(
                                        color: isSentByUser
                                            ? Colors.white
                                            : Colors.black87,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          DateFormat('HH:mm')
                                              .format(message.timestamp),
                                          style: TextStyle(
                                            color: isSentByUser
                                                ? Colors.white70
                                                : Colors.black54,
                                            fontSize: 12,
                                          ),
                                        ),
                                        if (isSentByUser) ...[
                                          const SizedBox(width: 4),
                                          Icon(
                                            message.status == MessageStatus.sent
                                                ? Icons.check
                                                : message.status == MessageStatus.delivered
                                                    ? Icons.done_all
                                                    : Icons.done_all,
                                            size: 16,
                                            color: message.status == MessageStatus.read
                                                ? Colors.blue[100]
                                                : Colors.white70,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            ChatInputField(
              chatController: chatController,
              receiverId: widget.receiverId,
              onSendMessage: (content) async {
                final message = Message(
                  senderId: userId,
                  receiverId: widget.receiverId,
                  content: content,
                  timestamp: DateTime.now(),
                  status: MessageStatus.sent,
                );
                await chatController.sendMessage(message);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _generateChatId(String userId, String receiverId) {
    return userId.hashCode <= receiverId.hashCode
        ? '${userId}_$receiverId'
        : '${receiverId}_$userId';
  }
}
