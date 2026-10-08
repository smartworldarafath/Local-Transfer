import 'dart:io';

import 'package:flutter/material.dart';
import 'package:localsend_app/config/theme.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/model/persistence/receive_history_entry.dart';
import 'package:localsend_app/pages/receive_page.dart';
import 'package:localsend_app/provider/receive_history_provider.dart';
import 'package:localsend_app/provider/settings_provider.dart';
import 'package:localsend_app/util/native/directories.dart';
import 'package:localsend_app/util/native/open_file.dart';
import 'package:localsend_app/util/native/open_folder.dart';
import 'package:localsend_app/util/native/platform_check.dart';
import 'package:localsend_app/widget/dialogs/file_info_dialog.dart';
import 'package:localsend_app/widget/dialogs/history_clear_dialog.dart';
import 'package:localsend_app/widget/file_thumbnail.dart';
import 'package:localsend_app/widget/responsive_list_view.dart';
import 'package:localsend_isolates/model/device.dart';
import 'package:localsend_isolates/model/session_status.dart';
import 'package:localsend_isolates/util/file_size_helper.dart';
import 'package:path/path.dart' as path;
import 'package:refena_flutter/refena_flutter.dart';
import 'package:routerino/routerino.dart';

enum _EntryOption {
  open,
  showInFolder,
  info,
  delete
  ;

  String get label {
    return switch (this) {
      _EntryOption.open => t.receiveHistoryPage.entryActions.open,
      _EntryOption.showInFolder => t.receiveHistoryPage.entryActions.showInFolder,
      _EntryOption.info => t.receiveHistoryPage.entryActions.info,
      _EntryOption.delete => t.receiveHistoryPage.entryActions.deleteFromHistory,
    };
  }
}

const _optionsAll = _EntryOption.values;
final _optionsWithoutOpen = [_EntryOption.info, _EntryOption.delete];

class ReceiveHistoryPage extends StatelessWidget {
  const ReceiveHistoryPage({super.key});

  Future<void> _openFile(
    BuildContext context,
    ReceiveHistoryEntry entry,
    Dispatcher<ReceiveHistoryService, List<ReceiveHistoryEntry>> dispatcher,
  ) async {
    if (entry.path != null) {
      await openFile(
        context,
        entry.fileType,
        entry.path!,
        onDeleteTap: () => dispatcher.dispatchAsync(RemoveHistoryEntryAction(entry.id)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final entries = context.watch(receiveHistoryProvider);
    final textColor = isDark ? Colors.white : Colors.black87;
    final buttonBg = isDark ? const Color(0xFF2B3344) : const Color(0xFFE2E7F0);
    final backBtnBg = isDark ? const Color(0xFF1E2430) : const Color(0xFFE9EDF5);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: backBtnBg,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
              ),
            ),
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: textColor, size: 20),
              onPressed: () => context.pop(),
            ),
          ),
        ),
      ),
      body: ResponsiveListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        children: [
          // Title: "History"
          Text(
            t.receiveHistoryPage.title,
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w700,
              color: textColor,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 20),

          // Two Pill Buttons: Open folder & Delete history
          Row(
            children: [
              Container(
                height: 44,
                decoration: BoxDecoration(
                  color: buttonBg,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: checkPlatform([TargetPlatform.iOS])
                        ? null
                        : () async {
                            final destination = context.read(settingsProvider).destination ?? await getDefaultDestinationDirectory();
                            await openFolder(folderPath: destination);
                          },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Row(
                        children: [
                          Icon(Icons.folder, size: 18, color: textColor),
                          const SizedBox(width: 8),
                          Text(
                            t.receiveHistoryPage.openFolder,
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
                ),
              ),
              const SizedBox(width: 12),
              Container(
                height: 44,
                decoration: BoxDecoration(
                  color: buttonBg.withOpacity(entries.isEmpty ? 0.4 : 1.0),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: entries.isEmpty
                        ? null
                        : () async {
                            final result = await showDialog(
                              context: context,
                              builder: (_) => const HistoryClearDialog(),
                            );

                            if (context.mounted && result == true) {
                              await context.redux(receiveHistoryProvider).dispatchAsync(RemoveAllHistoryEntriesAction());
                            }
                          },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete,
                            size: 18,
                            color: textColor.withOpacity(entries.isEmpty ? 0.4 : 1.0),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            t.receiveHistoryPage.deleteHistory,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: textColor.withOpacity(entries.isEmpty ? 0.4 : 1.0),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),

          // Content / Empty state
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 180),
              child: Center(
                child: Text(
                  t.receiveHistoryPage.empty,
                  style: TextStyle(
                    fontSize: 22,
                    color: textColor.withOpacity(0.5),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            )
          else
            ...entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E2430) : const Color(0xFFF0F3F8),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    onTap: entry.path != null || entry.isMessage
                        ? () async {
                            if (entry.isMessage) {
                              final vm = ViewProvider((ref) {
                                return ReceivePageVm(
                                  status: SessionStatus.waiting,
                                  sender: Device(
                                    signalingId: null,
                                    ip: '0.0.0.0',
                                    version: '1.0.0',
                                    port: 8080,
                                    https: false,
                                    fingerprint: 'fingerprint',
                                    alias: entry.senderAlias,
                                    deviceModel: 'deviceModel',
                                    deviceType: DeviceType.web,
                                    download: true,
                                    channels: const [],
                                  ),
                                  showSenderInfo: false,
                                  files: [],
                                  message: entry.fileName,
                                  onAccept: () {},
                                  onDecline: () {},
                                  onClose: () {},
                                );
                              });

                              await context.push(() => ReceivePage(vm));
                              return;
                            }

                            await _openFile(context, entry, context.redux(receiveHistoryProvider));
                          }
                        : null,
                    leading: FilePathThumbnail(
                      path: entry.path,
                      fileType: entry.fileType,
                    ),
                    title: Text(
                      entry.fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.w600, color: textColor),
                    ),
                    subtitle: Text(
                      '${entry.fileSize.asReadableFileSize} - ${entry.senderAlias}',
                      style: TextStyle(color: textColor.withOpacity(0.6)),
                    ),
                    trailing: PopupMenuButton<_EntryOption>(
                      icon: Icon(Icons.more_vert, color: textColor.withOpacity(0.7)),
                      onSelected: (option) async {
                        switch (option) {
                          case _EntryOption.open:
                            await _openFile(context, entry, context.redux(receiveHistoryProvider));
                            break;
                          case _EntryOption.showInFolder:
                            if (entry.path != null) {
                              await openFolder(folderPath: path.dirname(entry.path!));
                            }
                            break;
                          case _EntryOption.info:
                            await showDialog(
                              context: context,
                              builder: (_) => FileInfoDialog(entry: entry),
                            );
                            break;
                          case _EntryOption.delete:
                            await context.redux(receiveHistoryProvider).dispatchAsync(RemoveHistoryEntryAction(entry.id));
                            break;
                        }
                      },
                      itemBuilder: (context) {
                        final options = entry.path != null ? _optionsAll : _optionsWithoutOpen;
                        return options.map((option) {
                          return PopupMenuItem(
                            value: option,
                            child: Text(option.label),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
