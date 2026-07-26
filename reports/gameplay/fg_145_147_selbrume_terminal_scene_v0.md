# RM-013 — Selbrume Terminal Scene V0

Date : 2026-07-26
Phase : 1 — Fin de partie jouable
Lot : `RM-013`
Liens canoniques : `FG-145`, `FG-146`, `FG-147`, `FG-181`, `FG-182`
Verdict du lot : **DONE proposé**
Verdict des lots canoniques : **PARTIAL** jusqu'à `RM-014` et à la gate
complète de Phase 1

## 1. Résultat

La scène canonique `scene_ending_port` de Selbrume termine désormais la
campagne par une conséquence `Finish Game` authorée :

- ending stable : `ending.selbrume-sauvee` ;
- outcome : `victory` ;
- sauvegarde exigée avant présentation ;
- résultat et crédits localisés en français et en anglais ;
- crédits skippables ;
- politique postgame : retour au Hub ;
- conservation des faits `fact_ending_seen` et
  `fact_main_story_completed` ;
- conservation des steps `step_return_to_port` et
  `step_main_story_completed`.

Le parcours de référence reçoit maintenant la demande de completion par le
port runtime réel et vérifie le résultat, les crédits et la destination Hub.
Le receipt narratif Selbrume a été régénéré uniquement après le passage de ses
deux suites obligatoires.

## 2. Audit initial

### État observé

- L'événement terminal existait déjà sous l'identifiant
  `evt_019abcde-5000-7000-8000-000000000031`.
- Sa source était `triggerEnter` sur
  `map_port_brisants / zone_port_center`.
- Sa condition exigeait `fact_mist_source_resolved == true`.
- Sa reuse policy était `oneShot`.
- Il lançait `scene_ending_port`.
- La scène jouait la célébration, le dialogue final, le faisceau du phare,
  posait les deux faits de fin et complétait les deux derniers steps.
- Le graphe se terminait ensuite directement sur `End` : aucune conséquence
  `Finish Game`, aucun résultat, aucun crédit et aucun retour Hub n'étaient
  authorés.
- Le host d'évaluation créait `PlayableMapGame` sans
  `gameCompletionEmitter`. Dès que la scène a reçu `Finish Game`, ce host
  refusait donc correctement de valider une fin non livrable et rollbackait
  l'événement.

### Décisions

- L'identifiant est dérivé du nom fonctionnel « Selbrume sauvée » et reste
  indépendant du texte affiché.
- L'auteur de crédits est `Selbrume`, faute de métadonnée d'auteur humain
  canonique dans le projet. Aucune attribution personnelle n'a été inventée.
- La scène terminale conserve tous ses effets narratifs historiques avant
  d'émettre la completion.
- Le host d'évaluation enregistre le même `GameCompletionRequest` que le
  runtime installé ; il ne forge aucun fait, step, checkpoint ou résultat.

### Non-objectifs

- Pas de modification du dialogue Yarn ni des cartes.
- Pas de promotion de `FG-185`.
- Pas de preuve Hub installée : elle appartient à `RM-014`.
- Pas de modification du roadmap canonique ; les statuts sont seulement
  proposés dans ce rapport.

## 3. TDD et incidents découverts

### Rouge contractuel

Le nouveau test runtime a d'abord été exécuté avant la modification du projet :

```text
Expected: an object with length of <1>
Actual: WhereIterable<SceneNode>:<...> with length of <0>
```

Il prouvait que la scène terminale ne contenait aucune conséquence
`Finish Game`.

### Rouge d'intégration

Après l'authoring de la scène, la première régénération du receipt a préservé
l'ancien fichier et échoué sur le parcours produit :

```text
Timed out waiting for Fact fact_main_story_completed:
map=map_port_brisants, pos=GridPos(x: 28, y: 10), phase=overworld
```

Cause : `EvaluationPlayableMapGame` ne recevait pas de
`gameCompletionEmitter`. Le runtime fail-closed rejetait donc la scène avec
« Finish Game requires an active session completion port » avant son commit.

Le branchement du port a ensuite exposé une unique erreur d'assertion dans le
test ajouté :

```text
Expected: La brume est dissipée et le phare guide de nouveau les marins.
Actual: La lumière du phare traverse de nouveau la brume et les habitants
reprennent la mer.
```

Le runtime transportait correctement le texte réellement authoré. L'assertion
a été alignée sur ce contrat canonique.

## 4. Inventaire et zones modifiées

