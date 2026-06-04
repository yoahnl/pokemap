# NS-SCENES-V1-73 — Cinematic Stage / Map Context Editor V0

Date : 2026-06-04

Demande : lot fourni par Karim. Karim a aussi explicitement demande que le code genere soit inclus dans le rapport ; la section **Code genere** ci-dessous documente les principaux blocs produits avec chemins et lignes.

Statut : DONE

## Resume

V1-73 expose le Stage Context V1-72 dans le Cinematic Builder et la Cinematics Library sans demarrer de preview reelle ni runtime :

- map de scene choisie via `ProjectManifest.maps` ;
- clear map ;
- `backdropMode` editable entre `none` et `projectMap` ;
- actor bindings `player/mapEntity/cinematicOnly/unbound` ;
- initial placements `unset/fromMapEntity/fromMovementTarget` ;
- movement target bindings `abstractPoint/mapEntity/mapEvent` ;
- diagnostics stage visibles dans le Builder ;
- summary Library avec nom de map lisible et compteur diagnostics stage ;
- timeline, `timeline.steps`, durees, resize et transports preserves.

Adaptation necessaire : le prompt limitait les fichiers attendus aux workspaces Builder/Library et tests. Pour brancher l'UI en production depuis le Narrative Workspace, j'ai aussi modifie `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`. Sans ce wiring, le Builder aurait compile en test mais l'app n'aurait pas applique les operations V1-72 en memoire.

## Fichiers modifies

- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`
- `packages/map_editor/test/cinematic_builder_workspace_test.dart`
- `packages/map_editor/test/cinematics_library_workspace_test.dart`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

## Fichiers crees

- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_73_cinematic_stage_map_context_editor_v0.png`
- `reports/narrativeStudio/scenes/ns_scenes_v1_73_cinematic_stage_map_context_editor_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_73_evidence_pack.md`

## Decisions

- `CinematicAsset.mapId` reste l'unique ancre Stage Map.
- Aucun `stageContext.mapId` n'a ete ajoute.
- Le Builder peut lire `ProjectManifest.maps`, donc le picker de map est actif.
- Le Builder ne dispose pas encore d'une source fiable `MapData.entities/events`. Les choix `mapEntity` et `mapEvent` restent visibles mais desactives avec messages honnetes :
  - `Choisis d’abord une map de scène.`
  - `Les entités de cette map seront sélectionnables dans un lot suivant.`
  - `Les events de cette map seront sélectionnables dans un lot suivant.`
- Pas de preview reelle, pas de playback, pas de runtime cinematic map-aware.

## Code genere

### Contrat Builder

`packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:94`

```dart
typedef UpdateCinematicStageMapCallback = Future<bool> Function({
  required String cinematicId,
  String? mapId,
});

typedef UpdateCinematicStageContextCallback = Future<bool> Function({
  required String cinematicId,
  required CinematicStageContext stageContext,
});

typedef UpsertCinematicActorBindingCallback = Future<bool> Function({
  required String cinematicId,
  required CinematicActorBinding binding,
});
```

### Panneau Stage Context

`packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:3703`

```dart
class _StageContextEditor extends StatelessWidget {
  const _StageContextEditor({
    required this.entry,
    required this.asset,
    required this.stageMaps,
    required this.onUpdateStageMap,
    required this.onUpdateStageContext,
    required this.onUpsertActorBinding,
    required this.onUpsertActorInitialPlacement,
    required this.onUpsertMovementTargetBinding,
  });

  @override
  Widget build(BuildContext context) {
    final stageContext = asset.stageContext ?? CinematicStageContext();
    return PokeMapCard(
      key: const ValueKey('cinematic-builder-stage-context-editor'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionTitle(
            title: 'Contexte de scène',
            subtitle: 'Prépare la future preview, sans la lancer.',
          ),
          _StageMapSection(
            asset: asset,
            stageMaps: stageMaps,
            onUpdateStageMap: onUpdateStageMap,
          ),
          _StageBackdropSection(
            asset: asset,
            stageContext: stageContext,
            onUpdateStageContext: onUpdateStageContext,
          ),
          _StageActorBindingsSection(
            asset: asset,
            stageContext: stageContext,
            onUpsertActorBinding: onUpsertActorBinding,
          ),
          _StageInitialPlacementsSection(
            asset: asset,
            stageContext: stageContext,
            onUpsertActorInitialPlacement: onUpsertActorInitialPlacement,
          ),
          _StageMovementTargetBindingsSection(
            asset: asset,
            stageContext: stageContext,
            onUpsertMovementTargetBinding: onUpsertMovementTargetBinding,
          ),
          _StageDiagnosticsSection(entry: entry),
          const _MutedText('Preview réelle à venir.'),
          const _MutedText('Lecture read-only dans ce lot.'),
        ],
      ),
    );
  }
}
```

