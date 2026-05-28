# NS-STORYLINES-V1-04 — StorylineAsset JSON Codec V0

## 1. Executive summary

NS-STORYLINES-V1-04 ajoute un codec JSON manuel et stable pour `StorylineAsset` et ses sous-objets essentiels.

Résultat : `StorylineAsset` supporte maintenant `model -> toJson() -> StorylineAsset.fromJson(...) -> model équivalent`, sans `ProjectManifest.storylines`, sans migration legacy, sans UI et sans build_runner.

Verdict : DONE.

Prochain lot recommandé : NS-STORYLINES-V1-05 — ProjectManifest.storylines Integration V0.

## 2. Inputs read

Fichiers lus :

- `AGENTS.md`
- `agent_rules.md`
- `skills/README.md`
- `reports/narrativeStudio/storylines/road_map_storylines.md`
- `reports/narrativeStudio/storylines/ns_storylines_v1_03_storyline_asset_pure_model_v0.md`
- `reports/narrativeStudio/storylines/ns_storylines_v1_02_storyline_authoring_data_shape_contract.md`
- `reports/narrativeStudio/storylines/ns_storylines_v1_01_storyline_authoring_model_decision.md`
- `packages/map_core/lib/src/models/storyline_asset.dart`
- `packages/map_core/lib/src/models/scenario_asset.dart`
- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/models/script_conditions.dart`
- `packages/map_core/lib/src/models/script_asset.dart`
- `packages/map_core/lib/map_core.dart`
- `packages/map_core/test/storyline_asset_test.dart`
- `packages/map_core/test/scenario_assets_test.dart`
- `packages/map_core/test/`

Fichiers absents mais attendus :

- Aucun fichier obligatoire absent.

Conventions JSON observées :

- Les modèles existants utilisent `toJson()` / `fromJson(...)`.
- Les enums existants sont encodés en strings via `@JsonValue` / noms stables.
- `ScriptCondition` possède un codec officiel généré Freezed/Json : `ScriptCondition.fromJson(...)` et `toJson()`.
- Les tests de codec existants vérifient roundtrip et erreurs de validation.

## 3. Implementation summary

Modifié :

- `packages/map_core/lib/src/models/storyline_asset.dart`
- `packages/map_core/test/storyline_asset_test.dart`
- `reports/narrativeStudio/storylines/road_map_storylines.md`

Créé :

- `packages/map_core/test/storyline_asset_json_test.dart`
- `reports/narrativeStudio/storylines/ns_storylines_v1_04_storyline_asset_json_codec_v0.md`

Le codec est manuel, sans dépendance nouvelle et sans generated files.

## 4. Codec scope

Codec ajouté pour :

- `StorylineAsset`
- `StorylineChapter`
- `StorylineStep`
- `StorylineSceneLink`
- `StorylineSceneRef`
- `StorylineSceneOutcomeLink`
- `StorylineEffect`
- `StorylineRelationship`
- `SideQuestAvailability`
- `StorylineAnchor`
- `StorylineValidationIssue`
- `StorylineLegacySource`

Codec enum ajouté pour :

- `StorylineType`
- `StorylineStatus`
- `StorylineSceneLinkState`
- `StorylineSceneLinkRole`
- `StorylineRelationshipKind`
- `StorylineValidationSeverity`
- `StorylineEffectType`
- `StorylineAnchorKind`
- `StorylineSceneRefKind`

## 5. JSON shape decisions

Décisions :

- Champs obligatoires inclus.
- Listes et maps incluses comme `[]` / `{}`.
- Champs optionnels `null` omis par `toJson()`.
- `fromJson` applique les defaults : `schemaVersion = 1`, `status = draft`, `chapters = []`, `sceneLinks = []`, `relationships = []`, `metadata = {}`.
- Malformations JSON lèvent `FormatException`.
- Invariants métier continuent de passer par les constructeurs et lèvent `ValidationException` si nécessaire.

## 6. Enum serialization

Les enums sont sérialisés via `Enum.name`, qui donne les strings lowerCamel stables déjà décidées :

- `main`
- `sideQuest`
- `postGame`
- `hiddenEvent`
- `linkedScenario`
- `needsImplementation`
- `sideQuestUnlockedBy`
- `activateStep`
- `completeStep`
- `unlockStoryline`
- `sceneOutcome`
- `scenario`

Les tests vérifient explicitement que les enums ne sont pas sérialisés en integers.

## 7. ScriptCondition codec decision

Décision : codec officiel existant utilisé.

Preuve : `ScriptCondition` expose `factory ScriptCondition.fromJson(Map<String, dynamic> json)` et Freezed génère `toJson()`.

Aucun codec condition local n'a été créé. Aucun deuxième langage conditionnel n'a été ajouté.

Tests ajoutés : roundtrip de `entryCondition`, `completionCondition`, `relationship.condition`, `availabilityCondition` et `expiresCondition` via le modèle complet.

## 8. Validation during decode

`fromJson` est strict sur les types JSON :

- enum inconnu -> `FormatException` ;
- champ obligatoire manquant -> `FormatException` ;
- liste attendue absente -> default `[]` ;
- liste attendue mal typée -> `FormatException` ;
- map metadata mal typée -> `FormatException` ;
- valeur metadata non string -> `FormatException`.

Les constructeurs conservent les invariants :

- ids vides rejetés ;
- duplicates rejetés ;
- `sceneLink.chapterId` inconnu rejeté ;
- `sceneLink.stepId` inconnu rejeté ;
- `placeholder` avec `sceneRef` rejeté ;
- `linkedScenario` sans `sceneRef` rejeté ;
- relationship inline avec source différente du `StorylineAsset.id` rejetée.

## 9. Non-goals confirmed

Confirmé :

- `ProjectManifest` non modifié.
- `ProjectManifest.storylines` non ajouté.
- `ScenarioAsset` non modifié.
- `ScriptCondition` non modifié.
- `ScriptAsset` non modifié.
- Aucun fichier généré modifié.
- `build_runner` non lancé.
- Aucune migration legacy.
- Aucune UI.
- Aucun bouton activé.
- Aucun `map_editor`, `map_runtime`, `map_gameplay`, `map_battle` modifié.

## 10. Tests added

Ajouté :

- `packages/map_core/test/storyline_asset_json_test.dart`

Couverture :

- roundtrip minimal main draft ;
- roundtrip minimal sideQuest draft ;
- roundtrip complet authoring shape ;
- enums strings stables non integer ;
- defaults au decode ;
- invalid JSON ;
- validation constructeur appliquée au decode ;
- `ScriptCondition` roundtrip via codec officiel.

Modifié :

- `packages/map_core/test/storyline_asset_test.dart` : le guard V1-03 “pas de JSON” est remplacé par un guard V1-04 confirmant que le codec existe sans manifest integration.

## 11. Commands run

Commandes initiales :

```bash
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git diff --check
```

Commandes principales :

```bash
cd packages/map_core && dart format lib/src/models/storyline_asset.dart test/storyline_asset_test.dart test/storyline_asset_json_test.dart
cd packages/map_core && dart test test/storyline_asset_json_test.dart
cd packages/map_core && dart test test/storyline_asset_test.dart
cd packages/map_core && dart test test/scenario_assets_test.dart
cd packages/map_core && dart analyze lib/src/models/storyline_asset.dart test/storyline_asset_test.dart test/storyline_asset_json_test.dart
cd packages/map_core && dart test --reporter json | tail -n 1
cd packages/map_core && dart test --reporter json test/storyline_asset_json_test.dart | tail -n 1
cd packages/map_core && dart test --reporter json test/storyline_asset_test.dart | tail -n 1
cd packages/map_core && dart test --reporter json test/scenario_assets_test.dart | tail -n 1
```

Commandes finales :

```bash
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git diff --check
```

## 12. Roadmap update

Roadmap mise à jour :

- `NS-STORYLINES-V1-04` marqué DONE.
- Résumé du codec JSON ajouté.
- Tests et analyse listés.
- Non-objectifs confirmés : pas de `ProjectManifest`, pas de `ScenarioAsset`, pas de build_runner.
- Prochain lot recommandé : `NS-STORYLINES-V1-05 — ProjectManifest.storylines Integration V0`.

## 13. Evidence Pack

### Git branch initiale

```text
main
```

### Git status initial exact

```text
Sortie : <vide>
```

### Git diff --stat initial

```text
Sortie : <vide>
```

### Git diff --name-only initial

```text
Sortie : <vide>
```

### Git diff --check initial

```text
Sortie : <vide>
```

### Liste des fichiers lus

```text
AGENTS.md
agent_rules.md
skills/README.md
reports/narrativeStudio/storylines/road_map_storylines.md
reports/narrativeStudio/storylines/ns_storylines_v1_03_storyline_asset_pure_model_v0.md
reports/narrativeStudio/storylines/ns_storylines_v1_02_storyline_authoring_data_shape_contract.md
reports/narrativeStudio/storylines/ns_storylines_v1_01_storyline_authoring_model_decision.md
packages/map_core/lib/src/models/storyline_asset.dart
packages/map_core/lib/src/models/scenario_asset.dart
packages/map_core/lib/src/models/project_manifest.dart
packages/map_core/lib/src/models/script_conditions.dart
packages/map_core/lib/src/models/script_asset.dart
packages/map_core/lib/map_core.dart
packages/map_core/test/storyline_asset_test.dart
packages/map_core/test/scenario_assets_test.dart
packages/map_core/test/
```

### Liste des fichiers absents mais attendus

```text
Sortie : <vide>
```

### Contenu complet de storyline_asset.dart

```dart
import 'package:meta/meta.dart' show immutable;

import '../exceptions/map_exceptions.dart';
import 'script_conditions.dart';

enum StorylineType {
  main,
  sideQuest,
  tutorial,
  epilogue,
  episode,
  postGame,
  hiddenEvent,
}

enum StorylineStatus {
  draft,
  active,
  archived,
  disabled,
}

enum StorylineSceneLinkState {
  placeholder,
  linkedScenario,
  brokenLink,
  needsImplementation,
}

enum StorylineSceneLinkRole {
  primary,
  optional,
  branch,
  convergence,
  setup,
  payoff,
}

enum StorylineRelationshipKind {
  sideQuestAvailableDuring,
  sideQuestUnlockedBy,
  sideQuestAffectsMain,
  convergesTo,
  requires,
  blocks,
}

enum StorylineValidationSeverity {
  info,
  warning,
  error,
  blocking,
}

enum StorylineEffectType {
  activateStep,
  completeStep,
  unlockStoryline,
  emitFact,
  setWorldRule,
  affectRelationship,
}

enum StorylineAnchorKind {
  storyline,
  chapter,
  step,
  sceneOutcome,
}

enum StorylineSceneRefKind {
  scenario,
}