| Fichier | Zone précise | Impact |
|---|---|---|
| `selbrume/project.json` | graphe `scene_ending_port`, entre `node_7` et `node_end` | ajoute `node_8`, sa conséquence `finishGame`, ses textes localisés et les deux edges terminales |
| `packages/map_runtime/test/selbrume_terminal_scene_completion_contract_test.dart` | nouveau test complet | charge le vrai projet, vérifie la source terminale, exécute la scène et contrôle faits, steps, métadonnée et completion |
| `examples/playable_runtime_host/lib/src/evaluation/driver/evaluation_game_fixtures.dart` | constructeur `EvaluationPlayableMapGame` | transmet le port de completion au runtime réel |
| `examples/playable_runtime_host/lib/src/evaluation/driver/selbrume_evaluation_driver.dart` | création du runtime headless et projection d'évaluation | enregistre les `GameCompletionRequest` sans modifier l'état de jeu |
| `examples/playable_runtime_host/test/selbrume_player_journey_e2e_test.dart` | épilogue du parcours principal | attend et vérifie l'unique completion, son résultat, ses crédits et le retour Hub |
| `selbrume/.pokemap/validation/narrative_runtime_smoke_receipt.json` | fingerprint et date de preuve | receipt frais produit par les deux suites obligatoires |
| `reports/gameplay/fg_145_147_selbrume_terminal_scene_v0.md` | nouveau rapport | preuve de clôture du lot |

### Diff fonctionnel

```text
scene_ending_port:
node_7 (complete step_main_story_completed)
  -> node_8 (Finish Game: ending.selbrume-sauvee)
  -> node_end
```

```text
Evaluation host:
PlayableMapGame.gameCompletionEmitter
  -> List<GameCompletionRequest>
  -> assertions du parcours Selbrume
```

Le diff contrôlé avant commit contient 107 insertions et 3 suppressions sur
les quatre fichiers suivis hors receipt, nouveau test et rapport. Le nouveau
test contient 166 lignes.

## 5. Validation fraîche

### Runtime Selbrume ciblé

```bash
cd packages/map_runtime
flutter test \
  test/selbrume_terminal_scene_completion_contract_test.dart \
  test/selbrume_narrative_campaign_outcome_matrix_test.dart \
  test/selbrume_event_v2_three_source_integration_test.dart \
  -r failures-only
```

Résultat exact :

```text
+11: All tests passed!
```

Après correction du lint du nouveau test :

```bash
flutter test test/selbrume_terminal_scene_completion_contract_test.dart \
  -r failures-only
flutter analyze
```

Résultat exact :

```text
+1: All tests passed!
No issues found! (ran in 4.0s)
```

### Parcours produit et receipt

```bash
cd examples/playable_runtime_host
flutter test test/selbrume_player_journey_e2e_test.dart \
  --plain-name \
  'player completes Selbrume through PlayableMapGame production hooks' \
  -r failures-only
```

Résultat exact :

```text
+1: All tests passed!
```

```bash
dart run tool/verify_narrative_project.dart \
  --project-root ../../selbrume \
  --profile selbrume-release-v1 \
  --write-receipt
```

Résultats exacts :

```text
selbrume-lighthouse-retry: +3: All tests passed!
selbrume-player-journey: +6: All tests passed!
result: pass
projectFingerprint:
sha256:03651d6d870eb65765c0fc2a1971981549a0051ac25222b8c17d425a8d8f03c9
```

```bash
flutter test \
  test/narrative_runtime_smoke_receipt_file_integration_test.dart \
  test/narrative_runtime_smoke_receipt_integration_test.dart \
  test/human_walkthrough_receipt_validator_test.dart \
  -r failures-only
flutter analyze
```

Résultat exact :

```text
+7: All tests passed!
No issues found! (ran in 5.6s)
```

### Éditeur

```bash
cd packages/map_editor
flutter test \
  test/selbrume_narrative_validator_test.dart \
  test/narrative_template_catalog_test.dart \
  test/narrative_runtime_smoke_receipt_repository_test.dart \
  -r failures-only
flutter analyze
```

Résultat exact :

```text
+14: All tests passed!
No issues found! (ran in 6.6s)
```

### Hygiène du diff

```bash
git diff --check -- \
  selbrume/project.json \
  packages/map_runtime/test/selbrume_terminal_scene_completion_contract_test.dart \
  examples/playable_runtime_host/lib/src/evaluation/driver/evaluation_game_fixtures.dart \
  examples/playable_runtime_host/lib/src/evaluation/driver/selbrume_evaluation_driver.dart \
  examples/playable_runtime_host/test/selbrume_player_journey_e2e_test.dart \
  selbrume/.pokemap/validation/narrative_runtime_smoke_receipt.json
```

