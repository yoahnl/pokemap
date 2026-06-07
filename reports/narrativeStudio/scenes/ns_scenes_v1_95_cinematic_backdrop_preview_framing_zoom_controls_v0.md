# NS-SCENES-V1-95 — Cinematic Backdrop Preview Framing / Zoom Controls V0

## 1. Resume executif

Statut propose : `DONE`.

A la demande de Karim, V1-95 corrige l'effet "mini-map" de la preview cinematic backdrop apres V1-94/V1-94 bis. Le Builder garde `Carte entiere` par defaut, ajoute `Vue scene`, ajoute zoom - / reset / + local, centre la vue sur l'acteur selectionne si possible, sinon sur la bounding box des acteurs renderable, sinon sur le centre de la map.

Phrase canonique respectee : V1-95 rend la preview cinematic lisible comme une scene cadree. V1-95 ne lance toujours pas la cinematique.

## 2. Gate 0

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
```

Sortie vide au Gate 0.

```text
git diff --stat
```

Sortie vide au Gate 0.

```text
git diff --name-only
```

Sortie vide au Gate 0.

```text
git log --oneline -n 15
35415a41 feat(map_editor): smooth left sidebar transitions & refactored narrative studio quick actions
0f1cce5c Merge branch 'feature/stabilize-sidebar'
cf774aef ui: stabilize World Explorer sidebar width and card ordering in Narrative Studio
cdd653e5 feat(narrative): auto-commit changes
50d3ca85 remove failures
48d6398d ui: collapse project explorer accordions by default and fix tests
4dbebbfe feat(narrative): auto-commit changes
76a312ec feat(narrative): auto-commit changes
9c5db6f0 feat(narrative): auto-commit changes
eb05d109 feat(narrative): auto-commit changes
3e767d80 feat(narrative): auto-commit changes
3a3689df feat(narrative): auto-commit changes
12e52f7a update selbrume
1ac4186f update selbrume
a085d128 feat(narrative): auto-commit changes
```

## 3. Fichiers lus

Obligatoires lus/consultes : `AGENTS.md`, `agent_rules.md`, les roadmaps scenes, les rapports V1-91/V1-92/V1-94/V1-94 bis, `cinematic_map_backdrop_preview_panel.dart`, `cinematic_map_backdrop_viewport_transform.dart`, `cinematic_map_backdrop_layer_render_plan.dart`, `cinematic_map_backdrop_layer_renderer.dart`, `cinematic_actor_display_preview_overlay.dart`, `cinematic_builder_workspace.dart`, `cinematics_library_workspace.dart`, `cinematic_builder_workspace_test.dart`, `cinematics_library_workspace_test.dart`, `cinematic_actor_display_preview_model.dart`, `cinematic_map_backdrop_preview_model.dart`.

`agent_rules.md` rappelle : preuves executables, tests non factices, Git read-only, Evidence Pack complet, auto-review obligatoire.

## 4. Synthese des sub-agents et arbitrages

Sub-agent A — audit backdrop/viewport : le fit actuel passe par `fittedCinematicMapBackdropRect`; une map 55x55 devient minuscule parce que toute la map est forcee dans un viewport fixe. Recommandation : un transform partage entre backdrop, overlay acteurs et foreground.

Sub-agent B — modele framing : Option E retenue, soit `fitMap` conserve + `scene` + zoom local non persistant. Bornes : min `1.0`, max `4.0`, pas `0.25`.

Sub-agent C — focus : priorite V0 stable et testable : acteur selectionne renderable, puis bounding box des acteurs renderable, puis centre map. Pas d'actorMove interpolation.

Sub-agent D — integration painter/clip/transform : une seule frame map dans le viewport, clippee, appliquee au background, a l'Actor Display V1-92, puis au foreground.

Sub-agent E — UX : controles dans le panel backdrop, wording simple `Carte entiere`, `Vue scene`, `Zoom`. Transports inchanges et disabled.

Sub-agent F — tests/anti-scope : tests RED/GREEN, non-mutation, Path Studio/eau, acteurs alignes, Visual Gate, checks runtime/Flame/playback/Selbrume/image IA.

Sub-agent G/reviewer : le screenshot montre la scene cadree, l'eau Path Studio visible, les controles visibles, la timeline et l'inspector preserves.

## 5. Design Gate — Cinematic Backdrop Preview Framing / Zoom Controls V0

1. Limite corrigee : la preview V1-94 bis rendait enfin la vraie carte/eau, mais comme une mini-map trop dezoomee.
2. Cause mini-map : `fitMap` force toute la surface map dans le viewport, donc une 55x55 reduit fortement les tuiles.
3. Comportement conserve : `Carte entiere` preserve le fit-map existant.
4. Modes ajoutes : `fitMap` / `scene`.
5. Mode defaut : `fitMap`, pour ne pas changer le comportement initial.
6. Calcul `Vue scene` : vise une fenetre d'environ 22x14 tuiles, scale cover du viewport, puis zoom local.
7. Sources focus : acteur selectionne renderable, actors bbox, centre map.
8. Sans acteur : centre map.
9. Petite map : scale ne descend pas sous le fit-map et offset est centre/clamp.
10. Map non carree : scale calcule par dimensions pixels/tuiles et viewport, puis frame clamp.
11. Zoom clamp : `1.0..4.0`.
12. Reset : remet `zoom` a `1.0`, localement.
13. Transform partage : `framing.transform.frame` positionne le `SizedBox` commun map/background/acteurs/foreground.
14. Foreground V1-94 : peint dans le meme stack et la meme frame que le background.
15. Eau Path Studio : ordre de passes `terrain -> tileBackground -> path -> surface...`, donc le path water n'est plus recouvert.
16. Actor Display V1-92 : overlay reste dans la meme frame map.
17. Timeline/probe/duration/resize : le Builder complet reste vert `+180`.
18. Pickers : tests Builder complets gardent mapEntity/mapEvent/Character Library.
19. Transports : aucun playback ajoute, les transports restent disabled.
20. Runtime/Flame/GameState : aucun import/occurrence dans les fichiers source V1-95.
21. Playback/currentTimeMs/playbackTimeMs : aucune occurrence dans les fichiers source V1-95.
22. Mutation ProjectManifest/MapData : test de zoom/reset compare les JSON avant/apres.
23. Hardcode Selbrume : aucune occurrence source V1-95.
24. Couleurs hardcodees : aucun nouveau `Color(0x...)` ou `Colors.*` dans le diff UI; les controles utilisent le design system.
25. Visual Gate : `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_95_cinematic_backdrop_preview_framing_zoom_controls_v0.png`.
26. Prochain lot : `NS-SCENES-V1-96 — Cinematic Actor Display Preview Sprite Resolver Prep Contract`.

## 6. Probleme produit apres V1-94 bis

Le decor est fidele, mais la preview donne encore une sensation satellite. L'utilisateur voit l'eau et la map, mais pas a une echelle proche d'une scene jouable. Karim a aussi rappele que les elements Path Studio, donc l'eau, doivent rester visibles.

## 7. Scope realise

- Helper editor-only `cinematic_backdrop_preview_framing.dart`.
- Etat local `_backdropFramingState` dans le Builder, reset au changement de cinematic.
- Controles `Carte entiere`, `Vue scene`, zoom -, reset, zoom +, badge zoom.
- Frame partagee pour backdrop bitmap/layer, Actor Display V1-92 et foreground.
- Ordre de render pass ajuste pour restaurer l'eau Path Studio au-dessus du tile background.
- Tests widget et unitaires cibles.
- Visual Gate et roadmaps V1-95/V1-96.

## 8. Modele de framing editor-only

Nouveau fichier : `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_backdrop_preview_framing.dart`.

Code genere central :

```dart
enum CinematicBackdropPreviewFramingMode {
  fitMap,
  scene,
}

