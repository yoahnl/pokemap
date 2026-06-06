# NS-SCENES-V1-85 — Cinematic Map Backdrop Visual Primitives V0

## 1. Résumé exécutif

V1-85 rend le décor map visuellement plus crédible dans le Cinematic Builder.

V1-85 ne rend toujours pas une cinématique jouable.

Le lot remplace le rendu V1-84 en bandes de couches par une preview spatiale statique : grille proportionnelle, cellules/ancres dérivées de `MapData`, compteur de primitives et légende par layer. Le rendu reste sandbox, read-only et honnête : les vraies tiles/assets ne sont pas rendues.

## 2. Gate 0

```text
pwd
/Users/karim/Project/pokemonProject

git branch --show-current
main

git status --short --untracked-files=all
<vide>

git diff --stat
<vide>

git diff --name-only
<vide>

git log --oneline -n 15
3b73a8fd feat(narrative): auto-commit changes
587b47f6 update selbrume
50a43df8 feat(narrative): add cinematic map backdrop preview model, tests, and roadmap updates (NS-SCENES-V1-83)
c76550a6 feat(narrative): update cinematic workspaces, tests, and roadmap reports (NS-SCENES-V1-82)
e32d5f2a update screenshot failures for ns_scenes_v1_29_storyline_step_scene_link_v0
1b311e81 feat(narrative): update cinematic workspace and add test failure assets (NS-SCENES-V1-29-81)
122fe0c7 feat(narrative): update cinematic builder workspace (NS-SCENES-V1-81-BIS)
747aa6e6 feat(narrative): add cinematic builder workspace updates and test failure assets (NS-SCENES-V1-35)
2da49606 feat(narrative): add cinematic actor appearance readiness drift diagnostics polish v0 (NS-SCENES-V1-81)
eea6dbff feat(narrative): add cinematic character library picker v0 (NS-SCENES-V1-80)
eb7d47aa feat(narrative): add cinematic character library binding core model v0 (NS-SCENES-V1-79)
92a6c95e feat(narrative): add cinematic character library binding prep contract (NS-SCENES-V1-78)
d5113ec2 feat(narrative): add cinematic stage map entity event pickers v0 (NS-SCENES-V1-77)
01a69fdd feat(narrative): add cinematic stage map source catalog v0 (NS-SCENES-V1-76)
bea04114 feat(narrative): add cinematic map entity event source audit picker prep contract (NS-SCENES-V1-75)
```

## 3. Fichiers lus

`AGENTS.md`, `agent_rules.md`, les roadmaps scènes, les rapports/evidence packs V1-83/V1-84, `cinematic_map_backdrop_preview_model.dart`, `cinematic_map_backdrop_preview_model_test.dart`, `map_data.dart`, `map_layer.dart`, `cinematic_asset.dart`, `project_manifest.dart`, `map_core.dart`, `cinematic_map_backdrop_preview_panel.dart`, `cinematic_builder_workspace.dart`, `cinematics_library_workspace.dart`, les tests Builder/Library, et les inspirations `map_canvas.dart`, `map_grid_painter.dart`, `surface_layer_static_preview.dart`.

## 4. Synthèse des sub-agents et arbitrages

Sub-agent A — conclusion : `MapData` contient des coordonnées honnêtes pour `TileLayer`, `TerrainLayer`, `PathLayer`, `SurfaceLayer`, `EnvironmentLayer` et `MapPlacedElement`; `ObjectLayer` seul est un conteneur sans géométrie.

Sub-agent B — conclusion : étendre le read model avec `visualPrimitives` pures dans `map_core`; garder les summaries comme fallback.

Sub-agent C — conclusion : ne pas brancher `MapCanvas`; utiliser un mini `CustomPainter` dédié, alimenté par les couleurs du design system.

Sub-agent D — conclusion : tester que les primitives viennent de `MapData`, qu’aucune fake tile n’est inventée, et que collisions/events/entities/zones ne sont pas rendus.

Sub-agent E — conclusion : V1-85 est acceptable seulement si elle affiche un vrai canvas statique proportionnel, pas des bandes relookées.

Divergences identifiées : le prochain lot peut viser les acteurs ou les vrais tilesets. Arbitrage final : V1-85 rend le décor assez lisible pour recommander `NS-SCENES-V1-86 — Cinematic Actor Display Preview Prep Contract`; le rendu final tiles/assets reste une limite connue.