### Picker map no-code

`packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:3791`

```dart
final selectedMap = _stageMapForId(stageMaps, asset.mapId);
return Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    _KeyValue(
      label: 'Map de scène',
      value: selectedMap == null ? 'Aucune map' : selectedMap.name,
    ),
    Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        _InlineControlAction(
          label: 'Effacer la map',
          button: PokeMapButton(
            key: const ValueKey('cinematic-builder-clear-stage-map'),
            onPressed: asset.mapId == null ? null : () => onUpdateStageMap(null),
            variant: PokeMapButtonVariant.secondary,
            size: PokeMapButtonSize.small,
            leading: const Icon(CupertinoIcons.xmark_circle),
            child: const SizedBox.shrink(),
          ),
        ),
        for (final map in stageMaps)
          _InlineControlAction(
            label: map.name,
            button: PokeMapButton(
              key: ValueKey('cinematic-builder-stage-map-${map.id}'),
              onPressed: () => onUpdateStageMap(map.id),
              variant: PokeMapButtonVariant.secondary,
              size: PokeMapButtonSize.small,
              isSelected: asset.mapId == map.id,
              leading: const Icon(CupertinoIcons.map),
              child: const SizedBox.shrink(),
            ),
          ),
      ],
    ),
  ],
);
```

### Choix map-aware desactives avec message honnete

`packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:3955`

```dart
final mapEntityDisabledReason = asset.mapId == null
    ? 'Choisis d’abord une map de scène.'
    : 'Les entités de cette map seront sélectionnables dans un lot suivant.';
```

`packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:4242`

```dart
final entityReason = asset.mapId == null
    ? 'Choisis d’abord une map de scène.'
    : 'Les entités de cette map seront sélectionnables dans un lot suivant.';
final eventReason = asset.mapId == null
    ? 'Choisis d’abord une map de scène.'
    : 'Les events de cette map seront sélectionnables dans un lot suivant.';
```

### Persistance en memoire depuis le Narrative Workspace

`packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart:1566`

```dart
Future<bool> _updateCinematicStageMap({
  required String cinematicId,
  String? mapId,
}) async {
  final project = widget.project;
  if (project == null) {
    return false;
  }
  try {
    final result = updateCinematicStageMap(
      project,
      cinematicId: cinematicId,
      mapId: mapId,
    );
    widget.editorNotifier.applyInMemoryProjectManifest(
      result.updatedProject,
      statusMessage: 'Cinematic stage map updated',
    );
    return true;
  } on ArgumentError {
    return false;
  }
}
```

`packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart:1614`

```dart
Future<bool> _upsertCinematicActorBinding({
  required String cinematicId,
  required CinematicActorBinding binding,
}) async {
  final project = widget.project;
  if (project == null) {
    return false;
  }
  try {
    final result = upsertCinematicActorBinding(
      project,
      cinematicId: cinematicId,
      binding: binding,
    );
    widget.editorNotifier.applyInMemoryProjectManifest(
      result.updatedProject,
      statusMessage: 'Cinematic actor binding updated',
    );
    return true;
  } on ArgumentError {
    return false;
  }
}
```

### Resume Library

`packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart:959`

```dart
class _MetadataSummary extends StatelessWidget {
  const _MetadataSummary({
    required this.entry,
    required this.maps,
  });

  final CinematicsLibraryEntry entry;
  final List<ProjectMapEntry> maps;

  @override
  Widget build(BuildContext context) {
    final stageDiagnostics = _stageDiagnosticsFor(entry);
    return PokeMapCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionTitle(
            title: 'Métadonnées',
            subtitle: 'Lecture auteur',
          ),
          _KeyValue(label: 'Statut', value: entry.statusLabel),
          _KeyValue(label: 'Map stage', value: _stageMapLabel(entry, maps)),
          if (stageDiagnostics.isNotEmpty)
            PokeMapBadge(
              label: stageDiagnostics.length == 1
                  ? '1 diagnostic stage'
                  : '${stageDiagnostics.length} diagnostics stage',
              variant: PokeMapBadgeVariant.warning,
            ),
        ],
      ),
    );
  }
}
```

### Tests Builder et Visual Gate

`packages/map_editor/test/cinematic_builder_workspace_test.dart:78`

