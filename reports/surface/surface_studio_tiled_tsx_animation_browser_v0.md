# Lot TSX-3 — Surface Studio TSX Animation Browser / Region Picker V0

## 1. Verdict

V0 implémentée.

Surface Studio dispose maintenant d’un browser d’animations TSX dans le drawer avancé `Catalogue & diagnostics`. Le browser lit les `ProjectSurfaceAnimation` déjà présents dans le catalogue de travail, les liste, les filtre, permet une sélection locale multi-animation et affiche une preview frame par frame basée sur les `SurfaceAnimationFrame.tileRef` exactes.

Le lot ne crée aucun `ProjectSurfacePreset`, ne devine aucun rôle Surface, ne mute pas le `ProjectManifest`, ne sauvegarde pas sur disque et ne fait aucun appel IA / PixelLab / MCP.

Context Mode : indisponible dans cet environnement. La commande `ctx stats` retourne `zsh:1: command not found: ctx`.

## 2. Audit initial

Commande initiale :

```text
pwd
/Users/karim/Project/pokemonProject
```

`git status --short --untracked-files=all` initial :

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

`git diff --stat` initial :

```text
 packages/map_editor/test/shell_chrome_test_harness.dart              | 2 +-
 .../map_editor/test/surface_studio/surface_studio_panel_test.dart    | 2 +-
 .../test/surface_studio/surface_studio_workspace_entry_test.dart     | 4 ++--
 packages/map_runtime/test/battle_overlay_component_test.dart         | 4 +---
 packages/map_runtime/test/npc_runtime_presence_test.dart             | 3 +--
 packages/map_runtime/test/playable_map_game_input_test.dart          | 3 +--
 packages/map_runtime/test/trainer_battle_request_test.dart           | 2 +-
 packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart      | 5 ++---
 8 files changed, 10 insertions(+), 15 deletions(-)
```

Fichiers audités :

```text
packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_animated_tileset_parser.dart
packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_surface_animation_importer.dart
packages/map_editor/test/surface_studio/tiled_tsx_animated_tileset_parser_test.dart
packages/map_editor/test/surface_studio/tiled_tsx_surface_animation_importer_test.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_screen.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_catalog_browser.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_detected_animations_panel.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_animation_preview.dart
packages/map_editor/lib/src/features/surface_studio/preview/surface_studio_surface_preview_renderer.dart
packages/map_editor/lib/src/features/surface_studio/preview/surface_studio_preview_panel.dart
packages/map_core/lib/src/models/surface.dart
packages/map_core/lib/src/models/surface_catalog.dart
```

Réponses d’audit :

1. Surface Studio affichait déjà des animations via `SurfaceStudioCatalogBrowser` / `SurfaceStudioAnimationDetailView` dans le drawer avancé, et via `SurfaceStudioDetectedAnimationsPanel` pour les animations générées. Ces vues ne permettaient pas de filtrer 242 animations TSX ni d’en sélectionner plusieurs pour un futur lot.
2. Il existait un browser de catalogue Surface, mais pas un browser d’animations TSX avec recherche, sélection locale et inspection de frames.
3. Il n’existait pas de preview dédiée à une `ProjectSurfaceAnimation`. La preview existante `SurfaceStudioVerticalAtlasAnimationPreview` travaille sur une convention d’atlas vertical locale par colonne, pas sur les `tileRef` arbitraires issus d’un TSX.
4. Le pattern `drawImageRect` existant a été réutilisé en esprit, mais un composant dédié était nécessaire parce que TSX doit lire les `SurfaceAnimationFrame.tileRef.column,row` exacts, sans convention `row++`.
5. Les bytes d’image atlas sont résolus dans `SurfaceStudioPanel` via `resolveSurfaceStudioAtlasImagePreview(projectRootPath, projectTilesets, atlas.tilesetId)`, puis lus avec cache local si le chemin absolu existe.
6. Le point d’intégration choisi est le drawer avancé `Catalogue & diagnostics`, déjà fermé par défaut et ouvert explicitement depuis le header. Cela évite de recréer un second wizard ou de perturber les 5 étapes.
7. Les animations TSX importées ne sont pas automatiquement dans le catalogue : TSX-2 produit un résultat pur. TSX-3 lit les animations du catalogue de travail quand elles y sont présentes, et les tests utilisent aussi `importTiledTsxSurfaceAnimationsFromXml(...)` comme source pure.
8. Le meilleur point d’entrée V0 est `Catalogue & diagnostics -> Animations TSX importées`. Un futur TSX-4 pourra partir de la sélection locale pour construire explicitement un preset.

