# NSC-35 — Outcomes Dialogue et protections de dépendances Scene

Date : 2026-07-20  
Verdict : **DONE proposé**

## Résumé exécutif

Le lot empêche désormais la suppression silencieuse d'un outcome Dialogue encore consommé par une Scene. `map_core` inventorie les usages dans `SceneYarnDialoguePayload.expectedOutcomes`, les ports directs et les ports de `BranchByOutcome` différés. L'identité est toujours `(dialogueId, outcomeId)` : deux Dialogues au même libellé ne sont pas confondus.

Le guard éditeur bloque une mise à jour destructive et fournit un remplacement explicite sous forme de candidate immutable. Cette preview réécrit à la fois le registre Dialogue, les payloads Scene et leurs ports, sans muter le projet source. `UpdateProjectDialogueUseCase` appelle le guard avant persistence et accepte une table explicite de remplacements.

Le document NSC-34 expose aussi les outcomes réellement portés par ses branches structurées afin que NSC-36 puisse comparer le document validé au registre public lors de la sauvegarde.

## Audit et scope

- Les ports dynamiques NSC-31 existaient déjà à partir de `expectedOutcomes`.
- `diagnoseSceneAgainstProject` émettait déjà une erreur `dialogueExpectedOutcomeUnknown`.
- Le manque se situait avant l'écriture : `UpdateProjectDialogueUseCase` acceptait un registre amputé et laissait le diagnostic apparaître après coup.
- `NarrativeDependencyIndex` indexait le Dialogue mais pas ses outcomes imbriqués. Le lot ajoute une opération ciblée dans `project_dialogue_refs.dart`; NSC-37 pourra étendre l'index pour ses nouvelles commandes sans changer cette vérité.
- Yarn ne reçoit aucune écriture de progression : les `<<outcome …>>` restent seulement des résultats de choix.
- Aucun fichier Selbrume, runtime ou schema JSON n'est modifié.

## Passes séparées

Les nouveaux sub-agents étant interdits par la consigne système de cette tâche, les rôles de `codex_rule.md` ont été exécutés en passes locales.

| Passe | Verdict |
|---|---|
| Lovelace — Audit / Architecture | Conforme : réutilisation des ports et diagnostics existants. |
| Peirce — Implémentation | Conforme : inventaire core, preview pure, garde avant persistence. |
| Ramanujan — Tests / Build | Conforme : 113 tests ciblés, 3194 tests core, analyses et build verts. |
| Critique finale | Conforme : IDs stables, `completed` préservé, projet source non muté. |

## Inventaire des fichiers

| Fichier | Zone / impact |
|---|---|
| `packages/map_core/lib/src/operations/project_dialogue_refs.dart` | `DialogueOutcomeSceneUsage`, collecte et remplacement des références Scene. |
| `packages/map_core/test/project_dialogue_declared_outcomes_test.dart` | mêmes labels, ports directs/différés, préservation legacy. |
| `packages/map_core/test/scene_outcome_diagnostics_test.dart` | diagnostic bloquant après outcome orphelin. |
| `packages/map_editor/lib/src/application/services/dialogue_scene_dependency_guard.dart` | décision de blocage et candidate de remplacement. |
| `packages/map_editor/lib/src/application/use_cases/project_dialogue_use_cases.dart` | guard avant persistence et remplacements explicites. |
| `packages/map_editor/lib/src/features/dialogue/application/dialogue_editor_model.dart` | projection `documentOutcomes()` depuis les choix Yarn. |
| `packages/map_editor/test/dialogue_scene_dependency_guard_test.dart` | blocage, identité stable, preview non mutante. |
| `packages/map_editor/test/dialogue_yarn_codec_test.dart` | extraction ID + libellé du document validé. |

## Commandes et résultats

```text
cd packages/map_core
dart test test/project_dialogue_declared_outcomes_test.dart test/scene_outcome_diagnostics_test.dart --reporter failures-only
+7: All tests passed!

dart analyze
No issues found!

dart test --reporter failures-only
+3194: All tests passed!
```

```text
cd packages/map_editor
flutter test test/dialogue_scene_dependency_guard_test.dart test/dialogue_yarn_codec_test.dart test/dialogue_editor_validation_test.dart test/scenes_workspace_shell_test.dart test/project_content_controller_test.dart --reporter failures-only
+113: All tests passed!

flutter analyze
No issues found! (ran in 6.6s)

flutter build macos --debug
✓ Built build/macos/Build/Products/Debug/map_editor.app
```

`git diff --check` sur les huit chemins du lot : code 0, aucune sortie attendue.

## État git

Commit de départ : `35f6e448`. Le test Lighthouse déjà stagé et tous les changements Selbrume préexistants restent hors scope. Après commit ciblé, seuls les huit fichiers ci-dessus et ce rapport doivent entrer dans NSC-35 ; aucun push n'est demandé.

## Contenu complet des fichiers créés

### `packages/map_editor/lib/src/application/services/dialogue_scene_dependency_guard.dart`