```dart
testWidgets('edits cinematic stage map and backdrop from builder',
    (tester) async {
  _setLargeSurface(tester);
  final project = _project(cinematics: [_stageContextCinematic(mapId: null)]);
  var latestProject = project;
  final beforeAsset = _asset(project, 'cinematic_stage_context');
  final beforeSteps = beforeAsset.timeline.toJson();
  final beforeDuration =
      _entry(project, 'cinematic_stage_context').timeline.estimatedDurationMs;

  await _pumpBuilderHarness(
    tester,
    project,
    'cinematic_stage_context',
    onProjectChanged: (project) => latestProject = project,
  );

  final mapButton =
      find.byKey(const ValueKey('cinematic-builder-stage-map-map_lab'));
  await tester.ensureVisible(mapButton);
  await tester.tap(mapButton);
  await tester.pumpAndSettle();
  final backdropButton = find.byKey(
    const ValueKey('cinematic-builder-backdrop-projectMap'),
  );
  await tester.ensureVisible(backdropButton);
  await tester.tap(backdropButton);
  await tester.pumpAndSettle();

  final updated = _asset(latestProject, 'cinematic_stage_context');
  expect(updated.mapId, 'map_lab');
  expect(updated.stageContext?.backdropMode,
      CinematicStageBackdropMode.projectMap);
  expect(updated.stageContext?.toJson(), isNot(contains('mapId')));
  expect(updated.timeline.toJson(), beforeSteps);
  expect(
    _entry(latestProject, 'cinematic_stage_context')
        .timeline
        .estimatedDurationMs,
    beforeDuration,
  );
});
```

`packages/map_editor/test/cinematic_builder_workspace_test.dart:5949`

```dart
testWidgets(
    'captures V1-73 cinematic stage map context editor when requested',
    (tester) async {
  if (!const bool.fromEnvironment(
    'NS_SCENES_V1_73_CAPTURE_CINEMATIC_STAGE_CONTEXT_EDITOR',
  )) {
    return;
  }

  _setLargeSurface(tester, _referenceTimelineSurfaceSize);
  await _loadScreenshotFonts();
  final project = _project(
    cinematics: [
      _stageContextCinematic(
        stageContext: CinematicStageContext(
          backdropMode: CinematicStageBackdropMode.projectMap,
          actorBindings: [
            CinematicActorBinding(
              actorId: 'actor_professor',
              kind: CinematicActorBindingKind.player,
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
              kind: CinematicMovementTargetBindingKind.abstractPoint,
            ),
          ],
        ),
      ),
    ],
  );

  await _pumpBuilderHarness(
    tester,
    project,
    'cinematic_stage_context',
    surfaceSize: _referenceTimelineSurfaceSize,
  );

  final screenshotFile = File(
    '../../reports/narrativeStudio/scenes/screenshots/'
    'ns_scenes_v1_73_cinematic_stage_map_context_editor_v0.png',
  );
  screenshotFile.parent.createSync(recursive: true);
  await expectLater(
    find.byKey(const ValueKey('cinematic-builder-workspace')),
    matchesGoldenFile(screenshotFile.absolute.path),
  );
});
```

## Tests RED / GREEN

RED significatif :

```text
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'edits cinematic stage map and backdrop from builder'
Exit 1
Expected: exactly one matching candidate
Actual: Found 0 widgets with text "Contexte de scène"
```

GREEN cible :

```text
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'edits cinematic stage map and backdrop from builder'
+1: All tests passed!
```

Suite stage cible :

```text
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name 'stage|actor binding|initial placement|movement target binding|raw JSON|free ID|duration editor still works|resize handle still works|transport controls|preview playback|durationMs|timeline steps'
+21: All tests passed!
```

## Visual Gate

Commande :

```bash
cd packages/map_editor && flutter test --update-goldens --dart-define=NS_SCENES_V1_73_CAPTURE_CINEMATIC_STAGE_CONTEXT_EDITOR=true --reporter=compact test/cinematic_builder_workspace_test.dart
```

Resultat :

```text
+119: All tests passed!
```

Fichier :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_73_cinematic_stage_map_context_editor_v0.png
PNG image data, 1663 x 926, 8-bit/color RGBA, non-interlaced
SHA-256 79621972c1c50ef26ac1f5603b1587a6a2752087bd802d43173488154a3454ed
```

## Validations

`map_core` :

```text
cd packages/map_core && dart test --reporter=compact test/cinematic_asset_test.dart
+8: All tests passed!

cd packages/map_core && dart test --reporter=compact test/project_manifest_cinematics_test.dart
+6: All tests passed!

cd packages/map_core && dart test --reporter=compact test/cinematic_authoring_operations_test.dart
+37: All tests passed!

cd packages/map_core && dart test --reporter=compact test/cinematic_diagnostics_test.dart
+24: All tests passed!

cd packages/map_core && dart test --reporter=compact test/cinematic_timeline_time_layout_read_model_test.dart
+4: All tests passed!

cd packages/map_core && dart test --reporter=compact test/cinematic_timeline_lane_read_model_test.dart
+2: All tests passed!

