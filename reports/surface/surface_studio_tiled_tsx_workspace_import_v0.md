# Lot TSX-6 — Surface Studio Dedicated TSX Workspace / Import TSX UI V0

## 1. Verdict

Lot TSX-6 accepté côté implémentation automatisée. Le workflow TSX est visible au premier niveau dans Surface Studio, l’import .tsx passe par une abstraction testable, le catalogue de travail reçoit atlas + animations, et aucun preset / gameplay / sauvegarde disque automatique n’est créé. QA interactive macOS complète non exécutée dans ce lot. Réserve : le statut final contient deux modifications Mistral hors périmètre TSX-6, documentées ci-dessous.

## 2. Audit Initial

- Git initial avant modification : `git status --short --untracked-files=all` ne listait aucun fichier.
- `git diff --stat` initial ne listait aucune modification.
- Context Mode : disponible via les outils MCP `mcp__context_mode__`; la commande shell `ctx` n’était pas installée.
- Le browser TSX existant était rendu dans `SurfaceStudioPanel` via `_AdvancedDetailsSection`, lui-même passé comme `advancedDrawer` à `SurfaceStudioScreen`.
- Le drawer avancé était donc l’accès produit principal au browser TSX avant ce lot.
- Surface Studio gérait déjà un wizard principal (`SurfaceStudioScreen`) et un drawer avancé, mais pas de navigation primaire `Catalogue Surface / TSX / Diagnostics`.
- TSX-3 avait livré `TiledTsxAnimationBrowser` avec recherche, sélection locale, preview de frames et builder TSX-4 visible depuis la sélection.
- TSX-4 avait livré le draft / builder de preset explicite, sans mapping automatique.
- TSX-5 avait livré l’assistant Mistral optionnel dans le browser, avec validation humaine.
- `ProjectTilesetEntry` expose au minimum `id`, `name`, `relativePath`, ce qui suffit pour demander à l’utilisateur le tileset image PokeMap correspondant au `imageSource` TSX.
- Le repo utilise déjà `file_picker` dans `map_editor`, notamment pour l’import de tilesets classiques.

## 3. Emplacement du Nouvel Onglet TSX

`SurfaceStudioPanel` expose maintenant une navigation primaire : `Catalogue Surface`, `TSX`, `Diagnostics`. Le workspace TSX est rendu par `TiledTsxWorkspace` sous la clé `surface_studio.tsx_workspace`.

## 4. Navigation Avant / Après

Avant :
- Surface Studio ouvrait directement le wizard atlas vertical.
- Le browser TSX était accessible dans le drawer avancé `Catalogue & diagnostics`.

Après :
- `Catalogue Surface` garde le wizard existant.
- `TSX` affiche le workflow import / animations TSX au premier niveau.
- `Diagnostics` expose l’ancien contenu avancé comme workspace dédié.
- Le drawer avancé reste disponible depuis le wizard pour compatibilité.

## 5. Fonctionnement du File Picker / Loader

`TiledTsxFileLoader` est une interface injectable. L’implémentation production `TiledTsxPlatformFileLoader` utilise `FilePicker.platform.pickFiles` avec l’extension `.tsx`, puis lit le XML depuis le chemin choisi. Les tests injectent un faux loader et ne dépendent pas d’un chemin production hardcodé.

## 6. Résumé TSX Affiché

Après chargement, le workspace affiche `name`, `tileWidth`, `tileHeight`, `columns`, `tileCount`, `imageSource`, `imageWidth`, `imageHeight`, `animationCount`, `transparentColor` et les diagnostics d’erreur.

## 7. Matching imageSource -> ProjectTilesetEntry

Le matching V0 compare le basename de `summary.imageSource` avec le basename de `ProjectTilesetEntry.relativePath`, en minuscules. Exemple testé : `../Assets/TECH-Nature-animations.png` matche `Data/Tiled/Assets/TECH-Nature-animations.png`. Si aucun tileset n’existe, l’import est bloqué avec un message utilisateur.

## 8. Injection dans le Work Catalog

`appendTiledTsxSurfaceImportToCatalog` ajoute l’atlas et les animations à un `ProjectSurfaceCatalog` en conservant les atlas, animations et presets existants. La fonction refuse les ids d’atlas ou d’animations déjà présents. Elle ne crée aucun `ProjectSurfacePreset`.

Le workspace appelle `importTiledTsxSurfaceAnimations` puis `appendTiledTsxSurfaceImportToCatalog`. Il appelle `onSurfaceCatalogChanged` avec le catalogue de travail mis à jour. Aucune sauvegarde disque n’est déclenchée.

## 9. Diagnostics / Erreurs

Cas couverts : TSX invalide ou incomplet, TSX sans animations, absence de tileset image PokeMap, duplicate atlas id, duplicate animation id. Les erreurs sont affichées dans le workspace et ne mutent pas le catalogue.

## 10. Tests

### Commande
````text
cd packages/map_editor && flutter test test/surface_studio/tiled_tsx_workspace_tab_test.dart --no-pub --reporter expanded
````

Ligne finale exacte : `00:01 +2: All tests passed!`

Sortie complète :

````text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/tiled_tsx_workspace_tab_test.dart
00:00 +0: Surface Studio exposes a first-level TSX workspace
00:00 +1: Diagnostics remain available as their own top-level workspace
00:01 +2: All tests passed!
````

### Commande
````text
cd packages/map_editor && flutter test test/surface_studio/tiled_tsx_catalog_append_test.dart --no-pub --reporter expanded
````

Ligne finale exacte : `00:00 +4: All tests passed!`

Sortie complète :

````text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/tiled_tsx_catalog_append_test.dart
00:00 +0: appendTiledTsxSurfaceImportToCatalog adds atlas and animations to an empty catalog without presets
00:00 +1: appendTiledTsxSurfaceImportToCatalog preserves existing presets and never creates a preset
00:00 +2: appendTiledTsxSurfaceImportToCatalog rejects duplicate atlas id
00:00 +3: appendTiledTsxSurfaceImportToCatalog rejects duplicate animation id
00:00 +4: All tests passed!
````

### Commande
````text
cd packages/map_editor && flutter test test/surface_studio/tiled_tsx_import_ui_test.dart --no-pub --reporter expanded
````

Ligne finale exacte : `00:01 +5: All tests passed!`

Sortie complète :

````text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/tiled_tsx_import_ui_test.dart
00:00 +0: TiledTsxWorkspace import UI loads a TSX, shows summary, imports atlas and animations
00:00 +1: TiledTsxWorkspace import UI blocks import when no matching tileset is available
00:01 +2: TiledTsxWorkspace import UI shows parser errors for invalid TSX
00:01 +3: TiledTsxWorkspace import UI blocks TSX without animations
00:01 +4: TiledTsxWorkspace import UI reports duplicate atlas id without mutating the catalog
00:01 +5: All tests passed!
````

### Commande
````text
cd packages/map_editor && flutter test test/surface_studio/tiled_tsx_animated_tileset_parser_test.dart --no-pub --reporter expanded
````

Ligne finale exacte : `00:00 +7: All tests passed!`

Sortie complète :

````text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/tiled_tsx_animated_tileset_parser_test.dart
00:00 +0: parseTiledTsxAnimatedTileset parses the Pokemon SDK TECH animated tileset summary
00:00 +1: parseTiledTsxAnimatedTileset parses tile id 99 animation frames and durations
00:00 +2: parseTiledTsxAnimatedTileset resolves Tiled 0-based tile ids to source coordinates
00:00 +3: parseTiledTsxAnimatedTileset reports a TSX missing its image tag
00:00 +4: parseTiledTsxAnimatedTileset allows a TSX without animations
00:00 +5: parseTiledTsxAnimatedTileset reports missing frame duration
00:00 +6: parseTiledTsxAnimatedTileset warns when an animation frame references a tile outside tilecount
00:00 +7: All tests passed!
````

### Commande
````text
cd packages/map_editor && flutter test test/surface_studio/tiled_tsx_surface_animation_importer_test.dart --no-pub --reporter expanded
````

Ligne finale exacte : `00:00 +7: All tests passed!`

Sortie complète :

````text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/tiled_tsx_surface_animation_importer_test.dart
00:00 +0: importTiledTsxSurfaceAnimations imports the Pokemon SDK TSX as one atlas and 242 animations
00:00 +1: importTiledTsxSurfaceAnimations converts tile id 99 frames from explicit TSX tile ids
00:00 +2: importTiledTsxSurfaceAnimations keeps TSX order and does not expose any preset output
00:00 +3: importTiledTsxSurfaceAnimations reports invalid import options as blocking diagnostics
00:00 +4: importTiledTsxSurfaceAnimations imports a minimal TSX with explicit frame durations
00:00 +5: importTiledTsxSurfaceAnimations blocks imports when TSX geometry cannot form a tile grid
00:00 +6: importTiledTsxSurfaceAnimations reports duplicate generated animation ids as blocking diagnostics
00:00 +7: All tests passed!
````

### Commande
````text
cd packages/map_editor && flutter test test/surface_studio/tiled_tsx_animation_browser_test.dart --no-pub --reporter expanded
````

Ligne finale exacte : `00:01 +7: All tests passed!`

Sortie complète :

````text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/tiled_tsx_animation_browser_test.dart
00:00 +0: TiledTsxAnimationBrowser models builds browser items from the 242 imported Pokemon SDK animations
00:00 +1: TiledTsxAnimationBrowser models filters by animation id, display name, and base tile id
00:00 +2: TiledTsxAnimationBrowser widget selects and clears animations without mutating the catalog
00:01 +3: TiledTsxAnimationBrowser widget searches by tile id in the browser UI
00:01 +4: TiledTsxAnimationBrowser widget shows imported TSX frame details for tile 99
00:01 +5: TiledTsxSurfaceAnimationPreview steps through explicit ProjectSurfaceAnimation frames
00:01 +6: TiledTsxSurfaceAnimationPreview lists frames when atlas image bytes are unavailable
00:01 +7: All tests passed!
````

### Commande
````text
cd packages/map_editor && flutter test test/surface_studio/tiled_tsx_surface_preset_builder_test.dart --no-pub --reporter expanded
````

Ligne finale exacte : `00:00 +5: All tests passed!`

Sortie complète :

````text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/tiled_tsx_surface_preset_builder_test.dart
00:00 +0: TiledTsxSurfacePresetDraft validates and builds a preset from an explicit isolated mapping
00:00 +1: TiledTsxSurfacePresetDraft rejects duplicate preset ids
00:00 +2: TiledTsxSurfacePresetDraft requires isolated and known animation ids
00:00 +3: TiledTsxSurfacePresetDraft reports draft identity errors
00:00 +4: TiledTsxSurfacePresetDraft builds a preset from the real Pokemon SDK TSX import output
00:00 +5: All tests passed!
````

### Commande
````text
cd packages/map_editor && flutter test test/surface_studio/tiled_tsx_mistral_grouping_ui_test.dart --no-pub --reporter expanded
````

Ligne finale exacte : `00:01 +3: All tests passed!`

Sortie complète :

````text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/tiled_tsx_mistral_grouping_ui_test.dart
00:00 +0: Mistral grouping button requires selection and configured key
00:00 +1: Mistral grouping shows missing key message
00:00 +2: Mistral grouping requires confirmation, shows progress, then fills draft only after accept
00:01 +3: All tests passed!
````

### Commande globale Surface Studio

````text
cd packages/map_editor && flutter test test/surface_studio --no-pub --reporter expanded
````

Ligne finale exacte : `00:28 +409: All tests passed!`

Sortie complète :