```dart
import 'package:map_core/map_core.dart';

final class DialogueSceneDependencyDecision {
  DialogueSceneDependencyDecision._({
    required this.isAllowed,
    required List<DialogueOutcomeSceneUsage> affectedUsages,
    required this.message,
  }) : affectedUsages = List<DialogueOutcomeSceneUsage>.unmodifiable(affectedUsages);

  factory DialogueSceneDependencyDecision.allowed() =>
      DialogueSceneDependencyDecision._(
        isAllowed: true,
        affectedUsages: const <DialogueOutcomeSceneUsage>[],
        message: null,
      );

  factory DialogueSceneDependencyDecision.blocked({
    required List<DialogueOutcomeSceneUsage> affectedUsages,
    required String message,
  }) => DialogueSceneDependencyDecision._(
        isAllowed: false,
        affectedUsages: affectedUsages,
        message: message,
      );

  final bool isAllowed;
  final List<DialogueOutcomeSceneUsage> affectedUsages;
  final String? message;
}

final class DialogueOutcomeReplacementPreview {
  DialogueOutcomeReplacementPreview({
    required this.candidateProject,
    required List<DialogueOutcomeSceneUsage> affectedUsages,
  }) : affectedUsages = List<DialogueOutcomeSceneUsage>.unmodifiable(affectedUsages);
  final ProjectManifest candidateProject;
  final List<DialogueOutcomeSceneUsage> affectedUsages;
}

final class DialogueSceneDependencyGuard {
  const DialogueSceneDependencyGuard();

  DialogueSceneDependencyDecision inspectOutcomeUpdate({
    required ProjectManifest project,
    required String dialogueId,
    required List<DialogueDeclaredOutcome> candidateOutcomes,
  }) {
    final dialogue = _dialogueOrThrow(project, dialogueId);
    final candidateIds = <String>{};
    for (final outcome in candidateOutcomes) {
      final id = outcome.id.trim();
      if (id.isEmpty || !candidateIds.add(id)) {
        return DialogueSceneDependencyDecision.blocked(
          affectedUsages: const <DialogueOutcomeSceneUsage>[],
          message: 'Le registre candidat contient un résultat vide ou dupliqué.',
        );
      }
    }
    final removedIds = <String>{
      for (final outcome in dialogue.declaredOutcomes)
        if (!candidateIds.contains(outcome.id)) outcome.id,
    };
    final affected = <DialogueOutcomeSceneUsage>[
      for (final outcomeId in removedIds)
        ...collectDialogueOutcomeSceneUsages(
          project,
          dialogueId: dialogue.id,
          outcomeId: outcomeId,
        ),
    ];
    if (affected.isEmpty) return DialogueSceneDependencyDecision.allowed();
    final ids = affected.map((usage) => usage.outcomeId).toSet().toList()..sort();
    final scenes = affected.map((usage) => usage.sceneId).toSet().toList()..sort();
    return DialogueSceneDependencyDecision.blocked(
      affectedUsages: affected,
      message: 'Suppression bloquée : ${ids.join(', ')} est encore utilisé '
          'par ${scenes.join(', ')}. Choisissez un remplacement explicite.',
    );
  }

  DialogueOutcomeReplacementPreview previewOutcomeReplacement({
    required ProjectManifest project,
    required String dialogueId,
    required String fromOutcomeId,
    required DialogueDeclaredOutcome replacement,
  }) {
    final dialogue = _dialogueOrThrow(project, dialogueId);
    final from = fromOutcomeId.trim();
    final to = replacement.id.trim();
    if (from.isEmpty || to.isEmpty || from == 'completed' || to == 'completed') {
      throw ArgumentError('Outcome ids must be non-blank and non-reserved.');
    }
    if (!dialogue.declaredOutcomes.any((outcome) => outcome.id == from)) {
      throw ArgumentError.value(fromOutcomeId, 'fromOutcomeId', 'Unknown Dialogue outcome.');
    }
    if (from != to && dialogue.declaredOutcomes.any((outcome) => outcome.id == to)) {
      throw ArgumentError.value(replacement.id, 'replacement', 'Replacement outcome id already exists.');
    }
    final usages = collectDialogueOutcomeSceneUsages(
      project,
      dialogueId: dialogue.id,
      outcomeId: from,
    );
    final withRewrittenScenes = replaceDialogueOutcomeSceneReferences(
      project,
      dialogueId: dialogue.id,
      fromOutcomeId: from,
      toOutcomeId: to,
    );
    final updatedDialogues = [
      for (final candidate in withRewrittenScenes.dialogues)
        if (candidate.id == dialogue.id)
          candidate.copyWith(
            declaredOutcomes: [
              for (final outcome in candidate.declaredOutcomes)
                if (outcome.id == from) replacement else outcome,
            ],
          )
        else
          candidate,
    ];
    return DialogueOutcomeReplacementPreview(
      candidateProject: withRewrittenScenes.copyWith(dialogues: updatedDialogues),
      affectedUsages: usages,
    );
  }
}

ProjectDialogueEntry _dialogueOrThrow(ProjectManifest project, String dialogueId) {
  final normalized = dialogueId.trim();
  for (final dialogue in project.dialogues) {
    if (dialogue.id == normalized) return dialogue;
  }
  throw ArgumentError.value(dialogueId, 'dialogueId', 'Unknown Dialogue.');
}
```

