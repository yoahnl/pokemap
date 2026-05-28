# NS-STORYLINES-V1-03 — StorylineAsset Pure Model V0

## 1. Executive summary

NS-STORYLINES-V1-03 livre le premier modèle pur Storylines V1 dans `map_core`.

Le lot ajoute `StorylineAsset` et les sous-objets essentiels pour représenter l'authoring Storylines sans persistance JSON, sans intégration `ProjectManifest.storylines`, sans migration legacy et sans UI. Le modèle reste volontairement petit : classes immuables, validations locales, export public et tests unitaires ciblés.

Verdict : DONE.

Prochain lot recommandé : NS-STORYLINES-V1-04 — StorylineAsset JSON Codec V0.

## 2. Inputs read

Fichiers lus :

- `AGENTS.md`
- `agent_rules.md`
- `skills/README.md`
- `reports/narrativeStudio/storylines/road_map_storylines.md`
- `reports/narrativeStudio/storylines/ns_storylines_v1_02_storyline_authoring_data_shape_contract.md`
- `reports/narrativeStudio/storylines/ns_storylines_v1_01_storyline_authoring_model_decision.md`
- `reports/narrativeStudio/storylines/ns_storylines_v1_00_storyline_semantics_and_usable_authoring_contract.md`
- `packages/map_core/lib/src/models/scenario_asset.dart`
- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/models/script_conditions.dart`
- `packages/map_core/lib/src/models/script_asset.dart`
- `packages/map_core/lib/map_core.dart`
- `packages/map_core/test/`
- `packages/map_core/lib/src/exceptions/map_exceptions.dart`
- `packages/map_core/test/scenario_assets_test.dart`

Fichiers attendus absents :

- `packages/map_core/test/scenario_asset_test.dart` est absent. Équivalent trouvé et exécuté : `packages/map_core/test/scenario_assets_test.dart`.

Conventions observées :

- `ValidationException` existe dans `map_core` et a été réutilisée.
- Les modèles purs utilisent des classes manuelles immuables, `@immutable`, champs `final`, collections défensives, equality/hashCode manuels.
- `map_core.dart` est le barrel public à maintenir.
- `script_conditions.dart` expose `ScriptCondition`, réutilisé conceptuellement pour conditions d'entrée, de complétion et d'availability.

## 3. Implementation summary

Créé :

- `packages/map_core/lib/src/models/storyline_asset.dart`
- `packages/map_core/test/storyline_asset_test.dart`

Modifié :

- `packages/map_core/lib/map_core.dart`
- `reports/narrativeStudio/storylines/road_map_storylines.md`

Le modèle est exporté depuis `map_core.dart`.

Le lot ne touche pas à :

- `ProjectManifest`
- `ScenarioAsset`
- `script_asset.dart`
- `script_conditions.dart`
- fichiers générés
- `map_editor`
- `map_runtime`
- `map_gameplay`
- `map_battle`

## 4. Model scope

Scope V1-03 implémenté :

- modèle pur `StorylineAsset` ;
- enums Storylines V1 ;
- sous-objets de structure auteur ;
- validations locales synchrones dans les constructeurs ;
- immutabilité des collections ;
- tests unitaires.

Hors scope confirmé :

- JSON codec ;
- `toJson` / `fromJson` ;
- `ProjectManifest.storylines` ;
- migration legacy ;
- import `ScenarioAsset.globalStory` ;
- runtime ;
- UI ;
- boutons de création.

## 5. Enums implemented

Enums ajoutés :

- `StorylineType`
- `StorylineStatus`
- `StorylineSceneLinkState`
- `StorylineSceneLinkRole`
- `StorylineRelationshipKind`
- `StorylineValidationSeverity`
- `StorylineEffectType`
- `StorylineAnchorKind`
- `StorylineSceneRefKind`

Valeurs V1 initial principalement couvertes par tests :

- `StorylineType.main`
- `StorylineType.sideQuest`
- `StorylineStatus.draft`
- `StorylineSceneLinkState.placeholder`
- `StorylineSceneLinkState.linkedScenario`
- `StorylineEffectType.activateStep`
- `StorylineEffectType.completeStep`
- `StorylineEffectType.unlockStoryline`

Des valeurs futures existent déjà dans le modèle pour limiter une migration de surface plus tard, sans activer de comportement JSON/runtime/UI.

## 6. Classes implemented

Classes ajoutées :

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

Choix notable :

- `StorylineStep.entryCondition`, `StorylineStep.completionCondition`, `StorylineRelationship.condition`, `SideQuestAvailability.availabilityCondition` et `SideQuestAvailability.expiresCondition` utilisent `ScriptCondition?`.
- Aucun nouveau langage conditionnel n'est créé.
- `StorylineLegacySource.kind` reste un `String` en V0 pour éviter un enum prématuré avant le contrat d'import legacy.

## 7. Validation rules implemented

Validations locales implémentées :

- `StorylineAsset.id` non vide.
- `StorylineAsset.schemaVersion > 0`.
- `StorylineAsset.title` non vide.
- ids de chapters uniques dans une storyline.
- ids de steps uniques dans toute la storyline.
- ids de scene links uniques.
- ids de relationships uniques.
- `sceneLink.chapterId` référence un chapter existant.
- `sceneLink.stepId`, si présent, référence une step existante.
- `sceneLink.stepId` doit appartenir au `chapterId` référencé.
- `relationship.sourceStorylineId` doit correspondre au `StorylineAsset.id` si relationship inline.
- `StorylineChapter.id/title` non vides.
- `StorylineChapter.order >= 0`.
- ids de steps uniques dans un chapter.
- `directSceneLinkIds` non vides et uniques.
- `StorylineStep.id/title` non vides.
- `StorylineStep.order >= 0`.
- `sceneLinkIds` et `expectedOutcomeIds` non vides et uniques.
- `StorylineSceneLink.id/chapterId/label` non vides.
- `StorylineSceneLink.stepId` non vide si présent.
- `StorylineSceneLink.order >= 0`.
- ids de outcome links uniques dans un scene link.
- `placeholder` rejette `sceneRef`.
- `linkedScenario` exige un `sceneRef` de kind `scenario`.
- `needsImplementation` rejette `sceneRef`.
- `brokenLink` accepte `sceneRef` null ou stale pour diagnostic.
- `StorylineSceneRef.targetId` non vide.
- `StorylineSceneOutcomeLink.id/outcomeId` non vides.
- `StorylineSceneOutcomeLink.effects` non vide.
- `StorylineEffect.targetId` non vide.
- `StorylineRelationship.id/source/target` non vides.
- `StorylineRelationship.sourceStorylineId != targetStorylineId`.
- `SideQuestAvailability.requiredOutcomeIds` non vides et uniques.
- `StorylineAnchor.targetId` non vide.
- `StorylineValidationIssue.targetRef/ruleId/message` non vides.
- `StorylineValidationIssue.id` non vide si fourni.
- `StorylineLegacySource.kind/sourceId` non vides.

Validations volontairement non implémentées :

- unicité globale des `StorylineAsset` ;
- unicité globale de la main storyline active ;
- existence réelle d'un `ScenarioAsset` référencé ;
- existence réelle d'un outcome déclaré dans un `ScenarioAsset` ;
- validation de collection au niveau `ProjectManifest`.

## 8. Immutability guarantees

Garanties :

- classes annotées `@immutable` ;
- champs `final` ;
- listes construites via `List.unmodifiable` ;
- maps construites via `Map.unmodifiable` ;
- equality/hashCode manuels ;
- hash de maps basé sur les paires key/value, indépendant de l'ordre d'insertion ;
- tests de copie défensive des listes/maps d'entrée ;
- tests d'exposition en collections non modifiables.

## 9. Non-goals confirmed

Confirmé :

- Aucun codec JSON ajouté.
- Aucun `toJson` / `fromJson` ajouté.
- `ProjectManifest` non modifié.
- `ScenarioAsset` non modifié.
- Aucun fichier généré modifié.
- `build_runner` non lancé.
- `map_editor` non modifié.
- `map_runtime`, `map_gameplay`, `map_battle` non modifiés.
- Aucun bouton ou flow de création activé.
- Aucune vraie storyline ni quête annexe créée dans un projet.

## 10. Tests added

Test ajouté :

- `packages/map_core/test/storyline_asset_test.dart`

Couverture principale :

- construction valide minimale main draft ;
- construction valide minimale sideQuest draft ;
- valeurs d'enums V1 initial/futures ;
- validation des ids/titres/champs obligatoires ;
- unicité locale chapters/steps/scene links/outcome links/relationships/listes d'ids ;
- références internes chapter/step ;
- règles d'état `placeholder`, `linkedScenario`, `needsImplementation`, `brokenLink` ;
- immutabilité et copies défensives ;
- equality/hashCode ;
- absence de codec JSON.

Régression lancée :

- `packages/map_core/test/scenario_assets_test.dart`

## 11. Commands run

Commandes initiales :

```bash
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git diff --check
```

Commandes d'inspection :

```bash
sed -n '1,220p' AGENTS.md
sed -n '1,220p' agent_rules.md
sed -n '1,220p' skills/README.md
sed -n '1,220p' reports/narrativeStudio/storylines/road_map_storylines.md
sed -n '1,220p' reports/narrativeStudio/storylines/ns_storylines_v1_02_storyline_authoring_data_shape_contract.md
sed -n '1,220p' reports/narrativeStudio/storylines/ns_storylines_v1_01_storyline_authoring_model_decision.md
sed -n '1,220p' reports/narrativeStudio/storylines/ns_storylines_v1_00_storyline_semantics_and_usable_authoring_contract.md
sed -n '1,220p' packages/map_core/lib/src/models/scenario_asset.dart
sed -n '1,220p' packages/map_core/lib/src/models/project_manifest.dart
sed -n '1,220p' packages/map_core/lib/src/models/script_conditions.dart
sed -n '1,220p' packages/map_core/lib/src/models/script_asset.dart
sed -n '1,180p' packages/map_core/lib/map_core.dart
ls packages/map_core/test
sed -n '1,160p' packages/map_core/lib/src/exceptions/map_exceptions.dart
sed -n '1,220p' packages/map_core/test/scenario_assets_test.dart
```

Commandes de format/test/analyse :

```bash
cd packages/map_core && dart format lib/src/models/storyline_asset.dart test/storyline_asset_test.dart
cd packages/map_core && dart test test/storyline_asset_test.dart
cd packages/map_core && dart test test/scenario_assets_test.dart
cd packages/map_core && dart analyze lib/src/models/storyline_asset.dart test/storyline_asset_test.dart
cd packages/map_core && dart test
cd packages/map_core && dart test --reporter json test/storyline_asset_test.dart | tail -n 1
cd packages/map_core && dart test --reporter json test/scenario_assets_test.dart | tail -n 1
cd packages/map_core && dart test --reporter json | tail -n 1
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

