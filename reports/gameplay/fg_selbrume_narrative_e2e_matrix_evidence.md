# Evidence Pack — NSC-82 / Selbrume E2E persistence, runtime, Validator et retry

Date : 2026-07-21

Branche : `main`

Lots Narrative Studio : `NSC-82`

Lots mécaniques alimentés : `FG-180`, `FG-181`, `FG-182`, `FG-183`, `FG-185`

## 1. Résumé exécutif

Verdict du lot : **DONE proposé pour NSC-82**.

Le projet promu `selbrume/` est maintenant prouvé comme structurellement
valide, symboliquement soluble dans le budget borné, physiquement atteignable,
exécutable sur les chemins victoire/défaite/retry et persistant avant/après une
Scene. Une sauvegarde demandée pendant une Scene awaitable reste refusée sans
écrire de fichier. Le reçu runtime `selbrume-release-v1` a été régénéré
atomiquement après les 3 scénarios retry et les 5 parcours joueur.

Ce lot ne ferme pas les lots globaux `FG-180` à `FG-185` : il fournit leur
sous-ensemble Narrative Studio/Selbrume. La roadmap mécanique n'est pas
modifiée, conformément à la demande qui portait sur la phase 8 du plan
Narrative Studio.

## 2. Confirmation du scope

Inclus :

- réduction des permutations symboliques équivalentes ;
- projection physique alignée sur les métriques et masques pixel du runtime ;
- exploration de tous les raccords de maps valides ;
- matrice du projet promu avec défauts injectés ;
- sauvegarde avant/pendant/après Scene réelle et reload ;
- fingerprint promu et reçu runtime frais ;
- tests retry, player journey, combats, boss, saves, Validator et smokes.

Hors scope conservé :

- aucune modification du contenu de campagne Selbrume livré par NSC-81 ;
- aucun changement de schéma ou migration ;
- aucune correction opportuniste des avertissements préexistants de l'éditeur ;
- aucune déclaration de GO pour l'ensemble du MVP mécanique ;
- aucune mise à jour de `pokemap_roadmap_mecaniques_fangame.md`.

## 3. Audit initial

État Git initial après le commit NSC-81 :

```text
$ git status --short --untracked-files=all
(aucune sortie)
```

Contrats et preuves trouvés :

- `map_core` possédait déjà le solveur borné et le Validator structurel ;
- `map_gameplay` possédait déjà le Validator physique, mais celui-ci rejouait
  chaque état symbolique et ne gardait que le premier raccord de map ;
- le host possédait déjà 5 parcours joueur et 3 scénarios retry du phare ;
- le runtime possédait déjà les tests combat, boss, save/load et Validator bêta ;
- l'éditeur consommait déjà un reçu neutre et fail-closed ;
- le reçu et le fingerprint étaient devenus stale après NSC-81.

Risques identifiés avant modification : explosion factorielle du solveur,
faux négatifs physiques sur les collisions pixel 32 px, mauvais point d'entrée
sur les raccords, écriture pendant une Scene suspendue et preuve runtime stale.

## 4. Passes manuelles exigées par `codex_rule.md`

Les sub-agents sont interdits par l'orchestrateur actif ; les cinq rôles ont
donc été exécutés comme passes manuelles séparées et nommées.

| Passe | Verdict | Signal |
|---|---|---|
| Audit / Architecture | PASS | frontières `map_core` / `map_gameplay` / `map_runtime` / host préservées |
| Implémentation | PASS | réduction canonique, projection physique, matrice et receipt isolés |
| Tests | PASS | régressions positives, négatives et fail-closed ajoutées |
| Build / Validation | PASS avec note | app macOS produite ; avertissements Swift tiers seulement |
| Critique finale | PASS avec risques documentés | aucune modification étrangère détectée ; deux limites de projection conservées |

## 5. Inventaire complet des fichiers

