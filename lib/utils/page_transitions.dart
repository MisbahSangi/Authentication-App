import 'package:flutter/material.dart';

class PageTransitions {
  /// Fade transition
  static PageRouteBuilder fade(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  /// Slide from right transition
  static PageRouteBuilder slideRight(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);

        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  /// Slide from bottom transition
  static PageRouteBuilder slideUp(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;

        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);

        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
  }

  /// Scale transition
  static PageRouteBuilder scale(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const curve = Curves.easeOutBack;
        var curvedAnimation = CurvedAnimation(parent: animation, curve: curve);

        return ScaleTransition(
          scale: curvedAnimation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
  }

  /// Scale with fade transition
  static PageRouteBuilder scaleWithFade(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const curve = Curves.easeOutCubic;
        var curvedAnimation = CurvedAnimation(parent: animation, curve: curve);

        return FadeTransition(
          opacity: curvedAnimation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.0).animate(curvedAnimation),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  /// Rotation transition
  static PageRouteBuilder rotate(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const curve = Curves. easeInOut;
        var curvedAnimation = CurvedAnimation(parent: animation, curve: curve);

        return RotationTransition(
          turns: Tween<double>(begin: 0.5, end: 1.0). animate(curvedAnimation),
          child: FadeTransition(
            opacity: curvedAnimation,
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 500),
    );
  }

  /// Slide and fade transition
  static PageRouteBuilder slideAndFade(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.2, 0.0);
        const end = Offset.zero;
        const curve = Curves. easeOut;

        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: offsetAnimation,
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  /// Custom hero-style transition
  static PageRouteBuilder hero(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          ),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
  }
}

/// Extension for easy navigation with transitions
extension NavigatorExtension on BuildContext {
  void pushWithTransition(Widget page, {TransitionType type = TransitionType. slideRight}) {
    PageRouteBuilder route;
    
    switch (type) {
      case TransitionType.fade:
        route = PageTransitions.fade(page);
        break;
      case TransitionType.slideRight:
        route = PageTransitions.slideRight(page);
        break;
      case TransitionType.slideUp:
        route = PageTransitions.slideUp(page);
        break;
      case TransitionType.scale:
        route = PageTransitions.scale(page);
        break;
      case TransitionType. scaleWithFade:
        route = PageTransitions.scaleWithFade(page);
        break;
      case TransitionType.rotate:
        route = PageTransitions.rotate(page);
        break;
      case TransitionType.slideAndFade:
        route = PageTransitions.slideAndFade(page);
        break;
    }
    
    Navigator.push(this, route);
  }

  void pushReplacementWithTransition(Widget page, {TransitionType type = TransitionType.fade}) {
    PageRouteBuilder route;
    
    switch (type) {
      case TransitionType.fade:
        route = PageTransitions.fade(page);
        break;
      case TransitionType.slideRight:
        route = PageTransitions.slideRight(page);
        break;
      case TransitionType.slideUp:
        route = PageTransitions.slideUp(page);
        break;
      case TransitionType.scale:
        route = PageTransitions.scale(page);
        break;
      case TransitionType.scaleWithFade:
        route = PageTransitions. scaleWithFade(page);
        break;
      case TransitionType.rotate:
        route = PageTransitions.rotate(page);
        break;
      case TransitionType.slideAndFade:
        route = PageTransitions.slideAndFade(page);
        break;
    }
    
    Navigator.pushReplacement(this, route);
  }
}

enum TransitionType {
  fade,
  slideRight,
  slideUp,
  scale,
  scaleWithFade,
  rotate,
  slideAndFade,
}