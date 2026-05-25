# P4-01-bis — Narrative Reference Picker Evidence Pack Completion

## 1. Résumé exécutif

P4-01-bis complète uniquement l'Evidence Pack de P4-01.

Constat important : au démarrage du bis, le worktree était propre et P4-01 était déjà intégré dans `HEAD`.

```text
commit 887e1c0dadc43d93233f5415f6a0a72ea87a5008
Ajoute P4-01 : Narrative Reference Picker Coverage Missing Read Models (mises à jour et rapport)
```

Conséquence factuelle : les commandes `git diff -- packages/...` demandées pour les fichiers P4-01 produisent une sortie vide dans le worktree courant. Le présent bis compense donc le manque documentaire du rapport P4-01 en reproduisant les contenus vérifiés des read models, builders et tests ajoutés.

Verdict :

```text
P4-01 : clôturable après correction documentaire.
P4-01-bis : validable.
Prochain lot exact : P4-02 — Scenario Authoring Draft Model V0.
```

## 2. Scope du bis

Inclus :

- relire le rapport P4-01 ;
- relire la roadmap Phase 4 ;
- relire les fichiers P4-01 concernés ;
- relancer les tests P4-01, la régression validator, `dart analyze` et le format check ;
- exécuter les contrôles Git et hors scope demandés ;
- créer ce rapport evidence-only.

Exclus :

- modification de code ;
- modification de tests ;
- modification de roadmap ;
- ajout de read model ;
- UI, registry, migration, Selbrume, rewards/money/XP ;
- P4-02.

## 3. Problème documentaire corrigé

Le rapport P4-01 indiquait correctement les fichiers modifiés et les résultats, mais il ne fournissait pas assez de contenu vérifiable pour les deux fichiers principaux :

```text
packages/map_core/lib/src/read_models/narrative_reference_picker_read_models.dart
packages/map_core/test/narrative_reference_picker_read_models_test.dart
```

Le commit P4-01 indique :

```text
 MVP Selbrume/road_map_phase_4.md                   |  40 +-
 .../narrative_reference_picker_read_models.dart    | 694 +++++++++++++++++++++
 ...arrative_reference_picker_read_models_test.dart | 373 ++++++++++-
 ...eference_picker_coverage_missing_read_models.md | 486 +++++++++++++++
 4 files changed, 1583 insertions(+), 10 deletions(-)
```

Le diff complet du commit est volumineux. Le présent rapport reproduit donc le contenu complet des signatures publiques, enums, classes, builders et tests P4-01 ajoutés, ainsi que les commandes exactes et sorties de validation.

## 4. Contenu vérifié des read models

Fichier vérifié :

```text
packages/map_core/lib/src/read_models/narrative_reference_picker_read_models.dart
```

Exports publics vérifiés via `packages/map_core/lib/map_core.dart` :

```dart
export 'src/read_models/narrative_reference_picker_read_models.dart';
```

### 4.1 Enums ajoutés

```dart
enum NarrativeStoryStepPickerSource {
  stepStudio,
  legacyMetadata,
}

enum NarrativeEventSourceKind {
  mapEnter,
  triggerEnter,
  entityInteract,
  outcomeReceived,
}

enum NarrativePredicateReferenceKind {
  storyFlag,
  storyStep,
  cutscene,
  scenarioOutcome,
  battleOutcome,
}
```

### 4.2 `NarrativeStoryStepPickerOption`

```dart
@immutable
final class NarrativeStoryStepPickerOption {
  NarrativeStoryStepPickerOption({
    required this.stepId,
    required this.humanLabel,
    required this.description,
    required this.sourceScenarioId,
    required this.sourceScenarioLabel,
    required this.sourceKind,
    required this.order,
    required List<String> linkedCutsceneIds,
    required List<String> expectedOutcomeIds,
    required List<String> emittedOutcomeIds,
    required this.debugTechnicalLabel,
  })  : linkedCutsceneIds = List<String>.unmodifiable(linkedCutsceneIds),
        expectedOutcomeIds = List<String>.unmodifiable(expectedOutcomeIds),
        emittedOutcomeIds = List<String>.unmodifiable(emittedOutcomeIds);

  final String stepId;
  final String humanLabel;
  final String description;
  final String sourceScenarioId;
  final String sourceScenarioLabel;
  final NarrativeStoryStepPickerSource sourceKind;
  final int order;
  final List<String> linkedCutsceneIds;
  final List<String> expectedOutcomeIds;
  final List<String> emittedOutcomeIds;
  final String debugTechnicalLabel;
}
```

Les méthodes `operator ==` et `hashCode` sont présentes dans le fichier lu et comparent tous les champs listés ci-dessus.

### 4.3 `NarrativeEventSourcePickerOption`

```dart
@immutable
final class NarrativeEventSourcePickerOption {
  const NarrativeEventSourcePickerOption({
    required this.sourceId,
    required this.sourceKind,
    required this.humanLabel,
    required this.mapId,
    required this.mapLabel,
    required this.entityId,
    required this.entityLabel,
    required this.triggerId,
    required this.triggerLabel,
    required this.outcomeId,
    required this.debugTechnicalLabel,
  });

  final String sourceId;
  final NarrativeEventSourceKind sourceKind;
  final String humanLabel;
  final String mapId;
  final String mapLabel;
  final String entityId;
  final String entityLabel;
  final String triggerId;
  final String triggerLabel;
  final String outcomeId;
  final String debugTechnicalLabel;
}
```