@immutable
final class StorylineAsset {
  StorylineAsset({
    required this.id,
    this.schemaVersion = 1,
    required this.type,
    this.status = StorylineStatus.draft,
    required this.title,
    this.description,
    this.sortOrder,
    this.locale,
    List<StorylineChapter> chapters = const <StorylineChapter>[],
    List<StorylineSceneLink> sceneLinks = const <StorylineSceneLink>[],
    List<StorylineRelationship> relationships = const <StorylineRelationship>[],
    this.legacySource,
    this.authorNotes,
    Map<String, String> metadata = const <String, String>{},
  })  : chapters = List<StorylineChapter>.unmodifiable(chapters),
        sceneLinks = List<StorylineSceneLink>.unmodifiable(sceneLinks),
        relationships = List<StorylineRelationship>.unmodifiable(relationships),
        metadata = Map<String, String>.unmodifiable(metadata) {
    _requireNotBlank(id, 'StorylineAsset.id');
    if (schemaVersion <= 0) {
      throw const ValidationException(
        'StorylineAsset.schemaVersion must be greater than 0',
      );
    }
    _requireNotBlank(title, 'StorylineAsset.title');
    _validateUniqueIds(
      this.chapters.map((chapter) => chapter.id),
      'StorylineAsset.chapters',
    );
    _validateUniqueIds(
      _allSteps(this.chapters).map((step) => step.id),
      'StorylineAsset.steps',
    );
    _validateUniqueIds(
      this.sceneLinks.map((sceneLink) => sceneLink.id),
      'StorylineAsset.sceneLinks',
    );
    _validateUniqueIds(
      this.relationships.map((relationship) => relationship.id),
      'StorylineAsset.relationships',
    );
    _validateSceneLinkReferences(this.chapters, this.sceneLinks);
    for (final relationship in this.relationships) {
      if (relationship.sourceStorylineId != id) {
        throw ValidationException(
          'StorylineAsset.relationships sourceStorylineId must match $id',
        );
      }
    }
  }

  factory StorylineAsset.fromJson(Map<String, dynamic> json) {
    return StorylineAsset(
      id: _readRequiredString(json, 'id'),
      schemaVersion: _readInt(json, 'schemaVersion', defaultValue: 1),
      type: _readEnum(StorylineType.values, json['type'], 'type'),
      status: _readEnum(
        StorylineStatus.values,
        json['status'],
        'status',
        defaultValue: StorylineStatus.draft,
      ),
      title: _readRequiredString(json, 'title'),
      description: _readOptionalString(json, 'description'),
      sortOrder: _readOptionalInt(json, 'sortOrder'),
      locale: _readOptionalString(json, 'locale'),
      chapters: _readObjectList(
        json,
        'chapters',
        StorylineChapter.fromJson,
      ),
      sceneLinks: _readObjectList(
        json,
        'sceneLinks',
        StorylineSceneLink.fromJson,
      ),
      relationships: _readObjectList(
        json,
        'relationships',
        StorylineRelationship.fromJson,
      ),
      legacySource: _readOptionalObject(
        json,
        'legacySource',
        StorylineLegacySource.fromJson,
      ),
      authorNotes: _readOptionalString(json, 'authorNotes'),
      metadata: _readStringMap(json, 'metadata'),
    );
  }

  Map<String, dynamic> toJson() {
    return _withoutNulls({
      'id': id,
      'schemaVersion': schemaVersion,
      'type': _enumToJson(type),
      'status': _enumToJson(status),
      'title': title,
      'description': description,
      'sortOrder': sortOrder,
      'locale': locale,
      'chapters': chapters.map((chapter) => chapter.toJson()).toList(),
      'sceneLinks': sceneLinks.map((sceneLink) => sceneLink.toJson()).toList(),
      'relationships':
          relationships.map((relationship) => relationship.toJson()).toList(),
      'legacySource': legacySource?.toJson(),
      'authorNotes': authorNotes,
      'metadata': metadata,
    });
  }

  final String id;
  final int schemaVersion;
  final StorylineType type;
  final StorylineStatus status;
  final String title;
  final String? description;
  final int? sortOrder;
  final String? locale;
  final List<StorylineChapter> chapters;
  final List<StorylineSceneLink> sceneLinks;
  final List<StorylineRelationship> relationships;
  final StorylineLegacySource? legacySource;
  final String? authorNotes;
  final Map<String, String> metadata;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StorylineAsset &&
          other.id == id &&
          other.schemaVersion == schemaVersion &&
          other.type == type &&
          other.status == status &&
          other.title == title &&
          other.description == description &&
          other.sortOrder == sortOrder &&
          other.locale == locale &&
          _listEquals(other.chapters, chapters) &&
          _listEquals(other.sceneLinks, sceneLinks) &&
          _listEquals(other.relationships, relationships) &&
          other.legacySource == legacySource &&
          other.authorNotes == authorNotes &&
          _mapEquals(other.metadata, metadata);

  @override
  int get hashCode => Object.hash(
        id,
        schemaVersion,
        type,
        status,
        title,
        description,
        sortOrder,
        locale,
        Object.hashAll(chapters),
        Object.hashAll(sceneLinks),
        Object.hashAll(relationships),
        legacySource,
        authorNotes,
        _mapHash(metadata),
      );

  @override
  String toString() =>
      'StorylineAsset(id: $id, type: $type, status: $status, title: $title)';
}

@immutable
final class StorylineChapter {
  StorylineChapter({
    required this.id,
    required this.title,
    this.description,
    required this.order,
    List<StorylineStep> steps = const <StorylineStep>[],
    List<String> directSceneLinkIds = const <String>[],
    this.status,
    this.authorNotes,
    Map<String, String> metadata = const <String, String>{},
  })  : steps = List<StorylineStep>.unmodifiable(steps),
        directSceneLinkIds = _immutableNonBlankUniqueStrings(
            directSceneLinkIds, 'StorylineChapter.directSceneLinkIds'),
        metadata = Map<String, String>.unmodifiable(metadata) {
    _requireNotBlank(id, 'StorylineChapter.id');
    _requireNotBlank(title, 'StorylineChapter.title');
    _requireNonNegative(order, 'StorylineChapter.order');
    _validateUniqueIds(
      this.steps.map((step) => step.id),
      'StorylineChapter.steps',
    );
  }

  factory StorylineChapter.fromJson(Map<String, dynamic> json) {
    return StorylineChapter(
      id: _readRequiredString(json, 'id'),
      title: _readRequiredString(json, 'title'),
      description: _readOptionalString(json, 'description'),
      order: _readRequiredInt(json, 'order'),
      steps: _readObjectList(json, 'steps', StorylineStep.fromJson),
      directSceneLinkIds: _readStringList(json, 'directSceneLinkIds'),
      status:
          _readOptionalEnum(StorylineStatus.values, json['status'], 'status'),
      authorNotes: _readOptionalString(json, 'authorNotes'),
      metadata: _readStringMap(json, 'metadata'),
    );
  }

  Map<String, dynamic> toJson() {
    return _withoutNulls({
      'id': id,
      'title': title,
      'description': description,
      'order': order,
      'steps': steps.map((step) => step.toJson()).toList(),
      'directSceneLinkIds': directSceneLinkIds,
      'status': status == null ? null : _enumToJson(status!),
      'authorNotes': authorNotes,
      'metadata': metadata,
    });
  }

  final String id;
  final String title;
  final String? description;
  final int order;
  final List<StorylineStep> steps;
  final List<String> directSceneLinkIds;
  final StorylineStatus? status;
  final String? authorNotes;
  final Map<String, String> metadata;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StorylineChapter &&
          other.id == id &&
          other.title == title &&
          other.description == description &&
          other.order == order &&
          _listEquals(other.steps, steps) &&
          _listEquals(other.directSceneLinkIds, directSceneLinkIds) &&
          other.status == status &&
          other.authorNotes == authorNotes &&
          _mapEquals(other.metadata, metadata);

  @override
  int get hashCode => Object.hash(
        id,
        title,
        description,
        order,
        Object.hashAll(steps),
        Object.hashAll(directSceneLinkIds),
        status,
        authorNotes,
        _mapHash(metadata),
      );

  @override
  String toString() => 'StorylineChapter(id: $id, title: $title)';
}

@immutable
final class StorylineStep {
  StorylineStep({
    required this.id,
    required this.title,
    this.description,
    required this.order,
    this.entryCondition,
    this.completionCondition,
    List<String> sceneLinkIds = const <String>[],
    List<String> expectedOutcomeIds = const <String>[],
    this.status,
    this.authorNotes,
    Map<String, String> metadata = const <String, String>{},
  })  : sceneLinkIds = _immutableNonBlankUniqueStrings(
          sceneLinkIds,
          'StorylineStep.sceneLinkIds',
        ),
        expectedOutcomeIds = _immutableNonBlankUniqueStrings(
          expectedOutcomeIds,
          'StorylineStep.expectedOutcomeIds',
        ),
        metadata = Map<String, String>.unmodifiable(metadata) {
    _requireNotBlank(id, 'StorylineStep.id');
    _requireNotBlank(title, 'StorylineStep.title');
    _requireNonNegative(order, 'StorylineStep.order');
  }

  factory StorylineStep.fromJson(Map<String, dynamic> json) {
    return StorylineStep(
      id: _readRequiredString(json, 'id'),
      title: _readRequiredString(json, 'title'),
      description: _readOptionalString(json, 'description'),
      order: _readRequiredInt(json, 'order'),
      entryCondition: _readOptionalScriptCondition(json, 'entryCondition'),
      completionCondition:
          _readOptionalScriptCondition(json, 'completionCondition'),
      sceneLinkIds: _readStringList(json, 'sceneLinkIds'),
      expectedOutcomeIds: _readStringList(json, 'expectedOutcomeIds'),
      status:
          _readOptionalEnum(StorylineStatus.values, json['status'], 'status'),
      authorNotes: _readOptionalString(json, 'authorNotes'),
      metadata: _readStringMap(json, 'metadata'),
    );
  }

  Map<String, dynamic> toJson() {
    return _withoutNulls({
      'id': id,
      'title': title,
      'description': description,
      'order': order,
      'entryCondition': entryCondition?.toJson(),
      'completionCondition': completionCondition?.toJson(),
      'sceneLinkIds': sceneLinkIds,
      'expectedOutcomeIds': expectedOutcomeIds,
      'status': status == null ? null : _enumToJson(status!),
      'authorNotes': authorNotes,
      'metadata': metadata,
    });
  }

  final String id;
  final String title;
  final String? description;
  final int order;
  final ScriptCondition? entryCondition;
  final ScriptCondition? completionCondition;
  final List<String> sceneLinkIds;
  final List<String> expectedOutcomeIds;
  final StorylineStatus? status;
  final String? authorNotes;
  final Map<String, String> metadata;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StorylineStep &&
          other.id == id &&
          other.title == title &&
          other.description == description &&
          other.order == order &&
          other.entryCondition == entryCondition &&
          other.completionCondition == completionCondition &&
          _listEquals(other.sceneLinkIds, sceneLinkIds) &&
          _listEquals(other.expectedOutcomeIds, expectedOutcomeIds) &&
          other.status == status &&
          other.authorNotes == authorNotes &&
          _mapEquals(other.metadata, metadata);

  @override
  int get hashCode => Object.hash(
        id,
        title,
        description,
        order,
        entryCondition,
        completionCondition,
        Object.hashAll(sceneLinkIds),
        Object.hashAll(expectedOutcomeIds),
        status,
        authorNotes,
        _mapHash(metadata),
      );
}

