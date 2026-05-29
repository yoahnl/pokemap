# NS-SCENES-V1-08 — Authoring Minimal Scene Draft

## Résumé exécutif

Verdict : lot implémenté comme premier palier d'authoring réel, borné à la création d'une `SceneAsset` draft minimale.

Le workspace `Scènes` expose maintenant un bouton actif `Créer une scène`. Le flow ouvre un dialog minimal, refuse un nom vide, crée une vraie scène V1, l'ajoute en mémoire dans `ProjectManifest.scenes`, sélectionne la scène créée, sélectionne `node_start`, puis réutilise le graph read-only et l'inspecteur read-only existants.

Le lot ne crée aucun authoring de node, edge, payload ou layout. Il ne branche ni runtime, ni Storylines, ni `StorylineStep.sceneLinkIds`. Aucune donnée Selbrume ou scène fake n'a été ajoutée.

Prochain lot recommandé : `NS-SCENES-V1-09 — Scene Validation Diagnostics`.

## Addendum UI proportions

Après retour visuel, le layout Scènes a été resserré pour se rapprocher de la cible Scene Builder :

- header local `Scènes` retiré pour libérer la hauteur utile ;
- bouton `Créer une scène` déplacé dans la barre de l'arborescence ;
- arborescence réduite à une colonne fixe compacte ;
- graph central agrandi pour prendre la majorité de l'espace ;
- inspecteur de node placé en rail droit fixe ;
- boutons non utiles retirés de la zone centrale.

## Design Gate / Décision UI

- Action : le bouton `Créer une scène` est actif dans la barre du panneau d'arborescence.
- Flow : dialog minimal avec `Nom de la scène`, `Description optionnelle`, `Annuler`, `Créer la scène`.
- Validation UI minimale : nom vide ou uniquement espaces refusé dans le dialog.
- Génération d'ID : opération pure `map_core`, slug ASCII stable préfixé par `scene_`, suffixe numérique en cas de collision.
- Graph minimal : `node_start`, `node_end`, `edge_start_end`.
- Layout minimal : positions persistées pour `node_start` et `node_end`.
- Mutation projet : uniquement `ProjectManifest.scenes`, via `EditorNotifier.applyInMemoryProjectManifest`.
- Sélection : scène créée sélectionnée localement, puis `node_start` sélectionné localement.
- Anti-fake : aucun fallback produit, aucune donnée Selbrume, aucune scène hardcodée métier.
- Read-only conservé : graph et inspector restent strictement read-only après création.
- Primitive UI : `PokeMapButton` pour l'action, `CupertinoAlertDialog` / `CupertinoTextField` selon les conventions Flutter existantes, couleurs via `context.pokeMapColors`.

## Scope réalisé

- Création d'une opération pure `createSceneDraftInProject` dans `map_core`.
- Export public de l'opération depuis `map_core.dart`.
- Branchement du workspace `Scènes` vers l'opération via `NarrativeWorkspaceCanvas`.
- Dialog minimal de création de scène.
- Mise à jour mémoire de `ProjectManifest.scenes`.
- Sélection automatique de la nouvelle scène et de `node_start`.
- Tests core sur création, ID, collision, nom vide, non-mutation des scénarios/storylines.
- Tests editor sur le flow UI de création, sélection, graph read-only, inspector read-only et collision.
- Visual Gate V1-08 généré.
- Roadmap mise à jour.

## Fichiers créés

- `packages/map_core/lib/src/authoring/scene_authoring_operations.dart`
- `packages/map_core/test/scene_authoring_operations_test.dart`
- `reports/narrativeStudio/scenes/ns_scenes_v1_08_authoring_minimal_scene_draft.md`
- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_08_authoring_minimal_scene_draft.png`

## Fichiers modifiés

- `packages/map_core/lib/map_core.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`
- `packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart`
- `packages/map_editor/test/scenes_workspace_shell_test.dart`
- `reports/narrativeStudio/scenes/road_map_scenes.md`

## Décisions techniques

### Opération pure map_core

La création de scène draft est portée par `map_core`, car elle modifie un modèle canonique (`ProjectManifest`) et doit être testable sans Flutter.

Signature :

```dart
SceneDraftCreationResult createSceneDraftInProject(
  ProjectManifest project, {
  required String name,
  String? description,
})
```

L'opération retourne :

- `updatedProject` : projet copié avec la scène ajoutée dans `scenes`.
- `createdScene` : scène créée, utile à l'UI pour sélectionner l'ID.

### UI editor

`ScenesWorkspace` reçoit un callback `onCreateSceneDraft`. Cela garde le widget centré sur l'UI et laisse `NarrativeWorkspaceCanvas` gérer la mutation via `EditorNotifier`.

### Mutation mémoire

La mutation passe par :

```dart
editorNotifier.applyInMemoryProjectManifest(
  result.updatedProject,
  statusMessage: 'Scene draft created',
);
```

Il n'y a pas d'écriture disque explicite, pas de repository ajouté, pas de migration.

## Stratégie d'ID

- Base : nom utilisateur trimé.
- Slug : minuscules ASCII, lettres/chiffres conservés, séparateurs convertis en `_`.
- Préfixe : `scene_`.
- Collision : suffixe numérique `_2`, `_3`, etc.
- Exemple : `Rencontre rival` devient `scene_rencontre_rival`.
- Exemple collision : si `scene_rencontre_rival` et `scene_rencontre_rival_2` existent, la prochaine scène devient `scene_rencontre_rival_3`.
- Aucun timestamp.
- Aucun UUID random.
- Aucun ID dérivé de la position visuelle.
- Aucun ID dérivé du texte Yarn.
- Aucun ID lié à Selbrume.

IDs internes V0 de la draft :

- `node_start`
- `node_end`
- `edge_start_end`

Ces IDs sont stables dans le scope de la scène créée.

## Shape de SceneAsset draft

La scène créée contient :

```text
SceneAsset
  id: scene_<slug>
  name: <nom utilisateur trimé>
  description: <description trimée ou null>
  tags: []
  declaredOutcomes: []
  graph:
    startNodeId: node_start
    nodes:
      node_start kind start title "Début"
      node_end kind end title "Fin"
    edges:
      edge_start_end
        fromNodeId: node_start
        fromPortId: completed
        toNodeId: node_end
        kind: defaultFlow
  layout:
    node_start x=24 y=80
    node_end x=320 y=80
