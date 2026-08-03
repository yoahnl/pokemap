import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('macOS packager creates a full signed Sparkle archive and appcast', () {
    final script = File(
      'tool/release/package_macos_update.sh',
    ).readAsStringSync();

    expect(script, contains('set -euo pipefail'));
    expect(script, contains('ditto'));
    expect(script, contains('generate_appcast'));
    expect(script, contains('--ed-key-file'));
    expect(script, contains('--download-url-prefix'));
    expect(script, contains('appcast-macos.xml'));
    expect(script, contains('PokeMap-Editor-'));
  });

  test('Windows packager signs the Inno installer and writes its appcast', () {
    final script = File(
      'tool/release/package_windows_update.ps1',
    ).readAsStringSync();

    expect(script, contains('ISCC.exe'));
    expect(script, contains('winsparkle-tool'));
    expect(script, contains('--private-key-file'));
    expect(script, contains('sparkle:edSignature'));
    expect(script, contains('sparkle:installerArguments'));
    expect(script, contains('appcast-windows.xml'));
    expect(script, contains('PokeMap-Editor-Setup-'));
  });

  test('Windows manual packager creates an installer without an update feed',
      () {
    final script = File(
      'tool/release/package_windows_manual_release.ps1',
    ).readAsStringSync();

    expect(script, contains('ISCC.exe'));
    expect(script, contains('PokeMap-Editor-Setup-'));
    expect(script, contains('PokeMap.exe'));
    expect(script, isNot(contains('winsparkle-tool')));
    expect(script, isNot(contains('appcast-windows.xml')));
  });

  test('release workflow injects public keys without publishing private keys',
      () {
    final workflow = File(
      '../../.github/workflows/pokemap_desktop_release.yml',
    ).readAsStringSync();

    expect(workflow, contains('POKEMAP_SPARKLE_PUBLIC_ED_KEY'));
    expect(workflow, contains('SPARKLE_PRIVATE_ED_KEY_BASE64'));
    expect(workflow, contains('package_macos_update.sh'));
    expect(workflow, contains('package_windows_manual_release.ps1'));
    expect(workflow, isNot(contains('WINSPARKLE_PRIVATE_ED_KEY_BASE64')));
    expect(workflow, isNot(contains('sparkle_private_key=')));
  });
}