@immutable
final class StorylineSceneLink {
  StorylineSceneLink({
    required this.id,
    required this.chapterId,
    this.stepId,
    required this.label,
    required this.state,
    required this.role,
    this.sceneRef,
    required this.order,
    List<String> expectedOutcomeIds = const <String>[],
    List<StorylineSceneOutcomeLink> outcomeLinks =
        const <StorylineSceneOutcomeLink>[],
    this.authorNotes,
    Map<String, String> metadata = const <String, String>{},
  })  : expectedOutcomeIds = _immutableNonBlankUniqueStrings(
          expectedOutcomeIds,
          'StorylineSceneLink.expectedOutcomeIds',
        ),
        outcomeLinks =
            List<StorylineSceneOutcomeLink>.unmodifiable(outcomeLinks),
        metadata = Map<String, String>.unmodifiable(metadata) {
    _requireNotBlank(id, 'StorylineSceneLink.id');
    _requireNotBlank(chapterId, 'StorylineSceneLink.chapterId');
    if (stepId != null) {
      _requireNotBlank(stepId!, 'StorylineSceneLink.stepId');
    }
    _requireNotBlank(label, 'StorylineSceneLink.label');
    _requireNonNegative(order, 'StorylineSceneLink.order');
    _validateUniqueIds(
      this.outcomeLinks.map((outcomeLink) => outcomeLink.id),
      'StorylineSceneLink.outcomeLinks',
    );
    _validateSceneLinkState(state, sceneRef);
  }

  factory StorylineSceneLink.fromJson(Map<String, dynamic> json) {
    return StorylineSceneLink(
      id: _readRequiredString(json, 'id'),
      chapterId: _readRequiredString(json, 'chapterId'),
      stepId: _readOptionalString(json, 'stepId'),
      label: _readRequiredString(json, 'label'),
      state: _readEnum(StorylineSceneLinkState.values, json['state'], 'state'),
      role: _readEnum(StorylineSceneLinkRole.values, json['role'], 'role'),
      sceneRef: _readOptionalObject(
        json,
        'sceneRef',
        StorylineSceneRef.fromJson,
      ),
      order: _readRequiredInt(json, 'order'),
      expectedOutcomeIds: _readStringList(json, 'expectedOutcomeIds'),
      outcomeLinks: _readObjectList(
        json,
        'outcomeLinks',
        StorylineSceneOutcomeLink.fromJson,
      ),
      authorNotes: _readOptionalString(json, 'authorNotes'),
      metadata: _readStringMap(json, 'metadata'),
    );
  }

  Map<String, dynamic> toJson() {
    return _withoutNulls({
      'id': id,
      'chapterId': chapterId,
      'stepId': stepId,
      'label': label,
      'state': _enumToJson(state),
      'role': _enumToJson(role),
      'sceneRef': sceneRef?.toJson(),
      'order': order,
      'expectedOutcomeIds': expectedOutcomeIds,
      'outcomeLinks':
          outcomeLinks.map((outcomeLink) => outcomeLink.toJson()).toList(),
      'authorNotes': authorNotes,
      'metadata': metadata,
    });
  }

  final String id;
  final String chapterId;
  final String? stepId;
  final String label;
  final StorylineSceneLinkState state;
  final StorylineSceneLinkRole role;
  final StorylineSceneRef? sceneRef;
  final int order;
  final List<String> expectedOutcomeIds;
  final List<StorylineSceneOutcomeLink> outcomeLinks;
  final String? authorNotes;
  final Map<String, String> metadata;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StorylineSceneLink &&
          other.id == id &&
          other.chapterId == chapterId &&
          other.stepId == stepId &&
          other.label == label &&
          other.state == state &&
          other.role == role &&
          other.sceneRef == sceneRef &&
          other.order == order &&
          _listEquals(other.expectedOutcomeIds, expectedOutcomeIds) &&
          _listEquals(other.outcomeLinks, outcomeLinks) &&
          other.authorNotes == authorNotes &&
          _mapEquals(other.metadata, metadata);

  @override
  int get hashCode => Object.hash(
        id,
        chapterId,
        stepId,
        label,
        state,
        role,
        sceneRef,
        order,
        Object.hashAll(expectedOutcomeIds),
        Object.hashAll(outcomeLinks),
        authorNotes,
        _mapHash(metadata),
      );
}

@immutable
final class StorylineSceneRef {
  StorylineSceneRef({
    required this.kind,
    required this.targetId,
  }) {
    _requireNotBlank(targetId, 'StorylineSceneRef.targetId');
  }

  factory StorylineSceneRef.fromJson(Map<String, dynamic> json) {
    return StorylineSceneRef(
      kind: _readEnum(StorylineSceneRefKind.values, json['kind'], 'kind'),
      targetId: _readRequiredString(json, 'targetId'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'kind': _enumToJson(kind),
      'targetId': targetId,
    };
  }

  final StorylineSceneRefKind kind;
  final String targetId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StorylineSceneRef &&
          other.kind == kind &&
          other.targetId == targetId;

  @override
  int get hashCode => Object.hash(kind, targetId);
}

@immutable
final class StorylineSceneOutcomeLink {
  StorylineSceneOutcomeLink({
    required this.id,
    required this.outcomeId,
    this.label,
    required List<StorylineEffect> effects,
    this.notes,
    Map<String, String> metadata = const <String, String>{},
  })  : effects = List<StorylineEffect>.unmodifiable(effects),
        metadata = Map<String, String>.unmodifiable(metadata) {
    _requireNotBlank(id, 'StorylineSceneOutcomeLink.id');
    _requireNotBlank(outcomeId, 'StorylineSceneOutcomeLink.outcomeId');
    if (this.effects.isEmpty) {
      throw const ValidationException(
        'StorylineSceneOutcomeLink.effects must not be empty',
      );
    }
  }

  factory StorylineSceneOutcomeLink.fromJson(Map<String, dynamic> json) {
    return StorylineSceneOutcomeLink(
      id: _readRequiredString(json, 'id'),
      outcomeId: _readRequiredString(json, 'outcomeId'),
      label: _readOptionalString(json, 'label'),
      effects: _readObjectList(json, 'effects', StorylineEffect.fromJson),
      notes: _readOptionalString(json, 'notes'),
      metadata: _readStringMap(json, 'metadata'),
    );
  }

  Map<String, dynamic> toJson() {
    return _withoutNulls({
      'id': id,
      'outcomeId': outcomeId,
      'label': label,
      'effects': effects.map((effect) => effect.toJson()).toList(),
      'notes': notes,
      'metadata': metadata,
    });
  }

  final String id;
  final String outcomeId;
  final String? label;
  final List<StorylineEffect> effects;
  final String? notes;
  final Map<String, String> metadata;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StorylineSceneOutcomeLink &&
          other.id == id &&
          other.outcomeId == outcomeId &&
          other.label == label &&
          _listEquals(other.effects, effects) &&
          other.notes == notes &&
          _mapEquals(other.metadata, metadata);

  @override
  int get hashCode => Object.hash(
        id,
        outcomeId,
        label,
        Object.hashAll(effects),
        notes,
        _mapHash(metadata),
      );
}

@immutable
final class StorylineEffect {
  StorylineEffect({
    required this.type,
    required this.targetId,
    this.value,
  }) {
    _requireNotBlank(targetId, 'StorylineEffect.targetId');
  }

  factory StorylineEffect.fromJson(Map<String, dynamic> json) {
    return StorylineEffect(
      type: _readEnum(StorylineEffectType.values, json['type'], 'type'),
      targetId: _readRequiredString(json, 'targetId'),
      value: _readOptionalString(json, 'value'),
    );
  }

  Map<String, dynamic> toJson() {
    return _withoutNulls({
      'type': _enumToJson(type),
      'targetId': targetId,
      'value': value,
    });
  }

  final StorylineEffectType type;
  final String targetId;
  final String? value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StorylineEffect &&
          other.type == type &&
          other.targetId == targetId &&
          other.value == value;

  @override
  int get hashCode => Object.hash(type, targetId, value);
}

@immutable
final class StorylineRelationship {
  StorylineRelationship({
    required this.id,
    required this.kind,
    required this.sourceStorylineId,
    required this.targetStorylineId,
    this.anchor,
    this.availability,
    this.condition,
    this.notes,
    Map<String, String> metadata = const <String, String>{},
  }) : metadata = Map<String, String>.unmodifiable(metadata) {
    _requireNotBlank(id, 'StorylineRelationship.id');
    _requireNotBlank(
      sourceStorylineId,
      'StorylineRelationship.sourceStorylineId',
    );
    _requireNotBlank(
      targetStorylineId,
      'StorylineRelationship.targetStorylineId',
    );
    if (sourceStorylineId == targetStorylineId) {
      throw const ValidationException(
        'StorylineRelationship source and target must differ',
      );
    }
  }

  factory StorylineRelationship.fromJson(Map<String, dynamic> json) {
    return StorylineRelationship(
      id: _readRequiredString(json, 'id'),
      kind: _readEnum(
        StorylineRelationshipKind.values,
        json['kind'],
        'kind',
      ),
      sourceStorylineId: _readRequiredString(json, 'sourceStorylineId'),
      targetStorylineId: _readRequiredString(json, 'targetStorylineId'),
      anchor: _readOptionalObject(json, 'anchor', StorylineAnchor.fromJson),
      availability: _readOptionalObject(
        json,
        'availability',
        SideQuestAvailability.fromJson,
      ),
      condition: _readOptionalScriptCondition(json, 'condition'),
      notes: _readOptionalString(json, 'notes'),
      metadata: _readStringMap(json, 'metadata'),
    );
  }

  Map<String, dynamic> toJson() {
    return _withoutNulls({
      'id': id,
      'kind': _enumToJson(kind),
      'sourceStorylineId': sourceStorylineId,
      'targetStorylineId': targetStorylineId,
      'anchor': anchor?.toJson(),
      'availability': availability?.toJson(),
      'condition': condition?.toJson(),
      'notes': notes,
      'metadata': metadata,
    });
  }

  final String id;
  final StorylineRelationshipKind kind;
  final String sourceStorylineId;
  final String targetStorylineId;
  final StorylineAnchor? anchor;
  final SideQuestAvailability? availability;
  final ScriptCondition? condition;
  final String? notes;
  final Map<String, String> metadata;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StorylineRelationship &&
          other.id == id &&
          other.kind == kind &&
          other.sourceStorylineId == sourceStorylineId &&
          other.targetStorylineId == targetStorylineId &&
          other.anchor == anchor &&
          other.availability == availability &&
          other.condition == condition &&
          other.notes == notes &&
          _mapEquals(other.metadata, metadata);

  @override
  int get hashCode => Object.hash(
        id,
        kind,
        sourceStorylineId,
        targetStorylineId,
        anchor,
        availability,
        condition,
        notes,
        _mapHash(metadata),
      );
}

@immutable
final class SideQuestAvailability {
  SideQuestAvailability({
    required this.startAnchor,
    this.endAnchor,
    this.availabilityCondition,
    this.expiresCondition,
    List<String> requiredOutcomeIds = const <String>[],
  }) : requiredOutcomeIds = _immutableNonBlankUniqueStrings(
          requiredOutcomeIds,
          'SideQuestAvailability.requiredOutcomeIds',
        );

  factory SideQuestAvailability.fromJson(Map<String, dynamic> json) {
    return SideQuestAvailability(
      startAnchor: _readRequiredObject(
        json,
        'startAnchor',
        StorylineAnchor.fromJson,
      ),
      endAnchor:
          _readOptionalObject(json, 'endAnchor', StorylineAnchor.fromJson),
      availabilityCondition:
          _readOptionalScriptCondition(json, 'availabilityCondition'),
      expiresCondition: _readOptionalScriptCondition(json, 'expiresCondition'),
      requiredOutcomeIds: _readStringList(json, 'requiredOutcomeIds'),
    );
  }

