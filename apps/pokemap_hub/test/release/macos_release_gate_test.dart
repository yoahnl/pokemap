import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('release verifier is fail-closed for every Apple distribution gate',
      () async {
    final verifier = await File(
      'tool/release/verify_macos_distribution.dart',
    ).readAsString();

    expect(verifier, contains('Developer ID Application'));
    expect(verifier, contains('codesign'));
    expect(verifier, contains('notarytool'));
    expect(verifier, contains('stapler'));
    expect(verifier, contains('spctl'));
    expect(verifier, contains('hardenedRuntime'));
    expect(verifier, contains('releaseEntitlements'));
    expect(verifier, contains('com.apple.security.get-task-allow'));
    expect(verifier, contains('app.pokemap.hub'));
    expect(verifier, contains("'attach'"));
    expect(verifier, contains('neutralPackageSha256'));
    expect(verifier, isNot(contains('--skip')));
    expect(verifier, isNot(contains('NOTARY_PASSWORD')));
  });

  test('release workflow keeps secrets out of pull requests', () async {
    final workflow = await File(
      '../../.github/workflows/pokemap_hub_product_certification.yml',
    ).readAsString();

    expect(workflow, isNot(contains('pull_request_target')));
    expect(workflow, contains('flutter test'));
    expect(workflow, contains('flutter analyze'));
    expect(workflow, contains('flutter build macos --release'));
    expect(workflow, contains("startsWith(github.ref, 'refs/tags/"));
    expect(workflow, contains('xcrun notarytool submit'));
    expect(workflow, contains('xcrun stapler staple'));
    expect(workflow, contains('spctl --assess'));
    expect(
        workflow, contains('--entitlements macos/Runner/Release.entitlements'));
    expect(workflow, contains('build_neutral_package_artifact_test.dart'));
    expect(workflow, contains('verify_macos_distribution.dart'));
    expect(workflow, contains('(deny network*)'));
    expect(workflow, contains('"packages/map_editor/**"'));
    expect(workflow, contains('"packages/map_player_ui/**"'));
  });

  test('certification receipt schema excludes local and credential data',
      () async {
    final schema = await File(
      'tool/release/macos_certification_receipt.schema.json',
    ).readAsString();

    expect(schema, contains('"additionalProperties": false'));
    expect(schema, contains('"repositoryAbsent"'));
    expect(schema, contains('"networkDisabled"'));
    expect(schema, contains('"notarized"'));
    expect(schema, contains('"gatekeeperAccepted"'));
    expect(schema, isNot(contains('"username"')));
    expect(schema, isNot(contains('"absolutePath"')));
    expect(schema, isNot(contains('"credential"')));
  });
}
