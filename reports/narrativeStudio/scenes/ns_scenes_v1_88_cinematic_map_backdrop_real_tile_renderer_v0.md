# NS-SCENES-V1-88 — Cinematic Map Backdrop Real Tile Renderer V0

Date : 2026-06-06

## 1. Resume executif

Statut : `DONE` avec limites explicites.

Phrase canonique : V1-88 affiche un decor de map statique avec de vraies tiles resolues cote editor dans la preview du Cinematic Builder. V1-88 ne lance pas la cinematique, ne rend pas les acteurs et ne branche pas le runtime.

Demande : Karim a fourni le prompt V1-88 et a demande d'utiliser des sub-agents/passes au besoin ainsi que Codex computer use pour verifier par screenshot/manipulation. Le lot devait rester strictement editor-only/read-only et respecter les proportions obtenues en V1-86.

Decision retenue : Option E materialisee. Le Builder recoit un plan de rendu optionnel, construit depuis `MapData`, `ProjectManifest` et des images tileset resolues en amont. Le rendu est un `CustomPainter` dedie au Cinematic Builder, pas `MapCanvas`, pas Flame, pas runtime.

Prochain lot exact recommande : `NS-SCENES-V1-89 — Cinematic Actor Display Preview Prep Contract`.

## 2. Ce qui a ete implemente

Code genere par ce lot :

- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_tile_render_plan.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_tile_renderer.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_tileset_asset_registry.dart`

Code complet des nouveaux fichiers : voir `reports/narrativeStudio/scenes/ns_scenes_v1_88_evidence_pack.md`, section "Code genere".

Integrations modifiees :

- `cinematic_map_backdrop_preview_panel.dart` accepte un `CinematicMapBackdropTileRenderPlan`, rend une vue bitmap quand les instructions existent, et conserve le fallback structurel V1-86 sinon.
- `cinematic_builder_workspace.dart` propage le plan de rendu vers la preview sandbox sans playback.
- `cinematics_library_workspace.dart` expose un callback optionnel `BuildCinematicBackdropTileRenderPlanCallback` pour fournir le plan sans coupler le Builder au workspace parent.
- `cinematic_builder_workspace_test.dart` ajoute les tests RED/GREEN, fallback, plan et Visual Gate.
- `cinematics_library_workspace_test.dart` aligne les libelles UX sur `Carte du projet (statique)` et `Fallback structurel`.

Le plan conserve l'opacite des calques visibles et le painter l'applique lors du `drawImageRect`.

## 3. UX visible

Nouveaux libelles principaux :

- `Carte du projet (statique)`
- `Tiles reelles affichees`
- `Decor seul`
- `Sans acteurs`
- `Sans lecture`
- `Fallback structurel`

Ces libelles evitent de vendre une preview jouable : le decor est reel, mais la scene reste statique.

## 4. Screenshot / Visual Gate

Artefact produit :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_88_cinematic_map_backdrop_real_tile_renderer_v0.png
```

Preuve fichier :

```text
PNG image data, 1663 x 926, 8-bit/color RGBA, non-interlaced
SHA-256 407468fb38996324c12d024c0f3fc93419181bc3fa30612457edfac24f694089
```

Observation visuelle : la capture montre le Cinematic Builder avec une map statique composee de tiles bitmap, les badges `Decor seul`, `Sans acteurs`, `Sans lecture`, la timeline conservee, l'inspecteur visible, et aucun acteur rendu.

## 5. Verification RED/GREEN

Test RED initial :

```text
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'renders real tile map backdrop when tileset image is available'
```

Resultat RED : echec attendu, car `cinematic_map_backdrop_tile_render_plan.dart` n'existait pas encore, `CinematicMapBackdropTileRenderPlan` et `backdropTileRenderPlan` etaient inconnus.

Tests verts ciblés :

```text
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'renders real tile map backdrop when tileset image is available'
00:03 +1: All tests passed!
```

```text
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'falls back to structural backdrop when tileset image is unavailable'
00:02 +1: All tests passed!
```

```text
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'builds bitmap instructions only from visible tile layers'
00:03 +1: All tests passed!
```

```text
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'renders static map backdrop preview when backdrop model is available'
00:02 +1: All tests passed!
```

