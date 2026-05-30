# NS-SCENES-V1-20 — World Rules V0

## Resume executif

V1-20 ajoute le premier socle authoring controle des World Rules V0. Le lot introduit une registry canonique `ProjectManifest.worldRules`, un modele pur `WorldRuleDefinition`, des operations authoring immutables, des diagnostics dedies, une projection pure depuis `GameState`, et un affichage minimal dans l'apercu Narrative Studio. Aucun runtime Scene, Event -> Scene, StorylineStep link, migration legacy ou donnee Selbrume n'est branche.

## Design / Architecture Gate

- Les World Rules vivent dans `map_core`, car ce sont des donnees authoring projet et non une responsabilite runtime/editor.
- `ProjectManifest.worldRules` est le stockage canonique V0 ; les predicates legacy existants restent inspiration/bridge, sans migration automatique.
- Les sources V0 sont limitees a `Fact`, `StoryStep completion` et `consumed event`.
- Les targets V0 sont limitees a `mapEntity`, `npcDialogue` et `mapEvent`.
- Les effets V0 sont limites a visibilite/presence simple d'entite, override de dialogue PNJ, disponibilite/masquage d'event.
- La projection `projectWorldRuleEffects` est pure, non destructive, non runtime et ignore Flame/Flutter.
- L'editor ne cree pas encore de World Rules ; il affiche seulement compteur, diagnostics et premiers labels dans l'apercu.

## Scope realise

- Modele World Rule pur ajoute.
- `ProjectManifest.worldRules` ajoute et regenere via build_runner.
- Operations pures `addWorldRule`, `updateWorldRule`, `removeWorldRule`.
- Diagnostics `diagnoseWorldRules`.
- Projection pure `projectWorldRuleEffects`.
- Apercu editor minimal : module World Rules compte les regles, affiche diagnostics et labels.
- Visual gate PNG produit.

## Fichiers crees/modifies

### Crees V1-20
- `packages/map_core/lib/src/models/world_rule.dart`
- `packages/map_core/lib/src/authoring/world_rule_authoring_operations.dart`
- `packages/map_core/lib/src/diagnostics/world_rule_diagnostics.dart`
- `packages/map_core/lib/src/projection/world_rule_projection.dart`
- `packages/map_core/test/world_rule_test.dart`
- `packages/map_core/test/world_rule_authoring_operations_test.dart`
- `packages/map_core/test/project_manifest_world_rules_test.dart`
- `packages/map_core/test/world_rule_diagnostics_test.dart`
- `packages/map_core/test/world_rule_projection_test.dart`
- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_20_world_rules_v0.png`
- `reports/narrativeStudio/scenes/ns_scenes_v1_20_world_rules_v0.md`

### Modifies V1-20
- `packages/map_core/lib/map_core.dart`
- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/models/project_manifest.freezed.dart`
- `packages/map_core/lib/src/models/project_manifest.g.dart`
- `packages/map_editor/lib/src/features/narrative/application/overview/narrative_overview_read_model.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_overview_workspace.dart`
- `packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

### Preexistant non modifie par V1-20
- `reports/narrativeStudio/scenes/ns_scenes_v1_19_world_rule_contract_v0.md` et les edits V1-19 de roadmap etaient deja non commit au depart.

## Decisions techniques

- Le modele reste manuel/immutable comme `NarrativeFactDefinition`, sans Freezed dedie pour eviter une surface schema inutile.
- `WorldRuleDefinition` accepte les drafts structuraux lisibles ; les operations authoring refusent les cas invalides, et les diagnostics expliquent les refs inconnues.
- Les conflits V0 sont signales quand deux regles actives ciblent le meme target/effect avec la meme priorite.
- `npcDialogueOverride` exige un `dialogueId` et une cible `npcDialogue`.
- La projection saute toute regle avec diagnostic error et ne mute aucune donnee.

## Modele World Rule

- `WorldRuleDefinition`: `id`, `label`, `description`, `enabled`, `source`, `target`, `effect`, `priority`, `tags`, `debugTechnicalLabel`.
- `WorldRuleSource`: `kind`, `sourceId`, `predicate`, `label`, `debugTechnicalLabel`.
- `WorldRuleTarget`: `kind`, `mapId`, `entityId`, `eventId`, `label`.
- `WorldRuleEffect`: `kind`, `dialogueId`, `label`.

## Diagnostics

Codes ajoutes : `worldRuleSourceMissing`, `worldRuleSourceUnknown`, `worldRuleSourceUnsupported`, `worldRuleTargetMissing`, `worldRuleTargetUnknown`, `worldRuleEffectMissing`, `worldRuleEffectUnsupported`, `worldRuleEffectTargetMismatch`, `worldRuleConflict`, `worldRuleUsesRawTechnicalId`, `worldRuleLegacyPredicateLeak`. Les erreurs bloquent la projection pure ; les warnings gardent l'authoring corrigeable.

## Visual Gate

Chemin : `/Users/karim/Project/pokemonProject/reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_20_world_rules_v0.png`

Commande :
```text
cd packages/map_editor && flutter test --update-goldens --reporter=compact --dart-define=NS_SCENES_V1_20_CAPTURE_SCREENSHOT=true test/ui/canvas/narrative_overview_workspace_test.dart --plain-name "NarrativeOverviewWorkspace captures V1-20 World Rules screenshot when requested"
```
Le screenshot montre l'apercu Narrative Studio, la carte `Règles du monde`, un compteur `1`, le label local `Visible world rule`, les diagnostics `0`, et aucune donnee Selbrume.

## Tests et analyze

- `cd packages/map_core && dart run build_runner build --delete-conflicting-outputs`
  - Exit 0. Built with build_runner in 11s; wrote 12 outputs. Warnings: SDK language/analyzer version, json_annotation constraint warning.
- `cd packages/map_core && dart test test/world_rule_test.dart`
  - Exit 0. All tests passed!
- `cd packages/map_core && dart test test/world_rule_authoring_operations_test.dart`
  - Exit 0. All tests passed!
- `cd packages/map_core && dart test test/project_manifest_world_rules_test.dart`
  - Exit 0. All tests passed!
- `cd packages/map_core && dart test test/world_rule_diagnostics_test.dart`
  - Exit 0. All tests passed!
- `cd packages/map_core && dart test test/world_rule_projection_test.dart`
  - Exit 0. All tests passed!
- `cd packages/map_core && dart test test/project_manifest_facts_test.dart`
  - Exit 0. All tests passed!
- `cd packages/map_core && dart analyze`
  - Exit 0. Analyzing map_core... No issues found!
- `cd packages/map_editor && flutter test --reporter=compact test/ui/canvas/narrative_overview_workspace_test.dart`
  - Exit 0. All tests passed!
- `cd packages/map_editor && flutter test --reporter=compact test/ui/canvas/narrative_overview_shell_navigation_test.dart`
  - Exit 0. All tests passed!
- `cd packages/map_editor && flutter test --reporter=compact test/ui/canvas/narrative_studio_header_test.dart`
  - Exit 0. All tests passed!
- `cd packages/map_editor && flutter test --reporter=compact test/narrative_workspace_projection_test.dart`
  - Exit 0. All tests passed!
- `cd packages/map_editor && flutter test --update-goldens --reporter=compact --dart-define=NS_SCENES_V1_20_CAPTURE_SCREENSHOT=true test/ui/canvas/narrative_overview_workspace_test.dart --plain-name "NarrativeOverviewWorkspace captures V1-20 World Rules screenshot when requested"`
  - Exit 0. All tests passed! Screenshot written to reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_20_world_rules_v0.png
- `cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/features/narrative/application/overview/narrative_overview_read_model.dart lib/src/ui/canvas/narrative_overview_workspace.dart test/ui/canvas/narrative_overview_workspace_test.dart`
  - Exit 0. Analyzing 3 items... No issues found! (ran in 1.1s)

Notes : deux premieres tentatives Flutter lancees en parallele ont echoue a cause du startup lock/native asset macOS ; elles ont ete relancees sequentiellement avec succes.

## Git status initial

```text
/Users/karim/Project/pokemonProject
main
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_19_world_rule_contract_v0.md
 reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md     | 23 +++++++++++---
 reports/narrativeStudio/scenes/road_map_scenes.md                      | 37 +++++++++++++++++++---
 2 files changed, 52 insertions(+), 8 deletions(-)
1d5738d9 feat(scenes): add narrative fact registry and integrate into scene authoring
0d8f2b7c feat(scenes): implement scene condition authoring v0 and update workspace tests
8932f26b docs(scenes): add condition sources contract v0 and update roadmaps
385c2da3 docs(scenes): add prep condition sources roadmap review and roadmap updates
92d43017 chore(selbrume): update project.json configuration
eb2037bf feat(scenes): add wire anchor color coding and update screenshots
b98b4424 feat(scenes): add edge selection and deletion UX v0 with updated tests
a604c2c4 feat(scenes): add visual port connection UX v0 and update tests
82b0d2bc feat(scenes): add blueprint graph canvas foundation and update tests
1c5ee72d feat(scenes): implement edge authoring v0 and update tests
```

## Git status / diff avant creation de ce rapport

### git status
```text
 M packages/map_core/lib/map_core.dart
 M packages/map_core/lib/src/models/project_manifest.dart
 M packages/map_core/lib/src/models/project_manifest.freezed.dart
 M packages/map_core/lib/src/models/project_manifest.g.dart
 M packages/map_editor/lib/src/features/narrative/application/overview/narrative_overview_read_model.dart
 M packages/map_editor/lib/src/ui/canvas/narrative_overview_workspace.dart
 M packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? packages/map_core/lib/src/authoring/world_rule_authoring_operations.dart
?? packages/map_core/lib/src/diagnostics/world_rule_diagnostics.dart
?? packages/map_core/lib/src/models/world_rule.dart
?? packages/map_core/lib/src/projection/world_rule_projection.dart
?? packages/map_core/test/project_manifest_world_rules_test.dart
?? packages/map_core/test/world_rule_authoring_operations_test.dart
?? packages/map_core/test/world_rule_diagnostics_test.dart
?? packages/map_core/test/world_rule_projection_test.dart
?? packages/map_core/test/world_rule_test.dart
?? reports/narrativeStudio/scenes/ns_scenes_v1_19_world_rule_contract_v0.md
?? reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_20_world_rules_v0.png
```
### git diff --stat
```text
 packages/map_core/lib/map_core.dart                |   4 +
 .../map_core/lib/src/models/project_manifest.dart  |  43 ++++++
 .../lib/src/models/project_manifest.freezed.dart   |  60 +++++++-
 .../lib/src/models/project_manifest.g.dart         |   4 +
 .../overview/narrative_overview_read_model.dart    |  51 +++++--
 .../ui/canvas/narrative_overview_workspace.dart    |  41 +++++
 .../canvas/narrative_overview_workspace_test.dart  | 169 ++++++++++++++++++++-
 .../scenes/road_map_scene_builder_authoring.md     |  35 ++++-
 reports/narrativeStudio/scenes/road_map_scenes.md  |  76 ++++++++-
 9 files changed, 460 insertions(+), 23 deletions(-)
```
### git diff --name-only
```text
packages/map_core/lib/map_core.dart
packages/map_core/lib/src/models/project_manifest.dart
packages/map_core/lib/src/models/project_manifest.freezed.dart
packages/map_core/lib/src/models/project_manifest.g.dart
packages/map_editor/lib/src/features/narrative/application/overview/narrative_overview_read_model.dart
packages/map_editor/lib/src/ui/canvas/narrative_overview_workspace.dart
packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```
### git diff --check
```text
<vide>
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
### git log --oneline -n 10
```text
1d5738d9 feat(scenes): add narrative fact registry and integrate into scene authoring
0d8f2b7c feat(scenes): implement scene condition authoring v0 and update workspace tests
8932f26b docs(scenes): add condition sources contract v0 and update roadmaps
385c2da3 docs(scenes): add prep condition sources roadmap review and roadmap updates
92d43017 chore(selbrume): update project.json configuration
eb2037bf feat(scenes): add wire anchor color coding and update screenshots
b98b4424 feat(scenes): add edge selection and deletion UX v0 with updated tests
a604c2c4 feat(scenes): add visual port connection UX v0 and update tests
82b0d2bc feat(scenes): add blueprint graph canvas foundation and update tests
1c5ee72d feat(scenes): implement edge authoring v0 and update tests
```
### Liste des fichiers lus
- `AGENTS.md`
- `agent_rules.md`
- `skills/README.md`
- `skills/test-driven-development/SKILL.md`
- `skills/writing-plans/SKILL.md`
- `skills/verification-before-completion/SKILL.md`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_15_bis_edge_selection_deletion_ux_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_19_world_rule_contract_v0.md`
- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/models/map_data.dart`
- `packages/map_core/lib/src/models/map_event_definition.dart`
- `packages/map_core/lib/src/models/map_entity_payloads.dart`
- `packages/map_core/lib/src/models/game_state.dart`
- `packages/map_core/lib/src/models/save_data.dart`
- `packages/map_core/lib/src/models/storyline_asset.dart`
- `packages/map_core/lib/src/models/narrative_fact.dart`
- `packages/map_core/lib/src/authoring/narrative_fact_authoring_operations.dart`
- `packages/map_core/lib/src/diagnostics/scene_diagnostics.dart`
- `packages/map_core/lib/map_core.dart`
- `packages/map_editor/lib/src/features/narrative/application/overview/narrative_overview_read_model.dart`
- `packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_overview_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`
- `packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart`


### Contenu complet des fichiers crees V1-20