- `NS-STORYLINES-V1-03` marqué DONE.
- Scope corrigé en `StorylineAsset Pure Model V0`.
- `NS-STORYLINES-V1-04 — StorylineAsset JSON Codec V0` recommandé comme prochain lot.
- Intégration `ProjectManifest.storylines` décalée après le codec.
- Import legacy et flows de création décalés après le modèle/codec/manifest.
- V0 conservée comme `ACCEPTED WITH V1 LIMITATIONS`.

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
reports/narrativeStudio/storylines/ns_storylines_v1_02_storyline_authoring_data_shape_contract.md
reports/narrativeStudio/storylines/ns_storylines_v1_01_storyline_authoring_model_decision.md
reports/narrativeStudio/storylines/ns_storylines_v1_00_storyline_semantics_and_usable_authoring_contract.md
packages/map_core/lib/src/models/scenario_asset.dart
packages/map_core/lib/src/models/project_manifest.dart
packages/map_core/lib/src/models/script_conditions.dart
packages/map_core/lib/src/models/script_asset.dart
packages/map_core/lib/map_core.dart
packages/map_core/test/
packages/map_core/lib/src/exceptions/map_exceptions.dart
packages/map_core/test/scenario_assets_test.dart
```

### Liste des fichiers absents mais attendus

```text
packages/map_core/test/scenario_asset_test.dart
```

Équivalent utilisé :

```text
packages/map_core/test/scenario_assets_test.dart
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
```

### Contenu complet de storyline_asset_test.dart

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('StorylineAsset construction', () {
    test('accepts minimal main draft with default schema and empty structure',
        () {
      final storyline = StorylineAsset(
        id: 'main_story',
        type: StorylineType.main,
        title: 'Main Story',
      );

      expect(storyline.schemaVersion, 1);
      expect(storyline.status, StorylineStatus.draft);
      expect(storyline.chapters, isEmpty);
      expect(storyline.sceneLinks, isEmpty);
      expect(storyline.relationships, isEmpty);
    });

    test('accepts minimal side quest draft', () {
      final storyline = StorylineAsset(
        id: 'side_quest',
        type: StorylineType.sideQuest,
        title: 'Side Quest',
      );

      expect(storyline.type, StorylineType.sideQuest);
      expect(storyline.status, StorylineStatus.draft);
    });

    test('exposes V1 initial and future enum values', () {
      expect(StorylineType.main, isA<StorylineType>());
      expect(StorylineType.sideQuest, isA<StorylineType>());
      expect(StorylineStatus.draft, isA<StorylineStatus>());
      expect(
        StorylineSceneLinkState.placeholder,
        isA<StorylineSceneLinkState>(),
      );
      expect(
        StorylineSceneLinkState.linkedScenario,
        isA<StorylineSceneLinkState>(),
      );
      expect(StorylineEffectType.activateStep, isA<StorylineEffectType>());
      expect(StorylineEffectType.completeStep, isA<StorylineEffectType>());
      expect(StorylineEffectType.unlockStoryline, isA<StorylineEffectType>());
      expect(StorylineType.hiddenEvent, isA<StorylineType>());
      expect(StorylineEffectType.setWorldRule, isA<StorylineEffectType>());
    });
  });

  group('StorylineAsset field validation', () {
    test('rejects blank StorylineAsset id and title', () {
      expect(
        () => StorylineAsset(id: ' ', type: StorylineType.main, title: 'A'),
        _throwsValidation,
      );
      expect(
        () => StorylineAsset(id: 'a', type: StorylineType.main, title: ' '),
        _throwsValidation,
      );
      expect(
        () => StorylineAsset(
          id: 'a',
          schemaVersion: 0,
          type: StorylineType.main,
          title: 'A',
        ),
        _throwsValidation,
      );
    });

    test('rejects blank StorylineChapter id and title', () {
      expect(
        () => StorylineChapter(id: '', title: 'Chapter', order: 0),
        _throwsValidation,
      );
      expect(
        () => StorylineChapter(id: 'chapter', title: ' ', order: 0),
        _throwsValidation,
      );
      expect(
        () => StorylineChapter(id: 'chapter', title: 'Chapter', order: -1),
        _throwsValidation,
      );
    });

    test('rejects blank StorylineStep id and title', () {
      expect(
        () => StorylineStep(id: '', title: 'Step', order: 0),
        _throwsValidation,
      );
      expect(
        () => StorylineStep(id: 'step', title: ' ', order: 0),
        _throwsValidation,
      );
      expect(
        () => StorylineStep(id: 'step', title: 'Step', order: -1),
        _throwsValidation,
      );
    });

    test('rejects blank scene link fields', () {
      expect(
        () => StorylineSceneLink(
          id: '',
          chapterId: 'chapter',
          label: 'Scene',
          state: StorylineSceneLinkState.placeholder,
          role: StorylineSceneLinkRole.primary,
          order: 0,
        ),
        _throwsValidation,
      );
      expect(
        () => StorylineSceneLink(
          id: 'scene',
          chapterId: '',
          label: 'Scene',
          state: StorylineSceneLinkState.placeholder,
          role: StorylineSceneLinkRole.primary,
          order: 0,
        ),
        _throwsValidation,
      );
      expect(
        () => StorylineSceneLink(
          id: 'scene',
          chapterId: 'chapter',
          label: '',
          state: StorylineSceneLinkState.placeholder,
          role: StorylineSceneLinkRole.primary,
          order: 0,
        ),
        _throwsValidation,
      );
    });

    test('rejects blank leaf object fields', () {
      expect(
        () => StorylineSceneRef(
          kind: StorylineSceneRefKind.scenario,
          targetId: ' ',
        ),
        _throwsValidation,
      );
      expect(
        () => StorylineSceneOutcomeLink(
          id: '',
          outcomeId: 'outcome',
          effects: [_activateStep()],
        ),
        _throwsValidation,
      );
      expect(
        () => StorylineSceneOutcomeLink(
          id: 'outcome-link',
          outcomeId: '',
          effects: [_activateStep()],
        ),
        _throwsValidation,
      );
      expect(
        () => StorylineSceneOutcomeLink(
          id: 'outcome-link',
          outcomeId: 'outcome',
          effects: const [],
        ),
        _throwsValidation,
      );
      expect(
        () => StorylineEffect(
          type: StorylineEffectType.activateStep,
          targetId: '',
        ),
        _throwsValidation,
      );
      expect(
        () => StorylineAnchor(kind: StorylineAnchorKind.step, targetId: ' '),
        _throwsValidation,
      );
      expect(
        () => StorylineValidationIssue(
          targetRef: '',
          ruleId: 'rule',
          message: 'message',
          severity: StorylineValidationSeverity.error,
        ),
        _throwsValidation,
      );
      expect(
        () => StorylineValidationIssue(
          targetRef: 'target',
          ruleId: '',
          message: 'message',
          severity: StorylineValidationSeverity.error,
        ),
        _throwsValidation,
      );
      expect(
        () => StorylineValidationIssue(
          targetRef: 'target',
          ruleId: 'rule',
          message: '',
          severity: StorylineValidationSeverity.error,
        ),
        _throwsValidation,
      );
      expect(
        () => StorylineLegacySource(kind: '', sourceId: 'global_story'),
        _throwsValidation,
      );
      expect(
        () => StorylineLegacySource(kind: 'scenario.globalStory', sourceId: ''),
        _throwsValidation,
      );
      expect(
        () => StorylineRelationship(
          id: '',
          kind: StorylineRelationshipKind.requires,
          sourceStorylineId: 'source',
          targetStorylineId: 'target',
        ),
        _throwsValidation,
      );
      expect(
        () => StorylineRelationship(
          id: 'rel',
          kind: StorylineRelationshipKind.requires,
          sourceStorylineId: '',
          targetStorylineId: 'target',
        ),
        _throwsValidation,
      );
      expect(
        () => StorylineRelationship(
          id: 'rel',
          kind: StorylineRelationshipKind.requires,
          sourceStorylineId: 'source',
          targetStorylineId: '',
        ),
        _throwsValidation,
      );
    });
  });

  group('StorylineAsset local uniqueness', () {
    test('rejects duplicate chapter ids', () {
      expect(
        () => StorylineAsset(
          id: 'story',
          type: StorylineType.main,
          title: 'Story',
          chapters: [
            StorylineChapter(id: 'chapter', title: 'One', order: 0),
            StorylineChapter(id: 'chapter', title: 'Two', order: 1),
          ],
        ),
        _throwsValidation,
      );
    });

    test('rejects duplicate step ids across the storyline', () {
      expect(
        () => StorylineAsset(
          id: 'story',
          type: StorylineType.main,
          title: 'Story',
          chapters: [
            StorylineChapter(
              id: 'chapter-a',
              title: 'A',
              order: 0,
              steps: [StorylineStep(id: 'step', title: 'Step A', order: 0)],
            ),
            StorylineChapter(
              id: 'chapter-b',
              title: 'B',
              order: 1,
              steps: [StorylineStep(id: 'step', title: 'Step B', order: 0)],
            ),
          ],
        ),
        _throwsValidation,
      );
    });

    test('rejects duplicate scene link ids', () {
      expect(
        () => StorylineAsset(
          id: 'story',
          type: StorylineType.main,
          title: 'Story',
          chapters: [_chapter()],
          sceneLinks: [
            _placeholderSceneLink(id: 'scene'),
            _placeholderSceneLink(id: 'scene'),
          ],
        ),
        _throwsValidation,
      );
    });

    test('rejects duplicate outcome link ids inside scene link', () {
      expect(
        () => StorylineSceneLink(
          id: 'scene',
          chapterId: 'chapter',
          label: 'Scene',
          state: StorylineSceneLinkState.placeholder,
          role: StorylineSceneLinkRole.primary,
          order: 0,
          outcomeLinks: [
            StorylineSceneOutcomeLink(
              id: 'outcome-link',
              outcomeId: 'a',
              effects: [_activateStep()],
            ),
            StorylineSceneOutcomeLink(
              id: 'outcome-link',
              outcomeId: 'b',
              effects: [_activateStep()],
            ),
          ],
        ),
        _throwsValidation,
      );
    });

    test('rejects duplicate ids in string lists', () {
      expect(
        () => StorylineStep(
          id: 'step',
          title: 'Step',
          order: 0,
          sceneLinkIds: const ['scene', 'scene'],
        ),
        _throwsValidation,
      );
      expect(
        () => StorylineStep(
          id: 'step',
          title: 'Step',
          order: 0,
          expectedOutcomeIds: const ['outcome', 'outcome'],
        ),
        _throwsValidation,
      );
      expect(
        () => StorylineChapter(
          id: 'chapter',
          title: 'Chapter',
          order: 0,
          directSceneLinkIds: const ['scene', 'scene'],
        ),
        _throwsValidation,
      );
      expect(
        () => SideQuestAvailability(
          startAnchor: StorylineAnchor(
            kind: StorylineAnchorKind.step,
            targetId: 'step',
          ),
          requiredOutcomeIds: const ['outcome', 'outcome'],
        ),
        _throwsValidation,
      );
    });

    test('rejects duplicate relationship ids', () {
      expect(
        () => StorylineAsset(
          id: 'side',
          type: StorylineType.sideQuest,
          title: 'Side',
          relationships: [
            _relationship(id: 'rel'),
            _relationship(id: 'rel'),
          ],
        ),
        _throwsValidation,
      );
    });
  });

  group('StorylineAsset internal references', () {
    test('requires scene link chapterId to reference an existing chapter', () {
      expect(
        () => StorylineAsset(
          id: 'story',
          type: StorylineType.main,
          title: 'Story',
          sceneLinks: [_placeholderSceneLink()],
        ),
        _throwsValidation,
      );
    });

    test('requires scene link stepId to reference an existing step', () {
      expect(
        () => StorylineAsset(
          id: 'story',
          type: StorylineType.main,
          title: 'Story',
          chapters: [_chapter()],
          sceneLinks: [_placeholderSceneLink(stepId: 'missing_step')],
        ),
        _throwsValidation,
      );
    });

    test('requires scene link stepId to belong to the referenced chapter', () {
      expect(
        () => StorylineAsset(
          id: 'story',
          type: StorylineType.main,
          title: 'Story',
          chapters: [
            StorylineChapter(id: 'chapter', title: 'Chapter', order: 0),
            StorylineChapter(
              id: 'other',
              title: 'Other',
              order: 1,
              steps: [StorylineStep(id: 'step', title: 'Step', order: 0)],
            ),
          ],
          sceneLinks: [_placeholderSceneLink(stepId: 'step')],
        ),
        _throwsValidation,
      );
    });

    test('requires inline relationship source to match storyline id', () {
      expect(
        () => StorylineAsset(
          id: 'side',
          type: StorylineType.sideQuest,
          title: 'Side',
          relationships: [
            StorylineRelationship(
              id: 'rel',
              kind: StorylineRelationshipKind.sideQuestUnlockedBy,
              sourceStorylineId: 'other',
              targetStorylineId: 'main',
            ),
          ],
        ),
        _throwsValidation,
      );
    });

    test('rejects relationship with identical source and target', () {
      expect(
        () => StorylineRelationship(
          id: 'rel',
          kind: StorylineRelationshipKind.requires,
          sourceStorylineId: 'story',
          targetStorylineId: 'story',
        ),
        _throwsValidation,
      );
    });
  });

  group('StorylineSceneLink state rules', () {
    test('placeholder rejects sceneRef', () {
      expect(
        () => StorylineSceneLink(
          id: 'scene',
          chapterId: 'chapter',
          label: 'Scene',
          state: StorylineSceneLinkState.placeholder,
          role: StorylineSceneLinkRole.primary,
          sceneRef: StorylineSceneRef(
            kind: StorylineSceneRefKind.scenario,
            targetId: 'scenario',
          ),
          order: 0,
        ),
        _throwsValidation,
      );
    });

    test('linkedScenario requires scenario sceneRef', () {
      expect(
        () => StorylineSceneLink(
          id: 'scene',
          chapterId: 'chapter',
          label: 'Scene',
          state: StorylineSceneLinkState.linkedScenario,
          role: StorylineSceneLinkRole.primary,
          order: 0,
        ),
        _throwsValidation,
      );

      final link = StorylineSceneLink(
        id: 'scene',
        chapterId: 'chapter',
        label: 'Scene',
        state: StorylineSceneLinkState.linkedScenario,
        role: StorylineSceneLinkRole.primary,
        sceneRef: StorylineSceneRef(
          kind: StorylineSceneRefKind.scenario,
          targetId: 'scenario',
        ),
        order: 0,
      );

      expect(link.sceneRef?.targetId, 'scenario');
    });

    test('needsImplementation rejects sceneRef', () {
      expect(
        () => StorylineSceneLink(
          id: 'scene',
          chapterId: 'chapter',
          label: 'Scene',
          state: StorylineSceneLinkState.needsImplementation,
          role: StorylineSceneLinkRole.primary,
          sceneRef: StorylineSceneRef(
            kind: StorylineSceneRefKind.scenario,
            targetId: 'scenario',
          ),
          order: 0,
        ),
        _throwsValidation,
      );
    });

    test('brokenLink accepts null or stale sceneRef for diagnostics', () {
      final withoutRef = StorylineSceneLink(
        id: 'broken-a',
        chapterId: 'chapter',
        label: 'Broken A',
        state: StorylineSceneLinkState.brokenLink,
        role: StorylineSceneLinkRole.primary,
        order: 0,
      );
      final withRef = StorylineSceneLink(
        id: 'broken-b',
        chapterId: 'chapter',
        label: 'Broken B',
        state: StorylineSceneLinkState.brokenLink,
        role: StorylineSceneLinkRole.primary,
        sceneRef: StorylineSceneRef(
          kind: StorylineSceneRefKind.scenario,
          targetId: 'missing_scenario',
        ),
        order: 1,
      );

      expect(withoutRef.sceneRef, isNull);
      expect(withRef.sceneRef?.targetId, 'missing_scenario');
    });
  });

  group('StorylineAsset immutability', () {
    test('defensively copies constructor lists and maps', () {
      final chapters = [_chapter()];
      final sceneLinks = [_placeholderSceneLink()];
      final metadata = {'key': 'value'};

      final storyline = StorylineAsset(
        id: 'story',
        type: StorylineType.main,
        title: 'Story',
        chapters: chapters,
        sceneLinks: sceneLinks,
        metadata: metadata,
      );

      chapters.clear();
      sceneLinks.clear();
      metadata['key'] = 'changed';

      expect(storyline.chapters, hasLength(1));
      expect(storyline.sceneLinks, hasLength(1));
      expect(storyline.metadata['key'], 'value');
    });

    test('exposes unmodifiable collections', () {
      final storyline = StorylineAsset(
        id: 'story',
        type: StorylineType.main,
        title: 'Story',
        chapters: [_chapter()],
        sceneLinks: [_placeholderSceneLink()],
        metadata: const {'key': 'value'},
      );

      expect(
        () => storyline.chapters.add(
          StorylineChapter(id: 'other', title: 'Other', order: 1),
        ),
        throwsUnsupportedError,
      );
      expect(
        () => storyline.sceneLinks.add(_placeholderSceneLink(id: 'other')),
        throwsUnsupportedError,
      );
      expect(
        () => storyline.metadata['other'] = 'value',
        throwsUnsupportedError,
      );
    });

    test('supports value equality for equivalent models', () {
      final first = StorylineAsset(
        id: 'story',
        type: StorylineType.main,
        title: 'Story',
        chapters: [_chapter()],
        sceneLinks: [_placeholderSceneLink()],
      );
      final second = StorylineAsset(
        id: 'story',
        type: StorylineType.main,
        title: 'Story',
        chapters: [_chapter()],
        sceneLinks: [_placeholderSceneLink()],
      );
      final withMetadataA = StorylineAsset(
        id: 'story',
        type: StorylineType.main,
        title: 'Story',
        metadata: const {'a': '1', 'b': '2'},
      );
      final withMetadataB = StorylineAsset(
        id: 'story',
        type: StorylineType.main,
        title: 'Story',
        metadata: const {'b': '2', 'a': '1'},
      );

      expect(first, equals(second));
      expect(first.hashCode, equals(second.hashCode));
      expect(withMetadataA, equals(withMetadataB));
      expect(withMetadataA.hashCode, equals(withMetadataB.hashCode));
      expect(first.toString(), contains('story'));
    });
  });

  group('StorylineAsset V1-03 scope guards', () {
    test('does not expose JSON codecs in pure model lot', () {
      final dynamic storyline = StorylineAsset(
        id: 'story',
        type: StorylineType.main,
        title: 'Story',
      );

      expect(() => storyline.toJson(), throwsA(isA<NoSuchMethodError>()));
    });
  });
}

final Matcher _throwsValidation = throwsA(isA<ValidationException>());

StorylineChapter _chapter() {
  return StorylineChapter(
    id: 'chapter',
    title: 'Chapter',
    order: 0,
    steps: [StorylineStep(id: 'step', title: 'Step', order: 0)],
  );
}

StorylineSceneLink _placeholderSceneLink({
  String id = 'scene',
  String? stepId = 'step',
}) {
  return StorylineSceneLink(
    id: id,
    chapterId: 'chapter',
    stepId: stepId,
    label: 'Scene',
    state: StorylineSceneLinkState.placeholder,
    role: StorylineSceneLinkRole.primary,
    order: 0,
  );
}

StorylineEffect _activateStep() {
  return StorylineEffect(
    type: StorylineEffectType.activateStep,
    targetId: 'step',
  );
}

StorylineRelationship _relationship({required String id}) {
  return StorylineRelationship(
    id: id,
    kind: StorylineRelationshipKind.sideQuestUnlockedBy,
    sourceStorylineId: 'side',
    targetStorylineId: 'main',
  );
}
```

