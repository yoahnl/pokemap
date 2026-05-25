# P3-06 — Save/Load Narrative State Roundtrip Validation

## 1. Résumé exécutif

P3-06 a produit une preuve exécutable ciblée que les vérités narratives
techniques utilisées par P3-02 à P3-05 survivent à un roundtrip save/load disque
réel, puis restent lisibles par les projections runtime existantes.

Livrables :

- test ciblé créé :
  `packages/map_runtime/test/p3_save_load_narrative_state_roundtrip_test.dart` ;
- fixture P3-05 réutilisée sans modification :
  `packages/map_runtime/test/fixtures/p3_fact_world_rule_projection/` ;
- roadmap Phase 3 mise à jour ;
- rapport P3-06 créé.

Preuves obtenues :

- vraie sauvegarde écrite dans un fichier temporaire par `FileGameSaveRepository` ;
- vraie lecture disque via `LoadGameUseCase` ;
- `storyFlags.activeFlags` conservés ;
- `completedStepIds` conservés ;
- `completedCutsceneIds` conservés ;
- `scenario.outcome.*` conservé comme flag technique ;
- `battle:*:victory` et `battle:*:defeat` conservés comme flags techniques ;
- `consumedEventIds` conservés par le chemin `GameState` courant ;
- `currentMapId`, `playerPosition` et `playerFacing` conservés ;
- projections P3-05 encore valides après reload ;
- cas négatifs après reload couverts.

Prochain lot exact :

```text
P3-07 — Playable Runtime Host Narrative Smoke Test
```

## 2. Scope du lot

Inclus :

- test save/load réel via repository/use cases existants ;
- réutilisation de la fixture disque P3-05 ;
- vérification des vérités techniques narratives après reload ;
- vérification passive des predicates/projections après reload ;
- cas négatifs après reload ;
- mise à jour de `MVP Selbrume/road_map_phase_3.md`.

Exclus :

- nouveau modèle narratif ;
- modification `GameState` ou `SaveData` ;
- modification `ProjectManifest` ;
- migration JSON ;
- `FactRegistry` ;
- `WorldRuleRegistry` ;
- UI ;
- PlayableMapGame complet ;
- host smoke complet ;
- rewards, money, XP, level-up ;
- Selbrume final ;
- P3-07.

## 3. Sources lues

Gouvernance et rapports :

- `AGENTS.md`
- `skills/README.md`
- `MVP Selbrume/road_map_global.md`
- `MVP Selbrume/road_map_phase_3.md`
- `reports/roadmap/phase_3/p3_04_outcome_battle_outcome_runtime_continuation_validation.md`
- `reports/roadmap/phase_3/p3_04_bis_outcome_battle_evidence_status_reconciliation.md`
- `reports/roadmap/phase_3/p3_05_fact_world_rule_runtime_projection_validation.md`

Code et tests :

- `packages/map_core/lib/src/models/game_state.dart`
- `packages/map_core/lib/src/models/save_data.dart`
- `packages/map_core/lib/src/operations/game_state_persistence.dart`
- `packages/map_runtime/lib/src/infrastructure/file_game_save_repository.dart`
- `packages/map_runtime/lib/src/application/save_game_use_case.dart`
- `packages/map_runtime/lib/src/application/load_game_use_case.dart`
- `packages/map_runtime/lib/src/application/map_entity_runtime_predicate_evaluator.dart`
- `packages/map_runtime/lib/src/application/step_studio_world_presence_runtime.dart`
- `packages/map_runtime/lib/src/application/global_story_chapter_runtime.dart`
- `packages/map_runtime/test/file_game_save_repository_test.dart`
- `packages/map_runtime/test/step_studio_save_reload_visibility_integration_test.dart`
- `packages/map_runtime/test/p3_fact_world_rule_projection_test.dart`
- `packages/map_runtime/test/p3_outcome_battle_continuation_test.dart`
- `packages/map_runtime/test/fixtures/p3_fact_world_rule_projection/README.md`
- `packages/map_runtime/test/fixtures/p3_fact_world_rule_projection/project.json`
- `packages/map_runtime/test/fixtures/p3_fact_world_rule_projection/maps/p3_fact_world_rule_field.json`

## 4. Save/load path utilisé

P3-06 utilise le chemin existant :

```text
GameState
-> SaveGameUseCase
-> FileGameSaveRepository.save
-> fichier temporaire pokemonProject/game_save.json
-> FileGameSaveRepository.load
-> LoadGameUseCase
-> GameState rechargé
```