  Map<String, dynamic> toJson() {
    return _withoutNulls({
      'startAnchor': startAnchor.toJson(),
      'endAnchor': endAnchor?.toJson(),
      'availabilityCondition': availabilityCondition?.toJson(),
      'expiresCondition': expiresCondition?.toJson(),
      'requiredOutcomeIds': requiredOutcomeIds,
    });
  }

  final StorylineAnchor startAnchor;
  final StorylineAnchor? endAnchor;
  final ScriptCondition? availabilityCondition;
  final ScriptCondition? expiresCondition;
  final List<String> requiredOutcomeIds;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SideQuestAvailability &&
          other.startAnchor == startAnchor &&
          other.endAnchor == endAnchor &&
          other.availabilityCondition == availabilityCondition &&
          other.expiresCondition == expiresCondition &&
          _listEquals(other.requiredOutcomeIds, requiredOutcomeIds);

  @override
  int get hashCode => Object.hash(
        startAnchor,
        endAnchor,
        availabilityCondition,
        expiresCondition,
        Object.hashAll(requiredOutcomeIds),
      );
}

@immutable
final class StorylineAnchor {
  StorylineAnchor({
    required this.kind,
    required this.targetId,
  }) {
    _requireNotBlank(targetId, 'StorylineAnchor.targetId');
  }

  factory StorylineAnchor.fromJson(Map<String, dynamic> json) {
    return StorylineAnchor(
      kind: _readEnum(StorylineAnchorKind.values, json['kind'], 'kind'),
      targetId: _readRequiredString(json, 'targetId'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'kind': _enumToJson(kind),
      'targetId': targetId,
    };
  }

  final StorylineAnchorKind kind;
  final String targetId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StorylineAnchor &&
          other.kind == kind &&
          other.targetId == targetId;

  @override
  int get hashCode => Object.hash(kind, targetId);
}

@immutable
final class StorylineValidationIssue {
  StorylineValidationIssue({
    this.id,
    required this.severity,
    required this.targetRef,
    required this.ruleId,
    required this.message,
  }) {
    if (id != null) {
      _requireNotBlank(id!, 'StorylineValidationIssue.id');
    }
    _requireNotBlank(targetRef, 'StorylineValidationIssue.targetRef');
    _requireNotBlank(ruleId, 'StorylineValidationIssue.ruleId');
    _requireNotBlank(message, 'StorylineValidationIssue.message');
  }

  factory StorylineValidationIssue.fromJson(Map<String, dynamic> json) {
    return StorylineValidationIssue(
      id: _readOptionalString(json, 'id'),
      severity: _readEnum(
        StorylineValidationSeverity.values,
        json['severity'],
        'severity',
      ),
      targetRef: _readRequiredString(json, 'targetRef'),
      ruleId: _readRequiredString(json, 'ruleId'),
      message: _readRequiredString(json, 'message'),
    );
  }

  Map<String, dynamic> toJson() {
    return _withoutNulls({
      'id': id,
      'severity': _enumToJson(severity),
      'targetRef': targetRef,
      'ruleId': ruleId,
      'message': message,
    });
  }

  final String? id;
  final StorylineValidationSeverity severity;
  final String targetRef;
  final String ruleId;
  final String message;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StorylineValidationIssue &&
          other.id == id &&
          other.severity == severity &&
          other.targetRef == targetRef &&
          other.ruleId == ruleId &&
          other.message == message;

  @override
  int get hashCode => Object.hash(id, severity, targetRef, ruleId, message);
}

@immutable
final class StorylineLegacySource {
  StorylineLegacySource({
    required this.kind,
    required this.sourceId,
    Map<String, String> metadata = const <String, String>{},
  }) : metadata = Map<String, String>.unmodifiable(metadata) {
    _requireNotBlank(kind, 'StorylineLegacySource.kind');
    _requireNotBlank(sourceId, 'StorylineLegacySource.sourceId');
  }

