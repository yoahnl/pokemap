import 'dart:convert';
import 'dart:io';

import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

const _expected = <String,
    ({
  PsdkBattleMajorStatus? major,
  PsdkBattleVolatileStatus? volatile,
  int chance
})>{
  'poison_powder': (
    major: PsdkBattleMajorStatus.poison,
    volatile: null,
    chance: 100
  ),
  'stun_spore': (
    major: PsdkBattleMajorStatus.paralysis,
    volatile: null,
    chance: 100
  ),
  'sleep_powder': (
    major: PsdkBattleMajorStatus.sleep,
    volatile: null,
    chance: 100
  ),
  'confuse_ray': (
    major: null,
    volatile: PsdkBattleVolatileStatus.confusion,
    chance: 100
  ),
  'smog': (major: PsdkBattleMajorStatus.poison, volatile: null, chance: 40),
  'sludge': (major: PsdkBattleMajorStatus.poison, volatile: null, chance: 30),
  'bite': (major: null, volatile: PsdkBattleVolatileStatus.flinch, chance: 30),
  'hyper_fang': (
    major: null,
    volatile: PsdkBattleVolatileStatus.flinch,
    chance: 10
  ),
};

void main() {
  final catalogPath = Platform.environment['JOHTO_MOVE_CATALOG_PATH'] ??
      'test/fixtures/johto_moves_status_catalog.json';
  final catalog =
      jsonDecode(File(catalogPath).readAsStringSync()) as Map<String, dynamic>;
  final entries = <String, Map<String, dynamic>>{
    for (final entry
        in (catalog['entries'] as List).cast<Map<String, dynamic>>())
      entry['id'] as String: entry,
  };
  const projector = CanonicalPsdkMoveProjector();

  group('Johto move status projection', () {
    for (final entry in _expected.entries) {
      test(entry.key, () {
        final source = PokemonMove.fromJson(entries[entry.key]!).normalized();
        final projected = projector.project(move: source);
        expect(projected.statuses, hasLength(1));
        final status = projected.statuses.single;
        expect(status.majorStatus, entry.value.major);
        expect(status.volatileStatus, entry.value.volatile);
        expect(status.chance, entry.value.chance);
        expect(projected.category.name, source.category.name);
        expect(projected.power, source.basePower);
        expect(projected.accuracy,
            (entries[entry.key]!['accuracy'] as Map<String, dynamic>)['value']);
        expect(projected.pp, source.pp);
      });
    }
  });

  group('Johto move status battle execution', () {
    for (final entry in _expected.entries) {
      test('${entry.key} applies its imported effect', () {
        final move = projector.project(
          move: PokemonMove.fromJson(entries[entry.key]!).normalized(),
        );
        final result = _runMove(move);
        final target = result.state.battlerAt(psdkOpponentSlot);
        expect(result.state.battlerAt(psdkPlayerSlot).moves.single.currentPp,
            move.pp - 1);
        if (entry.value.major != null) {
          final applied = result.timeline.psdkTimeline.events
              .whereType<PsdkBattleStatusEvent>()
              .where((event) => event.moveId == entry.key);
          expect(applied, hasLength(1));
          expect(applied.single.target, psdkOpponentSlot);
          expect(applied.single.status, entry.value.major);
          expect(target.majorStatus, entry.value.major);
        } else {
          final applied = result.timeline.psdkTimeline.events
              .whereType<PsdkBattleEffectEvent>()
              .where((event) =>
                  event.action == 'added' &&
                  event.effectId == entry.value.volatile!.name);
          expect(applied, hasLength(1));
          expect(applied.single.target, psdkOpponentSlot);
          if (entry.value.volatile == PsdkBattleVolatileStatus.flinch) {
            expect(target.moves.single.currentPp, _idleMove.pp);
            expect(
              result.timeline.psdkTimeline.events
                  .whereType<PsdkBattleMoveFailedEvent>()
                  .where((event) => event.moveId == _idleMove.id),
              hasLength(1),
            );
          } else {
            expect(target.effects.contains('confusion'), isTrue);
          }
        }
        if (move.power > 0) {
          expect(_moveDamage(result, move.id), isNotEmpty);
        }
      });

      if (entry.value.chance < 100) {
        test('${entry.key} can hit without applying its secondary effect', () {
          final move = projector.project(
            move: PokemonMove.fromJson(entries[entry.key]!).normalized(),
          );
          final result = _runMove(move, genericSeed: 99);
          expect(_moveDamage(result, move.id), isNotEmpty);
          expect(result.state.battlerAt(psdkOpponentSlot).majorStatus, isNull);
          expect(
              result.timeline.psdkTimeline.events
                  .whereType<PsdkBattleStatusEvent>(),
              isEmpty);
          expect(
            result.timeline.psdkTimeline.events
                .whereType<PsdkBattleEffectEvent>()
                .where((event) =>
                    event.action == 'added' && event.effectId == 'flinch'),
            isEmpty,
          );
          expect(
              result.state.battlerAt(psdkOpponentSlot).moves.single.currentPp,
              _idleMove.pp - 1);
        });
      }

      final accuracy = (entries[entry.key]!['accuracy']
          as Map<String, dynamic>)['value'] as int;
      if (accuracy < 100) {
        test('${entry.key} retains its accuracy and applies no effect on miss',
            () {
          final move = projector.project(
            move: PokemonMove.fromJson(entries[entry.key]!).normalized(),
          );
          final result = _runMove(move, accuracySeed: 99);
          expect(
            result.timeline.psdkTimeline.events
                .whereType<PsdkBattleMissEvent>()
                .where((event) => event.moveId == move.id),
            hasLength(1),
          );
          expect(_moveDamage(result, move.id), isEmpty);
          expect(result.state.battlerAt(psdkOpponentSlot).majorStatus, isNull);
          expect(
              result.timeline.psdkTimeline.events
                  .whereType<PsdkBattleStatusEvent>(),
              isEmpty);
          expect(
            result.timeline.psdkTimeline.events
                .whereType<PsdkBattleEffectEvent>()
                .where((event) => event.action == 'added'),
            isEmpty,
          );
          expect(result.state.battlerAt(psdkPlayerSlot).moves.single.currentPp,
              move.pp - 1);
        });
      }
    }

    test('corrected poison powder still respects type immunity', () {
      final move = projector.project(
        move: PokemonMove.fromJson(entries['poison_powder']!).normalized(),
      );
      final result = _runMove(move, opponentType: 'steel');
      expect(result.state.battlerAt(psdkOpponentSlot).majorStatus, isNull);
      expect(
          result.timeline.psdkTimeline.events
              .whereType<PsdkBattleStatusEvent>(),
          isEmpty);
    });

    test('corrected confuse ray still respects Own Tempo', () {
      final move = projector.project(
        move: PokemonMove.fromJson(entries['confuse_ray']!).normalized(),
      );
      final result = _runMove(move, opponentAbilityId: 'own_tempo');
      expect(
          result.state
              .battlerAt(psdkOpponentSlot)
              .effects
              .contains('confusion'),
          isFalse);
      expect(
        result.timeline.psdkTimeline.events
            .whereType<PsdkBattleEffectEvent>()
            .where((event) =>
                event.action == 'added' && event.effectId == 'confusion'),
        isEmpty,
      );
    });
  });
}

