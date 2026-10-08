import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:localsend_app/config/theme.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/model/cross_file.dart';
import 'package:localsend_app/model/state/server/web_share_state.dart';
import 'package:localsend_app/provider/local_ip_provider.dart';
import 'package:localsend_app/provider/network/server/server_provider.dart';
import 'package:localsend_app/provider/settings_provider.dart';
import 'package:localsend_app/util/native/platform_check.dart';
import 'package:localsend_app/util/ui/snackbar.dart';
import 'package:localsend_app/widget/dialogs/pin_dialog.dart';
import 'package:localsend_app/widget/dialogs/qr_dialog.dart';
import 'package:localsend_app/widget/dialogs/zoom_dialog.dart';
import 'package:localsend_app/widget/responsive_list_view.dart';
import 'package:localsend_isolates/util/sleep.dart';
import 'package:logging/logging.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:routerino/routerino.dart';

final _logger = Logger('WebSharePage');

enum _ServerState { initializing, running, error, stopping }

class WebSharePage extends StatefulWidget {
  final List<CrossFile>? files;

  const WebSharePage({this.files});

  @override
  State<WebSharePage> createState() => _WebSharePageState();
}

class _WebSharePageState extends State<WebSharePage> with Refena {
  _ServerState _stateEnum = _ServerState.initializing;
  bool _encrypted = false;
  String? _initializedError;

