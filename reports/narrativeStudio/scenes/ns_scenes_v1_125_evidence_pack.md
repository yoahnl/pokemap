# NS-SCENES-V1-125 — Evidence Pack

## Verdict

```text
NS-SCENES-V1-125 : DONE documentaire.
Emote Assets / Reaction Bubble : contrat cadré.
Assets racine : audités.
Catalogue V0 : proposé.
actorEmote : cadré.
Assets product path futur : recommandé.
Runtime / Flame / GameState : hors scope.
Aucun code produit modifié.
Aucun asset déplacé/copié.
Aucun screenshot.
V1-126 : recommandé, non démarré.
```

## Gate 0 complet

Commande :

```bash
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git log --oneline -n 10
```

Sortie :

```text
/Users/karim/Project/pokemonProject
main
c5329014 NS-SCENES-V1-124 — Cinematic Camera Preview Playback UI V0
5fd4d2f4 NS-SCENES-V1-123 — Cinematic Camera Playback State Read Model V0
636613af NS-SCENES-V1-122 — Cinematic Camera Preview Playback Prep Contract
d6081a24 NS-SCENES-V1-121 — Cinematic Fade Preview Playback V0
035e3346 ns_scenes_v1_120: add cinematic preview playback scrub seek UI and evidence pack
e87152f2 docs(narrativeStudio): add cinematic preview playback scrub seek prep contract and evidence pack
1706e6d3 feat(narrativeStudio): add cinematic playback preview fallback diagnostics and polish
c1692b7d feat: cinematic actor walking animation renderer and fix actor move destination isolation
f99e235c feat: cinematic actor walking animation frame resolver v1.115
0ed41a86 docs: mise à jour rapports et roadmaps v1.114
```

État dirty initial : `git status --short --untracked-files=all` était vide.

`git diff --stat` initial :

```text
Sortie : <vide>
```

`git diff --name-only` initial :

```text
Sortie : <vide>
```

## Règles lues

Commande :

```bash
ls -lh AGENTS.md agent_rules.md codex_rule.md codex_rules.md skills/README.md skills/using-superpowers/SKILL.md skills/test-driven-development/SKILL.md skills/verification-before-completion/SKILL.md skills/writing-plans/SKILL.md 2>&1
```

Sortie :

```text
ls: codex_rules.md: No such file or directory
-rw-r--r--@ 1 karim  staff    12K Jun  8 23:08 AGENTS.md
-rw-r--r--@ 1 karim  staff   5.2K May  1 04:05 agent_rules.md
-rw-r--r--  1 karim  staff   4.6K Apr 22 16:49 codex_rule.md
-rw-r--r--@ 1 karim  staff   4.4K May 22 19:00 skills/README.md
-rw-r--r--  1 karim  staff   9.6K Apr 28 11:22 skills/test-driven-development/SKILL.md
-rw-r--r--  1 karim  staff   5.3K Apr 28 11:22 skills/using-superpowers/SKILL.md
-rw-r--r--  1 karim  staff   4.1K Apr 28 11:22 skills/verification-before-completion/SKILL.md
-rw-r--r--  1 karim  staff   5.9K Apr 28 11:22 skills/writing-plans/SKILL.md
```

Verdict règles :

- `AGENTS.md` lu.
- `agent_rules.md` lu.
- `codex_rule.md` lu.
- `codex_rules.md` absent.
- Skills demandés lus.

## Fichiers lus

Rapports récents :

- `reports/narrativeStudio/scenes/ns_scenes_v1_116_cinematic_actor_walking_animation_renderer_integration_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_117_cinematic_actor_animation_cadence_playback_status_polish_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_118_cinematic_playback_preview_diagnostics_fallback_detail_polish_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_120_cinematic_preview_playback_scrub_seek_ui_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_121_cinematic_fade_preview_playback_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_123_cinematic_camera_playback_state_read_model_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_124_cinematic_camera_preview_playback_ui_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_124_evidence_pack.md`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

