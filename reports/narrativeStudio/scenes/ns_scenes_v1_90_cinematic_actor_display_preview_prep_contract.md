# NS-SCENES-V1-90 — Cinematic Actor Display Preview Prep Contract

## 1. Résumé exécutif

Statut : `DONE` documentaire.

Phrase canonique :

```text
V1-90 prépare l'affichage statique des acteurs.
V1-90 ne rend toujours aucun acteur.
```

V1-90 cadre le futur affichage statique des acteurs dans la preview sandbox du Cinematic Builder, maintenant que V1-89 affiche un decor map reel via tilesets resolus par le workspace editor.

Decision principale : retenir l'Option C, c'est-a-dire un read model pur pour l'actor display, puis un resolver editor pour les assets/sprites et seulement ensuite un renderer overlay. Le prochain lot exact recommande est :

```text
NS-SCENES-V1-91 — Cinematic Actor Display Preview Read Model V0
```

Aucun code produit n'a ete modifie pour V1-90. Aucun acteur, sprite, placeholder acteur, runtime, Flame, playback, pathfinding ou collision n'a ete ajoute.

## 2. Gate 0

Commande :

```bash
pwd
```

Sortie :

```text
/Users/karim/Project/pokemonProject
```

Commande :

```bash
git branch --show-current
```

Sortie :

```text
main
```

Commande :

```bash
git status --short --untracked-files=all
```

Sortie :

```text
```

Commande :

```bash
git diff --stat
```

Sortie :

```text
```

Commande :

```bash
git diff --name-only
```

Sortie :

```text
```

Commande :

```bash
git log --oneline -n 15
```

Sortie :

```text
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
1b311e81 feat(narrative): update cinematic workspace and add test failure assets (NS-SCENES-V1-29-81)
122fe0c7 feat(narrative): update cinematic builder workspace (NS-SCENES-V1-81-BIS)
747aa6e6 feat(narrative): add cinematic builder workspace updates and test failure assets (NS-SCENES-V1-35)
```

Interpretation : le working tree etait propre avant V1-90. Le lot V1-89 apparait dans l'historique comme auto-commit avant ce lot.

## 3. Fichiers lus

Instructions et contexte :

- `AGENTS.md`
- `agent_rules.md`
- `skills/README.md`
- `skills/using-superpowers/SKILL.md`
- `skills/writing-plans/SKILL.md`
- `skills/dispatching-parallel-agents/SKILL.md`
- `skills/verification-before-completion/SKILL.md`

Roadmaps et rapports :

- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_89_cinematic_map_backdrop_real_tile_renderer_integration_fidelity_polish_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_89_evidence_pack.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_88_cinematic_map_backdrop_real_tile_renderer_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_81_cinematic_actor_appearance_readiness_drift_diagnostics_polish_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_80_cinematic_character_library_picker_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_79_cinematic_character_library_binding_core_model_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_77_cinematic_stage_map_entity_event_pickers_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_76_cinematic_stage_map_source_catalog_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_72_cinematic_stage_map_context_core_model_v0.md`

Audit core :

- `packages/map_core/lib/src/models/cinematic_asset.dart`
- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/models/map_data.dart`
- `packages/map_core/lib/src/models/map_entity_payloads.dart`
- `packages/map_core/lib/src/models/map_event_definition.dart`
- `packages/map_core/lib/src/read_models/cinematic_stage_map_source_catalog.dart`
- `packages/map_core/lib/src/read_models/cinematic_map_backdrop_preview_model.dart`
- `packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart`
- `packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart`

Audit editor :

- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_tile_renderer.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_tile_render_plan.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_tile_plan_loader.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_stage_preview_readiness.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`
- `packages/map_editor/lib/src/ui/panels/character_library_panel.dart`
- `packages/map_editor/test/cinematic_builder_workspace_test.dart`
- `packages/map_editor/test/cinematics_library_workspace_test.dart`

Audit anti-scope runtime :

- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- `packages/map_runtime/lib/src/presentation/flame/runtime_map_game.dart`
- `packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart`
- `packages/map_runtime/lib/src/presentation/flame/player_component.dart`
- `packages/map_runtime/lib/src/presentation/flame/overworld_actor_component.dart`
- `packages/map_runtime/lib/src/application/scene_runtime/scene_cinematic_runtime_awaitable_adapter.dart`
- `packages/map_core/lib/src/models/game_state.dart`

## 4. Synthèse des sub-agents et arbitrages

Sub-agent A — conclusion : l'inventaire fiable des acteurs vient de `CinematicAsset.requiredActors`; le binding fiable vient de `stageContext.actorBindings`; `actorAppearanceBindings`, `initialPlacements` et `movementTargetBindings` sont des couches separees. `unbound` reste non-renderable. `CinematicActorRef.entityId` ne doit pas devenir une source concurrente silencieuse.

Sub-agent B — conclusion : les positions doivent etre resolues en donnees pures, depuis `initialPlacements`, puis `fromMapEntity` ou `fromMovementTarget`. `abstractPoint`, `target_center` et `target_exit` n'ont aucune coordonnee implicite. Il ne faut pas inventer une position au centre de la map.

Sub-agent C — conclusion : l'apparence fiable de `cinematicOnly` passe par `CinematicActorAppearanceBinding -> ProjectCharacterEntry`. Pour `player`, la piste future est `ProjectSettings.defaultPlayerCharacterId`. Pour `mapEntity`, la piste future est `MapEntityNpcData.characterId`, puis `trainer.characterId`; `visualElementId` reste un fallback visuel different d'un personnage. Le mapping `actorFace up/down/left/right` vers `EntityFacing north/south/west/east` doit etre explicite.

Sub-agent D — conclusion : le futur overlay acteur doit partager le meme viewport/fitted rect que le decor V1-89. Il faut factoriser un transform editor-only pur : `mapPixelRect`, `scale`, `mapPixelToPreview`, `mapTileToPreviewRect`, `mapActorAnchorToPreview`. L'ancre acteur recommandee est le centre bas de tuile.

Sub-agent E — conclusion : aucun runtime ne doit etre utilise. `PlayableMapGame`, `RuntimeMapGame`, `GameWidget`, `FlameGame`, `CameraComponent`, `MapLayersComponent`, `PlayerComponent`, `OverworldActorComponent`, `GameState`, `SceneCinematicRuntimeAwaitableAdapter`, pathfinding, collision et interpolation `actorMove` sont hors scope.

Sub-agent F — conclusion : l'utilisateur doit comprendre que la preview future sera statique, pas jouee. Wording recommande : `Plateau de scene (statique)`, `Decor reel et poses initiales`, `Sans lecture`, `Pose initiale`, `Apparence a completer`.

Divergences identifiees :

- Le sub-agent F propose de nommer le lot futur "Renderer V0" si la roadmap garde V1-91 pour le scroll. L'arbitrage roadmap du prompt demande par defaut read model d'abord ; on retient donc V1-91 Read Model et on repousse le scroll en V1-92.
- Les sub-agents A/C signalent des sources runtime utiles pour comprendre les apparences (`resolveDefaultPlayerCharacter`, `resolveNpcCharacterId`), mais l'arbitrage interdit de les importer dans `map_editor`. Ces routines sont des references conceptuelles, pas des dependances.

Arbitrage final : Option C. Read model pur en premier, resolver editor ensuite, renderer overlay seulement apres. Le read model vit idealement dans `map_core` car il manipule des references, statuts et diagnostics, pas des `ui.Image`.

Option retenue : `CinematicActorDisplayPreviewModel` pur, sans rendu acteur dans V1-90.

## 5. Pourquoi V1-90 vient après V1-89

V1-89 a ferme le verrou decor : le Cinematic Builder peut recevoir un plan bitmap depuis une vraie map projet, avec tilesets resolus par le workspace editor et fallback structurel diagnostique.

Avant V1-89, cadrer les acteurs risquait de poser des personnages sur un decor abstrait. Apres V1-89, on peut cadrer la superposition statique des acteurs par-dessus une map reconnue, sans lancer de runtime.

## 6. Objectif produit de l'Actor Display Preview

Objectif : permettre plus tard a l'auteur de voir qui est implique dans la scene et ou chaque acteur commence, sans confondre cette image avec une lecture de la cinematic.

Difference decor map / actor display :

- le decor map est une projection spatiale statique de la map stage ;
- l'actor display est une projection statique des acteurs requis, de leurs bindings, de leurs positions initiales et de leurs apparences authoring ;
- aucun des deux ne doit executer la timeline.

## 7. Pass A — Actor sources / Stage Context

Acteurs affichables en V0 futur :

- `player` : acteur lie au joueur, affichable seulement si position et apparence sont resolues ;
- `mapEntity` : acteur lie a une entite stage bindable, typiquement NPC ;
- `cinematicOnly` : acteur lie a la Character Library via `actorAppearanceBindings` ;
- `unbound` : acteur repertorie mais non affichable, avec diagnostic.

Sources fiables :

- `CinematicAsset.requiredActors` pour l'inventaire ;
- `CinematicStageContext.actorBindings` pour le type de source ;
- `CinematicStageMapSourceCatalog` pour disponibilite map-aware ;
- `MapData.entities` et `MapData.events` pour les coordonnees numeriques ;
- `actorAppearanceBindings` pour les apparences `cinematicOnly`.

Sources non fiables :

- `positionSummary`, car c'est du texte ;
- `CinematicActorRef.entityId`, car ce n'est pas le binding stage V0 ;
- `CinematicMovementTargetRef` seul, car il ne porte pas de coordonnees.

Gestion des doublons : le futur read model doit dedupliquer par `actorId`, garder un ordre stable base sur `requiredActors`, appliquer "first wins" ou "last wins" seulement si le contrat l'ecrit, et produire un diagnostic de duplication.

## 8. Pass B — Position / placement resolution

Priorite de position recommandee :

1. `stageContext.initialPlacements` par `actorId`.
2. `fromMapEntity` : exige un actor binding `mapEntity`, un `mapEntityId`, un catalogue stage disponible et une entite dans `MapData.entities`.
3. `fromMovementTarget` : exige un `targetId`, un `movementTargetBinding`, puis une source map-aware resolue.
4. Placement absent, `unset`, source absente, `abstractPoint` ou map indisponible : position non resolue avec diagnostic.

`player` : position par `initialPlacements`; pas de fallback automatique vers `GameState` ou map spawn.

`mapEntity` : position par `MapEntity.pos` si binding et entite existent.

`cinematicOnly` : position par `initialPlacements`; si `fromMovementTarget`, la cible doit etre resolue.

`unbound` : position status `unbound`, non rendu.

`abstractPoint` : conserve un label logique mais ne donne pas de coordonnee.

Position hors-map : status `outOfMapBounds`, warning ou error selon qu'un placeholder hors-map est autorise. Recommandation V0 : ne pas afficher hors viewport ; lister dans diagnostics.

## 9. Pass C — Appearance / Character Library

Contrat apparence futur :

1. `cinematicOnly` : `CinematicActorAppearanceBinding.characterId -> ProjectManifest.characters`.
2. `player` : `ProjectSettings.defaultPlayerCharacterId -> ProjectCharacterEntry`, si defini.
3. `mapEntity` : `MapEntityNpcData.characterId`, puis `trainer.characterId` si le projet l'expose dans la source disponible.
4. Fallback mapEntity visuel : `editorVisual.elementId` ou `npc.visualElementId`, a marquer comme `placeholderOnly` ou `unsupported`, pas comme sprite personnage.
5. `unbound` : `notRequired` ou `unsupported`.

Champs suffisants pour un sprite statique futur :

- `ProjectCharacterEntry.tilesetId` non vide ;
- `frameWidth` et `frameHeight` valides ;
- au moins une `CharacterAnimation` `idle` avec `frames` non vides ;
- direction resolue ou fallback `south`.

Si le character existe sans tileset : diagnostic `actorDisplayCharacterMissingTileset`.

Si l'animation idle manque : diagnostic `actorDisplayCharacterMissingIdleAnimation`.

Si le sprite est introuvable : diagnostic `actorDisplaySpriteUnavailable`, placeholder honnete possible.

## 10. Pass D — Overlay / renderer contract

Le futur renderer acteur doit vivre cote editor, probablement pres du panel cinematic backdrop, mais consommer un plan immutable produit en amont.

Contrat de transform :

```text
CinematicMapBackdropViewportTransform
  viewportSize
  mapPixelSize
  fittedMapRect
  scale
  mapPixelToPreview(Offset)
  mapTileToPreviewRect(x, y, width, height)
  mapActorAnchorToPreview(x, y)