### Diff complet de map_core.dart

```diff
diff --git a/packages/map_core/lib/map_core.dart b/packages/map_core/lib/map_core.dart
index f70662da..1d96bad5 100644
--- a/packages/map_core/lib/map_core.dart
+++ b/packages/map_core/lib/map_core.dart
@@ -25,6 +25,7 @@ export 'src/models/script_conditions.dart';
 export 'src/models/map_event_definition.dart';
 export 'src/models/project_trainer.dart';
 export 'src/models/scenario_asset.dart';
+export 'src/models/storyline_asset.dart';
 export 'src/models/visual_frame_json.dart';
 export 'src/models/shadow.dart';
 export 'src/models/shadow_catalog.dart';
```

### Diff complet de road_map_storylines.md

```diff
diff --git a/reports/narrativeStudio/storylines/road_map_storylines.md b/reports/narrativeStudio/storylines/road_map_storylines.md
index c16ec040..3ae0e161 100644
--- a/reports/narrativeStudio/storylines/road_map_storylines.md
+++ b/reports/narrativeStudio/storylines/road_map_storylines.md
@@ -304,7 +304,11 @@ Interprétation V0 :
 | NS-STORYLINES-V1-00 | Storyline Semantics Reset / Usable Authoring Contract | product contract | DONE | NS-STORYLINES-V1-01 |
 | NS-STORYLINES-V1-01 | Storyline Authoring Model Decision | model decision | DONE | NS-STORYLINES-V1-02 |
 | NS-STORYLINES-V1-02 | Storyline Authoring Data Shape Contract | data contract | DONE | NS-STORYLINES-V1-03 |
-| NS-STORYLINES-V1-03 | StorylineAsset Model V0 | core model | TODO | NS-STORYLINES-V1-04 |
+| NS-STORYLINES-V1-03 | StorylineAsset Pure Model V0 | core model / pure dart | DONE | NS-STORYLINES-V1-04 |
+| NS-STORYLINES-V1-04 | StorylineAsset JSON Codec V0 | core codec | TODO | NS-STORYLINES-V1-05 |
+| NS-STORYLINES-V1-05 | ProjectManifest.storylines Integration V0 | core manifest | TODO | NS-STORYLINES-V1-06 |
+| NS-STORYLINES-V1-06 | Legacy GlobalStory Import Preview V0 | migration preview | TODO | NS-STORYLINES-V1-07 |
+| NS-STORYLINES-V1-07 | Create Main Storyline Flow V0 | editor authoring | TODO | NS-STORYLINES-V1-08 |
 
 ## 9. Detailed lots
 
@@ -652,15 +656,23 @@ Interprétation V0 :
 - Non-objectifs : pas d'UI de création avant contrat data shape.
 - Dépendances : NS-STORYLINES-V1-01.
 - Statut : DONE.
-- Prochain lot attendu : NS-STORYLINES-V1-03 — StorylineAsset Model V0.
-
-### NS-STORYLINES-V1-03 — StorylineAsset Model V0
-
-- Type : core model / tests.
-- Objectif : implémenter le modèle `StorylineAsset` V0, codecs JSON, compatibilité `ProjectManifest.storylines`, invariants de base et tests de migration/import legacy.
+- Prochain lot attendu : NS-STORYLINES-V1-03 — StorylineAsset Pure Model V0.
+
+### NS-STORYLINES-V1-03 — StorylineAsset Pure Model V0
+
+- Type : core model / pure Dart / tests.
+- Objectif : implémenter le modèle pur `StorylineAsset` V0 et ses sous-objets essentiels, sans codec JSON, sans `ProjectManifest.storylines`, sans migration legacy et sans UI.
+- Résultat : modèle pur livré dans `map_core`, export public ajouté et tests unitaires ciblés ajoutés.
+- Modèle livré : enums Storylines V1, `StorylineAsset`, chapters, steps, scene links, scene refs, outcome links, effects, relationships, side quest availability, anchors, validation issues et legacy source.
+- Validations : ids/titres non vides, unicité locale, références internes chapter/step, règles d'état placeholder/linkedScenario/brokenLink/needsImplementation, source relationship inline.
+- Immutabilité : champs `final`, collections copiées défensivement et exposées en non modifiable, equality/hashCode/toString manuels.
+- Fichiers créés/modifiés : `packages/map_core/lib/src/models/storyline_asset.dart`, `packages/map_core/lib/map_core.dart`, `packages/map_core/test/storyline_asset_test.dart`, `reports/narrativeStudio/storylines/ns_storylines_v1_03_storyline_asset_pure_model_v0.md`, `reports/narrativeStudio/storylines/road_map_storylines.md`.
+- Tests exécutés : `dart test test/storyline_asset_test.dart`, `dart test test/scenario_assets_test.dart`, `dart test`.
+- Analyse exécutée : `dart analyze lib/src/models/storyline_asset.dart test/storyline_asset_test.dart`.
+- Non-objectifs confirmés : aucun JSON `toJson/fromJson`, aucun `ProjectManifest`, aucun `ScenarioAsset`, aucun generated file, aucun build_runner, aucune UI.
 - Dépendances : NS-STORYLINES-V1-02.
-- Statut : TODO.
-- Prochain lot attendu : NS-STORYLINES-V1-04.
+- Statut : DONE.
+- Prochain lot attendu : NS-STORYLINES-V1-04 — StorylineAsset JSON Codec V0.
 
 ## 10. Update protocol for every future lot
 
@@ -778,10 +790,10 @@ Décision temporaire :
 ## 13. Current status
 
 ```text