```text
cd packages/map_editor && flutter test --reporter=compact test/cinematics_library_workspace_test.dart --plain-name 'wires loaded stage map snapshot into static backdrop preview'
00:03 +1: All tests passed!
```

Visual Gate :

```text
cd packages/map_editor && flutter test --update-goldens --dart-define=NS_SCENES_V1_88_CAPTURE_CINEMATIC_MAP_BACKDROP_REAL_TILE_RENDERER=true --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'captures V1-88 cinematic map backdrop real tile renderer when requested'
00:03 +1: All tests passed!
```

Suites completes relancees :

```text
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart
00:23 +155: All tests passed!
```

```text
cd packages/map_editor && flutter test --reporter=compact test/cinematics_library_workspace_test.dart
00:05 +15: All tests passed!
```

Core non-regression :

```text
cd packages/map_core && dart test --reporter=compact test/cinematic_map_backdrop_preview_model_test.dart
00:01 +19: All tests passed!
```

```text
cd packages/map_core && dart test --reporter=compact test/cinematic_stage_map_source_catalog_test.dart
00:01 +7: All tests passed!
```

```text
cd packages/map_core && dart test --reporter=compact test/cinematic_asset_test.dart
00:01 +14: All tests passed!
```

```text
cd packages/map_core && dart test --reporter=compact test/project_manifest_cinematics_test.dart
00:01 +9: All tests passed!
```

```text
cd packages/map_core && dart analyze
Analyzing map_core...
No issues found!
```

Analyse ciblee editor :

```text
cd packages/map_editor && flutter analyze --no-fatal-infos <8 fichiers touches>
Analyzing 8 items...
No issues found! (ran in 1.6s)
```

Analyse globale editor :

```text
cd packages/map_editor && flutter analyze
344 issues found. (ran in 3.2s)
```

Limite de l'analyse globale : les erreurs bloquantes sont hors scope V1-88, principalement dans `lib/src/application/services/pokemon_sdk_move_catalog_converter.dart` et `lib/src/application/use_cases/sync_pokemon_sdk_moves_catalog_use_case.dart` autour de types/parametres Pokemon SDK absents. Les fichiers V1-88 passes a l'analyse ciblee sont propres.

## 6. Anti-scope

Controles effectues :

- aucun diff dans `packages/map_runtime`, `packages/map_gameplay`, `packages/map_battle`, `examples`, `selbrume`;
- aucun import/symbole Flame, `PlayableMapGame`, `RuntimeMapGame`, `MapLayersComponent`, `SceneCinematicRuntimeAwaitableAdapter` dans les fichiers modifies V1-88 ;
- aucun `MapCanvas(` ni `MapGridPainter(` dans le nouveau renderer cinematic ;
- aucun faux decor Selbrume, `lysa`, `mael`, `bourg_selbrume` ou image IA en dur dans le code produit ;
- aucune nouvelle couleur hardcodee ajoutee dans les hunks UI ;
- l'I/O image est limitee au registre `CinematicTilesetAssetRegistry`, hors `build()`/`paint()`.

## 7. Limites connues

L'integration automatique depuis le workspace parent vers le `CinematicTilesetAssetRegistry` n'est pas cablee dans ce lot parce que le prompt bornait les fichiers autorises et excluait les modifications plus larges de wiring editor. Le contrat est pret via `BuildCinematicBackdropTileRenderPlanCallback`.

V1-88 rend les `TileLayer` visibles. Les placements visuels non-tile, surfaces/presets complexes et overlays restent hors V0 ou dans le fallback structurel.

Aucun acteur n'est rendu. C'est volontaire : V1-89 doit d'abord cadrer l'Actor Display statique sur ce decor reel.

Tentative abandonnee : un test de sampling pixel via `RenderRepaintBoundary.toImage` a bloque plusieurs minutes dans l'environnement de test. Il a ete remplace par des assertions de plan + widget tree + Visual Gate screenshot, plus stable.

## 8. Statut roadmap

`road_map_scenes.md` et `road_map_scene_builder_authoring.md` sont mis a jour :

- `NS-SCENES-V1-88` passe a `DONE`;
- le prochain lot recommande devient `NS-SCENES-V1-89 — Cinematic Actor Display Preview Prep Contract`;
- `NS-SCENES-V1-90 — Cinematic Timeline Scroll / Visibility Polish V0` reste backlog futur.