Les méthodes `operator ==` et `hashCode` sont présentes dans le fichier lu et comparent tous les champs listés ci-dessus.

### 4.4 `NarrativePredicateReferencePickerOption`

```dart
@immutable
final class NarrativePredicateReferencePickerOption {
  NarrativePredicateReferencePickerOption({
    required this.referenceId,
    required this.referenceKind,
    required this.humanLabel,
    required List<String> sourceScenarioIds,
    required this.debugTechnicalLabel,
  }) : sourceScenarioIds = List<String>.unmodifiable(sourceScenarioIds);

  final String referenceId;
  final NarrativePredicateReferenceKind referenceKind;
  final String humanLabel;
  final List<String> sourceScenarioIds;
  final String debugTechnicalLabel;
}
```

Les méthodes `operator ==` et `hashCode` sont présentes dans le fichier lu et comparent tous les champs listés ci-dessus.

### 4.5 Builder `buildNarrativeStoryStepPickerOptions`

```dart
List<NarrativeStoryStepPickerOption> buildNarrativeStoryStepPickerOptions(
  ProjectManifest manifest,
) {
  final byStepId = <String, NarrativeStoryStepPickerOption>{};

  for (final scenario in manifest.scenarios) {
    if (scenario.scope != ScenarioScope.globalStory) {
      continue;
    }
    for (final option in _storyStepOptionsForScenario(scenario)) {
      byStepId.putIfAbsent(option.stepId, () => option);
    }
  }

  final options = byStepId.values.toList(growable: false);
  options.sort((a, b) {
    final byScenario = _compareStringsCaseInsensitive(
        a.sourceScenarioLabel, b.sourceScenarioLabel);
    if (byScenario != 0) {
      return byScenario;
    }
    final byOrder = a.order.compareTo(b.order);
    if (byOrder != 0) {
      return byOrder;
    }
    final byLabel = _compareStringsCaseInsensitive(a.humanLabel, b.humanLabel);
    if (byLabel != 0) {
      return byLabel;
    }
    return _compareStringsCaseInsensitive(a.stepId, b.stepId);
  });
  return List<NarrativeStoryStepPickerOption>.unmodifiable(options);
}
```

Sources vérifiées :

```text
ScenarioAsset.metadata['authoring.stepStudioDocument']
fallback legacy step.id / step.name / step.description / step.cutsceneIds
```

### 4.6 Builder `buildNarrativeEventSourcePickerOptions`

```dart
List<NarrativeEventSourcePickerOption> buildNarrativeEventSourcePickerOptions(
  ProjectManifest manifest, {
  Iterable<MapData> maps = const [],
}) {
  final mapEntriesById = <String, ProjectMapEntry>{
    for (final map in manifest.maps)
      if (map.id.trim().isNotEmpty) map.id.trim(): map,
  };
  final optionsBySourceId = <String, NarrativeEventSourcePickerOption>{};

  void add(NarrativeEventSourcePickerOption option) {
    optionsBySourceId.putIfAbsent(option.sourceId, () => option);
  }

  for (final mapEntry in manifest.maps) {
    final mapId = mapEntry.id.trim();
    if (mapId.isEmpty) {
      continue;
    }
    final mapLabel = _labelOrId(mapEntry.name, mapId);
    add(
      NarrativeEventSourcePickerOption(
        sourceId: 'mapEnter:$mapId',
        sourceKind: NarrativeEventSourceKind.mapEnter,
        humanLabel: 'Map enter: $mapLabel',
        mapId: mapId,
        mapLabel: mapLabel,
        entityId: '',
        entityLabel: '',
        triggerId: '',
        triggerLabel: '',
        outcomeId: '',
        debugTechnicalLabel: 'sourceMapEnter:$mapId',
      ),
    );
  }

  for (final map in maps) {
    final mapId = map.id.trim();
    if (mapId.isEmpty) {
      continue;
    }
    final mapLabel = _mapLabelFor(mapId, map.name, mapEntriesById);

    for (final trigger in map.triggers) {
      final triggerId = trigger.id.trim();
      if (triggerId.isEmpty) {
        continue;
      }
      final triggerLabel = _labelOrId(trigger.name, triggerId);
      add(
        NarrativeEventSourcePickerOption(
          sourceId: 'triggerEnter:$mapId:$triggerId',
          sourceKind: NarrativeEventSourceKind.triggerEnter,
          humanLabel: 'Trigger enter: $triggerLabel ($mapLabel)',
          mapId: mapId,
          mapLabel: mapLabel,
          entityId: '',
          entityLabel: '',
          triggerId: triggerId,
          triggerLabel: triggerLabel,
          outcomeId: '',
          debugTechnicalLabel: 'sourceTriggerEnter:$mapId:$triggerId',
        ),
      );
    }

    for (final entity in map.entities) {
      final entityId = entity.id.trim();
      if (entityId.isEmpty) {
        continue;
      }
      final entityLabel = _labelOrId(entity.inspectorHeadline, entityId);
      add(
        NarrativeEventSourcePickerOption(
          sourceId: 'entityInteract:$mapId:$entityId',
          sourceKind: NarrativeEventSourceKind.entityInteract,
          humanLabel: 'Entity interact: $entityLabel ($mapLabel)',
          mapId: mapId,
          mapLabel: mapLabel,
          entityId: entityId,
          entityLabel: entityLabel,
          triggerId: '',
          triggerLabel: '',
          outcomeId: '',
          debugTechnicalLabel: 'sourceEntityInteract:$mapId:$entityId',
        ),
      );
    }
  }

  for (final outcome in buildNarrativeOutcomePickerOptions(manifest)) {
    final outcomeId = outcome.outcomeId.trim();
    if (outcomeId.isEmpty) {
      continue;
    }
    add(
      NarrativeEventSourcePickerOption(
        sourceId: 'outcomeReceived:$outcomeId',
        sourceKind: NarrativeEventSourceKind.outcomeReceived,
        humanLabel: 'Outcome received: ${outcome.humanLabel}',
        mapId: '',
        mapLabel: '',
        entityId: '',
        entityLabel: '',
        triggerId: '',
        triggerLabel: '',
        outcomeId: outcomeId,
        debugTechnicalLabel: 'sourceOutcome:$outcomeId',
      ),
    );
  }

  final options = optionsBySourceId.values.toList(growable: false);
  options.sort((a, b) {
    final byKind = a.sourceKind.index.compareTo(b.sourceKind.index);
    if (byKind != 0) {
      return byKind;
    }
    final byLabel = _compareStringsCaseInsensitive(a.humanLabel, b.humanLabel);
    if (byLabel != 0) {
      return byLabel;
    }
    return _compareStringsCaseInsensitive(a.sourceId, b.sourceId);
  });
  return List<NarrativeEventSourcePickerOption>.unmodifiable(options);
}
```

