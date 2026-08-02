import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/features/editor_updates/infrastructure/package_info_installed_version_reader.dart';
import 'package:pub_semver/pub_semver.dart';

void main() {
  test('reads the installed version from binary package metadata', () async {
    final reader = PackageInfoInstalledVersionReader(
      loadMetadata: () async => const EditorPackageVersionMetadata(
        version: '0.3.0',
        buildNumber: '300',
      ),
    );

    expect(await reader.read(), Version.parse('0.3.0'));
  });

  test('rejects malformed binary package metadata', () async {
    final reader = PackageInfoInstalledVersionReader(
      loadMetadata: () async => const EditorPackageVersionMetadata(
        version: 'dev',
        buildNumber: 'local',
      ),
    );

    await expectLater(
      reader.read(),
      throwsA(isA<EditorInstalledVersionException>()),
    );
  });
}
