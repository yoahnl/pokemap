import 'package:pub_semver/pub_semver.dart';

final class EditorReleaseVersionValidation {
  EditorReleaseVersionValidation({
    required this.version,
    required this.displayVersion,
    required this.buildNumber,
    required List<String> errors,
  }) : errors = List.unmodifiable(errors);

  final Version? version;
  final String? displayVersion;
  final int? buildNumber;
  final List<String> errors;

  bool get isValid => errors.isEmpty;
}

abstract final class EditorReleaseVersionContract {
  static final RegExp _tagPattern = RegExp(
    r'^pokemap-v(\d+\.\d+\.\d+)$',
  );
  static final RegExp _pubspecVersionPattern = RegExp(
    r'^version:\s*([^\s#]+)',
    multiLine: true,
  );

  static EditorReleaseVersionValidation validate({
    required String tag,
    required String pubspecContents,
    int? previousBuildNumber,
  }) {
    final errors = <String>[];
    final tagMatch = _tagPattern.firstMatch(tag);
    if (tagMatch == null) {
      errors.add('Release tag must match pokemap-vX.Y.Z.');
    }

    final versionText =
        _pubspecVersionPattern.firstMatch(pubspecContents)?.group(1);
    if (versionText == null) {
      errors.add('Unable to read a version from pubspec.yaml.');
      return EditorReleaseVersionValidation(
        version: null,
        displayVersion: null,
        buildNumber: null,
        errors: errors,
      );
    }

    Version? version;
    try {
      version = Version.parse(versionText);
    } on FormatException {
      errors.add('Pubspec version "$versionText" is not valid SemVer.');
      return EditorReleaseVersionValidation(
        version: null,
        displayVersion: null,
        buildNumber: null,
        errors: errors,
      );
    }

    final displayVersion = [
      version.major,
      version.minor,
      version.patch,
    ].join('.');
    final tagVersion = tagMatch?.group(1);
    if (tagVersion != null && tagVersion != displayVersion) {
      errors.add(
        'Tag version $tagVersion does not match pubspec version '
        '$displayVersion.',
      );
    }
    if (version.isPreRelease) {
      errors.add('Stable releases cannot use a prerelease version.');
    }

    final buildNumber = version.build.length == 1 && version.build.single is int
        ? version.build.single as int
        : null;
    if (buildNumber == null) {
      errors.add('The pubspec version must contain one numeric build number.');
    } else if (previousBuildNumber != null &&
        buildNumber <= previousBuildNumber) {
      errors.add(
        'Build number $buildNumber must be greater than previous build number '
        '$previousBuildNumber.',
      );
    }

    return EditorReleaseVersionValidation(
      version: version,
      displayVersion: displayVersion,
      buildNumber: buildNumber,
      errors: errors,
    );
  }
}
