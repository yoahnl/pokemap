# NSC-33 — Catalogue complet Conditions, Actions et Conséquences

Date de clôture proposée : 2026-07-20  
Phase : 3 — Scenes, Dialogues et Actions  
Verdict : **DONE proposé**, avec une réserve d'infrastructure documentée sur les suites Flutter complètes.

## Résumé exécutif

Le lot expose désormais les huit conséquences réellement prises en charge par le runtime Scene : `setFact`, `markEventConsumed`, `completeStoryStep`, `giveItem`, `takeItem`, `giveMoney`, `givePokemon` et `giveConfiguredStarter`. Le dernier trou d'authoring, `completeStoryStep`, utilise un picker guidé construit à partir des Storylines et des anciens StorySteps du projet, avec libellé humain et ID stable.

Le dry-run Scene transporte un état de conséquences explicite et produit, dans l'ordre d'exécution, un résumé avant/après. Le runtime prévalide chaque nœud Action avant son écriture : une conséquence invalide ne modifie pas le nœud courant, arrête la Scene, et ne rejoue ni ne prétend annuler les checkpoints antérieurs déjà validés.

## Confirmation du scope

Le wire canonique reste `SceneActionPayload.consequence` contenant exactement une `SceneConsequence`. Aucun kind `Reward`, aucun batch parallèle et aucune règle métier dupliquée n'ont été introduits. Les types, diagnostics et opérations d'authoring déjà présents ont été réutilisés au lieu d'être réécrits artificiellement.

## Audit initial

### Contrats trouvés

- `SceneConsequence` modélisait déjà les huit kinds visés.
- `SceneConsequenceRuntimeWriter` appliquait déjà leurs écritures persistantes.
- les diagnostics vérifiaient déjà références, quantités et forme des payloads ;
- le Scene Builder exposait sept conséquences sur huit ; `completeStoryStep` manquait ;
- le dry-run ne projetait aucun état avant/après ;
- l'exécution runtime pouvait accumuler plusieurs actions avant de découvrir une conséquence invalide à la fin de la Scene.

### Risques identifiés

- dupliquer les contrats existants uniquement pour cocher la liste de fichiers prévisionnelle ;
- afficher des StorySteps techniques ou inventés au lieu des éléments du projet ;
- confondre atomicité d'un nœud et rollback global d'une Scene ;
- exposer une erreur runtime après avoir continué les callbacks interactifs suivants ;
- inclure dans le commit les changements Selbrume préexistants ou le test déjà stagé par l'utilisateur.

### Limites de scope préservées

- conditions runtime limitées aux prédicats réellement supportés ;
- aucune conséquence interactive ajoutée au payload state-only ;
- aucune modification des règles items, argent, équipe ou starter ;
- aucun changement dans les fichiers Selbrume en cours de travail ;
- aucune mise à jour du statut des lots FG.

## Passes séparées imposées par `codex_rule.md`

L'environnement de cette tâche interdit explicitement de créer de nouveaux sub-agents. Les rôles requis ont donc été réalisés comme passes locales séparées, conformément au fallback prévu par `codex_rule.md`.

| Passe | Verdict | Signal principal |
|---|---|---|
| Lovelace — Audit / Architecture | Conforme | Contrats existants réutilisés ; aucun second wire de conséquence. |
| Peirce — Implémentation / Design system | Conforme | Picker StoryStep guidé et contrôles Scene existants étendus. |
| Ramanujan — Tests / Build | Conforme avec réserve | Tests ciblés, analyses et build verts ; suites complètes perturbées par une autre suite Flutter concurrente. |
| Critique finale | Conforme | Pas de fichier Selbrume inclus ; atomicité par nœud et arrêt immédiat prouvés. |

## Inventaire complet des fichiers du lot

