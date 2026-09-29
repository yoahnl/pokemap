import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Windows installer upgrades the existing PokeMap installation', () {
    final previous = File(
      '../../packages/map_editor/windows/installer/pokemap.iss',
    ).readAsStringSync();
    final studio = File(
      'windows/installer/avelune_studio.iss',
    ).readAsStringSync();

    for (final setting in [
      'AppId',
      'DefaultDirName',
      'PrivilegesRequired',
      'ArchitecturesAllowed',
      'ArchitecturesInstallIn64BitMode',
    ]) {
      expect(_setupValue(studio, setting), _setupValue(previous, setting));
    }
    expect(_setupValue(studio, 'AppName'), 'Avelune Studio');
    expect(
      _setupValue(studio, 'OutputBaseFilename'),
      'PokeMap-Editor-Setup-{#AppVersion}',
    );
    expect(studio, contains(r'Filename: "{app}\PokeMap.exe"'));
    expect(studio, contains(r'Name: "{autoprograms}\Avelune Studio"'));
    expect(studio, contains(r'Name: "{autodesktop}\Avelune Studio"'));
    expect(studio, contains(r'Name: "{app}\WinSparkle.dll"'));
    expect(
      _setupValue(studio, 'SetupIconFile'),
      r'..\runner\resources\app_icon.ico',
    );

    final packaging = File(
      'tool/release/package_windows_manual_release.ps1',
    ).readAsStringSync();
    expect(packaging, contains('windows\\installer\\avelune_studio.iss'));
    expect(packaging, contains('PokeMap-Editor-Setup-\$Version.exe'));
  });

  test('Windows runner uses the Studio name and icon', () {
    final previous = File(
      '../../packages/map_editor/windows/CMakeLists.txt',
    ).readAsStringSync();
    final studio = File('windows/CMakeLists.txt').readAsStringSync();
    expect(
      _cmakeValue(studio, 'BINARY_NAME'),
      _cmakeValue(previous, 'BINARY_NAME'),
    );
    final runnerBuild = File(
      'windows/runner/CMakeLists.txt',
    ).readAsStringSync();
    expect(runnerBuild, isNot(contains('WinSparkle')));
    expect(
      File('windows/runner/editor_updater_bridge.cpp').existsSync(),
      isFalse,
    );

    final main = File('windows/runner/main.cpp').readAsStringSync();
    final resources = File('windows/runner/Runner.rc').readAsStringSync();
    expect(main, contains('window.Create(L"Avelune Studio"'));
    expect(resources, contains('VALUE "ProductName", "Avelune Studio"'));
    expect(resources, contains('IDI_APP_ICON'));
    expect(resources, contains('resources\\\\app_icon.ico'));

    final icon = File(
      'windows/runner/resources/app_icon.ico',
    ).readAsBytesSync();
    expect(icon.length, greaterThan(64));
    expect(icon.sublist(0, 6), [0, 0, 1, 0, 1, 0]);
  });

  test('Linux keeps the install identity and displays Avelune Studio', () {
    final previous = File(
      '../../packages/map_editor/linux/CMakeLists.txt',
    ).readAsStringSync();
    final studio = File('linux/CMakeLists.txt').readAsStringSync();
    expect(
      _cmakeValue(studio, 'BINARY_NAME'),
      _cmakeValue(previous, 'BINARY_NAME'),
    );
    expect(
      _cmakeValue(studio, 'APPLICATION_ID'),
      _cmakeValue(previous, 'APPLICATION_ID'),
    );
    expect(studio, contains('RENAME "studio_icon.png"'));

    final runner = File('linux/runner/my_application.cc').readAsStringSync();
    expect(
      runner,
      contains('gtk_header_bar_set_title(header_bar, "Avelune Studio")'),
    );
    expect(runner, contains('gtk_window_set_title(window, "Avelune Studio")'));
    expect(runner, contains('gtk_window_set_icon_from_file(window, icon_path'));
    expect(runner, contains('"studio_icon.png"'));
  });

  test(
    'Linux packager produces the release asset from a complete bundle',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'avelune-studio-linux-release-',
      );
      try {
        final bundle = Directory('${directory.path}/bundle');
        final output = Directory('${directory.path}/release');
        await Directory('${bundle.path}/data').create(recursive: true);
        await Directory('${bundle.path}/lib').create(recursive: true);
        await File(
          'macos/Runner/Assets.xcassets/AppIcon.appiconset/icon_256x256.png',
        ).copy('${bundle.path}/data/studio_icon.png');
        final binary = File('${bundle.path}/pokemap');
        await binary.writeAsString('studio');
        final chmod = await Process.run('chmod', ['+x', binary.path]);
        expect(chmod.exitCode, 0);

        final result = await Process.run('bash', [
          'tool/release/package_linux_release.sh',
          '--version',
          '0.3.8',
          '--bundle',
          bundle.path,
          '--output-dir',
          output.path,
        ]);
        expect(
          result.exitCode,
          0,
          reason: '${result.stdout}\n${result.stderr}',
        );

        final archive = File(
          '${output.path}/PokeMap-Editor-0.3.8-linux-x64.tar.gz',
        );
        expect(await archive.exists(), isTrue);
        final listing = await Process.run('tar', ['-tzf', archive.path]);
        expect(listing.exitCode, 0);
        expect(listing.stdout.toString(), contains('./pokemap'));
        expect(listing.stdout.toString(), contains('./data/studio_icon.png'));
      } finally {
        await directory.delete(recursive: true);
      }
    },
    skip: Platform.isWindows,
  );
}

String? _setupValue(String source, String key) {
  return RegExp(
    '^${RegExp.escape(key)}=(.*)\$',
    multiLine: true,
  ).firstMatch(source)?.group(1);
}

String? _cmakeValue(String source, String key) {
  return RegExp(
    'set\\(${RegExp.escape(key)} "([^"]+)"\\)',
  ).firstMatch(source)?.group(1);
}
