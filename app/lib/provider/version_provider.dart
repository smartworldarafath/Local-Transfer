import 'package:package_info_plus/package_info_plus.dart';
import 'package:refena_flutter/refena_flutter.dart';

class VersionData {
  final String version;
  final String buildNumber;
  final String combinedString;

  VersionData({
    required this.version,
    required this.buildNumber,
  }) : combinedString = 'v1.2.0 (Beta 1)';
}

final versionProvider = FutureProvider((ref) async {
  final info = await PackageInfo.fromPlatform();
  return VersionData(
    version: info.version,
    buildNumber: info.buildNumber,
  );
}, debugLabel: 'VersionProvider');
