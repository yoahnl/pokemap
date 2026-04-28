# Lot 87 — Surface Atlas Tile Preview / Static Real Tile Rendering V0

## Résumé exécutif

Le Lot 87 remplace la preview Surface purement debug du Lot 86 par une preview statique réelle quand la chaîne de résolution est complète.

Pipeline livré côté éditeur :

```text
SurfaceLayer placement
→ surfacePresetId
→ ProjectSurfacePreset
→ SurfaceVariantRole résolu par resolveSurfaceVariantRoleForPlacement(...)
→ animationId
→ ProjectSurfaceAnimation
→ première SurfaceAnimationFrame
→ SurfaceAtlasTileRef
→ ProjectSurfaceAtlas
→ tilesetId + image chargée par le cache existant du canvas
→ drawImageRect(...)
```

La preview reste strictement statique : seule la première frame est utilisée, aucune horloge ni animation éditeur/runtime n'est ajoutée.

## Périmètre

Inclus :

- Resolver éditeur `SurfaceTilePreviewInstruction`.
- Résolution `surfacePresetId -> preset -> animation -> first frame -> atlas -> sourceRect`.
- Collecte des tilesets Surface réellement placés pour alimenter le cache image existant du canvas.
- Rendu `drawImageRect` dans `MapGridPainter` quand l'image est disponible.
- Fallback debug du Lot 86 conservé pour tout maillon manquant.

Exclus :

- Animation éditeur.
- Runtime Flame.
- Collecte runtime des tilesets Surface.
- Renderer runtime Surface.
- Migration legacy.
- Diagnostics core Surface.
- Refonte Surface Studio.
- Changement JSON ou modèle persistant.

## Gate 0 — Status initial avant modification

Commande :

```bash
pwd
```

Sortie :

```text
/Users/karim/Project/pokemonProject
```

Commande :

```bash
git branch --show-current
```

Sortie :

```text
main
```

Commande :

```bash
git status --short --untracked-files=all
```

Sortie :

```text

```

Commande :

```bash
git diff --stat
```

Sortie :

```text

```

Commande :

```bash
git log --oneline -n 10
```

Sortie :

```text
5814f6e9 feat(map): add surface role resolver preview
f8859a06 feat(map_editor): improve surface painter and studio workflow ux
b20287da feat(map_editor): redesign surface studio workflow
f3a37532 feat(map_editor): add surface painter entry flow
d2a3ca2e feat(map): add surface layer model and placement ops
6cc7fafa docs: update agent workflow guidance
9645a04b docs(surface): decide surface placement model
19c75e77 feat(map_editor): ajouter preset vertical atlas et golden slice e2e
ccdf1094 fix(map_editor): lisibilité et ergonomie sélecteur colonne aperçu atlas
33d776aa feat(map_editor): Lot 78 — animations Surface depuis atlas vertical
```

AGENTS vérifiés :

```text
AGENTS.md
```

## Audit rendu image / tilesets editor

Fichiers audités :

