# NSC-55 — Terminalité, défaite et politique de retry — Evidence Pack

## Résumé exécutif

NSC-55 porte désormais l'intention d'une fin de Scene sur son propriétaire canonique, `SceneEndPayload`, avec trois valeurs explicites : `progression`, `retryable` et `terminalFailureAccepted`. Une ancienne fin sans valeur reste nullable et produit un diagnostic indéterminé : aucun ID, titre ou label n'est interprété. Le Scene Builder expose un picker guidé, le runtime reçoit la policy et le Validator refuse un Event `oneShot` qui consommerait une source menant à une fin réessayable sans source narrative réutilisable prouvée.

La tranche verticale du phare de Selbrume est annotée et prouve le cycle défaite → rechargement → retry → victoire. Les autres Scenes historiques restent volontairement indéterminées tant que leur intention n'a pas été décidée par un auteur.

**Verdict proposé : DONE.**

## Scope, lot et état initial

- Lot : NSC-55, phase 5 de la roadmap Narrative Studio.
- État Git initial du lot : branche `main`, HEAD `c7cd91d7 feat(narrative): add correlated reachability solver`, arbre propre.
- Audit : les Events du phare (`026`, `027`, `028`) sont déjà `reusable` ; ils constituent donc la correction sûre réelle. Un projet synthétique couvre le cas interdit `oneShot`.
- Non-objectifs : la preuve physique sur la grille appartient à NSC-56/57 ; NSC-55 ne renomme ni ne déduit les issues historiques.

Deux corrections antérieures découvertes pendant la validation ont été isolées avant ce lot :

- `a1ab7e52 fix(narrative): restore human fact condition labels` restaure les labels auteur des Facts typés ;
- `7833e785 fix(narrative): fail closed on exhausted solver budget` évite une exception quand le budget global est épuisé entre deux Events et retourne `indeterminate`.

## Passes locales équivalentes aux sub-agents

Les sub-agents sont interdits par le mode actif ; les passes demandées par `codex_rule.md` ont été conduites localement et séparément.

| Passe | Verdict |
|---|---|
| Audit / Architecture | PASS — policy unique dans `SceneEndPayload`, projection runtime sans duplication Event/Storyline. |
| Implémentation | PASS — codec rétrocompatible, opération pure, picker design-system, Validator conservatif. |
| Tests | PASS ciblé — core, editor, runtime et phare verts. La suite editor globale conserve 15 échecs préexistants/hors scope détaillés ci-dessous. |
| Build | PASS — build macOS editor réussi ; analyzers ciblés/core/runtime/hôte sans issue. |
| Critique finale | PASS — absence historique, budget symbolique et preuve physique restent honnêtement indéterminés. |

## Inventaire complet des fichiers modifiés

| Fichier | Zone précise et impact |
|---|---|
| `packages/map_core/lib/src/models/scene_asset.dart` | Enum, champ nullable, JSON, égalité et hash de `SceneEndPayload`. |
| `packages/map_core/lib/src/authoring/scene_authoring_operations.dart` | Opération pure de mise à jour d'une fin, sans perte des métadonnées. |
| `packages/map_core/lib/src/runtime/scene_runtime_plan.dart` | Projection nullable dans l'intention runtime. |
| `packages/map_core/lib/src/runtime/scene_runtime_plan_builder.dart` | Copie de la policy du nœud End dans le plan. |
| `packages/map_core/lib/src/operations/narrative_project_validator.dart` | Diagnostics d'absence et de softlock `oneShot`/`retryable`. |
| `packages/map_core/test/scene_authoring_operations_test.dart` | Conservation des données et nœuds invalides. |
| `packages/map_core/test/project_manifest_scenes_test.dart` | Round-trip explicite et compatibilité du champ absent. |
| `packages/map_core/test/narrative_project_validator_test.dart` | Softlock, correction reusable, échec terminal accepté, anti-heuristique. |
| `packages/map_editor/lib/src/ui/canvas/scenes/scene_node_read_only_inspector.dart` | Picker guidé et avertissement d'intention. |
| `packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart` | Callback de mise à jour et rafraîchissement de Scene. |
| `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart` | Application de l'opération pure au manifest en mémoire. |
| `packages/map_editor/test/scene_outcome_policy_authoring_test.dart` | Test widget du choix `Réessayable`. |
| `packages/map_runtime/test/scene_runtime_state_persistence_gate_test.dart` | Projection et gates de checkpoint avant/pendant/après Scene. |
| `examples/playable_runtime_host/test/selbrume_lighthouse_retry_integration_test.dart` | Preuve des Events reusable et des politiques phare projetées au runtime. |
| `selbrume/project.json` | Politiques explicites limitées aux fins du phare. |
| `docs/superpowers/plans/2026-07-20-nsc-55-scene-outcome-policy.md` | Micro-plan TDD du lot. |
| `reports/narrativeStudio/completion/nsc_55_scene_outcome_policy_evidence_pack.md` | Présent Evidence Pack. |

