import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:localsend_app/config/theme.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/model/send_mode.dart';
import 'package:localsend_app/pages/device_details_page.dart';
import 'package:localsend_app/pages/selected_files_page.dart';
import 'package:localsend_app/pages/tabs/send_tab_vm.dart';
import 'package:localsend_app/pages/troubleshoot_page.dart';
import 'package:localsend_app/provider/animation_provider.dart';
import 'package:localsend_app/provider/file_transfer_provider.dart';
import 'package:localsend_app/provider/network/nearby_devices_provider.dart';
import 'package:localsend_app/provider/network/scan_facade.dart';
import 'package:localsend_app/provider/network/send_provider.dart';
import 'package:localsend_app/provider/selection/selected_sending_files_provider.dart';
import 'package:localsend_app/provider/settings_provider.dart';
import 'package:localsend_app/util/favorites.dart';
import 'package:localsend_app/util/native/file_picker.dart';
import 'package:localsend_app/util/native/platform_check.dart';
import 'package:localsend_app/widget/big_button.dart';
import 'package:localsend_app/widget/custom_icon_button.dart';
import 'package:localsend_app/widget/dialogs/add_file_dialog.dart';
import 'package:localsend_app/widget/dialogs/send_mode_help_dialog.dart';
import 'package:localsend_app/widget/file_thumbnail.dart';
import 'package:localsend_app/widget/list_tile/device_list_tile.dart';
import 'package:localsend_app/widget/opacity_slideshow.dart';
import 'package:localsend_app/widget/responsive_list_view.dart';
import 'package:localsend_isolates/model/device.dart';
import 'package:localsend_isolates/model/session_status.dart';
import 'package:localsend_isolates/util/file_size_helper.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:routerino/routerino.dart';

const _horizontalPadding = 20.0;
final pickerOptions = FilePickerOption.getOptionsForPlatform();

