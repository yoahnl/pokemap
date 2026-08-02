import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/features/editor_updates/domain/editor_release_version.dart';

void main() {
  group('EditorReleaseVersionContract', () {
    test('accepts a stable tag matching a numeric build version', () {
      final result = EditorReleaseVersionContract.validate(
        tag: 'pokemap-v0.3.0',
        pubspecContents: '''
name: map_editor
version: 0.3.0+300
''',
        previousBuildNumber: 299,
      );

      expect(result.isValid, isTrue);
      expect(result.version?.toString(), '0.3.0+300');
      expect(result.displayVersion, '0.3.0');
      expect(result.buildNumber, 300);
      expect(result.errors, isEmpty);
    });

    test('rejects a tag that differs from the pubspec display version', () {
      final result = EditorReleaseVersionContract.validate(
        tag: 'pokemap-v0.3.1',
        pubspecContents: 'version: 0.3.0+300',
      );

      expect(
        result.errors,
        contains('Tag version 0.3.1 does not match pubspec version 0.3.0.'),
      );
    });

    test('rejects a stable release with prerelease metadata', () {
      final result = EditorReleaseVersionContract.validate(
        tag: 'pokemap-v0.3.0',
        pubspecContents: 'version: 0.3.0-beta.1+300',
      );

      expect(
        result.errors,
        contains('Stable releases cannot use a prerelease version.'),
      );
    });

    test('rejects a missing numeric build number', () {
      final missing = EditorReleaseVersionContract.validate(
        tag: 'pokemap-v0.3.0',
        pubspecContents: 'version: 0.3.0',
      );
      final nonNumeric = EditorReleaseVersionContract.validate(
        tag: 'pokemap-v0.3.0',
        pubspecContents: 'version: 0.3.0+bootstrap',
      );

      expect(
        missing.errors,
        contains('The pubspec version must contain one numeric build number.'),
      );
      expect(
        nonNumeric.errors,
        contains('The pubspec version must contain one numeric build number.'),
      );
    });

    test('rejects a build number that is not strictly increasing', () {
      final result = EditorReleaseVersionContract.validate(
        tag: 'pokemap-v0.3.0',
        pubspecContents: 'version: 0.3.0+300',
        previousBuildNumber: 300,
      );

      expect(
        result.errors,
        contains(
          'Build number 300 must be greater than previous build number 300.',
        ),
      );
    });

    test('rejects malformed tags and missing pubspec versions', () {
      final malformedTag = EditorReleaseVersionContract.validate(
        tag: 'v0.3.0',
        pubspecContents: 'version: 0.3.0+300',
      );
      final missingVersion = EditorReleaseVersionContract.validate(
        tag: 'pokemap-v0.3.0',
        pubspecContents: 'name: map_editor',
      );

      expect(
        malformedTag.errors,
        contains('Release tag must match pokemap-vX.Y.Z.'),
      );
      expect(
        missingVersion.errors,
        contains('Unable to read a version from pubspec.yaml.'),
      );
    });
  });
}