```

La draft ne contient pas de payload métier caché, pas de metadata critique, pas de lien Storylines et pas de référence runtime.

## Mutation ProjectManifest

La mutation attendue et réalisée :

```text
ProjectManifest.scenes = [...scenes existantes, scène créée]
```

Champs non modifiés :

- `ProjectManifest.scenarios`
- `ProjectManifest.storylines`
- `scripts`
- `dialogues`
- `maps`
- état runtime
- `StorylineStep.sceneLinkIds`

Les tests vérifient explicitement que `scenarios` et `storylines` restent inchangés.

## Écarts au prompt éventuels

- Le prompt permettait une opération pure `map_core` si nécessaire ; elle a été créée pour éviter de placer une logique domaine dans `map_editor`.
- Le dialog utilise les widgets Cupertino existants, avec couleur d'erreur depuis `context.pokeMapColors`. Aucun composant design-system supplémentaire n'a été créé.
- Aucun screenshot manuel via navigateur n'a été nécessaire : le Visual Gate est produit par le test golden ciblé.

## Tests exécutés

### map_core — red ciblé initial

Commande :

```bash
cd packages/map_core && dart test test/scene_authoring_operations_test.dart
```

Résultat initial attendu avant implémentation :

```text
Failed to load "test/scene_authoring_operations_test.dart":
test/scene_authoring_operations_test.dart:10:22: Error: Method not found: 'createSceneDraftInProject'.
```

### map_core — test ciblé final

Commande :

```bash
cd packages/map_core && dart test test/scene_authoring_operations_test.dart
```

Sortie :

```text
00:00 +0: loading test/scene_authoring_operations_test.dart
00:00 +0: Scene authoring operations creates a minimal scene draft in ProjectManifest.scenes
00:00 +1: Scene authoring operations creates a minimal scene draft in ProjectManifest.scenes
00:00 +1: Scene authoring operations generates suffixed ids on collision
00:00 +2: Scene authoring operations generates suffixed ids on collision
00:00 +2: Scene authoring operations rejects an empty scene name
00:00 +3: Scene authoring operations rejects an empty scene name
00:00 +3: Scene authoring operations does not touch scenarios or storylines
00:00 +4: Scene authoring operations does not touch scenarios or storylines
00:00 +4: All tests passed!
```

### map_core — analyze

Commande :

```bash
cd packages/map_core && dart analyze
```

Sortie :

```text
Analyzing map_core...
No issues found!
```

### map_editor — tests ciblés scènes

Commande :

```bash
cd packages/map_editor && flutter test --reporter=compact test/scenes_workspace_shell_test.dart
```

Sortie :

```text
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/scenes_workspace_shell_test.dart
00:01 +0: NS-SCENES-V1-08 authoring minimal scene draft Narrative Studio exposes a real Scenes navigation entry
00:02 +1: NS-SCENES-V1-08 authoring minimal scene draft Narrative Studio exposes a real Scenes navigation entry
00:02 +1: NS-SCENES-V1-08 authoring minimal scene draft shows an honest empty state when ProjectManifest.scenes is empty
00:02 +2: NS-SCENES-V1-08 authoring minimal scene draft shows an honest empty state when ProjectManifest.scenes is empty
00:02 +2: NS-SCENES-V1-08 authoring minimal scene draft unsupported graph action stays disabled
00:02 +3: NS-SCENES-V1-08 authoring minimal scene draft unsupported graph action stays disabled
00:02 +3: NS-SCENES-V1-08 authoring minimal scene draft creates a minimal scene draft from the Scenes workspace
00:02 +4: NS-SCENES-V1-08 authoring minimal scene draft creates a minimal scene draft from the Scenes workspace
00:02 +4: NS-SCENES-V1-08 authoring minimal scene draft create scene draft handles id collisions
00:03 +5: NS-SCENES-V1-08 authoring minimal scene draft create scene draft handles id collisions
00:03 +5: NS-SCENES-V1-08 authoring minimal scene draft shows real SceneAsset data in the read-only tree and summary
00:03 +6: NS-SCENES-V1-08 authoring minimal scene draft shows real SceneAsset data in the read-only tree and summary
00:03 +6: NS-SCENES-V1-08 authoring minimal scene draft selects real graph nodes and shows read-only inspector
00:03 +7: NS-SCENES-V1-08 authoring minimal scene draft selects real graph nodes and shows read-only inspector
00:03 +7: NS-SCENES-V1-08 authoring minimal scene draft shows battle payload summary in read-only inspector
00:03 +8: NS-SCENES-V1-08 authoring minimal scene draft shows battle payload summary in read-only inspector
00:03 +8: NS-SCENES-V1-08 authoring minimal scene draft scene change recalculates local selected node
00:03 +9: NS-SCENES-V1-08 authoring minimal scene draft scene change recalculates local selected node
00:03 +9: NS-SCENES-V1-08 authoring minimal scene draft uses a derived layout for scenes with incomplete layout
00:03 +10: NS-SCENES-V1-08 authoring minimal scene draft uses a derived layout for scenes with incomplete layout
00:03 +10: NS-SCENES-V1-08 authoring minimal scene draft uses bounded derived layout for cyclic and disconnected graph
00:03 +11: NS-SCENES-V1-08 authoring minimal scene draft uses bounded derived layout for cyclic and disconnected graph
00:03 +11: NS-SCENES-V1-08 authoring minimal scene draft local scene selection updates summary without mutating project
00:03 +12: NS-SCENES-V1-08 authoring minimal scene draft local scene selection updates summary without mutating project
00:03 +12: NS-SCENES-V1-08 authoring minimal scene draft Storylines workspace remains selectable
00:03 +13: NS-SCENES-V1-08 authoring minimal scene draft Storylines workspace remains selectable
00:03 +13: NS-SCENES-V1-08 authoring minimal scene draft writes V1-08 visual gate screenshot
00:04 +14: NS-SCENES-V1-08 authoring minimal scene draft writes V1-08 visual gate screenshot
00:04 +14: All tests passed!
```

### map_editor — regressions navigation/header/projection

Commande :

```bash
cd packages/map_editor && flutter test --reporter=compact test/ui/canvas/narrative_overview_shell_navigation_test.dart
```

Sortie :

```text
00:05 +19: All tests passed!
```

Commande :

```bash
cd packages/map_editor && flutter test --reporter=compact test/ui/canvas/narrative_studio_header_test.dart
```

Sortie :

```text
00:02 +3: All tests passed!
```

Commande :

```bash
cd packages/map_editor && flutter test --reporter=compact test/narrative_workspace_projection_test.dart
```

Sortie :

```text
00:01 +3: All tests passed!
```

### map_editor — analyze ciblé

Commande :

```bash
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/scenes_workspace.dart lib/src/ui/canvas/scenes/scene_graph_read_only_view.dart lib/src/ui/canvas/scenes/scene_node_read_only_inspector.dart lib/src/ui/canvas/narrative_workspace_canvas.dart lib/src/features/narrative/application/narrative_workspace_projection.dart test/scenes_workspace_shell_test.dart test/ui/canvas/narrative_overview_shell_navigation_test.dart test/ui/canvas/narrative_studio_header_test.dart test/narrative_workspace_projection_test.dart
```

Sortie :

```text
Analyzing 9 items...
No issues found! (ran in 1.7s)
```

## Visual Gate

Screenshot généré :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_08_authoring_minimal_scene_draft.png
```

