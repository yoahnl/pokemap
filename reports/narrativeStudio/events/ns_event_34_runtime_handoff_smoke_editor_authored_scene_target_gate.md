# NS-EVENT-34 — Event Builder Runtime Handoff Smoke / Editor-authored Scene Target Gate

## 1. Résumé exécutif

Verdict :

```text
Runtime Handoff : PASS
```

Ce qui est prouvé :

- un `MapEventDefinition` construit par les opérations Event Builder peut être sérialisé dans un projet runtime sans transformation manuelle ;
- `loadRuntimeMapBundle(...)` relit ce projet et conserve `MapEventPage.sceneTarget` ;
- `PlayableMapGame` peut déclencher cet event par interaction joueur ;
- le runtime lit la page active et transmet la Scene cible à `SceneEventRuntimeHook` ;
- `SceneConsequence.setFact(...)` modifie `GameState.storyFlags.activeFlags` ;
- `SceneConsequence.markEventConsumed(...)` modifie `GameState.consumedEventIds` ;
- `RuntimeWorldRuleProjectionHook` observe ensuite les sources de state modifiées ;
- `SaveGameUseCase` puis `LoadGameUseCase` conservent le fact et l'event consommé.

Ce qui n'est pas encore prouvé :

- le déclenchement runtime réel de `MapEventType.triggerZone` par entrée de zone ;
- une sémantique runtime directe de `EventBuilderReusePolicy.oneShot/reusable` sans conséquence Scene explicite ;
- le passage complet par `examples/playable_runtime_host` ;
- une suite `packages/map_runtime/flutter test` entièrement verte : cinq échecs préexistants/non liés restent dans des tests eau/path-pattern et Selbrume P6.

Prochain lot recommandé :

```text
NS-EVENT-35 — Event Builder Trigger Variants Runtime Handoff / Lifecycle Semantics Gate
```

Blockers :

```text
Aucun blocker sur le handoff actor/object interaction -> Scene target -> GameState.
Réserves restantes sur triggerZone et lifecycle oneShot/reusable runtime-owned.
```

## 2. Usage du MCP Dart

MCP Dart demandé par le prompt. Recherche effectuée :

```bash
tool_search query="mcp__dart roots lsp dart analysis diagnostics references symbols"
```

Résultat : aucun outil MCP Dart callable n'était disponible dans cette session. Les vérifications ont donc été faites par :

- `rg` pour les références et symboles ;
- lecture directe des fichiers Dart ;
- tests CLI Flutter/Dart ;
- analyse ciblée CLI.

Symboles inspectés par lecture/CLI :

- `MapEventDefinition`
- `MapEventPage`
- `MapEventSceneTarget`
- `SceneAsset`
- `SceneConsequence`
- `SceneEventRuntimeHook`
- `SceneConsequenceRuntimeWriter`
- `SceneRuntimeExecutor`
- `GameState`
- `SaveGameUseCase`
- `LoadGameUseCase`
- `RuntimeWorldRuleProjectionHook`
- `createEventBuilderDraftEventOnMap`
- `setMapEventPageSceneTarget`
- `loadRuntimeMapBundle`
- `PlayableMapGame`

## 3. Sous-agents utilisés

Six sous-agents ont été utilisés, puis arbitrés par l'orchestrateur principal.

| Sous-agent | Mission | Conclusion utile |
|---|---|---|
| A — Runtime Event Handoff | Auditer la lecture runtime des `MapEventDefinition` avec `sceneTarget`. | `PlayableMapGame` lit les events, choisit la page active, puis appelle `_runSceneTargetForMapEvent(...)` et `SceneEventRuntimeHook.runForEventPage(...)`. Il manquait un smoke PlayableMapGame de bout en bout. |
| B — Scene Runtime / Consequences | Auditer `SceneRuntimeExecutor`, hook et writer. | `setFact` et `markEventConsumed` sont appliqués au `GameState` après exécution complète de Scene. `markEventConsumed` écrit un `eventId` nu. |
| C — Editor-authored Data Contract | Comparer ce que l'éditeur écrit et ce que runtime attend. | Le runtime consomme directement `id`, `position`, `pages`, `condition`, `sceneTarget`. Les metadata Event Builder ne bloquent pas le runtime. |
| D — World Rules / GameState Projection | Auditer projection World Rules et persistance. | Les sources `fact` et `consumedEvent` mutées par Scene sont observables par `RuntimeWorldRuleProjectionHook`. Save/load conserve les deux états dans le chemin testé. |
| E — Tests / Smoke Strategy | Proposer le plus petit smoke utile. | Recommandation : fixture temporaire disk-shaped `project.json` + map JSON, chargée par `loadRuntimeMapBundle`, puis interaction `PlayableMapGame`. |
| F — Reviewer contradictoire | Chercher scope creep et faux PASS. | PASS acceptable uniquement si le test traverse données persistées, runtime game, interaction, hook, `GameState`, projection et save/load. Refus de toute nouvelle mécanique. |