| Fichier | Zone modifiée | Raison / impact |
|---|---|---|
| `packages/map_core/lib/src/operations/narrative_symbolic_reachability_solver.dart` | boucle des Events éligibles | exécute le prochain Event selon priorité/order et conserve les branches internes de Scene |
| `packages/map_core/test/narrative_symbolic_reachability_solver_test.dart` | régressions du budget | prouve les Events indépendants et le prédécesseur qui rend un Event éligible |
| `packages/map_gameplay/lib/src/validation/narrative_physical_reachability_validator.dart` | états canoniques, monde, raccords, BFS | déduplique les états sans effet physique, respecte 32 px/masques pixel et tous les raccords |
| `packages/map_gameplay/test/narrative_physical_reachability_validator_test.dart` | régressions projection/raccord | prouve la déduplication et une entrée jouable qui n'est pas le premier raccord |
| `packages/map_runtime/test/selbrume_narrative_campaign_outcome_matrix_test.dart` | **fichier créé** | matrice promue, défauts injectés et checkpoint Scene réel |
| `examples/playable_runtime_host/test/selbrume_event_v2_promoted_project_test.dart` | constante SHA-256 | verrouille le nouveau manifeste canonique NSC-81 |
| `packages/map_editor/test/selbrume_narrative_validator_test.dart` | verdict et reçu | attend désormais `pass` et un reçu frais |
| `selbrume/.pokemap/validation/narrative_runtime_smoke_receipt.json` | preuve générée | fingerprint `sha256:dab55e...`, 3 retry + 5 journey verts |
| `docs/superpowers/plans/2026-07-21-nsc-82-selbrume-e2e-persistence-validator.md` | **fichier créé** | micro-plan exécutable et cases clôturées |
| `reports/gameplay/fg_selbrume_narrative_e2e_matrix_evidence.md` | **fichier créé** | présent Evidence Pack ; auto-inclusion impossible par définition |

## 6. Diffs / zones précises

### Solveur symbolique

Dans `solveNarrativeSymbolicReachability`, la boucle qui exécutait chaque
sibling depuis le même état a été remplacée par `candidates.first`. Les
définitions sont déjà triées par priorité décroissante puis ordre croissant.
Chaque Scene continue de produire toutes ses branches, et le prochain Event
est recalculé au tour de frontière suivant.

### Validator physique

- `_canonicalStates` ne conserve que les Facts, Steps et Events consommés qui
  alimentent une World Rule de visibilité physique ;
- `_exploreSymbolicState` réutilise un monde par map et déduplique les positions
  appartenant à la même composante praticable ;
- les `tileWidth`/`tileHeight` du manifeste sont transmis au monde ;
- `_findPathsToAll` emploie le masque pixel au centre de cellule et rejette
  l'eau en marche ;
- chaque raccord aligné atteignable est testé et le landing doit être accepté
  par `targetWorld.isBlocked`, comme dans le runtime.

### Matrice runtime

- baseline Selbrume : erreurs structurelles vides, symbolique `pass`, physique
  `pass` ;
- suppression de `scene_final_pokemon` : diagnostic
  `narrativeEventSceneMissing` ;
- suppression de `tr_sommet_confrontation` : défaut structurel et physique
  `missingSourceTarget` ;
- Scene réelle `scene_lysa_port` : save avant acceptée, save suspendue refusée
  sans fichier, victoire/End, save et reload identiques.

## 7. Tests et résultats exacts

