# NS-SCENES-V1-72 — Cinematic Stage / Map Context Core Model V0

## 1. Resume executif

V1-72 materialise le contrat V1-71 dans `map_core` uniquement.

Le modele authoring du Stage Context est maintenant porte par `CinematicAsset.stageContext`, tandis que `CinematicAsset.mapId` reste l'unique ancre Stage Map. Il n'y a pas de `stageContext.mapId`.

Le lot ajoute `backdropMode`, les actor bindings, les placements initiaux, les bindings de cibles de mouvement, les operations pures d'authoring et les diagnostics core. La timeline reste lineaire et preservee : aucun `startMs/endMs` persistant, aucun playback, aucune preview reelle, aucun runtime cinematic map-aware.

## 2. Gate 0

Commande `pwd` :

```text
/Users/karim/Project/pokemonProject
```

Commande `git branch --show-current` :

```text
main
```

Commande `git status --short --untracked-files=all` :

```text
<vide>
```

Commande `git diff --stat` :

```text
<vide>
```

Commande `git diff --name-only` :

```text
<vide>
```

Commande `git log --oneline -n 15` :

```text
e77212ff feat(narrative): add cinematic stage map context prep contract (NS-SCENES-V1-71)
edf3d1bd feat(narrative): add cinematic timeline duration validation diagnostics polish v0 (NS-SCENES-V1-70)
875404af feat(narrative): add cinematic timeline duration resize handles v0 (NS-SCENES-V1-69)
263233b4 feat(narrative): add cinematic timeline duration inspector editing v0 (NS-SCENES-V1-68)
c8bb19a2 feat(narrative): add cinematic timeline duration editing resize prep contract (NS-SCENES-V1-67)
e67e71c7 feat(narrative): add cinematic timeline mouse probe help selection explanation v0 (NS-SCENES-V1-66)
46cc0eb4 feat(narrative): add cinematic timeline mouse probe UX polish clear controls v0 (NS-SCENES-V1-65)
95e79063 feat(narrative): add cinematic timeline mouse probe boundary snap v0 (NS-SCENES-V1-64)
86004392 feat(narrative): add cinematic timeline mouse probe polish boundary snap prep v0 (NS-SCENES-V1-63)
79414165 feat(narrative): add cinematic timeline mouse time probe playhead drag v0 (NS-SCENES-V1-62)
044155fc feat(narrative): add cinematic timeline mouse playhead scrub prep contract (NS-SCENES-V1-61)
32f92c54 feat(narrative): add cinematic timeline keyboard navigation polish help overlay v0 (NS-SCENES-V1-60)
ede69519 feat(narrative): add cinematic timeline lane vertical navigation v0 (NS-SCENES-V1-59)
e1e83cd9 feat(narrative): add cinematic timeline lane vertical navigation prep contract (NS-SCENES-V1-58)
26958d88 feat(narrative): add cinematic timeline keyboard navigation selection polish v0 (NS-SCENES-V1-57)
```

Le working tree etait propre au Gate 0.

## 3. Fichiers lus

Instructions et prompt : `AGENTS.md`, `skills/README.md`, `skills/test-driven-development/SKILL.md`, `skills/writing-plans/SKILL.md`, `skills/verification-before-completion/SKILL.md`, prompt V1-72.

Roadmaps et rapports : `reports/narrativeStudio/scenes/road_map_scenes.md`, `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`, rapport V1-71 et rapports/evidence packs V1-70.

Core : `packages/map_core/lib/src/models/cinematic_asset.dart`, `packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart`, `packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart`, tests cinematic/manifest/read models.

Editor non-regression : `packages/map_editor/test/cinematics_library_workspace_test.dart`, `packages/map_editor/test/cinematic_builder_workspace_test.dart`.

## 4. TDD RED obligatoire

Premier RED model :

```bash
cd packages/map_core && dart test --reporter=compact test/cinematic_asset_test.dart --name "serializes cinematic stage context without duplicating map id"
```

