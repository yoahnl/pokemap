# NS-SCENES-V1-87 — Cinematic Map Backdrop Real Tile Rendering Prep Contract

## 1. Resume executif

Statut : `DONE` documentaire.

Phrase canonique : V1-87 prepare le rendu reel des tiles de map. V1-87 ne rend pas encore les tiles.

Decision retenue : Option E hybride. Le prochain lot doit creer un renderer cinematic editor-only/read-only dedie, alimente par `MapData`, `ProjectManifest`, un plan d'instructions bitmap et des images de tilesets resolues en amont. Le Cinematic Builder ne doit pas embarquer `MapCanvas` complet, ne doit pas charger les images dans `build()`/`paint()`, et ne doit pas importer le runtime ou Flame.

Prochain lot exact recommande : `NS-SCENES-V1-88 — Cinematic Map Backdrop Real Tile Renderer V0`.

Code genere par ce lot : aucun. Aucun fichier `packages/` n'a ete modifie.

## 2. Gate 0

Commandes executees avant modification depuis `/Users/karim/Project/pokemonProject` :

```text
pwd
/Users/karim/Project/pokemonProject
```

```text
git branch --show-current
main
```

```text
git status --short --untracked-files=all
(aucune sortie)
```

```text
git diff --stat
(aucune sortie)
```

```text
git diff --name-only
(aucune sortie)
```

```text
git log --oneline -n 15
fd10cce7 feat(narrative): auto-commit changes
c730bef3 feat(narrative): auto-commit changes
3b73a8fd feat(narrative): auto-commit changes
587b47f6 update selbrume
50a43df8 feat(narrative): add cinematic map backdrop preview model, tests, and roadmap updates (NS-SCENES-V1-83)
c76550a6 feat(narrative): update cinematic workspaces, tests, and roadmap reports (NS-SCENES-V1-82)
e32d5f2a update screenshot failures for ns_scenes_v1_29_storyline_step_scene_link_v0
1b311e81 feat(narrative): update cinematic builder workspace (NS-SCENES-V1-29-81)
122fe0c7 feat(narrative): update cinematic builder workspace (NS-SCENES-V1-81-BIS)
747aa6e6 feat(narrative): add cinematic builder workspace updates and test failure assets (NS-SCENES-V1-35)
2da49606 feat(narrative): add cinematic actor appearance readiness drift diagnostics polish v0 (NS-SCENES-V1-81)
eea6dbff feat(narrative): add cinematic character library picker v0 (NS-SCENES-V1-80)
eb7d47aa feat(narrative): add cinematic character library binding core model v0 (NS-SCENES-V1-79)
92a6c95e feat(narrative): add cinematic character library binding prep contract (NS-SCENES-V1-78)
d5113ec2 feat(narrative): add cinematic stage map entity event pickers v0 (NS-SCENES-V1-77)
```

## 3. Fichiers lus

Regles et prompt :

- `AGENTS.md`
- `agent_rules.md`
- `skills/README.md`
- `/Users/karim/.codex/attachments/b411b502-a685-45a2-ae10-a0ce3a044960/pasted-text.txt`
- `skills/brainstorming/SKILL.md`
- `skills/dispatching-parallel-agents/SKILL.md`
- `skills/verification-before-completion/SKILL.md`

Rapports et roadmaps :

- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_86_cinematic_map_backdrop_visual_composition_polish_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_86_evidence_pack.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_85_cinematic_map_backdrop_visual_primitives_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_84_cinematic_map_backdrop_preview_renderer_v0.md`

Core/editor/runtime audites en lecture seule :

- `packages/map_core/lib/src/models/map_data.dart`
- `packages/map_core/lib/src/models/map_layer.dart`
- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/read_models/cinematic_map_backdrop_preview_model.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_visual_primitives_painter.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/map_canvas.dart`
- `packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart`
- `packages/map_editor/lib/src/ui/canvas/map_canvas/map_canvas_assets.dart`
- `packages/map_editor/lib/src/features/surface_painter/surface_layer_static_preview.dart`
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- `packages/map_runtime/lib/src/presentation/flame/runtime_map_game.dart`
- `packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart`
- `packages/map_runtime/lib/src/application/scene_runtime/scene_cinematic_runtime_awaitable_adapter.dart`
- `packages/map_runtime/lib/map_runtime.dart`

Note : le chemin demande `packages/map_editor/lib/src/ui/canvas/map_canvas/surface_layer_static_preview.dart` n'existe pas ; le fichier reel trouve est `packages/map_editor/lib/src/features/surface_painter/surface_layer_static_preview.dart`.

