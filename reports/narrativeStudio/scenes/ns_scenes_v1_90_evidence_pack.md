# NS-SCENES-V1-90 — Evidence Pack

## 1. Gate 0 complet

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

## 2. Liste des fichiers lus

```text
AGENTS.md
agent_rules.md
skills/README.md
skills/using-superpowers/SKILL.md
skills/writing-plans/SKILL.md
skills/dispatching-parallel-agents/SKILL.md
skills/verification-before-completion/SKILL.md
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/ns_scenes_v1_89_cinematic_map_backdrop_real_tile_renderer_integration_fidelity_polish_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_89_evidence_pack.md
reports/narrativeStudio/scenes/ns_scenes_v1_88_cinematic_map_backdrop_real_tile_renderer_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_81_cinematic_actor_appearance_readiness_drift_diagnostics_polish_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_80_cinematic_character_library_picker_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_79_cinematic_character_library_binding_core_model_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_77_cinematic_stage_map_entity_event_pickers_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_76_cinematic_stage_map_source_catalog_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_72_cinematic_stage_map_context_core_model_v0.md
packages/map_core/lib/src/models/cinematic_asset.dart
packages/map_core/lib/src/models/project_manifest.dart
packages/map_core/lib/src/models/map_data.dart
packages/map_core/lib/src/models/map_entity_payloads.dart
packages/map_core/lib/src/models/map_event_definition.dart
packages/map_core/lib/src/models/game_state.dart
packages/map_core/lib/src/read_models/cinematic_stage_map_source_catalog.dart
packages/map_core/lib/src/read_models/cinematic_map_backdrop_preview_model.dart
packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart
packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_tile_renderer.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_tile_render_plan.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_tile_plan_loader.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_stage_preview_readiness.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/lib/src/ui/panels/character_library_panel.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
packages/map_editor/test/cinematics_library_workspace_test.dart
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
packages/map_runtime/lib/src/presentation/flame/runtime_map_game.dart
packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart
packages/map_runtime/lib/src/presentation/flame/player_component.dart
packages/map_runtime/lib/src/presentation/flame/overworld_actor_component.dart
packages/map_runtime/lib/src/application/scene_runtime/scene_cinematic_runtime_awaitable_adapter.dart
```

## 3. Notes des sub-agents / passes spécialisées

### Sub-agent A — Actor Sources / Stage Bindings Audit

Conclusion : `requiredActors` inventorie les acteurs, `actorBindings` choisit la source stage, `actorAppearanceBindings` s'applique aux acteurs `cinematicOnly`, `initialPlacements` et `movementTargetBindings` restent des couches separees. `unbound` est non-renderable. `CinematicActorRef.entityId` ne doit pas etre utilise comme binding concurrent.

Sources fiables citees : `CinematicAsset.requiredActors`, `CinematicStageContext.actorBindings`, `CinematicStageMapSourceCatalog`, `MapData.entities`, `actorAppearanceBindings`.

Risques : parser `positionSummary`, inventer une source depuis `entityId`, confondre actor display statique et runtime.

### Sub-agent B — Position / Placement Contract

Conclusion : le futur read model doit prendre `CinematicAsset`, `ProjectMapEntry?`, `MapData?` et resoudre les positions en grille depuis `initialPlacements`. `fromMapEntity` passe par `CinematicActorBinding.mapEntityId` et `MapData.entities`. `fromMovementTarget` passe par `movementTargetBindings` puis `MapData.entities` ou `MapData.events`. `abstractPoint`, `target_center` et `target_exit` ne donnent aucune coordonnee implicite.

Fallback : produire `unresolved` + diagnostic, jamais une coordonnee inventee.

### Sub-agent C — Appearance / Character Library Audit

Conclusion : `cinematicOnly` utilise `CinematicActorAppearanceBinding.characterId -> ProjectManifest.characters`. `player` peut utiliser plus tard `ProjectSettings.defaultPlayerCharacterId`. `mapEntity` peut utiliser `MapEntityNpcData.characterId`, puis `trainer.characterId`; `visualElementId` reste un fallback visuel, pas un personnage. Direction : mapper explicitement `up/down/left/right` vers `north/south/west/east`.

Diagnostics futurs : character absent, tileset absent, idle absent, source rect hors image, direction manquante.

### Sub-agent D — Overlay / Renderer Contract

Conclusion : le futur overlay acteur doit partager le viewport du decor V1-89. Le transform a factoriser doit exposer `fittedMapRect`, `scale`, `mapPixelToPreview`, `mapTileToPreviewRect` et `mapActorAnchorToPreview`. Ancre acteur recommandee : centre bas de tuile.

