import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('desktop workflow builds the PokeMap editor on all three platforms',
      () async {
    final workflow = await File(
      '../../.github/workflows/pokemap_desktop_release.yml',
    ).readAsString();

    expect(workflow, contains('tags: ["pokemap-v*"]'));
    expect(workflow, contains('working-directory: packages/map_editor'));
    expect(workflow, contains('flutter build macos --release'));
    expect(workflow, contains('flutter build windows --release'));
    expect(workflow, contains('flutter build linux --release'));
    expect(workflow, contains('PokeMap-macos'));
    expect(workflow, contains('PokeMap-windows-x64.zip'));
    expect(workflow, contains('PokeMap-linux-x64.tar.gz'));
    expect(workflow, contains('tool/release/package_macos_preview.sh'));
    expect(workflow, contains('tool/release/notarize_macos_release.sh'));
    expect(workflow, contains('--volume-name PokeMap'));
    expect(workflow, contains(r'gh release create "$GITHUB_REF_NAME"'));
  });

  test('desktop release keeps credentials out of pull requests', () async {
    final workflow = await File(
      '../../.github/workflows/pokemap_desktop_release.yml',
    ).readAsString();

    expect(workflow, isNot(contains('pull_request_target')));
    expect(
      workflow,
      contains("startsWith(github.ref, 'refs/tags/pokemap-v')"),
    );
    expect(workflow, contains('DEVELOPER_ID_P12_BASE64'));
    expect(workflow, contains('APP_SPECIFIC_PASSWORD'));
    expect(workflow, contains('permissions:'));
    expect(workflow, contains('contents: write'));
  });
}
