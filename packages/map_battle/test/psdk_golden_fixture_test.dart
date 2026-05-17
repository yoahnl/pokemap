import 'dart:convert';
import 'dart:io';

import 'package:map_battle/map_battle.dart';
import 'package:map_battle/src/data/psdk_golden_fixture.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK golden fixtures', () {
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
