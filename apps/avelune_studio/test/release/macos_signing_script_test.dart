import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('release signing seals extensionless nested Mach-O without executable permissions', () async {
    final root = await Directory.systemTemp.createTemp(
      'pokemap-signing-nested-mode-',
    );
    addTearDown(() => root.delete(recursive: true));
    final app = Directory('${root.path}/Fixture.app');
    final macos = await Directory('${app.path}/Contents/MacOS')
        .create(recursive: true);
    final frameworks = await Directory('${app.path}/Contents/Frameworks')
        .create(recursive: true);
    final executable = await File('/usr/bin/true')
        .copy('${macos.path}/Fixture');
    final nested = await File('/usr/bin/true')
        .copy('${frameworks.path}/Autoupdate');
    final unsigned = await Process.run('/usr/bin/codesign', <String>[
      '--remove-signature',
      nested.path,
    ]);
    expect(unsigned.exitCode, 0, reason: '${unsigned.stderr}');
    for (final (file, permissions) in [(executable, '755'), (nested, '644')]) {
      final chmod = await Process.run('/bin/chmod', <String>[
        permissions,
        file.path,
      ]);
      expect(chmod.exitCode, 0, reason: '${chmod.stderr}');
    }
    expect((await nested.stat()).mode & 0x1ff, int.parse('644', radix: 8));
    final before = await Process.run('/usr/bin/codesign', <String>[
      '--verify',
      '--strict',
      nested.path,
    ]);
    expect(before.exitCode, isNot(0), reason: '${before.stderr}');
    expect(before.stderr, contains('not signed'));
    await File('${app.path}/Contents/Info.plist').writeAsString('''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>Fixture</string>
  <key>CFBundleIdentifier</key>
  <string>app.pokemap.signing-nested-mode</string>
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

    final signing = await Process.run('/bin/bash', <String>[
      '../../tools/release/sign_macos_app.sh',
      '--app',
      app.path,
      '--identity',
      '-',
      '--no-timestamp',
      '--entitlements',
      entitlements.path,
    ]);

    expect(signing.exitCode, 0, reason: '${signing.stderr}');
    expect(signing.stdout, contains('signature_verified=true'));
    final after = await Process.run('/usr/bin/codesign', <String>[
      '--verify',
      '--strict',
      '--verbose=4',
      nested.path,
    ]);
    expect(after.exitCode, 0, reason: '${after.stderr}');
    final bundle = await Process.run('/usr/bin/codesign', <String>[
      '--verify',
      '--deep',
      '--strict',
      '--verbose=4',
      app.path,
    ]);
    expect(bundle.exitCode, 0, reason: '${bundle.stderr}');
  }, skip: !Platform.isMacOS);
}