@immutable
final class CinematicBackdropPreviewFramingState {
  const CinematicBackdropPreviewFramingState({
    this.mode = CinematicBackdropPreviewFramingMode.fitMap,
    this.zoom = 1,
  });

  static const minZoom = 1.0;
  static const maxZoom = 4.0;
  static const zoomStep = 0.25;

  final CinematicBackdropPreviewFramingMode mode;
  final double zoom;
}
```

## 9. Mode Carte entiere

`fitMap` retourne le `fittedCinematicMapBackdropRect` existant. Le zoom affiche `1.00x` et n'est pas actif hors `Vue scene`.

## 10. Mode Vue scene

`scene` calcule un scale de base visant environ 22 tuiles de large et 14 tuiles de haut, puis applique le zoom local. La frame est clamp pour eviter les espaces vides.

## 11. Zoom controls

Les controles sont construits avec `PokeMapSegmentedTabs`, `PokeMapIconButton` et `PokeMapBadge`. Les tabs ont maintenant une key optionnelle dans le design system pour fiabiliser les tests et les interactions.

## 12. Focus sources / fallback centre map

Focus V0 :

```text
1. selectedStep.actorId si l'acteur est renderable
2. bounding box des acteurs renderable
3. centre map
```

Le code ne parse pas les labels, ne lit pas `GameState`, ne simule pas `actorMove`.

## 13. Viewport transform partage

Le panel ne centre plus chaque painter separement. Il cree une frame map commune :

```dart
Positioned.fromRect(
  rect: framing.transform.frame,
  child: SizedBox(
    key: const ValueKey('cinematic-builder-map-backdrop-map-frame'),
    child: Stack(
      children: [
        CustomPaint(...background...),
        CinematicActorDisplayPreviewOverlay(...),
        CustomPaint(...foreground...),
      ],
    ),
  ),
)
```

## 14. Preservation backdrop V1-94 bis

Le fix Path Studio/eau est preserve et renforce : la passe `path` peint apres `tileBackground`. Le test `uses Path Studio center pattern when a path layer references its base preset` est vert.

## 15. Preservation Actor Display V1-92

Test ajoute : `keeps actor placeholders aligned after scene framing zoom`. L'ancre attendue est calculee depuis la frame map partagee; l'acteur reste aligne.

## 16. Preservation timeline / duration / resize / probe

La suite complete `cinematic_builder_workspace_test.dart` passe a `+180`. Elle contient les tests existants duration editor, resize handle, mouse probe, timeline, transports, pickers et captures historiques.

## 17. Preservation pickers map-aware / Character Library

Pas de changement de modele ou de picker. Les regressions existantes couvertes par la suite Builder restent vertes : mapEntity actor picker, movement target mapEntity/mapEvent pickers, Character Library picker.

## 18. Restrictions anti-runtime / anti-Flame / anti-playback

Aucun fichier `map_runtime`, `map_gameplay`, `map_battle`, `examples` ou `selbrume` n'est modifie. Les recherches anti-runtime/Flame/playback/sprite acteur/MapCanvas sont vides sur les fichiers source V1-95.

## 19. Design system

UI ajoutee via design system :

- `PokeMapSegmentedTabs`
- `PokeMapIconButton`
- `PokeMapBadge`

Aucune nouvelle couleur hardcodee dans le diff UI.

## 20. Tests ajoutes ou modifies

Tests V1-95 ajoutes dans `packages/map_editor/test/cinematic_builder_workspace_test.dart` :

- `renders scene framing mode zoomed beyond full map fit`
- `zooms in and resets cinematic backdrop framing without mutating project or map`
- `keeps actor placeholders aligned after scene framing zoom`
- `resolves cinematic backdrop focus from selected actor before fallbacks`
- `captures V1-95 cinematic backdrop framing zoom controls when requested`

Non-regression ajustee : ordre des passes attendu devient `terrain`, `tileBackground`, `path`, `surface`, `placedBackground`, `tileForeground`, `placedForeground`.

## 21. Visual Gate

Fichier produit :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_95_cinematic_backdrop_preview_framing_zoom_controls_v0.png
```