Rapports acteurs/sprites/Stage Points :

- `reports/narrativeStudio/scenes/ns_scenes_v1_91_cinematic_actor_display_preview_model_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_92_cinematic_actor_display_preview_renderer_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_98_cinematic_actor_display_preview_sprite_resolver_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_99_cinematic_actor_display_preview_sprite_renderer_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_100_cinematic_spatial_authoring_stage_points_prep_contract_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_101_cinematic_stage_point_core_model_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_102_cinematic_preview_point_placement_ui_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_103_cinematic_actor_initial_placement_from_stage_points_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_104_cinematic_actor_move_target_from_stage_points_v0.md`

Code/tests en lecture seule :

- `packages/map_core/lib/src/models/cinematic_asset.dart`
- `packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart`
- `packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart`
- `packages/map_core/lib/src/read_models/cinematic_preview_playback_plan.dart`
- `packages/map_core/lib/src/read_models/cinematic_timeline_time_layout_read_model.dart`
- `packages/map_core/lib/src/read_models/cinematic_actor_display_preview_model.dart`
- `packages/map_core/lib/map_core.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_camera_preview_overlay.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_fade_preview_overlay.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_display_preview_overlay.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_preview_playback_actor_overlay_adapter.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_manual_path_preview_overlay.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_stage_point_preview_overlay.dart`
- `packages/map_core/test/cinematic_preview_playback_plan_test.dart`
- `packages/map_editor/test/cinematic_builder_workspace_test.dart`
- `packages/map_editor/test/cinematics_library_workspace_test.dart`
- `packages/map_editor/test/cinematic_stage_point_preview_overlay_test.dart`

## Preuves assets emote

Commande :

```bash
ls -lh /Users/karim/Project/pokemonProject/emotions.png /Users/karim/Project/pokemonProject/emotions2.png
file /Users/karim/Project/pokemonProject/emotions.png /Users/karim/Project/pokemonProject/emotions2.png
shasum -a 256 /Users/karim/Project/pokemonProject/emotions.png /Users/karim/Project/pokemonProject/emotions2.png
sips -g pixelWidth -g pixelHeight /Users/karim/Project/pokemonProject/emotions.png /Users/karim/Project/pokemonProject/emotions2.png
```

Sortie :

```text
-rw-r--r--@ 1 karim  staff   849B Jun 14 12:59 /Users/karim/Project/pokemonProject/emotions.png
-rw-r--r--@ 1 karim  staff   1.9K Jun 14 12:59 /Users/karim/Project/pokemonProject/emotions2.png
/Users/karim/Project/pokemonProject/emotions.png:  PNG image data, 128 x 48, 8-bit colormap, non-interlaced
/Users/karim/Project/pokemonProject/emotions2.png: PNG image data, 128 x 48, 8-bit colormap, non-interlaced
09b9627648f16012042610ec159b95167e84559c6b4ae0fef09eb834d283ac9f  /Users/karim/Project/pokemonProject/emotions.png
f337639b596d145b306d3300b5f8144bc9387f329fd9fda743accfccb03643b0  /Users/karim/Project/pokemonProject/emotions2.png
/Users/karim/Project/pokemonProject/emotions.png
  pixelWidth: 128
  pixelHeight: 48
/Users/karim/Project/pokemonProject/emotions2.png
  pixelWidth: 128
  pixelHeight: 48
```

Commande :

```bash
git ls-files -- emotions.png emotions2.png
find /Users/karim/Project/pokemonProject -maxdepth 4 \( -name 'emotions.png' -o -name 'emotions2.png' \) -print
```

Sortie :

```text
emotions.png
emotions2.png
/Users/karim/Project/pokemonProject/pokémon_sdk_test_project/graphics/particles/emotions2.png
/Users/karim/Project/pokemonProject/pokémon_sdk_test_project/graphics/particles/emotions.png
/Users/karim/Project/pokemonProject/emotions2.png
/Users/karim/Project/pokemonProject/emotions.png
```

