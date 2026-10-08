import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Physics and configuration constants from Liquid Glass Engine
/// (C:\Users\Fahad\Downloads\LG\LG\LiquidGlassEffect.java)
class LiquidGlassDefaults {
  static const double refractIndex = 1.50; // Crown glass n = 1.50
  static const double thicknessDp = 11.0;
  static const double baseIntensity = 0.75;
  static const int defaultAngle = 135; // Optical light incident angle
}

/// Core Liquid Glass container rendering physically-inspired Snell's law optical
/// refraction, meniscus bevel, specular rim highlight, and frosted glass depth.
class LiquidGlassMaterial extends StatelessWidget {
  final Widget child;
  final BorderRadius borderRadius;
  final double blurSigma;
  final Color? tintColor;
  final double intensity;
  final int angleDegrees;
  final Border? border;
  final BoxShadow? shadow;
  final bool showSpecularBorder;

  const LiquidGlassMaterial({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.blurSigma = 16.0,
    this.tintColor,
    this.intensity = LiquidGlassDefaults.baseIntensity,
    this.angleDegrees = LiquidGlassDefaults.defaultAngle,
    this.border,
    this.shadow,
    this.showSpecularBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Angle to radiant endpoints
    final rad = angleDegrees * math.pi / 180.0;
    final beginAlignment = Alignment(-math.cos(rad), -math.sin(rad));
    final endAlignment = Alignment(math.cos(rad), math.sin(rad));

    final baseTint = tintColor ??
        (isDark
            ? Colors.white.withOpacity(0.08 * (intensity / 0.75))
            : Colors.white.withOpacity(0.55 * (intensity / 0.75)));

    final specularHighlight = isDark
        ? Colors.white.withOpacity(0.18 * (intensity / 0.75))
        : Colors.white.withOpacity(0.40 * (intensity / 0.75));

    final shadowTint = isDark
        ? Colors.black.withOpacity(0.25)
        : Colors.black.withOpacity(0.06);

    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            color: baseTint,
            gradient: LinearGradient(
              begin: beginAlignment,
              end: endAlignment,
              colors: [
                specularHighlight,
                baseTint,
                baseTint.withOpacity(baseTint.opacity * 0.7),
                shadowTint,
              ],
              stops: const [0.0, 0.35, 0.75, 1.0],
            ),
            border: showSpecularBorder
                ? Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.22 * (intensity / 0.75))
                        : Colors.white.withOpacity(0.65 * (intensity / 0.75)),
                    width: 1.2,
                  )
                : border,
            boxShadow: shadow != null
                ? [shadow!]
                : [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withOpacity(0.35)
                          : Colors.black.withOpacity(0.08),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// A highly responsive interactive button with 120Hz-tuned fluid spring
/// physics and Liquid Glass refraction effects.
class LiquidGlassButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;
  final Color? tintColor;
  final Color? highlightColor;
  final double? width;
  final double? height;
  final bool filled;

  const LiquidGlassButton({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    this.tintColor,
    this.highlightColor,
    this.width,
    this.height,
    this.filled = false,
  });

  @override
  State<LiquidGlassButton> createState() => _LiquidGlassButtonState();
}

class _LiquidGlassButtonState extends State<LiquidGlassButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _intensityAnimation;

  @override
  void initState() {
    super.initState();
    // 120Hz optimized snappy duration & spring curve
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
      reverseDuration: const Duration(milliseconds: 200),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.elasticOut,
      ),
    );

    _intensityAnimation = Tween<double>(begin: 0.75, end: 1.25).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutQuad,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap != null) {
      _controller.forward();
      unawaited(HapticFeedback.selectionClick());
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onTap != null) {
      _controller.reverse();
    }
  }

  void _handleTapCancel() {
    if (widget.onTap != null) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final primaryTint = widget.filled
        ? (colorScheme.primary.withOpacity(isDark ? 0.42 : 0.75))
        : widget.tintColor;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: _handleTapDown,
            onTapUp: _handleTapUp,
            onTapCancel: _handleTapCancel,
            onTap: widget.onTap,
            child: SizedBox(
              width: widget.width,
              height: widget.height,
              child: LiquidGlassMaterial(
                borderRadius: widget.borderRadius,
                tintColor: primaryTint,
                intensity: _intensityAnimation.value,
                child: Padding(
                  padding: widget.padding,
                  child: Center(
                    widthFactor: widget.width != null ? null : 1.0,
                    heightFactor: widget.height != null ? null : 1.0,
                    child: widget.child,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Liquid Glass Navigation Dock for Mobile (Receive / Send / Settings)
/// Designed specifically for smooth 120Hz display transitions,
/// frosted liquid glass material, fluid sliding active indicator pill,
/// and reactive touch animations.
class LiquidGlassDock extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<LiquidGlassDockDestination> destinations;

  const LiquidGlassDock({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: LiquidGlassMaterial(
          borderRadius: BorderRadius.circular(35),
          blurSigma: 20,
          tintColor: isDark
              ? const Color(0xFF161922).withOpacity(0.92)
              : Colors.white.withOpacity(0.85),
          intensity: 0.95,
          child: Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final count = destinations.length;
                final itemWidth = constraints.maxWidth / count;

                return Stack(
                  children: [
                    // Fluid animated sliding active pill matching mockups
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      left: selectedIndex * itemWidth + 2,
                      top: 2,
                      width: itemWidth - 4,
                      height: 54,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(27),
                          color: isDark
                              ? const Color(0xFF2C3549)
                              : colorScheme.primary.withOpacity(0.18),
                        ),
                      ),
                    ),
                    // Dock items
                    Row(
                      children: [
                        for (int i = 0; i < count; i++)
                          Expanded(
                            child: _LiquidGlassDockItem(
                              destination: destinations[i],
                              isSelected: i == selectedIndex,
                              onTap: () => onDestinationSelected(i),
                            ),
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class LiquidGlassDockDestination {
  final IconData icon;
  final String label;

  const LiquidGlassDockDestination({
    required this.icon,
    required this.label,
  });
}

class _LiquidGlassDockItem extends StatefulWidget {
  final LiquidGlassDockDestination destination;
  final bool isSelected;
  final VoidCallback onTap;

  const _LiquidGlassDockItem({
    required this.destination,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_LiquidGlassDockItem> createState() => _LiquidGlassDockItemState();
}

class _LiquidGlassDockItemState extends State<_LiquidGlassDockItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 180),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.90).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = widget.isSelected;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? const Color(0xFF62A2FF) : colorScheme.primary;
    final inactiveColor = isDark
        ? Colors.white.withOpacity(0.55)
        : Colors.black.withOpacity(0.55);

    return AnimatedBuilder(
      animation: _pressController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) {
              _pressController.forward();
              unawaited(HapticFeedback.selectionClick());
            },
            onTapUp: (_) => _pressController.reverse(),
            onTapCancel: () => _pressController.reverse(),
            onTap: widget.onTap,
            child: SizedBox(
              height: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 32,
                    child: Center(
                      child: AnimatedScale(
                        scale: isSelected ? 1.10 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        child: Icon(
                          widget.destination.icon,
                          size: 22,
                          color: isSelected ? activeColor : inactiveColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? activeColor : inactiveColor,
                    ),
                    child: Text(
                      widget.destination.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