## 5. Design Gate — Cinematic Map Backdrop Visual Primitives V0

1. V1-84 est insuffisant car il affiche des bandes de layers, pas une carte spatiale.
2. Données disponibles : `MapData.size`, layers, cellules row-major, placements, masks environment, `MapPlacedElement.pos`.
3. Primitives spatiales : tile, terrain, path, surface, objectAnchor depuis placed elements, environment anchors.
4. Fallback summary : layers vides ou sans géométrie exploitable.
5. Extension `map_core` nécessaire : oui, pour éviter de parser des summaries UI.
6. Contrat retenu : `CinematicMapBackdropVisualPrimitive` + enum kind + `visualPrimitives`.
7. Anti fake tiles : seules les cellules non vides réellement présentes sont projetées.
8. Anti fake map : aucune primitive si `MapData.layers` est vide.
9. Anti MapCanvas complet : mini painter dédié uniquement.
10. Anti runtime/Flame : aucun import runtime/Flame.
11. Lien primitives/layers : `layerId`, `layerLabel`, `layerKind`, `layerIndex`, `localOrder`.
12. Ordre : tri `(layerIndex, localOrder)`.
13. Visibility/opacity : conservées sur chaque primitive.
14. Viewport : `mapWidth/mapHeight` + cadre proportionnel; `viewportRecommendation` reste affiché en badge.
15. Couleurs : résolues dans le widget via tokens/design system, injectées au painter.
16. Design system : `context.pokeMapColors`, `PokeMapTone`, `PokeMapBadge`, `PokeMapPanel`.
17. Limites affichées : `Aperçu spatial structurel`, `Preview réelle à venir.`
18. Fallbacks V1-84 : préservés.
19. Diagnostics V1-84 : préservés.
20. Timeline/duration/resize/probe : tests existants avec backdrop visible restent verts.
21. Pickers mapEntity/mapEvent : tests existants avec backdrop visible restent verts.
22. Character Library picker : test existant avec backdrop visible reste vert.
23. Aucun acteur rendu : test sentinel `Professor Oak` absent et scan actor-render.
24. Aucun overlay gameplay/debug : collision ignorée et tests/scans.
25. Aucun playback : transports disabled, scan playback.
26. Aucun runtime : scans runtime/Flame.
27. Visual Gate : PNG Flutter 1663x926.
28. Prochain lot : `NS-SCENES-V1-86 — Cinematic Actor Display Preview Prep Contract`.

## 6. Problème UX après V1-84

La preview V1-84 était honnête, mais ressemblait encore à un résumé technique de layers. V1-85 affiche enfin une mini-carte abstraite avec une grille et des cellules placées.

## 7. Scope réalisé

- Ajout de `CinematicMapBackdropVisualPrimitiveKind`.
- Ajout de `CinematicMapBackdropVisualPrimitive`.
- Ajout de `mapWidth`, `mapHeight`, `visualPrimitives` au read model.
- Projection des primitives depuis `MapData`.
- Mini painter editor-only.
- Panel V1-84 remplacé par canvas spatial + légende.
- Tests et Visual Gate V1-85.

## 8. Audit MapData / layers

`TileLayer`, `TerrainLayer`, `PathLayer`, `SurfaceLayer` et `EnvironmentLayer` peuvent produire des primitives quand leurs coordonnées existent. `ObjectLayer` ne produit une ancre que via `MapPlacedElement.layerId`. `CollisionLayer`, `entities`, `events`, `triggers`, `warps` et `gameplayZones` restent exclus.

## 9. Contrat visual primitives

Chaque primitive porte `id`, `layerId`, `layerLabel`, `layerKind`, `kind`, `layerIndex`, `localOrder`, `visible`, `opacity`, `x`, `y`, `width`, `height`, `label`, `summary`, `source`.

## 10. Extension du read model V1-83

Extension minimale pure Dart, sans Flutter, Flame, disque, image, repository ou runtime.

## 11. Renderer visual primitives

Le nouveau fichier `cinematic_map_backdrop_visual_primitives_painter.dart` dessine le cadre, la grille et les primitives avec des couleurs reçues depuis le parent.

## 12. Fallbacks honnêtes

Si aucune primitive spatiale n’existe, le panel affiche `Aucune couche visuelle lisible.` et ne montre pas le canvas de primitives.

## 13. Diagnostics et limites affichées

Les diagnostics V1-84 restent en badges. La preview affiche `Aperçu spatial structurel` et `Preview réelle à venir.`

