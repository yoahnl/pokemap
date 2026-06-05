# NS-SCENES-V1-77 - Evidence Pack

## Gate 0

Commande :

```bash
pwd && git branch --show-current && git status --short --untracked-files=all && git diff --stat && git diff --name-only && git log --oneline -n 15
```

Signal observe :

```text
/Users/karim/Project/pokemonProject
main
```

`git status`, `git diff --stat` et `git diff --name-only` etaient vides avant modification.

## Prompt traite

Lot execute uniquement :

```text
NS-SCENES-V1-77 — Cinematic Stage Map Entity/Event Pickers V0
```

Objectif :

```text
Brancher CinematicStageMapSourceCatalog au Cinematic Builder pour actor binding -> mapEntity,
movement target -> mapEntity et movement target -> mapEvent, en consommant seulement
MapData.entities / MapData.events.
```

## Code genere / modifie

### Snapshot map non destructive dans la Library

Fichier : `packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart`

```dart
typedef LoadStageMapSnapshotCallback = Future<MapData?> Function(String mapId);

final LoadStageMapSnapshotCallback? onLoadStageMapSnapshot;
String? _loadingStageMapSourceCatalogMapId;
CinematicStageMapSourceCatalog? _stageMapSourceCatalog;
int _stageMapSourceCatalogGeneration = 0;
```

```dart
void _ensureStageMapSourceCatalog(CinematicAsset asset) {
  final mapId = asset.mapId?.trim();
  if (mapId == null || mapId.isEmpty) {
    if (_stageMapSourceCatalog != null ||
        _loadingStageMapSourceCatalogMapId != null) {
      scheduleMicrotask(() {
        if (!mounted) {
          return;
        }
        setState(() {
          _stageMapSourceCatalog = null;
          _loadingStageMapSourceCatalogMapId = null;
          _stageMapSourceCatalogGeneration++;
        });
      });
    }
    return;
  }
  if (_stageMapSourceCatalog?.stageMapId == mapId ||
      _loadingStageMapSourceCatalogMapId == mapId) {
    return;
  }

  final loader = widget.onLoadStageMapSnapshot;
  if (loader == null) {
    return;
  }

  final generation = ++_stageMapSourceCatalogGeneration;
  _loadingStageMapSourceCatalogMapId = mapId;
  unawaited(() async {
    final mapData = await loader(mapId);
    if (!mounted || generation != _stageMapSourceCatalogGeneration) {
      return;
    }
    final stageMap = _stageMapForId(widget.project.maps, mapId);
    setState(() {
      _stageMapSourceCatalog = buildCinematicStageMapSourceCatalog(
        stageMap: stageMap,
        mapData: mapData,
      );
      _loadingStageMapSourceCatalogMapId = null;
    });
  }());
}
```

### Passage du catalogue au Builder

Fichiers :

- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`

```dart
CinematicBuilderWorkspace(
  entry: builderEntry,
  asset: builderAsset,
  stageMaps: widget.project.maps,
  stageMapSourceCatalog: _stageMapSourceCatalog,
  // callbacks...
)
```

```dart
final CinematicStageMapSourceCatalog? stageMapSourceCatalog;
```

### Actor binding -> mapEntity

Fichier : `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`

```dart
final actorSources = _actorBindableEntitySources(asset, sourceCatalog);
final mapEntityDisabledReason =
    _mapEntityActorDisabledReason(asset, sourceCatalog, actorSources);