Resultat :

```text
Exit 1
Undefined name 'CinematicStageBackdropMode'.
Undefined name 'CinematicActorBindingKind'.
Method not found: 'CinematicActorBinding'.
Undefined name 'CinematicActorInitialPlacementKind'.
Method not found: 'CinematicActorInitialPlacement'.
Undefined name 'CinematicMovementTargetBindingKind'.
Method not found: 'CinematicMovementTargetBinding'.
Method not found: 'CinematicStageContext'.
No named parameter with the name 'stageContext'.
```

RED authoring :

```bash
cd packages/map_core && dart test --reporter=compact test/cinematic_authoring_operations_test.dart --name "updates cinematic stage map and backdrop without mutating timeline|upserts and removes actor bindings with validation|upserts placements and target bindings while preserving legacy bridge"
```

Resultat :

```text
Exit 1
Method not found: 'updateCinematicStageMap'.
Method not found: 'updateCinematicStageContext'.
Method not found: 'upsertCinematicActorBinding'.
Method not found: 'removeCinematicActorBinding'.
Method not found: 'upsertCinematicActorInitialPlacement'.
Method not found: 'upsertCinematicMovementTargetBinding'.
Method not found: 'removeCinematicActorInitialPlacement'.
Method not found: 'removeCinematicMovementTargetBinding'.
```

RED diagnostics :

```bash
cd packages/map_core && dart test --reporter=compact test/cinematic_diagnostics_test.dart --name "diagnoses unknown stage map and projectMap backdrop readiness|allows cinematic without stage context as draft|diagnoses actor binding issues and preview readiness|diagnoses initial placement issues and preview readiness|diagnoses movement target binding issues"
```

Resultat :

```text
Exit 1
Undefined name 'stageMapUnknown'.
Undefined name 'stageBackdropRequiresMap'.
Undefined name 'actorBindingMissing'.
Undefined name 'actorBindingUnknownActor'.
Undefined name 'actorBindingDuplicatePlayer'.
Undefined name 'actorBindingRequiresStageMap'.
Undefined name 'actorBindingMapEntityMissingSource'.
Undefined name 'actorInitialPlacementUnknownActor'.
Undefined name 'actorInitialPlacementTargetUnknown'.
Undefined name 'actorInitialPlacementRequiresBinding'.
Undefined name 'actorInitialPlacementMissing'.
Undefined name 'movementTargetBindingUnknownTarget'.
Undefined name 'movementTargetBindingRequiresStageMap'.
Undefined name 'movementTargetBindingMissingSource'.
```

## 5. Modele ajoute

`CinematicAsset` gagne un champ optionnel `stageContext`.

`CinematicStageContext` contient :

- `backdropMode`;
- `actorBindings`;
- `initialPlacements`;
- `movementTargetBindings`.

Enums V0 :

- `CinematicStageBackdropMode.none | projectMap`;
- `CinematicActorBindingKind.player | mapEntity | cinematicOnly | unbound`;
- `CinematicActorInitialPlacementKind.unset | fromMapEntity | fromMovementTarget`;
- `CinematicMovementTargetBindingKind.abstractPoint | mapEntity | mapEvent`.

Decision importante : `CinematicAsset.mapId` reste l'ancre Stage Map. Le JSON de `stageContext` ne contient pas `mapId`, et le test le verrouille.

## 6. Operations pures ajoutees

Operations `map_core` :

- `updateCinematicStageMap`;
- `updateCinematicStageContext`;
- `upsertCinematicActorBinding`;
- `removeCinematicActorBinding`;
- `upsertCinematicActorInitialPlacement`;
- `removeCinematicActorInitialPlacement`;
- `upsertCinematicMovementTargetBinding`;
- `removeCinematicMovementTargetBinding`.

Les operations preservent timeline, metadata, notes, tags, actors, movement targets et legacy bridge sauf champ explicitement vise.

Validations authoring :

