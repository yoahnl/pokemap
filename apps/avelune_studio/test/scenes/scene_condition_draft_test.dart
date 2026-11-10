import 'dart:async';

import 'package:avelune_studio/features/scenes/application/scene_condition_draft.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  test(
    'an unknown fact stays preserved until an explicit valid replacement',
    () {
      final source = SceneConditionSource.factValue(
        factId: 'missing',
        operator: NarrativeFactOperator.equals,
        expectedValue: NarrativeValue.boolean(true),
      );
      final project = workspaceProject.copyWith(
        facts: [NarrativeFactDefinition(id: 'gate', label: 'Passage')],
      );
      final draft = SceneConditionDraft(
        project: project,
        current: SceneConditionPayload(conditionSource: source),
        changed: () {},
      );
      addTearDown(draft.dispose);
      expect(draft.referenceId, 'missing');
      expect(draft.prepared, isNull);
      expect(draft.current.conditionSource, same(source));
      draft.selectReference('gate');
      expect(draft.prepared!.sourceId, 'gate');
      expect(draft.current.conditionSource, same(source));
    },
  );

  test(
    'ambiguous story flags are unavailable without discarding the source',
    () {
      final project = workspaceProject.copyWith(
        facts: [
          NarrativeFactDefinition(
            id: 'one',
            label: 'Premier',
            legacyFlagName: 'shared',
          ),
          NarrativeFactDefinition(
            id: 'two',
            label: 'Second',
            legacyFlagName: 'shared',
          ),
        ],
      );
      final draft = SceneConditionDraft(
        project: project,
        current: SceneConditionPayload(),
        changed: () {},
      );
      addTearDown(draft.dispose);
      draft.selectFamily('factLikeStoryFlag');
      expect(draft.references, isEmpty);
      expect(draft.prepared, isNull);
    },
  );

  test(
    'a stale map response cannot overwrite a newly selected source',
    () async {
      final first = Completer<MapData>(), second = Completer<MapData>();
      final draft = SceneConditionDraft(
        project: workspaceProject,
        current: SceneConditionPayload(),
        changed: () {},
        loadMap: (id) => id == 'a' ? first.future : second.future,
      );
      addTearDown(draft.dispose);
      draft.selectFamily('playerAtEntityAnchor');
      draft.selectedMapId = 'a';
      final old = draft.loadReferenceMap();
      draft.selectedMapId = 'b';
      final latest = draft.loadReferenceMap();
      second.complete(workspaceMap('b'));
      await latest;
      first.complete(workspaceMap('a'));
      await old;
      expect(draft.stageMap!.id, 'b');
      expect(draft.mapError, isNull);
    },
  );

  test(
    'pokedex range rejects coercion and keeps the supported numeric bounds',
    () {
      final draft = SceneConditionDraft(
        project: workspaceProject,
        current: SceneConditionPayload(),
        changed: () {},
      );
      addTearDown(draft.dispose);
      draft.selectFamily('pokedexCaughtCount');
      expect(draft.prepared, isNotNull);
      draft.minimumCount = '02';
      expect(draft.prepared, isNull);
      draft.minimumCount = '65536';
      expect(draft.prepared, isNull);
      draft.minimumCount = '20';
      draft.firstNational = '152';
      expect(draft.prepared, isNull);
      draft.firstNational = '1';
      expect(draft.prepared, isNotNull);
    },
  );
  test('typed integer edits preserve operator and source until explicit application', () {
    final source = SceneConditionSource.factValue(
      factId: 'count',
      operator: NarrativeFactOperator.greaterThanOrEqual,
      expectedValue: NarrativeValue.integer(3),
    );
    final project = workspaceProject.copyWith(
      facts: [
        NarrativeFactDefinition(
          id: 'count',
          label: 'Billets',
          initialValue: NarrativeValue.integer(0),
        ),
      ],
    );
    final draft = SceneConditionDraft(
      project: project,
      current: SceneConditionPayload(conditionSource: source),
      changed: () {},
    );
    addTearDown(draft.dispose);
    expect(draft.text, '3');
    draft.text = '5';
    expect(draft.current.conditionSource, same(source));
    expect(draft.prepared!.expectedFactValue, NarrativeValue.integer(5));
    expect(
      draft.prepared!.factOperator,
      NarrativeFactOperator.greaterThanOrEqual,
    );
    for (final invalid in ['5.2', 'bad', '']) {
      draft.text = invalid;
      expect(draft.prepared, isNull);
      expect(draft.current.conditionSource, same(source));
    }
  });

  test('string values retain spaces and reject ordering operators', () {
    final source = SceneConditionSource.factValue(
      factId: 'name',
      operator: NarrativeFactOperator.notEquals,
      expectedValue: const NarrativeValue.string('Quai'),
    );
    final project = workspaceProject.copyWith(
      facts: [
        NarrativeFactDefinition(
          id: 'name',
          label: 'Nom du quai',
          initialValue: const NarrativeValue.string(''),
        ),
      ],
    );
    final draft = SceneConditionDraft(
      project: project,
      current: SceneConditionPayload(conditionSource: source),
      changed: () {},
    );
    addTearDown(draft.dispose);
    draft.text = '  Quai nord  ';
    expect(
      draft.prepared!.expectedFactValue,
      const NarrativeValue.string('  Quai nord  '),
    );
    expect(draft.prepared!.factOperator, NarrativeFactOperator.notEquals);
    draft.comparisonOperator = NarrativeFactOperator.greaterThan;
    expect(draft.prepared, isNull);
    expect(draft.current.conditionSource, same(source));
  });

  test('player facing projects the exact direction and negation without rewriting its source', () {
    final source = SceneConditionSource.playerFacing(
      direction: EntityFacing.north,
    );
    final draft = SceneConditionDraft(
      project: workspaceProject,
      current: SceneConditionPayload(conditionSource: source),
      changed: () {},
    );
    addTearDown(draft.dispose);
    draft.selectReference('west');
    draft.expected = false;
    expect(draft.prepared!.playerFacingDirection, EntityFacing.west);
    expect(draft.prepared!.operator, SceneConditionOperator.isFalse);
    expect(draft.prepared!.label, 'Ouest');
    expect(draft.current.conditionSource, same(source));
  });

  test(
    'unsupported sources and empty catalogues never invent a replacement',
    () {
      final source = SceneConditionSource(
        sourceKind: SceneConditionSourceKind.worldState,
        sourceId: 'weather',
        operator: SceneConditionOperator.equals,
        value: 'rain',
        label: 'Météo',
      );
      final current = SceneConditionPayload(conditionSource: source);
      final draft = SceneConditionDraft(
        project: const ProjectManifest(name: 'Vide', maps: [], tilesets: []),
        current: current,
        changed: () {},
      );
      addTearDown(draft.dispose);
      expect(draft.unsupported, isTrue);
      expect(draft.prepared, isNull);
      expect(draft.current, same(current));
      draft.selectFamily('fact');
      expect(draft.references, isEmpty);
      expect(draft.prepared, isNull);
      expect(draft.current, same(current));
    },
  );

  test('pokedex source survives 2D to 3D to 2D reconfiguration without implicit application', () {
    final source = SceneConditionSource.pokedexCaughtAtLeast(
      range: PokedexSpeciesRange(firstNationalDex: 1, lastNationalDex: 151),
      minimum: 20,
    );
    final current = SceneConditionPayload(conditionSource: source);
    final draft = SceneConditionDraft(
      project: workspaceProject,
      current: current,
      changed: () {},
    );
    addTearDown(draft.dispose);
    expect(draft.prepared, isNotNull);
    draft.configure(
      project: workspaceProject.copyWith(
        settings: ProjectSettings(dimension: ProjectDimension.threeD),
      ),
      current: current,
      loadMoves: null,
      loadItems: null,
      loadMap: null,
    );
    expect(draft.availableFamilies, isNot(contains('pokedexCaughtCount')));
    expect(draft.unsupported, isTrue);
    expect(draft.prepared, isNull);
    expect(draft.current, same(current));
    draft.configure(
      project: workspaceProject,
      current: current,
      loadMoves: null,
      loadItems: null,
      loadMap: null,
    );
    expect(draft.unsupported, isFalse);
    expect(draft.prepared!.pokedexMinimumCaughtCount, 20);
    expect(draft.current, same(current));
  });

  test('pokedex threshold editing retains the species range and refuses malformed and inverted bounds', () {
    final source = SceneConditionSource.pokedexCaughtAtLeast(
      range: PokedexSpeciesRange(firstNationalDex: 1, lastNationalDex: 151),
      minimum: 20,
    );
    final draft = SceneConditionDraft(
      project: workspaceProject,
      current: SceneConditionPayload(conditionSource: source),
      changed: () {},
    );
    addTearDown(draft.dispose);
    draft.minimumCount = '25';
    expect(draft.prepared!.pokedexMinimumCaughtCount, 25);
    expect(draft.prepared!.pokedexSpeciesRange, source.pokedexSpeciesRange);
    expect(draft.prepared!.operator, SceneConditionOperator.isTrue);
    for (final invalid in ['0', '5.2', '65536', 'bad']) {
      draft.minimumCount = invalid;
      expect(draft.prepared, isNull);
      expect(draft.current.conditionSource, same(source));
    }
    draft.minimumCount = '20';
    draft.firstNational = '200';
    expect(draft.prepared, isNull);
    expect(draft.current.conditionSource, same(source));
  });
}
