import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:localsend_app/model/cross_file.dart';
import 'package:localsend_app/model/state/send/send_session_state.dart';
import 'package:localsend_app/provider/file_transfer_provider.dart';
import 'package:localsend_app/provider/network/send_provider.dart';
import 'package:localsend_app/provider/ui_theme_provider.dart';
import 'package:localsend_app/util/device_type_ext.dart';
import 'package:localsend_app/widget/custom_icon_button.dart';
import 'package:localsend_app/widget/liquid_glass.dart';
import 'package:localsend_app/widget/responsive_list_view.dart';
import 'package:localsend_isolates/model/device.dart';
import 'package:localsend_isolates/model/session_status.dart';
import 'package:localsend_isolates/util/file_size_helper.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:routerino/routerino.dart';

class GroupSendProgressPage extends StatelessWidget {
  final String groupName;
  final List<Device> targets;
  final List<CrossFile> files;

  const GroupSendProgressPage({
    required this.groupName,
    required this.targets,
    required this.files,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isAiUi = context.ref.watch(uiThemeProvider) == UiTheme.aiUi;
    final sendSessions = context.watch(sendProvider);
    final transferNotifier = context.watch(fileTransferProvider);

    final totalSize = files.fold(0, (prev, curr) => prev + curr.size);
    final totalSizeStr = totalSize.asReadableFileSize;

    // Aggregate progress
    var completedCount = 0;
    var declinedCount = 0;
    var totalProgress = 0.0;

    for (final target in targets) {
      final session = sendSessions.values.firstWhereOrNull(
        (s) => s.target.ip == target.ip || (s.target.fingerprint.isNotEmpty && s.target.fingerprint == target.fingerprint),
      );

      if (session != null) {
        switch (session.status) {
          case SessionStatus.sending:
            if (session.files.isNotEmpty) {
              final prog =
                  session.files.keys.fold(
                    0.0,
                    (prev, id) => prev + transferNotifier.getProgress(sessionId: session.sessionId, fileId: id),
                  ) /
                  session.files.length;
              totalProgress += prog;
            }
            break;
          case SessionStatus.finished:
            completedCount++;
            totalProgress += 1.0;
            break;
          case SessionStatus.declined:
          case SessionStatus.canceledByReceiver:
          case SessionStatus.canceledBySender:
          case SessionStatus.finishedWithErrors:
          case SessionStatus.tooManyAttempts:
          case SessionStatus.recipientBusy:
            declinedCount++;
            break;
          default:
            break;
        }
      }
    }

    final overallProgress = targets.isNotEmpty ? (totalProgress / targets.length).clamp(0.0, 1.0) : 0.0;
    final isAllDone = (completedCount + declinedCount) == targets.length;

    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = isDark ? Colors.white70 : Colors.black54;

    return Scaffold(
      appBar: AppBar(
        title: Text(groupName),
        centerTitle: true,
        leading: CustomIconButton(
          onPressed: () => context.pop(),
          child: const Icon(Icons.arrow_back),
        ),
      ),
      body: ResponsiveListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // Header Card: Summary & Overall Progress
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF166FFF).withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.groups_rounded, color: Color(0xFF166FFF), size: 26),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                groupName,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${files.length} files • $totalSizeStr',
                                style: TextStyle(fontSize: 14, color: subtextColor),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isAllDone ? Colors.green.withOpacity(0.15) : const Color(0xFF166FFF).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            isAllDone ? 'Finished' : '${(overallProgress * 100).toInt()}%',
                            style: TextStyle(
                              color: isAllDone ? Colors.green : const Color(0xFF166FFF),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: overallProgress,
                        minHeight: 8,
                        backgroundColor: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.06),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isAllDone ? Colors.green : const Color(0xFF166FFF),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$completedCount / ${targets.length} completed',
                          style: TextStyle(fontSize: 13, color: subtextColor),
                        ),
                        if (declinedCount > 0)
                          Text(
                            '$declinedCount declined/failed',
                            style: const TextStyle(fontSize: 13, color: Colors.orange),
                          ),
                      ],
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.groups_rounded, color: theme.colorScheme.primary, size: 26),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                groupName,
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${files.length} files • $totalSizeStr',
                                style: TextStyle(fontSize: 14, color: subtextColor),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          isAllDone ? 'Finished' : '${(overallProgress * 100).toInt()}%',
                          style: TextStyle(
                            color: isAllDone ? Colors.green : theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: overallProgress,
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '$completedCount / ${targets.length} completed',
                      style: TextStyle(fontSize: 13, color: subtextColor),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 24),

          // Section Title: Recipients
          Text(
            'Recipients (${targets.length})',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),

          // List of recipient status cards
          ...targets.map((target) {
            final session = sendSessions.values.firstWhereOrNull(
              (s) => s.target.ip == target.ip || (s.target.fingerprint.isNotEmpty && s.target.fingerprint == target.fingerprint),
            );

            return _RecipientStatusCard(
              target: target,
              session: session,
              isDark: isDark,
              isAiUi: isAiUi,
              textColor: textColor,
              subtextColor: subtextColor,
            );
          }),

          const SizedBox(height: 32),

          // Done or Cancel All Button
          Center(
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isAllDone ? Colors.green : const Color(0xFF166FFF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)),
                  elevation: 0,
                ),
                onPressed: () {
                  if (!isAllDone) {
                    for (final target in targets) {
                      final session = sendSessions.values.firstWhereOrNull(
                        (s) => s.target.ip == target.ip || (s.target.fingerprint.isNotEmpty && s.target.fingerprint == target.fingerprint),
                      );
                      if (session != null) {
                        context.ref.notifier(sendProvider).closeSession(session.sessionId);
                      }
                    }
                  }
                  context.pop();
                },
                icon: Icon(isAllDone ? Icons.check_circle_outline : Icons.close),
                label: Text(
                  isAllDone ? 'Done' : 'Cancel All Transfers',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _RecipientStatusCard extends StatelessWidget {
  final Device target;
  final SendSessionState? session;
  final bool isDark;
  final bool isAiUi;
  final Color textColor;
  final Color subtextColor;

  const _RecipientStatusCard({
    required this.target,
    required this.session,
    required this.isDark,
    required this.isAiUi,
    required this.textColor,
    required this.subtextColor,
  });

  @override
  Widget build(BuildContext context) {
    final status = session?.status ?? SessionStatus.waiting;
    final transferNotifier = context.watch(fileTransferProvider);

    final progress = session != null && session!.files.isNotEmpty
        ? (session!.files.keys.fold(
                    0.0,
                    (prev, id) => prev + transferNotifier.getProgress(sessionId: session!.sessionId, fileId: id),
                  ) /
                  session!.files.length)
              .clamp(0.0, 1.0)
        : 0.0;

    final (statusLabel, statusColor, statusIcon) = switch (status) {
      SessionStatus.waiting => ('Waiting for acceptance...', Colors.amber, Icons.hourglass_top_rounded),
      SessionStatus.sending => ('Sending ${(progress * 100).toInt()}%', const Color(0xFF166FFF), Icons.upload_rounded),
      SessionStatus.finished => ('Completed', Colors.green, Icons.check_circle_rounded),
      SessionStatus.declined ||
      SessionStatus.canceledByReceiver ||
      SessionStatus.canceledBySender => ('Declined / Canceled', Colors.red, Icons.cancel_rounded),
      SessionStatus.finishedWithErrors || SessionStatus.tooManyAttempts || SessionStatus.recipientBusy => ('Failed', Colors.red, Icons.error_rounded),
    };

    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(target.deviceType.icon, color: textColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      target.alias,
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
                      target.deviceModel ?? target.ip ?? 'Wi-Fi Peer',
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
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, color: statusColor, size: 14),
                    const SizedBox(width: 5),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (status == SessionStatus.sending) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF166FFF)),
                backgroundColor: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
              ),
            ),
          ],
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
          child: content,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.zero,
        elevation: 1,
        child: content,
      ),
    );
  }
}