Point important du code actuel :

- `saveDataFromGameState` est utilisé pour normaliser les parties compatibles
  `SaveData` ;
- le repository écrit ensuite un `GameState` normalisé avec `toJson()` ;
- ce chemin conserve donc `consumedEventIds`, `storyFlags.activeFlags`,
  `progression.completedStepIds` et `progression.completedCutsceneIds`.

Le test ne modifie ni format de sauvegarde, ni modèle, ni migration.

## 5. Roundtrip storyFlags

État sauvegardé :

```text
p3.fact.flag.visible
scenario.outcome.p3.outcome.visible
battle:p3_battle_projection:victory
battle:p3_battle_projection:defeat
```

Après reload, le test vérifie que ces quatre flags sont présents dans :

```text
GameState.storyFlags.activeFlags
```

## 6. Roundtrip completedStepIds

État sauvegardé :

```text
p3.step.visible
p3.chapter.step.a
p3.chapter.step.b
p3.world_presence.step.visible
```

Après reload, le test vérifie que ces ids sont présents dans :

```text
GameState.progression.completedStepIds
```

Ces ids couvrent la projection step directe, la dérivation chapter et Step
Studio world presence.

## 7. Roundtrip completedCutsceneIds

État sauvegardé :

```text
p3.cutscene.visible
```

Après reload, le test vérifie que cet id est présent dans :

```text
GameState.progression.completedCutsceneIds
```

## 8. Roundtrip scenario outcomes

P3-04 a validé le contrat :

```text
emitOutcome -> scenario.outcome.<outcomeId>
```

P3-06 vérifie que le flag technique suivant survit au roundtrip :

```text
scenario.outcome.p3.outcome.visible
```

Il reste un flag technique lu par les predicates existants. P3-06 ne crée pas
de Fact persistant.

## 9. Roundtrip battle outcomes

P3-04 a validé le contrat :

```text
battle:<battleId>:victory
battle:<battleId>:defeat
```

P3-06 vérifie que les deux flags suivants survivent au roundtrip :

```text
battle:p3_battle_projection:victory
battle:p3_battle_projection:defeat
```

Ils restent séparés de `scenario.outcome.*`.

## 10. Roundtrip consumedEventIds

`GameState` contient :

```dart
Set<String> consumedEventIds
```

Le test sauvegarde puis recharge :

```text
p3.event.consumed
```

Résultat :

```text
consumedEventIds est conservé par le chemin repository actuel.
```

Limite :

`SaveData` pur ne porte pas `consumedEventIds`, mais le repository écrit un
`GameState` JSON normalisé. P3-06 prouve donc le chemin runtime actuel, pas un
contrat `SaveData` isolé.

## 11. Projection runtime après reload

Après reload, le test réutilise la fixture P3-05 et vérifie :

- `p3_flag_visible_npc` visible via story flag ;
- `p3_step_visible_npc` visible via completed step ;
- `p3_cutscene_visible_npc` visible via completed cutscene ;
- `p3_outcome_visible_npc` visible via `scenario.outcome.*` ;
- `p3_battle_visible_npc` visible via `battle:*:victory` ;
- `p3_chapter_visible_npc` visible via chapter dérivé ;
- `p3_world_presence_npc` présent via Step Studio world presence ;
- `p3_conditional_dialogue_npc` résout `p3.flag.dialogue`.

Le test capture aussi `loadedState.toJson()` avant/après projection pour vérifier
que la lecture des predicates ne mute pas `GameState`.

## 12. Cas négatifs après reload

Le test sauvegarde et recharge un état négatif contenant :

```text
p3.fact.flag.wrong
scenario.outcome.p3.outcome.wrong
battle:p3_battle_projection:defeat
p3.step.wrong
p3.chapter.step.a
p3.world_presence.wrong
p3.cutscene.wrong
```

Après reload :

- les NPC flag/step/cutscene/outcome/battle/chapter restent invisibles ;
- Step Studio world presence reste false ;
- le dialogue conditionnel revient au fallback `p3.default.dialogue` ;
- `battle:*:defeat` ne déclenche pas la visibilité attendue pour
  `battle:*:victory` ;
- une seule step de chapter ne suffit pas à valider `chapterCompleted`.

## 13. Niveau de preuve obtenu