## 4. Synthese des sub-agents et arbitrages

Sub-agent A — MapData / layers : `MapData` porte une liste ordonnee de `MapLayer`, plus des collections separees pour entities, events, warps, triggers et gameplayZones. Les layers visuels futurs sont `TileLayer`, `SurfaceLayer`, `TerrainLayer` et `PathLayer` si leurs presets se resolvent en frames, plus `MapPlacedElement` rattaches aux `TileLayer`. Collision, triggers, events/entities overlays, warps et gameplay zones restent exclus.

Sub-agent B — Tileset / asset resolution : `ProjectTilesetEntry.relativePath` est persistant, `ProjectSettings.tileWidth/tileHeight` donnent la taille globale, et l'editor resout les chemins via `ProjectWorkspace` / `EditorNotifier.getTilesetAbsolutePathById`. Le cache actuel `_TilesetImageCache` est utile mais prive et local au canvas ; V1-88 doit introduire un registry editor dedie, hors `build()`/`paint()`.

Sub-agent C — Map Editor renderer : `MapGridPainter` est la reference la plus fidele pour l'ordre et les cas existants, mais il est massif et melange overlays d'edition, hover, collision, gameplay zones, events, triggers, warps, outils et selection. Reutiliser `MapCanvas` complet est rejete. Reutiliser des helpers purs est acceptable si le contrat cinematic reste read-only.

Sub-agent D — Runtime / Flame anti-scope : `PlayableMapGame`, `RuntimeMapGame`, `MapLayersComponent`, `GameWidget`, `FlameGame`, `CameraComponent`, `SceneCinematicRuntimeAwaitableAdapter` et le barrel `map_runtime` sont hors scope. Le renderer doit rester cote `map_editor`, sans boucle runtime, sans world/camera Flame, sans player/PNJ runtime, sans battle/dialogue/save.

Sub-agent E — UX/Product : V1-88 sera acceptable si l'utilisateur reconnait sa map au premier coup d'oeil, tout en voyant clairement que c'est un decor statique. Wording recommande : `Carte du projet (statique)`, `Decor seul`, `Sans acteurs`, `Sans lecture`. Eviter `Preview reelle a venir` quand la carte reelle est deja affichee.

Divergences identifiees : A recommande d'exclure `ObjectLayer` direct tant que son contrat n'est pas clarifie, tandis que V1-85 l'utilise comme ancre structurelle. Arbitrage : V1-88 doit rendre les `MapPlacedElement` lies aux `TileLayer` en priorite ; `ObjectLayer` direct reste diagnostic/fallback, pas bitmap V0. C recommande reutiliser progressivement des passes de `MapGridPainter`, B recommande extraire un registry asset ; ces deux avis sont compatibles si le renderer ne depend pas du `MapCanvas` complet.

Arbitrage final : Option E. V1-88 cree un renderer dedicated cinematic V0 + un petit contrat de plan de rendu, et reutilise seulement les helpers dont l'entree/sortie peut rester explicite et testable.

Option retenue : renderer cinematic read-only dedie, asset registry editor-only en amont, fallback structurel V1-86 en cas de blocage asset.

## 5. Pourquoi V1-86 ne suffit pas

V1-86 a corrige les proportions : la map structurelle est plus grande, la timeline reste lisible, et les primitives/cellules sont mieux composees. Mais V1-86 reste une projection symbolique : `CinematicMapBackdropVisualPrimitivesPainter` peint des rectangles, rubans et ancres colores, pas des images de tilesets.

La difference produit est simple :

- preview structurelle : indique ou sont les couches, cellules et ancres ;
- vraie preview de map : affiche les textures/assets du projet, dans le bon ordre, avec opacite/fallbacks.

Tant que la preview reste structurelle, l'utilisateur ne peut pas verifier visuellement Selbrume ou une map de projet. Poser des acteurs avant ce decor donnerait une preview plus riche mais moins fiable.

## 6. Objectif produit de la vraie preview map

V1-88 doit afficher une carte statique reconnaissable depuis les donnees projet, sans lancer une cinematique.

Seuil produit :

- vraie `MapData` ;
- vrais tilesets/images resolus ;
- proportions et fit V1-86 preserves ;
- layers visuels dans un ordre honnete ;
- opacite et visibility respectees ;
- fallback explicite si asset absent ;
- transports toujours disabled ;
- aucune promesse de playback ou acteur.