final _idleMove = PsdkBattleMoveData(
  id: 'opponent_splash',
  dbSymbol: 'splash',
  name: 'Splash',
  type: 'normal',
  category: PsdkBattleMoveCategory.status,
  power: 0,
  accuracy: 0,
  pp: 40,
  priority: 0,
  battleEngineMethod: 's_splash',
  target: PsdkBattleMoveTarget.none,
);

BattleEngineTurnResult _runMove(
  PsdkBattleMoveData move, {
  int genericSeed = 1,
  int accuracySeed = 1,
  String opponentType = 'normal',
  String? opponentAbilityId,
}) {
  final engine = BattleEngine(
    setup: BattleEngineSetup.singlesPokeMapBetaV1ForTest(
      player: _combatant('player', move, speed: 100),
      opponent: _combatant(
        'opponent',
        _idleMove,
        speed: 20,
        type: opponentType,
        abilityId: opponentAbilityId,
      ),
      rngSeeds: PsdkBattleRngSeeds(
        moveDamage: 1,
        moveCritical: 99999,
        moveAccuracy: accuracySeed,
        generic: genericSeed,
      ),
    ),
  );
  return engine.submit(const BattleDecision.fight(moveSlot: 0));
}

PsdkBattleCombatantSetup _combatant(
  String id,
  PsdkBattleMoveData move, {
  required int speed,
  String type = 'normal',
  String? abilityId,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 20,
    maxHp: 200,
    currentHp: 200,
    types: PsdkBattleTypes(primary: type),
    stats: PsdkBattleStats(
      attack: 50,
      defense: 50,
      specialAttack: 50,
      specialDefense: 50,
      speed: speed,
    ),
    abilityId: abilityId,
    moves: [move],
  );
}

Iterable<PsdkBattleDamageEvent> _moveDamage(
        BattleEngineTurnResult result, String moveId) =>
    result.timeline.psdkTimeline.events
        .whereType<PsdkBattleDamageEvent>()
        .where((event) => event.moveId == moveId && event.damage > 0);