#### packages/map_core/lib/src/models/world_rule.dart
```dart
import 'package:meta/meta.dart' show immutable;

enum WorldRuleSourceKind {
  fact,
  storyStepCompletion,
  consumedEvent,
}

enum WorldRuleSourcePredicate {
  isTrue,
  isFalse,
  completed,
  notCompleted,
  consumed,
  notConsumed,
}

enum WorldRuleTargetKind {
  mapEntity,
  npcDialogue,
  mapEvent,
}

enum WorldRuleEffectKind {
  entityVisible,
  entityHidden,
  npcDialogueOverride,
  eventEnabled,
  eventDisabled,
  eventHidden,
}

@immutable
final class WorldRuleSource {
  const WorldRuleSource({
    required this.kind,
    required this.sourceId,
    required this.predicate,
    this.label,
    this.debugTechnicalLabel,
  });

  factory WorldRuleSource.fromJson(Map<String, dynamic> json) {
    return WorldRuleSource(
      kind: _readEnum(WorldRuleSourceKind.values, json['kind'], 'kind'),
      sourceId: _readOptionalString(json, 'sourceId') ?? '',
      predicate: _readEnum(
        WorldRuleSourcePredicate.values,
        json['predicate'],
        'predicate',
      ),
      label: _readOptionalString(json, 'label'),
      debugTechnicalLabel: _readOptionalString(json, 'debugTechnicalLabel'),
    );
  }

  final WorldRuleSourceKind kind;
  final String sourceId;
  final WorldRuleSourcePredicate predicate;
  final String? label;
  final String? debugTechnicalLabel;

  Map<String, dynamic> toJson() => _withoutNulls({
        'kind': kind.name,
        'sourceId': sourceId,
        'predicate': predicate.name,
        'label': label,
        'debugTechnicalLabel': debugTechnicalLabel,
      });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorldRuleSource &&
          other.kind == kind &&
          other.sourceId == sourceId &&
          other.predicate == predicate &&
          other.label == label &&
          other.debugTechnicalLabel == debugTechnicalLabel;

  @override
  int get hashCode =>
      Object.hash(kind, sourceId, predicate, label, debugTechnicalLabel);
}

@immutable
final class WorldRuleTarget {
  const WorldRuleTarget({
    required this.kind,
    required this.mapId,
    this.entityId,
    this.eventId,
    this.label,
  });

  factory WorldRuleTarget.fromJson(Map<String, dynamic> json) {
    return WorldRuleTarget(
      kind: _readEnum(WorldRuleTargetKind.values, json['kind'], 'kind'),
      mapId: _readOptionalString(json, 'mapId') ?? '',
      entityId: _readOptionalString(json, 'entityId'),
      eventId: _readOptionalString(json, 'eventId'),
      label: _readOptionalString(json, 'label'),
    );
  }

  final WorldRuleTargetKind kind;
  final String mapId;
  final String? entityId;
  final String? eventId;
  final String? label;

  Map<String, dynamic> toJson() => _withoutNulls({
        'kind': kind.name,
        'mapId': mapId,
        'entityId': entityId,
        'eventId': eventId,
        'label': label,
      });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorldRuleTarget &&
          other.kind == kind &&
          other.mapId == mapId &&
          other.entityId == entityId &&
          other.eventId == eventId &&
          other.label == label;

  @override
  int get hashCode => Object.hash(kind, mapId, entityId, eventId, label);
}

@immutable
final class WorldRuleEffect {
  const WorldRuleEffect({
    required this.kind,
    this.dialogueId,
    this.label,
  });

  factory WorldRuleEffect.fromJson(Map<String, dynamic> json) {
    return WorldRuleEffect(
      kind: _readEnum(WorldRuleEffectKind.values, json['kind'], 'kind'),
      dialogueId: _readOptionalString(json, 'dialogueId'),
      label: _readOptionalString(json, 'label'),
    );
  }

  final WorldRuleEffectKind kind;
  final String? dialogueId;
  final String? label;

  Map<String, dynamic> toJson() => _withoutNulls({
        'kind': kind.name,
        'dialogueId': dialogueId,
        'label': label,
      });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorldRuleEffect &&
          other.kind == kind &&
          other.dialogueId == dialogueId &&
          other.label == label;

  @override
  int get hashCode => Object.hash(kind, dialogueId, label);
}

@immutable
final class WorldRuleDefinition {
  WorldRuleDefinition({
    required String id,
    required String label,
    String description = '',
    this.enabled = true,
    required this.source,
    required this.target,
    required this.effect,
    this.priority = 0,
    List<String> tags = const <String>[],
    String? debugTechnicalLabel,
  })  : id = _requireTrimmed(id, 'WorldRuleDefinition.id'),
        label = _requireTrimmed(label, 'WorldRuleDefinition.label'),
        description = description.trim(),
        tags = _stableTags(tags),
        debugTechnicalLabel = _trimOptional(debugTechnicalLabel);

  factory WorldRuleDefinition.fromJson(Map<String, dynamic> json) {
    return WorldRuleDefinition(
      id: _readRequiredString(json, 'id'),
      label: _readRequiredString(json, 'label'),
      description: _readOptionalString(json, 'description') ?? '',
      enabled: _readBool(json, 'enabled', defaultValue: true),
      source: WorldRuleSource.fromJson(_readObject(json, 'source')),
      target: WorldRuleTarget.fromJson(_readObject(json, 'target')),
      effect: WorldRuleEffect.fromJson(_readObject(json, 'effect')),
      priority: _readInt(json, 'priority'),
      tags: _readStringList(json, 'tags'),
      debugTechnicalLabel: _readOptionalString(json, 'debugTechnicalLabel'),
    );
  }

  final String id;
  final String label;
  final String description;
  final bool enabled;
  final WorldRuleSource source;
  final WorldRuleTarget target;
  final WorldRuleEffect effect;
  final int priority;
  final List<String> tags;
  final String? debugTechnicalLabel;

  Map<String, dynamic> toJson() => _withoutNulls({
        'id': id,
        'label': label,
        'description': description,
        'enabled': enabled,
        'source': source.toJson(),
        'target': target.toJson(),
        'effect': effect.toJson(),
        'priority': priority,
        'tags': tags,
        'debugTechnicalLabel': debugTechnicalLabel,
      });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorldRuleDefinition &&
          other.id == id &&
          other.label == label &&
          other.description == description &&
          other.enabled == enabled &&
          other.source == source &&
          other.target == target &&
          other.effect == effect &&
          other.priority == priority &&
          _listEquals(other.tags, tags) &&
          other.debugTechnicalLabel == debugTechnicalLabel;

  @override
  int get hashCode => Object.hash(
        id,
        label,
        description,
        enabled,
        source,
        target,
        effect,
        priority,
        Object.hashAll(tags),
        debugTechnicalLabel,
      );
}

bool isWorldRuleSourcePredicateCompatible(
  WorldRuleSourceKind kind,
  WorldRuleSourcePredicate predicate,
) {
  return switch (kind) {
    WorldRuleSourceKind.fact => predicate == WorldRuleSourcePredicate.isTrue ||
        predicate == WorldRuleSourcePredicate.isFalse,
    WorldRuleSourceKind.storyStepCompletion =>
      predicate == WorldRuleSourcePredicate.completed ||
          predicate == WorldRuleSourcePredicate.notCompleted,
    WorldRuleSourceKind.consumedEvent =>
      predicate == WorldRuleSourcePredicate.consumed ||
          predicate == WorldRuleSourcePredicate.notConsumed,
  };
}

bool isWorldRuleEffectCompatibleWithTarget(
  WorldRuleTargetKind targetKind,
  WorldRuleEffectKind effectKind,
) {
  return switch (targetKind) {
    WorldRuleTargetKind.mapEntity =>
      effectKind == WorldRuleEffectKind.entityVisible ||
          effectKind == WorldRuleEffectKind.entityHidden,
    WorldRuleTargetKind.npcDialogue =>
      effectKind == WorldRuleEffectKind.npcDialogueOverride,
    WorldRuleTargetKind.mapEvent =>
      effectKind == WorldRuleEffectKind.eventEnabled ||
          effectKind == WorldRuleEffectKind.eventDisabled ||
          effectKind == WorldRuleEffectKind.eventHidden,
  };
}

String _requireTrimmed(String value, String fieldName) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    throw ArgumentError.value(value, fieldName, 'must not be empty');
  }
  return trimmed;
}

String _readRequiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw ArgumentError.value(value, key, 'must be a non-empty string');
  }
  return value.trim();
}

String? _readOptionalString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) {
    return null;
  }
  if (value is! String) {
    throw ArgumentError.value(value, key, 'must be a string');
  }
  return _trimOptional(value);
}

bool _readBool(
  Map<String, dynamic> json,
  String key, {
  bool defaultValue = false,
}) {
  final value = json[key];
  if (value == null) {
    return defaultValue;
  }
  if (value is! bool) {
    throw ArgumentError.value(value, key, 'must be a boolean');
  }
  return value;
}

int _readInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) {
    return 0;
  }
  if (value is! int) {
    throw ArgumentError.value(value, key, 'must be an integer');
  }
  return value;
}

T _readEnum<T extends Enum>(List<T> values, Object? value, String key) {
  if (value is! String || value.trim().isEmpty) {
    throw ArgumentError.value(value, key, 'must be a non-empty enum string');
  }
  final trimmed = value.trim();
  for (final enumValue in values) {
    if (enumValue.name == trimmed) {
      return enumValue;
    }
  }
  throw ArgumentError.value(value, key, 'unsupported enum value');
}

Map<String, dynamic> _readObject(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! Map) {
    throw ArgumentError.value(value, key, 'must be a JSON object');
  }
  return value.map((key, value) {
    if (key is! String) {
      throw ArgumentError.value(key, 'JSON key', 'must be a string');
    }
    return MapEntry(key, value);
  });
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


#### packages/map_core/lib/src/authoring/world_rule_authoring_operations.dart
```dart
import '../models/enums.dart';
import '../models/map_data.dart';
import '../models/project_manifest.dart';
import '../models/world_rule.dart';

final class WorldRuleCreationResult {
  const WorldRuleCreationResult({
    required this.updatedProject,
    required this.createdRule,
  });

  final ProjectManifest updatedProject;
  final WorldRuleDefinition createdRule;
}

final class WorldRuleUpdateResult {
  const WorldRuleUpdateResult({
    required this.updatedProject,
    required this.updatedRule,
  });

  final ProjectManifest updatedProject;
  final WorldRuleDefinition updatedRule;
}

final class WorldRuleRemovalResult {
  const WorldRuleRemovalResult({
    required this.updatedProject,
    required this.removedRule,
  });

  final ProjectManifest updatedProject;
  final WorldRuleDefinition removedRule;
}

WorldRuleCreationResult addWorldRule(
  ProjectManifest manifest, {
  required String label,
  String description = '',
  bool enabled = true,
  required WorldRuleSource source,
  required WorldRuleTarget target,
  required WorldRuleEffect effect,
  int priority = 0,
  List<String> tags = const <String>[],
  String? debugTechnicalLabel,
  List<MapData> maps = const <MapData>[],
}) {
  final trimmedLabel = label.trim();
  if (trimmedLabel.isEmpty) {
    throw ArgumentError.value(label, 'label', 'World rule label is required.');
  }
  final rule = WorldRuleDefinition(
    id: _uniqueWorldRuleId(
      trimmedLabel,
      manifest.worldRules.map((rule) => rule.id),
    ),
    label: trimmedLabel,
    description: description,
    enabled: enabled,
    source: source,
    target: target,
    effect: effect,
    priority: priority,
    tags: tags,
    debugTechnicalLabel: debugTechnicalLabel,
  );
  _validateWorldRuleForAuthoring(manifest, rule, maps: maps);
  return WorldRuleCreationResult(
    updatedProject: manifest.copyWith(
      worldRules: [...manifest.worldRules, rule],
    ),
    createdRule: rule,
  );
}

WorldRuleUpdateResult updateWorldRule(
  ProjectManifest manifest, {
  required String ruleId,
  required String label,
  String description = '',
  bool enabled = true,
  required WorldRuleSource source,
  required WorldRuleTarget target,
  required WorldRuleEffect effect,
  int priority = 0,
  List<String> tags = const <String>[],
  String? debugTechnicalLabel,
  List<MapData> maps = const <MapData>[],
}) {
  final index = manifest.worldRules.indexWhere((rule) => rule.id == ruleId);
  if (index < 0) {
    throw ArgumentError.value(ruleId, 'ruleId', 'Unknown world rule.');
  }
  final updatedRule = WorldRuleDefinition(
    id: ruleId,
    label: label,
    description: description,
    enabled: enabled,
    source: source,
    target: target,
    effect: effect,
    priority: priority,
    tags: tags,
    debugTechnicalLabel: debugTechnicalLabel,
  );
  _validateWorldRuleForAuthoring(manifest, updatedRule, maps: maps);
  final worldRules = manifest.worldRules.toList(growable: true);
  worldRules[index] = updatedRule;
  return WorldRuleUpdateResult(
    updatedProject: manifest.copyWith(worldRules: worldRules),
    updatedRule: updatedRule,
  );
}

WorldRuleRemovalResult removeWorldRule(
  ProjectManifest manifest, {
  required String ruleId,
}) {
  final index = manifest.worldRules.indexWhere((rule) => rule.id == ruleId);
  if (index < 0) {
    throw ArgumentError.value(ruleId, 'ruleId', 'Unknown world rule.');
  }
  final removedRule = manifest.worldRules[index];
  final worldRules = manifest.worldRules.toList(growable: true)
    ..removeAt(index);
  return WorldRuleRemovalResult(
    updatedProject: manifest.copyWith(worldRules: worldRules),
    removedRule: removedRule,
  );
}

void _validateWorldRuleForAuthoring(
  ProjectManifest manifest,
  WorldRuleDefinition rule, {
  required List<MapData> maps,
}) {
  final sourceId = rule.source.sourceId.trim();
  if (sourceId.isEmpty) {
    throw ArgumentError.value(
        sourceId, 'source.sourceId', 'World rule source id is required.');
  }
  if (!isWorldRuleSourcePredicateCompatible(
    rule.source.kind,
    rule.source.predicate,
  )) {
    throw ArgumentError.value(
      rule.source.predicate,
      'source.predicate',
      'World rule predicate is not compatible with its source.',
    );
  }
  if (!isWorldRuleEffectCompatibleWithTarget(
    rule.target.kind,
    rule.effect.kind,
  )) {
    throw ArgumentError.value(
      rule.effect.kind,
      'effect.kind',
      'World rule effect is not compatible with its target.',
    );
  }
  if (rule.target.mapId.trim().isEmpty) {
    throw ArgumentError.value(
      rule.target.mapId,
      'target.mapId',
      'World rule target map id is required.',
    );
  }
  switch (rule.target.kind) {
    case WorldRuleTargetKind.mapEntity:
    case WorldRuleTargetKind.npcDialogue:
      if ((rule.target.entityId ?? '').trim().isEmpty) {
        throw ArgumentError.value(
          rule.target.entityId,
          'target.entityId',
          'World rule target entity id is required.',
        );
      }
    case WorldRuleTargetKind.mapEvent:
      if ((rule.target.eventId ?? '').trim().isEmpty) {
        throw ArgumentError.value(
          rule.target.eventId,
          'target.eventId',
          'World rule target event id is required.',
        );
      }
  }
  if (rule.effect.kind == WorldRuleEffectKind.npcDialogueOverride &&
      (rule.effect.dialogueId ?? '').trim().isEmpty) {
    throw ArgumentError.value(
      rule.effect.dialogueId,
      'effect.dialogueId',
      'World rule dialogue override id is required.',
    );
  }
  _validateSourceReferences(manifest, rule, maps: maps);
  _validateTargetReferences(manifest, rule, maps: maps);
  _validateEffectReferences(manifest, rule);
}

void _validateSourceReferences(
  ProjectManifest manifest,
  WorldRuleDefinition rule, {
  required List<MapData> maps,
}) {
  switch (rule.source.kind) {
    case WorldRuleSourceKind.fact:
      final factIds = manifest.facts.map((fact) => fact.id).toSet();
      if (!factIds.contains(rule.source.sourceId)) {
        throw ArgumentError.value(
          rule.source.sourceId,
          'source.sourceId',
          'Unknown narrative fact for world rule.',
        );
      }
    case WorldRuleSourceKind.storyStepCompletion:
      final stepIds = _storyStepIds(manifest);
      if (stepIds.isNotEmpty && !stepIds.contains(rule.source.sourceId)) {
        throw ArgumentError.value(
          rule.source.sourceId,
          'source.sourceId',
          'Unknown story step for world rule.',
        );
      }
    case WorldRuleSourceKind.consumedEvent:
      final eventIds = _eventIds(maps);
      if (eventIds.isNotEmpty && !eventIds.contains(rule.source.sourceId)) {
        throw ArgumentError.value(
          rule.source.sourceId,
          'source.sourceId',
          'Unknown consumed event for world rule.',
        );
      }
  }
}

void _validateTargetReferences(
  ProjectManifest manifest,
  WorldRuleDefinition rule, {
  required List<MapData> maps,
}) {
  final manifestMapIds = manifest.maps.map((map) => map.id).toSet();
  final mapsById = {for (final map in maps) map.id: map};
  if (!manifestMapIds.contains(rule.target.mapId) &&
      !mapsById.containsKey(rule.target.mapId)) {
    throw ArgumentError.value(
      rule.target.mapId,
      'target.mapId',
      'Unknown map for world rule target.',
    );
  }
  final map = mapsById[rule.target.mapId];
  if (map == null) {
    return;
  }
  switch (rule.target.kind) {
    case WorldRuleTargetKind.mapEntity:
      final entityIds = map.entities.map((entity) => entity.id).toSet();
      if (!entityIds.contains(rule.target.entityId)) {
        throw ArgumentError.value(
          rule.target.entityId,
          'target.entityId',
          'Unknown map entity for world rule target.',
        );
      }
    case WorldRuleTargetKind.npcDialogue:
      final entity = _findEntity(map, rule.target.entityId ?? '');
      if (entity == null) {
        throw ArgumentError.value(
          rule.target.entityId,
          'target.entityId',
          'Unknown NPC entity for world rule target.',
        );
      }
      if (entity.kind != MapEntityKind.npc) {
        throw ArgumentError.value(
          rule.target.entityId,
          'target.entityId',
          'World rule dialogue override target must be an NPC.',
        );
      }
    case WorldRuleTargetKind.mapEvent:
      final eventIds = map.events.map((event) => event.id).toSet();
      if (!eventIds.contains(rule.target.eventId)) {
        throw ArgumentError.value(
          rule.target.eventId,
          'target.eventId',
          'Unknown map event for world rule target.',
        );
      }
  }
}

void _validateEffectReferences(
  ProjectManifest manifest,
  WorldRuleDefinition rule,
) {
  if (rule.effect.kind != WorldRuleEffectKind.npcDialogueOverride) {
    return;
  }
  final dialogueIds = manifest.dialogues.map((dialogue) => dialogue.id).toSet();
  if (!dialogueIds.contains(rule.effect.dialogueId)) {
    throw ArgumentError.value(
      rule.effect.dialogueId,
      'effect.dialogueId',
      'Unknown dialogue for world rule effect.',
    );
  }
}

MapEntity? _findEntity(MapData map, String entityId) {
  for (final entity in map.entities) {
    if (entity.id == entityId) {
      return entity;
    }
  }
  return null;
}

Set<String> _storyStepIds(ProjectManifest manifest) {
  return {
    for (final storyline in manifest.storylines)
      for (final chapter in storyline.chapters)
        for (final step in chapter.steps) step.id,
  };
}

Set<String> _eventIds(List<MapData> maps) {
  return {
    for (final map in maps)
      for (final event in map.events) event.id,
  };
}

