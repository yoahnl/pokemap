# Lot TSX-1 — Pokemon SDK TSX Animated Tileset Audit / Import Prep V0

## 1. Verdict

Lot TSX-1 implemente.

Le lot ajoute une brique pure d'audit/import prep TSX cote `map_editor`, avec tests sur le vrai fichier `TECH-Animations.tsx`. Aucun preset Surface n'est genere automatiquement, aucun manifest n'est mute, aucun appel IA/PixelLab/MCP n'est effectue, et aucun package runtime/gameplay/battle n'est modifie.

Context Mode : indisponible dans cet environnement. La commande `ctx stats` a retourne `zsh:1: command not found: ctx`.

## 2. Audit initial

Commande initiale :

```bash
pwd
git status --short --untracked-files=all
git diff --stat
```

Sortie utile :

```text
/Users/karim/Project/pokemonProject
 M packages/map_editor/lib/src/features/surface_studio/atlas/surface_studio_atlas_panel.dart
 M packages/map_editor/lib/src/features/surface_studio/preview/surface_studio_preview_panel.dart
 M packages/map_editor/lib/src/features/surface_studio/preview/surface_studio_surface_preview_renderer.dart
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_view_geometry.dart
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_mistral_mapping_suggester.dart
 M packages/map_editor/test/dialogue_disk_hierarchy_v13_test.dart
 M packages/map_editor/test/editor_project_session_controller_test.dart
 M packages/map_editor/test/map_canvas_entity_properties_smoke_test.dart
 M packages/map_editor/test/project_dialogue_import_and_folder_use_case_test.dart
 M packages/map_editor/test/project_element_collision_persistence_test.dart
 M packages/map_editor/test/project_tileset_use_cases_test.dart
 M packages/map_editor/test/shell_chrome_test_harness.dart
 M packages/map_editor/test/surface_painter/editor_notifier_surface_paint_test.dart
 M packages/map_editor/test/surface_painter/surface_layer_static_preview_test.dart
 M packages/map_editor/test/surface_painter/surface_palette_panel_test.dart
 M packages/map_editor/test/surface_painter/surface_to_gameplay_zone_action_test.dart
 M packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart
 M packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
 M packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart
 M packages/map_editor/test/ui_panels_smoke_test.dart
?? packages/map_editor/lib/src/features/surface_studio/preview/surface_studio_surface_preview_cells.dart
?? packages/map_editor/lib/src/features/surface_studio/surface_studio_mistral_response_parser.dart
?? packages/map_editor/test/surface_studio/surface_studio_mistral_response_parser_test.dart
?? packages/map_editor/test/surface_studio/surface_studio_surface_preview_cells_test.dart
?? reports/surface/surface_studio_rebuild_v2_5_fit_width_multi_role_mistral_parser.md
```

Ces lignes etaient deja presentes avant ce lot TSX-1. Elles correspondent au travail V2.5 non commite et n'ont pas ete nettoyees ni revert.

Fichiers audites :

```text
packages/map_core/lib/src/models/surface.dart
packages/map_core/lib/src/models/surface_catalog.dart
packages/map_core/lib/src/operations/surface_animation_frame_json_codec.dart
packages/map_core/lib/src/operations/surface_animation_timeline_json_codec.dart
packages/map_core/lib/src/operations/surface_studio_read_model.dart
packages/map_editor/lib/src/features/surface_studio/
pokémon_sdk_test_project/Data/Tiled/Tilesets/TECH-Animations.tsx
pokémon_sdk_test_project/Data/Tiled/Assets/TECH-Nature-animations.png
```

Reponses aux questions d'audit :

