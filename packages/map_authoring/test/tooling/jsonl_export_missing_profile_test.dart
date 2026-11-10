import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test(
    'game_export without a profile returns a safe failure and keeps the JSONL worker alive',
    () async {
      final environment = Platform.environment;
      final home = environment['HOME'] ?? environment['USERPROFILE'];
      final configuredRoot = environment['AVELUNE_QA_ROOT'];
      if (configuredRoot == null && home == null) {
        throw StateError('Set AVELUNE_QA_ROOT when the home is unavailable.');
      }
      final cache = Platform.isMacOS
          ? '$home/Library/Caches'
          : Platform.isWindows
              ? environment['LOCALAPPDATA'] ?? '$home/AppData/Local'
              : environment['XDG_CACHE_HOME'] ?? '$home/.cache';
      final qa = Directory(configuredRoot ?? '$cache/AveluneQA');
      await qa.create(recursive: true);
      final fixture = await qa.createTemp('jsonl-export-missing-profile-');
      addTearDown(() => fixture.delete(recursive: true));
      final project = await Directory('${fixture.path}/project').create();
      final exports = await Directory('${fixture.path}/exports').create();
      await File('${project.path}/project.json').writeAsString(
        jsonEncode(
          ProjectManifest(
            name: 'Missing export profile',
            maps: const [],
            tilesets: const [],
            pokemon: const ProjectPokemonConfig(
              enabled: false,
              ruleset: PokemonRulesetProfile.pokeMapBetaV1,
            ),
          ).toJson(),
        ),
      );
      final profile = File('${project.path}/.pokemap/export-profile-v1.json');
      expect(await profile.exists(), isFalse);
      final before = await _projectTree(project);
      final output = File('${exports.path}/missing-profile.avelunegame');
      expect(Platform.resolvedExecutable, isNot(contains('flutter_tester')));
      final process = await Process.start(
        Platform.environment['POKEMAP_TEST_DART'] ??
            Platform.resolvedExecutable,
        [
          '--packages=${Directory.current.path}/.dart_tool/package_config.json',
          'bin/pokemap_authoring.dart',
          '--root',
          project.path,
          '--export-root',
          exports.path,
        ],
        workingDirectory: Directory.current.path,
      );
      final responses = StreamIterator(
        process.stdout.transform(utf8.decoder).transform(const LineSplitter()),
      );
      final errors = process.stderr.transform(utf8.decoder).join();
      addTearDown(() async {
        try {
          await process.stdin.close();
        } on Object {
          process.kill();
        }
        try {
          await process.exitCode.timeout(const Duration(seconds: 5));
        } on TimeoutException {
          process.kill();
          await process.exitCode.timeout(const Duration(seconds: 5));
        } finally {
          await responses.cancel();
          await errors;
        }
      });

      Future<Map<String, dynamic>> request(
        String id,
        String command, [
        Map<String, Object?> args = const {},
      ]) async {
        process.stdin.writeln(jsonEncode({
          'id': id,
          'command': command,
          'args': args,
        }));
        await process.stdin.flush();
        if (!await responses.moveNext().timeout(const Duration(seconds: 30))) {
          final code = await process.exitCode;
          fail('JSONL worker exited before $id: code $code; ${await errors}');
        }
        final raw = responses.current;
        expect(raw, isNot(contains(fixture.path)));
        expect(raw, isNot(contains(project.path)));
        expect(raw, isNot(contains('/Users/')));
        expect(raw, isNot(contains('/private/')));
        expect(raw, isNot(contains('/tmp/')));
        final response = jsonDecode(raw) as Map<String, dynamic>;
        expect(response['requestId'], id);
        return response;
      }

      final described = await request('before-export', 'describe');
      expect(described['status'], 'success');
      try {
        final rejected = await request('missing-profile', 'game_export', {
          'projectRoot': project.path,
          'outputPath': output.path,
          'mode': 'localTest',
        });
        expect(rejected['status'], 'failure');
        final error = rejected['error'] as Map<String, dynamic>;
        expect(error['code'], 'validation_failed');
        expect(
          (error['details'] as Map<String, dynamic>)['domainCode'],
          'missingExportProfile',
        );
        expect(error['retryable'], isFalse);
        final continued = await request('after-export', 'describe');
        expect(continued['status'], 'success');
        await process.stdin.close();
        expect(
          await process.exitCode.timeout(const Duration(seconds: 5)),
          AuthoringCliExitCodes.success,
        );
        expect(await errors, isEmpty);
      } finally {
        expect(await _projectTree(project), before);
        expect(await profile.exists(), isFalse);
        expect(await output.exists(), isFalse);
        expect(await exports.list().toList(), isEmpty);
      }
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}

Future<Map<String, Object?>> _projectTree(Directory root) async {
  final entries = <String, Object?>{};
  await for (final entry in root.list(recursive: true, followLinks: false)) {
    final relative = entry.path.substring(root.path.length + 1);
    entries[relative] = switch (entry) {
      File() => await entry.readAsBytes(),
      Directory() => null,
      _ => throw StateError('Unexpected fixture entry: $relative'),
    };
  }
  return entries;
}
