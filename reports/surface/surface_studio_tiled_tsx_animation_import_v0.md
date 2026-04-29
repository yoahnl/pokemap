# Lot TSX-2 — Convert TSX tile animations into PokeMap Surface animations V0

## 1. Verdict

Lot TSX-2 implemente.

Le lot ajoute une conversion pure :

```text
Tiled TSX animated tileset
-> ProjectSurfaceAtlas
-> List<ProjectSurfaceAnimation>
-> diagnostics d'import
```

Aucun `ProjectSurfacePreset` n'est cree. Aucun role Surface n'est devine. Aucun `ProjectManifest` n'est mute. Aucun appel IA, PixelLab ou MCP n'est effectue. Aucun package `map_gameplay`, `map_runtime` ou `map_battle` n'a ete modifie par ce lot.

Context Mode : indisponible. La commande `ctx stats` a retourne :

```text
zsh:4: command not found: ctx
```

## 2. Audit initial

Commande initiale demandee :

```bash
pwd
git status --short --untracked-files=all
git diff --stat
rg -n "class ProjectSurfaceAtlas|class ProjectSurfaceAnimation|class SurfaceAnimationTimeline|class SurfaceAnimationFrame|class SurfaceAtlasTileRef|durationMs|tileRef|atlasId|SurfaceAtlasLayout|ProjectSurfaceCatalog" packages/map_core/lib packages/map_editor/lib/src/features/surface_studio
```

Constats de constructors :

```dart
ProjectSurfaceAtlas({
  required String id,
  required String name,
  required String tilesetId,
  required SurfaceAtlasGeometry geometry,
  String? categoryId,
  int sortOrder = 0,
})
```

```dart
ProjectSurfaceAnimation({
  required String id,
  required String name,
  required SurfaceAnimationTimeline timeline,
  String? syncGroupId,
  String? categoryId,
  int sortOrder = 0,
})
```

```dart
SurfaceAnimationTimeline({
  required List<SurfaceAnimationFrame> frames,
})
```

```dart
SurfaceAnimationFrame({
  required SurfaceAtlasTileRef tileRef,
  required int durationMs,
})
```

```dart
SurfaceAtlasTileRef({
  required String atlasId,
  required int column,
  required int row,
})
```

Reponses d'audit :

1. `ProjectSurfaceAtlas` porte `id`, `name`, `tilesetId`, `geometry`, `categoryId`, `sortOrder`.
2. `ProjectSurfaceAnimation` porte `id`, `name`, `timeline`, `syncGroupId`, `categoryId`, `sortOrder`.
3. `SurfaceAnimationTimeline` prend une liste non vide de `SurfaceAnimationFrame`.
4. `SurfaceAnimationFrame` prend `tileRef` et `durationMs`.
5. `SurfaceAtlasTileRef` prend `atlasId`, `column`, `row`.
6. `SurfaceAtlasTileRef.column` et `SurfaceAtlasTileRef.row` sont 0-based, confirme par les commentaires du modele et `SurfaceAtlasGeometry.containsGridCoordinate`.
7. Le champ de duree est `SurfaceAnimationFrame.durationMs`.
8. Le champ d'atlas est `SurfaceAtlasTileRef.atlasId`.
9. L'importer TSX-2 est place dans `packages/map_editor/lib/src/features/surface_studio/importers/`, a cote du parser TSX-1.
10. TSX-2 peut rester entierement dans `map_editor`, car il s'agit d'une brique d'import editeur. Les modeles produits sont `map_core`, mais aucun nouveau contrat core n'etait necessaire.

## 3. Modeles / fonctions ajoutes

Fichier :

```text
packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_surface_animation_importer.dart
```

Modeles ajoutes :

```text
TiledTsxSurfaceAnimationImportOptions
TiledTsxSurfaceAnimationImportResult
TiledTsxSurfaceAnimationImportDiagnosticSeverity
TiledTsxSurfaceAnimationImportDiagnostic
```

Fonctions ajoutees :

```text
importTiledTsxSurfaceAnimations
importTiledTsxSurfaceAnimationsFromXml
```

Choix important : `TiledTsxSurfaceAnimationImportResult.atlas` est nullable pour les erreurs bloquantes. Cela evite de fabriquer un faux `ProjectSurfaceAtlas` quand `atlasId`, `tilesetId` ou la geometrie TSX sont invalides. En cas valide, l'atlas est non nul et les animations sont produites.

## 4. Construction du ProjectSurfaceAtlas

Depuis `TECH-Animations.tsx`, le convertisseur produit :