1. Parser TSX existant : aucun parser TSX/TMX dedie n'a ete trouve dans `map_editor` ou `map_core`.
2. Concepts Tiled existants : le repo contient des fixtures `.tsx`/`.tmx` dans `pokémon_sdk_test_project`, et des concepts generiques de tilesets projet, mais pas de lecture XML Tiled animee.
3. Les modeles Surface peuvent representer une animation TSX : oui partiellement. `SurfaceAnimationTimeline` stocke une liste ordonnee de `SurfaceAnimationFrame`, chaque frame portant un `SurfaceAtlasTileRef(column,row)` et `durationMs`. Un tile id Tiled peut donc etre converti en `(column,row)`.
4. Les codecs Surface peuvent stocker une animation issue de tile ids : oui, apres conversion `tileId -> column,row`, via `SurfaceAnimationFrame.tileRef` + `durationMs`. Il n'existe pas encore de codec TSX dedie ni d'import automatique dans le catalogue.
5. Surface Studio suppose encore "columns are variants, rows are frames" : oui dans ses assistants verticaux. `SurfaceStudioScreen` initialise encore un layout `columnsAreVariantsRowsAreFrames`, et `surfaceStudioProjectSurfaceAnimationFromReadyPlanItem` genere une timeline en gardant la meme colonne et en incrementant la ligne.
6. Incompatibilites avec le TSX Pokemon SDK : le TSX declare des frames explicites par `tileid`, potentiellement non equivalentes a "meme colonne, lignes successives". Il melange aussi plusieurs regions/cas visuels dans une grande image de 98 x 109 tuiles, sans semantic Surface role dans le XML.

## 3. Resume TSX

Fichier audite :

```text
pokémon_sdk_test_project/Data/Tiled/Tilesets/TECH-Animations.tsx
```

Entete TSX :

```xml
<tileset version="1.10" tiledversion="1.10.2" name="TECH-Animations" tilewidth="32" tileheight="32" tilecount="10682" columns="98">
 <image source="../Assets/TECH-Nature-animations.png" trans="f05ba1" width="3136" height="3488"/>
```

Valeurs deduites :

```text
name = TECH-Animations
tileWidth = 32
tileHeight = 32
columns = 98
tileCount = 10682
imageSource = ../Assets/TECH-Nature-animations.png
transparentColor = f05ba1
imageWidth = 3136
imageHeight = 3488
image grid = 98 x 109 tiles
animationCount = 242
```

Verification dimensionnelle :

```text
3136 / 32 = 98 columns
3488 / 32 = 109 rows
98 * 109 = 10682 tiles
```

## 4. Formule tileId -> row / column / sourceRect

Tiled utilise ici des tile ids 0-based.

Formule :

```text
column = tileId % columns
row = tileId ~/ columns
sourceX = column * tileWidth
sourceY = row * tileHeight
sourceW = tileWidth
sourceH = tileHeight
```

Exemples testes :

```text
tileId = 99
columns = 98
column = 99 % 98 = 1
row = 99 ~/ 98 = 1
sourceX = 1 * 32 = 32
sourceY = 1 * 32 = 32
sourceRect = x=32 y=32 w=32 h=32

tileId = 105
columns = 98
column = 105 % 98 = 7
row = 105 ~/ 98 = 1
sourceX = 7 * 32 = 224
sourceY = 1 * 32 = 32
sourceRect = x=224 y=32 w=32 h=32
```

## 5. Nombre d'animations detectees

Le parser detecte :

```text
242 animations Tiled
```

La commande de controle :

```bash
rg -c "<animation>" "pokémon_sdk_test_project/Data/Tiled/Tilesets/TECH-Animations.tsx"
```

Sortie :

```text
242
```

## 6. Exemple detaille tile id 99

Bloc TSX :

```xml
<tile id="99">
  <animation>
   <frame tileid="99" duration="100"/>
   <frame tileid="105" duration="100"/>
   <frame tileid="111" duration="100"/>
   <frame tileid="117" duration="100"/>
   <frame tileid="123" duration="100"/>
   <frame tileid="129" duration="100"/>
   <frame tileid="135" duration="100"/>
   <frame tileid="141" duration="100"/>
   <frame tileid="147" duration="100"/>
   <frame tileid="153" duration="100"/>
   <frame tileid="159" duration="100"/>
   <frame tileid="165" duration="100"/>
   <frame tileid="171" duration="100"/>
   <frame tileid="177" duration="100"/>
   <frame tileid="183" duration="100"/>
   <frame tileid="189" duration="100"/>
  </animation>
 </tile>
```