````text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_selection_summary_test.dart
00:00 +0: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_selection_summary_test.dart: résumé none + hint
00:00 +1: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_selection_summary_test.dart: résumé none + hint
00:00 +2: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/tiled_tsx_import_ui_test.dart: TiledTsxWorkspace import UI loads a TSX, shows summary, imports atlas and animations
00:00 +3: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/tiled_tsx_import_ui_test.dart: TiledTsxWorkspace import UI loads a TSX, shows summary, imports atlas and animations
00:00 +4: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/tiled_tsx_import_ui_test.dart: TiledTsxWorkspace import UI loads a TSX, shows summary, imports atlas and animations
00:00 +5: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/tiled_tsx_import_ui_test.dart: TiledTsxWorkspace import UI loads a TSX, shows summary, imports atlas and animations
00:01 +6: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_schema_panel_test.dart: schema panel uses accordions and shows expected roles
00:01 +7: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_schema_panel_test.dart: schema panel uses accordions and shows expected roles
00:01 +8: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_schema_panel_test.dart: schema panel uses accordions and shows expected roles
00:01 +9: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_schema_panel_test.dart: schema panel uses accordions and shows expected roles
00:02 +10: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_schema_panel_test.dart: schema panel uses accordions and shows expected roles
00:02 +11: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_schema_panel_test.dart: schema panel uses accordions and shows expected roles
00:02 +12: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mistral_progress_test.dart: Mistral progress stays visible while AI future is pending
00:02 +13: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mistral_progress_test.dart: Mistral progress stays visible while AI future is pending
00:02 +14: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mistral_progress_test.dart: Mistral progress stays visible while AI future is pending
00:02 +15: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mistral_progress_test.dart: Mistral progress stays visible while AI future is pending
00:02 +16: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mistral_progress_test.dart: Mistral progress stays visible while AI future is pending
00:02 +17: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mistral_progress_test.dart: Mistral progress stays visible while AI future is pending
00:02 +18: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mistral_progress_test.dart: Mistral progress stays visible while AI future is pending
00:02 +19: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mistral_progress_test.dart: Mistral progress stays visible while AI future is pending
00:02 +20: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mistral_progress_test.dart: Mistral progress stays visible while AI future is pending
00:02 +21: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mistral_progress_test.dart: Mistral progress stays visible while AI future is pending
00:02 +22: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mistral_progress_test.dart: Mistral progress stays visible while AI future is pending
00:02 +23: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mistral_progress_test.dart: Mistral progress stays visible while AI future is pending
00:02 +24: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapper_preview_test.dart: selection alone is not mapping, quick center assignment activates preview
00:02 +25: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapper_preview_test.dart: selection alone is not mapping, quick center assignment activates preview
00:02 +26: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapper_preview_test.dart: selection alone is not mapping, quick center assignment activates preview
00:02 +27: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapper_preview_test.dart: selection alone is not mapping, quick center assignment activates preview
00:02 +28: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapper_preview_test.dart: selection alone is not mapping, quick center assignment activates preview
00:02 +29: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapper_preview_test.dart: selection alone is not mapping, quick center assignment activates preview
00:02 +30: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapper_preview_test.dart: selection alone is not mapping, quick center assignment activates preview
00:03 +31: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapper_preview_test.dart: selection alone is not mapping, quick center assignment activates preview
00:03 +32: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapper_preview_test.dart: selection alone is not mapping, quick center assignment activates preview
00:03 +33: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapper_preview_test.dart: selection alone is not mapping, quick center assignment activates preview
00:03 +34: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapper_preview_test.dart: selection alone is not mapping, quick center assignment activates preview
00:03 +35: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/tiled_tsx_workspace_tab_test.dart: Surface Studio exposes a first-level TSX workspace
00:04 +36: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/tiled_tsx_workspace_tab_test.dart: Surface Studio exposes a first-level TSX workspace
00:04 +37: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/tiled_tsx_workspace_tab_test.dart: Surface Studio exposes a first-level TSX workspace
00:04 +38: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 60) titre, brouillon local, défauts 32/1/1
00:05 +39: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 60) titre, brouillon local, défauts 32/1/1
00:05 +40: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 60) titre, brouillon local, défauts 32/1/1
00:05 +41: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 60) titre, brouillon local, défauts 32/1/1
00:05 +42: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 60) titre, brouillon local, défauts 32/1/1
00:05 +43: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 60) titre, brouillon local, défauts 32/1/1
00:05 +44: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 60) titre, brouillon local, défauts 32/1/1
00:05 +45: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 60) titre, brouillon local, défauts 32/1/1
00:05 +46: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 60) titre, brouillon local, défauts 32/1/1
00:05 +47: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel V2.1 renders one wizard and no legacy workflow underneath
00:05 +48: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel V2.1 renders one wizard and no legacy workflow underneath
00:05 +49: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel V2.1 renders one wizard and no legacy workflow underneath
00:05 +50: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 60) id / nom / tileset vides: erreurs
00:05 +51: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel V2.1 keeps catalog and diagnostics in the advanced drawer
00:06 +52: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel V2.1 keeps catalog and diagnostics in the advanced drawer
00:06 +53: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel V2.1 keeps catalog and diagnostics in the advanced drawer
00:06 +54: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel V2.1 keeps catalog and diagnostics in the advanced drawer
00:06 +55: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel V2.1 keeps catalog and diagnostics in the advanced drawer
00:06 +56: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel V2.1 keeps catalog and diagnostics in the advanced drawer
00:06 +57: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 60) hauteur / colonnes / lignes <= 0: erreur
00:06 +58: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 60) hauteur / colonnes / lignes <= 0: erreur
00:06 +59: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 60) hauteur / colonnes / lignes <= 0: erreur
00:06 +60: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: premium wizard shell mirrors the reference structure
00:07 +61: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: premium wizard shell mirrors the reference structure
00:07 +62: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: premium wizard shell mirrors the reference structure
00:07 +63: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: premium wizard shell mirrors the reference structure
00:07 +64: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: premium wizard shell mirrors the reference structure
00:07 +65: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: premium wizard shell mirrors the reference structure
00:07 +66: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: premium wizard shell mirrors the reference structure
00:07 +67: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_selection_interaction_test.dart: Fiches sélectionnables (Lot 58) 8. atlas sans badge si none
00:07 +68: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_selection_interaction_test.dart: Fiches sélectionnables (Lot 58) 8. atlas sans badge si none
00:08 +69: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: sidebar and right dock collapse and expand with sliding panels
00:08 +70: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: sidebar and right dock collapse and expand with sliding panels
00:08 +71: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: sidebar and right dock collapse and expand with sliding panels
00:08 +72: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: sidebar and right dock collapse and expand with sliding panels
00:08 +73: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: sidebar and right dock collapse and expand with sliding panels
00:08 +74: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: sidebar and right dock collapse and expand with sliding panels
00:08 +75: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: sidebar and right dock collapse and expand with sliding panels
00:08 +76: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: sidebar and right dock collapse and expand with sliding panels
00:08 +77: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: sidebar and right dock collapse and expand with sliding panels
00:08 +78: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: sidebar and right dock collapse and expand with sliding panels
00:08 +79: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: sidebar and right dock collapse and expand with sliding panels
00:08 +80: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: sidebar and right dock collapse and expand with sliding panels
00:08 +81: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: sidebar and right dock collapse and expand with sliding panels
00:08 +82: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: sidebar and right dock collapse and expand with sliding panels
00:08 +83: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: sidebar and right dock collapse and expand with sliding panels
00:08 +84: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 60) sélection atlas manquant: note + stable
00:08 +85: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 60) sélection atlas manquant: note + stable
00:08 +86: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 60) sélection atlas manquant: note + stable
00:08 +87: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 60) sélection atlas manquant: note + stable
00:08 +88: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 60) sélection atlas manquant: note + stable
00:08 +89: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 60) sélection atlas manquant: note + stable
00:08 +90: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 60) sélection atlas manquant: note + stable
00:08 +91: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 60) sélection atlas manquant: note + stable
00:08 +92: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 60) sélection atlas manquant: note + stable
00:08 +93: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 60) sélection atlas manquant: note + stable
00:08 +94: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: stepper allows previous steps and blocks locked future steps
00:08 +95: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: stepper allows previous steps and blocks locked future steps
00:08 +96: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: stepper allows previous steps and blocks locked future steps
00:08 +97: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: stepper allows previous steps and blocks locked future steps
00:08 +98: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: stepper allows previous steps and blocks locked future steps
00:08 +99: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: stepper allows previous steps and blocks locked future steps
00:08 +100: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: stepper allows previous steps and blocks locked future steps
00:08 +101: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: stepper allows previous steps and blocks locked future steps
00:09 +102: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 60) brouillon valide + prévisu: texte aperçu
00:09 +103: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: bottom action bar exposes the required commands
00:09 +104: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_preset_detail_view_test.dart: SurfaceStudioPresetDetailView (Lot 57) 23. title Presets Surface
00:09 +105: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_preset_detail_view_test.dart: SurfaceStudioPresetDetailView (Lot 57) 23. title Presets Surface
00:09 +106: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_preset_detail_view_test.dart: SurfaceStudioPresetDetailView (Lot 57) 23. title Presets Surface
00:09 +107: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_preset_detail_view_test.dart: SurfaceStudioPresetDetailView (Lot 57) 23. title Presets Surface
00:09 +108: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_preset_detail_view_test.dart: SurfaceStudioPresetDetailView (Lot 57) 23. title Presets Surface
00:09 +109: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_preset_detail_view_test.dart: SurfaceStudioPresetDetailView (Lot 57) 23. title Presets Surface
00:09 +110: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_preset_detail_view_test.dart: SurfaceStudioPresetDetailView (Lot 57) 23. title Presets Surface
00:09 +111: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_preset_detail_view_test.dart: SurfaceStudioPresetDetailView (Lot 57) 23. title Presets Surface
00:09 +112: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:10 +113: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:10 +114: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:10 +115: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:10 +116: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:10 +117: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:10 +118: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:10 +119: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:10 +120: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:10 +121: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:10 +122: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:10 +123: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:10 +124: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:10 +125: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:10 +126: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:10 +127: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:10 +128: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:10 +129: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:10 +130: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:10 +131: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:10 +132: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:10 +133: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:10 +134: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:10 +135: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:10 +136: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:10 +137: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:10 +138: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:10 +139: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:11 +140: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:11 +141: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:11 +142: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:11 +143: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:12 +144: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:12 +145: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:12 +146: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:12 +147: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:12 +148: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:12 +149: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/tiled_tsx_surface_preset_builder_ui_test.dart: creates a preset from selected TSX animations only after explicit role mapping
00:12 +150: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_column_role_mapping_block_test.dart: SurfaceStudioColumnRoleMappingBlock affiche la section Mapping des colonnes
00:12 +151: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_column_role_mapping_block_test.dart: SurfaceStudioColumnRoleMappingBlock affiche la section Mapping des colonnes
00:13 +152: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_column_role_mapping_block_test.dart: SurfaceStudioColumnRoleMappingBlock affiche la section Mapping des colonnes
00:13 +153: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_preview_controls_test.dart: preview panel exposes playback, scrub, loop grid and size controls
00:13 +154: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_preview_controls_test.dart: preview panel exposes playback, scrub, loop grid and size controls
00:13 +155: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_preview_controls_test.dart: preview panel exposes playback, scrub, loop grid and size controls
00:13 +156: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_preview_controls_test.dart: preview panel exposes playback, scrub, loop grid and size controls
00:13 +157: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_preview_controls_test.dart: preview panel exposes playback, scrub, loop grid and size controls
00:13 +158: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_preview_controls_test.dart: preview panel exposes playback, scrub, loop grid and size controls
00:13 +159: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_preview_controls_test.dart: preview panel exposes playback, scrub, loop grid and size controls
00:14 +160: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_preview_controls_test.dart: preview panel exposes playback, scrub, loop grid and size controls
00:14 +161: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_preview_controls_test.dart: preview panel exposes playback, scrub, loop grid and size controls
00:14 +162: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_preview_controls_test.dart: preview panel exposes playback, scrub, loop grid and size controls
00:14 +163: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_column_role_mapping_block_test.dart: SurfaceStudioColumnRoleMappingBlock appelle onDraftChanged quand on suggère un mapping standard
00:14 +164: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 71) aperçu mis à jour en mode édition
00:14 +165: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_column_role_mapping_block_test.dart: SurfaceStudioColumnRoleMappingBlock appelle onDraftChanged quand on réinitialise le mapping
00:14 +166: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: section Mapping des colonnes visible pour atlas 23×32
00:14 +167: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: section Mapping des colonnes visible pour atlas 23×32
00:14 +168: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: section Mapping des colonnes visible pour atlas 23×32
00:14 +169: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: section Mapping des colonnes visible pour atlas 23×32
00:14 +170: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_column_role_mapping_block_test.dart: SurfaceStudioColumnRoleMappingBlock affiche les libellés utilisateur des rôles
00:14 +171: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: section Mapping des colonnes affiche Atlas simple pour 1×1
00:14 +172: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: Lot 77 : section Plan de génération des animations visible
00:14 +173: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: Lot 79 : section création surface peignable visible
00:15 +174: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: Lot 76 : section Aperçu animation par colonne visible
00:15 +175: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: boutons Suggérer et Réinitialiser fonctionnent
00:15 +176: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_source_picker_test.dart: suggestInternalAtlasIdFromName eau animée
00:15 +177: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_source_picker_test.dart: suggestInternalAtlasIdFromName vide
00:15 +178: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_source_picker_test.dart: sortedTilesetChoices ordre sortOrder puis nom
00:16 +179: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/tiled_tsx_surface_preset_builder_test.dart: TiledTsxSurfacePresetDraft validates and builds a preset from an explicit isolated mapping
00:16 +180: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/tiled_tsx_surface_preset_builder_test.dart: TiledTsxSurfacePresetDraft rejects duplicate preset ids
00:16 +181: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/tiled_tsx_surface_preset_builder_test.dart: TiledTsxSurfacePresetDraft requires isolated and known animation ids
00:16 +182: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/tiled_tsx_surface_preset_builder_test.dart: TiledTsxSurfacePresetDraft reports draft identity errors
00:16 +183: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/tiled_tsx_surface_preset_builder_test.dart: TiledTsxSurfacePresetDraft builds a preset from the real Pokemon SDK TSX import output
00:16 +184: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_diagnostics_view_test.dart: SurfaceStudioDiagnosticsView (Lot 55) 1. title Diagnostics Surface
00:16 +185: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_diagnostics_view_test.dart: SurfaceStudioDiagnosticsView (Lot 55) 1. title Diagnostics Surface
00:16 +186: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_functional_integration_test.dart: Surface Studio renders one integrated wizard without legacy below
00:16 +187: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_functional_integration_test.dart: Surface Studio renders one integrated wizard without legacy below
00:16 +188: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_functional_integration_test.dart: Surface Studio renders one integrated wizard without legacy below
00:16 +189: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_functional_integration_test.dart: Surface Studio renders one integrated wizard without legacy below
00:16 +190: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_functional_integration_test.dart: Surface Studio renders one integrated wizard without legacy below
00:16 +191: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_functional_integration_test.dart: Surface Studio renders one integrated wizard without legacy below
00:16 +192: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_functional_integration_test.dart: Surface Studio renders one integrated wizard without legacy below
00:16 +193: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_functional_integration_test.dart: Surface Studio renders one integrated wizard without legacy below
00:16 +194: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_functional_integration_test.dart: Surface Studio renders one integrated wizard without legacy below
00:16 +195: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_functional_integration_test.dart: Surface Studio renders one integrated wizard without legacy below
00:16 +196: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_functional_integration_test.dart: Surface Studio renders one integrated wizard without legacy below
00:16 +197: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_functional_integration_test.dart: Surface Studio renders one integrated wizard without legacy below
00:16 +198: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_functional_integration_test.dart: Surface Studio renders one integrated wizard without legacy below
00:16 +199: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_functional_integration_test.dart: Surface Studio renders one integrated wizard without legacy below
00:16 +200: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_functional_integration_test.dart: Surface Studio renders one integrated wizard without legacy below
00:16 +201: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_functional_integration_test.dart: Surface Studio renders one integrated wizard without legacy below
00:17 +202: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_functional_integration_test.dart: Surface Studio renders one integrated wizard without legacy below
00:17 +203: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_functional_integration_test.dart: Surface Studio renders one integrated wizard without legacy below
00:17 +204: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_functional_integration_test.dart: Surface Studio renders one integrated wizard without legacy below
00:17 +205: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_functional_integration_test.dart: Surface Studio renders one integrated wizard without legacy below
00:17 +206: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_functional_integration_test.dart: Surface Studio renders one integrated wizard without legacy below
00:17 +207: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_functional_integration_test.dart: Surface Studio renders one integrated wizard without legacy below
00:17 +208: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_functional_integration_test.dart: Surface Studio renders one integrated wizard without legacy below
00:17 +209: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_functional_integration_test.dart: Surface Studio renders one integrated wizard without legacy below
00:17 +210: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_functional_integration_test.dart: Surface Studio renders one integrated wizard without legacy below
00:17 +211: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_functional_integration_test.dart: Surface Studio renders one integrated wizard without legacy below
00:17 +212: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_functional_integration_test.dart: Surface Studio renders one integrated wizard without legacy below
00:17 +213: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_functional_integration_test.dart: Surface Studio renders one integrated wizard without legacy below
00:17 +214: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_functional_integration_test.dart: Surface Studio renders one integrated wizard without legacy below
00:17 +214: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
Warning: Falling back on slow accent color resolution. It’s possible that the accent colors have changed in a recent version of macOS, thus invalidating macos_ui’s accent colors, which were captured on macOS Ventura. If you see this message, please notify a maintainer of the macos_ui package.
00:17 +215: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_functional_integration_test.dart: Surface Studio renders one integrated wizard without legacy below
00:17 +216: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_functional_integration_test.dart: Surface Studio renders one integrated wizard without legacy below
00:17 +217: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:17 +218: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:17 +219: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:17 +220: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:17 +221: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:17 +222: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:17 +223: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:17 +224: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:18 +225: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:18 +226: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:18 +227: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:18 +228: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:18 +229: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:18 +230: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:18 +231: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:18 +232: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_functional_integration_test.dart: import and slice steps do not render schema or preview docks
00:18 +233: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_detail_view_test.dart: SurfaceStudioAtlasDetailView (Lot 56) 1. title Atlas Surface
00:19 +234: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_detail_view_test.dart: SurfaceStudioAtlasDetailView (Lot 56) 1. title Atlas Surface
00:19 +235: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 surface workspace renders one integrated assistant
00:19 +236: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 surface workspace renders one integrated assistant
00:19 +237: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 surface workspace renders one integrated assistant
00:19 +238: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 surface workspace renders one integrated assistant
00:19 +239: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 surface workspace renders one integrated assistant
00:19 +240: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 surface workspace renders one integrated assistant
00:19 +241: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 surface workspace renders one integrated assistant
00:19 +242: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 surface workspace renders one integrated assistant
00:19 +243: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 surface workspace renders one integrated assistant
00:19 +244: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/tiled_tsx_animation_browser_test.dart: TiledTsxAnimationBrowser models builds browser items from the 242 imported Pokemon SDK animations
00:19 +245: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_detail_view_test.dart: SurfaceStudioAtlasDetailView (Lot 56) 10. categoryId null
00:19 +246: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_detail_view_test.dart: SurfaceStudioAtlasDetailView (Lot 56) 10. categoryId null
00:19 +247: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:19 +248: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:19 +249: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:19 +250: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:19 +251: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:19 +252: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:19 +253: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:19 +254: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:19 +255: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:19 +256: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:19 +257: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:19 +258: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:19 +259: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:19 +260: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:19 +261: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:19 +262: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:19 +263: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:19 +264: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:19 +265: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:20 +266: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:20 +267: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:20 +268: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:20 +269: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:20 +270: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:20 +271: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:20 +272: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:20 +273: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:20 +274: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:20 +275: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:20 +276: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:20 +277: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:20 +278: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:20 +279: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:20 +280: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:20 +281: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/tiled_tsx_animation_browser_test.dart: TiledTsxAnimationBrowser widget searches by tile id in the browser UI
00:21 +282: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep then saveProjectManifest writes disk
00:21 +283: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep then saveProjectManifest writes disk
00:21 +284: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep then saveProjectManifest writes disk
00:21 +285: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep then saveProjectManifest writes disk
00:21 +286: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep then saveProjectManifest writes disk
00:21 +287: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep then saveProjectManifest writes disk
00:21 +288: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep then saveProjectManifest writes disk
00:21 +289: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep then saveProjectManifest writes disk
00:21 +290: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep then saveProjectManifest writes disk
00:21 +291: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep then saveProjectManifest writes disk
00:21 +292: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep then saveProjectManifest writes disk
00:21 +293: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep then saveProjectManifest writes disk
00:21 +294: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep then saveProjectManifest writes disk
00:21 +295: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep then saveProjectManifest writes disk
00:21 +296: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep then saveProjectManifest writes disk
00:21 +297: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep then saveProjectManifest writes disk
00:21 +298: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep then saveProjectManifest writes disk
00:21 +299: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep then saveProjectManifest writes disk
00:21 +300: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep then saveProjectManifest writes disk
00:21 +301: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep then saveProjectManifest writes disk
00:21 +302: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep then saveProjectManifest writes disk
00:21 +303: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep then saveProjectManifest writes disk
00:21 +304: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep then saveProjectManifest writes disk
00:21 +305: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep then saveProjectManifest writes disk
00:21 +306: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep then saveProjectManifest writes disk
EditorNotifier: saveProjectManifest()
FileProjectRepository: Validating and saving project to /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/map_editor_v21_save_fKOcBg/project.json
00:21 +307: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_role_mapping_editor_test.dart: editor lists roles, current animation and missing roles
00:22 +308: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:22 +309: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:22 +310: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:22 +311: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:22 +312: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:22 +313: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:22 +314: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:22 +315: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:22 +316: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:22 +317: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:22 +318: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:22 +319: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:22 +320: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:22 +321: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:22 +322: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:22 +323: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:23 +324: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/tiled_tsx_mistral_grouping_ui_test.dart: Mistral grouping button requires selection and configured key
00:23 +325: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/tiled_tsx_mistral_grouping_ui_test.dart: Mistral grouping button requires selection and configured key
00:23 +326: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/tiled_tsx_mistral_grouping_ui_test.dart: Mistral grouping button requires selection and configured key
00:23 +327: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/tiled_tsx_mistral_grouping_ui_test.dart: Mistral grouping button requires selection and configured key
00:23 +328: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/tiled_tsx_mistral_grouping_ui_test.dart: Mistral grouping button requires selection and configured key
00:23 +329: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/tiled_tsx_mistral_grouping_ui_test.dart: Mistral grouping button requires selection and configured key
00:23 +330: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/tiled_tsx_mistral_grouping_ui_test.dart: Mistral grouping button requires selection and configured key
00:23 +331: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/tiled_tsx_mistral_grouping_ui_test.dart: Mistral grouping button requires selection and configured key
00:23 +332: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/tiled_tsx_mistral_grouping_ui_test.dart: Mistral grouping button requires selection and configured key
00:23 +333: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/tiled_tsx_mistral_grouping_ui_test.dart: Mistral grouping button requires selection and configured key
00:24 +334: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Mistral analysis asks confirmation before any provider call
00:24 +335: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/tiled_tsx_mistral_grouping_ui_test.dart: Mistral grouping shows missing key message
00:24 +336: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: accepted Mistral suggestion updates mapping and live preview
00:24 +337: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/tiled_tsx_mistral_grouping_ui_test.dart: Mistral grouping requires confirmation, shows progress, then fills draft only after accept
00:24 +338: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/tiled_tsx_mistral_grouping_ui_test.dart: Mistral grouping requires confirmation, shows progress, then fills draft only after accept
00:24 +339: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/tiled_tsx_mistral_grouping_ui_test.dart: Mistral grouping requires confirmation, shows progress, then fills draft only after accept
00:24 +340: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_viewport_coordinate_test.dart: atlas viewport defaults to fitWidth for usable columns
00:25 +341: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart: atlas panel exposes zoom slider and column selection microcopy
00:25 +342: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart: atlas panel exposes zoom slider and column selection microcopy
00:25 +343: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart: atlas panel exposes zoom slider and column selection microcopy
00:25 +344: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart: atlas panel exposes zoom slider and column selection microcopy
00:25 +345: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart: atlas panel exposes zoom slider and column selection microcopy
00:25 +346: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart: atlas panel exposes zoom slider and column selection microcopy
00:25 +347: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart: atlas panel exposes zoom slider and column selection microcopy
00:26 +348: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart: atlas panel exposes zoom slider and column selection microcopy
00:26 +349: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart: atlas panel exposes zoom slider and column selection microcopy
00:26 +350: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart: atlas panel exposes zoom slider and column selection microcopy
00:26 +351: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart: atlas panel exposes zoom slider and column selection microcopy
00:26 +352: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart: atlas panel exposes zoom slider and column selection microcopy
00:26 +353: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_animation_detail_view_test.dart: SurfaceStudioAnimationDetailView (Lot 57) 1. title Animations Surface
00:26 +354: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_animation_detail_view_test.dart: SurfaceStudioAnimationDetailView (Lot 57) 1. title Animations Surface
00:26 +355: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_animation_detail_view_test.dart: SurfaceStudioAnimationDetailView (Lot 57) 1. title Animations Surface
00:26 +356: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_animation_detail_view_test.dart: SurfaceStudioAnimationDetailView (Lot 57) 1. title Animations Surface
00:26 +357: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_animation_detail_view_test.dart: SurfaceStudioAnimationDetailView (Lot 57) 1. title Animations Surface
00:26 +358: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_animation_detail_view_test.dart: SurfaceStudioAnimationDetailView (Lot 57) 2. empty: main message
00:26 +359: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_animation_detail_view_test.dart: SurfaceStudioAnimationDetailView (Lot 57) 3. empty: explainer
00:26 +360: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_animation_detail_view_test.dart: SurfaceStudioAnimationDetailView (Lot 57) 4. simple: name and id
00:26 +361: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_animation_detail_view_test.dart: SurfaceStudioAnimationDetailView (Lot 57) 5. simple: 1 frame
00:26 +362: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_animation_detail_view_test.dart: SurfaceStudioAnimationDetailView (Lot 57) 6. simple: total duration 120 ms
00:26 +363: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_animation_detail_view_test.dart: SurfaceStudioAnimationDetailView (Lot 57) 7. simple: referenced atlas
00:26 +364: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_animation_detail_view_test.dart: SurfaceStudioAnimationDetailView (Lot 57) 8. two referenced atlases order
00:26 +365: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_image_preview_layout_test.dart: SurfaceStudioAtlasImagePreview does not overflow in reported sizes
00:26 +366: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_image_preview_layout_test.dart: SurfaceStudioAtlasImagePreview does not overflow in reported sizes
00:27 +367: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_image_preview_layout_test.dart: SurfaceStudioAtlasImagePreview does not overflow in reported sizes
00:27 +368: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_image_preview_layout_test.dart: SurfaceStudioAtlasImagePreview does not overflow in reported sizes
00:27 +369: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_image_preview_layout_test.dart: SurfaceStudioAtlasImagePreview does not overflow in reported sizes
00:27 +370: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_image_preview_layout_test.dart: SurfaceStudioAtlasImagePreview does not overflow in reported sizes
00:27 +371: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_image_preview_layout_test.dart: SurfaceStudioAtlasImagePreview does not overflow in reported sizes
00:27 +372: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_image_preview_layout_test.dart: SurfaceStudioAtlasImagePreview does not overflow in reported sizes
00:27 +373: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_image_preview_layout_test.dart: SurfaceStudioAtlasImagePreview does not overflow in reported sizes
00:27 +374: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_image_preview_layout_test.dart: SurfaceStudioAtlasImagePreview does not overflow in reported sizes
00:27 +375: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_image_preview_layout_test.dart: SurfaceStudioAtlasImagePreview does not overflow in reported sizes
00:27 +376: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_image_preview_layout_test.dart: SurfaceStudioAtlasImagePreview does not overflow in reported sizes
00:27 +377: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_image_preview_layout_test.dart: SurfaceStudioAtlasImagePreview does not overflow in reported sizes
00:27 +378: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_image_preview_layout_test.dart: SurfaceStudioAtlasImagePreview does not overflow in reported sizes
00:27 +379: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_image_preview_layout_test.dart: SurfaceStudioAtlasImagePreview does not overflow in reported sizes
00:27 +380: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 1. browser shows title Catalogue Surface
00:27 +381: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 2. empty catalog: global empty message
00:27 +382: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 3. empty catalog: per-section empty lines
00:27 +383: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 4. minimal catalog: section headers visible
00:27 +384: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 5. minimal catalog: atlas details (736-tile grid)
00:27 +385: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 6. minimal catalog: animation details
00:27 +386: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 7. minimal catalog: preset details
00:27 +387: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 8. full animation: sync group and category
00:27 +388: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 9. atlas used by two animations
00:27 +389: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 10. atlas unused
00:27 +390: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 11. animation referenced atlas ids deduped order
00:27 +391: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 12. preset referenced animation ids deduped order
00:27 +392: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 13. preset roles source order
00:28 +393: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 14. atlas order preserved
00:28 +394: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 15. animation order preserved
00:28 +395: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 16. preset order preserved
00:28 +396: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 17. order is list order not sortOrder
00:28 +397: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 18. browser in scrollable ancestor
00:28 +398: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 19. no TextField in browser
00:28 +399: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 20. browser has no active edit affordances
00:28 +400: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 21. no internal type names in UI
00:28 +401: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 24. error read model builds without throw
00:28 +402: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 25. derived row fields drive display
00:28 +403: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 28. builds without ProviderScope
00:28 +404: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 29. accepts bounded width
00:28 +405: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 30. public map_core only (import smoke)
00:28 +406: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 45. Lot 57 — browser integrates Animation Detail
00:28 +407: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 46. Lot 57 — browser integrates Preset Detail
00:28 +408: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 47. Lot 57 — browser keeps Atlas Detail
00:28 +409: All tests passed!
````

## 11. Analyze

````text
cd packages/map_editor && flutter analyze lib/src/features/surface_studio lib/src/features/editor/application/editor_ai_settings.dart
````

Ligne finale exacte : `No issues found! (ran in 2.0s)`

Sortie complète :

````text
Analyzing 2 items...                                            
No issues found! (ran in 2.0s)
````

## 12. Non-Objectifs Confirmés

- Aucun `ProjectSurfacePreset` automatique à l’import TSX.
- Aucun mapping role -> animation automatique.
- Aucun rôle Surface deviné.
- Aucun appel Mistral pendant l’import.
- Aucun PixelLab / MCP / génération d’image.
- Aucun gameplay, `MapGameplayZone`, runtime Flame, map_runtime, map_gameplay ou map_battle modifié.
- Aucun `ProjectTilesetEntry` créé automatiquement.
- Aucun chemin Pokémon SDK hardcodé en production.
- Aucune sauvegarde disque automatique.

## 13. Limites Restantes

- QA interactive macOS complète non exécutée dans ce lot.
- Le matching imageSource reste V0 par basename ; une résolution plus riche par chemin projet pourra venir ensuite.
- L’image atlas n’est pas automatiquement créée comme tileset : l’utilisateur doit choisir un `ProjectTilesetEntry` existant.
- L’ergonomie fine du mapping rôle -> animation reste le sujet recommandé pour TSX-7.
- Deux fichiers Mistral ont un diff final `mistral-large-latest` -> `mistral-small-latest`; ce changement n’est pas requis par TSX-6.

## 14. Roadmap Suivante

TSX-7 — Improve TSX Role Mapping UX : dropdowns par rôle, previews dans les slots, filtrage sélectionné / non utilisé, meilleur workflow avant création du preset.

## 15. Git Status Final

````text
 M packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_mistral_grouping_suggester.dart
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_mistral_mapping_suggester.dart
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
 M packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
?? packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_catalog_append.dart
?? packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_workspace.dart
?? packages/map_editor/test/surface_studio/tiled_tsx_catalog_append_test.dart
?? packages/map_editor/test/surface_studio/tiled_tsx_import_ui_test.dart
?? packages/map_editor/test/surface_studio/tiled_tsx_workspace_tab_test.dart
?? reports/surface/surface_studio_tiled_tsx_workspace_import_v0.md
````