```text
Level 4 partiel :
- vrai fichier de sauvegarde temporaire écrit ;
- vraie lecture disque ;
- vraie fixture project.json P3-05 chargée via loadRuntimeMapBundle.

Level 2/3 contrôlé :
- FileGameSaveRepository ;
- SaveGameUseCase ;
- LoadGameUseCase ;
- MapEntityRuntimePredicateEvaluator ;
- Step Studio world presence runtime ;
- GlobalStoryChapterStepIndex.
```

Non revendiqué :

```text
PlayableMapGame complet.
Host smoke complet.
UI save menu.
Save slot UX.
Combat complet.
```

## 14. Ce qui est prouvé

P3-06 prouve que :

- les flags narratifs techniques survivent au roundtrip ;
- les completed steps survivent au roundtrip ;
- les completed cutscenes survivent au roundtrip ;
- `scenario.outcome.*` survit au roundtrip ;
- `battle:*` survit au roundtrip ;
- `consumedEventIds` survit dans le chemin repository courant ;
- la map courante, la position et l'orientation joueur survivent ;
- les projections P3-05 relisent correctement l'état après reload ;
- les mauvais flags/steps/cutscenes ne projettent pas le monde ;
- les predicates/world rules restent passifs.

## 15. Ce qui n’est pas prouvé

P3-06 ne prouve pas :

- host smoke complet ;
- instanciation complète `PlayableMapGame` ;
- menu de sauvegarde UI ;
- multi-slot save UX ;
- roundtrip d'un combat réel ;
- rewards, money, XP, level-up ;
- Selbrume réel ;
- migration d'un ancien format où `consumedEventIds` serait absent ;
- stratégie disque finale de projets complets.

## 16. Gaps reportés à P3-07 / checkpoint / phases suivantes

P3-07 :

- smoke test narratif ciblé dans `examples/playable_runtime_host` si le scope le
  permet ;
- preuve plus proche de `PlayableMapGame` et du host ;
- validation que les vérités reloadées alimentent le runtime jouable.

P3-CHECKPOINT :

- bilan Level 2 / Level 3 / Level 4 de toute la Phase 3 ;
- décision de passage vers Phase 4 authoring.

Phases suivantes :

- Phase 4 : UI authoring, pickers, workflows Narrative Studio ;
- Phase 5 : rewards, money, XP, level-up, static wild authoring ;
- Phase 6 : Selbrume golden slice réel ;
- Phase 7 : UI/UX finale.

## 17. Tests exécutés

Format :

```text
cd packages/map_runtime && dart format --set-exit-if-changed test/p3_save_load_narrative_state_roundtrip_test.dart
```

Test ciblé :

```text
cd packages/map_runtime && flutter test test/p3_save_load_narrative_state_roundtrip_test.dart
```

Régressions ciblées :

```text
cd packages/map_runtime && flutter test test/file_game_save_repository_test.dart
cd packages/map_runtime && flutter test test/step_studio_save_reload_visibility_integration_test.dart
cd packages/map_runtime && flutter test test/p3_fact_world_rule_projection_test.dart
cd packages/map_runtime && flutter test test/p3_outcome_battle_continuation_test.dart
```

Toutes ces commandes sont passées après format final.

## 18. Modifications effectuées

Fichiers créés :

```text
packages/map_runtime/test/p3_save_load_narrative_state_roundtrip_test.dart
reports/roadmap/phase_3/p3_06_save_load_narrative_state_roundtrip_validation.md
```

Fichiers modifiés :

```text
MVP Selbrume/road_map_phase_3.md
```

Fixtures créées ou modifiées :

```text
Aucune.
```

Code de production modifié :

```text
Aucun.
```

## 19. Evidence Pack

### 19.1 git status initial exact

```text

```

### 19.2 Fichiers lus principaux

```text
AGENTS.md
skills/README.md
MVP Selbrume/road_map_global.md
MVP Selbrume/road_map_phase_3.md
reports/roadmap/phase_3/p3_04_outcome_battle_outcome_runtime_continuation_validation.md
reports/roadmap/phase_3/p3_04_bis_outcome_battle_evidence_status_reconciliation.md
reports/roadmap/phase_3/p3_05_fact_world_rule_runtime_projection_validation.md
packages/map_core/lib/src/models/game_state.dart
packages/map_core/lib/src/models/save_data.dart
packages/map_core/lib/src/operations/game_state_persistence.dart
packages/map_runtime/lib/src/infrastructure/file_game_save_repository.dart
packages/map_runtime/lib/src/application/save_game_use_case.dart
packages/map_runtime/lib/src/application/load_game_use_case.dart
packages/map_runtime/test/file_game_save_repository_test.dart
packages/map_runtime/test/step_studio_save_reload_visibility_integration_test.dart
packages/map_runtime/test/p3_fact_world_rule_projection_test.dart
packages/map_runtime/test/p3_outcome_battle_continuation_test.dart
packages/map_runtime/test/fixtures/p3_fact_world_rule_projection/README.md
packages/map_runtime/test/fixtures/p3_fact_world_rule_projection/project.json
packages/map_runtime/test/fixtures/p3_fact_world_rule_projection/maps/p3_fact_world_rule_field.json
```

