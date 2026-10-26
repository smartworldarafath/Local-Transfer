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

    if (isDark) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0C101A),
                  Color(0xFF141724),
                  Color(0xFF1A1628),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
          Positioned(
            top: 140,
            left: -80,
            width: 340,
            height: 400,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF2E1C4D).withOpacity(0.60),
                      const Color(0xFF2E1C4D).withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 300,
            right: -80,
            width: 360,
            height: 420,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF142B3E).withOpacity(0.60),
                      const Color(0xFF142B3E).withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          child,
        ],
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Base sky-blue to warm pastel mesh (matching photo_1 & photo_2)
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFD6E9FA), // Top soft sky blue
                Color(0xFFEBE3F8), // Mid lavender
                Color(0xFFFDE9DC), // Lower warm peach
              ],
              stops: [0.0, 0.45, 1.0],
            ),
          ),
        ),
        // Lilac / violet bloom on the mid-left
        Positioned(
          top: 160,
          left: -70,
          width: 340,
          height: 400,
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFD5BEF8).withOpacity(0.70),
                    const Color(0xFFD5BEF8).withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Warm peach / apricot bloom on the mid-right
        Positioned(
          top: 300,
          right: -70,
          width: 360,
          height: 420,
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFBD7BA).withOpacity(0.75),
                    const Color(0xFFFBD7BA).withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Soft lavender bloom at bottom-left
        Positioned(
          bottom: 40,
          left: -50,
          width: 300,
          height: 320,
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFE0D2F8).withOpacity(0.55),
                    const Color(0xFFE0D2F8).withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}