Interpretation :

```text
baseTileId = 99
frameCount = 16
frame tile ids = 99, 105, 111, 117, 123, 129, 135, 141, 147, 153, 159, 165, 171, 177, 183, 189
duration per frame = 100 ms
```

Point important : ces frames ont un stride de `+6` en tile id pour cet exemple, pas `+98`. Elles ne sont donc pas "la meme colonne, ligne suivante" dans cette zone. Le TSX est la source de verite.

## 7. Pourquoi PokeMap doit importer les animations TSX

Pokemon SDK / Tiled n'a pas besoin de deviner les frames depuis une convention visuelle simple. Les animations sont declarees dans le XML :

```text
tile id de base -> liste ordonnee de frame tileid + duration
```

Pour PokeMap, le chemin sain est donc :

```text
1. lire le TSX ;
2. resoudre chaque tileid en coordonnees d'atlas ;
3. creer ou preparer des ProjectSurfaceAnimation depuis les timelines exactes ;
4. seulement ensuite demander a l'utilisateur ou a une aide IA de grouper/mapper ces animations en roles Surface.
```

Ce lot s'arrete a l'etape d'audit/parser. Il ne cree pas encore de `ProjectSurfaceAnimation`.

## 8. Pourquoi Surface Studio vertical atlas est insuffisant

Le modele Surface core est plus souple que l'assistant vertical actuel :

```text
SurfaceAtlasLayout.grid permet une grille arbitraire.
SurfaceAtlasTileRef stocke column,row en 0-based.
SurfaceAnimationTimeline stocke des frames ordonnees avec durationMs.
```

Mais Surface Studio V2.x travaille encore souvent comme suit :

```text
colonne = role / variante
ligne = frame
animation = meme colonne, lignes 0..N
```

Cette convention est utile pour un atlas auteur vertical propre, mais elle ne suffit pas pour `TECH-Animations.tsx` :

```text
- le fichier est un tileset Tiled general de 98 x 109 tuiles ;
- les animations sont explicites par tileid ;
- les frames peuvent sauter horizontalement ou dans d'autres regions ;
- le XML ne donne pas directement les roles Surface comme cornerNW, endNorth, isolated ;
- plusieurs familles visuelles cohabitent dans une meme image.
```

Conclusion : TSX d'abord, mapping Surface ensuite.

## 9. Fichiers crees / modifies

Crees :

```text
packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_animated_tileset_parser.dart
packages/map_editor/test/surface_studio/tiled_tsx_animated_tileset_parser_test.dart
reports/surface/surface_studio_tiled_tsx_animation_audit.md
```

Modifies :

```text
aucun fichier existant n'a ete modifie pour ce lot TSX-1
```

Supprimes :

```text
aucun
```

## 10. Tests

### Test cible TSX

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

Ligne finale exacte :

```text
00:00 +7: All tests passed!
```

Resultat : passe.

### Tests Surface Studio

Commande :

```bash
cd packages/map_editor && flutter test test/surface_studio --no-pub --reporter expanded
```

Sortie finale :

```text
00:23 +371: All tests passed!
```

Resultat : passe.

## 11. Analyze

Commande :

```bash
cd packages/map_editor && flutter analyze lib/src/features/surface_studio
```

Premiere sortie :

```text
Analyzing surface_studio...

   info • Dangling library doc comment • lib/src/features/surface_studio/importers/tiled_tsx_animated_tileset_parser.dart:1:1 • dangling_library_doc_comments

1 issue found. (ran in 2.2s)
```

Correction : le commentaire de tete du nouveau parser a ete transforme en commentaire simple de fichier.

Sortie finale :

```text
Analyzing surface_studio...
No issues found! (ran in 1.3s)
```

Resultat : passe.

## 12. Auto-review

Respect du scope :

```text
- Aucun runtime modifie.
- Aucun gameplay modifie.
- Aucun map_battle modifie.
- Aucun map_gameplay modifie.
- Aucun map_runtime modifie.
- Aucun appel IA.
- Aucun PixelLab.
- Aucun MCP.
- Aucun preset Surface genere automatiquement.
- Aucun ProjectManifest mute.
```