## 3. Emplacement UI choisi

Le browser TSX est intégré dans `SurfaceStudioPanel`, dans le drawer avancé construit par `_AdvancedDetailsSection`.

Raisons :

```text
- le drawer est déjà l’espace “Catalogue & diagnostics” ;
- il est fermé par défaut ;
- il ne remet pas de legacy sous le wizard ;
- il peut lire le catalogue de travail sans mutation ;
- il prépare TSX-4 sans créer de surface automatiquement.
```

Un test existant du drawer a été renforcé pour vérifier que `Animations TSX importées` apparaît dans `Catalogue & diagnostics`.

## 4. Modèles / composants créés

Fichiers créés :

```text
packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_animation_browser_models.dart
packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_animation_browser.dart
packages/map_editor/test/surface_studio/tiled_tsx_animation_browser_test.dart
reports/surface/surface_studio_tiled_tsx_animation_browser_v0.md
```

Modèles purs ajoutés :

```text
TiledTsxAnimationBrowserItem
TiledTsxAnimationBrowserFilter
buildTiledTsxAnimationBrowserItems(...)
filterTiledTsxAnimationBrowserItems(...)
```

Composants UI ajoutés :

```text
TiledTsxAnimationBrowser
TiledTsxSurfaceAnimationPreview
```

## 5. Browser : recherche, liste, sélection

Le browser affiche :

```text
- titre : Animations TSX importées ;
- sous-titre indiquant que frames et durées viennent du fichier Tiled ;
- métriques : nombre d’animations, atlas, taille de tuile, source ;
- champ de recherche ;
- liste compacte ;
- sélection locale multi-animation ;
- compteur de sélection ;
- action Vider ;
- option Sélection seulement.
```

La recherche matche :

```text
- animationId ;
- name ;
- baseTileId extrait de l’id `*-tile-N` ou du nom.
```

La sélection :

```text
- reste dans l’état local du widget ;
- appelle seulement un callback optionnel ;
- ne modifie pas ProjectSurfaceCatalog ;
- ne modifie pas ProjectManifest ;
- ne sauvegarde rien.
```

## 6. Preview animation

La preview reçoit :

```text
ProjectSurfaceAtlas?
ProjectSurfaceAnimation
Uint8List? atlasImageBytes
```

Elle affiche :

```text
- id animation ;
- frame count ;
- durée totale ;
- frame X / N ;
- column,row de la frame active ;
- durationMs de la frame active ;
- previous / next / play-pause ;
- strip horizontale des frames ;
- fallback si image absente.
```

Le crop utilise uniquement les frames existantes :

```text
sourceX = frame.tileRef.column * atlas.geometry.tileSize.width
sourceY = frame.tileRef.row * atlas.geometry.tileSize.height
sourceW = atlas.geometry.tileSize.width
sourceH = atlas.geometry.tileSize.height
```

Il n’y a pas de convention verticale, pas de `row++` automatique et pas de tentative de déduire des rôles Surface.

Fallback visible :

```text
Image atlas indisponible — frames listées sans aperçu visuel.
```

## 7. Exemple tile 99

Depuis `TECH-Animations.tsx`, TSX-2 produit :

```text
ProjectSurfaceAnimation id = tech-animations-tile-99
name = TECH-Animations tile 99
frameCount = 16
durationTotalMs = 1600
```

Frames inspectées par TSX-3 :

```text
Frame 1 / 16 : column 1, row 1, durationMs 100
Frame 2 / 16 : column 7, row 1, durationMs 100
...
Dernière frame : column 91, row 1, durationMs 100
```

Cela confirme que TSX-3 ne revient pas au modèle `columns=roles rows=frames`.

## 8. Tests

Commande :

```text
cd packages/map_editor && flutter test test/surface_studio/tiled_tsx_animated_tileset_parser_test.dart --no-pub --reporter expanded
```