  bool get _sendMode => widget.files != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _init(encrypted: false);
    });
  }

  void _init({required bool encrypted}) async {
    final settings = ref.read(settingsProvider);
    setState(() {
      _stateEnum = _ServerState.initializing;
      _encrypted = encrypted;
      _initializedError = null;
    });
    await sleepAsync(500);
    try {
      final files = widget.files;

      final previousWeb = ref.read(serverProvider)?.web;
      final webPin = previousWeb != null ? previousWeb.pin : (files == null ? settings.receivePin : null);

      if (files != null) {
        await ref
            .notifier(serverProvider)
            .restartServerWithWebDownload(
              alias: settings.alias,
              port: settings.port,
              https: _encrypted,
              files: files,
              pin: webPin,
            );
      } else {
        await ref
            .notifier(serverProvider)
            .restartServer(
              alias: settings.alias,
              port: settings.port,
              https: _encrypted,
              web: WebShareUpload(pin: webPin),
            );
      }
      setState(() {
        _stateEnum = _ServerState.running;
      });
    } catch (e) {
      if (context.mounted) {
        setState(() {
          _stateEnum = _ServerState.error;
          _initializedError = e.toString();
        });
      }
    }
  }

  Future<void> _revertServerState() async {
    await ref.notifier(serverProvider).restartServerFromSettings();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final backBtnBg = isDark ? const Color(0xFF1E2430) : const Color(0xFFE9EDF5);
    final pillCardBg = isDark ? const Color(0xFF1E2430) : const Color(0xFFF0F3F8);

    return PopScope(
      onPopInvokedWithResult: (_, _) async {
        if (_stateEnum == _ServerState.initializing || _stateEnum == _ServerState.stopping) {
          return;
        }

        setState(() {
          _stateEnum = _ServerState.stopping;
        });
        await sleepAsync(250);
        try {
          await _revertServerState();
        } catch (e) {
          _logger.warning('Failed to restore the server', e);
        }
        await sleepAsync(250);

        if (context.mounted) {
          context.pop();
        }
      },
      canPop: false,
      child: Scaffold(
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
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
          ),
        ),
        body: Builder(
          builder: (context) {
            if (_stateEnum != _ServerState.running) {
              return Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (_stateEnum == _ServerState.initializing || _stateEnum == _ServerState.stopping) ...[
                    const CircularProgressIndicator(),
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        _stateEnum == _ServerState.initializing ? t.webSharePage.loading : t.webSharePage.stopping,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ] else if (_initializedError != null) ...[
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 10),
                    Center(
                      child: Text(t.webSharePage.error, style: Theme.of(context).textTheme.titleLarge),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: SelectableText(_initializedError!, style: Theme.of(context).textTheme.bodyMedium),
                    ),
                  ],
                ],
              );
            }

            final serverState = context.watch(serverProvider);
            final webDownloadState = serverState?.webDownloadState;
            if (serverState == null || (_sendMode && webDownloadState == null)) {
              return const Center(child: CircularProgressIndicator());
            }
            final networkState = context.watch(localIpProvider);
            final settings = context.watch(settingsProvider);
            final pin = serverState.web?.pin;

            final primaryIp = networkState.localIps.isNotEmpty ? networkState.localIps.first : '192.168.1.47';
            final url = '${_encrypted ? 'https' : 'http'}://$primaryIp:${serverState.port}';
            final urlWithPin = switch (pin) {
              String() => '$url/?pin=${Uri.encodeQueryComponent(pin)}',
              null => url,
            };

            return ResponsiveListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              children: [
                // Title: "Receive via link" / "Share via link"
                Text(
                  _sendMode ? t.webSharePage.title : t.webReceivePage.title,
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 24),

                // Description: "Open this link in your browser:"
                Text(
                  t.webSharePage.openLink(n: 1),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: textColor.withOpacity(0.65),
                  ),
                ),
                const SizedBox(height: 12),

                // Link Pill Container
                Container(
                  height: 58,
                  decoration: BoxDecoration(
                    color: pillCardBg,
                    borderRadius: BorderRadius.circular(29),
                    border: Border.all(
                      color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Row(
                    children: [
                      Expanded(
                        child: SelectableText(
                          url,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: textColor,
                          ),
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Copy Icon
                      _CirclePillBtn(
                        icon: Icons.content_copy,
                        onTap: () async {
                          await Clipboard.setData(ClipboardData(text: url));
                          if (context.mounted && checkPlatformIsDesktop()) {
                            context.showSnackBar(t.general.copiedToClipboard);
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      // QR Icon
                      _CirclePillBtn(
                        icon: Icons.qr_code_scanner,
                        onTap: () async {
                          await showDialog(
                            context: context,
                            builder: (_) => QrDialog(
                              data: urlWithPin,
                              label: url,
                              listenIncomingWebDownloadRequests: _sendMode,
                              pin: pin,
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      // Cast / TV Icon
                      _CirclePillBtn(
                        icon: Icons.tv,
                        onTap: () async {
                          await showDialog(
                            context: context,
                            builder: (_) => ZoomDialog(
                              label: url,
                              listenIncomingWebDownloadRequests: _sendMode,
                              pin: pin,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Section Title: "Options Group (Full Dark Mode)"
                Text(
                  'Options Group (Full Dark Mode)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor.withOpacity(0.65),
                  ),
                ),
                const SizedBox(height: 12),

                // Options Group Squircle Card
                Container(
                  decoration: BoxDecoration(
                    color: pillCardBg,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Column(
                    children: [
                      // Encryption Toggle
                      _ModalToggleRow(
                        label: t.webSharePage.encryption,
                        value: _encrypted,
                        onChanged: (b) => _init(encrypted: b),
                      ),
                      Divider(color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05), height: 1),

                      // Automatically accept requests Toggle
                      _ModalToggleRow(
                        label: t.webSharePage.autoAccept,
                        value: _sendMode ? (webDownloadState?.autoAccept ?? false) : settings.quickSave,
                        onChanged: (b) async {
                          if (_sendMode) {
                            ref.notifier(serverProvider).setWebDownloadAutoAccept(b);
                          } else {
                            await ref.notifier(settingsProvider).setQuickSave(b);
                          }
                        },
                      ),
                      Divider(color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05), height: 1),

                      // Require PIN Toggle
                      _ModalToggleRow(
                        label: t.webSharePage.requirePin,
                        value: pin != null,
                        onChanged: (b) async {
                          if (pin != null) {
                            if (_sendMode) {
                              await ref.notifier(serverProvider).restartServerWithWebDownload(
                                    alias: settings.alias,
                                    port: settings.port,
                                    https: _encrypted,
                                    files: widget.files!,
                                    pin: null,
                                  );
                            } else {
                              await ref.notifier(serverProvider).restartServer(
                                    alias: settings.alias,
                                    port: settings.port,
                                    https: _encrypted,
                                    web: const WebShareUpload(pin: null),
                                  );
                            }
                          } else {
                            final String? newPin = await showDialog<String>(
                              context: context,
                              builder: (_) => const PinDialog(
                                obscureText: false,
                                generateRandom: true,
                              ),
                            );

                            if (newPin != null && newPin.isNotEmpty) {
                              if (_sendMode) {
                                await ref.notifier(serverProvider).restartServerWithWebDownload(
                                      alias: settings.alias,
                                      port: settings.port,
                                      https: _encrypted,
                                      files: widget.files!,
                                      pin: newPin,
                                    );
                              } else {
                                await ref.notifier(serverProvider).restartServer(
                                      alias: settings.alias,
                                      port: settings.port,
                                      https: _encrypted,
                                      web: WebShareUpload(pin: newPin),
                                    );
                              }
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CirclePillBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CirclePillBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final circleBg = isDark ? const Color(0xFF2C3545) : const Color(0xFFDCE2EE);
    final iconColor = isDark ? Colors.white : Colors.black87;

    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: circleBg,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, size: 18, color: iconColor),
        padding: EdgeInsets.zero,
        onPressed: onTap,
      ),
    );
  }
}

class _ModalToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _ModalToggleRow({
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
      height: 52,
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