Z-order : decor, acteurs tries par anchorY, puis cadre/chrome.

### Sub-agent E — Runtime / Playback Anti-scope

Conclusion : ne pas utiliser `PlayableMapGame`, `RuntimeMapGame`, `GameWidget`, `FlameGame`, `CameraComponent`, `MapLayersComponent`, `PlayerComponent`, `OverworldActorComponent`, `GameState`, `SceneCinematicRuntimeAwaitableAdapter`, pathfinding, collision, actorMove interpolation ou controles playback actifs.

Frontiere : `map_editor` lit l'authoring et les assets, mais ne simule pas une partie.

### Sub-agent F — Product / UX Reviewer

Conclusion : wording futur recommande : `Plateau de scene (statique)`, `Decor reel et poses initiales`, `Sans lecture`, `Pose initiale`, `Apparence a completer`, `A placer avant apercu statique`.

Seuil : l'utilisateur doit comprendre que les acteurs sont statiques, a leur position initiale, sans lecture de timeline.

## 4. Résultats des recherches rg structurantes

Commande :

```bash
rg -n "CinematicActorBinding|CinematicActorAppearanceBinding|actorBindings|actorAppearanceBindings|initialPlacements|movementTargetBindings|requiredActors|CinematicInitialPlacement|CinematicMovementTargetBinding" packages/map_core packages/map_editor
```

Sorties retenues par l'audit :

```text
packages/map_core/lib/src/models/cinematic_asset.dart:29:enum CinematicActorBindingKind {
packages/map_core/lib/src/models/cinematic_asset.dart:36:enum CinematicActorInitialPlacementKind {
packages/map_core/lib/src/models/cinematic_asset.dart:42:enum CinematicMovementTargetBindingKind {
packages/map_core/lib/src/models/cinematic_asset.dart:48:final class CinematicAsset {
packages/map_core/lib/src/models/cinematic_asset.dart:194:final class CinematicStageContext {
packages/map_core/lib/src/models/cinematic_asset.dart:289:final class CinematicActorBinding {
packages/map_core/lib/src/models/cinematic_asset.dart:336:final class CinematicActorAppearanceBinding {
packages/map_core/lib/src/models/cinematic_asset.dart:377:final class CinematicActorInitialPlacement {
packages/map_core/lib/src/models/cinematic_asset.dart:423:final class CinematicMovementTargetBinding {
packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart:348:  final actorBindingsById = <String, CinematicActorBinding>{};
packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart:434:  for (final binding in stageContext.actorAppearanceBindings) {
packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart:491:  for (final placement in stageContext.initialPlacements) {
packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart:559:  for (final binding in stageContext.movementTargetBindings) {
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart:1121:      onUpsertActorBinding: _upsertCinematicActorBinding,
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart:1122:      onUpsertActorAppearanceBinding: _upsertCinematicActorAppearanceBinding,
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart:1125:      onUpsertMovementTargetBinding: _upsertCinematicMovementTargetBinding,
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:5035:        selectedKind == CinematicActorBindingKind.mapEntity &&
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:5273:                              CinematicActorBindingKind.cinematicOnly,
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:5290:                              selectedKind == CinematicActorBindingKind.unbound,
```

Commande :

```bash
rg -n "ProjectCharacterEntry|characters|Character Library|character.*tileset|idle|animation|direction" packages/map_core packages/map_editor
```

Sorties retenues par l'audit :

```text
packages/map_core/lib/src/models/project_manifest.dart:381:    @Default([]) List<ProjectCharacterEntry> characters,
packages/map_core/lib/src/models/project_manifest.dart:827:class ProjectCharacterEntry with _$ProjectCharacterEntry {
packages/map_core/lib/src/models/project_manifest.dart:835:    @Default([]) List<CharacterAnimation> animations,
packages/map_core/lib/src/models/project_manifest.dart:849:    required EntityFacing direction,
packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart:643:    final character = charactersById[binding.characterId];
packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart:660:    if (character.tilesetId.trim().isEmpty) {
packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart:698:  return !character.animations.any(
packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart:700:        animation.state == CharacterAnimationState.idle &&
packages/map_editor/lib/src/ui/panels/character_library_panel.dart:243:// Animation slot grid (3 states × 4 directions)
packages/map_editor/lib/src/ui/panels/character_library_panel.dart:493:        notifier.getTilesetAbsolutePathById(widget.character.tilesetId);
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:8633:    CinematicActorBindingKind.player => 'Apparence héritée du joueur.',
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:8636:    CinematicActorBindingKind.cinematicOnly =>
```