- acteur inconnu refuse pour binding/placement ;
- target inconnu refuse pour placement ou target binding ;
- un seul actor binding `player` ;
- source requise pour target binding `mapEntity` / `mapEvent` ;
- suppression refuse les refs absentes.

## 7. Diagnostics core ajoutes

Codes ajoutes :

- `stageMapUnknown`;
- `stageBackdropRequiresMap`;
- `actorBindingUnknownActor`;
- `actorBindingMissing`;
- `actorBindingDuplicatePlayer`;
- `actorBindingRequiresStageMap`;
- `actorBindingMapEntityMissingSource`;
- `actorInitialPlacementUnknownActor`;
- `actorInitialPlacementMissing`;
- `actorInitialPlacementTargetUnknown`;
- `actorInitialPlacementRequiresBinding`;
- `movementTargetBindingUnknownTarget`;
- `movementTargetBindingRequiresStageMap`;
- `movementTargetBindingMissingSource`.

Un `CinematicAsset` sans `stageContext` reste un draft valide cote stage et ne recoit pas de diagnostic stage.

## 8. Tests ajoutes ou modifies

`packages/map_core/test/cinematic_asset_test.dart` :

- serialization stage context sans duplication map ;
- old JSON sans `stageContext`;
- variants V0 des enums stage.

`packages/map_core/test/cinematic_authoring_operations_test.dart` :

- update map/backdrop sans muter timeline ;
- upsert/remove actor bindings ;
- placements/target bindings en preservant legacy bridge.

`packages/map_core/test/cinematic_diagnostics_test.dart` :

- map stage inconnue / backdrop projectMap ;
- draft sans stageContext ;
- actor bindings ;
- placements initiaux ;
- target bindings.

`packages/map_core/test/project_manifest_cinematics_test.dart` :

- round-trip manifest JSON avec `stageContext`.

Adaptation : le prompt citait `test/project_manifest_test.dart`; le fichier pertinent existant dans ce package est `test/project_manifest_cinematics_test.dart`, utilise pour la verification.

## 9. Non-objectifs confirmes

Non realise dans V1-72 :

- aucune UI Stage Context ;
- aucune preview reelle ;
- aucun runtime cinematic map-aware ;
- aucun pathfinding ;
- aucune collision/warp ;
- aucun playback/timer/transport ;
- aucun `startMs/endMs` persistant ;
- aucun build_runner ;
- aucune image IA ;
- aucune donnee Selbrume ou map hardcodee.

Limite connue : les diagnostics V0 valident les refs cinematic et l'existence du `ProjectManifest.maps` stage, mais ne resolvent pas encore les IDs d'entites/events dans le contenu charge d'une map. Cette resolution appartient au futur editor/preview stage-aware.

## 10. Commandes executees

Format :

```bash
dart format packages/map_core/lib/src/models/cinematic_asset.dart packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart packages/map_core/test/cinematic_asset_test.dart packages/map_core/test/cinematic_authoring_operations_test.dart packages/map_core/test/cinematic_diagnostics_test.dart packages/map_core/test/project_manifest_cinematics_test.dart
```

Tests core ciblés :

```bash
cd packages/map_core && dart test --reporter=compact test/cinematic_asset_test.dart
cd packages/map_core && dart test --reporter=compact test/project_manifest_cinematics_test.dart
cd packages/map_core && dart test --reporter=compact test/cinematic_authoring_operations_test.dart
cd packages/map_core && dart test --reporter=compact test/cinematic_diagnostics_test.dart
cd packages/map_core && dart test --reporter=compact test/cinematic_timeline_time_layout_read_model_test.dart
cd packages/map_core && dart test --reporter=compact test/cinematic_timeline_lane_read_model_test.dart
```

Tests et analyse larges :

```bash
cd packages/map_core && dart test --reporter=compact
cd packages/map_core && dart analyze
cd packages/map_editor && flutter test --reporter=compact test/cinematics_library_workspace_test.dart
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart
cd packages/map_editor && flutter analyze
```