Preuve :

```text
-rw-r--r--  1 karim  staff  255831 Jun  7 14:11 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_95_cinematic_backdrop_preview_framing_zoom_controls_v0.png
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_95_cinematic_backdrop_preview_framing_zoom_controls_v0.png: PNG image data, 1663 x 926, 8-bit/color RGBA, non-interlaced
3a2ee1eef54a8c7a4342d137733484cd734625a71f4b90d441c0140ad1d3cff9  reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_95_cinematic_backdrop_preview_framing_zoom_controls_v0.png
```

## 22. Commandes executees

Voir l'Evidence Pack pour le detail. Commandes principales :

- RED test initial du mode scene.
- Tests editor cibles.
- Suite Builder complete.
- Suite Library.
- Visual Gate.
- Tests core cibles.
- `dart analyze` cible editor.
- `dart analyze` core.
- `flutter analyze` global editor.
- Checks anti-scope.
- Checks git finaux.

## 23. Resultats des tests

Editor :

```text
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'renders scene framing mode zoomed beyond full map fit'
00:03 +1: All tests passed!
```

```text
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'uses Path Studio center pattern when a path layer references its base preset'
00:02 +1: All tests passed!
```

```text
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart
00:25 +180: All tests passed!
```

```text
flutter test --reporter=compact test/cinematics_library_workspace_test.dart
00:06 +21: All tests passed!
```

Core :

```text
cinematic_actor_display_preview_model_test.dart: +25, All tests passed!
cinematic_map_backdrop_preview_model_test.dart: +19, All tests passed!
cinematic_stage_map_source_catalog_test.dart: +7, All tests passed!
cinematic_asset_test.dart: +14, All tests passed!
project_manifest_cinematics_test.dart: +9, All tests passed!
```

## 24. Analyze

Analyse ciblee editor :