### 19.3 Commandes exécutées

```text
git status --short --untracked-files=all
sed -n '1,260p' "MVP Selbrume/road_map_global.md"
sed -n '1,720p' "MVP Selbrume/road_map_phase_3.md"
sed -n '1,360p' reports/roadmap/phase_3/p3_05_fact_world_rule_runtime_projection_validation.md
rg -n "class GameState|storyFlags|completedStepIds|completedCutsceneIds|consumedEventIds|SaveData|FileGameSaveRepository|SaveGameUseCase|LoadGameUseCase|normalized|toJson|fromJson" packages/map_core packages/map_runtime --glob '!build/**' --glob '!**/.dart_tool/**'
sed -n '1,320p' packages/map_core/lib/src/models/game_state.dart
sed -n '1,360p' packages/map_core/lib/src/models/save_data.dart
sed -n '320,520p' packages/map_core/lib/src/models/save_data.dart
sed -n '1,320p' packages/map_core/lib/src/operations/game_state_persistence.dart
sed -n '1,260p' packages/map_runtime/lib/src/infrastructure/file_game_save_repository.dart
sed -n '1,220p' packages/map_runtime/lib/src/application/save_game_use_case.dart
sed -n '1,220p' packages/map_runtime/lib/src/application/load_game_use_case.dart
sed -n '1,420p' packages/map_runtime/test/file_game_save_repository_test.dart
sed -n '420,760p' packages/map_runtime/test/file_game_save_repository_test.dart
sed -n '1,360p' packages/map_runtime/test/p3_fact_world_rule_projection_test.dart
sed -n '1,260p' packages/map_runtime/test/fixtures/p3_fact_world_rule_projection/project.json
sed -n '1,360p' packages/map_runtime/test/fixtures/p3_fact_world_rule_projection/maps/p3_fact_world_rule_field.json
sed -n '1,120p' packages/map_runtime/test/fixtures/p3_fact_world_rule_projection/README.md
cd packages/map_runtime && flutter test test/p3_save_load_narrative_state_roundtrip_test.dart
cd packages/map_runtime && dart format --set-exit-if-changed test/p3_save_load_narrative_state_roundtrip_test.dart
cd packages/map_runtime && dart format --set-exit-if-changed test/p3_save_load_narrative_state_roundtrip_test.dart
cd packages/map_runtime && flutter test test/p3_save_load_narrative_state_roundtrip_test.dart
cd packages/map_runtime && flutter test test/file_game_save_repository_test.dart
cd packages/map_runtime && flutter test test/step_studio_save_reload_visibility_integration_test.dart
cd packages/map_runtime && flutter test test/p3_fact_world_rule_projection_test.dart
cd packages/map_runtime && flutter test test/p3_outcome_battle_continuation_test.dart
rg -n "Lot courant|Prochain lot exact|P3-05|P3-06|P3-07|P3-CHECKPOINT" "MVP Selbrume/road_map_phase_3.md"
sed -n '1,220p' "MVP Selbrume/road_map_phase_3.md"
sed -n '300,480p' "MVP Selbrume/road_map_phase_3.md"
sed -n '1,320p' packages/map_runtime/test/p3_save_load_narrative_state_roundtrip_test.dart
sed -n '1,360p' reports/roadmap/phase_3/p3_04_outcome_battle_outcome_runtime_continuation_validation.md
sed -n '1,260p' reports/roadmap/phase_3/p3_04_bis_outcome_battle_evidence_status_reconciliation.md
sed -n '1,260p' "MVP Selbrume/road_map_global.md"
git status --short --untracked-files=all
git diff --check
git diff --stat
git diff --name-only
git diff --name-only -- "MVP Selbrume/road_map_global.md"
git diff --name-only -- packages/map_core packages/map_runtime/lib packages/map_editor packages/map_gameplay packages/map_battle examples/playable_runtime_host
git diff --no-index --check /dev/null reports/roadmap/phase_3/p3_06_save_load_narrative_state_roundtrip_validation.md || true
git diff --no-index --check /dev/null packages/map_runtime/test/p3_save_load_narrative_state_roundtrip_test.dart || true
find reports/roadmap/phase_3 -maxdepth 1 \( -name '*p3_07*' -o -name '*P3-07*' \) -type f | sort
git status --short --untracked-files=all
```

