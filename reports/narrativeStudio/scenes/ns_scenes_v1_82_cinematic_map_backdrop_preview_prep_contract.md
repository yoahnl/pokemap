# NS-SCENES-V1-82 - Cinematic Map Backdrop Preview Prep Contract

## 1. Resume executif

V1-82 est le rapport manquant, relance a la demande de Karim apres constat que le lot avait ete indique dans les roadmaps sans artefact dedie.

Phrase canonique du lot :

```text
V1-82 definit comment afficher le decor de map plus tard.
V1-82 ne l'affiche pas encore.
```

Verdict : le Builder a assez d'information authoring pour demander une future preview backdrop, mais pas encore un contrat de rendu propre. La bonne suite est donc Option E : creer d'abord un read model pur `CinematicMapBackdropPreviewModel`, alimente depuis `CinematicAsset.mapId`, `ProjectManifest.maps`, `ProjectMapEntry.relativePath` et une `MapData` snapshot non destructive, puis seulement apres un renderer Flutter read-only sandbox.

V1-82 ne modifie aucun package volontairement. Les fichiers `packages/` deja modifies au Gate 0 sont des changements preexistants hors lot.

## 2. Gate 0

Commandes executees depuis la racine avant les modifications documentaires V1-82 :

```text
pwd
/Users/karim/Project/pokemonProject

git branch --show-current
main

git status --short --untracked-files=all
 M packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart
 M packages/map_core/test/cinematic_authoring_operations_test.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
 M packages/map_editor/lib/src/ui/editor_shell_page.dart
 M packages/map_editor/test/cinematic_builder_workspace_test.dart
 M packages/map_editor/test/cinematics_library_workspace_test.dart

git diff --stat
 .../authoring/cinematic_authoring_operations.dart  |  94 ++++++++
 .../test/cinematic_authoring_operations_test.dart  | 179 +++++++++++++-
 .../cinematics/cinematic_builder_workspace.dart    | 258 ++++++++++++++++++---
 .../cinematics/cinematics_library_workspace.dart   |  17 ++
 .../src/ui/canvas/narrative_workspace_canvas.dart  |  52 +++++
 .../map_editor/lib/src/ui/editor_shell_page.dart   |   1 +
 .../test/cinematic_builder_workspace_test.dart     | 204 +++++++++++++++-
 .../test/cinematics_library_workspace_test.dart    |  30 +++
 8 files changed, 797 insertions(+), 38 deletions(-)

git diff --name-only
packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart
packages/map_core/test/cinematic_authoring_operations_test.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/lib/src/ui/editor_shell_page.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
packages/map_editor/test/cinematics_library_workspace_test.dart

git log --oneline -n 15
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
fe619092 feat(narrative): add cinematic stage map context editor and diagnostics preview readiness polish v0 (NS-SCENES-V1-73-V1-74)
632e3747 feat(narrative): add cinematic stage map context core model v0 (NS-SCENES-V1-72)
e77212ff feat(narrative): add cinematic stage map context prep contract (NS-SCENES-V1-71)
edf3d1bd feat(narrative): add cinematic timeline duration validation diagnostics polish v0 (NS-SCENES-V1-70)
```

Interpretation : le workspace etait deja sale avant V1-82, avec huit fichiers `packages/` modifies. V1-82 ne doit ni les modifier, ni les restaurer, ni les inclure comme travail du lot.

## 3. Fichiers lus

Instructions et roadmaps :

- `AGENTS.md`
- `agent_rules.md`
- `skills/README.md`
- `skills/dispatching-parallel-agents/SKILL.md`
- `skills/subagent-driven-development/SKILL.md`
- `skills/verification-before-completion/SKILL.md`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_81_cinematic_actor_appearance_readiness_drift_diagnostics_polish_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_81_evidence_pack.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_80_cinematic_character_library_picker_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_79_cinematic_character_library_binding_core_model_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_77_cinematic_stage_map_entity_event_pickers_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_76_cinematic_stage_map_source_catalog_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_75_cinematic_map_entity_event_source_audit_picker_prep_contract.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_72_cinematic_stage_map_context_core_model_v0.md`

Core :

- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/models/map_data.dart`
- `packages/map_core/lib/src/models/map_event_definition.dart`
- `packages/map_core/lib/src/models/map_entity_payloads.dart`
- `packages/map_core/lib/src/models/cinematic_asset.dart`
- `packages/map_core/lib/src/read_models/cinematic_stage_map_source_catalog.dart`
- `packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart`
- `packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart`

Editor :

- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_stage_preview_readiness.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/map_canvas.dart`
- `packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart`
- `packages/map_editor/lib/src/ui/canvas/map_canvas/map_tool_preview.dart`
- `packages/map_editor/lib/src/ui/canvas/map_canvas/surface_layer_static_preview.dart`
- `packages/map_editor/lib/src/ui/canvas/map_canvas/editor_static_shadow_preview_painter.dart`

Runtime consulte uniquement pour l'anti-scope :

- `packages/map_runtime/README.md`
- `packages/map_runtime/lib/map_runtime.dart`
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- `packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart`
- `packages/map_runtime/lib/src/presentation/flame/player_component.dart`
- `packages/map_runtime/lib/src/presentation/flame/overworld_actor_component.dart`

## 4. Sub-agents / passes specialisees

Des sub-agents reels ont ete utilises pour separer les domaines :

- Sub-agent A - Stage Context / Cinematic Builder : `019e990f-ba82-7442-9900-27e62c7216f7`
- Sub-agent B - MapData / ProjectMapEntry / Snapshot : `019e9910-16fd-7781-8372-77f70e0d681b`
- Sub-agent C - Map Editor Rendering : `019e9910-a2e2-7f70-9ee4-d9a475c69248`
- Sub-agent D - Runtime / Flame Anti-scope : `019e9911-26fd-7500-9be6-58e55c894cca`
- Sub-agent E - Product / UX / Roadmap Reviewer : `019e9911-ab7e-76c3-87fe-06ed2a1923ae`

Chaque agent a produit des constats, risques, recommandations et non-objectifs. L'orchestrateur final a lu les conclusions, arbitre les divergences et ecrit ce rapport ainsi que les roadmaps.

## 5. Synthese des sub-agents et arbitrages

Sub-agent A - conclusion : `CinematicAsset.mapId` est l'ancre map unique. `stageContext.backdropMode` existe et ne porte pas de `mapId`. Le Builder affiche encore `Apercu sandbox` et la readiness Stage/Appearance. La future preview doit respecter `none/projectMap` et rester read-only.

Sub-agent B - conclusion : `ProjectManifest.maps` donne `ProjectMapEntry`, pas `MapData`. La chaine fiable est `CinematicAsset.mapId -> ProjectManifest.maps -> ProjectMapEntry.relativePath -> ProjectWorkspace.resolveMapPath -> MapRepository.loadMap -> MapData`. `EditorNotifier.loadMapSnapshotById` est deja la lecture non destructive utile, mais son erreur se reduit aujourd'hui a `null`.

Sub-agent C - conclusion : `MapCanvas` et `MapGridPainter` savent rendre beaucoup de choses, mais embarquent trop d'etat d'edition, de providers, de previews et d'interactions pour etre reutilises tels quels dans le Builder. Des primitives inspirees du Map Editor peuvent etre reprises plus tard, mais le Builder a besoin d'un renderer dedie et borne.

Sub-agent D - conclusion : le runtime Flame, `PlayableMapGame`, `RuntimeMapGame`, `MapLayersComponent`, `PlayerComponent`, `OverworldActorComponent` et `SceneCinematicRuntimeAwaitableAdapter` sont hors scope V0 editor. Les importer dans le Builder serait du runtime deguise.

Sub-agent E - conclusion : cote produit, il faut eviter une fausse preview. E proposait d'aller vers une preview V0, mais l'audit B/C montre qu'un read model doit preceder le renderer pour garder le contrat testable.

Divergences identifiees : E pousse la trajectoire produit vers une preview visible rapide ; C alerte contre la reutilisation directe du canvas map ; B alerte contre une lecture de map trop implicite ; D interdit le runtime. L'arbitrage final retient le chemin le plus conservateur : read model d'abord, renderer ensuite.

Option retenue : Option E hybride, avec V1-83 limite au read model `CinematicMapBackdropPreviewModel`, puis V1-84 pour un renderer Flutter read-only sandbox si V1-83 est propre.

## 6. Pourquoi ce lot existe maintenant

V1-72 a cree le Stage Context core. V1-73/V1-74 l'ont expose et diagnostique. V1-75/V1-76/V1-77 ont securise les sources `MapData.entities` et `MapData.events`. V1-78/V1-79/V1-80/V1-81 ont securise les apparences Character Library.

Le Builder peut maintenant exprimer : une map de scene, un mode de decor, des actors, des bindings map-aware, des targets et des apparences. Il ne sait pas encore afficher le decor de map. V1-82 ferme donc le contrat avant d'afficher quoi que ce soit.

## 7. Pourquoi ce lot est documentaire

Coder une preview maintenant risquerait de :

- charger la map au mauvais niveau ;
- reutiliser un canvas d'edition trop large ;
- embarquer un runtime Flame ;
- activer du playback ;
- creer une preview qui ressemble a une vraie execution mais ne l'est pas.

Le lot est donc limite a un rapport et aux roadmaps. Aucun test Dart/Flutter n'est requis pour un contrat documentaire ; la preuve attendue est l'audit, l'arbitrage, les checks Git et les anti-scope.

## 8. Etat actuel apres V1-81

Etat confirme :

- Stage Context authorable : oui.
- Map picker : oui, via `ProjectManifest.maps`.
- `backdropMode none/projectMap` : oui.
- Snapshot `MapData` non destructive pour source catalog : oui.
- Pickers `mapEntity` / `mapEvent` reels : oui.
- Picker Character Library : oui.
- Readiness stage/appearance : oui.
- Drift diagnostics appearance : oui.

Toujours absent :

- decor de map affiche ;
- source de rendu backdrop cadree en code ;
- viewport/camera preview ;
- actor display preview ;
- playback local ;
- transport fonctionnel ;
- runtime cinematic visuel.

## 9. Pass A - Audit Stage Context / mapId / backdropMode actuel

Constats :

- `CinematicAsset.mapId` est un champ top-level optionnel et trimme.
- `CinematicStageContext` contient `backdropMode`, `actorBindings`, `actorAppearanceBindings`, `initialPlacements` et `movementTargetBindings`.
- Il n'existe pas de `stageContext.mapId`, et il ne faut pas en ajouter.
- `CinematicStageBackdropMode` contient `none` et `projectMap`.
- `cinematic_diagnostics.dart` signale deja une map stage inconnue et le cas `projectMap` sans map stage.
- Le Builder affiche encore `_PreviewSandbox`, avec `Apercu sandbox` et `Preview reelle a venir`.

Risques :

- dupliquer `mapId` dans `stageContext` ;
- faire de `backdropMode.projectMap` une preview runtime implicite ;
- rendre la readiness bloquante pour des drafts qui veulent volontairement `none`.

Recommandation :

- garder `CinematicAsset.mapId` comme ancre unique ;
- interpreter `backdropMode.none` comme decor volontairement desactive ;
- interpreter `projectMap` comme demande de preview si map et `MapData` sont disponibles ;
- laisser le Builder read-only pour la zone preview tant que V1-83/V1-84 ne sont pas codes.

## 10. Pass B - Audit MapData et source snapshot editor

Constats :

- `ProjectManifest.maps` est une liste de `ProjectMapEntry`.
- `ProjectMapEntry.relativePath` est la source disque fiable.
- `MapData` porte `id`, `name`, `size`, `tilesetId`, `layers`, `placedElements`, `entities`, `events`, `warps`, `triggers`, `gameplayZones`.
- `EditorNotifier.loadMapSnapshotById(mapId)` retourne `activeMap` si c'est la bonne map, sinon lit via `ProjectMapEntry.relativePath` sans changer la map active.
- `buildCinematicStageMapSourceCatalog` consomme deja `ProjectMapEntry? stageMap` et `MapData? mapData` pour produire `missingStageMap`, `mapDataUnavailable`, `mapIdMismatch` ou `available`.

Risques :

- core ne doit jamais lire le disque ;
- le Builder ne doit pas lancer une lecture asynchrone dans un build ;
- `loadMapSnapshotById` ecrase les erreurs en `null`, ce qui demandera des diagnostics plus precis en V1-83 ;
- le catalogue V1-76 peut devenir stale si la map change sans regeneration.

Recommandation :

- reutiliser le meme chemin que V1-77 : snapshot editor non destructive, puis projection pure ;
- V1-83 doit accepter une `MapData?` deja chargee, pas la charger ;
- representer explicitement `missingStageMap`, `backdropDisabled`, `mapDataUnavailable`, `mapDataMismatch`, `tilesetUnavailable`, `available`.

## 11. Pass C - Audit Map Editor rendering existant

Constats :

- `MapCanvas` route une experience d'edition complete : selection, pan, zoom, hover, outils, layers, previews, providers, timers et actions `EditorNotifier`.
- `MapGridPainter` rend beaucoup de surface : terrain, path, tiles, placed elements, shadows, collisions, grid, zones, entities, foreground, previews.
- Des primitives isolees existent ou peuvent inspirer le futur rendu : `MapToolPreview`, `surface_layer_static_preview`, `editor_static_shadow_preview_painter`, presenters de layers.

Risques :

- instancier le Map Editor canvas dans le Cinematic Builder transformerait la preview en second editeur de map ;
- `MapGridPainter` est trop massif pour devenir une dependance directe non cadree ;
- les overlays d'edition, collisions, triggers et markers peuvent brouiller le role du backdrop.

Recommandation :

- ne pas reutiliser `MapCanvas` tel quel ;
- extraire ou recreer un renderer Flutter read-only dedie a partir d'un read model ;
- V0 doit afficher les layers visuels uniquement, sans collisions/triggers/events/entities par defaut.

## 12. Pass D - Audit runtime/Flame map rendering existant

Constats :

- `map_runtime` expose `RuntimeMapGame` et `PlayableMapGame`, tous deux bases sur Flame.
- `PlayableMapGame` gere input clavier, player, collisions, warps, entity interaction, battles, overlays, camera, game state, hooks Scene et actor components.
- `MapLayersComponent` existe cote runtime, mais appartient au monde Flame et aux bundles runtime.
- `map_editor` ne doit pas prendre de dependance runtime/Flame pour une preview d'authoring.

Risques :

- `PlayableMapGame` embarque gameplay, state et lifecycle ;
- `SceneCinematicRuntimeAwaitableAdapter` appartient a l'execution runtime, pas a l'authoring preview ;
- `GameWidget`, `FlameGame`, `CameraComponent`, `Component`, `PlayerComponent`, `OverworldActorComponent` seraient des signaux de runtime deguise.

Recommandation :

- interdire le runtime pour V1-83/V1-84 editor ;
- garder la future preview en Flutter read-only sandbox ;
- ne pas appeler `playCinematic`, `startPlayback`, `seek`, `Timer`, `Ticker`, `AnimationController`, `currentTimeMs` ou `playbackTimeMs`.

## 13. Pass E - Audit Cinematic Builder preview sandbox actuelle

Constats :

- `_PreviewSandbox` est un placeholder volontaire.
- Les hauteurs de preview/timeline ont ete ajustees avant V1-82 pour respecter les proportions demandees par Karim.
- Les transports restent visuels/desactives.
- La preview affiche un resume de step/probe, pas une execution.

Risques :

- remplacer trop vite le placeholder par une map peut casser les proportions de timeline ;
- le futur backdrop peut etre confondu avec le probe ou un playback ;
- trop d'informations map debug peuvent rendre la zone illisible.

Recommandation :

- V1-83 doit seulement produire un read model consommable ;
- V1-84 peut remplacer progressivement le contenu central du sandbox par un decor statique ;
- timeline, probe et transports restent independants.

## 14. Design Gate - Cinematic Map Backdrop Preview Prep Contract

1. V1-82 prepare le contrat de source, projection, viewport, diagnostics et tests du futur backdrop.
2. La source canonique de map est `CinematicAsset.mapId`.
3. `backdropMode none` signifie que le decor de map est volontairement desactive.
4. `backdropMode projectMap` signifie que le Builder veut afficher la map de scene si elle est resolvable.
5. La `MapData` s'obtient via une snapshot editor non destructive, pas depuis core.
6. Le Builder recoit deja indirectement une snapshot via la Library pour le source catalog V1-77.
7. Oui, `loadMapSnapshotById` peut etre reutilise comme point d'entree editor.
8. Non, le Map Editor canvas ne doit pas etre reutilise tel quel.
9. Non, le runtime Flame ne doit pas etre reutilise.
10. `PlayableMapGame` est trop dangereux car il embarque input, collisions, warps, GameState et gameplay.
11. `SceneCinematicRuntimeAwaitableAdapter` execute une cinematique runtime ; il ne sert pas a une preview decor statique.
12. Oui, un renderer sandbox dedie est necessaire apres read model.
13. Oui, un read model visuel est necessaire avant renderer.
14. V0 renderer devra viser les layers visuels reels, mais V1-82 ne les affiche pas.
15. Non, collisions/triggers/events ne sont pas affiches par defaut en V0.
16. Non, les acteurs ne sont pas affiches en V0 backdrop.
17. Viewport initial recommande : fit-map si raisonnable, sinon centre utile.
18. Zoom initial : calcul derive de la taille map et de la zone preview, clamp lisible.
19. Grande map : afficher une fenetre centree et prevoir reset/fit plus tard.
20. Petite map : centrer avec marge, sans agrandissement agressif.
21. `mapId` absent : status `missingStageMap` ou `backdropDisabled` selon mode.
22. `mapId` inconnu : diagnostic error `mapBackdropStageMapUnknown`.
23. `MapData` indisponible : readiness warning et fallback sandbox.
24. Tileset manquant : diagnostic `mapBackdropTilesetMissing`.
25. Layer/tile invalide : diagnostic `mapBackdropLayerUnsupported`.
26. Timeline et transports disabled restent independants du backdrop.
27. Future actor display preview dependra du backdrop, des actor bindings et Character Library.
28. Future local preview clock dependra d'un contrat separe, apres decor et actors.
29. Il n'y a pas de preview reelle parce que ce lot est un contrat documentaire.
30. Prochain lot exact recommande : `NS-SCENES-V1-83 - Cinematic Map Backdrop Preview Read Model V0`.

## 15. Problemes identifies

- Le Builder a une intention de decor, mais pas de projection backdrop.
- `MapCanvas` existe mais n'est pas un composant read-only simple.
- Le runtime rend la map mais avec trop de gameplay.
- Les erreurs snapshot sont encore peu expressives.
- Les layers visuels a afficher doivent etre separes des overlays debug.
- Le viewport doit etre determine sans lecture runtime/camera Flame.
- L'UI doit conserver les proportions preview/timeline existantes.

## 16. Options techniques comparees

Option A - reutiliser le Map Editor canvas :

- Avantages : rendu coherent, duplication reduite.
- Inconvenients : couplage fort, edition embarquee, interactions non voulues.
- Verdict : rejete tel quel pour V0.

Option B - reutiliser runtime Flame / `PlayableMapGame` :

- Avantages : proche du rendu jeu.
- Inconvenients : runtime premature, GameState, collisions, input, hooks.
- Verdict : rejete pour V0.

Option C - renderer Flutter read-only dedie depuis `MapData` :

- Avantages : sandbox, controlable, testable.
- Inconvenients : risque de duplication de rendu.
- Verdict : acceptable apres un read model.

Option D - read model backdrop + renderer leger :

- Avantages : separation propre data/projection/render.
- Inconvenients : demande un lot de plus.
- Verdict : bon noyau technique.

Option E - hybride :

- Avantages : contrat d'abord, renderer ensuite, reutilisation possible de primitives pures sans couplage massif.
- Inconvenients : preview visible decalee d'un lot.
- Verdict : retenu.

## 17. Option recommandee

Option E est retenue.

Plan recommande :

1. V1-83 : creer un read model pur `CinematicMapBackdropPreviewModel`.
2. V1-84 : brancher un renderer Flutter read-only sandbox depuis ce read model.
3. Plus tard : ajouter actor display preview.
4. Plus tard seulement : ajouter local preview clock et interpolation.

## 18. Contrat recommande Map Backdrop Preview V0

Contrat conceptuel, non implemente en V1-82 :

```text
CinematicMapBackdropPreviewModel
  status: none | missingStageMap | backdropDisabled | mapDataUnavailable | mapDataMismatch | tilesetUnavailable | available
  mapId
  mapLabel
  mapRelativePath
  mapDataId
  sizeSummary
  viewportRecommendation
  layers
  diagnostics