final canPickMapEntity = mapEntityDisabledReason == null;
```

```dart
_StageMapEntitySourcePicker(
  keyPrefix: 'cinematic-builder-actor-binding-${actor.actorId}-mapEntity',
  sources: actorSources,
  selectedSourceId: binding?.mapEntityId,
  onSourceSelected: (source) => widget.onUpsertActorBinding(
    CinematicActorBinding(
      actorId: actor.actorId,
      kind: CinematicActorBindingKind.mapEntity,
      mapEntityId: source.id,
    ),
  ),
)
```

### Movement target -> mapEntity / mapEvent

Fichier : `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`

```dart
_StageMapEntitySourcePicker(
  keyPrefix: 'cinematic-builder-target-binding-${target.targetId}-mapEntity',
  sources: entitySources,
  selectedSourceId: selectedKind == CinematicMovementTargetBindingKind.mapEntity
      ? binding?.sourceId
      : null,
  onSourceSelected: (source) => widget.onUpsertMovementTargetBinding(
    CinematicMovementTargetBinding(
      targetId: target.targetId,
      kind: CinematicMovementTargetBindingKind.mapEntity,
      sourceId: source.id,
    ),
  ),
)
```

```dart
_StageMapEventSourcePicker(
  keyPrefix: 'cinematic-builder-target-binding-${target.targetId}-mapEvent',
  sources: eventSources,
  selectedSourceId: selectedKind == CinematicMovementTargetBindingKind.mapEvent
      ? binding?.sourceId
      : null,
  onSourceSelected: (source) => widget.onUpsertMovementTargetBinding(
    CinematicMovementTargetBinding(
      targetId: target.targetId,
      kind: CinematicMovementTargetBindingKind.mapEvent,
      sourceId: source.id,
    ),
  ),
)
```

### Source filters et messages honnetes

Fichier : `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`

```dart
List<CinematicStageMapEntitySource> _actorBindableEntitySources(
  CinematicAsset asset,
  CinematicStageMapSourceCatalog? catalog,
) {
  if (!_stageSourceCatalogMatchesAsset(asset, catalog) ||
      catalog?.status != CinematicStageMapSourceCatalogStatus.available) {
    return const <CinematicStageMapEntitySource>[];
  }
  return catalog!.entities
      .where((source) => source.canBindActor)
      .toList(growable: false);
}
```

```dart
String? _sourceCatalogDisabledReason(
  CinematicAsset asset,
  CinematicStageMapSourceCatalog? catalog,
) {
  if (asset.mapId == null) {
    return 'Choisis d’abord une map de scène.';
  }
  if (catalog == null) {
    return 'Catalogue des entités/events de la map en cours de chargement.';
  }
  if (catalog.stageMapId != asset.mapId) {
    return 'Catalogue de sources aligné sur une autre map.';
  }
  return switch (catalog.status) {
    CinematicStageMapSourceCatalogStatus.available => null,
    CinematicStageMapSourceCatalogStatus.missingStageMap =>
      'Choisis d’abord une map de scène.',
    CinematicStageMapSourceCatalogStatus.mapDataUnavailable =>
      'MapData de la map de scène indisponible.',
    CinematicStageMapSourceCatalogStatus.mapIdMismatch =>
      'La MapData chargée ne correspond pas à la map de scène.',
  };
}
```

### Readiness reliee au catalogue

Fichier : `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_stage_preview_readiness.dart`

```dart
CinematicStagePreviewReadiness buildCinematicStagePreviewReadiness({
  required CinematicAsset asset,
  required CinematicsLibraryEntry entry,
  required List<ProjectMapEntry> maps,
  CinematicStageMapSourceCatalog? stageMapSourceCatalog,
})
```

```dart
final hasSource = switch (binding.kind) {
  CinematicMovementTargetBindingKind.abstractPoint => true,
  CinematicMovementTargetBindingKind.mapEntity =>
    _hasMapEntitySource(stageMapSourceCatalog, binding.sourceId),
  CinematicMovementTargetBindingKind.mapEvent =>
    _hasMapEventSource(stageMapSourceCatalog, binding.sourceId),
};
if (!hasSource) {
  return _item(
    'Cibles de mouvement',
    CinematicStagePreviewReadinessItemKind.blocking,
    '${target.label} pointe vers une source map absente',
  );
}
```

### Tests ajoutes

Fichier : `packages/map_editor/test/cinematic_builder_workspace_test.dart`

```dart
testWidgets('binds actor to selected map entity through stage source picker',
    (tester) async { ... });

testWidgets('binds movement target to selected map entity source',
    (tester) async { ... });

testWidgets('binds movement target to selected map event source',
    (tester) async { ... });
```

Fichier : `packages/map_editor/test/cinematics_library_workspace_test.dart`

```dart
testWidgets('loads stage map source catalog when opening builder',
    (tester) async { ... });