### 19.4 Sorties utiles des commandes

`game_state.dart` expose :

```text
StoryFlags storyFlags
Set<String> consumedEventIds
PlayerProgression progression
```

`save_data.dart` expose :

```text
PlayerProgression.completedStepIds
PlayerProgression.completedCutsceneIds
PlayerProgression.storyFlags
```

`game_state_persistence.dart` montre que `saveDataFromGameState` fusionne
`progression.storyFlags` et `storyFlags.activeFlags` pour normalisation, puis le
repository écrit un `GameState` JSON normalisé.

`file_game_save_repository.dart` montre :

```text
FileGameSaveRepository.save -> file.writeAsString(GameState.toJson())
FileGameSaveRepository.load -> GameState.fromJson -> normalizeLoadedGameState
```

### 19.5 Fichiers créés

```text
packages/map_runtime/test/p3_save_load_narrative_state_roundtrip_test.dart
reports/roadmap/phase_3/p3_06_save_load_narrative_state_roundtrip_validation.md
```

### 19.6 Fichiers modifiés

```text
MVP Selbrume/road_map_phase_3.md
```

### 19.7 Contenu complet du test créé

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/application/global_story_chapter_runtime.dart';
import 'package:map_runtime/src/application/map_entity_runtime_predicate_evaluator.dart';
import 'package:map_runtime/src/application/step_studio_world_presence_runtime.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('P3 save/load narrative state roundtrip', () {
    test('persists narrative truths and projections after reload', () async {
      final bundle = await _loadBundle();
      final initialState = _narrativeState(
        saveId: 'p3-save-load-positive',
        flags: {
          _flagVisible,
          _scenarioOutcomeFlag,
          _battleVictoryFlag,
          _battleDefeatFlag,
        },
        completedSteps: const [
          _stepVisible,
          _chapterStepA,
          _chapterStepB,
          _worldPresenceStep,
        ],
        completedCutscenes: const [_cutsceneVisible],
        consumedEvents: const {_consumedEvent},
      );

      final loadedState = await _saveAndLoad(initialState);

      expect(loadedState.saveId, 'p3-save-load-positive');
      expect(loadedState.currentMapId, _mapId);
      expect(loadedState.playerPosition, const GridPos(x: 4, y: 5));
      expect(loadedState.playerFacing, EntityFacing.east);
      expect(
        loadedState.storyFlags.activeFlags,
        containsAll(<String>[
          _flagVisible,
          _scenarioOutcomeFlag,
          _battleVictoryFlag,
          _battleDefeatFlag,
        ]),
      );
      expect(
        loadedState.progression.completedStepIds,
        containsAll(<String>[
          _stepVisible,
          _chapterStepA,
          _chapterStepB,
          _worldPresenceStep,
        ]),
      );
      expect(
        loadedState.progression.completedCutsceneIds,
        contains(_cutsceneVisible),
      );
      expect(loadedState.consumedEventIds, contains(_consumedEvent));

      final beforeProjection = loadedState.toJson();
      expect(_isVisible(bundle, 'p3_flag_visible_npc', loadedState), isTrue);
      expect(_isVisible(bundle, 'p3_step_visible_npc', loadedState), isTrue);
      expect(
          _isVisible(bundle, 'p3_cutscene_visible_npc', loadedState), isTrue);
      expect(_isVisible(bundle, 'p3_outcome_visible_npc', loadedState), isTrue);
      expect(_isVisible(bundle, 'p3_battle_visible_npc', loadedState), isTrue);
      expect(_isVisible(bundle, 'p3_chapter_visible_npc', loadedState), isTrue);
      expect(_isWorldPresenceVisible(bundle, loadedState), isTrue);
      expect(
          _resolveConditionalDialogue(bundle, loadedState), 'p3.flag.dialogue');
      expect(loadedState.toJson(), beforeProjection);
    });

    test('keeps projections false or fallback after a negative reload',
        () async {
      final bundle = await _loadBundle();
      final negativeState = _narrativeState(
        saveId: 'p3-save-load-negative',
        flags: const {
          'p3.fact.flag.wrong',
          'scenario.outcome.p3.outcome.wrong',
          _battleDefeatFlag,
        },
        completedSteps: const [
          'p3.step.wrong',
          _chapterStepA,
          'p3.world_presence.wrong',
        ],
        completedCutscenes: const ['p3.cutscene.wrong'],
      );

      final loadedState = await _saveAndLoad(negativeState);

      expect(loadedState.storyFlags.activeFlags,
          containsAll(<String>['p3.fact.flag.wrong', _battleDefeatFlag]));
      expect(loadedState.storyFlags.activeFlags, isNot(contains(_flagVisible)));
      expect(
        loadedState.storyFlags.activeFlags,
        isNot(contains(_scenarioOutcomeFlag)),
      );
      expect(
        loadedState.storyFlags.activeFlags,
        isNot(contains(_battleVictoryFlag)),
      );
      expect(loadedState.progression.completedStepIds, contains(_chapterStepA));
      expect(
        loadedState.progression.completedStepIds,
        isNot(contains(_chapterStepB)),
      );

      final beforeProjection = loadedState.toJson();
      expect(_isVisible(bundle, 'p3_flag_visible_npc', loadedState), isFalse);
      expect(_isVisible(bundle, 'p3_step_visible_npc', loadedState), isFalse);
      expect(
        _isVisible(bundle, 'p3_cutscene_visible_npc', loadedState),
        isFalse,
      );
      expect(
          _isVisible(bundle, 'p3_outcome_visible_npc', loadedState), isFalse);
      expect(_isVisible(bundle, 'p3_battle_visible_npc', loadedState), isFalse);
      expect(
          _isVisible(bundle, 'p3_chapter_visible_npc', loadedState), isFalse);
      expect(_isWorldPresenceVisible(bundle, loadedState), isFalse);
      expect(_resolveConditionalDialogue(bundle, loadedState),
          'p3.default.dialogue');
      expect(loadedState.toJson(), beforeProjection);
    });
  });
}

