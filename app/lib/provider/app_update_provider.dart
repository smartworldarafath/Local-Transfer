import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:localsend_app/provider/version_provider.dart';
import 'package:localsend_app/util/native/open_file.dart';
import 'package:localsend_app/util/native/platform_check.dart';
import 'package:localsend_isolates/model/file_type.dart';
import 'package:path_provider/path_provider.dart';
import 'package:refena_flutter/refena_flutter.dart';

class ReleaseAssetInfo {
  final String name;
  final String downloadUrl;
  final int size;

  ReleaseAssetInfo({
    required this.name,
    required this.downloadUrl,
    required this.size,
  });
}

class AppReleaseInfo {
  final String tagName;
  final String name;
  final String body;
  final String htmlUrl;
  final String? apkDownloadUrl;
  final int? apkSize;

  AppReleaseInfo({
    required this.tagName,
    required this.name,
    required this.body,
    required this.htmlUrl,
    this.apkDownloadUrl,
    this.apkSize,
  });

  factory AppReleaseInfo.fromJson(Map<String, dynamic> json) {
    String? apkUrl;
    int? size;
    final assets = json['assets'] as List<dynamic>?;
    if (assets != null) {
      for (final a in assets) {
        final name = (a['name'] as String? ?? '').toLowerCase();
        if (name.endsWith('.apk')) {
          apkUrl = a['browser_download_url'] as String?;
          size = a['size'] as int?;
          break;
        }
      }
    }

    return AppReleaseInfo(
      tagName: json['tag_name'] as String? ?? '',
      name: json['name'] as String? ?? json['tag_name'] as String? ?? '',
      body: json['body'] as String? ?? '',
      htmlUrl: json['html_url'] as String? ?? '',
      apkDownloadUrl: apkUrl,
      apkSize: size,
    );
  }
}

enum UpdateStatus {
  idle,
  checking,
  upToDate,
  available,
  downloading,
  readyToInstall,
  error,
}

class AppUpdateState {
  final UpdateStatus status;
  final AppReleaseInfo? latestRelease;
  final double downloadProgress; // 0.0 to 1.0
  final String? downloadedFilePath;
  final String? errorMessage;
  final bool autoCheck;
  final String channel; // 'Stable' or 'Beta'
  final bool autoDownloadWifi;

  AppUpdateState({
    this.status = UpdateStatus.idle,
    this.latestRelease,
    this.downloadProgress = 0.0,
    this.downloadedFilePath,
    this.errorMessage,
    this.autoCheck = true,
    this.channel = 'Beta',
    this.autoDownloadWifi = false,
  });

  AppUpdateState copyWith({
    UpdateStatus? status,
    AppReleaseInfo? latestRelease,
    double? downloadProgress,
    String? downloadedFilePath,
    String? errorMessage,
    bool? autoCheck,
    String? channel,
    bool? autoDownloadWifi,
  }) {
    return AppUpdateState(
      status: status ?? this.status,
      latestRelease: latestRelease ?? this.latestRelease,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      downloadedFilePath: downloadedFilePath ?? this.downloadedFilePath,
      errorMessage: errorMessage ?? this.errorMessage,
      autoCheck: autoCheck ?? this.autoCheck,
      channel: channel ?? this.channel,
      autoDownloadWifi: autoDownloadWifi ?? this.autoDownloadWifi,
    );
  }
}

class AppUpdateNotifier extends Notifier<AppUpdateState> {
  static const String repoReleasesUrl = 'https://api.github.com/repos/smartworldarafath/Local-Transfer/releases';

  @override
  AppUpdateState init() => AppUpdateState();

