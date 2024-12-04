import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../controllers/chat_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../models/message_model.dart';
import 'chat_input_field.dart';
import '../../widgets/avatar_widget.dart';

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
      _updateMessageStatus(widget.receiverId, userId);
      
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

  String _formatMessageDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return 'Hoje';
    } else if (messageDate == yesterday) {
      return 'Ontem';
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }

  Widget _buildDateDivider(DateTime date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _formatMessageDate(date),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          Expanded(
            child: Divider(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = authController.currentUser?.uid;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Chat com ${widget.receiverName}')),
        body: const Center(child: Text('Usuário não autenticado.')),
      );
    }

    return PopScope(
      canPop: true,
      onPopInvoked: (bool didPop) async {
        if (didPop) return;
        Navigator.of(context).pop();
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
              AvatarWidget(
                photoURL: widget.photoURL,
                userName: widget.receiverName,
                radius: 20,
                heroTag: 'avatar_${widget.receiverId}',
              ),
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
                  String? currentDate;
                  List<Widget> messageWidgets = [];

                  for (int i = 0; i < messages.length; i++) {
                    final message = messages[i];
                    final messageDate = DateTime(
                      message.timestamp.year,
                      message.timestamp.month,
                      message.timestamp.day,
                    );
                    final dateStr = messageDate.toString();

                    if (currentDate != dateStr) {
                      currentDate = dateStr;
                      messageWidgets.add(_buildDateDivider(message.timestamp));
                    }

                    final isSentByUser = message.senderId == userId;
                    messageWidgets.add(
                      Padding(
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
                                      ? colorScheme.primary
                                      : colorScheme.surfaceVariant,
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
                                            ? colorScheme.onPrimary
                                            : colorScheme.onSurfaceVariant,
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
                                                ? colorScheme.onPrimary.withOpacity(0.7)
                                                : colorScheme.onSurfaceVariant.withOpacity(0.7),
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
                                                ? colorScheme.onPrimary
                                                : colorScheme.onPrimary.withOpacity(0.7),
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
                      ),
                    );
                  }

                  return ListView.builder(
                    reverse: true,
                    itemCount: messageWidgets.length,
                    itemBuilder: (context, index) => messageWidgets[index],
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
}