CinematicMapBackdropLayerPreview
  id
  label
  kind
  visible
  opacity
  renderRefs

CinematicMapBackdropViewportRecommendation
  mode: fitMap | centerMap | centerActor | centerTarget
  zoom
  center
  reason
```

Le read model ne lit pas le disque. Il consomme des objets deja resolus.

## 19. Contrat recommande viewport/camera V0

Recommandation V0 :

- mode par defaut : `fitMap` si la map est de taille raisonnable ;
- fallback : `centerMap` ;
- si une initial placement acteur fiable existe, preparer `centerActor` mais ne pas rendre d'acteur en V0 ;
- si une movement target fiable existe, preparer `centerTarget` ;
- zoom clamp pour eviter une minuscule carte ou une carte gigantesque illisible ;
- pas de camera Flame ;
- pas de pan/zoom interactif obligatoire au premier renderer.

## 20. Contrat recommande diagnostics/readiness

Diagnostics futurs :

```text
mapBackdropDisabled
mapBackdropRequiresStageMap
mapBackdropStageMapUnknown
mapBackdropMapDataUnavailable
mapBackdropMapDataMismatch
mapBackdropTilesetMissing
mapBackdropLayerUnsupported
mapBackdropPreviewUnavailable
```

Severites recommandees :

- `mapBackdropDisabled` : info.
- `mapBackdropRequiresStageMap` : error si `projectMap`.
- `mapBackdropStageMapUnknown` : error.
- `mapBackdropMapDataUnavailable` : warning/readiness.
- `mapBackdropMapDataMismatch` : error.
- `mapBackdropTilesetMissing` : warning ou error selon rendu impossible.
- `mapBackdropLayerUnsupported` : warning.
- `mapBackdropPreviewUnavailable` : info/warning.

## 21. Relation avec Stage Context

Regles a preserver :

- `CinematicAsset.mapId` reste l'ancre unique.
- `stageContext.backdropMode` pilote seulement l'intention de decor.
- aucun `stageContext.mapId`.
- `backdropMode.none` ne doit pas etre interprete comme une erreur.
- `backdropMode.projectMap` sans map valide produit un diagnostic lisible.

## 22. Relation avec actor bindings / Character Library

V1-82 prepare seulement les dependances.

Ordre futur :

1. backdrop map ;
2. actor display statique ;
3. selection de frame/direction ;
4. preview locale horlogee ;
5. interpolation `actorMove`.

Ne pas coder en V1-82 :

- sprite actor ;
- player sprite ;
- `mapEntity` sprite ;
- character sprite ;
- `actorFace` visuel ;
- interpolation `actorMove`.

## 23. Relation avec timeline / duration / transports

La timeline reste la source authoring des blocs et durees. Le backdrop ne doit pas :

- activer Play/Reset/Stop ;
- introduire `currentTimeMs`, `playbackTimeMs` ou `isPlaying` ;
- lier le mouse probe a un runtime ;
- declencher un seek ;
- changer les proportions preview/timeline.

Le backdrop est une image/projection statique jusqu'a nouvel ordre.

## 24. Relation avec runtime

Frontiere runtime :

- pas d'import `package:map_runtime/map_runtime.dart` dans le Builder ;
- pas d'import Flame dans `map_editor` pour cette preview ;
- pas de `GameWidget` ;
- pas de `PlayableMapGame` ;
- pas de `RuntimeMapGame` ;
- pas de `MapLayersComponent` ;
- pas de `SceneCinematicRuntimeAwaitableAdapter` ;
- pas de callback gameplay.

Le runtime reste la cible d'execution reelle, pas l'outil d'authoring V0.

## 25. Tests futurs V1-83

Tests purs recommandes :

- `backdropMode.none` produit `backdropDisabled`.
- `projectMap` sans `mapId` produit `missingStageMap`.
- `mapId` absent du manifest produit `mapBackdropStageMapUnknown`.
- `ProjectMapEntry` present sans `MapData` produit `mapDataUnavailable`.
- `MapData.id` different produit `mapDataMismatch`.
- map disponible produit `available`.
- dimensions map produisent `sizeSummary`.
- layers visuels sont projetes, overlays debug exclus.
- viewport recommendation `fitMap`/`centerMap` est derivee sans runtime.
- diagnostics ont severite et messages humains.

## 26. Tests futurs V1-84

Tests widget/renderer recommandes :

- le Builder affiche un backdrop statique quand read model `available`.
- le Builder garde le placeholder quand status non disponible.
- aucune collision/trigger/event/entity overlay n'est visible par defaut.
- les transports restent desactives.
- la timeline conserve ses proportions.
- le renderer ne modifie pas `ProjectManifest`, `MapData` ou `CinematicAsset`.
- aucun import runtime/Flame n'est ajoute.
- Visual Gate seulement pour V1-84, pas V1-82.

## 27. Non-objectifs confirmes

V1-82 ne fait pas :

- code Dart produit ;
- widget Flutter ;
- modification `map_core`, `map_editor`, `map_runtime`, `map_gameplay`, `map_battle`, `examples` ;
- test Dart/Flutter ;
- screenshot ;
- Visual Gate ;
- build_runner ;
- map affichee ;
- preview reelle ;
- actor rendering ;
- sprite rendering ;
- playback ;
- timer ;
- `Ticker` ;
- `AnimationController` ;
- `currentTimeMs` ;
- `playbackTimeMs` ;
- `isPlaying` ;
- seek runtime ;
- scrubber runtime ;
- pathfinding ;
- collision ;
- warp ;
- spawn runtime ;
- mutation `GameState` ;
- donnee Selbrume ;
- image IA.

## 28. Roadmap post V1-82

Roadmaps mises a jour :

- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

V1-82 est marque DONE parce que le rapport existe, les sub-agents/passes sont documentes, les options sont tranchees et le prochain lot est clair.

Prochain lot exact recommande :

```text
NS-SCENES-V1-83 - Cinematic Map Backdrop Preview Read Model V0
```

Objectif V1-83 : creer le read model pur du backdrop preview depuis Stage Context + `ProjectMapEntry` + `MapData`, avec statuts, labels, dimensions, layers visuels, diagnostics et recommandations viewport, sans rendre la map en UI.

## 29. Commandes executees

Commandes d'audit executees :

```text
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git log --oneline -n 15
sed -n ... prompt V1-82
sed -n ... roadmaps et rapports V1-72/V1-75/V1-76/V1-77/V1-79/V1-80/V1-81
sed -n ... fichiers core/editor/runtime audites
rg -n "class .*Map.*Canvas|MapCanvas|MapEditor|MapPreview|TileLayer|TileRenderer|tileset|Tileset|Tiled|map render|renderMap|paintMap|CustomPainter|Flame|SpriteBatch|SpriteComponent" packages/map_editor packages/map_core packages/map_runtime
rg -n "loadMapSnapshotById|buildCinematicStageMapSourceCatalog|MapData|ProjectMapEntry|relativePath" packages/map_editor packages/map_core
rg -n "PlayableMapGame|MapRuntime|TiledComponent|WorldComponent|CameraComponent|FlameGame|GameWidget|Component" packages/map_runtime packages/map_editor
rg -n "cinematic.*preview|Apercu sandbox|backdropMode|projectMap|stageMap|Preview" packages/map_editor/lib/src/ui/canvas/cinematics packages/map_core/lib/src
```

Validation finale executee apres creation du rapport et mise a jour des roadmaps : voir sections 30 et 31.

## 30. Checks anti-scope

Les checks anti-scope finaux sont reproduits dans l'Evidence Pack. Interpretation attendue :

- les occurrences runtime/image/Selbrume dans les fichiers Markdown sont autorisees uniquement comme interdictions, analyses ou non-objectifs ;
- les fichiers `packages/` modifies sont preexistants au Gate 0 et ne sont pas du travail V1-82 ;
- aucune nouvelle implementation `CinematicMapBackdropPreview` n'a ete ajoutee dans les packages par V1-82.

## 31. Evidence Pack

### 31.1 Diff des roadmaps

```diff
diff --git a/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md b/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
index ebcf503f..b0a43f8e 100644
--- a/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
+++ b/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
@@ -9,7 +9,7 @@ Le runtime reste indispensable, mais le prochain blocage produit est plus basiqu
 ## Prochain lot exact recommande

 ```text
-NS-SCENES-V1-82 — Cinematic Map Backdrop Preview Prep Contract
+NS-SCENES-V1-83 — Cinematic Map Backdrop Preview Read Model V0
 ```

 ## Principes
