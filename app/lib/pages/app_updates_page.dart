import 'package:flutter/material.dart';
import 'package:localsend_app/provider/app_update_provider.dart';
import 'package:localsend_app/provider/version_provider.dart';
import 'package:localsend_app/widget/liquid_glass.dart';
import 'package:localsend_app/widget/responsive_list_view.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:routerino/routerino.dart';

class AppUpdatesPage extends StatelessWidget {
  const AppUpdatesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final versionData = context.watch(versionProvider).data;
    final updateState = context.watch(appUpdateProvider);
    final notifier = context.notifier(appUpdateProvider);

    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = isDark ? Colors.white60 : Colors.black54;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: LiquidGlassButton(
            borderRadius: BorderRadius.circular(20),
            padding: EdgeInsets.zero,
            onTap: () => context.pop(),
            child: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: textColor),
          ),
        ),
      ),
      body: ResponsiveListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        children: [
          Text(
            'App updates',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 25),

          // Top Status Card
          LiquidGlassMaterial(
            borderRadius: BorderRadius.circular(24),
            blurSigma: 12,
            tintColor: isDark ? const Color(0x331E222B) : Colors.white.withOpacity(0.7),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
              width: 1,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2A2F3D) : theme.colorScheme.primary.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          updateState.status == UpdateStatus.available
                              ? Icons.system_update_rounded
                              : Icons.cloud_done_rounded,
                          color: theme.colorScheme.primary,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              updateState.status == UpdateStatus.available
                                  ? 'Update available: ${updateState.latestRelease?.tagName}'
                                  : (updateState.status == UpdateStatus.checking
                                      ? 'Checking...'
                                      : 'Up to date'),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Version ${versionData?.combinedString ?? "v1.2.0 (Beta 1)"}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: subtextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (updateState.status == UpdateStatus.available)
                        LiquidGlassButton(
                          borderRadius: BorderRadius.circular(20),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          onTap: () => notifier.downloadAndInstall(context),
                          child: const Text(
                            'Update',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent),
                          ),
                        )
                      else
                        LiquidGlassButton(
                          borderRadius: BorderRadius.circular(20),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          onTap: () => notifier.checkForUpdates(),
                          child: updateState.status == UpdateStatus.checking
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text(
                                  'Check',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                        ),
                    ],
                  ),
                  if (updateState.status == UpdateStatus.downloading) ...[
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: updateState.downloadProgress > 0 ? updateState.downloadProgress : null,
                        minHeight: 6,
                        backgroundColor: isDark ? Colors.white12 : Colors.black12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Downloading update: ${(updateState.downloadProgress * 100).toStringAsFixed(0)}%',
                      style: theme.textTheme.bodySmall?.copyWith(color: subtextColor),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if (updateState.status == UpdateStatus.readyToInstall) ...[
                    const SizedBox(height: 14),
                    LiquidGlassButton(
                      borderRadius: BorderRadius.circular(16),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      onTap: () => notifier.downloadAndInstall(context),
                      child: const Center(
                        child: Text(
                          'Install Now',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.greenAccent),
                        ),
                      ),
                    ),
                  ],
                  if (updateState.errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      updateState.errorMessage!,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 25),

          // Options Group Card
          LiquidGlassMaterial(
            borderRadius: BorderRadius.circular(24),
            blurSigma: 12,
            tintColor: isDark ? const Color(0x331E222B) : Colors.white.withOpacity(0.7),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
              width: 1,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  SwitchListTile.adaptive(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    title: Text(
                      'Auto-check for updates',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                    value: updateState.autoCheck,
                    onChanged: (val) => notifier.setAutoCheck(val),
                  ),
                  Divider(height: 1, color: isDark ? Colors.white10 : Colors.black12),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    title: Text(
                      'Update channel',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2A2F3D) : theme.colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: updateState.channel,
                          dropdownColor: isDark ? const Color(0xFF1E222B) : theme.colorScheme.surface,
                          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                          items: const [
                            DropdownMenuItem(value: 'Stable', child: Text('Stable')),
                            DropdownMenuItem(value: 'Beta', child: Text('Beta')),
                          ],
                          onChanged: (val) {
                            if (val != null) notifier.setChannel(val);
                          },
                        ),
                      ),
                    ),
                  ),
                  Divider(height: 1, color: isDark ? Colors.white10 : Colors.black12),
                  SwitchListTile.adaptive(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    title: Text(
                      'Auto-download over Wi-Fi',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                    value: updateState.autoDownloadWifi,
                    onChanged: (val) => notifier.setAutoDownloadWifi(val),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