```text
Analyzing cinematic_backdrop_preview_framing.dart, cinematic_builder_workspace.dart, cinematic_map_backdrop_preview_panel.dart, cinematic_map_backdrop_render_pass.dart, pokemap_dashboard_primitives.dart, cinematic_builder_workspace_test.dart...
No issues found!
```

Analyse core :

```text
Analyzing map_core...
No issues found!
```

Analyse globale editor :

```text
345 issues found. (ran in 2.8s)
```

Cause bloquante hors lot : dette preexistante dans `pokemon_sdk_move_catalog_converter.dart`, `sync_pokemon_sdk_moves_catalog_use_case.dart` et tests associes, avec parametres/classes/getters Pokemon SDK non definis. Aucun fichier V1-95 n'apparait dans les erreurs globales.

## 25. Checks anti-scope

Sorties vides pour :

- diff `packages/map_runtime packages/map_gameplay packages/map_battle examples selbrume`
- runtime/Flame/GameState/map_runtime
- playback/currentTimeMs/playbackTimeMs/isPlaying
- actor sprite final
- MapCanvas/MapGridPainter
- chargement/decode image dans widgets/painters
- hardcode Selbrume dans source V1-95
- couleurs hardcodees ajoutees dans diff UI
- image IA/gpt-image-2

Checks git finaux :

```text
git diff --check
```

Sortie vide.

```text
git status --short --untracked-files=all
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_render_pass.dart
 M packages/map_editor/lib/src/ui/design_system/pokemap_dashboard_primitives.dart
 M packages/map_editor/test/cinematic_builder_workspace_test.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_backdrop_preview_framing.dart
?? reports/narrativeStudio/scenes/ns_scenes_v1_95_cinematic_backdrop_preview_framing_zoom_controls_v0.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_95_evidence_pack.md
?? reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_95_cinematic_backdrop_preview_framing_zoom_controls_v0.png
```

## 26. Fichiers crees

- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_backdrop_preview_framing.dart`
- `reports/narrativeStudio/scenes/ns_scenes_v1_95_cinematic_backdrop_preview_framing_zoom_controls_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_95_evidence_pack.md`
- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_95_cinematic_backdrop_preview_framing_zoom_controls_v0.png`

## 27. Fichiers modifies

- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_render_pass.dart`
- `packages/map_editor/lib/src/ui/design_system/pokemap_dashboard_primitives.dart`
- `packages/map_editor/test/cinematic_builder_workspace_test.dart`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

## 28. Roadmaps mises a jour

`road_map_scenes.md` et `road_map_scene_builder_authoring.md` marquent V1-95 `DONE`, deplacent le Sprite Resolver en V1-96 et recommandent :

```text
NS-SCENES-V1-96 — Cinematic Actor Display Preview Sprite Resolver Prep Contract
```

## 29. Limites connues

- Pas de camera runtime.
- Pas de playback.
- Pas de sprite acteur final.
- Pas de persistence du zoom/framing.
- Pas de mutation ProjectManifest/MapData.
- L'analyse globale editor reste rouge sur dette Pokemon SDK hors lot.

## 30. Non-objectifs confirmes

Non faits : runtime, Flame, map_runtime, GameState, CameraComponent, PlayableMapGame, actorMove interpolation, pathfinding, collision, trigger/warp, event marker runtime, sprite acteur final, MapCanvas complet, MapGridPainter brut, image IA, gpt-image-2, modification Selbrume.

## 31. Evidence Pack

Evidence Pack : `reports/narrativeStudio/scenes/ns_scenes_v1_95_evidence_pack.md`.

Il contient le Gate 0, les sorties RED/GREEN, le code du nouveau helper, les modifications source/test, la preuve screenshot, les checks anti-scope et l'auto-review.

## 32. Auto-review critique

Ce qui est prouve :

- `Vue scene` agrandit la frame map par rapport au fit-map.
- Zoom/reset est local et ne mute pas ProjectManifest/MapData.
- Actor Display V1-92 reste aligne apres zoom.
- Path Studio/eau reste rendu.
- Builder/Library restent accessibles.
- Core read models cibles restent verts.
- Aucun runtime/Flame/playback/sprite final n'est branche.

Ce qui n'est pas prouve :

- Une camera runtime exacte joueur, volontairement hors scope.
- Des sprites acteurs finaux, volontairement repousses en V1-96.
- La resolution de toutes les tailles possibles de map via screenshot, meme si le helper clamp petites/non carrees par construction et tests.

## 33. Recommandation pour le prochain lot

Recommandation :

```text
NS-SCENES-V1-96 — Cinematic Actor Display Preview Sprite Resolver Prep Contract
```

Raison : maintenant que le decor est lisible, on peut cadrer le resolver de sprites statiques des acteurs sans confondre preview editor et runtime.
