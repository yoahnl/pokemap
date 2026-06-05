# NS-SCENES-V1-77 - Cinematic Stage Map Entity/Event Pickers V0

## 1. Resume executif

Demandeur : Karim, via le prompt du lot V1-77.

V1-77 branche le catalogue V1-76 au Cinematic Builder pour activer de vrais pickers no-code map-aware.

Resultat livre :

- `CinematicsLibraryWorkspace` charge une snapshot `MapData` non destructive via le niveau editor ;
- la Library construit `CinematicStageMapSourceCatalog` depuis `ProjectMapEntry + MapData` ;
- `CinematicBuilderWorkspace` recoit ce catalogue ;
- actor binding -> `mapEntity` choisit une vraie entite PNJ bindable ;
- movement target -> `mapEntity` choisit une vraie entite de map cible ;
- movement target -> `mapEvent` choisit un vrai event de map cible ;
- les pickers affichent labels no-code, type et position ;
- les ids techniques restent secondaires et ne sont pas saisis ;
- la readiness preview valide les sources reelles ;
- la timeline, les durees, le resize, le probe et les transports disabled restent preserves.

Phrase canonique respectee : V1-77 permet enfin de choisir une entite/event reel de map. V1-77 ne lance toujours pas de preview reelle.

## 2. Gate 0

Commande executee avant modification :

```bash
pwd && git branch --show-current && git status --short --untracked-files=all && git diff --stat && git diff --name-only && git log --oneline -n 15
```

Constat :

```text
/Users/karim/Project/pokemonProject
main
```

`git status`, `git diff --stat` et `git diff --name-only` etaient vides au Gate 0. Le workspace etait propre avant V1-77.

## 3. Fichiers modifies

- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_stage_preview_readiness.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`
- `packages/map_editor/test/cinematic_builder_workspace_test.dart`
- `packages/map_editor/test/cinematics_library_workspace_test.dart`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`
- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_77_cinematic_stage_map_entity_event_pickers_v0.png`

## 4. Design Gate

1. Le Builder ne charge pas `MapData` directement depuis un repository.
2. Le core ne depend pas de `EditorNotifier`.
3. La source `MapData` est fournie depuis le niveau editor responsable du projet.
4. `CinematicAsset.mapId` reste l'unique ancre Stage Map.
5. `stageContext` ne recoit pas de `mapId`.
6. Les pickers consomment uniquement `CinematicStageMapSourceCatalog`.
7. Les entites viennent de `MapData.entities`.
8. Les events viennent de `MapData.events`.
9. Aucun champ libre `mapEntityId`, `sourceId` ou `eventId` n'est expose.
10. Aucun JSON brut n'est expose.
11. Les labels no-code passent avant les ids techniques.
12. Le preview sandbox reste une zone sandbox, pas une preview runtime.
13. Aucun runtime, pathfinding, collision, warp, timer ou playback n'est branche.
14. Aucune image IA, aucun `gpt-image-2`, aucune donnee Selbrume/Mael/Lysa n'est introduite.

## 5. Implementation

### 5.1 Wiring editor -> Library -> Builder

`CinematicsLibraryWorkspace` accepte maintenant un callback optionnel de snapshot map :

```dart
typedef LoadStageMapSnapshotCallback = Future<MapData?> Function(String mapId);

final LoadStageMapSnapshotCallback? onLoadStageMapSnapshot;
```

Quand un Builder canonique est ouvert, la Library charge la map de scene et construit le catalogue :

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

`NarrativeWorkspaceCanvas` fournit la source non destructive existante :

```dart
onLoadStageMapSnapshot: widget.editorNotifier.loadMapSnapshotById,
```

### 5.2 Reception du catalogue dans le Builder

```dart
class CinematicBuilderWorkspace extends StatefulWidget {
  const CinematicBuilderWorkspace({
    required this.entry,
    required this.asset,
    required this.stageMaps,
    this.stageMapSourceCatalog,
    // callbacks...
  });

  final CinematicStageMapSourceCatalog? stageMapSourceCatalog;
}
```

Le catalogue est transmis a l'inspecteur Stage Context et a la readiness preview.

### 5.3 Actor binding -> vraie mapEntity

Le bouton `Entite de map` n'est actif que si le catalogue est disponible, aligne sur la map de l'asset et contient des entites bindables acteur :

```dart
final actorSources = _actorBindableEntitySources(asset, sourceCatalog);
final mapEntityDisabledReason =
    _mapEntityActorDisabledReason(asset, sourceCatalog, actorSources);
