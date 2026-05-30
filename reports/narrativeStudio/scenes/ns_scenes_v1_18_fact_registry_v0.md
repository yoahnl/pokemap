# NS-SCENES-V1-18 — Fact Registry V0

## Résumé exécutif

Le lot `NS-SCENES-V1-18 — Fact Registry V0` est réalisé.

Il ajoute une première registry authoring de Facts lisibles, bool-first, stockée dans `ProjectManifest.facts`. Les Facts deviennent sélectionnables dans le picker de condition du Scene Builder via une source explicite `SceneConditionSourceKind.fact`, tandis que `factLikeStoryFlag` reste disponible comme fallback technique.

Le lot ne branche aucun runtime, ne crée aucune World Rule, ne migre pas automatiquement les story flags existants et ne modifie pas `map_runtime`, `map_gameplay`, `map_battle` ou `examples`.

## Design / Architecture Gate

Questions tranchées :

- Stockage des Facts authoring : `ProjectManifest.facts`, pas un sous-modèle `narrativeFacts`, car le repo stocke déjà les catalogues projet directement dans le manifest.
- Modèle minimal : `NarrativeFactDefinition`.
- Typage V0 : bool-first uniquement. Les types number/text/enum restent reportés.
- Mapping runtime futur : un Fact pourra être mappé plus tard vers l'état persistant, probablement via `GameState.storyFlags` ou une évolution typée équivalente, mais V1-18 ne crée pas de stockage runtime.
- Flags legacy : `legacyFlagName` existe pour envelopper un flag technique connu, sans migration automatique.
- Condition picker : les Facts de registry sont proposés avant les sources fact-like techniques.
- Diagnostics : ajout d'un diagnostic project-aware pour une condition qui référence un Fact absent.
- World Rules : préparées conceptuellement par la registry, mais non codées.

Décision finale : `ProjectManifest.facts` + `NarrativeFactDefinition` bool-first + source condition explicite `fact`.

## Scope réalisé

- Modèle core `NarrativeFactDefinition`.
- Intégration JSON dans `ProjectManifest`.
- Fichiers generated Freezed/JsonSerializable régénérés.
- Opérations pures `addNarrativeFact`, `updateNarrativeFact`, `removeNarrativeFact`.
- Refus de suppression d'un Fact référencé par une condition Scene V1.
- Extension `SceneConditionSourceKind.fact`.
- Diagnostics de référence Fact absente via `diagnoseSceneAgainstProject`.
- Picker Condition : affichage des Facts lisibles de registry avec label, catégorie, description et legacy flag debug.
- Test/golden Visual Gate V1-18.
- Roadmaps mises à jour.

## Fichiers créés/modifiés

Fichiers créés :

- `packages/map_core/lib/src/models/narrative_fact.dart`
- `packages/map_core/lib/src/authoring/narrative_fact_authoring_operations.dart`
- `packages/map_core/test/narrative_fact_test.dart`
- `packages/map_core/test/narrative_fact_authoring_operations_test.dart`
- `packages/map_core/test/project_manifest_facts_test.dart`
- `reports/narrativeStudio/scenes/ns_scenes_v1_18_fact_registry_v0.md`
- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_18_fact_registry_v0.png`

Fichiers modifiés :

- `packages/map_core/lib/map_core.dart`
- `packages/map_core/lib/src/authoring/scene_authoring_operations.dart`
- `packages/map_core/lib/src/diagnostics/scene_diagnostics.dart`
- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/models/project_manifest.freezed.dart`
- `packages/map_core/lib/src/models/project_manifest.g.dart`
- `packages/map_core/lib/src/models/scene_asset.dart`
- `packages/map_core/test/scene_asset_json_test.dart`
- `packages/map_core/test/scene_diagnostics_test.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`
- `packages/map_editor/lib/src/ui/canvas/scenes/scene_node_read_only_inspector.dart`
- `packages/map_editor/test/scenes_workspace_shell_test.dart`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

## Décisions techniques

