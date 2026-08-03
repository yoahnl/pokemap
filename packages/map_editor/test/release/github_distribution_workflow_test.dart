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
    expect(workflow, contains('workflow_dispatch:'));
    expect(workflow, contains('macos-preflight:'));
    expect(workflow, contains('assemble-release:'));
    expect(workflow, contains('create-draft-release:'));
    expect(workflow, contains('smoke-download-draft:'));
    expect(workflow, contains('publish-release:'));
    expect(workflow, contains('promote-stable-feed:'));
    expect(
      workflow,
      contains(r'gh release create "$GITHUB_REF_NAME" --draft'),
    );
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

  test('stable release validates its tag and build before signing', () async {
    final workflow = await File(
      '../../.github/workflows/pokemap_desktop_release.yml',
    ).readAsString();

    expect(workflow, contains('validate-release:'));
    expect(
      workflow,
      contains(
        r'dart run tool/release/validate_release_version.dart '
        r'--tag "$GITHUB_REF_NAME" --pubspec pubspec.yaml '
        r'--github-output "$GITHUB_OUTPUT"',
      ),
    );
    expect(workflow, contains('- validate-release'));
    expect(
      workflow.indexOf('validate-release:'),
      lessThan(workflow.indexOf('macos-release:')),
    );
    expect(
      workflow.indexOf('validate-release:'),
      lessThan(workflow.indexOf('Import ephemeral Developer ID identity')),
    );
  });

  test('stable publication is atomic and promotes its index last', () async {
    final workflow = await File(
      '../../.github/workflows/pokemap_desktop_release.yml',
    ).readAsString();

    expect(workflow, contains('concurrency:'));
    expect(workflow, contains('cancel-in-progress: false'));
    expect(workflow, contains('pokemap-update-index.json'));
    expect(workflow, contains('SHA256SUMS'));
    expect(workflow, contains('validate_update_assets.dart'));
    expect(workflow, contains(r'gh release download "$GITHUB_REF_NAME"'));
    expect(
      workflow,
      contains(r'gh release edit "$GITHUB_REF_NAME" --draft=false'),
    );
    expect(workflow, contains('pokemap-editor-update-stable'));

    final draft = workflow.indexOf('create-draft-release:');
    final smoke = workflow.indexOf('smoke-download-draft:');
    final publish = workflow.indexOf('publish-release:');
    final promote = workflow.indexOf('promote-stable-feed:');
    expect(draft, lessThan(smoke));
    expect(smoke, lessThan(publish));
    expect(publish, lessThan(promote));

    final stablePromotion = workflow.substring(promote);
    final macosFeed = stablePromotion.lastIndexOf('appcast-macos.xml');
    final windowsFeed = stablePromotion.lastIndexOf('appcast-windows.xml');
    final index = stablePromotion.lastIndexOf('pokemap-update-index.json');
    expect(index, greaterThan(macosFeed));
    expect(index, greaterThan(windowsFeed));
  });

  test('manual macOS preflight cannot publish a release', () async {
    final workflow = await File(
      '../../.github/workflows/pokemap_desktop_release.yml',
    ).readAsString();

    final preflightStart = workflow.indexOf('macos-preflight:');
    final nextJob = workflow.indexOf('\n  windows:', preflightStart);
    final preflight = workflow.substring(preflightStart, nextJob);
    expect(preflight, contains("github.event_name == 'workflow_dispatch'"));
    expect(preflight, contains('environment: pokemap-release'));
    expect(preflight, contains('notarytool'));
    expect(preflight, isNot(contains('gh release')));
  });
}
