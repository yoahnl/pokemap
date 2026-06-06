# NS-SCENES-V1-84 — Cinematic Map Backdrop Preview Renderer V0

## 1. Résumé exécutif

V1-84 affiche enfin un décor de map statique dans le Builder.

V1-84 ne lance toujours pas la cinématique.

Le lot branche le read model pur V1-83 (`CinematicMapBackdropPreviewModel`) dans le Cinematic Builder. Quand `stageContext.backdropMode == projectMap` et qu'une snapshot `MapData` est disponible, la zone preview affiche un décor sandbox read-only structurel : label map, dimensions, couches visuelles, cadrage/zoom et état read-only. Les autres statuts affichent un fallback humain lisible.

## 2. Gate 0

Commande exécutée depuis `/Users/karim/Project/pokemonProject` :

```text
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git log --oneline -n 15
```

Sortie utile :

```text
/Users/karim/Project/pokemonProject
main
git status/diff/diff --name-only : sortie vide au départ
50a43df8 feat(narrative): add cinematic map backdrop preview model, tests, and roadmap updates (NS-SCENES-V1-83)
c76550a6 feat(narrative): update cinematic workspaces, tests, and roadmap reports (NS-SCENES-V1-82)
```

## 3. Fichiers lus

Fichiers de contexte lus : `AGENTS.md`, `agent_rules.md`, roadmaps scènes, rapports V1-77/V1-81/V1-82/V1-83, read models core V1-83, modèles `CinematicAsset`/`ProjectManifest`/`MapData`/`MapLayer`, Builder, Library et tests associés.

## 4. Synthèse des sub-agents et arbitrages

Sub-agent A — conclusion : brancher le rendu dans `_PreviewSandbox`, sans toucher aux proportions preview/timeline ni aux transports.

Sub-agent B — conclusion : V1-83 suffit pour un renderer V0 honnête ; ne pas inventer de fausses tiles et ne pas étendre `map_core` pour ce lot.

Sub-agent C — conclusion : réutiliser la snapshot `MapData` déjà chargée par `CinematicsLibraryWorkspace`, la conserver côté Library et construire le backdrop model au niveau editor.

Sub-agent D — conclusion : corriger le test Builder rouge connu en ciblant les contrôles d'édition attendus, puis ajouter les tests anti-mutation/anti-playback/anti-actor.

Divergences identifiées : V1-83 ne permet pas un rendu final de tiles/assets. Arbitrage final : afficher un rendu structurel utile et honnête, avec layers visibles et cadrage, sans prétendre à une preview finale.

## 5. Design Gate — Cinematic Map Backdrop Preview Renderer V0

1. Contrat consommé : `CinematicMapBackdropPreviewModel`, status, diagnostics, layers, size summary, viewport recommendation.
2. Construction du modèle : dans `CinematicsLibraryWorkspace`, pas dans `map_core` ni dans le Builder.
3. Stage map : `ProjectManifest.maps` via `asset.mapId`.
4. MapData : snapshot editor déjà chargée par `onLoadStageMapSnapshot`.
5. Chargement dans build : évité ; `build()` déclenche seulement l'ensure existant, avec garde de génération async.
6. Passage au Builder : nouveau paramètre optionnel `backdropPreviewModel`.
7. Placement : `_PreviewSandbox` délègue à `CinematicMapBackdropPreviewPanel` si le modèle existe.
8. Available : rendu sandbox read-only avec label, dimensions, layers, viewport et message "Preview réelle à venir."
9-14. Statuts non available : fallback humain pour disabled, missing, unknown, unavailable, mismatch, tileset missing.
15. Suffisance V1-83 : oui pour V0 structurel.
16. Extension core : aucune.
17. Fake tiles/map : aucune tile inventée ; affichage abstrait des layers réellement projetés.
18. MapCanvas complet : non utilisé.
19. Flame/runtime : non importés.
20. Proportions : `_PreviewSandbox` conserve la hauteur calculée existante ; la timeline n'est pas redimensionnée.
21. Transports : restent disabled.
22. Timeline/duration/resize/probe : tests dédiés, dont un avec backdrop visible.
23. Pickers map-aware : tests dédiés avec backdrop visible.
24. Character Library : test dédié avec backdrop visible.
25. Test rouge connu : assertion obsolète remplacée par absence ciblée de champs d'édition.
26. Non-mutation : tests `project.toJson()` et `MapData.toJson()`.
27. Aucun acteur rendu : test sur absence d'entité/acteur dans le renderer.
28. Aucun playback : transports disabled, aucun timer/runtime.
29. Visual Gate : PNG Flutter sous `reports/narrativeStudio/scenes/screenshots/`.
30. Prochain lot : `NS-SCENES-V1-85 — Cinematic Map Backdrop Visual Primitives V0`.

## 6. Scope réalisé

Création d'un panel editor pur : `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart`.

Branchement Builder : `CinematicBuilderWorkspace` accepte `backdropPreviewModel` et `_PreviewSandbox` affiche le renderer quand présent.

Wiring Library : conservation de la snapshot `MapData`, construction du modèle via `buildCinematicMapBackdropPreviewModel`, clear du cache à la fermeture Builder.

## 7. Correction préflight du test Builder rouge connu

Failure reproduite :

```text
Expected: no widgets with CupertinoTextField under cinematic-builder-inspector-placeholder
Actual: found CupertinoTextField placeholder "Nom de l’acteur"
```

