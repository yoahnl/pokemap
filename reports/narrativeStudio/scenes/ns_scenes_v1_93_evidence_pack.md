# NS-SCENES-V1-93 — Evidence Pack

Lot : `NS-SCENES-V1-93 — Cinematic Map Backdrop Layer Fidelity Prep Contract`

Statut : `DONE`

Demande : prompt fourni par Karim. Karim a demandé de corriger la fidélité du décor map avant de continuer vers le Sprite Resolver Actor Display.

Code généré :

```text
Aucun code Dart/Flutter généré. V1-93 est documentaire/architecture-review uniquement.
```

## 1. Gate 0

Commandes exécutées depuis la racine :

```bash
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git log --oneline -n 15
```

Résultats :

```text
/Users/karim/Project/pokemonProject
main
```

`git status --short --untracked-files=all`, `git diff --stat` et `git diff --name-only` n'ont produit aucune sortie au Gate 0.

```text
9c5db6f0 feat(narrative): auto-commit changes
eb05d109 feat(narrative): auto-commit changes
3e767d80 feat(narrative): auto-commit changes
3a3689df feat(narrative): auto-commit changes
12e52f7a update selbrume
1ac4186f update selbrume
a085d128 feat(narrative): auto-commit changes
103cc837 feat(narrative): auto-commit changes
fd10cce7 feat(narrative): auto-commit changes
c730bef3 feat(narrative): auto-commit changes
3b73a8fd feat(narrative): auto-commit changes
587b47f6 update selbrume
50a43df8 feat(narrative): add cinematic map backdrop preview model, tests, and roadmap updates (NS-SCENES-V1-83)
c76550a6 feat(narrative): update cinematic workspaces, tests, and roadmap reports (NS-SCENES-V1-82)
e32d5f2a update screenshot failures for ns_scenes_v1_29_storyline_step_scene_link_v0
```

## 2. Fichiers lus

Consignes :

- `AGENTS.md`
- `agent_rules.md`
- `skills/README.md`
- `skills/using-superpowers/SKILL.md`
- `skills/dispatching-parallel-agents/SKILL.md`
- `skills/verification-before-completion/SKILL.md`

Roadmaps et rapports :

- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_87_cinematic_map_backdrop_real_tile_rendering_prep_contract.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_88_cinematic_map_backdrop_real_tile_renderer_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_89_cinematic_map_backdrop_real_tile_renderer_integration_fidelity_polish_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_92_cinematic_actor_display_preview_renderer_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_92_evidence_pack.md`

Sources auditées :

- `packages/map_core/lib/src/models/map_data.dart`
- `packages/map_core/lib/src/models/map_layer.dart`
- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/models/project_path_pattern_preset.dart`
- `packages/map_core/lib/src/models/environment.dart`
- `packages/map_core/lib/src/models/surface.dart`
- `packages/map_core/lib/src/read_models/cinematic_map_backdrop_preview_model.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_tile_render_plan.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_tile_plan_loader.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_tile_renderer.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_display_preview_overlay.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_viewport_transform.dart`
- `packages/map_editor/lib/src/ui/canvas/map_canvas.dart`
- `packages/map_editor/lib/src/ui/canvas/map_canvas/map_canvas_assets.dart`
- `packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart`
- `packages/map_editor/lib/src/features/surface_painter/surface_layer_static_preview.dart`
- `packages/map_editor/lib/src/features/surface_painter/surface_tile_preview_resolver.dart`
- `packages/map_editor/lib/src/application/use_cases/environment_generator_apply_use_cases.dart`

Fichiers demandés par le prompt mais dont le modèle réel est localisé ailleurs :

- `project_tileset.dart` : les champs utiles sont dans `project_manifest.dart` (`ProjectTilesetEntry`) et `tileset.dart`.
- `project_surface_catalog.dart` : le catalogue surface est dans `surface.dart` / `surface_catalog`.
- `environment_layer_content.dart` : `EnvironmentLayerContent` est dans `environment.dart`.
- `map_placed_element.dart` : `MapPlacedElement` est dans `map_data.dart`.

## 3. Notes de sub-agents

Sub-agent A — MapData Layer Semantics :