-Roadmap status: V0 ACCEPTED WITH V1 LIMITATIONS / V1 DATA SHAPE CONTRACT DONE
-Current lot: NS-STORYLINES-V1-02
+Roadmap status: V0 ACCEPTED WITH V1 LIMITATIONS / V1 PURE MODEL DONE
+Current lot: NS-STORYLINES-V1-03
 Current lot status: DONE
-Next recommended lot: NS-STORYLINES-V1-03 — StorylineAsset Model V0
+Next recommended lot: NS-STORYLINES-V1-04 — StorylineAsset JSON Codec V0
 ```
 
 | Lot | Status | Last update | Notes |
@@ -803,7 +815,11 @@ Next recommended lot: NS-STORYLINES-V1-03 — StorylineAsset Model V0
 | NS-STORYLINES-V1-00 | DONE | 2026-05-28 | Reset sémantique produit livré : Storylines V0 techniquement valide, V1 doit clarifier et rendre utilisables Storyline / Chapter / Story Step / Scene / Graph / Structure. |
 | NS-STORYLINES-V1-01 | DONE | 2026-05-28 | Modèle hybride retenu : `StorylineAsset` authoring + `ScenarioAsset` executable scene flow ; Structure source d'authoring, Graph généré. |
 | NS-STORYLINES-V1-02 | DONE | 2026-05-28 | Contrat data shape `StorylineAsset` livré : champs, enums, invariants, validations, JSON, migration legacy, UI actions et tests futurs. |
-| NS-STORYLINES-V1-03 | TODO | 2026-05-28 | StorylineAsset Model V0. |
+| NS-STORYLINES-V1-03 | DONE | 2026-05-28 | StorylineAsset Pure Model V0 livré dans `map_core`, sans JSON/manifest/UI. |
+| NS-STORYLINES-V1-04 | TODO | 2026-05-28 | StorylineAsset JSON Codec V0. |
+| NS-STORYLINES-V1-05 | TODO | 2026-05-28 | ProjectManifest.storylines Integration V0. |
+| NS-STORYLINES-V1-06 | TODO | 2026-05-28 | Legacy GlobalStory Import Preview V0. |
+| NS-STORYLINES-V1-07 | TODO | 2026-05-28 | Create Main Storyline Flow V0. |
 
 ## 14. V1 Creation Readiness Notes
 
@@ -826,15 +842,27 @@ Suite V1 documentaire recommandée :
 - `NS-STORYLINES-V1-00 — Storyline Semantics Reset / Usable Authoring Contract`
 - `NS-STORYLINES-V1-01 — Storyline Authoring Model Decision`
 - `NS-STORYLINES-V1-02 — Storyline Authoring Data Shape Contract`
-- `NS-STORYLINES-V1-03 — StorylineAsset Model V0`
-- `NS-STORYLINES-V1-04 — Create Main Storyline Flow`
-- `NS-STORYLINES-V1-05 — Create Side Quest Storyline Flow`
-- `NS-STORYLINES-V1-06 — Storyline Type / Status / Validation`
-- `NS-STORYLINES-V1-07 — Side Quest Graph Integration`
-- `NS-STORYLINES-V1-08 — V1 Visual Graph Enrichment`
+- `NS-STORYLINES-V1-03 — StorylineAsset Pure Model V0`
+- `NS-STORYLINES-V1-04 — StorylineAsset JSON Codec V0`
+- `NS-STORYLINES-V1-05 — ProjectManifest.storylines Integration V0`
+- `NS-STORYLINES-V1-06 — Legacy GlobalStory Import Preview V0`
+- `NS-STORYLINES-V1-07 — Create Main Storyline Flow V0`
+- `NS-STORYLINES-V1-08 — Create Side Quest Storyline Flow V0`
+- `NS-STORYLINES-V1-09 — Storyline Type / Status / Validation`
+- `NS-STORYLINES-V1-10 — Side Quest Graph Integration`
+- `NS-STORYLINES-V1-11 — V1 Visual Graph Enrichment`
 
 ## 15. Changelog
 
+### 2026-05-28 — NS-STORYLINES-V1-03
+
+- Premier modèle pur Storylines V1 livré dans `map_core`.
+- `StorylineAsset` et sous-objets essentiels ajoutés : chapters, steps, scene links, scene refs, outcome links, effects, relationships, side quest availability, anchors, validation issues et legacy source.
+- Enums Storylines V1 ajoutés pour type, status, scene link state/role, relationship kind, validation severity, effect type, anchor kind et scene ref kind.
+- Tests ciblés ajoutés pour constructions valides, validations locales, références internes, règles d'état, immutabilité, equality/hashCode et absence de JSON codec.
+- Non-objectifs respectés : aucun `toJson/fromJson`, aucun `ProjectManifest.storylines`, aucune migration legacy, aucune UI, aucun generated file.
+- Prochain lot recommandé : `NS-STORYLINES-V1-04 — StorylineAsset JSON Codec V0`.
+
 ### 2026-05-28 — NS-STORYLINES-V1-02
 
 - Contrat de données Storylines V1 livré.
@@ -843,7 +871,7 @@ Suite V1 documentaire recommandée :
 - Décision : `StorylineSceneLink` V1 initial démarre avec `placeholder` et `linkedScenario`; dialogue/cinematic/battle restent dans le `ScenarioAsset` exécutable.
 - Décision : outcome links V1 initial activent/complètent des `StorylineStep`; facts/world rules réservés à plus tard.
 - Migration : legacy import preview non destructif depuis `ScenarioAsset.globalStory`; `localEventFlow` jamais promu automatiquement.
-- Prochain lot recommandé : `NS-STORYLINES-V1-03 — StorylineAsset Model V0`.
+- Prochain lot recommandé : `NS-STORYLINES-V1-03 — StorylineAsset Pure Model V0`.
 
 ### 2026-05-28 — NS-STORYLINES-V1-01
```

