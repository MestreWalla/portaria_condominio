import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/message_model.dart';
import '../services/notification_service.dart';

class ChatController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  /// Envia uma mensagem para o Firestore
  Future<void> sendMessage(Message message) async {
    try {
      final chatId = _generateChatId(message.senderId, message.receiverId);

      await _firestore.collection('chats').doc(chatId).set({
        'participants': [message.senderId, message.receiverId],
        'lastMessage': message.content,
        'lastMessageTime': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add(message.toJson());

      // Buscar informações do remetente
      final senderDoc = await _firestore.collection('moradores').doc(message.senderId).get();
      final senderName = senderDoc.data()?['nome'] ?? 'Usuário';

      // Enviar notificação push para o destinatário
      await _notificationService.sendNotificationToUser(
        userId: message.receiverId,
        title: 'Nova mensagem de $senderName',
        body: message.content,
        data: {
          'type': 'chat_message',
          'senderId': message.senderId,
          'chatId': chatId,
        },
      );
    } catch (e) {
      throw Exception('Erro ao enviar mensagem: $e');
    }
  }

  /// Obtém as mensagens de um chat específico
  Stream<List<Message>> getMessages(String userId, String receiverId) {
    final chatId = _generateChatId(userId, receiverId);

    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Message.fromDocument(doc))
            .toList());
  }

  /// Obtém a lista de chats do usuário
  Stream<List<Map<String, dynamic>>> getUserChats(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return {
                'chatId': doc.id,
                'participants': data['participants'] as List<dynamic>,
                'lastMessage': data['lastMessage'] as String?,
                'lastMessageTime': data['lastMessageTime'] as Timestamp?,
                'unreadCount': data['unreadCount'] ?? 0,
              };
            }).toList());
  }

  /// Marca mensagens como entregues
  Future<void> markAsDelivered(String chatId, String messageId) async {
    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({'status': MessageStatus.delivered.index});
    } catch (e) {
      throw Exception('Erro ao marcar mensagem como entregue: $e');
    }
  }

  /// Marca mensagens como lidas
  Future<void> markAsRead(String chatId, String messageId) async {
    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({'status': MessageStatus.read.index});
    } catch (e) {
      throw Exception('Erro ao marcar mensagem como lida: $e');
    }
  }

  /// Marca todas as mensagens não lidas como entregues
  Future<void> markAllAsDelivered(String senderId, String currentUserId) async {
    final chatId = _generateChatId(senderId, currentUserId);
    try {
      final messages = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('receiverId', isEqualTo: currentUserId)
          .where('senderId', isEqualTo: senderId)
          .where('status', isEqualTo: MessageStatus.sent.index)
          .get();

      final batch = _firestore.batch();
      for (var doc in messages.docs) {
        batch.update(doc.reference, {'status': MessageStatus.delivered.index});
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Erro ao marcar mensagens como entregues: $e');
    }
  }

  /// Marca todas as mensagens entregues como lidas
  Future<void> markAllAsRead(String senderId, String currentUserId) async {
    final chatId = _generateChatId(senderId, currentUserId);
    try {
      final messages = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('receiverId', isEqualTo: currentUserId)
          .where('senderId', isEqualTo: senderId)
          .where('status', isEqualTo: MessageStatus.delivered.index)
          .get();

      final batch = _firestore.batch();
      for (var doc in messages.docs) {
        batch.update(doc.reference, {'status': MessageStatus.read.index});
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Erro ao marcar mensagens como lidas: $e');
    }
  }

  /// Atualiza o status online do usuário
  Future<void> updateUserStatus(String userId, bool isOnline) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Erro ao atualizar status do usuário: $e');
    }
  }

  /// Obtém o status online de um usuário
  Stream<bool> getUserOnlineStatus(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snapshot) => snapshot.data()?['isOnline'] ?? false);
  }

  /// Obtém o número de mensagens não lidas
  Future<int> getUnreadMessagesCount(String userId, String chatId) async {
    try {
      final messages = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('receiverId', isEqualTo: userId)
          .where('status', isEqualTo: MessageStatus.sent.index)
          .get();

      return messages.docs.length;
    } catch (e) {
      throw Exception('Erro ao obter contagem de mensagens não lidas: $e');
    }
  }

  /// Obtém o stream de contagem de mensagens não lidas para um chat específico
  Stream<int> getUnreadMessagesCountStream(String userId, String otherUserId) {
    final chatId = _generateChatId(userId, otherUserId);
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('receiverId', isEqualTo: userId)
        .where('status', whereIn: [MessageStatus.sent.index, MessageStatus.delivered.index])
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Deleta uma mensagem
  Future<void> deleteMessage(String chatId, String messageId) async {
    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .delete();
    } catch (e) {
      throw Exception('Erro ao deletar mensagem: $e');
    }
  }

  /// Obtém a lista de chats ativos do usuário (apenas chats com mensagens)
  Stream<List<String>> getActiveChats(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .snapshots()
        .asyncMap((snapshot) async {
          final activeChats = <String>[];
          for (var doc in snapshot.docs) {
            final chatId = doc.id;
            final messagesQuery = await _firestore
                .collection('chats')
                .doc(chatId)
                .collection('messages')
                .limit(1)
                .get();
            
            if (messagesQuery.docs.isNotEmpty) {
              final participants = List<String>.from(doc.data()['participants'] as List);
              final otherUserId = participants.firstWhere((id) => id != userId);
              activeChats.add(otherUserId);
            }
          }
          return activeChats;
        });
  }

  /// Obtém a última mensagem de um chat
  Future<String?> getLastMessage(String userId, String otherUserId) async {
    try {
      final chatId = _generateChatId(userId, otherUserId);
      final querySnapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.data()['content'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint('Erro ao buscar última mensagem: $e');
      return null;
    }
  }

  /// Gera um ID único para o chat com base nos dois usuários envolvidos
  String _generateChatId(String userId, String receiverId) {
    return userId.hashCode <= receiverId.hashCode
        ? '${userId}_$receiverId'
        : '${receiverId}_$userId';
  }

  /// Obtém o stream de contagem de mensagens não lidas para todos os chats
  Stream<int> getTotalUnreadMessagesStream(String currentUserId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .snapshots()
        .asyncMap((snapshot) async {
          int totalUnread = 0;
          for (var doc in snapshot.docs) {
            final chatId = doc.id;
            final messagesQuery = await _firestore
                .collection('chats')
                .doc(chatId)
                .collection('messages')
                .where('receiverId', isEqualTo: currentUserId)
                .where('status', whereIn: [MessageStatus.sent.index, MessageStatus.delivered.index])
                .get();
            totalUnread += messagesQuery.docs.length;
          }
          return totalUnread;
        });
  }
}