@@ -115,8 +115,24 @@ NS-SCENES-V1-82 — Cinematic Map Backdrop Preview Prep Contract
 | NS-SCENES-V1-79 | Cinematic Character Library Binding Core Model V0 | core / authoring | Implémenter le modèle authoring minimal permettant de lier un actor `cinematicOnly` à un personnage de la Character Library, avec JSON backward-compatible, opérations pures et diagnostics. | Pas d'UI picker, pas de preview réelle, pas de runtime, pas de playback, pas de pathfinding, pas d'override player/mapEntity en V0, pas de donnée Selbrume. | `cinematic_asset.dart`, authoring operations, diagnostics cinematic, tests JSON/operations/diagnostics, rapport. | DONE : `CinematicActorAppearanceBinding` separe, `stageContext.actorAppearanceBindings`, validation actor/character, diagnostics refs cassees, JSON backward-compatible, tests/analyze core verts. | Trop alourdir `CinematicActorBinding` ; autoriser les overrides visuels trop tôt ; casser les anciens JSON. | DONE : modèle minimal stable avant le picker Character Library, sans UI ni preview reelle. | V1-78. |
 | NS-SCENES-V1-80 | Cinematic Character Library Picker V0 | editor / authoring | Exposer dans le Cinematic Builder un picker no-code pour choisir un `ProjectCharacterEntry` pour un acteur `cinematicOnly`, en consommant `actorAppearanceBindings` V1-79. | Pas de preview reelle, pas de runtime, pas de playback, pas de pathfinding, pas d'override player/mapEntity/unbound en V0, pas de donnee Selbrume. | Builder cinematics, readiness editor, tests widget, rapport, screenshot. | DONE : picker Character Library lisible, selection/clear explicites, empty/broken states, labels no-code, diagnostics Character Library visibles, aucun ID brut comme workflow principal. | Brancher une fausse preview ; melanger acteur et apparence ; exposer `characterId` comme saisie libre. | DONE : premier pont editor entre acteur cinematic-only et Character Library, sans preview reelle ni runtime. | V1-79. |
 | NS-SCENES-V1-81 | Cinematic Actor Appearance Readiness / Drift Diagnostics Polish V0 | editor / ui-polish | Polir les diagnostics apparence/stage apres V1-80 : refs cassees, changement de kind apres selection, assets Character Library incomplets et messages readiness. | Pas de preview reelle, runtime, playback, pathfinding, override player/mapEntity/unbound, mutation Character Library ou nouveau modele core. | Builder/Library cinematics, readiness editor, tests widget, rapport, screenshot si UI. | DONE : drift apparence lisible, actions de nettoyage explicites, readiness precise, summary Library et Visual Gate. | Masquer une reference cassee ; supprimer automatiquement une ref ; faire croire a une preview reelle. | DONE : diagnostic polish apres picker, sans elargir le pouvoir runtime/editor. | V1-80. |
