import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

PokemonMove _roundTrip(PokemonMove move) {
  final encoded = jsonEncode(move.toJson());
  final decoded = jsonDecode(encoded) as Map<String, dynamic>;
  return PokemonMove.fromJson(decoded);
}

void main() {
  group('PokemonMove', () {
    test('round-trip JSON for a simple damage move', () {
      const move = PokemonMove(
        id: 'thunderbolt',
        name: 'Thunderbolt',
        names: {'en': 'Thunderbolt', 'fr': 'Tonnerre'},
        generation: 1,
        source: 'showdown',
        type: 'electric',
        category: PokemonMoveCategory.special,
        target: PokemonMoveTarget.normal,
        basePower: 90,
        accuracy: PokemonMoveAccuracy.percent(value: 100),
        pp: 15,
        priority: 0,
        flags: [
          PokemonMoveFlag.protect,
          PokemonMoveFlag.mirror,
        ],
        shortDescription: '10% chance to paralyze the target.',
        description: 'A strong electric blast crashes down on the target.',
      );

      expect(_roundTrip(move), move);
      expect(move.usesStandardDamageFlow, isTrue);
    });

    test('round-trip JSON for a move with a secondary status effect', () {
      const move = PokemonMove(
        id: 'thunderbolt',
        name: 'Thunderbolt',
        source: 'showdown',
        type: 'electric',
        category: PokemonMoveCategory.special,
        basePower: 90,
        accuracy: PokemonMoveAccuracy.percent(value: 100),
        pp: 15,
        effects: [
          PokemonMoveEffect.applyStatus(
            chance: 10,
            statusId: 'par',
          ),
        ],
      );

      expect(_roundTrip(move), move);
    });

    test('round-trip JSON for a move with drain', () {
      const move = PokemonMove(
        id: 'absorb',
        name: 'Absorb',
        source: 'showdown',
        type: 'grass',
        category: PokemonMoveCategory.special,
        basePower: 20,
        accuracy: PokemonMoveAccuracy.percent(value: 100),
        pp: 25,
        effects: [
          PokemonMoveEffect.drain(
            numerator: 1,
            denominator: 2,
          ),
        ],
      );

      expect(_roundTrip(move), move);
    });

    test('round-trip JSON for a multi-hit move', () {
      const move = PokemonMove(
        id: 'double-slap',
        name: 'Double Slap',
        source: 'showdown',
        type: 'normal',
        category: PokemonMoveCategory.physical,
        basePower: 15,
        accuracy: PokemonMoveAccuracy.percent(value: 85),
        pp: 10,
        effects: [
          PokemonMoveEffect.multiHit(
            minHits: 2,
            maxHits: 5,
          ),
        ],
      );

      expect(_roundTrip(move), move);
    });

    test('round-trip JSON keeps engine support metadata', () {
      const move = PokemonMove(
        id: 'acrobatics',
        name: 'Acrobatics',
        source: 'showdown',
        type: 'flying',
        category: PokemonMoveCategory.physical,
        basePower: 55,
        accuracy: PokemonMoveAccuracy.percent(value: 100),
        pp: 15,
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredPartial,
        unsupportedReasons: ['showdown_callback:basePowerCallback'],
        sourceRefs: PokemonMoveSourceRefs(
          showdownMoveId: 'acrobatics',
          showdownHooksPresent: ['basePowerCallback'],
        ),
      );

      expect(_roundTrip(move), move);
    });

    test('deserialization works when optional fields are absent', () {
      final restored = PokemonMove.fromJson({
        'id': 'swift',
        'name': 'Swift',
        'type': 'normal',
        'category': 'special',
        'accuracy': {
          'kind': 'always_hits',
        },
        'pp': 20,
      });

      expect(restored.id, 'swift');
      expect(restored.names, isEmpty);
      expect(restored.target, PokemonMoveTarget.normal);
      expect(restored.basePower, 0);
      expect(restored.flags, isEmpty);
      expect(restored.effects, isEmpty);
      expect(
        restored.engineSupportLevel,
        PokemonMoveEngineSupportLevel.catalogOnly,
      );
      expect(restored.sourceRefs.showdownMoveId, isNull);
    });

    test('fromJson enforces normalization for blank ids', () {
      expect(
        () => PokemonMove.fromJson({
          'id': '   ',
          'name': 'Swift',
          'type': 'normal',
          'category': 'special',
          'accuracy': {
            'kind': 'always_hits',
          },
        }),
        throwsStateError,
      );
    });

    test('can represent a move with stat changes and recoil', () {
      const move = PokemonMove(
        id: 'close-combat-plus',
        name: 'Close Combat Plus',
        source: 'test',
        type: 'fighting',
        category: PokemonMoveCategory.physical,
        basePower: 120,
        accuracy: PokemonMoveAccuracy.percent(value: 100),
        pp: 5,
        effects: [
          PokemonMoveEffect.modifyStats(
            targetScope: PokemonMoveEffectTargetScope.self,
            stageChanges: [
              PokemonMoveStatStageChange(
                stat: PokemonMoveStatId.defense,
                stages: -1,
              ),
              PokemonMoveStatStageChange(
                stat: PokemonMoveStatId.specialDefense,
                stages: -1,
              ),
            ],
          ),
          PokemonMoveEffect.recoil(
            numerator: 1,
            denominator: 3,
          ),
        ],
      );

      expect(_roundTrip(move), move);
    });

    test('normalized trims ids and dedupes flags and unsupported reasons', () {
      const move = PokemonMove(
        id: '  thunderbolt  ',
        name: '  Thunderbolt  ',
        names: {
          ' fr ': ' Tonnerre ',
          'en': ' Thunderbolt ',
          '': 'ignored',
        },
        source: ' showdown ',
        type: ' electric ',
        category: PokemonMoveCategory.special,
        basePower: 90,
        accuracy: PokemonMoveAccuracy.percent(value: 100),
        flags: [
          PokemonMoveFlag.protect,
          PokemonMoveFlag.protect,
          PokemonMoveFlag.mirror,
        ],
        unsupportedReasons: [
          ' showdown_callback:onHit ',
          'showdown_callback:onHit',
          '   ',
        ],
        sourceRefs: PokemonMoveSourceRefs(
          showdownMoveId: ' thunderbolt ',
          showdownHooksPresent: [
            ' onHit ',
            'onHit',
            '  ',
          ],
        ),
      );

      final normalized = move.normalized();

      expect(normalized.id, 'thunderbolt');
      expect(normalized.name, 'Thunderbolt');
      expect(normalized.names, {
        'en': 'Thunderbolt',
        'fr': 'Tonnerre',
      });
      expect(normalized.source, 'showdown');
      expect(normalized.type, 'electric');
      expect(normalized.flags, [
        PokemonMoveFlag.protect,
        PokemonMoveFlag.mirror,
      ]);
      expect(normalized.unsupportedReasons, ['showdown_callback:onHit']);
      expect(normalized.sourceRefs.showdownMoveId, 'thunderbolt');
      expect(normalized.sourceRefs.showdownHooksPresent, ['onHit']);
    });

    test('normalized rejects blank id', () {
      const move = PokemonMove(
        id: '   ',
        name: 'Move',
        type: 'normal',
        category: PokemonMoveCategory.status,
        accuracy: PokemonMoveAccuracy.alwaysHits(),
      );

      expect(() => move.normalized(), throwsStateError);
    });

    test('normalized rejects blank name', () {
      const move = PokemonMove(
        id: 'move',
        name: '   ',
        type: 'normal',
        category: PokemonMoveCategory.status,
        accuracy: PokemonMoveAccuracy.alwaysHits(),
      );

      expect(() => move.normalized(), throwsStateError);
    });
  });

  group('PokemonMoveAccuracy', () {
    test('serializes percent accuracy', () {
      const accuracy = PokemonMoveAccuracy.percent(value: 85);

      expect(
        PokemonMoveAccuracy.fromJson(accuracy.toJson()),
        accuracy,
      );
    });

    test('serializes always hits accuracy', () {
      const accuracy = PokemonMoveAccuracy.alwaysHits();

      expect(
        PokemonMoveAccuracy.fromJson(accuracy.toJson()),
        accuracy,
      );
    });

    test('normalized rejects out-of-range percent accuracy', () {
      const accuracy = PokemonMoveAccuracy.percent(value: 101);

      expect(() => accuracy.normalized(), throwsStateError);
    });

    test('fromJson rejects out-of-range percent accuracy', () {
      expect(
        () => PokemonMoveAccuracy.fromJson({
          'kind': 'percent',
          'value': 101,
        }),
        throwsStateError,
      );
    });
  });

  group('PokemonMoveEffect', () {
    PokemonMoveEffect roundTripEffect(PokemonMoveEffect effect) {
      final encoded = jsonEncode(effect.toJson());
      final decoded = jsonDecode(encoded) as Map<String, dynamic>;
      return PokemonMoveEffect.fromJson(decoded);
    }

    test('round-trip JSON for fixed damage', () {
      const effect = PokemonMoveEffect.fixedDamage(value: 40);
      expect(roundTripEffect(effect), effect);
    });

    test('round-trip JSON for setWeather', () {
      const effect = PokemonMoveEffect.setWeather(weatherId: 'rain-dance');
      expect(roundTripEffect(effect), effect);
    });

    test('round-trip JSON for setTerrain', () {
      const effect =
          PokemonMoveEffect.setTerrain(terrainId: 'electric-terrain');
      expect(roundTripEffect(effect), effect);
    });

    test('round-trip JSON for setPseudoWeather', () {
      const effect =
          PokemonMoveEffect.setPseudoWeather(pseudoWeatherId: 'trick-room');
      expect(roundTripEffect(effect), effect);
    });

    test('round-trip JSON for setSideCondition', () {
      const effect = PokemonMoveEffect.setSideCondition(conditionId: 'spikes');
      expect(roundTripEffect(effect), effect);
    });

    test('round-trip JSON for setSlotCondition', () {
      const effect =
          PokemonMoveEffect.setSlotCondition(conditionId: 'futuremove');
      expect(roundTripEffect(effect), effect);
    });

    test('round-trip JSON for forceSwitch', () {
      const effect = PokemonMoveEffect.forceSwitch();
      expect(roundTripEffect(effect), effect);
    });

    test('round-trip JSON for requireRecharge', () {
      const effect = PokemonMoveEffect.requireRecharge();
      expect(roundTripEffect(effect), effect);
    });

    test('round-trip JSON for chargeThenStrike', () {
      const effect = PokemonMoveEffect.chargeThenStrike(
        chargeStateId: 'solar-beam-charge',
      );
      expect(roundTripEffect(effect), effect);
    });

    test('normalized rejects invalid multiHit range', () {
      const effect = PokemonMoveEffect.multiHit(
        minHits: 5,
        maxHits: 2,
      );

      expect(() => effect.normalized(), throwsStateError);
    });

    test('fromJson rejects invalid multiHit range', () {
      expect(
        () => PokemonMoveEffect.fromJson({
          'kind': 'multi_hit',
          'targetScope': 'target',
          'minHits': 5,
          'maxHits': 2,
        }),
        throwsStateError,
      );
    });
  });
}
