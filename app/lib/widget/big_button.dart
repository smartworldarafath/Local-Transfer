import 'package:flutter/material.dart';
import 'package:localsend_app/widget/liquid_glass.dart';
import 'package:localsend_app/widget/responsive_builder.dart';

class BigButton extends StatelessWidget {
  static const double desktopWidth = 100.0;
  static const double mobileWidth = 90.0;

  final IconData icon;
  final String label;
  final bool filled;
  final double? width;
  final VoidCallback onTap;

  const BigButton({
    required this.icon,
    required this.label,
    required this.filled,
    this.width,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final sizingInformation = SizingInformation(MediaQuery.sizeOf(context).width);
    final buttonWidth = width ?? (sizingInformation.isDesktop ? desktopWidth : mobileWidth);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final primaryGlassTint = filled
        ? colorScheme.primary.withOpacity(isDark ? 0.40 : 0.75)
        : (isDark ? Colors.white.withOpacity(0.10) : colorScheme.primary.withOpacity(0.12));
    final textColor = filled ? colorScheme.onPrimary : colorScheme.onSurface;

    return SizedBox(
      width: buttonWidth,
      height: 65.0,
      child: LiquidGlassButton(
        borderRadius: BorderRadius.circular(12),
        tintColor: primaryGlassTint,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: textColor),
            FittedBox(
              alignment: Alignment.bottomCenter,
              child: Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