```

Ancre acteur recommandee :

```text
anchorMapPixel = ((x + 0.5) * tileWidth, (y + 1.0) * tileHeight)
anchorLocal = (0.5, 1.0)
```

Z-order :

1. backdrop bitmap V1-89 ;
2. acteurs statiques tries par `anchorMapY`, puis `anchorMapX`, puis `actorId` ;
3. grille/cadre/chrome si necessaire.

Limite assumee : pas d'occlusion foreground tant que le decor V1-89 ne separe pas les layers avant/arriere.

## 11. Pass E — Runtime / Flame anti-scope

Interdits confirmes :

- `PlayableMapGame`
- `RuntimeMapGame`
- `GameWidget`
- `FlameGame`
- `CameraComponent`
- `MapLayersComponent`
- `PlayerComponent`
- `OverworldActorComponent`
- `GameState`
- `SceneCinematicRuntimeAwaitableAdapter`
- pathfinding
- collision
- `actorMove` interpolation
- `currentTimeMs`
- `playbackTimeMs`
- `isPlaying`
- `Timer`
- `Ticker`
- `AnimationController`

Raison : ces symboles representent la boucle de jeu, l'etat sauvegarde, la camera runtime, l'input, les collisions ou la lecture temporelle. V1-90 et V1-91 doivent lire l'authoring, pas simuler une partie.

Les transports restent disabled : les boutons actuels sont des placeholders desactives. V1-90 ne les rend pas fonctionnels.

## 12. Pass F — Product / UX review

Wording futur recommande :

- Titre : `Plateau de scene (statique)`.
- Sous-texte : `Decor reel et poses initiales. La timeline n'est pas lue dans cet apercu.`
- Badges : `Decor + acteurs`, `Pose initiale`, `Sans lecture`.
- Placement absent : `A placer avant apercu statique`.
- Apparence absente : `Apparence a completer`.
- Sprite indisponible : `Acteur sans sprite preview`.
- Reference cassee : `Reference a corriger`.