  factory StorylineLegacySource.fromJson(Map<String, dynamic> json) {
    return StorylineLegacySource(
      kind: _readRequiredString(json, 'kind'),
      sourceId: _readRequiredString(json, 'sourceId'),
      metadata: _readStringMap(json, 'metadata'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'kind': kind,
      'sourceId': sourceId,
      'metadata': metadata,
    };
  }

  final String kind;
  final String sourceId;
  final Map<String, String> metadata;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StorylineLegacySource &&
          other.kind == kind &&
          other.sourceId == sourceId &&
          _mapEquals(other.metadata, metadata);

  @override
  int get hashCode => Object.hash(
        kind,
        sourceId,
        _mapHash(metadata),
      );
}

Iterable<StorylineStep> _allSteps(List<StorylineChapter> chapters) sync* {
  for (final chapter in chapters) {
    yield* chapter.steps;
  }
}

void _validateSceneLinkReferences(
  List<StorylineChapter> chapters,
  List<StorylineSceneLink> sceneLinks,
) {
  final chapterIds = chapters.map((chapter) => chapter.id).toSet();
  final stepToChapter = <String, String>{};
  for (final chapter in chapters) {
    for (final step in chapter.steps) {
      stepToChapter[step.id] = chapter.id;
    }
  }

  for (final sceneLink in sceneLinks) {
    if (!chapterIds.contains(sceneLink.chapterId)) {
      throw ValidationException(
        'StorylineSceneLink ${sceneLink.id} references missing chapter '
        '${sceneLink.chapterId}',
      );
    }
    final stepId = sceneLink.stepId;
    if (stepId != null && !stepToChapter.containsKey(stepId)) {
      throw ValidationException(
        'StorylineSceneLink ${sceneLink.id} references missing step $stepId',
      );
    }
    if (stepId != null && stepToChapter[stepId] != sceneLink.chapterId) {
      throw ValidationException(
        'StorylineSceneLink ${sceneLink.id} step $stepId does not belong to '
        'chapter ${sceneLink.chapterId}',
      );
    }
  }
}

void _validateSceneLinkState(
  StorylineSceneLinkState state,
  StorylineSceneRef? sceneRef,
) {
  switch (state) {
    case StorylineSceneLinkState.placeholder:
      if (sceneRef != null) {
        throw const ValidationException(
          'placeholder StorylineSceneLink must not have sceneRef',
        );
      }
    case StorylineSceneLinkState.linkedScenario:
      if (sceneRef == null) {
        throw const ValidationException(
          'linkedScenario StorylineSceneLink requires sceneRef',
        );
      }
      if (sceneRef.kind != StorylineSceneRefKind.scenario) {
        throw const ValidationException(
          'linkedScenario StorylineSceneLink requires scenario sceneRef',
        );
      }
    case StorylineSceneLinkState.brokenLink:
      break;
    case StorylineSceneLinkState.needsImplementation:
      if (sceneRef != null) {
        throw const ValidationException(
          'needsImplementation StorylineSceneLink must not have sceneRef',
        );
      }
  }
}

List<String> _immutableNonBlankUniqueStrings(
  List<String> values,
  String fieldName,
) {
  for (final value in values) {
    _requireNotBlank(value, fieldName);
  }
  _validateUniqueIds(values, fieldName);
  return List<String>.unmodifiable(values);
}

void _validateUniqueIds(Iterable<String> ids, String fieldName) {
  final seen = <String>{};
  for (final id in ids) {
    if (!seen.add(id)) {
      throw ValidationException('$fieldName contains duplicate id $id');
    }
  }
}

void _requireNotBlank(String value, String fieldName) {
  if (value.trim().isEmpty) {
    throw ValidationException('$fieldName must not be empty');
  }
}

void _requireNonNegative(int value, String fieldName) {
  if (value < 0) {
    throw ValidationException('$fieldName must be >= 0');
  }
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) {
    return true;
  }
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i += 1) {
    if (a[i] != b[i]) {
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
  for (final entry in a.entries) {
    if (!b.containsKey(entry.key) || b[entry.key] != entry.value) {
      return false;
    }
  }
  return true;
}

int _mapHash<K, V>(Map<K, V> map) {
  return Object.hashAllUnordered(
    map.entries.map((entry) => Object.hash(entry.key, entry.value)),
  );
}

Map<String, dynamic> _withoutNulls(Map<String, dynamic> json) {
  return {
    for (final entry in json.entries)
      if (entry.value != null) entry.key: entry.value,
  };
}

String _enumToJson(Enum value) => value.name;

T _readEnum<T extends Enum>(
  List<T> values,
  Object? value,
  String fieldName, {
  T? defaultValue,
}) {
  if (value == null && defaultValue != null) {
    return defaultValue;
  }
  if (value is! String) {
    throw FormatException('$fieldName must be a string enum value');
  }
  for (final enumValue in values) {
    if (enumValue.name == value) {
      return enumValue;
    }
  }
  throw FormatException('$fieldName has unknown enum value $value');
}

T? _readOptionalEnum<T extends Enum>(
  List<T> values,
  Object? value,
  String fieldName,
) {
  if (value == null) {
    return null;
  }
  return _readEnum(values, value, fieldName);
}

String _readRequiredString(Map<String, dynamic> json, String fieldName) {
  final value = json[fieldName];
  if (value is! String) {
    throw FormatException('$fieldName must be a string');
  }
  return value;
}

String? _readOptionalString(Map<String, dynamic> json, String fieldName) {
  final value = json[fieldName];
  if (value == null) {
    return null;
  }
  if (value is! String) {
    throw FormatException('$fieldName must be a string');
  }
  return value;
}

int _readRequiredInt(Map<String, dynamic> json, String fieldName) {
  final value = json[fieldName];
  if (value is! int) {
    throw FormatException('$fieldName must be an int');
  }
  return value;
}

int _readInt(
  Map<String, dynamic> json,
  String fieldName, {
  required int defaultValue,
}) {
  final value = json[fieldName];
  if (value == null) {
    return defaultValue;
  }
  if (value is! int) {
    throw FormatException('$fieldName must be an int');
  }
  return value;
}

int? _readOptionalInt(Map<String, dynamic> json, String fieldName) {
  final value = json[fieldName];
  if (value == null) {
    return null;
  }
  if (value is! int) {
    throw FormatException('$fieldName must be an int');
  }
  return value;
}

Map<String, String> _readStringMap(
  Map<String, dynamic> json,
  String fieldName,
) {
  final value = json[fieldName];
  if (value == null) {
    return const <String, String>{};
  }
  if (value is! Map) {
    throw FormatException('$fieldName must be a map');
  }
  final result = <String, String>{};
  for (final entry in value.entries) {
    if (entry.key is! String || entry.value is! String) {
      throw FormatException('$fieldName must contain only string values');
    }
    result[entry.key as String] = entry.value as String;
  }
  return result;
}

List<String> _readStringList(Map<String, dynamic> json, String fieldName) {
  final value = json[fieldName];
  if (value == null) {
    return const <String>[];
  }
  if (value is! List) {
    throw FormatException('$fieldName must be a list');
  }
  return [
    for (final item in value)
      if (item is String)
        item
      else
        throw FormatException('$fieldName must contain only strings'),
  ];
}

List<T> _readObjectList<T>(
  Map<String, dynamic> json,
  String fieldName,
  T Function(Map<String, dynamic>) decode,
) {
  final value = json[fieldName];
  if (value == null) {
    return <T>[];
  }
  if (value is! List) {
    throw FormatException('$fieldName must be a list');
  }
  return [
    for (final item in value) decode(_asJsonObject(item, fieldName)),
  ];
}

T _readRequiredObject<T>(
  Map<String, dynamic> json,
  String fieldName,
  T Function(Map<String, dynamic>) decode,
) {
  return decode(_asJsonObject(json[fieldName], fieldName));
}

T? _readOptionalObject<T>(
  Map<String, dynamic> json,
  String fieldName,
  T Function(Map<String, dynamic>) decode,
) {
  final value = json[fieldName];
  if (value == null) {
    return null;
  }
  return decode(_asJsonObject(value, fieldName));
}

ScriptCondition? _readOptionalScriptCondition(
  Map<String, dynamic> json,
  String fieldName,
) {
  final value = json[fieldName];
  if (value == null) {
    return null;
  }
  return ScriptCondition.fromJson(_asJsonObject(value, fieldName));
}

Map<String, dynamic> _asJsonObject(Object? value, String fieldName) {
  if (value is! Map) {
    throw FormatException('$fieldName must be a JSON object');
  }
  return value.map((key, item) {
    if (key is! String) {
      throw FormatException('$fieldName must use string keys');
    }
    return MapEntry(key, item);
  });
}
```

### Contenu complet de storyline_asset_json_test.dart

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('StorylineAsset JSON roundtrip', () {
    test('round-trips minimal main draft', () {
      final storyline = StorylineAsset(
        id: 'main_story',
        type: StorylineType.main,
        title: 'Main Story',
      );

      final json = storyline.toJson();
      final decoded = StorylineAsset.fromJson(json);

      expect(decoded, equals(storyline));
      expect(json['type'], 'main');
      expect(json['status'], 'draft');
      expect(json['chapters'], isA<List<dynamic>>());
      expect(json['sceneLinks'], isA<List<dynamic>>());
      expect(json['relationships'], isA<List<dynamic>>());
      expect(json['metadata'], isA<Map<String, String>>());
    });

    test('round-trips minimal side quest draft', () {
      final storyline = StorylineAsset(
        id: 'side_story',
        type: StorylineType.sideQuest,
        title: 'Side Story',
      );

      expect(StorylineAsset.fromJson(storyline.toJson()), equals(storyline));
    });

    test('round-trips complete authoring shape', () {
      final storyline = _completeStoryline();

      final json = storyline.toJson();
      final decoded = StorylineAsset.fromJson(json);

      expect(decoded, equals(storyline));
      expect(
        decoded.chapters.single.steps.single.entryCondition?.type,
        ScriptConditionType.flagIsSet,
      );
      expect(
        decoded.relationships.single.availability?.availabilityCondition?.type,
        ScriptConditionType.flagIsSet,
      );
    });
  });

  group('StorylineAsset JSON enum strings', () {
    test('uses stable lowerCamel strings and never enum indexes', () {
      final json = _completeStoryline().toJson();
      final sceneLinks = json['sceneLinks'] as List<dynamic>;
      final linkedScene = sceneLinks[1] as Map<String, dynamic>;
      final sceneRef = linkedScene['sceneRef'] as Map<String, dynamic>;
      final outcomeLinks = linkedScene['outcomeLinks'] as List<dynamic>;
      final outcomeLink = outcomeLinks.single as Map<String, dynamic>;
      final effects = outcomeLink['effects'] as List<dynamic>;
      final effect = effects.first as Map<String, dynamic>;
      final relationships = json['relationships'] as List<dynamic>;
      final relationship = relationships.single as Map<String, dynamic>;
      final availability = relationship['availability'] as Map<String, dynamic>;
      final endAnchor = availability['endAnchor'] as Map<String, dynamic>;

      expect(json['type'], 'sideQuest');
      expect(json['status'], 'active');
      expect(linkedScene['state'], 'linkedScenario');
      expect(linkedScene['role'], 'branch');
      expect(sceneRef['kind'], 'scenario');
      expect(effect['type'], 'activateStep');
      expect(relationship['kind'], 'sideQuestAvailableDuring');
      expect(endAnchor['kind'], 'sceneOutcome');
      expect(json['type'], isNot(isA<int>()));
      expect(linkedScene['state'], isNot(isA<int>()));
      expect(effect['type'], isNot(isA<int>()));
    });
  });

  group('StorylineAsset JSON defaults', () {
    test('decodes defaults from minimal JSON', () {
      final decoded = StorylineAsset.fromJson({
        'id': 'story',
        'type': 'main',
        'title': 'Story',
      });

      expect(decoded.schemaVersion, 1);
      expect(decoded.status, StorylineStatus.draft);
      expect(decoded.chapters, isEmpty);
      expect(decoded.sceneLinks, isEmpty);
      expect(decoded.relationships, isEmpty);
      expect(decoded.metadata, isEmpty);
    });
  });

  group('StorylineAsset invalid JSON', () {
    test('rejects unknown or mistyped top-level fields', () {
      expect(
        () => StorylineAsset.fromJson({
          'id': 'story',
          'type': 'unknown',
          'title': 'Story',
        }),
        _throwsFormat,
      );
      expect(
        () => StorylineAsset.fromJson({
          'id': 'story',
          'type': 'main',
          'status': 'unknown',
          'title': 'Story',
        }),
        _throwsFormat,
      );
      expect(
        () => StorylineAsset.fromJson({'type': 'main', 'title': 'Story'}),
        _throwsFormat,
      );
      expect(
        () => StorylineAsset.fromJson({'id': 'story', 'title': 'Story'}),
        _throwsFormat,
      );
      expect(
        () => StorylineAsset.fromJson({'id': 'story', 'type': 'main'}),
        _throwsFormat,
      );
      expect(
        () => StorylineAsset.fromJson({
          'id': 'story',
          'schemaVersion': '1',
          'type': 'main',
          'title': 'Story',
        }),
        _throwsFormat,
      );
      expect(
        () => StorylineAsset.fromJson({
          'id': 'story',
          'type': 'main',
          'title': 'Story',
          'chapters': 'not-list',
        }),
        _throwsFormat,
      );
      expect(
        () => StorylineAsset.fromJson({
          'id': 'story',
          'type': 'main',
          'title': 'Story',
          'metadata': 'not-map',
        }),
        _throwsFormat,
      );
      expect(
        () => StorylineAsset.fromJson({
          'id': 'story',
          'type': 'main',
          'title': 'Story',
          'metadata': {'ok': 1},
        }),
        _throwsFormat,
      );
    });

    test('rejects unknown nested enum values', () {
      final invalidSceneRef = _completeStoryline().toJson();
      final sceneLinks = invalidSceneRef['sceneLinks'] as List<dynamic>;
      final linkedScene = sceneLinks[1] as Map<String, dynamic>;
      final sceneRef = linkedScene['sceneRef'] as Map<String, dynamic>;
      sceneRef['kind'] = 'dialogue';

      expect(() => StorylineAsset.fromJson(invalidSceneRef), _throwsFormat);

      final invalidEffect = _completeStoryline().toJson();
      final invalidEffectSceneLinks = invalidEffect['sceneLinks'] as List;
      final invalidEffectScene =
          invalidEffectSceneLinks[1] as Map<String, dynamic>;
      final outcomeLinks = invalidEffectScene['outcomeLinks'] as List;
      final outcomeLink = outcomeLinks.single as Map<String, dynamic>;
      final effects = outcomeLink['effects'] as List;
      final effect = effects.first as Map<String, dynamic>;
      effect['type'] = 'unknownEffect';

      expect(() => StorylineAsset.fromJson(invalidEffect), _throwsFormat);
    });
  });

  group('StorylineAsset JSON constructor validation', () {
    test('rejects duplicate chapter ids during decode', () {
      final json = _completeStoryline().toJson();
      json['chapters'] = [
        (json['chapters'] as List).single,
        (json['chapters'] as List).single,
      ];

      expect(() => StorylineAsset.fromJson(json), _throwsDecode);
    });

    test('rejects scene link references to missing chapter or step', () {
      final missingChapter = _completeStoryline().toJson();
      final missingChapterSceneLinks = missingChapter['sceneLinks'] as List;
      final sceneLink = missingChapterSceneLinks.first as Map<String, dynamic>;
      sceneLink['chapterId'] = 'missing';

      expect(() => StorylineAsset.fromJson(missingChapter), _throwsDecode);

      final missingStep = _completeStoryline().toJson();
      final missingStepSceneLinks = missingStep['sceneLinks'] as List;
      final missingStepLink =
          missingStepSceneLinks.first as Map<String, dynamic>;
      missingStepLink['stepId'] = 'missing';

      expect(() => StorylineAsset.fromJson(missingStep), _throwsDecode);
    });

    test('rejects invalid scene link state combinations', () {
      final placeholderWithRef = _completeStoryline().toJson();
      final placeholderSceneLinks = placeholderWithRef['sceneLinks'] as List;
      final placeholder = placeholderSceneLinks.first as Map<String, dynamic>;
      placeholder['sceneRef'] = {
        'kind': 'scenario',
        'targetId': 'scenario',
      };

      expect(() => StorylineAsset.fromJson(placeholderWithRef), _throwsDecode);

      final linkedWithoutRef = _completeStoryline().toJson();
      final linkedSceneLinks = linkedWithoutRef['sceneLinks'] as List;
      final linked = linkedSceneLinks[1] as Map<String, dynamic>;
      linked.remove('sceneRef');

      expect(() => StorylineAsset.fromJson(linkedWithoutRef), _throwsDecode);
    });

    test('rejects inline relationship source mismatch', () {
      final json = _completeStoryline().toJson();
      final relationships = json['relationships'] as List;
      final relationship = relationships.single as Map<String, dynamic>;
      relationship['sourceStorylineId'] = 'other_story';

      expect(() => StorylineAsset.fromJson(json), _throwsDecode);
    });
  });
}

final Matcher _throwsFormat = throwsA(isA<FormatException>());
final Matcher _throwsDecode = throwsA(
  anyOf(isA<FormatException>(), isA<ValidationException>()),
);

StorylineAsset _completeStoryline() {
  return StorylineAsset(
    id: 'side_story',
    schemaVersion: 1,
    type: StorylineType.sideQuest,
    status: StorylineStatus.active,
    title: 'Side Story',
    description: 'Optional branch.',
    sortOrder: 2,
    locale: 'fr',
    chapters: [
      StorylineChapter(
        id: 'chapter_1',
        title: 'Chapter One',
        description: 'Chapter description.',
        order: 0,
        directSceneLinkIds: const ['scene_placeholder'],
        status: StorylineStatus.active,
        authorNotes: 'Chapter notes.',
        metadata: const {'chapterKey': 'chapterValue'},
        steps: [
          StorylineStep(
            id: 'step_1',
            title: 'Find the clue',
            description: 'Step description.',
            order: 0,
            entryCondition: ScriptConditionFactory.flagIsSet('side.started'),
            completionCondition:
                ScriptConditionFactory.eventIsConsumed('event_clue'),
            sceneLinkIds: const ['scene_placeholder', 'scene_linked'],
            expectedOutcomeIds: const ['outcome_a'],
            status: StorylineStatus.active,
            authorNotes: 'Step notes.',
            metadata: const {'stepKey': 'stepValue'},
          ),
        ],
      ),
    ],
    sceneLinks: [
      StorylineSceneLink(
        id: 'scene_placeholder',
        chapterId: 'chapter_1',
        stepId: 'step_1',
        label: 'Placeholder Scene',
        state: StorylineSceneLinkState.placeholder,
        role: StorylineSceneLinkRole.setup,
        order: 0,
        expectedOutcomeIds: const ['outcome_planned'],
        authorNotes: 'Placeholder notes.',
        metadata: const {'placeholderKey': 'placeholderValue'},
      ),
      StorylineSceneLink(
        id: 'scene_linked',
        chapterId: 'chapter_1',
        stepId: 'step_1',
        label: 'Linked Scene',
        state: StorylineSceneLinkState.linkedScenario,
        role: StorylineSceneLinkRole.branch,
        sceneRef: StorylineSceneRef(
          kind: StorylineSceneRefKind.scenario,
          targetId: 'scenario_intro',
        ),
        order: 1,
        expectedOutcomeIds: const ['outcome_a'],
        outcomeLinks: [
          StorylineSceneOutcomeLink(
            id: 'outcome_link',
            outcomeId: 'outcome_a',
            label: 'Success',
            effects: [
              StorylineEffect(
                type: StorylineEffectType.activateStep,
                targetId: 'step_2',
              ),
              StorylineEffect(
                type: StorylineEffectType.completeStep,
                targetId: 'step_1',
              ),
              StorylineEffect(
                type: StorylineEffectType.unlockStoryline,
                targetId: 'main_story',
              ),
            ],
            notes: 'Outcome notes.',
            metadata: const {'outcomeKey': 'outcomeValue'},
          ),
        ],
        authorNotes: 'Linked notes.',
        metadata: const {'sceneKey': 'sceneValue'},
      ),
    ],
    relationships: [
      StorylineRelationship(
        id: 'rel_1',
        kind: StorylineRelationshipKind.sideQuestAvailableDuring,
        sourceStorylineId: 'side_story',
        targetStorylineId: 'main_story',
        anchor: StorylineAnchor(
          kind: StorylineAnchorKind.step,
          targetId: 'step_1',
        ),
        availability: SideQuestAvailability(
          startAnchor: StorylineAnchor(
            kind: StorylineAnchorKind.chapter,
            targetId: 'chapter_1',
          ),
          endAnchor: StorylineAnchor(
            kind: StorylineAnchorKind.sceneOutcome,
            targetId: 'outcome_a',
          ),
          availabilityCondition:
              ScriptConditionFactory.flagIsSet('main.chapter_1'),
          expiresCondition: ScriptConditionFactory.flagIsUnset('main.ended'),
          requiredOutcomeIds: const ['outcome_a'],
        ),
        condition: ScriptConditionFactory.playerOnMap('harbor'),
        notes: 'Relationship notes.',
        metadata: const {'relationshipKey': 'relationshipValue'},
      ),
    ],
    legacySource: StorylineLegacySource(
      kind: 'scenario.globalStory',
      sourceId: 'legacy_global',
      metadata: const {'legacyKey': 'legacyValue'},
    ),
    authorNotes: 'Story notes.',
    metadata: const {'storyKey': 'storyValue'},
  );
}
```

### Diff complet de storyline_asset_test.dart si modifié

```diff
diff --git a/packages/map_core/test/storyline_asset_test.dart b/packages/map_core/test/storyline_asset_test.dart
index 8c7dc66e..419c1279 100644
--- a/packages/map_core/test/storyline_asset_test.dart
+++ b/packages/map_core/test/storyline_asset_test.dart
@@ -641,15 +641,15 @@ void main() {
     });
   });
 
-  group('StorylineAsset V1-03 scope guards', () {
-    test('does not expose JSON codecs in pure model lot', () {
-      final dynamic storyline = StorylineAsset(
+  group('StorylineAsset V1-04 scope guards', () {
+    test('exposes JSON codec without manifest integration', () {
+      final storyline = StorylineAsset(
         id: 'story',
         type: StorylineType.main,
         title: 'Story',
       );
 
-      expect(() => storyline.toJson(), throwsA(isA<NoSuchMethodError>()));
+      expect(storyline.toJson(), containsPair('type', 'main'));
     });
   });
 }
```

### Diff complet de road_map_storylines.md

```diff
diff --git a/reports/narrativeStudio/storylines/road_map_storylines.md b/reports/narrativeStudio/storylines/road_map_storylines.md
index 3ae0e161..a1fc7cd3 100644
--- a/reports/narrativeStudio/storylines/road_map_storylines.md
+++ b/reports/narrativeStudio/storylines/road_map_storylines.md
@@ -305,7 +305,7 @@ Interprétation V0 :
 | NS-STORYLINES-V1-01 | Storyline Authoring Model Decision | model decision | DONE | NS-STORYLINES-V1-02 |
 | NS-STORYLINES-V1-02 | Storyline Authoring Data Shape Contract | data contract | DONE | NS-STORYLINES-V1-03 |
 | NS-STORYLINES-V1-03 | StorylineAsset Pure Model V0 | core model / pure dart | DONE | NS-STORYLINES-V1-04 |
-| NS-STORYLINES-V1-04 | StorylineAsset JSON Codec V0 | core codec | TODO | NS-STORYLINES-V1-05 |
+| NS-STORYLINES-V1-04 | StorylineAsset JSON Codec V0 | core codec | DONE | NS-STORYLINES-V1-05 |
 | NS-STORYLINES-V1-05 | ProjectManifest.storylines Integration V0 | core manifest | TODO | NS-STORYLINES-V1-06 |
 | NS-STORYLINES-V1-06 | Legacy GlobalStory Import Preview V0 | migration preview | TODO | NS-STORYLINES-V1-07 |
 | NS-STORYLINES-V1-07 | Create Main Storyline Flow V0 | editor authoring | TODO | NS-STORYLINES-V1-08 |
@@ -674,6 +674,22 @@ Interprétation V0 :
 - Statut : DONE.
 - Prochain lot attendu : NS-STORYLINES-V1-04 — StorylineAsset JSON Codec V0.
 
+### NS-STORYLINES-V1-04 — StorylineAsset JSON Codec V0
+
+- Type : core codec / manual JSON / pure Dart / tests.
+- Objectif : ajouter un codec JSON manuel pour `StorylineAsset` et ses sous-objets, sans intégration `ProjectManifest.storylines`.
+- Résultat : `StorylineAsset` peut faire `model -> toJson() -> fromJson(...) -> model équivalent`.
+- JSON : enums encodés en strings lowerCamel stables via `.name`, listes/maps présentes en `[]` / `{}`, champs optionnels null omis.
+- Decode : defaults `schemaVersion = 1`, `status = draft`, `chapters = []`, `sceneLinks = []`, `relationships = []`, `metadata = {}` ; erreurs de forme en `FormatException`, invariants via constructeurs / `ValidationException`.
+- ScriptCondition : codec officiel existant réutilisé (`ScriptCondition.fromJson` / `toJson` générés), sans nouveau langage conditionnel.
+- Fichiers créés/modifiés : `packages/map_core/lib/src/models/storyline_asset.dart`, `packages/map_core/test/storyline_asset_test.dart`, `packages/map_core/test/storyline_asset_json_test.dart`, `reports/narrativeStudio/storylines/ns_storylines_v1_04_storyline_asset_json_codec_v0.md`, `reports/narrativeStudio/storylines/road_map_storylines.md`.
+- Tests exécutés : `dart test test/storyline_asset_json_test.dart`, `dart test test/storyline_asset_test.dart`, `dart test test/scenario_assets_test.dart`, `dart test`.
+- Analyse exécutée : `dart analyze lib/src/models/storyline_asset.dart test/storyline_asset_test.dart test/storyline_asset_json_test.dart`.
+- Non-objectifs confirmés : aucun `ProjectManifest`, aucun `ScenarioAsset`, aucun generated file, aucun build_runner, aucune UI.
+- Dépendances : NS-STORYLINES-V1-03.
+- Statut : DONE.
+- Prochain lot attendu : NS-STORYLINES-V1-05 — ProjectManifest.storylines Integration V0.
+
 ## 10. Update protocol for every future lot
 
 Chaque futur lot Storylines doit :
@@ -790,10 +806,10 @@ Décision temporaire :
 ## 13. Current status
 
 ```text
-Roadmap status: V0 ACCEPTED WITH V1 LIMITATIONS / V1 PURE MODEL DONE
-Current lot: NS-STORYLINES-V1-03
+Roadmap status: V0 ACCEPTED WITH V1 LIMITATIONS / V1 JSON CODEC DONE
+Current lot: NS-STORYLINES-V1-04
 Current lot status: DONE
-Next recommended lot: NS-STORYLINES-V1-04 — StorylineAsset JSON Codec V0
+Next recommended lot: NS-STORYLINES-V1-05 — ProjectManifest.storylines Integration V0
 ```
 
 | Lot | Status | Last update | Notes |
@@ -816,7 +832,7 @@ Next recommended lot: NS-STORYLINES-V1-04 — StorylineAsset JSON Codec V0
 | NS-STORYLINES-V1-01 | DONE | 2026-05-28 | Modèle hybride retenu : `StorylineAsset` authoring + `ScenarioAsset` executable scene flow ; Structure source d'authoring, Graph généré. |
 | NS-STORYLINES-V1-02 | DONE | 2026-05-28 | Contrat data shape `StorylineAsset` livré : champs, enums, invariants, validations, JSON, migration legacy, UI actions et tests futurs. |
 | NS-STORYLINES-V1-03 | DONE | 2026-05-28 | StorylineAsset Pure Model V0 livré dans `map_core`, sans JSON/manifest/UI. |
-| NS-STORYLINES-V1-04 | TODO | 2026-05-28 | StorylineAsset JSON Codec V0. |
+| NS-STORYLINES-V1-04 | DONE | 2026-05-28 | StorylineAsset JSON Codec V0 livré, sans manifest/migration/UI. |
 | NS-STORYLINES-V1-05 | TODO | 2026-05-28 | ProjectManifest.storylines Integration V0. |
 | NS-STORYLINES-V1-06 | TODO | 2026-05-28 | Legacy GlobalStory Import Preview V0. |
 | NS-STORYLINES-V1-07 | TODO | 2026-05-28 | Create Main Storyline Flow V0. |
@@ -854,6 +870,16 @@ Suite V1 documentaire recommandée :
 
 ## 15. Changelog
 
+### 2026-05-28 — NS-STORYLINES-V1-04
+
+- Codec JSON manuel livré pour `StorylineAsset` et ses sous-objets essentiels.
+- Enums Storylines sérialisés en strings lowerCamel stables, jamais en index.
+- Decode strict : erreurs de forme en `FormatException`, invariants métiers préservés par les constructeurs.
+- `ScriptCondition` sérialisé via le codec officiel existant ; aucun langage conditionnel local ajouté.
+- Tests JSON ajoutés : roundtrip minimal/complet, defaults, enums, invalid JSON et validations au decode.
+- Non-objectifs respectés : aucun `ProjectManifest.storylines`, aucune migration legacy, aucun `ScenarioAsset`, aucun generated file, aucun build_runner, aucune UI.
+- Prochain lot recommandé : `NS-STORYLINES-V1-05 — ProjectManifest.storylines Integration V0`.
+
 ### 2026-05-28 — NS-STORYLINES-V1-03
 
 - Premier modèle pur Storylines V1 livré dans `map_core`.
```

### Diff complet de storyline_asset.dart

```diff
diff --git a/packages/map_core/lib/src/models/storyline_asset.dart b/packages/map_core/lib/src/models/storyline_asset.dart
index 47810547..ef23c4e5 100644
--- a/packages/map_core/lib/src/models/storyline_asset.dart
+++ b/packages/map_core/lib/src/models/storyline_asset.dart
@@ -126,6 +126,66 @@ final class StorylineAsset {
     }
   }
 
+  factory StorylineAsset.fromJson(Map<String, dynamic> json) {
+    return StorylineAsset(
+      id: _readRequiredString(json, 'id'),
+      schemaVersion: _readInt(json, 'schemaVersion', defaultValue: 1),
+      type: _readEnum(StorylineType.values, json['type'], 'type'),
+      status: _readEnum(
+        StorylineStatus.values,
+        json['status'],
+        'status',
+        defaultValue: StorylineStatus.draft,
+      ),
+      title: _readRequiredString(json, 'title'),
+      description: _readOptionalString(json, 'description'),
+      sortOrder: _readOptionalInt(json, 'sortOrder'),
+      locale: _readOptionalString(json, 'locale'),
+      chapters: _readObjectList(
+        json,
+        'chapters',
+        StorylineChapter.fromJson,
+      ),
+      sceneLinks: _readObjectList(
+        json,
+        'sceneLinks',
+        StorylineSceneLink.fromJson,
+      ),
+      relationships: _readObjectList(
+        json,
+        'relationships',
+        StorylineRelationship.fromJson,
+      ),
+      legacySource: _readOptionalObject(
+        json,
+        'legacySource',
+        StorylineLegacySource.fromJson,
+      ),
+      authorNotes: _readOptionalString(json, 'authorNotes'),
+      metadata: _readStringMap(json, 'metadata'),
+    );
+  }
+
+  Map<String, dynamic> toJson() {
+    return _withoutNulls({
+      'id': id,
+      'schemaVersion': schemaVersion,
+      'type': _enumToJson(type),
+      'status': _enumToJson(status),
+      'title': title,
+      'description': description,
+      'sortOrder': sortOrder,
+      'locale': locale,
+      'chapters': chapters.map((chapter) => chapter.toJson()).toList(),
+      'sceneLinks': sceneLinks.map((sceneLink) => sceneLink.toJson()).toList(),
+      'relationships':
+          relationships.map((relationship) => relationship.toJson()).toList(),
+      'legacySource': legacySource?.toJson(),
+      'authorNotes': authorNotes,
+      'metadata': metadata,
+    });
+  }
+
   final String id;
   final int schemaVersion;
   final StorylineType type;
@@ -208,6 +268,35 @@ final class StorylineChapter {
     );
   }
 
+  factory StorylineChapter.fromJson(Map<String, dynamic> json) {
+    return StorylineChapter(
+      id: _readRequiredString(json, 'id'),
+      title: _readRequiredString(json, 'title'),
+      description: _readOptionalString(json, 'description'),
+      order: _readRequiredInt(json, 'order'),
+      steps: _readObjectList(json, 'steps', StorylineStep.fromJson),
+      directSceneLinkIds: _readStringList(json, 'directSceneLinkIds'),
+      status:
+          _readOptionalEnum(StorylineStatus.values, json['status'], 'status'),
+      authorNotes: _readOptionalString(json, 'authorNotes'),
+      metadata: _readStringMap(json, 'metadata'),
+    );
+  }
+
+  Map<String, dynamic> toJson() {
+    return _withoutNulls({
+      'id': id,
+      'title': title,
+      'description': description,
+      'order': order,
+      'steps': steps.map((step) => step.toJson()).toList(),
+      'directSceneLinkIds': directSceneLinkIds,
+      'status': status == null ? null : _enumToJson(status!),
+      'authorNotes': authorNotes,
+      'metadata': metadata,
+    });
+  }
+
   final String id;
   final String title;
   final String? description;
@@ -277,6 +366,40 @@ final class StorylineStep {
     _requireNonNegative(order, 'StorylineStep.order');
   }
 
+  factory StorylineStep.fromJson(Map<String, dynamic> json) {
+    return StorylineStep(
+      id: _readRequiredString(json, 'id'),
+      title: _readRequiredString(json, 'title'),
+      description: _readOptionalString(json, 'description'),
+      order: _readRequiredInt(json, 'order'),
+      entryCondition: _readOptionalScriptCondition(json, 'entryCondition'),
+      completionCondition:
+          _readOptionalScriptCondition(json, 'completionCondition'),
+      sceneLinkIds: _readStringList(json, 'sceneLinkIds'),
+      expectedOutcomeIds: _readStringList(json, 'expectedOutcomeIds'),
+      status:
+          _readOptionalEnum(StorylineStatus.values, json['status'], 'status'),
+      authorNotes: _readOptionalString(json, 'authorNotes'),
+      metadata: _readStringMap(json, 'metadata'),
+    );
+  }
+
+  Map<String, dynamic> toJson() {
+    return _withoutNulls({
+      'id': id,
+      'title': title,
+      'description': description,
+      'order': order,
+      'entryCondition': entryCondition?.toJson(),
+      'completionCondition': completionCondition?.toJson(),
+      'sceneLinkIds': sceneLinkIds,
+      'expectedOutcomeIds': expectedOutcomeIds,
+      'status': status == null ? null : _enumToJson(status!),
+      'authorNotes': authorNotes,
+      'metadata': metadata,
+    });
+  }
+
   final String id;
   final String title;
   final String? description;
@@ -358,6 +481,49 @@ final class StorylineSceneLink {
     _validateSceneLinkState(state, sceneRef);
   }
 
+  factory StorylineSceneLink.fromJson(Map<String, dynamic> json) {
+    return StorylineSceneLink(
+      id: _readRequiredString(json, 'id'),
+      chapterId: _readRequiredString(json, 'chapterId'),
+      stepId: _readOptionalString(json, 'stepId'),
+      label: _readRequiredString(json, 'label'),
+      state: _readEnum(StorylineSceneLinkState.values, json['state'], 'state'),
+      role: _readEnum(StorylineSceneLinkRole.values, json['role'], 'role'),
+      sceneRef: _readOptionalObject(
+        json,
+        'sceneRef',
+        StorylineSceneRef.fromJson,
+      ),
+      order: _readRequiredInt(json, 'order'),
+      expectedOutcomeIds: _readStringList(json, 'expectedOutcomeIds'),
+      outcomeLinks: _readObjectList(
+        json,
+        'outcomeLinks',
+        StorylineSceneOutcomeLink.fromJson,
+      ),
+      authorNotes: _readOptionalString(json, 'authorNotes'),
+      metadata: _readStringMap(json, 'metadata'),
+    );
+  }
+
+  Map<String, dynamic> toJson() {
+    return _withoutNulls({
+      'id': id,
+      'chapterId': chapterId,
+      'stepId': stepId,
+      'label': label,
+      'state': _enumToJson(state),
+      'role': _enumToJson(role),
+      'sceneRef': sceneRef?.toJson(),
+      'order': order,
+      'expectedOutcomeIds': expectedOutcomeIds,
+      'outcomeLinks':
+          outcomeLinks.map((outcomeLink) => outcomeLink.toJson()).toList(),
+      'authorNotes': authorNotes,
+      'metadata': metadata,
+    });
+  }
+
   final String id;
   final String chapterId;
   final String? stepId;
@@ -414,6 +580,20 @@ final class StorylineSceneRef {
     _requireNotBlank(targetId, 'StorylineSceneRef.targetId');
   }
 
+  factory StorylineSceneRef.fromJson(Map<String, dynamic> json) {
+    return StorylineSceneRef(
+      kind: _readEnum(StorylineSceneRefKind.values, json['kind'], 'kind'),
+      targetId: _readRequiredString(json, 'targetId'),
+    );
+  }
+
+  Map<String, dynamic> toJson() {
+    return {
+      'kind': _enumToJson(kind),
+      'targetId': targetId,
+    };
+  }
+
   final StorylineSceneRefKind kind;
   final String targetId;
 
@@ -448,6 +628,28 @@ final class StorylineSceneOutcomeLink {
     }
   }
 
+  factory StorylineSceneOutcomeLink.fromJson(Map<String, dynamic> json) {
+    return StorylineSceneOutcomeLink(
+      id: _readRequiredString(json, 'id'),
+      outcomeId: _readRequiredString(json, 'outcomeId'),
+      label: _readOptionalString(json, 'label'),
+      effects: _readObjectList(json, 'effects', StorylineEffect.fromJson),
+      notes: _readOptionalString(json, 'notes'),
+      metadata: _readStringMap(json, 'metadata'),
+    );
+  }
+
+  Map<String, dynamic> toJson() {
+    return _withoutNulls({
+      'id': id,
+      'outcomeId': outcomeId,
+      'label': label,
+      'effects': effects.map((effect) => effect.toJson()).toList(),
+      'notes': notes,
+      'metadata': metadata,
+    });
+  }
+
   final String id;
   final String outcomeId;
   final String? label;
@@ -487,6 +689,22 @@ final class StorylineEffect {
     _requireNotBlank(targetId, 'StorylineEffect.targetId');
   }
 
+  factory StorylineEffect.fromJson(Map<String, dynamic> json) {
+    return StorylineEffect(
+      type: _readEnum(StorylineEffectType.values, json['type'], 'type'),
+      targetId: _readRequiredString(json, 'targetId'),
+      value: _readOptionalString(json, 'value'),
+    );
+  }
+
+  Map<String, dynamic> toJson() {
+    return _withoutNulls({
+      'type': _enumToJson(type),
+      'targetId': targetId,
+      'value': value,
+    });
+  }
+
   final StorylineEffectType type;
   final String targetId;
   final String? value;
@@ -532,6 +750,42 @@ final class StorylineRelationship {
     }
   }
 
+  factory StorylineRelationship.fromJson(Map<String, dynamic> json) {
+    return StorylineRelationship(
+      id: _readRequiredString(json, 'id'),
+      kind: _readEnum(
+        StorylineRelationshipKind.values,
+        json['kind'],
+        'kind',
+      ),
+      sourceStorylineId: _readRequiredString(json, 'sourceStorylineId'),
+      targetStorylineId: _readRequiredString(json, 'targetStorylineId'),
+      anchor: _readOptionalObject(json, 'anchor', StorylineAnchor.fromJson),
+      availability: _readOptionalObject(
+        json,
+        'availability',
+        SideQuestAvailability.fromJson,
+      ),
+      condition: _readOptionalScriptCondition(json, 'condition'),
+      notes: _readOptionalString(json, 'notes'),
+      metadata: _readStringMap(json, 'metadata'),
+    );
+  }
+
+  Map<String, dynamic> toJson() {
+    return _withoutNulls({
+      'id': id,
+      'kind': _enumToJson(kind),
+      'sourceStorylineId': sourceStorylineId,
+      'targetStorylineId': targetStorylineId,
+      'anchor': anchor?.toJson(),
+      'availability': availability?.toJson(),
+      'condition': condition?.toJson(),
+      'notes': notes,
+      'metadata': metadata,
+    });
+  }
+
   final String id;
   final StorylineRelationshipKind kind;
   final String sourceStorylineId;
@@ -583,6 +837,32 @@ final class SideQuestAvailability {
           'SideQuestAvailability.requiredOutcomeIds',
         );
 
+  factory SideQuestAvailability.fromJson(Map<String, dynamic> json) {
+    return SideQuestAvailability(
+      startAnchor: _readRequiredObject(
+        json,
+        'startAnchor',
+        StorylineAnchor.fromJson,
+      ),
+      endAnchor:
+          _readOptionalObject(json, 'endAnchor', StorylineAnchor.fromJson),
+      availabilityCondition:
+          _readOptionalScriptCondition(json, 'availabilityCondition'),
+      expiresCondition: _readOptionalScriptCondition(json, 'expiresCondition'),
+      requiredOutcomeIds: _readStringList(json, 'requiredOutcomeIds'),
+    );
+  }
+
+  Map<String, dynamic> toJson() {
+    return _withoutNulls({
+      'startAnchor': startAnchor.toJson(),
+      'endAnchor': endAnchor?.toJson(),
+      'availabilityCondition': availabilityCondition?.toJson(),
+      'expiresCondition': expiresCondition?.toJson(),
+      'requiredOutcomeIds': requiredOutcomeIds,
+    });
+  }
+
   final StorylineAnchor startAnchor;
   final StorylineAnchor? endAnchor;
   final ScriptCondition? availabilityCondition;
@@ -618,6 +898,20 @@ final class StorylineAnchor {
     _requireNotBlank(targetId, 'StorylineAnchor.targetId');
   }
 
+  factory StorylineAnchor.fromJson(Map<String, dynamic> json) {
+    return StorylineAnchor(
+      kind: _readEnum(StorylineAnchorKind.values, json['kind'], 'kind'),
+      targetId: _readRequiredString(json, 'targetId'),
+    );
+  }
+
+  Map<String, dynamic> toJson() {
+    return {
+      'kind': _enumToJson(kind),
+      'targetId': targetId,
+    };
+  }
+
   final StorylineAnchorKind kind;
   final String targetId;
 
@@ -649,6 +943,30 @@ final class StorylineValidationIssue {
     _requireNotBlank(message, 'StorylineValidationIssue.message');
   }
 
+  factory StorylineValidationIssue.fromJson(Map<String, dynamic> json) {
+    return StorylineValidationIssue(
+      id: _readOptionalString(json, 'id'),
+      severity: _readEnum(
+        StorylineValidationSeverity.values,
+        json['severity'],
+        'severity',
+      ),
+      targetRef: _readRequiredString(json, 'targetRef'),
+      ruleId: _readRequiredString(json, 'ruleId'),
+      message: _readRequiredString(json, 'message'),
+    );
+  }
+
+  Map<String, dynamic> toJson() {
+    return _withoutNulls({
+      'id': id,
+      'severity': _enumToJson(severity),
+      'targetRef': targetRef,
+      'ruleId': ruleId,
+      'message': message,
+    });
+  }
+
   final String? id;
   final StorylineValidationSeverity severity;
   final String targetRef;
@@ -680,6 +998,22 @@ final class StorylineLegacySource {
     _requireNotBlank(sourceId, 'StorylineLegacySource.sourceId');
   }
 
+  factory StorylineLegacySource.fromJson(Map<String, dynamic> json) {
+    return StorylineLegacySource(
+      kind: _readRequiredString(json, 'kind'),
+      sourceId: _readRequiredString(json, 'sourceId'),
+      metadata: _readStringMap(json, 'metadata'),
+    );
+  }
+
+  Map<String, dynamic> toJson() {
+    return {
+      'kind': kind,
+      'sourceId': sourceId,
+      'metadata': metadata,
+    };
+  }
+
   final String kind;
   final String sourceId;
   final Map<String, String> metadata;
@@ -840,3 +1174,194 @@ int _mapHash<K, V>(Map<K, V> map) {
     map.entries.map((entry) => Object.hash(entry.key, entry.value)),
   );
 }
+
+Map<String, dynamic> _withoutNulls(Map<String, dynamic> json) {
+  return {
+    for (final entry in json.entries)
+      if (entry.value != null) entry.key: entry.value,
+  };
+}
+
+String _enumToJson(Enum value) => value.name;
+
+T _readEnum<T extends Enum>(
+  List<T> values,
+  Object? value,
+  String fieldName, {
+  T? defaultValue,
+}) {
+  if (value == null && defaultValue != null) {
+    return defaultValue;
+  }
+  if (value is! String) {
+    throw FormatException('$fieldName must be a string enum value');
+  }
+  for (final enumValue in values) {
+    if (enumValue.name == value) {
+      return enumValue;
+    }
+  }
+  throw FormatException('$fieldName has unknown enum value $value');
+}
+
+T? _readOptionalEnum<T extends Enum>(
+  List<T> values,
+  Object? value,
+  String fieldName,
+) {
+  if (value == null) {
+    return null;
+  }
+  return _readEnum(values, value, fieldName);
+}
+
+String _readRequiredString(Map<String, dynamic> json, String fieldName) {
+  final value = json[fieldName];
+  if (value is! String) {
+    throw FormatException('$fieldName must be a string');
+  }
+  return value;
+}
+
+String? _readOptionalString(Map<String, dynamic> json, String fieldName) {
+  final value = json[fieldName];
+  if (value == null) {
+    return null;
+  }
+  if (value is! String) {
+    throw FormatException('$fieldName must be a string');
+  }
+  return value;
+}
+
+int _readRequiredInt(Map<String, dynamic> json, String fieldName) {
+  final value = json[fieldName];
+  if (value is! int) {
+    throw FormatException('$fieldName must be an int');
+  }
+  return value;
+}
+
+int _readInt(
+  Map<String, dynamic> json,
+  String fieldName, {
+  required int defaultValue,
+}) {
+  final value = json[fieldName];
+  if (value == null) {
+    return defaultValue;
+  }
+  if (value is! int) {
+    throw FormatException('$fieldName must be an int');
+  }
+  return value;
+}
+
+int? _readOptionalInt(Map<String, dynamic> json, String fieldName) {
+  final value = json[fieldName];
+  if (value == null) {
+    return null;
+  }
+  if (value is! int) {
+    throw FormatException('$fieldName must be an int');
+  }
+  return value;
+}
+
+Map<String, String> _readStringMap(
+  Map<String, dynamic> json,
+  String fieldName,
+) {
+  final value = json[fieldName];
+  if (value == null) {
+    return const <String, String>{};
+  }
+  if (value is! Map) {
+    throw FormatException('$fieldName must be a map');
+  }
+  final result = <String, String>{};
+  for (final entry in value.entries) {
+    if (entry.key is! String || entry.value is! String) {
+      throw FormatException('$fieldName must contain only string values');
+    }
+    result[entry.key as String] = entry.value as String;
+  }
+  return result;
+}
+
+List<String> _readStringList(Map<String, dynamic> json, String fieldName) {
+  final value = json[fieldName];
+  if (value == null) {
+    return const <String>[];
+  }
+  if (value is! List) {
+    throw FormatException('$fieldName must be a list');
+  }
+  return [
+    for (final item in value)
+      if (item is String)
+        item
+      else
+        throw FormatException('$fieldName must contain only strings'),
+  ];
+}
+
+List<T> _readObjectList<T>(
+  Map<String, dynamic> json,
+  String fieldName,
+  T Function(Map<String, dynamic>) decode,
+) {
+  final value = json[fieldName];
+  if (value == null) {
+    return <T>[];
+  }
+  if (value is! List) {
+    throw FormatException('$fieldName must be a list');
+  }
+  return [
+    for (final item in value) decode(_asJsonObject(item, fieldName)),
+  ];
+}
+
+T _readRequiredObject<T>(
+  Map<String, dynamic> json,
+  String fieldName,
+  T Function(Map<String, dynamic>) decode,
+) {
+  return decode(_asJsonObject(json[fieldName], fieldName));
+}
+
+T? _readOptionalObject<T>(
+  Map<String, dynamic> json,
+  String fieldName,
+  T Function(Map<String, dynamic>) decode,
+) {
+  final value = json[fieldName];
+  if (value == null) {
+    return null;
+  }
+  return decode(_asJsonObject(value, fieldName));
+}
+
+ScriptCondition? _readOptionalScriptCondition(
+  Map<String, dynamic> json,
+  String fieldName,
+) {
+  final value = json[fieldName];
+  if (value == null) {
+    return null;
+  }
+  return ScriptCondition.fromJson(_asJsonObject(value, fieldName));
+}
+
+Map<String, dynamic> _asJsonObject(Object? value, String fieldName) {
+  if (value is! Map) {
+    throw FormatException('$fieldName must be a JSON object');
+  }
+  return value.map((key, item) {
+    if (key is! String) {
+      throw FormatException('$fieldName must use string keys');
+    }
+    return MapEntry(key, item);
+  });
+}
```

### Sorties exactes des tests ciblés

Commande :

```bash
cd packages/map_core && dart test --reporter json test/storyline_asset_json_test.dart | tail -n 1
```

Sortie :

```text
{"success":true,"type":"done","time":386}
```

Commande :

```bash
cd packages/map_core && dart test --reporter json test/storyline_asset_test.dart | tail -n 1
```

Sortie :

```text
{"success":true,"type":"done","time":423}
```

Commande :

```bash
cd packages/map_core && dart test --reporter json test/scenario_assets_test.dart | tail -n 1
```

Sortie :

```text
{"success":true,"type":"done","time":374}
```

### Sortie exacte de dart analyze

```text
Analyzing storyline_asset.dart, storyline_asset_test.dart, storyline_asset_json_test.dart...
No issues found!
```

### Sortie exacte du test complet map_core

Commande :

```bash
cd packages/map_core && dart test --reporter json | tail -n 1
```

Sortie :

```text
{"success":true,"type":"done","time":4861}
```

### Git status final exact

```text
 M packages/map_core/lib/src/models/storyline_asset.dart
 M packages/map_core/test/storyline_asset_test.dart
 M reports/narrativeStudio/storylines/road_map_storylines.md
?? packages/map_core/test/storyline_asset_json_test.dart
?? reports/narrativeStudio/storylines/ns_storylines_v1_04_storyline_asset_json_codec_v0.md
```

### Git diff --stat final

```text
 .../map_core/lib/src/models/storyline_asset.dart   | 525 +++++++++++++++++++++
 packages/map_core/test/storyline_asset_test.dart   |   8 +-
 .../storylines/road_map_storylines.md              |  36 +-
 3 files changed, 560 insertions(+), 9 deletions(-)
```

### Git diff --name-only final

```text
packages/map_core/lib/src/models/storyline_asset.dart
packages/map_core/test/storyline_asset_test.dart
reports/narrativeStudio/storylines/road_map_storylines.md
```

### Git diff --check final

```text
Sortie : <vide>
```

### Auto-review critique

- Le codec est manuel et strict, sans dépendance nouvelle.
- Les enums utilisent `.name`; cela correspond aux lowerCamel Dart actuels et doit être protégé par tests si des enums sont renommés.
- Les conditions reposent sur le codec officiel `ScriptCondition`; le lot serait devenu BLOCKED sans ce codec.
- Les validations globales restent hors scope et devront venir avec `ProjectManifest.storylines` / validator.
- Le modèle est maintenant sauvegardable comme JSON isolé, mais pas encore persisté dans un projet.

## 14. Self-review

Critères vérifiés :

- Codec JSON stable ajouté pour `StorylineAsset`.
- Codec JSON ajouté pour tous les sous-objets essentiels.
- Enums encodés en strings stables, pas en index.
- Roundtrip minimal et complet testés.
- Defaults au decode testés.
- Invalid JSON testé.
- Validation constructeur appliquée au decode.
- `ScriptCondition` géré via codec existant.
- `ProjectManifest` non modifié.
- `ScenarioAsset` non modifié.
- Aucun generated file modifié.
- `build_runner` non lancé.
- Tests ciblés passés.
- Analyse ciblée passée.
- Test complet `map_core` passé.
- Roadmap mise à jour.
- Prochain lot recommandé : NS-STORYLINES-V1-05 — ProjectManifest.storylines Integration V0.
