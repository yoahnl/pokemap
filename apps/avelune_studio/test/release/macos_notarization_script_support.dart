import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const notarizationStages = <(String, String)>[
  ('staple', 'app'),
  ('validate', 'app'),
  ('staple', 'dmg'),
  ('validate', 'dmg'),
];

List<String> recordedCalls(List<String> commands, (String, String) stage) =>
    commands
        .where(
          (line) =>
              line.startsWith('xcrun stapler ${stage.$1} ') &&
              line.endsWith('.${stage.$2}'),
        )
        .toList();

void expectNoLaterStages(NotarizationRun run, (String, String) stage) {
  expect(run.commands.last, recordedCalls(run.commands, stage).last);
  for (final later in notarizationStages.skip(
    notarizationStages.indexOf(stage) + 1,
  )) {
    expect(recordedCalls(run.commands, later), isEmpty);
  }
  if (stage.$2 == 'app') {
    expect(
      run.commands.where((line) => line.startsWith('hdiutil create ')),
      isEmpty,
    );
  }
  expect(run.execution.stdout, isNot(contains('notarization_verified=true')));
}

class NotarizationRun {
  const NotarizationRun(
    this.execution,
    this.commands,
    this.dmg,
    this.metadata,
    this.logs,
  );

  final ProcessResult execution;
  final List<String> commands;
  final File dmg;
  final File metadata;
  final Directory logs;
}

Future<NotarizationRun> runNotarization({
  (String, String)? failingStage,
  int failures = 0,
  int failureExit = 68,
  String failureMessage = 'Error Domain=NSURLErrorDomain Code=-1005 "The network connection was lost."',
  String notaryStatus = 'Accepted',
  String? dmgNotaryStatus,
  String? notaryKeychain,
}) async {
  final root = await Directory.systemTemp.createTemp(
    'pokemap-notarization-fixture-',
  );
  addTearDown(() => root.delete(recursive: true));
  final app = await Directory('${root.path}/Avelune Studio.app').create();
  final tools = await Directory('${root.path}/tools').create();
  final commandLog = File('${root.path}/commands.log');
  final xcrun = await _fakeTool(tools, 'xcrun', r'''
if [[ "$1 $2" == "notarytool submit" ]]; then
  case "$3" in
    *.zip) id="app-submission"; status="$NOTARY_STATUS" ;;
    *.dmg) id="dmg-submission"; status="$DMG_NOTARY_STATUS" ;;
    *) exit 65 ;;
  esac
  printf '{"id":"%s","status":"%s"}\n' "$id" "$status"
elif [[ "$1 $2" == "notarytool log" ]]; then
  output="${!#}"
  printf '{"issues":[]}\n' > "$output"
elif [[ "$1" == "stapler" ]]; then
  case "$3" in
    *.app) target="app" ;;
    *.dmg) target="dmg" ;;
    *) exit 65 ;;
  esac
  attempts="$COMMAND_LOG.$2-$target-attempts"
  count=0
  if [[ -f "$attempts" ]]; then
    count="$(cat "$attempts")"
  fi
  count="$((count + 1))"
  printf '%s' "$count" > "$attempts"
  if [[ "$2" == "$FAIL_OPERATION" && "$target" == "$FAIL_TARGET" && "$count" -le "$FAIL_COUNT" ]]; then
    printf '%s\n' "$FAIL_MESSAGE" >&2
    exit "$FAIL_EXIT"
  fi
fi
''');
  final hdiutil = await _fakeTool(tools, 'hdiutil', r'''
if [[ "$1" == "create" ]]; then
  output="${!#}"
  : > "$output"
elif [[ "$1" == "verify" ]]; then
  attempts="$COMMAND_LOG.hdiutil-verify-attempts"
  count=0
  if [[ -f "$attempts" ]]; then
    count="$(cat "$attempts")"
  fi
  count="$((count + 1))"
  printf '%s' "$count" > "$attempts"
  if [[ "$count" == "1" ]]; then
    exit 75
  fi
fi
''');
  final ditto = await _fakeTool(tools, 'ditto', r'''
output="${!#}"
: > "$output"
''');
  final spctl = await _fakeTool(tools, 'spctl', '');
  final codesign = await _fakeTool(tools, 'codesign', r'''
if [[ "$1" == "-d" ]]; then
  printf 'Authority=Developer ID Application: Fixture (FIXTURETEAM)\n' >&2
fi
''');
  final dmg = File('${root.path}/AveluneStudio.dmg');
  final result = File('${root.path}/notary-result.json');
  final logs = Directory('${root.path}/logs');
  final execution = await Process.run(
    '/bin/bash',
    <String>[
      '../../tools/release/notarize_macos_release.sh',
      '--app',
      app.path,
      '--dmg',
      dmg.path,
      '--notary-profile',
      'fixture-profile',
      if (notaryKeychain != null) ...['--notary-keychain', notaryKeychain],
      '--result-json',
      result.path,
      '--log-directory',
      logs.path,
      '--volume-name',
      'Fixture Volume',
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
      'STAPLER_RETRY_DELAY_SECONDS': '0',
      'FAIL_OPERATION': failingStage?.$1 ?? '',
      'FAIL_TARGET': failingStage?.$2 ?? '',
      'FAIL_COUNT': '$failures',
      'FAIL_EXIT': '$failureExit',
      'FAIL_MESSAGE': failureMessage,
      'NOTARY_STATUS': notaryStatus,
      'DMG_NOTARY_STATUS': dmgNotaryStatus ?? notaryStatus,
    },
  );
  return NotarizationRun(
    execution,
    await commandLog.readAsLines(),
    dmg,
    result,
    logs,
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