const _mapId = 'p3_fact_world_rule_map';
const _flagVisible = 'p3.fact.flag.visible';
const _stepVisible = 'p3.step.visible';
const _cutsceneVisible = 'p3.cutscene.visible';
const _scenarioOutcomeFlag = 'scenario.outcome.p3.outcome.visible';
const _battleVictoryFlag = 'battle:p3_battle_projection:victory';
const _battleDefeatFlag = 'battle:p3_battle_projection:defeat';
const _chapterStepA = 'p3.chapter.step.a';
const _chapterStepB = 'p3.chapter.step.b';
const _worldPresenceStep = 'p3.world_presence.step.visible';
const _consumedEvent = 'p3.event.consumed';

Future<RuntimeMapBundle> _loadBundle() {
  final projectFilePath = p.join(
    Directory.current.path,
    'test',
    'fixtures',
    'p3_fact_world_rule_projection',
    'project.json',
  );

  return loadRuntimeMapBundle(
    projectFilePath: projectFilePath,
    mapId: _mapId,
  );
}

GameState _narrativeState({
  required String saveId,
  required Set<String> flags,
  required List<String> completedSteps,
  List<String> completedCutscenes = const [],
  Set<String> consumedEvents = const {},
}) {
  return GameState(
    saveId: saveId,
    currentMapId: _mapId,
    playerPosition: const GridPos(x: 4, y: 5),
    playerFacing: EntityFacing.east,
    storyFlags: StoryFlags(activeFlags: flags),
    progression: PlayerProgression(
      completedStepIds: completedSteps,
      completedCutsceneIds: completedCutscenes,
    ),
    consumedEventIds: consumedEvents,
  );
}

