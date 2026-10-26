import 'package:flutter/material.dart';
import 'package:localsend_app/provider/ui_theme_provider.dart';
import 'package:refena_flutter/refena_flutter.dart';

class AiUiContainer extends StatelessWidget {
  final Widget child;

  const AiUiContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final uiTheme = context.ref.watch(uiThemeProvider);
    if (uiTheme != UiTheme.aiUi) {
      return child;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final gradient = isDark
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0D1424),
              Color(0xFF1E1730),
              Color(0xFF28182E),
              Color(0xFF101B24),
            ],
            stops: [0.0, 0.35, 0.70, 1.0],
          )
        : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFCEE5F8),
              Color(0xFFE8DEF8),
              Color(0xFFFDE4D2),
              Color(0xFFD6F4EC),
            ],
            stops: [0.0, 0.35, 0.70, 1.0],
          );

    return DecoratedBox(
      decoration: BoxDecoration(gradient: gradient),
      child: child,
    );
  }
}