Anti-scope :

```bash
git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle examples
rg -n "PlayableMapGame|SceneRuntimeExecutor|SceneEventRuntimeHook|SceneCinematicRuntimeAwaitableAdapter|SceneCinematicRuntimeNoVisualPlayer|playCinematic|startPlayback|stopPlayback|pausePlayback|resumePlayback|runtimePreview|previewRuntime|PlaybackController|Timer\\(|Ticker|AnimationController|isPlaying|currentTimeMs|playbackTimeMs|pathfinding|Pathfinder|collision|warp|spawnRuntime|GameState|MapRuntime|runtimeSpawn|gpt-image-2|image_generation|generate image|AI image|image model|selbrume|mael|maël|lysa|port_brisants|bourg_selbrume|phare|brume|marais" <fichiers modifies>
rg -n "stageContext.*mapId|CinematicStageContext\\([^\\)]*mapId|mapId.*stageContext" packages/map_core/lib/src/models packages/map_core/test
rg -n "startMs|endMs|cursorTimeMs|playheadTimeMs|currentTimeMs|playbackTimeMs|isPlaying|persistedStartMs|persistedEndMs" packages/map_core/lib/src/models packages/map_core/lib/src/authoring packages/map_core/lib/src/diagnostics
```

## 11. Resultats

GREEN ciblés :

```text
cinematic_asset_test.dart: +8 All tests passed!
project_manifest_cinematics_test.dart: +6 All tests passed!
cinematic_authoring_operations_test.dart: +37 All tests passed!
cinematic_diagnostics_test.dart: +24 All tests passed!
cinematic_timeline_time_layout_read_model_test.dart: +4 All tests passed!
cinematic_timeline_lane_read_model_test.dart: +2 All tests passed!
```

Suite complete core :

```text
cd packages/map_core && dart test --reporter=compact
+2354: All tests passed!
```

Analyse core :

```text
Analyzing map_core...
No issues found!
```

Non-regression editor :

```text
cinematics_library_workspace_test.dart: +10 All tests passed!
cinematic_builder_workspace_test.dart: +93 All tests passed!
```

Analyse editor globale :

```text
cd packages/map_editor && flutter analyze
Exit 1
344 issues found.
```

Cette analyse reste rouge sur dette hors lot deja connue, notamment `pokemon_sdk_move_catalog_converter.dart` (`dbSymbol`, `PokemonMoveAimedTarget`, `PokemonMoveFlags`, `PokemonMoveBattleStageMod`, `PokemonMoveStatus`) et `sync_pokemon_sdk_moves_catalog_use_case.dart` (`fetchPokemonSdkStudioProjectPayload`). Aucun fichier `map_editor` n'a ete modifie par V1-72.

Anti-scope :

```text
git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle examples
<vide>

runtime/playback/pathfinding/image/Selbrume rg
<vide>

startMs/endMs/persisted playback rg
<vide>
```

Le seul match `stageContext/mapId` est volontaire :

```text
packages/map_core/test/project_manifest_cinematics_test.dart:104: expect(cinematicJson['stageContext'], isNot(contains('mapId')));
```

## 12. Fichiers modifies

```text
packages/map_core/lib/src/models/cinematic_asset.dart
packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart
packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart
packages/map_core/test/cinematic_asset_test.dart
packages/map_core/test/cinematic_authoring_operations_test.dart
packages/map_core/test/cinematic_diagnostics_test.dart
packages/map_core/test/project_manifest_cinematics_test.dart
reports/narrativeStudio/scenes/ns_scenes_v1_72_cinematic_stage_map_context_core_model_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_72_evidence_pack.md
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
```

## 13. Code genere

Karim a demande que le code genere soit present dans le rapport. Cette annexe ajoute donc les surfaces de code production et le test principal qui verrouille l'invariant le plus important du lot : `CinematicAsset.mapId` reste l'unique ancre Stage Map et `stageContext` ne contient pas de `mapId`.