| Fichier | Zones modifiées | Raison et impact |
|---|---|---|
| `packages/map_core/lib/src/runtime/scene_runtime_dry_run_preview.dart` | `SceneDryRunConsequenceState`, `SceneDryRunConsequenceChange`, input/result et application des conséquences | Donne au preview un état contrôlé et une trace ordonnée avant/après. |
| `packages/map_core/test/scene_runtime_dry_run_preview_test.dart` | scénarios de conséquences et erreur | Prouve les huit kinds, l'ordre et l'absence de mutation du nœud invalide. |
| `packages/map_editor/lib/src/features/narrative/state/scene_consequence_catalog_providers.dart` | catalogue `storySteps`, `withStorySteps`, `withProjectStorySteps` | Projette les Storylines et StorySteps legacy en options guidées. |
| `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart` | construction des catalogues Scene | Injecte les StorySteps réels du projet dans le workspace. |
| `packages/map_editor/lib/src/ui/canvas/scenes/scene_node_read_only_inspector.dart` | résumé, diagnostic et édition `completeStoryStep` | Rend la conséquence lisible et modifiable sans ID libre. |
| `packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart` | mode de picker, bouton et formulaire StoryStep | Rend `completeStoryStep` créable no-code. |
| `packages/map_editor/test/scene_consequence_authoring_test.dart` | nouveau test de catalogue | Prouve libellé humain et conservation de l'ID stable. |
| `packages/map_editor/test/scenes_workspace_shell_test.dart` | fixture Storyline et parcours créer/éditer | Prouve le parcours UI complet du picker StoryStep. |
| `packages/map_runtime/lib/src/application/narrative_scene_runtime_execution.dart` | validation au callback Action | Arrête la Scene avant tout callback suivant si le nœud courant est invalide. |
| `packages/map_runtime/lib/src/application/scene_runtime/scene_consequence_runtime_writer.dart` | `applyOne` | Fournit un checkpoint immuable atomique pour une conséquence. |
| `packages/map_runtime/lib/src/application/scene_runtime/scene_event_runtime_hook.dart` | prévalidation par Action et propagation de l'échec writer | Aligne l'exécution Event→Scene sur la même frontière d'atomicité. |
| `packages/map_runtime/test/narrative_scene_runtime_execution_test.dart` | échec de la deuxième Action | Prouve arrêt avant Battle et état externe inchangé. |
| `packages/map_runtime/test/scene_consequence_runtime_writer_test.dart` | test `applyOne` | Prouve résultat immuable et non-mutation de l'entrée. |
| `packages/map_runtime/test/scene_event_runtime_hook_test.dart` | attente de checkpoint par nœud | Prouve conservation du premier checkpoint et rejet atomique du second. |

Diff synthétique avant rapport : **13 fichiers suivis, 913 insertions, 21 suppressions**, plus le nouveau test d'authoring ci-dessous.

## Contenu complet du fichier créé

### `packages/map_editor/test/scene_consequence_authoring_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/narrative/state/scene_consequence_catalog_providers.dart';

void main() {
  test('story step consequence catalog keeps human labels and stable IDs', () {
    final catalogs =
        const SceneConsequenceCatalogs.unavailable().withStorySteps(
      [
        NarrativeStoryStepPickerOption(
          stepId: 'step_leave_port',
          humanLabel: 'Quitter le port',
          description: 'Objectif de départ.',
          sourceScenarioId: 'story_main',
          sourceScenarioLabel: 'Histoire principale',
          sourceKind: NarrativeStoryStepPickerSource.stepStudio,
          order: 0,
          linkedCutsceneIds: const <String>[],
          expectedOutcomeIds: const <String>[],
          emittedOutcomeIds: const <String>[],
          debugTechnicalLabel: 'story_main:chapter_port:step_leave_port',
        ),
      ],
    );

    expect(catalogs.storySteps.isReady, isTrue);
    expect(catalogs.storySteps.options.single.id, 'step_leave_port');
    expect(catalogs.storySteps.options.single.label, 'Quitter le port');
  });
}
```

Le présent Evidence Pack est lui-même un fichier créé ; son contenu complet est ce document.

## Tests et validations

### Ciblés — verts

```text
cd packages/map_core
dart test test/scene_runtime_dry_run_preview_test.dart test/scene_diagnostics_test.dart test/scene_runtime_executor_test.dart
+65: All tests passed!
```

```text
cd packages/map_runtime
flutter test test/scene_event_runtime_hook_test.dart test/scene_consequence_runtime_writer_test.dart test/narrative_scene_runtime_execution_test.dart --reporter failures-only
+51: All tests passed!
```

```text
cd packages/map_editor
flutter test test/scene_consequence_authoring_test.dart test/scenes_workspace_shell_test.dart --reporter failures-only
+89: All tests passed!
```

Après extension du test d'édition de l'inspecteur :

```text
flutter test test/scenes_workspace_shell_test.dart --plain-name "creates and edits complete story step with guided project picker"
+1: All tests passed!
```

### Suites et analyses package

```text
cd packages/map_core && dart analyze
No issues found!