## 7. Audit MapData / layers visuels

`MapData` contient `id`, `name`, `size`, `tilesetId`, `layers`, `placedElements`, `entities`, `connections`, `warps`, `triggers`, `gameplayZones` et `events`. Les collections non-layer doivent rester hors du decor statique V1-88.

`MapLayer` expose :

- `TileLayer` : `tilesetId`, `isVisible`, `opacity`, `tiles`.
- `CollisionLayer` : technique, exclu.
- `TerrainLayer` : `terrains`; rendu bitmap possible via `ProjectTerrainPreset` si resoluble.
- `PathLayer` : `presetId`, `cells`, animation metadata ; rendu bitmap possible via path presets/patterns, mais V1-88 doit rester statique.
- `SurfaceLayer` : sparse `placements`, bon candidat via `ProjectSurfaceCatalog`.
- `ObjectLayer` : pas de geometrie directe ; prudence V0.
- `EnvironmentLayer` : source/generation authoring ; ne doit pas etre peinte directement comme decor final.

Layers a rendre en V1-88 :

- `TileLayer` visible, `opacity > 0`, cellules `tileId > 0`, tileset resolu ;
- `MapPlacedElement` dont `layerId` vise un `TileLayer`, avec `ProjectElementEntry.frames` resolues ;
- `SurfaceLayer` visible si `ProjectSurfaceCatalog` et tilesets resolvent une instruction atlas ;
- `TerrainLayer` visible, hors `TerrainType.none`, si preset/frame resoluble ;
- `PathLayer` visible si preset/path pattern resoluble en frame statique.

Layers a exclure :

- `CollisionLayer` ;
- `EnvironmentLayer` direct, sauf diagnostics/fallback structurel ;
- `ObjectLayer` direct en V0 ;
- `entities`, `events`, `triggers`, `warps`, `connections`, `gameplayZones` ;
- overlays editor : grille de travail, hover, selection, masks, tool previews.

## 8. Audit tilesets / asset resolution

Le core reste pur : `ProjectTilesetEntry` ne porte que `id`, `name`, `relativePath`, `transparentColor` et metadata ; il ne lit pas le disque. `ProjectSettings.tileWidth/tileHeight` donne la taille globale des tiles. `TilesetSourceRect` et `TilesetVisualFrame` expriment les sources en coordonnees de tiles.

Cote editor, `EditorNotifier.getTilesetAbsolutePathById` utilise le workspace projet pour convertir `relativePath` en chemin absolu. `MapCanvas` collecte les tileset IDs utiles, construit un `Future`, puis `_TilesetImageCache.loadMany` lit le fichier, applique eventuellement `transparentColor`, decode en `ui.Image`, et calcule `tilesPerRowById`.

V1-88 ne doit pas charger dans `build()` ni `paint()`. Le contrat recommande :

- un registry/provider editor dedie ;
- entree : `projectRootPath`, `ProjectManifest`, `requestedTilesetIds`, `tileWidth/tileHeight`, transparent colors ;
- sortie : status par tileset, chemin absolu, `ui.Image?`, dimensions, columns/rows, diagnostics ;
- cle cache : `relativePath`, transparentColor, tile size, et si possible metadata d'invalidation type mtime ;
- aucune lecture disque dans le widget/painter cinematic.

## 9. Audit Map Editor rendering

`MapCanvas` est un `ConsumerStatefulWidget` interactif. Il lit l'etat global editor, hover, gestures, selection, outils, pan/zoom, timers d'animation et previews d'edition. Il est donc trop couple pour etre embarque.

`MapGridPainter` est utile comme reference mais pas comme dependance brute. Son ordre observe :

1. terrain visible ;
2. path visible ;
3. tile background ;
4. surface atlas preview ;
5. shadows ;
6. placed elements background ;
7. collision overlays ;
8. grille/hover ;
9. gameplay zones et entities background ;
10. tile/placed elements foreground ;
11. entities foreground ;
12. selection/tool/environment/events/triggers/warps/connections.

V1-88 doit reprendre seulement la partie decor :

- terrain/path si resolubles ;
- tile background ;
- surface ;
- shadows uniquement si deja resolues et non ambigu ;
- placed elements ;
- foreground split si le helper peut etre appele sans selection/tool state.

Danger : `MapGridPainter` utilise des helpers prives/part-files, des couleurs legacy, un timer d'animation et des overlays editor. Il faut extraire ou dupliquer minimalement des calculs stables dans un contrat testable plutot que dependre du painter massif.