Interprétation :

- Les deux assets racine sont suivis par Git.
- Des copies existent dans `pokémon_sdk_test_project/graphics/particles/`, mais V1-125 n’a déplacé ni copié aucun asset.
- Dimensions prouvées : `128 x 48`.
- Hypothèse forte : `8 x 3` cellules de `16 x 16`, soit `24 slots`.

## Recherches rg utiles

Commande :

```bash
rg -n "actorEmote" packages/map_core/lib/src/models/cinematic_asset.dart packages/map_core/lib/src/read_models/cinematic_preview_playback_plan.dart packages/map_core/lib/src/read_models/cinematic_timeline_lane_read_model.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
```

Sortie :

```text
packages/map_core/lib/src/read_models/cinematic_timeline_lane_read_model.dart:296:    CinematicTimelineStepKind.actorEmote =>
packages/map_core/lib/src/read_models/cinematic_timeline_lane_read_model.dart:383:    CinematicTimelineStepKind.actorEmote =>
packages/map_core/lib/src/read_models/cinematic_preview_playback_plan.dart:666:      case CinematicTimelineStepKind.actorEmote:
packages/map_core/lib/src/read_models/cinematic_preview_playback_plan.dart:800:      case CinematicTimelineStepKind.actorEmote:
packages/map_core/lib/src/read_models/cinematic_preview_playback_plan.dart:1127:    CinematicTimelineStepKind.actorEmote ||
packages/map_core/lib/src/models/cinematic_asset.dart:8:  actorEmote,
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:11990:    CinematicTimelineStepKind.actorEmote => 'Émotion acteur',
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:12499:    CinematicTimelineStepKind.actorEmote => CupertinoIcons.person_crop_circle,
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:12560:    CinematicTimelineStepKind.actorEmote =>
```

Commande :

```bash
rg -n "actorPoses|fadeState|cameraPose|frameAt" packages/map_core/lib/src/read_models/cinematic_preview_playback_plan.dart | sed -n '1,80p'
```

Sortie :

```text
435:    required List<CinematicActorPlaybackPose> actorPoses,
436:    this.fadeState,
437:    CinematicCameraPlaybackPose? cameraPose,
440:        actorPoses = List<CinematicActorPlaybackPose>.unmodifiable(actorPoses),
441:        cameraPose =
442:            cameraPose ?? const CinematicCameraPlaybackPose.inactive(),
451:  final List<CinematicActorPlaybackPose> actorPoses;
452:  final CinematicFadePlaybackState? fadeState;
453:  final CinematicCameraPlaybackPose cameraPose;
458:    for (final pose in actorPoses) {
473:          _listEquals(other.actorPoses, actorPoses) &&
474:          other.fadeState == fadeState &&
475:          other.cameraPose == cameraPose &&
483:        Object.hashAll(actorPoses),
484:        fadeState,
485:        cameraPose,
536:  CinematicPreviewPlaybackFrame frameAt(int timeMs) =>
742:  CinematicFadePlaybackState? fadeState;
743:  var cameraPose = const CinematicCameraPlaybackPose.inactive();
784:            fadeState = _fadeStateFor(
793:          cameraPose = _cameraPoseFor(
815:    actorPoses: posesByActorId.values.toList(),
816:    fadeState: fadeState,
817:    cameraPose: cameraPose,
1072:CinematicFadePlaybackState _fadeStateFor({
1090:CinematicCameraPlaybackPose _cameraPoseFor({
```

Commande :

```bash
rg -n "assets:|CinematicTilesetAssetRegistry|rootBundle|ImageProvider|ui\.Image|tilesetsDirectoryPath|getTilesetRelativePath" packages/map_editor/lib/src packages/map_core/lib/src packages/map_editor/pubspec.yaml packages/map_runtime/pubspec.yaml examples/playable_runtime_host/pubspec.yaml | sed -n '1,100p'
```

