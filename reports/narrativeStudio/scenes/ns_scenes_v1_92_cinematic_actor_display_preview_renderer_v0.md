# NS-SCENES-V1-92 — Cinematic Actor Display Preview Renderer V0

Statut : `DONE`

Demande : lot fourni par Karim. Karim a demande de brancher le read model V1-91 dans le Cinematic Builder pour afficher les acteurs statiques sur le vrai decor V1-89, sans lancer la cinematique.

Phrase canonique :

```text
V1-92 fait entrer les acteurs sur scène sous forme statique.
V1-92 ne lance toujours pas la cinématique.
```

## Résumé

V1-92 branche `CinematicActorDisplayPreviewModel` dans l'editor et affiche maintenant des placeholders statiques sur la carte du Builder.

Ce qui est affiche :

- le decor reel V1-89 reste visible ;
- seuls les acteurs `isRenderable` du read model sont poses sur la map ;
- les acteurs `unbound`, sans position, hors source ou incomplets ne sont pas inventes ;
- chaque placeholder a un label court, un type visuel player/mapEntity/cinematicOnly et un hint de direction statique ;
- les diagnostics acteurs sont visibles avec wording auteur ;
- les transports restent disabled ;
- la timeline, la duree, le probe, les proportions et le resize restent preserves.

Ce qui n'est pas fait :

- aucun playback ;
- aucune interpolation `actorMove` ;
- aucun runtime, Flame, GameState ou PlayableMapGame ;
- aucun sprite final charge ou resolu ;
- aucune mutation MapData/ProjectManifest.

## Fichiers modifiés

- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_tile_renderer.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_display_preview_overlay.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_viewport_transform.dart`
- `packages/map_editor/lib/src/ui/design_system/pokemap_badge.dart`
- `packages/map_editor/test/cinematic_builder_workspace_test.dart`
- `packages/map_editor/test/cinematics_library_workspace_test.dart`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`
- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_92_cinematic_actor_display_preview_renderer_v0.png`

## Code généré

Wiring Library -> Builder :

```dart
final actorDisplayPreviewModel = _buildActorDisplayPreviewModel(
  builderAsset,
);

