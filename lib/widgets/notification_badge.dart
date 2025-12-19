import 'package:flutter/material.dart';
import '../services/notification_badge_service.dart';

class NotificationBadge extends StatelessWidget {
  final Widget child;
  final Color badgeColor;
  final Color textColor;

  const NotificationBadge({
    super.key,
    required this.child,
    this.badgeColor = Colors. red,
    this.textColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    final notificationService = NotificationBadgeService();

    return StreamBuilder<int>(
      stream: notificationService.getUnreadCountStream(),
      builder: (context, snapshot) {
        final count = snapshot.data ??  0;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            child,
            if (count > 0)
              Positioned(
                right: -6,
                top: -6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 1.5,
                    ),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Center(
                    child: Text(
                      count > 99 ? '99+' : count.toString(),
                      style: TextStyle(
                        color: textColor,
                        fontSize: count > 99 ?  8 : 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Animated notification badge with pulse effect
class AnimatedNotificationBadge extends StatefulWidget {
  final Widget child;
  final Color badgeColor;
  final Color textColor;

  const AnimatedNotificationBadge({
    super.key,
    required this.child,
    this.badgeColor = Colors.red,
    this.textColor = Colors.white,
  });

  @override
  State<AnimatedNotificationBadge> createState() => _AnimatedNotificationBadgeState();
}

class _AnimatedNotificationBadgeState extends State<AnimatedNotificationBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  final _notificationService = NotificationBadgeService();
  int _previousCount = 0;

  @override
  void initState() {
    super. initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super. dispose();
  }

  void _animateBadge(int newCount) {
    if (newCount > _previousCount) {
      _controller.forward(). then((_) => _controller.reverse());
    }
    _previousCount = newCount;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: _notificationService.getUnreadCountStream(),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        
        // Animate when count increases
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _animateBadge(count);
        });

        return Stack(
          clipBehavior: Clip.none,
          children: [
            widget.child,
            if (count > 0)
              Positioned(
                right: -6,
                top: -6,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: widget.badgeColor,
                      shape: BoxShape. circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: widget.badgeColor. withOpacity(0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Center(
                      child: Text(
                        count > 99 ? '99+' : count.toString(),
                        style: TextStyle(
                          color: widget. textColor,
                          fontSize: count > 99 ? 8 : 10,
                          fontWeight: FontWeight. bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}