Arbitrage : le smoke retenu est plus fort qu'un test direct du hook, car il passe par le chargement projet/map runtime et l'interaction `PlayableMapGame`.

## 4. Audit initial

Gate 0 exécuté avant modification :

```bash
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git log --oneline -n 20
```

Sortie :

```text
/Users/karim/Project/pokemonProject
main
0b180895 NS-EVENT-33: Event Builder MVP Closure / End-to-End Authoring Readiness Gate - DONE
25cdf062 NS-EVENT-32: Event Builder World Rules Projection UX Closure / Validation Gate - DONE
972c73ad NS-EVENT-31: Implement Passive World Rules Projection UI V0 - DONE
a1480aeb NS-EVENT-30: Implement Passive World Rules Projection Read Model V0
3502ca74 NS-EVENT-29: Implement Linked Scene Consequences World Impact Projection Read Model V0
906809bb NS-EVENT-28: Polish Event Builder World Changes Read-only Projection UI
e13ebb6e NS-EVENT-27: Implement Event Builder Scene Outcomes and Lifecycle Projection UI V0
b7fce79e NS-EVENT-26: Implement Event Builder Scene Outcomes and Lifecycle Projection Read Model V0
36a8f362 NS-EVENT-25: Add outcomes, reactions, and consequences contract alignment audit report
8c2bb4b2 ns_event_v1: Ajout des composants de l'éditeur d'événements et rapports associés
54c59fba ns_event_16: Consolidation de la disposition des blocs et disponibilité de la création d'activation de carte
8b3866a8 ns_event_15: Ajout de l'auteur des types de déclencheurs pour les événements
8a5996be ns_event_14: Ajout des conditions de consommation d'événements
7f490b9e ns_event_13: Ajout de l'auteur des conditions de fait pour les événements
26bec474 ns_event_12: Ajout de l'auteur des comportements pour les événements
00698aea ns_event_11: Ajout de l'auteur des actions de scène pour les événements
fc0e0be0 ns_event_10: Ajout de la saisie du titre pour les brouillons d'événements
cdedbe6e ns_event_09: Fermeture du flux de création de brouillon
d3f1866f ns_event_08: Ajout du sélecteur de position explicite sur la carte pour la création de brouillon
30ae9429 ns_event_07: Ajout de l'entrée UI explicite pour la création de brouillon avec position
```

Notes :

- `git status --short --untracked-files=all` : vide au Gate 0 ;
- `git diff --stat` : vide au Gate 0 ;
- `git diff --name-only` : vide au Gate 0.

Worktree initial propre.

## 5. Runtime handoff contract

Contrat prouvé par le smoke :

```text
Event Builder authoring operations
-> MapData.events / MapEventDefinition.pages[0].sceneTarget
-> project.json + map JSON
-> loadRuntimeMapBundle(...)
-> PlayableMapGame.onLoad()
-> RuntimeInputControl.primary
-> MapEventPage.sceneTarget
-> SceneEventRuntimeHook.runForEventPage(...)
-> SceneRuntimeExecutor
-> SceneConsequenceRuntimeWriter
-> GameState
```

Surfaces runtime lues :

- `MapEventDefinition.id`
- `MapEventDefinition.type`
- `MapEventDefinition.position`
- `MapEventDefinition.pages`
- `MapEventPage.sceneTarget`
- `MapEventPage.condition`
- `MapEventPage.script`
- `MapEventPage.message`

Surfaces Event Builder présentes mais non bloquantes :

- `MapEventPage.metadata[eventBuilder.schemaVersion]`
- `MapEventPage.metadata[eventBuilder.reusePolicy]`

Décision : aucun adaptateur spécial n'est requis pour un event interaction avec Scene cible.

## 6. Editor-authored data fixture

Fixture construite dans le test :

```text
MapData
- id: map_ns_event_34_port
- spawn playerStart: (0, 0), facing east
- object layer: objects

Event Builder operation
- createEventBuilderDraftEventOnMap(...)
- title: Runtime handoff
- position: layer objects, x 1, y 0
- type: actor
- reusePolicy: oneShot

Scene action authoring operation
- setMapEventPageSceneTarget(..., sceneId: scene_ns_event_34_handoff)

Stable id for test
- updateMapEventOnMap(..., id: evt_runtime_handoff)

SceneAsset
- start
- action SceneConsequence.setFact(fact_ns_event_34_scene_started, true)
- action SceneConsequence.markEventConsumed(map_ns_event_34_port, evt_runtime_handoff)
- end

World Rules
- fact true -> map event enabled
- consumed event -> map event enabled
```

