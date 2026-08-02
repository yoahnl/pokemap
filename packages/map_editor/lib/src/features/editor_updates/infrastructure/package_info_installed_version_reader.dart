import 'package:package_info_plus/package_info_plus.dart';
import 'package:pub_semver/pub_semver.dart';

import '../domain/editor_update_catalog.dart';

final class EditorPackageVersionMetadata {
  const EditorPackageVersionMetadata({
    required this.version,
    required this.buildNumber,
  });

  final String version;
  final String buildNumber;
}

final class EditorInstalledVersionException implements Exception {
  const EditorInstalledVersionException(this.message);

  final String message;

  @override
  String toString() => 'EditorInstalledVersionException($message)';
}

final class PackageInfoInstalledVersionReader
    implements EditorInstalledVersionReader {
  PackageInfoInstalledVersionReader({
    Future<EditorPackageVersionMetadata> Function()? loadMetadata,
  }) : _loadMetadata = loadMetadata ?? _loadPlatformMetadata;

  final Future<EditorPackageVersionMetadata> Function() _loadMetadata;

  @override
  Future<Version> read() async {
    final metadata = await _loadMetadata();
    final Version version;
    try {
      version = Version.parse(metadata.version);
    } on FormatException {
      throw const EditorInstalledVersionException(
        'The installed application version is not valid SemVer.',
      );
    }
    if (version.isPreRelease ||
        version.build.isNotEmpty ||
        int.tryParse(metadata.buildNumber) == null) {
      throw const EditorInstalledVersionException(
        'The installed application metadata is not a stable release.',
      );
    }
    return version;
  }

  static Future<EditorPackageVersionMetadata> _loadPlatformMetadata() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return EditorPackageVersionMetadata(
      version: packageInfo.version,
      buildNumber: packageInfo.buildNumber,
    );
  }
}
