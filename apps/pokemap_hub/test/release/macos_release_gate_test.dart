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

  test(
    'release signing script seals nested code with one identity',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'pokemap-signing-fixture-',
      );
      addTearDown(() => root.delete(recursive: true));
      final app = Directory('${root.path}/Fixture.app');
      final macos = Directory('${app.path}/Contents/MacOS');
      final frameworks = Directory('${app.path}/Contents/Frameworks');
      await macos.create(recursive: true);
      await frameworks.create(recursive: true);
      final executable = await File('/usr/bin/true').copy(
        '${macos.path}/Fixture',
      );
      final nested = await File('/usr/bin/true').copy(
        '${frameworks.path}/libfixture.dylib',
      );
      for (final file in <File>[executable, nested]) {
        final chmod = await Process.run('/bin/chmod', <String>[
          '755',
          file.path,
        ]);
        expect(chmod.exitCode, 0, reason: '${chmod.stderr}');
      }
      await File('${app.path}/Contents/Info.plist').writeAsString('''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>Fixture</string>
  <key>CFBundleIdentifier</key>
  <string>app.pokemap.signing-fixture</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
</dict>
</plist>
''');
      final entitlements = File('${root.path}/Release.entitlements');
      await entitlements.writeAsString('''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict/></plist>
''');

      final signing = await Process.run(
        '/bin/bash',
        <String>[
          'tool/release/sign_macos_app.sh',
          '--app',
          app.path,
          '--identity',
          '-',
          '--entitlements',
          entitlements.path,
          '--no-timestamp',
        ],
      );

      expect(signing.exitCode, 0, reason: '${signing.stderr}');
      expect(signing.stdout, contains('signature_verified=true'));
      final verification = await Process.run('/usr/bin/codesign', <String>[
        '--verify',
        '--deep',
        '--strict',
        '--verbose=4',
        app.path,
      ]);
      expect(verification.exitCode, 0, reason: '${verification.stderr}');
    },
    skip: !Platform.isMacOS,
  );

  test('release signing script enforces Developer ID team coherence', () async {
    final signing = await File(
      'tool/release/sign_macos_app.sh',
    ).readAsString();

    expect(signing, contains('Authority=Developer ID Application:'));
    expect(signing, contains('TeamIdentifier='));
    expect(signing, contains('Nested code TeamIdentifier mismatch'));
    expect(signing, contains('team_consistent=true'));
  });

  test('release workflow keeps secrets out of pull requests', () async {
    final workflow = await File(
      '../../.github/workflows/pokemap_hub_product_certification.yml',
    ).readAsString();

    expect(workflow, isNot(contains('pull_request_target')));
    expect(workflow, contains('workflow_dispatch:'));
    expect(workflow, contains("github.event_name == 'workflow_dispatch'"));
    expect(workflow, contains('inputs.notarize'));
    expect(workflow, contains('flutter test'));
    expect(workflow, contains('flutter analyze'));
    expect(workflow, contains('flutter build macos --release'));
    expect(workflow, contains('FLUTTER_VERSION: 3.46.0-0.3.pre'));
    expect(workflow, contains(r'refs/tags/$FLUTTER_VERSION'));
    expect(workflow, contains('tool/release/sign_macos_app.sh'));
    expect(
      workflow,
      isNot(contains(r'find "$APP_PATH/Contents/Frameworks"')),
    );
    expect(workflow, contains("startsWith(github.ref, 'refs/tags/"));
    expect(workflow, contains('tool/release/notarize_macos_release.sh'));
    expect(workflow, isNot(contains('hdiutil create -volname')));
    expect(
        workflow, contains('--entitlements macos/Runner/Release.entitlements'));
    expect(workflow, contains('build_neutral_package_artifact_test.dart'));
    expect(workflow, contains('verify_macos_distribution.dart'));
    expect(workflow, contains('(deny network*)'));
    expect(
      workflow,
      contains(
        'actions/upload-artifact@'
        'ea165f8d65b6e75b540449e92b4886f43607fa02',
      ),
    );
    expect(workflow, contains('build/PokeMapHub.dmg'));
    expect(workflow, contains('build/macos-certification-receipt.json'));
    expect(workflow, contains(r'$RUNNER_TEMP/notary-logs'));
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
