import 'dart:io';

import 'package:avelune_studio/features/pokemon/application/pokemon_combat_controller.dart';
import 'package:avelune_studio/features/pokemon/data/local_pokemon_combat_adapter.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_workspace_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/combat_project_fixture.dart';
import '../support/pokemon_authoring_fixture.dart';

Future<PokemonAuthoringFixture> _open() async {
  final host = await PokemonAuthoringFixture.create(
    prepareSource: seedCombatProject,
  );
  addTearDown(host.dispose);
  expect(await host.view(PokemonWorkspaceView.combats), isTrue);
  return host;
}

void main() {
  test('encounter variants retain stable independent identities and save through the real adapter', () async {
    final host = await _open();
    final combat = host.combat;
    expect(combat.createTable('Route du matin'), isTrue);
    combat.addEncounterSpecies('bulbasaur');
    combat.addEncounterVariant();
    combat.addEncounterVariant();
    expect(combat.table!.current.variants.map((variant) => variant.id), [
      'variant_1',
      'variant_2',
    ]);
    combat.addEncounterSpecies('bulbasaur', variantId: 'variant_1');
    combat.addEncounterSpecies('bulbasaur', variantId: 'variant_2');
    combat.editEncounterVariant(
      'variant_2',
      (variant) => variant.copyWith(
        name: 'Matin',
        priority: 1,
        timeWindows: const [LocalTimeWindow(startMinute: 480, endMinute: 1200)],
      ),
    );
    final before = combat.table!.current;
    expect(before.entries.single.minLevel, 5);
    expect(before.entries.single.maxLevel, 5);
    expect(
      encounterTableEntries(before, 'variant_2').single.speciesId,
      'bulbasaur',
    );
    expect(
      await combat.save(host.pokemon.index!),
      isTrue,
      reason: combat.error,
    );
    final reopened = await LocalPokemonCombatAdapter(
      session: host.source.session,
      mapAdapter: host.source.maps,
    ).load();
    final saved = reopened.project.encounterTables.singleWhere(
      (table) => table.id == before.id,
    );
    expect(saved.variants[1].name, 'Matin');
    expect(saved.variants[1].timeWindows.single.startMinute, 480);
    expect(saved.variants[1].entries.single, before.variants[1].entries.single);
    expect(saved.variants[0], before.variants[0]);
  });

  test('variant time window replacements and removals preserve unrelated ranges and persist through the real adapter', () async {
    final host = await _open();
    final combat = host.combat;
    expect(combat.createTable('Horaires'), isTrue);
    combat.addEncounterSpecies('bulbasaur');
    combat.addEncounterVariant();
    combat.addEncounterVariant();
    for (final id in ['variant_1', 'variant_2']) {
      combat.addEncounterSpecies('bulbasaur', variantId: id);
      combat.addVariantTimeWindow(id);
    }
    combat.addVariantTimeWindow('variant_1');
    expect(
      await combat.save(host.pokemon.index!),
      isTrue,
      reason: combat.error,
    );
    final original = combat.table!.current;
    final projectFile = File('${host.source.directory.path}/project.json');
    final diskBefore = await projectFile.readAsBytes();
    const night = LocalTimeWindow(startMinute: 1200, endMinute: 240);
    const day = LocalTimeWindow(startMinute: 240, endMinute: 1440);
    combat.replaceVariantTimeWindow('variant_1', 0, night);
    final replaced = combat.table!.current;
    expect(replaced.variants.first.timeWindows, [
      night,
      original.variants.first.timeWindows.last,
    ]);
    expect(replaced.variants.last, original.variants.last);
    expect(original.variants.first.timeWindows, const [
      LocalTimeWindow(startMinute: 480, endMinute: 1200),
      LocalTimeWindow(startMinute: 480, endMinute: 1200),
    ]);
    combat.removeVariantTimeWindow('variant_1', 1);
    expect(combat.table!.current.variants.first.timeWindows, [night]);
    expect(combat.table!.current.variants.last, original.variants.last);
    combat.replaceVariantTimeWindow('variant_2', 0, day);
    final updated = combat.table!.current;
    expect(updated.entries, original.entries);
    expect(
      updated.variants.first,
      original.variants.first.copyWith(timeWindows: [night]),
    );
    expect(
      updated.variants.last,
      original.variants.last.copyWith(timeWindows: [day]),
    );
    expect(await projectFile.readAsBytes(), diskBefore);
    expect(combat.dirty, isTrue);
    expect(
      await combat.save(host.pokemon.index!),
      isTrue,
      reason: combat.error,
    );
    final reopened = await LocalPokemonCombatAdapter(
      session: host.source.session,
      mapAdapter: host.source.maps,
    ).load();
    final saved = reopened.project.encounterTables.singleWhere(
      (table) => table.id == updated.id,
    );
    expect(saved, updated);
    expect(saved.variants.first.timeWindows.single.contains(1200), isTrue);
    expect(saved.variants.first.timeWindows.single.contains(239), isTrue);
    expect(saved.variants.first.timeWindows.single.contains(240), isFalse);
    expect(saved.variants.last.timeWindows.single.contains(1439), isTrue);
    expect(saved.variants.last.timeWindows.single.contains(1440), isFalse);
    combat.removeVariantTimeWindow('variant_1', 0);
    expect(combat.table!.current.variants.first.timeWindows, isEmpty);
    expect(
      await combat.save(host.pokemon.index!),
      isTrue,
      reason: combat.error,
    );
    final withoutLimit = await LocalPokemonCombatAdapter(
      session: host.source.session,
      mapAdapter: host.source.maps,
    ).load();
    final allDay = withoutLimit.project.encounterTables.singleWhere(
      (table) => table.id == updated.id,
    );
    expect(allDay.variants.first.timeWindows, isEmpty);
    expect(allDay.variants.last, saved.variants.last);
  });

  test('invalid variant time windows keep the draft and never overwrite the saved project', () async {
    final host = await _open();
    final combat = host.combat;
    combat.createTable('Horaires');
    combat.addEncounterVariant();
    combat.addEncounterSpecies('bulbasaur', variantId: 'variant_1');
    combat.addVariantTimeWindow('variant_1');
    expect(
      await combat.save(host.pokemon.index!),
      isTrue,
      reason: combat.error,
    );
    final original = combat.table!.current;
    final projectFile = File('${host.source.directory.path}/project.json');
    final before = await projectFile.readAsBytes();
    for (final invalid in const [
      LocalTimeWindow(startMinute: 480, endMinute: 480),
      LocalTimeWindow(startMinute: 240, endMinute: 1441),
    ]) {
      combat.replaceVariantTimeWindow('variant_1', 0, invalid);
      final draft = combat.table!.current;
      expect(await combat.save(host.pokemon.index!), isFalse);
      expect(combat.error, isNotNull);
      expect(combat.table!.current, same(draft));
      expect(combat.dirty, isTrue);
      expect(await projectFile.readAsBytes(), before);
      combat.discard();
      expect(combat.table!.current, original);
      expect(combat.dirty, isFalse);
    }
  });

  test(
    'removing one encounter variant preserves every unrelated numeric draft',
    () async {
      final host = await _open();
      final combat = host.combat;
      combat.createTable('Route');
      combat.addEncounterVariant();
      combat.addEncounterVariant();
      combat.numericInputs.addAll({
        'variant:variant_1:priority': 'invalid',
        'variant:variant_2:priority': '7',
        'chance': '12',
      });
      combat.fieldErrors['variant:variant_1:priority'] = 'Invalid';
      combat.removeEncounterVariant('variant_1');
      expect(combat.table!.current.variants.single.id, 'variant_2');
      expect(combat.numericInputs, {
        'variant:variant_2:priority': '7',
        'chance': '12',
      });
      expect(combat.fieldErrors, isEmpty);
      combat.addEncounterVariant();
      expect(combat.table!.current.variants.map((variant) => variant.id), [
        'variant_2',
        'variant_1',
      ]);
    },
  );

  test('variant row removal reindexes both raw inputs and errors without crossing owners', () async {
    final host = await _open();
    final combat = host.combat;
    combat.numericInputs.addAll({
      'variant:v:entry0:min': 'old',
      'variant:v:entry1:min': 'invalid',
      'variant:v:entry2:min': '7',
      'variant:w:entry2:min': '9',
    });
    combat.fieldErrors.addAll({
      'variant:v:entry1:min': 'remove',
      'variant:v:entry2:min': 'keep',
      'other': 'other',
    });
    combat.remapVariantInputs('variant:v:entry', 1);
    expect(combat.numericInputs, {
      'variant:v:entry0:min': 'old',
      'variant:v:entry1:min': '7',
      'variant:w:entry2:min': '9',
    });
    expect(combat.fieldErrors, {
      'variant:v:entry1:min': 'keep',
      'other': 'other',
    });
  });

  test('saving or disposed combat owners refuse variant removal and input mutation', () async {
    final host = await _open();
    final combat = host.combat;
    combat.createTable('Route');
    combat.addEncounterVariant();
    combat.addVariantTimeWindow('variant_1');
    final before = combat.table!.current;
    combat.numericInputs['variant:variant_1:priority'] = 'invalid';
    combat.saving = true;
    combat.addVariantTimeWindow('variant_1');
    combat.replaceVariantTimeWindow(
      'variant_1',
      0,
      const LocalTimeWindow(startMinute: 0, endMinute: 60),
    );
    combat.removeVariantTimeWindow('variant_1', 0);
    combat.removeEncounterVariant('variant_1');
    combat.remapVariantInputs('variant:variant_1:', 0);
    expect(combat.table!.current, same(before));
    expect(combat.numericInputs['variant:variant_1:priority'], 'invalid');
    combat.saving = false;
    combat.dispose();
    combat.addVariantTimeWindow('variant_1');
    combat.replaceVariantTimeWindow(
      'variant_1',
      0,
      const LocalTimeWindow(startMinute: 0, endMinute: 60),
    );
    combat.removeVariantTimeWindow('variant_1', 0);
    combat.removeEncounterVariant('variant_1');
    combat.remapVariantInputs('variant:variant_1:', 0);
    expect(combat.table!.current, same(before));
    expect(combat.numericInputs['variant:variant_1:priority'], 'invalid');
  });

  test('trainer additions and replacements preserve other team entries and default to level five', () async {
    final host = await _open();
    final combat = host.combat;
    combat.createTrainer('Guide');
    combat.addTrainerSpecies('bulbasaur');
    combat.addTrainerSpecies('bulbasaur');
    final members = combat.trainer!.current.team;
    expect(members.first.level, 5);
    combat.replaceTrainerMember(0, members.first.copyWith(level: 12));
    expect(combat.trainer!.current.team.first.level, 12);
    expect(combat.trainer!.current.team.last, members.last);
  });

  test(
    'trainer ball choices exclude ambiguous identities and ordinary items',
    () {
      const capture = ProjectCaptureItemDefinition(
        rateNumerator: 1,
        rateDenominator: 1,
        allowedEncounterKinds: {EncounterKind.walk},
      );
      const ball = ProjectItemDefinition(
        id: 'ball',
        displayName: 'Ball',
        pocketId: 'balls',
        capture: capture,
      );
      const duplicate = ProjectItemDefinition(
        id: 'duplicate',
        displayName: 'Duplicate',
        pocketId: 'balls',
        capture: capture,
      );
      const potion = ProjectItemDefinition(
        id: 'potion',
        displayName: 'Potion',
        pocketId: 'medicine',
      );
      const catalog = ProjectItemCatalog(
        schemaVersion: 1,
        entries: [ball, duplicate, duplicate, potion],
      );
      expect(trainerBallChoices(catalog), {'': 'Aucune Ball', 'ball': 'Ball'});
      expect(trainerBallChoices(null), {'': 'Aucune Ball'});
    },
  );

  test('guided variant condition and time defaults clear only the replaced fact input', () async {
    final host = await _open();
    final combat = host.combat;
    combat.createTable('Route');
    combat.addEncounterVariant();
    final initial = NarrativeFactDefinition(
      id: 'ready',
      label: 'Prêt',
      initialValue: NarrativeValue.boolean(false),
    );
    final next = NarrativeFactDefinition(
      id: 'counter',
      label: 'Compteur',
      initialValue: NarrativeValue.integer(3),
    );
    combat.addVariantCondition('variant_1', initial);
    combat.addVariantTimeWindow('variant_1');
    combat.numericInputs.addAll({
      'variant:variant_1:condition:0:value': 'invalid',
      'chance': '12',
    });
    combat.fieldErrors['variant:variant_1:condition:0:value'] = 'Invalid';
    combat.selectVariantFact('variant_1', 0, next);
    final variant = combat.table!.current.variants.single;
    expect(
      variant.conditions.single.toJson(),
      ScriptConditionFactory.factEquals(next.id, next.initialValue).toJson(),
    );
    expect(variant.timeWindows.single.startMinute, 480);
    expect(variant.timeWindows.single.endMinute, 1200);
    expect(combat.numericInputs, {'chance': '12'});
    expect(combat.fieldErrors, isEmpty);
  });
}