Sources vérifiées :

```text
ProjectManifest.maps
MapData.triggers
MapData.entities
buildNarrativeOutcomePickerOptions(manifest)
```

### 4.7 Builder `buildNarrativePredicateReferencePickerOptions`

```dart
List<NarrativePredicateReferencePickerOption>
    buildNarrativePredicateReferencePickerOptions(ProjectManifest manifest) {
  final byKey = <String, _MutablePredicateReferencePickerOption>{};

  void add({
    required NarrativePredicateReferenceKind kind,
    required String referenceId,
    required String humanLabel,
    required String sourceScenarioId,
  }) {
    final id = referenceId.trim();
    if (id.isEmpty) {
      return;
    }
    final key = '${kind.name}:$id';
    byKey
        .putIfAbsent(
          key,
          () => _MutablePredicateReferencePickerOption(
            referenceId: id,
            referenceKind: kind,
            humanLabel: _labelOrId(humanLabel, id),
          ),
        )
        .addSourceScenarioId(sourceScenarioId);
  }

  for (final scenario in manifest.scenarios) {
    final scenarioId = scenario.id.trim();
    for (final flagName in _flagNamesForScenario(scenario)) {
      add(
        kind: NarrativePredicateReferenceKind.storyFlag,
        referenceId: flagName,
        humanLabel: _humanizeTechnicalId(flagName),
        sourceScenarioId: scenarioId,
      );
    }
  }

  for (final step in buildNarrativeStoryStepPickerOptions(manifest)) {
    add(
      kind: NarrativePredicateReferenceKind.storyStep,
      referenceId: step.stepId,
      humanLabel: step.humanLabel,
      sourceScenarioId: step.sourceScenarioId,
    );
  }

  for (final scenario in manifest.scenarios) {
    if (scenario.scope != ScenarioScope.localEventFlow) {
      continue;
    }
    add(
      kind: NarrativePredicateReferenceKind.cutscene,
      referenceId: scenario.id,
      humanLabel: _labelOrId(scenario.name, scenario.id),
      sourceScenarioId: scenario.id,
    );
  }

  for (final outcome in buildNarrativeOutcomePickerOptions(manifest)) {
    final outcomeId = outcome.outcomeId.trim();
    if (outcomeId.isEmpty) {
      continue;
    }
    final sourceScenarioIds = _dedupeAndSort([
      ...outcome.declaredByScenarioIds,
      ...outcome.emittedByScenarioIds,
      ...outcome.consumedByScenarioIds,
    ]);
    for (final scenarioId in sourceScenarioIds) {
      add(
        kind: NarrativePredicateReferenceKind.scenarioOutcome,
        referenceId: 'scenario.outcome.$outcomeId',
        humanLabel: 'Scenario outcome: ${outcome.humanLabel}',
        sourceScenarioId: scenarioId,
      );
    }
  }

  for (final battle in buildNarrativeBattleReferencePickerOptions(manifest)) {
    for (final outcomeKind in battle.supportedOutcomeKinds) {
      final suffix = outcomeKind.name;
      add(
        kind: NarrativePredicateReferenceKind.battleOutcome,
        referenceId: 'battle:${battle.battleId}:$suffix',
        humanLabel:
            '${_capitalizeFirst(_humanizeTechnicalId(battle.battleId))} $suffix',
        sourceScenarioId: battle.sourceScenarioId,
      );
    }
  }

  final options = byKey.values.map((entry) {
    return NarrativePredicateReferencePickerOption(
      referenceId: entry.referenceId,
      referenceKind: entry.referenceKind,
      humanLabel: entry.humanLabel,
      sourceScenarioIds: _dedupeAndSort(entry.sourceScenarioIds),
      debugTechnicalLabel: entry.referenceId,
    );
  }).toList(growable: false);

  options.sort((a, b) {
    final byKind = a.referenceKind.index.compareTo(b.referenceKind.index);
    if (byKind != 0) {
      return byKind;
    }
    final byLabel = _compareStringsCaseInsensitive(a.humanLabel, b.humanLabel);
    if (byLabel != 0) {
      return byLabel;
    }
    return _compareStringsCaseInsensitive(a.referenceId, b.referenceId);
  });
  return List<NarrativePredicateReferencePickerOption>.unmodifiable(options);
}
```