Le test relit ensuite le JSON persisté pour vérifier que `sceneTarget.sceneId` existe dans la map écrite.

## 7. Smoke test strategy

Choix retenu :

```text
packages/map_runtime/test/ns_event_34_scene_target_handoff_smoke_test.dart
```

Raisons :

- `map_runtime` possède `PlayableMapGame`, `loadRuntimeMapBundle`, le hook Scene et les save use cases ;
- le test prouve un chemin runtime réel sans dépendre d'une fixture Selbrume ;
- le test reste petit et déterministe ;
- aucune UI editor n'est ouverte ;
- aucune nouvelle mécanique runtime n'est ajoutée.

Choix non retenus :

- test direct `SceneEventRuntimeHook` seulement : trop faible pour prouver le handoff `MapEventDefinition.sceneTarget` ;
- test `examples/playable_runtime_host` : utile plus tard, mais plus lourd et moins ciblé ;
- modification Selbrume : hors scope.

## 8. Tests ajoutés/modifiés

Fichier créé :

```text
packages/map_runtime/test/ns_event_34_scene_target_handoff_smoke_test.dart
```

Aucun fichier de production modifié.

Aucun fichier `map_core`, `map_editor`, `map_gameplay`, `map_battle`, `examples`, `assets`, `selbrume` ou `pubspec.yaml` modifié.

## 9. Résultat du smoke

Commande finale :

```bash
cd packages/map_runtime
/opt/homebrew/share/flutter/bin/flutter test --reporter=compact test/ns_event_34_scene_target_handoff_smoke_test.dart --name "NS-EVENT-34"
```

Résultat :

```text
00:02 +1: All tests passed!
```

Signaux runtime observés dans la sortie :

```text
Bundle load completed
[interact] MapEvent: evt_runtime_handoff page=0
[scene_runtime] event=evt_runtime_handoff page=0 status=completed scene=scene_ns_event_34_handoff message=-
Save file written
Game loaded from save
```

## 10. GameState / consequences evidence

Assertions clés du test :

```dart
expect(updatedState.storyFlags.activeFlags, contains(_factId));
expect(updatedState.consumedEventIds, contains(_eventId));
expect(updatedState.currentMapId, _mapId);
```

Ces assertions prouvent :

- `SceneConsequence.setFact(...)` écrit dans `GameState.storyFlags.activeFlags` ;
- `SceneConsequence.markEventConsumed(...)` écrit dans `GameState.consumedEventIds` ;
- l'exécution ne change pas de map de manière inattendue.

## 11. Save/load audit

Le smoke utilise :

```dart
SaveGameUseCase(saveRepository).execute(updatedState)
LoadGameUseCase(saveRepository).execute()
normalizeLoadedGameState(...)
```

Assertions :

```dart
expect(normalizedReloaded.storyFlags.activeFlags, contains(_factId));
expect(normalizedReloaded.consumedEventIds, contains(_eventId));
```

Décision : le chemin save/load testé conserve les sources narratives nécessaires au handoff.

Limite : aucun refactor save/load n'a été fait, et aucun test `examples/playable_runtime_host` n'a été ajouté.

## 12. World Rules runtime projection audit

Le smoke utilise `RuntimeWorldRuleProjectionHook` sur le `GameState` muté :

```dart
final projection = const RuntimeWorldRuleProjectionHook().resolve(
  project: bundle.manifest,
  gameState: updatedState,
  map: bundle.map,
);
expect(projection.enabledEventIds, contains(_eventId));
```

Décision : les sources modifiées par Scene consequences sont observables par le moteur de projection World Rules existant.

Limite : le test ne simule pas d'effet visuel complet dans une app host, il vérifie la projection runtime pure exposée par le hook.

## 13. Verdict Runtime Handoff : PASS

```text
Runtime Handoff : PASS
```

Justification :

- le handoff authoring -> JSON -> runtime bundle -> interaction -> Scene hook -> GameState est prouvé ;
- le chemin de consequences `setFact` et `markEventConsumed` est prouvé ;
- la projection World Rules runtime observe les mutations ;
- save/load conserve les mutations ;
- aucune feature nouvelle n'a été ajoutée.

Réserves :

- `triggerZone` runtime reste à prouver ;
- `oneShot/reusable` reste metadata authoring/lifecycle intention, pas enforcement runtime autonome dans ce smoke ;
- la full suite `packages/map_runtime` a encore cinq échecs non liés.

## 14. Non-objectifs respectés

Confirmé :

- pas de drag/drop ;
- pas d'authoring outcome ;
- pas d'authoring reaction ;
- pas d'authoring World Rule ;
- pas de `EventReaction` ;
- pas de `EventOutcome` ;
- pas de nouveau `SceneConsequenceKind` ;
- pas de `completeStep` ;
- pas de `giveItem` ;
- pas de refonte `GameState` ;
- pas de refonte save/load ;
- pas de refonte `SceneRuntimeExecutor` ;
- pas de refonte World Rule engine ;
- pas de modification Selbrume ;
- pas de modification `project.json` final ;
- pas de build_runner ;
- pas de generated files ;
- pas de commit.

