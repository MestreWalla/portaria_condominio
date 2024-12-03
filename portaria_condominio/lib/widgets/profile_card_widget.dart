import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:portaria_condominio/widgets/avatar_widget.dart';
import '../views/settings/settings_view.dart';

class ProfileCardWidget extends StatelessWidget {
  final String? photoURL;
  final String userName;
  final String userEmail;
  final String apartment;

  const ProfileCardWidget({
    super.key,
    required this.photoURL,
    required this.userName,
    required this.userEmail,
    required this.apartment,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
            AvatarWidget(
              photoURL: photoURL,
              userName: userName,
              radius: 24,
              heroTag: 'home_avatar',
            ),
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
  }
}