### 13.1 Modele Stage Context

Fichier : `packages/map_core/lib/src/models/cinematic_asset.dart`

```dart
enum CinematicStageBackdropMode {
  none,
  projectMap,
}

enum CinematicActorBindingKind {
  player,
  mapEntity,
  cinematicOnly,
  unbound,
}

enum CinematicActorInitialPlacementKind {
  unset,
  fromMapEntity,
  fromMovementTarget,
}

enum CinematicMovementTargetBindingKind {
  abstractPoint,
  mapEntity,
  mapEvent,
}
```

```dart
final CinematicStageContext? stageContext;
```

```dart
@immutable
final class CinematicStageContext {
  CinematicStageContext({
    this.backdropMode = CinematicStageBackdropMode.none,
    List<CinematicActorBinding> actorBindings = const <CinematicActorBinding>[],
    List<CinematicActorInitialPlacement> initialPlacements =
        const <CinematicActorInitialPlacement>[],
    List<CinematicMovementTargetBinding> movementTargetBindings =
        const <CinematicMovementTargetBinding>[],
  })  : actorBindings = List<CinematicActorBinding>.unmodifiable(actorBindings),
        initialPlacements = List<CinematicActorInitialPlacement>.unmodifiable(
          initialPlacements,
        ),
        movementTargetBindings =
            List<CinematicMovementTargetBinding>.unmodifiable(
          movementTargetBindings,
        );

  factory CinematicStageContext.fromJson(Map<String, dynamic> json) {
    return CinematicStageContext(
      backdropMode: _readEnum(
        CinematicStageBackdropMode.values,
        json['backdropMode'] ?? CinematicStageBackdropMode.none.name,
        'backdropMode',
      ),
      actorBindings: _readObjectList(
        json,
        'actorBindings',
        CinematicActorBinding.fromJson,
      ),
      initialPlacements: _readObjectList(
        json,
        'initialPlacements',
        CinematicActorInitialPlacement.fromJson,
      ),
      movementTargetBindings: _readObjectList(
        json,
        'movementTargetBindings',
        CinematicMovementTargetBinding.fromJson,
      ),
    );
  }

  final CinematicStageBackdropMode backdropMode;
  final List<CinematicActorBinding> actorBindings;
  final List<CinematicActorInitialPlacement> initialPlacements;
  final List<CinematicMovementTargetBinding> movementTargetBindings;

  Map<String, dynamic> toJson() => {
        'backdropMode': backdropMode.name,
        'actorBindings':
            actorBindings.map((binding) => binding.toJson()).toList(),
        'initialPlacements':
            initialPlacements.map((placement) => placement.toJson()).toList(),
        'movementTargetBindings':
            movementTargetBindings.map((binding) => binding.toJson()).toList(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CinematicStageContext &&
          other.backdropMode == backdropMode &&
          _listEquals(other.actorBindings, actorBindings) &&
          _listEquals(other.initialPlacements, initialPlacements) &&
          _listEquals(other.movementTargetBindings, movementTargetBindings);

  @override
  int get hashCode => Object.hash(
        backdropMode,
        Object.hashAll(actorBindings),
        Object.hashAll(initialPlacements),
        Object.hashAll(movementTargetBindings),
      );
}
```

```dart
@immutable
final class CinematicActorBinding {
  CinematicActorBinding({
    required String actorId,
    required this.kind,
    String? mapEntityId,
  })  : actorId = _requireTrimmed(
          actorId,
          'CinematicActorBinding.actorId',
        ),
        mapEntityId = _trimOptional(mapEntityId);

  factory CinematicActorBinding.fromJson(Map<String, dynamic> json) {
    return CinematicActorBinding(
      actorId: _readRequiredString(json, 'actorId'),
      kind: _readEnum(
        CinematicActorBindingKind.values,
        json['kind'],
        'kind',
      ),
      mapEntityId: _readOptionalString(json, 'mapEntityId'),
    );
  }

  final String actorId;
  final CinematicActorBindingKind kind;
  final String? mapEntityId;

  Map<String, dynamic> toJson() => _withoutNulls({
        'actorId': actorId,
        'kind': kind.name,
        'mapEntityId': mapEntityId,
      });
}
```