Correction : le test `lists timeline steps in order with read-only details` ne vérifie plus l'absence de tout `CupertinoTextField` dans l'inspecteur, car le renommage acteur est désormais attendu. Il vérifie plutôt l'absence des contrôles d'édition timeline hors scope.

## 8. Contrat V1-83 consommé

Le renderer consomme `status`, `mapLabel`, `sizeSummary`, `viewportRecommendation`, `layers`, `diagnostics` et `isAvailable`.

## 9. Wiring du read model côté editor

`CinematicsLibraryWorkspace` stocke `_stageMapSnapshot` et `_stageMapSnapshotMapId`, puis construit un `CinematicMapBackdropPreviewModel?` uniquement quand `backdropMode == projectMap`.

## 10. Renderer backdrop sandbox

Le renderer affiche une projection abstraite de la map : cadre read-only, couches visibles empilées, légende layer, cadrage/zoom et message de limite. Il ne dessine pas d'acteurs, d'events, de collisions ou de sprites.

## 11. États non available / fallbacks

Tous les statuts demandés sont couverts : `backdropDisabled`, `missingStageMap`, `stageMapUnknown`, `mapDataUnavailable`, `mapDataMismatch`, `tilesetUnavailable`.

## 12. Diagnostics affichés

Les diagnostics du read model sont affichés en badges de sévérité, sans stack trace, JSON ou dump technique comme message principal.

## 13. Viewport / cadrage

V1-84 affiche `fitMap` / `centerMap` sous forme de badge et le zoom recommandé. Aucun pan/zoom interactif ni caméra runtime.

## 14. Préservation timeline / duration / resize / probe

Tests ajoutés avec backdrop visible : édition de durée, resize handle, mouse probe, transports disabled.

## 15. Préservation pickers map-aware / Character Library

Tests ajoutés avec backdrop visible pour actor `mapEntity`, target `mapEvent`, et Character Library picker.

## 16. Restrictions anti-runtime / anti-Flame / anti-playback

Aucun import runtime/Flame, aucun `PlayableMapGame`, aucun `GameWidget`, aucun timer, aucun playback.

## 17. Design system

Le nouveau panel utilise `context.pokeMapColors`, `PokeMapIconTile`, `PokeMapBadge` et `PokeMapTone`. Aucune couleur hardcodée ajoutée dans le nouveau panel.

## 18. Tests ajoutés ou modifiés

Tests ajoutés : available backdrop, fallbacks tous statuts, fallback mapData unavailable, duration/resize/probe avec backdrop, map-aware pickers avec backdrop, Character Library avec backdrop, Library snapshot -> Builder.

Test modifié : préflight Builder obsolète.

## 19. Visual Gate

Chemin :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_84_cinematic_map_backdrop_preview_renderer_v0.png
```

Preuve :

```text
PNG image data, 1663 x 926, 8-bit/color RGBA, non-interlaced
253K
sha256 c005528da38d6af1766c949749528154323ef4e5cc896919bb141631915d1e81
```

## 20. Commandes exécutées

Voir l'Evidence Pack pour les sorties détaillées.

## 21. Résultats des tests

Core ciblé : vert.

Builder complet : `+148`, `All tests passed!`.

Library complète : `+15`, `All tests passed!`.

Visual Gate : `+148`, `All tests passed!`.

## 22. Analyze

`map_core dart analyze` : `No issues found!`.

Analyse editor ciblée : `No issues found!`.

Analyse globale editor : rouge sur dette hors lot existante (`pokemon_sdk_move_catalog_converter.dart`, `sync_pokemon_sdk_moves_catalog_use_case.dart`, infos historiques).

## 23. Checks anti-scope

Pas de modification dans `map_runtime`, `map_gameplay`, `map_battle`, `examples`, `selbrume`.

Les scans sur diff ajouté ne montrent aucun runtime/Flame/playback/actor-render/couleur hardcodée/Selbrume/image IA ajouté. Deux lignes de test `mapId: null` / `map_missing` existent uniquement pour tester les fallbacks.

## 24. Fichiers créés

```text
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart
reports/narrativeStudio/scenes/ns_scenes_v1_84_cinematic_map_backdrop_preview_renderer_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_84_evidence_pack.md
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_84_cinematic_map_backdrop_preview_renderer_v0.png
```

## 25. Fichiers modifiés

```text
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
packages/map_editor/test/cinematics_library_workspace_test.dart
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
```

## 26. Roadmaps mises à jour

V1-84 est marqué DONE dans les deux roadmaps, avec la recommandation V1-85.

## 27. Limites connues

Le rendu V0 est structurel/abstrait. Il n'affiche pas encore les vrais tiles/assets comme une preview finale.

## 28. Non-objectifs confirmés

Pas de runtime, Flame, PlayableMapGame, playback, acteurs rendus, Character Library sprite rendu, pathfinding, collision, triggers, overlays event/entity, image IA, données Selbrume.

## 29. Evidence Pack

Voir `reports/narrativeStudio/scenes/ns_scenes_v1_84_evidence_pack.md`.

## 30. Auto-review critique

Point fort : le lot reste borné et prouvé par tests avec backdrop visible.

Risque restant : le rendu abstrait peut être visuellement moins proche de l'objectif final qu'un rendu tile/assets. C'est volontaire pour V0, car V1-83 ne fournit pas encore de primitives graphiques finales.

## 31. Recommandation pour le prochain lot

`NS-SCENES-V1-85 — Cinematic Map Backdrop Visual Primitives V0`.
