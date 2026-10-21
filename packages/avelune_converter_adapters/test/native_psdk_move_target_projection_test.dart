import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'package:avelune_converter_adapters/src/native_psdk_catalog.dart';
import 'package:avelune_converter_adapters/src/native_psdk_trainer_bundle.dart';

import '../tool/build_native_psdk_trainer_bundle.dart' as generator;

void main() {
  test('native Surf target survives Studio conversion and deals actual damage',
      () {
    final move = const PokemonSdkMoveCatalogConverter().convert(const {
      'dbSymbol': 'surf',
      'type': 'water',
      'category': 'special',
      'power': 90,
      'accuracy': 100,
      'pp': 15,
      'battleEngineMethod': 's_basic',
      'battleEngineAimedTarget': 'adjacent_all_pokemon',
    });
    _expectDamage(move);
  });

  test('embedded converter catalog keeps Surf damaging in the native engine',
      () {
    final move = NativePsdkCatalogManifest.builtin().movesById['surf']!;
    _expectDamage(move);
  });
  test(
      'pinned target refresh rejects absent, duplicate and changed source witnesses',
      () {
    final bundle = NativePsdkTrainerBundle.builtin();
    final relative = 'Data/Studio/moves/${bundle.movesById.keys.first}.json';
    final bytes = utf8.encode('{}');
    final changed = NativePsdkTrainerSourceFile(
      relativePath: relative,
      sha256: Sha256Hash(crypto.sha256.convert(bytes).toString()),
      bytes: bytes,
    );
    for (final sources in <List<NativePsdkTrainerSourceFile>>[
      [],
      [changed],
      [changed, changed],
    ]) {
      expect(
          () => generator.refreshNativePsdkTrainerTargets(
              bundle: bundle, sources: sources),
          throwsStateError);
    }
  });

  final reference = Platform.environment['AVELUNE_NATIVE_PSDK_REFERENCE_ROOT'];
  test('native Acupressure keeps its supported self-or-ally target', () {
    final move = NativePsdkCatalogManifest.builtin().movesById['acupressure']!;
    expect(move.target, PokemonMoveTarget.adjacentAllyOrSelf);
    expect(const CanonicalPsdkMoveProjector().project(move: move).target,
        PsdkBattleMoveTarget.adjacentAllyOrSelf);
  });

  test(
      'pinned target refresh changes only target metadata with exact native sources',
      () async {
    final bundle = NativePsdkTrainerBundle.builtin();
    final before = canonicalHashOf(bundle.toJson(),
        limits: nativePsdkCatalogShardJsonLimits);
    final sources = <NativePsdkTrainerSourceFile>[];
    for (final move in bundle.movesById.values) {
      final relative = 'Data/Studio/moves/${move.id}.json';
      final bytes = await File('$reference/$relative').readAsBytes();
      sources.add(NativePsdkTrainerSourceFile(
          relativePath: relative,
          sha256: Sha256Hash(crypto.sha256.convert(bytes).toString()),
          bytes: bytes));
    }
    final refreshed = generator.refreshNativePsdkTrainerTargets(
        bundle: bundle, sources: sources);
    _expectDamage(refreshed.movesById['surf']!);
    expect(
        canonicalHashOf(bundle.toJson(),
            limits: nativePsdkCatalogShardJsonLimits),
        before);
    expect(refreshed.speciesById.keys, bundle.speciesById.keys);
    expect(refreshed.evidence, bundle.evidence);
    expect(
        generator
            .refreshNativePsdkTrainerTargets(
                bundle: refreshed, sources: sources)
            .toJson(),
        refreshed.toJson());
  }, skip: reference == null);
}

void _expectDamage(PokemonMove move) {
  final projected = const CanonicalPsdkMoveProjector().project(move: move);
  final engine = PsdkBattleEngine(
    setup: PsdkBattleSetup.singlesPokeMapBetaV1ForTest(
      player: _combatant('player', [projected]),
      opponent: _combatant('opponent', [
        PsdkBattleMoveData(
          id: 'tackle',
          dbSymbol: 'tackle',
          name: 'Tackle',
          type: 'normal',
          category: PsdkBattleMoveCategory.physical,
          power: 1,
          accuracy: 100,
          pp: 35,
          priority: 0,
          battleEngineMethod: 's_basic',
          target: PsdkBattleMoveTarget.adjacentFoe,
        ),
      ]),
      rngSeeds: const PsdkBattleRngSeeds(
        moveDamage: 1,
        moveCritical: 2,
        moveAccuracy: 3,
        generic: 4,
      ),
    ),
  );
  final result = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
  expect(result.state.battlerAt(psdkOpponentSlot).currentHp, lessThan(100));
  expect(result.timeline.events.whereType<PsdkBattleDamageEvent>(), isNotEmpty);
  expect(result.state.battlerAt(psdkPlayerSlot).moves.first.currentPp, 14);
  expect(projected.target, PsdkBattleMoveTarget.allAdjacent);
  expect(move.target, PokemonMoveTarget.allAdjacent);
}

PsdkBattleCombatantSetup _combatant(
        String id, List<PsdkBattleMoveData> moves) =>
    PsdkBattleCombatantSetup(
      id: id,
      speciesId: id,
      displayName: id,
      level: 20,
      maxHp: 100,
      currentHp: 100,
      types: const PsdkBattleTypes(primary: 'normal'),
      stats: const PsdkBattleStats(
        attack: 50,
        defense: 50,
        specialAttack: 50,
        specialDefense: 50,
        speed: 50,
      ),
      moves: moves,
    );