+| NS-SCENES-V1-82 | Cinematic Map Backdrop Preview Prep Contract | doc-only / architecture-review | Cadrer la future preview de decor map du Cinematic Builder avant toute implementation visuelle : source MapData, renderer autorise, viewport/camera, diagnostics, anti-runtime, tests futurs. | Pas de code produit, pas de package, pas de widget, pas de test, pas de screenshot, pas de map affichee, pas de preview reelle, runtime, playback, pathfinding, collision, image IA ou donnees Selbrume. | Rapport V1-82, roadmaps. | DONE : sub-agents/passes A-E, arbitrage final, Option E retenue, contrat backdrop/viewport/readiness/tests futurs, checks anti-scope documentaires. | Coder la preview trop tot ; reutiliser PlayableMapGame ; coupler MapCanvas massif ; vendre une fausse preview. | DONE : contrat pret pour V1-83 read model, sans modifier les packages par V1-82. | V1-81. |
+| NS-SCENES-V1-83 | Cinematic Map Backdrop Preview Read Model V0 | core / read-model | Creer un read model pur du backdrop preview depuis Stage Context + `ProjectMapEntry` + `MapData` : statuts, labels, dimensions, layers visuels, diagnostics, viewport recommendation. | Pas de renderer UI, pas de map affichee, pas de runtime/Flame, pas de playback, pas d'acteurs rendus, pas de pathfinding/collision. | Futur read model map_core ou editor selon arbitrage final V1-82, tests purs, rapport. | TODO : RED/GREEN sur statuts none/missing/unavailable/mismatch/available, layers visuels, diagnostics, viewport recommendation. | Confondre read model et renderer ; charger le disque depuis core ; ignorer les erreurs snapshot. | TODO : contrat V1-82 materialise en projection testable, sans rendu. | V1-82. |
 | NS-SCENES-V1-90 | Cinematic Timeline Scroll / Visibility Polish V0 | editor / ui-polish | Backlog futur : polir la visibilite des blocs/repere/selection quand les interactions clavier ou souris placent l'element cible hors de la vue utile. | Pas de playback, seek runtime, scrubber runtime, transport fonctionnel, drag/resize/reorder, mutation JSON, runtime, zoom temporel ou changement de modele. | Builder cinematics, tests widget, rapport, screenshot. | TODO : scroll automatique/visibilite controles, proportions timeline preservees, selection/probe non mutants. | Casser les proportions visees ; confondre scroll de vue et navigation temporelle ; ajouter un pouvoir de montage. | TODO : visibilite plus fiable, sans nouveau pouvoir temporel. | Backlog post Character Library. |