- `facts` est le nom de champ public dans `ProjectManifest`.
- `facts` absent ou `null` décode vers `[]`.
- `NarrativeFactDefinition` valide `id` et `label`, stabilise les tags et supprime les valeurs optionnelles vides.
- `SceneConditionSourceKind.fact` est séparé de `factLikeStoryFlag` pour éviter de confondre une source métier lisible avec un flag technique.
- Le diagnostic project-aware est ajouté dans une nouvelle fonction afin de ne pas imposer `ProjectManifest` aux diagnostics locaux existants.
- L'UI ne crée pas de Fact depuis l'inspecteur : pas de mini Fact Studio dans ce lot.

## Modèle Fact Registry

`NarrativeFactDefinition` V0 :

- `id`
- `label`
- `description`
- `category`
- `defaultValue`
- `tags`
- `legacyFlagName`

Le modèle est bool-first : `defaultValue` est un booléen. Aucun type avancé n'est ajouté.

## ProjectManifest integration

`ProjectManifest` reçoit :

```dart
@Default([])
@JsonKey(
  name: 'facts',
  fromJson: _factsFromJson,
  toJson: _factsToJson,
)
List<NarrativeFactDefinition> facts,
```

Le JSON accepte :

- `facts` absent => `[]`
- `facts: null` => `[]`
- `facts: []` => `[]`
- `facts` liste d'objets valides => decode OK

Aucune conversion automatique `storyFlags -> facts` n'est ajoutée.

## Opérations authoring

Opérations ajoutées :

- `addNarrativeFact`
- `updateNarrativeFact`
- `removeNarrativeFact`

Garanties :

- pas de mutation du `ProjectManifest` original ;
- génération d'id stable depuis le label ;
- collision par suffixe `_2`, `_3`, etc. ;
- label vide refusé ;
- `legacyFlagName` vide trim => `null` ;
- suppression refusée si une scène référence le Fact ;
- pas de random ;
- pas de timestamp.

## Intégration Condition picker

Le picker de condition ajoute les Facts de registry en priorité :

- source kind : `SceneConditionSourceKind.fact`
- source id : `fact.id`
- label : `fact.label`
- debug technical label : `fact.legacyFlagName ?? fact.id`
- description : `fact.description`
- category : `fact.category`

L'inspecteur affiche le bouton `Fact Registry` seulement si le projet contient au moins un Fact. Les sources `factLikeStoryFlag`, `storyStepCompletion` et `consumedEvent` restent compatibles.

## Diagnostics facts

Ajout :

- `SceneDiagnosticCode.conditionFactRefUnknown`
- `diagnoseSceneAgainstProject(SceneAsset scene, ProjectManifest project)`

Comportement :

- une condition `sourceKind: fact` dont `sourceId` n'existe pas dans `ProjectManifest.facts` émet une erreur ;
- une condition V1-17 fact-like reste compatible ;
- les conditions incomplètes restent bloquées par les diagnostics existants.

## Tests exécutés

### map_core

Commande :

```bash
cd packages/map_core && dart test test/narrative_fact_test.dart test/narrative_fact_authoring_operations_test.dart test/project_manifest_facts_test.dart test/scene_diagnostics_test.dart test/scene_asset_json_test.dart
```

Sortie :

```text
00:00 +0: loading test/narrative_fact_test.dart
00:00 +0: test/narrative_fact_test.dart: NarrativeFactDefinition creates a bool-first fact definition with stable metadata
00:00 +1: test/narrative_fact_authoring_operations_test.dart: Narrative fact authoring operations adds a fact with a stable slug id without mutating manifest
00:00 +8: test/project_manifest_facts_test.dart: ProjectManifest facts integration round-trips facts through ProjectManifest JSON
00:00 +9: test/scene_diagnostics_test.dart: Scene diagnostics V1-08 minimal draft has no blocking error
00:00 +11: test/scene_asset_json_test.dart: SceneAsset JSON roundtrip round-trips a complete V0 authoring shape
00:00 +25: test/scene_asset_json_test.dart: SceneAsset JSON roundtrip round-trips Fact Registry condition source payload
00:00 +28: All tests passed!
```

Commande :