Commande :

```bash
rg -n "CinematicStageMapSourceCatalog|stageMapSourceCatalog|canBindActor|canBeMovementTarget|mapEntity|mapEvent" packages/map_core packages/map_editor
```

Sorties retenues par l'audit :

```text
packages/map_core/lib/src/read_models/cinematic_stage_map_source_catalog.dart:39:final class CinematicStageMapSourceCatalog {
packages/map_core/lib/src/read_models/cinematic_stage_map_source_catalog.dart:64:      status == CinematicStageMapSourceCatalogStatus.available;
packages/map_core/lib/src/read_models/cinematic_stage_map_source_catalog.dart:94:    required this.canBindActor,
packages/map_core/lib/src/read_models/cinematic_stage_map_source_catalog.dart:105:  final bool canBindActor;
packages/map_core/lib/src/read_models/cinematic_stage_map_source_catalog.dart:106:  final bool canBeMovementTarget;
packages/map_core/lib/src/read_models/cinematic_stage_map_source_catalog.dart:134:CinematicStageMapSourceCatalog buildCinematicStageMapSourceCatalog({
packages/map_core/lib/src/read_models/cinematic_stage_map_source_catalog.dart:273:    canBindActor: entity.kind == MapEntityKind.npc || entity.npc != null,
packages/map_core/lib/src/read_models/cinematic_stage_map_source_catalog.dart:274:    canBeMovementTarget: true,
packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart:263:  CinematicStageMapSourceCatalog? _stageMapSourceCatalog;
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:5018:    final sourceCatalog = widget.stageMapSourceCatalog;
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:8412:String? _mapEntityActorDisabledReason(
```

Commande :

```bash
rg -n "CinematicMapBackdropTileRenderPainter|CinematicMapBackdropPreviewPanel|fitted|viewport|TileRenderPlan|drawImageRect" packages/map_editor/lib/src/ui/canvas/cinematics
```

Sortie :

```text
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_tile_render_plan.dart:145:final class CinematicMapBackdropTileRenderPlan {
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_tile_render_plan.dart:169:CinematicMapBackdropTileRenderPlan buildCinematicMapBackdropTileRenderPlan({
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_tile_renderer.dart:19:class CinematicMapBackdropTileRenderPainter extends CustomPainter {
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_tile_renderer.dart:38:    final frame = _fittedMapRect(size);
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_tile_renderer.dart:64:      canvas.drawImageRect(
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_tile_renderer.dart:83:  Rect _fittedMapRect(Size size) {
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart:12:class CinematicMapBackdropPreviewPanel extends StatelessWidget {
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart:240:                  final viewportWidth = plan.pixelWidth * scale;
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart:245:                        'cinematic-builder-map-backdrop-bitmap-viewport',
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart:409:            final viewportWidth = mapWidth * scale;
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart:414:                  'cinematic-builder-map-backdrop-visual-viewport',
```

Commande :

```bash
rg -n "PlayableMapGame|RuntimeMapGame|GameWidget|FlameGame|CameraComponent|MapLayersComponent|PlayerComponent|OverworldActorComponent|GameState|map_runtime|currentTimeMs|playbackTimeMs|isPlaying" packages/map_editor/lib/src/ui/canvas/cinematics packages/map_runtime || true
```

Sorties retenues par l'audit anti-scope :

```text
packages/map_runtime/lib/map_runtime.dart:27:export 'src/presentation/flame/playable_map_game.dart' show PlayableMapGame;
packages/map_runtime/lib/map_runtime.dart:40:export 'src/presentation/flame/runtime_map_game.dart' show RuntimeMapGame;
packages/map_runtime/README.md:57:      body: GameWidget(game: RuntimeMapGame(bundle: bundle)),
packages/map_runtime/README.md:86:| `RuntimeMapGame` | A `FlameGame` that renders the map (read-only). |
packages/map_runtime/README.md:87:| `PlayableMapGame` | A `FlameGame` with player movement, collision, warp transitions, entity interaction, battle triggering, narrow battle outcome write-back for the supported slice, and `handleRuntimeInputEvent(...)` for custom input sources. |
packages/map_runtime/test/shadow/runtime_actor_contact_shadow_host_integration_test.dart:11:import 'package:map_runtime/src/presentation/flame/playable_map_game.dart';
packages/map_runtime/test/shadow/runtime_actor_contact_shadow_host_integration_test.dart:12:import 'package:map_runtime/src/presentation/flame/runtime_map_game.dart';
```

