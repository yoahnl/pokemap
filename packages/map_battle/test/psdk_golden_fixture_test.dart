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

    test('rejects fixtures with missing required fields', () {
      expect(
        () => PsdkGoldenFixture.fromJson(<String, Object?>{
          'scenarioId': 'missing_required_fields',
        }),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('sourcePsdkVersion'),
          ),
        ),
      );
    });
  });
}