Sortie finale exacte :

```text
00:00 +7: All tests passed!
```

Commande :

```text
cd packages/map_editor && flutter test test/surface_studio/tiled_tsx_surface_animation_importer_test.dart --no-pub --reporter expanded
```

Sortie finale exacte :

```text
00:00 +7: All tests passed!
```

Commande :

```text
cd packages/map_editor && flutter test test/surface_studio/tiled_tsx_animation_browser_test.dart --no-pub --reporter expanded
```

Sortie finale exacte :

```text
00:01 +7: All tests passed!
```

Commande additionnelle d’intégration drawer :

```text
cd packages/map_editor && flutter test test/surface_studio/surface_studio_panel_test.dart --no-pub --reporter expanded
```

Sortie finale exacte :

```text
00:01 +4: All tests passed!
```

Commande :

```text
cd packages/map_editor && flutter test test/surface_studio --no-pub --reporter expanded
```

Sortie finale exacte :

```text
00:24 +384: All tests passed!
```

Note : le lot complet Surface Studio affiche aussi un warning connu de `macos_ui` sur la résolution lente de couleur accent macOS. Il ne vient pas du browser TSX et ne fait pas échouer les tests.

## 9. Analyze

Commande :

```text
cd packages/map_editor && flutter analyze lib/src/features/surface_studio
```

Résultat exact :

```text
No issues found! (ran in 2.1s)
```

## 10. Non-objectifs confirmés

Confirmé :

```text
- aucun ProjectSurfacePreset créé ;
- aucun mapping automatique role -> animation ;
- aucune création automatique de surface eau/lave/glace ;
- aucune mutation ProjectManifest ;
- aucune sauvegarde disque ;
- aucun appel Mistral ;
- aucun appel PixelLab ;
- aucun appel MCP ;
- aucune génération d’image ;
- aucune modification map_gameplay ;
- aucune modification map_runtime ;
- aucune modification map_battle ;
- aucune migration legacy ;
- aucune refonte complète de Surface Studio.
```

## 11. Limites restantes

Limites V0 assumées :

```text
- TSX-3 n’ajoute pas encore de bouton d’import fichier TSX depuis l’UI ;
- il affiche les animations déjà produites par TSX-2 quand elles sont dans le catalogue de travail ;
- la sélection locale n’est pas persistée ;
- aucun groupe/région Surface n’est créé ;
- aucun rôle Surface n’est proposé ;
- la preview visuelle dépend de la résolution de l’image atlas via ProjectTilesetEntry ;
- si l’image est indisponible, la liste des frames reste inspectable sans crop visuel.
```

## 12. Roadmap TSX suivante

Suite recommandée :

```text
TSX-4 — Build Surface preset from selected TSX animations V0
TSX-5 — Optional Mistral grouping assistant for TSX animations
```

TSX-4 devrait partir de la sélection locale et demander explicitement à l’utilisateur comment associer les animations aux rôles Surface. Il ne doit pas deviner automatiquement un preset complet.

## 13. Git status final

Commande :

```text
git status --short --untracked-files=all
```

Sortie :

```text
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
 M packages/map_editor/test/shell_chrome_test_harness.dart
 M packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
 M packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart
 M packages/map_runtime/test/battle_overlay_component_test.dart
 M packages/map_runtime/test/npc_runtime_presence_test.dart
 M packages/map_runtime/test/playable_map_game_input_test.dart
 M packages/map_runtime/test/trainer_battle_request_test.dart
 M packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart
?? packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_animation_browser.dart
?? packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_animation_browser_models.dart
?? packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_surface_animation_importer.dart
?? packages/map_editor/test/surface_studio/tiled_tsx_animation_browser_test.dart
?? packages/map_editor/test/surface_studio/tiled_tsx_surface_animation_importer_test.dart
?? reports/surface/surface_studio_tiled_tsx_animation_browser_v0.md
?? reports/surface/surface_studio_tiled_tsx_animation_import_v0.md
```

Les fichiers `map_runtime/test/*` et les ajustements hors TSX-3 visibles ci-dessus étaient déjà présents dans le worktree avant ce lot et n’ont pas été modifiés par TSX-3.
