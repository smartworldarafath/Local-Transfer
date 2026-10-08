import 'package:flutter/material.dart';

/// A squircle button card for the SendTab Selection grid, matching 1791382743298.jpg.
/// Features a dark rounded squircle container (radius ~24), icon, label, and subtitle.
class BigButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final bool filled;
  final double? width;
  final VoidCallback onTap;

  const BigButton({
    super.key,
    required this.icon,
    required this.label,
    this.subtitle,
    required this.filled,
    this.width,
    required this.onTap,
  });

  @override
  State<BigButton> createState() => _BigButtonState();
}

class _BigButtonState extends State<BigButton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = widget.filled
        ? theme.colorScheme.primary
        : (isDark ? const Color(0xFF1E2430) : const Color(0xFFF0F3F8));
    final textColor = widget.filled
        ? theme.colorScheme.onPrimary
        : (isDark ? Colors.white : Colors.black87);
    final subtitleColor = widget.filled
        ? theme.colorScheme.onPrimary.withOpacity(0.8)
        : (isDark ? Colors.white60 : Colors.black54);
    final iconColor = widget.filled
        ? theme.colorScheme.onPrimary
        : (isDark ? Colors.white.withOpacity(0.9) : Colors.black87);

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: child,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTapDown: (_) => _controller.forward(),
          onTapUp: (_) => _controller.reverse(),
          onTapCancel: () => _controller.reverse(),
          onTap: widget.onTap,
          child: Container(
            width: widget.width,
            height: 112,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.07) : Colors.black.withOpacity(0.06),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.icon, size: 28, color: iconColor),
                const SizedBox(height: 8),
                Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                if (widget.subtitle != null && widget.subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    widget.subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: subtitleColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