  Future<void> checkForUpdates({bool silent = false}) async {
    if (state.status == UpdateStatus.checking || state.status == UpdateStatus.downloading) {
      return;
    }

    state = state.copyWith(status: UpdateStatus.checking, errorMessage: null);

    try {
      final client = HttpClient();
      client.userAgent = 'LocalTransfer-App';
      final request = await client.getUrl(Uri.parse(repoReleasesUrl));
      request.headers.set('Accept', 'application/vnd.github.v3+json');
      final response = await request.close();

      if (response.statusCode != 200) {
        throw Exception('GitHub API returned status code ${response.statusCode}');
      }

      final responseBody = await response.transform(utf8.decoder).join();
      final List<dynamic> releasesJson = jsonDecode(responseBody) as List<dynamic>;

      if (releasesJson.isEmpty) {
        state = state.copyWith(status: UpdateStatus.upToDate);
        return;
      }

      final currentVersion = ref.read(versionProvider).data?.version ?? '1.2.0';
      final latest = AppReleaseInfo.fromJson(releasesJson.first as Map<String, dynamic>);

      // Check if latest version tag is newer than current version
      final latestTagClean = latest.tagName.replaceAll(RegExp(r'[^0-9.]'), '');
      final currentClean = currentVersion.replaceAll(RegExp(r'[^0-9.]'), '');

      final isNewer = _isVersionGreater(latestTagClean, currentClean);

      if (isNewer && latest.apkDownloadUrl != null) {
        state = state.copyWith(
          status: UpdateStatus.available,
          latestRelease: latest,
        );
      } else {
        state = state.copyWith(
          status: UpdateStatus.upToDate,
          latestRelease: latest,
        );
      }
    } catch (e) {
      if (!silent) {
        state = state.copyWith(
          status: UpdateStatus.error,
          errorMessage: e.toString(),
        );
      } else {
        state = state.copyWith(status: UpdateStatus.idle);
      }
    }
  }

  bool _isVersionGreater(String v1, String v2) {
    try {
      final parts1 = v1.split('.').map(int.parse).toList();
      final parts2 = v2.split('.').map(int.parse).toList();
      for (int i = 0; i < parts1.length && i < parts2.length; i++) {
        if (parts1[i] > parts2[i]) return true;
        if (parts1[i] < parts2[i]) return false;
      }
      return parts1.length > parts2.length;
    } catch (_) {
      return v1 != v2;
    }
  }

  Future<void> downloadAndInstall(BuildContext context) async {
    final release = state.latestRelease;
    final apkUrl = release?.apkDownloadUrl;
    if (apkUrl == null) return;

    state = state.copyWith(
      status: UpdateStatus.downloading,
      downloadProgress: 0.01,
      errorMessage: null,
    );

    try {
      final tempDir = await getTemporaryDirectory();
      final savePath = '${tempDir.path}/LocalTransfer_${release!.tagName}.apk';
      final file = File(savePath);

      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(apkUrl));
      final response = await request.close();

      if (response.statusCode != 200) {
        throw Exception('Download failed with status: ${response.statusCode}');
      }

      final contentLength = response.contentLength;
      int downloaded = 0;
      final sink = file.openWrite();

      await for (final chunk in response) {
        downloaded += chunk.length;
        sink.add(chunk);
        if (contentLength > 0) {
          state = state.copyWith(downloadProgress: downloaded / contentLength);
        }
      }
      await sink.flush();
      await sink.close();

      state = state.copyWith(
        status: UpdateStatus.readyToInstall,
        downloadProgress: 1.0,
        downloadedFilePath: savePath,
      );

      // Trigger installation immediately
      if (checkPlatform([TargetPlatform.android])) {
        // ignore: use_build_context_synchronously
        await openFile(context, FileType.apk, savePath);
      }
    } catch (e) {
      state = state.copyWith(
        status: UpdateStatus.error,
        errorMessage: 'Failed to download update: $e',
      );
    }
  }

  void setAutoCheck(bool val) => state = state.copyWith(autoCheck: val);
  void setChannel(String val) => state = state.copyWith(channel: val);
  void setAutoDownloadWifi(bool val) => state = state.copyWith(autoDownloadWifi: val);
}

final appUpdateProvider = NotifierProvider<AppUpdateNotifier, AppUpdateState>((ref) {
  return AppUpdateNotifier();
}, debugLabel: 'AppUpdateProvider');