```bash
cd packages/map_core && dart analyze
```

Sortie :

```text
Analyzing map_core...
No issues found!
```

### build_runner

Commande :

```bash
cd packages/map_core && dart run build_runner build --delete-conflicting-outputs
```

Sortie :

```text
Generating the build script.
Reading the asset graph.
Checking for updates.
Updating the asset graph.
Building, incremental build.
W SDK language version 3.12.0 is newer than `analyzer` language version 3.9.0. Run `dart pub upgrade`.
W json_serializable on lib/src/models/element_collision_profile.dart:
  The version constraint "^4.8.1" on json_annotation allows versions before 4.9.0 which is not allowed.
Running the post build.
Writing the asset graph.
Built with build_runner in 10s; wrote 12 outputs.
```

Fichiers generated modifiés :

- `packages/map_core/lib/src/models/project_manifest.freezed.dart`
- `packages/map_core/lib/src/models/project_manifest.g.dart`

Ces fichiers ont été générés par `build_runner`, pas modifiés à la main.

### map_editor

Commande :

```bash
cd packages/map_editor && flutter test --reporter=compact test/scenes_workspace_shell_test.dart --plain-name "authors a condition from a Fact Registry source"
```

Sortie :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/scenes_workspace_shell_test.dart
00:02 +0: NS-SCENES-V1-09 scene validation diagnostics authors a condition from a Fact Registry source
00:04 +1: All tests passed!
```

Commande :

```bash
cd packages/map_editor && flutter test --update-goldens --reporter=compact test/scenes_workspace_shell_test.dart --plain-name "writes V1-18 Fact Registry screenshot"
```

Sortie :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/scenes_workspace_shell_test.dart
00:03 +0: NS-SCENES-V1-09 scene validation diagnostics writes V1-18 Fact Registry screenshot
00:04 +1: All tests passed!
```

Commande :

```bash
cd packages/map_editor && flutter test --reporter=compact test/scenes_workspace_shell_test.dart
```

Sortie :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/scenes_workspace_shell_test.dart
00:04 +11: NS-SCENES-V1-09 scene validation diagnostics visual port drag shows preview, highlights target, and creates edge
00:06 +21: NS-SCENES-V1-09 scene validation diagnostics authors a condition from a Fact Registry source
00:08 +47: All tests passed!
```

Commande :

```bash
cd packages/map_editor && flutter test --reporter=compact test/ui/canvas/narrative_overview_shell_navigation_test.dart
```

Sortie :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart
00:05 +19: All tests passed!
```

Commande :

```bash
cd packages/map_editor && flutter test --reporter=compact test/ui/canvas/narrative_studio_header_test.dart
```

Sortie :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_studio_header_test.dart
00:02 +3: All tests passed!
```

Commande :

```bash
cd packages/map_editor && flutter test --reporter=compact test/narrative_workspace_projection_test.dart
```

Sortie :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/narrative_workspace_projection_test.dart
00:01 +3: All tests passed!
```

Commande :

```bash
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/narrative_workspace_canvas.dart lib/src/ui/canvas/scenes_workspace.dart lib/src/ui/canvas/scenes/scene_node_read_only_inspector.dart test/scenes_workspace_shell_test.dart
```

Sortie :

```text
Analyzing 4 items...
No issues found! (ran in 2.0s)
```

Commande de contrôle couleurs feature :

```bash
git diff -U0 -- packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart packages/map_editor/lib/src/ui/canvas/scenes/scene_node_read_only_inspector.dart packages/map_editor/test/scenes_workspace_shell_test.dart | rg -n "^[+] .*Color\(|^[+] .*Colors\.|^[+] .*CupertinoColors"
```

Sortie : <vide>

## Visual Gate

Fichier :

```text
/Users/karim/Project/pokemonProject/reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_18_fact_registry_v0.png
```

Commande :

```bash
cd packages/map_editor && flutter test --update-goldens --reporter=compact test/scenes_workspace_shell_test.dart --plain-name "writes V1-18 Fact Registry screenshot"
```

