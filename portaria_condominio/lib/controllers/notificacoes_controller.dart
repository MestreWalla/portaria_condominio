import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:portaria_condominio/models/notificacao_model.dart';
import 'package:portaria_condominio/services/notification_service.dart';

class NotificationController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  /// Enviar notificação (usado pela portaria)
  Future<void> sendNotification(NotificationModel notification) async {
    try {
      // Salvar a notificação no Firestore
      final docRef = await _firestore.collection('notifications').add(notification.toJson());
      
      // Buscar todos os usuários ativos
      final usersSnapshot = await _firestore
          .collection('users')
          .where('status', isEqualTo: 'active')
          .get();

      // Enviar notificação push para cada usuário
      for (var userDoc in usersSnapshot.docs) {
        // Enviar notificação via FCM
        await _notificationService.sendNotificationToUser(
          userId: userDoc.id,
          title: notification.title,
          body: notification.description,
          data: {
            'notificationId': docRef.id,
            'type': 'new_notification',
            'timestamp': notification.timestamp.toIso8601String(),
          },
        );

        // Mostrar notificação local
        await _notificationService.showLocalNotification(
          title: notification.title,
          body: notification.description,
          payload: docRef.id,
        );
      }
    } catch (e) {
      debugPrint('Erro ao enviar notificação: $e');
      throw Exception('Erro ao enviar notificação: $e');
    }
  }

  /// Atualiza o status da notificação no Firestore
  Future<void> updateNotificationStatus(NotificationModel notification) async {
    try {
      await _firestore.collection('notifications').doc(notification.id).update({
        'status': notification.status,
      });
    } catch (e) {
      throw Exception('Erro ao atualizar o status da notificação: $e');
    }
  }

  /// Obter todas as notificações para o usuário autenticado
  Stream<List<NotificationModel>> getNotifications() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromDocument(doc))
            .toList());
  }

  /// Obtém um stream que envia a quantidade de notificações não lidas
  Stream<int> getUnreadNotificationCount() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Stream.value(0);
    }

    return _firestore
        .collection('notifications')
        .where('status', isEqualTo: 'unread')
        .snapshots()
        .map((snapshot) => snapshot.size);
  }
}