Seuil d'acceptabilite : l'utilisateur doit comprendre immediatement que les acteurs sont places a leur position initiale, que la timeline n'est pas jouee, que les deplacements restent dans la timeline et que les fallbacks signalent des donnees a completer.

## 13. Options techniques comparées

Option A — Renderer acteur directement depuis le Builder.

Verdict : rejetee sauf glue UI tres mince. Simple au debut, mais couplage widget, duplication de logique et tests fragiles.

Option B — Read model actor display dans `map_core`.

Verdict : bon socle pour positions, statuts, references et diagnostics. Limite : ne peut pas manipuler `ui.Image` ni resoudre les sprites.

Option C — Read model pur + resolver editor pour assets.

Verdict : retenue. Elle separe data/diagnostics, resolution asset et rendu, comme V1-83 a V1-89.

Option D — Placeholder-only renderer.

Verdict : utile comme fallback futur, pas comme architecture principale.

Option E — Runtime-derived actor state.

Verdict : rejetee pour V0. Trop large, non authoring, liee a `GameState`, Flame, collision, input et playback.

## 14. Option retenue

Option C.

Architecture recommandee :

```text
map_core
  CinematicActorDisplayPreviewModel
  CinematicActorDisplayPreviewActor
  CinematicActorPreviewPosition
  CinematicActorPreviewAppearance
  CinematicActorPreviewDiagnostic

map_editor futur
  actor sprite/placeholder resolver
  actor overlay render plan
  actor overlay painter
```

## 15. Contrat recommandé Actor Display Preview

Contrat conceptuel :

```text
CinematicActorDisplayPreviewModel
  status
  actors
  diagnostics
  summary

CinematicActorDisplayPreviewActor
  actorId
  label
  bindingKind
  source
  positionStatus
  mapPosition
  appearanceStatus
  appearanceRef
  direction
  renderHint
  diagnostics
```

Statuts model :

- `ready`
- `incomplete`
- `blocked`
- `noActors`

## 16. Contrat recommandé position / placement

Contrat conceptuel :

```text
CinematicActorPreviewPosition
  x
  y
  sourceKind
  sourceId
  label
```

Position statuses :

- `resolved`
- `missingInitialPlacement`
- `missingSource`
- `abstractOnly`
- `outOfMapBounds`
- `unbound`

Regle cle : ne jamais convertir un `abstractPoint` ou une position manquante en centre map implicite.

## 17. Contrat recommandé appearance / sprite / placeholder

Contrat conceptuel :

