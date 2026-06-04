# NS-SCENES-V1-74 — Cinematic Stage Context Diagnostics / Preview Readiness Polish V0

## Statut

DONE.

## Demande

Karim a demandé le lot V1-74 afin de rendre le Stage Context du Cinematic Builder plus lisible avant une future preview réelle, sans activer la preview, le playback, le runtime ou des sources map-aware non fiables.

## Décision

Le Builder affiche maintenant une section `Préparation preview` dans le panneau `Contexte de scène`.

Cette readiness est une projection editor-side et distingue :

- `Sandbox uniquement`
- `Contexte incomplet`
- `À corriger avant preview`
- `Prêt pour future preview`

La section rappelle explicitement : `La preview réelle arrivera plus tard.`

## Scope Réalisé

- Ajout d'un read model editor pur `cinematic_stage_preview_readiness.dart`.
- Checklist no-code :
  - `Map de scène`
  - `Décor`
  - `Acteurs liés`
  - `Positions initiales`
  - `Cibles de mouvement`
  - `Sources map-aware`
- Statuts de checklist : `OK`, `À compléter`, `Bloquant`, `À venir`.
- Diagnostics stage rendus en messages humains, avec le code technique seulement en référence secondaire.
- Messages temporaires explicites pour `mapEntity` / `mapEvent` :
  - `Sélection d’entités prévue dans un lot suivant.`
  - `Sélection d’events prévue dans un lot suivant.`
  - `Le Builder ne reçoit pas encore les entités/events de la map.`
- Résumé Library : champ `Preview` avec `sandbox uniquement`, `contexte incomplet`, `à corriger avant preview` ou `prêt pour future preview`.
- Capture Visual Gate V1-74 mise à jour : `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_74_cinematic_stage_context_diagnostics_preview_readiness_polish_v0.png`.
- Roadmaps mises à jour : V1-74 DONE, prochain lot recommandé V1-75.

## Non-objectifs Respectés

- Pas de preview réelle.
- Pas de playback.
- Pas de timer.
- Pas de `currentTimeMs`, `playbackTimeMs` ou `isPlaying`.
- Pas de pathfinding, collision, warp, spawn ou résolution runtime.
- Pas de données Selbrume hardcodées.
- Pas de `stageContext.mapId`.
- Pas d'IDs libres, JSON brut ou coordonnées libres.
- Pas de modification runtime/gameplay/battle/examples.

## Fichiers Modifiés

- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_stage_preview_readiness.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart`
- `packages/map_editor/test/cinematic_builder_workspace_test.dart`
- `packages/map_editor/test/cinematics_library_workspace_test.dart`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

Le fichier `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart` reste modifié par le lot précédent V1-73 dans le working tree partagé.

## Code Généré

Le code complet du nouveau fichier `cinematic_stage_preview_readiness.dart` est reproduit dans l'evidence pack V1-74, section `Code complet ajouté`.

Extrait central :

```dart
CinematicStagePreviewReadiness buildCinematicStagePreviewReadiness({
  required CinematicAsset asset,
  required CinematicsLibraryEntry entry,
  required List<ProjectMapEntry> maps,
}) {
  final stageContext = asset.stageContext;
  final effectiveContext = stageContext ?? CinematicStageContext();
  final diagnostics = _stageDiagnostics(entry)
      .map(
        (diagnostic) => CinematicStagePreviewReadinessDiagnostic(
          code: diagnostic.code,
          message: _humanStageDiagnosticMessage(diagnostic, asset),
          severity: diagnostic.severity,
        ),
      )
      .toList(growable: false);
  final items = <CinematicStagePreviewReadinessItem>[
    _mapItem(asset, maps),
    _backdropItem(asset, effectiveContext, maps),
    _actorBindingsItem(asset, effectiveContext),
    _initialPlacementsItem(asset, effectiveContext),
    _movementTargetsItem(asset, effectiveContext),
    _mapAwareSourcesItem(asset, effectiveContext),
  ];

  final hasBlocking = diagnostics.any(
        (diagnostic) =>
            diagnostic.severity == CinematicsLibraryDiagnosticSeverity.error,
      ) ||
      items.any((item) =>
          item.kind == CinematicStagePreviewReadinessItemKind.blocking);
  final hasIncomplete = items.any(
    (item) => item.kind == CinematicStagePreviewReadinessItemKind.incomplete,
  );

  if (stageContext == null) {
    return CinematicStagePreviewReadiness(
      kind: CinematicStagePreviewReadinessKind.sandboxOnly,
      statusLabel: 'Sandbox uniquement',
      libraryStatusLabel: 'sandbox uniquement',
      summary:
          'Ajoute un contexte de scène pour préparer une future preview. La preview réelle arrivera plus tard.',
      items: items,
      diagnostics: diagnostics,
    );
  }
  if (hasBlocking) {
    return CinematicStagePreviewReadiness(
      kind: CinematicStagePreviewReadinessKind.blocked,
      statusLabel: 'À corriger avant preview',
      libraryStatusLabel: 'à corriger avant preview',
      summary:
          'Corrige les éléments bloquants avant une future preview. La preview réelle arrivera plus tard.',
      items: items,
      diagnostics: diagnostics,
    );
  }
  if (hasIncomplete || diagnostics.isNotEmpty) {
    return CinematicStagePreviewReadiness(
      kind: CinematicStagePreviewReadinessKind.incomplete,
      statusLabel: 'Contexte incomplet',
      libraryStatusLabel: 'contexte incomplet',
      summary:
          'Complète les éléments de préparation avant une future preview. La preview réelle arrivera plus tard.',
      items: items,
      diagnostics: diagnostics,
    );
  }
  return CinematicStagePreviewReadiness(
    kind: CinematicStagePreviewReadinessKind.ready,
    statusLabel: 'Prêt pour future preview',
    libraryStatusLabel: 'prêt pour future preview',
    summary:
        'Le contexte est prêt pour une future preview. La preview réelle arrivera plus tard.',
    items: items,
    diagnostics: diagnostics,
  );
}
```

## Validation

### Tests ciblés éditeur

- `cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'shows cinematic stage preview readiness checklist without starting preview'`
  - Résultat : `+1: All tests passed!`
- `cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart`
  - Résultat : `+125: All tests passed!`
- `cd packages/map_editor && flutter test --reporter=compact test/cinematics_library_workspace_test.dart`
  - Résultat : `+12: All tests passed!`

### Visual Gate

- `cd packages/map_editor && flutter test --update-goldens --dart-define=NS_SCENES_V1_74_CAPTURE_CINEMATIC_STAGE_PREVIEW_READINESS=true --reporter=compact test/cinematic_builder_workspace_test.dart`
  - Résultat : `+125: All tests passed!`
  - Capture : `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_74_cinematic_stage_context_diagnostics_preview_readiness_polish_v0.png`
  - Dimensions : `1663 x 926`
  - SHA-256 : `48db68dcf42c568593a60f1f29d676c09755f26500ba3b6679f788efe3f37e51`

### map_core demandé par le lot

Commande groupée exécutée depuis `packages/map_core` :

```bash
dart test --reporter=compact test/cinematic_asset_test.dart
dart test --reporter=compact test/project_manifest_cinematics_test.dart
dart test --reporter=compact test/cinematic_authoring_operations_test.dart
dart test --reporter=compact test/cinematic_diagnostics_test.dart
dart test --reporter=compact test/cinematic_timeline_time_layout_read_model_test.dart
dart test --reporter=compact test/cinematic_timeline_lane_read_model_test.dart
dart analyze
```

Résultat : tous les tests passent et `dart analyze` affiche `No issues found!`.

### Analyse éditeur ciblée

```bash
cd packages/map_editor && flutter analyze --no-fatal-infos \
  lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart \
  lib/src/ui/canvas/cinematics/cinematic_stage_preview_readiness.dart \
  lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart \
  lib/src/ui/canvas/narrative_workspace_canvas.dart \
  test/cinematic_builder_workspace_test.dart \
  test/cinematics_library_workspace_test.dart
```

Résultat : `No issues found!`

### Analyse globale map_editor

`cd packages/map_editor && flutter analyze` reste rouge sur de la dette préexistante Pokemon SDK hors lot, notamment :

- `lib/src/application/services/pokemon_sdk_move_catalog_converter.dart`
- `lib/src/application/use_cases/sync_pokemon_sdk_moves_catalog_use_case.dart`

Le résultat global annonce `344 issues found`.

## Limites Connues

- Les entités/events de map ne sont toujours pas sélectionnables : c'est volontaire.
- La readiness peut signaler `À venir` pour les sources map-aware même si le reste est prêt.
- Les codes diagnostics restent visibles comme référence secondaire, pour garder la traçabilité technique.
- Le prochain lot doit auditer les sources fiables de map avant d'ouvrir les pickers `mapEntity` / `mapEvent`.

## Prochain Lot Recommandé

`NS-SCENES-V1-75 — Cinematic Map Entity/Event Source Audit / Picker Prep Contract`

Raison : V1-74 clarifie les gaps ; V1-75 doit maintenant établir d'où viendront les entités/events de map côté editor avant toute UI picker réelle.
