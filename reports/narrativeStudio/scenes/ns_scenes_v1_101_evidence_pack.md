# NS-SCENES-V1-101 — Cinematic Stage Point Core Model V0 — Evidence Pack

## 1. Git Status Initial & Final

```text
/Users/karim/Project/pokemonProject
 M packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart
 M packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart
 M packages/map_core/lib/src/models/cinematic_asset.dart
 M packages/map_core/test/cinematic_asset_test.dart
 M packages/map_core/test/cinematic_authoring_operations_test.dart
 M packages/map_core/test/cinematic_diagnostics_test.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_101_cinematic_stage_point_core_model_v0.md
```

Le working tree a été modifié de façon isolée et chirurgicale au sein du package `map_core`. Aucun package externe ou application n'a été affecté.

## 2. Fichiers modifiés

- [cinematic_asset.dart](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/cinematic_asset.dart) : Déclaration du modèle `CinematicStagePoint` et intégration à `CinematicStageContext`.
- [cinematic_authoring_operations.dart](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart) : Opérations d'édition pures `addCinematicStagePoint`, `updateCinematicStagePoint` et `removeCinematicStagePoint`.
- [cinematic_diagnostics.dart](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart) : Validation statique du contexte avec 6 codes d'erreurs et alertes dédiées.
- [cinematic_asset_test.dart](file:///Users/karim/Project/pokemonProject/packages/map_core/test/cinematic_asset_test.dart) : Tests unitaires de validation JSON (compatibilité, ordre, double precision, description nulle).
- [cinematic_authoring_operations_test.dart](file:///Users/karim/Project/pokemonProject/packages/map_core/test/cinematic_authoring_operations_test.dart) : Tests unitaires sur les opérations d'édition pures.
- [cinematic_diagnostics_test.dart](file:///Users/karim/Project/pokemonProject/packages/map_core/test/cinematic_diagnostics_test.dart) : Tests unitaires sur la validation et les codes d'erreur statiques.

## 3. Preuve d'Exécution des Tests & Diagnostics

### Commandes exécutées dans `packages/map_core`

```bash
dart test
dart analyze
```

### Log de tests unitaires passés

```text
00:04 +2450: All tests passed!
```

### Log de l'analyse statique Dart

```text
Analyzing map_core...
No issues found!
```

## 4. Diffs partiels notables

### Modèle CinematicStagePoint et intégration JSON
```dart
@immutable
final class CinematicStagePoint {
  CinematicStagePoint({
    required String id,
    required String label,
    required this.x,
    required this.y,
    String? description,
  })  : id = _requireTrimmed(id, 'CinematicStagePoint.id'),
        label = _requireTrimmed(label, 'CinematicStagePoint.label'),
        description = _trimOptional(description);

  factory CinematicStagePoint.fromJson(Map<String, dynamic> json) {
    return CinematicStagePoint(
      id: _readRequiredString(json, 'id'),
      label: _readRequiredString(json, 'label'),
      x: _readRequiredDouble(json, 'x'),
      y: _readRequiredDouble(json, 'y'),
      description: _readOptionalString(json, 'description'),
    );
  }
  ...
}
```

### Diagnostic d'intégrité de Stage Point
```dart
      if (!point.x.isFinite ||
          point.x.isNaN ||
          !point.y.isFinite ||
          point.y.isNaN) {
        diagnostics.add(
          CinematicDiagnostic(
            code: CinematicDiagnosticCode.stagePointInvalidCoordinate,
            severity: CinematicDiagnosticSeverity.error,
            message:
                'Le Stage Point "$id" a des coordonnées non finies.',
            cinematicId: cinematic.id,
            referenceId: id,
            target: CinematicDiagnosticTarget.stageContext,
            suggestedFixLabel:
                'Corriger les coordonnées pour qu’elles soient finies.',
          ),
        );
      }
```

## 5. Arbitrage sur les ArgumentError et la robustesse

- Conformément aux instructions, le constructeur et la désérialisation JSON n'échouent pas sur des coordonnées non finies. Elles sont lues sous forme de double (grâce à `toDouble()` sur un type `num`) pour permettre au moteur de diagnostic de générer un message d'erreur clair (`stagePointInvalidCoordinate`).
- Les opérations d'édition interactives d'auteur, quant à elles, lèvent immédiatement des exceptions `ArgumentError` afin de bloquer toute saisie erronée au plus tôt.

## 6. Prochain Lot Proposé

`NS-SCENES-V1-102 — Cinematic Preview Point Placement UI V0`
- Intégration de l'UI pour poser/déplacer les points sur le Canvas de preview.