## 16. Git Diff Stat

````text
 .../tiled_tsx_mistral_grouping_suggester.dart      |   2 +-
 .../surface_studio_mistral_mapping_suggester.dart  |   2 +-
 .../surface_studio/surface_studio_panel.dart       | 219 ++++++++++++++++-----
 .../surface_studio/surface_studio_panel_test.dart  |   6 +-
 4 files changed, 178 insertions(+), 51 deletions(-)
````

## 17. Fichiers Créés / Modifiés / Supprimés

Créés :
- packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_catalog_append.dart
- packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_workspace.dart
- packages/map_editor/test/surface_studio/tiled_tsx_catalog_append_test.dart
- packages/map_editor/test/surface_studio/tiled_tsx_import_ui_test.dart
- packages/map_editor/test/surface_studio/tiled_tsx_workspace_tab_test.dart
- reports/surface/surface_studio_tiled_tsx_workspace_import_v0.md

Modifiés TSX-6 :
- packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
- packages/map_editor/test/surface_studio/surface_studio_panel_test.dart

Modifiés hors périmètre TSX-6 observés au statut final :
- packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_mistral_grouping_suggester.dart
- packages/map_editor/lib/src/features/surface_studio/surface_studio_mistral_mapping_suggester.dart

Supprimés : aucun.

Le rapport ne s’auto-inclut pas dans sa section de contenu afin d’éviter une inclusion récursive.

## 18. Contenu Complet des Fichiers Créés / Modifiés

### packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_catalog_append.dart

````dart
import 'package:map_core/map_core.dart';

final class TiledTsxCatalogAppendResult {
  const TiledTsxCatalogAppendResult({
    required this.catalog,
    required this.errors,
    this.warnings = const <String>[],
  });

  final ProjectSurfaceCatalog? catalog;
  final List<String> errors;
  final List<String> warnings;

  bool get hasErrors => errors.isNotEmpty;
}

TiledTsxCatalogAppendResult appendTiledTsxSurfaceImportToCatalog({
  required ProjectSurfaceCatalog catalog,
  required ProjectSurfaceAtlas atlas,
  required List<ProjectSurfaceAnimation> animations,
}) {
  final errors = <String>[];
  if (catalog.containsAtlas(atlas.id)) {
    errors.add('Atlas TSX déjà présent dans le catalogue : ${atlas.id}.');
  }
  for (final animation in animations) {
    if (catalog.containsAnimation(animation.id)) {
      errors.add(
        'Animation TSX déjà présente dans le catalogue : ${animation.id}.',
      );
    }
  }
  final incomingAnimationIds = <String>{};
  for (final animation in animations) {
    if (!incomingAnimationIds.add(animation.id)) {
      errors.add(
        'Animation TSX dupliquée dans l’import : ${animation.id}.',
      );
    }
  }
  if (errors.isNotEmpty) {
    return TiledTsxCatalogAppendResult(
      catalog: null,
      errors: List<String>.unmodifiable(errors),
    );
  }

  return TiledTsxCatalogAppendResult(
    catalog: ProjectSurfaceCatalog(
      atlases: [...catalog.atlases, atlas],
      animations: [...catalog.animations, ...animations],
      presets: catalog.presets,
    ),
    errors: const <String>[],
  );
}
````

### packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_workspace.dart

````dart
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show
        DropdownButton,
        DropdownMenuItem,
        ElevatedButton,
        Material,
        MaterialType;
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../../ui/shared/cupertino_editor_widgets.dart';
import 'tiled_tsx_animated_tileset_parser.dart';
import 'tiled_tsx_animation_browser.dart';
import 'tiled_tsx_catalog_append.dart';
import 'tiled_tsx_mistral_grouping_suggester.dart';
import 'tiled_tsx_surface_animation_importer.dart';

final class TiledTsxLoadedFile {
  const TiledTsxLoadedFile({
    required this.path,
    required this.fileName,
    required this.xml,
  });

  final String path;
  final String fileName;
  final String xml;
}

abstract interface class TiledTsxFileLoader {
  Future<TiledTsxLoadedFile?> pickAndLoadTsx();
}

final class TiledTsxPlatformFileLoader implements TiledTsxFileLoader {
  const TiledTsxPlatformFileLoader();

  @override
  Future<TiledTsxLoadedFile?> pickAndLoadTsx() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['tsx'],
      withData: false,
    );
    final path = picked?.files.single.path;
    if (path == null) {
      return null;
    }
    final xml = await File(path).readAsString();
    return TiledTsxLoadedFile(
      path: path,
      fileName: p.basename(path),
      xml: xml,
    );
  }
}

class TiledTsxWorkspace extends StatefulWidget {
  const TiledTsxWorkspace({
    super.key,
    required this.catalog,
    this.projectTilesets = const <ProjectTilesetEntry>[],
    this.onSurfaceCatalogChanged,
    this.fileLoader = const TiledTsxPlatformFileLoader(),
    this.atlasImageBytes,
    this.projectSettings,
    this.groupingSuggester,
  });

  final ProjectSurfaceCatalog catalog;
  final List<ProjectTilesetEntry> projectTilesets;
  final ValueChanged<ProjectSurfaceCatalog>? onSurfaceCatalogChanged;
  final TiledTsxFileLoader fileLoader;
  final Uint8List? atlasImageBytes;
  final ProjectSettings? projectSettings;
  final TiledTsxAnimationGroupingSuggester? groupingSuggester;

  @override
  State<TiledTsxWorkspace> createState() => _TiledTsxWorkspaceState();
}

class _TiledTsxWorkspaceState extends State<TiledTsxWorkspace> {
  TiledTsxLoadedFile? _loadedFile;
  TiledTsxTilesetAudit? _audit;
  ProjectTilesetEntry? _selectedTileset;
  ProjectSurfaceCatalog? _localCatalog;
  bool _loading = false;
  String? _statusMessage;
  List<String> _errors = const <String>[];

  @override
  void didUpdateWidget(covariant TiledTsxWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.catalog != oldWidget.catalog) {
      _localCatalog = null;
    }
    if (widget.projectTilesets != oldWidget.projectTilesets) {
      _selectedTileset = _pickMatchingTileset(_audit);
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    final effectiveCatalog = _localCatalog ?? widget.catalog;
    final atlas = _atlasForBrowser(effectiveCatalog);
    final animations = effectiveCatalog.animations;
    return SingleChildScrollView(
      key: const ValueKey('surface_studio.tsx_workspace'),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Workspace TSX',
            style: TextStyle(
              color: label,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Importez un fichier .tsx Tiled, choisissez l’image tileset PokeMap correspondante, puis parcourez les animations Surface produites.',
            style: TextStyle(color: subtle, fontSize: 13),
          ),
          const SizedBox(height: 14),
          _ImportSection(
            loadedFile: _loadedFile,
            audit: _audit,
            projectTilesets: widget.projectTilesets,
            selectedTileset: _selectedTileset,
            loading: _loading,
            statusMessage: _statusMessage,
            errors: _errors,
            onPickTsx: _pickTsx,
            onTilesetChanged: (tileset) {
              setState(() => _selectedTileset = tileset);
            },
            onConfirmImport: _canConfirmImport ? _confirmImport : null,
          ),
          const SizedBox(height: 14),
          if (animations.isEmpty)
            _TsxEmptyState(onImportPressed: _pickTsx)
          else
            TiledTsxAnimationBrowser(
              atlas: atlas,
              animations: animations,
              atlasImageBytes: widget.atlasImageBytes,
              sourceLabel: _loadedFile?.fileName ?? 'Catalogue de travail',
              catalog: effectiveCatalog,
              onSurfaceCatalogChanged: widget.onSurfaceCatalogChanged,
              projectSettings: widget.projectSettings,
              groupingSuggester: widget.groupingSuggester,
            ),
        ],
      ),
    );
  }

  bool get _canConfirmImport =>
      !_loading &&
      _audit != null &&
      _audit!.hasErrors == false &&
      _audit!.summary.animationCount > 0 &&
      _selectedTileset != null;

  Future<void> _pickTsx() async {
    setState(() {
      _loading = true;
      _statusMessage = null;
      _errors = const <String>[];
    });
    try {
      final loaded = await widget.fileLoader.pickAndLoadTsx();
      if (!mounted) {
        return;
      }
      if (loaded == null) {
        setState(() {
          _loading = false;
          _statusMessage = 'Import TSX annulé.';
        });
        return;
      }
      final audit = parseTiledTsxAnimatedTileset(loaded.xml);
      final errors = <String>[
        if (audit.hasErrors) 'Le fichier XML TSX est invalide ou incomplet.',
        if (!audit.hasErrors && audit.summary.animationCount == 0)
          'Le TSX ne contient aucune animation.',
        ...audit.diagnostics
            .where(
              (diagnostic) =>
                  diagnostic.severity == TiledTsxDiagnosticSeverity.error,
            )
            .map((diagnostic) => diagnostic.message),
      ];
      setState(() {
        _loadedFile = loaded;
        _audit = audit;
        _selectedTileset = _pickMatchingTileset(audit);
        _loading = false;
        _statusMessage = null;
        _errors = List<String>.unmodifiable(errors);
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _errors = ['Le fichier XML TSX est invalide ou incomplet.', '$error'];
      });
    }
  }

  void _confirmImport() {
    final audit = _audit;
    final tileset = _selectedTileset;
    if (audit == null || tileset == null) {
      return;
    }
    final prefix = _slugify(audit.summary.name);
    final imported = importTiledTsxSurfaceAnimations(
      audit: audit,
      options: TiledTsxSurfaceAnimationImportOptions(
        atlasId: prefix,
        tilesetId: tileset.id,
        animationIdPrefix: prefix,
        sortOrderBase: widget.catalog.animationCount,
      ),
    );
    if (imported.hasErrors || imported.atlas == null) {
      setState(() {
        _errors = imported.diagnostics
            .where(
              (diagnostic) =>
                  diagnostic.severity ==
                  TiledTsxSurfaceAnimationImportDiagnosticSeverity.error,
            )
            .map((diagnostic) => diagnostic.message)
            .toList(growable: false);
        _statusMessage = null;
      });
      return;
    }
    final appended = appendTiledTsxSurfaceImportToCatalog(
      catalog: _localCatalog ?? widget.catalog,
      atlas: imported.atlas!,
      animations: imported.animations,
    );
    if (appended.hasErrors || appended.catalog == null) {
      setState(() {
        _errors = appended.errors;
        _statusMessage = null;
      });
      return;
    }
    widget.onSurfaceCatalogChanged?.call(appended.catalog!);
    setState(() {
      _localCatalog = appended.catalog;
      _errors = const <String>[];
      _statusMessage =
          'Import TSX prêt : ${imported.animations.length} animations ajoutées.';
    });
  }

  ProjectTilesetEntry? _pickMatchingTileset(TiledTsxTilesetAudit? audit) {
    if (widget.projectTilesets.isEmpty) {
      return null;
    }
    final imageSource = audit?.summary.imageSource;
    if (imageSource != null && imageSource.isNotEmpty) {
      final expectedBasename = p.basename(imageSource).toLowerCase();
      for (final tileset in widget.projectTilesets) {
        if (p.basename(tileset.relativePath).toLowerCase() == expectedBasename) {
          return tileset;
        }
      }
    }
    return widget.projectTilesets.first;
  }
}

class _ImportSection extends StatelessWidget {
  const _ImportSection({
    required this.loadedFile,
    required this.audit,
    required this.projectTilesets,
    required this.selectedTileset,
    required this.loading,
    required this.statusMessage,
    required this.errors,
    required this.onPickTsx,
    required this.onTilesetChanged,
    required this.onConfirmImport,
  });