- `MapData` sépare `layers`, `placedElements`, `entities`, events/triggers/warps/gameplay zones.
- `MapLayer` expose `TileLayer`, `TerrainLayer`, `PathLayer`, `SurfaceLayer`, `ObjectLayer`, `EnvironmentLayer` et `CollisionLayer`.
- Le décor V1-94 doit rendre les layers visuels et les `MapPlacedElement`, pas les overlays gameplay/debug.
- `EnvironmentLayer` est une source authoring/diagnostic ; ses `generatedPlacementIds` doivent être rendus via les `MapPlacedElement`.

Sub-agent B — Map Editor Rendering Parity :

- Le Map Editor peint terrain, path, tile background, surface, ombres, placed elements background, overlays d'édition, entities, tile/placed foreground, puis outils/events/triggers/warps.
- Le futur rendu cinematic doit reprendre l'ordre utile, mais pas `MapCanvas` complet ni `MapGridPainter` brut.
- Les helpers purs ou extractibles sont préférables : foreground split, frame picking, terrain/path/surface resolution.

Sub-agent C — Asset / Catalog Resolution :

- `CinematicTilesetAssetRegistry` suffit pour charger/décoder un tileset, pas pour résoudre les références métier.
- V1-94 a besoin d'un resolver multi-catalogues pour terrain, path, surface, placed elements et generated placements.
- La recommandation "actor sprites first" de C est rejetée pour ce lot, car Karim a explicitement demandé décor d'abord.

Sub-agent D — Render Plan Contract :

- Le plan actuel est trop `TileLayer`-centric.
- Option E recommandée : `CinematicMapBackdropLayerRenderPlan` dédié, multi-layer, editor-only/read-only, avec diagnostics et partial render.

Sub-agent E — Runtime / Flame / MapCanvas anti-scope :

- V1-94 ne doit pas importer runtime, Flame, `GameWidget`, `PlayableMapGame`, `RuntimeMapGame`, `GameState`, `MapCanvas` ou `MapGridPainter` brut.
- La preview reste authoring statique, pas gameplay.

Sub-agent F — Product / UX :

- Le seuil produit est la reconnaissance immédiate du décor de projet.
- Non tolérable : terrain/paths/placedElements absents alors que les assets existent, fallback silencieux, ordre de couches faux, wording trop optimiste, sprites acteurs avant décor.

Sub-agent G — Tests / Visual Gate :

- Préférer une fixture neutre dédiée, sans Selbrume/Lysa.
- Tester l'ordre, les familles rendues, le partial render, les diagnostics et l'exclusion collision/events/entities/triggers/warps.
- Capturer une Visual Gate V1-94 dédiée seulement dans le prochain lot.

## 4. Recherches structurantes

Commandes utilisées :

```bash
rg -n "class .*Layer|TileLayer|TerrainLayer|PathLayer|SurfaceLayer|EnvironmentLayer|ObjectLayer|MapPlacedElement|placedElements|EnvironmentLayerContent|EnvironmentAreaMask" packages/map_core/lib/src packages/map_editor/lib/src
rg -n "drawImageRect|paint.*Layer|paintTile|paintTerrain|paintPath|paintSurface|paintEnvironment|paintPlaced|MapGridPainter|MapCanvas" packages/map_editor/lib/src/ui packages/map_editor/lib/src/features
rg -n "ProjectSurfaceCatalog|SurfaceCatalog|surfaceCatalog|surface.*atlas|paintSurfaceLayerAtlasTilePreview" packages/map_core packages/map_editor
rg -n "ProjectPathPatternPreset|pathPattern|path.*preset|resolvePathPatternVisual|PathLayer" packages/map_core packages/map_editor
rg -n "EnvironmentPaletteItem|environmentPalette|environment.*asset|generatedPlacement|EnvironmentLayer" packages/map_core packages/map_editor
rg -n "CinematicMapBackdropTileRenderPlan|CinematicMapBackdropBitmapInstruction|CinematicTilesetAssetRegistry|CinematicMapBackdropTileRenderPainter|tileMetricMismatch|noBitmapInstructions" packages/map_editor/lib/src/ui/canvas/cinematics
rg -n "PlayableMapGame|RuntimeMapGame|GameWidget|FlameGame|CameraComponent|MapLayersComponent|GameState|map_runtime|currentTimeMs|playbackTimeMs|isPlaying" packages/map_editor packages/map_runtime
```

