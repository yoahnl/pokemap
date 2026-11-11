import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/pokemon/application/pokemon_combat_authoring_rules.dart';
import 'package:avelune_studio/features/pokemon/application/pokemon_combat_controller.dart';
import 'package:avelune_studio/features/pokemon/data/local_pokemon_combat_adapter.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_workspace_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/combat_project_fixture.dart';
import '../support/m3_story_fixture.dart';

const _index = PokemonWorkspaceIndex(
  enabled: true,
  entries: [
    PokemonSpeciesSummary(
      id: 'bulbasaur',
      name: 'Bulbizarre',
      nationalDex: 1,
      generation: 1,
      types: ['grass'],
      formIds: [],
      mediaRelativePath: '',
      enabled: true,
      relativePath: 'data/pokemon/species/0001-bulbasaur.json',
    ),
  ],
  types: [],
  items: {},
  moves: PokemonMovesCatalogView(entries: [], relativePath: 'moves.json'),
);

final _counter = NarrativeFactDefinition(
  id: 'counter',
  label: 'Compteur',
  initialValue: NarrativeValue.integer(0),
);
final _edition = NarrativeFactDefinition(
  id: 'edition',
  label: 'Édition du jeu',
  initialValue: const NarrativeValue.string('or'),
);

void main() {
  late M3StoryFixture source;
  late LocalPokemonCombatAdapter local;
  late PokemonCombatController combat;

  setUp(() async {
    source = await M3StoryFixture.create();
    await seedCombatProject(source);
    final file = File('${source.directory.path}/project.json');
    final project = ProjectManifest.fromJson(
      jsonDecode(await file.readAsString()) as Map<String, dynamic>,
    );
    await file.writeAsString(
      jsonEncode(
        project
            .copyWith(facts: [...project.facts, _counter, _edition])
            .toJson(),
      ),
    );
    await source.maps.loadProject(source.session);
    local = LocalPokemonCombatAdapter(
      session: source.session,
      mapAdapter: source.maps,
    );
    combat = PokemonCombatController(local, changed: () {});
    await combat.load();
  });
  tearDown(() async {
    combat.dispose();
    await source.directory.delete(recursive: true);
  });

  void configure(String id, String name, String value, int start, int end) {
    combat.editEncounterVariant(id, (current) => current.copyWith(name: name));
    combat.addVariantCondition(id, _edition);
    combat.editVariantConditionValue(id, 0, _edition, value);
    combat.addVariantTimeWindow(id);
    combat.replaceVariantTimeWindow(
      id,
      0,
      LocalTimeWindow(startMinute: start * 60, endMinute: end * 60),
    );
    combat.addEncounterSpecies('bulbasaur', variantId: id);
  }

  void priority(String id, String raw) => combat.editNumber(
    'variant:$id:priority',
    raw,
    (value) => combat.editEncounterVariant(
      id,
      (current) => current.copyWith(priority: value),
    ),
  );

  test('Studio saves UI-edited variants with application-owned time windows and independently reopens them', () async {
    expect(combat.createTable('Prairie'), isTrue);
    combat.addEncounterVariant();
    final first = combat.table!.current.variants.single.id;
    configure(first, 'Édition Or · nuit', 'or', 20, 4);
    combat.addVariantCondition(first, _edition);
    combat.selectVariantFact(first, 1, _counter);
    combat.editVariantConditionValue(first, 1, _counter, 'incorrect');
    expect(combat.fieldErrors, isNotEmpty);
    combat.remapVariantInputs('variant:$first:condition:', 1);
    combat.editEncounterVariant(
      first,
      (current) => current.copyWith(conditions: [current.conditions.first]),
    );
    expect(combat.fieldErrors, isEmpty);
    combat.addEncounterVariant();
    expect(combat.table!.current.variants, hasLength(2));
    final second = combat.table!.current.variants.last.id;
    configure(second, 'Édition Argent · jour', 'argent', 4, 20);
    priority(first, '3');
    priority(second, '4');
    combat.replaceVariantTimeWindow(
      second,
      0,
      const LocalTimeWindow(startMinute: 240, endMinute: 1440),
    );
    expect(await combat.save(_index), isTrue);
    expect(combat.error, isNull);
    expect(combat.dirty, isFalse);
    final reopened =
        (await LocalPokemonCombatAdapter(
          session: source.session,
          mapAdapter: source.maps,
        ).load()).project.encounterTables.singleWhere(
          (table) => table.id == 'prairie',
        );
    expect(reopened.entries, isEmpty);
    expect(reopened.variants.map((variant) => variant.priority), [3, 4]);
    expect(reopened.variants.map((variant) => variant.name), [
      'Édition Or · nuit',
      'Édition Argent · jour',
    ]);
    expect(reopened.variants.first.conditions, [
      ScriptConditionFactory.factEquals(
        'edition',
        const NarrativeValue.string('or'),
      ),
    ]);
    expect(reopened.variants.last.conditions, [
      ScriptConditionFactory.factEquals(
        'edition',
        const NarrativeValue.string('argent'),
      ),
    ]);
    expect(reopened.variants.first.timeWindows, [
      const LocalTimeWindow(startMinute: 1200, endMinute: 240),
    ]);
    expect(reopened.variants.last.timeWindows, [
      const LocalTimeWindow(startMinute: 240, endMinute: 1440),
    ]);
    expect(reopened.allEntries.map((entry) => entry.speciesId), [
      'bulbasaur',
      'bulbasaur',
    ]);
  });

  test('variant condition values follow the fact type', () {
    final flag = NarrativeFactDefinition(
      id: 'flag',
      label: 'Drapeau',
      initialValue: const NarrativeValue.boolean(false),
    );
    expect(combat.createTable('Prairie'), isTrue);
    combat.addEncounterVariant();
    final id = combat.table!.current.variants.single.id;
    combat.addVariantCondition(id, flag);
    combat.editVariantConditionValue(id, 0, flag, 'true');
    expect(
      combat.table!.current.variants.single.conditions.single,
      ScriptConditionFactory.factEquals(
        'flag',
        const NarrativeValue.boolean(true),
      ),
    );
    combat.selectVariantFact(id, 0, _counter);
    combat.editVariantConditionValue(id, 0, _counter, '7');
    expect(
      combat.table!.current.variants.single.conditions.single,
      ScriptConditionFactory.factEquals('counter', NarrativeValue.integer(7)),
    );
    expect(combat.fieldErrors, isEmpty);
    combat.editVariantConditionValue(id, 0, _counter, '7.5');
    expect(combat.numericInputs['variant:$id:condition:0:value'], '7.5');
    expect(combat.fieldErrors['variant:$id:condition:0:value'], isNotNull);
    expect(
      combat.table!.current.variants.single.conditions.single,
      ScriptConditionFactory.factEquals('counter', NarrativeValue.integer(7)),
    );
    combat.selectVariantFact(id, 0, _edition);
    combat.editVariantConditionValue(id, 0, _edition, '12');
    expect(
      combat.table!.current.variants.single.conditions.single,
      ScriptConditionFactory.factEquals(
        'edition',
        const NarrativeValue.string('12'),
      ),
    );
  });

  test(
    'encounter chance is authored as a percentage of the stored fraction',
    () {
      expect(combat.createTable('Prairie'), isTrue);
      combat.editEncounterChancePercent('25');
      expect(combat.table!.current.chancePerStep, 0.25);
      expect(pokemonEncounterChancePercent(combat.table!.current), 25);
      combat.editEncounterChancePercent('vingt');
      expect(combat.table!.current.chancePerStep, 0.25);
      expect(combat.fieldErrors['chance'], isNotNull);
    },
  );

  test(
    'a unique encounter level sets both bounds while a table keeps its max',
    () {
      const entry = ProjectEncounterEntry(
        speciesId: 'bulbasaur',
        minLevel: 5,
        maxLevel: 9,
      );
      final unique = pokemonEncounterEntryWithMinLevel(entry, 12, unique: true);
      expect((unique.minLevel, unique.maxLevel), (12, 12));
      final table = pokemonEncounterEntryWithMinLevel(entry, 7, unique: false);
      expect((table.minLevel, table.maxLevel), (7, 9));
    },
  );

  test(
    'a trainer Pokémon accepts at most four moves and blank choices clear',
    () {
      const member = ProjectTrainerPokemonEntry(
        speciesId: 'bulbasaur',
        level: 5,
        moves: ['a', 'b', 'c'],
      );
      expect(pokemonTrainerCanAddMove(member), isTrue);
      expect(
        pokemonTrainerCanAddMove(member.copyWith(moves: ['a', 'b', 'c', 'd'])),
        isFalse,
      );
      expect(pokemonOptionalChoice(''), isNull);
      expect(pokemonOptionalChoice('poke-ball'), 'poke-ball');
    },
  );
}