Résultat exact : aucune sortie, code `0`.

## 6. Verdicts des passes

- Audit initial et architecture : **GO**. La conséquence reste dans le modèle
  de scène, le runtime ne contient pas de règle Selbrume et le host ne fait
  qu'observer le port public.
- TDD : **GO**. Le test a été rouge sur l'absence de `Finish Game`, puis vert
  après l'authoring.
- Runtime : **GO** sur les tests ciblés et l'analyse.
- Parcours produit : **GO** sur la campagne complète, la completion et le
  receipt frais.
- Éditeur/readiness : **GO** ; le receipt est reconnu frais.
- Passe sub-agent : **N/A**. Aucun sub-agent n'a été demandé pour ce lot et
  l'exécution est restée dans la passe principale.
- Critique finale : **GO RM-013**, avec maintien explicite de `FG-147`,
  `FG-181` et `FG-182` en `PARTIAL` avant `RM-014`.

## 7. État Git

### État initial du lot

Les sept modifications utilisateur préexistantes suivantes étaient présentes
et ont été laissées intactes :

```text
 M apps/pokemap_hub/lib/src/ui/hub_app.dart
 M apps/pokemap_hub/lib/src/ui/hub_shell.dart
 M apps/pokemap_hub/test/ui/hub_app_player_navigation_test.dart
 M apps/pokemap_hub/test/ui/hub_preferences_store_test.dart
 M apps/pokemap_hub/test/ui/hub_shell_test.dart
 M packages/map_player_ui/lib/src/localization/player_localizations.dart
 M packages/map_player_ui/lib/src/preferences/player_preferences.dart
```

### État final attendu après le commit ciblé RM-013

Les mêmes sept modifications utilisateur restent dans le working tree. Aucun
fichier de ce lot ne doit rester non committé.

## 8. Auto-critique et risques

- Le receipt conserve sa limitation historique
  `PARTIAL / NO-GO baseline: runtime smoke only; FG-185 is not promoted.` :
  c'est volontaire et `RM-013` ne doit pas promouvoir la release.
- Le host prouve le port runtime et la destination `hub`, mais pas encore
  l'affichage réel des écrans Hub. Cette preuve appartient à `RM-014`.
- Le crédit `author: Selbrume` est une attribution projet neutre. Une future
  métadonnée d'auteur canonique pourra la remplacer sans changer l'ending ID.
- La suite complète de chaque package est réservée à la gate de Phase 1 après
  `RM-014`. Le lot dispose de preuves ciblées fraîches, mais ne revendique pas
  encore cette gate globale.

## 9. Statuts proposés

| Élément | Statut proposé | Motif |
|---|---|---|
| `RM-013` | `DONE` | scène terminale, completion, résultat, crédits et receipt frais prouvés |
| `FG-145` | `PARTIAL` | le lot consomme le suivi rival/NPC existant mais ne clôt pas le template trainer complet |
| `FG-146` | `PARTIAL` | la campagne terminale est validée, sans mise à jour du statut canonique dans ce lot |
| `FG-147` | `PARTIAL` | résultat/crédits existent ; l'E2E Hub installé reste à prouver par `RM-014` |
| `FG-181` | `PARTIAL` | readiness terminale renforcée, sans gate globale |
| `FG-182` | `PARTIAL` | parcours runtime vert, preuve Hub-vers-crédits encore absente |
| `FG-185` | inchangé | aucune promotion autorisée par ce lot |

Lot suivant recommandé : `RM-014 — Story-to-Credits Golden E2E V0`.

## Annexe A — contenu complet du fichier créé