+## Mise a jour V1-82
+
+Statut : `NS-SCENES-V1-82 — Cinematic Map Backdrop Preview Prep Contract` est DONE.
+
+Demande : Karim a relance le lot apres l'oubli du rapport. Le scope etait strictement documentaire avec sub-agents / passes specialisees obligatoires, aucun code produit, aucun package, aucun test, aucune preview reelle.
+
+Decision : Option E retenue. Le Builder doit d'abord consommer un contrat/read model backdrop preview avant tout rendu. La source canonique reste `CinematicAsset.mapId` + `ProjectManifest.maps` + `ProjectMapEntry.relativePath` + `MapData` chargee par le niveau editor. `stageContext.backdropMode.none` signifie decor volontairement desactive ; `projectMap` demande une preview seulement si mapId, ProjectMapEntry et MapData sont disponibles et alignes.
+
+Scope realise : audit Stage Context/mapId/backdropMode, audit MapData snapshot, audit Map Editor rendering, audit runtime/Flame anti-scope, audit Product/UX, synthese des sub-agents et arbitrages, options A-E comparees, contrat conceptuel `CinematicMapBackdropPreviewModel`, viewport/camera, diagnostics futurs, tests futurs V1-83/V1-84 et Evidence Pack.
+
+Limites : V1-82 n'affiche pas la map, ne code pas de renderer, ne reutilise pas `PlayableMapGame`, ne modifie pas runtime/Flame, ne lance pas de playback, ne rend pas les acteurs et ne hardcode aucune donnee Selbrume. Les fichiers `packages/` modifies au Gate 0 sont preexistants hors V1-82.
+
+Prochain lot exact recommande : `NS-SCENES-V1-83 — Cinematic Map Backdrop Preview Read Model V0`.
+
 ## Mise a jour V1-81

 Statut : `NS-SCENES-V1-81 — Cinematic Actor Appearance Readiness / Drift Diagnostics Polish V0` est DONE.
diff --git a/reports/narrativeStudio/scenes/road_map_scenes.md b/reports/narrativeStudio/scenes/road_map_scenes.md
index 0c83b0e2..08e375db 100644
--- a/reports/narrativeStudio/scenes/road_map_scenes.md
+++ b/reports/narrativeStudio/scenes/road_map_scenes.md
@@ -136,15 +136,16 @@ Ces briques sont utiles, mais elles ne constituent pas encore une Scene V1 propr
 | NS-SCENES-V1-79 — Cinematic Character Library Binding Core Model V0 | DONE | Modele core `CinematicActorAppearanceBinding` ajoute dans `stageContext.actorAppearanceBindings`, JSON backward-compatible, operations pures upsert/remove, diagnostics actor/character binding, limite `cinematicOnly` V0, tests/analyze core verts, sans UI picker, preview réelle, runtime, pathfinding ni donnée Selbrume. |
 | NS-SCENES-V1-80 — Cinematic Character Library Picker V0 | DONE | Picker no-code Character Library expose dans le Cinematic Builder pour les acteurs `cinematicOnly` : selection/clear de `ProjectCharacterEntry`, empty/broken states, messages herites player/mapEntity/unbound, readiness apparences et Visual Gate, sans preview reelle, runtime, playback, pathfinding, override player/mapEntity/unbound ou saisie libre de `characterId`. |
 | NS-SCENES-V1-81 — Cinematic Actor Appearance Readiness / Drift Diagnostics Polish V0 | DONE | Diagnostics apparence Character Library humanises apres V1-80 : ref character cassee, actor kind incompatible, actor supprime/orphelin, Character Library vide, character incomplet, actions de correction explicites, readiness `Apparences acteurs`, summary Library et Visual Gate, sans preview reelle, runtime, playback, pathfinding, mutation Character Library ni donnee Selbrume. |