Sources vérifiées :

```text
flags via activationCondition / node binding / node payload condition / Step Studio metadata
story steps via buildNarrativeStoryStepPickerOptions
cutscenes via ScenarioScope.localEventFlow
scenario.outcome.* via buildNarrativeOutcomePickerOptions
battle:* via buildNarrativeBattleReferencePickerOptions
```

### 4.8 Helpers privés ajoutés vérifiés

Le fichier contient aussi les helpers privés ajoutés autour de ces builders :

```text
_MutablePredicateReferencePickerOption
_storyStepOptionsForScenario
_flagNamesForScenario
_flagNamesFromCondition
_flagNamesFromStepStudioMetadata
_mapLabelFor
_mapValue
_listValue
_idsFromObjectList
_stringValue
_intValue
_capitalizeFirst
```

Leur contenu a été relu avec :

```bash
sed -n '760,1120p' packages/map_core/lib/src/read_models/narrative_reference_picker_read_models.dart
```

## 5. Contenu vérifié des tests

Fichier vérifié :

```text
packages/map_core/test/narrative_reference_picker_read_models_test.dart
```

### 5.1 Test Step Studio metadata

```dart
test('builds story step picker options from Step Studio metadata', () {
  final options = buildNarrativeStoryStepPickerOptions(
    _manifest(
      scenarios: [
        _scenario(
          id: 'global_story',
          name: 'Global Story',
          scope: ScenarioScope.globalStory,
          declaredOutcomes: const [],
          metadata: {
            'authoring.stepStudioDocument': '''
{
  "schemaVersion": "step_studio_v1",
  "globalStoryScenarioId": "global_story",
  "steps": [
    {
      "id": "p4.step.second",
      "name": "Second Step",
      "description": "Follow-up",
      "order": 1,
      "activation": {"mode": "afterOutcome", "outcomeId": "p4.outcome.first.done"},
      "completion": {"mode": "whenOutcomeEmitted", "outcomeId": "p4.outcome.second.done"},
      "cutscenes": [{"cutsceneId": "p4_second_cutscene", "role": "main"}],
      "outcomes": [{"label": "Second done", "scope": "progression", "outcomeId": "p4.outcome.second.done"}]
    },
    {
      "id": "p4.step.first",
      "name": "First Step",
      "description": "Start here",
      "order": 0,
      "activation": {"mode": "atGameStart"},
      "completion": {"mode": "whenCutsceneEnds", "cutsceneId": "p4_first_cutscene"},
      "cutscenes": [{"cutsceneId": "p4_first_cutscene", "role": "main"}],
      "outcomes": [{"label": "First done", "scope": "progression", "outcomeId": "p4.outcome.first.done"}]
    }
  ]
}
''',
          },
        ),
      ],
    ),
  );

  expect(options.map((option) => option.stepId), [
    'p4.step.first',
    'p4.step.second',
  ]);

  final first = options.first;
  expect(first.humanLabel, 'First Step');
  expect(first.description, 'Start here');
  expect(first.sourceScenarioId, 'global_story');
  expect(first.sourceScenarioLabel, 'Global Story');
  expect(first.sourceKind, NarrativeStoryStepPickerSource.stepStudio);
  expect(first.order, 0);
  expect(first.linkedCutsceneIds, ['p4_first_cutscene']);
  expect(first.expectedOutcomeIds, isEmpty);
  expect(first.emittedOutcomeIds, ['p4.outcome.first.done']);
  expect(first.debugTechnicalLabel, 'global_story:p4.step.first');

  final second = options.last;
  expect(second.expectedOutcomeIds, ['p4.outcome.first.done']);
  expect(second.emittedOutcomeIds, ['p4.outcome.second.done']);
});
```

### 5.2 Test fallback legacy

```dart
test('dedupes story steps and keeps legacy metadata as fallback', () {
  final options = buildNarrativeStoryStepPickerOptions(
    _manifest(
      scenarios: [
        _scenario(
          id: 'global_story',
          name: 'Global Story',
          scope: ScenarioScope.globalStory,
          declaredOutcomes: const [],
          metadata: {
            'step.id': 'p4.legacy.step',
            'step.name': 'Legacy Step',
            'step.description': 'Legacy description',
            'step.cutsceneIds': 'cutscene_a, cutscene_b, cutscene_a',
          },
        ),
        _scenario(
          id: 'broken_story',
          name: 'Broken Story',
          scope: ScenarioScope.globalStory,
          declaredOutcomes: const [],
          metadata: const {
            'authoring.stepStudioDocument': '{broken json',
          },
        ),
      ],
    ),
  );

  expect(options, hasLength(1));
  expect(options.single.stepId, 'p4.legacy.step');
  expect(options.single.humanLabel, 'Legacy Step');
  expect(options.single.description, 'Legacy description');
  expect(
    options.single.sourceKind,
    NarrativeStoryStepPickerSource.legacyMetadata,
  );
  expect(options.single.linkedCutsceneIds, [
    'cutscene_a',
    'cutscene_b',
  ]);
});
```