```dart
@immutable
final class CinematicActorInitialPlacement {
  CinematicActorInitialPlacement({
    required String actorId,
    required this.kind,
    String? targetId,
  })  : actorId = _requireTrimmed(
          actorId,
          'CinematicActorInitialPlacement.actorId',
        ),
        targetId = _trimOptional(targetId);

  factory CinematicActorInitialPlacement.fromJson(Map<String, dynamic> json) {
    return CinematicActorInitialPlacement(
      actorId: _readRequiredString(json, 'actorId'),
      kind: _readEnum(
        CinematicActorInitialPlacementKind.values,
        json['kind'],
        'kind',
      ),
      targetId: _readOptionalString(json, 'targetId'),
    );
  }

  final String actorId;
  final CinematicActorInitialPlacementKind kind;
  final String? targetId;

  Map<String, dynamic> toJson() => _withoutNulls({
        'actorId': actorId,
        'kind': kind.name,
        'targetId': targetId,
      });
}
```

```dart
@immutable
final class CinematicMovementTargetBinding {
  CinematicMovementTargetBinding({
    required String targetId,
    required this.kind,
    String? sourceId,
  })  : targetId = _requireTrimmed(
          targetId,
          'CinematicMovementTargetBinding.targetId',
        ),
        sourceId = _trimOptional(sourceId);

  factory CinematicMovementTargetBinding.fromJson(Map<String, dynamic> json) {
    return CinematicMovementTargetBinding(
      targetId: _readRequiredString(json, 'targetId'),
      kind: _readEnum(
        CinematicMovementTargetBindingKind.values,
        json['kind'],
        'kind',
      ),
      sourceId: _readOptionalString(json, 'sourceId'),
    );
  }

  final String targetId;
  final CinematicMovementTargetBindingKind kind;
  final String? sourceId;

  Map<String, dynamic> toJson() => _withoutNulls({
        'targetId': targetId,
        'kind': kind.name,
        'sourceId': sourceId,
      });
}
```

### 13.2 Operations d'authoring Stage Context

Fichier : `packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart`

```dart
final class CinematicStageContextAuthoringResult {
  const CinematicStageContextAuthoringResult({
    required this.updatedProject,
    required this.cinematic,
  });

  final ProjectManifest updatedProject;
  final CinematicAsset cinematic;
}
```

```dart
CinematicStageContextAuthoringResult updateCinematicStageMap(
  ProjectManifest project, {
  required String cinematicId,
  String? mapId,
});

CinematicStageContextAuthoringResult updateCinematicStageContext(
  ProjectManifest project, {
  required String cinematicId,
  CinematicStageContext? stageContext,
});

CinematicStageContextAuthoringResult upsertCinematicActorBinding(
  ProjectManifest project, {
  required String cinematicId,
  required CinematicActorBinding binding,
});

CinematicStageContextAuthoringResult removeCinematicActorBinding(
  ProjectManifest project, {
  required String cinematicId,
  required String actorId,
});

CinematicStageContextAuthoringResult upsertCinematicActorInitialPlacement(
  ProjectManifest project, {
  required String cinematicId,
  required CinematicActorInitialPlacement placement,
});

CinematicStageContextAuthoringResult removeCinematicActorInitialPlacement(
  ProjectManifest project, {
  required String cinematicId,
  required String actorId,
});

CinematicStageContextAuthoringResult upsertCinematicMovementTargetBinding(
  ProjectManifest project, {
  required String cinematicId,
  required CinematicMovementTargetBinding binding,
});

CinematicStageContextAuthoringResult removeCinematicMovementTargetBinding(
  ProjectManifest project, {
  required String cinematicId,
  required String targetId,
});
```