Le screenshot est produit par un test widget contrôlé, avec un `ConditionNode` sélectionné, le picker `Fact Registry`, un Fact lisible de test et aucun runtime.

## Git status initial

Commande :

```bash
pwd && git branch --show-current && git status --short --untracked-files=all && git diff --stat && git log --oneline -n 10
```

Sortie :

```text
/Users/karim/Project/pokemonProject
main
0d8f2b7c feat(scenes): implement scene condition authoring v0 and update workspace tests
8932f26b docs(scenes): add condition sources contract v0 and update roadmaps
385c2da3 docs(scenes): add prep condition sources roadmap review and roadmap updates
92d43017 chore(selbrume): update project.json configuration
eb2037bf feat(scenes): add wire anchor color coding and update screenshots
b98b4424 feat(scenes): add edge selection and deletion UX v0 with updated tests
a604c2c4 feat(scenes): add visual port connection UX v0 and update tests
82b0d2bc feat(scenes): add blueprint graph canvas foundation and update tests
1c5ee72d feat(scenes): implement edge authoring v0 and update tests
18046f6a feat(scenes): implement node authoring v0 and update tests
```

`git status --short --untracked-files=all` initial : sortie vide.

`git diff --stat` initial : sortie vide.

## Git final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie :

```text
 M packages/map_core/lib/map_core.dart
 M packages/map_core/lib/src/authoring/scene_authoring_operations.dart
 M packages/map_core/lib/src/diagnostics/scene_diagnostics.dart
 M packages/map_core/lib/src/models/project_manifest.dart
 M packages/map_core/lib/src/models/project_manifest.freezed.dart
 M packages/map_core/lib/src/models/project_manifest.g.dart
 M packages/map_core/lib/src/models/scene_asset.dart
 M packages/map_core/test/scene_asset_json_test.dart
 M packages/map_core/test/scene_diagnostics_test.dart
 M packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
 M packages/map_editor/lib/src/ui/canvas/scenes/scene_node_read_only_inspector.dart
 M packages/map_editor/test/scenes_workspace_shell_test.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? packages/map_core/lib/src/authoring/narrative_fact_authoring_operations.dart
?? packages/map_core/lib/src/models/narrative_fact.dart
?? packages/map_core/test/narrative_fact_authoring_operations_test.dart
?? packages/map_core/test/narrative_fact_test.dart
?? packages/map_core/test/project_manifest_facts_test.dart
?? reports/narrativeStudio/scenes/ns_scenes_v1_18_fact_registry_v0.md
?? reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_18_fact_registry_v0.png
```

Commande :

```bash
git diff --stat
```

Sortie :

```text
 packages/map_core/lib/map_core.dart                |   2 +
 .../src/authoring/scene_authoring_operations.dart  |   1 +
 .../lib/src/diagnostics/scene_diagnostics.dart     |  38 +++++++
 .../map_core/lib/src/models/project_manifest.dart  |  43 ++++++++
 .../lib/src/models/project_manifest.freezed.dart   |  42 +++++++-
 .../lib/src/models/project_manifest.g.dart         |   2 +
 packages/map_core/lib/src/models/scene_asset.dart  |   1 +
 packages/map_core/test/scene_asset_json_test.dart  |  22 ++++
 packages/map_core/test/scene_diagnostics_test.dart |  52 +++++++++-
 .../src/ui/canvas/narrative_workspace_canvas.dart  |  13 +++
 .../scenes/scene_node_read_only_inspector.dart     |  39 +++++++
 .../test/scenes_workspace_shell_test.dart          | 112 ++++++++++++++++++++-
 .../scenes/road_map_scene_builder_authoring.md     |  16 ++-
 reports/narrativeStudio/scenes/road_map_scenes.md  |  38 ++++++-
 14 files changed, 409 insertions(+), 12 deletions(-)
```

Commande :

```bash
git diff --name-only
```

Sortie :