- `packages/map_editor/lib/src/ui/canvas/map_canvas.dart`
- `packages/map_editor/lib/src/ui/canvas/map_canvas/map_canvas_assets.dart`
- `packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart`
- `packages/map_editor/test/map_grid_painter_test.dart`
- `packages/map_editor/lib/src/ui/canvas/entity_editor_element_visual.dart`
- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/models/surface.dart`
- `packages/map_core/lib/src/models/surface_catalog.dart`

Constats :

- `MapCanvas` construit déjà `tilesetImagesById` via `_TilesetImageCache.loadMany(...)`.
- Le cache est alimenté par `_collectLayerTilesetPaths(...)`.
- `MapGridPainter` reçoit déjà `tilesetImagesById`.
- Les tiles classiques et les autotiles existants utilisent déjà `canvas.drawImageRect(...)`.
- Le bon point de branchement Surface est la boucle `SurfaceLayer` déjà ajoutée au Lot 86, située après tile/terrain/path de base et avant collision/grid/selection overlays.

## Audit Surface preview Lot 86

Fichiers audités :

- `packages/map_editor/lib/src/features/surface_painter/surface_layer_static_preview.dart`
- `packages/map_editor/test/surface_painter/surface_layer_static_preview_test.dart`
- `packages/map_core/lib/src/operations/surface_variant_role_resolver.dart`
- `packages/map_core/test/surface_variant_role_resolver_test.dart`

Constats :

- Le Lot 86 calcule déjà un `SurfaceVariantRole` avec `resolveSurfaceVariantRoleForPlacement(...)`.
- Le Lot 86 dessine un overlay debug stable par `surfacePresetId`.
- L'overlay debug est conservé comme fallback au lieu d'être supprimé.

## Décision pipeline de résolution

La résolution éditeur est portée par :

```text
packages/map_editor/lib/src/features/surface_painter/surface_tile_preview_resolver.dart
```

Décision :

- Retourner une instruction pure `SurfaceTilePreviewInstruction`.
- Ne pas charger d'image dans le resolver.
- Ne pas dépendre du runtime.
- Ne pas modifier `map_core`.
- Retourner `null` si la vraie tuile ne peut pas être résolue, afin de déclencher le fallback debug.

Stratégie animation :

```text
1. tenter animationIdForRole(resolvedRole)
2. sinon tenter animationIdForRole(SurfaceVariantRole.isolated)
3. sinon prendre la première ref du preset
4. sinon fallback debug
```

Calcul `sourceRect` :

```text
sourceX = tileRef.column * atlas.geometry.tileSize.width
sourceY = tileRef.row * atlas.geometry.tileSize.height
sourceWidth = atlas.geometry.tileSize.width
sourceHeight = atlas.geometry.tileSize.height
```

## Décision fallback

Le fallback debug du Lot 86 reste obligatoire.

Il est utilisé si :

- `ProjectManifest` absent.
- Preset absent.
- Animation absente.
- Timeline/frame absente.
- Atlas absent.
- Frame hors atlas.
- Tileset id absent.
- Image tileset non chargée.
- `sourceRect` hors image.

Effet produit : une Surface peinte reste visible au minimum comme overlay debug même quand le catalogue ou les assets sont incomplets.

## Implémentation resolver editor

Ajout :

```text
packages/map_editor/lib/src/features/surface_painter/surface_tile_preview_resolver.dart
```

Contenu fonctionnel :

- `SurfaceTilePreviewInstruction`
- `resolveSurfaceTilePreviewInstruction(...)`
- `collectSurfaceTilePreviewTilesetIds(...)`

Le helper `collectSurfaceTilePreviewTilesetIds(...)` charge seulement les tilesets nécessaires aux presets Surface réellement placés dans la map, pas tout le `surfaceCatalog`.

## Implémentation painter editor

Modifications :

- `paintSurfaceLayerAtlasTilePreview(...)` ajouté dans `surface_layer_static_preview.dart`.
- `MapGridPainter` appelle maintenant `paintSurfaceLayerAtlasTilePreview(...)`.
- `MapCanvas._collectLayerTilesetPaths(...)` ajoute les tilesets Surface placés au cache image existant.

Rendu :

- `drawImageRect(...)` quand image + catalogue + sourceRect sont résolus.
- `FilterQuality.none` pour une preview tile nette.
- `layer.opacity` appliquée au paint de la tile.
- fallback debug si la vraie tile ne peut pas être dessinée.

## Fichiers créés

- `packages/map_editor/lib/src/features/surface_painter/surface_tile_preview_resolver.dart`
- `packages/map_editor/test/surface_painter/surface_tile_preview_resolver_test.dart`
- `reports/surface/surface_engine_lot_87_surface_atlas_tile_preview_static_rendering.md`

## Fichiers modifiés

- `packages/map_editor/lib/src/features/surface_painter/surface_layer_static_preview.dart`
- `packages/map_editor/lib/src/ui/canvas/map_canvas.dart`
- `packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart`
- `packages/map_editor/test/map_grid_painter_test.dart`
- `packages/map_editor/test/surface_painter/surface_layer_static_preview_test.dart`

## Fichiers supprimés

Aucun.

## Tests lancés

### RED tests vérifiés

Commande :

```bash
cd packages/map_editor && flutter test test/surface_painter/surface_tile_preview_resolver_test.dart
```

RED attendu :

```text
Error when reading 'lib/src/features/surface_painter/surface_tile_preview_resolver.dart': No such file or directory
Method not found: 'resolveSurfaceTilePreviewInstruction'
```

Commande :

```bash
cd packages/map_editor && flutter test test/surface_painter/surface_layer_static_preview_test.dart
```

RED attendu :

```text
Method not found: 'paintSurfaceLayerAtlasTilePreview'
```

Commande :

```bash
cd packages/map_editor && flutter test test/map_grid_painter_test.dart
```

RED attendu :

```text
Expected: a value greater than <220>
  Actual: <74>