## 15. Risques résiduels

| Risque | Gravité | Décision |
|---|---|---|
| `triggerZone` authorable mais non prouvé comme entrée de zone runtime. | Medium | À traiter dans NS-EVENT-35. |
| `EventBuilderReusePolicy.oneShot/reusable` non appliqué directement par runtime. | Medium | À clarifier : lifecycle metadata ou runtime policy réelle. |
| `markEventConsumed` stocke un `eventId` nu. | Low/Medium | Risque de collision si plusieurs maps ont le même event id ; à auditer avant contenu multi-map massif. |
| Full `map_runtime` suite rouge sur tests non liés. | Medium | À ne pas bloquer NS-EVENT-34, mais à traiter séparément. |
| Aucun smoke playable host complet. | Low/Medium | Futur lot host si besoin beta. |

## 16. Prochain lot recommandé

```text
NS-EVENT-35 — Event Builder Trigger Variants Runtime Handoff / Lifecycle Semantics Gate
```

Objectif recommandé :

- prouver ou borner `actor`, `object`, `triggerZone` côté runtime ;
- décider si `EventBuilderReusePolicy.oneShot/reusable` doit rester une intention authoring ou devenir un contrat runtime ;
- éviter de créer une deuxième lifecycle policy concurrente avec `SceneConsequence.markEventConsumed`.

Non-objectifs recommandés pour NS-EVENT-35 :

- pas de drag/drop ;
- pas d'Event-owned reactions/outcomes ;
- pas de nouvelle SceneConsequence ;
- pas de refonte runtime.

## 17. Evidence Pack

### Règles et fichiers lus

Règles :

- `AGENTS.md`
- `agent_rules.md`
- `codex_rule.md`
- `skills/README.md`
- `skills/using-superpowers/SKILL.md`
- `skills/test-driven-development/SKILL.md`
- `skills/verification-before-completion/SKILL.md`
- `skills/subagent-driven-development/SKILL.md`
- `skills/systematic-debugging/SKILL.md`

Rapports :

- `reports/narrativeStudio/events/ns_event_25_outcomes_reactions_consequences_contract_alignment_audit.md`
- `reports/narrativeStudio/events/ns_event_29_linked_scene_consequences_world_impact_projection_v0.md`
- `reports/narrativeStudio/events/ns_event_30_passive_world_rules_projection_read_model_v0.md`
- `reports/narrativeStudio/events/ns_event_31_passive_world_rules_projection_ui_v0.md`
- `reports/narrativeStudio/events/ns_event_32_world_rules_projection_ux_closure_validation_gate.md`
- `reports/narrativeStudio/events/ns_event_33_event_builder_mvp_closure_readiness_gate.md`

Code et tests principaux :

- `packages/map_core/lib/src/models/map_event_definition.dart`
- `packages/map_core/lib/src/models/scene_asset.dart`
- `packages/map_core/lib/src/models/scene_consequence.dart`
- `packages/map_core/lib/src/models/world_rule.dart`
- `packages/map_core/lib/src/models/game_state.dart`
- `packages/map_core/lib/src/read_models/event_builder_read_model.dart`
- `packages/map_core/lib/src/authoring/event_builder_authoring_operations.dart`
- `packages/map_core/test/event_builder_authoring_operations_test.dart`
- `packages/map_core/test/event_builder_read_model_test.dart`
- `packages/map_core/test/scene_consequence_model_test.dart`
- `packages/map_runtime/lib/src/application/playable_map_game.dart`
- `packages/map_runtime/lib/src/application/scene_runtime/scene_event_runtime_hook.dart`
- `packages/map_runtime/lib/src/application/scene_runtime/scene_consequence_runtime_writer.dart`
- `packages/map_runtime/lib/src/application/world_rules/runtime_world_rule_projection_hook.dart`
- `packages/map_runtime/lib/src/application/save_game_use_case.dart`
- `packages/map_runtime/lib/src/application/load_game_use_case.dart`
- `packages/map_runtime/test/scene_event_runtime_hook_test.dart`
- `packages/map_runtime/test/scene_runtime_state_persistence_gate_test.dart`
- `packages/map_runtime/test/world_rules_runtime_projection_hook_test.dart`
- `packages/map_runtime/test/scene_consequence_runtime_writer_test.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/test/event_builder_workspace_test.dart`

### Commandes de recherche utiles