```text
id = options.atlasId = tech-animations
name = TECH-Animations
tilesetId = options.tilesetId = tech-nature-animations
tileSize = 32 x 32
gridSize = 98 x 109
layout = SurfaceAtlasLayout.grid
categoryId = options.categoryId
sortOrder = options.sortOrderBase
```

Le `tilesetId` ne vient pas automatiquement de `imageSource`. Il vient des options, car PokeMap reference ses `ProjectTilesetEntry` via un id logique.

## 5. Conversion des animations

Pour chaque `TiledTsxTileAnimation`, le convertisseur cree :

```text
ProjectSurfaceAnimation.id = <slug(animationIdPrefix)>-tile-<baseTileId>
ProjectSurfaceAnimation.name = <summary.name> tile <baseTileId>
ProjectSurfaceAnimation.timeline = frames TSX converties dans l'ordre
ProjectSurfaceAnimation.categoryId = options.categoryId
ProjectSurfaceAnimation.sortOrder = options.sortOrderBase + index TSX
```

Pour chaque frame TSX :

```text
tileid -> resolveTiledTsxTileCoordinate(...)
duration -> SurfaceAnimationFrame.durationMs
atlasId -> SurfaceAtlasTileRef.atlasId = options.atlasId
column,row -> SurfaceAtlasTileRef column,row 0-based
```

Le convertisseur ne fait pas :

```text
- row++ automatique ;
- colonne fixe ;
- convention columns=roles rows=frames ;
- mapping de role Surface ;
- generation de preset.
```

## 6. Exemple detaille tile id 99

Resultat attendu et teste :

```text
ProjectSurfaceAnimation id = tech-animations-tile-99
name = TECH-Animations tile 99
frameCount = 16
```

Frames detaillees :

```text
1. tileid 99  -> column 1,  row 1, durationMs 100, atlasId tech-animations
2. tileid 105 -> column 7,  row 1, durationMs 100, atlasId tech-animations
...
16. tileid 189 -> column 91, row 1, durationMs 100, atlasId tech-animations
```

Ce test prouve que TSX-2 lit les `frame tileid` exacts du TSX. Il ne genere pas une animation en gardant la colonne et en incrementant seulement la ligne.

## 7. Diagnostics

Diagnostics d'erreur bloquants :

```text
- atlasId vide ;
- tilesetId vide ;
- animationIdPrefix vide ;
- animationIdPrefix sans segment slug ASCII exploitable ;
- tileWidth/tileHeight invalides ;
- imageWidth/imageHeight invalides ;
- imageWidth non divisible par tileWidth ;
- imageHeight non divisible par tileHeight ;
- columns incoherent avec imageWidth / tileWidth ;
- animation sans frames ;
- frame duration <= 0 ;
- generated animation id duplique.
```

Diagnostics de warning :

```text
- diagnostics warning remontes du parser TSX-1 ;
- tileCount different de image grid ;
- frame tileId hors tileCount ;
- frame resolue hors grille atlas.
```

Une erreur bloquante retourne :

```text
atlas = null
animations = []
diagnostics = erreurs + warnings
```

Un warning seul n'empeche pas forcement l'import.

## 8. Tests

### Regression parser TSX-1

Commande :

```bash
cd packages/map_editor && flutter test test/surface_studio/tiled_tsx_animated_tileset_parser_test.dart --no-pub --reporter expanded
```

Sortie :

```text
00:00 +0: parseTiledTsxAnimatedTileset parses the Pokemon SDK TECH animated tileset summary
00:00 +1: parseTiledTsxAnimatedTileset parses tile id 99 animation frames and durations
00:00 +2: parseTiledTsxAnimatedTileset resolves Tiled 0-based tile ids to source coordinates
00:00 +3: parseTiledTsxAnimatedTileset reports a TSX missing its image tag
00:00 +4: parseTiledTsxAnimatedTileset allows a TSX without animations
00:00 +5: parseTiledTsxAnimatedTileset reports missing frame duration
00:00 +6: parseTiledTsxAnimatedTileset warns when an animation frame references a tile outside tilecount
00:00 +7: All tests passed!
```

Resultat : passe.

### Importer TSX-2

Commande :

```bash
cd packages/map_editor && flutter test test/surface_studio/tiled_tsx_surface_animation_importer_test.dart --no-pub --reporter expanded
```

Sortie :