### Sorties exactes des tests ciblés

Commande :

```bash
cd packages/map_core && dart test --reporter json test/storyline_asset_test.dart | tail -n 1
```

Sortie :

```text
{"success":true,"type":"done","time":402}
```

Commande :

```bash
cd packages/map_core && dart test --reporter json test/scenario_assets_test.dart | tail -n 1
```

Sortie :

```text
{"success":true,"type":"done","time":360}
```

### Sortie exacte de dart analyze

Commande :

```bash
cd packages/map_core && dart analyze lib/src/models/storyline_asset.dart test/storyline_asset_test.dart
```

Sortie :

```text
Analyzing storyline_asset.dart, storyline_asset_test.dart...
No issues found!
```

### Sortie exacte du test complet map_core

Commande :

```bash
cd packages/map_core && dart test --reporter json | tail -n 1
```

Sortie :

```text
{"success":true,"type":"done","time":4593}
```

### Git status final exact

```text
 M packages/map_core/lib/map_core.dart
 M reports/narrativeStudio/storylines/road_map_storylines.md
?? packages/map_core/lib/src/models/storyline_asset.dart
?? packages/map_core/test/storyline_asset_test.dart
?? reports/narrativeStudio/storylines/ns_storylines_v1_03_storyline_asset_pure_model_v0.md
```