class SendTab extends StatelessWidget {
  const SendTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E2430) : const Color(0xFFF0F3F8);
    final circleBtnBg = isDark ? const Color(0xFF1E2430) : const Color(0xFFE9EDF5);
    final textColor = isDark ? Colors.white : Colors.black87;
    final iconColor = isDark ? Colors.white : Colors.black87;

    return ViewModelBuilder(
      provider: (ref) => sendTabVmProvider,
      init: (context) async => context.global.dispatchAsync(SendTabInitAction(context)),
      builder: (context, vm) {
        final ref = context.ref;

        // Custom ordered options to match 1791382743298.jpg:
        // Row 1: File, Media, Paste (Clipboard)
        // Row 2: Text, Folder, App
        final orderedOptions = <FilePickerOption>[
          FilePickerOption.file,
          FilePickerOption.media,
          FilePickerOption.clipboard,
          FilePickerOption.text,
          FilePickerOption.folder,
          FilePickerOption.app,
        ].where((opt) => pickerOptions.contains(opt)).toList();

        return ResponsiveListView(
          padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding, vertical: 15),
          children: [
            // Header: "Selection"
            Text(
              t.sendTab.selection.title,
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w700,
                color: textColor,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 18),

            // 6-Grid Squircle Selection Cards
            if (vm.selectedFiles.isEmpty)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.95,
                ),
                itemCount: orderedOptions.length,
                itemBuilder: (context, index) {
                  final option = orderedOptions[index];
                  final subtitle = switch (option) {
                    FilePickerOption.file => '3.17 files',
                    FilePickerOption.media => '77 media',
                    FilePickerOption.clipboard => 'Delete',
                    FilePickerOption.text => '11 text',
                    FilePickerOption.folder => 'All items',
                    FilePickerOption.app => 'App and',
                  };

                  return BigButton(
                    icon: option.icon,
                    label: option.label,
                    subtitle: subtitle,
                    filled: false,
                    onTap: () async => ref.global.dispatchAsync(
                      PickFileAction(
                        option: option,
                        context: context,
                      ),
                    ),
                  );
                },
              )
            else
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          t.sendTab.selection.title,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => ref.redux(selectedSendingFilesProvider).dispatch(ClearSelectionAction()),
                          icon: Icon(Icons.close, color: textColor.withOpacity(0.7)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      t.sendTab.selection.files(files: vm.selectedFiles.length),
                      style: TextStyle(color: textColor.withOpacity(0.8)),
                    ),
                    Text(
                      t.sendTab.selection.size(size: vm.selectedFiles.fold(0, (prev, curr) => prev + curr.size).asReadableFileSize),
                      style: TextStyle(color: textColor.withOpacity(0.8)),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: defaultThumbnailSize,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: vm.selectedFiles.length,
                        itemBuilder: (context, index) {
                          final file = vm.selectedFiles[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: SmartFileThumbnail.fromCrossFile(file),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () async {
                            await context.push(() => const SelectedFilesPage());
                          },
                          child: Text(t.general.edit),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF357AF6),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: () async {
                            if (pickerOptions.length == 1) {
                              await ref.global.dispatchAsync(
                                PickFileAction(
                                  option: pickerOptions.first,
                                  context: context,
                                ),
                              );
                              return;
                            }
                            await AddFileDialog.open(
                              context: context,
                              options: pickerOptions,
                            );
                          },
                          icon: const Icon(Icons.add),
                          label: Text(t.general.add),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 28),

            // Section Header: "Nearby devices" + 4 Circular Action Buttons
            Row(
              children: [
                Expanded(
                  child: Text(
                    t.sendTab.nearbyDevices,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
                _CircularActionBtn(
                  bg: circleBtnBg,
                  icon: Icons.refresh,
                  iconColor: iconColor,
                  onTap: () async => await ref.global.dispatchAsync(StartSmartScan()),
                ),
                const SizedBox(width: 8),
                _CircularActionBtn(
                  bg: circleBtnBg,
                  icon: Icons.gps_fixed,
                  iconColor: iconColor,
                  onTap: () async => vm.onTapAddress(context),
                ),
                const SizedBox(width: 8),
                _CircularActionBtn(
                  bg: circleBtnBg,
                  icon: Icons.favorite_border,
                  iconColor: iconColor,
                  onTap: () async => await vm.onTapFavorite(context),
                ),
                const SizedBox(width: 8),
                _SendModeCircleBtn(
                  bg: circleBtnBg,
                  iconColor: iconColor,
                  onSelect: (mode) async => vm.onTapSendMode(context, mode),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Nearby Devices Card or Empty Carousel Placeholder Card
            if (vm.nearbyDevices.isEmpty)
              Container(
                height: 110,
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.language,
                            size: 44,
                            color: textColor.withOpacity(0.7),
                          ),
                        ],
                      ),
                    ),
                    // Carousel page indicator dots
                    Positioned(
                      bottom: 12,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 16,
                            height: 6,
                            decoration: BoxDecoration(
                              color: textColor.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 16,
                            height: 6,
                            decoration: BoxDecoration(
                              color: textColor.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              ...vm.nearbyDevices.map((device) {
                final favoriteEntry = vm.favoriteDevices.findDevice(device);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Hero(
                    tag: 'device-${device.ip}',
                    child: vm.sendMode == SendMode.multiple
                        ? _MultiSendDeviceListTile(
                            device: device,
                            isFavorite: favoriteEntry != null,
                            nameOverride: favoriteEntry?.alias,
                            vm: vm,
                          )
                        : DeviceListTile(
                            device: device,
                            isFavorite: favoriteEntry != null,
                            nameOverride: favoriteEntry?.alias,
                            onDetailsTap: () async => await context.push(() => DeviceDetailsPage(device: device)),
                            onTap: () async => await vm.onTapDevice(context, device),
                          ),
                  ),
                );
              }),

            const SizedBox(height: 16),

            // Troubleshoot Pill Button
            Center(
              child: Container(
                height: 38,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C3545) : const Color(0xFFDCE2EE),
                  borderRadius: BorderRadius.circular(19),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(19),
                    onTap: () async {
                      await context.push(() => const TroubleshootPage());
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Center(
                        child: Text(
                          t.troubleshootPage.title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Footer Subtitle / Share Instruction
            Consumer(
              builder: (context, ref) {
                final animations = ref.watch(animationProvider);
                return OpacitySlideshow(
                  durationMillis: 6000,
                  running: animations,
                  children: [
                    Text(
                      t.sendTab.help,
                      style: TextStyle(
                        fontSize: 13,
                        color: textColor.withOpacity(0.65),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (checkPlatformCanReceiveShareIntent())
                      Text(
                        t.sendTab.shareIntentInfo,
                        style: TextStyle(
                          fontSize: 13,
                          color: textColor.withOpacity(0.65),
                        ),
                        textAlign: TextAlign.center,
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 40),
          ],
        );
      },
    );
  }
}

class _CircularActionBtn extends StatelessWidget {
  final Color bg;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _CircularActionBtn({
    required this.bg,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
        ),
      ),
      child: IconButton(
        icon: Icon(icon, color: iconColor, size: 20),
        onPressed: onTap,
        padding: EdgeInsets.zero,
      ),
    );
  }
}

class _SendModeCircleBtn extends StatelessWidget {
  final Color bg;
  final Color iconColor;
  final ValueChanged<SendMode> onSelect;

  const _SendModeCircleBtn({
    required this.bg,
    required this.iconColor,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
        ),
      ),
      child: PopupMenuButton<SendMode>(
        icon: Icon(Icons.settings_outlined, color: iconColor, size: 20),
        padding: EdgeInsets.zero,
        onSelected: onSelect,
        itemBuilder: (context) => [
          PopupMenuItem(
            value: SendMode.single,
            child: Text(t.sendTab.sendModes.single),
          ),
          PopupMenuItem(
            value: SendMode.multiple,
            child: Text(t.sendTab.sendModes.multiple),
          ),
        ],
      ),
    );
  }
}

class _MultiSendDeviceListTile extends StatelessWidget {
  final Device device;
  final bool isFavorite;
  final String? nameOverride;
  final SendTabVm vm;

  const _MultiSendDeviceListTile({
    required this.device,
    required this.isFavorite,
    required this.nameOverride,
    required this.vm,
  });

  @override
  Widget build(BuildContext context) {
    final ref = context.ref;
    final session = ref.watch(sendProvider)[device.ip];
    return DeviceListTile(
      device: device,
      isFavorite: isFavorite,
      nameOverride: nameOverride,
      onTap: () async {
        if (session != null && device.ip != null) {
          if (session.status == SessionStatus.waiting) {
            ref.notifier(sendProvider).cancelSession(device.ip!);
          } else {
            ref.notifier(sendProvider).closeSession(device.ip!);
          }
          return;
        }
        await vm.onTapDevice(context, device);
      },
    );
  }
}