```text
00:00 +0: importTiledTsxSurfaceAnimations imports the Pokemon SDK TSX as one atlas and 242 animations
00:00 +1: importTiledTsxSurfaceAnimations converts tile id 99 frames from explicit TSX tile ids
00:00 +2: importTiledTsxSurfaceAnimations keeps TSX order and does not expose any preset output
00:00 +3: importTiledTsxSurfaceAnimations reports invalid import options as blocking diagnostics
00:00 +4: importTiledTsxSurfaceAnimations imports a minimal TSX with explicit frame durations
00:00 +5: importTiledTsxSurfaceAnimations blocks imports when TSX geometry cannot form a tile grid
00:00 +6: importTiledTsxSurfaceAnimations reports duplicate generated animation ids as blocking diagnostics
00:00 +7: All tests passed!
```

Resultat : passe.

### Tests Surface Studio

Commande :

```bash
cd packages/map_editor && flutter test test/surface_studio --no-pub --reporter expanded
```

Premiere execution : echec de compilation sur des tests deja modifies avant TSX-2 :

```text
test/surface_studio/surface_studio_panel_test.dart:157:5: Error: Duplicated named argument 'surfaceCatalog'.
test/surface_studio/surface_studio_workspace_entry_test.dart:145:34: Error: No named parameter with the name 'surfaceCatalog'.
test/surface_studio/surface_studio_workspace_entry_test.dart:194:5: Error: Duplicated named argument 'surfaceCatalog'.
test/shell_chrome_test_harness.dart:41:5: Error: Duplicated named argument 'surfaceCatalog'.
```

Correction minimale appliquee :

```text
- suppression du `surfaceCatalog: ProjectSurfaceCatalog()` duplique dans trois helpers de test ;
- retour a `saveProjectManifest()` sans parametre obsolète.
```

Execution finale :

```text
00:21 +377: All tests passed!
```

Resultat : passe.

## 9. Analyze

Commande :

```bash
cd packages/map_editor && flutter analyze lib/src/features/surface_studio
```

Sortie :

```text
Analyzing surface_studio...
No issues found! (ran in 1.9s)
```

Resultat : passe.

## 10. Non-objectifs confirmes

Confirmes :

```text
- pas de refonte UI Surface Studio ;
- pas de picker de region TSX ;
- pas de preset Surface automatique ;
- pas de mapping role -> animation ;
- pas de Mistral ;
- pas de PixelLab ;
- pas de MCP ;
- pas de runtime Flame ;
- pas de gameplay ;
- pas de modification map_gameplay ;
- pas de modification map_runtime par TSX-2 ;
- pas de modification map_battle ;
- pas de mutation ProjectManifest ;
- pas de sauvegarde disque par l'importer.
```

Note worktree : `packages/map_runtime/test/battle_overlay_component_test.dart` est modifie dans le status final, mais cette modification etait hors TSX-2 et n'a pas ete editee pendant ce lot.

## 11. Roadmap TSX suivante

Suite recommandee :

```text
Lot TSX-3 — Surface Studio TSX Animation Browser / Region Picker V0
Lot TSX-4 — Build Surface preset from selected TSX animations V0
Lot TSX-5 — Optional Mistral grouping assistant for TSX animations
```

Principe :

```text
TSX reste source de verite pour frames/durations.
PokeMap convertit les animations exactes.
Surface Studio aide ensuite a selectionner, grouper et mapper.
Mistral peut aider plus tard a nommer/grouper, mais ne doit plus deviner les frames.
```

## 12. Git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie :

```text
 M packages/map_editor/test/shell_chrome_test_harness.dart
 M packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
 M packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart
 M packages/map_runtime/test/battle_overlay_component_test.dart
 M packages/map_runtime/test/npc_runtime_presence_test.dart
 M packages/map_runtime/test/playable_map_game_input_test.dart
 M packages/map_runtime/test/trainer_battle_request_test.dart
 M packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart
?? packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_surface_animation_importer.dart
?? packages/map_editor/test/surface_studio/tiled_tsx_surface_animation_importer_test.dart
?? reports/surface/surface_studio_tiled_tsx_animation_import_v0.md
```

Lignes TSX-2 ajoutees :

```text
?? packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_surface_animation_importer.dart
?? packages/map_editor/test/surface_studio/tiled_tsx_surface_animation_importer_test.dart
?? reports/surface/surface_studio_tiled_tsx_animation_import_v0.md
```

Lignes de tests editeur corrigees pour compiler la suite Surface Studio :

```text
 M packages/map_editor/test/shell_chrome_test_harness.dart
 M packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
 M packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart
```

Lignes hors TSX-2 non editees pendant ce lot :

```text
 M packages/map_runtime/test/battle_overlay_component_test.dart
 M packages/map_runtime/test/npc_runtime_presence_test.dart
 M packages/map_runtime/test/playable_map_game_input_test.dart
 M packages/map_runtime/test/trainer_battle_request_test.dart
 M packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart
```
