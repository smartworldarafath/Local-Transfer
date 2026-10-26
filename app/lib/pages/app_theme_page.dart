import 'package:flutter/material.dart';
import 'package:localsend_app/model/persistence/color_mode.dart';
import 'package:localsend_app/pages/home_page.dart';
import 'package:localsend_app/pages/home_page_controller.dart';
import 'package:localsend_app/provider/background_look_provider.dart';
import 'package:localsend_app/provider/settings_provider.dart';
import 'package:localsend_app/provider/ui_theme_provider.dart';
import 'package:localsend_app/widget/ai_ui_background.dart';
import 'package:localsend_app/widget/dialogs/ai_ui_preview_dialog.dart';
import 'package:localsend_app/widget/dialogs/custom_color_dialog.dart';
import 'package:localsend_app/widget/liquid_glass.dart';
import 'package:localsend_app/widget/responsive_builder.dart';
import 'package:localsend_app/widget/responsive_list_view.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:routerino/routerino.dart';

class AppThemePage extends StatefulWidget {
  const AppThemePage({super.key});

  @override
  State<AppThemePage> createState() => _AppThemePageState();
}

class _AppThemePageState extends State<AppThemePage> with Refena {


  String _getColorModeName(ColorMode mode) {
    switch (mode) {
      case ColorMode.system:
        return 'Custom (Dynamic)';
      case ColorMode.localsend:
        return 'Local Transfer (Teal)';
      case ColorMode.oled:
        return 'OLED (Pitch Black)';
      case ColorMode.yaru:
        return 'Yaru';
      case ColorMode.custom:
        return 'Custom Palette';
    }
  }