Lignes structurantes retenues :

- `packages/map_core/lib/src/models/map_data.dart:23` : `MapData.layers`.
- `packages/map_core/lib/src/models/map_data.dart:99` : `MapPlacedElement`.
- `packages/map_core/lib/src/models/map_layer.dart:23` : sealed class `MapLayer`.
- `packages/map_core/lib/src/models/map_layer.dart:37` : `TileLayer`.
- `packages/map_core/lib/src/models/map_layer.dart:67` : `TerrainLayer`.
- `packages/map_core/lib/src/models/map_layer.dart:76` : `PathLayer`.
- `packages/map_core/lib/src/models/map_layer.dart:91` : `SurfaceLayer`.
- `packages/map_core/lib/src/models/map_layer.dart:99` : `ObjectLayer`.
- `packages/map_core/lib/src/models/map_layer.dart:105` : `EnvironmentLayer`.
- `packages/map_core/lib/src/models/project_manifest.dart:319` : `ProjectManifest.tilesets`.
- `packages/map_core/lib/src/models/project_manifest.dart:327` : `ProjectManifest.elements`.
- `packages/map_core/lib/src/models/project_manifest.dart:350` : `ProjectManifest.terrainPresets`.
- `packages/map_core/lib/src/models/project_manifest.dart:361` : `ProjectManifest.pathPresets`.
- `packages/map_core/lib/src/models/project_manifest.dart:366` : `ProjectManifest.pathPatternPresets`.
- `packages/map_core/lib/src/models/project_manifest.dart:384` : `ProjectManifest.surfaceCatalog`.
- `packages/map_core/lib/src/read_models/cinematic_map_backdrop_preview_model.dart:20` : `CinematicMapBackdropPreviewStatus`.
- `packages/map_core/lib/src/read_models/cinematic_map_backdrop_preview_model.dart:402` : projection des visual primitives.
- `packages/map_core/lib/src/read_models/cinematic_map_backdrop_preview_model.dart:669` : projection des visual layers.
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_tile_render_plan.dart:119` : `CinematicMapBackdropBitmapInstruction`.
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_tile_render_plan.dart:145` : `CinematicMapBackdropTileRenderPlan`.
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_tile_render_plan.dart:169` : builder du plan tile-only.
- `packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart:1` : `part of map_canvas.dart`.
- `packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart:258` : `MapGridPainter.paint`.
- `packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart:1641` : peinture `TileLayer`.
- `packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart:1787` : peinture `MapPlacedElement`.
- `packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart:2068` : peinture `TerrainLayer`.
- `packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart:2114` : peinture `PathLayer`.
- `packages/map_editor/lib/src/features/surface_painter/surface_tile_preview_resolver.dart:40` : resolver surface preview.
- `packages/map_editor/lib/src/features/surface_painter/surface_layer_static_preview.dart:123` : surface atlas static preview.

## 5. Arbitrage final

Option retenue :

```text
Option E — plan cinematic multi-layer dédié + helpers purs/extractibles du Map Editor.
```

Décisions :

- V1-94 rend le décor avant les sprites acteurs.
- V1-94 peut introduire un resolver multi-catalogues comme sous-partie du renderer backdrop.
- V1-94 préserve l'Actor Display V1-92 et garde les placeholders statiques.
- V1-95 reprend le Sprite Resolver Actor Display Prep Contract.

## 6. Hunks roadmap

`road_map_scene_builder_authoring.md` :

```diff
-NS-SCENES-V1-92 — Cinematic Actor Display Preview Renderer V0
+NS-SCENES-V1-94 — Cinematic Map Backdrop Layer Fidelity Renderer V0
```

```diff
-| NS-SCENES-V1-93 | Cinematic Actor Display Preview Sprite Resolver Prep Contract | doc-only / architecture-review | Cadrer le futur resolver de sprites statiques pour remplacer progressivement les placeholders V1-92 : sources Character Library/player/mapEntity, frames idle, fallback, diagnostics, cache et anti-scope runtime. | Pas de renderer sprite actif, playback, runtime/Flame, actorMove interpolation, pathfinding/collision, mutation Character Library, generation image IA ou donnees Selbrume. | Rapport V1-93, evidence pack, roadmaps. | TODO : contrat sprite resolver editor-only. | Charger trop tot des sprites dans core ; confondre sprite statique et animation runtime ; masquer les placeholders incomplets. | TODO : contrat pret pour afficher des acteurs reconnaissables sans lancer la cinematique. | V1-92. |
+| NS-SCENES-V1-93 | Cinematic Map Backdrop Layer Fidelity Prep Contract | doc-only / architecture-review | A la demande de Karim, suspendre le Sprite Resolver et cadrer la fidelite map restante : audit layers MapData, rendu Map Editor, assets/catalogues, plan multi-layer, diagnostics, tests et Visual Gate V1-94. | Pas de code produit, packages, test, screenshot, renderer, MapCanvas complet, runtime/Flame, playback, fake terrain/path/environment, mutation Selbrume ou image IA. | Rapport V1-93, evidence pack, roadmaps. | DONE : sub-agents A-G, Option E retenue, contrat renderer V1-94, assets/catalogues et anti-scope documentes. | Sous-estimer les placed elements/paths ; lancer les sprites acteurs trop tot ; importer MapCanvas ou runtime pour gagner du temps. | DONE : contrat pret pour fidelity backdrop V1-94, sans modifier les packages. | V1-92. |
+| NS-SCENES-V1-94 | Cinematic Map Backdrop Layer Fidelity Renderer V0 | editor / preview-sandbox | Etendre le renderer backdrop cinematic pour rendre terrain, paths, surfaces, placed elements et generated placements quand assets/donnees sont disponibles, avec plan multi-layer editor-only/read-only. | Pas de MapCanvas complet, runtime/Flame, playback, mutation projet/map, hardcode Selbrume, sprites acteurs finaux, pathfinding/collision ou outils d'edition. | Builder/Library cinematics, plan backdrop multi-layer, resolver asset catalog, tests widget/plan, rapport, Visual Gate. | TODO : tests de plan par familles, partial render, diagnostics asset-missing, Visual Gate neutre, anti-scope et anti-Selbrume diff. | Ordre de couches faux ; fallback silencieux ; charger images dans paint/build ; casser l'overlay acteurs V1-92 ou les proportions timeline. | TODO : decor projet statique beaucoup plus proche du Map Editor, acteurs V1-92 preserves, sans runtime. | V1-93. |
+| NS-SCENES-V1-95 | Cinematic Actor Display Preview Sprite Resolver Prep Contract | doc-only / architecture-review | Cadrer le futur resolver de sprites statiques apres fidelity backdrop V1-94 : sources Character Library/player/mapEntity, frames idle, fallback, diagnostics, cache et anti-scope runtime. | Pas de renderer sprite actif, playback, runtime/Flame, actorMove interpolation, pathfinding/collision, mutation Character Library, generation image IA ou donnees Selbrume. | Rapport V1-95, evidence pack, roadmaps. | TODO : contrat sprite resolver editor-only. | Charger trop tot des sprites dans core ; confondre sprite statique et animation runtime ; masquer les placeholders incomplets. | TODO : contrat pret pour afficher des acteurs reconnaissables sans lancer la cinematique. | V1-94. |
```

`road_map_scenes.md` :

```diff
-| NS-SCENES-V1-93 — Cinematic Actor Display Preview Sprite Resolver Prep Contract | TODO | Cadrer le futur resolver de sprites actor display statique apres les placeholders V1-92 : sources Character Library/player/mapEntity, frames idle, fallbacks, diagnostics et anti-scope runtime. Le polish timeline scroll/visibility est repousse apres ce verrou actor readability. |
+| NS-SCENES-V1-93 — Cinematic Map Backdrop Layer Fidelity Prep Contract | DONE | Lot documentaire demande par Karim : suspension volontaire du Sprite Resolver pour auditer la fidelite map restante apres V1-92 ; audit MapData/layers, rendu Map Editor, assets/catalogues, render plan multi-layer, anti-scope runtime/Flame/MapCanvas, tests/Visual Gate V1-94, Option E retenue, sans code produit, packages, tests, screenshot, renderer, Selbrume modifiee ni playback. |
+| NS-SCENES-V1-94 — Cinematic Map Backdrop Layer Fidelity Renderer V0 | TODO | Etendre le renderer backdrop cinematic pour rendre terrain, paths, surfaces, placed elements et generated placements quand les donnees/assets sont disponibles, via plan multi-layer editor-only/read-only, sans MapCanvas complet, runtime, Flame, playback, mutation projet/map ni sprites acteurs finaux. |
+| NS-SCENES-V1-95 — Cinematic Actor Display Preview Sprite Resolver Prep Contract | TODO | Cadrer le futur resolver de sprites actor display statique apres fidelity backdrop V1-94 : sources Character Library/player/mapEntity, frames idle, fallbacks, diagnostics, cache et anti-scope runtime. |
```

```diff
-`NS-SCENES-V1-93 — Cinematic Actor Display Preview Sprite Resolver Prep Contract`
+`NS-SCENES-V1-94 — Cinematic Map Backdrop Layer Fidelity Renderer V0`
```

## 7. Checks anti-scope exécutés en clôture

Commandes :

```bash
git diff --name-only -- packages
git diff --check
git diff --stat
git diff --name-only
git status --short --untracked-files=all
rg -n "PlayableMapGame|RuntimeMapGame|GameWidget|FlameGame|CameraComponent|MapLayersComponent|GameState|map_runtime|currentTimeMs|playbackTimeMs|isPlaying|Timer\\(|Ticker|AnimationController|drawImageRect|MapCanvas\\(|MapGridPainter\\(|gpt-image-2|image_generation" reports/narrativeStudio/scenes/ns_scenes_v1_93_cinematic_map_backdrop_layer_fidelity_prep_contract.md reports/narrativeStudio/scenes/ns_scenes_v1_93_evidence_pack.md reports/narrativeStudio/scenes/road_map_scenes.md reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md || true
```

Attendu :

- `git diff --name-only -- packages` : aucune sortie.
- `git diff --check` : aucune sortie.
- Les seules modifications sont les rapports/roadmaps autorisés.
- Les termes anti-scope n'apparaissent que dans non-objectifs, options rejetées, anti-scope, checks ou contrat futur.

Résultats obtenus :

```text
$ git diff --name-only -- packages

