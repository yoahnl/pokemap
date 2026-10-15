import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/application/runtime_battle_setup_exception.dart';
import 'package:map_runtime/src/application/runtime_pokemon_evolution_loader.dart';

void main() {
  late Directory directory;
  late Map<String, dynamic> native;
  const config = ProjectPokemonConfig(
    ruleset: PokemonRulesetProfile.pokeMapBetaV1,
    speciesDir: 'native/species',
    evolutionsDir: 'native/evolutions',
  );
  Future<void> putEvolution(String id, Map<String, dynamic> data) async {
    final file = File('${directory.path}/native/evolutions/$id.json');
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(data));
  }

  Future<Map<String, dynamic>> getEvolution(String id) async => jsonDecode(
    await File('${directory.path}/native/evolutions/$id.json').readAsString(),
  ) as Map<String, dynamic>;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('native-trade-loader-');
    native = jsonDecode(
      await File(
        '../avelune_converter_adapters/assets/native_psdk_trainer_bundle.json',
      ).readAsString(),
    ) as Map<String, dynamic>;
    for (final raw in (native['species'] as List).cast<Map>()) {
      final file = File('${directory.path}/native/species/${raw['id']}.json');
      await file.parent.create(recursive: true);
      await file.writeAsString(jsonEncode(raw));
    }
    for (final raw in (native['evolutions'] as List).cast<Map>()) {
      await putEvolution(
        raw['speciesId'] as String,
        raw.cast<String, dynamic>(),
      );
    }
  });
  tearDown(() async {
    await directory.delete(recursive: true);
  });
  Future<List<PokemonEvolutionCandidate>> load(String id) =>
      RuntimePokemonEvolutionLoader().loadTradeCandidates(
        projectRootDirectory: directory.path,
        pokemonConfig: config,
        sourceSpeciesId: id,
      );

  test(
    'actual native Machoke rule resolves Machamp metadata without source code',
    () async {
      final candidates = await load('machoke');
      expect(candidates, hasLength(1));
      final candidate = candidates.single;
      expect(candidate.targetSpeciesId, 'machamp');
      expect(candidate.condition.kind, PokemonEvolutionConditionKind.trade);
      final target = (native['species'] as List).cast<Map>().singleWhere(
        (raw) => raw['id'] == 'machamp',
      );
      expect(candidate.targetBaseStats.hp, (target['baseStats'] as Map)['hp']);
      expect(
        candidate.targetPrimaryAbilityId,
        (target['abilities'] as Map)['primary'],
      );
    },
  );
  test('actual native Onix held condition remains required', () async {
    final candidate = (await load('onix')).single;
    expect(
      candidate.condition.tradeRequirements!.requiredHeldItemId,
      'metal_coat',
    );
    const pokemon = PlayerPokemon(
      speciesId: 'onix',
      natureId: 'hardy',
      abilityId: 'sturdy',
      level: 20,
      currentHp: 10,
    );
    const trigger = PokemonEvolutionTrigger.trade(partnerSpeciesId: 'machoke');
    expect(candidate.isEligible(pokemon, trigger: trigger), false);
    expect(
      candidate.isEligible(
        pokemon.copyWith(heldItemId: 'metal_coat'),
        trigger: trigger,
      ),
      true,
    );
  });
  test('a malformed or extended native trade rule fails closed', () async {
    for (final requirements in <Object>[
      {'unknown': true},
      'not-an-object',
      {'requiredHeldItemId': '../coat'},
    ]) {
      final source = await getEvolution('machoke');
      (source['evolutions'] as List).single['tradeRequirements'] = requirements;
      await putEvolution('machoke', source);
      await expectLater(
        load('machoke'),
        throwsA(isA<RuntimeBattleSetupException>()),
      );
    }
  });
  test(
    'unrecognized conditional evolution is not silently treated as ineligible',
    () async {
      final source = await getEvolution('machoke');
      final rule = (source['evolutions'] as List).single as Map;
      rule['method'] = 'conditional';
      rule.remove('tradeRequirements');
      await putEvolution('machoke', source);
      await expectLater(
        load('machoke'),
        throwsA(isA<RuntimeBattleSetupException>()),
      );
    },
  );
  test('ordinary native level rules are ignored by trade and remain available to level flow', () async {
    expect(await load('machop'), isEmpty);
    final level = await RuntimePokemonEvolutionLoader().loadLevelUpCandidates(
      projectRootDirectory: directory.path,
      pokemonConfig: config,
      sourceSpeciesId: 'machop',
    );
    expect(level.single.targetSpeciesId, 'machoke');
    expect(
      await RuntimePokemonEvolutionLoader().loadLevelUpCandidates(
        projectRootDirectory: directory.path,
        pokemonConfig: config,
        sourceSpeciesId: 'machoke',
      ),
      isEmpty,
    );
  });
  test('trade loader retains native source path boundaries', () async {
    await expectLater(
      load('../machoke'),
      throwsA(isA<RuntimeBattleSetupException>()),
    );
  });
}
