import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../controllers/configuracoes_controller.dart';
import '../../controllers/notificacoes_controller.dart';
import '../../localizations/app_localizations.dart';
import '../../../routes/app_routes.dart';
import '../settings/settings_view.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  /// Obtém o papel (role) do usuário autenticado
  Future<String> _getUserRole() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return 'unknown';
    }

    final doc = await FirebaseFirestore.instance
        .collection('moradores')
        .doc(user.uid)
        .get();
    if (doc.exists) {
      return doc.data()?['role'] ?? 'unknown';
    }
    return 'unknown';
  }

  /// Obtém os dados do usuário do Firestore
  Future<Map<String, dynamic>?> _getUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final doc = await FirebaseFirestore.instance
        .collection('moradores')
        .doc(user.uid)
        .get();

    return doc.data();
  }

  /// Widget de menu item
  Widget _menuItem(
    BuildContext context,
    String label,
    IconData icon,
    String route,
    ConfiguracoesController configController, {
    int notificationCount = 0,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    size: 48,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 16),
                  Text(
                    label,
                    style: TextStyle(
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
              if (notificationCount > 0)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.error,
                  ),
                  child: Text(
                    notificationCount.toString(),
                    style: TextStyle(
                      color: colorScheme.onError,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(String? photoURL, String userName, ThemeData theme) {
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
            backgroundColor: theme.colorScheme.onPrimary,
            onBackgroundImageError: (exception, stackTrace) {
              debugPrint('Erro ao carregar imagem: $exception');
              return;
            },
          ),
        );
      } catch (e) {
        debugPrint('Erro ao decodificar base64: $e');
        return _buildDefaultAvatar(userName, theme);
      }
    }
    return _buildDefaultAvatar(userName, theme);
  }

  Widget _buildDefaultAvatar(String userName, ThemeData theme) {
    return Hero(
      tag: 'avatar_default_${DateTime.now().millisecondsSinceEpoch}',
      child: CircleAvatar(
        radius: 30,
        backgroundColor: theme.colorScheme.onPrimary,
        child: Text(
          userName[0].toUpperCase(),
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(
      BuildContext context, ConfiguracoesController configController) {
    final theme = Theme.of(context);

    return FutureBuilder<Map<String, dynamic>?>(
      future: _getUserData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final userData = snapshot.data;
        final user = FirebaseAuth.instance.currentUser;
        final userName = userData?['nome'] ??
            user?.displayName ??
            AppLocalizations.of(context).translate('user');
        final userEmail = userData?['email'] ?? user?.email ?? '';
        final apartment = userData?['apartamento'] ?? '';
        final photoURL = userData?['photoURL'];

        return Card(
          elevation: 0,
          color: theme.colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ExpansionTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            collapsedShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: theme.colorScheme.primary,
            collapsedBackgroundColor: theme.colorScheme.primary,
            tilePadding: const EdgeInsets.all(16.0),
            title: Row(
              children: [
                _buildAvatar(photoURL, userName, theme),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        userEmail,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onPrimary.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        apartment,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onPrimary.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            trailing: Icon(
              Icons.expand_more,
              color: theme.colorScheme.onPrimary,
            ),
            children: [
              Container(
                color: theme.colorScheme.primary,
                child: Column(
                  children: [
                    const Divider(height: 1, color: Colors.white24),
                    ListTile(
                      leading: Icon(
                        Icons.settings,
                        color: theme.colorScheme.onPrimary,
                      ),
                      title: Text(
                        'Configurações',
                        style: TextStyle(
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                      onTap: () {
                        debugPrint('Navegando para configurações...');
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SettingsView(),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: Icon(
                        Icons.person,
                        color: theme.colorScheme.onPrimary,
                      ),
                      title: Text(
                        'Perfil',
                        style: TextStyle(
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                      onTap: () => Navigator.pushNamed(context, '/profile'),
                    ),
                    ListTile(
                      leading: Icon(
                        Icons.logout,
                        color: theme.colorScheme.onPrimary,
                      ),
                      title: Text(
                        'Sair',
                        style: TextStyle(
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                      onTap: () async {
                        await FirebaseAuth.instance.signOut();
                        if (context.mounted) {
                          Navigator.pushReplacementNamed(context, '/login');
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final configController = Provider.of<ConfiguracoesController>(context);
    final localizations = AppLocalizations.of(context);
    final notificationController = NotificationController();

    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<int>(
          stream: notificationController.getUnreadNotificationCount(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                  child: Text(localizations.translate('error_fetching_data')));
            }

            final notificationCount = snapshot.data ?? 0;

            return FutureBuilder<String>(
              future: _getUserRole(),
              builder: (context, roleSnapshot) {
                if (roleSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (roleSnapshot.hasError) {
                  return Center(
                      child:
                          Text(localizations.translate('error_fetching_role')));
                }

                final userRole = roleSnapshot.data ?? 'unknown';

                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildProfileCard(context, configController),
                    if (userRole == 'admin' || userRole == 'portaria')
                      _menuItem(
                        context,
                        localizations.translate('residents'),
                        Icons.people,
                        '/moradores',
                        configController,
                      ),
                    if (userRole != 'visitor')
                      _menuItem(
                        context,
                        localizations.translate('providers'),
                        Icons.work,
                        '/prestadores',
                        configController,
                      ),
                    if (userRole != 'visitor')
                      _menuItem(
                        context,
                        localizations.translate('visits'),
                        Icons.person_add,
                        '/visitas',
                        configController,
                      ),
                    _menuItem(
                      context,
                      localizations.translate('orders'),
                      Icons.shopping_cart,
                      '/pedidos',
                      configController,
                    ),
                    _menuItem(
                      context,
                      localizations.translate('notifications'),
                      Icons.notifications,
                      '/notificacoes',
                      configController,
                      notificationCount: notificationCount,
                    ),
                    _menuItem(
                      context,
                      localizations.translate('chats'),
                      Icons.chat,
                      AppRoutes.chatList,
                      configController,
                    ),
                    if (userRole == 'admin')
                      _menuItem(
                        context,
                        localizations.translate('new_notification'),
                        Icons.notification_add,
                        '/notificacoesAdmin',
                        configController,
                      ),
                    if (userRole == 'admin' || userRole == 'portaria')
                      _menuItem(
                        context,
                        localizations.translate('qr_code_reader'),
                        Icons.qr_code_scanner,
                        '/qr-scanner',
                        configController,
                      ),
                    _menuItem(
                      context,
                      localizations.translate('map'),
                      Icons.map,
                      '/mapa',
                      configController,
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