String _uniqueWorldRuleId(String label, Iterable<String> existingIds) {
  final existing = existingIds.toSet();
  final slug = _slugify(label);
  final base = 'world_rule_${slug.isEmpty ? 'item' : slug}';
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


#### packages/map_core/lib/src/diagnostics/world_rule_diagnostics.dart
```dart
import '../models/enums.dart';
import '../models/map_data.dart';
import '../models/project_manifest.dart';
import '../models/world_rule.dart';

enum WorldRuleDiagnosticSeverity {
  error,
  warning,
  info,
}

enum WorldRuleDiagnosticCode {
  worldRuleSourceMissing,
  worldRuleSourceUnknown,
  worldRuleSourceUnsupported,
  worldRuleTargetMissing,
  worldRuleTargetUnknown,
  worldRuleEffectMissing,
  worldRuleEffectUnsupported,
  worldRuleEffectTargetMismatch,
  worldRuleConflict,
  worldRuleUsesRawTechnicalId,
  worldRuleLegacyPredicateLeak,
}

final class WorldRuleDiagnostic {
  const WorldRuleDiagnostic({
    required this.code,
    required this.severity,
    required this.message,
    required this.ruleId,
    this.sourceId,
    this.targetId,
    this.mapId,
    this.suggestedFixLabel,
  });

  final WorldRuleDiagnosticCode code;
  final WorldRuleDiagnosticSeverity severity;
  final String message;
  final String ruleId;
  final String? sourceId;
  final String? targetId;
  final String? mapId;
  final String? suggestedFixLabel;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorldRuleDiagnostic &&
          other.code == code &&
          other.severity == severity &&
          other.message == message &&
          other.ruleId == ruleId &&
          other.sourceId == sourceId &&
          other.targetId == targetId &&
          other.mapId == mapId &&
          other.suggestedFixLabel == suggestedFixLabel;

  @override
  int get hashCode => Object.hash(
        code,
        severity,
        message,
        ruleId,
        sourceId,
        targetId,
        mapId,
        suggestedFixLabel,
      );
}

final class WorldRuleDiagnosticsReport {
  WorldRuleDiagnosticsReport({
    required List<WorldRuleDiagnostic> diagnostics,
  }) : _diagnostics = List<WorldRuleDiagnostic>.unmodifiable(diagnostics);

  final List<WorldRuleDiagnostic> _diagnostics;

  List<WorldRuleDiagnostic> get diagnostics => _diagnostics;

  int get count => _diagnostics.length;

  int get errorCount => _diagnostics
      .where((diagnostic) =>
          diagnostic.severity == WorldRuleDiagnosticSeverity.error)
      .length;

  int get warningCount => _diagnostics
      .where((diagnostic) =>
          diagnostic.severity == WorldRuleDiagnosticSeverity.warning)
      .length;

  int get infoCount => _diagnostics
      .where((diagnostic) =>
          diagnostic.severity == WorldRuleDiagnosticSeverity.info)
      .length;

  bool get hasDiagnostics => _diagnostics.isNotEmpty;

  bool get hasErrors => errorCount > 0;

  List<WorldRuleDiagnostic> byCode(WorldRuleDiagnosticCode code) {
    return List<WorldRuleDiagnostic>.unmodifiable(
      _diagnostics.where((diagnostic) => diagnostic.code == code),
    );
  }

  List<WorldRuleDiagnostic> byRuleId(String ruleId) {
    return List<WorldRuleDiagnostic>.unmodifiable(
      _diagnostics.where((diagnostic) => diagnostic.ruleId == ruleId),
    );
  }
}

WorldRuleDiagnosticsReport diagnoseWorldRules(
  ProjectManifest project, {
  List<MapData> maps = const <MapData>[],
}) {
  final diagnostics = <WorldRuleDiagnostic>[];
  final mapsById = {for (final map in maps) map.id: map};
  final projectMapIds = project.maps.map((map) => map.id).toSet();
  final factIds = project.facts.map((fact) => fact.id).toSet();
  final dialogueIds = project.dialogues.map((dialogue) => dialogue.id).toSet();
  final storyStepIds = _storyStepIds(project);
  final consumedEventIds = _eventIds(maps);

  for (final rule in project.worldRules) {
    _diagnoseSource(
      rule,
      diagnostics,
      factIds: factIds,
      storyStepIds: storyStepIds,
      consumedEventIds: consumedEventIds,
    );
    _diagnoseTarget(
      rule,
      diagnostics,
      projectMapIds: projectMapIds,
      mapsById: mapsById,
    );
    _diagnoseEffect(
      rule,
      diagnostics,
      dialogueIds: dialogueIds,
    );
    _diagnoseLabels(rule, diagnostics);
  }
  _diagnoseConflicts(project.worldRules, diagnostics);
  return WorldRuleDiagnosticsReport(diagnostics: diagnostics);
}

void _diagnoseSource(
  WorldRuleDefinition rule,
  List<WorldRuleDiagnostic> diagnostics, {
  required Set<String> factIds,
  required Set<String> storyStepIds,
  required Set<String> consumedEventIds,
}) {
  if (rule.source.sourceId.trim().isEmpty) {
    diagnostics.add(
      WorldRuleDiagnostic(
        code: WorldRuleDiagnosticCode.worldRuleSourceMissing,
        severity: WorldRuleDiagnosticSeverity.error,
        message: 'La World Rule doit choisir une source métier.',
        ruleId: rule.id,
        suggestedFixLabel: 'Choisir un Fact, une étape ou un event consommé.',
      ),
    );
    return;
  }
  if (!isWorldRuleSourcePredicateCompatible(
    rule.source.kind,
    rule.source.predicate,
  )) {
    diagnostics.add(
      WorldRuleDiagnostic(
        code: WorldRuleDiagnosticCode.worldRuleSourceUnsupported,
        severity: WorldRuleDiagnosticSeverity.error,
        message: 'Le prédicat de source n’est pas supporté par ce type.',
        ruleId: rule.id,
        sourceId: rule.source.sourceId,
        suggestedFixLabel: 'Choisir un prédicat compatible avec la source.',
      ),
    );
  }

  switch (rule.source.kind) {
    case WorldRuleSourceKind.fact:
      if (!factIds.contains(rule.source.sourceId)) {
        diagnostics.add(
          WorldRuleDiagnostic(
            code: WorldRuleDiagnosticCode.worldRuleSourceUnknown,
            severity: WorldRuleDiagnosticSeverity.error,
            message: 'La World Rule référence un Fact absent du projet.',
            ruleId: rule.id,
            sourceId: rule.source.sourceId,
            suggestedFixLabel: 'Choisir un Fact existant.',
          ),
        );
      }
    case WorldRuleSourceKind.storyStepCompletion:
      if (storyStepIds.isNotEmpty &&
          !storyStepIds.contains(rule.source.sourceId)) {
        diagnostics.add(
          WorldRuleDiagnostic(
            code: WorldRuleDiagnosticCode.worldRuleSourceUnknown,
            severity: WorldRuleDiagnosticSeverity.error,
            message: 'La World Rule référence une étape narrative inconnue.',
            ruleId: rule.id,
            sourceId: rule.source.sourceId,
            suggestedFixLabel: 'Choisir une étape existante.',
          ),
        );
      }
    case WorldRuleSourceKind.consumedEvent:
      if (consumedEventIds.isNotEmpty &&
          !consumedEventIds.contains(rule.source.sourceId)) {
        diagnostics.add(
          WorldRuleDiagnostic(
            code: WorldRuleDiagnosticCode.worldRuleSourceUnknown,
            severity: WorldRuleDiagnosticSeverity.error,
            message: 'La World Rule référence un event consommé inconnu.',
            ruleId: rule.id,
            sourceId: rule.source.sourceId,
            suggestedFixLabel: 'Choisir un event existant.',
          ),
        );
      }
  }
}

void _diagnoseTarget(
  WorldRuleDefinition rule,
  List<WorldRuleDiagnostic> diagnostics, {
  required Set<String> projectMapIds,
  required Map<String, MapData> mapsById,
}) {
  if (rule.target.mapId.trim().isEmpty) {
    diagnostics.add(
      WorldRuleDiagnostic(
        code: WorldRuleDiagnosticCode.worldRuleTargetMissing,
        severity: WorldRuleDiagnosticSeverity.error,
        message: 'La World Rule doit choisir une map cible.',
        ruleId: rule.id,
        suggestedFixLabel: 'Choisir une map cible.',
      ),
    );
    return;
  }
  if (!projectMapIds.contains(rule.target.mapId) &&
      !mapsById.containsKey(rule.target.mapId)) {
    diagnostics.add(
      WorldRuleDiagnostic(
        code: WorldRuleDiagnosticCode.worldRuleTargetUnknown,
        severity: WorldRuleDiagnosticSeverity.error,
        message: 'La World Rule cible une map inconnue.',
        ruleId: rule.id,
        mapId: rule.target.mapId,
        suggestedFixLabel: 'Choisir une map du projet.',
      ),
    );
    return;
  }
  final map = mapsById[rule.target.mapId];
  if (map == null) {
    return;
  }
  switch (rule.target.kind) {
    case WorldRuleTargetKind.mapEntity:
      final entityId = rule.target.entityId?.trim() ?? '';
      if (entityId.isEmpty) {
        diagnostics.add(_missingTarget(rule, 'entité cible'));
        return;
      }
      if (!map.entities.any((entity) => entity.id == entityId)) {
        diagnostics.add(_unknownTarget(rule, entityId, 'entité'));
      }
    case WorldRuleTargetKind.npcDialogue:
      final entityId = rule.target.entityId?.trim() ?? '';
      if (entityId.isEmpty) {
        diagnostics.add(_missingTarget(rule, 'PNJ cible'));
        return;
      }
      final entity = _findEntity(map, entityId);
      if (entity == null) {
        diagnostics.add(_unknownTarget(rule, entityId, 'PNJ'));
      } else if (entity.kind != MapEntityKind.npc) {
        diagnostics.add(
          WorldRuleDiagnostic(
            code: WorldRuleDiagnosticCode.worldRuleTargetUnknown,
            severity: WorldRuleDiagnosticSeverity.error,
            message: 'La World Rule de dialogue cible une entité non PNJ.',
            ruleId: rule.id,
            targetId: entityId,
            mapId: rule.target.mapId,
            suggestedFixLabel: 'Choisir un PNJ.',
          ),
        );
      }
    case WorldRuleTargetKind.mapEvent:
      final eventId = rule.target.eventId?.trim() ?? '';
      if (eventId.isEmpty) {
        diagnostics.add(_missingTarget(rule, 'event cible'));
        return;
      }
      if (!map.events.any((event) => event.id == eventId)) {
        diagnostics.add(_unknownTarget(rule, eventId, 'event'));
      }
  }
}

void _diagnoseEffect(
  WorldRuleDefinition rule,
  List<WorldRuleDiagnostic> diagnostics, {
  required Set<String> dialogueIds,
}) {
  if (!isWorldRuleEffectCompatibleWithTarget(
    rule.target.kind,
    rule.effect.kind,
  )) {
    diagnostics.add(
      WorldRuleDiagnostic(
        code: WorldRuleDiagnosticCode.worldRuleEffectTargetMismatch,
        severity: WorldRuleDiagnosticSeverity.error,
        message: 'L’effet de la World Rule ne correspond pas à sa cible.',
        ruleId: rule.id,
        targetId: _targetIdentity(rule.target),
        mapId: rule.target.mapId,
        suggestedFixLabel: 'Choisir un effet compatible avec la cible.',
      ),
    );
  }
  if (rule.effect.kind == WorldRuleEffectKind.npcDialogueOverride) {
    final dialogueId = rule.effect.dialogueId?.trim() ?? '';
    if (dialogueId.isEmpty) {
      diagnostics.add(
        WorldRuleDiagnostic(
          code: WorldRuleDiagnosticCode.worldRuleEffectMissing,
          severity: WorldRuleDiagnosticSeverity.error,
          message: 'L’effet de dialogue doit choisir un dialogue.',
          ruleId: rule.id,
          suggestedFixLabel: 'Choisir un dialogue existant.',
        ),
      );
    } else if (!dialogueIds.contains(dialogueId)) {
      diagnostics.add(
        WorldRuleDiagnostic(
          code: WorldRuleDiagnosticCode.worldRuleEffectUnsupported,
          severity: WorldRuleDiagnosticSeverity.error,
          message: 'L’effet référence un dialogue absent du projet.',
          ruleId: rule.id,
          targetId: dialogueId,
          suggestedFixLabel: 'Choisir un dialogue existant.',
        ),
      );
    }
  }
}

void _diagnoseLabels(
  WorldRuleDefinition rule,
  List<WorldRuleDiagnostic> diagnostics,
) {
  if (rule.label.trim() == rule.id ||
      (rule.label.contains('_') && !rule.label.contains(' '))) {
    diagnostics.add(
      WorldRuleDiagnostic(
        code: WorldRuleDiagnosticCode.worldRuleUsesRawTechnicalId,
        severity: WorldRuleDiagnosticSeverity.warning,
        message: 'La World Rule affiche encore un identifiant technique.',
        ruleId: rule.id,
        suggestedFixLabel: 'Donner un label lisible à la règle.',
      ),
    );
  }
  final debug = [
    rule.debugTechnicalLabel,
    rule.source.debugTechnicalLabel,
  ].whereType<String>().join(' ').toLowerCase();
  if (debug.contains('scriptcondition') ||
      debug.contains('script_condition') ||
      debug.contains('predicate')) {
    diagnostics.add(
      WorldRuleDiagnostic(
        code: WorldRuleDiagnosticCode.worldRuleLegacyPredicateLeak,
        severity: WorldRuleDiagnosticSeverity.warning,
        message: 'La World Rule expose encore un prédicat legacy.',
        ruleId: rule.id,
        suggestedFixLabel: 'Remplacer par une source métier lisible.',
      ),
    );
  }
}

void _diagnoseConflicts(
  List<WorldRuleDefinition> rules,
  List<WorldRuleDiagnostic> diagnostics,
) {
  final seen = <String, WorldRuleDefinition>{};
  for (final rule in rules) {
    if (!rule.enabled) {
      continue;
    }
    final key =
        '${_targetIdentity(rule.target)}|${rule.effect.kind.name}|${rule.priority}';
    final previous = seen[key];
    if (previous == null) {
      seen[key] = rule;
      continue;
    }
    diagnostics.add(
      WorldRuleDiagnostic(
        code: WorldRuleDiagnosticCode.worldRuleConflict,
        severity: WorldRuleDiagnosticSeverity.warning,
        message:
            'Plusieurs World Rules actives ciblent le même effet avec la même priorité.',
        ruleId: rule.id,
        targetId: _targetIdentity(rule.target),
        mapId: rule.target.mapId,
        suggestedFixLabel: 'Changer la priorité ou fusionner ces règles.',
      ),
    );
  }
}

WorldRuleDiagnostic _missingTarget(WorldRuleDefinition rule, String label) {
  return WorldRuleDiagnostic(
    code: WorldRuleDiagnosticCode.worldRuleTargetMissing,
    severity: WorldRuleDiagnosticSeverity.error,
    message: 'La World Rule doit choisir une $label.',
    ruleId: rule.id,
    mapId: rule.target.mapId,
    suggestedFixLabel: 'Choisir une cible existante.',
  );
}

WorldRuleDiagnostic _unknownTarget(
  WorldRuleDefinition rule,
  String targetId,
  String label,
) {
  return WorldRuleDiagnostic(
    code: WorldRuleDiagnosticCode.worldRuleTargetUnknown,
    severity: WorldRuleDiagnosticSeverity.error,
    message: 'La World Rule cible un(e) $label inconnu(e).',
    ruleId: rule.id,
    targetId: targetId,
    mapId: rule.target.mapId,
    suggestedFixLabel: 'Choisir une cible existante.',
  );
}

MapEntity? _findEntity(MapData map, String entityId) {
  for (final entity in map.entities) {
    if (entity.id == entityId) {
      return entity;
    }
  }
  return null;
}

Set<String> _storyStepIds(ProjectManifest project) {
  return {
    for (final storyline in project.storylines)
      for (final chapter in storyline.chapters)
        for (final step in chapter.steps) step.id,
  };
}

Set<String> _eventIds(List<MapData> maps) {
  return {
    for (final map in maps)
      for (final event in map.events) event.id,
  };
}

String _targetIdentity(WorldRuleTarget target) {
  return switch (target.kind) {
    WorldRuleTargetKind.mapEntity =>
      '${target.mapId}:entity:${target.entityId ?? ''}',
    WorldRuleTargetKind.npcDialogue =>
      '${target.mapId}:npcDialogue:${target.entityId ?? ''}',
    WorldRuleTargetKind.mapEvent =>
      '${target.mapId}:event:${target.eventId ?? ''}',
  };
}
```


#### packages/map_core/lib/src/projection/world_rule_projection.dart
```dart
import '../diagnostics/world_rule_diagnostics.dart';
import '../models/game_state.dart';
import '../models/map_data.dart';
import '../models/narrative_fact.dart';
import '../models/project_manifest.dart';
import '../models/world_rule.dart';

final class WorldRuleResolvedEffect {
  const WorldRuleResolvedEffect({
    required this.ruleId,
    required this.target,
    required this.effect,
    required this.priority,
  });

  final String ruleId;
  final WorldRuleTarget target;
  final WorldRuleEffect effect;
  final int priority;
}

List<WorldRuleResolvedEffect> projectWorldRuleEffects(
  ProjectManifest project,
  GameState gameState, {
  List<MapData> maps = const <MapData>[],
  String? mapId,
}) {
  final diagnostics = diagnoseWorldRules(project, maps: maps);
  final invalidRuleIds = {
    for (final diagnostic in diagnostics.diagnostics)
      if (diagnostic.severity == WorldRuleDiagnosticSeverity.error)
        diagnostic.ruleId,
  };
  final factById = {for (final fact in project.facts) fact.id: fact};
  final resolved = <WorldRuleResolvedEffect>[];
  for (final rule in project.worldRules) {
    if (!rule.enabled || invalidRuleIds.contains(rule.id)) {
      continue;
    }
    if (mapId != null && rule.target.mapId != mapId) {
      continue;
    }
    if (!_sourceMatches(rule.source, gameState, factById)) {
      continue;
    }
    resolved.add(
      WorldRuleResolvedEffect(
        ruleId: rule.id,
        target: rule.target,
        effect: rule.effect,
        priority: rule.priority,
      ),
    );
  }
  resolved.sort((a, b) {
    final byPriority = a.priority.compareTo(b.priority);
    if (byPriority != 0) {
      return byPriority;
    }
    return a.ruleId.compareTo(b.ruleId);
  });
  return List<WorldRuleResolvedEffect>.unmodifiable(resolved);
}

bool _sourceMatches(
  WorldRuleSource source,
  GameState gameState,
  Map<String, NarrativeFactDefinition> factById,
) {
  return switch (source.kind) {
    WorldRuleSourceKind.fact => _factMatches(source, gameState, factById),
    WorldRuleSourceKind.storyStepCompletion =>
      _storyStepCompletionMatches(source, gameState),
    WorldRuleSourceKind.consumedEvent =>
      _consumedEventMatches(source, gameState),
  };
}

bool _factMatches(
  WorldRuleSource source,
  GameState gameState,
  Map<String, NarrativeFactDefinition> factById,
) {
  final fact = factById[source.sourceId];
  if (fact == null) {
    return false;
  }
  final runtimeKey = fact.legacyFlagName ?? fact.id;
  final active = gameState.storyFlags.activeFlags.contains(runtimeKey) ||
      fact.defaultValue;
  return switch (source.predicate) {
    WorldRuleSourcePredicate.isTrue => active,
    WorldRuleSourcePredicate.isFalse => !active,
    WorldRuleSourcePredicate.completed ||
    WorldRuleSourcePredicate.notCompleted ||
    WorldRuleSourcePredicate.consumed ||
    WorldRuleSourcePredicate.notConsumed =>
      false,
  };
}

bool _storyStepCompletionMatches(
  WorldRuleSource source,
  GameState gameState,
) {
  final completed = gameState.progression.completedStepIds
      .map((id) => id.trim())
      .contains(source.sourceId);
  return switch (source.predicate) {
    WorldRuleSourcePredicate.completed => completed,
    WorldRuleSourcePredicate.notCompleted => !completed,
    WorldRuleSourcePredicate.isTrue ||
    WorldRuleSourcePredicate.isFalse ||
    WorldRuleSourcePredicate.consumed ||
    WorldRuleSourcePredicate.notConsumed =>
      false,
  };
}

bool _consumedEventMatches(
  WorldRuleSource source,
  GameState gameState,
) {
  final consumed = gameState.consumedEventIds.contains(source.sourceId);
  return switch (source.predicate) {
    WorldRuleSourcePredicate.consumed => consumed,
    WorldRuleSourcePredicate.notConsumed => !consumed,
    WorldRuleSourcePredicate.isTrue ||
    WorldRuleSourcePredicate.isFalse ||
    WorldRuleSourcePredicate.completed ||
    WorldRuleSourcePredicate.notCompleted =>
      false,
  };
}
```


#### packages/map_core/test/world_rule_test.dart
```dart
import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('WorldRuleDefinition', () {
    test('creates a declarative authoring rule with stable metadata', () {
      final rule = WorldRuleDefinition(
        id: 'world_rule_hide_rival',
        label: 'Masquer le rival apres combat',
        description: 'Le rival disparait quand le combat est termine.',
        enabled: false,
        source: const WorldRuleSource(
          kind: WorldRuleSourceKind.fact,
          sourceId: 'fact_rival_defeated',
          predicate: WorldRuleSourcePredicate.isTrue,
        ),
        target: const WorldRuleTarget(
          kind: WorldRuleTargetKind.mapEntity,
          mapId: 'map_port',
          entityId: 'entity_rival',
        ),
        effect: const WorldRuleEffect(
          kind: WorldRuleEffectKind.entityHidden,
        ),
        priority: 20,
        tags: const ['rival', 'port', 'rival'],
        debugTechnicalLabel: 'story_flag.rival_defeated',
      );

      expect(rule.id, 'world_rule_hide_rival');
      expect(rule.label, 'Masquer le rival apres combat');
      expect(rule.enabled, isFalse);
      expect(rule.priority, 20);
      expect(rule.tags, ['rival', 'port']);
      expect(rule.debugTechnicalLabel, 'story_flag.rival_defeated');
      expect(rule.source.sourceId, 'fact_rival_defeated');
      expect(rule.target.entityId, 'entity_rival');
      expect(rule.effect.kind, WorldRuleEffectKind.entityHidden);
    });

    test('rejects empty top-level id and label', () {
      expect(
        () => WorldRuleDefinition(
          id: ' ',
          label: 'Rule',
          source: const WorldRuleSource(
            kind: WorldRuleSourceKind.fact,
            sourceId: 'fact_known',
            predicate: WorldRuleSourcePredicate.isTrue,
          ),
          target: const WorldRuleTarget(
            kind: WorldRuleTargetKind.mapEntity,
            mapId: 'map_test',
            entityId: 'entity_test',
          ),
          effect: const WorldRuleEffect(
            kind: WorldRuleEffectKind.entityVisible,
          ),
        ),
        throwsArgumentError,
      );
      expect(
        () => WorldRuleDefinition(
          id: 'world_rule_valid',
          label: '',
          source: const WorldRuleSource(
            kind: WorldRuleSourceKind.fact,
            sourceId: 'fact_known',
            predicate: WorldRuleSourcePredicate.isTrue,
          ),
          target: const WorldRuleTarget(
            kind: WorldRuleTargetKind.mapEntity,
            mapId: 'map_test',
            entityId: 'entity_test',
          ),
          effect: const WorldRuleEffect(
            kind: WorldRuleEffectKind.entityVisible,
          ),
        ),
        throwsArgumentError,
      );
    });

    test('round-trips through JSON', () {
      final rule = WorldRuleDefinition(
        id: 'world_rule_dialogue',
        label: 'Dialogue apres etape',
        description: 'Le PNJ utilise un dialogue alternatif.',
        source: const WorldRuleSource(
          kind: WorldRuleSourceKind.storyStepCompletion,
          sourceId: 'step_intro',
          predicate: WorldRuleSourcePredicate.completed,
        ),
        target: const WorldRuleTarget(
          kind: WorldRuleTargetKind.npcDialogue,
          mapId: 'map_harbor',
          entityId: 'npc_captain',
        ),
        effect: const WorldRuleEffect(
          kind: WorldRuleEffectKind.npcDialogueOverride,
          dialogueId: 'dialogue_after_intro',
        ),
        priority: 4,
        tags: const ['dialogue'],
      );

      final json =
          jsonDecode(jsonEncode(rule.toJson())) as Map<String, dynamic>;
      final decoded = WorldRuleDefinition.fromJson(json);

      expect(decoded, equals(rule));
      expect(decoded.toJson()['id'], 'world_rule_dialogue');
      expect(decoded.toJson()['source'], isA<Map<String, dynamic>>());
      expect(decoded.toJson()['target'], isA<Map<String, dynamic>>());
      expect(decoded.toJson()['effect'], isA<Map<String, dynamic>>());
    });
  });
}
```


#### packages/map_core/test/world_rule_authoring_operations_test.dart
```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('World rule authoring operations', () {
    test('adds a world rule with stable id without mutating manifest', () {
      final manifest = _manifest(
        facts: [
          NarrativeFactDefinition(
            id: 'fact_actor_hidden',
            label: 'Acteur masque',
          ),
        ],
      );
      final map = _mapWithNpc();

      final result = addWorldRule(
        manifest,
        label: 'Masquer acteur apres fact',
        description: 'Projection visible du monde.',
        source: const WorldRuleSource(
          kind: WorldRuleSourceKind.fact,
          sourceId: 'fact_actor_hidden',
          predicate: WorldRuleSourcePredicate.isTrue,
        ),
        target: const WorldRuleTarget(
          kind: WorldRuleTargetKind.mapEntity,
          mapId: 'map_test',
          entityId: 'npc_test',
        ),
        effect: const WorldRuleEffect(
          kind: WorldRuleEffectKind.entityHidden,
        ),
        priority: 3,
        tags: const ['world', 'world'],
        maps: [map],
      );

      expect(manifest.worldRules, isEmpty);
      expect(result.createdRule.id, 'world_rule_masquer_acteur_apres_fact');
      expect(result.createdRule.label, 'Masquer acteur apres fact');
      expect(result.createdRule.priority, 3);
      expect(result.createdRule.tags, ['world']);
      expect(result.updatedProject.worldRules, [result.createdRule]);
    });

    test('adds suffixed ids on collisions and rejects empty labels', () {
      final manifest = _manifest(
        facts: [
          NarrativeFactDefinition(id: 'fact_known', label: 'Known'),
        ],
        worldRules: [
          _rule(
            id: 'world_rule_same_label',
            label: 'Same label',
          ),
        ],
      );

      final result = addWorldRule(
        manifest,
        label: 'Same label',
        source: const WorldRuleSource(
          kind: WorldRuleSourceKind.fact,
          sourceId: 'fact_known',
          predicate: WorldRuleSourcePredicate.isTrue,
        ),
        target: const WorldRuleTarget(
          kind: WorldRuleTargetKind.mapEntity,
          mapId: 'map_test',
          entityId: 'npc_test',
        ),
        effect: const WorldRuleEffect(kind: WorldRuleEffectKind.entityVisible),
        maps: [_mapWithNpc()],
      );

      expect(result.createdRule.id, 'world_rule_same_label_2');
      expect(
        () => addWorldRule(
          manifest,
          label: '   ',
          source: _factSource('fact_known'),
          target: _entityTarget,
          effect: const WorldRuleEffect(kind: WorldRuleEffectKind.entityHidden),
        ),
        throwsArgumentError,
      );
    });

    test('updates and removes a rule without mutating other project data', () {
      final existing = _rule(id: 'world_rule_existing', label: 'Existing');
      final scene = _scene();
      final manifest = _manifest(
        facts: [
          NarrativeFactDefinition(id: 'fact_known', label: 'Known'),
        ],
        scenes: [scene],
        worldRules: [existing],
      );

      final update = updateWorldRule(
        manifest,
        ruleId: existing.id,
        label: 'Updated rule',
        description: 'Updated description',
        source: _factSource('fact_known'),
        target: _entityTarget,
        effect: const WorldRuleEffect(kind: WorldRuleEffectKind.entityVisible),
        priority: 8,
        maps: [_mapWithNpc()],
      );

      expect(manifest.worldRules.single.label, 'Existing');
      expect(update.updatedRule.id, existing.id);
      expect(update.updatedRule.label, 'Updated rule');
      expect(update.updatedRule.priority, 8);
      expect(update.updatedProject.scenes, [scene]);

      final removal = removeWorldRule(
        update.updatedProject,
        ruleId: existing.id,
      );

      expect(removal.removedRule.id, existing.id);
      expect(removal.updatedProject.worldRules, isEmpty);
      expect(update.updatedProject.worldRules, [update.updatedRule]);
      expect(
        () => removeWorldRule(manifest, ruleId: 'unknown_rule'),
        throwsArgumentError,
      );
    });

    test('refuses unknown sources and structural target/effect mismatches', () {
      final manifest = _manifest();

      expect(
        () => addWorldRule(
          manifest,
          label: 'Unknown fact',
          source: _factSource('fact_missing'),
          target: _entityTarget,
          effect: const WorldRuleEffect(kind: WorldRuleEffectKind.entityHidden),
          maps: [_mapWithNpc()],
        ),
        throwsArgumentError,
      );
      expect(
        () => addWorldRule(
          _manifest(
            facts: [
              NarrativeFactDefinition(id: 'fact_known', label: 'Known'),
            ],
          ),
          label: 'Bad predicate',
          source: const WorldRuleSource(
            kind: WorldRuleSourceKind.fact,
            sourceId: 'fact_known',
            predicate: WorldRuleSourcePredicate.completed,
          ),
          target: _entityTarget,
          effect: const WorldRuleEffect(kind: WorldRuleEffectKind.entityHidden),
          maps: [_mapWithNpc()],
        ),
        throwsArgumentError,
      );
      expect(
        () => addWorldRule(
          _manifest(
            facts: [
              NarrativeFactDefinition(id: 'fact_known', label: 'Known'),
            ],
            dialogues: const [
              ProjectDialogueEntry(
                id: 'dialogue_known',
                name: 'Known',
                relativePath: 'dialogues/known.yarn',
              ),
            ],
          ),
          label: 'Mismatched effect',
          source: _factSource('fact_known'),
          target: _entityTarget,
          effect: const WorldRuleEffect(
            kind: WorldRuleEffectKind.npcDialogueOverride,
            dialogueId: 'dialogue_known',
          ),
          maps: [_mapWithNpc()],
        ),
        throwsArgumentError,
      );
    });
  });
}

ProjectManifest _manifest({
  List<NarrativeFactDefinition> facts = const [],
  List<ProjectDialogueEntry> dialogues = const [],
  List<SceneAsset> scenes = const [],
  List<WorldRuleDefinition> worldRules = const [],
}) {
  return ProjectManifest(
    name: 'World rules test',
    maps: const [
      ProjectMapEntry(
        id: 'map_test',
        name: 'Map test',
        relativePath: 'maps/map_test.json',
      ),
    ],
    tilesets: const [],
    dialogues: dialogues,
    facts: facts,
    scenes: scenes,
    worldRules: worldRules,
  );
}

MapData _mapWithNpc() {
  return const MapData(
    id: 'map_test',
    name: 'Map test',
    size: GridSize(width: 10, height: 8),
    entities: [
      MapEntity(
        id: 'npc_test',
        name: 'NPC test',
        kind: MapEntityKind.npc,
        pos: GridPos(x: 2, y: 3),
        npc: MapEntityNpcData(displayName: 'NPC test'),
      ),
    ],
    events: [
      MapEventDefinition(
        id: 'event_test',
        title: 'Event test',
        pages: [
          MapEventPage(pageNumber: 0),
        ],
        position: EventPosition(layerId: 'events', x: 1, y: 1),
      ),
    ],
  );
}

SceneAsset _scene() {
  return SceneAsset(
    id: 'scene_test',
    name: 'Scene test',
    graph: SceneGraph(
      startNodeId: 'node_start',
      nodes: [
        SceneNode(id: 'node_start', kind: SceneNodeKind.start),
        SceneNode(id: 'node_end', kind: SceneNodeKind.end),
      ],
      edges: const [],
    ),
  );
}

WorldRuleDefinition _rule({
  required String id,
  required String label,
}) {
  return WorldRuleDefinition(
    id: id,
    label: label,
    source: _factSource('fact_known'),
    target: _entityTarget,
    effect: const WorldRuleEffect(kind: WorldRuleEffectKind.entityHidden),
  );
}

WorldRuleSource _factSource(String factId) {
  return WorldRuleSource(
    kind: WorldRuleSourceKind.fact,
    sourceId: factId,
    predicate: WorldRuleSourcePredicate.isTrue,
  );
}

const WorldRuleTarget _entityTarget = WorldRuleTarget(
  kind: WorldRuleTargetKind.mapEntity,
  mapId: 'map_test',
  entityId: 'npc_test',
);
```


#### packages/map_core/test/project_manifest_world_rules_test.dart
```dart
import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectManifest worldRules integration', () {
    test('decodes absent null and empty worldRules as empty list', () {
      expect(
          ProjectManifest.fromJson(_minimalProjectJson()).worldRules, isEmpty);
      expect(
        ProjectManifest.fromJson({
          ..._minimalProjectJson(),
          'worldRules': null,
        }).worldRules,
        isEmpty,
      );
      expect(
        ProjectManifest.fromJson({
          ..._minimalProjectJson(),
          'worldRules': <Object?>[],
        }).worldRules,
        isEmpty,
      );
    });

    test('round-trips world rules through ProjectManifest JSON', () {
      final manifest = ProjectManifest(
        name: 'Project',
        maps: const [],
        tilesets: const [],
        worldRules: [
          WorldRuleDefinition(
            id: 'world_rule_hide_actor',
            label: 'Masquer un acteur',
            source: const WorldRuleSource(
              kind: WorldRuleSourceKind.fact,
              sourceId: 'fact_actor_hidden',
              predicate: WorldRuleSourcePredicate.isTrue,
            ),
            target: const WorldRuleTarget(
              kind: WorldRuleTargetKind.mapEntity,
              mapId: 'map_test',
              entityId: 'entity_actor',
            ),
            effect: const WorldRuleEffect(
              kind: WorldRuleEffectKind.entityHidden,
            ),
          ),
        ],
      );

      final json =
          jsonDecode(jsonEncode(manifest.toJson())) as Map<String, dynamic>;
      final decoded = ProjectManifest.fromJson(json);

      expect(decoded.worldRules, equals(manifest.worldRules));
      expect(decoded.toJson()['worldRules'], isA<List<dynamic>>());
      expect((decoded.toJson()['worldRules'] as List).single['label'],
          'Masquer un acteur');
    });

    test('rejects invalid worldRules JSON shape', () {
      expect(
        () => ProjectManifest.fromJson({
          ..._minimalProjectJson(),
          'worldRules': 'not-a-list',
        }),
        throwsA(isA<Object>()),
      );
      expect(
        () => ProjectManifest.fromJson({
          ..._minimalProjectJson(),
          'worldRules': ['not-an-object'],
        }),
        throwsA(isA<Object>()),
      );
    });
  });
}

Map<String, dynamic> _minimalProjectJson() {
  return {
    'name': 'Project',
    'maps': <Object?>[],
    'tilesets': <Object?>[],
  };
}
```


#### packages/map_core/test/world_rule_diagnostics_test.dart
```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('World rule diagnostics', () {
    test('reports unknown source and unknown target references', () {
      final project = _manifest(
        worldRules: [
          WorldRuleDefinition(
            id: 'world_rule_unknown_refs',
            label: 'Unknown refs',
            source: const WorldRuleSource(
              kind: WorldRuleSourceKind.fact,
              sourceId: 'fact_missing',
              predicate: WorldRuleSourcePredicate.isTrue,
            ),
            target: const WorldRuleTarget(
              kind: WorldRuleTargetKind.mapEntity,
              mapId: 'map_test',
              entityId: 'entity_missing',
            ),
            effect: const WorldRuleEffect(
              kind: WorldRuleEffectKind.entityHidden,
            ),
          ),
        ],
      );

      final report = diagnoseWorldRules(project, maps: [_mapWithNpc()]);

      expect(report.hasErrors, isTrue);
      expect(
        report.byCode(WorldRuleDiagnosticCode.worldRuleSourceUnknown),
        hasLength(1),
      );
      expect(
        report.byCode(WorldRuleDiagnosticCode.worldRuleTargetUnknown),
        hasLength(1),
      );
    });

    test('reports effect target mismatch and raw technical labels', () {
      final project = _manifest(
        facts: [
          NarrativeFactDefinition(id: 'fact_known', label: 'Known'),
        ],
        dialogues: const [
          ProjectDialogueEntry(
            id: 'dialogue_known',
            name: 'Known',
            relativePath: 'dialogues/known.yarn',
          ),
        ],
        worldRules: [
          WorldRuleDefinition(
            id: 'world_rule_raw',
            label: 'world_rule_raw',
            debugTechnicalLabel: 'ScriptCondition(flag: fact_known)',
            source: const WorldRuleSource(
              kind: WorldRuleSourceKind.fact,
              sourceId: 'fact_known',
              predicate: WorldRuleSourcePredicate.isTrue,
            ),
            target: const WorldRuleTarget(
              kind: WorldRuleTargetKind.mapEntity,
              mapId: 'map_test',
              entityId: 'npc_test',
            ),
            effect: const WorldRuleEffect(
              kind: WorldRuleEffectKind.npcDialogueOverride,
              dialogueId: 'dialogue_known',
            ),
          ),
        ],
      );

      final report = diagnoseWorldRules(project, maps: [_mapWithNpc()]);

      expect(report.hasErrors, isTrue);
      expect(
        report.byCode(WorldRuleDiagnosticCode.worldRuleEffectTargetMismatch),
        hasLength(1),
      );
      expect(
        report.byCode(WorldRuleDiagnosticCode.worldRuleUsesRawTechnicalId),
        hasLength(1),
      );
      expect(
        report.byCode(WorldRuleDiagnosticCode.worldRuleLegacyPredicateLeak),
        hasLength(1),
      );
    });

    test('reports unsupported predicates and conflicting same target priority',
        () {
      final first = _validRule(
        id: 'world_rule_first',
        label: 'First',
      );
      final second = _validRule(
        id: 'world_rule_second',
        label: 'Second',
      );
      final project = _manifest(
        facts: [
          NarrativeFactDefinition(id: 'fact_known', label: 'Known'),
        ],
        worldRules: [
          first,
          second,
          WorldRuleDefinition(
            id: 'world_rule_bad_predicate',
            label: 'Bad predicate',
            source: const WorldRuleSource(
              kind: WorldRuleSourceKind.fact,
              sourceId: 'fact_known',
              predicate: WorldRuleSourcePredicate.completed,
            ),
            target: const WorldRuleTarget(
              kind: WorldRuleTargetKind.mapEntity,
              mapId: 'map_test',
              entityId: 'npc_test',
            ),
            effect: const WorldRuleEffect(
              kind: WorldRuleEffectKind.entityVisible,
            ),
          ),
        ],
      );

      final report = diagnoseWorldRules(project, maps: [_mapWithNpc()]);

      expect(
        report.byCode(WorldRuleDiagnosticCode.worldRuleSourceUnsupported),
        hasLength(1),
      );
      expect(
        report.byCode(WorldRuleDiagnosticCode.worldRuleConflict),
        isNotEmpty,
      );
      expect(report.warningCount, greaterThanOrEqualTo(1));
    });
  });
}

ProjectManifest _manifest({
  List<NarrativeFactDefinition> facts = const [],
  List<ProjectDialogueEntry> dialogues = const [],
  List<WorldRuleDefinition> worldRules = const [],
}) {
  return ProjectManifest(
    name: 'Diagnostics project',
    maps: const [
      ProjectMapEntry(
        id: 'map_test',
        name: 'Map test',
        relativePath: 'maps/map_test.json',
      ),
    ],
    tilesets: const [],
    dialogues: dialogues,
    facts: facts,
    worldRules: worldRules,
  );
}

MapData _mapWithNpc() {
  return const MapData(
    id: 'map_test',
    name: 'Map test',
    size: GridSize(width: 10, height: 8),
    entities: [
      MapEntity(
        id: 'npc_test',
        name: 'NPC test',
        kind: MapEntityKind.npc,
        pos: GridPos(x: 2, y: 3),
        npc: MapEntityNpcData(displayName: 'NPC test'),
      ),
    ],
    events: [
      MapEventDefinition(
        id: 'event_test',
        title: 'Event test',
        pages: [
          MapEventPage(pageNumber: 0),
        ],
        position: EventPosition(layerId: 'events', x: 1, y: 1),
      ),
    ],
  );
}

WorldRuleDefinition _validRule({
  required String id,
  required String label,
}) {
  return WorldRuleDefinition(
    id: id,
    label: label,
    source: const WorldRuleSource(
      kind: WorldRuleSourceKind.fact,
      sourceId: 'fact_known',
      predicate: WorldRuleSourcePredicate.isTrue,
    ),
    target: const WorldRuleTarget(
      kind: WorldRuleTargetKind.mapEntity,
      mapId: 'map_test',
      entityId: 'npc_test',
    ),
    effect: const WorldRuleEffect(kind: WorldRuleEffectKind.entityVisible),
  );
}
```


#### packages/map_core/test/world_rule_projection_test.dart
```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('World rule projection', () {
    test('projects enabled matching fact rules without mutating inputs', () {
      final project = _manifest(
        facts: [
          NarrativeFactDefinition(id: 'fact_known', label: 'Known'),
        ],
        worldRules: [
          _entityRule(
            id: 'world_rule_hide',
            effect: const WorldRuleEffect(
              kind: WorldRuleEffectKind.entityHidden,
            ),
          ),
          _entityRule(
            id: 'world_rule_disabled',
            enabled: false,
            effect: const WorldRuleEffect(
              kind: WorldRuleEffectKind.entityVisible,
            ),
          ),
        ],
      );
      final state = GameState(
        saveId: 'save',
        storyFlags: const StoryFlags(activeFlags: {'fact_known'}),
      );

      final effects = projectWorldRuleEffects(
        project,
        state,
        maps: [_mapWithNpc()],
        mapId: 'map_test',
      );

      expect(effects, hasLength(1));
      expect(effects.single.ruleId, 'world_rule_hide');
      expect(effects.single.effect.kind, WorldRuleEffectKind.entityHidden);
      expect(project.worldRules, hasLength(2));
      expect(state.storyFlags.activeFlags, {'fact_known'});
    });

    test('supports story step completion and consumed event sources', () {
      final project = _manifest(
        storylines: [
          StorylineAsset(
            id: 'storyline_test',
            type: StorylineType.main,
            title: 'Storyline test',
            chapters: [
              StorylineChapter(
                id: 'chapter_test',
                title: 'Chapter test',
                order: 0,
                steps: [
                  StorylineStep(
                    id: 'step_intro',
                    title: 'Intro',
                    order: 0,
                  ),
                ],
              ),
            ],
          ),
        ],
        worldRules: [
          _eventRule(
            id: 'world_rule_step',
            source: const WorldRuleSource(
              kind: WorldRuleSourceKind.storyStepCompletion,
              sourceId: 'step_intro',
              predicate: WorldRuleSourcePredicate.completed,
            ),
            effect: const WorldRuleEffect(
              kind: WorldRuleEffectKind.eventEnabled,
            ),
          ),
          _eventRule(
            id: 'world_rule_consumed',
            source: const WorldRuleSource(
              kind: WorldRuleSourceKind.consumedEvent,
              sourceId: 'event_test',
              predicate: WorldRuleSourcePredicate.consumed,
            ),
            effect: const WorldRuleEffect(
              kind: WorldRuleEffectKind.eventHidden,
            ),
            priority: 2,
          ),
        ],
      );
      final state = GameState(
        saveId: 'save',
        progression: const PlayerProgression(
          completedStepIds: ['step_intro'],
        ),
        consumedEventIds: const {'event_test'},
      );

      final effects = projectWorldRuleEffects(
        project,
        state,
        maps: [_mapWithNpc()],
      );

      expect(
        effects.map((effect) => effect.ruleId),
        ['world_rule_step', 'world_rule_consumed'],
      );
      expect(
        effects.map((effect) => effect.effect.kind),
        [
          WorldRuleEffectKind.eventEnabled,
          WorldRuleEffectKind.eventHidden,
        ],
      );
    });

    test('skips invalid rules with diagnostic errors', () {
      final project = _manifest(
        facts: [
          NarrativeFactDefinition(id: 'fact_known', label: 'Known'),
        ],
        worldRules: [
          _entityRule(
            id: 'world_rule_valid',
            effect: const WorldRuleEffect(
              kind: WorldRuleEffectKind.entityVisible,
            ),
          ),
          WorldRuleDefinition(
            id: 'world_rule_invalid',
            label: 'Invalid',
            source: const WorldRuleSource(
              kind: WorldRuleSourceKind.fact,
              sourceId: 'fact_missing',
              predicate: WorldRuleSourcePredicate.isTrue,
            ),
            target: const WorldRuleTarget(
              kind: WorldRuleTargetKind.mapEntity,
              mapId: 'map_test',
              entityId: 'npc_test',
            ),
            effect: const WorldRuleEffect(
              kind: WorldRuleEffectKind.entityHidden,
            ),
          ),
        ],
      );
      final state = GameState(
        saveId: 'save',
        storyFlags: const StoryFlags(activeFlags: {'fact_known'}),
      );

      final effects = projectWorldRuleEffects(
        project,
        state,
        maps: [_mapWithNpc()],
      );

      expect(effects.map((effect) => effect.ruleId), ['world_rule_valid']);
    });
  });
}

ProjectManifest _manifest({
  List<NarrativeFactDefinition> facts = const [],
  List<StorylineAsset> storylines = const [],
  List<WorldRuleDefinition> worldRules = const [],
}) {
  return ProjectManifest(
    name: 'Projection project',
    maps: const [
      ProjectMapEntry(
        id: 'map_test',
        name: 'Map test',
        relativePath: 'maps/map_test.json',
      ),
    ],
    tilesets: const [],
    facts: facts,
    storylines: storylines,
    worldRules: worldRules,
  );
}

MapData _mapWithNpc() {
  return const MapData(
    id: 'map_test',
    name: 'Map test',
    size: GridSize(width: 10, height: 8),
    entities: [
      MapEntity(
        id: 'npc_test',
        name: 'NPC test',
        kind: MapEntityKind.npc,
        pos: GridPos(x: 2, y: 3),
        npc: MapEntityNpcData(displayName: 'NPC test'),
      ),
    ],
    events: [
      MapEventDefinition(
        id: 'event_test',
        title: 'Event test',
        pages: [
          MapEventPage(pageNumber: 0),
        ],
        position: EventPosition(layerId: 'events', x: 1, y: 1),
      ),
    ],
  );
}

WorldRuleDefinition _entityRule({
  required String id,
  bool enabled = true,
  required WorldRuleEffect effect,
}) {
  return WorldRuleDefinition(
    id: id,
    label: id,
    enabled: enabled,
    source: const WorldRuleSource(
      kind: WorldRuleSourceKind.fact,
      sourceId: 'fact_known',
      predicate: WorldRuleSourcePredicate.isTrue,
    ),
    target: const WorldRuleTarget(
      kind: WorldRuleTargetKind.mapEntity,
      mapId: 'map_test',
      entityId: 'npc_test',
    ),
    effect: effect,
  );
}

WorldRuleDefinition _eventRule({
  required String id,
  required WorldRuleSource source,
  required WorldRuleEffect effect,
  int priority = 0,
}) {
  return WorldRuleDefinition(
    id: id,
    label: id,
    source: source,
    target: const WorldRuleTarget(
      kind: WorldRuleTargetKind.mapEvent,
      mapId: 'map_test',
      eventId: 'event_test',
    ),
    effect: effect,
    priority: priority,
  );
}
```


#### reports/narrativeStudio/scenes/ns_scenes_v1_20_world_rules_v0.md
Le contenu complet du rapport est le present fichier Markdown.


#### reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_20_world_rules_v0.png
Fichier binaire PNG produit par le visual gate. Chemin absolu : `/Users/karim/Project/pokemonProject/reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_20_world_rules_v0.png`.


### Sections completes modifiees et diffs


#### Diff complet — packages/map_core/lib/map_core.dart
```text
diff --git a/packages/map_core/lib/map_core.dart b/packages/map_core/lib/map_core.dart
index 193a6d17..8555f81b 100644
--- a/packages/map_core/lib/map_core.dart
+++ b/packages/map_core/lib/map_core.dart
@@ -28,6 +28,7 @@ export 'src/models/project_trainer.dart';
 export 'src/models/scenario_asset.dart';
 export 'src/models/scene_asset.dart';
 export 'src/models/storyline_asset.dart';
+export 'src/models/world_rule.dart';
 export 'src/models/visual_frame_json.dart';
 export 'src/models/shadow.dart';
 export 'src/models/shadow_catalog.dart';
@@ -74,6 +75,7 @@ export 'src/operations/surface_catalog_authoring_diagnostics.dart';
 export 'src/operations/surface_catalog_diagnostics_summary.dart';
 export 'src/operations/surface_catalog_diagnostics_presentation.dart';
 export 'src/diagnostics/scene_diagnostics.dart';
+export 'src/diagnostics/world_rule_diagnostics.dart';
 export 'src/operations/narrative_validator.dart';
 export 'src/authoring/narrative_event_source_authoring_operations.dart';
 export 'src/authoring/narrative_fact_authoring_operations.dart';
@@ -81,9 +83,11 @@ export 'src/authoring/narrative_outcome_authoring_operations.dart';
 export 'src/authoring/narrative_predicate_authoring_draft.dart';
 export 'src/authoring/narrative_scenario_authoring_draft.dart';
 export 'src/authoring/scene_authoring_operations.dart';
+export 'src/authoring/world_rule_authoring_operations.dart';
 export 'src/authoring/narrative_validator_authoring_adapter.dart';
 export 'src/authoring/storyline_legacy_import_preview.dart';
 export 'src/read_models/narrative_reference_picker_read_models.dart';
+export 'src/projection/world_rule_projection.dart';
 export 'src/operations/static_shadow_geometry.dart';
 export 'src/operations/static_shadow_family_projection.dart';
 export 'src/operations/static_shadow_projection_geometry.dart';
```


#### Diff complet — packages/map_core/lib/src/models/project_manifest.dart
```text
diff --git a/packages/map_core/lib/src/models/project_manifest.dart b/packages/map_core/lib/src/models/project_manifest.dart
index 6ab0c91b..a5bd2048 100644
--- a/packages/map_core/lib/src/models/project_manifest.dart
+++ b/packages/map_core/lib/src/models/project_manifest.dart
@@ -17,6 +17,7 @@ import 'storyline_asset.dart';
 import 'surface_catalog.dart';
 import 'tileset_transparent_color.dart';
 import 'visual_frame_json.dart';
+import 'world_rule.dart';
 
 import '../exceptions/map_exceptions.dart';
 import '../operations/environment_preset_json_codec.dart';
@@ -152,6 +153,41 @@ Map<String, dynamic> _factJsonObject(Object? json) {
   });
 }
 
+/// JSON -> authoring World Rules.
+///
+/// Missing or `null` keeps old projects readable as an empty list. This does
+/// not convert legacy map predicates or script conditions automatically.
+List<WorldRuleDefinition> _worldRulesFromJson(Object? json) {
+  if (json == null) {
+    return const <WorldRuleDefinition>[];
+  }
+  if (json is! List) {
+    throw const ValidationException('worldRules must be a JSON list');
+  }
+  return [
+    for (final item in json)
+      WorldRuleDefinition.fromJson(_worldRuleJsonObject(item)),
+  ];
+}
+
+List<Map<String, dynamic>> _worldRulesToJson(
+  List<WorldRuleDefinition> worldRules,
+) {
+  return [for (final rule in worldRules) rule.toJson()];
+}
+
+Map<String, dynamic> _worldRuleJsonObject(Object? json) {
+  if (json is! Map) {
+    throw const ValidationException('worldRule must be a JSON object');
+  }
+  return json.map((key, value) {
+    if (key is! String) {
+      throw const ValidationException('worldRule JSON keys must be strings');
+    }
+    return MapEntry(key, value);
+  });
+}
+
 /// JSON -> ShadowV2 projected building shadow catalog.
 ///
 /// Missing or `null` root data remains an empty in-memory catalog. When the
@@ -278,6 +314,13 @@ class ProjectManifest with _$ProjectManifest {
     )
     List<NarrativeFactDefinition> facts,
     @Default([])
+    @JsonKey(
+      name: 'worldRules',
+      fromJson: _worldRulesFromJson,
+      toJson: _worldRulesToJson,
+    )
+    List<WorldRuleDefinition> worldRules,
+    @Default([])
     @JsonKey(
       name: 'scenes',
       fromJson: _scenesFromJson,
```


#### Diff complet — packages/map_core/lib/src/models/project_manifest.freezed.dart
```text
diff --git a/packages/map_core/lib/src/models/project_manifest.freezed.dart b/packages/map_core/lib/src/models/project_manifest.freezed.dart
index 923ca1dd..90d7ddf4 100644
--- a/packages/map_core/lib/src/models/project_manifest.freezed.dart
+++ b/packages/map_core/lib/src/models/project_manifest.freezed.dart
@@ -59,6 +59,12 @@ mixin _$ProjectManifest {
   List<ScenarioAsset> get scenarios => throw _privateConstructorUsedError;
   @JsonKey(name: 'facts', fromJson: _factsFromJson, toJson: _factsToJson)
   List<NarrativeFactDefinition> get facts => throw _privateConstructorUsedError;
+  @JsonKey(
+      name: 'worldRules',
+      fromJson: _worldRulesFromJson,
+      toJson: _worldRulesToJson)
+  List<WorldRuleDefinition> get worldRules =>
+      throw _privateConstructorUsedError;
   @JsonKey(name: 'scenes', fromJson: _scenesFromJson, toJson: _scenesToJson)
   List<SceneAsset> get scenes => throw _privateConstructorUsedError;
   @JsonKey(
@@ -135,6 +141,11 @@ abstract class $ProjectManifestCopyWith<$Res> {
       List<ScenarioAsset> scenarios,
       @JsonKey(name: 'facts', fromJson: _factsFromJson, toJson: _factsToJson)
       List<NarrativeFactDefinition> facts,
+      @JsonKey(
+          name: 'worldRules',
+          fromJson: _worldRulesFromJson,
+          toJson: _worldRulesToJson)
+      List<WorldRuleDefinition> worldRules,
       @JsonKey(name: 'scenes', fromJson: _scenesFromJson, toJson: _scenesToJson)
       List<SceneAsset> scenes,
       @JsonKey(
@@ -199,6 +210,7 @@ class _$ProjectManifestCopyWithImpl<$Res, $Val extends ProjectManifest>
     Object? scripts = null,
     Object? scenarios = null,
     Object? facts = null,
+    Object? worldRules = null,
     Object? scenes = null,
     Object? storylines = null,
     Object? trainers = null,
@@ -291,6 +303,10 @@ class _$ProjectManifestCopyWithImpl<$Res, $Val extends ProjectManifest>
           ? _value.facts
           : facts // ignore: cast_nullable_to_non_nullable
               as List<NarrativeFactDefinition>,
+      worldRules: null == worldRules
+          ? _value.worldRules
+          : worldRules // ignore: cast_nullable_to_non_nullable
+              as List<WorldRuleDefinition>,
       scenes: null == scenes
           ? _value.scenes
           : scenes // ignore: cast_nullable_to_non_nullable
@@ -393,6 +409,11 @@ abstract class _$$ProjectManifestImplCopyWith<$Res>
       List<ScenarioAsset> scenarios,
       @JsonKey(name: 'facts', fromJson: _factsFromJson, toJson: _factsToJson)
       List<NarrativeFactDefinition> facts,
+      @JsonKey(
+          name: 'worldRules',
+          fromJson: _worldRulesFromJson,
+          toJson: _worldRulesToJson)
+      List<WorldRuleDefinition> worldRules,
       @JsonKey(name: 'scenes', fromJson: _scenesFromJson, toJson: _scenesToJson)
       List<SceneAsset> scenes,
       @JsonKey(
@@ -457,6 +478,7 @@ class __$$ProjectManifestImplCopyWithImpl<$Res>
     Object? scripts = null,
     Object? scenarios = null,
     Object? facts = null,
+    Object? worldRules = null,
     Object? scenes = null,
     Object? storylines = null,
     Object? trainers = null,
@@ -549,6 +571,10 @@ class __$$ProjectManifestImplCopyWithImpl<$Res>
           ? _value._facts
           : facts // ignore: cast_nullable_to_non_nullable
               as List<NarrativeFactDefinition>,
+      worldRules: null == worldRules
+          ? _value._worldRules
+          : worldRules // ignore: cast_nullable_to_non_nullable
+              as List<WorldRuleDefinition>,
       scenes: null == scenes
           ? _value._scenes
           : scenes // ignore: cast_nullable_to_non_nullable
@@ -627,6 +653,8 @@ class _$ProjectManifestImpl implements _ProjectManifest {
       final List<ScenarioAsset> scenarios = const [],
       @JsonKey(name: 'facts', fromJson: _factsFromJson, toJson: _factsToJson)
       final List<NarrativeFactDefinition> facts = const [],
+      @JsonKey(name: 'worldRules', fromJson: _worldRulesFromJson, toJson: _worldRulesToJson)
+      final List<WorldRuleDefinition> worldRules = const [],
       @JsonKey(name: 'scenes', fromJson: _scenesFromJson, toJson: _scenesToJson)
       final List<SceneAsset> scenes = const [],
       @JsonKey(name: 'storylines', fromJson: _storylinesFromJson, toJson: _storylinesToJson)
@@ -648,8 +676,7 @@ class _$ProjectManifestImpl implements _ProjectManifest {
           fromJson: _projectedBuildingShadowCatalogFromJson,
           toJson: _projectedBuildingShadowCatalogToJson,
           includeIfNull: false)
-      this.projectedBuildingShadowCatalog =
-          const ProjectBuildingShadowPresetCatalog.empty()})
+      this.projectedBuildingShadowCatalog = const ProjectBuildingShadowPresetCatalog.empty()})
       : _maps = maps,
         _groups = groups,
         _tilesetFolders = tilesetFolders,
@@ -668,6 +695,7 @@ class _$ProjectManifestImpl implements _ProjectManifest {
         _scripts = scripts,
         _scenarios = scenarios,
         _facts = facts,
+        _worldRules = worldRules,
         _scenes = scenes,
         _storylines = storylines,
         _trainers = trainers,
@@ -852,6 +880,18 @@ class _$ProjectManifestImpl implements _ProjectManifest {
     return EqualUnmodifiableListView(_facts);
   }
 
+  final List<WorldRuleDefinition> _worldRules;
+  @override
+  @JsonKey(
+      name: 'worldRules',
+      fromJson: _worldRulesFromJson,
+      toJson: _worldRulesToJson)
+  List<WorldRuleDefinition> get worldRules {
+    if (_worldRules is EqualUnmodifiableListView) return _worldRules;
+    // ignore: implicit_dynamic_type
+    return EqualUnmodifiableListView(_worldRules);
+  }
+
   final List<SceneAsset> _scenes;
   @override
   @JsonKey(name: 'scenes', fromJson: _scenesFromJson, toJson: _scenesToJson)
@@ -926,7 +966,7 @@ class _$ProjectManifestImpl implements _ProjectManifest {
 
   @override
   String toString() {
-    return 'ProjectManifest(name: $name, version: $version, maps: $maps, groups: $groups, tilesetFolders: $tilesetFolders, tilesets: $tilesets, elementCategories: $elementCategories, elements: $elements, terrainCategories: $terrainCategories, pathCategories: $pathCategories, terrainPresets: $terrainPresets, pathPresets: $pathPresets, pathPatternPresets: $pathPatternPresets, environmentPresets: $environmentPresets, encounterTables: $encounterTables, dialogueFolders: $dialogueFolders, dialogues: $dialogues, scripts: $scripts, scenarios: $scenarios, facts: $facts, scenes: $scenes, storylines: $storylines, trainers: $trainers, characters: $characters, settings: $settings, pokemon: $pokemon, globalProperties: $globalProperties, surfaceCatalog: $surfaceCatalog, shadowCatalog: $shadowCatalog, projectedBuildingShadowCatalog: $projectedBuildingShadowCatalog)';
+    return 'ProjectManifest(name: $name, version: $version, maps: $maps, groups: $groups, tilesetFolders: $tilesetFolders, tilesets: $tilesets, elementCategories: $elementCategories, elements: $elements, terrainCategories: $terrainCategories, pathCategories: $pathCategories, terrainPresets: $terrainPresets, pathPresets: $pathPresets, pathPatternPresets: $pathPatternPresets, environmentPresets: $environmentPresets, encounterTables: $encounterTables, dialogueFolders: $dialogueFolders, dialogues: $dialogues, scripts: $scripts, scenarios: $scenarios, facts: $facts, worldRules: $worldRules, scenes: $scenes, storylines: $storylines, trainers: $trainers, characters: $characters, settings: $settings, pokemon: $pokemon, globalProperties: $globalProperties, surfaceCatalog: $surfaceCatalog, shadowCatalog: $shadowCatalog, projectedBuildingShadowCatalog: $projectedBuildingShadowCatalog)';
   }
 
   @override
@@ -966,6 +1006,8 @@ class _$ProjectManifestImpl implements _ProjectManifest {
             const DeepCollectionEquality()
                 .equals(other._scenarios, _scenarios) &&
             const DeepCollectionEquality().equals(other._facts, _facts) &&
+            const DeepCollectionEquality()
+                .equals(other._worldRules, _worldRules) &&
             const DeepCollectionEquality().equals(other._scenes, _scenes) &&
             const DeepCollectionEquality()
                 .equals(other._storylines, _storylines) &&
@@ -1011,6 +1053,7 @@ class _$ProjectManifestImpl implements _ProjectManifest {
         const DeepCollectionEquality().hash(_scripts),
         const DeepCollectionEquality().hash(_scenarios),
         const DeepCollectionEquality().hash(_facts),
+        const DeepCollectionEquality().hash(_worldRules),
         const DeepCollectionEquality().hash(_scenes),
         const DeepCollectionEquality().hash(_storylines),
         const DeepCollectionEquality().hash(_trainers),
@@ -1071,6 +1114,11 @@ abstract class _ProjectManifest implements ProjectManifest {
       final List<ScenarioAsset> scenarios,
       @JsonKey(name: 'facts', fromJson: _factsFromJson, toJson: _factsToJson)
       final List<NarrativeFactDefinition> facts,
+      @JsonKey(
+          name: 'worldRules',
+          fromJson: _worldRulesFromJson,
+          toJson: _worldRulesToJson)
+      final List<WorldRuleDefinition> worldRules,
       @JsonKey(name: 'scenes', fromJson: _scenesFromJson, toJson: _scenesToJson)
       final List<SceneAsset> scenes,
       @JsonKey(
@@ -1151,6 +1199,12 @@ abstract class _ProjectManifest implements ProjectManifest {
   @JsonKey(name: 'facts', fromJson: _factsFromJson, toJson: _factsToJson)
   List<NarrativeFactDefinition> get facts;
   @override
+  @JsonKey(
+      name: 'worldRules',
+      fromJson: _worldRulesFromJson,
+      toJson: _worldRulesToJson)
+  List<WorldRuleDefinition> get worldRules;
+  @override
   @JsonKey(name: 'scenes', fromJson: _scenesFromJson, toJson: _scenesToJson)
   List<SceneAsset> get scenes;
   @override
```


#### Diff complet — packages/map_core/lib/src/models/project_manifest.g.dart
```text
diff --git a/packages/map_core/lib/src/models/project_manifest.g.dart b/packages/map_core/lib/src/models/project_manifest.g.dart
index 9a96ecf3..9128ae77 100644
--- a/packages/map_core/lib/src/models/project_manifest.g.dart
+++ b/packages/map_core/lib/src/models/project_manifest.g.dart
@@ -88,6 +88,9 @@ _$ProjectManifestImpl _$$ProjectManifestImplFromJson(
               .toList() ??
           const [],
       facts: json['facts'] == null ? const [] : _factsFromJson(json['facts']),
+      worldRules: json['worldRules'] == null
+          ? const []
+          : _worldRulesFromJson(json['worldRules']),
       scenes:
           json['scenes'] == null ? const [] : _scenesFromJson(json['scenes']),
       storylines: json['storylines'] == null
@@ -155,6 +158,7 @@ Map<String, dynamic> _$$ProjectManifestImplToJson(
       'scripts': instance.scripts.map((e) => e.toJson()).toList(),
       'scenarios': instance.scenarios.map((e) => e.toJson()).toList(),
       'facts': _factsToJson(instance.facts),
+      'worldRules': _worldRulesToJson(instance.worldRules),
       'scenes': _scenesToJson(instance.scenes),
       'storylines': _storylinesToJson(instance.storylines),
       'trainers': instance.trainers.map((e) => e.toJson()).toList(),
```


#### Diff complet — packages/map_editor/lib/src/features/narrative/application/overview/narrative_overview_read_model.dart
```text
diff --git a/packages/map_editor/lib/src/features/narrative/application/overview/narrative_overview_read_model.dart b/packages/map_editor/lib/src/features/narrative/application/overview/narrative_overview_read_model.dart
index 1ce01b2e..1140e7e7 100644
--- a/packages/map_editor/lib/src/features/narrative/application/overview/narrative_overview_read_model.dart
+++ b/packages/map_editor/lib/src/features/narrative/application/overview/narrative_overview_read_model.dart
@@ -216,6 +216,7 @@ class NarrativeModuleSummary {
     required this.emptyStateMessage,
     required this.destination,
     this.secondaryStats = const <NarrativeMetricSummary>[],
+    this.previewLabels = const <String>[],
   });
 
   final String id;
@@ -226,6 +227,7 @@ class NarrativeModuleSummary {
   final String emptyStateMessage;
   final String? destination;
   final List<NarrativeMetricSummary> secondaryStats;
+  final List<String> previewLabels;
 }
 
 class NarrativeStructureInspectorSummary {
@@ -335,6 +337,7 @@ NarrativeOverviewReadModel buildNarrativeOverviewReadModel({
   final allSteps = allStepContexts
       .expand((context) => context.stepDocument.steps)
       .toList(growable: false);
+  final worldRuleDiagnostics = diagnoseWorldRules(project);
   final validation = _buildEditorialStatus(
     narrativeValidationReport: narrativeValidationReport,
     authoringDiagnostics: authoringDiagnostics,
@@ -383,8 +386,8 @@ NarrativeOverviewReadModel buildNarrativeOverviewReadModel({
   final worldRules = _metricWithCount(
     id: 'world_rules',
     label: 'Règles du monde',
-    count: _countWorldRules(allSteps),
-    emptyStateMessage: 'Aucune règle du monde définie.',
+    count: project.worldRules.length,
+    emptyStateMessage: 'Aucune World Rule authorée.',
     unavailableMessage: 'Règles du monde indisponibles.',
   );
   final openIssues = validation.notEvaluated
@@ -445,7 +448,13 @@ NarrativeOverviewReadModel buildNarrativeOverviewReadModel({
     ),
   );
 
-  final modules = _buildModules(metrics);
+  final modules = _buildModules(
+    metrics,
+    worldRuleDiagnostics: worldRuleDiagnostics,
+    worldRulePreviewLabels: [
+      for (final rule in project.worldRules.take(3)) rule.label,
+    ],
+  );
   final projectHealth = _buildProjectHealth(validation, metrics);
   final structureInspector = _buildStructureInspector(
     project: project,
@@ -801,13 +810,6 @@ bool _completionHasDependency(StepStudioCompletionRule completion) {
   };
 }
 
-int _countWorldRules(List<StepStudioStep> steps) {
-  return steps.fold<int>(
-    0,
-    (sum, step) => sum + step.worldChanges.length,
-  );
-}
-
 Set<String> _collectDialogueIdsFromScenarios({
   required ProjectManifest project,
   required Set<String> scenarioIds,
@@ -956,7 +958,11 @@ NarrativeChapterEditorialStatus _chapterStatusFor(
   return NarrativeChapterEditorialStatus.defined;
 }
 
-List<NarrativeModuleSummary> _buildModules(NarrativeOverviewMetrics metrics) {
+List<NarrativeModuleSummary> _buildModules(
+  NarrativeOverviewMetrics metrics, {
+  required WorldRuleDiagnosticsReport worldRuleDiagnostics,
+  required List<String> worldRulePreviewLabels,
+}) {
   return <NarrativeModuleSummary>[
     const NarrativeModuleSummary(
       id: NarrativeOverviewModuleIds.quests,
@@ -1004,6 +1010,10 @@ List<NarrativeModuleSummary> _buildModules(NarrativeOverviewMetrics metrics) {
       availability: metrics.worldRules.availability,
       emptyStateMessage: metrics.worldRules.emptyStateMessage,
       destination: 'step_studio',
+      secondaryStats: <NarrativeMetricSummary>[
+        _worldRuleDiagnosticsMetric(worldRuleDiagnostics),
+      ],
+      previewLabels: worldRulePreviewLabels,
     ),
     const NarrativeModuleSummary(
       id: NarrativeOverviewModuleIds.facts,
@@ -1018,6 +1028,25 @@ List<NarrativeModuleSummary> _buildModules(NarrativeOverviewMetrics metrics) {
   ];
 }
 
+NarrativeMetricSummary _worldRuleDiagnosticsMetric(
+  WorldRuleDiagnosticsReport report,
+) {
+  final issueCount = report.errorCount + report.warningCount;
+  return NarrativeMetricSummary(
+    id: 'world_rule_diagnostics',
+    label: 'Diagnostics',
+    count: issueCount,
+    availability: issueCount == 0
+        ? NarrativeOverviewAvailability.empty
+        : NarrativeOverviewAvailability.available,
+    sourceStatus: report.hasDiagnostics
+        ? NarrativeOverviewSourceStatus.explicit
+        : NarrativeOverviewSourceStatus.missing,
+    emptyStateMessage: 'Aucun diagnostic World Rule.',
+    unavailableMessage: 'Diagnostics World Rules indisponibles.',
+  );
+}
+
 NarrativeProjectHealthSummary _buildProjectHealth(
   EditorialStatusSummary editorialStatus,
   NarrativeOverviewMetrics metrics,
```


#### Diff complet — packages/map_editor/lib/src/ui/canvas/narrative_overview_workspace.dart
```text
diff --git a/packages/map_editor/lib/src/ui/canvas/narrative_overview_workspace.dart b/packages/map_editor/lib/src/ui/canvas/narrative_overview_workspace.dart
index 6732ac3e..d5efb185 100644
--- a/packages/map_editor/lib/src/ui/canvas/narrative_overview_workspace.dart
+++ b/packages/map_editor/lib/src/ui/canvas/narrative_overview_workspace.dart
@@ -486,6 +486,17 @@ class _ModuleCard extends StatelessWidget {
               height: 1.3,
             ),
           ),
+          if (module.previewLabels.isNotEmpty) ...[
+            const SizedBox(height: 8),
+            Wrap(
+              spacing: 6,
+              runSpacing: 6,
+              children: [
+                for (final label in module.previewLabels)
+                  _ModulePreviewLabel(label: label),
+              ],
+            ),
+          ],
           const SizedBox(height: 10),
           Text(
             _moduleCardValue(module),
@@ -526,6 +537,36 @@ class _ModuleCard extends StatelessWidget {
   }
 }
 
+class _ModulePreviewLabel extends StatelessWidget {
+  const _ModulePreviewLabel({required this.label});
+
+  final String label;
+
+  @override
+  Widget build(BuildContext context) {
+    return Container(
+      decoration: BoxDecoration(
+        color: EditorChrome.chipFill(context),
+        borderRadius: BorderRadius.circular(999),
+        border: Border.all(
+          color: EditorChrome.activeAccent(context).withValues(alpha: 0.24),
+        ),
+      ),
+      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
+      child: Text(
+        label,
+        maxLines: 1,
+        overflow: TextOverflow.ellipsis,
+        style: TextStyle(
+          color: EditorChrome.primaryLabel(context),
+          fontSize: 11,
+          fontWeight: FontWeight.w800,
+        ),
+      ),
+    );
+  }
+}
+
 class _ModuleIcon extends StatelessWidget {
   const _ModuleIcon({
     required this.moduleId,
```


#### Diff complet — packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart
```text
diff --git a/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart b/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart
index b345ba30..40372de7 100644
--- a/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart
+++ b/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart
@@ -240,6 +240,10 @@ void main() {
               relativePath: 'dialogues/test_dialogue_1.yarn',
             ),
           ],
+          facts: [
+            NarrativeFactDefinition(id: 'fact_known', label: 'Known'),
+          ],
+          worldRules: [_overviewWorldRule()],
         ),
       );
 
@@ -349,6 +353,10 @@ void main() {
               relativePath: 'dialogues/test_dialogue_1.yarn',
             ),
           ],
+          facts: [
+            NarrativeFactDefinition(id: 'fact_known', label: 'Known'),
+          ],
+          worldRules: [_overviewWorldRule()],
         ),
       );
 
@@ -565,6 +573,10 @@ void main() {
               relativePath: 'dialogues/test_dialogue_1.yarn',
             ),
           ],
+          facts: [
+            NarrativeFactDefinition(id: 'fact_known', label: 'Known'),
+          ],
+          worldRules: [_overviewWorldRule()],
         ),
       );
 
@@ -578,6 +590,19 @@ void main() {
           findsOneWidget);
       expect(_textInModule(NarrativeOverviewModuleIds.worldRules, '1'),
           findsOneWidget);
+      expect(
+        _textInModule(NarrativeOverviewModuleIds.worldRules, 'Diagnostics'),
+        findsOneWidget,
+      );
+      expect(
+        _textInModule(
+          NarrativeOverviewModuleIds.worldRules,
+          'Visible world rule',
+        ),
+        findsOneWidget,
+      );
+      expect(_textInModule(NarrativeOverviewModuleIds.worldRules, '0'),
+          findsOneWidget);
       expect(
         _textInModule(NarrativeOverviewModuleIds.dialogues, 'Indisponible'),
         findsOneWidget,
@@ -598,6 +623,42 @@ void main() {
     },
   );
 
+  testWidgets(
+    'NarrativeOverviewWorkspace renders ProjectManifest world rule diagnostics',
+    (tester) async {
+      final readModel = buildNarrativeOverviewReadModel(
+        project: _minimalProject(
+          'test_project',
+          worldRules: [
+            _overviewWorldRule(
+              sourceId: 'fact_missing',
+              label: 'Rule with missing fact',
+            ),
+          ],
+        ),
+      );
+
+      await _pumpOverview(tester, readModel, width: 1040, height: 1120);
+
+      expect(_textInModule(NarrativeOverviewModuleIds.worldRules, '1'),
+          findsWidgets);
+      expect(
+        _textInModule(NarrativeOverviewModuleIds.worldRules, 'Diagnostics'),
+        findsOneWidget,
+      );
+      expect(
+        _textInModule(
+          NarrativeOverviewModuleIds.worldRules,
+          'Rule with missing fact',
+        ),
+        findsOneWidget,
+      );
+      expect(_textInModule(NarrativeOverviewModuleIds.worldRules, '1'),
+          findsWidgets);
+      expect(find.textContaining('Selbrume'), findsNothing);
+    },
+  );
+
   testWidgets(
     'NarrativeOverviewWorkspace module grid keeps previous overview blocks visible',
     (tester) async {
@@ -962,6 +1023,81 @@ void main() {
     },
   );
 
+  testWidgets(
+    'NarrativeOverviewWorkspace captures V1-20 World Rules screenshot when requested',
+    (tester) async {
+      if (!const bool.fromEnvironment('NS_SCENES_V1_20_CAPTURE_SCREENSHOT')) {
+        return;
+      }
+
+      await _loadScreenshotFont();
+      tester.view.physicalSize = const Size(1180, 840);
+      tester.view.devicePixelRatio = 1;
+      addTearDown(() {
+        tester.view.resetPhysicalSize();
+        tester.view.resetDevicePixelRatio();
+      });
+
+      final readModel = buildNarrativeOverviewReadModel(
+        project: _minimalProject(
+          'test_project',
+          facts: [
+            NarrativeFactDefinition(id: 'fact_known', label: 'Known'),
+          ],
+          worldRules: [_overviewWorldRule()],
+        ),
+      );
+
+      await tester.pumpWidget(
+        MacosTheme(
+          data: MacosThemeData.dark(),
+          child: CupertinoApp(
+            home: CupertinoPageScaffold(
+              child: ColoredBox(
+                key: const ValueKey('ns-scenes-v1-20-screenshot-root'),
+                color: const Color(0xFF07111F),
+                child: DefaultTextStyle.merge(
+                  style: const TextStyle(fontFamily: _screenshotFontFamily),
+                  child: Center(
+                    child: SizedBox(
+                      width: 1180,
+                      height: 840,
+                      child: NarrativeOverviewWorkspace(readModel: readModel),
+                    ),
+                  ),
+                ),
+              ),
+            ),
+          ),
+        ),
+      );
+      await tester.pump(const Duration(milliseconds: 100));
+      await tester.scrollUntilVisible(
+        find.byKey(
+          const ValueKey(
+            'narrative-overview-module-${NarrativeOverviewModuleIds.worldRules}',
+          ),
+          skipOffstage: false,
+        ),
+        260,
+      );
+      await tester.pump(const Duration(milliseconds: 100));
+
+      final screenshotFile = File(
+        '../../reports/narrativeStudio/scenes/screenshots/'
+        'ns_scenes_v1_20_world_rules_v0.png',
+      );
+      screenshotFile.parent.createSync(recursive: true);
+      await expectLater(
+        find.byKey(const ValueKey('ns-scenes-v1-20-screenshot-root')),
+        matchesGoldenFile(screenshotFile.absolute.path),
+      );
+
+      expect(screenshotFile.existsSync(), isTrue);
+      expect(find.textContaining('Selbrume'), findsNothing);
+    },
+  );
+
   testWidgets(
     'NarrativeOverviewWorkspace captures main story card screenshot when requested',
     (tester) async {
@@ -1516,14 +1652,45 @@ ProjectManifest _minimalProject(
   String name, {
   List<ScenarioAsset> scenarios = const <ScenarioAsset>[],
   List<ProjectDialogueEntry> dialogues = const <ProjectDialogueEntry>[],
+  List<NarrativeFactDefinition> facts = const <NarrativeFactDefinition>[],
+  List<WorldRuleDefinition> worldRules = const <WorldRuleDefinition>[],
 }) {
   return ProjectManifest(
     surfaceCatalog: const ProjectSurfaceCatalog.empty(),
     name: name,
-    maps: const <ProjectMapEntry>[],
+    maps: const <ProjectMapEntry>[
+      ProjectMapEntry(
+        id: 'map_test',
+        name: 'Map test',
+        relativePath: 'maps/map_test.json',
+      ),
+    ],
     tilesets: const <ProjectTilesetEntry>[],
     scenarios: scenarios,
     dialogues: dialogues,
+    facts: facts,
+    worldRules: worldRules,
+  );
+}
+
+WorldRuleDefinition _overviewWorldRule({
+  String sourceId = 'fact_known',
+  String label = 'Visible world rule',
+}) {
+  return WorldRuleDefinition(
+    id: 'world_rule_visible',
+    label: label,
+    source: WorldRuleSource(
+      kind: WorldRuleSourceKind.fact,
+      sourceId: sourceId,
+      predicate: WorldRuleSourcePredicate.isTrue,
+    ),
+    target: const WorldRuleTarget(
+      kind: WorldRuleTargetKind.mapEntity,
+      mapId: 'map_test',
+      entityId: 'entity_test',
+    ),
+    effect: const WorldRuleEffect(kind: WorldRuleEffectKind.entityVisible),
   );
 }
```


#### Diff complet — reports/narrativeStudio/scenes/road_map_scenes.md
```text
diff --git a/reports/narrativeStudio/scenes/road_map_scenes.md b/reports/narrativeStudio/scenes/road_map_scenes.md
index b807e8a5..a41502e4 100644
--- a/reports/narrativeStudio/scenes/road_map_scenes.md
+++ b/reports/narrativeStudio/scenes/road_map_scenes.md
@@ -58,8 +58,8 @@ Ces briques sont utiles, mais elles ne constituent pas encore une Scene V1 propr
 | NS-SCENES-V1-16 — Condition Sources Contract V0 | DONE | Contrat no-code des sources de condition : sources V0 autorisees, sources reportees, mapping technique, operateurs, pickers et diagnostics, sans code ni UI. |
 | NS-SCENES-V1-17 — Condition Authoring V0 (Existing Sources Only) | DONE | `ConditionNode` configurable avec source structuree V0 depuis refs existantes : fact-like story flag, story step completion et event consumed, sans texte magique ni fake ref. |
 | NS-SCENES-V1-18 — Fact Registry V0 | DONE | Registry authoring de Facts lisibles bool-first dans `ProjectManifest.facts`, operations pures, JSON, diagnostics refs inconnues et picker Condition prioritaire. |
-| NS-SCENES-V1-19 — World Rule Contract V0 | TODO | Formaliser les World Rules comme regles visibles derivees de Facts/Steps/conditions, sans encore brancher tout le runtime. |
-| NS-SCENES-V1-20 — World Rules V0 | TODO | Premier authoring/validation de World Rules controlees : visibilite, dialogue, portes/collisions ou map state selon contrat. |
+| NS-SCENES-V1-19 — World Rule Contract V0 | DONE | Contrat produit/technique des World Rules V0 : registry projet future avec targets explicites, sources Fact/Step/Event, effets V0 limites et diagnostics requis. |
+| NS-SCENES-V1-20 — World Rules V0 | DONE | Premier modele/authoring/validation de World Rules controlees : registry `ProjectManifest.worldRules`, operations pures, diagnostics, projection pure et apercu editor minimal. |
 | NS-SCENES-V1-21 — Scene Runtime Plan V0 | TODO | Ajouter un modele pur `SceneRuntimePlan` / intents dans `map_core`, compiler `SceneAsset` valide en plan executable sans layout ni Flutter. |
 | NS-SCENES-V1-22 — Payload Pickers V0 | TODO | Ajouter les pickers Yarn, cinematic, battle/action refs et limiter les IDs libres. |
 | NS-SCENES-V1-23 — Diagnostics Expansion | TODO | Etendre diagnostics aux refs, ports, outcomes non geres, unreachable/cycles et payloads incomplets. |
@@ -70,9 +70,77 @@ Ces briques sont utiles, mais elles ne constituent pas encore une Scene V1 propr
 
 ## Prochain lot recommande
 
-`NS-SCENES-V1-19 — World Rule Contract V0`
+`NS-SCENES-V1-21 — Scene Runtime Plan V0`
 
-Raison : V1-18 donne aux conditions une source Fact lisible, bool-first, sans exposer les flags techniques comme experience principale. Le prochain bloc doit cadrer les World Rules avant d'ajouter leurs modeles/UI, afin de decrire proprement les changements visibles du monde derives des Facts/Steps/conditions.
+Raison : V1-20 a ajoute les World Rules authoring comme donnees projet validables, sans les brancher au runtime. Le prochain bloc peut revenir a la preparation d'execution Scene V1 avec un `SceneRuntimePlan` pur, en gardant layout, World Rules et runtime separes.
+
+## Decisions V1-20
+
+- `WorldRuleDefinition` est ajoute comme modele authoring declaratif : id, label, description, enabled, source, target, effect, priority, tags et debug technique optionnel.
+- `ProjectManifest.worldRules` devient la registry canonique V0 des World Rules ; champ absent ou null => liste vide, sans migration automatique depuis predicates legacy, Step Studio ou map entities.
+- Sources V0 codees : `Fact`, `StoryStep completion` et `consumed event`, avec predicates compatibles controles.
+- Targets V0 codees : `mapEntity`, `npcDialogue`, `mapEvent`.
+- Effets V0 codes : `entityVisible`, `entityHidden`, `npcDialogueOverride`, `eventEnabled`, `eventDisabled`, `eventHidden`.
+- Les operations pures `addWorldRule`, `updateWorldRule` et `removeWorldRule` preservent le manifest original, generent des IDs stables et refusent labels vides, refs structurellement invalides et mismatches target/effect.
+- `diagnoseWorldRules` signale sources/targets/effects manquants ou inconnus, predicates incompatibles, mismatches, conflits de priorite et fuites d'IDs/predicates techniques.
+- `projectWorldRuleEffects` projette des effets resolus depuis `ProjectManifest` + `GameState`, sans muter `ProjectManifest`, `MapData` ou `GameState`.
+- L'editor affiche un etat minimal honnete dans l'aperçu : compteur World Rules, diagnostics et premiers labels, sans authoring UI complet.
+- Aucun runtime Scene, aucun Event -> Scene, aucun StorylineStep link, aucune migration ScenarioAsset et aucune donnee Selbrume ne sont ajoutes.
+
+## Limites V1-20
+
+- Pas d'ecran dedie d'authoring World Rules dans l'editor.
+- Pas de picker map/entity/event/dialogue cote UI, seulement une integration overview minimale.
+- La projection pure reste non destructive et non branchee au runtime.
+- Les collisions dynamiques, warps, tiles, ambience/map state, mouvements d'entites et effets composites restent hors scope.
+- Les Facts restent bool-first et la projection s'appuie sur `GameState.storyFlags` / `legacyFlagName` quand disponible.
+
+## Tests V1-20
+
+- `cd packages/map_core && dart test test/world_rule_test.dart`
+- `cd packages/map_core && dart test test/world_rule_authoring_operations_test.dart`
+- `cd packages/map_core && dart test test/project_manifest_world_rules_test.dart`
+- `cd packages/map_core && dart test test/world_rule_diagnostics_test.dart`
+- `cd packages/map_core && dart test test/world_rule_projection_test.dart`
+- `cd packages/map_core && dart test test/project_manifest_facts_test.dart`
+- `cd packages/map_core && dart run build_runner build --delete-conflicting-outputs`
+- `cd packages/map_core && dart analyze`
+- `cd packages/map_editor && flutter test --reporter=compact test/ui/canvas/narrative_overview_workspace_test.dart`
+- `cd packages/map_editor && flutter test --reporter=compact test/ui/canvas/narrative_overview_shell_navigation_test.dart`
+- `cd packages/map_editor && flutter test --reporter=compact test/ui/canvas/narrative_studio_header_test.dart`
+- `cd packages/map_editor && flutter test --reporter=compact test/narrative_workspace_projection_test.dart`
+- `cd packages/map_editor && flutter test --update-goldens --reporter=compact --dart-define=NS_SCENES_V1_20_CAPTURE_SCREENSHOT=true test/ui/canvas/narrative_overview_workspace_test.dart --plain-name "NarrativeOverviewWorkspace captures V1-20 World Rules screenshot when requested"`
+- `cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/features/narrative/application/overview/narrative_overview_read_model.dart lib/src/ui/canvas/narrative_overview_workspace.dart test/ui/canvas/narrative_overview_workspace_test.dart`
+- Verification finale : `git diff --check`.
+
+## Decisions V1-19
+
+- Lot documentation-only : aucun code, widget, modele Dart, runtime, test ou fixture n'est modifie.
+- Une World Rule est une regle authoring declarative, inspectable et validable qui projette un changement visible ou actif du monde depuis une source lisible.
+- Une World Rule n'est pas un script cache, une action one-shot, une condition dissimulee dans un PNJ ou un flag technique expose comme UX principale.
+- Stockage futur recommande : registry projet canonique, avec targets explicites et affichage contextuel depuis Map Editor/entity inspector.
+- Sources V0 recommandees : Fact Registry fact, StoryStep completed/notCompleted, consumed event ; `ScriptCondition` reste backend/legacy, pas surface produit.
+- Effets V0 prioritaires : presence/visibilite d'entite, dialogue conditionnel PNJ, disponibilite simple d'event si la cible est validee.
+- Effets repousses : collision dynamique, warp dynamique, deplacement d'entite, ambience/map state global et World Rule source derivee d'une autre World Rule.
+- Runtime futur recommande : projection/resolution non destructive depuis `GameState`, sans muter `MapData` ou `ProjectManifest`.
+- Diagnostics requis : source/target/effect manquants ou inconnus, mismatch target/effect, conflits de priorite, cycles et fuite d'IDs techniques.
+- Prochain lot exact : `NS-SCENES-V1-20 — World Rules V0`.
+
+## Limites V1-19
+
+- Aucun modele `WorldRule` n'est cree.
+- Aucun champ `ProjectManifest.worldRules` n'est ajoute.
+- Aucun runtime, gameplay, editor widget ou payload Scene n'est modifie.
+- Les portes/collisions/warps restent conceptuellement analyses mais non autorises comme effet V0 direct.
+- Aucune donnee Selbrume n'est creee.
+
+## Tests V1-19
+
+- Dart analyze non requis : lot documentation-only.
+- Flutter analyze non requis : lot documentation-only.
+- Dart test non requis : lot documentation-only.
+- Flutter test non requis : lot documentation-only.
+- Verification requise : `git diff --check`.
 
 ## Decisions V1-18
```


#### Diff complet — reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
```text
diff --git a/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md b/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
index 549640e5..83cc86b0 100644
--- a/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
+++ b/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
@@ -9,7 +9,7 @@ Le runtime reste indispensable, mais le prochain blocage produit est plus basiqu
 ## Prochain lot exact recommande
 
 ```text
-NS-SCENES-V1-19 — World Rule Contract V0
+NS-SCENES-V1-21 — Scene Runtime Plan V0
 ```
 
 ## Principes
@@ -37,8 +37,8 @@ NS-SCENES-V1-19 — World Rule Contract V0
 | NS-SCENES-V1-16 | Condition Sources Contract V0 | doc / core-design | Definir les sources conditionnelles no-code, leur maturite, mapping technique, pickers, diagnostics et limite runtime. | Pas de Condition UI complete, pas de Fact Registry codee, pas de World Rule runtime. | rapport V1-16, roadmaps. | `git diff --check` uniquement. | Sur-documenter ; ou exposer `ScriptCondition` brut comme UX. | DONE : sources V0 autorisees/reportees, contrat conceptuel, operateurs, diagnostics et pickers definis. | V1-16-prep. |
 | NS-SCENES-V1-17 | Condition Authoring V0 (Existing Sources Only) | core / editor | Configurer un `ConditionNode` V0 avec sources existantes uniquement, sans texte magique ni fake refs. | Pas de runtime, pas d'expressions complexes, pas de sources non cadrees, pas de Yarn/Battle/Cinematic pickers. | scene authoring operations, inspector controls, diagnostics tests. | Tests payload condition, mutation ProjectManifest.scenes, diagnostics condition incomplete/valid. | Ouvrir trop tot un langage de conditions complet ; exposer flags bruts. | DONE : condition configurable via source structuree explicite, diagnostics bloquants si incomplete, picker limite aux refs existantes. | V1-16. |
 | NS-SCENES-V1-18 | Fact Registry V0 | core / editor | Ajouter une registry authoring de Facts lisibles, bool-first, avec labels, descriptions et categories pour pickers no-code. | Pas de World Rules completes, pas de runtime Scene complet, pas de types avances obligatoires. | `ProjectManifest`, operations facts, picker Condition, tests serialization/diagnostics. | DONE : tests registry JSON, operations pures, picker Fact, diagnostics refs inconnues. | Confondre Fact et StoryStep ; exposer seulement des IDs techniques. | DONE : Facts lisibles stockes dans `ProjectManifest.facts`, refs stables, picker prioritaire, fallback technique conserve. | V1-16, V1-17. |
-| NS-SCENES-V1-19 | World Rule Contract V0 | doc / core-design | Formaliser les World Rules comme regles visibles derivees de Facts/Steps/conditions. | Pas de runtime complet, pas de Map Editor lourd, pas de seed Selbrume. | rapport contractuel, event/map model audit. | `git diff --check` ou tests core si modele pur. | Faire des World Rules des scripts caches ; creer des boucles invisibles. | Types de regles, sources, effets, priorites et diagnostics de base definis. | V1-18 recommande. |
-| NS-SCENES-V1-20 | World Rules V0 | core / editor / gameplay | Premier authoring/validation de World Rules controlees : visibilite, dialogue, porte/collision ou map state selon contrat. | Pas de runtime Scene complet, pas de StorylineStep link. | map entity/world rule models si decide, editor picker, diagnostics. | Tests refs map/entity, evaluation pure, diagnostics. | Casser les predicates existants ; rendre le monde trop dynamique sans validation. | Regles visibles authorables et validables, sans flags bruts dans l'UX. | V1-19. |
+| NS-SCENES-V1-19 | World Rule Contract V0 | doc / core-design | Formaliser les World Rules comme regles visibles derivees de Facts/Steps/conditions. | Pas de modele, pas de runtime, pas de Map Editor lourd, pas de seed Selbrume. | rapport contractuel, event/map model audit. | DONE : `git diff --check`. | Faire des World Rules des scripts caches ; creer des boucles invisibles. | DONE : sources, targets, effets, stockage, priorites et diagnostics definis. | V1-18. |
+| NS-SCENES-V1-20 | World Rules V0 | core / editor | Premier modele/authoring/validation de World Rules controlees : registry projet, operations pures, diagnostics, projection pure et apercu minimal. | Pas de runtime Scene complet, pas de StorylineStep link, pas de collision/warp dynamique direct, pas d'ecran editor complet. | `world_rule.dart`, `ProjectManifest`, operations authoring, diagnostics, projection, overview read model. | DONE : tests JSON/manifest/ops/diagnostics/projection + overview widget + analyze + visual gate. | Casser les predicates existants ; rendre le monde trop dynamique sans validation. | DONE : World Rules authorables et validables, compteur/labels en apercu, projection pure non runtime. | V1-19. |
 | NS-SCENES-V1-21 | Scene Runtime Plan V0 | core | Ajouter `SceneRuntimePlan`, intents, builder pur depuis `SceneAsset` valide. | Pas d'execution runtime, pas de Flutter, pas de `ScenarioAsset` auto. | `packages/map_core/lib/src/runtime/scene_runtime_plan.dart`, tests core. | Draft minimal, yarn/battle/cinematic/action intents, diagnostics error bloque, layout ignore. | Figer trop tot un executor ; dupliquer ScenarioRuntime. | Plan pur testable, ignore layout, refuse scenes invalides. | V1-17, V1-18 utile. |
 | NS-SCENES-V1-22 | Payload Pickers V0 | editor / core | Remplacer IDs libres par pickers/drafts honnetes : Yarn, cinematic, battle, action. | Pas de full editor payload, pas de runtime. | workspace Scenes, inspector draft controls, projection refs. | Tests pickers refs reelles, refs inconnues diagnostic, boutons honnetes. | Faux contenus Selbrume, refs tapees a la main. | Node payloads configurables avec vraies refs ou drafts clairement invalides. | V1-17, V1-21 utile. |
 | NS-SCENES-V1-23 | Diagnostics Expansion | core / editor | Etendre diagnostics aux refs, ports requis, outcomes non geres, unreachable, cycles, sources conditions et facts/world rules. | Pas de correction auto, pas de Validator global complet. | `scene_diagnostics.dart`, UI diagnostics. | Tests refs inconnues, missing outputs, unreachable, cycles, severity. | Trop bloquer les drafts ; confusion warning/error. | Builder guide l'auteur sans empecher draft minimal valide. | V1-17, V1-18, V1-22. |
@@ -154,6 +154,32 @@ Limites : bool-only, pas de registry editor dediee, pas de World Rules, pas de r
 
 Prochain lot exact : `NS-SCENES-V1-19 — World Rule Contract V0`.
 
+## Mise a jour V1-19
+
+Statut : `NS-SCENES-V1-19 — World Rule Contract V0` est DONE.
+
+Decision : une World Rule V0 est une regle authoring declarative, inspectable et validable. Elle lit une source metier (`Fact`, `StoryStep completed/notCompleted`, `consumed event`) et projette un effet visible/actif sur une cible explicite du monde. Elle n'est pas un script cache, une action one-shot de Scene, une condition dissimulee dans un PNJ ou un flag technique expose comme UX principale.
+
+Stockage futur recommande : registry projet canonique avec targets explicites, plus affichage contextuel dans Map Editor/entity inspector. Les implementations existantes `MapEntityNpcVisibilityRule`, `MapEntityConditionalDialogue`, `MapEntityRuntimePredicateEvaluator`, `NpcMapPresencePredicate` et `StepStudioWorldPresenceRule` servent d'inspiration ou de bridge, pas de modele produit final.
+
+Effets V0 recommandes : presence/visibilite d'entite, dialogue conditionnel PNJ, disponibilite simple d'event si les refs sont validables. Les collisions dynamiques, warps dynamiques, deplacements d'entites et ambiances/map state sont repousses.
+
+Limites : aucun code, aucun widget, aucun modele Dart, aucun runtime et aucune donnee Selbrume ne sont ajoutes.
+
+Prochain lot exact : `NS-SCENES-V1-20 — World Rules V0`.
+
+## Mise a jour V1-20
+
+Statut : `NS-SCENES-V1-20 — World Rules V0` est DONE.
+
+Decision : V1-20 ajoute une registry canonique `ProjectManifest.worldRules` et un modele `WorldRuleDefinition` declaratif. Les sources V0 supportees sont `Fact`, `StoryStep completion` et `consumed event`. Les targets V0 sont `mapEntity`, `npcDialogue` et `mapEvent`. Les effets V0 sont `entityVisible`, `entityHidden`, `npcDialogueOverride`, `eventEnabled`, `eventDisabled` et `eventHidden`.
+
+Integration : les operations pures `addWorldRule`, `updateWorldRule` et `removeWorldRule` preservent le manifest original et refusent les mismatches. `diagnoseWorldRules` couvre refs inconnues, predicates incompatibles, target/effect mismatch, conflits de priorite et labels techniques. `projectWorldRuleEffects` fournit une projection pure depuis `GameState`, sans mutation ni runtime. L'overview du Narrative Studio affiche compteur, diagnostics et premiers labels World Rules.
+
+Limites : pas d'ecran dedie World Rules, pas de picker map/entity/event/dialogue, pas de runtime Scene, pas d'Event -> Scene, pas de StorylineStep link, pas de collision/warp/tile/ambience dynamique, pas de donnees Selbrume.
+
+Prochain lot exact : `NS-SCENES-V1-21 — Scene Runtime Plan V0`.
+
 ## Selbrume golden slice
 
 Avant le golden slice, il faut au minimum :
@@ -163,6 +189,7 @@ Avant le golden slice, il faut au minimum :
 - Visual Port Connection UX V0 pour rendre la construction de graph utilisable sans ambiguite.
 - Payload Pickers V0 pour Yarn, battle, cinematic/action.
 - Diagnostics Expansion.
+- World Rules V0 pour les consequences visibles controlees.
 - Scene Runtime Plan V0.
 - Event to Scene Trigger Prep.
 - Scene Runtime Executor MVP.
@@ -170,6 +197,6 @@ Avant le golden slice, il faut au minimum :
 Peut attendre apres le slice :
 
 - StorylineStep -> Scene Link complet.
-- World Rule editor complet.
+- World Rule editor avance au-dela des effets V0.
 - Fact registry avance.
 - Cinematic editor avance si une cinematic fixture controlee suffit.
```


## Auto-review critique

- Le modele V0 est volontairement petit et controle, mais il ne fournit pas encore un ecran editor complet ni des pickers map/entity/event/dialogue.
- La projection pure utilise `GameState.storyFlags` et `legacyFlagName` pour les Facts ; un futur runtime devra clarifier le stockage runtime canonique des Facts.
- `diagnoseWorldRules(project)` sans `MapData` ne peut pas valider finement les entity/event IDs ; cette validation devient complete quand les maps sont fournies.
- L'overview affiche encore Facts comme donnees a venir dans certaines zones historiques ; hors scope V1-20, mais a harmoniser plus tard.
- Une commande de correction de test a ete faite par remplacement mecanique shell au lieu d'`apply_patch`; elle n'a touche qu'un test V1-20, mais ce n'est pas le chemin prefere.

## Regard critique sur le prompt

Le prompt est coherent avec V1-19 et force les bonnes limites : pas de runtime, pas de migration legacy, pas de donnees Selbrume. La demande d'Evidence Pack complet est tres couteuse lorsque des fichiers generes et de gros diffs sont impliques ; pour les prochains lots, il serait utile de distinguer preuves exhaustives de code cree et preuves synthetiques pour fichiers generes.

## Prochain lot exact recommande

`NS-SCENES-V1-21 — Scene Runtime Plan V0`

Raison : les sources de conditions, Facts et World Rules sont maintenant cadrees/codees comme donnees authoring. Le prochain risque est l'execution future : il faut compiler une `SceneAsset` valide en plan runtime pur sans layout, sans Flutter, sans ScenarioAsset canonique.

## Git status final

### git status --short --untracked-files=all
```text
 M packages/map_core/lib/map_core.dart
 M packages/map_core/lib/src/models/project_manifest.dart
 M packages/map_core/lib/src/models/project_manifest.freezed.dart
 M packages/map_core/lib/src/models/project_manifest.g.dart
 M packages/map_editor/lib/src/features/narrative/application/overview/narrative_overview_read_model.dart
 M packages/map_editor/lib/src/ui/canvas/narrative_overview_workspace.dart
 M packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? packages/map_core/lib/src/authoring/world_rule_authoring_operations.dart
?? packages/map_core/lib/src/diagnostics/world_rule_diagnostics.dart
?? packages/map_core/lib/src/models/world_rule.dart
?? packages/map_core/lib/src/projection/world_rule_projection.dart
?? packages/map_core/test/project_manifest_world_rules_test.dart
?? packages/map_core/test/world_rule_authoring_operations_test.dart
?? packages/map_core/test/world_rule_diagnostics_test.dart
?? packages/map_core/test/world_rule_projection_test.dart
?? packages/map_core/test/world_rule_test.dart
?? reports/narrativeStudio/scenes/ns_scenes_v1_19_world_rule_contract_v0.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_20_world_rules_v0.md
?? reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_20_world_rules_v0.png
```

### git diff --stat final
```text
 packages/map_core/lib/map_core.dart                |   4 +
 .../map_core/lib/src/models/project_manifest.dart  |  43 ++++++
 .../lib/src/models/project_manifest.freezed.dart   |  60 +++++++-
 .../lib/src/models/project_manifest.g.dart         |   4 +
 .../overview/narrative_overview_read_model.dart    |  51 +++++--
 .../ui/canvas/narrative_overview_workspace.dart    |  41 +++++
 .../canvas/narrative_overview_workspace_test.dart  | 169 ++++++++++++++++++++-
 .../scenes/road_map_scene_builder_authoring.md     |  35 ++++-
 reports/narrativeStudio/scenes/road_map_scenes.md  |  76 ++++++++-
 9 files changed, 460 insertions(+), 23 deletions(-)
```

### git diff --name-only final
```text
packages/map_core/lib/map_core.dart
packages/map_core/lib/src/models/project_manifest.dart
packages/map_core/lib/src/models/project_manifest.freezed.dart
packages/map_core/lib/src/models/project_manifest.g.dart
packages/map_editor/lib/src/features/narrative/application/overview/narrative_overview_read_model.dart
packages/map_editor/lib/src/ui/canvas/narrative_overview_workspace.dart
packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

### git diff --check final
```text
<vide>
```