## 10. Audit runtime / Flame anti-scope

`RuntimeMapGame` et `PlayableMapGame` sont des `FlameGame`. `PlayableMapGame` porte input, `GameState`, player, NPC, camera, scenario, dialogue, battle, save/load et synchronisation monde. `MapLayersComponent` vit dans le monde Flame. Ces composants sont faits pour executer ou viewer un runtime, pas pour authorer un decor statique dans le Builder.

Interdits V1-88 :

- import `package:map_runtime/map_runtime.dart` dans `map_editor` ;
- `PlayableMapGame`, `RuntimeMapGame`, `GameWidget`, `FlameGame`, `CameraComponent`, `MapLayersComponent`, `PlayerComponent` ;
- `SceneCinematicRuntimeAwaitableAdapter` ;
- usage runtime de `GameState` ;
- boucle/timer de playback cinematic.

Frontiere : `map_editor` consomme `map_core` + assets projet + `CustomPainter`. `map_runtime` garde le chargement/monde/camera/acteur runtime.

## 11. Options techniques comparees

Option A — Reutiliser `MapCanvas` complet : rejetee. Avantage : fidelite immediate. Inconvenients : couplage editor global, gestes/outils, selections, hover, timers, overlays, risque mutation et surface UI trop lourde.

Option B — Reutiliser les painters Map Editor existants : partiellement retenue. Avantage : ordre et cas existants. Inconvenients : `MapGridPainter` est massif, prive par part-file et melange decor/overlays. Retenir seulement des helpers purs ou une extraction future controlee.

Option C — Extraire un renderer read-only partage : bon objectif long terme, mais trop large pour V1-88. Risque de regression Map Editor et gros scope de tests.

Option D — Creer un renderer Cinematic dedie V0 : simple et anti-runtime. Risque de duplication avec Map Editor si fait sans contrat.

Option E — Hybride recommande : retenue. Creer un petit contrat de rendu cinematic dedie, reemployer des helpers purs existants si possible, ne jamais brancher `MapCanvas` complet.

## 12. Option retenue

Option E est retenue parce qu'elle respecte les frontieres produit et reduit le risque :

- `map_core` reste donnees/read models purs ;
- `map_editor` resout les assets et peint en read-only ;
- `map_runtime` reste hors scope ;
- V1-88 peut livrer une vraie map statique sans attendre une refonte de `MapGridPainter`.

## 13. Contrat recommande du futur renderer V1-88

Nom de contrat propose : `CinematicMapBackdropTileRenderPlan` ou equivalent editor-local.

Entrees :

- `MapData mapData` ;
- `ProjectManifest project` ;
- `ProjectSettings settings` ;
- `CinematicAsset asset` pour statut/label seulement ;
- registry des tilesets resolus ;
- flags de fallback ;
- size disponible de la preview.

Sorties :

- `mapWidth`, `mapHeight`, `tileWidth`, `tileHeight` ;
- `List<CinematicMapBackdropBitmapInstruction>` ;
- diagnostics asset/layer/sourceRect ;
- fallback vers `CinematicMapBackdropPreviewModel.visualPrimitives` si plan bitmap indisponible ;
- status UX : rendered / partial / structuralFallback / unavailable.

Instruction bitmap V0 :

- `layerId`, `layerLabel`, `layerKind` ;
- `zOrder` ;
- `tilesetId` ;
- `srcRect` pixels ;
- `dstRect` map units ;
- `opacity` ;
- `diagnosticCode?`.

Painter :

- recoit seulement plan + images deja resolues ;
- cull/clip au viewport ;
- conserve ratio map ;
- ne lit pas le disque ;
- ne demarre pas d'animation ;
- ne modifie pas la map ou le projet.

## 14. Contrat recommande d'asset/image resolution

Creer un service/provider editor dedie, pas dans le painter :

```text
EditorTilesetAssetRegistry
input: projectRootPath + ProjectManifest + requestedTilesetIds + tile metrics
output: Map<tilesetId, CinematicResolvedTilesetAsset>
```

`CinematicResolvedTilesetAsset` doit contenir :

- `tilesetId` ;
- `relativePath` ;
- `absolutePath` ;
- `ui.Image? image` ;
- `imageWidth/imageHeight` ;
- `tileWidth/tileHeight` ;
- `columns/rows` ;
- `transparentColor` appliquee ou non ;
- `status` : available / missingEntry / missingFile / decodeFailed / invalidTileSize / emptyImage ;
- diagnostics humains.