```

### Tests ciblés après implémentation

Commande :

```bash
cd packages/map_editor && flutter test test/surface_painter/surface_tile_preview_resolver_test.dart
```

Sortie finale :

```text
00:01 +7: All tests passed!
```

Commande :

```bash
cd packages/map_editor && flutter test test/surface_painter/surface_layer_static_preview_test.dart
```

Sortie finale :

```text
00:01 +7: All tests passed!
```

Commande :

```bash
cd packages/map_editor && flutter test test/map_grid_painter_test.dart
```

Sortie finale :

```text
00:01 +5: All tests passed!
```

### Non-régression map_core ciblée

Commande :

```bash
cd packages/map_core && dart test test/surface_variant_role_resolver_test.dart
```

Sortie finale :

```text
00:00 +7: All tests passed!
```

Commande :

```bash
cd packages/map_core && dart test test/surface_layer_placements_test.dart
```

Sortie finale :

```text
00:00 +14: All tests passed!
```

### Non-régression map_editor

Commande :

```bash
cd packages/map_editor && flutter test test/surface_painter
```

Sortie finale :

```text
00:03 +34: All tests passed!
```

Commande :

```bash
cd packages/map_editor && flutter test test/map_selection_controller_test.dart
```

Sortie finale :

```text
00:01 +5: All tests passed!
```

Commande :

```bash
cd packages/map_editor && flutter test test/surface_studio
```

Sortie finale :

```text
00:14 +392: All tests passed!
```

## Analyse lancée

Commande :

```bash
cd packages/map_editor && flutter analyze lib/src/features/surface_painter/surface_tile_preview_resolver.dart lib/src/features/surface_painter/surface_layer_static_preview.dart lib/src/ui/canvas/map_canvas.dart lib/src/ui/canvas/map_canvas/map_grid_painter.dart test/surface_painter/surface_tile_preview_resolver_test.dart test/surface_painter/surface_layer_static_preview_test.dart test/map_grid_painter_test.dart
```

Sortie :

```text
No issues found! (ran in 1.5s)
```

## Résultats

- Preview réelle depuis atlas Surface : ajoutée.
- Preview statique uniquement : conservée.
- Première frame uniquement : oui.
- Fallback debug : conservé.
- Rendu runtime : non ajouté.
- Animation editor : non ajoutée.
- `map_core` : non modifié.

## Evidence Pack

### Fichiers audités

```text
packages/map_core/lib/src/models/surface.dart
packages/map_core/lib/src/models/surface_catalog.dart
packages/map_core/lib/src/operations/surface_variant_role_resolver.dart
packages/map_core/test/surface_variant_role_resolver_test.dart
packages/map_editor/lib/src/features/surface_painter/surface_layer_static_preview.dart
packages/map_editor/lib/src/ui/canvas/map_canvas.dart
packages/map_editor/lib/src/ui/canvas/map_canvas/map_canvas_assets.dart
packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart
packages/map_editor/test/map_grid_painter_test.dart
packages/map_editor/test/surface_painter/surface_layer_static_preview_test.dart
```

### Recherches obligatoires lancées

```bash
rg -n "Image|ui\.Image|drawImage|drawImageRect|TileLayer|tileset|TileSet|Tileset|MapGridPainter|MapCanvas" packages/map_editor/lib/src/ui packages/map_editor/lib/src/features packages/map_editor/test
rg -n "surface_layer_static_preview|SurfaceLayer|SurfaceCellPlacement|surfacePresetId|resolveSurfaceVariantRoleForPlacement" packages/map_editor/lib packages/map_editor/test packages/map_core/lib packages/map_core/test
rg -n "ProjectManifest|surfaceCatalog|ProjectTileset|tilesets|relativePath|projectRootPath" packages/map_editor/lib packages/map_editor/test packages/map_core/lib
```

### Nouveau fichier principal

`surface_tile_preview_resolver.dart` contient :

```text
SurfaceTilePreviewInstruction
resolveSurfaceTilePreviewInstruction(...)
collectSurfaceTilePreviewTilesetIds(...)
```

Le fichier fait 185 lignes.

### Diff stat avant rapport

```text
 .../surface_layer_static_preview.dart              | 179 +++++++++++++++++----
 .../map_editor/lib/src/ui/canvas/map_canvas.dart   |  16 ++
 .../src/ui/canvas/map_canvas/map_grid_painter.dart |   4 +-
 .../map_editor/test/map_grid_painter_test.dart     | 126 +++++++++++++++
 .../surface_layer_static_preview_test.dart         | 108 +++++++++++++
 5 files changed, 403 insertions(+), 30 deletions(-)
```

Note : `git diff --stat` ne liste pas les fichiers untracked. Les fichiers créés sont listés dans les sections dédiées.

## Git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie :

```text
 M packages/map_editor/lib/src/features/surface_painter/surface_layer_static_preview.dart
 M packages/map_editor/lib/src/ui/canvas/map_canvas.dart
 M packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart
 M packages/map_editor/test/map_grid_painter_test.dart
 M packages/map_editor/test/surface_painter/surface_layer_static_preview_test.dart