Commande :

```bash
cd packages/map_editor && flutter test --update-goldens --reporter=compact test/scenes_workspace_shell_test.dart --plain-name 'writes V1-08 visual gate screenshot'
```

Sortie :

```text
00:02 +1: All tests passed!
```

Taille du fichier :

```text
-rw-r--r--  1 karim  staff  46426 May 29 21:16 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_08_authoring_minimal_scene_draft.png
```

Ce qui est visible : workspace `Scènes`, arborescence contenant la scène créée par le flow de test, graph start/end read-only, inspecteur read-only du start node, bouton `Créer une scène`, aucune édition de node/edge, aucun runtime.

Preuve anti-fake : la scène du screenshot est créée par le test via le dialog avec le nom neutre `New Draft Scene`. Elle n'est pas présente dans le code produit.

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
c1bf1c76 feat(scenes): add read-only node inspector and update workspace tests
e3b346c7 feat(scenes): harden graph read-only fallback layout and update tests
d97be401 chore: auto-commit changes
7fcd3c87 chore: auto-commit changes
6bbff623 scènes workspace shell UI
3253c8d5 chore: auto-commit changes
e75b3876 chore: auto-commit changes
00bcaa4d chore: auto-commit changes
a85fc3c4 docs(scenes): add scene system audit and roadmap v1.0.0
af6c491b feat(storylines): update structure layout and tests v1.1.1
```

## Git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie :

```text
 M packages/map_core/lib/map_core.dart
 M packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
 M packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart
 M packages/map_editor/test/scenes_workspace_shell_test.dart
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? packages/map_core/lib/src/authoring/scene_authoring_operations.dart
?? packages/map_core/test/scene_authoring_operations_test.dart
?? reports/narrativeStudio/scenes/ns_scenes_v1_08_authoring_minimal_scene_draft.md
?? reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_08_authoring_minimal_scene_draft.png
```

## Git diff --stat final

Commande :

```bash
git diff --stat
```

Sortie :

```text
 packages/map_core/lib/map_core.dart                |   1 +
 .../src/ui/canvas/narrative_workspace_canvas.dart  |  19 +++
 .../lib/src/ui/canvas/scenes_workspace.dart        | 150 ++++++++++++++++++-
 .../test/scenes_workspace_shell_test.dart          | 160 +++++++++++++++++++--
 reports/narrativeStudio/scenes/road_map_scenes.md  |  25 +++-
 5 files changed, 334 insertions(+), 21 deletions(-)
```

## Git diff --name-only final

Commande :

```bash
git diff --name-only
```

Sortie :

```text
packages/map_core/lib/map_core.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart
packages/map_editor/test/scenes_workspace_shell_test.dart
reports/narrativeStudio/scenes/road_map_scenes.md
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
cd packages/map_core && dart test test/scene_authoring_operations_test.dart
cd packages/map_core && dart analyze
cd packages/map_editor && flutter test --reporter=compact test/scenes_workspace_shell_test.dart --plain-name 'creates a minimal scene draft from the Scenes workspace'
cd packages/map_editor && flutter test --reporter=compact test/scenes_workspace_shell_test.dart --plain-name 'create scene draft handles id collisions'
cd packages/map_editor && flutter test --update-goldens --reporter=compact test/scenes_workspace_shell_test.dart --plain-name 'writes V1-08 visual gate screenshot'
cd packages/map_editor && flutter test --reporter=compact test/scenes_workspace_shell_test.dart
cd packages/map_editor && flutter test --reporter=compact test/ui/canvas/narrative_overview_shell_navigation_test.dart
cd packages/map_editor && flutter test --reporter=compact test/ui/canvas/narrative_studio_header_test.dart
cd packages/map_editor && flutter test --reporter=compact test/narrative_workspace_projection_test.dart
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/scenes_workspace.dart lib/src/ui/canvas/scenes/scene_graph_read_only_view.dart lib/src/ui/canvas/scenes/scene_node_read_only_inspector.dart lib/src/ui/canvas/narrative_workspace_canvas.dart lib/src/features/narrative/application/narrative_workspace_projection.dart test/scenes_workspace_shell_test.dart test/ui/canvas/narrative_overview_shell_navigation_test.dart test/ui/canvas/narrative_studio_header_test.dart test/narrative_workspace_projection_test.dart
rg "Color\(0x|Colors\." packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart packages/map_editor/lib/src/ui/canvas/scenes packages/map_editor/test/scenes_workspace_shell_test.dart packages/map_core/lib/src/authoring/scene_authoring_operations.dart packages/map_core/test/scene_authoring_operations_test.dart
rg "fakeScenes|demoScenes|hardcodedSceneList|Annonce au port|Selbrume Demo|Maël|Lysa|Port des Brisants|La brume du phare|Le Goélise" packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart packages/map_editor/lib/src/ui/canvas/scenes packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart packages/map_core/lib/src/authoring/scene_authoring_operations.dart
git diff --check
```

### Vérification anti-couleurs hardcodées

Commande :

```bash
rg "Color\(0x|Colors\." packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart packages/map_editor/lib/src/ui/canvas/scenes packages/map_editor/test/scenes_workspace_shell_test.dart packages/map_core/lib/src/authoring/scene_authoring_operations.dart packages/map_core/test/scene_authoring_operations_test.dart
```

Sortie :

```text
Sortie : <vide>
```

### Vérification anti-fake / anti-Selbrume produit

Commande :

```bash
rg "fakeScenes|demoScenes|hardcodedSceneList|Annonce au port|Selbrume Demo|Maël|Lysa|Port des Brisants|La brume du phare|Le Goélise" packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart packages/map_editor/lib/src/ui/canvas/scenes packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart packages/map_core/lib/src/authoring/scene_authoring_operations.dart
```

Sortie :

```text
Sortie : <vide>
```

## Contenu complet des fichiers créés

### packages/map_core/lib/src/authoring/scene_authoring_operations.dart

```dart
import '../models/project_manifest.dart';
import '../models/scene_asset.dart';

