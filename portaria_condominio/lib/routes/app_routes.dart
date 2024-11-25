import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../views/chat/chat_view.dart';
import '../views/chat/user_list_view.dart';
import '../views/chat/chat_list_view.dart';
import '../views/home/cadastro_notificacoes.dart';
import '../views/home/home_view.dart';
import '../views/home/mapa_view.dart';
import '../views/home/moradores_view.dart';
import '../views/home/notificacoes_view.dart';
import '../views/home/pedidos_view.dart';
import '../views/home/prestadores_view.dart';
import '../views/home/visitas_view.dart';
import '../views/login/cadastro_view.dart';
import '../views/login/login_view.dart';
import '../views/settings/settings_view.dart';

class AppRoutes {
  static const String login = '/login';
  static const String cadastro = '/cadastro';
  static const String home = '/home';
  static const String moradores = '/moradores';
  static const String prestadores = '/prestadores';
  static const String visitas = '/visitas';
  static const String pedidos = '/pedidos';
  static const String notificacoes = '/notificacoes';
  static const String cadastroNotificacoes = '/notificacoesAdmin';
  static const String mapa = '/mapa';
  static const String settings = '/settings';
  static const String usersListView = '/usersListView';
  static const String chat = '/chat';
  static const String chatList = '/chatList';

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final name = settings.name;
    debugPrint('AppRoutes: Generating route for: $name');
    
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null && name != login && name != cadastro) {
      return MaterialPageRoute(builder: (_) => const LoginView());
    }

    final routes = {
      login: (_) => const LoginView(),
      cadastro: (_) => const CadastroView(),
      home: (_) => const HomeView(),
      moradores: (_) => const MoradoresView(),
      prestadores: (_) => PrestadoresView(currentUserId: currentUserId!),
      visitas: (_) => const VisitasView(),
      pedidos: (_) => const PedidosView(),
      notificacoes: (_) => const NotificationsView(),
      mapa: (_) => const MapaView(),
      settings: (_) => const SettingsView(),
      cadastroNotificacoes: (_) => const NotificationCreationView(),
      usersListView: (_) => const UsersListView(),
      chatList: (_) => const ChatListView(),
    };

    final builder = routes[name];
    if (builder != null) {
      debugPrint('AppRoutes: Found builder for route: $name');
      return MaterialPageRoute(builder: builder);
    }

    if (name == chat && settings.arguments is Map<String, dynamic>) {
      final args = settings.arguments as Map<String, dynamic>;
      final receiverId = args['otherUserId'] as String;
      final receiverName = args['userName'] as String? ?? 'Usuário';
      return MaterialPageRoute(
        builder: (_) => ChatView(
          receiverId: receiverId,
          receiverName: receiverName,
        ),
      );
    }

    debugPrint('AppRoutes: Route not found for: $name');
    return _errorRoute();
  }

  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(
      builder: (_) => const Scaffold(
        body: Center(child: Text('Rota não encontrada')),
      ),
    );
  }
}