### 5.3 Test Event Source

```dart
test('builds event source picker options from maps entities and outcomes',
    () {
  final options = buildNarrativeEventSourcePickerOptions(
    _manifest(
      maps: const [
        ProjectMapEntry(
          id: 'p4_map',
          name: 'P4 Test Map',
          relativePath: 'maps/p4_test_map.json',
        ),
      ],
      scenarios: [
        _scenario(
          id: 'source_scenario',
          declaredOutcomes: const ['p4.outcome.ready'],
          nodes: const [
            ScenarioNode(
              id: 'emit',
              type: ScenarioNodeType.action,
              binding: ScenarioNodeBinding(outcomeId: 'p4.outcome.ready'),
              payload: ScenarioNodePayload(actionKind: 'emitOutcome'),
            ),
          ],
          edges: const [],
        ),
      ],
    ),
    maps: [
      _mapData(
        id: 'p4_map',
        name: 'P4 Test Map Runtime',
        entities: const [
          MapEntity(
            id: 'p4_npc',
            name: 'Technical NPC',
            kind: MapEntityKind.npc,
            pos: GridPos(x: 2, y: 3),
            npc: MapEntityNpcData(displayName: 'P4 Guide'),
          ),
        ],
        triggers: const [
          MapTrigger(
            id: 'p4_trigger',
            name: 'P4 Trigger',
            type: TriggerType.event,
            area: MapRect(
              pos: GridPos(x: 1, y: 1),
              size: GridSize(width: 2, height: 2),
            ),
          ),
        ],
      ),
    ],
  );

  expect(options.map((option) => option.sourceKind), [
    NarrativeEventSourceKind.mapEnter,
    NarrativeEventSourceKind.triggerEnter,
    NarrativeEventSourceKind.entityInteract,
    NarrativeEventSourceKind.outcomeReceived,
  ]);

  final mapEnter = _byEventSourceKind(
    options,
    NarrativeEventSourceKind.mapEnter,
  );
  expect(mapEnter.sourceId, 'mapEnter:p4_map');
  expect(mapEnter.mapId, 'p4_map');
  expect(mapEnter.humanLabel, 'Map enter: P4 Test Map');

  final trigger = _byEventSourceKind(
    options,
    NarrativeEventSourceKind.triggerEnter,
  );
  expect(trigger.sourceId, 'triggerEnter:p4_map:p4_trigger');
  expect(trigger.triggerId, 'p4_trigger');
  expect(trigger.humanLabel, 'Trigger enter: P4 Trigger (P4 Test Map)');

  final entity = _byEventSourceKind(
    options,
    NarrativeEventSourceKind.entityInteract,
  );
  expect(entity.sourceId, 'entityInteract:p4_map:p4_npc');
  expect(entity.entityId, 'p4_npc');
  expect(entity.humanLabel, 'Entity interact: P4 Guide (P4 Test Map)');

  final outcome = _byEventSourceKind(
    options,
    NarrativeEventSourceKind.outcomeReceived,
  );
  expect(outcome.sourceId, 'outcomeReceived:p4.outcome.ready');
  expect(outcome.outcomeId, 'p4.outcome.ready');
  expect(outcome.humanLabel, 'Outcome received: p4 outcome ready');
});
```

### 5.4 Test Predicate Reference

```dart
test('builds predicate reference picker options from derived facts', () {
  final options = buildNarrativePredicateReferencePickerOptions(
    _manifest(
      scenarios: [
        _scenario(
          id: 'global_story',
          name: 'Global Story',
          scope: ScenarioScope.globalStory,
          declaredOutcomes: const [],
          activationCondition: ScriptConditionFactory.flagIsSet(
            'p4.flag.ready',
          ),
          metadata: {
            'authoring.stepStudioDocument': '''
{
  "schemaVersion": "step_studio_v1",
  "globalStoryScenarioId": "global_story",
  "steps": [
    {
      "id": "p4.step.ready",
      "name": "Ready Step",
      "description": "",
      "order": 0,
      "activation": {"mode": "whenFlagTrue", "flagName": "p4.flag.ready"},
      "completion": {"mode": "whenCutsceneEnds", "cutsceneId": "p4_cutscene"}
    }
  ]
}
''',
          },
          nodes: const [
            ScenarioNode(
              id: 'set_flag',
              type: ScenarioNodeType.action,
              binding: ScenarioNodeBinding(flagName: 'p4.flag.ready'),
              payload: ScenarioNodePayload(actionKind: 'setFlag'),
            ),
          ],
          edges: const [],
        ),
        _scenario(
          id: 'p4_cutscene',
          name: 'P4 Cutscene',
          declaredOutcomes: const ['p4.outcome.done'],
          nodes: const [
            ScenarioNode(
              id: 'emit',
              type: ScenarioNodeType.action,
              binding: ScenarioNodeBinding(outcomeId: 'p4.outcome.done'),
              payload: ScenarioNodePayload(actionKind: 'emitOutcome'),
            ),
            ScenarioNode(
              id: 'battle',
              type: ScenarioNodeType.action,
              binding: ScenarioNodeBinding(trainerId: 'p4_trainer'),
              payload: ScenarioNodePayload(
                actionKind: 'startTrainerBattle',
                params: {'battleId': 'p4_battle'},
              ),
            ),
          ],
          edges: const [],
        ),
      ],
    ),
  );

  expect(
    _byPredicateReference(
      options,
      NarrativePredicateReferenceKind.storyFlag,
      'p4.flag.ready',
    ).sourceScenarioIds,
    ['global_story'],
  );
  expect(
    _byPredicateReference(
      options,
      NarrativePredicateReferenceKind.storyStep,
      'p4.step.ready',
    ).humanLabel,
    'Ready Step',
  );
  expect(
    _byPredicateReference(
      options,
      NarrativePredicateReferenceKind.cutscene,
      'p4_cutscene',
    ).humanLabel,
    'P4 Cutscene',
  );
  expect(
    _byPredicateReference(
      options,
      NarrativePredicateReferenceKind.scenarioOutcome,
      'scenario.outcome.p4.outcome.done',
    ).sourceScenarioIds,
    ['p4_cutscene'],
  );
  expect(
    _byPredicateReference(
      options,
      NarrativePredicateReferenceKind.battleOutcome,
      'battle:p4_battle:victory',
    ).humanLabel,
    'P4 battle victory',
  );
  expect(
    _byPredicateReference(
      options,
      NarrativePredicateReferenceKind.battleOutcome,
      'battle:p4_battle:defeat',
    ).debugTechnicalLabel,
    'battle:p4_battle:defeat',
  );
});
```