Regle : `build()` peut observer un Future/AsyncValue deja en cours, mais ne doit pas faire `File(...).readAsBytes()` ou `ui.instantiateImageCodec` directement.

## 15. Contrat recommande layer ordering

Ordre V1-88 recommande :

1. `TerrainLayer` bitmap resoluble, sinon fallback discret ;
2. `PathLayer` bitmap resoluble, statique ;
3. `TileLayer` background ;
4. `SurfaceLayer` atlas resoluble ;
5. shadows statiques seulement si helper editor pur disponible ;
6. `MapPlacedElement` background ;
7. `TileLayer` foreground si split explicite disponible ;
8. `MapPlacedElement` foreground.

Exclure explicitement collision, grille editor, hover, masks, tool previews, gameplay zones, entities, events, triggers, warps, connections et selections.

Si un layer `isVisible == false` ou `opacity <= 0`, il ne genere aucune instruction bitmap. Si un `tileId` est invalide ou hors image, le renderer genere un diagnostic et peut peindre un placeholder local uniquement si le fallback global n'est pas preferable.

## 16. Fallbacks et diagnostics futurs

Fallbacks :

- tileset entry absent : structural fallback + diagnostic bloquant layer ;
- fichier absent : structural fallback + chemin relatif affiche ;
- decode fail : structural fallback + diagnostic ;
- source rect hors image : placeholder cellule/layer + warning ;
- layer non resoluble : ignorer en bitmap mais exposer diagnostic ;
- map grande type 55 x 55 : fit complet par defaut, pas de zoom mental requis, avec possibilité future de viewport/camera.

Diagnostics no-code :

- `Tileset indisponible` ;
- `Image illisible` ;
- `Tuile hors atlas` ;
- `Couche masquee` ;
- `Couche non rendue en V0` ;
- `Fallback structurel affiche`.

## 17. Preservation timeline / transports / pickers

V1-88 doit préserver les proportions acquises en V1-86 :

- preview map visible sans ecraser la timeline ;
- timeline par pistes et rangées conservees ;
- transports restent disabled ;
- probe/selection locaux ne deviennent pas playback ;
- pickers map-aware et Character Library ne changent pas de contrat ;
- inspecteur et palette ne recuperent pas d'IDs bruts.

Le renderer ne doit pas introduire de `currentTimeMs`, `playbackTimeMs`, `isPlaying`, timer ou ticker cinematic.

## 18. Preparation future Actor Display

V1-89 pourra cadrer les acteurs parce que V1-88 donnera un decor fiable :

- l'acteur sera positionne sur des coordonnees map lisibles ;
- les placements initiaux et movement targets auront un referentiel visuel ;
- les sprites Character Library pourront etre compares au decor ;
- les diagnostics acteur ne masqueront plus le probleme fondamental du decor symbolique.

V1-87 ne rend aucun acteur.

## 19. Non-objectifs confirmes

Non faits :

- pas de code Dart produit ;
- pas de modification `packages/` ;
- pas de test ;
- pas de screenshot ;
- pas de Visual Gate ;
- pas de renderer ;
- pas de vraie map affichee ;
- pas de tile rendue ;
- pas de runtime ;
- pas de Flame ;
- pas de playback ;
- pas d'acteurs rendus ;
- pas de fake tiles ;
- pas de donnees Selbrume hardcodees ;
- pas d'image IA ni `gpt-image-2`.

## 20. Tests futurs V1-88

Tests recommandes :

- plan builder pur/editor : `TileLayer` visible produit instructions bitmap ;
- `tileId <= 0` ignore ;
- source rect hors image diagnostique ;
- tileset absent diagnostique ;
- `isVisible=false` et `opacity=0` ignorent la couche ;
- `SurfaceLayer` resoluble dessine atlas, sinon fallback ;
- `TerrainLayer TerrainType.none` ignore ;
- `PathLayer` statique resoluble ;
- aucune instruction pour collision/entities/events/triggers/warps/gameplayZones ;
- widget Builder affiche vraie map quand registry available ;
- widget Builder affiche fallback structurel quand registry unavailable ;
- proportions/timeline/transports disabled preserves ;
- scan anti-runtime dans `map_editor`.

## 21. Visual Gate future V1-88

Visual Gate recommandee, uniquement en V1-88 :