```

## RED

Commande :

```bash
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "binds actor to selected map entity through stage source picker"
```

Signal :

```text
Echec attendu : le picker source n'existait pas encore.
Source attendue absente : cinematic-builder-actor-binding-actor_professor-mapEntity-source-entity_professor.
```

Interpretation : RED valide, le test exigeait bien un vrai bouton de source map et non un id libre.

## GREEN ciblé

Actor binding :

```bash
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "binds actor to selected map entity through stage source picker"
```

Resultat :

```text
All tests passed.
```

Movement target entity/event :

```bash
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "binds movement target to selected map"
```

Resultat :

```text
2 tests passed.
```

Library async catalog :

```bash
cd packages/map_editor && flutter test --reporter=compact test/cinematics_library_workspace_test.dart --name "loads stage map source catalog when opening builder"
```

Resultat :

```text
All tests passed.
```

## Suites completes

Builder :

```bash
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart
```

Resultat :

```text
+128 avant capture V1-77.
```

Library :

```bash
cd packages/map_editor && flutter test --reporter=compact test/cinematics_library_workspace_test.dart
```

Resultat :

```text
+13, tous les tests passent.
```

Core :

```bash
cd packages/map_core && dart test && dart analyze
```

Resultat :

```text
+2361
All tests passed!
Analyzing map_core...
No issues found!
```

## Visual Gate

Commande imposee :

```bash
cd packages/map_editor && flutter test --update-goldens --dart-define=NS_SCENES_V1_77_CAPTURE_CINEMATIC_STAGE_MAP_PICKERS=true --reporter=compact test/cinematic_builder_workspace_test.dart
```

Resultat :

```text
+129
All tests passed.
```

Capture produite :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_77_cinematic_stage_map_entity_event_pickers_v0.png
```

Verification fichier :

```bash
ls -lh reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_77_cinematic_stage_map_entity_event_pickers_v0.png
file reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_77_cinematic_stage_map_entity_event_pickers_v0.png
```

Sortie :

```text
-rw-r--r--  1 karim  staff   222K Jun  5 02:01 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_77_cinematic_stage_map_entity_event_pickers_v0.png
PNG image data, 1663 x 926, 8-bit/color RGBA, non-interlaced
```

Inspection visuelle :

- Builder non blank ;
- preview sandbox visible et non reelle ;
- timeline visible et preservee ;
- picker `Sources events` ouvert ;
- source reelle `Gate bell` visible ;
- pas d'image IA.

## Analyze editor

Analyse cible des fichiers touches :

```bash
cd packages/map_editor && dart analyze lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart lib/src/ui/canvas/cinematics/cinematic_stage_preview_readiness.dart lib/src/ui/canvas/narrative_workspace_canvas.dart test/cinematic_builder_workspace_test.dart test/cinematics_library_workspace_test.dart
```

Resultat :

```text
No issues found!
```

Analyse globale :

```bash
cd packages/map_editor && flutter analyze
```

Resultat :

```text
344 issues.
```

Cette analyse globale reste rouge sur dette preexistante hors lot Pokemon SDK :

- `lib/src/application/services/pokemon_sdk_move_catalog_converter.dart`
- `lib/src/application/use_cases/sync_pokemon_sdk_moves_catalog_use_case.dart`

## Incident non bloquant

Un lancement parallele de deux commandes Flutter dans le meme package a produit une erreur temporaire de native assets :

```text
Failed to change install names ... objective_c.dylib ... No such file or directory
```

Les commandes ont ete relancees sequentiellement ensuite. Les suites Builder et Library sont passees.

## Anti-scope

Recherche et verification de comportement :

- pas de preview reelle activee ;
- pas de runtime touche ;
- pas de playback/timer/Ticker/AnimationController/currentTimeMs/playbackTimeMs/isPlaying ;
- pas de pathfinding/collision/warp/spawn runtime ;
- pas de `stageContext.mapId` ajoute ;
- pas de TextField d'id `mapEntityId`, `sourceId` ou `eventId` ;
- pas de JSON brut expose ;
- pas de coordonnee libre x/y ;
- pas de fake entity/event ;
- pas de donnees Selbrume/Mael/Lysa ;
- pas d'image IA ou `gpt-image-2`.

## Roadmaps

Roadmaps mises a jour :

- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

Statut :

```text
NS-SCENES-V1-77 — DONE
```

Suite recommandee :

```text
NS-SCENES-V1-78 — Cinematic Stage Source Drift Diagnostics Polish V0
```