### 5.5 Test cas vide

```dart
test('returns empty missing read model options for empty sources', () {
  final emptyManifest = _manifest(scenarios: const []);

  expect(buildNarrativeStoryStepPickerOptions(emptyManifest), isEmpty);
  expect(buildNarrativeEventSourcePickerOptions(emptyManifest), isEmpty);
  expect(
    buildNarrativePredicateReferencePickerOptions(emptyManifest),
    isEmpty,
  );
});
```

### 5.6 Helpers de test ajoutés

```dart
MapData _mapData({
  required String id,
  required String name,
  List<MapEntity> entities = const [],
  List<MapTrigger> triggers = const [],
}) {
  return MapData(
    id: id,
    name: name,
    size: const GridSize(width: 8, height: 8),
    entities: entities,
    triggers: triggers,
  );
}

NarrativeEventSourcePickerOption _byEventSourceKind(
  List<NarrativeEventSourcePickerOption> options,
  NarrativeEventSourceKind sourceKind,
) {
  return options.singleWhere((option) => option.sourceKind == sourceKind);
}

NarrativePredicateReferencePickerOption _byPredicateReference(
  List<NarrativePredicateReferencePickerOption> options,
  NarrativePredicateReferenceKind referenceKind,
  String referenceId,
) {
  return options.singleWhere(
    (option) =>
        option.referenceKind == referenceKind &&
        option.referenceId == referenceId,
  );
}
```

## 6. Exports publics vérifiés

`packages/map_core/lib/map_core.dart` exporte :

```dart
export 'src/read_models/narrative_reference_picker_read_models.dart';
```

Le fichier barrel n'a pas été modifié par P4-01-bis.

## 7. Tests relancés

### 7.1 Test P4-01 ciblé

```text
cd packages/map_core && dart test test/narrative_reference_picker_read_models_test.dart

00:00 +0: loading test/narrative_reference_picker_read_models_test.dart
00:00 +0: Narrative reference picker read models builds scenario picker options with stable labels and counts
00:00 +1: Narrative reference picker read models builds scenario picker options with stable labels and counts
00:00 +1: Narrative reference picker read models builds outcome picker options from declared emitted and consumed ids
00:00 +2: Narrative reference picker read models builds outcome picker options from declared emitted and consumed ids
00:00 +2: Narrative reference picker read models builds battle reference picker options from trainer battle nodes
00:00 +3: Narrative reference picker read models builds battle reference picker options from trainer battle nodes
00:00 +3: Narrative reference picker read models builds story step picker options from Step Studio metadata
00:00 +4: Narrative reference picker read models builds story step picker options from Step Studio metadata
00:00 +4: Narrative reference picker read models dedupes story steps and keeps legacy metadata as fallback
00:00 +5: Narrative reference picker read models dedupes story steps and keeps legacy metadata as fallback
00:00 +5: Narrative reference picker read models builds event source picker options from maps entities and outcomes
00:00 +6: Narrative reference picker read models builds event source picker options from maps entities and outcomes
00:00 +6: Narrative reference picker read models builds predicate reference picker options from derived facts
00:00 +7: Narrative reference picker read models builds predicate reference picker options from derived facts
00:00 +7: Narrative reference picker read models returns empty missing read model options for empty sources
00:00 +8: Narrative reference picker read models returns empty missing read model options for empty sources
00:00 +8: All tests passed!
```

### 7.2 Régression narrative validator