```text
cd packages/map_core
/opt/homebrew/bin/dart test --reporter compact
02:02 +4323: All tests passed!
/opt/homebrew/bin/dart analyze
No issues found!

cd packages/map_gameplay
/opt/homebrew/bin/dart test --reporter compact
00:03 +300: All tests passed!
/opt/homebrew/bin/dart analyze
No issues found!

cd packages/map_runtime
/opt/homebrew/bin/flutter test --no-pub \
  test/selbrume_event_v2_trigger_battle_anchor_integration_test.dart \
  test/selbrume_static_boss_playable_map_game_integration_test.dart \
  test/narrative_event_save_load_busy_gate_test.dart \
  test/narrative_outcome_outbox_save_load_test.dart \
  test/narrative_event_progress_save_load_test.dart \
  test/p6_selbrume_save_load_golden_slice_test.dart \
  test/p6_selbrume_beta_validator_pass_test.dart \
  test/selbrume_narrative_campaign_outcome_matrix_test.dart
01:17 +15: All tests passed!

/opt/homebrew/bin/flutter test --no-pub \
  test/phase_a_golden_battle_slice_smoke_test.dart
00:00 +3: All tests passed!

/opt/homebrew/bin/flutter analyze --no-pub
No issues found! (ran in 4.5s)

cd packages/map_editor
/opt/homebrew/bin/flutter test --no-pub \
  test/selbrume_narrative_validator_test.dart
00:41 +1: All tests passed!
/opt/homebrew/bin/flutter analyze --no-pub \
  test/selbrume_narrative_validator_test.dart
No issues found! (ran in 2.4s)

cd examples/playable_runtime_host
/opt/homebrew/bin/flutter test --no-pub \
  test/selbrume_event_v2_promoted_project_test.dart
00:02 +1: All tests passed!
/opt/homebrew/bin/flutter test --no-pub \
  test/phase_a_golden_slice_launch_test.dart
00:00 +1: All tests passed!
/opt/homebrew/bin/flutter analyze --no-pub
No issues found! (ran in 4.9s)
```

Producteur du reçu :

```text
FLUTTER_BIN=/opt/homebrew/bin/flutter /opt/homebrew/bin/dart run \
  tool/verify_narrative_project.dart \
  --project-root ../../selbrume \
  --profile selbrume-release-v1 \
  --write-receipt

selbrume-lighthouse-retry: 00:03 +3: All tests passed!
selbrume-player-journey: 03:27 +5: All tests passed!
result: pass
projectFingerprint: sha256:dab55e949848f49bcfb863bc4c771ffbf0bed6cdad8f1203679a4232bf79d445
```

Analyse complète éditeur, non maquillée :

```text
cd packages/map_editor
/opt/homebrew/bin/flutter analyze --no-pub
11 issues found. (ran in 6.4s)
```

Les 11 avertissements sont tous préexistants et localisés dans
`lib/src/ui/canvas/dialogue_studio/dialogs/dialogue_studio_dialogs.dart`
(`unused_element` et accès Riverpod/State protégés). Aucun fichier du lot ne
touche cette zone. L'analyse ciblée du test modifié est propre.

## 8. Build

```text
cd examples/playable_runtime_host
/opt/homebrew/bin/flutter build macos --debug --no-pub
✓ Built build/macos/Build/Products/Debug/playable_runtime_host.app
```

Xcode a émis des avertissements Swift 6 dans `audioplayers_darwin-6.5.0` et
un avertissement de dépréciation dans `file_selector_macos-0.9.5`. Le build a
terminé avec le code 0 et l'application a été produite.

## 9. Limites et risques restants

1. Le solveur démontre un ordre existentiel canonique des Events éligibles ;
   il ne tente plus toutes les permutations de choix spatial du joueur.
2. La preuve physique statique utilise la projection du masque pixel au centre
   de cellule. Les parcours host restent la preuve supérieure pour les
   transitions pixel par pixel et compensent cette abstraction.
3. Le reçu prouve les suites déclarées du profil v1 ; la matrice Validator est
   une gate séparée et n'est pas ajoutée au profil pour éviter de changer son
   contrat sans lot de versionnement dédié.
4. Les avertissements éditeur préexistants restent à traiter dans un chantier
   distinct.

## 10. Auto-critique finale

- Modifications inutiles : aucune détectée ; le contenu Selbrume reste stable.
- Effets de bord : la sélection canonique change la stratégie du solveur mais
  pas l'autorité runtime ; 4323 tests core réduisent le risque.
- Commentaires : les décisions non triviales du solveur et du raccord physique
  sont expliquées au point de décision.
- Tests insuffisants : la sous-cellule pixel n'est pas exhaustivement prouvée
  par le Validator statique ; le player journey réel couvre la campagne.
- Scope mélangé : le correctif physique était nécessaire à la matrice NSC-82,
  et reste dans `map_gameplay` sans dépendance Flutter.
- Mensonge potentiel : aucun verdict global MVP n'est déclaré ; seul NSC-82 est
  proposé DONE.

