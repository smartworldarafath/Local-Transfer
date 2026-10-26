import 'package:flutter/material.dart';
import 'package:localsend_app/model/cross_file.dart';
import 'package:localsend_app/pages/group/group_send_progress_page.dart';
import 'package:localsend_app/pages/tabs/send_tab.dart';
import 'package:localsend_app/provider/animation_provider.dart';
import 'package:localsend_app/provider/network/group_provider.dart';
import 'package:localsend_app/provider/network/send_provider.dart';
import 'package:localsend_app/provider/selection/selected_sending_files_provider.dart';
import 'package:localsend_app/provider/ui_theme_provider.dart';
import 'package:localsend_app/util/device_type_ext.dart';
import 'package:localsend_app/widget/airdrop_beacon.dart';
import 'package:localsend_app/widget/custom_icon_button.dart';
import 'package:localsend_app/widget/dialogs/add_file_dialog.dart';
import 'package:localsend_app/widget/liquid_glass.dart';
import 'package:localsend_app/widget/responsive_list_view.dart';
import 'package:localsend_isolates/util/file_size_helper.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:routerino/routerino.dart';

class GroupSendPage extends StatefulWidget {
  const GroupSendPage({super.key});

  @override
  State<GroupSendPage> createState() => _GroupSendPageState();
}

class _GroupSendPageState extends State<GroupSendPage> with SingleTickerProviderStateMixin {
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
      context.ref.notifier(groupSendProvider).start();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    context.ref.notifier(groupSendProvider).stop();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    await AddFileDialog.open(
      context: context,
      options: pickerOptions,
    );
  }

  Future<void> _startGroupTransfer(DiscoveredGroup group, List<CrossFile> files) async {
    final targets = group.members.values.toList();
    if (targets.isEmpty || files.isEmpty) return;

    for (final target in targets) {
      await context.ref
          .notifier(sendProvider)
          .startSession(
            target: target,
            files: files,
            background: true,
          );
    }

    if (mounted) {
      await context.push(
        () => GroupSendProgressPage(
          groupName: group.groupName,
          targets: targets,
          files: files,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isAiUi = context.ref.watch(uiThemeProvider) == UiTheme.aiUi;
    final animations = context.watch(animationProvider);
    final sendState = context.watch(groupSendProvider);
    final selectedFiles = context.watch(selectedSendingFilesProvider);
    final activeGroup = sendState.activeGroup;

    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = isDark ? Colors.white70 : Colors.black54;

    final hasRecipients = activeGroup != null && activeGroup.members.isNotEmpty;
    final hasFiles = selectedFiles.isNotEmpty;
    final canSend = hasRecipients && hasFiles;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Send'),
        centerTitle: true,
        leading: CustomIconButton(
          onPressed: () => context.pop(),
          child: const Icon(Icons.arrow_back),
        ),
      ),
      body: ResponsiveListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // Active Group Card
          if (activeGroup != null)
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
                            'Active Wi-Fi Group',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.green.shade400,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        activeGroup.groupName,
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
                          '${activeGroup.members.length} / $maxGroupCapacity devices ready',
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
                            'Active Wi-Fi Group',
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
                        activeGroup.groupName,
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
                          '${activeGroup.members.length} / $maxGroupCapacity devices ready',
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
              )
          else
            // Searching for group state
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: animations ? _pulseAnimation.value : 1.0,
                        child: child,
                      );
                    },
                    child: const AirDropBeacon(
                      size: 110,
                      color: Color(0xFF166FFF),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Searching for Group Receive devices...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Ask friends to enter "Group Receive" on the same Wi-Fi',
                    style: TextStyle(fontSize: 13, color: subtextColor),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

          const SizedBox(height: 24),

          // Recipients Section
          if (activeGroup != null && activeGroup.members.isNotEmpty) ...[
            Text(
              'Recipients (${activeGroup.members.length})',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),
            ...activeGroup.members.values.map((dev) {
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
                          Text(
                            dev.alias,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
          ],

          // Selected Files Section
          Text(
            'Files to Send (${selectedFiles.length})',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),

          if (selectedFiles.isEmpty)
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _pickFiles,
              icon: const Icon(Icons.add_photo_alternate_rounded, size: 26),
              label: const Text(
                'Select Photos, Videos & Files',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            )
          else
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.folder_zip_rounded, color: Color(0xFF166FFF), size: 30),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${selectedFiles.length} files selected',
                              style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
                            ),
                            Text(
                              selectedFiles.fold(0, (prev, curr) => prev + curr.size).asReadableFileSize,
                              style: TextStyle(fontSize: 13, color: subtextColor),
                            ),
                          ],
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _pickFiles,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add'),
                      ),
                    ],
                  ),
                ),
              ],
            ),

          const SizedBox(height: 36),

          // Send to Group Primary Action Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: canSend ? const Color(0xFF166FFF) : (isDark ? Colors.white12 : Colors.black12),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                elevation: canSend ? 4 : 0,
              ),
              onPressed: canSend ? () => _startGroupTransfer(activeGroup, selectedFiles) : null,
              icon: const Icon(Icons.send_rounded),
              label: Text(
                hasRecipients ? 'Send to Group (${activeGroup.members.length} devices)' : 'Send to Group',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