Validation ajoutee :

```dart
void _validateStageContextForAuthoring(
  CinematicAsset cinematic,
  CinematicStageContext stageContext,
) {
  final playerActorIds = <String>{};
  for (final binding in stageContext.actorBindings) {
    _requireActor(cinematic, binding.actorId);
    if (binding.kind == CinematicActorBindingKind.player &&
        !playerActorIds.add(binding.actorId)) {
      throw ArgumentError.value(
        binding.actorId,
        'actorId',
        'Duplicate player actor binding.',
      );
    }
  }
  final playerBindings = stageContext.actorBindings
      .where((binding) => binding.kind == CinematicActorBindingKind.player)
      .toList();
  if (playerBindings.length > 1) {
    throw ArgumentError.value(
      playerBindings.last.actorId,
      'actorId',
      'Only one player actor binding is allowed in a cinematic.',
    );
  }

  for (final placement in stageContext.initialPlacements) {
    _requireActor(cinematic, placement.actorId);
    if (placement.kind ==
        CinematicActorInitialPlacementKind.fromMovementTarget) {
      _requireMovementTarget(cinematic, placement.targetId ?? '');
    }
  }

  for (final binding in stageContext.movementTargetBindings) {
    _requireMovementTarget(cinematic, binding.targetId);
    if (_movementTargetBindingRequiresSource(binding) &&
        binding.sourceId == null) {
      throw ArgumentError.value(
        binding.sourceId,
        'sourceId',
        'Map-aware movement target bindings require a source id.',
      );
    }
  }
}
```

### 13.3 Diagnostics Stage Context

Fichier : `packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart`

```dart
enum CinematicDiagnosticCode {
  cinematicMissingId,
  cinematicMissingTitle,
  cinematicDuplicateId,
  cinematicEmptyTimeline,
  cinematicDuplicateStepId,
  cinematicInvalidStepDuration,
  cinematicUnsupportedGameplayStep,
  cinematicTechnicalLabel,
  cinematicUnknownStorylineRef,
  cinematicUnknownChapterRef,
  cinematicUnknownMapRef,
  cinematicUnknownActorRef,
  cinematicActorMoveMissingActorRef,
  cinematicActorMoveMissingTargetRef,
  cinematicUnknownMovementTargetRef,
  cinematicActorMoveInvalidDuration,
  cinematicActorMoveInvalidMovementMode,
  cinematicActorMoveUnsupportedPathMode,
  stageMapUnknown,
  stageBackdropRequiresMap,
  actorBindingUnknownActor,
  actorBindingMissing,
  actorBindingDuplicatePlayer,
  actorBindingRequiresStageMap,
  actorBindingMapEntityMissingSource,
  actorInitialPlacementUnknownActor,
  actorInitialPlacementMissing,
  actorInitialPlacementTargetUnknown,
  actorInitialPlacementRequiresBinding,
  movementTargetBindingUnknownTarget,
  movementTargetBindingRequiresStageMap,
  movementTargetBindingMissingSource,
  cinematicLegacyBridge,
  cinematicScenarioBridgeNotCanonical,
}
```

```dart
enum CinematicDiagnosticTarget {
  cinematic,
  timeline,
  step,
  reference,
  stageContext,
  legacyBridge,
}
```

Hook de diagnostic ajoute :

```dart
CinematicDiagnosticsReport diagnoseCinematicAsset(CinematicAsset cinematic) {
  final diagnostics = <CinematicDiagnostic>[];
  _diagnoseCinematicShape(cinematic, diagnostics);
  _diagnoseStageContext(cinematic, diagnostics);
  _diagnoseTimeline(cinematic, diagnostics);
  _diagnoseLegacyBridge(cinematic, diagnostics);
  return CinematicDiagnosticsReport(diagnostics: diagnostics);
}
```

Diagnostic map stage projet :