```bash
rg -n "sceneTarget|SceneEventRuntimeHook|runForEventPage|_tryInteractWithMapEvent|_handleMapEventInteraction|_runSceneTargetForMapEvent" packages/map_runtime packages/map_core packages/map_editor
rg -n "SceneConsequence|markEventConsumed|setFact|RuntimeWorldRuleProjectionHook|SaveGameUseCase|LoadGameUseCase" packages/map_runtime packages/map_core
rg --files packages/map_runtime/test | rg -i "scene|world|save|event|runtime"
```

### RED initial

Commande avant création du test :

```bash
cd packages/map_runtime
/Users/karim/develop/flutter/bin/flutter test --reporter=compact test/ns_event_34_scene_target_handoff_smoke_test.dart --name "NS-EVENT-34"
```

Résultat :

```text
Failed to load "test/ns_event_34_scene_target_handoff_smoke_test.dart": Does not exist.
```

Après première version du test, erreurs corrigées dans le test uniquement :

```text
RuntimeWorldRuleProjectionState has no getter effects.
ProjectManifest requires tilesets.
Non-const constructors used in const list.
```

### Fichier créé : contenu complet

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;

const _mapId = 'map_ns_event_34_port';
const _eventId = 'evt_runtime_handoff';
const _sceneId = 'scene_ns_event_34_handoff';
const _factId = 'fact_ns_event_34_scene_started';
const _factRuleId = 'rule_ns_event_34_fact_projection';
const _consumedRuleId = 'rule_ns_event_34_consumed_projection';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NS-EVENT-34 runtime handoff smoke', () {
    test('runtime consumes editor-authored scene target event', () async {
      final root = await Directory.systemTemp.createTemp(
        'ns_event_34_scene_target_handoff_',
      );
      addTearDown(() async {
        if (await root.exists()) {
          await root.delete(recursive: true);
        }
      });

      final fixture = _editorAuthoredFixture();
      final projectFilePath = await _writeRuntimeProject(
        root,
        project: fixture.project,
        map: fixture.map,
      );

      final persistedProject = jsonDecode(
        await File(projectFilePath).readAsString(),
      ) as Map<String, dynamic>;
      final persistedMap = jsonDecode(
        await File(p.join(root.path, 'maps', '$_mapId.json')).readAsString(),
      ) as Map<String, dynamic>;

      expect((persistedProject['scenes'] as List<Object?>), hasLength(1));
      expect(
        (((persistedMap['events'] as List<Object?>).single
                as Map<String, dynamic>)['pages'] as List<Object?>)
            .single as Map<String, dynamic>,
        containsPair(
          'sceneTarget',
          containsPair('sceneId', _sceneId),
        ),
      );

      final bundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: _mapId,
      );
      final loadedEvent = bundle.map.events.single;
      expect(loadedEvent.id, _eventId);
      expect(loadedEvent.pages.single.sceneTarget?.sceneId, _sceneId);
      expect(loadedEvent.pages.single.script, isNull);
      expect(loadedEvent.pages.single.message, isNull);
      expect(
        loadedEvent.pages.single.metadata[EventBuilderMetadataKeys.reusePolicy],
        EventBuilderReusePolicy.oneShot.name,
      );

      final saveRepository = _TempFileGameSaveRepository(root);
      final game = _TestPlayableMapGame(
        bundle: bundle,
        projectFilePath: projectFilePath,
        saveRepository: saveRepository,
      );

      game.onGameResize(_testViewportSize);
      await game.onLoad();

      expect(game.debugFlowPhaseName, 'overworld');
      expect(game.debugPlayerGridPosition, const GridPos(x: 0, y: 0));

      expect(
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.press(RuntimeInputControl.primary),
        ),
        isTrue,
      );

      await _pumpUntil(
        game,
        () =>
            game.gameStateSnapshot.storyFlags.activeFlags.contains(_factId) &&
            game.gameStateSnapshot.consumedEventIds.contains(_eventId),
      );

      final updatedState = game.gameStateSnapshot;
      expect(updatedState.storyFlags.activeFlags, contains(_factId));
      expect(updatedState.consumedEventIds, contains(_eventId));
      expect(updatedState.currentMapId, _mapId);

      final projection = const RuntimeWorldRuleProjectionHook().resolve(
        project: bundle.manifest,
        gameState: updatedState,
        map: bundle.map,
      );
      expect(projection.enabledEventIds, contains(_eventId));

      expect(
        await SaveGameUseCase(saveRepository).execute(updatedState),
        isTrue,
      );
      final reloaded = await LoadGameUseCase(saveRepository).execute();
      expect(reloaded, isNotNull);
      final normalizedReloaded = normalizeLoadedGameState(reloaded!);
      expect(normalizedReloaded.storyFlags.activeFlags, contains(_factId));
      expect(normalizedReloaded.consumedEventIds, contains(_eventId));
    });
  });
}

