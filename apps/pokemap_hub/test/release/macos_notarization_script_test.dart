import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'notarization script staples the app before creating the final DMG',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'pokemap-notarization-fixture-',
      );
      addTearDown(() => root.delete(recursive: true));
      final app = Directory('${root.path}/PokeMap Hub.app');
      await app.create();
      final tools = Directory('${root.path}/tools');
      await tools.create();
      final commandLog = File('${root.path}/commands.log');
      final xcrun = await _fakeTool(
        tools,
        'xcrun',
        '''
if [[ "\$1 \$2" == "notarytool submit" ]]; then
  case "\$3" in
    *.zip) id="app-submission" ;;
    *.dmg) id="dmg-submission" ;;
    *) exit 65 ;;
  esac
  printf '{"id":"%s","status":"Accepted"}\\n' "\$id"
elif [[ "\$1 \$2" == "notarytool log" ]]; then
  output="\${!#}"
  printf '{"issues":[]}\\n' > "\$output"
fi
''',
      );
      final hdiutil = await _fakeTool(
        tools,
        'hdiutil',
        '''
if [[ "\$1" == "create" ]]; then
  output="\${!#}"
  : > "\$output"
elif [[ "\$1" == "verify" ]]; then
  attempts="\$COMMAND_LOG.hdiutil-verify-attempts"
  count=0
  if [[ -f "\$attempts" ]]; then
    count="\$(cat "\$attempts")"
  fi
  count="\$((count + 1))"
  printf '%s' "\$count" > "\$attempts"
  if [[ "\$count" == "1" ]]; then
    exit 75
  fi
fi
''',
      );
      final ditto = await _fakeTool(
        tools,
        'ditto',
        '''
output="\${!#}"
: > "\$output"
''',
      );
      final spctl = await _fakeTool(tools, 'spctl', '');
      final codesign = await _fakeTool(
        tools,
        'codesign',
        '''
if [[ "\$1" == "-d" ]]; then
  printf 'Authority=Developer ID Application: Fixture (FIXTURETEAM)\\n' >&2
fi
''',
      );
      final dmg = File('${root.path}/PokeMapHub.dmg');
      final result = File('${root.path}/notary-result.json');
      final logs = Directory('${root.path}/logs');

      final execution = await Process.run(
        '/bin/bash',
        <String>[
          'tool/release/notarize_macos_release.sh',
          '--app',
          app.path,
          '--dmg',
          dmg.path,
          '--notary-profile',
          'fixture-profile',
          '--result-json',
          result.path,
          '--log-directory',
          logs.path,
        ],
        environment: <String, String>{
          ...Platform.environment,
          'COMMAND_LOG': commandLog.path,
          'XCRUN_BIN': xcrun.path,
          'HDIUTIL_BIN': hdiutil.path,
          'DITTO_BIN': ditto.path,
          'SPCTL_BIN': spctl.path,
          'CODESIGN_BIN': codesign.path,
          'DMG_VERIFY_RETRY_DELAY_SECONDS': '0',
        },
      );

      expect(execution.exitCode, 0, reason: '${execution.stderr}');
      expect(dmg.existsSync(), isTrue);
      final decoded = jsonDecode(await result.readAsString());
      expect(decoded, <String, Object?>{
        'id': 'dmg-submission',
        'status': 'Accepted',
      });
      final commands = await commandLog.readAsLines();
      final appSubmit = commands.indexWhere(
        (line) => line.contains('notarytool submit') && line.contains('.zip'),
      );
      final appStaple = commands.indexWhere(
        (line) => line.contains('stapler staple') && line.contains('.app'),
      );
      final dmgCreate = commands.indexWhere(
        (line) => line.startsWith('hdiutil create '),
      );
      final dmgSubmit = commands.indexWhere(
        (line) => line.contains('notarytool submit') && line.contains('.dmg'),
      );
      final dmgSign = commands.indexWhere(
        (line) =>
            line.startsWith('codesign --force --sign ') &&
            line.contains('.dmg'),
      );
      final dmgStaple = commands.indexWhere(
        (line) => line.contains('stapler staple') && line.contains('.dmg'),
      );
      expect(appSubmit, greaterThanOrEqualTo(0));
      expect(appStaple, greaterThan(appSubmit));
      expect(dmgCreate, greaterThan(appStaple));
      expect(dmgSign, greaterThan(dmgCreate));
      expect(dmgSubmit, greaterThan(dmgSign));
      expect(dmgStaple, greaterThan(dmgSubmit));
    },
    skip: Platform.isWindows,
  );
}

Future<File> _fakeTool(
  Directory directory,
  String name,
  String behavior,
) async {
  final file = File('${directory.path}/$name');
  await file.writeAsString('''
#!/usr/bin/env bash
set -euo pipefail
printf '%s' '$name' >> "\$COMMAND_LOG"
printf ' %q' "\$@" >> "\$COMMAND_LOG"
printf '\\n' >> "\$COMMAND_LOG"
$behavior
''');
  final chmod = await Process.run('/bin/chmod', <String>['755', file.path]);
  expect(chmod.exitCode, 0, reason: '${chmod.stderr}');
  return file;
}