### `packages/map_runtime/test/selbrume_terminal_scene_completion_contract_test.dart`

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/application/narrative_scene_runtime_execution.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Selbrume terminal Scene commits victory and returns to the Hub',
      () async {
    final project = _loadSelbrumeProject();
    final eventRecord = project.eventRegistry!.records.singleWhere(
      (record) => record.definitionOrNull?.sceneId == 'scene_ending_port',
    );
    final event = eventRecord.definitionOrNull!;
    final scene = project.scenes.singleWhere(
      (candidate) => candidate.id == event.sceneId,
    );
    final finishNodes = scene.graph.nodes.where(
      (node) =>
          node.payload is SceneActionPayload &&
          (node.payload as SceneActionPayload).consequence
              is SceneFinishGameConsequence,
    );

    expect(eventRecord.enabledOrNull, isTrue);
    expect(event.reusePolicy, NarrativeEventReusePolicy.oneShot);
    expect(event.source.toJson(), {
      'kind': 'triggerEnter',
      'mapId': 'map_port_brisants',
      'triggerId': 'zone_port_center',
    });
    expect(
      event.conditions.single.toJson(),
      {
        'kind': 'fact',
        'factId': 'fact_mist_source_resolved',
        'expectedValue': true,
      },
    );
    expect(finishNodes, hasLength(1));
    expect(buildSceneRuntimePlan(scene).canBuild, isTrue);

    final finish = (finishNodes.single.payload as SceneActionPayload)
        .consequence as SceneFinishGameConsequence;
    expect(finish.endingId, 'ending.selbrume-sauvee');
    expect(finish.outcome, SceneGameCompletionOutcome.victory);
    expect(
      finish.commitPolicy,
      SceneFinishGameCommitPolicy.persistBeforePresentation,
    );
    expect(finish.postGamePolicy, ScenePostGamePolicy.returnToHub);
    expect(finish.credits, isNotNull);
    expect(finish.credits!.skippable, isTrue);

    final initial = const GameState(
      saveId: 'save_selbrume_terminal_contract',
      currentMapId: 'map_port_brisants',
    ).copyWith(
      storyFlags: const StoryFlags(
        activeFlags: {'fact_mist_source_resolved'},
      ),
      narrativeFactRuntimeState: NarrativeFactRuntimeState(
        overridesByFactId: const {'fact_mist_source_resolved': true},
      ),
    );
    final playedCinematics = <String>[];
    final playedDialogues = <String>[];

    final result = await executeNarrativeEventScene(
      request: NarrativeSceneExecutionRequest(
        eventId: event.id,
        sceneId: scene.id,
        executionId: 'execution_selbrume_terminal_contract',
        gameState: initial,
      ),
      project: project,
      mapsById: const <String, MapData>{},
      currentGameState: () => initial,
      callbacks: SceneRuntimeHostCallbacks(
        evaluateCondition: (_) => throw StateError(
          'The canonical terminal Scene has no runtime condition node.',
        ),
        showDialogue: (intent) {
          playedDialogues.add(intent.dialogueId!);
          return 'completed';
        },
        startBattle: (_) => throw StateError(
          'The canonical terminal Scene has no battle node.',
        ),
        playCinematic: (intent) {
          playedCinematics.add(intent.cinematicId!);
          return 'completed';
        },
      ),
    );

    expect(
      result,
      isA<NarrativeSceneExecutionCompleted>(),
      reason: result is NarrativeSceneExecutionFailed
          ? result.failure.toString()
          : null,
    );
    final completed = result as NarrativeSceneExecutionCompleted;
    expect(playedDialogues, ['dialogue_ending_port']);
    expect(
      playedCinematics,
      ['cinematic_port_celebration', 'cinematic_lighthouse_final_beam'],
    );
    expect(
      completed.updatedGameState.narrativeFactRuntimeState.overridesByFactId,
      containsPair('fact_main_story_completed', true),
    );
    expect(
      completed.updatedGameState.narrativeFactRuntimeState.overridesByFactId,
      containsPair('fact_ending_seen', true),
    );
    expect(
      completed.updatedGameState.progression.completedStepIds,
      containsAll({'step_return_to_port', 'step_main_story_completed'}),
    );
    expect(
      completed.updatedGameState.metadata[sceneGameCompletionEndingMetadataKey],
      'ending.selbrume-sauvee',
    );
    expect(completed.gameCompletion!.endingId, 'ending.selbrume-sauvee');
    expect(
      completed.gameCompletion!.outcome,
      SceneGameCompletionOutcome.victory,
    );
    expect(
      completed.gameCompletion!.postGamePolicy,
      ScenePostGamePolicy.returnToHub,
    );
    expect(completed.gameCompletion!.credits!.skippable, isTrue);
  });
}

ProjectManifest _loadSelbrumeProject() {
  final root = _repositoryRoot();
  return ProjectManifest.fromJson(
    jsonDecode(
      File(p.join(root.path, 'selbrume', 'project.json')).readAsStringSync(),
    ) as Map<String, dynamic>,
  );
}

Directory _repositoryRoot() {
  var current = Directory.current.absolute;
  while (true) {
    if (File(p.join(current.path, 'selbrume', 'project.json')).existsSync()) {
      return current;
    }
    final parent = current.parent;
    if (parent.path == current.path) {
      throw StateError('Repository root containing Selbrume was not found.');
    }
    current = parent;
  }
}
```
