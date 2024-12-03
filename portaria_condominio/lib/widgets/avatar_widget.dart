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
    final avatar = _createAvatar(colorScheme);
    
    return _wrapWithHero(avatar);
  }

  Widget _createAvatar(ColorScheme colorScheme) {
    if (photoURL != null && photoURL!.isNotEmpty) {
      return _createPhotoAvatar(colorScheme);
    }
    return _createDefaultAvatar(colorScheme);
  }

  Widget _createPhotoAvatar(ColorScheme colorScheme) {
    try {
      final base64String = photoURL!.startsWith('data:image') 
          ? photoURL!.split(',')[1]
          : photoURL!;

      return CircleAvatar(
        radius: radius,
        backgroundImage: MemoryImage(base64Decode(base64String)),
        backgroundColor: colorScheme.surfaceContainerHighest,
        onBackgroundImageError: (exception, stackTrace) {
          debugPrint('Erro ao carregar imagem: $exception');
          return;
        },
      );
    } catch (e) {
      debugPrint('Erro ao decodificar base64: $e');
      return _createDefaultAvatar(colorScheme);
    }
  }

  Widget _createDefaultAvatar(ColorScheme colorScheme) {
    return CircleAvatar(
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
  }

  Widget _wrapWithHero(Widget avatar) {
    if (heroTag == null) return avatar;
    
    final tag = avatar is CircleAvatar && avatar.backgroundImage == null
        ? '${heroTag}_default_${DateTime.now().millisecondsSinceEpoch}'
        : '${heroTag}_${DateTime.now().millisecondsSinceEpoch}';
        
    return Hero(tag: tag, child: avatar);
  }
}
