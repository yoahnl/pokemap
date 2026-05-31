import 'dart:convert';
import 'dart:io';

import 'package:map_battle/map_battle.dart';
import 'package:map_battle/src/data/psdk_golden_fixture.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK golden fixtures', () {
    test('loads a corpus summary with stable ids and parity evidence tags',
        () async {
      final corpus = await PsdkGoldenFixtureCorpus.load(
        Directory('test/fixtures/psdk_golden'),
      );

      expect(corpus.fixtures.map((fixture) => fixture.scenarioId), <String>[
        'basic_damage_neutral',
        'status_stat_non_damage',
        'weather_rain_mod1_damage',
      ]);
      expect(corpus.summary.count, 3);
      expect(
        corpus.summary.tags,
        containsAll(<String>['move_method', 'damage', 'status', 'field']),
      );
      expect(corpus.summary.auditDeltas.strictAttacks, 2);
      expect(corpus.summary.auditDeltas.portedMethods, 2);
      expect(corpus.summary.auditDeltas.portedEffects, 1);
    });

    test('keeps the corpus index-backed with real PSDK source paths', () async {
      final corpus = await PsdkGoldenFixtureCorpus.load(
        Directory('test/fixtures/psdk_golden'),
      );
      final index =
          File('test/fixtures/psdk_golden/_index.md').readAsStringSync();
      final psdkBattleRoot = _psdkBattleRoot();

      for (final fixture in corpus.fixtures) {
        final filename = '${fixture.scenarioId}.json';
        expect(index, contains('`$filename`'), reason: filename);
        for (final sourcePath in fixture.psdkSourcePaths) {
          expect(
            File.fromUri(psdkBattleRoot.uri.resolve(sourcePath)).existsSync(),
            isTrue,
            reason: '${fixture.scenarioId} -> $sourcePath',
          );
        }
      }
    });

    test('rejects a corpus fixture whose id does not match its filename',
        () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'psdk_golden_bad_id_',
      );
      addTearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });
      final json = _fixtureJson()..['scenarioId'] = 'different_fixture_id';
      await File('${tempDir.path}/filename_id.json').writeAsString(
        const JsonEncoder.withIndent('  ').convert(json),
      );

      expect(
        () => PsdkGoldenFixtureCorpus.load(tempDir),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('scenarioId "different_fixture_id" must match filename'),
          ),
        ),
      );
    });

    test('loads and replays the basic neutral damage fixture', () async {
      final fixture = await PsdkGoldenFixture.load(
        File('test/fixtures/psdk_golden/basic_damage_neutral.json'),
      );

      expect(fixture.scenarioId, 'basic_damage_neutral');
      expect(fixture.tags, containsAll(<String>['move_method', 'damage']));
      expect(
        fixture.psdkSourcePaths,
        contains('10 Move/1 Mechanics/100 Basic.rb'),
      );
      expect(fixture.expectedAuditDeltas.strictAttacks, 1);

      final engine = PsdkBattleEngine(setup: fixture.toPsdkSetup());
      PsdkBattleTurnResult? result;
      for (final action in fixture.actions) {
        expect(action.actor, PsdkGoldenActor.player);
        result = engine.submit(PsdkBattleDecision.fight(
          moveSlot: action.moveSlot,
        ));
      }

      expect(result, isNotNull);
      expect(fixture.compare(result!), isEmpty);
      expect(
        result.timeline.events.whereType<PsdkBattleDamageEvent>().single.damage,
        7,
      );
    });

    test('loads and replays a non-damage status/stat fixture', () async {
      final fixture = await PsdkGoldenFixture.load(
        File('test/fixtures/psdk_golden/status_stat_non_damage.json'),
      );

      expect(fixture.scenarioId, 'status_stat_non_damage');
      expect(fixture.tags, containsAll(<String>['move_method', 'status']));
      expect(fixture.expectedTimeline.statusEvents.single.status,
          PsdkBattleMajorStatus.paralysis);
      expect(fixture.expectedTimeline.statStageEvents.single.stat, 'attack');

      final engine = PsdkBattleEngine(setup: fixture.toPsdkSetup());
      final result = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));

      expect(fixture.compare(result), isEmpty);
      expect(
        result.state.battlerAt(psdkOpponentSlot).majorStatus,
        PsdkBattleMajorStatus.paralysis,
      );
      expect(
        result.state.battlerAt(psdkOpponentSlot).statStages.valueOf('attack'),
        -1,
      );
      expect(
          result.timeline.events.whereType<PsdkBattleDamageEvent>(), isEmpty);
    });

    test('loads and replays every tracked golden fixture', () async {
      final files = Directory('test/fixtures/psdk_golden')
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.json'))
          .toList()
        ..sort((left, right) => left.path.compareTo(right.path));

      expect(files, hasLength(greaterThanOrEqualTo(2)));

      for (final file in files) {
        final fixture = await PsdkGoldenFixture.load(file);
        final engine = PsdkBattleEngine(setup: fixture.toPsdkSetup());
        PsdkBattleTurnResult? result;
        for (final action in fixture.actions) {
          expect(action.actor, PsdkGoldenActor.player, reason: file.path);
          result = engine.submit(PsdkBattleDecision.fight(
            moveSlot: action.moveSlot,
          ));
        }

        expect(result, isNotNull, reason: file.path);
        expect(fixture.compare(result!), isEmpty, reason: file.path);
      }
    });

    test('rejects fixtures with missing required fields', () {
      expect(
        () => PsdkGoldenFixture.fromJson(<String, Object?>{
          'scenarioId': 'missing_required_fields',
        }),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('tags'),
          ),
        ),
      );
    });

    test('rejects empty gate evidence lists', () {
      for (final entry in <String, Map<String, Object?>>{
        'tags': <String, Object?>{
          'tags': <Object?>[],
        },
        'psdkSourcePaths': <String, Object?>{
          'psdkSourcePaths': <Object?>[],
        },
        'actions': <String, Object?>{
          'actions': <Object?>[],
        },
        'eventKinds': <String, Object?>{
          'expectedTimeline': <String, Object?>{
            'eventKinds': <Object?>[],
          },
        },
      }.entries) {
        expect(
          () => PsdkGoldenFixture.fromJson(
            _fixtureJson(overrides: entry.value),
          ),
          throwsA(
            isA<FormatException>().having(
              (error) => error.message,
              'message',
              contains(entry.key),
            ),
          ),
          reason: entry.key,
        );
      }
    });

    test('defaults omitted audit deltas to zero', () {
      final json = _fixtureJson()..remove('expectedAuditDeltas');

      final fixture = PsdkGoldenFixture.fromJson(json);

      expect(fixture.expectedAuditDeltas.strictAttacks, 0);
      expect(fixture.expectedAuditDeltas.portedMethods, 0);
      expect(fixture.expectedAuditDeltas.portedEffects, 0);
    });
  });
}