## 14. Préservation timeline / duration / resize / probe

Le test `keeps duration resize and mouse probe working with map backdrop visible` reste inclus dans la suite Builder complète.

## 15. Préservation pickers map-aware / Character Library

Les tests `keeps map-aware pickers working with map backdrop visible` et `keeps Character Library picker working with map backdrop visible` restent verts dans la suite Builder complète.

## 16. Restrictions anti-runtime / anti-Flame / anti-playback

Aucun import runtime/Flame, aucun `PlayableMapGame`, aucun `GameWidget`, aucun timer, aucun playback, aucun actor renderer.

## 17. Design system

Aucune couleur hardcodée ajoutée. Le painter reçoit uniquement des `Color` déjà résolues depuis `context.pokeMapColors` et `PokeMapTone`.

## 18. Tests ajoutés ou modifiés

Core : primitives MapData, object anchors, fallback summary, no fake primitives, exclusions.

Editor : canvas de primitives, fallback sans primitives, Visual Gate V1-85.

Library : snapshot chargé avec layers réels visible dans le Builder.

## 19. Visual Gate

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_85_cinematic_map_backdrop_visual_primitives_v0.png
PNG image data, 1663 x 926, 8-bit/color RGBA, non-interlaced
255K
sha256 1f24ba63853d3f6ce69c17f0e30111127ddcb0072a5c5699d732aa4b53c6fc57
```

## 20. Commandes exécutées

Voir l’Evidence Pack V1-85 pour le détail.

## 21. Résultats des tests

Core targeted : `+19 All tests passed!`

Builder complet : `+150 All tests passed!`

Library complet : `+15 All tests passed!`

Visual Gate : `+150 All tests passed!`

## 22. Analyze

`map_core dart analyze` : `No issues found!`

Analyse ciblée editor : `No issues found!`

Analyse globale editor : rouge sur dette préexistante hors lot, notamment `pokemon_sdk_move_catalog_converter.dart` et `sync_pokemon_sdk_moves_catalog_use_case.dart`.

## 23. Checks anti-scope

Pas de modification dans `map_runtime`, `map_gameplay`, `map_battle`, `examples`, `selbrume`.

Scans runtime/Flame, fake map, couleurs hardcodées : sortie vide.

Scans playback/actor/stageContext/image IA : uniquement assertions/fixtures historiques ou mentions de roadmaps anti-scope, documentées dans l’Evidence Pack.

## 24. Fichiers créés

```text
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_visual_primitives_painter.dart
reports/narrativeStudio/scenes/ns_scenes_v1_85_cinematic_map_backdrop_visual_primitives_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_85_evidence_pack.md
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_85_cinematic_map_backdrop_visual_primitives_v0.png
```

## 25. Fichiers modifiés

```text
packages/map_core/lib/src/read_models/cinematic_map_backdrop_preview_model.dart
packages/map_core/test/cinematic_map_backdrop_preview_model_test.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
packages/map_editor/test/cinematics_library_workspace_test.dart
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
```

## 26. Roadmaps mises à jour

V1-85 est marqué DONE dans les deux roadmaps. Le prochain lot exact recommandé est `NS-SCENES-V1-86 — Cinematic Actor Display Preview Prep Contract`.

## 27. Limites connues

Les vraies tiles/assets ne sont pas rendues. Les couleurs/formes restent symboliques. Aucun acteur n’est affiché.

## 28. Non-objectifs confirmés

Pas de runtime, Flame, PlayableMapGame, GameWidget, playback, timer, actor rendering, sprites Character Library, collision/pathfinding/triggers/event/entity overlays, mutation map/projet, données Selbrume ou image IA.

## 29. Evidence Pack

Voir `reports/narrativeStudio/scenes/ns_scenes_v1_85_evidence_pack.md`.

Cet evidence pack contient aussi le code généré principal : le nouveau painter complet, le contrat core des visual primitives et le bridge UI qui le branche dans le Builder.

## 30. Auto-review critique

Le saut visuel est réel par rapport aux bandes V1-84, mais la miniature reste abstraite et dépend de la densité réelle des données de test. La prochaine amélioration décor pure serait les tilesets statiques; le prochain lot recommandé par le prompt reste toutefois l’affichage statique des acteurs.

## 31. Recommandation pour le prochain lot

`NS-SCENES-V1-86 — Cinematic Actor Display Preview Prep Contract`.