+| NS-SCENES-V1-82 — Cinematic Map Backdrop Preview Prep Contract | DONE | Rapport documentaire avec sub-agents/passes specialisees : audit Stage Context/mapId/backdropMode, MapData snapshot, rendu Map Editor, anti-scope runtime/Flame, options comparees, Option E retenue, contrat backdrop preview, viewport/camera, diagnostics et tests futurs cadres, sans map affichee, preview reelle, runtime, playback, pathfinding, donnees Selbrume ni modification package V1-82. |
 | NS-SCENES-V1-90 — Cinematic Timeline Scroll / Visibility Polish V0 | TODO | Backlog futur déplacé depuis V1-80 : polir le scroll automatique et la visibilite des blocs/selection/probe apres le cadrage Character Library, en preservant les proportions de timeline demandees par Karim. |

 ## Prochain lot recommande

-`NS-SCENES-V1-82 — Cinematic Map Backdrop Preview Prep Contract`
+`NS-SCENES-V1-83 — Cinematic Map Backdrop Preview Read Model V0`

-Raison : V1-81 ferme le polish des diagnostics d'apparence Character Library sans brancher de preview reelle. Le prochain verrou produit recommande est de cadrer la future preview map backdrop : source de rendu, camera/viewport, limites sandbox et refus explicite de runtime/playback premature.
+Raison : V1-82 ferme le contrat documentaire de preview backdrop sans afficher de map. Le prochain verrou recommande est un read model pur `CinematicMapBackdropPreviewModel` depuis Stage Context + `ProjectMapEntry` + `MapData`, avec statuts, labels, dimensions, layers visuels, diagnostics et recommandations viewport, sans encore rendre la map en UI.

-Ordre apres V1-81 : `NS-SCENES-V1-82 — Cinematic Map Backdrop Preview Prep Contract`.
+Ordre apres V1-82 : `NS-SCENES-V1-83 — Cinematic Map Backdrop Preview Read Model V0`.

 Le lot `NS-SCENES-V1-78 — Cinematic Stage Source Drift Diagnostics Polish V0` précédemment recommandé est repoussé après la séquence Character Library Binding. Il reste pertinent, mais il ne doit plus occuper V1-78.

@@ -152,6 +153,20 @@ Le lot `NS-SCENES-V1-67 — Cinematic Timeline Scroll / Visibility Polish V0` pr

 Note : l'overview n'affiche plus `Facts — necessite un modele`; Facts et Regles du monde pointent maintenant vers des workspaces actifs.

+## Mise a jour V1-82
+
+Statut : `NS-SCENES-V1-82 — Cinematic Map Backdrop Preview Prep Contract` est DONE.
+
+Demande : lot documentaire relance a la demande de Karim apres constat que le rapport V1-82 manquait. Le prompt imposait un rapport unique, des sub-agents ou passes specialisees, Gate 0, audit Stage Context, MapData snapshot, rendu Map Editor, runtime/Flame anti-scope, options comparees, contrat backdrop/viewport/diagnostics/tests futurs et mise a jour des roadmaps.
+
+Decision : Option E retenue. V1-82 definit comment afficher le decor de map plus tard, mais ne l'affiche pas encore. La suite recommandee commence par un read model pur `CinematicMapBackdropPreviewModel` avant tout renderer : source canonique `CinematicAsset.mapId -> ProjectManifest.maps -> ProjectMapEntry.relativePath -> MapData`, `stageContext.backdropMode` pilote l'intention `none/projectMap`, et le Builder reste consommateur de snapshot/catalogue fourni par le niveau editor.
+
+Scope realise : rapport V1-82 en francais, cinq sub-agents/passes documentees, arbitrage final, options A-E comparees, rejet runtime/Flame/PlayableMapGame, prudence sur MapCanvas/MapGridPainter, contrat conceptuel backdrop preview, viewport/camera, diagnostics futurs, tests futurs V1-83/V1-84 et evidence pack documentaire.
+
+Limites confirmees : aucun code produit V1-82, aucun package modifie par V1-82, aucun test lance, aucune map affichee, aucune preview reelle, aucun runtime, playback, timer, `Ticker`, `AnimationController`, `currentTimeMs`, `playbackTimeMs`, pathfinding, collision, warp, spawn runtime, image IA ou donnee Selbrume. Les modifications `packages/` visibles au Gate 0 sont preexistantes hors V1-82 et ne sont pas incluses dans ce lot.
+
+Prochain lot exact recommande : `NS-SCENES-V1-83 — Cinematic Map Backdrop Preview Read Model V0`.
+
 ## Mise a jour V1-81

 Statut : `NS-SCENES-V1-81 — Cinematic Actor Appearance Readiness / Drift Diagnostics Polish V0` est DONE.
```

### 31.2 Validation finale

`git diff --check`

```text
<vide>
```

`git diff --stat`

```text
 .../authoring/cinematic_authoring_operations.dart  |  94 ++++++++
 .../test/cinematic_authoring_operations_test.dart  | 179 +++++++++++++-
 .../cinematics/cinematic_builder_workspace.dart    | 258 ++++++++++++++++++---
 .../cinematics/cinematics_library_workspace.dart   |  17 ++
 .../src/ui/canvas/narrative_workspace_canvas.dart  |  52 +++++
 .../map_editor/lib/src/ui/editor_shell_page.dart   |   1 +
 .../test/cinematic_builder_workspace_test.dart     | 204 +++++++++++++++-
 .../test/cinematics_library_workspace_test.dart    |  30 +++
 .../scenes/road_map_scene_builder_authoring.md     |  18 +-
 reports/narrativeStudio/scenes/road_map_scenes.md  |  21 +-
 10 files changed, 832 insertions(+), 42 deletions(-)