  final TiledTsxLoadedFile? loadedFile;
  final TiledTsxTilesetAudit? audit;
  final List<ProjectTilesetEntry> projectTilesets;
  final ProjectTilesetEntry? selectedTileset;
  final bool loading;
  final String? statusMessage;
  final List<String> errors;
  final VoidCallback onPickTsx;
  final ValueChanged<ProjectTilesetEntry?> onTilesetChanged;
  final VoidCallback? onConfirmImport;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    final border = EditorChrome.editorIslandRim(context);
    return Container(
      key: const ValueKey('tiled_tsx_workspace.import_section'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: EditorChrome.elevatedPanelBackground(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Importer un fichier TSX',
                      style: TextStyle(
                        color: label,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Les frames et durées viennent du fichier Tiled. Aucun preset Surface n’est créé à l’import.',
                      style: TextStyle(color: subtle, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                key: const ValueKey('tiled_tsx_workspace.import'),
                onPressed: loading ? null : onPickTsx,
                child: Text(loading ? 'Chargement…' : 'Importer un fichier TSX'),
              ),
            ],
          ),
          if (audit != null) ...[
            const SizedBox(height: 12),
            _TsxSummary(audit: audit!, loadedFile: loadedFile),
            const SizedBox(height: 12),
            _TilesetPicker(
              tilesets: projectTilesets,
              selectedTileset: selectedTileset,
              onChanged: onTilesetChanged,
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton(
                key: const ValueKey('tiled_tsx_workspace.confirm_import'),
                onPressed: onConfirmImport,
                child: const Text('Confirmer l’import TSX'),
              ),
            ),
          ],
          if (projectTilesets.isEmpty && audit != null) ...[
            const SizedBox(height: 10),
            const Text(
              'Ajoutez d’abord l’image comme tileset du projet, puis relancez l’import TSX.',
              style: TextStyle(
                color: CupertinoColors.systemOrange,
                fontSize: 12,
              ),
            ),
          ],
          if (statusMessage != null) ...[
            const SizedBox(height: 10),
            Text(
              statusMessage!,
              style: const TextStyle(
                color: CupertinoColors.systemGreen,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (errors.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text(
              'Erreur import TSX',
              style: TextStyle(
                color: CupertinoColors.systemRed,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            for (final error in errors)
              Text(
                error,
                style: const TextStyle(
                  color: CupertinoColors.systemRed,
                  fontSize: 12,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _TsxSummary extends StatelessWidget {
  const _TsxSummary({
    required this.audit,
    required this.loadedFile,
  });

  final TiledTsxTilesetAudit audit;
  final TiledTsxLoadedFile? loadedFile;

  @override
  Widget build(BuildContext context) {
    final s = audit.summary;
    return _InfoBlock(
      title: 'Résumé TSX',
      rows: [
        ('Fichier', loadedFile?.fileName ?? 'TSX'),
        ('name', s.name),
        ('tileWidth', '${s.tileWidth}'),
        ('tileHeight', '${s.tileHeight}'),
        ('columns', '${s.columns}'),
        ('tileCount', '${s.tileCount}'),
        ('imageSource', s.imageSource),
        ('imageWidth', '${s.imageWidth}'),
        ('imageHeight', '${s.imageHeight}'),
        ('animations', '${s.animationCount} animations'),
        ('transparentColor', s.transparentColor ?? 'aucune'),
      ],
    );
  }
}

class _TilesetPicker extends StatelessWidget {
  const _TilesetPicker({
    required this.tilesets,
    required this.selectedTileset,
    required this.onChanged,
  });

  final List<ProjectTilesetEntry> tilesets;
  final ProjectTilesetEntry? selectedTileset;
  final ValueChanged<ProjectTilesetEntry?> onChanged;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    if (tilesets.isEmpty) {
      return Text(
        'Aucun tileset image PokeMap disponible.',
        style: TextStyle(color: subtle, fontSize: 12),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choisir le tileset image correspondant',
          style: TextStyle(
            color: label,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Material(
          type: MaterialType.transparency,
          child: DropdownButton<ProjectTilesetEntry>(
            key: const ValueKey('tiled_tsx_workspace.tileset_picker'),
            value: selectedTileset,
            isExpanded: true,
            items: [
              for (final tileset in tilesets)
                DropdownMenuItem<ProjectTilesetEntry>(
                  value: tileset,
                  child: Text(
                    '${tileset.name} · ${tileset.id} · ${tileset.relativePath}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _TsxEmptyState extends StatelessWidget {
  const _TsxEmptyState({
    required this.onImportPressed,
  });

  final VoidCallback onImportPressed;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: EditorChrome.elevatedPanelBackground(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: EditorChrome.editorIslandRim(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aucune animation TSX importée.',
            style: TextStyle(
              color: label,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Importez un fichier .tsx pour générer des animations Surface depuis un tileset Tiled.',
            style: TextStyle(color: subtle, fontSize: 12),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            key: const ValueKey('tiled_tsx_workspace.empty_import'),
            onPressed: onImportPressed,
            child: const Text('Importer un fichier TSX'),
          ),
        ],
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({
    required this.title,
    required this.rows,
  });

  final String title;
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: EditorChrome.islandFillElevated(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: EditorChrome.editorIslandRim(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: label,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                children: [
                  SizedBox(
                    width: 130,
                    child: Text(
                      row.$1,
                      style: TextStyle(color: subtle, fontSize: 12),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      row.$2,
                      style: TextStyle(color: label, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

ProjectSurfaceAtlas? _atlasForBrowser(ProjectSurfaceCatalog catalog) {
  for (final animation in catalog.animations) {
    final frames = animation.timeline.frames;
    if (frames.isEmpty) {
      continue;
    }
    final atlas = catalog.atlasById(frames.first.tileRef.atlasId);
    if (atlas != null) {
      return atlas;
    }
  }
  return catalog.atlases.isEmpty ? null : catalog.atlases.first;
}

String _slugify(String value) {
  final lower = value.trim().toLowerCase();
  final slug = lower
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return slug.isEmpty ? 'tsx-import' : slug;
}
````

### packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart

````dart
// Surface Studio — assistant premium de mapping d'atlas.
//
// Le viewport principal porte un seul workflow guide moderne. Les anciennes
// briques utiles restent accessibles dans le drawer avance, sans second
// Surface Studio rendu sous l'assistant.

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';

import '../../ui/shared/cupertino_editor_widgets.dart';
import 'importers/tiled_tsx_animation_browser.dart';
import 'importers/tiled_tsx_workspace.dart';
import 'surface_studio_atlas_editing.dart';
import 'surface_studio_atlas_image_preview.dart';
import 'surface_studio_catalog_browser.dart';
import 'surface_studio_diagnostics_view.dart';
import 'surface_studio_paintable_surfaces_panel.dart';
import 'surface_studio_preset_editor_controller.dart';
import 'surface_studio_ai_mapping_suggester.dart';
import 'surface_studio_role_mapping_editor.dart';
import 'surface_studio_selection.dart';
import 'surface_studio_selection_inspector.dart';
import 'surface_studio_selection_summary.dart';
import 'surface_studio_screen.dart';

SurfaceStudioSelection _selectionValidInReadModel(
  SurfaceStudioReadModel rm,
  SurfaceStudioSelection sel,
) {
  if (sel.isNone) return sel;
  if (sel.isAtlas) {
    for (final row in rm.atlases) {
      if (row.id == sel.id) return sel;
    }
  } else if (sel.isAnimation) {
    for (final row in rm.animations) {
      if (row.id == sel.id) return sel;
    }
  } else if (sel.isPreset) {
    for (final row in rm.presets) {
      if (row.id == sel.id) return sel;
    }
  }
  return const SurfaceStudioSelection.none();
}

/// Accent produit Surface Studio (même base que la tuile World Explorer).
const Color _surfaceStudioAccent = Color(0xFF2DD4BF);

enum _SurfaceStudioPrimaryWorkspace {
  catalogue,
  tsx,
  diagnostics,
}

/// Panneau présentationnel **lecture seule** pour Surface Studio.
class SurfaceStudioPanel extends StatefulWidget {
  const SurfaceStudioPanel({
    super.key,
    required this.readModel,
    this.onSurfaceCatalogSaveRequested,
    this.onRequestProjectSave,
    this.projectTilesets,
    this.projectRootPath,
    this.projectSettings,
    this.surfaceMappingImageLoader,
    this.aiMappingSuggester,
    this.tsxFileLoader = const TiledTsxPlatformFileLoader(),
  });

  final SurfaceStudioReadModel readModel;
  final ValueChanged<ProjectSurfaceCatalog>? onSurfaceCatalogSaveRequested;
  final Future<bool> Function()? onRequestProjectSave;
  final List<ProjectTilesetEntry>? projectTilesets;
  final ProjectSettings? projectSettings;
  final SurfaceStudioAtlasUiImageLoader? surfaceMappingImageLoader;
  final SurfaceStudioAiMappingSuggester? aiMappingSuggester;
  final TiledTsxFileLoader tsxFileLoader;

  /// Racine projet sur disque pour résoudre les chemins d’images tileset (aperçu Lot 72).
  final String? projectRootPath;

  static const String titleText = 'Surface Studio';
  static const String readOnlyBadgeText = 'Lecture seule';
  static const String partialAuthoringBadgeText = 'Édition partielle';
  static const String workflowStepsHintText =
      'Étapes : atlas → grille → animations → surfaces prêtes à peindre';
  static const String productDescriptionText =
      'Créer des surfaces peintes à partir d’un atlas, étape par étape.';
  static const String placeholderActionsTitle = 'Actions auteur';
  static const String placeholderSoonText = 'Bientôt';
  static const String actionImportVerticalAtlasLabel =
      'Importer un atlas vertical';
  static const String workCatalogDirtyStateText =
      'Catalogue de travail modifié — sauvegarde projet non effectuée.';
  static const String savePrepActionLabel =
      'Préparer la sauvegarde du catalogue Surface';
  static const String savePrepTransmittedNote =
      'Catalogue de travail transmis au parent.';
  static const String savePrepNotConnectedNote =
      'Sauvegarde non connectée dans ce contexte.';
  static const String savePrepNoDiskNote =
      'Aucune écriture disque ne sera effectuée par Surface Studio.';
  static const String manifestMemoryUpdatedNote =
      'Manifest projet mis à jour en mémoire — écriture disque non effectuée.';
  static const String projectSaveViaExistingFlowButtonLabel =
      'Sauvegarder le projet via le flux existant';
  static const String projectDiskSaveResultSuccessNote =
      'Projet sauvegardé via le flux projet existant.';
  static const String projectDiskSaveRequestedNote =
      'Sauvegarde projet demandée.';
  static const String projectDiskSaveFailureNote =
      'Échec de sauvegarde projet — voir la barre d’état.';

  @override
  State<SurfaceStudioPanel> createState() => _SurfaceStudioPanelState();
}

class _SurfaceStudioPanelState extends State<SurfaceStudioPanel> {
  /// Sélection d’inspection : locale au widget, jamais écrite dans le manifest.
  SurfaceStudioSelection _selection = const SurfaceStudioSelection.none();
  _SurfaceStudioPrimaryWorkspace _primaryWorkspace =
      _SurfaceStudioPrimaryWorkspace.catalogue;
  late SurfaceStudioReadModel _workReadModel;
  String? _saveFlowPrepNote;
  String? _projectSaveDiskNote;
  int _atlasEditSignal = 0;
  String? _tsxBrowserImagePath;
  Uint8List? _tsxBrowserImageBytes;

  @override
  void initState() {
    super.initState();
    _workReadModel = widget.readModel;
  }

  @override
  void didUpdateWidget(covariant SurfaceStudioPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.readModel != oldWidget.readModel) {
      final hadDirty = _workReadModel != oldWidget.readModel;
      final absNow = widget.readModel ==
          buildSurfaceStudioReadModelFromCatalog(_workReadModel.catalog);
      final wasAbsorbed = hadDirty && absNow;
      setState(() {
        _workReadModel = widget.readModel;
        _selection = _selectionValidInReadModel(_workReadModel, _selection);
        _saveFlowPrepNote =
            wasAbsorbed ? SurfaceStudioPanel.manifestMemoryUpdatedNote : null;
      });
    }
  }

  bool get _hasWorkCatalogChanges => _workReadModel != widget.readModel;

  void _bumpAtlasEditSignal() {
    setState(() => _atlasEditSignal += 1);
  }

  void _onConfirmDeleteSelectedAtlas() {
    final id = _selection.id;
    if (id == null || !_selection.isAtlas) {
      return;
    }
    try {
      final next = removeAtlasIdFromWorkCatalog(_workReadModel.catalog, id);
      setState(() {
        _saveFlowPrepNote = null;
        _workReadModel = buildSurfaceStudioReadModelFromCatalog(next);
        _selection = const SurfaceStudioSelection.none();
      });
    } on StateError {
      return;
    }
  }

  SurfaceStudioSelection _selectionAfterCatalogChanged(
    ProjectSurfaceCatalog cat,
  ) {
    if (_selection.isAtlas) {
      final sid = _selection.id;
      if (sid != null) {
        for (final a in cat.atlases) {
          if (a.id == sid) {
            return SurfaceStudioSelection.atlas(sid);
          }
        }
        return const SurfaceStudioSelection.none();
      }
    }
    if (_selection.isAnimation) {
      final sid = _selection.id;
      if (sid != null) {
        for (final a in cat.animations) {
          if (a.id == sid) {
            return SurfaceStudioSelection.animation(sid);
          }
        }
        return const SurfaceStudioSelection.none();
      }
    }
    if (_selection.isPreset) {
      final sid = _selection.id;
      if (sid != null) {
        for (final p in cat.presets) {
          if (p.id == sid) {
            return SurfaceStudioSelection.preset(sid);
          }
        }
        return const SurfaceStudioSelection.none();
      }
    }
    if (cat.atlases.isNotEmpty) {
      return SurfaceStudioSelection.atlas(cat.atlases.last.id);
    }
    return const SurfaceStudioSelection.none();
  }

  void _onSurfaceCatalogSavePrep() {
    final cb = widget.onSurfaceCatalogSaveRequested;
    if (cb == null) {
      return;
    }
    cb(_workReadModel.catalog);
    setState(() {
      _saveFlowPrepNote = SurfaceStudioPanel.savePrepTransmittedNote;
    });
  }

  Future<void> _onRequestProjectSave() async {
    final fn = widget.onRequestProjectSave;
    if (fn == null) {
      return;
    }
    setState(() {
      _projectSaveDiskNote = SurfaceStudioPanel.projectDiskSaveRequestedNote;
    });
    final ok = await fn();
    if (!mounted) {
      return;
    }
    setState(() {
      _projectSaveDiskNote = ok
          ? SurfaceStudioPanel.projectDiskSaveResultSuccessNote
          : SurfaceStudioPanel.projectDiskSaveFailureNote;
    });
  }

  ProjectSurfacePreset? _selectedWorkPreset() {
    final id = _selection.id;
    if (id == null || !_selection.isPreset) {
      return null;
    }
    return _workReadModel.catalog.presetById(id);
  }

  void _selectPreset(String presetId) {
    setState(() {
      _selection = SurfaceStudioSelection.preset(presetId);
    });
  }

  void _onPresetRoleAnimationChanged(
    SurfaceVariantRole role,
    String animationId,
  ) {
    final presetId = _selection.id;
    if (presetId == null || !_selection.isPreset) {
      return;
    }
    final next = surfaceStudioReplacePresetRoleAnimation(
      catalog: _workReadModel.catalog,
      presetId: presetId,
      role: role,
      animationId: animationId,
    );
    setState(() {
      _saveFlowPrepNote = null;
      _workReadModel = buildSurfaceStudioReadModelFromCatalog(next);
      _selection = SurfaceStudioSelection.preset(presetId);
    });
  }

  Future<void> _openPresetMappingEditor(String presetId) async {
    final preset = _workReadModel.catalog.presetById(presetId);
    if (preset == null) {
      return;
    }
    setState(() {
      _selection = SurfaceStudioSelection.preset(presetId);
    });
    await showMacosSheet<void>(
      context: context,
      builder: (ctx) => Center(
        child: MacosSheet(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: SizedBox(
              key: const ValueKey('surface_mapping_editor_sheet'),
              width: 1120,
              height: 760,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Surface Mapping Editor',
                          style: editorMacosSheetTitleStyle(ctx),
                        ),
                      ),
                      PushButton(
                        key: const ValueKey('surface_mapping_editor_close'),
                        controlSize: ControlSize.large,
                        secondary: true,
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Fermer'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Étape 1 : choisissez un slot visuel. Étape 2 : cliquez directement une colonne dans l’atlas réel.',
                    style: TextStyle(
                      color: _surfaceStudioAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: SingleChildScrollView(
                      child: SurfaceStudioRoleMappingEditor(
                        catalog: _workReadModel.catalog,
                        preset: preset,
                        projectRootPath: widget.projectRootPath,
                        projectTilesets: widget.projectTilesets ??
                            const <ProjectTilesetEntry>[],
                        imageLoader: widget.surfaceMappingImageLoader,
                        onRoleAnimationChanged: _onPresetRoleAnimationChanged,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onSurfaceCatalogChanged(ProjectSurfaceCatalog cat) {
    setState(() {
      _saveFlowPrepNote = null;
      _workReadModel = buildSurfaceStudioReadModelFromCatalog(cat);
      _selection = _selectionAfterCatalogChanged(cat);
    });
  }

  ProjectSurfaceAtlas? _atlasForAnimationBrowser() {
    for (final animation in _workReadModel.catalog.animations) {
      final frames = animation.timeline.frames;
      if (frames.isEmpty) {
        continue;
      }
      final atlas = _workReadModel.catalog.atlasById(
        frames.first.tileRef.atlasId,
      );
      if (atlas != null) {
        return atlas;
      }
    }
    return _workReadModel.catalog.atlases.isEmpty
        ? null
        : _workReadModel.catalog.atlases.first;
  }

  Uint8List? _atlasImageBytesForBrowser(ProjectSurfaceAtlas? atlas) {
    if (atlas == null) {
      _tsxBrowserImagePath = null;
      _tsxBrowserImageBytes = null;
      return null;
    }
    final resolution = resolveSurfaceStudioAtlasImagePreview(
      projectRootPath: widget.projectRootPath,
      projectTilesets: widget.projectTilesets ?? const <ProjectTilesetEntry>[],
      technicalTilesetId: atlas.tilesetId,
    );
    final path = resolution.resolvedAbsolutePath;
    if (path == null || path.isEmpty) {
      _tsxBrowserImagePath = null;
      _tsxBrowserImageBytes = null;
      return null;
    }
    if (_tsxBrowserImagePath == path && _tsxBrowserImageBytes != null) {
      return _tsxBrowserImageBytes;
    }
    try {
      final bytes = File(path).readAsBytesSync();
      _tsxBrowserImagePath = path;
      _tsxBrowserImageBytes = bytes;
      return bytes;
    } catch (_) {
      _tsxBrowserImagePath = path;
      _tsxBrowserImageBytes = null;
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final canMutateCatalog = widget.onSurfaceCatalogSaveRequested != null;
    final inspection = Column(
      key: const ValueKey('surface_studio_inspection_column'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SurfaceStudioSelectionSummary(selection: _selection),
        const SizedBox(height: 10),
        SurfaceStudioSelectionInspector(
          readModel: _workReadModel,
          selection: _selection,
          onRequestEditSelectedAtlas:
              canMutateCatalog ? _bumpAtlasEditSignal : null,
          onConfirmDeleteSelectedAtlas:
              canMutateCatalog ? _onConfirmDeleteSelectedAtlas : null,
        ),
      ],
    );
    final selectedPreset = _selectedWorkPreset();
    final paintableSurfaces = SurfaceStudioPaintableSurfacesPanel(
      readModel: _workReadModel,
      selectedPresetId: selectedPreset?.id,
      onPresetSelected: _selectPreset,
      onEditMappingPressed: canMutateCatalog ? _openPresetMappingEditor : null,
      onSaveCatalogPressed: widget.onSurfaceCatalogSaveRequested != null
          ? _onSurfaceCatalogSavePrep
          : null,
    );
    final tsxBrowserAtlas = _atlasForAnimationBrowser();
    Widget buildAdvancedDetails() {
      return _AdvancedDetailsSection(
        inspection: inspection,
        browser: SurfaceStudioCatalogBrowser(
          readModel: _workReadModel,
          selection: _selection,
          onSelectionChanged: (v) {
            setState(() => _selection = v);
          },
        ),
        tsxAnimations: TiledTsxAnimationBrowser(
          atlas: tsxBrowserAtlas,
          animations: _workReadModel.catalog.animations,
          atlasImageBytes: _atlasImageBytesForBrowser(tsxBrowserAtlas),
          sourceLabel: 'Catalogue de travail',
          catalog: _workReadModel.catalog,
          projectSettings: widget.projectSettings,
          onSurfaceCatalogChanged: _onSurfaceCatalogChanged,
        ),
        diagnostics: SurfaceStudioDiagnosticsView(readModel: _workReadModel),
        futureActions: paintableSurfaces,
        placeholder: const _SectionPlaceholder(
          title: SurfaceStudioPanel.placeholderActionsTitle,
        ),
      );
    }

    final advancedDrawer = SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: buildAdvancedDetails(),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final shellWidth =
            constraints.hasBoundedWidth ? constraints.maxWidth : 1600.0;
        final shellHeight =
            constraints.hasBoundedHeight ? constraints.maxHeight : 900.0;
        final tsxWorkspaceAtlas = _atlasForAnimationBrowser();
        final content = switch (_primaryWorkspace) {
          _SurfaceStudioPrimaryWorkspace.catalogue => SurfaceStudioScreen(
              readModel: _workReadModel,
              projectSettings: widget.projectSettings,
              projectTilesets: widget.projectTilesets ?? const [],
              projectRootPath: widget.projectRootPath,
              surfaceMappingImageLoader: widget.surfaceMappingImageLoader,
              hasWorkCatalogChanges: _hasWorkCatalogChanges,
              saveFlowPrepNote: _saveFlowPrepNote,
              projectSaveDiskNote: _projectSaveDiskNote,
              onSurfaceCatalogChanged: _onSurfaceCatalogChanged,
              onWorkCatalogAnimationsCreated: (createdIds) {
                if (createdIds.isEmpty) {
                  return;
                }
                setState(() {
                  _selection =
                      SurfaceStudioSelection.animation(createdIds.first);
                });
              },
              onWorkCatalogPresetCreated: (presetId) {
                if (presetId.isEmpty) {
                  return;
                }
                setState(() {
                  _selection = SurfaceStudioSelection.preset(presetId);
                });
              },
              onResetWorkCatalog: () {
                setState(() {
                  _workReadModel = widget.readModel;
                  _selection =
                      _selectionValidInReadModel(_workReadModel, _selection);
                  _saveFlowPrepNote = null;
                });
              },
              onSurfaceCatalogSavePrep:
                  widget.onSurfaceCatalogSaveRequested == null
                      ? null
                      : _onSurfaceCatalogSavePrep,
              onRequestProjectSave: widget.onRequestProjectSave == null
                  ? null
                  : _onRequestProjectSave,
              advancedDrawer: advancedDrawer,
              aiMappingSuggester: widget.aiMappingSuggester,
            ),
          _SurfaceStudioPrimaryWorkspace.tsx => TiledTsxWorkspace(
              catalog: _workReadModel.catalog,
              projectTilesets: widget.projectTilesets ?? const [],
              onSurfaceCatalogChanged: _onSurfaceCatalogChanged,
              fileLoader: widget.tsxFileLoader,
              atlasImageBytes: _atlasImageBytesForBrowser(tsxWorkspaceAtlas),
              projectSettings: widget.projectSettings,
            ),
          _SurfaceStudioPrimaryWorkspace.diagnostics => SingleChildScrollView(
              key: const ValueKey('surface_studio.diagnostics_workspace'),
              padding: const EdgeInsets.all(14),
              child: buildAdvancedDetails(),
            ),
        };
        return SizedBox(
          width: shellWidth,
          height: shellHeight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SurfaceStudioPrimaryTabs(
                selected: _primaryWorkspace,
                onSelected: (workspace) {
                  setState(() => _primaryWorkspace = workspace);
                },
              ),
              Expanded(child: content),
            ],
          ),
        );
      },
    );
  }
}

class _SurfaceStudioPrimaryTabs extends StatelessWidget {
  const _SurfaceStudioPrimaryTabs({
    required this.selected,
    required this.onSelected,
  });

  final _SurfaceStudioPrimaryWorkspace selected;
  final ValueChanged<_SurfaceStudioPrimaryWorkspace> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('surface_studio.primary_tabs'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      color: EditorChrome.appBackground(context),
      child: Row(
        children: [
          _SurfaceStudioPrimaryTabButton(
            key: const ValueKey('surface_studio.tab.catalogue'),
            label: 'Catalogue Surface',
            selected: selected == _SurfaceStudioPrimaryWorkspace.catalogue,
            onPressed: () =>
                onSelected(_SurfaceStudioPrimaryWorkspace.catalogue),
          ),
          const SizedBox(width: 8),
          _SurfaceStudioPrimaryTabButton(
            key: const ValueKey('surface_studio.tab.tsx'),
            label: 'TSX',
            selected: selected == _SurfaceStudioPrimaryWorkspace.tsx,
            onPressed: () => onSelected(_SurfaceStudioPrimaryWorkspace.tsx),
          ),
          const SizedBox(width: 8),
          _SurfaceStudioPrimaryTabButton(
            key: const ValueKey('surface_studio.tab.diagnostics'),
            label: 'Diagnostics',
            selected: selected == _SurfaceStudioPrimaryWorkspace.diagnostics,
            onPressed: () =>
                onSelected(_SurfaceStudioPrimaryWorkspace.diagnostics),
          ),
        ],
      ),
    );
  }
}

class _SurfaceStudioPrimaryTabButton extends StatelessWidget {
  const _SurfaceStudioPrimaryTabButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? _surfaceStudioAccent.withValues(alpha: 0.2)
        : EditorChrome.elevatedPanelBackground(context);
    final textColor =
        selected ? _surfaceStudioAccent : EditorChrome.primaryLabel(context);
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      color: color,
      borderRadius: BorderRadius.circular(9),
      onPressed: onPressed,
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 13,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
        ),
      ),
    );
  }
}

class _AdvancedDetailsSection extends StatelessWidget {
  const _AdvancedDetailsSection({
    required this.inspection,
    required this.browser,
    required this.tsxAnimations,
    required this.diagnostics,
    required this.futureActions,
    required this.placeholder,
  });

  final Widget inspection;
  final Widget browser;
  final Widget tsxAnimations;
  final Widget diagnostics;
  final Widget futureActions;
  final Widget placeholder;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);

    return _StudioCard(
      key: const ValueKey('surface_studio_advanced_details'),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Détails avancés',
            style: TextStyle(
              color: label,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Catalogue, inspection et diagnostics restent disponibles sans remplacer le workflow principal.',
            style: TextStyle(color: subtle, fontSize: 11.5, height: 1.35),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, c) {
              if (c.maxWidth >= 960) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: inspection),
                    const SizedBox(width: 12),
                    Expanded(child: browser),
                    const SizedBox(width: 12),
                    Expanded(child: diagnostics),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  inspection,
                  const SizedBox(height: 12),
                  browser,
                  const SizedBox(height: 12),
                  diagnostics,
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          tsxAnimations,
          const SizedBox(height: 12),
          futureActions,
          const SizedBox(height: 10),
          placeholder,
        ],
      ),
    );
  }
}

/// Carte interne : même relief que les tuiles inspecteur / sections.
class _StudioCard extends StatelessWidget {
  const _StudioCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: EditorChrome.elevatedPanelBackground(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: EditorChrome.editorIslandRim(context),
          width: 1,
        ),
        boxShadow: EditorChrome.sectionCardShadows(context),
      ),
      child: child,
    );
  }
}

class _SectionPlaceholder extends StatelessWidget {
  const _SectionPlaceholder({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);

    return _StudioCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: label,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  SurfaceStudioPanel.placeholderSoonText,
                  style: TextStyle(
                    color: subtle,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          MacosIcon(
            CupertinoIcons.chevron_right,
            size: 16,
            color: subtle,
          ),
        ],
      ),
    );
  }
}

/// Adaptateur : construit le read model **sans** I/O à partir d’un [ProjectManifest].
class SurfaceStudioPanelFromManifest extends StatefulWidget {
  const SurfaceStudioPanelFromManifest({
    super.key,
    required this.manifest,
    this.onProjectManifestChanged,
    this.onRequestProjectSave,
    this.projectRootPath,
  });

  final ProjectManifest manifest;
  final ValueChanged<ProjectManifest>? onProjectManifestChanged;
  final Future<bool> Function()? onRequestProjectSave;

  /// Dossier projet ouvert (même source que l’éditeur) pour résoudre les fichiers image.
  final String? projectRootPath;

  @override
  State<SurfaceStudioPanelFromManifest> createState() =>
      _SurfaceStudioPanelFromManifestState();
}

class _SurfaceStudioPanelFromManifestState
    extends State<SurfaceStudioPanelFromManifest> {
  late ProjectManifest _manifest;

  @override
  void initState() {
    super.initState();
    _manifest = widget.manifest;
  }

  @override
  void didUpdateWidget(covariant SurfaceStudioPanelFromManifest oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.manifest != oldWidget.manifest) {
      setState(() {
        _manifest = widget.manifest;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SurfaceStudioPanel(
      readModel: buildSurfaceStudioReadModel(_manifest),
      projectSettings: _manifest.settings,
      projectTilesets: _manifest.tilesets,
      projectRootPath: widget.projectRootPath,
      onSurfaceCatalogSaveRequested: (c) {
        final n = replaceProjectManifestSurfaceCatalog(_manifest, c);
        setState(() {
          _manifest = n;
        });
        widget.onProjectManifestChanged?.call(n);
      },
      onRequestProjectSave: widget.onRequestProjectSave,
    );
  }
}
````

### packages/map_editor/test/surface_studio/surface_studio_panel_test.dart

````dart
// Surface Studio V2.1 panel tests.
//
// These assertions intentionally replace the old Lot 52-69 panel expectations:
// the catalog browser, diagnostics and paintable-surface panels still exist, but
// they must no longer render as a second Surface Studio under the wizard.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show MaterialApp;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_panel.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_workflow_layout.dart';

import 'surface_studio_rebuild_test_harness.dart';

void main() {
  group('SurfaceStudioPanel V2.1', () {
    testWidgets('renders one wizard and no legacy workflow underneath',
        (tester) async {
      await pumpSurfaceStudioForTest(tester);
      await tester.pump();

      expect(find.byKey(const Key('surfaceStudio.shell')), findsOneWidget);
      expect(
        find.text('Surface Studio — Assistant de mapping d’atlas'),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('surface_studio_legacy_authoring_bridge')),
        findsNothing,
      );
      expect(find.byType(SurfaceStudioWorkflowLayout), findsNothing);
      expect(find.text('Assistant de création'), findsNothing);
      expect(find.byKey(const Key('surface_studio.primary_tabs')), findsOne);
      expect(find.text('Catalogue Surface'), findsOneWidget);
      expect(find.text('TSX'), findsOneWidget);
      expect(find.text('Diagnostics Surface'), findsNothing);
    });

    testWidgets('keeps catalog and diagnostics in the advanced drawer',
        (tester) async {
      await pumpSurfaceStudioForTest(tester);
      await tester.pump();

      await tester.tap(find.byIcon(CupertinoIcons.gear_alt));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('surfaceStudio.advanced.drawer')),
        findsOneWidget,
      );
      expect(find.text('Catalogue & diagnostics'), findsOneWidget);
      expect(find.text('Détails avancés'), findsOneWidget);
      expect(find.text('Catalogue Surface'), findsWidgets);
      expect(find.text('Animations TSX importées'), findsOneWidget);
      expect(find.text('Diagnostics Surface'), findsOneWidget);
      expect(find.text('Surfaces prêtes à peindre'), findsOneWidget);
    });

    testWidgets(
        'SurfaceStudioPanelFromManifest saves the work catalog by action',
        (tester) async {
      ProjectManifest? changedManifest;
      await pumpSurfaceStudioPanelFromManifest(
        tester,
        manifest: _manifest(ProjectSurfaceCatalog()),
        onProjectManifestChanged: (manifest) => changedManifest = manifest,
      );
      await tester.pump();

      await tester.enterText(
        find.byKey(const Key('surfaceStudio.import.atlasId')),
        'v21-atlas',
      );
      await tester.enterText(
        find.byKey(const Key('surfaceStudio.import.atlasName')),
        'V2.1 Atlas',
      );
      await tester.enterText(
        find.byKey(const Key('surfaceStudio.import.tilesetId')),
        'tiles',
      );
      await tester
          .tap(find.byKey(const Key('surfaceStudio.import.createAtlas')));
      await tester.pump();

      expect(
        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
        findsOneWidget,
      );
      expect(changedManifest, isNull);

      await tester
          .tap(find.byKey(const Key('surfaceStudio.action.saveCatalog')));
      await tester.pump();

      expect(changedManifest, isNotNull);
      expect(
        changedManifest!.surfaceCatalog.atlases.map((atlas) => atlas.id),
        contains('v21-atlas'),
      );
    });

    testWidgets('SurfaceStudioPanel still builds without ProviderScope',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 1800,
            height: 1000,
            child: SurfaceStudioPanel(
              readModel: buildSurfaceStudioReadModelFromCatalog(_catalog()),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('surfaceStudio.shell')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

Future<void> pumpSurfaceStudioPanelFromManifest(
  WidgetTester tester, {
  required ProjectManifest manifest,
  ValueChanged<ProjectManifest>? onProjectManifestChanged,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(2048, 1120);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    MaterialApp(
      home: SizedBox(
        width: 2048,
        height: 1120,
        child: SurfaceStudioPanelFromManifest(
          manifest: manifest,
          projectRootPath: '/missing/project',
          onProjectManifestChanged: onProjectManifestChanged,
        ),
      ),
    ),
  );
}

ProjectManifest _manifest(ProjectSurfaceCatalog catalog) {
  return ProjectManifest(
    name: 'Test',
    maps: const [],
    tilesets: const [
      ProjectTilesetEntry(
        id: 'tiles',
        name: 'Tiles',
        relativePath: 'missing/tiles.png',
      ),
    ],
    surfaceCatalog: catalog,
  );
}

ProjectSurfaceCatalog _catalog() {
  const atlasId = 'water-atlas';
  final animation = ProjectSurfaceAnimation(
    id: 'water-col-0',
    name: 'Water Column 0',
    timeline: SurfaceAnimationTimeline(
      frames: [
        SurfaceAnimationFrame(
          tileRef: SurfaceAtlasTileRef(
            atlasId: atlasId,
            column: 0,
            row: 0,
          ),
          durationMs: 120,
        ),
      ],
    ),
    syncGroupId: atlasId,
  );
  return ProjectSurfaceCatalog(
    atlases: [
      ProjectSurfaceAtlas(
        id: atlasId,
        name: 'Water Atlas',
        tilesetId: 'tiles',
        geometry: SurfaceAtlasGeometry(
          tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
          gridSize: SurfaceAtlasGridSize(columns: 12, rows: 32),
          layout: SurfaceAtlasLayout.grid,
        ),
      ),
    ],
    animations: [animation],
    presets: [
      ProjectSurfacePreset(
        id: 'water',
        name: 'Water Surface',
        variantAnimations: SurfaceVariantAnimationRefSet(
          refs: [
            SurfaceVariantAnimationRef(
              role: SurfaceVariantRole.isolated,
              animationId: 'water-col-0',
            ),
          ],
        ),
      ),
    ],
  );
}
````

### packages/map_editor/test/surface_studio/tiled_tsx_catalog_append_test.dart

````dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_studio/importers/tiled_tsx_catalog_append.dart';

void main() {
  group('appendTiledTsxSurfaceImportToCatalog', () {
    test('adds atlas and animations to an empty catalog without presets', () {
      final result = appendTiledTsxSurfaceImportToCatalog(
        catalog: ProjectSurfaceCatalog(),
        atlas: _atlas('tech-animations'),
        animations: [_animation('tech-animations-tile-99')],
      );

      expect(result.hasErrors, isFalse);
      expect(result.catalog, isNotNull);
      expect(result.catalog!.atlasCount, 1);
      expect(result.catalog!.animationCount, 1);
      expect(result.catalog!.presetCount, 0);
      expect(result.catalog!.containsAtlas('tech-animations'), isTrue);
      expect(
        result.catalog!.containsAnimation('tech-animations-tile-99'),
        isTrue,
      );
    });

    test('preserves existing presets and never creates a preset', () {
      final preset = _preset('existing-water');
      final catalog = ProjectSurfaceCatalog(
        atlases: [_atlas('existing-atlas')],
        animations: [_animation('existing-animation')],
        presets: [preset],
      );

      final result = appendTiledTsxSurfaceImportToCatalog(
        catalog: catalog,
        atlas: _atlas('tech-animations'),
        animations: [_animation('tech-animations-tile-99')],
      );

      expect(result.hasErrors, isFalse);
      expect(result.catalog!.atlases.map((atlas) => atlas.id), [
        'existing-atlas',
        'tech-animations',
      ]);
      expect(result.catalog!.animations.map((animation) => animation.id), [
        'existing-animation',
        'tech-animations-tile-99',
      ]);
      expect(result.catalog!.presets, [preset]);
      expect(result.catalog!.presetCount, 1);
    });

    test('rejects duplicate atlas id', () {
      final result = appendTiledTsxSurfaceImportToCatalog(
        catalog: ProjectSurfaceCatalog(
          atlases: [_atlas('tech-animations')],
        ),
        atlas: _atlas('tech-animations'),
        animations: [_animation('tech-animations-tile-99')],
      );

      expect(result.hasErrors, isTrue);
      expect(result.catalog, isNull);
      expect(
        result.errors,
        contains('Atlas TSX déjà présent dans le catalogue : tech-animations.'),
      );
    });

    test('rejects duplicate animation id', () {
      final result = appendTiledTsxSurfaceImportToCatalog(
        catalog: ProjectSurfaceCatalog(
          animations: [_animation('tech-animations-tile-99')],
        ),
        atlas: _atlas('tech-animations'),
        animations: [_animation('tech-animations-tile-99')],
      );

      expect(result.hasErrors, isTrue);
      expect(result.catalog, isNull);
      expect(
        result.errors,
        contains(
          'Animation TSX déjà présente dans le catalogue : tech-animations-tile-99.',
        ),
      );
    });
  });
}

ProjectSurfaceAtlas _atlas(String id) {
  return ProjectSurfaceAtlas(
    id: id,
    name: id,
    tilesetId: 'tech-nature-animations',
    geometry: SurfaceAtlasGeometry(
      tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
      gridSize: SurfaceAtlasGridSize(columns: 2, rows: 2),
    ),
  );
}

ProjectSurfaceAnimation _animation(String id) {
  return ProjectSurfaceAnimation(
    id: id,
    name: id,
    timeline: SurfaceAnimationTimeline(
      frames: [
        SurfaceAnimationFrame(
          tileRef: SurfaceAtlasTileRef(
            atlasId: 'tech-animations',
            column: 0,
            row: 0,
          ),
          durationMs: 100,
        ),
      ],
    ),
  );
}

ProjectSurfacePreset _preset(String id) {
  return ProjectSurfacePreset(
    id: id,
    name: id,
    variantAnimations: SurfaceVariantAnimationRefSet(
      refs: [
        SurfaceVariantAnimationRef(
          role: SurfaceVariantRole.isolated,
          animationId: 'existing-animation',
        ),
      ],
    ),
  );
}
````

### packages/map_editor/test/surface_studio/tiled_tsx_import_ui_test.dart

````dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_studio/importers/tiled_tsx_workspace.dart';
import 'package:path/path.dart' as p;

void main() {
  group('TiledTsxWorkspace import UI', () {
    testWidgets('loads a TSX, shows summary, imports atlas and animations',
        (tester) async {
      ProjectSurfaceCatalog? changedCatalog;

      await tester.pumpWidget(
        _wrap(
          TiledTsxWorkspace(
            catalog: ProjectSurfaceCatalog(),
            projectTilesets: const [
              ProjectTilesetEntry(
                id: 'tech-nature-animations',
                name: 'TECH Nature Animations',
                relativePath: 'Data/Tiled/Assets/TECH-Nature-animations.png',
              ),
            ],
            fileLoader: _FakeTsxFileLoader(_readTechAnimationsTsx()),
            onSurfaceCatalogChanged: (catalog) => changedCatalog = catalog,
          ),
        ),
      );

      expect(find.text('Aucune animation TSX importée.'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('tiled_tsx_workspace.import')));
      await tester.pumpAndSettle();

      expect(find.text('Résumé TSX'), findsOneWidget);
      expect(find.text('TECH-Animations'), findsWidgets);
      expect(find.text('242 animations'), findsWidgets);
      expect(find.text('../Assets/TECH-Nature-animations.png'), findsOneWidget);
      expect(find.textContaining('TECH Nature Animations'), findsWidgets);

      final confirm = find.byKey(
        const ValueKey('tiled_tsx_workspace.confirm_import'),
      );
      await tester.ensureVisible(confirm);
      await tester.tap(confirm);
      await tester.pumpAndSettle();

      expect(changedCatalog, isNotNull);
      expect(changedCatalog!.atlasCount, 1);
      expect(changedCatalog!.animationCount, 242);
      expect(changedCatalog!.presetCount, 0);
      expect(changedCatalog!.containsAtlas('tech-animations'), isTrue);
      expect(
        changedCatalog!.containsAnimation('tech-animations-tile-99'),
        isTrue,
      );
      expect(
        find.text('Import TSX prêt : 242 animations ajoutées.'),
        findsOneWidget,
      );
      expect(find.text('Animations TSX importées'), findsOneWidget);
      expect(find.text('tech-animations-tile-99'), findsWidgets);
    });

    testWidgets('blocks import when no matching tileset is available',
        (tester) async {
      ProjectSurfaceCatalog? changedCatalog;

      await tester.pumpWidget(
        _wrap(
          TiledTsxWorkspace(
            catalog: ProjectSurfaceCatalog(),
            projectTilesets: const [],
            fileLoader: _FakeTsxFileLoader(_readTechAnimationsTsx()),
            onSurfaceCatalogChanged: (catalog) => changedCatalog = catalog,
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('tiled_tsx_workspace.import')));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Ajoutez d’abord l’image comme tileset du projet, puis relancez l’import TSX.',
        ),
        findsOneWidget,
      );

      final confirm = find.byKey(
        const ValueKey('tiled_tsx_workspace.confirm_import'),
      );
      expect(tester.widget<ElevatedButton>(confirm).onPressed, isNull);
      expect(changedCatalog, isNull);
    });

    testWidgets('shows parser errors for invalid TSX', (tester) async {
      await tester.pumpWidget(
        _wrap(
          TiledTsxWorkspace(
            catalog: ProjectSurfaceCatalog(),
            projectTilesets: const [
              ProjectTilesetEntry(
                id: 'mini',
                name: 'Mini',
                relativePath: 'mini.png',
              ),
            ],
            fileLoader: const _FakeTsxFileLoader('<not-xml>'),
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('tiled_tsx_workspace.import')));
      await tester.pumpAndSettle();

      expect(find.text('Erreur import TSX'), findsOneWidget);
      expect(find.textContaining('XML'), findsWidgets);
    });

    testWidgets('blocks TSX without animations', (tester) async {
      await tester.pumpWidget(
        _wrap(
          TiledTsxWorkspace(
            catalog: ProjectSurfaceCatalog(),
            projectTilesets: const [
              ProjectTilesetEntry(
                id: 'static',
                name: 'Static',
                relativePath: 'static.png',
              ),
            ],
            fileLoader: const _FakeTsxFileLoader(_staticTsx),
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('tiled_tsx_workspace.import')));
      await tester.pumpAndSettle();

      expect(find.text('Le TSX ne contient aucune animation.'), findsOneWidget);
      final confirm = find.byKey(
        const ValueKey('tiled_tsx_workspace.confirm_import'),
      );
      expect(tester.widget<ElevatedButton>(confirm).onPressed, isNull);
    });

    testWidgets('reports duplicate atlas id without mutating the catalog',
        (tester) async {
      ProjectSurfaceCatalog? changedCatalog;
      final existing = ProjectSurfaceCatalog(
        atlases: [
          ProjectSurfaceAtlas(
            id: 'tech-animations',
            name: 'TECH-Animations',
            tilesetId: 'tech-nature-animations',
            geometry: SurfaceAtlasGeometry(
              tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
              gridSize: SurfaceAtlasGridSize(columns: 98, rows: 109),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        _wrap(
          TiledTsxWorkspace(
            catalog: existing,
            projectTilesets: const [
              ProjectTilesetEntry(
                id: 'tech-nature-animations',
                name: 'TECH Nature Animations',
                relativePath: 'Data/Tiled/Assets/TECH-Nature-animations.png',
              ),
            ],
            fileLoader: _FakeTsxFileLoader(_readTechAnimationsTsx()),
            onSurfaceCatalogChanged: (catalog) => changedCatalog = catalog,
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('tiled_tsx_workspace.import')));
      await tester.pumpAndSettle();
      final confirm = find.byKey(
        const ValueKey('tiled_tsx_workspace.confirm_import'),
      );
      await tester.ensureVisible(confirm);
      await tester.tap(confirm);
      await tester.pumpAndSettle();

      expect(changedCatalog, isNull);
      expect(
        find.text('Atlas TSX déjà présent dans le catalogue : tech-animations.'),
        findsOneWidget,
      );
    });
  });
}

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 1300,
        height: 900,
        child: child,
      ),
    ),
  );
}

String _readTechAnimationsTsx() {
  final repoRoot = Directory.current.parent.parent;
  final sdkProject = repoRoot
      .listSync()
      .whereType<Directory>()
      .firstWhere((dir) => p.basename(dir.path).contains('sdk_test_project'));
  final tsxFile = File(
    p.join(
      sdkProject.path,
      'Data',
      'Tiled',
      'Tilesets',
      'TECH-Animations.tsx',
    ),
  );
  return tsxFile.readAsStringSync();
}

final class _FakeTsxFileLoader implements TiledTsxFileLoader {
  const _FakeTsxFileLoader(this.xml);

  final String xml;

  @override
  Future<TiledTsxLoadedFile?> pickAndLoadTsx() async {
    return TiledTsxLoadedFile(
      path: '/tmp/TECH-Animations.tsx',
      fileName: 'TECH-Animations.tsx',
      xml: xml,
    );
  }
}

const _staticTsx = '''
<?xml version="1.0" encoding="UTF-8"?>
<tileset name="Static" tilewidth="32" tileheight="32" tilecount="1" columns="1">
 <image source="../Assets/static.png" width="32" height="32"/>
</tileset>
''';
````

### packages/map_editor/test/surface_studio/tiled_tsx_workspace_tab_test.dart

````dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_studio/importers/tiled_tsx_workspace.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_panel.dart';

void main() {
  testWidgets('Surface Studio exposes a first-level TSX workspace',
      (tester) async {
    await tester.pumpWidget(
      _wrapPanel(
        SurfaceStudioPanel(
          readModel: buildSurfaceStudioReadModelFromCatalog(
            ProjectSurfaceCatalog(),
          ),
          projectTilesets: const [],
          tsxFileLoader: const _NoopTsxFileLoader(),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('surface_studio.primary_tabs')), findsOne);
    expect(find.text('Catalogue Surface'), findsOneWidget);
    expect(find.text('TSX'), findsOneWidget);
    expect(find.text('Diagnostics'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('surface_studio.tab.tsx')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('surface_studio.tsx_workspace')), findsOne);
    expect(find.text('Aucune animation TSX importée.'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('tiled_tsx_workspace.empty_import')),
      findsOneWidget,
    );
    expect(find.text('Détails avancés'), findsNothing);
  });

  testWidgets('Diagnostics remain available as their own top-level workspace',
      (tester) async {
    await tester.pumpWidget(
      _wrapPanel(
        SurfaceStudioPanel(
          readModel: buildSurfaceStudioReadModelFromCatalog(
            ProjectSurfaceCatalog(),
          ),
          projectTilesets: const [],
          tsxFileLoader: const _NoopTsxFileLoader(),
        ),
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey('surface_studio.tab.diagnostics')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('surface_studio.diagnostics_workspace')),
      findsOne,
    );
    expect(find.text('Détails avancés'), findsOneWidget);
  });
}

Widget _wrapPanel(Widget child) {
  return MaterialApp(
    home: MediaQuery(
      data: const MediaQueryData(size: Size(2048, 1120)),
      child: CupertinoPageScaffold(
        child: SizedBox(
          width: 2048,
          height: 1120,
          child: child,
        ),
      ),
    ),
  );
}

final class _NoopTsxFileLoader implements TiledTsxFileLoader {
  const _NoopTsxFileLoader();

  @override
  Future<TiledTsxLoadedFile?> pickAndLoadTsx() async => null;
}
````

### packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_mistral_grouping_suggester.dart

````dart
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:map_core/map_core.dart';

import '../surface_studio_mapping_suggestion_models.dart';
import '../surface_studio_mistral_response_parser.dart';
import 'tiled_tsx_mistral_animation_pack.dart';
import 'tiled_tsx_mistral_grouping_models.dart';
import 'tiled_tsx_mistral_grouping_prompt_builder.dart';

abstract interface class TiledTsxAnimationGroupingSuggester {
  Future<TiledTsxMistralGroupingResult> suggest({
    required String apiKey,
    required TiledTsxMistralGroupingRequest request,
    required Uint8List? atlasImageBytes,
  });
}

final class TiledTsxMistralAnimationGroupingSuggester
    implements TiledTsxAnimationGroupingSuggester {
  TiledTsxMistralAnimationGroupingSuggester({
    http.Client? httpClient,
    this.baseUrl = 'https://api.mistral.ai/v1/chat/completions',
    this.model = 'mistral-small-latest',
    this.timeout = const Duration(seconds: 30),
  }) : _client = httpClient ?? http.Client();

  final http.Client _client;
  final String baseUrl;
  final String model;
  final Duration timeout;

  @override
  Future<TiledTsxMistralGroupingResult> suggest({
    required String apiKey,
    required TiledTsxMistralGroupingRequest request,
    required Uint8List? atlasImageBytes,
  }) async {
    final key = apiKey.trim();
    if (key.isEmpty) {
      return const TiledTsxMistralGroupingResult(
        suggestions: <TiledTsxRoleAnimationSuggestion>[],
        rejectedAnimationIds: <String>[],
        warnings: <String>['Clé Mistral absente.'],
      );
    }

    final pack = buildTiledTsxMistralAnimationPack(
      request: request,
      atlasImageBytes: atlasImageBytes,
    );
    final prompt = buildTiledTsxMistralGroupingPrompt(
      request: request,
      metadataJson: pack.metadataJson,
    );
    final body = jsonEncode({
      'model': model,
      'temperature': 0.1,
      'reasoning_effort': 'high',
      'response_format': _jsonSchemaResponseFormat(),
      'messages': [
        {
          'role': 'user',
          'content': [
            {'type': 'text', 'text': prompt},
            {
              'type': 'image_url',
              'image_url': pack.contactSheetDataUrl,
            },
          ],
        },
      ],
    });

    try {
      final response = await _client
          .post(
            Uri.parse(baseUrl),
            headers: {
              'Authorization': 'Bearer $key',
              'Content-Type': 'application/json',
            },
            body: body,
          )
          .timeout(timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return TiledTsxMistralGroupingResult(
          suggestions: const <TiledTsxRoleAnimationSuggestion>[],
          rejectedAnimationIds: const <String>[],
          warnings: <String>['Mistral HTTP ${response.statusCode}.'],
        );
      }
      return parseTiledTsxMistralGroupingChatResponse(
        response.body,
        request: request,
      );
    } on TimeoutException {
      return const TiledTsxMistralGroupingResult(
        suggestions: <TiledTsxRoleAnimationSuggestion>[],
        rejectedAnimationIds: <String>[],
        warnings: <String>['Mistral timeout.'],
      );
    } catch (_) {
      return const TiledTsxMistralGroupingResult(
        suggestions: <TiledTsxRoleAnimationSuggestion>[],
        rejectedAnimationIds: <String>[],
        warnings: <String>['Analyse Mistral impossible.'],
      );
    }
  }

  Map<String, Object?> _jsonSchemaResponseFormat() {
    return {
      'type': 'json_schema',
      'json_schema': {
        'name': 'tiled_tsx_animation_grouping',
        'strict': true,
        'schema': {
          'type': 'object',
          'additionalProperties': false,
          'required': ['suggestions', 'rejectedAnimationIds', 'warnings'],
          'properties': {
            'suggestions': {
              'type': 'array',
              'items': {
                'type': 'object',
                'additionalProperties': false,
                'required': [
                  'role',
                  'animationId',
                  'confidence',
                  'evidenceAnimationIds',
                  'reason',
                ],
                'properties': {
                  'role': {
                    'type': 'string',
                    'enum': tiledTsxMistralAllowedRoleNames,
                  },
                  'animationId': {'type': 'string'},
                  'confidence': {
                    'type': 'string',
                    'enum': ['high', 'medium', 'low'],
                  },
                  'evidenceAnimationIds': {
                    'type': 'array',
                    'items': {'type': 'string'},
                  },
                  'reason': {'type': 'string'},
                },
              },
            },
            'rejectedAnimationIds': {
              'type': 'array',
              'items': {'type': 'string'},
            },
            'warnings': {
              'type': 'array',
              'items': {'type': 'string'},
            },
          },
        },
      },
    };
  }
}

TiledTsxMistralGroupingResult parseTiledTsxMistralGroupingChatResponse(
  String body, {
  required TiledTsxMistralGroupingRequest request,
}) {
  try {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('root');
    }
    final choices = decoded['choices'];
    if (choices is! List || choices.isEmpty) {
      throw const FormatException('choices');
    }
    final first = choices.first;
    if (first is! Map<String, dynamic>) {
      throw const FormatException('choice');
    }
    final message = first['message'];
    if (message is! Map<String, dynamic>) {
      throw const FormatException('message');
    }
    final text = extractMistralAssistantTextContent(message['content']);
    if (text == null) {
      throw const FormatException('content text');
    }
    final payload = extractFirstJsonObjectFromMistralText(text);
    if (payload == null) {
      throw const FormatException('payload');
    }
    return parseTiledTsxMistralGroupingPayload(payload, request: request);
  } catch (e) {
    return TiledTsxMistralGroupingResult(
      suggestions: const <TiledTsxRoleAnimationSuggestion>[],
      rejectedAnimationIds: const <String>[],
      warnings: <String>['Réponse Mistral invalide: $e'],
    );
  }
}

TiledTsxMistralGroupingResult parseTiledTsxMistralGroupingPayload(
  Map<String, dynamic> payload, {
  required TiledTsxMistralGroupingRequest request,
}) {
  final selectedIds =
      request.animations.map((animation) => animation.id).toSet();
  final warnings = <String>[];
  final suggestions = <TiledTsxRoleAnimationSuggestion>[];
  final rejectedAnimationIds = <String>[];
  final usedRoles = <SurfaceVariantRole>{};
  final usedAnimationIds = <String>{};

  final rawWarnings = payload['warnings'];
  if (rawWarnings is List) {
    for (final warning in rawWarnings) {
      if (warning is String && warning.trim().isNotEmpty) {
        warnings.add(warning.trim());
      }
    }
  }

  final rawRejected = payload['rejectedAnimationIds'];
  if (rawRejected is List) {
    for (final id in rawRejected) {
      if (id is! String || id.trim().isEmpty) {
        warnings.add('Animation rejetée Mistral invalide ignorée.');
        continue;
      }
      final animationId = id.trim();
      if (!selectedIds.contains(animationId)) {
        warnings.add(
          'Animation rejetée Mistral inconnue ou non sélectionnée ignorée : $animationId.',
        );
        continue;
      }
      rejectedAnimationIds.add(animationId);
    }
  }

  final rawSuggestions = payload['suggestions'];
  if (rawSuggestions is! List) {
    warnings.add('Réponse Mistral sans suggestions.');
    return TiledTsxMistralGroupingResult(
      suggestions: const <TiledTsxRoleAnimationSuggestion>[],
      rejectedAnimationIds: List<String>.unmodifiable(rejectedAnimationIds),
      warnings: List<String>.unmodifiable(warnings),
    );
  }

  for (final item in rawSuggestions) {
    if (item is! Map<String, dynamic>) {
      warnings.add('Suggestion Mistral non objet rejetée.');
      continue;
    }
    final roleName = item['role'];
    final role = roleName is String ? tiledTsxRoleFromName(roleName) : null;
    if (role == null) {
      warnings.add('Rôle Mistral inconnu rejeté : $roleName.');
      continue;
    }
    if (usedRoles.contains(role)) {
      warnings.add('Rôle Mistral dupliqué rejeté : ${role.name}.');
      continue;
    }

    final rawAnimationId = item['animationId'];
    final animationId = rawAnimationId is String ? rawAnimationId.trim() : '';
    if (animationId.isEmpty || !selectedIds.contains(animationId)) {
      warnings.add(
        'Animation Mistral inconnue ou non sélectionnée rejetée pour ${role.name} : $rawAnimationId.',
      );
      continue;
    }
    if (usedAnimationIds.contains(animationId)) {
      warnings.add(
        'Animation Mistral dupliquée rejetée pour ${role.name} : $animationId.',
      );
      continue;
    }

    final confidence = _confidenceFromName(item['confidence']);
    if (confidence == null) {
      warnings.add('Confiance Mistral inconnue rejetée pour ${role.name}.');
      continue;
    }

    final evidence = _stringList(item['evidenceAnimationIds']);
    if (evidence.isEmpty) {
      warnings.add(
        'Suggestion Mistral sans evidenceAnimationIds rejetée pour ${role.name}.',
      );
      continue;
    }
    final unknownEvidence =
        evidence.where((id) => !selectedIds.contains(id)).toList();
    if (unknownEvidence.isNotEmpty) {
      warnings.add(
        'Evidence Mistral inconnue rejetée pour ${role.name} : ${unknownEvidence.first}.',
      );
      continue;
    }

    final reason = item['reason'];
    suggestions.add(
      TiledTsxRoleAnimationSuggestion(
        role: role,
        animationId: animationId,
        confidence: confidence,
        reason: reason is String && reason.trim().isNotEmpty
            ? reason.trim()
            : 'Suggestion Mistral sans raison détaillée.',
        evidenceAnimationIds: List<String>.unmodifiable(evidence),
      ),
    );
    usedRoles.add(role);
    usedAnimationIds.add(animationId);
  }

  return TiledTsxMistralGroupingResult(
    suggestions: List<TiledTsxRoleAnimationSuggestion>.unmodifiable(
      suggestions,
    ),
    rejectedAnimationIds: List<String>.unmodifiable(rejectedAnimationIds),
    warnings: List<String>.unmodifiable(warnings),
  );
}

SurfaceStudioMappingSuggestionConfidence? _confidenceFromName(Object? value) {
  if (value is! String) {
    return null;
  }
  for (final confidence in SurfaceStudioMappingSuggestionConfidence.values) {
    if (confidence.name == value) {
      return confidence;
    }
  }
  return null;
}

List<String> _stringList(Object? value) {
  if (value is! List) {
    return const <String>[];
  }
  final strings = <String>[];
  for (final raw in value) {
    if (raw is String && raw.trim().isNotEmpty) {
      strings.add(raw.trim());
    }
  }
  return strings;
}
````

### packages/map_editor/lib/src/features/surface_studio/surface_studio_mistral_mapping_suggester.dart

````dart
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'surface_studio_ai_mapping_suggester.dart';
import 'surface_studio_mapping_suggestion_models.dart';
import 'surface_studio_mapping_suggestion_prompt_builder.dart';
import 'surface_studio_mistral_response_parser.dart';
import 'surface_studio_mistral_vision_pack.dart';

final class SurfaceStudioMistralMappingSuggester
    implements SurfaceStudioAiMappingSuggester {
  SurfaceStudioMistralMappingSuggester({
    http.Client? httpClient,
    this.baseUrl = 'https://api.mistral.ai/v1/chat/completions',
    this.model = 'mistral-small-latest',
    this.timeout = const Duration(seconds: 30),
  }) : _client = httpClient ?? http.Client();

  final http.Client _client;
  final String baseUrl;
  final String model;
  final Duration timeout;

  @override
  Future<SurfaceStudioMappingSuggestionResult> suggest({
    required String apiKey,
    required Uint8List imageBytes,
    required int tileWidth,
    required int tileHeight,
    required int columnCount,
    required int frameCount,
  }) async {
    final key = apiKey.trim();
    if (key.isEmpty) {
      return const SurfaceStudioMappingSuggestionResult(
        suggestions: <SurfaceStudioRoleSuggestion>[],
        warnings: <String>['Clé Mistral absente.'],
        source: SurfaceStudioMappingSuggestionSource.mistral,
      );
    }

    final visionPack = buildSurfaceStudioMistralVisionPack(
      imageBytes: imageBytes,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      columnCount: columnCount,
      frameCount: frameCount,
    );
    final prompt = buildSurfaceStudioMappingSuggestionPrompt(
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      columnCount: columnCount,
      frameCount: frameCount,
      columnDescriptors: visionPack.columnDescriptors,
    );
    final body = jsonEncode({
      'model': model,
      'temperature': 0.1,
      'reasoning_effort': 'high',
      'response_format': _jsonSchemaResponseFormat(),
      'messages': [
        {
          'role': 'user',
          'content': [
            {'type': 'text', 'text': prompt},
            {
              'type': 'image_url',
              'image_url': visionPack.originalAtlasDataUrl,
            },
            {
              'type': 'image_url',
              'image_url': visionPack.annotatedAtlasDataUrl,
            },
            {
              'type': 'image_url',
              'image_url': visionPack.columnContactSheetDataUrl,
            },
          ],
        },
      ],
    });

    try {
      final response = await _client
          .post(
            Uri.parse(baseUrl),
            headers: {
              'Authorization': 'Bearer $key',
              'Content-Type': 'application/json',
            },
            body: body,
          )
          .timeout(timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return SurfaceStudioMappingSuggestionResult(
          suggestions: const <SurfaceStudioRoleSuggestion>[],
          warnings: <String>['Mistral HTTP ${response.statusCode}.'],
          source: SurfaceStudioMappingSuggestionSource.mistral,
        );
      }
      return parseSurfaceStudioMistralChatResponse(
        response.body,
        columnCount: columnCount,
        columnDescriptors: visionPack.columnDescriptors,
      );
    } on TimeoutException {
      return const SurfaceStudioMappingSuggestionResult(
        suggestions: <SurfaceStudioRoleSuggestion>[],
        warnings: <String>['Mistral timeout.'],
        source: SurfaceStudioMappingSuggestionSource.mistral,
      );
    } catch (_) {
      return const SurfaceStudioMappingSuggestionResult(
        suggestions: <SurfaceStudioRoleSuggestion>[],
        warnings: <String>['Analyse Mistral impossible.'],
        source: SurfaceStudioMappingSuggestionSource.mistral,
      );
    }
  }

  Map<String, Object?> _jsonSchemaResponseFormat() {
    return {
      'type': 'json_schema',
      'json_schema': {
        'name': 'surface_studio_mapping_suggestion',
        'strict': true,
        'schema': {
          'type': 'object',
          'additionalProperties': false,
          'required': ['assignments', 'rejectedColumns', 'warnings'],
          'properties': {
            'assignments': {
              'type': 'array',
              'items': {
                'type': 'object',
                'additionalProperties': false,
                'required': [
                  'role',
                  'columns',
                  'confidence',
                  'evidenceColumns',
                  'reason',
                ],
                'properties': {
                  'role': {
                    'type': 'string',
                    'enum': surfaceStudioMistralAllowedRoleNames,
                  },
                  'columns': {
                    'type': 'array',
                    'items': {'type': 'integer'},
                  },
                  'confidence': {
                    'type': 'string',
                    'enum': ['high', 'medium', 'low'],
                  },
                  'evidenceColumns': {
                    'type': 'array',
                    'items': {'type': 'integer'},
                  },
                  'reason': {'type': 'string'},
                },
              },
            },
            'rejectedColumns': {
              'type': 'array',
              'items': {
                'type': 'object',
                'additionalProperties': false,
                'required': ['column', 'reason'],
                'properties': {
                  'column': {'type': 'integer'},
                  'reason': {'type': 'string'},
                },
              },
            },
            'warnings': {
              'type': 'array',
              'items': {'type': 'string'},
            },
          },
        },
      },
    };
  }
}
````

## 19. Diffs Complets

### Fichiers suivis modifiés

````diff
diff --git a/packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_mistral_grouping_suggester.dart b/packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_mistral_grouping_suggester.dart
index 36416317..a83876e9 100644
--- a/packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_mistral_grouping_suggester.dart
+++ b/packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_mistral_grouping_suggester.dart
@@ -24,7 +24,7 @@ final class TiledTsxMistralAnimationGroupingSuggester
   TiledTsxMistralAnimationGroupingSuggester({
     http.Client? httpClient,
     this.baseUrl = 'https://api.mistral.ai/v1/chat/completions',
-    this.model = 'mistral-large-latest',
+    this.model = 'mistral-small-latest',
     this.timeout = const Duration(seconds: 30),
   }) : _client = httpClient ?? http.Client();
 
diff --git a/packages/map_editor/lib/src/features/surface_studio/surface_studio_mistral_mapping_suggester.dart b/packages/map_editor/lib/src/features/surface_studio/surface_studio_mistral_mapping_suggester.dart
index 0e68bbb0..417bc89d 100644
--- a/packages/map_editor/lib/src/features/surface_studio/surface_studio_mistral_mapping_suggester.dart
+++ b/packages/map_editor/lib/src/features/surface_studio/surface_studio_mistral_mapping_suggester.dart
@@ -15,7 +15,7 @@ final class SurfaceStudioMistralMappingSuggester
   SurfaceStudioMistralMappingSuggester({
     http.Client? httpClient,
     this.baseUrl = 'https://api.mistral.ai/v1/chat/completions',
-    this.model = 'mistral-large-latest',
+    this.model = 'mistral-small-latest',
     this.timeout = const Duration(seconds: 30),
   }) : _client = httpClient ?? http.Client();
 
diff --git a/packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart b/packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
index 802f576d..0f710fcf 100644
--- a/packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
+++ b/packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
@@ -13,6 +13,7 @@ import 'package:map_core/map_core.dart';
 
 import '../../ui/shared/cupertino_editor_widgets.dart';
 import 'importers/tiled_tsx_animation_browser.dart';
+import 'importers/tiled_tsx_workspace.dart';
 import 'surface_studio_atlas_editing.dart';
 import 'surface_studio_atlas_image_preview.dart';
 import 'surface_studio_catalog_browser.dart';
@@ -50,6 +51,12 @@ SurfaceStudioSelection _selectionValidInReadModel(
 /// Accent produit Surface Studio (même base que la tuile World Explorer).
 const Color _surfaceStudioAccent = Color(0xFF2DD4BF);
 
+enum _SurfaceStudioPrimaryWorkspace {
+  catalogue,
+  tsx,
+  diagnostics,
+}
+
 /// Panneau présentationnel **lecture seule** pour Surface Studio.
 class SurfaceStudioPanel extends StatefulWidget {
   const SurfaceStudioPanel({
@@ -62,6 +69,7 @@ class SurfaceStudioPanel extends StatefulWidget {
     this.projectSettings,
     this.surfaceMappingImageLoader,
     this.aiMappingSuggester,
+    this.tsxFileLoader = const TiledTsxPlatformFileLoader(),
   });
 
   final SurfaceStudioReadModel readModel;
@@ -71,6 +79,7 @@ class SurfaceStudioPanel extends StatefulWidget {
   final ProjectSettings? projectSettings;
   final SurfaceStudioAtlasUiImageLoader? surfaceMappingImageLoader;
   final SurfaceStudioAiMappingSuggester? aiMappingSuggester;
+  final TiledTsxFileLoader tsxFileLoader;
 
   /// Racine projet sur disque pour résoudre les chemins d’images tileset (aperçu Lot 72).
   final String? projectRootPath;
@@ -114,6 +123,8 @@ class SurfaceStudioPanel extends StatefulWidget {
 class _SurfaceStudioPanelState extends State<SurfaceStudioPanel> {
   /// Sélection d’inspection : locale au widget, jamais écrite dans le manifest.
   SurfaceStudioSelection _selection = const SurfaceStudioSelection.none();
+  _SurfaceStudioPrimaryWorkspace _primaryWorkspace =
+      _SurfaceStudioPrimaryWorkspace.catalogue;
   late SurfaceStudioReadModel _workReadModel;
   String? _saveFlowPrepNote;
   String? _projectSaveDiskNote;
@@ -434,9 +445,8 @@ class _SurfaceStudioPanelState extends State<SurfaceStudioPanel> {
           : null,
     );
     final tsxBrowserAtlas = _atlasForAnimationBrowser();
-    final advancedDrawer = SingleChildScrollView(
-      padding: const EdgeInsets.all(14),
-      child: _AdvancedDetailsSection(
+    Widget buildAdvancedDetails() {
+      return _AdvancedDetailsSection(
         inspection: inspection,
         browser: SurfaceStudioCatalogBrowser(
           readModel: _workReadModel,
@@ -459,7 +469,12 @@ class _SurfaceStudioPanelState extends State<SurfaceStudioPanel> {
         placeholder: const _SectionPlaceholder(
           title: SurfaceStudioPanel.placeholderActionsTitle,
         ),
-      ),
+      );
+    }
+
+    final advancedDrawer = SingleChildScrollView(
+      padding: const EdgeInsets.all(14),
+      child: buildAdvancedDetails(),
     );
 
     return LayoutBuilder(
@@ -468,52 +483,81 @@ class _SurfaceStudioPanelState extends State<SurfaceStudioPanel> {
             constraints.hasBoundedWidth ? constraints.maxWidth : 1600.0;
         final shellHeight =
             constraints.hasBoundedHeight ? constraints.maxHeight : 900.0;
+        final tsxWorkspaceAtlas = _atlasForAnimationBrowser();
+        final content = switch (_primaryWorkspace) {
+          _SurfaceStudioPrimaryWorkspace.catalogue => SurfaceStudioScreen(
+              readModel: _workReadModel,
+              projectSettings: widget.projectSettings,
+              projectTilesets: widget.projectTilesets ?? const [],
+              projectRootPath: widget.projectRootPath,
+              surfaceMappingImageLoader: widget.surfaceMappingImageLoader,
+              hasWorkCatalogChanges: _hasWorkCatalogChanges,
+              saveFlowPrepNote: _saveFlowPrepNote,
+              projectSaveDiskNote: _projectSaveDiskNote,
+              onSurfaceCatalogChanged: _onSurfaceCatalogChanged,
+              onWorkCatalogAnimationsCreated: (createdIds) {
+                if (createdIds.isEmpty) {
+                  return;
+                }
+                setState(() {
+                  _selection =
+                      SurfaceStudioSelection.animation(createdIds.first);
+                });
+              },
+              onWorkCatalogPresetCreated: (presetId) {
+                if (presetId.isEmpty) {
+                  return;
+                }
+                setState(() {
+                  _selection = SurfaceStudioSelection.preset(presetId);
+                });
+              },
+              onResetWorkCatalog: () {
+                setState(() {
+                  _workReadModel = widget.readModel;
+                  _selection =
+                      _selectionValidInReadModel(_workReadModel, _selection);
+                  _saveFlowPrepNote = null;
+                });
+              },
+              onSurfaceCatalogSavePrep:
+                  widget.onSurfaceCatalogSaveRequested == null
+                      ? null
+                      : _onSurfaceCatalogSavePrep,
+              onRequestProjectSave: widget.onRequestProjectSave == null
+                  ? null
+                  : _onRequestProjectSave,
+              advancedDrawer: advancedDrawer,
+              aiMappingSuggester: widget.aiMappingSuggester,
+            ),
+          _SurfaceStudioPrimaryWorkspace.tsx => TiledTsxWorkspace(
+              catalog: _workReadModel.catalog,
+              projectTilesets: widget.projectTilesets ?? const [],
+              onSurfaceCatalogChanged: _onSurfaceCatalogChanged,
+              fileLoader: widget.tsxFileLoader,
+              atlasImageBytes: _atlasImageBytesForBrowser(tsxWorkspaceAtlas),
+              projectSettings: widget.projectSettings,
+            ),
+          _SurfaceStudioPrimaryWorkspace.diagnostics => SingleChildScrollView(
+              key: const ValueKey('surface_studio.diagnostics_workspace'),
+              padding: const EdgeInsets.all(14),
+              child: buildAdvancedDetails(),
+            ),
+        };
         return SizedBox(
           width: shellWidth,
           height: shellHeight,
-          child: SurfaceStudioScreen(
-            readModel: _workReadModel,
-            projectSettings: widget.projectSettings,
-            projectTilesets: widget.projectTilesets ?? const [],
-            projectRootPath: widget.projectRootPath,
-            surfaceMappingImageLoader: widget.surfaceMappingImageLoader,
-            hasWorkCatalogChanges: _hasWorkCatalogChanges,
-            saveFlowPrepNote: _saveFlowPrepNote,
-            projectSaveDiskNote: _projectSaveDiskNote,
-            onSurfaceCatalogChanged: _onSurfaceCatalogChanged,
-            onWorkCatalogAnimationsCreated: (createdIds) {
-              if (createdIds.isEmpty) {
-                return;
-              }
-              setState(() {
-                _selection = SurfaceStudioSelection.animation(createdIds.first);
-              });
-            },
-            onWorkCatalogPresetCreated: (presetId) {
-              if (presetId.isEmpty) {
-                return;
-              }
-              setState(() {
-                _selection = SurfaceStudioSelection.preset(presetId);
-              });
-            },
-            onResetWorkCatalog: () {
-              setState(() {
-                _workReadModel = widget.readModel;
-                _selection =
-                    _selectionValidInReadModel(_workReadModel, _selection);
-                _saveFlowPrepNote = null;
-              });
-            },
-            onSurfaceCatalogSavePrep:
-                widget.onSurfaceCatalogSaveRequested == null
-                    ? null
-                    : _onSurfaceCatalogSavePrep,
-            onRequestProjectSave: widget.onRequestProjectSave == null
-                ? null
-                : _onRequestProjectSave,
-            advancedDrawer: advancedDrawer,
-            aiMappingSuggester: widget.aiMappingSuggester,
+          child: Column(
+            crossAxisAlignment: CrossAxisAlignment.stretch,
+            children: [
+              _SurfaceStudioPrimaryTabs(
+                selected: _primaryWorkspace,
+                onSelected: (workspace) {
+                  setState(() => _primaryWorkspace = workspace);
+                },
+              ),
+              Expanded(child: content),
+            ],
           ),
         );
       },
@@ -521,6 +565,87 @@ class _SurfaceStudioPanelState extends State<SurfaceStudioPanel> {
   }
 }
 
+class _SurfaceStudioPrimaryTabs extends StatelessWidget {
+  const _SurfaceStudioPrimaryTabs({
+    required this.selected,
+    required this.onSelected,
+  });
+
+  final _SurfaceStudioPrimaryWorkspace selected;
+  final ValueChanged<_SurfaceStudioPrimaryWorkspace> onSelected;
+
+  @override
+  Widget build(BuildContext context) {
+    return Container(
+      key: const ValueKey('surface_studio.primary_tabs'),
+      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
+      color: EditorChrome.appBackground(context),
+      child: Row(
+        children: [
+          _SurfaceStudioPrimaryTabButton(
+            key: const ValueKey('surface_studio.tab.catalogue'),
+            label: 'Catalogue Surface',
+            selected: selected == _SurfaceStudioPrimaryWorkspace.catalogue,
+            onPressed: () =>
+                onSelected(_SurfaceStudioPrimaryWorkspace.catalogue),
+          ),
+          const SizedBox(width: 8),
+          _SurfaceStudioPrimaryTabButton(
+            key: const ValueKey('surface_studio.tab.tsx'),
+            label: 'TSX',
+            selected: selected == _SurfaceStudioPrimaryWorkspace.tsx,
+            onPressed: () => onSelected(_SurfaceStudioPrimaryWorkspace.tsx),
+          ),
+          const SizedBox(width: 8),
+          _SurfaceStudioPrimaryTabButton(
+            key: const ValueKey('surface_studio.tab.diagnostics'),
+            label: 'Diagnostics',
+            selected: selected == _SurfaceStudioPrimaryWorkspace.diagnostics,
+            onPressed: () =>
+                onSelected(_SurfaceStudioPrimaryWorkspace.diagnostics),
+          ),
+        ],
+      ),
+    );
+  }
+}
+
+class _SurfaceStudioPrimaryTabButton extends StatelessWidget {
+  const _SurfaceStudioPrimaryTabButton({
+    super.key,
+    required this.label,
+    required this.selected,
+    required this.onPressed,
+  });
+
+  final String label;
+  final bool selected;
+  final VoidCallback onPressed;
+
+  @override
+  Widget build(BuildContext context) {
+    final color = selected
+        ? _surfaceStudioAccent.withValues(alpha: 0.2)
+        : EditorChrome.elevatedPanelBackground(context);
+    final textColor =
+        selected ? _surfaceStudioAccent : EditorChrome.primaryLabel(context);
+    return CupertinoButton(
+      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
+      color: color,
+      borderRadius: BorderRadius.circular(9),
+      onPressed: onPressed,
+      child: Text(
+        label,
+        style: TextStyle(
+          color: textColor,
+          fontSize: 13,
+          fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
+        ),
+      ),
+    );
+  }
+}
+
 class _AdvancedDetailsSection extends StatelessWidget {
   const _AdvancedDetailsSection({
     required this.inspection,
diff --git a/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart b/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
index eb1c1c1e..66be9741 100644
--- a/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
+++ b/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
@@ -32,7 +32,9 @@ void main() {
       );
       expect(find.byType(SurfaceStudioWorkflowLayout), findsNothing);
       expect(find.text('Assistant de création'), findsNothing);
-      expect(find.text('Catalogue Surface'), findsNothing);
+      expect(find.byKey(const Key('surface_studio.primary_tabs')), findsOne);
+      expect(find.text('Catalogue Surface'), findsOneWidget);
+      expect(find.text('TSX'), findsOneWidget);
       expect(find.text('Diagnostics Surface'), findsNothing);
     });
 
@@ -50,7 +52,7 @@ void main() {
       );
       expect(find.text('Catalogue & diagnostics'), findsOneWidget);
       expect(find.text('Détails avancés'), findsOneWidget);
-      expect(find.text('Catalogue Surface'), findsOneWidget);
+      expect(find.text('Catalogue Surface'), findsWidgets);
       expect(find.text('Animations TSX importées'), findsOneWidget);
       expect(find.text('Diagnostics Surface'), findsOneWidget);
       expect(find.text('Surfaces prêtes à peindre'), findsOneWidget);
````

### Nouveau fichier : packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_catalog_append.dart

````diff
--- /dev/null	2026-04-30 00:57:08
+++ packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_catalog_append.dart	2026-04-30 00:36:31
@@ -0,0 +1,56 @@
+import 'package:map_core/map_core.dart';
+
+final class TiledTsxCatalogAppendResult {
+  const TiledTsxCatalogAppendResult({
+    required this.catalog,
+    required this.errors,
+    this.warnings = const <String>[],
+  });
+
+  final ProjectSurfaceCatalog? catalog;
+  final List<String> errors;
+  final List<String> warnings;
+
+  bool get hasErrors => errors.isNotEmpty;
+}
+
+TiledTsxCatalogAppendResult appendTiledTsxSurfaceImportToCatalog({
+  required ProjectSurfaceCatalog catalog,
+  required ProjectSurfaceAtlas atlas,
+  required List<ProjectSurfaceAnimation> animations,
+}) {
+  final errors = <String>[];
+  if (catalog.containsAtlas(atlas.id)) {
+    errors.add('Atlas TSX déjà présent dans le catalogue : ${atlas.id}.');
+  }
+  for (final animation in animations) {
+    if (catalog.containsAnimation(animation.id)) {
+      errors.add(
+        'Animation TSX déjà présente dans le catalogue : ${animation.id}.',
+      );
+    }
+  }
+  final incomingAnimationIds = <String>{};
+  for (final animation in animations) {
+    if (!incomingAnimationIds.add(animation.id)) {
+      errors.add(
+        'Animation TSX dupliquée dans l’import : ${animation.id}.',
+      );
+    }
+  }
+  if (errors.isNotEmpty) {
+    return TiledTsxCatalogAppendResult(
+      catalog: null,
+      errors: List<String>.unmodifiable(errors),
+    );
+  }
+
+  return TiledTsxCatalogAppendResult(
+    catalog: ProjectSurfaceCatalog(
+      atlases: [...catalog.atlases, atlas],
+      animations: [...catalog.animations, ...animations],
+      presets: catalog.presets,
+    ),
+    errors: const <String>[],
+  );
+}
````

### Nouveau fichier : packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_workspace.dart

````diff
--- /dev/null	2026-04-30 00:57:08
+++ packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_workspace.dart	2026-04-30 00:52:03
@@ -0,0 +1,641 @@
+import 'dart:io';
+import 'dart:typed_data';
+
+import 'package:file_picker/file_picker.dart';
+import 'package:flutter/cupertino.dart';
+import 'package:flutter/material.dart'
+    show
+        DropdownButton,
+        DropdownMenuItem,
+        ElevatedButton,
+        Material,
+        MaterialType;
+import 'package:map_core/map_core.dart';
+import 'package:path/path.dart' as p;
+
+import '../../../ui/shared/cupertino_editor_widgets.dart';
+import 'tiled_tsx_animated_tileset_parser.dart';
+import 'tiled_tsx_animation_browser.dart';
+import 'tiled_tsx_catalog_append.dart';
+import 'tiled_tsx_mistral_grouping_suggester.dart';
+import 'tiled_tsx_surface_animation_importer.dart';
+
+final class TiledTsxLoadedFile {
+  const TiledTsxLoadedFile({
+    required this.path,
+    required this.fileName,
+    required this.xml,
+  });
+
+  final String path;
+  final String fileName;
+  final String xml;
+}
+
+abstract interface class TiledTsxFileLoader {
+  Future<TiledTsxLoadedFile?> pickAndLoadTsx();
+}
+
+final class TiledTsxPlatformFileLoader implements TiledTsxFileLoader {
+  const TiledTsxPlatformFileLoader();
+
+  @override
+  Future<TiledTsxLoadedFile?> pickAndLoadTsx() async {
+    final picked = await FilePicker.platform.pickFiles(
+      type: FileType.custom,
+      allowedExtensions: const ['tsx'],
+      withData: false,
+    );
+    final path = picked?.files.single.path;
+    if (path == null) {
+      return null;
+    }
+    final xml = await File(path).readAsString();
+    return TiledTsxLoadedFile(
+      path: path,
+      fileName: p.basename(path),
+      xml: xml,
+    );
+  }
+}
+
+class TiledTsxWorkspace extends StatefulWidget {
+  const TiledTsxWorkspace({
+    super.key,
+    required this.catalog,
+    this.projectTilesets = const <ProjectTilesetEntry>[],
+    this.onSurfaceCatalogChanged,
+    this.fileLoader = const TiledTsxPlatformFileLoader(),
+    this.atlasImageBytes,
+    this.projectSettings,
+    this.groupingSuggester,
+  });
+
+  final ProjectSurfaceCatalog catalog;
+  final List<ProjectTilesetEntry> projectTilesets;
+  final ValueChanged<ProjectSurfaceCatalog>? onSurfaceCatalogChanged;
+  final TiledTsxFileLoader fileLoader;
+  final Uint8List? atlasImageBytes;
+  final ProjectSettings? projectSettings;
+  final TiledTsxAnimationGroupingSuggester? groupingSuggester;
+
+  @override
+  State<TiledTsxWorkspace> createState() => _TiledTsxWorkspaceState();
+}
+
+class _TiledTsxWorkspaceState extends State<TiledTsxWorkspace> {
+  TiledTsxLoadedFile? _loadedFile;
+  TiledTsxTilesetAudit? _audit;
+  ProjectTilesetEntry? _selectedTileset;
+  ProjectSurfaceCatalog? _localCatalog;
+  bool _loading = false;
+  String? _statusMessage;
+  List<String> _errors = const <String>[];
+
+  @override
+  void didUpdateWidget(covariant TiledTsxWorkspace oldWidget) {
+    super.didUpdateWidget(oldWidget);
+    if (widget.catalog != oldWidget.catalog) {
+      _localCatalog = null;
+    }
+    if (widget.projectTilesets != oldWidget.projectTilesets) {
+      _selectedTileset = _pickMatchingTileset(_audit);
+    }
+  }
+
+  @override
+  Widget build(BuildContext context) {
+    final label = EditorChrome.primaryLabel(context);
+    final subtle = EditorChrome.subtleLabel(context);
+    final effectiveCatalog = _localCatalog ?? widget.catalog;
+    final atlas = _atlasForBrowser(effectiveCatalog);
+    final animations = effectiveCatalog.animations;
+    return SingleChildScrollView(
+      key: const ValueKey('surface_studio.tsx_workspace'),
+      padding: const EdgeInsets.all(18),
+      child: Column(
+        crossAxisAlignment: CrossAxisAlignment.stretch,
+        children: [
+          Text(
+            'Workspace TSX',
+            style: TextStyle(
+              color: label,
+              fontSize: 20,
+              fontWeight: FontWeight.w700,
+            ),
+          ),
+          const SizedBox(height: 6),
+          Text(
+            'Importez un fichier .tsx Tiled, choisissez l’image tileset PokeMap correspondante, puis parcourez les animations Surface produites.',
+            style: TextStyle(color: subtle, fontSize: 13),
+          ),
+          const SizedBox(height: 14),
+          _ImportSection(
+            loadedFile: _loadedFile,
+            audit: _audit,
+            projectTilesets: widget.projectTilesets,
+            selectedTileset: _selectedTileset,
+            loading: _loading,
+            statusMessage: _statusMessage,
+            errors: _errors,
+            onPickTsx: _pickTsx,
+            onTilesetChanged: (tileset) {
+              setState(() => _selectedTileset = tileset);
+            },
+            onConfirmImport: _canConfirmImport ? _confirmImport : null,
+          ),
+          const SizedBox(height: 14),
+          if (animations.isEmpty)
+            _TsxEmptyState(onImportPressed: _pickTsx)
+          else
+            TiledTsxAnimationBrowser(
+              atlas: atlas,
+              animations: animations,
+              atlasImageBytes: widget.atlasImageBytes,
+              sourceLabel: _loadedFile?.fileName ?? 'Catalogue de travail',
+              catalog: effectiveCatalog,
+              onSurfaceCatalogChanged: widget.onSurfaceCatalogChanged,
+              projectSettings: widget.projectSettings,
+              groupingSuggester: widget.groupingSuggester,
+            ),
+        ],
+      ),
+    );
+  }
+
+  bool get _canConfirmImport =>
+      !_loading &&
+      _audit != null &&
+      _audit!.hasErrors == false &&
+      _audit!.summary.animationCount > 0 &&
+      _selectedTileset != null;
+
+  Future<void> _pickTsx() async {
+    setState(() {
+      _loading = true;
+      _statusMessage = null;
+      _errors = const <String>[];
+    });
+    try {
+      final loaded = await widget.fileLoader.pickAndLoadTsx();
+      if (!mounted) {
+        return;
+      }
+      if (loaded == null) {
+        setState(() {
+          _loading = false;
+          _statusMessage = 'Import TSX annulé.';
+        });
+        return;
+      }
+      final audit = parseTiledTsxAnimatedTileset(loaded.xml);
+      final errors = <String>[
+        if (audit.hasErrors) 'Le fichier XML TSX est invalide ou incomplet.',
+        if (!audit.hasErrors && audit.summary.animationCount == 0)
+          'Le TSX ne contient aucune animation.',
+        ...audit.diagnostics
+            .where(
+              (diagnostic) =>
+                  diagnostic.severity == TiledTsxDiagnosticSeverity.error,
+            )
+            .map((diagnostic) => diagnostic.message),
+      ];
+      setState(() {
+        _loadedFile = loaded;
+        _audit = audit;
+        _selectedTileset = _pickMatchingTileset(audit);
+        _loading = false;
+        _statusMessage = null;
+        _errors = List<String>.unmodifiable(errors);
+      });
+    } catch (error) {
+      if (!mounted) {
+        return;
+      }
+      setState(() {
+        _loading = false;
+        _errors = ['Le fichier XML TSX est invalide ou incomplet.', '$error'];
+      });
+    }
+  }
+
+  void _confirmImport() {
+    final audit = _audit;
+    final tileset = _selectedTileset;
+    if (audit == null || tileset == null) {
+      return;
+    }
+    final prefix = _slugify(audit.summary.name);
+    final imported = importTiledTsxSurfaceAnimations(
+      audit: audit,
+      options: TiledTsxSurfaceAnimationImportOptions(
+        atlasId: prefix,
+        tilesetId: tileset.id,
+        animationIdPrefix: prefix,
+        sortOrderBase: widget.catalog.animationCount,
+      ),
+    );
+    if (imported.hasErrors || imported.atlas == null) {
+      setState(() {
+        _errors = imported.diagnostics
+            .where(
+              (diagnostic) =>
+                  diagnostic.severity ==
+                  TiledTsxSurfaceAnimationImportDiagnosticSeverity.error,
+            )
+            .map((diagnostic) => diagnostic.message)
+            .toList(growable: false);
+        _statusMessage = null;
+      });
+      return;
+    }
+    final appended = appendTiledTsxSurfaceImportToCatalog(
+      catalog: _localCatalog ?? widget.catalog,
+      atlas: imported.atlas!,
+      animations: imported.animations,
+    );
+    if (appended.hasErrors || appended.catalog == null) {
+      setState(() {
+        _errors = appended.errors;
+        _statusMessage = null;
+      });
+      return;
+    }
+    widget.onSurfaceCatalogChanged?.call(appended.catalog!);
+    setState(() {
+      _localCatalog = appended.catalog;
+      _errors = const <String>[];
+      _statusMessage =
+          'Import TSX prêt : ${imported.animations.length} animations ajoutées.';
+    });
+  }
+
+  ProjectTilesetEntry? _pickMatchingTileset(TiledTsxTilesetAudit? audit) {
+    if (widget.projectTilesets.isEmpty) {
+      return null;
+    }
+    final imageSource = audit?.summary.imageSource;
+    if (imageSource != null && imageSource.isNotEmpty) {
+      final expectedBasename = p.basename(imageSource).toLowerCase();
+      for (final tileset in widget.projectTilesets) {
+        if (p.basename(tileset.relativePath).toLowerCase() == expectedBasename) {
+          return tileset;
+        }
+      }
+    }
+    return widget.projectTilesets.first;
+  }
+}
+
+class _ImportSection extends StatelessWidget {
+  const _ImportSection({
+    required this.loadedFile,
+    required this.audit,
+    required this.projectTilesets,
+    required this.selectedTileset,
+    required this.loading,
+    required this.statusMessage,
+    required this.errors,
+    required this.onPickTsx,
+    required this.onTilesetChanged,
+    required this.onConfirmImport,
+  });
+
+  final TiledTsxLoadedFile? loadedFile;
+  final TiledTsxTilesetAudit? audit;
+  final List<ProjectTilesetEntry> projectTilesets;
+  final ProjectTilesetEntry? selectedTileset;
+  final bool loading;
+  final String? statusMessage;
+  final List<String> errors;
+  final VoidCallback onPickTsx;
+  final ValueChanged<ProjectTilesetEntry?> onTilesetChanged;
+  final VoidCallback? onConfirmImport;
+
+  @override
+  Widget build(BuildContext context) {
+    final label = EditorChrome.primaryLabel(context);
+    final subtle = EditorChrome.subtleLabel(context);
+    final border = EditorChrome.editorIslandRim(context);
+    return Container(
+      key: const ValueKey('tiled_tsx_workspace.import_section'),
+      padding: const EdgeInsets.all(14),
+      decoration: BoxDecoration(
+        color: EditorChrome.elevatedPanelBackground(context),
+        borderRadius: BorderRadius.circular(10),
+        border: Border.all(color: border),
+      ),
+      child: Column(
+        crossAxisAlignment: CrossAxisAlignment.stretch,
+        children: [
+          Row(
+            children: [
+              Expanded(
+                child: Column(
+                  crossAxisAlignment: CrossAxisAlignment.start,
+                  children: [
+                    Text(
+                      'Importer un fichier TSX',
+                      style: TextStyle(
+                        color: label,
+                        fontSize: 16,
+                        fontWeight: FontWeight.w700,
+                      ),
+                    ),
+                    const SizedBox(height: 4),
+                    Text(
+                      'Les frames et durées viennent du fichier Tiled. Aucun preset Surface n’est créé à l’import.',
+                      style: TextStyle(color: subtle, fontSize: 12),
+                    ),
+                  ],
+                ),
+              ),
+              const SizedBox(width: 12),
+              ElevatedButton(
+                key: const ValueKey('tiled_tsx_workspace.import'),
+                onPressed: loading ? null : onPickTsx,
+                child: Text(loading ? 'Chargement…' : 'Importer un fichier TSX'),
+              ),
+            ],
+          ),
+          if (audit != null) ...[
+            const SizedBox(height: 12),
+            _TsxSummary(audit: audit!, loadedFile: loadedFile),
+            const SizedBox(height: 12),
+            _TilesetPicker(
+              tilesets: projectTilesets,
+              selectedTileset: selectedTileset,
+              onChanged: onTilesetChanged,
+            ),
+            const SizedBox(height: 12),
+            Align(
+              alignment: Alignment.centerLeft,
+              child: ElevatedButton(
+                key: const ValueKey('tiled_tsx_workspace.confirm_import'),
+                onPressed: onConfirmImport,
+                child: const Text('Confirmer l’import TSX'),
+              ),
+            ),
+          ],
+          if (projectTilesets.isEmpty && audit != null) ...[
+            const SizedBox(height: 10),
+            const Text(
+              'Ajoutez d’abord l’image comme tileset du projet, puis relancez l’import TSX.',
+              style: TextStyle(
+                color: CupertinoColors.systemOrange,
+                fontSize: 12,
+              ),
+            ),
+          ],
+          if (statusMessage != null) ...[
+            const SizedBox(height: 10),
+            Text(
+              statusMessage!,
+              style: const TextStyle(
+                color: CupertinoColors.systemGreen,
+                fontSize: 12,
+                fontWeight: FontWeight.w600,
+              ),
+            ),
+          ],
+          if (errors.isNotEmpty) ...[
+            const SizedBox(height: 10),
+            const Text(
+              'Erreur import TSX',
+              style: TextStyle(
+                color: CupertinoColors.systemRed,
+                fontSize: 12,
+                fontWeight: FontWeight.w700,
+              ),
+            ),
+            const SizedBox(height: 4),
+            for (final error in errors)
+              Text(
+                error,
+                style: const TextStyle(
+                  color: CupertinoColors.systemRed,
+                  fontSize: 12,
+                ),
+              ),
+          ],
+        ],
+      ),
+    );
+  }
+}
+
+class _TsxSummary extends StatelessWidget {
+  const _TsxSummary({
+    required this.audit,
+    required this.loadedFile,
+  });
+
+  final TiledTsxTilesetAudit audit;
+  final TiledTsxLoadedFile? loadedFile;
+
+  @override
+  Widget build(BuildContext context) {
+    final s = audit.summary;
+    return _InfoBlock(
+      title: 'Résumé TSX',
+      rows: [
+        ('Fichier', loadedFile?.fileName ?? 'TSX'),
+        ('name', s.name),
+        ('tileWidth', '${s.tileWidth}'),
+        ('tileHeight', '${s.tileHeight}'),
+        ('columns', '${s.columns}'),
+        ('tileCount', '${s.tileCount}'),
+        ('imageSource', s.imageSource),
+        ('imageWidth', '${s.imageWidth}'),
+        ('imageHeight', '${s.imageHeight}'),
+        ('animations', '${s.animationCount} animations'),
+        ('transparentColor', s.transparentColor ?? 'aucune'),
+      ],
+    );
+  }
+}
+
+class _TilesetPicker extends StatelessWidget {
+  const _TilesetPicker({
+    required this.tilesets,
+    required this.selectedTileset,
+    required this.onChanged,
+  });
+
+  final List<ProjectTilesetEntry> tilesets;
+  final ProjectTilesetEntry? selectedTileset;
+  final ValueChanged<ProjectTilesetEntry?> onChanged;
+
+  @override
+  Widget build(BuildContext context) {
+    final label = EditorChrome.primaryLabel(context);
+    final subtle = EditorChrome.subtleLabel(context);
+    if (tilesets.isEmpty) {
+      return Text(
+        'Aucun tileset image PokeMap disponible.',
+        style: TextStyle(color: subtle, fontSize: 12),
+      );
+    }
+    return Column(
+      crossAxisAlignment: CrossAxisAlignment.start,
+      children: [
+        Text(
+          'Choisir le tileset image correspondant',
+          style: TextStyle(
+            color: label,
+            fontSize: 13,
+            fontWeight: FontWeight.w700,
+          ),
+        ),
+        const SizedBox(height: 6),
+        Material(
+          type: MaterialType.transparency,
+          child: DropdownButton<ProjectTilesetEntry>(
+            key: const ValueKey('tiled_tsx_workspace.tileset_picker'),
+            value: selectedTileset,
+            isExpanded: true,
+            items: [
+              for (final tileset in tilesets)
+                DropdownMenuItem<ProjectTilesetEntry>(
+                  value: tileset,
+                  child: Text(
+                    '${tileset.name} · ${tileset.id} · ${tileset.relativePath}',
+                    overflow: TextOverflow.ellipsis,
+                  ),
+                ),
+            ],
+            onChanged: onChanged,
+          ),
+        ),
+      ],
+    );
+  }
+}
+
+class _TsxEmptyState extends StatelessWidget {
+  const _TsxEmptyState({
+    required this.onImportPressed,
+  });
+
+  final VoidCallback onImportPressed;
+
+  @override
+  Widget build(BuildContext context) {
+    final label = EditorChrome.primaryLabel(context);
+    final subtle = EditorChrome.subtleLabel(context);
+    return Container(
+      padding: const EdgeInsets.all(18),
+      decoration: BoxDecoration(
+        color: EditorChrome.elevatedPanelBackground(context),
+        borderRadius: BorderRadius.circular(10),
+        border: Border.all(color: EditorChrome.editorIslandRim(context)),
+      ),
+      child: Column(
+        crossAxisAlignment: CrossAxisAlignment.start,
+        children: [
+          Text(
+            'Aucune animation TSX importée.',
+            style: TextStyle(
+              color: label,
+              fontSize: 16,
+              fontWeight: FontWeight.w700,
+            ),
+          ),
+          const SizedBox(height: 6),
+          Text(
+            'Importez un fichier .tsx pour générer des animations Surface depuis un tileset Tiled.',
+            style: TextStyle(color: subtle, fontSize: 12),
+          ),
+          const SizedBox(height: 12),
+          ElevatedButton(
+            key: const ValueKey('tiled_tsx_workspace.empty_import'),
+            onPressed: onImportPressed,
+            child: const Text('Importer un fichier TSX'),
+          ),
+        ],
+      ),
+    );
+  }
+}
+
+class _InfoBlock extends StatelessWidget {
+  const _InfoBlock({
+    required this.title,
+    required this.rows,
+  });
+
+  final String title;
+  final List<(String, String)> rows;
+
+  @override
+  Widget build(BuildContext context) {
+    final label = EditorChrome.primaryLabel(context);
+    final subtle = EditorChrome.subtleLabel(context);
+    return Container(
+      padding: const EdgeInsets.all(10),
+      decoration: BoxDecoration(
+        color: EditorChrome.islandFillElevated(context),
+        borderRadius: BorderRadius.circular(8),
+        border: Border.all(color: EditorChrome.editorIslandRim(context)),
+      ),
+      child: Column(
+        crossAxisAlignment: CrossAxisAlignment.start,
+        children: [
+          Text(
+            title,
+            style: TextStyle(
+              color: label,
+              fontSize: 13,
+              fontWeight: FontWeight.w700,
+            ),
+          ),
+          const SizedBox(height: 8),
+          for (final row in rows)
+            Padding(
+              padding: const EdgeInsets.only(bottom: 3),
+              child: Row(
+                children: [
+                  SizedBox(
+                    width: 130,
+                    child: Text(
+                      row.$1,
+                      style: TextStyle(color: subtle, fontSize: 12),
+                    ),
+                  ),
+                  Expanded(
+                    child: Text(
+                      row.$2,
+                      style: TextStyle(color: label, fontSize: 12),
+                      overflow: TextOverflow.ellipsis,
+                    ),
+                  ),
+                ],
+              ),
+            ),
+        ],
+      ),
+    );
+  }
+}
+
+ProjectSurfaceAtlas? _atlasForBrowser(ProjectSurfaceCatalog catalog) {
+  for (final animation in catalog.animations) {
+    final frames = animation.timeline.frames;
+    if (frames.isEmpty) {
+      continue;
+    }
+    final atlas = catalog.atlasById(frames.first.tileRef.atlasId);
+    if (atlas != null) {
+      return atlas;
+    }
+  }
+  return catalog.atlases.isEmpty ? null : catalog.atlases.first;
+}
+
+String _slugify(String value) {
+  final lower = value.trim().toLowerCase();
+  final slug = lower
+      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
+      .replaceAll(RegExp(r'^-+|-+$'), '');
+  return slug.isEmpty ? 'tsx-import' : slug;
+}
````

### Nouveau fichier : packages/map_editor/test/surface_studio/tiled_tsx_catalog_append_test.dart

````diff
--- /dev/null	2026-04-30 00:57:08
+++ packages/map_editor/test/surface_studio/tiled_tsx_catalog_append_test.dart	2026-04-30 00:33:43
@@ -0,0 +1,135 @@
+import 'package:flutter_test/flutter_test.dart';
+import 'package:map_core/map_core.dart';
+import 'package:map_editor/src/features/surface_studio/importers/tiled_tsx_catalog_append.dart';
+
+void main() {
+  group('appendTiledTsxSurfaceImportToCatalog', () {
+    test('adds atlas and animations to an empty catalog without presets', () {
+      final result = appendTiledTsxSurfaceImportToCatalog(
+        catalog: ProjectSurfaceCatalog(),
+        atlas: _atlas('tech-animations'),
+        animations: [_animation('tech-animations-tile-99')],
+      );
+
+      expect(result.hasErrors, isFalse);
+      expect(result.catalog, isNotNull);
+      expect(result.catalog!.atlasCount, 1);
+      expect(result.catalog!.animationCount, 1);
+      expect(result.catalog!.presetCount, 0);
+      expect(result.catalog!.containsAtlas('tech-animations'), isTrue);
+      expect(
+        result.catalog!.containsAnimation('tech-animations-tile-99'),
+        isTrue,
+      );
+    });
+
+    test('preserves existing presets and never creates a preset', () {
+      final preset = _preset('existing-water');
+      final catalog = ProjectSurfaceCatalog(
+        atlases: [_atlas('existing-atlas')],
+        animations: [_animation('existing-animation')],
+        presets: [preset],
+      );
+
+      final result = appendTiledTsxSurfaceImportToCatalog(
+        catalog: catalog,
+        atlas: _atlas('tech-animations'),
+        animations: [_animation('tech-animations-tile-99')],
+      );
+
+      expect(result.hasErrors, isFalse);
+      expect(result.catalog!.atlases.map((atlas) => atlas.id), [
+        'existing-atlas',
+        'tech-animations',
+      ]);
+      expect(result.catalog!.animations.map((animation) => animation.id), [
+        'existing-animation',
+        'tech-animations-tile-99',
+      ]);
+      expect(result.catalog!.presets, [preset]);
+      expect(result.catalog!.presetCount, 1);
+    });
+
+    test('rejects duplicate atlas id', () {
+      final result = appendTiledTsxSurfaceImportToCatalog(
+        catalog: ProjectSurfaceCatalog(
+          atlases: [_atlas('tech-animations')],
+        ),
+        atlas: _atlas('tech-animations'),
+        animations: [_animation('tech-animations-tile-99')],
+      );
+
+      expect(result.hasErrors, isTrue);
+      expect(result.catalog, isNull);
+      expect(
+        result.errors,
+        contains('Atlas TSX déjà présent dans le catalogue : tech-animations.'),
+      );
+    });
+
+    test('rejects duplicate animation id', () {
+      final result = appendTiledTsxSurfaceImportToCatalog(
+        catalog: ProjectSurfaceCatalog(
+          animations: [_animation('tech-animations-tile-99')],
+        ),
+        atlas: _atlas('tech-animations'),
+        animations: [_animation('tech-animations-tile-99')],
+      );
+
+      expect(result.hasErrors, isTrue);
+      expect(result.catalog, isNull);
+      expect(
+        result.errors,
+        contains(
+          'Animation TSX déjà présente dans le catalogue : tech-animations-tile-99.',
+        ),
+      );
+    });
+  });
+}
+
+ProjectSurfaceAtlas _atlas(String id) {
+  return ProjectSurfaceAtlas(
+    id: id,
+    name: id,
+    tilesetId: 'tech-nature-animations',
+    geometry: SurfaceAtlasGeometry(
+      tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
+      gridSize: SurfaceAtlasGridSize(columns: 2, rows: 2),
+    ),
+  );
+}
+
+ProjectSurfaceAnimation _animation(String id) {
+  return ProjectSurfaceAnimation(
+    id: id,
+    name: id,
+    timeline: SurfaceAnimationTimeline(
+      frames: [
+        SurfaceAnimationFrame(
+          tileRef: SurfaceAtlasTileRef(
+            atlasId: 'tech-animations',
+            column: 0,
+            row: 0,
+          ),
+          durationMs: 100,
+        ),
+      ],
+    ),
+  );
+}
+
+ProjectSurfacePreset _preset(String id) {
+  return ProjectSurfacePreset(
+    id: id,
+    name: id,
+    variantAnimations: SurfaceVariantAnimationRefSet(
+      refs: [
+        SurfaceVariantAnimationRef(
+          role: SurfaceVariantRole.isolated,
+          animationId: 'existing-animation',
+        ),
+      ],
+    ),
+  );
+}
````

### Nouveau fichier : packages/map_editor/test/surface_studio/tiled_tsx_import_ui_test.dart

````diff
--- /dev/null	2026-04-30 00:57:08
+++ packages/map_editor/test/surface_studio/tiled_tsx_import_ui_test.dart	2026-04-30 00:51:35
@@ -0,0 +1,251 @@
+import 'dart:io';
+
+import 'package:flutter/material.dart';
+import 'package:flutter_test/flutter_test.dart';
+import 'package:map_core/map_core.dart';
+import 'package:map_editor/src/features/surface_studio/importers/tiled_tsx_workspace.dart';
+import 'package:path/path.dart' as p;
+
+void main() {
+  group('TiledTsxWorkspace import UI', () {
+    testWidgets('loads a TSX, shows summary, imports atlas and animations',
+        (tester) async {
+      ProjectSurfaceCatalog? changedCatalog;
+
+      await tester.pumpWidget(
+        _wrap(
+          TiledTsxWorkspace(
+            catalog: ProjectSurfaceCatalog(),
+            projectTilesets: const [
+              ProjectTilesetEntry(
+                id: 'tech-nature-animations',
+                name: 'TECH Nature Animations',
+                relativePath: 'Data/Tiled/Assets/TECH-Nature-animations.png',
+              ),
+            ],
+            fileLoader: _FakeTsxFileLoader(_readTechAnimationsTsx()),
+            onSurfaceCatalogChanged: (catalog) => changedCatalog = catalog,
+          ),
+        ),
+      );
+
+      expect(find.text('Aucune animation TSX importée.'), findsOneWidget);
+      await tester.tap(find.byKey(const ValueKey('tiled_tsx_workspace.import')));
+      await tester.pumpAndSettle();
+
+      expect(find.text('Résumé TSX'), findsOneWidget);
+      expect(find.text('TECH-Animations'), findsWidgets);
+      expect(find.text('242 animations'), findsWidgets);
+      expect(find.text('../Assets/TECH-Nature-animations.png'), findsOneWidget);
+      expect(find.textContaining('TECH Nature Animations'), findsWidgets);
+
+      final confirm = find.byKey(
+        const ValueKey('tiled_tsx_workspace.confirm_import'),
+      );
+      await tester.ensureVisible(confirm);
+      await tester.tap(confirm);
+      await tester.pumpAndSettle();
+
+      expect(changedCatalog, isNotNull);
+      expect(changedCatalog!.atlasCount, 1);
+      expect(changedCatalog!.animationCount, 242);
+      expect(changedCatalog!.presetCount, 0);
+      expect(changedCatalog!.containsAtlas('tech-animations'), isTrue);
+      expect(
+        changedCatalog!.containsAnimation('tech-animations-tile-99'),
+        isTrue,
+      );
+      expect(
+        find.text('Import TSX prêt : 242 animations ajoutées.'),
+        findsOneWidget,
+      );
+      expect(find.text('Animations TSX importées'), findsOneWidget);
+      expect(find.text('tech-animations-tile-99'), findsWidgets);
+    });
+
+    testWidgets('blocks import when no matching tileset is available',
+        (tester) async {
+      ProjectSurfaceCatalog? changedCatalog;
+
+      await tester.pumpWidget(
+        _wrap(
+          TiledTsxWorkspace(
+            catalog: ProjectSurfaceCatalog(),
+            projectTilesets: const [],
+            fileLoader: _FakeTsxFileLoader(_readTechAnimationsTsx()),
+            onSurfaceCatalogChanged: (catalog) => changedCatalog = catalog,
+          ),
+        ),
+      );
+
+      await tester.tap(find.byKey(const ValueKey('tiled_tsx_workspace.import')));
+      await tester.pumpAndSettle();
+
+      expect(
+        find.text(
+          'Ajoutez d’abord l’image comme tileset du projet, puis relancez l’import TSX.',
+        ),
+        findsOneWidget,
+      );
+
+      final confirm = find.byKey(
+        const ValueKey('tiled_tsx_workspace.confirm_import'),
+      );
+      expect(tester.widget<ElevatedButton>(confirm).onPressed, isNull);
+      expect(changedCatalog, isNull);
+    });
+
+    testWidgets('shows parser errors for invalid TSX', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          TiledTsxWorkspace(
+            catalog: ProjectSurfaceCatalog(),
+            projectTilesets: const [
+              ProjectTilesetEntry(
+                id: 'mini',
+                name: 'Mini',
+                relativePath: 'mini.png',
+              ),
+            ],
+            fileLoader: const _FakeTsxFileLoader('<not-xml>'),
+          ),
+        ),
+      );
+
+      await tester.tap(find.byKey(const ValueKey('tiled_tsx_workspace.import')));
+      await tester.pumpAndSettle();
+
+      expect(find.text('Erreur import TSX'), findsOneWidget);
+      expect(find.textContaining('XML'), findsWidgets);
+    });
+
+    testWidgets('blocks TSX without animations', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          TiledTsxWorkspace(
+            catalog: ProjectSurfaceCatalog(),
+            projectTilesets: const [
+              ProjectTilesetEntry(
+                id: 'static',
+                name: 'Static',
+                relativePath: 'static.png',
+              ),
+            ],
+            fileLoader: const _FakeTsxFileLoader(_staticTsx),
+          ),
+        ),
+      );
+
+      await tester.tap(find.byKey(const ValueKey('tiled_tsx_workspace.import')));
+      await tester.pumpAndSettle();
+
+      expect(find.text('Le TSX ne contient aucune animation.'), findsOneWidget);
+      final confirm = find.byKey(
+        const ValueKey('tiled_tsx_workspace.confirm_import'),
+      );
+      expect(tester.widget<ElevatedButton>(confirm).onPressed, isNull);
+    });
+
+    testWidgets('reports duplicate atlas id without mutating the catalog',
+        (tester) async {
+      ProjectSurfaceCatalog? changedCatalog;
+      final existing = ProjectSurfaceCatalog(
+        atlases: [
+          ProjectSurfaceAtlas(
+            id: 'tech-animations',
+            name: 'TECH-Animations',
+            tilesetId: 'tech-nature-animations',
+            geometry: SurfaceAtlasGeometry(
+              tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
+              gridSize: SurfaceAtlasGridSize(columns: 98, rows: 109),
+            ),
+          ),
+        ],
+      );
+
+      await tester.pumpWidget(
+        _wrap(
+          TiledTsxWorkspace(
+            catalog: existing,
+            projectTilesets: const [
+              ProjectTilesetEntry(
+                id: 'tech-nature-animations',
+                name: 'TECH Nature Animations',
+                relativePath: 'Data/Tiled/Assets/TECH-Nature-animations.png',
+              ),
+            ],
+            fileLoader: _FakeTsxFileLoader(_readTechAnimationsTsx()),
+            onSurfaceCatalogChanged: (catalog) => changedCatalog = catalog,
+          ),
+        ),
+      );
+
+      await tester.tap(find.byKey(const ValueKey('tiled_tsx_workspace.import')));
+      await tester.pumpAndSettle();
+      final confirm = find.byKey(
+        const ValueKey('tiled_tsx_workspace.confirm_import'),
+      );
+      await tester.ensureVisible(confirm);
+      await tester.tap(confirm);
+      await tester.pumpAndSettle();
+
+      expect(changedCatalog, isNull);
+      expect(
+        find.text('Atlas TSX déjà présent dans le catalogue : tech-animations.'),
+        findsOneWidget,
+      );
+    });
+  });
+}
+
+Widget _wrap(Widget child) {
+  return MaterialApp(
+    home: Scaffold(
+      body: SizedBox(
+        width: 1300,
+        height: 900,
+        child: child,
+      ),
+    ),
+  );
+}
+
+String _readTechAnimationsTsx() {
+  final repoRoot = Directory.current.parent.parent;
+  final sdkProject = repoRoot
+      .listSync()
+      .whereType<Directory>()
+      .firstWhere((dir) => p.basename(dir.path).contains('sdk_test_project'));
+  final tsxFile = File(
+    p.join(
+      sdkProject.path,
+      'Data',
+      'Tiled',
+      'Tilesets',
+      'TECH-Animations.tsx',
+    ),
+  );
+  return tsxFile.readAsStringSync();
+}
+
+final class _FakeTsxFileLoader implements TiledTsxFileLoader {
+  const _FakeTsxFileLoader(this.xml);
+
+  final String xml;
+
+  @override
+  Future<TiledTsxLoadedFile?> pickAndLoadTsx() async {
+    return TiledTsxLoadedFile(
+      path: '/tmp/TECH-Animations.tsx',
+      fileName: 'TECH-Animations.tsx',
+      xml: xml,
+    );
+  }
+}
+
+const _staticTsx = '''
+<?xml version="1.0" encoding="UTF-8"?>
+<tileset name="Static" tilewidth="32" tileheight="32" tilecount="1" columns="1">
+ <image source="../Assets/static.png" width="32" height="32"/>
+</tileset>
+''';
````

### Nouveau fichier : packages/map_editor/test/surface_studio/tiled_tsx_workspace_tab_test.dart

````diff
--- /dev/null	2026-04-30 00:57:08
+++ packages/map_editor/test/surface_studio/tiled_tsx_workspace_tab_test.dart	2026-04-30 00:42:29
@@ -0,0 +1,87 @@
+import 'package:flutter/cupertino.dart';
+import 'package:flutter/material.dart';
+import 'package:flutter_test/flutter_test.dart';
+import 'package:map_core/map_core.dart';
+import 'package:map_editor/src/features/surface_studio/importers/tiled_tsx_workspace.dart';
+import 'package:map_editor/src/features/surface_studio/surface_studio_panel.dart';
+
+void main() {
+  testWidgets('Surface Studio exposes a first-level TSX workspace',
+      (tester) async {
+    await tester.pumpWidget(
+      _wrapPanel(
+        SurfaceStudioPanel(
+          readModel: buildSurfaceStudioReadModelFromCatalog(
+            ProjectSurfaceCatalog(),
+          ),
+          projectTilesets: const [],
+          tsxFileLoader: const _NoopTsxFileLoader(),
+        ),
+      ),
+    );
+
+    expect(find.byKey(const ValueKey('surface_studio.primary_tabs')), findsOne);
+    expect(find.text('Catalogue Surface'), findsOneWidget);
+    expect(find.text('TSX'), findsOneWidget);
+    expect(find.text('Diagnostics'), findsOneWidget);
+
+    await tester.tap(find.byKey(const ValueKey('surface_studio.tab.tsx')));
+    await tester.pumpAndSettle();
+
+    expect(find.byKey(const ValueKey('surface_studio.tsx_workspace')), findsOne);
+    expect(find.text('Aucune animation TSX importée.'), findsOneWidget);
+    expect(
+      find.byKey(const ValueKey('tiled_tsx_workspace.empty_import')),
+      findsOneWidget,
+    );
+    expect(find.text('Détails avancés'), findsNothing);
+  });
+
+  testWidgets('Diagnostics remain available as their own top-level workspace',
+      (tester) async {
+    await tester.pumpWidget(
+      _wrapPanel(
+        SurfaceStudioPanel(
+          readModel: buildSurfaceStudioReadModelFromCatalog(
+            ProjectSurfaceCatalog(),
+          ),
+          projectTilesets: const [],
+          tsxFileLoader: const _NoopTsxFileLoader(),
+        ),
+      ),
+    );
+
+    await tester.tap(
+      find.byKey(const ValueKey('surface_studio.tab.diagnostics')),
+    );
+    await tester.pumpAndSettle();
+
+    expect(
+      find.byKey(const ValueKey('surface_studio.diagnostics_workspace')),
+      findsOne,
+    );
+    expect(find.text('Détails avancés'), findsOneWidget);
+  });
+}
+
+Widget _wrapPanel(Widget child) {
+  return MaterialApp(
+    home: MediaQuery(
+      data: const MediaQueryData(size: Size(2048, 1120)),
+      child: CupertinoPageScaffold(
+        child: SizedBox(
+          width: 2048,
+          height: 1120,
+          child: child,
+        ),
+      ),
+    ),
+  );
+}
+
+final class _NoopTsxFileLoader implements TiledTsxFileLoader {
+  const _NoopTsxFileLoader();
+
+  @override
+  Future<TiledTsxLoadedFile?> pickAndLoadTsx() async => null;
+}
````

## 20. Auto-Review

Fonctionnalité réelle : le workflow TSX est visible dans un onglet de premier niveau et peut importer un TSX via loader injectable.
Qualité UI : la navigation primaire réduit la dépendance au drawer avancé sans supprimer les flows existants.
Qualité données : l’import réutilise TSX-1/TSX-2, conserve les frames/durations TSX et ajoute atlas + animations au catalogue de travail.
Risques restants : pas de QA interactive macOS complète ; matching d’image volontairement simple ; pas encore d’amélioration UX des slots de rôle TSX ; deux diffs Mistral hors périmètre restent présents au statut final.
Non-objectifs TSX-6 : respectés.
