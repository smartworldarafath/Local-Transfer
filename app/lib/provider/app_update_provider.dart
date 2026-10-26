import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:localsend_app/provider/version_provider.dart';
import 'package:localsend_app/util/native/open_file.dart';
import 'package:localsend_app/util/native/platform_check.dart';
import 'package:localsend_isolates/model/file_type.dart';
import 'package:path_provider/path_provider.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

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
  final String? windowsDownloadUrl;
  final int? windowsSize;
  final String? macosDownloadUrl;
  final int? macosSize;
  final String? linuxDownloadUrl;
  final int? linuxSize;
  final String? iosDownloadUrl;
  final int? iosSize;

  AppReleaseInfo({
    required this.tagName,
    required this.name,
    required this.body,
    required this.htmlUrl,
    this.apkDownloadUrl,
    this.apkSize,
    this.windowsDownloadUrl,
    this.windowsSize,
    this.macosDownloadUrl,
    this.macosSize,
    this.linuxDownloadUrl,
    this.linuxSize,
    this.iosDownloadUrl,
    this.iosSize,
  });

  String? get platformDownloadUrl {
    if (checkPlatform([TargetPlatform.android])) {
      return apkDownloadUrl;
    } else if (checkPlatform([TargetPlatform.windows])) {
      return windowsDownloadUrl;
    } else if (checkPlatform([TargetPlatform.macOS])) {
      return macosDownloadUrl;
    } else if (checkPlatform([TargetPlatform.linux])) {
      return linuxDownloadUrl;
    } else if (checkPlatform([TargetPlatform.iOS])) {
      return iosDownloadUrl;
    }
    return apkDownloadUrl ?? windowsDownloadUrl ?? macosDownloadUrl ?? linuxDownloadUrl;
  }

  factory AppReleaseInfo.fromJson(Map<String, dynamic> json) {
    String? apkUrl;
    int? apkSize;
    String? windowsUrl;
    int? windowsSize;
    String? macosUrl;
    int? macosSize;
    String? linuxUrl;
    int? linuxSize;
    String? iosUrl;
    int? iosSize;

    final assets = json['assets'] as List<dynamic>?;
    if (assets != null) {
      for (final a in assets) {
        final name = (a['name'] as String? ?? '').toLowerCase();
        final url = a['browser_download_url'] as String?;
        final size = a['size'] as int?;

        if (name.endsWith('.apk')) {
          apkUrl ??= url;
          apkSize ??= size;
        } else if (name.endsWith('.exe')) {
          windowsUrl = url;
          windowsSize = size;
        } else if (name.endsWith('.zip') && (name.contains('windows') || name.contains('win'))) {
          windowsUrl ??= url;
          windowsSize ??= size;
        } else if (name.endsWith('.dmg')) {
          macosUrl = url;
          macosSize = size;
        } else if (name.endsWith('.zip') && (name.contains('macos') || name.contains('mac') || name.contains('darwin'))) {
          macosUrl ??= url;
          macosSize ??= size;
        } else if (name.endsWith('.appimage')) {
          linuxUrl = url;
          linuxSize = size;
        } else if (name.endsWith('.tar.gz') && (name.contains('linux') || name.contains('x86_64'))) {
          linuxUrl ??= url;
          linuxSize ??= size;
        } else if (name.endsWith('.ipa')) {
          iosUrl = url;
          iosSize = size;
        }
      }
    }

    final tagName = json['tag_name'] as String? ?? '';
    return AppReleaseInfo(
      tagName: tagName,
      name: json['name'] as String? ?? json['tag_name'] as String? ?? '',
      body: json['body'] as String? ?? '',
      htmlUrl: json['html_url'] as String? ?? '',
      apkDownloadUrl: apkUrl ?? 'https://github.com/smartworldarafath/Local-Transfer/releases/download/$tagName/LocalTransfer-$tagName.apk',
      apkSize: apkSize,
      windowsDownloadUrl: windowsUrl ?? 'https://github.com/smartworldarafath/Local-Transfer/releases/download/$tagName/LocalTransfer-$tagName-windows-x64.exe',
      windowsSize: windowsSize,
      macosDownloadUrl: macosUrl ?? 'https://github.com/smartworldarafath/Local-Transfer/releases/download/$tagName/LocalTransfer-$tagName-macos.dmg',
      macosSize: macosSize,
      linuxDownloadUrl: linuxUrl ?? 'https://github.com/smartworldarafath/Local-Transfer/releases/download/$tagName/LocalTransfer-$tagName-linux-x86_64.AppImage',
      linuxSize: linuxSize,
      iosDownloadUrl: iosUrl ?? 'https://github.com/smartworldarafath/Local-Transfer/releases/download/$tagName/LocalTransfer-$tagName-ios-universal.ipa',
      iosSize: iosSize,
    );
  }

  factory AppReleaseInfo.fromVersionJson(Map<String, dynamic> json) {
    final downloads = json['download_urls'] as Map<String, dynamic>? ?? {};
    final tag = json['tag_name'] as String? ?? 'v${json['version']}';
    return AppReleaseInfo(
      tagName: tag,
      name: json['name'] as String? ?? 'v${json['version']}',
      body: json['body'] as String? ?? '',
      htmlUrl: json['html_url'] as String? ?? 'https://github.com/smartworldarafath/Local-Transfer/releases',
      apkDownloadUrl: downloads['android'] as String? ?? 'https://github.com/smartworldarafath/Local-Transfer/releases/download/$tag/LocalTransfer-$tag.apk',
      windowsDownloadUrl: (downloads['windows_exe'] ?? downloads['windows_zip']) as String? ?? 'https://github.com/smartworldarafath/Local-Transfer/releases/download/$tag/LocalTransfer-$tag-windows-x64.exe',
      macosDownloadUrl: (downloads['macos_dmg'] ?? downloads['macos_zip']) as String? ?? 'https://github.com/smartworldarafath/Local-Transfer/releases/download/$tag/LocalTransfer-$tag-macos.dmg',
      linuxDownloadUrl: (downloads['linux_appimage'] ?? downloads['linux_tar']) as String? ?? 'https://github.com/smartworldarafath/Local-Transfer/releases/download/$tag/LocalTransfer-$tag-linux-x86_64.AppImage',
      iosDownloadUrl: downloads['ios_ipa'] as String? ?? 'https://github.com/smartworldarafath/Local-Transfer/releases/download/$tag/LocalTransfer-$tag-ios-universal.ipa',
    );
  }

  static AppReleaseInfo? fromAtomFeed(String xml) {
    try {
      final entryRegex = RegExp(r'<entry>([\s\S]*?)<\/entry>');
      final match = entryRegex.firstMatch(xml);
      if (match == null) return null;
      final entry = match.group(1)!;

      final tagMatch = RegExp(r'<id>tag:github\.com,2008:Repository\/\d+\/(.+?)<\/id>').firstMatch(entry);
      final titleMatch = RegExp(r'<title>(.*?)<\/title>').firstMatch(entry);
      final linkMatch = RegExp(r'<link[^>]*href="([^"]+)"').firstMatch(entry);

      final tagName = tagMatch?.group(1) ?? '';
      final title = titleMatch?.group(1) ?? tagName;
      final htmlUrl = linkMatch?.group(1) ?? 'https://github.com/smartworldarafath/Local-Transfer/releases/tag/$tagName';

      return AppReleaseInfo(
        tagName: tagName,
        name: title,
        body: '',
        htmlUrl: htmlUrl,
        apkDownloadUrl: 'https://github.com/smartworldarafath/Local-Transfer/releases/download/$tagName/LocalTransfer-$tagName.apk',
        windowsDownloadUrl: 'https://github.com/smartworldarafath/Local-Transfer/releases/download/$tagName/LocalTransfer-$tagName-windows-x64.exe',
        macosDownloadUrl: 'https://github.com/smartworldarafath/Local-Transfer/releases/download/$tagName/LocalTransfer-$tagName-macos.dmg',
        linuxDownloadUrl: 'https://github.com/smartworldarafath/Local-Transfer/releases/download/$tagName/LocalTransfer-$tagName-linux-x86_64.AppImage',
        iosDownloadUrl: 'https://github.com/smartworldarafath/Local-Transfer/releases/download/$tagName/LocalTransfer-$tagName-ios-universal.ipa',
      );
    } catch (_) {
      return null;
    }
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
      AppReleaseInfo? latest;

      // 1. Try GitHub Releases REST API
      try {
        final client = HttpClient();
        client.userAgent = 'LocalTransfer-App';
        final request = await client.getUrl(Uri.parse(repoReleasesUrl));
        request.headers.set('Accept', 'application/vnd.github.v3+json');
        final response = await request.close();

        if (response.statusCode == 200) {
          final responseBody = await response.transform(utf8.decoder).join();
          final List<dynamic> releasesJson = jsonDecode(responseBody) as List<dynamic>;
          if (releasesJson.isNotEmpty) {
            latest = AppReleaseInfo.fromJson(releasesJson.first as Map<String, dynamic>);
          }
        }
      } catch (_) {
        // Proceed to zero-rate-limit fallback
      }

      // 2. If API was rate limited (403/429) or failed, try version.json (Raw / CDN)
      if (latest == null) {
        for (final rawUrl in [
          'https://raw.githubusercontent.com/smartworldarafath/Local-Transfer/main/version.json',
          'https://cdn.jsdelivr.net/gh/smartworldarafath/Local-Transfer@main/version.json',
        ]) {
          try {
            final client = HttpClient();
            client.userAgent = 'LocalTransfer-App';
            final request = await client.getUrl(Uri.parse(rawUrl));
            final response = await request.close();
            if (response.statusCode == 200) {
              final body = await response.transform(utf8.decoder).join();
              final Map<String, dynamic> vJson = jsonDecode(body) as Map<String, dynamic>;
              latest = AppReleaseInfo.fromVersionJson(vJson);
              break;
            }
          } catch (_) {}
        }
      }

      // 3. Fallback to GitHub Releases Atom feed (always available, no token/rate limit)
      if (latest == null) {
        try {
          final client = HttpClient();
          client.userAgent = 'LocalTransfer-App';
          final request = await client.getUrl(Uri.parse('https://github.com/smartworldarafath/Local-Transfer/releases.atom'));
          final response = await request.close();
          if (response.statusCode == 200) {
            final body = await response.transform(utf8.decoder).join();
            latest = AppReleaseInfo.fromAtomFeed(body);
          }
        } catch (_) {}
      }

      if (latest == null) {
        throw Exception('Unable to reach update servers. Please check your internet connection.');
      }

      final currentVersionCombined = ref.read(versionProvider).data?.combinedString ?? 'v1.3.5 (Beta 4)';
      final isNewer = _isVersionGreater(latest.tagName, currentVersionCombined);

      if (isNewer) {
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

  bool _isVersionGreater(String remote, String current) {
    try {
      final semverRegex = RegExp(r'(\d+)\.(\d+)\.(\d+)');
      final matchRemote = semverRegex.firstMatch(remote);
      final matchCurrent = semverRegex.firstMatch(current);

      if (matchRemote != null && matchCurrent != null) {
        final rMajor = int.parse(matchRemote.group(1)!);
        final rMinor = int.parse(matchRemote.group(2)!);
        final rPatch = int.parse(matchRemote.group(3)!);

        final cMajor = int.parse(matchCurrent.group(1)!);
        final cMinor = int.parse(matchCurrent.group(2)!);
        final cPatch = int.parse(matchCurrent.group(3)!);

        if (rMajor != cMajor) return rMajor > cMajor;
        if (rMinor != cMinor) return rMinor > cMinor;
        if (rPatch != cPatch) return rPatch > cPatch;
      } else if (matchRemote != null && matchCurrent == null) {
        return true;
      } else if (matchRemote == null) {
        return false;
      }

      // If Major.Minor.Patch are identical, check beta version numbers
      final betaRegex = RegExp(r'beta[^\d]*(\d+(?:\.\d+)?)', caseSensitive: false);
      final remoteBeta = betaRegex.firstMatch(remote)?.group(1);
      final currentBeta = betaRegex.firstMatch(current)?.group(1);

      if (remoteBeta != null && currentBeta != null) {
        final rB = double.tryParse(remoteBeta) ?? 0.0;
        final cB = double.tryParse(currentBeta) ?? 0.0;
        return rB > cB;
      } else if (remoteBeta == null && currentBeta != null) {
        // Remote is full release, current is beta -> remote is newer!
        return true;
      } else if (remoteBeta != null && currentBeta == null) {
        // Remote is beta, current is full release -> remote is older!
        return false;
      }

      // Both versions are identical in semver and beta stage -> NOT newer!
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> downloadAndInstall(BuildContext context) async {
    final release = state.latestRelease;
    if (release == null) return;

    // Non-Android platforms: direct open or download
    if (checkPlatform([TargetPlatform.windows])) {
      final targetUrl = release.windowsDownloadUrl ?? release.htmlUrl;
      if (targetUrl.toLowerCase().endsWith('.exe')) {
        await _downloadAndRunWindowsExe(context, targetUrl, release.tagName);
        return;
      }
      await launchUrl(Uri.parse(targetUrl), mode: LaunchMode.externalApplication);
      return;
    }

    if (checkPlatform([TargetPlatform.macOS, TargetPlatform.linux, TargetPlatform.iOS])) {
      final targetUrl = release.platformDownloadUrl ?? release.htmlUrl;
      await launchUrl(Uri.parse(targetUrl), mode: LaunchMode.externalApplication);
      return;
    }

    // Android APK download & install flow
    final apkUrl = release.apkDownloadUrl;
    if (apkUrl == null) {
      await launchUrl(Uri.parse(release.htmlUrl), mode: LaunchMode.externalApplication);
      return;
    }

    state = state.copyWith(
      status: UpdateStatus.downloading,
      downloadProgress: 0.01,
      errorMessage: null,
    );

    try {
      final tempDir = await getTemporaryDirectory();
      final savePath = '${tempDir.path}/LocalTransfer_${release.tagName}.apk';
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

      if (context.mounted && checkPlatform([TargetPlatform.android])) {
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

  Future<void> _downloadAndRunWindowsExe(BuildContext context, String exeUrl, String tagName) async {
    state = state.copyWith(
      status: UpdateStatus.downloading,
      downloadProgress: 0.01,
      errorMessage: null,
    );

    try {
      final tempDir = await getTemporaryDirectory();
      final savePath = '${tempDir.path}\\LocalTransfer_$tagName.exe';
      final file = File(savePath);

      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(exeUrl));
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

      // Launch Windows installer
      await Process.start(savePath, [], runInShell: true);
    } catch (e) {
      state = state.copyWith(
        status: UpdateStatus.error,
        errorMessage: 'Failed to download installer: $e',
      );
      // Fallback to browser
      await launchUrl(Uri.parse(exeUrl), mode: LaunchMode.externalApplication);
    }
  }

  void setAutoCheck(bool val) => state = state.copyWith(autoCheck: val);
  void setChannel(String val) => state = state.copyWith(channel: val);
  void setAutoDownloadWifi(bool val) => state = state.copyWith(autoDownloadWifi: val);
}

final appUpdateProvider = NotifierProvider<AppUpdateNotifier, AppUpdateState>((ref) {
  return AppUpdateNotifier();
}, debugLabel: 'AppUpdateProvider');