Map<String, Object?> _fixtureJson({
  Map<String, Object?> overrides = const <String, Object?>{},
}) {
  final json = jsonDecode(
    File('test/fixtures/psdk_golden/basic_damage_neutral.json')
        .readAsStringSync(),
  ) as Map<String, Object?>;
  _deepMerge(json, overrides);
  return json;
}

void _deepMerge(Map<String, Object?> target, Map<String, Object?> source) {
  for (final entry in source.entries) {
    final targetValue = target[entry.key];
    final sourceValue = entry.value;
    if (targetValue is Map<String, Object?> &&
        sourceValue is Map<String, Object?>) {
      _deepMerge(targetValue, sourceValue);
    } else {
      target[entry.key] = sourceValue;
    }
  }
}

Directory _psdkBattleRoot() {
  final direct = Directory('../../pokemonsdk-development/scripts/5 Battle');
  if (direct.existsSync()) {
    return direct;
  }
  final gitRoot = _gitCommonRoot();
  if (gitRoot == null) {
    return direct;
  }
  final fallback = Directory.fromUri(
    gitRoot.uri.resolve('pokemonsdk-development/scripts/5 Battle'),
  );
  if (fallback.existsSync()) {
    return fallback;
  }
  return direct;
}

Directory? _gitCommonRoot() {
  final result = Process.runSync(
    'git',
    <String>['rev-parse', '--git-common-dir'],
  );
  if (result.exitCode != 0) {
    return null;
  }
  final commonPath = '${result.stdout}'.trim();
  if (commonPath.isEmpty) {
    return null;
  }
  final commonDirectory = Directory(commonPath);
  if (commonDirectory.absolute.path.endsWith('${Platform.pathSeparator}.git')) {
    return commonDirectory.parent;
  }
  return null;
}
