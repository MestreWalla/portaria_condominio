import 'dart:convert';
import 'package:flutter/material.dart';

class AvatarWidget extends StatelessWidget {
  final String? photoURL;
  final String userName;
  final double radius;
  final String? heroTag;

  const AvatarWidget({
    super.key,
    required this.photoURL,
    required this.userName,
    this.radius = 24,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    if (photoURL != null && photoURL!.isNotEmpty) {
      try {
        String base64String;
        if (photoURL!.startsWith('data:image')) {
          base64String = photoURL!.split(',')[1];
        } else {
          base64String = photoURL!;
        }

        final avatar = CircleAvatar(
          radius: radius,
          backgroundImage: MemoryImage(base64Decode(base64String)),
          backgroundColor: colorScheme.surfaceContainerHighest,
          onBackgroundImageError: (exception, stackTrace) {
            debugPrint('Erro ao carregar imagem: $exception');
            return;
          },
        );

        return heroTag != null
            ? Hero(tag: '${heroTag}_${DateTime.now().millisecondsSinceEpoch}', child: avatar)
            : avatar;
      } catch (e) {
        debugPrint('Erro ao decodificar base64: $e');
        return _buildDefaultAvatar(colorScheme);
      }
    }
    return _buildDefaultAvatar(colorScheme);
  }

  Widget _buildDefaultAvatar(ColorScheme colorScheme) {
    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: colorScheme.primary,
      child: Text(
        userName.isNotEmpty ? userName[0].toUpperCase() : '?',
        style: TextStyle(
          color: colorScheme.onPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    return heroTag != null
        ? Hero(tag: '${heroTag}_default_${DateTime.now().millisecondsSinceEpoch}', child: avatar)
        : avatar;
  }
}