Interpretation : les occurrences sont dans `packages/map_runtime`, lu pour definir l'anti-scope. Le scan futur des fichiers modifies V1-90 doit montrer que ces termes n'apparaissent que dans l'analyse documentaire.

## 5. Arbitrage final

Option retenue : Option C.

```text
Read model pur pour actor display, puis resolver editor pour sprites/images.
```

Raisons :

- `map_core` peut tester les acteurs, positions, statuts, diagnostics et references sans Flutter.
- `map_editor` peut resoudre les assets et construire un plan de rendu sans faire porter cette responsabilite aux widgets.
- Runtime, Flame, GameState et playback restent exclus.
- Le read model prepare V1-91 sans forcer de rendu trop tot.

Prochain lot exact :

```text
NS-SCENES-V1-91 — Cinematic Actor Display Preview Read Model V0
```

## 6. Hunks complets des roadmaps modifiées

```diff
diff --git a/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md b/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
index 773a9044..7f4d3330 100644
--- a/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
+++ b/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
@@ -9,7 +9,7 @@ Le runtime reste indispensable, mais le prochain blocage produit est plus basiqu
 ## Prochain lot exact recommande
 
 ```text
-NS-SCENES-V1-90 — Cinematic Actor Display Preview Prep Contract
+NS-SCENES-V1-91 — Cinematic Actor Display Preview Read Model V0
 ```
 
 ## Principes
@@ -123,8 +123,25 @@ NS-SCENES-V1-90 — Cinematic Actor Display Preview Prep Contract
 | NS-SCENES-V1-87 | Cinematic Map Backdrop Real Tile Rendering Prep Contract | doc-only / architecture-review | Cadrer le rendu reel des tiles/assets dans la preview cinematic avant tout code : audit MapData/layers, tilesets, asset resolution, rendu Map Editor et anti-scope runtime. | Pas de code produit, package, widget, test, screenshot, renderer, vraie map affichee, runtime/Flame, playback, acteurs rendus, fake tiles ou donnee Selbrume. | Rapport V1-87, Evidence Pack, roadmaps. | DONE : sub-agents A-E, Option E retenue, contrat futur renderer V1-88, asset registry editor-only recommande, layer ordering/fallbacks/tests futurs cadres. | Brancher MapCanvas complet ; charger les images dans build/paint ; utiliser le runtime ; poser des acteurs sur un decor abstrait. | DONE : contrat pret pour V1-88, sans modifier les packages. | V1-86. |
 | NS-SCENES-V1-88 | Cinematic Map Backdrop Real Tile Renderer V0 | editor / preview-sandbox | Afficher les vraies tiles/assets de la map dans le Cinematic Builder via un renderer read-only editor-only, avec images resolues en amont et diagnostics visibles. | Pas de runtime/Flame, `PlayableMapGame`, playback, acteurs rendus, pathfinding/collision, mutation map/projet, donnees Selbrume ou image IA. | Builder cinematics, renderer cinematic, asset registry/cache editor-only, tests widget, rapport, Visual Gate. | DONE : rendu `TileLayer` visible via instructions bitmap, registre asset editor-only, fallback structurel diagnostique, proportions V1-86 preservees, tests/Visual Gate. | Divergence visuelle avec Map Editor ; cache image perime ; fallback silencieux ; timeline reduite. | DONE : vraie map statique affichable sans lancer la cinematique. | V1-87. |
 | NS-SCENES-V1-89 | Cinematic Map Backdrop Real Tile Renderer Integration / Fidelity Polish V0 | editor / preview-sandbox | Brancher le renderer bitmap V1-88 au vrai workspace editor : resolver tileset parent, chargement async borne, fallback diagnostique et fidelity TileLayer durcie. | Pas d'acteurs rendus, runtime/Flame, playback/interpolation, pathfinding/collision, donnee Selbrume hardcodee ou mutation runtime/map/projet. | Library/Builder cinematics, `narrative_workspace_canvas.dart`, loader asset, tests widget/plan, rapports, screenshot. | DONE : success/fallback/collecteur/fidelite, Visual Gate 1663x926, anti-scope runtime/Flame. | Fallback silencieux ; stale cache ; charger des images dans build/paint ; reduire la timeline. | DONE : vraies tiles resolues depuis le parent editor et affichees dans le Builder. | V1-88. |
-| NS-SCENES-V1-90 | Cinematic Actor Display Preview Prep Contract | doc-only / architecture-review | Cadrer l'affichage statique futur des acteurs une fois le vrai decor map rendu : sources actor bindings/placements/Character Library, positions, apparences et diagnostics. | Pas de rendu acteur actif, runtime/Flame, playback/interpolation, pathfinding/collision, donnee Selbrume ou mutation runtime. | Rapport V1-90, roadmaps. | TODO : contrat acteurs preview et anti-scope runtime. | Confondre acteur statique et gameplay ; cacher les gaps Character Library ; casser le decor V1-89. | TODO : contrat pret pour renderer actor statique futur. | V1-89. |
-| NS-SCENES-V1-91 | Cinematic Timeline Scroll / Visibility Polish V0 | editor / ui-polish | Backlog futur : polir la visibilite des blocs/repere/selection quand les interactions clavier ou souris placent l'element cible hors de la vue utile. | Pas de playback, seek runtime, scrubber runtime, transport fonctionnel, drag/resize/reorder, mutation JSON, runtime, zoom temporel ou changement de modele. | Builder cinematics, tests widget, rapport, screenshot. | TODO : scroll automatique/visibilite controles, proportions timeline preservees, selection/probe non mutants. | Casser les proportions visees ; confondre scroll de vue et navigation temporelle ; ajouter un pouvoir de montage. | TODO : visibilite plus fiable, sans nouveau pouvoir temporel. | Backlog post Actor Display Prep. |
+| NS-SCENES-V1-90 | Cinematic Actor Display Preview Prep Contract | doc-only / architecture-review | Cadrer l'affichage statique futur des acteurs une fois le vrai decor map rendu : sources actor bindings/placements/Character Library, positions, apparences, overlay/viewport et diagnostics. | Pas de code produit, package, test, screenshot, rendu acteur actif, runtime/Flame, playback/interpolation, pathfinding/collision, donnee Selbrume ou mutation runtime/map/projet. | Rapport V1-90, Evidence Pack, roadmaps. | DONE : sub-agents A-F, Option C retenue, contrat actor display read model, positions, apparences, overlay, diagnostics/tests/Visual Gate V1-91, anti-scope runtime. | Confondre acteur statique et gameplay ; cacher les gaps Character Library ; casser le decor V1-89 ; coder un renderer trop tot. | DONE : contrat pret pour read model Actor Display statique futur, sans rendre d'acteur. | V1-89. |
+| NS-SCENES-V1-91 | Cinematic Actor Display Preview Read Model V0 | core / read-model | Creer un read model pur des acteurs affichables dans la preview cinematic : acteurs, bindings, positions resolues ou manquantes, apparences, placeholders, diagnostics et summary. | Pas de renderer UI, sprite actor affiche, playback, runtime/Flame, GameState, pathfinding/collision, mutation MapData/ProjectManifest ou screenshot. | `map_core` read model actor display, tests purs, rapport. | TODO : modeliser les acteurs statiques sans UI. | Melanger read model et painter ; inventer des positions ; utiliser le runtime pour simplifier. | TODO : actor display projetable et testable, sans rendu. | V1-90. |
+| NS-SCENES-V1-92 | Cinematic Timeline Scroll / Visibility Polish V0 | editor / ui-polish | Backlog futur : polir la visibilite des blocs/repere/selection quand les interactions clavier ou souris placent l'element cible hors de la vue utile. | Pas de playback, seek runtime, scrubber runtime, transport fonctionnel, drag/resize/reorder, mutation JSON, runtime, zoom temporel ou changement de modele. | Builder cinematics, tests widget, rapport, screenshot. | TODO : scroll automatique/visibilite controles, proportions timeline preservees, selection/probe non mutants. | Casser les proportions visees ; confondre scroll de vue et navigation temporelle ; ajouter un pouvoir de montage. | TODO : visibilite plus fiable, sans nouveau pouvoir temporel. | Backlog post Actor Display Read Model. |
+ 
+## Mise a jour V1-90
+ 
+Statut : `NS-SCENES-V1-90 — Cinematic Actor Display Preview Prep Contract` est DONE.
+ 
+Demande : Karim a fourni le prompt V1-90 et a demande explicitement sub-agents/passes, sans code produit ni rendu acteur. Le lot vient apres V1-89 parce que le decor map reel existe enfin dans le Builder.
+ 
+Decision : Option C retenue. Le futur affichage statique des acteurs doit commencer par un read model pur, puis seulement ensuite un resolver editor et un renderer overlay. Le Builder ne doit pas porter directement toute la logique, et le runtime/Flame/GameState restent bannis.
+ 
+Scope realise : audit actor sources/stage bindings, position/placement, Character Library/appearance, overlay/viewport, anti-runtime/playback, UX wording, diagnostics futurs, tests futurs et Visual Gate V1-91.
+ 
+Preuve : rapports V1-90, Evidence Pack, sub-agents A-F, Gate 0 propre, checks anti-scope documentaires et `git diff --check`.
+ 
+Limites : aucun fichier `packages/`, aucun test, aucun screenshot, aucun acteur/sprite/placeholder rendu, aucun playback, runtime, Flame, pathfinding/collision, mutation MapData/ProjectManifest ou donnee Selbrume.
+ 
+Prochain lot exact recommande : `NS-SCENES-V1-91 — Cinematic Actor Display Preview Read Model V0`.
 
 ## Mise a jour V1-89
 
diff --git a/reports/narrativeStudio/scenes/road_map_scenes.md b/reports/narrativeStudio/scenes/road_map_scenes.md
index 7071c1d3..94e883b6 100644
--- a/reports/narrativeStudio/scenes/road_map_scenes.md
+++ b/reports/narrativeStudio/scenes/road_map_scenes.md
@@ -144,20 +144,37 @@ Ces briques sont utiles, mais elles ne constituent pas encore une Scene V1 propr
 | NS-SCENES-V1-87 — Cinematic Map Backdrop Real Tile Rendering Prep Contract | DONE | Lot documentaire demande par Karim : audit MapData/layers visuels, tilesets/assets, rendu Map Editor et anti-scope runtime/Flame ; Option E retenue, contrat futur renderer V1-88 defini, sans code produit, package, test, screenshot, renderer, map rendue, playback ni acteurs. |
 | NS-SCENES-V1-88 — Cinematic Map Backdrop Real Tile Renderer V0 | DONE | Renderer bitmap editor-only read-only pour la preview du Cinematic Builder : instructions tiles derivees de `MapData`, images tileset resolues en amont, painter dedie proportionnel, diagnostics/fallbacks, Visual Gate 1663x926, tests builder/library/core et analyse ciblee verts, sans runtime, Flame, playback, acteurs rendus, pathfinding, collision, mutation projet/map, donnees Selbrume ni image IA. |
 | NS-SCENES-V1-89 — Cinematic Map Backdrop Real Tile Renderer Integration / Fidelity Polish V0 | DONE | Integre le renderer bitmap V1-88 au vrai workspace editor : resolution tileset via parent/editor notifier, fallback structurel uniquement diagnostique, fidelity TileLayer durcie, Visual Gate 1663x926, sans acteurs/playback/runtime. |
-| NS-SCENES-V1-90 — Cinematic Actor Display Preview Prep Contract | TODO | Cadrer l'affichage statique futur des acteurs apres le vrai decor map : sources actor bindings/placements/Character Library, positions, apparences et diagnostics, sans rendu acteur actif, runtime, playback, pathfinding ou collision. |
-| NS-SCENES-V1-91 — Cinematic Timeline Scroll / Visibility Polish V0 | TODO | Backlog futur déplacé depuis V1-80 : polir le scroll automatique et la visibilite des blocs/selection/probe apres le cadrage Character Library, en preservant les proportions de timeline demandees par Karim. |
+| NS-SCENES-V1-90 — Cinematic Actor Display Preview Prep Contract | DONE | Lot documentaire demande par Karim : audit actor sources/stage bindings, positions/placements, Character Library/appearances, overlay/viewport, anti-runtime/Flame et UX ; Option C retenue, contrat futur read model actor display, diagnostics/tests/Visual Gate V1-91 cadres, sans code produit, packages, tests, screenshot, rendu acteur, runtime, playback, pathfinding/collision ni donnee Selbrume. |
+| NS-SCENES-V1-91 — Cinematic Actor Display Preview Read Model V0 | TODO | Creer un read model pur des acteurs affichables dans la preview cinematic : acteurs, bindings, positions resolues ou manquantes, apparences, placeholders, diagnostics et summary, sans encore rendre les acteurs en UI. |
+| NS-SCENES-V1-92 — Cinematic Timeline Scroll / Visibility Polish V0 | TODO | Backlog futur déplacé depuis V1-80/V1-91 : polir le scroll automatique et la visibilite des blocs/selection/probe apres le read model Actor Display, en preservant les proportions de timeline demandees par Karim. |
 
 ## Prochain lot recommande
 
-`NS-SCENES-V1-90 — Cinematic Actor Display Preview Prep Contract`
+`NS-SCENES-V1-91 — Cinematic Actor Display Preview Read Model V0`
 
-Raison : V1-89 branche maintenant le renderer de vraies tiles au workspace editor et prouve la resolution d'assets depuis le parent. Le prochain verrou logique est de cadrer l'affichage statique futur des acteurs par-dessus ce decor, sans encore rendre d'acteur actif ni lancer de runtime/playback.
+Raison : V1-90 a tranche le contrat d'affichage statique futur des acteurs et retient un read model pur avant tout renderer. Le prochain verrou logique est de materialiser ce modele : inventaire acteurs, bindings, positions resolues ou manquantes, apparences, placeholders et diagnostics, sans encore dessiner d'acteur.
 
-Ordre apres V1-89 : `NS-SCENES-V1-90 — Cinematic Actor Display Preview Prep Contract`, puis `NS-SCENES-V1-91 — Cinematic Timeline Scroll / Visibility Polish V0` reste un backlog futur.
+Ordre apres V1-90 : `NS-SCENES-V1-91 — Cinematic Actor Display Preview Read Model V0`, puis `NS-SCENES-V1-92 — Cinematic Timeline Scroll / Visibility Polish V0` reste un backlog futur.
 
 Le lot `NS-SCENES-V1-78 — Cinematic Stage Source Drift Diagnostics Polish V0` précédemment recommandé est repoussé après la séquence Character Library Binding. Il reste pertinent, mais il ne doit plus occuper V1-78.
 
-Le lot `NS-SCENES-V1-67 — Cinematic Timeline Scroll / Visibility Polish V0` precedemment recommande est remplace par `NS-SCENES-V1-67 — Cinematic Timeline Duration Editing / Resize Prep Contract`, puis deplace en backlog futur. Il etait stocke comme `NS-SCENES-V1-72 — Cinematic Timeline Scroll / Visibility Polish V0`; V1-72 devient maintenant le modele core Stage/Map Context. Le polish scroll/visibility a ensuite occupe le slot V1-80, mais V1-80 est maintenant reserve au Character Library Picker ; V1-90 est maintenant reserve a Actor Display Prep apres le lot V1-89 demande par Karim, donc le polish scroll/visibility est deplace explicitement en `NS-SCENES-V1-91 — Cinematic Timeline Scroll / Visibility Polish V0`.
+Le lot `NS-SCENES-V1-67 — Cinematic Timeline Scroll / Visibility Polish V0` precedemment recommande est remplace par `NS-SCENES-V1-67 — Cinematic Timeline Duration Editing / Resize Prep Contract`, puis deplace en backlog futur. Il etait stocke comme `NS-SCENES-V1-72 — Cinematic Timeline Scroll / Visibility Polish V0`; V1-72 devient maintenant le modele core Stage/Map Context. Le polish scroll/visibility a ensuite occupe le slot V1-80, mais V1-80 est maintenant reserve au Character Library Picker ; V1-90 est maintenant reserve a Actor Display Prep apres le lot V1-89 demande par Karim, puis V1-91 est pris par Actor Display Read Model. Le polish scroll/visibility est donc deplace explicitement en `NS-SCENES-V1-92 — Cinematic Timeline Scroll / Visibility Polish V0`.
+ 
+## Mise a jour V1-90
+ 
+Statut : `NS-SCENES-V1-90 — Cinematic Actor Display Preview Prep Contract` est DONE.
+ 
+Demande : Karim a fourni le prompt V1-90 et a demande explicitement des sub-agents/passes, sans coder l'affichage des acteurs. Le lot devait preparer l'affichage statique futur apres le decor reel V1-89, tout en confirmant que V1-90 ne rend toujours aucun acteur.
+ 
+Decision : l'Option C est retenue. Le futur actor display doit passer par un read model pur, idealement dans `map_core`, puis par un resolver editor pour les assets/sprites. Le Builder ne doit pas calculer directement toute la logique dans le widget, et le runtime/Flame/GameState sont exclus.
+ 
+Scope realise : audit actor sources/stage bindings, contrat positions/placements, contrat Character Library/appearances, contrat overlay/viewport transform, anti-scope runtime/playback, wording UX, diagnostics futurs, tests futurs et Visual Gate V1-91.
+ 
+Preuve : rapports `ns_scenes_v1_90_cinematic_actor_display_preview_prep_contract.md` et `ns_scenes_v1_90_evidence_pack.md`, sub-agents A-F, Gate 0 propre, checks anti-scope documentaires et `git diff --check`.
+ 
+Limites : lot documentaire uniquement. Aucun code produit, package, test, screenshot, rendu acteur, sprite Character Library, placeholder acteur, runtime, Flame, playback, pathfinding/collision, mutation MapData/ProjectManifest ou donnee Selbrume n'est ajoute.
+ 
+Prochain lot exact recommande : `NS-SCENES-V1-91 — Cinematic Actor Display Preview Read Model V0`.
 
 ## Mise a jour V1-89
```

