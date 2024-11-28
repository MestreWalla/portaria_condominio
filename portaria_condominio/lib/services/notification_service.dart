import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // Canal de notificação para Android
  static const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  Future<void> initialize() async {
    // Solicitar permissão para notificações
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint('User granted permission: ${settings.authorizationStatus}');

    // Configurar canal de notificação no Android
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Configurar notificações locais
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        _handleNotificationTap(details.payload);
      },
    );

    // Configurar handlers para mensagens FCM
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Obter e salvar token FCM
    String? token = await _fcm.getToken();
    if (token != null) {
      await _saveTokenToFirestore(token);
      // Iniciar monitoramento de notificações pendentes
      _startListeningForPendingNotifications(token);
    }

    // Atualizar token quando for atualizado
    _fcm.onTokenRefresh.listen((String token) {
      _saveTokenToFirestore(token);
      // Atualizar monitoramento com novo token
      _startListeningForPendingNotifications(token);
    });
  }

  // Método para monitorar notificações pendentes
  void _startListeningForPendingNotifications(String token) {
    _firestore
        .collection('notifications_queue')
        .where('token', isEqualTo: token)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snapshot) async {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final notification = change.doc.data();
          if (notification != null) {
            // Mostrar notificação local
            await showLocalNotification(
              title: notification['notification']['title'] ?? '',
              body: notification['notification']['body'] ?? '',
              payload: notification['data']?['type'] == 'chat_message'
                  ? 'chat:${notification['data']['senderId']}'
                  : notification['data']?['notificationId'],
            );

            // Atualizar status da notificação
            await change.doc.reference.update({
              'status': 'delivered',
              'deliveredAt': FieldValue.serverTimestamp(),
            });
          }
        }
      }
    }, onError: (error) {
      debugPrint('Error listening for notifications: $error');
    });
  }

  void _handleNotificationTap(String? payload) {
    if (payload == null) return;

    final context = navigatorKey.currentContext;
    if (context == null) return;

    if (payload.startsWith('chat:')) {
      // Navegar para o chat específico
      final senderId = payload.split(':')[1];
      Navigator.of(context).pushNamed(
        '/chat',
        arguments: {'userId': senderId},
      );
    } else {
      // Navegar para a tela de notificações
      Navigator.of(context).pushNamed('/notifications');
    }
  }

  Future<void> _saveTokenToFirestore(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = _firestore.collection('moradores').doc(user.uid);
      final docSnapshot = await userDoc.get();

      if (docSnapshot.exists) {
        await userDoc.update({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
      } else {
        await userDoc.set({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
          'userId': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      debugPrint('FCM Token saved: $token');
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('Received foreground message: ${message.messageId}');

    RemoteNotification? notification = message.notification;

    if (notification != null) {
      String? payload;
      if (message.data['type'] == 'chat_message') {
        payload = 'chat:${message.data['senderId']}';
      } else {
        payload = message.data['notificationId'];
      }

      await showLocalNotification(
        title: notification.title ?? '',
        body: notification.body ?? '',
        payload: payload,
      );
    }
  }

  void _handleBackgroundMessage(RemoteMessage message) {
    debugPrint('Received background message: ${message.messageId}');
    // Adicione aqui a lógica para lidar com mensagens em background
  }

  // Método para enviar notificação para um usuário específico
  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Buscar o token FCM do usuário
      final userDoc = await _firestore.collection('moradores').doc(userId).get();
      final fcmToken = userDoc.data()?['fcmToken'] as String?;

      if (fcmToken == null) {
        debugPrint('No FCM token found for user: $userId');
        return;
      }

      // Preparar a mensagem
      final message = {
        'notification': {
          'title': title,
          'body': body,
        },
        'data': data ?? {},
        'token': fcmToken,
        'android': {
          'notification': {
            'channel_id': channel.id,
            'priority': 'high',
            'notification_priority': 'PRIORITY_MAX',
            'sound': 'default',
            'default_sound': true,
            'default_vibrate_timings': true,
            'default_light_settings': true,
          },
        },
      };

      // Enviar a mensagem através do Firebase Cloud Functions
      await _firestore.collection('notifications_queue').add({
        ...message,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      debugPrint('Notification queued for user: $userId');
    } catch (e) {
      debugPrint('Error sending notification: $e');
      rethrow;
    }
  }

  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channel.id,
      channel.name,
      channelDescription: 'Canal para notificações importantes',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      enableLights: true,
      enableVibration: true,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('notification'),
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
      ),
      category: AndroidNotificationCategory.message,
    );

    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      NotificationDetails(android: androidDetails),
      payload: payload,
    );
  }

  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }
}

// Handler para mensagens em background
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling a background message: ${message.messageId}');
}