```text
CinematicActorPreviewAppearance
  mode: sprite | placeholder | missing
  characterId
  characterLabel
  spriteHint
  fallbackLabel
```

Appearance statuses :

- `spriteReady`
- `placeholderOnly`
- `missingCharacter`
- `missingTileset`
- `missingIdleAnimation`
- `notRequired`
- `unsupported`

V1-90 ne doit pas afficher de sprite. V1-91 ne devrait pas encore afficher de sprite non plus si le lot reste read model.

## 18. Contrat recommandé overlay / viewport transform

Le transform doit etre partage entre tiles, primitives, overlay acteurs et tests. Il doit eviter la duplication actuelle entre panel et painter.

Tests futurs attendus :

- fitted rect stable ;
- coordonnee tile -> preview ;
- ancre acteur centre-bas ;
- tiles non carrees ;
- clipping hors map ;
- z-order par anchorY.

## 19. Diagnostics futurs

Diagnostics minimaux :

- `actorDisplayNoActors` : info.
- `actorDisplayUnknownActor` : error.
- `actorDisplayMissingBinding` : warning.
- `actorDisplayUnboundActor` : warning.
- `actorDisplayMissingInitialPlacement` : warning.
- `actorDisplayMissingMapEntity` : error.
- `actorDisplayMissingMovementTarget` : error.
- `actorDisplayAbstractTargetOnly` : warning.
- `actorDisplayOutOfMapBounds` : warning.
- `actorDisplayMissingAppearance` : warning.
- `actorDisplayUnknownCharacter` : warning ou error selon fallback.
- `actorDisplayCharacterMissingTileset` : warning.
- `actorDisplayCharacterMissingIdleAnimation` : warning.
- `actorDisplaySpriteUnavailable` : warning.
- `actorDisplayRuntimeUnsupported` : info guardrail.
- `actorDisplayDirectionFallback` : info.
- `actorDisplayDuplicateBinding` : warning.
- `actorDisplayDuplicatePlacement` : warning.

## 20. Tests futurs V1-91

Tests purs `map_core` recommandes :

- no actors -> `noActors` + diagnostic info ;
- player avec placement resolu -> acteur positionne sans runtime ;
- mapEntity -> `MapEntity.pos` ;
- cinematicOnly -> appearance binding character ;
- unbound -> non-renderable ;
- placement absent -> diagnostic ;
- `fromMovementTarget` vers mapEntity ;
- `fromMovementTarget` vers mapEvent ;
- `abstractPoint` non resolu ;
- `target_center` et `target_exit` non special-cases ;
- character manquant ;
- character sans tileset ;
- character sans idle animation ;
- actorFace ignore pour placement mais converti en direction display si present ;
- timeline `actorMove` ignoree ;
- absence d'import Flutter/Flame/runtime dans `map_core`.

## 21. Visual Gate future V1-91

Si V1-91 reste strictement read model, aucune capture n'est requise.

Visual Gate attendue pour le premier renderer overlay futur :

```text
NS_SCENES_V1_92_CAPTURE_CINEMATIC_ACTOR_DISPLAY_PREVIEW=true
```

Attendus visuels futurs :

- decor V1-89 toujours lisible ;
- timeline conserve ses proportions ;
- badges `Pose initiale` et `Sans lecture` ;
- acteur `player`, `mapEntity`, `cinematicOnly` ou placeholders visibles selon fixtures ;
- diagnostics calmes pour missing placement/sprite ;
- transports disabled.

## 22. Roadmap post V1-90

Mise a jour retenue :

- V1-90 : DONE.
- V1-91 : `Cinematic Actor Display Preview Read Model V0`.
- V1-92 : `Cinematic Timeline Scroll / Visibility Polish V0`.

Le read model d'abord evite de melanger rendu, assets et logique de resolution dans un widget.

## 23. Non-objectifs confirmés

V1-90 n'a pas :

- modifie de code produit ;
- modifie `packages/` ;
- cree de test ;
- genere de screenshot ;
- rendu d'acteur ;
- rendu de sprite Character Library ;
- affiche de placeholder acteur ;
- branche de runtime ;
- importe Flame ;
- ajoute de playback ;
- utilise `GameState` ;
- ajoute `currentTimeMs`, `playbackTimeMs` ou `isPlaying` ;
- modifie `MapData`, `ProjectManifest` ou Selbrume.

## 24. Commandes exécutées

Commandes principales :