final canPickMapEntity = mapEntityDisabledReason == null;
```

La selection persiste uniquement l'id de la source reelle choisie :

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

### 5.4 Movement target -> vraie mapEntity / vrai mapEvent

Les cibles de mouvement exposent deux pickers map-aware, selon les capabilities du catalogue :

```dart
final entitySources = _movementTargetEntitySources(asset, sourceCatalog);
final eventSources = _movementTargetEventSources(asset, sourceCatalog);
```

Selection d'une entite :

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

Selection d'un event :

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

### 5.5 Pickers no-code

Les pickers affichent le label no-code, puis le detail type/position. Le bouton est icon-only et l'id technique n'est pas le workflow principal :

```dart
class _StageMapEntitySourcePicker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _StageSourcePickerShell(
      title: 'Sources entités',
      children: [
        for (final source in sources)
          _StageSourceOption(
            keyValue: '$keyPrefix-source-${source.id}',
            label: source.label,
            detail: '${source.kindLabel} · ${source.positionSummary}',
            icon: CupertinoIcons.location,
            selected: selectedSourceId == source.id,
            onPressed: () => onSourceSelected(source),
          ),
      ],
    );
  }
}
```

### 5.6 Readiness preview

`buildCinematicStagePreviewReadiness` accepte le catalogue et verifie les refs persistantes contre les vraies sources :

```dart
CinematicStagePreviewReadiness buildCinematicStagePreviewReadiness({
  required CinematicAsset asset,
  required CinematicsLibraryEntry entry,
  required List<ProjectMapEntry> maps,
  CinematicStageMapSourceCatalog? stageMapSourceCatalog,
})
```

Les bindings `mapEntity` et `mapEvent` absents ou invalides deviennent incomplets/bloquants, au lieu de rester un placeholder "lot suivant".

Extrait exact du controle movement target :

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

## 6. Tests TDD et regressions

RED valide :

```bash
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "binds actor to selected map entity through stage source picker"
```

Echec attendu avant implementation : le bouton source `entity_professor` n'existait pas encore dans le Builder.

GREEN cible actor :

```bash
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "binds actor to selected map entity through stage source picker"
```

Resultat : test passe.

GREEN cibles movement target :

```bash
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "binds movement target to selected map"
```

Resultat : 2 tests passent.

Suite Builder complete :

```bash
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart
```

Resultat : `+128` avant ajout de la capture V1-77, puis `+129` avec le Visual Gate V1-77.

Suite Library complete :

```bash
cd packages/map_editor && flutter test --reporter=compact test/cinematics_library_workspace_test.dart
```

Resultat : `+13`, tous les tests passent.

Core :

```bash
cd packages/map_core && dart test && dart analyze
```

Resultat : `+2361`, `All tests passed!`, puis `Analyzing map_core... No issues found!`.

Analyse cible editor :

```bash
cd packages/map_editor && dart analyze lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart lib/src/ui/canvas/cinematics/cinematic_stage_preview_readiness.dart lib/src/ui/canvas/narrative_workspace_canvas.dart test/cinematic_builder_workspace_test.dart test/cinematics_library_workspace_test.dart
```

Resultat : `No issues found!`.

Analyse globale editor :

```bash
cd packages/map_editor && flutter analyze
```

Resultat : echec connu hors lot, `344 issues`, concentrees sur la dette Pokemon SDK preexistante :

- `lib/src/application/services/pokemon_sdk_move_catalog_converter.dart`
- `lib/src/application/use_cases/sync_pokemon_sdk_moves_catalog_use_case.dart`

## 7. Visual Gate

Commande imposee par le prompt :

```bash
cd packages/map_editor && flutter test --update-goldens --dart-define=NS_SCENES_V1_77_CAPTURE_CINEMATIC_STAGE_MAP_PICKERS=true --reporter=compact test/cinematic_builder_workspace_test.dart
```

Resultat : `+129`, tous les tests passent.

Capture :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_77_cinematic_stage_map_entity_event_pickers_v0.png
```

Verification fichier :

```text
PNG image data, 1663 x 926, 8-bit/color RGBA, non-interlaced
222K
```

Inspection visuelle : Builder visible, preview sandbox non reelle, timeline preservee, picker `Sources events` ouvert avec `Gate bell`.

## 8. Anti-scope confirme

Non fait volontairement :

- aucune preview reelle ;
- aucun rendu map/actor/backdrop ;
- aucun runtime ;
- aucun playback, timer, `Ticker`, `AnimationController`, `currentTimeMs`, `playbackTimeMs`, `isPlaying` ;
- aucun pathfinding, collision, warp, spawn runtime ;
- aucune coordonnee libre x/y ;
- aucun champ TextField d'id technique ;
- aucun JSON brut ;
- aucun `stageContext.mapId` ;
- aucune donnee fake Selbrume/Mael/Lysa ;
- aucune image IA ou `gpt-image-2`.

## 9. Roadmaps

Mises a jour :

- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

Statut propose et applique : `NS-SCENES-V1-77` est DONE.

Prochain lot recommande : `NS-SCENES-V1-78 — Cinematic Stage Source Drift Diagnostics Polish V0`.