- viewport 1663 x 926 coherent avec les gates precedentes ;
- vraie map statique visible, pas seulement primitives ;
- timeline conservee ;
- badges limites : decor seul, sans acteurs, sans lecture ;
- fallback structurel capture separee si asset absent ;
- inspection via outil visuel seulement apres implementation V1-88.

V1-87 n'a genere aucune image.

## 22. Roadmaps mises a jour

Roadmaps modifiees :

- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

Mise a jour :

- V1-87 devient `Cinematic Map Backdrop Real Tile Rendering Prep Contract` DONE ;
- V1-88 devient `Cinematic Map Backdrop Real Tile Renderer V0` TODO ;
- V1-89 devient `Cinematic Actor Display Preview Prep Contract` TODO ;
- prochain lot recommande : V1-88.

## 23. Commandes executees

Commandes de lecture/audit :

- `pwd`
- `git branch --show-current`
- `git status --short --untracked-files=all`
- `git diff --stat`
- `git diff --name-only`
- `git log --oneline -n 15`
- `sed -n ...` sur prompt, regles, skills, roadmaps et rapports precedents
- `nl -ba ... | sed -n ...` sur fichiers core/editor/runtime audites
- `rg -n ...` pour painters, layers, tilesets/assets et anti-scope runtime

Commandes non executees par design :

- pas de `flutter test` ;
- pas de `dart test` ;
- pas de `flutter analyze` ;
- pas de screenshot ;
- pas de build runner.

Raison : le lot est documentaire et interdit tests/screenshot/code produit.

Les sorties finales des checks anti-scope sont reproduites dans l'Evidence Pack V1-87.

## 24. Checks anti-scope

Resultat attendu et verifie en fin de lot :

- `git diff --name-only -- packages` : aucune sortie ;
- `git diff --check` : aucune sortie ;
- termes runtime/playback seulement dans les sections anti-scope/non-objectifs des rapports/roadmaps.

## 25. Evidence Pack

Evidence Pack cree :

`reports/narrativeStudio/scenes/ns_scenes_v1_87_evidence_pack.md`

Il contient Gate 0, fichiers lus, notes sub-agents, recherches `rg`, arbitrage, hunks complets des roadmaps modifiees, checks git finaux et auto-review critique.

## 26. Auto-review critique

1. Est-ce que V1-87 a modifie du code produit ? Non.
2. Est-ce que V1-87 a modifie packages/ ? Non.
3. Est-ce que V1-87 a cree un test ? Non.
4. Est-ce que V1-87 a genere une image ou un screenshot ? Non.
5. Est-ce que V1-87 a affiche une vraie map ? Non.
6. Est-ce que V1-87 a importe runtime/Flame ? Non.
7. Est-ce que V1-87 a propose `PlayableMapGame` ? Non ; il est explicitement rejete.
8. Est-ce que V1-87 a compare `MapCanvas` complet ? Oui ; option rejetee.
9. Est-ce que V1-87 a identifie les painters reutilisables ? Oui ; helpers/passes Map Editor seulement sous contrat.
10. Est-ce que V1-87 a identifie les painters dangereux ? Oui ; `MapCanvas` complet et `MapGridPainter` brut.
11. Est-ce que V1-87 a defini la resolution des tileset images ? Oui ; registry editor en amont.
12. Est-ce que V1-87 a defini les layers a rendre ? Oui.
13. Est-ce que V1-87 a defini les layers a exclure ? Oui.
14. Est-ce que V1-87 a defini l'ordre de rendu futur ? Oui.
15. Est-ce que V1-87 a defini les fallbacks ? Oui.
16. Est-ce que V1-87 a defini les tests V1-88 ? Oui.
17. Est-ce que V1-87 a mis a jour les roadmaps ? Oui.
18. Est-ce que l'Evidence Pack est complet ? Oui, apres verification finale.
19. Quel est le prochain lot exact recommande ? `NS-SCENES-V1-88 — Cinematic Map Backdrop Real Tile Renderer V0`.

Risque restant : V1-88 devra trancher au code le niveau exact de reutilisation `MapGridPainter` vs duplicated minimal instructions. Le contrat documentaire limite ce risque mais ne le supprime pas.

## 27. Recommandation pour le prochain lot

Lancer `NS-SCENES-V1-88 — Cinematic Map Backdrop Real Tile Renderer V0`.

Objectif V1-88 : afficher les vraies tiles/assets de la map dans la zone preview du Cinematic Builder, avec un renderer editor-only read-only, des images resolues en amont, diagnostics/fallbacks, proportions V1-86 preservees, sans runtime, Flame, playback ni acteurs rendus.
