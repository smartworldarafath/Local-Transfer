import 'package:flutter/material.dart';
import 'package:localsend_app/provider/animation_provider.dart';
import 'package:localsend_app/provider/device_info_provider.dart';
import 'package:localsend_app/provider/network/group_provider.dart';
import 'package:localsend_app/provider/ui_theme_provider.dart';
import 'package:localsend_app/util/device_type_ext.dart';
import 'package:localsend_app/widget/airdrop_beacon.dart';
import 'package:localsend_app/widget/custom_icon_button.dart';
import 'package:localsend_app/widget/liquid_glass.dart';
import 'package:localsend_app/widget/responsive_list_view.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:routerino/routerino.dart';

class GroupReceivePage extends StatefulWidget {
  const GroupReceivePage({super.key});

  @override
  State<GroupReceivePage> createState() => _GroupReceivePageState();
}

class _GroupReceivePageState extends State<GroupReceivePage> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutCubic),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.ref.notifier(groupReceiveProvider).start();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    context.ref.notifier(groupReceiveProvider).stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isAiUi = context.ref.watch(uiThemeProvider) == UiTheme.aiUi;
    final animations = context.watch(animationProvider);
    final groupState = context.watch(groupReceiveProvider);
    final myDevice = context.watch(deviceFullInfoProvider);
    final myKey = myDevice.fingerprint.isNotEmpty ? myDevice.fingerprint : (myDevice.ip ?? 'local');

    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = isDark ? Colors.white70 : Colors.black54;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Receive'),
        centerTitle: true,
        leading: CustomIconButton(
          onPressed: () => context.pop(),
          child: const Icon(Icons.arrow_back),
        ),
      ),
      body: ResponsiveListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // Radar pulse animation
          Center(
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: animations ? _pulseAnimation.value : 1.0,
                  child: child,
                );
              },
              child: const AirDropBeacon(
                size: 140,
                color: Color(0xFF166FFF),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Group Name & Capacity Card
          if (isAiUi)
            LiquidGlassMaterial(
              borderRadius: BorderRadius.circular(24),
              blurSigma: 16,
              tintColor: isDark ? const Color(0xFF1E2430).withOpacity(0.65) : Colors.white.withOpacity(0.70),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.12) : Colors.white.withOpacity(0.65),
                width: 1.0,
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Wi-Fi Group Active',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade400,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      groupState.groupName,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF166FFF).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${groupState.count} / $maxGroupCapacity devices joined',
                        style: const TextStyle(
                          color: Color(0xFF166FFF),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Wi-Fi Group Active',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      groupState.groupName,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${groupState.count} / $maxGroupCapacity devices joined',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 24),

          // Section Title
          Text(
            'Connected Devices (${groupState.count})',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),

          // List of joined members
          ...groupState.members.entries.map((entry) {
            final dev = entry.value;
            final isSelf = entry.key == myKey;

            final cardContent = Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(dev.deviceType.icon, color: textColor, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                dev.alias,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isSelf) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF166FFF).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'You',
                                  style: TextStyle(
                                    color: Color(0xFF166FFF),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dev.deviceModel ?? dev.ip ?? 'Wi-Fi Peer',
                          style: TextStyle(fontSize: 13, color: subtextColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_rounded, color: Colors.green, size: 14),
                        SizedBox(width: 5),
                        Text(
                          'Ready',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );

            if (isAiUi) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: LiquidGlassMaterial(
                  borderRadius: BorderRadius.circular(18),
                  blurSigma: 14,
                  tintColor: isDark ? const Color(0xFF1E2430).withOpacity(0.60) : Colors.white.withOpacity(0.65),
                  border: Border.all(
                    color: isDark ? Colors.white.withOpacity(0.10) : Colors.white.withOpacity(0.60),
                    width: 1.0,
                  ),
                  child: cardContent,
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                margin: EdgeInsets.zero,
                elevation: 1,
                child: cardContent,
              ),
            );
          }),

          const SizedBox(height: 20),

          // Instructions Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded, color: Color(0xFF166FFF), size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Keep this screen open',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: textColor,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'All friends on the same Wi-Fi who enter "Group Receive" will automatically join "${groupState.groupName}". When the sender initiates the transfer, all members receive files simultaneously.',
                        style: TextStyle(color: subtextColor, fontSize: 13, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
