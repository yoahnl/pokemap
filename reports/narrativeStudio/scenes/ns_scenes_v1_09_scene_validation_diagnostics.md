# NS-SCENES-V1-09 — Scene Validation Diagnostics

## Résumé exécutif

Verdict : lot réalisé.

Un premier système de diagnostics Scene V1 existe côté `map_core`. Il est pur, déterministe, non mutating, et vérifie les erreurs/warnings structurels avant d'élargir l'authoring. Le workspace `Scènes` projette ces diagnostics, affiche un badge dans l'arborescence et une section `Diagnostics` dans l'inspecteur read-only.

Le lot ne crée aucun authoring node/edge/payload/layout, aucun runtime, aucun adapter legacy, aucun lien Storylines.

Prochain lot recommandé : `NS-SCENES-V1-10 — Runtime Execution Prep`.

## Design / Architecture Gate

- Diagnostics placés dans `packages/map_core/lib/src/diagnostics/scene_diagnostics.dart`.
- `map_core` possède les règles pures : graph, start/end, edges, layout, outcomes.
- `map_editor` ne recalcule pas de règles métier : il consomme `diagnoseScene(scene)` via la projection.
- `SceneDiagnosticsReport` expose les compteurs `errorCount`, `warningCount`, `infoCount`, `hasErrors`, `byCode`.
- Les diagnostics n'écrivent rien dans `SceneAsset` ou `ProjectManifest`.
- UI : badge compact dans l'arborescence + section dans l'inspecteur.
- Pas de Validator global, pas de bouton de correction automatique.
- Les cas déjà impossibles à construire restent documentés.

## Scope réalisé

- Ajout de `SceneDiagnosticSeverity`, `SceneDiagnosticCode`, `SceneDiagnosticTarget`, `SceneDiagnostic`, `SceneDiagnosticsReport`.
- Ajout de `diagnoseScene(SceneAsset scene)`.
- Export public depuis `map_core.dart`.
- Projection `NarrativeSceneSummary` enrichie avec `diagnostics`.
- Badge diagnostic dans l'arborescence Scènes.
- Section `Diagnostics` dans `SceneNodeReadOnlyInspector`.
- Tests core diagnostics.
- Tests widget diagnostics.
- Visual Gate V1-09.
- Roadmap mise à jour.

## Fichiers créés

- `packages/map_core/lib/src/diagnostics/scene_diagnostics.dart`
- `packages/map_core/test/scene_diagnostics_test.dart`
- `reports/narrativeStudio/scenes/ns_scenes_v1_09_scene_validation_diagnostics.md`
- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_09_scene_validation_diagnostics.png`

## Fichiers modifiés

- `packages/map_core/lib/map_core.dart`
- `packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart`
- `packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/scenes/scene_node_read_only_inspector.dart`
- `packages/map_editor/test/scenes_workspace_shell_test.dart`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_08_authoring_minimal_scene_draft.png`

## Diagnostics ajoutés

Codes disponibles :

- `missingStartNode`
- `startNodeNotFound`
- `startNodeNotStartKind`
- `missingEndNode`
- `unknownFromNode`
- `unknownToNode`
- `layoutUnknownNode`
- `layoutMissingNode`
- `declaredOutcomeUnused`
- `endOutcomeUndeclared`
- `emptyGraph`
- `legacyScenarioLeak`

Diagnostics effectivement testés :

- draft minimale V1-08 sans erreur bloquante ;
- `missingEndNode` en erreur ;
- `endOutcomeUndeclared` en erreur ;
- `declaredOutcomeUnused` en warning ;
- `layoutMissingNode` en warning ;
- layout complet sans `layoutMissingNode`.

## Cas impossibles à diagnostiquer car refusés par le modèle

Ces cas restent codés défensivement, mais les constructeurs actuels les refusent avant qu'un `SceneAsset` valide existe :

- `missingStartNode` avec `startNodeId` vide : `SceneGraph` refuse un `startNodeId` blank.
- `startNodeNotFound` : `SceneGraph` exige que `startNodeId` référence un node existant.
- `startNodeNotStartKind` : `SceneGraph` exige que `startNodeId` pointe vers `SceneNodeKind.start`.
- `unknownFromNode` / `unknownToNode` : `SceneGraph` refuse les edges vers nodes inconnus.
- `layoutUnknownNode` : `SceneAsset` valide `SceneGraphLayout` contre le graph.
- payload requis manquant : les payload constructors refusent les références obligatoires vides.

Le modèle n'a pas été affaibli pour fabriquer des objets impossibles.

## Intégration editor

- `NarrativeSceneSummary` contient maintenant un `SceneDiagnosticsReport`.
- L'arborescence affiche `1 erreur` ou `1 warning` selon le diagnostic le plus sévère.
- L'inspecteur read-only affiche une section `Diagnostics` avec statut et messages.
- Les diagnostics sont visibles sur la scène sélectionnée.
- Aucun bouton `Corriger automatiquement`.
- Aucun formulaire d'édition.
- Aucune mutation de `ProjectManifest`.

## Écarts au prompt éventuels

- `legacyScenarioLeak` est seulement présent dans l'enum V0 ; aucune scène V1 actuelle ne porte une référence legacy détectable.
- `layoutUnknownNode`, `unknownFromNode`, `unknownToNode` et les diagnostics start invalides sont défensifs, car le modèle les empêche déjà.
- Le screenshot V1-08 a été régénéré car l'inspecteur affiche désormais une section diagnostics `Valide`.

## Tests exécutés

### map_core diagnostics

Commande :

```bash
cd packages/map_core && dart test test/scene_diagnostics_test.dart
```

Résultat :

```text
00:00 +6: All tests passed!
```

### map_core authoring regression

Commande :

```bash
cd packages/map_core && dart test test/scene_authoring_operations_test.dart
```

Résultat :

```text
00:00 +4: All tests passed!
```

### map_core analyze

Commande :

```bash
cd packages/map_core && dart analyze
```

Résultat :

```text
Analyzing map_core...
No issues found!
```

### map_editor scenes workspace

Commande :

```bash
cd packages/map_editor && flutter test --reporter=compact test/scenes_workspace_shell_test.dart
```

Résultat :

```text
00:04 +18: All tests passed!
```

### map_editor regressions

Commande :

```bash
cd packages/map_editor && flutter test --reporter=compact test/ui/canvas/narrative_overview_shell_navigation_test.dart
```

Résultat :

```text
00:04 +19: All tests passed!
```

Commande :

```bash
cd packages/map_editor && flutter test --reporter=compact test/ui/canvas/narrative_studio_header_test.dart
```

Résultat :

```text
00:02 +3: All tests passed!
```

Commande :

```bash
cd packages/map_editor && flutter test --reporter=compact test/narrative_workspace_projection_test.dart
```

Résultat :

```text
00:01 +3: All tests passed!
```

### map_editor analyze ciblé

Commande :

```bash
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/features/narrative/application/narrative_workspace_projection.dart lib/src/ui/canvas/scenes_workspace.dart lib/src/ui/canvas/scenes/scene_graph_read_only_view.dart lib/src/ui/canvas/scenes/scene_node_read_only_inspector.dart test/scenes_workspace_shell_test.dart test/ui/canvas/narrative_overview_shell_navigation_test.dart test/ui/canvas/narrative_studio_header_test.dart test/narrative_workspace_projection_test.dart
```

Résultat :

```text
Analyzing 8 items...
No issues found! (ran in 1.7s)
```

## Visual Gate

Screenshot :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_09_scene_validation_diagnostics.png
```

Commande :

```bash
cd packages/map_editor && flutter test --update-goldens --reporter=compact test/scenes_workspace_shell_test.dart --plain-name 'writes V1-09 diagnostics visual gate screenshot'
```

Résultat :

```text
00:02 +1: All tests passed!
```

Taille :

```text
-rw-r--r--  1 karim  staff  38204 May 29 22:24 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_09_scene_validation_diagnostics.png
```

Ce qui est visible : workspace Scènes, arborescence gauche, scène test locale `Diagnostic Test Scene`, badge warning, graph read-only, inspecteur read-only, section `Diagnostics`, aucun bouton de correction automatique.

Preuve anti-fake : la scène diagnostic est une fixture locale de test dans `packages/map_editor/test/scenes_workspace_shell_test.dart`.

## Git status initial

Commande :

```bash
git status --short --untracked-files=all
```

Sortie :

```text
Sortie : <vide>
```

## Git diff --stat initial

Commande :

```bash
git diff --stat
```

Sortie :

```text
Sortie : <vide>
```

## Git log initial

Commande :

```bash
git log --oneline -n 10
```

Sortie :

```text
f9095001 feat(scenes): add minimal scene draft authoring operations and tests
c1bf1c76 feat(scenes): add read-only node inspector and update workspace tests
e3b346c7 feat(scenes): harden graph read-only fallback layout and update tests
d97be401 chore: auto-commit changes
7fcd3c87 chore: auto-commit changes
6bbff623 scènes workspace shell UI
3253c8d5 chore: auto-commit changes
e75b3876 chore: auto-commit changes
00bcaa4d chore: auto-commit changes
a85fc3c4 docs(scenes): add scene system audit and roadmap v1.0.0
```

## Git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie :

```text
 M packages/map_core/lib/map_core.dart
 M packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart
 M packages/map_editor/lib/src/ui/canvas/scenes/scene_node_read_only_inspector.dart
 M packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart
 M packages/map_editor/test/scenes_workspace_shell_test.dart
 M reports/narrativeStudio/scenes/road_map_scenes.md
 M reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_08_authoring_minimal_scene_draft.png
?? packages/map_core/lib/src/diagnostics/scene_diagnostics.dart
?? packages/map_core/test/scene_diagnostics_test.dart
?? reports/narrativeStudio/scenes/ns_scenes_v1_09_scene_validation_diagnostics.md
?? reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_09_scene_validation_diagnostics.png
```

## Git diff --stat final

Commande :

```bash
git diff --stat
```

Sortie :

```text
 packages/map_core/lib/map_core.dart                |   1 +
 .../narrative_workspace_projection.dart            |  19 +++++
 .../scenes/scene_node_read_only_inspector.dart     |  66 +++++++++++++++
 .../lib/src/ui/canvas/scenes_workspace.dart        |  37 ++++++++-
 .../test/scenes_workspace_shell_test.dart          |  89 ++++++++++++++++++++-
 reports/narrativeStudio/scenes/road_map_scenes.md  |  22 ++++-
 ..._scenes_v1_08_authoring_minimal_scene_draft.png | Bin 37256 -> 37621 bytes
 7 files changed, 227 insertions(+), 7 deletions(-)
```

## Git diff --name-only final

Commande :

```bash
git diff --name-only
```

Sortie :

```text
packages/map_core/lib/map_core.dart
packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart
packages/map_editor/lib/src/ui/canvas/scenes/scene_node_read_only_inspector.dart
packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart
packages/map_editor/test/scenes_workspace_shell_test.dart
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_08_authoring_minimal_scene_draft.png
```

## Git diff --check final

Commande :

```bash
git diff --check
```

Sortie :

```text
Sortie : <vide>
```

## Evidence Pack

### pwd

```text
/Users/karim/Project/pokemonProject
```

### git branch --show-current

```text
main
```

### Commandes principales exécutées

```text
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git log --oneline -n 10
cd packages/map_core && dart test test/scene_diagnostics_test.dart
cd packages/map_core && dart test test/scene_authoring_operations_test.dart
cd packages/map_core && dart analyze
cd packages/map_editor && flutter test --update-goldens --reporter=compact test/scenes_workspace_shell_test.dart --plain-name 'writes V1-09 diagnostics visual gate screenshot'
cd packages/map_editor && flutter test --update-goldens --reporter=compact test/scenes_workspace_shell_test.dart --plain-name 'writes V1-08 visual gate screenshot'
cd packages/map_editor && flutter test --reporter=compact test/scenes_workspace_shell_test.dart
cd packages/map_editor && flutter test --reporter=compact test/ui/canvas/narrative_overview_shell_navigation_test.dart
cd packages/map_editor && flutter test --reporter=compact test/ui/canvas/narrative_studio_header_test.dart
cd packages/map_editor && flutter test --reporter=compact test/narrative_workspace_projection_test.dart
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/features/narrative/application/narrative_workspace_projection.dart lib/src/ui/canvas/scenes_workspace.dart lib/src/ui/canvas/scenes/scene_graph_read_only_view.dart lib/src/ui/canvas/scenes/scene_node_read_only_inspector.dart test/scenes_workspace_shell_test.dart test/ui/canvas/narrative_overview_shell_navigation_test.dart test/ui/canvas/narrative_studio_header_test.dart test/narrative_workspace_projection_test.dart
git diff --check
```

### Vérification anti-couleurs hardcodées

Commande :

```bash
rg "Color\(0x|Colors\." packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart packages/map_editor/lib/src/ui/canvas/scenes packages/map_editor/test/scenes_workspace_shell_test.dart packages/map_core/lib/src/diagnostics/scene_diagnostics.dart packages/map_core/test/scene_diagnostics_test.dart
```

Sortie :

```text
Sortie : <vide>
```

### Vérification anti-fake / anti-Selbrume produit

Commande :

```bash
rg "fakeScenes|demoScenes|hardcodedSceneList|Annonce au port|Selbrume Demo|Maël|Lysa|Port des Brisants|La brume du phare|Le Goélise" packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart packages/map_editor/lib/src/ui/canvas/scenes packages/map_core/lib/src/diagnostics/scene_diagnostics.dart
```

Sortie :

```text
Sortie : <vide>
```

## Contenu complet des fichiers créés

### packages/map_core/lib/src/diagnostics/scene_diagnostics.dart

Fichier créé : `packages/map_core/lib/src/diagnostics/scene_diagnostics.dart`

Contenu complet :

```dart
import '../models/scene_asset.dart';

enum SceneDiagnosticSeverity {
  error,
  warning,
  info,
}

enum SceneDiagnosticCode {
  missingStartNode,
  startNodeNotFound,
  startNodeNotStartKind,
  missingEndNode,
  unknownFromNode,
  unknownToNode,
  layoutUnknownNode,
  layoutMissingNode,
  declaredOutcomeUnused,
  endOutcomeUndeclared,
  emptyGraph,
  legacyScenarioLeak,
}

enum SceneDiagnosticTarget {
  scene,
  graph,
  node,
  edge,
  layout,
  outcome,
}

final class SceneDiagnostic {
  const SceneDiagnostic({
    required this.code,
    required this.severity,
    required this.message,
    required this.sceneId,
    required this.target,
    this.nodeId,
    this.edgeId,
    this.outcomeId,
    this.suggestedFixLabel,
  });

  final SceneDiagnosticCode code;
  final SceneDiagnosticSeverity severity;
  final String message;
  final String sceneId;
  final SceneDiagnosticTarget target;
  final String? nodeId;
  final String? edgeId;
  final String? outcomeId;
  final String? suggestedFixLabel;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneDiagnostic &&
          other.code == code &&
          other.severity == severity &&
          other.message == message &&
          other.sceneId == sceneId &&
          other.target == target &&
          other.nodeId == nodeId &&
          other.edgeId == edgeId &&
          other.outcomeId == outcomeId &&
          other.suggestedFixLabel == suggestedFixLabel;

  @override
  int get hashCode => Object.hash(
        code,
        severity,
        message,
        sceneId,
        target,
        nodeId,
        edgeId,
        outcomeId,
        suggestedFixLabel,
      );
}

final class SceneDiagnosticsReport {
  SceneDiagnosticsReport({
    required List<SceneDiagnostic> diagnostics,
  }) : _diagnostics = List<SceneDiagnostic>.unmodifiable(diagnostics);

  final List<SceneDiagnostic> _diagnostics;

  List<SceneDiagnostic> get diagnostics => _diagnostics;

  int get count => _diagnostics.length;

  int get errorCount => _diagnostics
      .where(
          (diagnostic) => diagnostic.severity == SceneDiagnosticSeverity.error)
      .length;

  int get warningCount => _diagnostics
      .where(
        (diagnostic) => diagnostic.severity == SceneDiagnosticSeverity.warning,
      )
      .length;

  int get infoCount => _diagnostics
      .where(
          (diagnostic) => diagnostic.severity == SceneDiagnosticSeverity.info)
      .length;

  bool get hasDiagnostics => _diagnostics.isNotEmpty;

  bool get hasErrors => errorCount > 0;

  List<SceneDiagnostic> byCode(SceneDiagnosticCode code) {
    return List<SceneDiagnostic>.unmodifiable(
      _diagnostics.where((diagnostic) => diagnostic.code == code),
    );
  }
}

SceneDiagnosticsReport diagnoseScene(SceneAsset scene) {
  final diagnostics = <SceneDiagnostic>[];
  final nodeById = {
    for (final node in scene.graph.nodes) node.id: node,
  };
  final nodeIds = nodeById.keys.toSet();

  if (scene.graph.nodes.isEmpty) {
    diagnostics.add(
      SceneDiagnostic(
        code: SceneDiagnosticCode.emptyGraph,
        severity: SceneDiagnosticSeverity.error,
        message: 'La scène ne contient aucun nœud.',
        sceneId: scene.id,
        target: SceneDiagnosticTarget.graph,
        suggestedFixLabel: 'Créer un nœud de début et un nœud de fin.',
      ),
    );
  }

  if (scene.graph.startNodeId.trim().isEmpty) {
    diagnostics.add(
      SceneDiagnostic(
        code: SceneDiagnosticCode.missingStartNode,
        severity: SceneDiagnosticSeverity.error,
        message: 'La scène n’a pas de nœud de départ.',
        sceneId: scene.id,
        target: SceneDiagnosticTarget.graph,
        suggestedFixLabel: 'Définir un nœud de départ.',
      ),
    );
  } else {
    final startNode = nodeById[scene.graph.startNodeId];
    if (startNode == null) {
      diagnostics.add(
        SceneDiagnostic(
          code: SceneDiagnosticCode.startNodeNotFound,
          severity: SceneDiagnosticSeverity.error,
          message: 'Le nœud de départ est introuvable.',
          sceneId: scene.id,
          nodeId: scene.graph.startNodeId,
          target: SceneDiagnosticTarget.node,
          suggestedFixLabel: 'Choisir un nœud de départ existant.',
        ),
      );
    } else if (startNode.kind != SceneNodeKind.start) {
      diagnostics.add(
        SceneDiagnostic(
          code: SceneDiagnosticCode.startNodeNotStartKind,
          severity: SceneDiagnosticSeverity.error,
          message: 'Le nœud de départ doit être de type début.',
          sceneId: scene.id,
          nodeId: startNode.id,
          target: SceneDiagnosticTarget.node,
          suggestedFixLabel: 'Utiliser un nœud de type début.',
        ),
      );
    }
  }

  if (!scene.graph.nodes.any((node) => node.kind == SceneNodeKind.end)) {
    diagnostics.add(
      SceneDiagnostic(
        code: SceneDiagnosticCode.missingEndNode,
        severity: SceneDiagnosticSeverity.error,
        message: 'La scène n’a pas de fin.',
        sceneId: scene.id,
        target: SceneDiagnosticTarget.graph,
        suggestedFixLabel: 'Ajouter un nœud de fin.',
      ),
    );
  }

  if (scene.graph.nodes.length == 1 && scene.graph.edges.isEmpty) {
    diagnostics.add(
      SceneDiagnostic(
        code: SceneDiagnosticCode.emptyGraph,
        severity: SceneDiagnosticSeverity.info,
        message: 'La scène contient seulement un nœud isolé.',
        sceneId: scene.id,
        nodeId: scene.graph.nodes.single.id,
        target: SceneDiagnosticTarget.graph,
        suggestedFixLabel: 'Ajouter au moins un chemin vers une fin.',
      ),
    );
  }

  for (final edge in scene.graph.edges) {
    if (!nodeIds.contains(edge.fromNodeId)) {
      diagnostics.add(
        SceneDiagnostic(
          code: SceneDiagnosticCode.unknownFromNode,
          severity: SceneDiagnosticSeverity.error,
          message: 'Un lien part d’un nœud inconnu.',
          sceneId: scene.id,
          edgeId: edge.id,
          nodeId: edge.fromNodeId,
          target: SceneDiagnosticTarget.edge,
          suggestedFixLabel: 'Reconnecter le lien depuis un nœud existant.',
        ),
      );
    }
    if (!nodeIds.contains(edge.toNodeId)) {
      diagnostics.add(
        SceneDiagnostic(
          code: SceneDiagnosticCode.unknownToNode,
          severity: SceneDiagnosticSeverity.error,
          message: 'Un lien pointe vers un nœud inconnu.',
          sceneId: scene.id,
          edgeId: edge.id,
          nodeId: edge.toNodeId,
          target: SceneDiagnosticTarget.edge,
          suggestedFixLabel: 'Reconnecter le lien vers un nœud existant.',
        ),
      );
    }
  }

  final layoutNodeIds = {
    for (final layout in scene.layout.nodeLayouts) layout.nodeId,
  };
  for (final layoutNodeId in layoutNodeIds) {
    if (!nodeIds.contains(layoutNodeId)) {
      diagnostics.add(
        SceneDiagnostic(
          code: SceneDiagnosticCode.layoutUnknownNode,
          severity: SceneDiagnosticSeverity.warning,
          message: 'Le layout référence un nœud inconnu.',
          sceneId: scene.id,
          nodeId: layoutNodeId,
          target: SceneDiagnosticTarget.layout,
          suggestedFixLabel: 'Retirer cette position de layout.',
        ),
      );
    }
  }
  for (final node in scene.graph.nodes) {
    if (!layoutNodeIds.contains(node.id)) {
      diagnostics.add(
        SceneDiagnostic(
          code: SceneDiagnosticCode.layoutMissingNode,
          severity: SceneDiagnosticSeverity.warning,
          message: 'Un nœud n’a pas de position sauvegardée.',
          sceneId: scene.id,
          nodeId: node.id,
          target: SceneDiagnosticTarget.layout,
          suggestedFixLabel: 'Sauvegarder une position de layout.',
        ),
      );
    }
  }

  final declaredOutcomeIds = {
    for (final outcome in scene.declaredOutcomes) outcome.id,
  };
  final emittedSceneOutcomeIds = <String>{};
  for (final node in scene.graph.nodes) {
    final payload = node.payload;
    if (payload is! SceneEndPayload) {
      continue;
    }
    final outcomeId = payload.sceneOutcomeId;
    if (outcomeId == null) {
      continue;
    }
    emittedSceneOutcomeIds.add(outcomeId);
    if (!declaredOutcomeIds.contains(outcomeId)) {
      diagnostics.add(
        SceneDiagnostic(
          code: SceneDiagnosticCode.endOutcomeUndeclared,
          severity: SceneDiagnosticSeverity.error,
          message: 'Une fin émet un outcome non déclaré.',
          sceneId: scene.id,
          nodeId: node.id,
          outcomeId: outcomeId,
          target: SceneDiagnosticTarget.outcome,
          suggestedFixLabel: 'Déclarer cet outcome de scène.',
        ),
      );
    }
  }
  for (final outcome in scene.declaredOutcomes) {
    if (!emittedSceneOutcomeIds.contains(outcome.id)) {
      diagnostics.add(
        SceneDiagnostic(
          code: SceneDiagnosticCode.declaredOutcomeUnused,
          severity: SceneDiagnosticSeverity.warning,
          message: 'Un outcome déclaré n’est émis par aucune fin.',
          sceneId: scene.id,
          outcomeId: outcome.id,
          target: SceneDiagnosticTarget.outcome,
          suggestedFixLabel: 'Utiliser cet outcome dans un nœud de fin.',
        ),
      );
    }
  }

  return SceneDiagnosticsReport(diagnostics: diagnostics);
}
```

### packages/map_core/test/scene_diagnostics_test.dart

Fichier créé : `packages/map_core/test/scene_diagnostics_test.dart`

Contenu complet :

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Scene diagnostics', () {
    test('V1-08 minimal draft has no blocking error', () {
      final result = createSceneDraftInProject(
        _project(),
        name: 'Minimal draft',
      );

      final report = diagnoseScene(result.createdScene);

      expect(report.hasErrors, isFalse);
      expect(report.byCode(SceneDiagnosticCode.missingEndNode), isEmpty);
      expect(report.byCode(SceneDiagnosticCode.layoutMissingNode), isEmpty);
    });

    test('scene without end node emits missingEndNode error', () {
      final scene = _scene(
        nodes: [
          SceneNode(id: 'node_start', kind: SceneNodeKind.start),
        ],
        edges: const [],
      );

      final report = diagnoseScene(scene);

      expect(report.hasErrors, isTrue);
      final diagnostic =
          report.byCode(SceneDiagnosticCode.missingEndNode).single;
      expect(diagnostic.severity, SceneDiagnosticSeverity.error);
      expect(diagnostic.sceneId, scene.id);
      expect(diagnostic.message, 'La scène n’a pas de fin.');
    });

    test('end outcome absent from declared outcomes emits error', () {
      final scene = _scene(
        nodes: [
          SceneNode(id: 'node_start', kind: SceneNodeKind.start),
          SceneNode(
            id: 'node_end',
            kind: SceneNodeKind.end,
            payload: SceneEndPayload(sceneOutcomeId: 'outcome_done'),
          ),
        ],
      );

      final report = diagnoseScene(scene);

      final diagnostic =
          report.byCode(SceneDiagnosticCode.endOutcomeUndeclared).single;
      expect(diagnostic.severity, SceneDiagnosticSeverity.error);
      expect(diagnostic.sceneId, scene.id);
      expect(diagnostic.nodeId, 'node_end');
      expect(diagnostic.outcomeId, 'outcome_done');
    });

    test('declared outcome never emitted by an end node emits warning', () {
      final scene = _scene(
        declaredOutcomes: [
          SceneOutcome(id: 'outcome_done', label: 'Done'),
        ],
      );

      final report = diagnoseScene(scene);

      final diagnostic =
          report.byCode(SceneDiagnosticCode.declaredOutcomeUnused).single;
      expect(diagnostic.severity, SceneDiagnosticSeverity.warning);
      expect(diagnostic.sceneId, scene.id);
      expect(diagnostic.outcomeId, 'outcome_done');
    });

    test('incomplete layout emits layoutMissingNode warning', () {
      final scene = _scene(
        layout: SceneGraphLayout(
          nodeLayouts: [
            SceneNodeLayout(nodeId: 'node_start', x: 24, y: 80),
          ],
        ),
      );

      final report = diagnoseScene(scene);

      final diagnostic =
          report.byCode(SceneDiagnosticCode.layoutMissingNode).single;
      expect(diagnostic.severity, SceneDiagnosticSeverity.warning);
      expect(diagnostic.sceneId, scene.id);
      expect(diagnostic.nodeId, 'node_end');
    });

    test('complete layout does not emit layoutMissingNode', () {
      final scene = _scene();

      final report = diagnoseScene(scene);

      expect(report.byCode(SceneDiagnosticCode.layoutMissingNode), isEmpty);
    });
  });
}

ProjectManifest _project() {
  return ProjectManifest(
    name: 'Scene diagnostics test',
    maps: const [],
    tilesets: const [],
  );
}

SceneAsset _scene({
  List<SceneNode>? nodes,
  List<SceneEdge>? edges,
  SceneGraphLayout? layout,
  List<SceneOutcome> declaredOutcomes = const [],
}) {
  final graphNodes = nodes ??
      [
        SceneNode(id: 'node_start', kind: SceneNodeKind.start),
        SceneNode(id: 'node_end', kind: SceneNodeKind.end),
      ];
  return SceneAsset(
    id: 'scene_diagnostic_test',
    name: 'Diagnostic Test Scene',
    graph: SceneGraph(
      startNodeId: 'node_start',
      nodes: graphNodes,
      edges: edges ??
          [
            if (graphNodes.any((node) => node.id == 'node_end'))
              SceneEdge(
                id: 'edge_start_end',
                fromNodeId: 'node_start',
                fromPortId: 'completed',
                toNodeId: 'node_end',
                kind: SceneEdgeKind.defaultFlow,
              ),
          ],
    ),
    layout: layout ??
        SceneGraphLayout(
          nodeLayouts: [
            SceneNodeLayout(nodeId: 'node_start', x: 24, y: 80),
            if (graphNodes.any((node) => node.id == 'node_end'))
              SceneNodeLayout(nodeId: 'node_end', x: 320, y: 80),
          ],
        ),
    declaredOutcomes: declaredOutcomes,
  );
}
```

### reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_09_scene_validation_diagnostics.png

Fichier créé : PNG binaire généré par golden test.

### reports/narrativeStudio/scenes/ns_scenes_v1_09_scene_validation_diagnostics.md

Fichier courant : rapport V1-09.

## Auto-review critique

- Les diagnostics sont volontairement V0 et ne remplacent pas un Validator global.
- Plusieurs codes existent défensivement mais ne sont pas déclenchables tant que les modèles refusent ces objets invalides.
- Le warning `layoutMissingNode` est cohérent avec le fallback layout read-only : warning, pas error.
- Le système ne résout aucune référence Yarn/Battle/Cinematic.
- L'UI affiche les diagnostics sans action de correction ; c'est volontaire pour ne pas démarrer l'authoring node/edge.

## Regard critique sur le prompt

Le prompt demande certains diagnostics sur des états que le modèle actuel empêche déjà. C'est bon architecturalement : le diagnostic V0 doit documenter ces frontières sans affaiblir les constructeurs. La bonne suite est soit runtime prep, soit un lot de diagnostics plus riche quand les références Yarn/Battle/Cinematic seront stabilisées.

## Non-objectifs confirmés

- Pas d'édition de scène existante.
- Pas de suppression ou duplication.
- Pas d'ajout, édition ou suppression de node.
- Pas d'ajout, édition ou suppression d'edge.
- Pas de drag and drop.
- Pas de déplacement de layout.
- Pas d'édition de payload.
- Pas de runtime Scene.
- Pas d'adapter SceneAsset / ScenarioAsset.
- Pas de provider ou repository disque.
- Pas de seed Selbrume.
- Pas de scène `Annonce au port`.
- Pas de `StorylineStep.sceneLinkIds`.
- Pas de modification Storylines.
- Pas de modification `ScenarioAsset`.
- Pas de Validator global complet.