```text
packages/map_core/lib/map_core.dart
packages/map_core/lib/src/authoring/scene_authoring_operations.dart
packages/map_core/lib/src/diagnostics/scene_diagnostics.dart
packages/map_core/lib/src/models/project_manifest.dart
packages/map_core/lib/src/models/project_manifest.freezed.dart
packages/map_core/lib/src/models/project_manifest.g.dart
packages/map_core/lib/src/models/scene_asset.dart
packages/map_core/test/scene_asset_json_test.dart
packages/map_core/test/scene_diagnostics_test.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/lib/src/ui/canvas/scenes/scene_node_read_only_inspector.dart
packages/map_editor/test/scenes_workspace_shell_test.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

Commande :

```bash
git diff --check
```

Sortie : <vide>

## Evidence Pack

### pwd

```text
/Users/karim/Project/pokemonProject
```

### git branch --show-current

```text
main
```

### Liste des fichiers lus

- `AGENTS.md`
- `agent_rules.md`
- `skills/README.md`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_16_condition_sources_contract_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_17_condition_authoring_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_16_prep_condition_sources_facts_world_rules_roadmap_review.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_09_scene_validation_diagnostics.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_15_bis_edge_selection_deletion_ux_v0.md`
- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/models/game_state.dart`
- `packages/map_core/lib/src/models/save_data.dart`
- `packages/map_core/lib/src/models/scene_asset.dart`
- `packages/map_core/lib/src/models/script_conditions.dart`
- `packages/map_core/lib/src/diagnostics/scene_diagnostics.dart`
- `packages/map_core/lib/src/authoring/scene_authoring_operations.dart`
- `packages/map_core/lib/map_core.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`
- `packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/scenes/scene_node_read_only_inspector.dart`
- `packages/map_editor/test/scenes_workspace_shell_test.dart`

### Contenu complet des principaux fichiers créés

`packages/map_core/lib/src/models/narrative_fact.dart`

```dart
import 'package:meta/meta.dart' show immutable;

@immutable
final class NarrativeFactDefinition {
  NarrativeFactDefinition({
    required String id,
    required String label,
    String description = '',
    String category = '',
    this.defaultValue = false,
    List<String> tags = const <String>[],
    String? legacyFlagName,
  })  : id = _requireTrimmed(id, 'NarrativeFactDefinition.id'),
        label = _requireTrimmed(label, 'NarrativeFactDefinition.label'),
        description = description.trim(),
        category = category.trim(),
        tags = _stableTags(tags),
        legacyFlagName = _trimOptional(legacyFlagName);

  factory NarrativeFactDefinition.fromJson(Map<String, dynamic> json) {
    return NarrativeFactDefinition(
      id: _readRequiredString(json, 'id'),
      label: _readRequiredString(json, 'label'),
      description: _readOptionalString(json, 'description') ?? '',
      category: _readOptionalString(json, 'category') ?? '',
      defaultValue: _readBool(json, 'defaultValue'),
      tags: _readStringList(json, 'tags'),
      legacyFlagName: _readOptionalString(json, 'legacyFlagName'),
    );
  }

  final String id;
  final String label;
  final String description;
  final String category;
  final bool defaultValue;
  final List<String> tags;
  final String? legacyFlagName;

  Map<String, dynamic> toJson() => _withoutNulls({
        'id': id,
        'label': label,
        'description': description,
        'category': category,
        'defaultValue': defaultValue,
        'tags': tags,
        'legacyFlagName': legacyFlagName,
      });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NarrativeFactDefinition &&
          other.id == id &&
          other.label == label &&
          other.description == description &&
          other.category == category &&
          other.defaultValue == defaultValue &&
          _listEquals(other.tags, tags) &&
          other.legacyFlagName == legacyFlagName;

  @override
  int get hashCode => Object.hash(
        id,
        label,
        description,
        category,
        defaultValue,
        Object.hashAll(tags),
        legacyFlagName,
      );
}

String _requireTrimmed(String value, String fieldName) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    throw ArgumentError.value(value, fieldName, 'must not be empty');
  }
  return trimmed;
}

String? _trimOptional(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}

List<String> _stableTags(List<String> values) {
  final seen = <String>{};
  final result = <String>[];
  for (final value in values) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || !seen.add(trimmed)) {
      continue;
    }
    result.add(trimmed);
  }
  return List<String>.unmodifiable(result);
}

