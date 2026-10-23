import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _stages = <(String, String)>[
  ('staple', 'app'),
  ('validate', 'app'),
  ('staple', 'dmg'),
  ('validate', 'dmg'),
];

void main() {
  group('notarization script', () {
    test('staples the app before creating the final DMG', () async {
      final run = await _runNotarization();
      expect(run.execution.exitCode, 0, reason: '${run.execution.stderr}');
      expect(run.dmg.existsSync(), isTrue);
      final decoded = jsonDecode(await run.metadata.readAsString());
      expect(decoded, <String, Object?>{
        'id': 'dmg-submission',
        'status': 'Accepted',
      });
      final commands = run.commands;
      final appSubmit = commands.indexWhere(
        (line) => line.contains('notarytool submit') && line.contains('.zip'),
      );
      final appStaple = commands.indexWhere(
        (line) => line.contains('stapler staple') && line.contains('.app'),
      );
      final appValidate = commands.indexWhere(
        (line) => line.contains('stapler validate') && line.contains('.app'),
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
      final dmgValidate = commands.indexWhere(
        (line) => line.contains('stapler validate') && line.contains('.dmg'),
      );
      expect(appSubmit, greaterThanOrEqualTo(0));
      expect(appStaple, greaterThan(appSubmit));
      expect(appValidate, greaterThan(appStaple));
      expect(dmgCreate, greaterThan(appValidate));
      expect(commands[dmgCreate], contains('-volname Fixture\\ Volume'));
      expect(dmgSign, greaterThan(dmgCreate));
      expect(dmgSubmit, greaterThan(dmgSign));
      expect(dmgStaple, greaterThan(dmgSubmit));
      expect(dmgValidate, greaterThan(dmgStaple));
    });

    for (final stage in _stages) {
      test(
        'retries a lost connection during ${stage.$1} ${stage.$2}',
        () async {
          final run = await _runNotarization(failingStage: stage, failures: 1);
          expect(run.execution.exitCode, 0, reason: '${run.execution.stderr}');
          expect(run.execution.stderr, contains('NSURLErrorDomain Code=-1005'));
          expect(_calls(run.commands, stage), hasLength(2));
          for (final other in _stages.where((item) => item != stage)) {
            expect(_calls(run.commands, other), hasLength(1));
          }
          expect(run.execution.stdout, contains('notarization_verified=true'));
        },
      );

      test(
        'stops after three lost connections during ${stage.$1} ${stage.$2}',
        () async {
          final run = await _runNotarization(failingStage: stage, failures: 99);
          expect(run.execution.exitCode, 68, reason: '${run.execution.stderr}');
          expect(run.execution.stderr, contains('NSURLErrorDomain Code=-1005'));
          expect(_calls(run.commands, stage), hasLength(3));
          _expectNoLaterStages(run, stage);
        },
      );
    }

    test('accepts recovery on the third DMG validation attempt', () async {
      const stage = ('validate', 'dmg');
      final run = await _runNotarization(failingStage: stage, failures: 2);
      expect(run.execution.exitCode, 0, reason: '${run.execution.stderr}');
      expect(_calls(run.commands, stage), hasLength(3));
      expect(run.execution.stdout, contains('notarization_verified=true'));
    });

    test('does not retry another network error 68', () async {
      const stage = ('validate', 'app');
      final run = await _runNotarization(
        failingStage: stage,
        failures: 99,
        failureMessage: 'Error Domain=NSURLErrorDomain Code=-1009',
      );
      expect(run.execution.exitCode, 68);
      expect(_calls(run.commands, stage), hasLength(1));
      _expectNoLaterStages(run, stage);
    });

    test('does not retry a non-network stapler error 68', () async {
      const stage = ('validate', 'app');
      final run = await _runNotarization(
        failingStage: stage,
        failures: 99,
        failureMessage: 'The staple and validate action failed! Error 68.',
      );
      expect(run.execution.exitCode, 68);
      expect(_calls(run.commands, stage), hasLength(1));
      _expectNoLaterStages(run, stage);
    });

    test(
      'does not retry another exit code with a lost-connection message',
      () async {
        const stage = ('validate', 'app');
        final run = await _runNotarization(
          failingStage: stage,
          failures: 99,
          failureExit: 42,
        );
        expect(run.execution.exitCode, 42);
        expect(_calls(run.commands, stage), hasLength(1));
        _expectNoLaterStages(run, stage);
      },
    );

    test('rejects Invalid notarization without stapling', () async {
      final run = await _runNotarization(notaryStatus: 'Invalid');
      expect(run.execution.exitCode, 65);
      expect(run.commands.where((line) => line.contains('stapler ')), isEmpty);
      expect(
        run.commands.where((line) => line.startsWith('hdiutil create ')),
        isEmpty,
      );
      expect(
        run.execution.stdout,
        isNot(contains('notarization_verified=true')),
      );
    });
  }, skip: Platform.isWindows);
}

List<String> _calls(List<String> commands, (String, String) stage) => commands
    .where(
      (line) =>
          line.startsWith('xcrun stapler ${stage.$1} ') &&
          line.endsWith('.${stage.$2}'),
    )
    .toList();

void _expectNoLaterStages(_NotarizationRun run, (String, String) stage) {
  expect(run.commands.last, _calls(run.commands, stage).last);
  for (final later in _stages.skip(_stages.indexOf(stage) + 1)) {
    expect(_calls(run.commands, later), isEmpty);
  }
  if (stage.$2 == 'app') {
    expect(
      run.commands.where((line) => line.startsWith('hdiutil create ')),
      isEmpty,
    );
  }
  expect(run.execution.stdout, isNot(contains('notarization_verified=true')));
}

class _NotarizationRun {
  const _NotarizationRun(
    this.execution,
    this.commands,
    this.dmg,
    this.metadata,
  );

  final ProcessResult execution;
  final List<String> commands;
  final File dmg;
  final File metadata;
}

Future<_NotarizationRun> _runNotarization({
  (String, String)? failingStage,
  int failures = 0,
  int failureExit = 68,
  String failureMessage = 'Error Domain=NSURLErrorDomain Code=-1005 "The network connection was lost."',
  String notaryStatus = 'Accepted',
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
    *.zip) id="app-submission" ;;
    *.dmg) id="dmg-submission" ;;
    *) exit 65 ;;
  esac
  printf '{"id":"%s","status":"%s"}\n' "$id" "$NOTARY_STATUS"
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
    },
  );
  return _NotarizationRun(
    execution,
    await commandLog.readAsLines(),
    dmg,
    result,
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