```text
cd packages/map_core && dart test test/narrative_validator_test.dart

00:00 +0: loading test/narrative_validator_test.dart
00:00 +0: Narrative Validator Minimal V0 valid minimal golden slice returns no diagnostics
00:00 +1: Narrative Validator Minimal V0 valid minimal golden slice returns no diagnostics
00:00 +1: Narrative Validator Minimal V0 unknown edge target produces error
00:00 +2: Narrative Validator Minimal V0 unknown edge target produces error
00:00 +2: Narrative Validator Minimal V0 unreachable node produces warning
00:00 +3: Narrative Validator Minimal V0 unreachable node produces warning
00:00 +3: Narrative Validator Minimal V0 scenario without source produces error
00:00 +4: Narrative Validator Minimal V0 scenario without source produces error
00:00 +4: Narrative Validator Minimal V0 openDialogue with unknown dialogue produces error
00:00 +5: Narrative Validator Minimal V0 openDialogue with unknown dialogue produces error
00:00 +5: Narrative Validator Minimal V0 startTrainerBattle with unknown trainer produces error
00:00 +6: Narrative Validator Minimal V0 startTrainerBattle with unknown trainer produces error
00:00 +6: Narrative Validator Minimal V0 startTrainerBattle with blank trainerId produces error
00:00 +7: Narrative Validator Minimal V0 startTrainerBattle with blank trainerId produces error
00:00 +7: Narrative Validator Minimal V0 startTrainerBattle with blank npcEntityId produces error
00:00 +8: Narrative Validator Minimal V0 startTrainerBattle with blank npcEntityId produces error
00:00 +8: Narrative Validator Minimal V0 startTrainerBattle with explicit blank battleId produces error
00:00 +9: Narrative Validator Minimal V0 startTrainerBattle with explicit blank battleId produces error
00:00 +9: Narrative Validator Minimal V0 source entityInteract with unknown map produces error
00:00 +10: Narrative Validator Minimal V0 source entityInteract with unknown map produces error
00:00 +10: Narrative Validator Minimal V0 source entityInteract with unknown entity produces error
00:00 +11: Narrative Validator Minimal V0 source entityInteract with unknown entity produces error
00:00 +11: Narrative Validator Minimal V0 sourceOutcome without matching emitOutcome produces warning
00:00 +12: Narrative Validator Minimal V0 sourceOutcome without matching emitOutcome produces warning
00:00 +12: Narrative Validator Minimal V0 emitOutcome without matching sourceOutcome produces warning
00:00 +13: Narrative Validator Minimal V0 emitOutcome without matching sourceOutcome produces warning
00:00 +13: Narrative Validator Minimal V0 declared outcome never emitted produces warning
00:00 +14: Narrative Validator Minimal V0 declared outcome never emitted produces warning
00:00 +14: Narrative Validator Minimal V0 emitOutcome not declared by scenario produces warning
00:00 +15: Narrative Validator Minimal V0 emitOutcome not declared by scenario produces warning
00:00 +15: Narrative Validator Minimal V0 conditional visibility rule without predicate produces error
00:00 +16: Narrative Validator Minimal V0 conditional visibility rule without predicate produces error
00:00 +16: Narrative Validator Minimal V0 world rule predicate with empty refId produces error
00:00 +17: Narrative Validator Minimal V0 world rule predicate with empty refId produces error
00:00 +17: Narrative Validator Minimal V0 choice node produces runtime unsupported warning
00:00 +18: Narrative Validator Minimal V0 choice node produces runtime unsupported warning
00:00 +18: Narrative Validator Minimal V0 setFlag used by condition does not warn as unused
00:00 +19: Narrative Validator Minimal V0 setFlag used by condition does not warn as unused
00:00 +19: Narrative Validator Minimal V0 completeStep used by world rule does not warn as unused
00:00 +20: Narrative Validator Minimal V0 completeStep used by world rule does not warn as unused
00:00 +20: Narrative Validator Minimal V0 diagnostics are stable and sorted deterministically
00:00 +21: Narrative Validator Minimal V0 diagnostics are stable and sorted deterministically
00:00 +21: All tests passed!
```

### 7.3 Analyze

```text
cd packages/map_core && dart analyze

Analyzing map_core...
No issues found!
```

### 7.4 Format check

```text
cd packages/map_core && dart format --set-exit-if-changed lib/src/read_models/narrative_reference_picker_read_models.dart test/narrative_reference_picker_read_models_test.dart

Formatted 2 files (0 changed) in 0.02 seconds.
```

## 8. Contrôles hors scope

Avant création du rapport P4-01-bis, le worktree était propre et les diffs ciblés étaient vides.

```text
git diff --name-only -- "MVP Selbrume/road_map_global.md"

git diff --name-only -- packages/map_editor packages/map_runtime packages/map_gameplay packages/map_battle examples/playable_runtime_host

git diff --name-only -- packages/map_core/lib/src/models packages/map_core/lib/src/operations packages/map_core/lib/src/validation

```

Les trois sorties sont vides.

Contrôles explicites :

```text
road_map_global.md non modifiée : oui
packages hors scope non modifiés : oui
modèles / operations / validation map_core non modifiés par le bis : oui
P4-02 non exécuté : oui
UI non créée : oui
registry non créé : oui
Selbrume final non créé : oui
rewards/money/XP non ajoutés : oui
```

## 9. Verdict sur la clôture de P4-01

```text
P4-01 : clôturable après correction documentaire.
P4-01-bis : validable.
Prochain lot exact : P4-02 — Scenario Authoring Draft Model V0.
```

## 10. Modifications effectuées

Fichier créé :