## 11. État Git final avant commit

Les seuls changements attendus sont les dix fichiers listés en section 5.
`git diff --check` ne retourne aucune erreur. Le commit isolé attendu est :

```text
test(narrative): prove Selbrume persistence matrix
```

## 12. Contenu complet des fichiers créés

Le présent rapport ne peut pas s'auto-inclure. Les deux autres fichiers créés
sont reproduits intégralement ci-dessous.

### `docs/superpowers/plans/2026-07-21-nsc-82-selbrume-e2e-persistence-validator.md`

```markdown
# NSC-82 Selbrume E2E Persistence / Validator Implementation Plan

**Goal:** Prouver sur le projet promu Selbrume les chemins victoire, défaite,
retry, sauvegarde/reload, non-double application et les quatre dimensions du
Validator, puis produire un receipt runtime frais.

**Architecture:** Le projet solver `map_core` conserve les corrélations de
branches mais ordonnance canoniquement les Events simultanément éligibles afin
de ne pas explorer leurs permutations équivalentes. Les tests runtime chargent
`selbrume/project.json` et ses vraies maps. Le host reste l'unique producteur du
receipt neutre consommé par l'éditeur.

## Task 1 — Baseline et RED Validator

- [x] Capturer le fingerprint promu devenu stale après NSC-81.
- [x] Ajouter une régression pure montrant que des Events indépendants ne
  doivent pas épuiser le budget par permutations.
- [x] Ajouter la matrice runtime Selbrume et constater le verdict symbolique
  `indeterminate` avant correction.

## Task 2 — Solveur borné sans permutations équivalentes

- [x] Exécuter un seul Event éligible par état selon priorité/order canonique ;
  conserver toutes les branches internes de sa Scene.
- [x] Prouver qu'un Event devenu éligible après un prédécesseur est encore
  exécuté.
- [x] Conserver budget dépassé = `indeterminate`, jamais `pass`.
- [x] Vérifier les tests map_core complets.

## Task 3 — Matrice promue persistence / défauts

- [x] Créer `selbrume_narrative_campaign_outcome_matrix_test.dart`.
- [x] Vérifier baseline structure, solvabilité et atteignabilité physique.
- [x] Injecter une Scene manquante et un trigger physique manquant ; vérifier
  que les dimensions se dégradent sans faux PASS.
- [x] Exécuter une Scene réelle suspendue : save avant acceptée, pendant
  refusée sans fichier, après End acceptée et reload identique.
- [x] Vérifier les politiques de fin et la non-double application déjà
  traversées par les tests retry/journey.

## Task 4 — Snapshot, receipt et gates existantes

- [x] Mettre à jour le fingerprint manifeste attendu après le changement
  canonique NSC-81.
- [x] Lancer promoted project, player journey, lighthouse retry, trigger battle,
  static boss, save/load et beta Validator.
- [x] Produire atomiquement un receipt `selbrume-release-v1` frais.
- [x] Vérifier que l'éditeur lit le receipt avec le même fingerprint.

## Task 5 — Evidence Pack et commit

- [x] Exécuter format/test/analyze ciblés puis suites package proportionnées.
- [x] Exécuter le smoke Phase A et le build macOS host avec Flutter compatible.
- [x] Produire `reports/gameplay/fg_selbrume_narrative_e2e_matrix_evidence.md`.
- [x] Commit isolé : `test(narrative): prove Selbrume persistence matrix`.
```

### `packages/map_runtime/test/selbrume_narrative_campaign_outcome_matrix_test.dart`

```dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/application/narrative_runtime_activity_gate.dart';
import 'package:map_runtime/src/application/narrative_scene_runtime_execution.dart';
import 'package:map_runtime/src/application/save_game_use_case.dart';
import 'package:map_runtime/src/application/scene_runtime/scene_fact_condition_runtime_resolver.dart';
import 'package:map_runtime/src/application/scene_runtime/scene_runtime_host_callbacks.dart';
import 'package:map_runtime/src/infrastructure/file_game_save_repository.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('promoted Selbrume Validator dimensions fail closed on injected defects',
      () {
    final fixture = _loadSelbrume();
    final baseline = validateNarrativeProject(
      fixture.project,
      maps: fixture.mapsById.values.toList(growable: false),
    );

    expect(baseline.narrativelySolvable, NarrativeSymbolicVerdict.pass);
    expect(
      baseline.diagnostics.where(
        (diagnostic) =>
            diagnostic.severity == NarrativeProjectDiagnosticSeverity.error,
      ),
      isEmpty,
    );
    final physical = validateNarrativePhysicalReachability(
      project: fixture.project,
      maps: fixture.mapsById.values.toList(growable: false),
      narrativeReport: baseline.symbolicReachability!,
    );
    expect(
      physical.verdict,
      NarrativePhysicalReachabilityVerdict.pass,
      reason: <String>[
        'reachableMaps=${physical.reachableMapIds.toList()..sort()}',
        'completedSteps=${baseline.symbolicReachability!.exploredStates.expand((state) => state.completedStepIds).toSet().toList()..sort()}',
        ...physical.issues.map(
          (issue) => '${issue.code.name}: ${issue.message}',
        ),
      ].join('\n'),
    );

    final missingScene = fixture.project.copyWith(
      scenes: fixture.project.scenes
          .where((scene) => scene.id != 'scene_final_pokemon')
          .toList(growable: false),
    );
    final missingSceneReport = validateNarrativeProject(
      missingScene,
      maps: fixture.mapsById.values.toList(growable: false),
    );
    expect(missingSceneReport.errorCount, greaterThan(0));
    expect(
      missingSceneReport.diagnostics.map((diagnostic) => diagnostic.code),
      contains('narrativeEventSceneMissing'),
    );

    final summit = fixture.mapsById['map_sommet_phare']!;
    final mapsWithoutBossTrigger = <String, MapData>{
      ...fixture.mapsById,
      summit.id: summit.copyWith(
        triggers: summit.triggers
            .where((trigger) => trigger.id != 'tr_sommet_confrontation')
            .toList(growable: false),
      ),
    };
    final missingTriggerReport = validateNarrativeProject(
      fixture.project,
      maps: mapsWithoutBossTrigger.values.toList(growable: false),
    );
    expect(missingTriggerReport.errorCount, greaterThan(0));
    final missingTriggerPhysical = validateNarrativePhysicalReachability(
      project: fixture.project,
      maps: mapsWithoutBossTrigger.values.toList(growable: false),
      narrativeReport: missingTriggerReport.symbolicReachability!,
    );
    expect(
      missingTriggerPhysical.verdict,
      isNot(NarrativePhysicalReachabilityVerdict.pass),
    );
    expect(
      missingTriggerPhysical.issues.map((issue) => issue.code),
      contains(NarrativePhysicalIssueCode.missingSourceTarget),
    );
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('real Lysa awaitable blocks save, then End persists across reload',
      () async {
    final fixture = _loadSelbrume();
    final directory =
        await Directory.systemTemp.createTemp('selbrume_lysa_checkpoint_');
    addTearDown(() => directory.delete(recursive: true));
    final gate = NarrativeRuntimeActivityGate();
    final repository = _TempFileGameSaveRepository(directory, gate: gate);
    final save = SaveGameUseCase(repository);
    var state = GameState(
      saveId: 'selbrume_lysa_checkpoint',
      currentMapId: 'map_port_brisants',
      narrativeFactRuntimeState: NarrativeFactRuntimeState(
        overridesByFactId: const <String, bool>{
          'fact_port_alert_seen': true,
        },
      ),
    );

    expect(await save.execute(state), isTrue);
    final saveFile = File(await repository.exposedSaveFilePath());
    expect(await saveFile.exists(), isTrue);
    await saveFile.delete();

    final dialogueStarted = Completer<void>();
    final dialogueRelease = Completer<void>();
    final execution = gate.runWithActivity(
      NarrativeRuntimeActivity.sceneSuspended,
      () => executeNarrativeEventScene(
        request: NarrativeSceneExecutionRequest(
          eventId: 'evt_checkpoint_lysa',
          sceneId: 'scene_lysa_port',
          executionId: 'execution_checkpoint_lysa',
          gameState: state,
        ),
        project: fixture.project,
        mapsById: fixture.mapsById,
        currentGameState: () => state,
        callbacks: SceneRuntimeHostCallbacks(
          evaluateCondition: (intent) => _resolveCondition(
            fixture.project,
            state,
            intent,
          ),
          showDialogue: (_) async {
            dialogueStarted.complete();
            await dialogueRelease.future;
            return 'confident';
          },
          startBattle: (_) => 'victory',
          playCinematic: (_) => 'completed',
        ),
      ),
    );
    await dialogueStarted.future;

    expect(await save.execute(state), isFalse);
    expect(await saveFile.exists(), isFalse);

    dialogueRelease.complete();
    final result = await execution;
    expect(result, isA<NarrativeSceneExecutionCompleted>());
    state = (result as NarrativeSceneExecutionCompleted).updatedGameState;
    expect(
      result.qualifiedOutcomes,
      contains(
        NarrativeOutcomeRef(
          producerKind: NarrativeOutcomeProducerKind.scene,
          producerId: 'scene_lysa_port',
          outcomeId: 'lysa.victory',
        ),
      ),
    );
    expect(gate.activity, NarrativeRuntimeActivity.idle);
    expect(await save.execute(state), isTrue);

    final reloaded = await repository.load();
    expect(reloaded, isNotNull);
    expect(
      saveDataFromGameState(reloaded!).toJson(),
      saveDataFromGameState(state).toJson(),
    );
    expect(
      reloaded.narrativeFactRuntimeState.overridesByFactId,
      containsPair('fact_lysa_tone_confident', true),
    );
  });
}

String _resolveCondition(
  ProjectManifest project,
  GameState state,
  SceneRuntimePlanIntent intent,
) {
  final source = intent.conditionSource;
  if (source == null) {
    throw StateError('The Selbrume checkpoint Scene condition is missing.');
  }
  if (source.sourceKind != SceneConditionSourceKind.fact) {
    throw UnsupportedError(
      'Condition ${source.sourceKind.name} is outside this checkpoint test.',
    );
  }
  return evaluateCanonicalNarrativeFactSceneCondition(
    source: source,
    gameState: state,
    resolver: NarrativeFactRuntimeResolver.fromFacts(project.facts),
  )
      ? 'true'
      : 'false';
}

({ProjectManifest project, Map<String, MapData> mapsById}) _loadSelbrume() {
  final root = _findRepositoryRoot();
  final projectRoot = Directory(p.join(root.path, 'selbrume'));
  final project = ProjectManifest.fromJson(
    _readJson(File(p.join(projectRoot.path, 'project.json'))),
  );
  return (
    project: project,
    mapsById: <String, MapData>{
      for (final entry in project.maps)
        entry.id: MapData.fromJson(
          _readJson(File(p.join(projectRoot.path, entry.relativePath))),
        ),
    },
  );
}

Directory _findRepositoryRoot() {
  var current = Directory.current.absolute;
  while (true) {
    if (File(p.join(current.path, 'AGENTS.md')).existsSync() &&
        File(p.join(current.path, 'selbrume', 'project.json')).existsSync()) {
      return current;
    }
    if (current.parent.path == current.path) {
      throw StateError('pokemonProject repository root not found.');
    }
    current = current.parent;
  }
}

Map<String, dynamic> _readJson(File file) =>
    (jsonDecode(file.readAsStringSync()) as Map).cast<String, dynamic>();

final class _TempFileGameSaveRepository extends FileGameSaveRepository {
  _TempFileGameSaveRepository(
    this.testDirectory, {
    required NarrativeRuntimeActivityGate gate,
  }) : super(activityGate: gate);

  final Directory testDirectory;

  Future<String> exposedSaveFilePath() => getSaveFilePath();

  @override
  Future<String> getSaveFilePath() async {
    final directory = Directory(p.join(testDirectory.path, 'pokemonProject'));
    await directory.create(recursive: true);
    return p.join(directory.path, 'game_save.json');
  }
}
```
