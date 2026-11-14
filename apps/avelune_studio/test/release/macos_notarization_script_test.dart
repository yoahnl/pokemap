import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'macos_notarization_script_support.dart';

void main() {
  group('notarization script', () {
    test(
      'passes an explicit keychain to every notary credential lookup',
      () async {
        final run = await runNotarization(
          notaryKeychain: '/tmp/Fixture Keychain',
        );
        expect(run.execution.exitCode, 0, reason: '${run.execution.stderr}');
        final lookups = run.commands.where(
          (line) => line.contains('notarytool '),
        );
        expect(lookups, hasLength(4));
        for (final lookup in lookups) {
          expect(lookup, contains('--keychain /tmp/Fixture\\ Keychain'));
        }
      },
    );

    test('staples the app before creating the final DMG', () async {
      final run = await runNotarization();
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

    for (final stage in notarizationStages) {
      test(
        'retries a lost connection during ${stage.$1} ${stage.$2}',
        () async {
          final run = await runNotarization(failingStage: stage, failures: 1);
          expect(run.execution.exitCode, 0, reason: '${run.execution.stderr}');
          expect(run.execution.stderr, contains('NSURLErrorDomain Code=-1005'));
          expect(recordedCalls(run.commands, stage), hasLength(2));
          for (final other in notarizationStages.where(
            (item) => item != stage,
          )) {
            expect(recordedCalls(run.commands, other), hasLength(1));
          }
          expect(run.execution.stdout, contains('notarization_verified=true'));
        },
      );

      test(
        'stops after three lost connections during ${stage.$1} ${stage.$2}',
        () async {
          final run = await runNotarization(failingStage: stage, failures: 99);
          expect(run.execution.exitCode, 68, reason: '${run.execution.stderr}');
          expect(run.execution.stderr, contains('NSURLErrorDomain Code=-1005'));
          expect(recordedCalls(run.commands, stage), hasLength(3));
          expectNoLaterStages(run, stage);
        },
      );
    }

    test('accepts recovery on the third DMG validation attempt', () async {
      const stage = ('validate', 'dmg');
      final run = await runNotarization(failingStage: stage, failures: 2);
      expect(run.execution.exitCode, 0, reason: '${run.execution.stderr}');
      expect(recordedCalls(run.commands, stage), hasLength(3));
      expect(run.execution.stdout, contains('notarization_verified=true'));
    });

    test('does not retry another network error 68', () async {
      const stage = ('validate', 'app');
      final run = await runNotarization(
        failingStage: stage,
        failures: 99,
        failureMessage: 'Error Domain=NSURLErrorDomain Code=-1009',
      );
      expect(run.execution.exitCode, 68);
      expect(recordedCalls(run.commands, stage), hasLength(1));
      expectNoLaterStages(run, stage);
    });

    test('does not retry a non-network stapler error 68', () async {
      const stage = ('validate', 'app');
      final run = await runNotarization(
        failingStage: stage,
        failures: 99,
        failureMessage: 'The staple and validate action failed! Error 68.',
      );
      expect(run.execution.exitCode, 68);
      expect(recordedCalls(run.commands, stage), hasLength(1));
      expectNoLaterStages(run, stage);
    });

    test(
      'does not retry another exit code with a lost-connection message',
      () async {
        const stage = ('validate', 'app');
        final run = await runNotarization(
          failingStage: stage,
          failures: 99,
          failureExit: 42,
        );
        expect(run.execution.exitCode, 42);
        expect(recordedCalls(run.commands, stage), hasLength(1));
        expectNoLaterStages(run, stage);
      },
    );

    test('rejects Invalid notarization without stapling', () async {
      final run = await runNotarization(notaryStatus: 'Invalid');
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

    for (final target in ['app', 'dmg']) {
      test(
        'retains $target rejection result and Apple log before stopping',
        () async {
          final run = await runNotarization(
            notaryStatus: target == 'app' ? 'Rejected' : 'Accepted',
            dmgNotaryStatus: 'Rejected',
          );
          expect(run.execution.exitCode, 65, reason: '${run.execution.stderr}');
          final result = target == 'app'
              ? File('${run.logs.path}/app-notary-result.json')
              : run.metadata;
          expect(jsonDecode(await result.readAsString()), <String, Object?>{
            'id': '$target-submission',
            'status': 'Rejected',
          });
          final log = File('${run.logs.path}/$target-notary-log.json');
          expect(jsonDecode(await log.readAsString()), <String, Object?>{
            'issues': <Object?>[],
          });
          expect(
            run.commands.last,
            contains('notarytool log $target-submission'),
          );
          expect(recordedCalls(run.commands, ('staple', target)), isEmpty);
          expect(recordedCalls(run.commands, ('validate', target)), isEmpty);
          expect(
            run.commands.where((line) => line.startsWith('spctl ')),
            hasLength(target == 'app' ? 0 : 1),
          );
          expect(
            run.execution.stdout,
            isNot(contains('notarization_verified=true')),
          );
        },
      );
    }
  }, skip: Platform.isWindows);
}