Future<GameState> _saveAndLoad(GameState state) async {
  final tempDirectory =
      await Directory.systemTemp.createTemp('p3_save_load_narrative_');
  addTearDown(() async {
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  final repository = _TestFileGameSaveRepository(tempDirectory);
  final saved = await SaveGameUseCase(repository).execute(state);
  expect(saved, isTrue);
  expect(await repository.exists(), isTrue);
  expect(await File(await repository.exposedSaveFilePath()).exists(), isTrue);

  final loadedState = await LoadGameUseCase(repository).execute();
  expect(loadedState, isNotNull);
  return loadedState!;
}

bool _isVisible(
  RuntimeMapBundle bundle,
  String entityId,
  GameState state,
) {
  final evaluator = MapEntityRuntimePredicateEvaluator(
    gameState: state,
    chapterIndex: buildGlobalStoryChapterStepIndex(bundle.manifest.scenarios),
  );
  return evaluator.isNpcPresentOnMap(_npc(bundle, entityId));
}

bool _isWorldPresenceVisible(RuntimeMapBundle bundle, GameState state) {
  final rules = buildStepStudioWorldPresenceRuleList(bundle.manifest.scenarios);
  return isNpcRuntimePresentOnMap(
    gameState: state,
    manifest: bundle.manifest,
    stepStudioWorldRules: rules,
    mapId: _mapId,
    entity: _npc(bundle, 'p3_world_presence_npc'),
  );
}

String? _resolveConditionalDialogue(RuntimeMapBundle bundle, GameState state) {
  final evaluator = MapEntityRuntimePredicateEvaluator(
    gameState: state,
    chapterIndex: buildGlobalStoryChapterStepIndex(bundle.manifest.scenarios),
  );
  return evaluator
      .resolveNpcDialogue(_npc(bundle, 'p3_conditional_dialogue_npc').npc!)
      ?.dialogueId;
}

MapEntity _npc(RuntimeMapBundle bundle, String entityId) {
  return bundle.map.entities.singleWhere((entity) => entity.id == entityId);
}

class _TestFileGameSaveRepository extends FileGameSaveRepository {
  _TestFileGameSaveRepository(this._testDirectory);

  final Directory _testDirectory;

  Future<String> exposedSaveFilePath() => getSaveFilePath();

  @override
  Future<String> getSaveFilePath() async {
    final saveDir = Directory('${_testDirectory.path}/pokemonProject');
    if (!await saveDir.exists()) {
      await saveDir.create(recursive: true);
    }
    return '${saveDir.path}/game_save.json';
  }
}
```

### 19.8 Contenu complet des fixtures créées ou modifiées

```text
Aucune fixture créée ou modifiée par P3-06.
```

### 19.9 Sortie complète du test ciblé

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/p3_save_load_narrative_state_roundtrip_test.dart
00:00 +0: P3 save/load narrative state roundtrip persists narrative truths and projections after reload
[step_studio_trace] save_repo_write_start path=/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/p3_save_load_narrative_3FO5rs/pokemonProject/game_save.json completedStepIds=[p3.step.visible, p3.chapter.step.a, p3.chapter.step.b, p3.world_presence.step.visible]
[save] game saved to /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/p3_save_load_narrative_3FO5rs/pokemonProject/game_save.json
[step_studio_trace] save_repo_write_done path=/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/p3_save_load_narrative_3FO5rs/pokemonProject/game_save.json completedStepIds=[p3.step.visible, p3.chapter.step.a, p3.chapter.step.b, p3.world_presence.step.visible]
[load] game loaded from /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/p3_save_load_narrative_3FO5rs/pokemonProject/game_save.json
00:00 +1: P3 save/load narrative state roundtrip keeps projections false or fallback after a negative reload
[step_studio_trace] save_repo_write_start path=/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/p3_save_load_narrative_FwxJ5B/pokemonProject/game_save.json completedStepIds=[p3.step.wrong, p3.chapter.step.a, p3.world_presence.wrong]
[save] game saved to /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/p3_save_load_narrative_FwxJ5B/pokemonProject/game_save.json
[step_studio_trace] save_repo_write_done path=/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/p3_save_load_narrative_FwxJ5B/pokemonProject/game_save.json completedStepIds=[p3.step.wrong, p3.chapter.step.a, p3.world_presence.wrong]
[load] game loaded from /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/p3_save_load_narrative_FwxJ5B/pokemonProject/game_save.json
00:00 +2: All tests passed!
```

### 19.10 Sortie complète des régressions ciblées

`cd packages/map_runtime && flutter test test/file_game_save_repository_test.dart`

```text
00:00 +14: All tests passed!
```

La sortie complète contenait les traces attendues des tests d'erreur
`GameSaveException` et des chemins temporaires de sauvegarde. Les signaux utiles
sont : 14 tests exécutés, tous passés.

`cd packages/map_runtime && flutter test test/step_studio_save_reload_visibility_integration_test.dart`

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/step_studio_save_reload_visibility_integration_test.dart
00:00 +0: intégration data flow: cutscene terminée -> step_2 complétée -> save/reload -> Emma absente
00:00 +1: All tests passed!
```

`cd packages/map_runtime && flutter test test/p3_fact_world_rule_projection_test.dart`

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/p3_fact_world_rule_projection_test.dart
00:00 +0: P3 fact and world rule runtime projection loads the disk fixture and projects NPC visibility from truths
00:00 +1: P3 fact and world rule runtime projection resolves conditional dialogues from existing predicates passively
00:00 +2: All tests passed!
```

`cd packages/map_runtime && flutter test test/p3_outcome_battle_continuation_test.dart`

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/p3_outcome_battle_continuation_test.dart
00:00 +0: P3 outcome and battle outcome continuation emits a scenario outcome and reaches a sourceOutcome continuation
00:00 +1: P3 outcome and battle outcome continuation dispatches explicit outcomeReceived and ignores unknown outcomes
00:00 +2: P3 outcome and battle outcome continuation starts a trainer battle and exposes battle handoff data
00:00 +3: P3 outcome and battle outcome continuation keeps battle outcome flags separate and resumes victory or defeat
00:00 +4: All tests passed!
```

### 19.11 Format

Première exécution, avant stabilisation :

```text
Formatted test/p3_save_load_narrative_state_roundtrip_test.dart
Formatted 1 file (1 changed) in 0.01 seconds.
```

Exécution finale :

```text
Formatted 1 file (0 changed) in 0.00 seconds.
```

### 19.12 git diff --check exact

```text

```

### 19.13 git diff --stat exact

```text
 MVP Selbrume/road_map_phase_3.md | 59 +++++++++++++++++++++++++++++++++++-----
 1 file changed, 52 insertions(+), 7 deletions(-)
```

### 19.14 git diff --name-only exact

```text
MVP Selbrume/road_map_phase_3.md
```

### 19.15 git status final exact

```text
 M "MVP Selbrume/road_map_phase_3.md"
?? packages/map_runtime/test/p3_save_load_narrative_state_roundtrip_test.dart
?? reports/roadmap/phase_3/p3_06_save_load_narrative_state_roundtrip_validation.md
```

### 19.16 Contrôles hors scope

`road_map_global.md` :

```text

```

Packages/code hors scope :

```text

```

Checks no-index sur fichiers non suivis :

```text
git diff --no-index --check /dev/null reports/roadmap/phase_3/p3_06_save_load_narrative_state_roundtrip_validation.md || true
Sortie exacte : vide.

git diff --no-index --check /dev/null packages/map_runtime/test/p3_save_load_narrative_state_roundtrip_test.dart || true
Sortie exacte : vide.
```

Contrôle P3-07 :

```text
find reports/roadmap/phase_3 -maxdepth 1 \( -name '*p3_07*' -o -name '*P3-07*' \) -type f | sort
Sortie exacte : vide.
```

Contrôles explicites :

```text
road_map_global.md n'a pas été modifié.
P3-07 n'a pas été exécuté.
Selbrume final n'a pas été créé.
Aucun FactRegistry / WorldRuleRegistry n'a été créé.
Aucun reward/money/XP n'a été ajouté.
```

## 20. Auto-review critique

- Le lot a-t-il modifié uniquement ce qui était autorisé ? Oui :
  roadmap Phase 3, rapport P3-06 et test ciblé `map_runtime`.
- Le rapport P3-06 existe-t-il au bon chemin ? Oui.
- `road_map_phase_3.md` est-elle mise à jour ? Oui, P3-06 est terminé et P3-07
  est le prochain lot exact.
- `road_map_global.md` est-elle restée intacte ? Oui.
- Aucun modèle `GameState` / `SaveData` / `ProjectManifest` n'a-t-il été
  modifié ? Oui.
- Aucun registry n'a-t-il été créé ? Oui.
- Aucun JSON / migration n'a-t-il été créé ? Oui.
- Le test utilise-t-il un vrai save/load disque ? Oui, via un fichier temporaire
  `game_save.json`.
- Les projections après reload sont-elles testées ? Oui.
- Les cas négatifs après reload sont-ils couverts ? Oui.
- Les tests ciblés passent-ils ? Oui.
- P3-07 n'a-t-il pas été exécuté ? Oui.
- Selbrume final n'a-t-il pas été créé ? Oui.

## 21. Regard critique sur le prompt

Le prompt est bien borné : il demande une preuve exécutable sans ouvrir de
nouveau modèle, sans registry et sans host smoke complet. Le point subtil est
`consumedEventIds` : il n'est pas porté par `SaveData`, mais il est bien
persisté par le chemin actuel du repository parce que celui-ci écrit un
`GameState` JSON. Le rapport le documente explicitement pour éviter de vendre un
contrat `SaveData` isolé comme preuve générale.