Choix techniques :

```text
- Parser place dans map_editor, car ce lot est import-only et non un contrat core persistant.
- Pas de dependance XML ajoutee : map_editor n'avait pas de dependance XML, et le besoin V0 est limite a un sous-ensemble TSX simple.
- Diagnostics non bloquants pour certains cas : le parser retourne un audit exploitable avec erreurs/warnings plutot que de cacher tout le fichier derriere une exception.
```

Risques restants :

```text
- Le parser V0 lit le subset TSX utile ici ; un futur import general Tiled devrait utiliser un vrai parser XML.
- Les attributs single-quote ne sont pas couverts en V0, car le TSX fourni utilise les guillemets doubles Tiled standard.
- La transformation vers ProjectSurfaceAnimation n'est pas faite dans ce lot.
- Le regroupement semantique en roles Surface reste un lot ulterieur.
```

## 13. Prochaine roadmap TSX

Suite recommandee :

```text
Lot TSX-2 — Import TSX tile animations into a PokeMap animation catalog
Lot TSX-3 — Surface Studio TSX region picker
Lot TSX-4 — Build Surface preset from selected TSX animated tiles
```

Principe directeur :

```text
TSX = source de verite pour les frames et durations.
Surface Studio = selection, regroupement et mapping.
Mistral = aide eventuelle pour nommer/grouper apres extraction, pas pour deviner les frames.
```

## 14. Git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie :

```text
 M packages/map_editor/lib/src/features/surface_studio/atlas/surface_studio_atlas_panel.dart
 M packages/map_editor/lib/src/features/surface_studio/preview/surface_studio_preview_panel.dart
 M packages/map_editor/lib/src/features/surface_studio/preview/surface_studio_surface_preview_renderer.dart
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_view_geometry.dart
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_mistral_mapping_suggester.dart
 M packages/map_editor/test/dialogue_disk_hierarchy_v13_test.dart
 M packages/map_editor/test/editor_project_session_controller_test.dart
 M packages/map_editor/test/map_canvas_entity_properties_smoke_test.dart
 M packages/map_editor/test/project_dialogue_import_and_folder_use_case_test.dart
 M packages/map_editor/test/project_element_collision_persistence_test.dart
 M packages/map_editor/test/project_tileset_use_cases_test.dart
 M packages/map_editor/test/shell_chrome_test_harness.dart
 M packages/map_editor/test/surface_painter/editor_notifier_surface_paint_test.dart
 M packages/map_editor/test/surface_painter/surface_layer_static_preview_test.dart
 M packages/map_editor/test/surface_painter/surface_palette_panel_test.dart
 M packages/map_editor/test/surface_painter/surface_to_gameplay_zone_action_test.dart
 M packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart
 M packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
 M packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart
 M packages/map_editor/test/ui_panels_smoke_test.dart
?? packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_animated_tileset_parser.dart
?? packages/map_editor/lib/src/features/surface_studio/preview/surface_studio_surface_preview_cells.dart
?? packages/map_editor/lib/src/features/surface_studio/surface_studio_mistral_response_parser.dart
?? packages/map_editor/test/surface_studio/surface_studio_mistral_response_parser_test.dart
?? packages/map_editor/test/surface_studio/surface_studio_surface_preview_cells_test.dart
?? packages/map_editor/test/surface_studio/tiled_tsx_animated_tileset_parser_test.dart
?? reports/surface/surface_studio_rebuild_v2_5_fit_width_multi_role_mistral_parser.md
?? reports/surface/surface_studio_tiled_tsx_animation_audit.md
```

Lignes TSX-1 ajoutees par ce lot :

```text
?? packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_animated_tileset_parser.dart
?? packages/map_editor/test/surface_studio/tiled_tsx_animated_tileset_parser_test.dart
?? reports/surface/surface_studio_tiled_tsx_animation_audit.md
```

Les autres lignes correspondent au worktree V2.5 deja present avant TSX-1.