### `packages/map_editor/test/dialogue_scene_dependency_guard_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/services/dialogue_scene_dependency_guard.dart';

void main() {
  const guard = DialogueSceneDependencyGuard();

  test('blocks removing an outcome still consumed by a Scene', () {
    final decision = guard.inspectOutcomeUpdate(
      project: _project(),
      dialogueId: 'dialogue_a',
      candidateOutcomes: const [
        DialogueDeclaredOutcome(id: 'refused', label: 'Refuser'),
      ],
    );
    expect(decision.isAllowed, isFalse);
    expect(decision.affectedUsages.map((usage) => usage.sceneId).toSet(), {'scene_a'});
    expect(decision.message, contains('accepted'));
  });

  test('allows removing an unused outcome and distinguishes equal labels', () {
    final decision = guard.inspectOutcomeUpdate(
      project: _project(),
      dialogueId: 'dialogue_b',
      candidateOutcomes: const <DialogueDeclaredOutcome>[],
    );
    expect(decision.isAllowed, isTrue);
    expect(decision.affectedUsages, isEmpty);
  });

  test('previews an explicit replacement without mutating the source project', () {
    final project = _project();
    final preview = guard.previewOutcomeReplacement(
      project: project,
      dialogueId: 'dialogue_a',
      fromOutcomeId: 'accepted',
      replacement: const DialogueDeclaredOutcome(id: 'approved', label: 'Approuver'),
    );
    final originalPayload = project.scenes.single.graph.nodes
        .where((node) => node.id == 'dialogue').single.payload
        as SceneYarnDialoguePayload;
    final previewPayload = preview.candidateProject.scenes.single.graph.nodes
        .where((node) => node.id == 'dialogue').single.payload
        as SceneYarnDialoguePayload;
    expect(preview.affectedUsages, isNotEmpty);
    expect(originalPayload.expectedOutcomes, ['accepted']);
    expect(previewPayload.expectedOutcomes, ['approved']);
    expect(
      preview.candidateProject.dialogues
          .where((dialogue) => dialogue.id == 'dialogue_a').single
          .declaredOutcomes.map((outcome) => outcome.id),
      ['approved', 'refused'],
    );
  });
}

ProjectManifest _project() {
  return ProjectManifest(
    name: 'Dependency guard',
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
    maps: const [],
    tilesets: const [],
    dialogues: const [
      ProjectDialogueEntry(
        id: 'dialogue_a', name: 'Même nom', relativePath: 'dialogues/a.yarn',
        declaredOutcomes: [
          DialogueDeclaredOutcome(id: 'accepted', label: 'Accepter'),
          DialogueDeclaredOutcome(id: 'refused', label: 'Refuser'),
        ],
      ),
      ProjectDialogueEntry(
        id: 'dialogue_b', name: 'Même nom', relativePath: 'dialogues/b.yarn',
        declaredOutcomes: [DialogueDeclaredOutcome(id: 'accepted', label: 'Accepter')],
      ),
    ],
    scenes: [
      SceneAsset(
        id: 'scene_a', name: 'Scene A',
        graph: SceneGraph(
          startNodeId: 'start',
          nodes: [
            SceneNode(id: 'start', kind: SceneNodeKind.start),
            SceneNode(
              id: 'dialogue', kind: SceneNodeKind.yarnDialogue,
              payload: SceneYarnDialoguePayload(
                dialogueId: 'dialogue_a', expectedOutcomes: const ['accepted'],
              ),
            ),
            SceneNode(id: 'end', kind: SceneNodeKind.end),
          ],
          edges: [
            SceneEdge(
              id: 'start_dialogue', fromNodeId: 'start', fromPortId: 'completed',
              toNodeId: 'dialogue', kind: SceneEdgeKind.defaultFlow,
            ),
            SceneEdge(
              id: 'dialogue_end', fromNodeId: 'dialogue', fromPortId: 'accepted',
              toNodeId: 'end', kind: SceneEdgeKind.dialogueOutcome,
            ),
          ],
        ),
      ),
    ],
  );
}
```

Le présent rapport est le troisième fichier créé ; son contenu complet est ce document.

## Auto-critique et risques

- L'UI de gestion complète des outcomes n'existe pas encore ; NSC-36 devra afficher le guard et demander confirmation de la preview.
- La collecte est structurelle et couvre les payloads/ports Scene. Un futur prédicat Dialogue outcome transportant une identité qualifiée devra rejoindre cet inventaire lorsqu'un wire explicite existera.
- Un remplacement vers un ID déjà déclaré est refusé plutôt que fusionné implicitement, pour éviter deux branches devenant indiscernables.
- Le legacy `completed` n'est jamais traité comme un outcome public renommable.

## Statut

`NSC-35` : **DONE proposé**. Prochaine étape : `NSC-36 — Preview Dialogue, persistance et UI complète`.