String _readRequiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw ArgumentError.value(value, key, 'must be a non-empty string');
  }
  return value;
}

String? _readOptionalString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) {
    return null;
  }
  if (value is! String) {
    throw ArgumentError.value(value, key, 'must be a string');
  }
  return value;
}

bool _readBool(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) {
    return false;
  }
  if (value is! bool) {
    throw ArgumentError.value(value, key, 'must be a boolean');
  }
  return value;
}

List<String> _readStringList(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) {
    return const <String>[];
  }
  if (value is! List) {
    throw ArgumentError.value(value, key, 'must be a list');
  }
  return [
    for (final item in value)
      if (item is String) item else throw ArgumentError.value(item, key),
  ];
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
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}
```

`packages/map_core/lib/src/authoring/narrative_fact_authoring_operations.dart`

```dart
import '../models/narrative_fact.dart';
import '../models/project_manifest.dart';
import '../models/scene_asset.dart';

final class NarrativeFactCreationResult {
  const NarrativeFactCreationResult({
    required this.updatedProject,
    required this.createdFact,
  });

  final ProjectManifest updatedProject;
  final NarrativeFactDefinition createdFact;
}

final class NarrativeFactUpdateResult {
  const NarrativeFactUpdateResult({
    required this.updatedProject,
    required this.updatedFact,
  });

  final ProjectManifest updatedProject;
  final NarrativeFactDefinition updatedFact;
}

final class NarrativeFactRemovalResult {
  const NarrativeFactRemovalResult({
    required this.updatedProject,
    required this.removedFact,
  });

  final ProjectManifest updatedProject;
  final NarrativeFactDefinition removedFact;
}

NarrativeFactCreationResult addNarrativeFact(
  ProjectManifest manifest, {
  required String label,
  String description = '',
  String category = '',
  bool defaultValue = false,
  List<String> tags = const <String>[],
  String? legacyFlagName,
}) {
  final trimmedLabel = label.trim();
  if (trimmedLabel.isEmpty) {
    throw ArgumentError.value(label, 'label', 'Fact label is required.');
  }
  final fact = NarrativeFactDefinition(
    id: _uniqueFactId(trimmedLabel, manifest.facts.map((fact) => fact.id)),
    label: trimmedLabel,
    description: description,
    category: category,
    defaultValue: defaultValue,
    tags: tags,
    legacyFlagName: legacyFlagName,
  );
  return NarrativeFactCreationResult(
    updatedProject: manifest.copyWith(facts: [...manifest.facts, fact]),
    createdFact: fact,
  );
}

NarrativeFactUpdateResult updateNarrativeFact(
  ProjectManifest manifest, {
  required String factId,
  required String label,
  String description = '',
  String category = '',
  bool defaultValue = false,
  List<String> tags = const <String>[],
  String? legacyFlagName,
}) {
  final index = manifest.facts.indexWhere((fact) => fact.id == factId);
  if (index < 0) {
    throw ArgumentError.value(factId, 'factId', 'Unknown narrative fact.');
  }
  final updatedFact = NarrativeFactDefinition(
    id: factId,
    label: label,
    description: description,
    category: category,
    defaultValue: defaultValue,
    tags: tags,
    legacyFlagName: legacyFlagName,
  );
  final facts = manifest.facts.toList(growable: true);
  facts[index] = updatedFact;
  return NarrativeFactUpdateResult(
    updatedProject: manifest.copyWith(facts: facts),
    updatedFact: updatedFact,
  );
}

NarrativeFactRemovalResult removeNarrativeFact(
  ProjectManifest manifest, {
  required String factId,
}) {
  final index = manifest.facts.indexWhere((fact) => fact.id == factId);
  if (index < 0) {
    throw ArgumentError.value(factId, 'factId', 'Unknown narrative fact.');
  }
  final referencingScene = _firstSceneReferencingFact(manifest, factId);
  if (referencingScene != null) {
    throw ArgumentError.value(
      factId,
      'factId',
      'Cannot remove narrative fact referenced by scene ${referencingScene.id}.',
    );
  }
  final removedFact = manifest.facts[index];
  final facts = manifest.facts.toList(growable: true)..removeAt(index);
  return NarrativeFactRemovalResult(
    updatedProject: manifest.copyWith(facts: facts),
    removedFact: removedFact,
  );
}

