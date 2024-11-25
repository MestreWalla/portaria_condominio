import 'package:flutter/material.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/chat_controller.dart';
import '../../controllers/morador_controller.dart';
import '../../controllers/prestador_controller.dart';
import '../../models/morador_model.dart';
import '../../models/prestador_model.dart';
import '../../localizations/app_localizations.dart';
import 'chat_view.dart';

class ChatListView extends StatefulWidget {
  const ChatListView({super.key});

  @override
  State<ChatListView> createState() => _ChatListViewState();
}

class _ChatListViewState extends State<ChatListView> {
  final chatController = ChatController();
  final moradorController = MoradorController();
  final prestadorController = PrestadorController();
  final authController = AuthController();
  
  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final userId = authController.currentUser?.uid;

    if (userId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('chats')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNewChatDialog(userId),
        child: const Icon(Icons.chat_bubble_outline),
      ),
      body: StreamBuilder<List<String>>(
        stream: chatController.getActiveChats(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Erro ao carregar conversas: ${snapshot.error}',
                style: TextStyle(color: colorScheme.error),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    localizations.translate('no_chats'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => _showNewChatDialog(userId),
                    icon: const Icon(Icons.add),
                    label: Text(localizations.translate('start_new_chat')),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final otherUserId = snapshot.data![index];
              return FutureBuilder<Widget>(
                future: _buildChatTile(userId, otherUserId),
                builder: (context, tileSnapshot) {
                  if (tileSnapshot.connectionState == ConnectionState.waiting) {
                    return const ListTile(
                      leading: CircleAvatar(child: Icon(Icons.person)),
                      title: LinearProgressIndicator(),
                    );
                  }
                  return tileSnapshot.data ?? const SizedBox();
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<Widget> _buildChatTile(String currentUserId, String otherUserId) async {
    try {
      final colorScheme = Theme.of(context).colorScheme;
      String? userName;

      // Tenta buscar como morador
      final morador = await moradorController.buscarMoradorPorId(otherUserId);
      if (morador != null) {
        userName = morador.nome;
      } else {
        // Se não for morador, tenta buscar como prestador
        final prestador = await prestadorController.buscarPrestadorPorId(otherUserId);
        if (prestador != null) {
          userName = prestador.nome;
        }
      }

      final lastMessage = await chatController.getLastMessage(currentUserId, otherUserId);

      return ListTile(
        leading: CircleAvatar(
          backgroundColor: colorScheme.primary,
          child: Text(
            userName?.isNotEmpty == true ? userName![0].toUpperCase() : '?',
            style: TextStyle(
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(userName ?? 'Usuário'),
        subtitle: Text(lastMessage ?? 'Sem mensagens'),
        onTap: () {
          Navigator.pushNamed(
            context,
            '/chat',
            arguments: {
              'otherUserId': otherUserId,
              'userName': userName,
            },
          );
        },
      );
    } catch (e) {
      debugPrint('Erro ao construir tile do chat: $e');
      return const SizedBox();
    }
  }

  void _showNewChatDialog(String currentUserId) async {
    final colorScheme = Theme.of(context).colorScheme;
    final localizations = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surfaceVariant.withOpacity(0.95),
      builder: (context) {
        return DefaultTabController(
          length: 2,
          child: Column(
            children: [
              Container(
                color: colorScheme.primaryContainer,
                child: TabBar(
                  labelColor: colorScheme.onPrimaryContainer,
                  unselectedLabelColor: colorScheme.onPrimaryContainer.withOpacity(0.6),
                  indicatorColor: colorScheme.primary,
                  tabs: [
                    Tab(text: localizations.translate('chat_select_residents')),
                    Tab(text: localizations.translate('chat_select_providers')),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  color: colorScheme.surfaceVariant.withOpacity(0.3),
                  child: TabBarView(
                    children: [
                      // Lista de Moradores
                      FutureBuilder<List<Morador>>(
                        future: moradorController.buscarTodosMoradores(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return Center(
                              child: Text(localizations.translate('chat_no_residents')),
                            );
                          }
                          return ListView.builder(
                            itemCount: snapshot.data!.length,
                            itemBuilder: (context, index) {
                              final morador = snapshot.data![index];
                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: colorScheme.primary,
                                    child: Text(
                                      morador.nome[0].toUpperCase(),
                                      style: TextStyle(
                                        color: colorScheme.onPrimary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    morador.nome,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  subtitle: Text(
                                    morador.endereco,
                                    style: TextStyle(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  tileColor: colorScheme.surface,
                                  onTap: () {
                                    Navigator.pop(context);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ChatView(
                                          receiverId: morador.id,
                                          receiverName: morador.nome,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          );
                        },
                      ),
                      // Lista de Prestadores
                      FutureBuilder<List<Prestador>>(
                        future: prestadorController.buscarTodosPrestadores(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return Center(
                              child: Text(localizations.translate('chat_no_providers')),
                            );
                          }
                          return ListView.builder(
                            itemCount: snapshot.data!.length,
                            itemBuilder: (context, index) {
                              final prestador = snapshot.data![index];
                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: colorScheme.secondary,
                                    child: Text(
                                      prestador.nome[0].toUpperCase(),
                                      style: TextStyle(
                                        color: colorScheme.onSecondary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    prestador.nome,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  subtitle: Text(
                                    prestador.empresa,
                                    style: TextStyle(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  tileColor: colorScheme.surface,
                                  onTap: () {
                                    Navigator.pop(context);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ChatView(
                                          receiverId: prestador.id,
                                          receiverName: prestador.nome,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          );
                        },
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
  }
}