Sortie :

```text
packages/map_runtime/pubspec.yaml:44:  assets:
packages/map_editor/lib/src/infrastructure/filesystem/project_filesystem.dart:17:  String get tilesetsDirectoryPath =>
packages/map_editor/lib/src/infrastructure/filesystem/project_filesystem.dart:45:  String getTilesetRelativePath(String fileName) {
packages/map_editor/lib/src/infrastructure/filesystem/project_filesystem.dart:173:    final destinationDir = Directory(tilesetsDirectoryPath);
packages/map_editor/lib/src/infrastructure/filesystem/project_filesystem.dart:179:    var destinationPath = p.join(tilesetsDirectoryPath, fileName);
packages/map_editor/lib/src/infrastructure/filesystem/project_filesystem.dart:183:      destinationPath = p.join(tilesetsDirectoryPath, fileName);
packages/map_editor/lib/src/infrastructure/filesystem/project_filesystem.dart:188:    return getTilesetRelativePath(fileName);
packages/map_editor/lib/src/ui/widgets/element_collision_triple_mask_editor.dart:60:  final ui.Image image;
packages/map_editor/lib/src/ui/widgets/element_collision_triple_mask_editor.dart:136:        await widget.image.toByteData(format: ui.ImageByteFormat.rawRgba);
packages/map_editor/lib/src/ui/widgets/element_collision_triple_mask_editor.dart:781:  final ui.Image image;
packages/map_editor/lib/src/application/collision_generation/placed_element_auto_collision_generator.dart:78:        await image.toByteData(format: ui.ImageByteFormat.rawRgba);
packages/map_editor/lib/src/ui/canvas/entity_editor_element_visual.dart:23:  final ui.Image image;
packages/map_editor/lib/src/ui/canvas/entity_editor_element_visual.dart:68:  required ui.Image image,
packages/map_editor/lib/src/ui/canvas/entity_editor_element_visual.dart:96:  required ui.Image image,
packages/map_editor/lib/src/ui/canvas/entity_editor_element_visual.dart:179:  required Map<String, ui.Image?> tilesetImagesById,
packages/map_editor/lib/src/ui/canvas/entity_editor_element_visual.dart:228:  required Map<String, ui.Image?> tilesetImagesById,
packages/map_editor/lib/src/application/seeds/pokemon_moves_bootstrap_seed.dart:18:/// - le bootstrap n'a donc ni dépendance `rootBundle`, ni dépendance réseau ;
packages/map_editor/lib/src/ui/canvas/map_canvas/map_canvas_assets.dart:20:  static final Map<String, Future<ui.Image?>> _cache = {};
packages/map_editor/lib/src/ui/canvas/map_canvas/map_canvas_assets.dart:22:  static Future<ui.Image?> load(
packages/map_editor/lib/src/ui/canvas/map_canvas/map_canvas_assets.dart:54:  static Future<Map<String, ui.Image?>> loadMany(
packages/map_editor/lib/src/ui/canvas/map_canvas/map_canvas_assets.dart:58:    final futures = <Future<MapEntry<String, ui.Image?>>>[];
packages/map_editor/lib/src/ui/canvas/map_canvas/map_canvas_assets.dart:68:      final result = <String, ui.Image?>{};
packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart:194:  final Map<String, ui.Image?> tilesetImagesById;
packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart:873:    ui.Image image,
packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart:1908:    ui.Image image,
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_tile_render_plan.dart:50:    required ui.Image image,
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_tile_render_plan.dart:109:  final ui.Image? image;
packages/map_editor/lib/src/ui/canvas/tileset_editor_canvas.dart:87:    return FutureBuilder<ui.Image?>(
packages/map_editor/lib/src/ui/canvas/tileset_editor_canvas.dart:689:  final ui.Image image;
packages/map_editor/lib/src/ui/canvas/tileset_editor_canvas.dart:766:  static final Map<String, Future<ui.Image?>> _cache = {};
packages/map_editor/lib/src/ui/canvas/tileset_editor_canvas.dart:768:  static Future<ui.Image?> load(String? path) {
packages/map_editor/lib/src/ui/canvas/map_canvas.dart:66:  Future<Map<String, ui.Image?>>? _tilesetImagesFuture;
packages/map_editor/lib/src/ui/canvas/map_canvas.dart:184:    return FutureBuilder<Map<String, ui.Image?>>(
packages/map_editor/lib/src/ui/canvas/map_canvas.dart:187:        final tilesetImagesById = snapshot.data ?? const <String, ui.Image?>{};
packages/map_editor/lib/src/ui/panels/character_library_panel.dart:24:  static final Map<String, Future<ui.Image?>> _cache = {};
packages/map_editor/lib/src/ui/panels/character_library_panel.dart:26:  static Future<ui.Image?> load(String? path) {
packages/map_editor/lib/src/ui/panels/character_library_panel.dart:46:  final ui.Image image;
packages/map_editor/lib/src/ui/panels/character_library_panel.dart:106:  final ui.Image image;
packages/map_editor/lib/src/ui/panels/character_library_panel.dart:148:  final ui.Image? image;
packages/map_editor/lib/src/ui/panels/character_library_panel.dart:497:    return FutureBuilder<ui.Image?>(
packages/map_editor/lib/src/ui/panels/character_library_panel.dart:608:    ui.Image image,
packages/map_editor/lib/src/ui/panels/character_library_panel.dart:663:    ui.Image? image,
packages/map_editor/lib/src/ui/panels/tileset_palette/dialogs/element_frame_picker_dialog.dart:8:  required ui.Image image,
packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/collision/element_collision_profile_painter.dart:19:  final ui.Image image;
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_layer_plan_loader.dart:10:    CinematicTilesetAssetRegistry? registry,
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_layer_plan_loader.dart:11:  }) : _registry = registry ?? CinematicTilesetAssetRegistry();
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_layer_plan_loader.dart:13:  final CinematicTilesetAssetRegistry _registry;
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_tileset_asset_registry.dart:9:final class CinematicTilesetAssetRegistry {
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_tileset_asset_registry.dart:10:  CinematicTilesetAssetRegistry();
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_tile_plan_loader.dart:12:    CinematicTilesetAssetRegistry? registry,
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_tile_plan_loader.dart:13:  }) : _registry = registry ?? CinematicTilesetAssetRegistry();
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_tile_plan_loader.dart:15:  final CinematicTilesetAssetRegistry _registry;
```

