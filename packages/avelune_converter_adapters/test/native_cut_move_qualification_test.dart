import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/src/native_psdk_trainer_bundle.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  final builtin = NativePsdkTrainerBundle.builtin();
  final root = Platform.environment['AVELUNE_NATIVE_PSDK_REFERENCE_ROOT'];
  final skipSource =
      root == null ? 'Requires the read-only PSDK reference.' : false;
  late List<NativePsdkTrainerSourceFile> sources;
  final levels = (builtin.evidence['requestedLevels'] as Map).map(
      (key, value) =>
          MapEntry(key as String, (value as List).cast<int>().toSet()));

  setUpAll(() async {
    if (root == null) return;
    sources = [];
    for (final raw in (builtin.evidence['sources'] as List).cast<Map>()) {
      final path = raw['relativePath'] as String;
      final bytes = await File('$root/$path').readAsBytes();
      expect(crypto.sha256.convert(bytes).toString(), raw['sha256']);
      sources.add(NativePsdkTrainerSourceFile(
          relativePath: path,
          sha256: Sha256Hash(raw['sha256'] as String),
          bytes: bytes));
    }
  });

  test('Cut is separately qualified without changing trainer defaults', () {
    final cut = builtin.movesById['cut']!;
    expect(cut.engineSupportLevel,
        PokemonMoveEngineSupportLevel.structuredPartial);
    expect(cut.pp, 30);
    expect(cut.basePower, 50);
    expect(cut.accuracy.toJson(), {'kind': 'percent', 'value': 95});
    expect(cut.type, 'normal');
    expect(cut.category, PokemonMoveCategory.physical);
    expect(cut.target, PokemonMoveTarget.adjacentFoe);
    expect(cut.effects, isEmpty);
    expect(cut.unsupportedReasons, ['psdk_method:s_basic']);
    expect(builtin.evidence['nativeQualifiedFieldMoveIds'], ['cut']);
    expect(
        builtin.evidence['nativeBattleDefaultMoveIds'], isNot(contains('cut')));
    final defaults =
        (builtin.evidence['nativeBattleDefaultMoveIds'] as List).toSet();
    for (final move in builtin.movesById.values) {
      if (move.id == 'cut' || defaults.contains(move.id)) continue;
      expect(move.engineSupportLevel, PokemonMoveEngineSupportLevel.catalogOnly,
          reason: move.id);
      expect(move.unsupportedReasons,
          contains('native_roster_unused_move_unqualified'),
          reason: move.id);
    }
    expect(builtin.toJson().keys, isNot(contains('player')));
  });

  test('rebuild retains only the attested field move qualification', () {
    final rebuilt = const NativePsdkTrainerBundleBuilder()
        .build(files: sources, requestedLevels: levels);
    expect(rebuilt.catalogs['moves']!.toJson(),
        builtin.catalogs['moves']!.toJson());
    expect(rebuilt.evidence['nativeBattleDefaultMoveIds'],
        builtin.evidence['nativeBattleDefaultMoveIds']);
    expect(rebuilt.evidence['nativeQualifiedFieldMoveIds'], ['cut']);
  }, skip: skipSource);

  for (final field in ['pp', 'dbSymbol', 'battleEngineMethod']) {
    test('rejects freshly hashed unattested Cut $field payload', () {
      final original = sources.singleWhere(
          (file) => file.relativePath == 'Data/Studio/moves/cut.json');
      final json = (jsonDecode(utf8.decode(original.bytes)) as Map)
          .cast<String, dynamic>();
      json[field] = switch (field) {
        'pp' => 999,
        'dbSymbol' => 'tackle',
        _ => 's_do_nothing',
      };
      final bytes = utf8.encode(jsonEncode(json));
      final changed = NativePsdkTrainerSourceFile(
          relativePath: original.relativePath,
          sha256: Sha256Hash(crypto.sha256.convert(bytes).toString()),
          bytes: bytes);
      expect(
          () => const NativePsdkTrainerBundleBuilder().build(files: [
                for (final file in sources)
                  if (file != original) file else changed
              ], requestedLevels: levels),
          throwsA(isA<ContractError>().having((error) => error.code, 'code',
              'native_trainer.field_move_source_witness:Data/Studio/moves/cut.json')));
    }, skip: skipSource);
  }

  test('hydrates an already learned Cut to 30 PP and consumes one in battle',
      () {
    final cut = builtin.movesById['cut']!;
    expect(cut.engineSupportLevel,
        isNot(PokemonMoveEngineSupportLevel.catalogOnly));
    final species = builtin.speciesById['beedrill']!;
    final stats = species.baseStats;
    final hydration = const PlayerPokemonHydrator().hydrate(
        pokemon: PlayerPokemon(
            speciesId: species.id,
            level: 20,
            natureId: 'hardy',
            abilityId: species.abilities.primary,
            knownMoveIds: const ['cut']),
        catalogs: PlayerPokemonHydrationCatalogs(speciesById: {
          species.id: PlayerPokemonHydrationSpecies(
              id: species.id,
              baseStats: PokemonBaseStats(
                  hp: stats.hp,
                  attack: stats.atk,
                  defense: stats.def,
                  specialAttack: stats.spa,
                  specialDefense: stats.spd,
                  speed: stats.spe),
              primaryAbilityId: species.abilities.primary,
              abilityIds: [species.abilities.primary],
              growthRateId: species.progression.growthRateId),
        }, maxPpByMoveId: {
          cut.id: cut.pp
        }),
        ruleset: PokemonRulesetProfile.pokeMapBetaV1,
        origin: PlayerPokemonHydrationOrigin.scripted);
    expect(hydration.hasErrors, isFalse);
    final hydrated = hydration.pokemon!;
    expect(hydrated.knownMoveIds, ['cut']);
    expect(hydrated.currentPpByMoveId, {'cut': 30});
    final move = PsdkBattleMoveData(
        id: cut.id,
        dbSymbol: cut.id,
        name: cut.name,
        type: cut.type,
        category: PsdkBattleMoveCategory.physical,
        power: cut.basePower,
        accuracy: (cut.accuracy.toJson()['value'] as int),
        pp: cut.pp,
        currentPp: hydrated.currentPpByMoveId![cut.id],
        priority: cut.priority,
        criticalRate: cut.critRatio,
        battleEngineMethod:
            cut.unsupportedReasons.single.substring('psdk_method:'.length),
        target: PsdkBattleMoveTarget.adjacentFoe,
        contact: cut.flags.contains(PokemonMoveFlag.contact));
    final engine = PsdkBattleEngine(
        setup: PsdkBattleSetup.singlesPokeMapBetaV1ForTest(
            player: _combatant('player', move, 100),
            opponent: _combatant(
                'opponent',
                PsdkBattleMoveData(
                    id: 'hold_hands',
                    dbSymbol: 'hold_hands',
                    name: 'Hold Hands',
                    type: 'normal',
                    category: PsdkBattleMoveCategory.status,
                    power: 0,
                    accuracy: 100,
                    pp: 40,
                    priority: 0,
                    battleEngineMethod: 's_do_nothing',
                    target: PsdkBattleMoveTarget.self),
                1),
            rngSeeds: const PsdkBattleRngSeeds(
                moveDamage: 1,
                moveCritical: 99999,
                moveAccuracy: 3,
                generic: 4)));
    final result = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
    final spent = result.timeline.events
        .whereType<PsdkBattleMovePpSpentEvent>()
        .singleWhere((event) => event.moveId == 'cut');
    expect(spent.spent, 1);
    expect(spent.remainingPp, 29);
    final damage =
        result.timeline.events.whereType<PsdkBattleDamageEvent>().single;
    expect(damage.moveId, 'cut');
    expect(damage.damage, 10);
    expect(result.state.battlerAt(psdkOpponentSlot).currentHp, 390);
    expect(result.state.battlerAt(psdkPlayerSlot).moves.single.currentPp, 29);
  });
}

PsdkBattleCombatantSetup _combatant(
        String id, PsdkBattleMoveData move, int speed) =>
    PsdkBattleCombatantSetup(
        id: id,
        speciesId: id,
        displayName: id,
        level: 20,
        maxHp: 400,
        currentHp: 400,
        types: const PsdkBattleTypes(primary: 'water'),
        stats: PsdkBattleStats(
            attack: 50,
            defense: 50,
            specialAttack: 50,
            specialDefense: 50,
            speed: speed),
        moves: [move]);