  void _showComingSoonDialog({required String title, required String message}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: Theme.of(ctx).colorScheme.primary),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 15, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(),
            child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _openColorSchemePicker(BuildContext context, ColorMode currentMode, Color customColor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  'Choose Color Scheme',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.auto_awesome, color: Colors.blue),
                  title: const Text('Dynamic / System Colors'),
                  subtitle: const Text('Matches system palette (Android 12+)'),
                  trailing: currentMode == ColorMode.system ? const Icon(Icons.check, color: Colors.blue) : null,
                  onTap: () async {
                    sheetContext.pop();
                    await ref.notifier(settingsProvider).setColorMode(ColorMode.system);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.circle, color: Colors.teal),
                  title: const Text('Local Transfer (Teal)'),
                  subtitle: const Text('Classic vibrant teal theme'),
                  trailing: currentMode == ColorMode.localsend ? const Icon(Icons.check, color: Colors.teal) : null,
                  onTap: () async {
                    sheetContext.pop();
                    await ref.notifier(settingsProvider).setColorMode(ColorMode.localsend);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.color_lens, color: Colors.deepPurple),
                  title: const Text('Custom Color'),
                  subtitle: const Text('Pick any accent color'),
                  trailing: currentMode == ColorMode.custom ? const Icon(Icons.check, color: Colors.deepPurple) : null,
                  onTap: () async {
                    sheetContext.pop();
                    await showDialog(
                      context: context,
                      builder: (_) => CustomColorDialog(
                        initialColor: customColor,
                      ),
                    ).then((selected) async {
                      if (selected is Color) {
                        await ref.notifier(settingsProvider).setCustomColor(selected);
                        await ref.notifier(settingsProvider).setColorMode(ColorMode.custom);
                      }
                    });
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = isDark ? Colors.white60 : Colors.black54;

    final settings = ref.watch(settingsProvider);
    final currentThemeMode = settings.theme;
    final isSystemTheme = currentThemeMode == ThemeMode.system;
    final isOled = settings.colorMode == ColorMode.oled;

    final backgroundLook = ref.watch(backgroundLookProvider);

    final activeUiTheme = ref.watch(uiThemeProvider);
    final isAiUi = activeUiTheme == UiTheme.aiUi;

    // Card background color matching One UI / AI UI
    final cardColor = isAiUi
        ? (isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.70))
        : (isDark ? const Color(0xFF1E222B) : Colors.white);
    final cardBorder = isAiUi
        ? (isDark ? Colors.white.withOpacity(0.14) : Colors.white.withOpacity(0.60))
        : (isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04));
    final rowBg = isAiUi
        ? (isDark ? Colors.white.withOpacity(0.06) : Colors.white.withOpacity(0.55))
        : (isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF6F8FA));

    return AiUiContainer(
      child: Scaffold(
        backgroundColor: isAiUi ? Colors.transparent : theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: LiquidGlassButton(
            borderRadius: BorderRadius.circular(20),
            padding: EdgeInsets.zero,
            onTap: () => context.pop(),
            child: Icon(Icons.arrow_back_rounded, size: 20, color: textColor),
          ),
        ),
      ),
      body: ResponsiveListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        children: [
          // Header with Title and "Beta" Badge
          Row(
            children: [
              Text(
                'App theme',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.35),
                    width: 1,
                  ),
                ),
                child: Text(
                  'Beta',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // 1. Match system theme Card
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: cardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Match system theme',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Use system settings to automatically change between light and dark mode',
                        style: TextStyle(fontSize: 13, color: subtextColor),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Switch.adaptive(
                  value: isSystemTheme,
                  activeColor: theme.colorScheme.primary,
                  onChanged: (enabled) async {
                    if (enabled) {
                      await ref.notifier(settingsProvider).setTheme(ThemeMode.system);
                    } else {
                      await ref.notifier(settingsProvider).setTheme(isDark ? ThemeMode.dark : ThemeMode.light);
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 2. Theme selection Card
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: cardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Theme selection',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 14),

                // Light theme Row
                _buildThemeSelectionRow(
                  title: 'Light theme',
                  subtitle: 'Light',
                  icon: Icons.wb_sunny_outlined,
                  iconBg: const Color(0xFFFFF7E6),
                  iconColor: const Color(0xFFF59E0B),
                  selected: currentThemeMode == ThemeMode.light,
                  rowBg: rowBg,
                  textColor: textColor,
                  subtextColor: subtextColor,
                  onTap: () async {
                    await ref.notifier(settingsProvider).setTheme(ThemeMode.light);
                  },
                ),
                const SizedBox(height: 10),

                // Dark theme Row
                _buildThemeSelectionRow(
                  title: 'Dark theme',
                  subtitle: 'Dark',
                  icon: Icons.nightlight_round,
                  iconBg: const Color(0xFFE8EEF5),
                  iconColor: const Color(0xFF3B82F6),
                  selected: currentThemeMode == ThemeMode.dark,
                  rowBg: rowBg,
                  textColor: textColor,
                  subtextColor: subtextColor,
                  onTap: () async {
                    await ref.notifier(settingsProvider).setTheme(ThemeMode.dark);
                  },
                ),
                const SizedBox(height: 10),

                // System theme Row (Default)
                _buildThemeSelectionRow(
                  title: 'System default',
                  subtitle: 'Follow device system theme',
                  icon: Icons.brightness_auto_rounded,
                  iconBg: const Color(0xFFE6F4EA),
                  iconColor: const Color(0xFF10B981),
                  selected: currentThemeMode == ThemeMode.system,
                  rowBg: rowBg,
                  textColor: textColor,
                  subtextColor: subtextColor,
                  onTap: () async {
                    await ref.notifier(settingsProvider).setTheme(ThemeMode.system);
                  },
                ),
                const SizedBox(height: 10),

                // Color scheme Row
                InkWell(
                  onTap: () => _openColorSchemePicker(context, settings.colorMode, settings.customColor),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: rowBg,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0E7FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.palette_rounded, color: Color(0xFF4F46E5), size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Color scheme',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                settings.colorMode == ColorMode.system
                                    ? 'Custom (Dynamic)'
                                    : settings.colorMode == ColorMode.localsend
                                        ? 'Local Transfer (Teal)'
                                        : settings.colorMode == ColorMode.custom
                                            ? 'Custom Palette'
                                            : _getColorModeName(settings.colorMode),
                                style: TextStyle(fontSize: 13, color: subtextColor),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                'Configure',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 3. AMOLED dark mode Card
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: cardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AMOLED dark mode',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Pitch black theme for OLED screens',
                        style: TextStyle(fontSize: 13, color: subtextColor),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Switch.adaptive(
                  value: isOled,
                  activeColor: theme.colorScheme.primary,
                  onChanged: (enabled) async {
                    if (enabled) {
                      await ref.notifier(settingsProvider).setColorMode(ColorMode.oled);
                      await ref.notifier(settingsProvider).setTheme(ThemeMode.dark);
                    } else {
                      await ref.notifier(settingsProvider).setColorMode(ColorMode.system);
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 4. UI theme Card (photo 4)
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: cardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'UI theme',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 14),

                // Ai Ui
                _buildUiThemeOption(
                  title: 'Ai Ui',
                  iconWidget: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFFEC4899), Color(0xFF3B82F6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Ai',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  selected: activeUiTheme == UiTheme.aiUi,
                  rowBg: rowBg,
                  textColor: textColor,
                  onTap: () {
                    AiUiPreviewDialog.show(
                      context,
                      onApply: () async {
                        await ref.notifier(uiThemeProvider).setUiTheme(UiTheme.aiUi);
                      },
                    );
                  },
                ),
                const SizedBox(height: 10),

                // One Ui (Default)
                _buildUiThemeOption(
                  title: 'One Ui',
                  iconWidget: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 24),
                  ),
                  selected: activeUiTheme == UiTheme.oneUi,
                  rowBg: rowBg,
                  textColor: textColor,
                  onTap: () async {
                    await ref.notifier(uiThemeProvider).setUiTheme(UiTheme.oneUi);
                  },
                ),
                const SizedBox(height: 10),

                // Liquid Glass
                _buildUiThemeOption(
                  title: 'Liquid Glass',
                  iconWidget: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF38BDF8).withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.water_drop_rounded, color: Colors.white, size: 24),
                  ),
                  selected: activeUiTheme == UiTheme.liquidGlass,
                  rowBg: rowBg,
                  textColor: textColor,
                  onTap: () {
                    _showComingSoonDialog(
                      title: 'Liquid Glass Theme',
                      message: 'Liquid Glass theme is currently in development and will be available in a future update.',
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 5. Custom Theme Card (photo 3)
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: cardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Custom Theme',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    InkWell(
                      onTap: () {
                        _showComingSoonDialog(
                          title: 'Custom Theme',
                          message: 'Custom theme customization is currently under development and will be available soon.',
                        );
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.file_upload_outlined, size: 18, color: textColor),
                            const SizedBox(width: 6),
                            Text(
                              'Upload',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Choose a photo or file to customize',
                        style: TextStyle(
                          fontSize: 13,
                          color: subtextColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 6. Background Look Card (photo 3)
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: cardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Background Look',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 14),
                ...BackgroundLook.values.map((look) {
                  final isSelected = backgroundLook == look;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      onTap: () async {
                        await ref.notifier(backgroundLookProvider).setBackgroundLook(look);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: rowBg,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: look.swatch(isDark),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.black.withOpacity(0.08),
                                  width: 1,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                look.label,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: textColor,
                                ),
                              ),
                            ),
                            Radio<bool>(
                              value: true,
                              groupValue: isSelected,
                              activeColor: theme.colorScheme.primary,
                              onChanged: (_) async {
                                await ref.notifier(backgroundLookProvider).setBackgroundLook(look);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
      bottomNavigationBar: ResponsiveBuilder(
        builder: (sizing) {
          if (!sizing.isMobile) return const SizedBox.shrink();
          return LiquidGlassDock(
            selectedIndex: 2, // Settings tab
            onDestinationSelected: (index) {
              context.pop();
              if (index != 2) {
                ref.redux(homePageControllerProvider).dispatch(ChangeTabAction(HomeTab.values[index]));
              }
            },
            destinations: HomeTab.values.map((tab) {
              return LiquidGlassDockDestination(icon: tab.icon, label: tab.label);
            }).toList(),
            );
          },
        ),
      ),
    );
  }

  Widget _buildThemeSelectionRow({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required bool selected,
    required Color rowBg,
    required Color textColor,
    required Color subtextColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: rowBg,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13, color: subtextColor),
                  ),
                ],
              ),
            ),
            Radio<bool>(
              value: true,
              groupValue: selected,
              activeColor: Theme.of(context).colorScheme.primary,
              onChanged: (_) => onTap(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUiThemeOption({
    required String title,
    required Widget iconWidget,
    required bool selected,
    required Color rowBg,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: rowBg,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            iconWidget,
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ),
            Radio<bool>(
              value: true,
              groupValue: selected,
              activeColor: Theme.of(context).colorScheme.primary,
              onChanged: (_) => onTap(),
            ),
          ],
        ),
      ),
    );
  }
}