Commande :

```bash
find assets -maxdepth 3 -type d -print 2>&1
find packages/map_editor -maxdepth 3 \( -type d -name assets -o -path 'packages/map_editor/assets*' \) -print | sort
```

Sortie :

```text
find: assets: No such file or directory
```

La deuxième commande `find packages/map_editor ...` n’a produit aucune ligne.

## Options comparées

- Option A : chargement direct depuis la racine. Refusée.
- Option B : intégration future dans un dossier officiel. Retenue pour le futur, pas exécutée en V1-125.
- Option C : catalogue typé atlas + frame rects. Retenue.
- Option D : enum seul. Partiellement acceptable comme aide interne, insuffisant comme contrat principal.
- Option E : choix libre par frame. Refusée.
- Option F : séparer Emote et FX. Retenue.

Décision finale :

```text
Option B future + Option C + Option F
```

## Justification du pivot roadmap

Pivot accepté :

- V1-124 fournit déjà une caméra V0 symbolique suffisante pour avancer.
- Les emotes apportent une valeur visuelle immédiate.
- Les assets candidats existent déjà.
- Le système emote est plus démonstratif pour le Builder à ce stade.
- Camera Target / Zoom reste en backlog sous `NS-SCENES-V1-129 — Cinematic Camera Target / Zoom Authoring Prep Contract`.

Prochain lot recommandé :