## 7. Sorties de vérification finale

Commande :

```bash
git diff --name-only -- packages
```

Sortie :

```text
```

Interpretation : aucun fichier `packages/` n'est modifie par V1-90.

Commande :

```bash
git diff --check
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
 .../scenes/road_map_scene_builder_authoring.md     | 23 ++++++++++++++---
 reports/narrativeStudio/scenes/road_map_scenes.md  | 29 +++++++++++++++++-----
 2 files changed, 43 insertions(+), 9 deletions(-)
```

Note : `git diff --stat` ne liste que les fichiers suivis. Les deux nouveaux rapports V1-90 apparaissent dans `git status --short --untracked-files=all`.

Commande :

```bash
git diff --name-only
```

Sortie :

```text
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

Commande :

```bash
git status --short --untracked-files=all
```

Sortie :

```text
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_90_cinematic_actor_display_preview_prep_contract.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_90_evidence_pack.md
```

Commande :

```bash
find reports/narrativeStudio/scenes/screenshots -maxdepth 1 -iname '*v1_90*' -print
```

Sortie :

```text
```

Interpretation : aucun screenshot V1-90 n'a ete genere.

Commande :

```bash
rg -n "PlayableMapGame|RuntimeMapGame|GameWidget|FlameGame|CameraComponent|MapLayersComponent|PlayerComponent|OverworldActorComponent|GameState|map_runtime|currentTimeMs|playbackTimeMs|isPlaying|Timer\\(|Ticker|AnimationController|drawActor|renderActor|CharacterSprite|ActorSprite|gpt-image-2|image_generation" reports/narrativeStudio/scenes/ns_scenes_v1_90_cinematic_actor_display_preview_prep_contract.md reports/narrativeStudio/scenes/ns_scenes_v1_90_evidence_pack.md reports/narrativeStudio/scenes/road_map_scenes.md reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md || true
```

Resultat : occurrences documentaires uniquement. Elles apparaissent dans :

```text
reports/narrativeStudio/scenes/ns_scenes_v1_90_evidence_pack.md
reports/narrativeStudio/scenes/ns_scenes_v1_90_cinematic_actor_display_preview_prep_contract.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