return CinematicBuilderWorkspace(
  entry: builderEntry,
  asset: builderAsset,
  stageMaps: widget.project.maps,
  groups: widget.project.groups,
  characters: widget.project.characters,
  stageMapSourceCatalog: _stageMapSourceCatalog,
  backdropPreviewModel: backdropPreviewModel,
  backdropTileRenderPlan: backdropTileRenderPlan,
  actorDisplayPreviewModel: actorDisplayPreviewModel,
  ...
);
```

Construction du read model editor-side :

```dart
CinematicActorDisplayPreviewModel? _buildActorDisplayPreviewModel(
  CinematicAsset asset,
) {
  if (asset.stageContext?.backdropMode !=
      CinematicStageBackdropMode.projectMap) {
    return null;
  }
  final mapId = asset.mapId?.trim();
  final stageMap = mapId == null || mapId.isEmpty
      ? null
      : _stageMapForId(widget.project.maps, mapId);
  final mapData = _stageMapSnapshotMapId == mapId ? _stageMapSnapshot : null;
  final sourceCatalog = _stageMapSourceCatalog?.stageMapId == mapId
      ? _stageMapSourceCatalog
      : null;
  return buildCinematicActorDisplayPreviewModel(
    cinematic: asset,
    project: widget.project,
    stageMap: stageMap,
    mapData: mapData,
    stageMapSourceCatalog: sourceCatalog,
  );
}
```

Overlay statique :

```dart
final actors = model.actors.where((actor) => actor.isRenderable).toList();
...
final transform = CinematicMapBackdropViewportTransform.fill(
  viewportSize: size,
  mapWidth: mapWidth,
  mapHeight: mapHeight,
);
...
_ActorDisplayPlaceholder(
  actor: actor,
  anchor: transform.tileCenterBottom(
    tileX: actor.position.x ?? 0,
    tileY: actor.position.y ?? 0,
  ),
  compact: compact,
)
```

Contrat transform partage :

```dart
Rect fittedCinematicMapBackdropRect({
  required Size availableSize,
  required Size mapPixelSize,
}) {
  if (availableSize.isEmpty ||
      mapPixelSize.width <= 0 ||
      mapPixelSize.height <= 0) {
    return Rect.zero;
  }
  final scale = math.min(
    availableSize.width / mapPixelSize.width,
    availableSize.height / mapPixelSize.height,
  );
  final width = mapPixelSize.width * scale;
  final height = mapPixelSize.height * scale;
  return Rect.fromLTWH(
    (availableSize.width - width) / 2,
    (availableSize.height - height) / 2,
    width,
    height,
  );
}
```

## Sub-agents / passes

Sub-agent A — Editor Wiring / Data Flow : confirme que la Library possede les donnees necessaires (`ProjectManifest`, `CinematicAsset`, `stageMapSnapshot`, `stageMapSourceCatalog`) et recommande de construire le read model en parent avant passage au Builder.

Sub-agent B — Viewport Transform / Overlay Alignment : recommande de factoriser le `fittedMapRect` et d'ancrer les acteurs au centre-bas de tuile avec la meme frame que le decor.

Sub-agent C — Actor Placeholder / Visual Design : recommande des placeholders honnetes et abstraits, par type player/mapEntity/cinematicOnly, sans gros labels permanents ni promesse de sprite final.

Sub-agent D — Actor Diagnostics / Fallback UX : recommande de dessiner uniquement `actor.isRenderable`, de garder unbound/missing hors carte et de traduire les diagnostics en actions auteur.

Sub-agent E — Tests / Visual Gate / Anti-scope : recommande le test RED `renders static actor placeholders over the cinematic map backdrop`, un test d'alignement et un Visual Gate V1-92.

Sub-agent F — Product Reviewer : valide le GO produit si l'utilisateur comprend que la preview est statique, pose initiale seulement, sans lecture ni runtime. Recommande ensuite le prep contract sprite resolver.

## Décisions

1. Le read model est construit dans `CinematicsLibraryWorkspace`, pas dans le painter.
2. Le Builder recoit un `CinematicActorDisplayPreviewModel?` optionnel.
3. Le panneau backdrop garde le cas `noActors` en `Décor seul / Sans acteurs`.
4. Les acteurs renderables sont superposes via un overlay `IgnorePointer`, donc ils ne capturent aucun input.
5. Les directions `actorFace` deviennent des hints statiques `N/S/E/W`.
6. Les messages diagnostics sont humains et orientes action.
7. `PokeMapBadge` tronque maintenant son label dans les surfaces contraintes pour eviter les overflows historiques.

## Screenshot

Fichier :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_92_cinematic_actor_display_preview_renderer_v0.png
```

Caractéristiques :

```text
PNG image data, 1663 x 926, 8-bit/color RGBA, non-interlaced
Taille : 287K
SHA-256 : 431d9555fcf0ea36c5929af660adcf7720fb1b76c0802c6ebe0feabcc14df8c3
```

## Tests

Voir l'evidence pack V1-92 pour les sorties completes.

Résultat principal :

- `flutter test --reporter=compact test/cinematic_builder_workspace_test.dart` : vert.
- `flutter test --reporter=compact test/cinematics_library_workspace_test.dart` : vert.
- `flutter analyze --no-fatal-infos ...` sur les fichiers touches : vert.
- tests non-regression `map_core` demandes : verts.
- `dart analyze` dans `packages/map_core` : vert.

## Limites

- Les placeholders ne sont pas des sprites finaux.
- Les apparences Character Library incompletes restent diagnostiquees.
- Les acteurs non renderables ne sont pas clamped, pas centres arbitrairement et pas affiches.
- `actorMove` reste visible dans la timeline authoring, mais n'est pas execute par la preview.

## Statut roadmap

`NS-SCENES-V1-92` peut etre marque `DONE`.

Prochain lot recommande :

```text
NS-SCENES-V1-93 — Cinematic Actor Display Preview Sprite Resolver Prep Contract
```

Raison : V1-92 montre ou commencent les acteurs. Le prochain gap utilisateur est de reconnaitre qui ils sont, sans passer au runtime ni au playback.