```bash
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git log --oneline -n 15
wc -l ...
rg -n "CinematicActorBinding|CinematicActorAppearanceBinding|actorBindings|actorAppearanceBindings|initialPlacements|movementTargetBindings|requiredActors|CinematicInitialPlacement|CinematicMovementTargetBinding" packages/map_core packages/map_editor
rg -n "ProjectCharacterEntry|characters|Character Library|character.*tileset|idle|animation|direction" packages/map_core packages/map_editor
rg -n "CinematicStageMapSourceCatalog|stageMapSourceCatalog|canBindActor|canBeMovementTarget|mapEntity|mapEvent" packages/map_core packages/map_editor
rg -n "CinematicMapBackdropTileRenderPainter|CinematicMapBackdropPreviewPanel|fitted|viewport|TileRenderPlan|drawImageRect" packages/map_editor/lib/src/ui/canvas/cinematics
rg -n "PlayableMapGame|RuntimeMapGame|GameWidget|FlameGame|CameraComponent|MapLayersComponent|PlayerComponent|OverworldActorComponent|GameState|map_runtime|currentTimeMs|playbackTimeMs|isPlaying" packages/map_editor/lib/src/ui/canvas/cinematics packages/map_runtime || true
```

Les sorties exactes de preuve finale sont dans l'Evidence Pack V1-90.

## 25. Checks anti-scope

Checks attendus :

- `git diff --name-only -- packages` doit rester vide.
- Les fichiers modifies doivent etre uniquement les deux rapports V1-90 et les deux roadmaps.
- Les termes runtime/Flame/playback peuvent apparaitre uniquement dans non-objectifs, anti-scope ou lots futurs.

## 26. Evidence Pack

Evidence Pack :

```text
reports/narrativeStudio/scenes/ns_scenes_v1_90_evidence_pack.md
```

## 27. Auto-review critique

1. Est-ce que V1-90 a modifié du code produit ? Non.
2. Est-ce que V1-90 a modifié `packages/` ? Non attendu ; verification finale dans Evidence Pack.
3. Est-ce que V1-90 a créé un test ? Non.
4. Est-ce que V1-90 a généré un screenshot ? Non.
5. Est-ce que V1-90 a rendu un acteur ? Non.
6. Est-ce que V1-90 a rendu un sprite Character Library ? Non.
7. Est-ce que V1-90 a branché le runtime ? Non.
8. Est-ce que V1-90 a importé Flame ? Non.
9. Est-ce que V1-90 a ajouté du playback ? Non.
10. Est-ce que V1-90 a utilisé GameState ? Non.
11. Est-ce que V1-90 a ajouté `currentTimeMs`/`playbackTimeMs`/`isPlaying` ? Non.
12. Est-ce que V1-90 a comparé les sources actor bindings ? Oui.
13. Est-ce que V1-90 a cadré player ? Oui.
14. Est-ce que V1-90 a cadré mapEntity ? Oui.
15. Est-ce que V1-90 a cadré cinematicOnly ? Oui.
16. Est-ce que V1-90 a cadré unbound ? Oui.
17. Est-ce que V1-90 a défini la résolution de position ? Oui.
18. Est-ce que V1-90 a défini les fallbacks position ? Oui.
19. Est-ce que V1-90 a défini les fallbacks appearance ? Oui.
20. Est-ce que V1-90 a défini les diagnostics futurs ? Oui.
21. Est-ce que V1-90 a défini les tests V1-91 ? Oui.
22. Est-ce que V1-90 a défini la Visual Gate V1-91 ? Oui, avec precision : pas de screenshot si V1-91 reste read model pur ; Visual Gate pour le premier renderer overlay.
23. Est-ce que V1-90 a mis à jour les roadmaps ? Oui.
24. Est-ce que l'Evidence Pack est complet ? Oui.
25. Quel est le prochain lot exact recommandé ? `NS-SCENES-V1-91 — Cinematic Actor Display Preview Read Model V0`.

## 28. Recommandation pour le prochain lot

Recommandation :

```text
NS-SCENES-V1-91 — Cinematic Actor Display Preview Read Model V0
```

Objectif :

```text
Créer un read model pur des acteurs affichables dans la preview cinematic :
acteurs, bindings, positions résolues ou manquantes, apparences, placeholders,
diagnostics et summary, sans encore rendre les acteurs en UI.
```
