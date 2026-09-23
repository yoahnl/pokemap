import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
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
      final executable = await File(
        '/usr/bin/true',
      ).copy('${macos.path}/Fixture');
      final nested = await File(
        '/usr/bin/true',
      ).copy('${frameworks.path}/libfixture.dylib');
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

      final signing = await Process.run('/bin/bash', <String>[
        'tool/release/sign_macos_app.sh',
        '--app',
        app.path,
        '--identity',
        '-',
        '--entitlements',
        entitlements.path,
        '--no-timestamp',
      ]);

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

  test(
    'release signing expands the bundle identifier in entitlements',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'pokemap-entitlements-fixture-',
      );
      addTearDown(() => root.delete(recursive: true));
      final app = Directory('${root.path}/Fixture.app');
      final macos = Directory('${app.path}/Contents/MacOS');
      await macos.create(recursive: true);
      final executable = await File(
        '/usr/bin/true',
      ).copy('${macos.path}/Fixture');
      final chmod = await Process.run('/bin/chmod', <String>[
        '755',
        executable.path,
      ]);
      expect(chmod.exitCode, 0, reason: '${chmod.stderr}');
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
      await entitlements.writeAsString(r'''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>com.apple.security.temporary-exception.mach-lookup.global-name</key>
  <array>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)-spks</string>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)-spki</string>
  </array>
</dict>
</plist>
''');

      final signing = await Process.run('/bin/bash', <String>[
        'tool/release/sign_macos_app.sh',
        '--app',
        app.path,
        '--identity',
        '-',
        '--entitlements',
        entitlements.path,
        '--no-timestamp',
      ]);

      expect(signing.exitCode, 0, reason: '${signing.stderr}');
      final signedEntitlements = await Process.run(
        '/usr/bin/codesign',
        <String>['--display', '--entitlements', ':-', app.path],
      );
      expect(
        signedEntitlements.exitCode,
        0,
        reason: '${signedEntitlements.stderr}',
      );
      final output = '${signedEntitlements.stdout}${signedEntitlements.stderr}';
      expect(output, contains('app.pokemap.signing-fixture-spks'));
      expect(output, contains('app.pokemap.signing-fixture-spki'));
      expect(output, isNot(contains(r'$(PRODUCT_BUNDLE_IDENTIFIER)')));
    },
    skip: !Platform.isMacOS,
  );

  test('release signing script enforces Developer ID team coherence', () async {
    final signing = await File('tool/release/sign_macos_app.sh').readAsString();

    expect(signing, contains('Authority=Developer ID Application:'));
    expect(signing, contains('TeamIdentifier='));
    expect(signing, contains('Nested code TeamIdentifier mismatch'));
    expect(signing, contains('team_consistent=true'));
  });
}