cd packages/map_core && dart test --reporter failures-only
+3191: All tests passed!

cd packages/map_runtime && flutter analyze
No issues found! (ran in 9.0s)

cd packages/map_editor && flutter analyze
No issues found! (ran in 13.5s)
```

La suite complète `map_runtime` a atteint `+1832 ~1 -1` avec un seul timeout historique :

```text
test/p6_selbrume_save_load_golden_slice_test.dart
TimeoutException after 0:00:30.000000
```

Relancé seul :

```text
flutter test test/p6_selbrume_save_load_golden_slice_test.dart --reporter failures-only
+1: All tests passed! (29.18 s)
```

La suite complète `map_editor` a été interrompue lorsqu'une autre suite Flutter, provenant d'un autre worktree du projet, a été détectée en concurrence. Avant l'interruption, quatre tests historiques de performance avaient expiré ou dépassé leur budget, dont `narrative_event_authoring_snapshot_performance_test.dart` et `narrative_event_validation_incremental_performance_test.dart`. Ces résultats ne sont donc pas présentés comme verts et ne sont pas attribués à NSC-33.

### Build

```text
cd packages/map_editor && flutter build macos --debug
✓ Built build/macos/Build/Products/Debug/map_editor.app
```

### Hygiène diff

```text
git diff --check -- <14 chemins NSC-33>
```

Résultat : aucune sortie, code 0.

## État git

### État initial pertinent

Le worktree comportait déjà des modifications utilisateur Selbrume dans le host, le seed éditeur, des tests runtime, `selbrume/project.json`, un rapport non suivi et un test Lighthouse déjà stagé. Elles sont hors scope et ne doivent pas être capturées par le commit NSC-33.

### État final attendu après commit ciblé

- les 14 fichiers de code/test NSC-33 et ce rapport sont commités ;
- le test Lighthouse reste stagé exactement comme avant ;
- tous les autres changements Selbrume restent non commités ;
- aucun push n'est réalisé.

## Critique finale et risques restants

- La projection StoryStep fusionne la source Storyline canonique et la source globale legacy en préférant le premier ID rencontré ; c'est volontaire pour éviter les doublons, mais une future UI de provenance pourrait rendre ce choix plus explicite.
- Le dry-run projette les conséquences à partir d'un plan déjà validé. Les diagnostics restent l'autorité sur les références et la forme ; le dry-run ne devient pas un second validateur métier.
- Le runtime Event→Scene peut restituer les checkpoints précédents dans son état d'échec, tandis que le coordinateur Event de niveau supérieur conserve sa propre politique transactionnelle. Cette distinction doit rester documentée pour éviter de promettre un rollback global inexistant au niveau Scene.
- La suite Flutter complète devra être rejouée lors du gate de phase dans un environnement sans processus Flutter concurrent. Les tests ciblés, analyses et build apportent toutefois une preuve fraîche directement liée au lot.

## Statut proposé et prochaine étape

`NSC-33`: **DONE proposé**.  
Prochaine étape : `NSC-34 — Document Dialogue, nœuds Yarn et codec lossless`, sans préjuger de son audit ni modifier les contrats Dialogue dans ce lot.