```text
reports/roadmap/phase_4/p4_01_bis_narrative_reference_picker_evidence_pack_completion.md
```

Fichiers non modifiés par ce bis :

```text
packages/map_core/lib/src/read_models/narrative_reference_picker_read_models.dart
packages/map_core/test/narrative_reference_picker_read_models_test.dart
packages/map_core/lib/map_core.dart
MVP Selbrume/road_map_phase_4.md
MVP Selbrume/road_map_global.md
```

## 11. Evidence Pack

### 11.1 git status initial exact

```text

```

### 11.2 Commandes exécutées

```bash
git status --short --untracked-files=all
sed -n '1,260p' reports/roadmap/phase_4/p4_01_narrative_reference_picker_coverage_missing_read_models.md
sed -n '1,760p' packages/map_core/lib/src/read_models/narrative_reference_picker_read_models.dart
sed -n '760,1120p' packages/map_core/lib/src/read_models/narrative_reference_picker_read_models.dart
sed -n '1,520p' packages/map_core/test/narrative_reference_picker_read_models_test.dart
sed -n '520,700p' packages/map_core/test/narrative_reference_picker_read_models_test.dart
sed -n '1,220p' packages/map_core/lib/map_core.dart
sed -n '1,260p' "MVP Selbrume/road_map_phase_4.md"
git log --oneline --decorate -5
git log --oneline -- reports/roadmap/phase_4/p4_01_narrative_reference_picker_coverage_missing_read_models.md packages/map_core/lib/src/read_models/narrative_reference_picker_read_models.dart packages/map_core/test/narrative_reference_picker_read_models_test.dart "MVP Selbrume/road_map_phase_4.md" | head -20
git show --stat --format=short 887e1c0d -- "MVP Selbrume/road_map_phase_4.md" packages/map_core/lib/src/read_models/narrative_reference_picker_read_models.dart packages/map_core/test/narrative_reference_picker_read_models_test.dart reports/roadmap/phase_4/p4_01_narrative_reference_picker_coverage_missing_read_models.md
cd packages/map_core && dart test test/narrative_reference_picker_read_models_test.dart
cd packages/map_core && dart test test/narrative_validator_test.dart
cd packages/map_core && dart analyze
cd packages/map_core && dart format --set-exit-if-changed lib/src/read_models/narrative_reference_picker_read_models.dart test/narrative_reference_picker_read_models_test.dart
git diff --check
git diff --stat
git diff --name-only
git status --short --untracked-files=all
git diff -- packages/map_core/lib/src/read_models/narrative_reference_picker_read_models.dart
git diff -- packages/map_core/test/narrative_reference_picker_read_models_test.dart
git diff -- "MVP Selbrume/road_map_phase_4.md"
git diff --name-only -- "MVP Selbrume/road_map_global.md"
git diff --name-only -- packages/map_editor packages/map_runtime packages/map_gameplay packages/map_battle examples/playable_runtime_host
git diff --name-only -- packages/map_core/lib/src/models packages/map_core/lib/src/operations packages/map_core/lib/src/validation
```

### 11.3 Commit P4-01 vérifié

```text
commit 887e1c0dadc43d93233f5415f6a0a72ea87a5008
Author: yoahn <yoahn.linard@papernest.com>

    Ajoute P4-01 : Narrative Reference Picker Coverage Missing Read Models (mises à jour et rapport)

 MVP Selbrume/road_map_phase_4.md                   |  40 +-
 .../narrative_reference_picker_read_models.dart    | 694 +++++++++++++++++++++
 ...arrative_reference_picker_read_models_test.dart | 373 ++++++++++-
 ...eference_picker_coverage_missing_read_models.md | 486 +++++++++++++++
 4 files changed, 1583 insertions(+), 10 deletions(-)
```

### 11.4 git diff --check exact avant rapport

```text

```

### 11.5 git diff --stat exact avant rapport

```text

```

### 11.6 git diff --name-only exact avant rapport

```text

```

### 11.7 git status final exact

```text
?? reports/roadmap/phase_4/p4_01_bis_narrative_reference_picker_evidence_pack_completion.md
```

### 11.8 git diff --check final exact

```text

```

### 11.9 git diff --stat final exact

```text

```

### 11.10 git diff --name-only final exact

```text

```

Note : ces sorties restent vides parce que le seul changement du bis est un fichier non suivi, donc absent de `git diff` tant qu'il n'est pas ajouté à l'index.

## 12. Auto-review critique

- Le rapport P4-01-bis existe au bon chemin : oui.
- Le bis a-t-il modifié du code ? non.
- Le bis a-t-il modifié des tests ? non.
- Le bis a-t-il modifié une roadmap ? non.
- Les preuves manquantes de P4-01 sont-elles fournies ? oui, sous forme de contenu vérifié et recopié.
- Les tests P4-01 repassent-ils ? oui.
- `dart analyze` est-il clean ? oui.
- P4-02 a-t-il été exécuté ? non.
- Une UI, un registry, Selbrume, rewards/money/XP ont-ils été créés ? non.
- Limite honnête : le diff complet du commit P4-01 n'est pas recopié intégralement dans ce rapport, car il représente 1583 insertions. Le rapport reproduit le minimum demandé quand le diff est très long : signatures publiques, classes/enums/builders ajoutés, tests ajoutés, helpers de test et sorties exactes de validation.
