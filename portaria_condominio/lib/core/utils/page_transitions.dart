import 'package:flutter/material.dart';

class CustomPageTransitionsBuilder extends PageTransitionsBuilder {
  const CustomPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Animação de entrada
    final slideIn = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: Curves.easeInOut,
    ));

    // Animação de saída
    final slideOut = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-0.3, 0.0),
    ).animate(CurvedAnimation(
      parent: secondaryAnimation,
      curve: Curves.easeInOut,
    ));

    // Escala para a página anterior
    final scaleOut = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(
      parent: secondaryAnimation,
      curve: Curves.easeInOut,
    ));

    return SlideTransition(
      position: slideIn,
      child: SlideTransition(
        position: slideOut,
        child: ScaleTransition(
          scale: scaleOut,
          child: child,
        ),
      ),
    );
  }
}