_RuntimeHandoffFixture _editorAuthoredFixture() {
  const baseMap = MapData(
    id: _mapId,
    name: 'NS-EVENT-34 Port',
    size: GridSize(width: 3, height: 3),
    layers: <MapLayer>[
      MapLayer.object(id: 'objects', name: 'Objects'),
    ],
    entities: <MapEntity>[
      MapEntity(
        id: 'spawn_ns_event_34',
        name: 'Spawn NS-EVENT-34',
        kind: MapEntityKind.spawn,
        pos: GridPos(x: 0, y: 0),
        blocksMovement: false,
        spawn: MapEntitySpawnData(
          role: EntitySpawnRole.playerStart,
          facing: EntityFacing.east,
        ),
      ),
    ],
    mapMetadata: MapMetadata(defaultSpawnId: 'spawn_ns_event_34'),
  );

  final draft = createEventBuilderDraftEventOnMap(
    baseMap,
    title: 'Runtime handoff',
    position: const EventPosition(layerId: 'objects', x: 1, y: 0),
    type: MapEventType.actor,
    reusePolicy: EventBuilderReusePolicy.oneShot,
  );
  var map = setMapEventPageSceneTarget(
    draft.updatedMap,
    eventId: draft.createdEvent.id,
    pageNumber: 0,
    sceneId: _sceneId,
  );
  map = updateMapEventOnMap(
    map,
    eventId: draft.createdEvent.id,
    id: _eventId,
  );
  final event = map.events.singleWhere((candidate) => candidate.id == _eventId);

  final project = ProjectManifest(
    name: 'NS-EVENT-34 Runtime Handoff',
    settings: const ProjectSettings(tileWidth: 16, tileHeight: 16),
    maps: const <ProjectMapEntry>[
      ProjectMapEntry(
        id: _mapId,
        name: 'NS-EVENT-34 Port',
        relativePath: 'maps/$_mapId.json',
      ),
    ],
    tilesets: const <ProjectTilesetEntry>[],
    facts: <NarrativeFactDefinition>[
      NarrativeFactDefinition(
        id: _factId,
        label: 'Scene runtime handoff started',
      ),
    ],
    worldRules: <WorldRuleDefinition>[
      WorldRuleDefinition(
        id: _factRuleId,
        label: 'Fact projects world impact',
        source: const WorldRuleSource(
          kind: WorldRuleSourceKind.fact,
          sourceId: _factId,
          predicate: WorldRuleSourcePredicate.isTrue,
        ),
        target: const WorldRuleTarget(
          kind: WorldRuleTargetKind.mapEvent,
          mapId: _mapId,
          eventId: _eventId,
        ),
        effect: const WorldRuleEffect(kind: WorldRuleEffectKind.eventEnabled),
        priority: 0,
      ),
      WorldRuleDefinition(
        id: _consumedRuleId,
        label: 'Consumed event projects world impact',
        source: const WorldRuleSource(
          kind: WorldRuleSourceKind.consumedEvent,
          sourceId: _eventId,
          predicate: WorldRuleSourcePredicate.consumed,
        ),
        target: const WorldRuleTarget(
          kind: WorldRuleTargetKind.mapEvent,
          mapId: _mapId,
          eventId: _eventId,
        ),
        effect: const WorldRuleEffect(kind: WorldRuleEffectKind.eventEnabled),
        priority: 1,
      ),
    ],
    scenes: <SceneAsset>[
      _handoffScene(),
    ],
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
  );

  return _RuntimeHandoffFixture(
    project: project,
    map: map,
    event: event,
  );
}

SceneAsset _handoffScene() {
  return SceneAsset(
    id: _sceneId,
    name: 'NS-EVENT-34 handoff scene',
    graph: SceneGraph(
      startNodeId: 'node_start',
      nodes: <SceneNode>[
        SceneNode(id: 'node_start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'node_set_fact',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.consequence(
            SceneConsequence.setFact(factId: _factId, value: true),
          ),
        ),
        SceneNode(
          id: 'node_mark_event_consumed',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.consequence(
            SceneConsequence.markEventConsumed(
              mapId: _mapId,
              eventId: _eventId,
            ),
          ),
        ),
        SceneNode(id: 'node_end', kind: SceneNodeKind.end),
      ],
      edges: <SceneEdge>[
        SceneEdge(
          id: 'edge_start_set_fact',
          fromNodeId: 'node_start',
          fromPortId: 'completed',
          toNodeId: 'node_set_fact',
          kind: SceneEdgeKind.defaultFlow,
        ),
        SceneEdge(
          id: 'edge_set_fact_mark_event',
          fromNodeId: 'node_set_fact',
          fromPortId: 'completed',
          toNodeId: 'node_mark_event_consumed',
          kind: SceneEdgeKind.actionCompleted,
        ),
        SceneEdge(
          id: 'edge_mark_event_end',
          fromNodeId: 'node_mark_event_consumed',
          fromPortId: 'completed',
          toNodeId: 'node_end',
          kind: SceneEdgeKind.actionCompleted,
        ),
      ],
    ),
  );
}