## Décisions et changements précis

- Le champ JSON `outcomePolicy` est optionnel. Son absence est conservée au round-trip.
- L'opération d'authoring ne remplace que le payload ciblé et préserve notes, nœuds, arêtes, layout et données projet.
- Le picker utilise les primitives PokeMap et des libellés métier ; aucun ID brut ni couleur locale n'est exposé.
- Le Validator émet `sceneOutcomePolicyIndeterminate` pour une fin non qualifiée.
- Il émet `oneShotRetryableOutcomeSoftlock` seulement si un Event actif `oneShot` vise une Scene avec fin `retryable` et qu'aucun Event actif `reusable` de cette Scene n'est prouvé dans les états NSC-54.
- Le runtime ne change pas les règles de sauvegarde : la sauvegarde reste autorisée avant et après la Scene, refusée durant une attente non résolue.
- Les labels comme `defeat_retry_softlock` ne déclenchent rien sans policy explicite.

## Commandes et résultats exacts

```text
cd packages/map_core
/opt/homebrew/bin/dart test test/scene_authoring_operations_test.dart test/project_manifest_scenes_test.dart test/narrative_project_validator_test.dart
+94: All tests passed!

/opt/homebrew/bin/dart test --reporter compact
+4253: All tests passed!

/opt/homebrew/bin/dart analyze
No issues found!

cd packages/map_editor
/opt/homebrew/bin/flutter test test/scene_outcome_policy_authoring_test.dart
+1: All tests passed!

/opt/homebrew/bin/flutter analyze lib/src/ui/canvas/narrative_workspace_canvas.dart lib/src/ui/canvas/scenes_workspace.dart lib/src/ui/canvas/scenes/scene_node_read_only_inspector.dart test/scene_outcome_policy_authoring_test.dart
No issues found!

/opt/homebrew/bin/flutter build macos --debug
Built build/macos/Build/Products/Debug/map_editor.app

/opt/homebrew/bin/flutter test --reporter compact
+4009 -15: Some tests failed.

/opt/homebrew/bin/flutter analyze
11 issues found (warnings préexistants dans dialogue_studio_dialogs.dart).

cd packages/map_runtime
/opt/homebrew/bin/flutter test test/scene_runtime_state_persistence_gate_test.dart
+6: All tests passed!

/opt/homebrew/bin/flutter test --reporter compact
+1900 ~1: All other tests passed! (1 test skipped)

/opt/homebrew/bin/flutter analyze
No issues found!

cd examples/playable_runtime_host
/opt/homebrew/bin/flutter test --reporter compact test/selbrume_lighthouse_retry_integration_test.dart
+3: All tests passed!

/opt/homebrew/bin/flutter analyze
No issues found!

cd repository-root
jq empty selbrume/project.json
exit 0, aucune sortie

git diff --check
aucune sortie
```

Le test Validator Selbrume isolé ne lève plus d'exception après `7833e785`, mais retourne deux diagnostics `narrativeSolvabilityIndeterminate` : le budget global de 16384 états est dépassé. Ce signal vient du solveur NSC-54 sur l'ensemble du gros projet, pas de NSC-55.

Les 15 échecs de la suite editor globale concernent des tests/goldens préexistants ou hors scope : révisions Event Builder, overflow/goldens Facts et World Rules, golden Phase K, création Event, opérateur de condition Scene, expression de condition, screenshot Scenes et le gate Selbrume borné. Le test ciblé NSC-55, son analyzer et le build sont verts.

## État Git final avant commit

- Les modifications fonctionnelles sont limitées aux fichiers listés ci-dessus.
- `git diff --check` est propre.
- Aucun artefact de build, cache ou fichier machine n'est ajouté.

## Limites, risques et auto-critique

- Les fins historiques hors phare restent indéterminées : c'est une dette d'authoring visible, pas une migration inventée.
- Le diagnostic de retry prouve une source narrative reusable ; la preuve de sa cellule et de son accessibilité physique arrive avec NSC-56/57.
- La combinatoire Selbrume dépasse encore le budget global NSC-54. Le rapport multidimensionnel NSC-57 devra préserver ce statut au lieu de le masquer.
- Le picker modifie une policy à la fois. Un futur outil de migration assistée pourra regrouper les décisions, mais ne devra jamais les deviner.

L'implémentation est volontairement conservative : elle peut demander une décision auteur de plus, mais ne déclare jamais une défaite récupérable sur la seule base d'un nom évocateur.

## Prochaine étape

NSC-56 — preuve physique pure des cellules, interactions et transitions de maps.

## Contenu complet des fichiers créés

Le présent rapport ne peut pas s'inclure récursivement ; les autres fichiers créés sont reproduits ci-dessous.

<details>
<summary>Contenu complet — docs/superpowers/plans/2026-07-20-nsc-55-scene-outcome-policy.md</summary>