cd packages/map_core && dart analyze
No issues found!
```

`map_editor` :

```text
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart
+119: All tests passed!

cd packages/map_editor && flutter test --reporter=compact test/cinematics_library_workspace_test.dart
+11: All tests passed!

cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart lib/src/ui/canvas/narrative_workspace_canvas.dart test/cinematic_builder_workspace_test.dart test/cinematics_library_workspace_test.dart
No issues found! (ran in 2.2s)
```

Analyse globale :

```text
cd packages/map_editor && flutter analyze
Exit 1
344 issues found. (ran in 3.3s)
```

Les erreurs globales sont hors lot et pointent notamment `lib/src/application/services/pokemon_sdk_move_catalog_converter.dart` et `lib/src/application/use_cases/sync_pokemon_sdk_moves_catalog_use_case.dart`, qui ne sont pas modifies par V1-73.

## Anti-scope

- `git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle examples` : sortie vide.
- Aucun symbole runtime/playback/preview reelle dans les fichiers modifies.
- Aucun pathfinding/collision/warp/spawn runtime dans les fichiers modifies.
- Aucun `stageContext.mapId`.
- Aucun workflow principal avec raw JSON ou ID libre.
- Aucun `Color(0x...)` ni `Colors.*` dans les fichiers UI modifies.
- Aucune donnee Selbrume codee.
- Aucune generation d'image IA ni reference `gpt-image-2` dans les fichiers modifies.

## Auto-review obligatoire

1. Est-ce que V1-73 a modifie map_runtime ? Non.
2. Est-ce que V1-73 a modifie map_gameplay/map_battle/examples ? Non.
3. Est-ce que V1-73 a modifie PlayableMapGame ? Non.
4. Est-ce que V1-73 a modifie SceneCinematicRuntimeAwaitableAdapter ? Non.
5. Est-ce que V1-73 a ajoute une preview reelle ? Non.
6. Est-ce que V1-73 a ajoute du playback ? Non.
7. Est-ce que V1-73 a ajoute currentTimeMs/playbackTimeMs/isPlaying ? Non.
8. Est-ce que V1-73 a ajoute pathfinding/collision/warp/spawn runtime ? Non.
9. Est-ce que V1-73 a ajoute des donnees Selbrume ? Non.
10. Est-ce que V1-73 a ajoute stageContext.mapId ? Non.
11. Est-ce que CinematicAsset.mapId reste l'ancre stage map unique ? Oui.
12. Est-ce que la map est choisie via picker ? Oui, depuis `ProjectManifest.maps`.
13. Est-ce que backdropMode est editable ? Oui.
14. Est-ce que actor bindings sont editables ? Oui.
15. Est-ce que duplicate player est evite ou diagnostique ? Oui : l'UI bloque le doublon player et le core conserve le diagnostic.
16. Est-ce que initial placements sont editables ? Oui.
17. Est-ce que movement target bindings sont editables ? Oui, avec `abstractPoint` actif et options map-aware desactivees jusqu'a source map fiable.
18. Est-ce qu'aucun ID libre n'est expose en workflow principal ? Oui.
19. Est-ce qu'aucun JSON brut n'est expose ? Oui.
20. Est-ce que les diagnostics stage sont visibles ? Oui.
21. Est-ce que timeline.steps est preserve ? Oui.
22. Est-ce que durationMs est preserve ? Oui.
23. Est-ce que duration editor et resize fonctionnent encore ? Oui.
24. Est-ce que les transports restent disabled ? Oui.
25. Est-ce que la Visual Gate prouve l'UI stage context ? Oui, PNG 1663x926 genere et suite Builder `+119`.
26. Est-ce que l'Evidence Pack est complet sans placeholders ? Oui, voir `ns_scenes_v1_73_evidence_pack.md`.
27. Quel est le prochain lot exact recommande ? `NS-SCENES-V1-74 — Cinematic Stage Context Diagnostics / Preview Readiness Polish V0`.

## Limites connues

- Les entites/events d'une map ne sont pas encore selectionnables, car le Builder ne recoit pas `MapData.entities/events`.
- Les options `mapEntity/mapEvent` sont donc volontairement desactivees avec message de lot suivant.
- La preview reste sandbox/non reelle.
- Le screenshot prouve la surface editor et les proportions 1663x926 ; il ne pretend pas valider une preview runtime.

## Prochain lot recommande

`NS-SCENES-V1-74 — Cinematic Stage Context Diagnostics / Preview Readiness Polish V0`

Objectif : rendre encore plus lisible la readiness de future preview, les diagnostics stage et les raisons exactes qui bloquent les bindings map-aware, sans coder la preview reelle.