Future<String> _writeRuntimeProject(
  Directory root, {
  required ProjectManifest project,
  required MapData map,
}) async {
  final mapsDir = Directory(p.join(root.path, 'maps'));
  await mapsDir.create(recursive: true);
  await File(p.join(mapsDir.path, '$_mapId.json')).writeAsString(
    const JsonEncoder.withIndent('  ').convert(map.toJson()),
  );
  final projectFile = File(p.join(root.path, 'project.json'));
  await projectFile.writeAsString(
    const JsonEncoder.withIndent('  ').convert(project.toJson()),
  );
  return projectFile.path;
}

final _testViewportSize = Vector2(640, 480);

Future<void> _pumpUntil(
  PlayableMapGame game,
  bool Function() done, {
  int maxTicks = 240,
}) async {
  for (var i = 0; i < maxTicks; i++) {
    if (done()) {
      return;
    }
    game.update(0.016);
    await Future<void>.delayed(Duration.zero);
  }
  fail('Timed out waiting for the NS-EVENT-34 runtime smoke to settle.');
}

final class _RuntimeHandoffFixture {
  const _RuntimeHandoffFixture({
    required this.project,
    required this.map,
    required this.event,
  });

  final ProjectManifest project;
  final MapData map;
  final MapEventDefinition event;
}

class _TestPlayableMapGame extends PlayableMapGame {
  _TestPlayableMapGame({
    required super.bundle,
    required super.projectFilePath,
    required super.saveRepository,
  });

  @override
  bool get isLoaded => true;
}

class _TempFileGameSaveRepository extends FileGameSaveRepository {
  _TempFileGameSaveRepository(this._testDirectory);

  final Directory _testDirectory;

  @override
  Future<String> getSaveFilePath() async {
    final saveDir = Directory(p.join(_testDirectory.path, 'pokemonProject'));
    if (!await saveDir.exists()) {
      await saveDir.create(recursive: true);
    }
    return p.join(saveDir.path, 'game_save.json');
  }
}
```

### Validations exécutées

Analyse ciblée du nouveau test :

```bash
cd packages/map_runtime
/opt/homebrew/share/flutter/bin/flutter analyze --no-fatal-infos test/ns_event_34_scene_target_handoff_smoke_test.dart
```

Résultat :

```text
Analyzing ns_event_34_scene_target_handoff_smoke_test.dart...
No issues found! (ran in 1.2s)
```

Smoke NS-EVENT-34 :

```bash
cd packages/map_runtime
/opt/homebrew/share/flutter/bin/flutter test --reporter=compact test/ns_event_34_scene_target_handoff_smoke_test.dart --name "NS-EVENT-34"
```

Résultat :

```text
00:02 +1: All tests passed!
```

Régression runtime ciblée :

```bash
cd packages/map_runtime
/opt/homebrew/share/flutter/bin/flutter test --reporter=compact \
  test/ns_event_34_scene_target_handoff_smoke_test.dart \
  test/scene_event_runtime_hook_test.dart \
  test/scene_runtime_state_persistence_gate_test.dart \
  test/world_rules_runtime_projection_hook_test.dart \
  test/scene_consequence_runtime_writer_test.dart
```

Résultat :

```text
00:03 +51: All tests passed!
```

Régressions core Event Builder :

```bash
cd packages/map_core
/Users/karim/develop/flutter/bin/dart test --reporter=compact \
  test/event_builder_contract_test.dart \
  test/event_builder_authoring_operations_test.dart \
  test/event_builder_read_model_test.dart \
  test/scene_consequence_model_test.dart
```

Résultat :

```text
00:01 +60: All tests passed!
```

Régression editor authoring gate :

```bash
cd packages/map_editor
/opt/homebrew/share/flutter/bin/flutter test --reporter=compact test/event_builder_workspace_test.dart --name "NS-EVENT-33"
```

Résultat :

```text
00:16 +4: All tests passed!
```

Note outil : une première tentative avec `/Users/karim/develop/flutter/bin/flutter` a échoué sur une API Flutter plus récente utilisée par l'éditeur :

```text
lib/src/ui/canvas/storylines/storylines_structure_view.dart:577:13: Error: No named parameter with the name 'onReorderItem'.
```

La validation editor a donc été relancée avec `/opt/homebrew/share/flutter/bin/flutter`, cohérent avec le Flutter local plus récent.

Full suite `map_runtime` :

```bash
cd packages/map_runtime
/opt/homebrew/share/flutter/bin/flutter test --reporter=compact
```

Résultat : échec avec cinq tests non liés au fichier ajouté.

Résumé machine parsé :

```text
FAILURE_COUNT 5
--- FAILURE 1 ---
TEST: golden slice eau 2x2 animée depuis JSON dans MapLayersComponent
ERROR:
Expected: [255, 0, 255, 255]
  Actual: [255, 0, 0, 255]
   Which: at location [2] is <0> instead of <255>
