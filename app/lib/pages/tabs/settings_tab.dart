import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:localsend_app/config/theme.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/model/persistence/color_mode.dart';
import 'package:localsend_app/pages/about/about_page.dart';
import 'package:localsend_app/pages/app_updates_page.dart';
import 'package:localsend_app/pages/changelog_page.dart';
import 'package:localsend_app/pages/donation/donation_page.dart';
import 'package:localsend_app/pages/settings/network_interfaces_page.dart';
import 'package:localsend_app/pages/tabs/settings_tab_controller.dart';
import 'package:localsend_app/provider/network/server/server_provider.dart';
import 'package:localsend_app/provider/settings_provider.dart';
import 'package:localsend_app/provider/version_provider.dart';
import 'package:localsend_app/util/alias_generator.dart';
import 'package:localsend_app/util/device_type_ext.dart';
import 'package:localsend_app/util/i18n.dart';
import 'package:localsend_app/util/native/device_info_helper.dart';
import 'package:localsend_app/util/native/macos_channel.dart';
import 'package:localsend_app/util/native/pick_directory_path.dart';
import 'package:localsend_app/util/native/platform_check.dart';
import 'package:localsend_app/widget/custom_dropdown_button.dart';
import 'package:localsend_app/widget/dialogs/encryption_disabled_notice.dart';
import 'package:localsend_app/widget/dialogs/pin_dialog.dart';
import 'package:localsend_app/widget/dialogs/quick_save_from_favorites_notice.dart';
import 'package:localsend_app/widget/dialogs/quick_save_notice.dart';
import 'package:localsend_app/widget/dialogs/text_field_tv.dart';
import 'package:localsend_app/widget/dialogs/text_field_with_actions.dart';
import 'package:localsend_app/widget/labeled_checkbox.dart';
import 'package:localsend_app/widget/local_send_logo.dart';
import 'package:localsend_app/widget/responsive_list_view.dart';
import 'package:localsend_isolates/constants.dart';
import 'package:localsend_isolates/model/device.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:routerino/routerino.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return ViewModelBuilder(
      provider: (ref) => settingsTabControllerProvider,
      builder: (context, vm) {
        final ref = context.ref;
        return ResponsiveListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          children: [
            // Page Title: "Settings"
            Text(
              t.settingsTab.title,
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w700,
                color: textColor,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 24),

            // General Section Header
            Text(
              t.settingsTab.general.title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textColor.withOpacity(0.65),
              ),
            ),
            const SizedBox(height: 10),

            // General Card Container (wrapping Theme, Color, Language, App updates, Animations)
            _SettingsPillGroup(
              children: [
                _SettingsDropdownRow<ThemeMode>(
                  label: t.settingsTab.general.brightness,
                  value: vm.settings.theme,
                  items: vm.themeModes.map((theme) {
                    return DropdownMenuItem(
                      value: theme,
                      alignment: Alignment.center,
                      child: Text(theme.humanName),
                    );
                  }).toList(),
                  onChanged: (theme) {
                    if (theme != null) vm.onChangeTheme(context, theme);
                  },
                ),
                _SettingsDropdownRow<ColorMode>(
                  label: t.settingsTab.general.color,
                  value: vm.settings.colorMode,
                  items: vm.colorModes.map((colorMode) {
                    return DropdownMenuItem(
                      value: colorMode,
                      alignment: Alignment.center,
                      child: Text(colorMode.humanName, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (colorMode) {
                    if (colorMode != null) vm.onChangeColorMode(context, colorMode);
                  },
                ),
                _SettingsPillButtonRow(
                  label: t.settingsTab.general.language,
                  buttonLabel: vm.settings.locale?.getLocaleName() ?? t.settingsTab.general.languageOptions.system,
                  onTap: () => vm.onTapLanguage(context),
                ),
                _SettingsPillButtonRow(
                  label: 'App updates',
                  buttonLabel: 'Check for updates',
                  onTap: () => context.push(() => const AppUpdatesPage()),
                ),
                _SettingsToggleRow(
                  label: t.settingsTab.general.animations,
                  value: vm.settings.enableAnimations,
                  onChanged: (b) async {
                    await ref.notifier(settingsProvider).setEnableAnimations(b);
                  },
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Receive Section Header
            Text(
              t.settingsTab.receive.title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textColor.withOpacity(0.65),
              ),
            ),
            const SizedBox(height: 10),

            // Receive Section Items as individual pill cards
            _SettingsPillCard(
              child: _SettingsToggleRow(
                label: t.settingsTab.receive.quickSave,
                value: vm.settings.quickSave,
                onChanged: (b) async {
                  final old = vm.settings.quickSave;
                  await ref.notifier(settingsProvider).setQuickSave(b);
                  if (b) {
                    await ref.notifier(settingsProvider).setQuickSaveFromFavorites(false);
                  }
                  if (!old && b && context.mounted) {
                    await QuickSaveNotice.open(context);
                  }
                },
              ),
            ),
            const SizedBox(height: 10),

            _SettingsPillCard(
              child: _SettingsToggleRow(
                label: t.settingsTab.receive.quickSaveFromFavorites,
                value: vm.settings.quickSaveFromFavorites,
                onChanged: (b) async {
                  final old = vm.settings.quickSaveFromFavorites;
                  await ref.notifier(settingsProvider).setQuickSaveFromFavorites(b);
                  if (b) {
                    await ref.notifier(settingsProvider).setQuickSave(false);
                  }
                  if (!old && b && context.mounted) {
                    await QuickSaveFromFavoritesNotice.open(context);
                  }
                },
              ),
            ),
            const SizedBox(height: 10),

            _SettingsPillCard(
              child: _SettingsToggleRow(
                label: t.settingsTab.receive.requirePin,
                value: vm.settings.receivePin != null,
                onChanged: (b) async {
                  final currentPIN = vm.settings.receivePin;
                  if (currentPIN != null) {
                    await ref.notifier(settingsProvider).setReceivePin(null);
                  } else {
                    final String? newPin = await showDialog<String>(
                      context: context,
                      builder: (_) => const PinDialog(
                        obscureText: false,
                        generateRandom: false,
                      ),
                    );

                    if (newPin != null && newPin.isNotEmpty) {
                      await ref.notifier(settingsProvider).setReceivePin(newPin);
                    }
                  }

                  if (ref.read(serverProvider) != null) {
                    await ref.notifier(serverProvider).restartServerFromSettings();
                  }
                },
              ),
            ),
            const SizedBox(height: 10),

            if (checkPlatformWithFileSystem()) ...[
              _SettingsPillCard(
                child: _SettingsPillButtonRow(
                  label: t.settingsTab.receive.destination,
                  buttonLabel: vm.settings.destination != null ? '(Custom)' : '(Downloads)',
                  onTap: () async {
                    if (vm.settings.destination != null) {
                      await ref.notifier(settingsProvider).setDestination(null);
                      if (defaultTargetPlatform == TargetPlatform.macOS) {
                        await removeExistingDestinationAccess();
                      }
                      return;
                    }

                    final directory = await pickDirectoryPath();
                    if (directory != null) {
                      if (defaultTargetPlatform == TargetPlatform.macOS) {
                        await persistDestinationFolderAccess(directory);
                      }
                      await ref.notifier(settingsProvider).setDestination(directory);
                    }
                  },
                ),
              ),
              const SizedBox(height: 10),
            ],

            if (checkPlatformWithGallery()) ...[
              _SettingsPillCard(
                child: _SettingsToggleRow(
                  label: t.settingsTab.receive.saveToGallery,
                  value: vm.settings.saveToGallery,
                  onChanged: (b) async {
                    await ref.notifier(settingsProvider).setSaveToGallery(b);
                  },
                ),
              ),
              const SizedBox(height: 10),
            ],

            _SettingsPillCard(
              child: _SettingsToggleRow(
                label: t.settingsTab.receive.saveToHistory,
                value: vm.settings.saveToHistory,
                onChanged: (b) async {
                  await ref.notifier(settingsProvider).setSaveToHistory(b);
                },
              ),
            ),
            const SizedBox(height: 28),

            // Network / About / Advanced Section
            Text(
              t.settingsTab.network.title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textColor.withOpacity(0.65),
              ),
            ),
            const SizedBox(height: 10),

            _SettingsPillGroup(
              children: [
                _SettingsPillButtonRow(
                  label: t.settingsTab.network.deviceType,
                  buttonLabel: vm.deviceInfo.deviceType.name,
                  onTap: () async {
                    await showDialog(
                      context: context,
                      builder: (_) => SimpleDialog(
                        title: Text(t.settingsTab.network.deviceType),
                        children: DeviceType.values.map((type) {
                          return SimpleDialogOption(
                            onPressed: () {
                              ref.notifier(settingsProvider).setDeviceType(type);
                              Navigator.pop(context);
                            },
                            child: Row(
                              children: [
                                Icon(type.icon),
                                const SizedBox(width: 10),
                                Text(type.name),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
                _SettingsPillButtonRow(
                  label: t.settingsTab.network.deviceModel,
                  buttonLabel: vm.deviceModelController.text.isNotEmpty ? vm.deviceModelController.text : '-',
                  onTap: () async {
                    await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(t.settingsTab.network.deviceModel),
                        content: TextFormField(
                          controller: vm.deviceModelController,
                          textAlign: TextAlign.center,
                          onChanged: (s) async {
                            await ref.notifier(settingsProvider).setDeviceModel(s);
                          },
                          autofocus: true,
                          onFieldSubmitted: (_) => context.pop(),
                        ),
                        actions: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Theme.of(context).colorScheme.onPrimary,
                            ),
                            onPressed: () => context.pop(),
                            child: Text(t.general.confirm),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                _SettingsPillButtonRow(
                  label: t.settingsTab.network.network,
                  buttonLabel: 'Interfaces',
                  onTap: () => context.push(() => const NetworkInterfacesPage()),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // About & Version Info
            _SettingsPillGroup(
              children: [
                _SettingsPillButtonRow(
                  label: 'Version',
                  buttonLabel: 'v1.2.0 (Beta 1)',
                  onTap: () => context.push(() => const AboutPage()),
                ),
                _SettingsPillButtonRow(
                  label: t.aboutPage.title,
                  buttonLabel: 'Local Transfer',
                  onTap: () => context.push(() => const AboutPage()),
                ),
              ],
            ),
            const SizedBox(height: 50),
          ],
        );
      },
    );
  }
}

/// A pill card enclosing a single settings row
class _SettingsPillCard extends StatelessWidget {
  final Widget child;

  const _SettingsPillCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2430) : const Color(0xFFF0F3F8),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: child,
    );
  }
}

/// A group container wrapping multiple settings rows in one continuous rounded squircle card
class _SettingsPillGroup extends StatelessWidget {
  final List<Widget> children;

  const _SettingsPillGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2430) : const Color(0xFFF0F3F8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            if (i > 0)
              Divider(
                color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05),
                height: 1,
              ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: children[i],
            ),
          ],
        ],
      ),
    );
  }
}

/// Dropdown row with right-aligned rounded capsule button
class _SettingsDropdownRow<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;

  const _SettingsDropdownRow({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final capsuleBg = isDark ? const Color(0xFF2B3344) : const Color(0xFFE2E7F0);

    return SizedBox(
      height: 48,
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ),
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: capsuleBg,
              borderRadius: BorderRadius.circular(19),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: value,
                items: items,
                onChanged: onChanged,
                icon: Icon(Icons.arrow_drop_down, color: textColor.withOpacity(0.7)),
                dropdownColor: isDark ? const Color(0xFF1E2430) : Colors.white,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pill button row with right-aligned rounded capsule button
class _SettingsPillButtonRow extends StatelessWidget {
  final String label;
  final String buttonLabel;
  final VoidCallback onTap;

  const _SettingsPillButtonRow({
    required this.label,
    required this.buttonLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final capsuleBg = isDark ? const Color(0xFF2B3344) : const Color(0xFFE2E7F0);

    return SizedBox(
      height: 48,
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(19),
              onTap: onTap,
              child: Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: capsuleBg,
                  borderRadius: BorderRadius.circular(19),
                ),
                child: Center(
                  child: Text(
                    buttonLabel,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Toggle row with adaptive switch matching mockup
class _SettingsToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _SettingsToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return SizedBox(
      height: 48,
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: const Color(0xFF357AF6),
            activeThumbColor: Colors.white,
            inactiveTrackColor: isDark ? const Color(0xFF2B3344) : const Color(0xFFD0D7E3),
            inactiveThumbColor: isDark ? Colors.white70 : Colors.white,
          ),
        ],
      ),
    );
  }
}

extension on ThemeMode {
  String get humanName {
    switch (this) {
      case ThemeMode.system:
        return t.settingsTab.general.brightnessOptions.system;
      case ThemeMode.light:
        return t.settingsTab.general.brightnessOptions.light;
      case ThemeMode.dark:
        return t.settingsTab.general.brightnessOptions.dark;
    }
  }
}

extension on ColorMode {
  String get humanName {
    return switch (this) {
      ColorMode.system => t.settingsTab.general.colorOptions.system,
      ColorMode.localsend => t.appName,
      ColorMode.oled => t.settingsTab.general.colorOptions.oled,
      ColorMode.yaru => 'Yaru',
      ColorMode.custom => t.settingsTab.general.colorOptions.custom,
    };
  }
}