```text
NS-SCENES-V1-126 — Cinematic Emote Core Model / Asset Catalog V0
```

## Fichiers modifiés

- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

## Fichiers créés

- `reports/narrativeStudio/scenes/ns_scenes_v1_125_cinematic_emote_assets_reaction_bubble_prep_contract_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_125_evidence_pack.md`

Code généré : aucun.

## Diffs / zones précises modifiées

`reports/narrativeStudio/scenes/road_map_scenes.md` :

- ajout du lot V1-125 DONE ;
- ajout de V1-129 Camera Target / Zoom en BACKLOG ;
- header global du prochain lot aligné vers V1-126 ;
- ordre récent après V1-102 mis à jour ;
- nouvelle section `Mise a jour V1-125` ;
- section V1-124 ajustée pour signaler le report caméra.

`reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md` :

- header global du prochain lot aligné vers V1-126 ;
- note de pivot V1-125 ;
- lignes V1-125 à V1-129 ajoutées dans la table authoring ;
- nouvelle section `Mise a jour V1-125` ;
- section V1-124 ajustée pour signaler le report caméra.

## Tests et analyses

Tests Dart/Flutter non lancés : V1-125 est documentaire et aucun fichier sous `packages/`, `examples/`, `assets`, `selbrume` ou `pubspec.yaml` n’a été modifié.

## Checks finaux

Commande :

```bash
git diff --check
git diff --stat
git diff --name-only
git status --short --untracked-files=all
```

Sortie `git diff --check` :

```text
Sortie : <vide>
```

Sortie `git diff --stat` :

```text
 .../scenes/road_map_scene_builder_authoring.md     | 53 +++++++++++++-------
 reports/narrativeStudio/scenes/road_map_scenes.md  | 56 +++++++++++++++-------
 2 files changed, 74 insertions(+), 35 deletions(-)
```

Sortie `git diff --name-only` :

```text
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

Sortie `git status --short --untracked-files=all` :

```text
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_125_cinematic_emote_assets_reaction_bubble_prep_contract_v0.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_125_evidence_pack.md
```

Note : les fichiers créés sont non indexés ; `git diff --stat` ne liste donc que les roadmaps modifiées.

## Checks anti-scope

Commande :

```bash
git diff --name-only -- packages/map_core packages/map_editor packages/map_runtime packages/map_gameplay packages/map_battle examples/playable_runtime_host assets selbrume pubspec.yaml
find reports/narrativeStudio/scenes/screenshots -maxdepth 1 -name '*v1_125*' -print
find reports/narrativeStudio/scenes/screenshots -maxdepth 1 -name '*v1_126*' -print
```

Sortie :

```text
Sortie : <vide>
```

Commande de contrôle roadmap :

```bash
rg -n "NS-SCENES-V1-125 — Cinematic Camera Target / Zoom Authoring Prep Contract" reports/narrativeStudio/scenes/road_map_scenes.md reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md || true
```

Sortie :

```text
Sortie : <vide>
```

## Confirmations

- Aucun package Dart/Flutter modifié.
- Aucun asset déplacé ou copié.
- Aucun `pubspec.yaml` modifié.
- Aucun screenshot créé.
- Aucun runtime ajouté.
- Aucun Flame ajouté.
- Aucun GameState ajouté.
- V1-126 non démarré.

## Risques

- Certaines cellules de l’atlas principal restent ambiguës sans validation visuelle produit.
- `emotions2.png` semble être un atlas de fallback/base plus qu’un catalogue complet.
- Le chemin `assets/cinematics/emotes/` est recommandé mais non créé.
- Le choix actor-only peut être insuffisant si le besoin immédiat devient une emote sur repère/objet.

## Auto-critique

La décision de ne pas coder est respectée. Le contrat est suffisamment précis pour démarrer V1-126 sans refaire un bis documentaire. L’incertitude principale reste la sémantique exacte de quelques frames ; elle doit être traitée par des tests et une validation de catalogue au moment de V1-126.