```

`git diff --name-only`

```text
packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart
packages/map_core/test/cinematic_authoring_operations_test.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/lib/src/ui/editor_shell_page.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
packages/map_editor/test/cinematics_library_workspace_test.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

`git status --short --untracked-files=all`

```text
 M packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart
 M packages/map_core/test/cinematic_authoring_operations_test.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
 M packages/map_editor/lib/src/ui/editor_shell_page.dart
 M packages/map_editor/test/cinematic_builder_workspace_test.dart
 M packages/map_editor/test/cinematics_library_workspace_test.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_82_cinematic_map_backdrop_preview_prep_contract.md
```

Interpretation : le rapport est un fichier non suivi, donc il apparait dans `git status` mais pas dans `git diff --stat` ni `git diff --name-only`. Les huit fichiers `packages/` etaient deja presents au Gate 0 et restent hors V1-82.

`git diff --name-only -- packages`

```text
packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart
packages/map_core/test/cinematic_authoring_operations_test.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/lib/src/ui/editor_shell_page.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
packages/map_editor/test/cinematics_library_workspace_test.dart
```

Interpretation : sortie non vide uniquement a cause des changements package preexistants au Gate 0. V1-82 n'a pas ajoute de fichier package.

`rg -n "CinematicMapBackdropPreview|MapBackdropPreview|BackdropPreviewModel|BackdropRenderer|renderBackdrop|mapBackdropPreview" packages/map_core packages/map_editor packages/map_runtime || true`

```text
<vide>
```

Interpretation : aucune implementation backdrop preview n'existe dans les packages apres V1-82.

`rg -n "gpt-image-2|image_generation|generate image|AI image|image model" reports/narrativeStudio/scenes/ns_scenes_v1_82_cinematic_map_backdrop_preview_prep_contract.md reports/narrativeStudio/scenes/road_map_scenes.md reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md || true`

```text
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md:234:Limites confirmees : preview reelle eteinte, runtime intouché, timeline/duree/resize/probe/transports preserves, aucun ID libre, aucun JSON brut, aucun `stageContext.mapId`, aucune image IA ou `gpt-image-2`.
reports/narrativeStudio/scenes/road_map_scenes.md:182:Limites confirmees : pas de preview reelle, pas de runtime, pas de playback, pas de pathfinding, pas de mutation Character Library, pas de `characterId` dans `CinematicActorBinding` ou `requiredActors`, pas de TextField ID, pas de JSON brut, pas d'image IA ou `gpt-image-2`, pas de donnee Selbrume.
reports/narrativeStudio/scenes/road_map_scenes.md:198:Limites confirmees : pas de preview reelle, pas de runtime, pas de playback, pas de pathfinding, pas d'override `player`/`mapEntity`/`unbound`, pas de modification Character Library, pas de `stageContext.mapId`, pas d'image IA ou `gpt-image-2`.
reports/narrativeStudio/scenes/road_map_scenes.md:328:Limites : aucune preview reelle, aucun runtime, aucun playback, aucun timer, aucune coordonnee libre, aucun JSON brut, aucun `stageContext.mapId`, aucun pathfinding, aucune donnee Selbrume, aucune image IA ou `gpt-image-2`.
```

Interpretation : les seules mentions sont des interdictions ou limites historiques. Aucun outil image IA n'a ete appele pour V1-82.

Les recherches anti-runtime et anti-Selbrume sur les trois fichiers Markdown retournent de nombreuses occurrences historiques dans les roadmaps. Les occurrences propres a V1-82 sont des interdictions et analyses d'anti-scope, par exemple `PlayableMapGame`, `SceneCinematicRuntimeAwaitableAdapter`, `Ticker`, `AnimationController`, `currentTimeMs`, `playbackTimeMs` et `donnee Selbrume` apparaissent uniquement pour refuser ces ajouts.

## 32. Auto-review critique

1. Est-ce que V1-82 a modifie du code produit ? Non, seulement rapport et roadmaps.
2. Est-ce que V1-82 a modifie un package ? Non volontairement ; les packages modifies etaient deja presents au Gate 0.
3. Est-ce que V1-82 a modifie un test ? Non.
4. Est-ce que V1-82 a affiche une map ? Non.
5. Est-ce que V1-82 a ajoute une preview reelle ? Non.
6. Est-ce que V1-82 a modifie le runtime ? Non.
7. Est-ce que V1-82 a ajoute du playback ? Non.
8. Est-ce que V1-82 a ajoute `currentTimeMs` / `playbackTimeMs` / `isPlaying` ? Non.
9. Est-ce que V1-82 a ajoute pathfinding/collision/warp/spawn runtime ? Non.
10. Est-ce que V1-82 a ajoute des donnees Selbrume ? Non.
11. Est-ce que Stage Context a ete audite ? Oui.
12. Est-ce que MapData snapshot a ete audite ? Oui.
13. Est-ce que Map Editor rendering a ete audite ? Oui.
14. Est-ce que runtime/Flame rendering a ete audite ? Oui, uniquement pour anti-scope.
15. Est-ce que les sub-agents/passes specialisees sont documentes ? Oui.
16. Est-ce que les divergences entre sub-agents sont arbitrees ? Oui.
17. Est-ce que les options techniques sont comparees ? Oui.
18. Est-ce que l'option recommandee est claire ? Oui, Option E.
19. Est-ce que le contrat backdrop preview est defini ? Oui, conceptuellement.
20. Est-ce que le contrat viewport/camera est defini ? Oui.
21. Est-ce que les diagnostics futurs sont listes ? Oui.
22. Est-ce que les tests futurs sont listes ? Oui, V1-83 et V1-84.
23. Est-ce que le prochain lot exact est recommande ? Oui, V1-83 read model.
24. Est-ce que l'Evidence Pack est complet sans placeholders ? Oui pour les validations finales utiles au lot ; les sorties massives de recherches historiques sont interpretees au lieu d'etre transformees en dump illisible.

Critique : le seul point faible est structurel : le workspace etait deja sale dans `packages/` au Gate 0. V1-82 doit donc etre juge sur ses fichiers documentaires, pas sur un diff package preexistant.

## 33. Verdict final

V1-82 ferme le contrat documentaire de preview backdrop, sans afficher de map ni coder de runtime. Le prochain lot doit etre `NS-SCENES-V1-83 - Cinematic Map Backdrop Preview Read Model V0`.