SceneAsset? _firstSceneReferencingFact(
    ProjectManifest manifest, String factId) {
  for (final scene in manifest.scenes) {
    for (final node in scene.graph.nodes) {
      final payload = node.payload;
      if (payload is! SceneConditionPayload) {
        continue;
      }
      final source = payload.conditionSource;
      if (source?.sourceKind == SceneConditionSourceKind.fact &&
          source?.sourceId == factId) {
        return scene;
      }
    }
  }
  return null;
}

String _uniqueFactId(String label, Iterable<String> existingIds) {
  final existing = existingIds.toSet();
  final slug = _slugify(label);
  final base = 'fact_${slug.isEmpty ? 'item' : slug}';
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
```

Les autres fichiers créés sont des tests ciblés listés plus haut ; leurs cas couvrent la création/validation JSON, les opérations et l'intégration `ProjectManifest.facts`.

Le fichier binaire `ns_scenes_v1_18_fact_registry_v0.png` est le screenshot de Visual Gate généré par le test golden.

Le présent document constitue le contenu du fichier rapport créé.

### Sections modifiées principales

- `ProjectManifest` : helpers `_factsFromJson`, `_factsToJson`, `_factJsonObject`, champ `facts`.
- `SceneConditionSourceKind` : ajout de `fact`.
- `scene_diagnostics.dart` : ajout `conditionFactRefUnknown` et `diagnoseSceneAgainstProject`.
- `narrative_workspace_canvas.dart` : ajout des Facts au picker condition.
- `scene_node_read_only_inspector.dart` : bouton `Fact Registry`, résumé catégorie/description, opérateurs booléens.
- Roadmaps : V1-18 marqué DONE, prochain lot V1-19.

### Diff complet / generated files

Generated files :

- `packages/map_core/lib/src/models/project_manifest.freezed.dart`
- `packages/map_core/lib/src/models/project_manifest.g.dart`

Hunks pertinents :

```text
project_manifest.freezed.dart : ajout du champ facts dans getters, copyWith, constructeur, égalité, hashCode et toString.
project_manifest.g.dart : decode json['facts'] via _factsFromJson, encode via _factsToJson.
```

Justification : ces fichiers sont très longs et générés automatiquement ; les hunks pertinents ci-dessus correspondent au champ `facts`.

### Auto-review critique

- Le modèle est volontairement bool-first : c'est un bon garde-fou, mais il faudra éviter que `defaultValue` soit confondu avec la valeur runtime courante.
- `diagnoseSceneAgainstProject` n'est pas encore intégré dans la projection globale editor ; l'UI actuelle bénéficie surtout du picker qui évite les refs absentes. Un futur lot Diagnostics Expansion devra unifier les diagnostics project-aware.
- La registry a des opérations core mais pas encore de surface editor dédiée. C'est assumé pour ne pas créer un Fact Studio complet dans V1-18.
- Le screenshot golden utilise le rendu widget-test existant ; il valide la structure UI mais reste moins lisible qu'une capture desktop avec police réelle.
- `legacyFlagName` facilite la migration douce, mais peut devenir une dette si le lot World Rules ou Runtime Plan ne formalise pas vite le mapping persistant.

### Regard critique sur le prompt

Le prompt est bien cadré : il limite les Facts à une registry authoring et interdit clairement World Rules/runtime/migration automatique. Le point délicat est la demande simultanée d'un picker editor et d'une registry sans écran de gestion ; la solution retenue garde l'UI minimale et teste les Facts via fixture contrôlée.

Le prochain lot recommandé reste `NS-SCENES-V1-19 — World Rule Contract V0`, pas une extension de Condition Authoring, parce que les Facts deviennent utiles seulement si les conséquences visibles du monde sont cadrées.