final class SceneDraftCreationResult {
  const SceneDraftCreationResult({
    required this.updatedProject,
    required this.createdScene,
  });

  final ProjectManifest updatedProject;
  final SceneAsset createdScene;
}

SceneDraftCreationResult createSceneDraftInProject(
  ProjectManifest project, {
  required String name,
  String? description,
}) {
  final trimmedName = name.trim();
  if (trimmedName.isEmpty) {
    throw ArgumentError.value(name, 'name', 'Scene name is required.');
  }

  final scene = _createSceneDraft(
    id: _uniqueSceneId(trimmedName, project.scenes.map((scene) => scene.id)),
    name: trimmedName,
    description: _trimOptional(description),
  );
  return SceneDraftCreationResult(
    updatedProject: project.copyWith(
      scenes: [...project.scenes, scene],
    ),
    createdScene: scene,
  );
}

SceneAsset _createSceneDraft({
  required String id,
  required String name,
  String? description,
}) {
  return SceneAsset(
    id: id,
    name: name,
    description: description,
    graph: SceneGraph(
      startNodeId: 'node_start',
      nodes: [
        SceneNode(
          id: 'node_start',
          kind: SceneNodeKind.start,
          title: 'Début',
        ),
        SceneNode(
          id: 'node_end',
          kind: SceneNodeKind.end,
          title: 'Fin',
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
    layout: SceneGraphLayout(
      nodeLayouts: [
        SceneNodeLayout(nodeId: 'node_start', x: 24, y: 80),
        SceneNodeLayout(nodeId: 'node_end', x: 320, y: 80),
      ],
    ),
  );
}

String _uniqueSceneId(String name, Iterable<String> existingIds) {
  final existing = existingIds.toSet();
  final base = 'scene_${_slugify(name)}';
  if (!existing.contains(base)) {
    return base;
  }
  var suffix = 2;
  while (existing.contains('${base}_$suffix')) {
    suffix++;
  }
  return '${base}_$suffix';
}

String _slugify(String value) {
  final lower = value.trim().toLowerCase();
  final buffer = StringBuffer();
  var wroteSeparator = false;

  for (final codeUnit in lower.codeUnits) {
    final isDigit = codeUnit >= 48 && codeUnit <= 57;
    final isAsciiLetter = codeUnit >= 97 && codeUnit <= 122;
    if (isDigit || isAsciiLetter) {
      buffer.writeCharCode(codeUnit);
      wroteSeparator = false;
    } else if (!wroteSeparator && buffer.isNotEmpty) {
      buffer.write('_');
      wroteSeparator = true;
    }
  }

  final slug = buffer.toString();
  return slug.endsWith('_') ? slug.substring(0, slug.length - 1) : slug;
}

String? _trimOptional(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}
```

### packages/map_core/test/scene_authoring_operations_test.dart

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Scene authoring operations', () {
    test('creates a minimal scene draft in ProjectManifest.scenes', () {
      final project = _project();

      final result = createSceneDraftInProject(
        project,
        name: ' Rencontre rival ',
        description: ' Premier brouillon ',
      );

      expect(project.scenes, isEmpty);
      expect(result.updatedProject.scenes, hasLength(1));
      expect(result.createdScene.id, 'scene_rencontre_rival');
      expect(result.createdScene.name, 'Rencontre rival');
      expect(result.createdScene.description, 'Premier brouillon');
      expect(result.createdScene.tags, isEmpty);
      expect(result.createdScene.declaredOutcomes, isEmpty);
      expect(result.createdScene.graph.startNodeId, 'node_start');
      expect(result.createdScene.graph.nodes.map((node) => node.id), [
        'node_start',
        'node_end',
      ]);
      expect(result.createdScene.graph.edges.single.id, 'edge_start_end');
      expect(result.createdScene.graph.edges.single.fromPortId, 'completed');
      expect(
        result.createdScene.graph.edges.single.kind,
        SceneEdgeKind.defaultFlow,
      );
      expect(
          result.createdScene.layout.nodeLayouts.map((node) => node.nodeId), [
        'node_start',
        'node_end',
      ]);
    });

    test('generates suffixed ids on collision', () {
      final project = _project(
        scenes: [
          _scene('scene_rencontre_rival'),
          _scene('scene_rencontre_rival_2'),
        ],
      );

      final result = createSceneDraftInProject(
        project,
        name: 'Rencontre rival',
      );

      expect(result.createdScene.id, 'scene_rencontre_rival_3');
      expect(result.updatedProject.scenes, hasLength(3));
    });

    test('rejects an empty scene name', () {
      expect(
        () => createSceneDraftInProject(_project(), name: '   '),
        throwsArgumentError,
      );
    });

    test('does not touch scenarios or storylines', () {
      final scenario = ScenarioAsset(
        id: 'scenario_existing',
        name: 'Existing scenario',
        scope: ScenarioScope.localEventFlow,
        entryNodeId: 'scenario_node_start',
        nodes: [
          ScenarioNode(
            id: 'scenario_node_start',
            type: ScenarioNodeType.start,
            title: 'Start',
          ),
        ],
      );
      final storyline = StorylineAsset(
        id: 'storyline_existing',
        title: 'Existing storyline',
        type: StorylineType.main,
      );
      final project = _project(
        scenarios: [scenario],
        storylines: [storyline],
      );

      final result = createSceneDraftInProject(project, name: 'Scene');

      expect(result.updatedProject.scenarios, project.scenarios);
      expect(result.updatedProject.storylines, project.storylines);
      expect(result.updatedProject.scenes, hasLength(1));
    });
  });
}

ProjectManifest _project({
  List<SceneAsset> scenes = const [],
  List<ScenarioAsset> scenarios = const [],
  List<StorylineAsset> storylines = const [],
}) {
  return ProjectManifest(
    name: 'Scene authoring test',
    maps: const [],
    tilesets: const [],
    scenes: scenes,
    scenarios: scenarios,
    storylines: storylines,
  );
}

SceneAsset _scene(String id) {
  return SceneAsset(
    id: id,
    name: id,
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
```

### reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_08_authoring_minimal_scene_draft.png

```text
PNG binaire généré par test golden.
Chemin : reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_08_authoring_minimal_scene_draft.png
Taille : 46426 octets
```

### reports/narrativeStudio/scenes/ns_scenes_v1_08_authoring_minimal_scene_draft.md

```text
Ce fichier est le rapport courant NS-SCENES-V1-08.
```

## Sections modifiées complètes / diff des fichiers modifiés

### Diff complet tracked

```diff
diff --git a/packages/map_core/lib/map_core.dart b/packages/map_core/lib/map_core.dart
index 7f0d18d8..bd75a812 100644
--- a/packages/map_core/lib/map_core.dart
+++ b/packages/map_core/lib/map_core.dart
@@ -77,6 +77,7 @@ export 'src/authoring/narrative_event_source_authoring_operations.dart';
 export 'src/authoring/narrative_outcome_authoring_operations.dart';
 export 'src/authoring/narrative_predicate_authoring_draft.dart';
 export 'src/authoring/narrative_scenario_authoring_draft.dart';
+export 'src/authoring/scene_authoring_operations.dart';
 export 'src/authoring/narrative_validator_authoring_adapter.dart';
 export 'src/authoring/storyline_legacy_import_preview.dart';
 export 'src/read_models/narrative_reference_picker_read_models.dart';
diff --git a/packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart b/packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
index 845676fe..5d6801e8 100644
--- a/packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
+++ b/packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
@@ -122,6 +122,25 @@ class NarrativeWorkspaceCanvas extends ConsumerWidget {
         ),
       EditorWorkspaceMode.scenes => ScenesWorkspace(
           scenes: projection.scenes,
+          onCreateSceneDraft: ({
+            required String name,
+            String? description,
+          }) async {
+            final project = editor.project;
+            if (project == null) {
+              return null;
+            }
+            final result = createSceneDraftInProject(
+              project,
+              name: name,
+              description: description,
+            );
+            editorNotifier.applyInMemoryProjectManifest(
+              result.updatedProject,
+              statusMessage: 'Scene draft created',
+            );
+            return result.createdScene.id;
+          },
         ),
       EditorWorkspaceMode.step => _StepWorkspaceBody(
           projection: projection,
diff --git a/packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart b/packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart
index 9cd67dce..c996b039 100644
--- a/packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart
+++ b/packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart
@@ -6,13 +6,20 @@ import '../design_system/design_system.dart';
 import 'scenes/scene_graph_read_only_view.dart';
 import 'scenes/scene_node_read_only_inspector.dart';
 
+typedef SceneDraftCreator = Future<String?> Function({
+  required String name,
+  String? description,
+});
+
 class ScenesWorkspace extends StatefulWidget {
   const ScenesWorkspace({
     super.key,
     required this.scenes,
+    required this.onCreateSceneDraft,
   });
 
   final List<NarrativeSceneSummary> scenes;
+  final SceneDraftCreator onCreateSceneDraft;
 
   @override
   State<ScenesWorkspace> createState() => _ScenesWorkspaceState();
@@ -79,6 +86,7 @@ class _ScenesWorkspaceState extends State<ScenesWorkspace> {
             sceneCount: widget.scenes.length,
             totalNodes: totalNodes,
             totalOutcomes: totalOutcomes,
+            onCreateSceneDraft: _createSceneDraft,
           ),
           const SizedBox(height: 10),
           Expanded(
@@ -116,6 +124,28 @@ class _ScenesWorkspaceState extends State<ScenesWorkspace> {
     );
   }
 
+  Future<void> _createSceneDraft() async {
+    final draft = await showCupertinoDialog<_SceneDraftDialogResult>(
+      context: context,
+      builder: (context) => const _CreateSceneDraftDialog(),
+    );
+    if (draft == null) {
+      return;
+    }
+
+    final createdSceneId = await widget.onCreateSceneDraft(
+      name: draft.name,
+      description: draft.description,
+    );
+    if (!mounted || createdSceneId == null) {
+      return;
+    }
+    setState(() {
+      _selectedSceneId = createdSceneId;
+      _selectedNodeId = 'node_start';
+    });
+  }
+
   NarrativeSceneSummary? get _selectedScene {
     for (final scene in widget.scenes) {
       if (scene.id == _selectedSceneId) {
@@ -151,11 +181,13 @@ class _ScenesHeader extends StatelessWidget {
     required this.sceneCount,
     required this.totalNodes,
     required this.totalOutcomes,
+    required this.onCreateSceneDraft,
   });
 
   final int sceneCount;
   final int totalNodes;
   final int totalOutcomes;
+  final VoidCallback onCreateSceneDraft;
 
   @override
   Widget build(BuildContext context) {
@@ -192,8 +224,8 @@ class _ScenesHeader extends StatelessWidget {
                 ),
                 const SizedBox(height: 3),
                 Text(
-                  'Arborescence read-only depuis ProjectManifest.scenes. '
-                  'Le graph arrive au lot suivant.',
+                  'Créez une scène draft minimale, puis inspectez son graph '
+                  'read-only depuis ProjectManifest.scenes.',
                   maxLines: 1,
                   overflow: TextOverflow.ellipsis,
                   style: TextStyle(
@@ -225,13 +257,13 @@ class _ScenesHeader extends StatelessWidget {
             ],
           ),
           const SizedBox(width: 12),
-          const PokeMapButton(
-            key: ValueKey('scenes-create-scene-disabled'),
-            onPressed: null,
+          PokeMapButton(
+            key: const ValueKey('scenes-create-scene-action'),
+            onPressed: onCreateSceneDraft,
             variant: PokeMapButtonVariant.primary,
             size: PokeMapButtonSize.small,
-            leading: Icon(CupertinoIcons.plus),
-            child: Text('Créer — bientôt'),
+            leading: const Icon(CupertinoIcons.plus),
+            child: const Text('Créer une scène'),
           ),
         ],
       ),
@@ -239,6 +271,110 @@ class _ScenesHeader extends StatelessWidget {
   }
 }
 
+class _SceneDraftDialogResult {
+  const _SceneDraftDialogResult({
+    required this.name,
+    this.description,
+  });
+
+  final String name;
+  final String? description;
+}
+
+class _CreateSceneDraftDialog extends StatefulWidget {
+  const _CreateSceneDraftDialog();
+
+  @override
+  State<_CreateSceneDraftDialog> createState() =>
+      _CreateSceneDraftDialogState();
+}
+
+class _CreateSceneDraftDialogState extends State<_CreateSceneDraftDialog> {
+  final TextEditingController _nameController = TextEditingController();
+  final TextEditingController _descriptionController = TextEditingController();
+  bool _showNameError = false;
+
+  @override
+  void dispose() {
+    _nameController.dispose();
+    _descriptionController.dispose();
+    super.dispose();
+  }
+
+  @override
+  Widget build(BuildContext context) {
+    final colors = context.pokeMapColors;
+    return CupertinoAlertDialog(
+      key: const ValueKey('scenes-create-scene-dialog'),
+      title: const Text('Créer une scène'),
+      content: Padding(
+        padding: const EdgeInsets.only(top: 12),
+        child: Column(
+          children: [
+            CupertinoTextField(
+              key: const ValueKey('scenes-create-scene-name-field'),
+              controller: _nameController,
+              placeholder: 'Nom de la scène',
+              onChanged: (_) {
+                if (_showNameError) {
+                  setState(() => _showNameError = false);
+                }
+              },
+            ),
+            const SizedBox(height: 8),
+            CupertinoTextField(
+              key: const ValueKey('scenes-create-scene-description-field'),
+              controller: _descriptionController,
+              placeholder: 'Description optionnelle',
+              minLines: 2,
+              maxLines: 3,
+            ),
+            if (_showNameError) ...[
+              const SizedBox(height: 8),
+              Text(
+                'Nom requis.',
+                key: const ValueKey('scenes-create-scene-name-error'),
+                style: TextStyle(
+                  color: colors.error,
+                  fontSize: 12,
+                  fontWeight: FontWeight.w700,
+                ),
+              ),
+            ],
+          ],
+        ),
+      ),
+      actions: [
+        CupertinoDialogAction(
+          key: const ValueKey('scenes-create-scene-cancel'),
+          child: const Text('Annuler'),
+          onPressed: () => Navigator.of(context).pop(),
+        ),
+        CupertinoDialogAction(
+          key: const ValueKey('scenes-create-scene-submit'),
+          isDefaultAction: true,
+          child: const Text('Créer la scène'),
+          onPressed: () {
+            final name = _nameController.text.trim();
+            if (name.isEmpty) {
+              setState(() => _showNameError = true);
+              return;
+            }
+            Navigator.of(context).pop(
+              _SceneDraftDialogResult(
+                name: name,
+                description: _descriptionController.text.trim().isEmpty
+                    ? null
+                    : _descriptionController.text.trim(),
+              ),
+            );
+          },
+        ),
+      ],
+    );
+  }
+}
+
 class _SceneTreePanel extends StatelessWidget {
   const _SceneTreePanel({
     required this.scenes,
```

```diff
diff --git a/packages/map_editor/test/scenes_workspace_shell_test.dart b/packages/map_editor/test/scenes_workspace_shell_test.dart
index 74a3b994..b82c3c3b 100644
--- a/packages/map_editor/test/scenes_workspace_shell_test.dart
+++ b/packages/map_editor/test/scenes_workspace_shell_test.dart
@@ -9,7 +9,7 @@ import 'package:map_editor/src/ui/canvas/narrative_workspace_canvas.dart';
 import 'package:map_editor/src/ui/design_system/design_system.dart';
 
 void main() {
-  group('NS-SCENES-V1-07 node inspector read-only', () {
+  group('NS-SCENES-V1-08 authoring minimal scene draft', () {
     testWidgets('Narrative Studio exposes a real Scenes navigation entry',
         (tester) async {
       final container = await _pumpNarrativeShell(
@@ -64,8 +64,7 @@ void main() {
       expect(find.byKey(const ValueKey('scenes-list-compact')), findsNothing);
     });
 
-    testWidgets('disabled actions do not mutate ProjectManifest',
-        (tester) async {
+    testWidgets('unsupported graph action stays disabled', (tester) async {
       final project = _projectWithScene();
       final container = await _pumpNarrativeShell(
         tester,
@@ -73,9 +72,6 @@ void main() {
         workspaceMode: EditorWorkspaceMode.scenes,
       );
 
-      final createButton = tester.widget<PokeMapButton>(
-        find.byKey(const ValueKey('scenes-create-scene-disabled')).first,
-      );
       final builderButton = tester.widget<PokeMapButton>(
         find
             .byKey(
@@ -86,11 +82,123 @@ void main() {
             .first,
       );
 
-      expect(createButton.onPressed, isNull);
       expect(builderButton.onPressed, isNull);
       expect(container.read(editorNotifierProvider).project, equals(project));
     });
 
+    testWidgets('creates a minimal scene draft from the Scenes workspace',
+        (tester) async {
+      final project = _emptyProject();
+      final container = await _pumpNarrativeShell(
+        tester,
+        project: project,
+        workspaceMode: EditorWorkspaceMode.scenes,
+      );
+
+      final createButton = tester.widget<PokeMapButton>(
+        find.byKey(const ValueKey('scenes-create-scene-action')).first,
+      );
+      expect(createButton.onPressed, isNotNull);
+
+      await tester
+          .tap(find.byKey(const ValueKey('scenes-create-scene-action')));
+      await tester.pumpAndSettle();
+      expect(
+        find.byKey(const ValueKey('scenes-create-scene-dialog')),
+        findsOneWidget,
+      );
+
+      await tester
+          .tap(find.byKey(const ValueKey('scenes-create-scene-submit')));
+      await tester.pumpAndSettle();
+      expect(
+        find.byKey(const ValueKey('scenes-create-scene-name-error')),
+        findsOneWidget,
+      );
+      expect(container.read(editorNotifierProvider).project, equals(project));
+
+      await tester.enterText(
+        find.byKey(const ValueKey('scenes-create-scene-name-field')),
+        'New Draft Scene',
+      );
+      await tester.enterText(
+        find.byKey(const ValueKey('scenes-create-scene-description-field')),
+        'Created from the test flow.',
+      );
+      await tester
+          .tap(find.byKey(const ValueKey('scenes-create-scene-submit')));
+      await tester.pumpAndSettle();
+
+      final updated = container.read(editorNotifierProvider).project!;
+      expect(updated.scenes, hasLength(1));
+      expect(updated.scenes.single.id, 'scene_new_draft_scene');
+      expect(updated.scenes.single.name, 'New Draft Scene');
+      expect(updated.scenes.single.description, 'Created from the test flow.');
+      expect(updated.scenarios, equals(project.scenarios));
+      expect(updated.storylines, equals(project.storylines));
+      expect(
+        find.byKey(const ValueKey('scenes-tree-item-scene_new_draft_scene')),
+        findsOneWidget,
+      );
+      expect(
+        find.byKey(
+          const ValueKey('scenes-selected-summary-scene_new_draft_scene'),
+        ),
+        findsOneWidget,
+      );
+      expect(
+        find.byKey(const ValueKey('scene-graph-node-node_start')),
+        findsOneWidget,
+      );
+      expect(
+        find.byKey(const ValueKey('scene-graph-node-node_end')),
+        findsOneWidget,
+      );
+      expect(
+        find.byKey(const ValueKey('scene-graph-node-selected-node_start')),
+        findsOneWidget,
+      );
+      expect(find.text('Détails du nœud'), findsOneWidget);
+      expect(find.text('node_start'), findsWidgets);
+    });
+
+    testWidgets('create scene draft handles id collisions', (tester) async {
+      final project = ProjectManifest(
+        name: 'Scenes shell test',
+        maps: const [],
+        tilesets: const [],
+        scenes: [
+          _sceneWithId('scene_new_draft_scene'),
+        ],
+      );
+      final container = await _pumpNarrativeShell(
+        tester,
+        project: project,
+        workspaceMode: EditorWorkspaceMode.scenes,
+      );
+
+      await tester
+          .tap(find.byKey(const ValueKey('scenes-create-scene-action')));
+      await tester.pumpAndSettle();
+      await tester.enterText(
+        find.byKey(const ValueKey('scenes-create-scene-name-field')),
+        'New Draft Scene',
+      );
+      await tester
+          .tap(find.byKey(const ValueKey('scenes-create-scene-submit')));
+      await tester.pumpAndSettle();
+
+      final updated = container.read(editorNotifierProvider).project!;
+      expect(updated.scenes.map((scene) => scene.id), [
+        'scene_new_draft_scene',
+        'scene_new_draft_scene_2',
+      ]);
+      expect(
+        find.byKey(const ValueKey('scenes-tree-item-scene_new_draft_scene_2')),
+        findsOneWidget,
+      );
+    });
+
     testWidgets('shows real SceneAsset data in the read-only tree and summary',
         (tester) async {
       await _pumpNarrativeShell(
@@ -368,22 +476,29 @@ void main() {
       );
     });
 
-    testWidgets('writes V1-07 visual gate screenshot', (tester) async {
+    testWidgets('writes V1-08 visual gate screenshot', (tester) async {
       await _pumpNarrativeShell(
         tester,
-        project: _projectWithTwoScenes(),
+        project: _emptyProject(),
         workspaceMode: EditorWorkspaceMode.scenes,
       );
 
       await tester
-          .tap(find.byKey(const ValueKey('scene-graph-node-node_yarn')));
+          .tap(find.byKey(const ValueKey('scenes-create-scene-action')));
+      await tester.pumpAndSettle();
+      await tester.enterText(
+        find.byKey(const ValueKey('scenes-create-scene-name-field')),
+        'New Draft Scene',
+      );
+      await tester
+          .tap(find.byKey(const ValueKey('scenes-create-scene-submit')));
       await tester.pumpAndSettle();
 
       await expectLater(
         find.byKey(const ValueKey('scenes-workspace-shell')),
         matchesGoldenFile(
           '../../../reports/narrativeStudio/scenes/screenshots/'
-          'ns_scenes_v1_07_node_inspector_read_only.png',
+          'ns_scenes_v1_08_authoring_minimal_scene_draft.png',
         ),
       );
     });
@@ -567,6 +682,29 @@ SceneAsset _testIntroScene() {
   );
 }
 
+SceneAsset _sceneWithId(String id) {
+  return SceneAsset(
+    id: id,
+    name: 'Existing scene',
+    graph: SceneGraph(
+      startNodeId: 'node_start',
+      nodes: [
+        SceneNode(id: 'node_start', kind: SceneNodeKind.start),
+        SceneNode(id: 'node_end', kind: SceneNodeKind.end),
+      ],
+      edges: [
+        SceneEdge(
+          id: 'edge_start_end',
+          fromNodeId: 'node_start',
+          fromPortId: 'completed',
+          toNodeId: 'node_end',
+          kind: SceneEdgeKind.defaultFlow,
+        ),
+      ],
+    ),
+  );
+}
+
 SceneAsset _testComplexFallbackScene() {
   return SceneAsset(
     id: 'scene_test_complex_fallback',
diff --git a/reports/narrativeStudio/scenes/road_map_scenes.md b/reports/narrativeStudio/scenes/road_map_scenes.md
index 57ba3df0..24b841c5 100644
--- a/reports/narrativeStudio/scenes/road_map_scenes.md
+++ b/reports/narrativeStudio/scenes/road_map_scenes.md
@@ -44,16 +44,35 @@ Ces briques sont utiles, mais elles ne constituent pas encore une Scene V1 propr
 | NS-SCENES-V1-05 — Scene Tree Panel Read-only | DONE | Arborescence read-only des scenes reelles, selection locale, resume central, header Scenes compacte, aucun graph ni mutation. |
 | NS-SCENES-V1-06 — Graph Read-only Skeleton | DONE | Graph Scene V1 read-only depuis le `SceneAsset` selectionne : nodes, edges, labels, layout persiste ou layout derive non persiste. |
 | NS-SCENES-V1-07 — Node Inspector Read-only | DONE | Selection locale de node dans le graph read-only, inspecteur read-only du payload et des edges entrants/sortants, sans authoring ni mutation. |
-| NS-SCENES-V1-08 — Authoring Minimal Scene Draft | TODO | Creer/editer une scene draft minimale, sans brancher Storylines ni runtime complet. |
+| NS-SCENES-V1-08 — Authoring Minimal Scene Draft | DONE | Creation d'une SceneAsset draft minimale depuis le workspace Scenes, ajout en memoire dans `ProjectManifest.scenes`, selection auto et graph/inspector read-only. |
 | NS-SCENES-V1-09 — Scene Validation Diagnostics | TODO | Diagnostics de graphe : start/end, edges invalides, nodes incomplets, refs manquantes, outcomes orphelins. |
 | NS-SCENES-V1-10 — Runtime Execution Prep | TODO | Adapter ou wrapper les briques runtime existantes pour preparer l'execution Scene V1. |
 | NS-SCENES-V1-11 — StorylineStep to Scene Link | TODO | Brancher `StorylineStep.sceneLinkIds` seulement apres stabilisation du modele Scene V1. |
 
 ## Prochain lot recommande
 
-`NS-SCENES-V1-08 — Authoring Minimal Scene Draft`
+`NS-SCENES-V1-09 — Scene Validation Diagnostics`
 
-Raison : le workspace Scenes affiche maintenant un graph read-only reel et un inspecteur read-only du node selectionne. Le prochain lot peut introduire un authoring minimal de Scene draft, sans runtime ni branchement Storylines.
+Raison : le workspace Scenes peut maintenant creer une scene draft minimale. Avant d'elargir l'authoring de nodes/edges, il faut poser les diagnostics Scene V1 pour encadrer start/end, refs, edges, ports et outcomes.
+
+## Decisions V1-08
+
+- Le bouton `Créer une scène` ouvre un dialog minimal nom + description optionnelle.
+- Le nom vide est refuse dans le dialog.
+- La creation passe par `createSceneDraftInProject`, operation pure `map_core`.
+- Les ids de scene sont slugifies avec prefixe `scene_` et suffixe numerique en cas de collision.
+- La scene draft contient uniquement `node_start`, `node_end`, `edge_start_end`, layout start/end et aucune metadata metier.
+- La mutation touche uniquement `ProjectManifest.scenes` en memoire via `EditorNotifier.applyInMemoryProjectManifest`.
+- La scene creee est selectionnee, puis `node_start` est selectionne dans l'inspecteur read-only.
+- Aucun authoring de node, edge, payload, layout, runtime ou Storylines n'est ajoute.
+
+## Limites V1-08
+
+- Pas d'edition de scene existante.
+- Pas d'ajout ou edition de node/edge.
+- Pas de drag and drop layout.
+- Pas de persistence disque explicite.
+- Pas de diagnostics Scene V1 avant V1-09.
 
 ## Decisions V1-07
```

## Auto-review critique

- Le lot respecte le périmètre : création draft minimale seulement.
- La logique d'ID est volontairement simple et testée, mais elle reste ASCII-only ; cela évite les surprises pour V0, mais une stratégie Unicode/locale pourra être réévaluée plus tard.
- `node_start`, `node_end` et `edge_start_end` sont stables dans une scène simple ; si V1-09 ajoute des diagnostics plus stricts, il faudra confirmer la convention de ports attendus.
- Le dialog est minimal et ne prétend pas être un éditeur de scène complet.
- Le flow est mémoire seulement ; aucun mécanisme disque n'a été ajouté.
- Le Visual Gate repose sur une scène neutre créée par test, ce qui est conforme au scope mais ne remplace pas un smoke manuel complet dans l'app.

## Regard critique sur le prompt

Le prompt était précis et utile. Le seul point potentiellement ambigu était la localisation de l'opération pure : il disait "si une opération pure est créée", tout en listant `map_core` comme zone probable. Le choix `map_core` est le plus propre pour éviter de disperser une règle de mutation canonique dans l'UI. Le prompt demande aussi un Evidence Pack très complet ; pour les fichiers PNG binaires, la preuve exploitable reste le chemin, la taille et la commande de génération.

## Non-objectifs confirmés

- Pas d'édition de scène existante.
- Pas de suppression ou duplication.
- Pas d'import `ScenarioAsset`.
- Pas de migration legacy.
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
