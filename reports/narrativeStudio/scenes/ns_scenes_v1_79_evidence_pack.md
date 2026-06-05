# NS-SCENES-V1-79 — Evidence Pack

## 1. Lot

`NS-SCENES-V1-79 — Cinematic Character Library Binding Core Model V0`

Demandeur : Karim.

## 2. Gate 0

```bash
pwd
```

```text
/Users/karim/Project/pokemonProject
```

```bash
git branch --show-current
```

```text
main
```

```bash
git status --short --untracked-files=all
```

```text

```

```bash
git diff --stat
```

```text

```

```bash
git diff --name-only
```

```text

```

```bash
git log --oneline -n 15
```

```text
92a6c95e feat(narrative): add cinematic character library binding prep contract (NS-SCENES-V1-78)
d5113ec2 feat(narrative): add cinematic stage map entity event pickers v0 (NS-SCENES-V1-77)
01a69fdd feat(narrative): add cinematic stage map source catalog v0 (NS-SCENES-V1-76)
bea04114 feat(narrative): add cinematic map entity event source audit picker prep contract (NS-SCENES-V1-75)
fe619092 feat(narrative): add cinematic stage map context editor and diagnostics preview readiness polish v0 (NS-SCENES-V1-73-V1-74)
632e3747 feat(narrative): add cinematic stage map context core model v0 (NS-SCENES-V1-72)
e77212ff feat(narrative): add cinematic stage map context prep contract (NS-SCENES-V1-71)
edf3d1bd feat(narrative): add cinematic timeline duration validation diagnostics polish v0 (NS-SCENES-V1-70)
875404af feat(narrative): add cinematic timeline duration resize handles v0 (NS-SCENES-V1-69)
263233b4 feat(narrative): add cinematic timeline duration inspector editing v0 (NS-SCENES-V1-68)
c8bb19a2 feat(narrative): add cinematic timeline duration editing resize prep contract (NS-SCENES-V1-67)
e67e71c7 feat(narrative): add cinematic timeline mouse probe help selection explanation v0 (NS-SCENES-V1-66)
46cc0eb4 feat(narrative): add cinematic timeline mouse probe UX polish clear controls v0 (NS-SCENES-V1-65)
95e79063 feat(narrative): add cinematic timeline mouse probe boundary snap v0 (NS-SCENES-V1-64)
86004392 feat(narrative): add cinematic timeline mouse probe polish boundary snap prep v0 (NS-SCENES-V1-63)
```

## 3. Fichiers lus