### Git diff --stat final

```text
 packages/map_core/lib/map_core.dart                |  1 +
 .../storylines/road_map_storylines.md              | 68 +++++++++++++++-------
 2 files changed, 49 insertions(+), 20 deletions(-)
```

### Git diff --name-only final

```text
packages/map_core/lib/map_core.dart
reports/narrativeStudio/storylines/road_map_storylines.md
```

### Git diff --check final

```text
Sortie : <vide>
```

### Auto-review critique

- Le lot respecte le découpage demandé : modèle pur seulement.
- Les validations implémentées sont locales ; les validations globales restent volontairement au futur niveau collection / manifest / validator.
- `ScriptCondition` est réutilisé sans créer de nouveau langage conditionnel, mais l'UI no-code devra plus tard fournir une couche lisible au-dessus.
- `StorylineLegacySource.kind` reste string pour éviter une fausse précision avant le lot d'import legacy.
- Les fichiers JSON/manifest/UI n'ont pas été touchés.
- Limite restante : le modèle n'est pas encore persistable ; c'est le rôle du lot V1-04.

## 14. Self-review

Critères vérifiés :

- `StorylineAsset` existe comme modèle pur.
- Enums principaux et sous-objets essentiels existent.
- Constructeurs valident les invariants locaux.
- Collections immuables / copiées défensivement.
- `map_core.dart` exporte le modèle.
- Aucun JSON codec.
- Aucun `toJson/fromJson`.
- `ProjectManifest` non modifié.
- `ScenarioAsset` non modifié.
- Fichiers générés non modifiés.
- `build_runner` non lancé.
- `map_editor` non modifié.
- Tests ciblés passés.
- Analyse ciblée passée.
- Test complet `map_core` passé.
- Roadmap mise à jour.
- Prochain lot recommandé : NS-STORYLINES-V1-04 — StorylineAsset JSON Codec V0.