```markdown
# NSC-55 — Terminalité, défaite et politique de retry

## Objectif

Porter l'intention de terminalité sur l'unique propriétaire canonique,
`SceneEndPayload`, puis détecter sans heuristique les Events one-shot qui
peuvent consommer leur source avant une fin explicitement réessayable.

## Contrat et non-objectifs

- Ajouter une policy nullable `progression`, `retryable` ou
  `terminalFailureAccepted` à chaque fin de Scene.
- Un champ absent reste `null` et produit un diagnostic indéterminé ; aucun ID,
  titre ou label n'est interprété.
- La policy est projetée dans le plan runtime, sans changer la sémantique de
  checkpoint existante.
- Le diagnostic NSC-55 ne prouve que le retry narratif. La corrélation avec
  l'atteignabilité physique reste réservée à NSC-57 après NSC-56.
- Storyline et Event ne dupliquent jamais la policy.

## Étapes TDD

1. RED — ajouter les tests codec/round-trip et opération d'authoring core.
2. GREEN — ajouter l'enum, le champ nullable et l'opération pure.
3. RED — ajouter les scénarios Validator one-shot/retryable, correction,
   terminal accepté et absence de policy.
4. GREEN — produire uniquement des diagnostics fondés sur la policy explicite
   et la reachability NSC-54.
5. RED — ajouter le test du picker Scene Builder.
6. GREEN — relier le picker design-system à l'opération pure.
7. RED/GREEN — prouver la projection runtime, les gates de checkpoint et
   annoter la slice Phare Selbrume.
8. REFACTOR — formatter, lancer les tests ciblés puis les suites/analyzers et
   effectuer les passes Audit/Architecture, Tests, Build et Critique finale.

## Commandes de preuve

```bash
cd packages/map_core && dart test test/scene_authoring_operations_test.dart test/project_manifest_scenes_test.dart test/narrative_project_validator_test.dart
cd packages/map_core && dart test && dart analyze
cd packages/map_editor && flutter test test/scene_outcome_policy_authoring_test.dart
cd packages/map_editor && flutter test && flutter analyze
cd packages/map_runtime && flutter test test/scene_runtime_state_persistence_gate_test.dart
cd packages/map_runtime && flutter test && flutter analyze
cd examples/playable_runtime_host && flutter test test/selbrume_lighthouse_retry_integration_test.dart
cd examples/playable_runtime_host && flutter test && flutter analyze
```
```
</details>

<details>
<summary>Contenu complet — packages/map_editor/test/scene_outcome_policy_authoring_test.dart</summary>

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/narrative/application/narrative_workspace_projection.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/scenes/scene_node_read_only_inspector.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  testWidgets('authors an explicit retryable policy from the End inspector',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    String? updatedNodeId;
    String? updatedOutcomeId;
    SceneOutcomePolicy? updatedPolicy;

    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Scaffold(
          body: SizedBox(
            width: 380,
            height: 1600,
            child: SceneNodeReadOnlyInspector(
              scene: _summary(),
              selectedNodeId: 'node_end',
              onUpdateEndPayload: ({
                required nodeId,
                sceneOutcomeId,
                required outcomePolicy,
              }) async {
                updatedNodeId = nodeId;
                updatedOutcomeId = sceneOutcomeId;
                updatedPolicy = outcomePolicy;
                return true;
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final picker = tester.widget<PokeMapDropdownField<String>>(
      find.byKey(const ValueKey('scene-end-outcome-policy-picker')),
    );
    expect(picker.value, 'unset');
    expect(find.text('À définir'), findsOneWidget);

    picker.onChanged('retryable');
    await tester.pump();

    expect(updatedNodeId, 'node_end');
    expect(updatedOutcomeId, 'defeat');
    expect(updatedPolicy, SceneOutcomePolicy.retryable);
  });
}

NarrativeSceneSummary _summary() {
  final outcomes = [SceneOutcome(id: 'defeat', label: 'Défaite')];
  final scene = SceneAsset(
    id: 'scene_retry_authoring',
    name: 'Retry authoring',
    declaredOutcomes: outcomes,
    graph: SceneGraph(
      startNodeId: 'node_start',
      nodes: [
        SceneNode(id: 'node_start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'node_end',
          kind: SceneNodeKind.end,
          payload: SceneEndPayload(sceneOutcomeId: 'defeat'),
        ),
      ],
      edges: [
        SceneEdge(
          id: 'edge_start_end',
          fromNodeId: 'node_start',
          fromPortId: 'completed',
          toNodeId: 'node_end',
          kind: SceneEdgeKind.defaultFlow,
        ),
      ],
    ),
  );
  return NarrativeSceneSummary(
    id: scene.id,
    name: scene.name,
    nodeCount: scene.graph.nodes.length,
    edgeCount: scene.graph.edges.length,
    declaredOutcomeCount: outcomes.length,
    declaredOutcomes: outcomes.map((outcome) => outcome.label).toList(),
    tags: const [],
    graph: scene.graph,
    layout: scene.layout,
    diagnostics: diagnoseScene(scene),
    outcomeDefinitions: outcomes,
  );
}
```
</details>