- `AGENTS.md`
- `skills/README.md`
- `skills/writing-plans/SKILL.md`
- `skills/test-driven-development/SKILL.md`
- `skills/verification-before-completion/SKILL.md`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_78_cinematic_character_library_binding_prep_contract.md`
- `packages/map_core/lib/src/models/cinematic_asset.dart`
- `packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart`
- `packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart`
- `packages/map_core/test/cinematic_asset_test.dart`
- `packages/map_core/test/cinematic_authoring_operations_test.dart`
- `packages/map_core/test/cinematic_diagnostics_test.dart`
- `packages/map_core/test/project_manifest_cinematics_test.dart`

## 4. TDD RED — modèle

```bash
cd packages/map_core && dart test --reporter=compact test/cinematic_asset_test.dart --name 'serializes cinematic actor appearance binding for cinematic only actor'
```

```text
00:00 +0: loading test/cinematic_asset_test.dart
00:00 +0 -1: loading test/cinematic_asset_test.dart [E]
Failed to load "test/cinematic_asset_test.dart":
test/cinematic_asset_test.dart:168:13: Error: Method not found: 'CinematicActorAppearanceBinding'.
            CinematicActorAppearanceBinding(
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/cinematic_asset_test.dart:167:11: Error: No named parameter with the name 'actorAppearanceBindings'.
          actorAppearanceBindings: [
          ^^^^^^^^^^^^^^^^^^^^^^^
lib/src/models/cinematic_asset.dart:196:3: Context: Found this candidate, but the arguments don't match.
  CinematicStageContext({
  ^^^^^^^^^^^^^^^^^^^^^
test/cinematic_asset_test.dart:211:31: Error: The getter 'actorAppearanceBindings' isn't defined for the type 'CinematicStageContext'.
 - 'CinematicStageContext' is from 'package:map_core/src/models/cinematic_asset.dart' ('lib/src/models/cinematic_asset.dart').
Try correcting the name to the name of an existing getter, or defining a getter or field named 'actorAppearanceBindings'.
        decoded.stageContext?.actorAppearanceBindings.single.characterId,
                              ^^^^^^^^^^^^^^^^^^^^^^^

To run this test again: dart test test/cinematic_asset_test.dart -p vm --plain-name 'loading test/cinematic_asset_test.dart'
00:00 +0 -1: Some tests failed.
```

## 5. TDD RED — opérations

```bash
cd packages/map_core && dart test --reporter=compact test/cinematic_authoring_operations_test.dart --name 'upserts actor appearance binding for cinematic only actor'
```

```text
00:00 +0: loading test/cinematic_authoring_operations_test.dart
00:00 +0 -1: loading test/cinematic_authoring_operations_test.dart [E]
Failed to load "test/cinematic_authoring_operations_test.dart":
test/cinematic_authoring_operations_test.dart:422:22: Error: Method not found: 'upsertCinematicActorAppearanceBinding'.
      final result = upsertCinematicActorAppearanceBinding(
                     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/cinematic_authoring_operations_test.dart:482:22: Error: Method not found: 'upsertCinematicActorAppearanceBinding'.
      final result = upsertCinematicActorAppearanceBinding(
                     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/cinematic_authoring_operations_test.dart:535:22: Error: Method not found: 'removeCinematicActorAppearanceBinding'.
      final result = removeCinematicActorAppearanceBinding(
                     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
00:00 +0 -1: Some tests failed.
```

## 6. TDD RED — diagnostics

```bash
cd packages/map_core && dart test --reporter=compact test/cinematic_diagnostics_test.dart --name 'diagnoses actor appearance binding unknown actor'
```

```text
00:00 +0: loading test/cinematic_diagnostics_test.dart
00:00 +0 -1: loading test/cinematic_diagnostics_test.dart [E]
Failed to load "test/cinematic_diagnostics_test.dart":
test/cinematic_diagnostics_test.dart:690:47: Error: Member not found: 'cinematicOnlyCharacterMissing'.
        report.byCode(CinematicDiagnosticCode.cinematicOnlyCharacterMissing),
                                              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/cinematic_diagnostics_test.dart:721:43: Error: Member not found: 'actorAppearanceBindingUnknownActor'.
          .byCode(CinematicDiagnosticCode.actorAppearanceBindingUnknownActor)
                                          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/cinematic_diagnostics_test.dart:762:43: Error: Member not found: 'actorAppearanceBindingUnknownCharacter'.
          .byCode(CinematicDiagnosticCode.actorAppearanceBindingUnknownCharacter)
                                          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
00:00 +0 -1: Some tests failed.
```

## 7. Code ajouté — modèle

```dart
@immutable
final class CinematicActorAppearanceBinding {
  CinematicActorAppearanceBinding({
    required String actorId,
    required String characterId,
  })  : actorId = _requireTrimmed(
          actorId,
          'CinematicActorAppearanceBinding.actorId',
        ),
        characterId = _requireTrimmed(
          characterId,
          'CinematicActorAppearanceBinding.characterId',
        );

  factory CinematicActorAppearanceBinding.fromJson(
    Map<String, dynamic> json,
  ) {
    return CinematicActorAppearanceBinding(
      actorId: _readRequiredString(json, 'actorId'),
      characterId: _readRequiredString(json, 'characterId'),
    );
  }

  final String actorId;
  final String characterId;

  Map<String, dynamic> toJson() => {
        'actorId': actorId,
        'characterId': characterId,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CinematicActorAppearanceBinding &&
          other.actorId == actorId &&
          other.characterId == characterId;

  @override
  int get hashCode => Object.hash(actorId, characterId);
}
```

## 8. Code ajouté — Stage Context

```dart
CinematicStageContext({
  this.backdropMode = CinematicStageBackdropMode.none,
  List<CinematicActorBinding> actorBindings = const <CinematicActorBinding>[],
  List<CinematicActorAppearanceBinding> actorAppearanceBindings =
      const <CinematicActorAppearanceBinding>[],
  List<CinematicActorInitialPlacement> initialPlacements =
      const <CinematicActorInitialPlacement>[],
  List<CinematicMovementTargetBinding> movementTargetBindings =
      const <CinematicMovementTargetBinding>[],
})  : actorBindings = List<CinematicActorBinding>.unmodifiable(actorBindings),
      actorAppearanceBindings =
          List<CinematicActorAppearanceBinding>.unmodifiable(
        actorAppearanceBindings,
      ),
      initialPlacements = List<CinematicActorInitialPlacement>.unmodifiable(
        initialPlacements,
      ),
      movementTargetBindings =
          List<CinematicMovementTargetBinding>.unmodifiable(
        movementTargetBindings,
      );
```

```dart
actorAppearanceBindings: _readObjectList(
  json,
  'actorAppearanceBindings',
  CinematicActorAppearanceBinding.fromJson,
),
```

```dart
'actorAppearanceBindings':
    actorAppearanceBindings.map((binding) => binding.toJson()).toList(),
```

## 9. Code ajouté — opérations

```dart
CinematicStageContextAuthoringResult upsertCinematicActorAppearanceBinding(
  ProjectManifest project, {
  required String cinematicId,
  required CinematicActorAppearanceBinding binding,
}) {
  final cinematic = _requireCinematic(project, cinematicId);
  _requireActor(cinematic, binding.actorId);
  final context = cinematic.stageContext ?? CinematicStageContext();
  _requireCinematicOnlyActorBinding(context, binding.actorId);

  final bindings = <CinematicActorAppearanceBinding>[];
  var replaced = false;
  for (final existing in context.actorAppearanceBindings) {
    if (existing.actorId == binding.actorId) {
      bindings.add(binding);
      replaced = true;
    } else {
      bindings.add(existing);
    }
  }
  if (!replaced) {
    bindings.add(binding);
  }
  final updatedContext = CinematicStageContext(
    backdropMode: context.backdropMode,
    actorBindings: context.actorBindings,
    actorAppearanceBindings: bindings,
    initialPlacements: context.initialPlacements,
    movementTargetBindings: context.movementTargetBindings,
  );
  _validateStageContextForAuthoring(cinematic, updatedContext);
  final result = updateCinematicAsset(
    project,
    _copyCinematicWithStageContext(cinematic, updatedContext),
  );
  return CinematicStageContextAuthoringResult(
    updatedProject: result.updatedProject,
    cinematic: result.cinematic,
  );
}

CinematicStageContextAuthoringResult removeCinematicActorAppearanceBinding(
  ProjectManifest project, {
  required String cinematicId,
  required String actorId,
}) {
  final cinematic = _requireCinematic(project, cinematicId);
  final id = _trimRequired(
    actorId,
    'actorId',
    'Actor appearance binding removal requires an actor id.',
  );
  final context = cinematic.stageContext ?? CinematicStageContext();
  final bindings = context.actorAppearanceBindings
      .where((binding) => binding.actorId != id)
      .toList(growable: false);
  if (bindings.length == context.actorAppearanceBindings.length) {
    throw ArgumentError.value(
      actorId,
      'actorId',
      'Actor appearance binding removal references an unknown binding.',
    );
  }
  final updatedContext = CinematicStageContext(
    backdropMode: context.backdropMode,
    actorBindings: context.actorBindings,
    actorAppearanceBindings: bindings,
    initialPlacements: context.initialPlacements,
    movementTargetBindings: context.movementTargetBindings,
  );
  final result = updateCinematicAsset(
    project,
    _copyCinematicWithStageContext(cinematic, updatedContext),
  );
  return CinematicStageContextAuthoringResult(
    updatedProject: result.updatedProject,
    cinematic: result.cinematic,
  );
}
```

## 10. Code ajouté — diagnostics

```dart
actorAppearanceBindingUnknownActor,
actorAppearanceBindingUnknownCharacter,
actorAppearanceBindingRequiresCinematicOnly,
cinematicOnlyCharacterMissing,
characterLibraryUnavailable,
characterAssetMissingSprite,
characterAssetMissingPreviewData,
```

```dart
if (hasCinematicOnlyActor && charactersById.isEmpty) {
  for (final binding in stageContext.actorBindings) {
    if (binding.kind != CinematicActorBindingKind.cinematicOnly) {
      continue;
    }
    diagnostics.add(
      CinematicDiagnostic(
        code: CinematicDiagnosticCode.characterLibraryUnavailable,
        severity: CinematicDiagnosticSeverity.warning,
        message:
            'La Character Library est vide alors qu’un acteur cinematicOnly en dépendra.',
        cinematicId: cinematic.id,
        referenceId: binding.actorId,
        target: CinematicDiagnosticTarget.stageContext,
        suggestedFixLabel:
            'Créer un personnage dans la Character Library avant la preview.',
      ),
    );
  }
}
```

```dart
for (final binding in stageContext.actorAppearanceBindings) {
  final character = charactersById[binding.characterId];
  if (character == null) {
    diagnostics.add(
      CinematicDiagnostic(
        code: CinematicDiagnosticCode.actorAppearanceBindingUnknownCharacter,
        severity: CinematicDiagnosticSeverity.error,
        message:
            'Une apparence cinematic référence un personnage Character Library inconnu.',
        cinematicId: cinematic.id,
        referenceId: binding.characterId,
        target: CinematicDiagnosticTarget.stageContext,
        suggestedFixLabel: 'Choisir un personnage existant.',
      ),
    );
    continue;
  }
}
```

## 11. Tests ajoutés

`cinematic_asset_test.dart` :

- `serializes cinematic actor appearance binding for cinematic only actor`
- `deserializes cinematic asset without actor appearance bindings`
- `does not store character id inside actor binding`
- `roundtrips actor appearance bindings in stage context`
- `keeps actorAppearanceBindings empty by default`
- `does not persist startMs or endMs for actor appearance binding`

`cinematic_authoring_operations_test.dart` :

- `upserts actor appearance binding for cinematic only actor`
- `replaces existing actor appearance binding for same actor`
- `removes actor appearance binding`
- `rejects actor appearance binding for unknown actor`
- `rejects actor appearance binding for player actor in v0`
- `rejects actor appearance binding for map entity actor in v0`
- `rejects actor appearance binding for unbound actor in v0`
- `appearance binding operations do not mutate timeline steps`
- `appearance binding operations do not mutate durationMs`
- `appearance binding operations preserve map id and stage context map-free invariant`

`cinematic_diagnostics_test.dart` :

- `diagnoses actor appearance binding unknown actor`
- `diagnoses actor appearance binding unknown character`
- `diagnoses actor appearance binding requiring cinematic only`
- `warns when cinematic only actor has no character appearance`
- `warns when character library is unavailable for cinematic only actor`
- `warns when selected character has missing preview data if detectable`
- `does not warn character missing for map entity actor`
- `does not warn character missing for player actor`
- `does not warn character missing for unbound actor`
- `does not diagnose old asset without stage context as error`

`project_manifest_cinematics_test.dart` :

- `project manifest roundtrips cinematic actor appearance bindings`
- `project manifest old cinematic without appearance bindings still loads`
- `diagnostics can resolve character ids from ProjectManifest.characters`

## 12. GREEN — format

```bash
cd packages/map_core && dart format lib/src/models/cinematic_asset.dart lib/src/authoring/cinematic_authoring_operations.dart lib/src/diagnostics/cinematic_diagnostics.dart test/cinematic_asset_test.dart test/cinematic_authoring_operations_test.dart test/cinematic_diagnostics_test.dart test/project_manifest_cinematics_test.dart
```

```text
Formatted test/cinematic_asset_test.dart
Formatted test/cinematic_diagnostics_test.dart
Formatted test/project_manifest_cinematics_test.dart
Formatted 7 files (3 changed) in 0.04 seconds.
```

## 13. GREEN — tests ciblés

```bash
cd packages/map_core && dart test --reporter=compact test/cinematic_asset_test.dart --name 'serializes cinematic actor appearance binding for cinematic only actor'
```

```text
00:00 +0: loading test/cinematic_asset_test.dart
00:00 +1: All tests passed!
```

```bash
cd packages/map_core && dart test --reporter=compact test/cinematic_asset_test.dart
```

```text
00:00 +14: All tests passed!
```

```bash
cd packages/map_core && dart test --reporter=compact test/project_manifest_cinematics_test.dart
```

```text
00:00 +9: All tests passed!
```

```bash
cd packages/map_core && dart test --reporter=compact test/cinematic_authoring_operations_test.dart
```

```text
00:00 +47: All tests passed!
```

```bash
cd packages/map_core && dart test --reporter=compact test/cinematic_diagnostics_test.dart
```

```text
00:00 +34: All tests passed!
```

## 14. GREEN — analyse map_core

```bash
cd packages/map_core && dart analyze
```

```text
Analyzing map_core...
No issues found!
```

## 15. GREEN — suite complète map_core

```bash
cd packages/map_core && dart test --reporter=compact
```

```text
+2390 All tests passed!
```

La sortie complète est longue ; la ligne finale ci-dessus est la preuve terminale utile conservée pour le rapport.

## 16. Non-régression editor

Première tentative parallèle Builder : échec infrastructure Flutter startup lock.

```text
Waiting for another flutter command to release the startup lock...
Unable to delete file or directory at "/Users/karim/Project/pokemonProject/packages/map_editor/macos/Flutter/ephemeral/Packages/.packages". This may be due to the project being in a read-only volume. Consider relocating the project and trying again.
```

Relance séquentielle verte :

```bash
cd packages/map_editor && flutter test --reporter=compact test/cinematics_library_workspace_test.dart
```

```text
+13 All tests passed!
```

```bash
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart
```

```text
+129 All tests passed!
```

## 17. Analyse editor globale

```bash
cd packages/map_editor && flutter analyze
```

```text
344 issues found!
```

Signal : échec hors lot, déjà localisé dans la dette Pokemon SDK (`pokemon_sdk_move_catalog_converter.dart`, `sync_pokemon_sdk_moves_catalog_use_case.dart`). Aucun fichier `map_editor` n'a été modifié.

## 18. Build runner

Non lancé. Aucun fichier généré n'est concerné : `cinematic_asset.dart` est manuel et ne contient pas de `part`.

## 19. Garde-fous de périmètre

```bash
git diff --name-only -- packages/map_editor packages/map_runtime packages/map_gameplay packages/map_battle examples selbrume
```

```text

```

Conclusion : aucun changement dans les packages/UI/runtime interdits.

## 20. Inventaire diff avant rapports

```text
packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart
packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart
packages/map_core/lib/src/models/cinematic_asset.dart
packages/map_core/test/cinematic_asset_test.dart
packages/map_core/test/cinematic_authoring_operations_test.dart
packages/map_core/test/cinematic_diagnostics_test.dart
packages/map_core/test/project_manifest_cinematics_test.dart
```

## 21. Inventaire diff avec rapports

```text
packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart
packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart
packages/map_core/lib/src/models/cinematic_asset.dart
packages/map_core/test/cinematic_asset_test.dart
packages/map_core/test/cinematic_authoring_operations_test.dart
packages/map_core/test/cinematic_diagnostics_test.dart
packages/map_core/test/project_manifest_cinematics_test.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/ns_scenes_v1_79_cinematic_character_library_binding_core_model_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_79_evidence_pack.md
```

## 22. Statut roadmap

`road_map_scenes.md` :

- V1-79 passe DONE.
- V1-80 devient `Cinematic Character Library Picker V0`.
- L'ancien scroll/visibility est déplacé en V1-90.
- Section `Mise a jour V1-79` ajoutée.

`road_map_scene_builder_authoring.md` :

- V1-79 passe DONE.
- V1-80 devient `Cinematic Character Library Picker V0`.
- V1-90 reçoit le backlog scroll/visibility.
- Section `Mise a jour V1-79` ajoutée.

## 23. Non-goals prouvés

- Pas de UI picker Character Library.
- Pas de preview réelle.
- Pas de runtime.
- Pas de playback.
- Pas de pathfinding.
- Pas de donnée Selbrume.
- Pas de `stageContext.mapId`.
- Pas de `characterId` dans `CinematicActorBinding`.
- Pas de `startMs/endMs` dans `CinematicActorAppearanceBinding`.
- Pas d'image IA.

## 24. Recommandation suivante

`NS-SCENES-V1-80 — Cinematic Character Library Picker V0`

But : connecter l'éditeur au modèle V1-79 avec un picker no-code pour `ProjectCharacterEntry`, limité aux acteurs `cinematicOnly`.