$ git diff --check

$ git diff --stat
 .../scenes/road_map_scene_builder_authoring.md     | 22 +++++++++++++++--
 reports/narrativeStudio/scenes/road_map_scenes.md  | 28 ++++++++++++++++++----
 2 files changed, 44 insertions(+), 6 deletions(-)

$ git diff --name-only
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md

$ git status --short --untracked-files=all
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_93_cinematic_map_backdrop_layer_fidelity_prep_contract.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_93_evidence_pack.md
```

Note : `git diff --stat` et `git diff --name-only` ne listent pas les fichiers non suivis. Les deux nouveaux rapports sont donc attestés par `git status --short --untracked-files=all`.

Scan anti-scope complet sur les fichiers du lot :

```text
Commande exécutée avec sortie volontairement revue manuellement :
rg -n "PlayableMapGame|RuntimeMapGame|GameWidget|FlameGame|CameraComponent|MapLayersComponent|GameState|map_runtime|currentTimeMs|playbackTimeMs|isPlaying|Timer\\(|Ticker|AnimationController|drawImageRect|MapCanvas\\(|MapGridPainter\\(|gpt-image-2|image_generation" reports/narrativeStudio/scenes/ns_scenes_v1_93_cinematic_map_backdrop_layer_fidelity_prep_contract.md reports/narrativeStudio/scenes/ns_scenes_v1_93_evidence_pack.md reports/narrativeStudio/scenes/road_map_scenes.md reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md || true
```

Résultat : le scan complet ressort les occurrences V1-93 anti-scope/futures checks, ainsi que de nombreuses occurrences historiques déjà présentes dans les roadmaps anciennes. Aucune occurrence ne correspond à un import ou à un code produit ajouté dans ce lot.

Scan ciblé du diff suivi :

```text
$ git diff -- reports/narrativeStudio/scenes/road_map_scenes.md reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md reports/narrativeStudio/scenes/ns_scenes_v1_93_cinematic_map_backdrop_layer_fidelity_prep_contract.md reports/narrativeStudio/scenes/ns_scenes_v1_93_evidence_pack.md | rg -n "PlayableMapGame|RuntimeMapGame|GameWidget|FlameGame|CameraComponent|MapLayersComponent|GameState|map_runtime|currentTimeMs|playbackTimeMs|isPlaying|Timer\\(|Ticker|AnimationController|drawImageRect|MapCanvas\\(|MapGridPainter\\(|gpt-image-2|image_generation" || true
16: | NS-SCENES-V1-91 | Cinematic Actor Display Preview Read Model V0 | core / read-model | Creer un read model pur des acteurs affichables dans la preview cinematic : acteurs, bindings, positions resolues ou manquantes, apparences, placeholders, diagnostics et summary. | Pas de renderer UI, sprite actor affiche, playback, runtime/Flame, GameState, pathfinding/collision, mutation MapData/ProjectManifest ou screenshot. | `map_core` read model actor display, tests purs, rapport. | DONE : `CinematicActorDisplayPreviewModel`, builder pur depuis `CinematicAsset`/manifest/stage map/MapData, diagnostics locaux, positions/apparences/directions/render hints et tests/analyze core verts. | Melanger read model et painter ; inventer des positions ; utiliser le runtime pour simplifier. | DONE : actor display projetable et testable, sans rendu. | V1-90. |
17: | NS-SCENES-V1-92 | Cinematic Actor Display Preview Renderer V0 | editor / preview-sandbox | Brancher le read model V1-91 dans le Cinematic Builder pour afficher des acteurs statiques sous forme de placeholders par-dessus le decor V1-89. | Pas de playback, actorMove interpolation, runtime/Flame, GameState, pathfinding/collision, mutation MapData/ProjectManifest, sprite final ou lancement de cinematique. | Builder cinematics, overlay actor display, transform viewport partage, tests widget, rapport, screenshot. | DONE : `CinematicActorDisplayPreviewModel` construit par la Library et passe au Builder ; placeholders statiques renderables seulement, unbound/missing hors map, labels courts, direction hints, diagnostics humains, Visual Gate 1663x926 et analyses/tests verts. | Confondre projection statique et playback ; charger les sprites dans core ; casser les proportions preview/timeline. | DONE : acteurs visibles en preview editor-only, sans runtime. | V1-91. |
29:+Decision : Option E retenue. V1-94 doit livrer un plan de rendu backdrop cinematic multi-layer dedie, avec resolver multi-catalogues au-dessus de `CinematicTilesetAssetRegistry`, en reutilisant seulement des helpers purs/extractibles du Map Editor. `MapCanvas` complet, `MapGridPainter` brut, runtime, Flame, GameState et playback restent interdits.
```

Interprétation : les lignes 16-17 sont du contexte de hunk existant ; la ligne ajoutée 29 est une interdiction explicite V1-93.

Whitespace untracked + tracked du lot :

```text
$ rg -n "[ \t]+$" reports/narrativeStudio/scenes/ns_scenes_v1_93_cinematic_map_backdrop_layer_fidelity_prep_contract.md reports/narrativeStudio/scenes/ns_scenes_v1_93_evidence_pack.md reports/narrativeStudio/scenes/road_map_scenes.md reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md || true

```

## 8. Auto-review

- Code produit modifié : Non.
- Packages modifiés : Non.
- Test ajouté : Non.
- Screenshot généré : Non.
- Renderer codé : Non.
- Runtime/Flame importé : Non.
- MapCanvas branché : Non.
- Selbrume modifiée : Non.
- Sprite Resolver lancé : Non.
- V1-94 recommandé explicitement : Oui.
- V1-95 utilisé pour repousser le Sprite Resolver : Oui.

## 9. Limites connues

V1-93 ne prouve pas visuellement la fidélité map. Il prépare le contrat de V1-94. Les preuves visuelles, tests Flutter/Dart et captures restent volontairement futurs, parce que le prompt interdit le code produit, le renderer, les tests et les screenshots dans ce lot.