```dart
final mapId = cinematic.mapId;
if (mapId != null && mapIds.isNotEmpty && !mapIds.contains(mapId)) {
  diagnostics.add(
    CinematicDiagnostic(
      code: CinematicDiagnosticCode.stageMapUnknown,
      severity: CinematicDiagnosticSeverity.error,
      message: 'La cinématique utilise une map stage inconnue.',
      cinematicId: cinematic.id,
      referenceId: mapId,
      target: CinematicDiagnosticTarget.stageContext,
      suggestedFixLabel: 'Choisir une map existante pour le stage.',
    ),
  );
  diagnostics.add(
    CinematicDiagnostic(
      code: CinematicDiagnosticCode.cinematicUnknownMapRef,
      severity: CinematicDiagnosticSeverity.warning,
      message: 'La cinématique référence une map inconnue.',
      cinematicId: cinematic.id,
      referenceId: mapId,
      target: CinematicDiagnosticTarget.reference,
      suggestedFixLabel: 'Choisir une map existante.',
    ),
  );
}
```

### 13.4 Test de verrouillage mapId / stageContext

Fichier : `packages/map_core/test/cinematic_asset_test.dart`

```dart
test('serializes cinematic stage context without duplicating map id', () {
  final asset = CinematicAsset(
    id: 'cinematic_stage_intro',
    title: 'Stage intro',
    mapId: 'map_lab',
    requiredActors: [
      CinematicActorRef(actorId: 'actor_player', label: 'Joueur'),
      CinematicActorRef(actorId: 'actor_professor', label: 'Professor'),
    ],
    movementTargets: [
      CinematicMovementTargetRef(
        targetId: 'target_center',
        label: 'Centre scene',
      ),
    ],
    stageContext: CinematicStageContext(
      backdropMode: CinematicStageBackdropMode.projectMap,
      actorBindings: [
        CinematicActorBinding(
          actorId: 'actor_player',
          kind: CinematicActorBindingKind.player,
        ),
        CinematicActorBinding(
          actorId: 'actor_professor',
          kind: CinematicActorBindingKind.mapEntity,
          mapEntityId: 'entity_professor',
        ),
      ],
      initialPlacements: [
        CinematicActorInitialPlacement(
          actorId: 'actor_professor',
          kind: CinematicActorInitialPlacementKind.fromMovementTarget,
          targetId: 'target_center',
        ),
      ],
      movementTargetBindings: [
        CinematicMovementTargetBinding(
          targetId: 'target_center',
          kind: CinematicMovementTargetBindingKind.mapEntity,
          sourceId: 'entity_stage_center',
        ),
      ],
    ),
    timeline: CinematicTimeline(
      steps: [
        CinematicTimelineStep(
          id: 'step_actor_move',
          kind: CinematicTimelineStepKind.actorMove,
          actorId: 'actor_professor',
          targetId: 'target_center',
          durationMs: 1000,
        ),
      ],
    ),
  );

  final json = jsonDecode(jsonEncode(asset.toJson())) as Map<String, dynamic>;
  final decoded = CinematicAsset.fromJson(json);

  expect(decoded, asset);
  expect(json['mapId'], 'map_lab');
  final stageContext = json['stageContext'] as Map<String, dynamic>;
  expect(stageContext, isNot(contains('mapId')));
  expect(jsonEncode(stageContext).contains('map_lab'), isFalse);
  expect(jsonEncode(json).split('map_lab').length - 1, 1);
  expect(decoded.stageContext?.backdropMode, CinematicStageBackdropMode.projectMap);
  expect(decoded.timeline.steps.single.durationMs, 1000);
  expect(jsonEncode(json).contains('startMs'), isFalse);
  expect(jsonEncode(json).contains('endMs'), isFalse);
});
```

## 14. Statut

`NS-SCENES-V1-72 — Cinematic Stage / Map Context Core Model V0` peut etre marque DONE.

Prochain lot recommande : `NS-SCENES-V1-73 — Cinematic Stage / Map Context Editor V0`.