--- FAILURE 2 ---
TEST: P6-05 builds Grant trainer battle setup and persists a controlled victory outcome
ERROR:
Expected: ['bulbasaur', 'metapod', 'ivysaur']
  Actual: ['bulbasaur', 'dratini', 'ivysaur']
--- FAILURE 3 ---
TEST: P6-01 loads repo-local Selbrume and builds New Game from explicit Selbrume spawn
ERROR:
Expected: null
  Actual: 'spawn'
--- FAILURE 4 ---
TEST: P6-07 validates repo-local Selbrume golden slice with no beta blocker
ERROR:
Expected: ['bulbasaur', 'metapod', 'ivysaur']
  Actual: ['bulbasaur', 'dratini', 'ivysaur']
--- FAILURE 5 ---
TEST: MapLayersComponent PathPattern runtime render centerPattern animé change de frame selon elapsedMs
ERROR:
Expected: [0, 0, 255, 255]
  Actual: [255, 0, 0, 255]
SUMMARY: {'success': False, 'type': 'done', 'time': 66355}
```

Décision : ces cinq échecs ne touchent pas le smoke NS-EVENT-34, le Scene runtime hook, les consequences, les World Rules ou le fichier ajouté.

Build macOS debug :

```text
Non exécuté : aucun runtime host ni code produit n'a été modifié. Le lot ajoute uniquement un test runtime et un rapport.
```

### Fichiers créés/modifiés/supprimés

Créés :

- `packages/map_runtime/test/ns_event_34_scene_target_handoff_smoke_test.dart`
- `reports/narrativeStudio/events/ns_event_34_runtime_handoff_smoke_editor_authored_scene_target_gate.md`

Modifiés :

- aucun fichier existant.

Supprimés :

- aucun.

### Anti-scope

Résultat vérifié en fin de lot :

```text
git diff --name-only -- packages/map_editor packages/map_core examples assets selbrume pubspec.yaml
<vide>

git diff --name-only -- packages/map_battle packages/map_gameplay
<vide>
```

### Gate final exact

```bash
git status --short --untracked-files=all
```

```text
?? packages/map_runtime/test/ns_event_34_scene_target_handoff_smoke_test.dart
?? reports/narrativeStudio/events/ns_event_34_runtime_handoff_smoke_editor_authored_scene_target_gate.md
```

```bash
git diff --stat
```

```text
<vide>
```

```bash
git diff --name-only
```

```text
<vide>
```

```bash
git diff --check
```

```text
<vide>
```

```bash
git diff --name-only -- packages/map_editor packages/map_core examples assets selbrume pubspec.yaml
```

```text
<vide>
```

```bash
git diff --name-only -- packages/map_battle packages/map_gameplay
```

```text
<vide>
```

## 18. Auto-review critique

Checklist indépendante :

- Le lot prouve un chemin runtime réel : oui, via `PlayableMapGame`.
- Le test utilise des données authorées par les opérations Event Builder : oui.
- Le test relit les JSON runtime : oui.
- `SceneConsequence.setFact` est prouvé jusqu'à `GameState` : oui.
- `SceneConsequence.markEventConsumed` est prouvé jusqu'à `GameState` : oui.
- Save/load est inclus sans refactor : oui.
- World Rules sont observées sans simulation editor : oui.
- Aucun code produit n'est modifié : oui.
- Aucun Event outcome/reaction n'est ajouté : oui.
- Aucun nouveau `SceneConsequenceKind` n'est ajouté : oui.
- Le verdict ne cache pas les réserves `triggerZone` / lifecycle : oui.

Point de vigilance : le test est volontairement une fixture minimale, pas une preuve beta complète du playable host.

## 19. Critique du prompt

Le prompt est ambitieux mais justifié : demander handoff, consequences, save/load et World Rule projection dans un même lot aurait pu déraper vers une refonte runtime. Le découpage reste acceptable parce que le repo possédait déjà tous les hooks nécessaires.

La partie "save/load si déjà disponible" est saine : elle évite de forcer une refonte. Ici le chemin existait, donc il a été inclus.

La partie "World Rule projection observable si déjà branchée" est également saine : le test observe le hook runtime existant, sans créer de moteur ni simuler des règles côté Event Builder.

La limite principale du prompt est qu'il pourrait laisser croire que tous les types de trigger sont couverts. Ce lot prouve le chemin interaction face au joueur, pas l'entrée de zone. Le prochain lot devrait donc traiter explicitement les variantes de trigger et la sémantique lifecycle.