?? packages/map_editor/lib/src/features/surface_painter/surface_tile_preview_resolver.dart
?? packages/map_editor/test/surface_painter/surface_tile_preview_resolver_test.dart
?? reports/surface/surface_engine_lot_87_surface_atlas_tile_preview_static_rendering.md
```

Commande :

```bash
git diff --stat
```

Sortie :

```text
 .../surface_layer_static_preview.dart              | 179 +++++++++++++++++----
 .../map_editor/lib/src/ui/canvas/map_canvas.dart   |  16 ++
 .../src/ui/canvas/map_canvas/map_grid_painter.dart |   4 +-
 .../map_editor/test/map_grid_painter_test.dart     | 126 +++++++++++++++
 .../surface_layer_static_preview_test.dart         | 108 +++++++++++++
 5 files changed, 403 insertions(+), 30 deletions(-)
```

Note : les fichiers `??` sont non trackés et donc absents de `git diff --stat`.

## Changements préexistants

Aucun. Le Gate 0 était clean.

## Changements du Lot 87

Tous les changements listés ci-dessus appartiennent au Lot 87.

## Périmètre explicitement non touché

Confirmé :

- `ProjectManifest` non modifié.
- `surface.dart` non modifié.
- `surface_catalog.dart` non modifié.
- codecs Surface non modifiés.
- `map_core` non modifié.
- `map_runtime` non modifié.
- `map_gameplay` non modifié.
- `map_battle` non modifié.
- aucun renderer runtime Surface créé.
- aucun resolver runtime Surface créé.
- aucune animation clock runtime créée.
- aucune migration legacy codée.
- aucun provider/repository/service Surface créé.
- aucune refonte Surface Studio.
- aucune animation editor créée.
- `Runner.xcscheme` non modifié.

## Vérification fichiers temporaires

Commande :

```bash
find . -type f \( -name '_gen_*.py' -o -name 'build_*.py' -o -name '*.tmp' \) -print
```

Sortie :

```text

```

Aucun fichier temporaire trouvé.

Commande :

```bash
git diff --check
```

Sortie :

```text

```

Aucun whitespace error signalé.

## Vérification mojibake

Commande sur les fichiers code/test touchés :

```bash
rg -n "<mojibake signatures>" packages/map_editor/lib/src/features/surface_painter/surface_tile_preview_resolver.dart packages/map_editor/lib/src/features/surface_painter/surface_layer_static_preview.dart packages/map_editor/lib/src/ui/canvas/map_canvas.dart packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart packages/map_editor/test/surface_painter/surface_tile_preview_resolver_test.dart packages/map_editor/test/surface_painter/surface_layer_static_preview_test.dart packages/map_editor/test/map_grid_painter_test.dart
```

Sortie :

```text

```

Aucun mojibake détecté dans les fichiers touchés.

## Auto-review

- Est-ce que la preview utilise les vraies tiles d'atlas quand résolubles ? Oui.
- Est-ce que la preview reste statique ? Oui.
- Est-ce que seule la première frame est utilisée ? Oui.
- Est-ce que le rôle est résolu via `resolveSurfaceVariantRoleForPlacement` ? Oui.
- Est-ce que le pipeline `surfacePresetId -> preset -> animation -> frame -> atlas` fonctionne ? Oui.
- Est-ce que `sourceRect` est calculé depuis `column/row/tileSize` ? Oui.
- Est-ce que le fallback debug reste disponible ? Oui.
- Est-ce que l'absence de preset/animation/atlas/image ne crashe pas ? Oui, le resolver retourne `null` et le painter conserve l'overlay.
- Est-ce que terrain/path/tile rendering ne régresse pas ? Oui, tests ciblés `map_grid_painter_test` verts.
- Est-ce que Surface Painter fonctionne toujours ? Oui, `flutter test test/surface_painter` vert.
- Est-ce que Surface Studio fonctionne toujours ? Oui, `flutter test test/surface_studio` vert.
- Est-ce que `map_runtime` est modifié ? Non.
- Est-ce qu'un renderer runtime est créé ? Non.
- Est-ce qu'une animation clock est créée ? Non.
- Est-ce que les tests ciblés passent ? Oui.
- Est-ce que les analyses ciblées passent ? Oui.
- Est-ce qu'un 87-bis est nécessaire ? Non. La preview réelle fonctionne quand le catalogue et l'image sont résolus, et le fallback garde la visibilité dans les autres cas.

## Critique du prompt

- Le prompt demande de remplacer la preview debug, mais le maintien du fallback est indispensable : sans lui, une référence incomplète rendrait à nouveau les surfaces invisibles.
- Le terme "image source d'un atlas Surface" peut prêter à confusion : côté éditeur, l'image disponible est l'image de tileset référencée par `ProjectSurfaceAtlas.tilesetId`; ce lot réutilise donc le cache tileset existant.
- Charger seulement les tilesets des presets réellement placés évite de précharger tout Surface Studio. C'est plus léger et aligné avec un lot editor preview.
- Le lot ne résout volontairement pas l'animation, même si le modèle contient des durées : utiliser la première frame documente le comportement actuel plutôt qu'un futur idéal.