Interpretation : les termes runtime/Flame/playback sont presents dans les non-objectifs, l'analyse anti-scope, les hunks de roadmap et l'historique des roadmaps. Aucun fichier source n'est modifie ; `git diff --name-only -- packages` est vide.

## 8. Auto-review critique

1. V1-90 a modifié du code produit ? Non.
2. V1-90 a modifié `packages/` ? Non ; `git diff --name-only -- packages` est vide.
3. V1-90 a créé un test ? Non.
4. V1-90 a généré un screenshot ? Non.
5. V1-90 a rendu un acteur ? Non.
6. V1-90 a rendu un sprite Character Library ? Non.
7. V1-90 a branché le runtime ? Non.
8. V1-90 a importé Flame ? Non.
9. V1-90 a ajouté du playback ? Non.
10. V1-90 a utilisé `GameState` ? Non.
11. V1-90 a ajouté `currentTimeMs`/`playbackTimeMs`/`isPlaying` ? Non.
12. V1-90 a comparé les sources actor bindings ? Oui.
13. V1-90 a cadré player ? Oui.
14. V1-90 a cadré mapEntity ? Oui.
15. V1-90 a cadré cinematicOnly ? Oui.
16. V1-90 a cadré unbound ? Oui.
17. V1-90 a défini la résolution de position ? Oui.
18. V1-90 a défini les fallbacks position ? Oui.
19. V1-90 a défini les fallbacks appearance ? Oui.
20. V1-90 a défini les diagnostics futurs ? Oui.
21. V1-90 a défini les tests V1-91 ? Oui.
22. V1-90 a défini la Visual Gate V1-91 ? Oui.
23. V1-90 a mis à jour les roadmaps ? Oui.
24. Evidence Pack complet ? Oui.
25. Prochain lot exact recommande ? `NS-SCENES-V1-91 — Cinematic Actor Display Preview Read Model V0`.
