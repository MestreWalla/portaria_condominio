// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// class UsersListView extends StatefulWidget {
//   const UsersListView({super.key});

//   @override
//   State<UsersListView> createState() => _UsersListViewState();
// }

// class _UsersListViewState extends State<UsersListView> {
//   Widget _buildAvatar(String? photoURL, ColorScheme colorScheme, String userName) {
//     if (photoURL != null && photoURL.isNotEmpty) {
//       try {
//         String base64String;
//         if (photoURL.startsWith('data:image')) {
//           base64String = photoURL.split(',')[1];
//         } else {
//           base64String = photoURL;
//         }

//         return Hero(
//           tag: 'avatar_${DateTime.now().millisecondsSinceEpoch}',
//           child: CircleAvatar(
//             radius: 24,
//             backgroundImage: MemoryImage(base64Decode(base64String)),
//             backgroundColor: colorScheme.surfaceContainerHighest,
//             onBackgroundImageError: (exception, stackTrace) {
//               debugPrint('Erro ao carregar imagem: $exception');
//               return;
//             },
//           ),
//         );
//       } catch (e) {
//         debugPrint('Erro ao decodificar base64: $e');
//         return _buildDefaultAvatar(colorScheme, userName);
//       }
//     }
//     return _buildDefaultAvatar(colorScheme, userName);
//   }

//   Widget _buildDefaultAvatar(ColorScheme colorScheme, String userName) {
//     return Hero(
//       tag: 'avatar_default_${DateTime.now().millisecondsSinceEpoch}',
//       child: CircleAvatar(
//         radius: 24,
//         backgroundColor: colorScheme.primary,
//         child: Text(
//           userName.isNotEmpty ? userName[0].toUpperCase() : '?',
//           style: TextStyle(
//             color: colorScheme.onPrimary,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final colorScheme = Theme.of(context).colorScheme;

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Usuários'),
//         centerTitle: true,
//         backgroundColor: colorScheme.surface,
//         surfaceTintColor: colorScheme.surfaceTint,
//       ),
//       body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
//         stream: FirebaseFirestore.instance.collection('moradores').snapshots(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return Center(
//               child: CircularProgressIndicator(
//                 color: colorScheme.primary,
//               ),
//             );
//           }

//           if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//             return Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(
//                     Icons.person_off_outlined,
//                     size: 48,
//                     color: colorScheme.onSurfaceVariant,
//                   ),
//                   const SizedBox(height: 16),
//                   Text(
//                     'Nenhum usuário encontrado.',
//                     style: TextStyle(
//                       color: colorScheme.onSurfaceVariant,
//                       fontSize: 16,
//                     ),
//                   ),
//                 ],
//               ),
//             );
//           }

//           final users = snapshot.data!.docs;

//           return ListView.builder(
//             itemCount: users.length,
//             padding: const EdgeInsets.symmetric(vertical: 8),
//             itemBuilder: (context, index) {
//               final user = users[index];
//               final userId = user.id;
//               final userName = user['nome'] ?? 'Usuário';
//               final photoURL = user['photoURL'];

//               return Card(
//                 margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
//                 elevation: 0,
//                 color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
//                 child: ListTile(
//                   contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
//                   leading: _buildAvatar(photoURL, colorScheme, userName),
//                   title: Text(
//                     userName,
//                     style: TextStyle(
//                       color: colorScheme.onSurface,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                   subtitle: Text(
//                     'Toque para iniciar conversa',
//                     style: TextStyle(
//                       color: colorScheme.onSurfaceVariant,
//                       fontSize: 12,
//                     ),
//                   ),
//                   trailing: Icon(
//                     Icons.arrow_forward_ios,
//                     size: 16,
//                     color: colorScheme.onSurfaceVariant,
//                   ),
//                   onTap: () {
//                     Navigator.pushNamed(
//                       context,
//                       '/chat',
//                       arguments: {
//                         'id': userId,
//                         'nome': userName,
//                       },
//                     );
//                   },
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }
