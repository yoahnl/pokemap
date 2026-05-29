# NS-SCENES-V1-03 — Scene Core Model V0

## Résumé exécutif

NS-SCENES-V1-03 est livré côté `map_core`. Le lot crée le modèle authoring Scene V1 minimal, ajoute `ProjectManifest.scenes`, conserve `ProjectManifest.scenarios` sans migration, exporte l'API publique et couvre le modèle par tests core/JSON/manifest. Aucun code editor, runtime, gameplay, battle, Storylines ou Selbrume n'a été modifié.

## Scope réalisé

- `SceneAsset` dédié ajouté comme modèle core manuel immuable.
- `SceneGraph` contient `startNodeId`, nodes et edges.
- `SceneGraphLayout` reste séparé du graph logique et editor-only.
- `SceneNode`, payloads typés, `SceneEdge`, `SceneOutcome`, layout nodes/edges et points créés.
- `ProjectManifest.scenes` ajouté avec décodage absent/null vers `[]`.
- `map_core.dart` exporte `scene_asset.dart`.
- Tests ciblés ajoutés et validés.

## Fichiers créés/modifiés

Créés :
- `packages/map_core/lib/src/models/scene_asset.dart`
- `packages/map_core/test/scene_asset_test.dart`
- `packages/map_core/test/scene_asset_json_test.dart`
- `packages/map_core/test/project_manifest_scenes_test.dart`


Modifiés :
- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/models/project_manifest.freezed.dart`
- `packages/map_core/lib/src/models/project_manifest.g.dart`
- `packages/map_core/lib/map_core.dart`
- `reports/narrativeStudio/scenes/road_map_scenes.md`


## Décisions techniques

- Modèle manuel plutôt que Freezed pour `SceneAsset`, afin de suivre le pattern de `StorylineAsset` : validation constructeur, codecs manuels, immutabilité défensive.
- Pas de `graphId` en V0 : une `SceneAsset` porte un graph logique.
- Pas de `createdAt` / `updatedAt` pour éviter le churn de diff.
- `SceneGraphLayout` est stocké séparément dans `SceneAsset.layout`; le runtime peut l’ignorer.
- Les payloads sont typés ; la seule map de paramètres est `SceneActionPayload.parameters` en `Map<String, String>`, localisée à l’action.
- `SceneEdgeKind.defaultFlow` sérialise en JSON sous `default`, car `default` ne peut pas être un identifiant enum Dart.
- `ProjectManifest.scenarios` et `ProjectManifest.storylines` restent inchangés fonctionnellement.

## Écarts au prompt éventuels

- Aucun fichier `scene_asset.freezed.dart` ou `scene_asset.g.dart` n’a été créé, car le modèle suit le style manuel de `StorylineAsset`.
- `default` est représenté par `SceneEdgeKind.defaultFlow` côté Dart, avec JSON `default`.
- Les diagnostics avancés ne sont pas implémentés, conformément au non-objectif V1-03.

## Tests exécutés

```text
pwd; git branch --show-current; git status --short --untracked-files=all; git diff --stat; git log --oneline -n 10
sed -n ... mandatory files and neighboring models/tests
dart test test/scene_asset_test.dart
dart format lib/src/models/scene_asset.dart lib/src/models/project_manifest.dart lib/map_core.dart test/scene_asset_test.dart test/scene_asset_json_test.dart test/project_manifest_scenes_test.dart
dart run build_runner build --delete-conflicting-outputs
dart test test/scene_asset_test.dart
dart test test/scene_asset_json_test.dart
dart test test/project_manifest_scenes_test.dart
dart analyze
dart test
git diff --check
git diff --stat
git diff --name-only
```

## Résultats exacts

### Red TDD initial — `dart test test/scene_asset_test.dart`
```text
00:00 +0: loading test/scene_asset_test.dart
00:00 +0 -1: loading test/scene_asset_test.dart [E]
Failed to load "test/scene_asset_test.dart":
test/scene_asset_test.dart:207:1: Error: Type 'SceneAsset' not found.
SceneAsset _minimalScene() {
^^^^^^^^^^
...
00:00 +0 -1: Some tests failed.
```

### `dart test test/scene_asset_test.dart`
```text
Formatted 1 file (0 changed) in 0.00 seconds.
00:00 +0: loading test/scene_asset_test.dart
00:00 +0: SceneAsset construction accepts a minimal scene with start and end nodes
00:00 +1: SceneAsset construction accepts a minimal scene with start and end nodes
00:00 +1: SceneAsset construction keeps graph logic and editor layout separated
00:00 +2: SceneAsset construction keeps graph logic and editor layout separated
00:00 +2: SceneAsset construction exposes V0 node and edge taxonomy
00:00 +3: SceneAsset construction exposes V0 node and edge taxonomy
00:00 +3: SceneAsset validation rejects blank core identifiers and names
00:00 +4: SceneAsset validation rejects blank core identifiers and names
00:00 +4: SceneAsset validation rejects duplicate graph, layout and outcome ids
00:00 +5: SceneAsset validation rejects duplicate graph, layout and outcome ids
00:00 +5: SceneAsset validation rejects missing start node and broken edge references
00:00 +6: SceneAsset validation rejects missing start node and broken edge references
00:00 +6: SceneAsset validation rejects payloads attached to incompatible node kinds
00:00 +7: SceneAsset validation rejects payloads attached to incompatible node kinds
00:00 +7: SceneAsset authoring guarantees keeps ids stable when user-facing names are renamed
00:00 +8: SceneAsset authoring guarantees keeps ids stable when user-facing names are renamed
00:00 +8: SceneAsset authoring guarantees keeps metadata non-critical and string-only
00:00 +9: SceneAsset authoring guarantees keeps metadata non-critical and string-only
00:00 +9: All tests passed!
```

### `dart test test/scene_asset_json_test.dart`
```text
Formatted 1 file (0 changed) in 0.00 seconds.
00:00 +0: loading test/scene_asset_json_test.dart
00:00 +0: SceneAsset JSON roundtrip round-trips a complete V0 authoring shape
00:00 +1: SceneAsset JSON roundtrip round-trips a complete V0 authoring shape
00:00 +1: SceneAsset JSON roundtrip serializes enums as stable strings
00:00 +2: SceneAsset JSON roundtrip serializes enums as stable strings
00:00 +2: SceneAsset JSON roundtrip round-trips all minimal payload kinds
00:00 +3: SceneAsset JSON roundtrip round-trips all minimal payload kinds
00:00 +3: SceneAsset JSON roundtrip round-trips layout nodes and edge control points
00:00 +4: SceneAsset JSON roundtrip round-trips layout nodes and edge control points
00:00 +4: SceneAsset JSON defaults and invalid shapes decodes stable defaults from minimal JSON
00:00 +5: SceneAsset JSON defaults and invalid shapes decodes stable defaults from minimal JSON
00:00 +5: SceneAsset JSON defaults and invalid shapes rejects unknown enum and invalid payload shapes
00:00 +6: SceneAsset JSON defaults and invalid shapes rejects unknown enum and invalid payload shapes
00:00 +6: All tests passed!
```

### `dart test test/project_manifest_scenes_test.dart`
```text
00:00 +0: loading test/project_manifest_scenes_test.dart
00:00 +0: ProjectManifest scenes integration decodes old project JSON without scenes as empty list
00:00 +1: ProjectManifest scenes integration decodes old project JSON without scenes as empty list
00:00 +1: ProjectManifest scenes integration decodes scenes null and empty scenes as empty list
00:00 +2: ProjectManifest scenes integration decodes scenes null and empty scenes as empty list
00:00 +2: ProjectManifest scenes integration decodes project JSON with a SceneAsset
00:00 +3: ProjectManifest scenes integration decodes project JSON with a SceneAsset
00:00 +3: ProjectManifest scenes integration round-trips manifest with scenes through JSON
00:00 +4: ProjectManifest scenes integration round-trips manifest with scenes through JSON
00:00 +4: ProjectManifest scenes integration keeps scenarios and storylines independent from scenes
00:00 +5: ProjectManifest scenes integration keeps scenarios and storylines independent from scenes
00:00 +5: ProjectManifest scenes integration rejects invalid scenes JSON shape
00:00 +6: ProjectManifest scenes integration rejects invalid scenes JSON shape
00:00 +6: All tests passed!
```

### `dart test` ligne finale exacte
```text
00:03 +2072: All tests passed!
```

## Analyze exact
```text
Analyzing map_core...
No issues found!
```

## Build_runner exact
Commande : `cd packages/map_core && dart run build_runner build --delete-conflicting-outputs`
```text
Generating the build script.
Reading the asset graph.
Checking for updates.
Updating the asset graph.
Building, incremental build.
0s freezed on 291 inputs; lib/map_core.dart
W SDK language version 3.12.0 is newer than `analyzer` language version 3.9.0. Run `dart pub upgrade`.
0s freezed on 291 inputs: 1 no-op; lib/src/authoring/narrative_event_source_authoring_operations.dart
2s freezed on 291 inputs: 2 no-op; spent 1s analyzing; lib/src/authoring/narrative_outcome_authoring_operations.dart
3s freezed on 291 inputs: 17 skipped, 1 output, 3 same, 6 no-op; spent 2s analyzing; lib/src/models/project_path_pattern_preset.dart
3s freezed on 291 inputs: 272 skipped, 1 output, 3 same, 15 no-op; spent 2s analyzing
0s json_serializable on 582 inputs; lib/map_core.dart
1s json_serializable on 582 inputs: 1 no-op; lib/map_core.freezed.dart
W json_serializable on lib/src/models/element_collision_profile.dart:
The version constraint "^4.8.1" on json_annotation allows versions before 4.9.0 which is not allowed.
2s json_serializable on 582 inputs: 99 skipped, 1 output, 3 same, 30 no-op; spent 2s analyzing; lib/src/operations/map_placed_elements.freezed.dart
3s json_serializable on 582 inputs: 205 skipped, 1 output, 3 same, 70 no-op; spent 3s analyzing; test/beta_playability_validator_test.freezed.dart
4s json_serializable on 582 inputs: 268 skipped, 1 output, 3 same, 133 no-op; spent 3s analyzing; test/project_surface_animation_test.freezed.dart
5s json_serializable on 582 inputs: 340 skipped, 1 output, 3 same, 205 no-op; spent 4s analyzing; test/surface_studio_read_model_test.freezed.dart
5s json_serializable on 582 inputs: 357 skipped, 1 output, 3 same, 221 no-op; spent 4s analyzing
0s source_gen:combining_builder on 582 inputs; lib/map_core.dart
0s source_gen:combining_builder on 582 inputs: 571 skipped, 1 output, 3 same, 7 no-op
Running the post build.
Writing the asset graph.
Built with build_runner in 10s; wrote 12 outputs.
```

## Generated files créés/modifiés

- Créés : aucun generated `scene_asset.*`, car `scene_asset.dart` est manuel.
- Modifiés : `packages/map_core/lib/src/models/project_manifest.freezed.dart`, `packages/map_core/lib/src/models/project_manifest.g.dart`.
- Raison : ajout du champ Freezed/JSON `ProjectManifest.scenes`.

## Git status initial
```text
Sortie : <vide>
```

## Git status final
```text
 M packages/map_core/lib/map_core.dart
 M packages/map_core/lib/src/models/project_manifest.dart
 M packages/map_core/lib/src/models/project_manifest.freezed.dart
 M packages/map_core/lib/src/models/project_manifest.g.dart
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? packages/map_core/lib/src/models/scene_asset.dart
?? packages/map_core/test/project_manifest_scenes_test.dart
?? packages/map_core/test/scene_asset_json_test.dart
?? packages/map_core/test/scene_asset_test.dart
?? reports/narrativeStudio/scenes/ns_scenes_v1_03_scene_core_model_v0.md
```

## Git diff --stat
Initial :
```text
Sortie : <vide>
```
Final :
```text
 packages/map_core/lib/map_core.dart                |  1 +
 .../map_core/lib/src/models/project_manifest.dart  | 40 ++++++++++++++++++++++
 .../lib/src/models/project_manifest.freezed.dart   | 37 +++++++++++++++++++-
 .../lib/src/models/project_manifest.g.dart         |  3 ++
 reports/narrativeStudio/scenes/road_map_scenes.md  | 29 +++++++++++++---
 5 files changed, 105 insertions(+), 5 deletions(-)
```

## Git diff --name-only
```text
packages/map_core/lib/map_core.dart
packages/map_core/lib/src/models/project_manifest.dart
packages/map_core/lib/src/models/project_manifest.freezed.dart
packages/map_core/lib/src/models/project_manifest.g.dart
reports/narrativeStudio/scenes/road_map_scenes.md
```

## Git diff --check
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

### git log --oneline -n 10 initial
```text
00bcaa4d chore: auto-commit changes
a85fc3c4 docs(scenes): add scene system audit and roadmap v1.0.0
af6c491b feat(storylines): update structure layout and tests v1.1.1
04cce3b7 feat(storylines): add structure layout chapter/step readability v1.1.0
2c536dbd feat(storylines): fix graph focus layout canvas priority
a428448e feat(storylines): fix Selbrume graph layout side quest rendering v0
4acf8c3f feat(storylines): add Selbrume storylines demo seed v0
b26ae424 docs(storylines): reorganize v1 screenshots and add checkpoint acceptance report
63a005e3 feat(storylines): add visual graph enrichment v1.12
db1bc6e3 docs(storylines): reorganize v1 screenshots and reports for side quest attachment
```

### Fichiers inspectés
- `AGENTS.md`
- `agent_rules.md`
- `skills/README.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_00_scene_system_scope_current_state_audit.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_01_scene_product_model_graph_contract.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_02_scene_storage_id_read_model_decision.md`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/models/scenario_asset.dart`
- `packages/map_core/lib/src/models/script_asset.dart`
- `packages/map_core/lib/src/models/script_conditions.dart`
- `packages/map_core/lib/src/models/storyline_asset.dart`
- `packages/map_core/lib/map_core.dart`
- `packages/map_core/test/storyline_asset_test.dart`
- `packages/map_core/test/storyline_asset_json_test.dart`
- `packages/map_core/test/project_manifest_storylines_test.dart`


### Contenu complet — `packages/map_core/lib/src/models/scene_asset.dart`
```dart
import 'package:meta/meta.dart' show immutable;

import '../exceptions/map_exceptions.dart';

enum SceneNodeKind {
  start,
  end,
  yarnDialogue,
  condition,
  action,
  battle,
  cinematic,
  branchByOutcome,
  merge,
}

enum SceneEdgeKind {
  defaultFlow,
  conditionTrue,
  conditionFalse,
  dialogueOutcome,
  battleVictory,
  battleDefeat,
  cinematicCompleted,
  actionCompleted,
  branchOutcome,
  error,
  blocked,
}

@immutable
final class SceneAsset {
  SceneAsset({
    required this.id,
    required this.name,
    this.description,
    this.storylineId,
    this.chapterId,
    List<String> tags = const <String>[],
    required this.graph,
    SceneGraphLayout? layout,
    List<SceneOutcome> declaredOutcomes = const <SceneOutcome>[],
    Map<String, String> metadata = const <String, String>{},
  })  : tags = _immutableNonBlankUniqueStrings(tags, 'SceneAsset.tags'),
        layout = layout ?? SceneGraphLayout(),
        declaredOutcomes = List<SceneOutcome>.unmodifiable(declaredOutcomes),
        metadata = Map<String, String>.unmodifiable(metadata) {
    _requireNotBlank(id, 'SceneAsset.id');
    _requireNotBlank(name, 'SceneAsset.name');
    _requireOptionalNotBlank(storylineId, 'SceneAsset.storylineId');
    _requireOptionalNotBlank(chapterId, 'SceneAsset.chapterId');
    _validateUniqueIds(
      this.declaredOutcomes.map((outcome) => outcome.id),
      'SceneAsset.declaredOutcomes',
    );
    this.layout._validateAgainst(graph);
  }

  factory SceneAsset.fromJson(Map<String, dynamic> json) {
    return SceneAsset(
      id: _readRequiredString(json, 'id'),
      name: _readRequiredString(json, 'name'),
      description: _readOptionalString(json, 'description'),
      storylineId: _readOptionalString(json, 'storylineId'),
      chapterId: _readOptionalString(json, 'chapterId'),
      tags: _readStringList(json, 'tags'),
      graph: SceneGraph.fromJson(_readRequiredObject(json, 'graph')),
      layout: _readOptionalObject(json, 'layout', SceneGraphLayout.fromJson),
      declaredOutcomes: _readObjectList(
        json,
        'declaredOutcomes',
        SceneOutcome.fromJson,
      ),
      metadata: _readStringMap(json, 'metadata'),
    );
  }

  Map<String, dynamic> toJson() {
    return _withoutNulls({
      'id': id,
      'name': name,
      'description': description,
      'storylineId': storylineId,
      'chapterId': chapterId,
      'tags': tags,
      'graph': graph.toJson(),
      'layout': layout.toJson(),
      'declaredOutcomes':
          declaredOutcomes.map((outcome) => outcome.toJson()).toList(),
      'metadata': metadata,
    });
  }

  final String id;
  final String name;
  final String? description;
  final String? storylineId;
  final String? chapterId;
  final List<String> tags;
  final SceneGraph graph;
  final SceneGraphLayout layout;
  final List<SceneOutcome> declaredOutcomes;
  final Map<String, String> metadata;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneAsset &&
          other.id == id &&
          other.name == name &&
          other.description == description &&
          other.storylineId == storylineId &&
          other.chapterId == chapterId &&
          _listEquals(other.tags, tags) &&
          other.graph == graph &&
          other.layout == layout &&
          _listEquals(other.declaredOutcomes, declaredOutcomes) &&
          _mapEquals(other.metadata, metadata);

  @override
  int get hashCode => Object.hash(
        id,
        name,
        description,
        storylineId,
        chapterId,
        Object.hashAll(tags),
        graph,
        layout,
        Object.hashAll(declaredOutcomes),
        _mapHash(metadata),
      );

  @override
  String toString() => 'SceneAsset(id: $id, name: $name)';
}

@immutable
final class SceneGraph {
  SceneGraph({
    required this.startNodeId,
    List<SceneNode> nodes = const <SceneNode>[],
    List<SceneEdge> edges = const <SceneEdge>[],
  })  : nodes = List<SceneNode>.unmodifiable(nodes),
        edges = List<SceneEdge>.unmodifiable(edges) {
    _requireNotBlank(startNodeId, 'SceneGraph.startNodeId');
    _validateUniqueIds(this.nodes.map((node) => node.id), 'SceneGraph.nodes');
    _validateUniqueIds(this.edges.map((edge) => edge.id), 'SceneGraph.edges');

    final nodeIds = this.nodes.map((node) => node.id).toSet();
    final startNode = this
        .nodes
        .where((node) => node.id == startNodeId)
        .cast<SceneNode?>()
        .firstOrNull;
    if (startNode == null) {
      throw ValidationException(
        'SceneGraph.startNodeId must reference an existing node: $startNodeId',
      );
    }
    if (startNode.kind != SceneNodeKind.start) {
      throw const ValidationException(
        'SceneGraph.startNodeId must reference a start node',
      );
    }

    for (final edge in this.edges) {
      if (!nodeIds.contains(edge.fromNodeId)) {
        throw ValidationException(
          'SceneGraph.edges contains unknown fromNodeId: ${edge.fromNodeId}',
        );
      }
      if (!nodeIds.contains(edge.toNodeId)) {
        throw ValidationException(
          'SceneGraph.edges contains unknown toNodeId: ${edge.toNodeId}',
        );
      }
    }
  }

  factory SceneGraph.fromJson(Map<String, dynamic> json) {
    return SceneGraph(
      startNodeId: _readRequiredString(json, 'startNodeId'),
      nodes: _readObjectList(json, 'nodes', SceneNode.fromJson),
      edges: _readObjectList(json, 'edges', SceneEdge.fromJson),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startNodeId': startNodeId,
      'nodes': nodes.map((node) => node.toJson()).toList(),
      'edges': edges.map((edge) => edge.toJson()).toList(),
    };
  }

  final String startNodeId;
  final List<SceneNode> nodes;
  final List<SceneEdge> edges;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneGraph &&
          other.startNodeId == startNodeId &&
          _listEquals(other.nodes, nodes) &&
          _listEquals(other.edges, edges);

  @override
  int get hashCode => Object.hash(
        startNodeId,
        Object.hashAll(nodes),
        Object.hashAll(edges),
      );
}

@immutable
final class SceneGraphLayout {
  SceneGraphLayout({
    List<SceneNodeLayout> nodeLayouts = const <SceneNodeLayout>[],
    List<SceneEdgeLayout> edgeLayouts = const <SceneEdgeLayout>[],
  })  : nodeLayouts = List<SceneNodeLayout>.unmodifiable(nodeLayouts),
        edgeLayouts = List<SceneEdgeLayout>.unmodifiable(edgeLayouts) {
    _validateUniqueIds(
      this.nodeLayouts.map((layout) => layout.nodeId),
      'SceneGraphLayout.nodeLayouts',
    );
    _validateUniqueIds(
      this.edgeLayouts.map((layout) => layout.edgeId),
      'SceneGraphLayout.edgeLayouts',
    );
  }

  factory SceneGraphLayout.fromJson(Map<String, dynamic> json) {
    return SceneGraphLayout(
      nodeLayouts: _readObjectList(
        json,
        'nodeLayouts',
        SceneNodeLayout.fromJson,
      ),
      edgeLayouts: _readObjectList(
        json,
        'edgeLayouts',
        SceneEdgeLayout.fromJson,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nodeLayouts': nodeLayouts.map((layout) => layout.toJson()).toList(),
      'edgeLayouts': edgeLayouts.map((layout) => layout.toJson()).toList(),
    };
  }

  void _validateAgainst(SceneGraph graph) {
    final nodeIds = graph.nodes.map((node) => node.id).toSet();
    final edgeIds = graph.edges.map((edge) => edge.id).toSet();

    for (final layout in nodeLayouts) {
      if (!nodeIds.contains(layout.nodeId)) {
        throw ValidationException(
          'SceneGraphLayout.nodeLayouts references unknown nodeId: '
          '${layout.nodeId}',
        );
      }
    }
    for (final layout in edgeLayouts) {
      if (!edgeIds.contains(layout.edgeId)) {
        throw ValidationException(
          'SceneGraphLayout.edgeLayouts references unknown edgeId: '
          '${layout.edgeId}',
        );
      }
    }
  }

  final List<SceneNodeLayout> nodeLayouts;
  final List<SceneEdgeLayout> edgeLayouts;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneGraphLayout &&
          _listEquals(other.nodeLayouts, nodeLayouts) &&
          _listEquals(other.edgeLayouts, edgeLayouts);

  @override
  int get hashCode => Object.hash(
        Object.hashAll(nodeLayouts),
        Object.hashAll(edgeLayouts),
      );
}

@immutable
final class SceneNodeLayout {
  SceneNodeLayout({
    required this.nodeId,
    required this.x,
    required this.y,
  }) {
    _requireNotBlank(nodeId, 'SceneNodeLayout.nodeId');
    _requireFiniteNumber(x, 'SceneNodeLayout.x');
    _requireFiniteNumber(y, 'SceneNodeLayout.y');
  }

  factory SceneNodeLayout.fromJson(Map<String, dynamic> json) {
    return SceneNodeLayout(
      nodeId: _readRequiredString(json, 'nodeId'),
      x: _readRequiredDouble(json, 'x'),
      y: _readRequiredDouble(json, 'y'),
    );
  }

  Map<String, dynamic> toJson() => {'nodeId': nodeId, 'x': x, 'y': y};

  final String nodeId;
  final double x;
  final double y;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneNodeLayout &&
          other.nodeId == nodeId &&
          other.x == x &&
          other.y == y;

  @override
  int get hashCode => Object.hash(nodeId, x, y);
}

@immutable
final class SceneEdgeLayout {
  SceneEdgeLayout({
    required this.edgeId,
    List<SceneLayoutPoint> controlPoints = const <SceneLayoutPoint>[],
  }) : controlPoints = List<SceneLayoutPoint>.unmodifiable(controlPoints) {
    _requireNotBlank(edgeId, 'SceneEdgeLayout.edgeId');
  }

  factory SceneEdgeLayout.fromJson(Map<String, dynamic> json) {
    return SceneEdgeLayout(
      edgeId: _readRequiredString(json, 'edgeId'),
      controlPoints: _readObjectList(
        json,
        'controlPoints',
        SceneLayoutPoint.fromJson,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'edgeId': edgeId,
      'controlPoints': controlPoints.map((point) => point.toJson()).toList(),
    };
  }

  final String edgeId;
  final List<SceneLayoutPoint> controlPoints;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneEdgeLayout &&
          other.edgeId == edgeId &&
          _listEquals(other.controlPoints, controlPoints);

  @override
  int get hashCode => Object.hash(edgeId, Object.hashAll(controlPoints));
}

@immutable
final class SceneLayoutPoint {
  SceneLayoutPoint({required this.x, required this.y}) {
    _requireFiniteNumber(x, 'SceneLayoutPoint.x');
    _requireFiniteNumber(y, 'SceneLayoutPoint.y');
  }

  factory SceneLayoutPoint.fromJson(Map<String, dynamic> json) {
    return SceneLayoutPoint(
      x: _readRequiredDouble(json, 'x'),
      y: _readRequiredDouble(json, 'y'),
    );
  }

  Map<String, dynamic> toJson() => {'x': x, 'y': y};

  final double x;
  final double y;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneLayoutPoint && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);
}

@immutable
final class SceneNode {
  SceneNode({
    required this.id,
    required this.kind,
    this.title,
    this.description,
    SceneNodePayload? payload,
  }) : payload = payload ?? SceneNodePayload.emptyForKind(kind) {
    _requireNotBlank(id, 'SceneNode.id');
    if (this.payload.kind != kind) {
      throw ValidationException(
        'SceneNode.payload kind ${this.payload.kind.name} is incompatible '
        'with SceneNode.kind ${kind.name}',
      );
    }
  }

  factory SceneNode.fromJson(Map<String, dynamic> json) {
    final kind = _readEnum(SceneNodeKind.values, json['kind'], 'kind');
    return SceneNode(
      id: _readRequiredString(json, 'id'),
      kind: kind,
      title: _readOptionalString(json, 'title'),
      description: _readOptionalString(json, 'description'),
      payload: _readOptionalObject(
            json,
            'payload',
            (payloadJson) => SceneNodePayload.fromJson(
              payloadJson,
              expectedKind: kind,
            ),
          ) ??
          SceneNodePayload.emptyForKind(kind),
    );
  }

  Map<String, dynamic> toJson() {
    return _withoutNulls({
      'id': id,
      'kind': _enumToJson(kind),
      'title': title,
      'description': description,
      'payload': payload.toJson(),
    });
  }

  final String id;
  final SceneNodeKind kind;
  final String? title;
  final String? description;
  final SceneNodePayload payload;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneNode &&
          other.id == id &&
          other.kind == kind &&
          other.title == title &&
          other.description == description &&
          other.payload == payload;

  @override
  int get hashCode => Object.hash(id, kind, title, description, payload);
}

abstract base class SceneNodePayload {
  const SceneNodePayload();

  factory SceneNodePayload.fromJson(
    Map<String, dynamic> json, {
    SceneNodeKind? expectedKind,
  }) {
    final kind = _readEnum(
      SceneNodeKind.values,
      json['kind'],
      'payload.kind',
      defaultValue: expectedKind,
    );
    if (expectedKind != null && kind != expectedKind) {
      throw ValidationException(
        'SceneNodePayload.kind ${kind.name} is incompatible with '
        'SceneNode.kind ${expectedKind.name}',
      );
    }
    return switch (kind) {
      SceneNodeKind.start => SceneStartPayload.fromJson(json),
      SceneNodeKind.end => SceneEndPayload.fromJson(json),
      SceneNodeKind.yarnDialogue => SceneYarnDialoguePayload.fromJson(json),
      SceneNodeKind.condition => SceneConditionPayload.fromJson(json),
      SceneNodeKind.action => SceneActionPayload.fromJson(json),
      SceneNodeKind.battle => SceneBattlePayload.fromJson(json),
      SceneNodeKind.cinematic => SceneCinematicPayload.fromJson(json),
      SceneNodeKind.branchByOutcome =>
        SceneBranchByOutcomePayload.fromJson(json),
      SceneNodeKind.merge => SceneMergePayload.fromJson(json),
    };
  }

  static SceneNodePayload emptyForKind(SceneNodeKind kind) {
    return switch (kind) {
      SceneNodeKind.start => SceneStartPayload(),
      SceneNodeKind.end => SceneEndPayload(),
      SceneNodeKind.yarnDialogue => throw const ValidationException(
          'SceneNode.kind yarnDialogue requires an explicit payload',
        ),
      SceneNodeKind.condition => SceneConditionPayload(),
      SceneNodeKind.action => throw const ValidationException(
          'SceneNode.kind action requires an explicit payload',
        ),
      SceneNodeKind.battle => throw const ValidationException(
          'SceneNode.kind battle requires an explicit payload',
        ),
      SceneNodeKind.cinematic => throw const ValidationException(
          'SceneNode.kind cinematic requires an explicit payload',
        ),
      SceneNodeKind.branchByOutcome => SceneBranchByOutcomePayload(),
      SceneNodeKind.merge => SceneMergePayload(),
    };
  }

  SceneNodeKind get kind;

  Map<String, dynamic> toJson();
}

@immutable
final class SceneStartPayload extends SceneNodePayload {
  SceneStartPayload({this.notes});

  factory SceneStartPayload.fromJson(Map<String, dynamic> json) {
    return SceneStartPayload(notes: _readOptionalString(json, 'notes'));
  }

  @override
  SceneNodeKind get kind => SceneNodeKind.start;

  final String? notes;

  @override
  Map<String, dynamic> toJson() => _withoutNulls({
        'kind': _enumToJson(kind),
        'notes': notes,
      });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneStartPayload && other.notes == notes;

  @override
  int get hashCode => notes.hashCode;
}

@immutable
final class SceneEndPayload extends SceneNodePayload {
  SceneEndPayload({this.sceneOutcomeId, this.notes}) {
    _requireOptionalNotBlank(sceneOutcomeId, 'SceneEndPayload.sceneOutcomeId');
  }

  factory SceneEndPayload.fromJson(Map<String, dynamic> json) {
    return SceneEndPayload(
      sceneOutcomeId: _readOptionalString(json, 'sceneOutcomeId'),
      notes: _readOptionalString(json, 'notes'),
    );
  }

  @override
  SceneNodeKind get kind => SceneNodeKind.end;

  final String? sceneOutcomeId;
  final String? notes;

  @override
  Map<String, dynamic> toJson() => _withoutNulls({
        'kind': _enumToJson(kind),
        'sceneOutcomeId': sceneOutcomeId,
        'notes': notes,
      });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneEndPayload &&
          other.sceneOutcomeId == sceneOutcomeId &&
          other.notes == notes;

  @override
  int get hashCode => Object.hash(sceneOutcomeId, notes);
}

@immutable
final class SceneYarnDialoguePayload extends SceneNodePayload {
  SceneYarnDialoguePayload({
    required this.dialogueId,
    this.yarnNodeName,
    List<String> expectedOutcomes = const <String>[],
    List<String> speakerHints = const <String>[],
  })  : expectedOutcomes = _immutableNonBlankUniqueStrings(
          expectedOutcomes,
          'SceneYarnDialoguePayload.expectedOutcomes',
        ),
        speakerHints = _immutableNonBlankUniqueStrings(
          speakerHints,
          'SceneYarnDialoguePayload.speakerHints',
        ) {
    _requireNotBlank(dialogueId, 'SceneYarnDialoguePayload.dialogueId');
    _requireOptionalNotBlank(
      yarnNodeName,
      'SceneYarnDialoguePayload.yarnNodeName',
    );
  }

  factory SceneYarnDialoguePayload.fromJson(Map<String, dynamic> json) {
    return SceneYarnDialoguePayload(
      dialogueId: _readRequiredString(json, 'dialogueId'),
      yarnNodeName: _readOptionalString(json, 'yarnNodeName'),
      expectedOutcomes: _readStringList(json, 'expectedOutcomes'),
      speakerHints: _readStringList(json, 'speakerHints'),
    );
  }

  @override
  SceneNodeKind get kind => SceneNodeKind.yarnDialogue;

  final String dialogueId;
  final String? yarnNodeName;
  final List<String> expectedOutcomes;
  final List<String> speakerHints;

  @override
  Map<String, dynamic> toJson() => _withoutNulls({
        'kind': _enumToJson(kind),
        'dialogueId': dialogueId,
        'yarnNodeName': yarnNodeName,
        'expectedOutcomes': expectedOutcomes,
        'speakerHints': speakerHints,
      });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneYarnDialoguePayload &&
          other.dialogueId == dialogueId &&
          other.yarnNodeName == yarnNodeName &&
          _listEquals(other.expectedOutcomes, expectedOutcomes) &&
          _listEquals(other.speakerHints, speakerHints);

  @override
  int get hashCode => Object.hash(
        dialogueId,
        yarnNodeName,
        Object.hashAll(expectedOutcomes),
        Object.hashAll(speakerHints),
      );
}

@immutable
final class SceneConditionPayload extends SceneNodePayload {
  SceneConditionPayload({
    this.conditionLabel,
    this.conditionRef,
    this.conditionDraft,
  }) {
    _requireOptionalNotBlank(
      conditionLabel,
      'SceneConditionPayload.conditionLabel',
    );
    _requireOptionalNotBlank(
      conditionRef,
      'SceneConditionPayload.conditionRef',
    );
    _requireOptionalNotBlank(
      conditionDraft,
      'SceneConditionPayload.conditionDraft',
    );
  }

  factory SceneConditionPayload.fromJson(Map<String, dynamic> json) {
    return SceneConditionPayload(
      conditionLabel: _readOptionalString(json, 'conditionLabel'),
      conditionRef: _readOptionalString(json, 'conditionRef'),
      conditionDraft: _readOptionalString(json, 'conditionDraft'),
    );
  }

  @override
  SceneNodeKind get kind => SceneNodeKind.condition;

  final String? conditionLabel;
  final String? conditionRef;
  final String? conditionDraft;

  @override
  Map<String, dynamic> toJson() => _withoutNulls({
        'kind': _enumToJson(kind),
        'conditionLabel': conditionLabel,
        'conditionRef': conditionRef,
        'conditionDraft': conditionDraft,
      });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneConditionPayload &&
          other.conditionLabel == conditionLabel &&
          other.conditionRef == conditionRef &&
          other.conditionDraft == conditionDraft;

  @override
  int get hashCode => Object.hash(conditionLabel, conditionRef, conditionDraft);
}

@immutable
final class SceneActionPayload extends SceneNodePayload {
  SceneActionPayload({
    required this.actionKind,
    Map<String, String> parameters = const <String, String>{},
  }) : parameters = Map<String, String>.unmodifiable(parameters) {
    _requireNotBlank(actionKind, 'SceneActionPayload.actionKind');
  }

  factory SceneActionPayload.fromJson(Map<String, dynamic> json) {
    return SceneActionPayload(
      actionKind: _readRequiredString(json, 'actionKind'),
      parameters: _readStringMap(json, 'parameters'),
    );
  }

  @override
  SceneNodeKind get kind => SceneNodeKind.action;

  final String actionKind;
  final Map<String, String> parameters;

  @override
  Map<String, dynamic> toJson() => {
        'kind': _enumToJson(kind),
        'actionKind': actionKind,
        'parameters': parameters,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneActionPayload &&
          other.actionKind == actionKind &&
          _mapEquals(other.parameters, parameters);

  @override
  int get hashCode => Object.hash(actionKind, _mapHash(parameters));
}

@immutable
final class SceneBattlePayload extends SceneNodePayload {
  SceneBattlePayload({
    required this.battleKind,
    this.trainerId,
    this.battleTemplateId,
    this.npcEntityId,
    List<String> declaredOutcomes = const <String>[],
  }) : declaredOutcomes = _immutableNonBlankUniqueStrings(
          declaredOutcomes,
          'SceneBattlePayload.declaredOutcomes',
        ) {
    _requireNotBlank(battleKind, 'SceneBattlePayload.battleKind');
    _requireOptionalNotBlank(trainerId, 'SceneBattlePayload.trainerId');
    _requireOptionalNotBlank(
      battleTemplateId,
      'SceneBattlePayload.battleTemplateId',
    );
    _requireOptionalNotBlank(npcEntityId, 'SceneBattlePayload.npcEntityId');
  }

  factory SceneBattlePayload.fromJson(Map<String, dynamic> json) {
    return SceneBattlePayload(
      battleKind: _readRequiredString(json, 'battleKind'),
      trainerId: _readOptionalString(json, 'trainerId'),
      battleTemplateId: _readOptionalString(json, 'battleTemplateId'),
      npcEntityId: _readOptionalString(json, 'npcEntityId'),
      declaredOutcomes: _readStringList(json, 'declaredOutcomes'),
    );
  }

  @override
  SceneNodeKind get kind => SceneNodeKind.battle;

  final String battleKind;
  final String? trainerId;
  final String? battleTemplateId;
  final String? npcEntityId;
  final List<String> declaredOutcomes;

  @override
  Map<String, dynamic> toJson() => _withoutNulls({
        'kind': _enumToJson(kind),
        'battleKind': battleKind,
        'trainerId': trainerId,
        'battleTemplateId': battleTemplateId,
        'npcEntityId': npcEntityId,
        'declaredOutcomes': declaredOutcomes,
      });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneBattlePayload &&
          other.battleKind == battleKind &&
          other.trainerId == trainerId &&
          other.battleTemplateId == battleTemplateId &&
          other.npcEntityId == npcEntityId &&
          _listEquals(other.declaredOutcomes, declaredOutcomes);

  @override
  int get hashCode => Object.hash(
        battleKind,
        trainerId,
        battleTemplateId,
        npcEntityId,
        Object.hashAll(declaredOutcomes),
      );
}

@immutable
final class SceneCinematicPayload extends SceneNodePayload {
  SceneCinematicPayload({required this.cinematicId}) {
    _requireNotBlank(cinematicId, 'SceneCinematicPayload.cinematicId');
  }

  factory SceneCinematicPayload.fromJson(Map<String, dynamic> json) {
    return SceneCinematicPayload(
      cinematicId: _readRequiredString(json, 'cinematicId'),
    );
  }

  @override
  SceneNodeKind get kind => SceneNodeKind.cinematic;

  final String cinematicId;

  @override
  Map<String, dynamic> toJson() => {
        'kind': _enumToJson(kind),
        'cinematicId': cinematicId,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneCinematicPayload && other.cinematicId == cinematicId;

  @override
  int get hashCode => cinematicId.hashCode;
}

@immutable
final class SceneBranchByOutcomePayload extends SceneNodePayload {
  SceneBranchByOutcomePayload({
    this.sourceNodeId,
    this.sourceOutcomeSetRef,
    this.fallbackPolicy,
  }) {
    _requireOptionalNotBlank(
      sourceNodeId,
      'SceneBranchByOutcomePayload.sourceNodeId',
    );
    _requireOptionalNotBlank(
      sourceOutcomeSetRef,
      'SceneBranchByOutcomePayload.sourceOutcomeSetRef',
    );
    _requireOptionalNotBlank(
      fallbackPolicy,
      'SceneBranchByOutcomePayload.fallbackPolicy',
    );
  }

  factory SceneBranchByOutcomePayload.fromJson(Map<String, dynamic> json) {
    return SceneBranchByOutcomePayload(
      sourceNodeId: _readOptionalString(json, 'sourceNodeId'),
      sourceOutcomeSetRef: _readOptionalString(json, 'sourceOutcomeSetRef'),
      fallbackPolicy: _readOptionalString(json, 'fallbackPolicy'),
    );
  }

  @override
  SceneNodeKind get kind => SceneNodeKind.branchByOutcome;

  final String? sourceNodeId;
  final String? sourceOutcomeSetRef;
  final String? fallbackPolicy;

  @override
  Map<String, dynamic> toJson() => _withoutNulls({
        'kind': _enumToJson(kind),
        'sourceNodeId': sourceNodeId,
        'sourceOutcomeSetRef': sourceOutcomeSetRef,
        'fallbackPolicy': fallbackPolicy,
      });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneBranchByOutcomePayload &&
          other.sourceNodeId == sourceNodeId &&
          other.sourceOutcomeSetRef == sourceOutcomeSetRef &&
          other.fallbackPolicy == fallbackPolicy;

  @override
  int get hashCode =>
      Object.hash(sourceNodeId, sourceOutcomeSetRef, fallbackPolicy);
}

@immutable
final class SceneMergePayload extends SceneNodePayload {
  SceneMergePayload({this.label, this.notes}) {
    _requireOptionalNotBlank(label, 'SceneMergePayload.label');
  }

  factory SceneMergePayload.fromJson(Map<String, dynamic> json) {
    return SceneMergePayload(
      label: _readOptionalString(json, 'label'),
      notes: _readOptionalString(json, 'notes'),
    );
  }

  @override
  SceneNodeKind get kind => SceneNodeKind.merge;

  final String? label;
  final String? notes;

  @override
  Map<String, dynamic> toJson() => _withoutNulls({
        'kind': _enumToJson(kind),
        'label': label,
        'notes': notes,
      });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneMergePayload &&
          other.label == label &&
          other.notes == notes;

  @override
  int get hashCode => Object.hash(label, notes);
}

@immutable
final class SceneEdge {
  SceneEdge({
    required this.id,
    required this.fromNodeId,
    required this.fromPortId,
    required this.toNodeId,
    required this.kind,
    this.label,
  }) {
    _requireNotBlank(id, 'SceneEdge.id');
    _requireNotBlank(fromNodeId, 'SceneEdge.fromNodeId');
    _requireNotBlank(fromPortId, 'SceneEdge.fromPortId');
    _requireNotBlank(toNodeId, 'SceneEdge.toNodeId');
  }

  factory SceneEdge.fromJson(Map<String, dynamic> json) {
    return SceneEdge(
      id: _readRequiredString(json, 'id'),
      fromNodeId: _readRequiredString(json, 'fromNodeId'),
      fromPortId: _readRequiredString(json, 'fromPortId'),
      toNodeId: _readRequiredString(json, 'toNodeId'),
      kind: _readSceneEdgeKind(json['kind'], 'kind'),
      label: _readOptionalString(json, 'label'),
    );
  }

  Map<String, dynamic> toJson() {
    return _withoutNulls({
      'id': id,
      'fromNodeId': fromNodeId,
      'fromPortId': fromPortId,
      'toNodeId': toNodeId,
      'kind': _sceneEdgeKindToJson(kind),
      'label': label,
    });
  }

  final String id;
  final String fromNodeId;
  final String fromPortId;
  final String toNodeId;
  final SceneEdgeKind kind;
  final String? label;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneEdge &&
          other.id == id &&
          other.fromNodeId == fromNodeId &&
          other.fromPortId == fromPortId &&
          other.toNodeId == toNodeId &&
          other.kind == kind &&
          other.label == label;

  @override
  int get hashCode =>
      Object.hash(id, fromNodeId, fromPortId, toNodeId, kind, label);
}

@immutable
final class SceneOutcome {
  SceneOutcome({
    required this.id,
    required this.label,
    this.description,
  }) {
    _requireNotBlank(id, 'SceneOutcome.id');
    _requireNotBlank(label, 'SceneOutcome.label');
  }

  factory SceneOutcome.fromJson(Map<String, dynamic> json) {
    return SceneOutcome(
      id: _readRequiredString(json, 'id'),
      label: _readRequiredString(json, 'label'),
      description: _readOptionalString(json, 'description'),
    );
  }

  Map<String, dynamic> toJson() {
    return _withoutNulls({
      'id': id,
      'label': label,
      'description': description,
    });
  }

  final String id;
  final String label;
  final String? description;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneOutcome &&
          other.id == id &&
          other.label == label &&
          other.description == description;

  @override
  int get hashCode => Object.hash(id, label, description);
}

void _requireNotBlank(String value, String field) {
  if (value.trim().isEmpty) {
    throw ValidationException('$field must not be blank');
  }
}

void _requireOptionalNotBlank(String? value, String field) {
  if (value != null && value.trim().isEmpty) {
    throw ValidationException('$field must not be blank when provided');
  }
}

void _requireFiniteNumber(double value, String field) {
  if (!value.isFinite) {
    throw ValidationException('$field must be finite');
  }
}

String _readRequiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String) {
    throw FormatException('$key must be a string');
  }
  _requireNotBlank(value, key);
  return value;
}

String? _readOptionalString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) {
    return null;
  }
  if (value is! String) {
    throw FormatException('$key must be a string');
  }
  _requireOptionalNotBlank(value, key);
  return value;
}

double _readRequiredDouble(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! num) {
    throw FormatException('$key must be a number');
  }
  final number = value.toDouble();
  _requireFiniteNumber(number, key);
  return number;
}

Map<String, dynamic> _readRequiredObject(
  Map<String, dynamic> json,
  String key,
) {
  final value = json[key];
  if (value is! Map) {
    throw FormatException('$key must be a JSON object');
  }
  return _jsonObject(value, key);
}

T? _readOptionalObject<T>(
  Map<String, dynamic> json,
  String key,
  T Function(Map<String, dynamic>) fromJson,
) {
  final value = json[key];
  if (value == null) {
    return null;
  }
  if (value is! Map) {
    throw FormatException('$key must be a JSON object');
  }
  return fromJson(_jsonObject(value, key));
}

List<T> _readObjectList<T>(
  Map<String, dynamic> json,
  String key,
  T Function(Map<String, dynamic>) fromJson,
) {
  final value = json[key];
  if (value == null) {
    return const [];
  }
  if (value is! List) {
    throw FormatException('$key must be a list');
  }
  return [
    for (final item in value)
      if (item is Map)
        fromJson(_jsonObject(item, key))
      else
        throw FormatException('$key entries must be JSON objects'),
  ];
}

List<String> _readStringList(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) {
    return const [];
  }
  if (value is! List) {
    throw FormatException('$key must be a list');
  }
  final strings = <String>[];
  for (final item in value) {
    if (item is! String) {
      throw FormatException('$key entries must be strings');
    }
    strings.add(item);
  }
  return _immutableNonBlankUniqueStrings(strings, key);
}

Map<String, String> _readStringMap(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) {
    return const {};
  }
  if (value is! Map) {
    throw FormatException('$key must be a JSON object');
  }
  final result = <String, String>{};
  for (final entry in value.entries) {
    if (entry.key is! String || entry.value is! String) {
      throw FormatException('$key entries must be strings');
    }
    result[entry.key as String] = entry.value as String;
  }
  return Map<String, String>.unmodifiable(result);
}

Map<String, dynamic> _jsonObject(Map json, String field) {
  return json.map((key, value) {
    if (key is! String) {
      throw FormatException('$field JSON keys must be strings');
    }
    return MapEntry(key, value);
  });
}

T _readEnum<T extends Enum>(
  List<T> values,
  Object? value,
  String field, {
  T? defaultValue,
}) {
  if (value == null && defaultValue != null) {
    return defaultValue;
  }
  if (value is! String) {
    throw FormatException('$field must be a string');
  }
  for (final candidate in values) {
    if (candidate.name == value) {
      return candidate;
    }
  }
  throw FormatException('Unknown $field value: $value');
}

SceneEdgeKind _readSceneEdgeKind(Object? value, String field) {
  if (value is! String) {
    throw FormatException('$field must be a string');
  }
  if (value == 'default') {
    return SceneEdgeKind.defaultFlow;
  }
  for (final candidate in SceneEdgeKind.values) {
    if (candidate.name == value) {
      return candidate;
    }
  }
  throw FormatException('Unknown $field value: $value');
}

String _enumToJson(Enum value) => value.name;

String _sceneEdgeKindToJson(SceneEdgeKind kind) {
  return switch (kind) {
    SceneEdgeKind.defaultFlow => 'default',
    _ => kind.name,
  };
}

List<String> _immutableNonBlankUniqueStrings(
  Iterable<String> values,
  String field,
) {
  final seen = <String>{};
  final result = <String>[];
  for (final value in values) {
    _requireNotBlank(value, field);
    if (!seen.add(value)) {
      throw ValidationException('$field contains duplicate id: $value');
    }
    result.add(value);
  }
  return List<String>.unmodifiable(result);
}

void _validateUniqueIds(Iterable<String> ids, String field) {
  final seen = <String>{};
  for (final id in ids) {
    _requireNotBlank(id, field);
    if (!seen.add(id)) {
      throw ValidationException('$field contains duplicate id: $id');
    }
  }
}

Map<String, dynamic> _withoutNulls(Map<String, dynamic> values) {
  return {
    for (final entry in values.entries)
      if (entry.value != null) entry.key: entry.value,
  };
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) {
    return true;
  }
  if (a.length != b.length) {
    return false;
  }
  for (var index = 0; index < a.length; index++) {
    if (a[index] != b[index]) {
      return false;
    }
  }
  return true;
}

bool _mapEquals<K, V>(Map<K, V> a, Map<K, V> b) {
  if (identical(a, b)) {
    return true;
  }
  if (a.length != b.length) {
    return false;
  }
  for (final key in a.keys) {
    if (!b.containsKey(key) || b[key] != a[key]) {
      return false;
    }
  }
  return true;
}

int _mapHash<K, V>(Map<K, V> map) {
  return Object.hashAll(
    map.entries.map((entry) => Object.hash(entry.key, entry.value)),
  );
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    for (final item in this) {
      return item;
    }
    return null;
  }
}

```

### Contenu complet — `packages/map_core/test/scene_asset_test.dart`
```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('SceneAsset construction', () {
    test('accepts a minimal scene with start and end nodes', () {
      final scene = _minimalScene();

      expect(scene.id, 'scene_intro');
      expect(scene.name, 'Intro scene');
      expect(scene.graph.startNodeId, 'node_start');
      expect(scene.graph.nodes, hasLength(2));
      expect(scene.graph.edges, hasLength(1));
      expect(scene.layout.nodeLayouts, hasLength(2));
      expect(scene.declaredOutcomes, isEmpty);
      expect(scene.metadata, isEmpty);
    });

    test('keeps graph logic and editor layout separated', () {
      final scene = _minimalScene();

      expect(scene.graph.toJson(), isNot(contains('nodeLayouts')));
      expect(scene.layout.toJson()['nodeLayouts'], isA<List<dynamic>>());
      expect(scene.layout.nodeLayouts.first.nodeId, 'node_start');
    });

    test('exposes V0 node and edge taxonomy', () {
      expect(SceneNodeKind.start, isA<SceneNodeKind>());
      expect(SceneNodeKind.end, isA<SceneNodeKind>());
      expect(SceneNodeKind.yarnDialogue, isA<SceneNodeKind>());
      expect(SceneNodeKind.condition, isA<SceneNodeKind>());
      expect(SceneNodeKind.action, isA<SceneNodeKind>());
      expect(SceneNodeKind.battle, isA<SceneNodeKind>());
      expect(SceneNodeKind.cinematic, isA<SceneNodeKind>());
      expect(SceneNodeKind.branchByOutcome, isA<SceneNodeKind>());
      expect(SceneNodeKind.merge, isA<SceneNodeKind>());

      expect(SceneEdgeKind.defaultFlow, isA<SceneEdgeKind>());
      expect(SceneEdgeKind.conditionTrue, isA<SceneEdgeKind>());
      expect(SceneEdgeKind.conditionFalse, isA<SceneEdgeKind>());
      expect(SceneEdgeKind.dialogueOutcome, isA<SceneEdgeKind>());
      expect(SceneEdgeKind.battleVictory, isA<SceneEdgeKind>());
      expect(SceneEdgeKind.battleDefeat, isA<SceneEdgeKind>());
      expect(SceneEdgeKind.cinematicCompleted, isA<SceneEdgeKind>());
      expect(SceneEdgeKind.actionCompleted, isA<SceneEdgeKind>());
      expect(SceneEdgeKind.branchOutcome, isA<SceneEdgeKind>());
      expect(SceneEdgeKind.error, isA<SceneEdgeKind>());
      expect(SceneEdgeKind.blocked, isA<SceneEdgeKind>());
    });
  });

  group('SceneAsset validation', () {
    test('rejects blank core identifiers and names', () {
      expect(() => SceneAsset(id: '', name: 'Scene', graph: _graph()), _throws);
      expect(
          () => SceneAsset(id: 'scene', name: ' ', graph: _graph()), _throws);
      expect(
        () => SceneGraph(startNodeId: '', nodes: _nodes()),
        _throws,
      );
      expect(
        () => SceneNode(id: '', kind: SceneNodeKind.start),
        _throws,
      );
      expect(
        () => SceneEdge(
          id: '',
          fromNodeId: 'node_start',
          fromPortId: 'completed',
          toNodeId: 'node_end',
          kind: SceneEdgeKind.defaultFlow,
        ),
        _throws,
      );
      expect(
        () => SceneOutcome(id: '', label: 'Completed'),
        _throws,
      );
      expect(
        () => SceneOutcome(id: 'completed', label: ''),
        _throws,
      );
    });

    test('rejects duplicate graph, layout and outcome ids', () {
      expect(
        () => SceneGraph(
          startNodeId: 'node_start',
          nodes: [
            SceneNode(id: 'node_start', kind: SceneNodeKind.start),
            SceneNode(id: 'node_start', kind: SceneNodeKind.end),
          ],
        ),
        _throws,
      );
      expect(
        () => SceneAsset(
          id: 'scene',
          name: 'Scene',
          graph: _graph(),
          layout: SceneGraphLayout(
            nodeLayouts: [
              SceneNodeLayout(nodeId: 'node_start', x: 0, y: 0),
              SceneNodeLayout(nodeId: 'node_start', x: 32, y: 0),
            ],
          ),
        ),
        _throws,
      );
      expect(
        () => SceneAsset(
          id: 'scene',
          name: 'Scene',
          graph: _graph(),
          declaredOutcomes: [
            SceneOutcome(id: 'done', label: 'Done'),
            SceneOutcome(id: 'done', label: 'Done again'),
          ],
        ),
        _throws,
      );
    });

    test('rejects missing start node and broken edge references', () {
      expect(
        () => SceneGraph(
          startNodeId: 'missing',
          nodes: _nodes(),
        ),
        _throws,
      );
      expect(
        () => SceneGraph(
          startNodeId: 'node_start',
          nodes: _nodes(),
          edges: [
            SceneEdge(
              id: 'edge_missing_target',
              fromNodeId: 'node_start',
              fromPortId: 'completed',
              toNodeId: 'missing',
              kind: SceneEdgeKind.defaultFlow,
            ),
          ],
        ),
        _throws,
      );
      expect(
        () => SceneEdge(
          id: 'edge',
          fromNodeId: 'node_start',
          fromPortId: '',
          toNodeId: 'node_end',
          kind: SceneEdgeKind.defaultFlow,
        ),
        _throws,
      );
    });

    test('rejects payloads attached to incompatible node kinds', () {
      expect(
        () => SceneNode(
          id: 'node_dialogue',
          kind: SceneNodeKind.condition,
          payload: SceneYarnDialoguePayload(dialogueId: 'dialogue_intro'),
        ),
        _throws,
      );
    });
  });

  group('SceneAsset authoring guarantees', () {
    test('keeps ids stable when user-facing names are renamed', () {
      final before = _minimalScene();
      final after = SceneAsset(
        id: before.id,
        name: 'Renamed scene',
        description: before.description,
        graph: before.graph,
        layout: before.layout,
      );

      expect(after.id, before.id);
      expect(after.name, 'Renamed scene');
    });

    test('keeps metadata non-critical and string-only', () {
      final scene = SceneAsset(
        id: 'scene',
        name: 'Scene',
        graph: _graph(),
        metadata: const {
          'seed': 'manual_fixture',
          'notes': 'non critical',
        },
      );

      expect(scene.metadata['seed'], 'manual_fixture');
      expect(scene.toJson()['metadata'], isA<Map<String, String>>());
    });
  });
}

final Matcher _throws = throwsA(
  anyOf(isA<FormatException>(), isA<ValidationException>()),
);

SceneAsset _minimalScene() {
  return SceneAsset(
    id: 'scene_intro',
    name: 'Intro scene',
    description: 'A minimal orchestration scene.',
    graph: _graph(),
    layout: SceneGraphLayout(
      nodeLayouts: [
        SceneNodeLayout(nodeId: 'node_start', x: 0, y: 0),
        SceneNodeLayout(nodeId: 'node_end', x: 320, y: 0),
      ],
    ),
  );
}

SceneGraph _graph() {
  return SceneGraph(
    startNodeId: 'node_start',
    nodes: _nodes(),
    edges: [
      SceneEdge(
        id: 'edge_start_end',
        fromNodeId: 'node_start',
        fromPortId: 'completed',
        toNodeId: 'node_end',
        kind: SceneEdgeKind.defaultFlow,
      ),
    ],
  );
}

List<SceneNode> _nodes() {
  return [
    SceneNode(id: 'node_start', kind: SceneNodeKind.start),
    SceneNode(id: 'node_end', kind: SceneNodeKind.end),
  ];
}

```

### Contenu complet — `packages/map_core/test/scene_asset_json_test.dart`
```dart
import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('SceneAsset JSON roundtrip', () {
    test('round-trips a complete V0 authoring shape', () {
      final scene = _completeScene();

      final json =
          jsonDecode(jsonEncode(scene.toJson())) as Map<String, dynamic>;
      final decoded = SceneAsset.fromJson(json);

      expect(decoded, equals(scene));
      expect(json['graph'], isA<Map<String, dynamic>>());
      expect(json['layout'], isA<Map<String, dynamic>>());
      expect(json['declaredOutcomes'], isA<List<dynamic>>());
      expect(json['metadata'], isA<Map<String, dynamic>>());
    });

    test('serializes enums as stable strings', () {
      final json = _completeScene().toJson();
      final graph = json['graph'] as Map<String, dynamic>;
      final nodes = graph['nodes'] as List<dynamic>;
      final edges = graph['edges'] as List<dynamic>;

      final start = nodes.first as Map<String, dynamic>;
      final firstEdge = edges.first as Map<String, dynamic>;

      expect(start['kind'], 'start');
      expect(firstEdge['kind'], 'default');
      expect(start['kind'], isNot(isA<int>()));
      expect(firstEdge['kind'], isNot(isA<int>()));
    });

    test('round-trips all minimal payload kinds', () {
      final payloads = <SceneNodePayload>[
        SceneStartPayload(notes: 'Entry point'),
        SceneEndPayload(sceneOutcomeId: 'scene_done'),
        SceneYarnDialoguePayload(
          dialogueId: 'dialogue_intro',
          yarnNodeName: 'Start',
          expectedOutcomes: const ['reassure', 'panic'],
          speakerHints: const ['npc_mayor'],
        ),
        SceneConditionPayload(
          conditionLabel: 'Has seen the lighthouse',
          conditionRef: 'condition_seen_lighthouse',
        ),
        SceneActionPayload(
          actionKind: 'setFlag',
          parameters: {'flagId': 'saw_lighthouse'},
        ),
        SceneBattlePayload(
          battleKind: 'trainer',
          trainerId: 'trainer_rival',
          declaredOutcomes: const ['victory', 'defeat'],
        ),
        SceneCinematicPayload(cinematicId: 'cinematic_fog_lifts'),
        SceneBranchByOutcomePayload(
          sourceNodeId: 'node_dialogue',
          sourceOutcomeSetRef: 'dialogue_intro',
          fallbackPolicy: 'blocked',
        ),
        SceneMergePayload(label: 'Return to main flow'),
      ];

      for (final payload in payloads) {
        final decoded = SceneNodePayload.fromJson(payload.toJson());

        expect(decoded, equals(payload));
      }
    });

    test('round-trips layout nodes and edge control points', () {
      final layout = SceneGraphLayout(
        nodeLayouts: [
          SceneNodeLayout(nodeId: 'node_start', x: 0, y: 0),
        ],
        edgeLayouts: [
          SceneEdgeLayout(
            edgeId: 'edge_start_dialogue',
            controlPoints: [
              SceneLayoutPoint(x: 120, y: 32),
              SceneLayoutPoint(x: 240, y: 32),
            ],
          ),
        ],
      );

      expect(SceneGraphLayout.fromJson(layout.toJson()), equals(layout));
    });
  });

  group('SceneAsset JSON defaults and invalid shapes', () {
    test('decodes stable defaults from minimal JSON', () {
      final decoded = SceneAsset.fromJson({
        'id': 'scene',
        'name': 'Scene',
        'graph': _minimalGraphJson(),
      });

      expect(decoded.description, isNull);
      expect(decoded.tags, isEmpty);
      expect(decoded.layout, equals(SceneGraphLayout()));
      expect(decoded.declaredOutcomes, isEmpty);
      expect(decoded.metadata, isEmpty);
    });

    test('rejects unknown enum and invalid payload shapes', () {
      expect(
        () => SceneNode.fromJson({
          'id': 'node',
          'kind': 'dialogue',
        }),
        _throws,
      );
      expect(
        () => SceneEdge.fromJson({
          'id': 'edge',
          'fromNodeId': 'from',
          'fromPortId': 'completed',
          'toNodeId': 'to',
          'kind': 'unknown',
        }),
        _throws,
      );
      expect(
        () => SceneNodePayload.fromJson({
          'kind': 'yarnDialogue',
        }),
        _throws,
      );
      expect(
        () => SceneNodePayload.fromJson({
          'kind': 'action',
          'actionKind': 'setFlag',
          'parameters': {'flag': 1},
        }),
        _throws,
      );
    });
  });
}

final Matcher _throws = throwsA(
  anyOf(isA<FormatException>(), isA<ValidationException>()),
);

SceneAsset _completeScene() {
  return SceneAsset(
    id: 'scene_intro',
    name: 'Intro scene',
    description: 'Scene graph with every V0 node kind.',
    storylineId: 'story_main',
    chapterId: 'chapter_1',
    tags: const ['demo', 'draft'],
    graph: SceneGraph(
      startNodeId: 'node_start',
      nodes: [
        SceneNode(
          id: 'node_start',
          kind: SceneNodeKind.start,
          title: 'Start',
          payload: SceneStartPayload(notes: 'Entry'),
        ),
        SceneNode(
          id: 'node_dialogue',
          kind: SceneNodeKind.yarnDialogue,
          title: 'Talk',
          payload: SceneYarnDialoguePayload(
            dialogueId: 'dialogue_intro',
            yarnNodeName: 'Start',
            expectedOutcomes: const ['reassure', 'panic'],
          ),
        ),
        SceneNode(
          id: 'node_branch',
          kind: SceneNodeKind.branchByOutcome,
          title: 'Branch',
          payload: SceneBranchByOutcomePayload(sourceNodeId: 'node_dialogue'),
        ),
        SceneNode(
          id: 'node_condition',
          kind: SceneNodeKind.condition,
          title: 'Check',
          payload: SceneConditionPayload(conditionRef: 'condition_has_badge'),
        ),
        SceneNode(
          id: 'node_action',
          kind: SceneNodeKind.action,
          title: 'Set flag',
          payload: SceneActionPayload(actionKind: 'setFlag'),
        ),
        SceneNode(
          id: 'node_battle',
          kind: SceneNodeKind.battle,
          title: 'Battle',
          payload: SceneBattlePayload(
            battleKind: 'trainer',
            trainerId: 'trainer_rival',
            declaredOutcomes: ['victory', 'defeat'],
          ),
        ),
        SceneNode(
          id: 'node_cinematic',
          kind: SceneNodeKind.cinematic,
          title: 'Cinematic',
          payload: SceneCinematicPayload(cinematicId: 'cinematic_intro'),
        ),
        SceneNode(
          id: 'node_merge',
          kind: SceneNodeKind.merge,
          title: 'Merge',
          payload: SceneMergePayload(label: 'Continue'),
        ),
        SceneNode(
          id: 'node_end',
          kind: SceneNodeKind.end,
          title: 'End',
          payload: SceneEndPayload(sceneOutcomeId: 'scene_done'),
        ),
      ],
      edges: [
        SceneEdge(
          id: 'edge_start_dialogue',
          fromNodeId: 'node_start',
          fromPortId: 'completed',
          toNodeId: 'node_dialogue',
          kind: SceneEdgeKind.defaultFlow,
        ),
        SceneEdge(
          id: 'edge_dialogue_branch',
          fromNodeId: 'node_dialogue',
          fromPortId: 'outcome:reassure',
          toNodeId: 'node_branch',
          kind: SceneEdgeKind.dialogueOutcome,
          label: 'Reassure',
        ),
        SceneEdge(
          id: 'edge_condition_true',
          fromNodeId: 'node_condition',
          fromPortId: 'true',
          toNodeId: 'node_action',
          kind: SceneEdgeKind.conditionTrue,
        ),
      ],
    ),
    layout: SceneGraphLayout(
      nodeLayouts: [
        SceneNodeLayout(nodeId: 'node_start', x: 0, y: 0),
        SceneNodeLayout(nodeId: 'node_dialogue', x: 240, y: 0),
      ],
    ),
    declaredOutcomes: [
      SceneOutcome(
        id: 'scene_done',
        label: 'Scene completed',
        description: 'The scene reached a clean end.',
      ),
    ],
    metadata: const {'source': 'unit_test'},
  );
}

Map<String, dynamic> _minimalGraphJson() {
  return {
    'startNodeId': 'node_start',
    'nodes': [
      {'id': 'node_start', 'kind': 'start'},
      {'id': 'node_end', 'kind': 'end'},
    ],
    'edges': [
      {
        'id': 'edge_start_end',
        'fromNodeId': 'node_start',
        'fromPortId': 'completed',
        'toNodeId': 'node_end',
        'kind': 'default',
      },
    ],
  };
}

```

### Contenu complet — `packages/map_core/test/project_manifest_scenes_test.dart`
```dart
import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectManifest scenes integration', () {
    test('decodes old project JSON without scenes as empty list', () {
      final manifest = ProjectManifest.fromJson(_minimalProjectJson());

      expect(manifest.scenes, isEmpty);
      expect(manifest.scenarios, isEmpty);
      expect(manifest.storylines, isEmpty);
    });

    test('decodes scenes null and empty scenes as empty list', () {
      expect(
        ProjectManifest.fromJson({
          ..._minimalProjectJson(),
          'scenes': null,
        }).scenes,
        isEmpty,
      );
      expect(
        ProjectManifest.fromJson({
          ..._minimalProjectJson(),
          'scenes': <Object?>[],
        }).scenes,
        isEmpty,
      );
    });

    test('decodes project JSON with a SceneAsset', () {
      final manifest = ProjectManifest.fromJson({
        ..._minimalProjectJson(),
        'scenes': [_scene().toJson()],
      });

      expect(manifest.scenes, hasLength(1));
      expect(manifest.scenes.single.id, 'scene_intro');
      expect(manifest.scenes.single.graph.nodes, hasLength(2));
    });

    test('round-trips manifest with scenes through JSON', () {
      final manifest = ProjectManifest(
        name: 'Project',
        maps: const [],
        tilesets: const [],
        scenes: [_scene()],
      );

      final json =
          jsonDecode(jsonEncode(manifest.toJson())) as Map<String, dynamic>;
      final decoded = ProjectManifest.fromJson(json);

      expect(decoded.scenes, equals(manifest.scenes));
      expect(decoded.toJson()['scenes'], isA<List<dynamic>>());
    });

    test('keeps scenarios and storylines independent from scenes', () {
      final scenario = const ScenarioAsset(
        id: 'legacy_scenario',
        name: 'Legacy Scenario',
        scope: ScenarioScope.localEventFlow,
        entryNodeId: 'start',
        nodes: [
          ScenarioNode(id: 'start', type: ScenarioNodeType.start),
        ],
      );
      final storyline = StorylineAsset(
        id: 'story_main',
        type: StorylineType.main,
        title: 'Main Story',
      );

      final manifest = ProjectManifest.fromJson({
        ..._minimalProjectJson(),
        'scenarios': [scenario.toJson()],
        'storylines': [storyline.toJson()],
        'scenes': [_scene().toJson()],
      });

      expect(manifest.scenes, hasLength(1));
      expect(manifest.scenarios, hasLength(1));
      expect(manifest.scenarios.single.id, 'legacy_scenario');
      expect(manifest.storylines, hasLength(1));
      expect(manifest.storylines.single.id, 'story_main');
    });

    test('rejects invalid scenes JSON shape', () {
      expect(
        () => ProjectManifest.fromJson({
          ..._minimalProjectJson(),
          'scenes': 'not-a-list',
        }),
        _throwsDecode,
      );
      expect(
        () => ProjectManifest.fromJson({
          ..._minimalProjectJson(),
          'scenes': ['not-an-object'],
        }),
        _throwsDecode,
      );
      expect(
        () => ProjectManifest.fromJson({
          ..._minimalProjectJson(),
          'scenes': [
            {
              'id': '',
              'name': 'Broken',
              'graph': _graphJson(),
            },
          ],
        }),
        _throwsDecode,
      );
    });
  });
}

final Matcher _throwsDecode = throwsA(
  anyOf(isA<FormatException>(), isA<ValidationException>()),
);

Map<String, dynamic> _minimalProjectJson() {
  return {
    'name': 'Project',
    'maps': <Object?>[],
    'tilesets': <Object?>[],
  };
}

SceneAsset _scene() {
  return SceneAsset(
    id: 'scene_intro',
    name: 'Intro scene',
    graph: SceneGraph(
      startNodeId: 'node_start',
      nodes: [
        SceneNode(id: 'node_start', kind: SceneNodeKind.start),
        SceneNode(id: 'node_end', kind: SceneNodeKind.end),
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
}

Map<String, dynamic> _graphJson() {
  return {
    'startNodeId': 'node_start',
    'nodes': [
      {'id': 'node_start', 'kind': 'start'},
      {'id': 'node_end', 'kind': 'end'},
    ],
    'edges': [
      {
        'id': 'edge_start_end',
        'fromNodeId': 'node_start',
        'fromPortId': 'completed',
        'toNodeId': 'node_end',
        'kind': 'default',
      },
    ],
  };
}

```

### Diff complet — `packages/map_core/lib/src/models/project_manifest.dart`
```diff
diff --git a/packages/map_core/lib/src/models/project_manifest.dart b/packages/map_core/lib/src/models/project_manifest.dart
index eda59fab..2259f8b4 100644
--- a/packages/map_core/lib/src/models/project_manifest.dart
+++ b/packages/map_core/lib/src/models/project_manifest.dart
@@ -8,6 +8,7 @@ import 'project_trainer.dart';
 import 'project_path_pattern_preset.dart';
 import 'projected_building_shadow.dart';
 import 'scenario_asset.dart';
+import 'scene_asset.dart';
 import 'script_asset.dart';
 import 'shadow.dart';
 import 'shadow_catalog.dart';
@@ -83,6 +84,38 @@ Map<String, dynamic> _storylineJsonObject(Object? json) {
   });
 }
 
+/// JSON -> authoring Scenes.
+///
+/// Missing or `null` keeps old projects readable as an empty list. This does
+/// not import or migrate legacy `ScenarioAsset` data automatically.
+List<SceneAsset> _scenesFromJson(Object? json) {
+  if (json == null) {
+    return const <SceneAsset>[];
+  }
+  if (json is! List) {
+    throw const ValidationException('scenes must be a JSON list');
+  }
+  return [
+    for (final item in json) SceneAsset.fromJson(_sceneJsonObject(item)),
+  ];
+}
+
+List<Map<String, dynamic>> _scenesToJson(List<SceneAsset> scenes) {
+  return [for (final scene in scenes) scene.toJson()];
+}
+
+Map<String, dynamic> _sceneJsonObject(Object? json) {
+  if (json is! Map) {
+    throw const ValidationException('scene must be a JSON object');
+  }
+  return json.map((key, value) {
+    if (key is! String) {
+      throw const ValidationException('scene JSON keys must be strings');
+    }
+    return MapEntry(key, value);
+  });
+}
+
 /// JSON -> ShadowV2 projected building shadow catalog.
 ///
 /// Missing or `null` root data remains an empty in-memory catalog. When the
@@ -202,6 +235,13 @@ class ProjectManifest with _$ProjectManifest {
     @Default([]) List<ProjectScriptEntry> scripts,
     @Default([]) List<ScenarioAsset> scenarios,
     @Default([])
+    @JsonKey(
+      name: 'scenes',
+      fromJson: _scenesFromJson,
+      toJson: _scenesToJson,
+    )
+    List<SceneAsset> scenes,
+    @Default([])
     @JsonKey(
       name: 'storylines',
       fromJson: _storylinesFromJson,
```

### Diff complet — `packages/map_core/lib/src/models/project_manifest.freezed.dart`
```diff
diff --git a/packages/map_core/lib/src/models/project_manifest.freezed.dart b/packages/map_core/lib/src/models/project_manifest.freezed.dart
index 56de7193..aa4da7e0 100644
--- a/packages/map_core/lib/src/models/project_manifest.freezed.dart
+++ b/packages/map_core/lib/src/models/project_manifest.freezed.dart
@@ -57,6 +57,8 @@ mixin _$ProjectManifest {
       throw _privateConstructorUsedError;
   List<ProjectScriptEntry> get scripts => throw _privateConstructorUsedError;
   List<ScenarioAsset> get scenarios => throw _privateConstructorUsedError;
+  @JsonKey(name: 'scenes', fromJson: _scenesFromJson, toJson: _scenesToJson)
+  List<SceneAsset> get scenes => throw _privateConstructorUsedError;
   @JsonKey(
       name: 'storylines',
       fromJson: _storylinesFromJson,
@@ -129,6 +131,8 @@ abstract class $ProjectManifestCopyWith<$Res> {
       List<ProjectDialogueEntry> dialogues,
       List<ProjectScriptEntry> scripts,
       List<ScenarioAsset> scenarios,
+      @JsonKey(name: 'scenes', fromJson: _scenesFromJson, toJson: _scenesToJson)
+      List<SceneAsset> scenes,
       @JsonKey(
           name: 'storylines',
           fromJson: _storylinesFromJson,
@@ -190,6 +194,7 @@ class _$ProjectManifestCopyWithImpl<$Res, $Val extends ProjectManifest>
     Object? dialogues = null,
     Object? scripts = null,
     Object? scenarios = null,
+    Object? scenes = null,
     Object? storylines = null,
     Object? trainers = null,
     Object? characters = null,
@@ -277,6 +282,10 @@ class _$ProjectManifestCopyWithImpl<$Res, $Val extends ProjectManifest>
           ? _value.scenarios
           : scenarios // ignore: cast_nullable_to_non_nullable
               as List<ScenarioAsset>,
+      scenes: null == scenes
+          ? _value.scenes
+          : scenes // ignore: cast_nullable_to_non_nullable
+              as List<SceneAsset>,
       storylines: null == storylines
           ? _value.storylines
           : storylines // ignore: cast_nullable_to_non_nullable
@@ -373,6 +382,8 @@ abstract class _$$ProjectManifestImplCopyWith<$Res>
       List<ProjectDialogueEntry> dialogues,
       List<ProjectScriptEntry> scripts,
       List<ScenarioAsset> scenarios,
+      @JsonKey(name: 'scenes', fromJson: _scenesFromJson, toJson: _scenesToJson)
+      List<SceneAsset> scenes,
       @JsonKey(
           name: 'storylines',
           fromJson: _storylinesFromJson,
@@ -434,6 +445,7 @@ class __$$ProjectManifestImplCopyWithImpl<$Res>
     Object? dialogues = null,
     Object? scripts = null,
     Object? scenarios = null,
+    Object? scenes = null,
     Object? storylines = null,
     Object? trainers = null,
     Object? characters = null,
@@ -521,6 +533,10 @@ class __$$ProjectManifestImplCopyWithImpl<$Res>
           ? _value._scenarios
           : scenarios // ignore: cast_nullable_to_non_nullable
               as List<ScenarioAsset>,
+      scenes: null == scenes
+          ? _value._scenes
+          : scenes // ignore: cast_nullable_to_non_nullable
+              as List<SceneAsset>,
       storylines: null == storylines
           ? _value._storylines
           : storylines // ignore: cast_nullable_to_non_nullable
@@ -593,6 +609,8 @@ class _$ProjectManifestImpl implements _ProjectManifest {
       final List<ProjectDialogueEntry> dialogues = const [],
       final List<ProjectScriptEntry> scripts = const [],
       final List<ScenarioAsset> scenarios = const [],
+      @JsonKey(name: 'scenes', fromJson: _scenesFromJson, toJson: _scenesToJson)
+      final List<SceneAsset> scenes = const [],
       @JsonKey(
           name: 'storylines',
           fromJson: _storylinesFromJson,
@@ -634,6 +652,7 @@ class _$ProjectManifestImpl implements _ProjectManifest {
         _dialogues = dialogues,
         _scripts = scripts,
         _scenarios = scenarios,
+        _scenes = scenes,
         _storylines = storylines,
         _trainers = trainers,
         _characters = characters,
@@ -808,6 +827,15 @@ class _$ProjectManifestImpl implements _ProjectManifest {
     return EqualUnmodifiableListView(_scenarios);
   }
 
+  final List<SceneAsset> _scenes;
+  @override
+  @JsonKey(name: 'scenes', fromJson: _scenesFromJson, toJson: _scenesToJson)
+  List<SceneAsset> get scenes {
+    if (_scenes is EqualUnmodifiableListView) return _scenes;
+    // ignore: implicit_dynamic_type
+    return EqualUnmodifiableListView(_scenes);
+  }
+
   final List<StorylineAsset> _storylines;
   @override
   @JsonKey(
@@ -873,7 +901,7 @@ class _$ProjectManifestImpl implements _ProjectManifest {
 
   @override
   String toString() {
-    return 'ProjectManifest(name: $name, version: $version, maps: $maps, groups: $groups, tilesetFolders: $tilesetFolders, tilesets: $tilesets, elementCategories: $elementCategories, elements: $elements, terrainCategories: $terrainCategories, pathCategories: $pathCategories, terrainPresets: $terrainPresets, pathPresets: $pathPresets, pathPatternPresets: $pathPatternPresets, environmentPresets: $environmentPresets, encounterTables: $encounterTables, dialogueFolders: $dialogueFolders, dialogues: $dialogues, scripts: $scripts, scenarios: $scenarios, storylines: $storylines, trainers: $trainers, characters: $characters, settings: $settings, pokemon: $pokemon, globalProperties: $globalProperties, surfaceCatalog: $surfaceCatalog, shadowCatalog: $shadowCatalog, projectedBuildingShadowCatalog: $projectedBuildingShadowCatalog)';
+    return 'ProjectManifest(name: $name, version: $version, maps: $maps, groups: $groups, tilesetFolders: $tilesetFolders, tilesets: $tilesets, elementCategories: $elementCategories, elements: $elements, terrainCategories: $terrainCategories, pathCategories: $pathCategories, terrainPresets: $terrainPresets, pathPresets: $pathPresets, pathPatternPresets: $pathPatternPresets, environmentPresets: $environmentPresets, encounterTables: $encounterTables, dialogueFolders: $dialogueFolders, dialogues: $dialogues, scripts: $scripts, scenarios: $scenarios, scenes: $scenes, storylines: $storylines, trainers: $trainers, characters: $characters, settings: $settings, pokemon: $pokemon, globalProperties: $globalProperties, surfaceCatalog: $surfaceCatalog, shadowCatalog: $shadowCatalog, projectedBuildingShadowCatalog: $projectedBuildingShadowCatalog)';
   }
 
   @override
@@ -912,6 +940,7 @@ class _$ProjectManifestImpl implements _ProjectManifest {
             const DeepCollectionEquality().equals(other._scripts, _scripts) &&
             const DeepCollectionEquality()
                 .equals(other._scenarios, _scenarios) &&
+            const DeepCollectionEquality().equals(other._scenes, _scenes) &&
             const DeepCollectionEquality()
                 .equals(other._storylines, _storylines) &&
             const DeepCollectionEquality().equals(other._trainers, _trainers) &&
@@ -955,6 +984,7 @@ class _$ProjectManifestImpl implements _ProjectManifest {
         const DeepCollectionEquality().hash(_dialogues),
         const DeepCollectionEquality().hash(_scripts),
         const DeepCollectionEquality().hash(_scenarios),
+        const DeepCollectionEquality().hash(_scenes),
         const DeepCollectionEquality().hash(_storylines),
         const DeepCollectionEquality().hash(_trainers),
         const DeepCollectionEquality().hash(_characters),
@@ -1012,6 +1042,8 @@ abstract class _ProjectManifest implements ProjectManifest {
       final List<ProjectDialogueEntry> dialogues,
       final List<ProjectScriptEntry> scripts,
       final List<ScenarioAsset> scenarios,
+      @JsonKey(name: 'scenes', fromJson: _scenesFromJson, toJson: _scenesToJson)
+      final List<SceneAsset> scenes,
       @JsonKey(
           name: 'storylines',
           fromJson: _storylinesFromJson,
@@ -1087,6 +1119,9 @@ abstract class _ProjectManifest implements ProjectManifest {
   @override
   List<ScenarioAsset> get scenarios;
   @override
+  @JsonKey(name: 'scenes', fromJson: _scenesFromJson, toJson: _scenesToJson)
+  List<SceneAsset> get scenes;
+  @override
   @JsonKey(
       name: 'storylines',
       fromJson: _storylinesFromJson,
```

### Diff complet — `packages/map_core/lib/src/models/project_manifest.g.dart`
```diff
diff --git a/packages/map_core/lib/src/models/project_manifest.g.dart b/packages/map_core/lib/src/models/project_manifest.g.dart
index 3b0e143c..742f189f 100644
--- a/packages/map_core/lib/src/models/project_manifest.g.dart
+++ b/packages/map_core/lib/src/models/project_manifest.g.dart
@@ -87,6 +87,8 @@ _$ProjectManifestImpl _$$ProjectManifestImplFromJson(
               ?.map((e) => ScenarioAsset.fromJson(e as Map<String, dynamic>))
               .toList() ??
           const [],
+      scenes:
+          json['scenes'] == null ? const [] : _scenesFromJson(json['scenes']),
       storylines: json['storylines'] == null
           ? const []
           : _storylinesFromJson(json['storylines']),
@@ -151,6 +153,7 @@ Map<String, dynamic> _$$ProjectManifestImplToJson(
       'dialogues': instance.dialogues.map((e) => e.toJson()).toList(),
       'scripts': instance.scripts.map((e) => e.toJson()).toList(),
       'scenarios': instance.scenarios.map((e) => e.toJson()).toList(),
+      'scenes': _scenesToJson(instance.scenes),
       'storylines': _storylinesToJson(instance.storylines),
       'trainers': instance.trainers.map((e) => e.toJson()).toList(),
       'characters': instance.characters.map((e) => e.toJson()).toList(),
```

### Diff complet — `packages/map_core/lib/map_core.dart`
```diff
diff --git a/packages/map_core/lib/map_core.dart b/packages/map_core/lib/map_core.dart
index db91ee66..7f0d18d8 100644
--- a/packages/map_core/lib/map_core.dart
+++ b/packages/map_core/lib/map_core.dart
@@ -25,6 +25,7 @@ export 'src/models/script_conditions.dart';
 export 'src/models/map_event_definition.dart';
 export 'src/models/project_trainer.dart';
 export 'src/models/scenario_asset.dart';
+export 'src/models/scene_asset.dart';
 export 'src/models/storyline_asset.dart';
 export 'src/models/visual_frame_json.dart';
 export 'src/models/shadow.dart';
```

### Diff complet — `reports/narrativeStudio/scenes/road_map_scenes.md`
```diff
diff --git a/reports/narrativeStudio/scenes/road_map_scenes.md b/reports/narrativeStudio/scenes/road_map_scenes.md
index 325a9137..c9f081cd 100644
--- a/reports/narrativeStudio/scenes/road_map_scenes.md
+++ b/reports/narrativeStudio/scenes/road_map_scenes.md
@@ -39,7 +39,7 @@ Ces briques sont utiles, mais elles ne constituent pas encore une Scene V1 propr
 | NS-SCENES-V1-00 — Scene System Scope / Current State Audit | DONE | Audit documentaire de l'existant, definition Scene V1, frontieres produit et roadmap. |
 | NS-SCENES-V1-01 — Scene Product Model / Graph Contract | DONE | Contrat produit Scene V1 formalise : definitions Scene/Graph/Node/Edge/Port/Outcome, taxonomie nodes/edges, payloads minimaux/interdits, diagnostics et runtime intents. |
 | NS-SCENES-V1-02 — Scene Storage / ID / Read Model Decision | DONE | Decision retenue : `SceneAsset` authoring dedie + `ProjectManifest.scenes` futur, avec `ScenarioAsset` conserve comme legacy/runtime bridge temporaire et sans migration automatique. |
-| NS-SCENES-V1-03 — Scene Core Model V0 | TODO | Ajouter le modele core `SceneAsset`, graph/layout value objects, `ProjectManifest.scenes`, exports et tests JSON/core. |
+| NS-SCENES-V1-03 — Scene Core Model V0 | DONE | Modele core `SceneAsset` ajoute dans `map_core` avec `SceneGraph`, `SceneGraphLayout`, nodes/edges/outcomes, `ProjectManifest.scenes`, export public et tests core/JSON/manifest. |
 | NS-SCENES-V1-04 — Workspace Shell Scenes | TODO | Creer le shell editor `Scenes` sans authoring profond ni runtime. |
 | NS-SCENES-V1-05 — Scene Tree Panel Read-only | TODO | Afficher une arborescence de scenes reelles depuis `ProjectManifest.scenes`, sans fake fallback. |
 | NS-SCENES-V1-06 — Graph Read-only Skeleton | TODO | Afficher un graph Scene V1 read-only avec start/end et nodes reels du read model. |
@@ -51,9 +51,30 @@ Ces briques sont utiles, mais elles ne constituent pas encore une Scene V1 propr
 
 ## Prochain lot recommande
 
-`NS-SCENES-V1-03 — Scene Core Model V0`
+`NS-SCENES-V1-04 — Workspace Shell Scenes`
 
-Raison : la decision storage/IDs/read models est tranchee ; une UI Scenes sans modele core creerait du faux. Le prochain lot doit poser `SceneAsset`, `ProjectManifest.scenes`, graph/layout et tests core avant le shell editor.
+Raison : le modele core Scene V1 existe maintenant dans `map_core` et `ProjectManifest.scenes` est serialisable avec compatibilite absent/null vers `[]`. Le prochain lot peut creer le shell editor Scenes sans authoring profond, sans runtime et sans brancher Storylines.
+
+## Decisions V1-03
+
+- `SceneAsset` est le modele authoring Scene V1 dedie.
+- `SceneGraph` contient `startNodeId`, nodes et edges ; il ne contient pas le layout.
+- `SceneGraphLayout` est separe et editor-only : node layouts et edge layouts peuvent etre ignores par le runtime.
+- `SceneNodeKind` couvre `start`, `end`, `yarnDialogue`, `condition`, `action`, `battle`, `cinematic`, `branchByOutcome`, `merge`.
+- `SceneEdge` porte un `fromPortId` explicite ; le kind JSON `default` est expose via l'enum Dart `defaultFlow` pour eviter le mot-cle Dart.
+- Les payloads de nodes sont types ; aucun `Map<String, dynamic>` global ne porte la logique.
+- `ProjectManifest.scenes` est ajoute sans supprimer ni migrer `ProjectManifest.scenarios`.
+- `map_core.dart` exporte `scene_asset.dart`.
+
+## Limites V1-03
+
+- Aucun workspace UI Scenes.
+- Aucun runtime Scene.
+- Aucun adapter `SceneAsset -> ScenarioAsset` ou `ScenarioAsset -> SceneAsset`.
+- Aucun diagnostic avance de graph.
+- Aucun authoring operation.
+- Aucun seed Selbrume ni scene de demonstration.
+- Aucun branchement `StorylineStep.sceneLinkIds`.
 
 ## Decisions V1-02
 
@@ -100,7 +121,7 @@ Raison : la decision storage/IDs/read models est tranchee ; une UI Scenes sans m
 - `ProjectManifest.storylines` existant et stable.
 - `ScenarioAsset`, `ScriptAsset`, `ScriptCondition`, `MapEventDefinition` audites comme legacy/adaptables.
 - Runtime scenario/script/cutscene audite a haut niveau.
-- Decision storage Scene V1 a venir dans V1-02.
+- Decision storage Scene V1 tranchee dans V1-02 et modele core pose dans V1-03.
 
 ## Non-objectifs globaux
```

## Auto-review critique

- Le modèle est volontairement strict sur IDs, références de graph et layout, mais il ne remplace pas un vrai système de diagnostics auteur. V1-09 devra séparer validation bloquante et warnings d’authoring.
- Les payloads draft obligatoires (`yarnDialogue`, `action`, `battle`, `cinematic`) requièrent un payload explicite. C’est sain côté core, mais l’UI devra fournir des drafts contrôlés plutôt que créer des nodes incomplets silencieux.
- `SceneActionPayload.parameters` reste une map string/string encadrée. C’est acceptable en V0, mais les actions devront devenir typées par `actionKind` avant runtime sérieux.
- Le rapport inclut les contenus source/tests créés et les diffs de fichiers modifiés ; les fichiers generated sont audités par diff et sortie build_runner.

## Regard critique sur le prompt

- Le prompt demande un modèle persistant complet mais aussi minimal. La tension principale concerne les payloads : trop typés maintenant pourrait figer le runtime, trop libres recréerait une dette metadata. La solution V0 garde les payloads petits et typés.
- La demande de contenu complet du rapport créé est récursive par nature ; le rapport documente son propre scope, les fichiers produits et les preuves de vérification sans créer une duplication infinie.
