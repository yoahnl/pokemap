# NS-SCENES-V1-109 — Evidence Pack

## Verdict

```text
NS-SCENES-V1-109 : DONE documentaire.
Preview Playback : contrat cadré.
Playback Plan : recommandé pour V1-110.
Transport UI : reporté à un lot ultérieur.
ActorMove direct/manual path : cadrés pour playback preview futur.
Runtime / Flame / GameState : non touchés.
Aucun code produit modifié.
Aucun screenshot.
V1-110 recommandé, non démarré.
```

## Gate 0 Complet

Lot exécuté :

```text
NS-SCENES-V1-109 — Cinematic Preview Playback Prep Contract
```

Type :

```text
doc-only / architecture-review / interaction-contract / design-first
```

Interdits respectés :

- pas de playback implementation ;
- pas de transport buttons fonctionnels ;
- pas de Play / Pause / Stop actifs ;
- pas de timer ;
- pas de ticker ;
- pas de `AnimationController` ;
- pas de runtime ;
- pas de Flame ;
- pas de `GameState` ;
- pas de screenshot ;
- pas de Visual Gate ;
- pas de V1-110.

## Règles Lues

```text
AGENTS.md
agent_rules.md
codex_rule.md
skills/README.md
skills/using-superpowers/SKILL.md
skills/verification-before-completion/SKILL.md
```

`codex_rules.md` :

```text
codex_rules.md MISSING
```

## État Git Initial

```bash
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git log --oneline -n 10
```

Sorties :

```text
/Users/karim/Project/pokemonProject
main
```

`git status --short --untracked-files=all` :

```text
Sortie : <vide>
```

`git diff --stat` :

```text
Sortie : <vide>
```

`git diff --name-only` :

```text
Sortie : <vide>
```

`git log --oneline -n 10` :

```text
3ed90377 fix: corrections tests et rapports v1.108
4670f42c update selbrume
caaa7f65 feat: cinematic manual path drawing UI et rapports v1.108
b54e1cd3 docs: ajout rapports v1.107 bis (nettoyage JSON et hardening)
ecb0d64b feat: cinematic manual path core model et tests
550e6364 docs: mise à jour roadmaps et ajout rapports v1.106
73be9440 feat: cinematic builder UX simplification et rapports
d93136a5 refactor: UI cinematic builder workspace et tests
1444a60f update selbrume
50c1bba6 update selbrume
```

## Fichiers Lus

Rapports :

- `reports/narrativeStudio/scenes/ns_scenes_v1_108_cinematic_manual_path_drawing_ui_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_108_evidence_pack.md`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_40_cinematic_runtime_adapter_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_41_cinematic_builder_v0_scope_runtime_playback_contract.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_51_cinematic_timeline_time_axis_bar_layout_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_52_cinematic_timeline_selection_cursor_playhead_placeholder_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_53_cinematic_timeline_transport_controls_placeholder_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_61_cinematic_timeline_mouse_playhead_scrub_prep_contract.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_62_cinematic_timeline_mouse_time_probe_playhead_drag_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_67_cinematic_timeline_duration_editing_resize_prep_contract.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_68_cinematic_timeline_duration_inspector_editing_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_69_cinematic_timeline_duration_resize_handles_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_107_cinematic_manual_path_core_model_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_107_bis_cinematic_manual_path_evidence_json_cleanup_hardening.md`

Code en lecture seule :

- `packages/map_core/lib/src/models/cinematic_asset.dart`
- `packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart`
- `packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart`
- `packages/map_core/lib/src/read_models/cinematic_actor_display_preview_model.dart`
- `packages/map_core/lib/src/read_models/cinematic_timeline_lane_read_model.dart`
- `packages/map_core/lib/src/read_models/cinematic_timeline_time_layout_read_model.dart`
- `packages/map_core/lib/map_core.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_manual_path_preview_overlay.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_stage_point_preview_overlay.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_display_preview_overlay.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_viewport_transform.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`
- `packages/map_runtime/lib/src/application/scene_runtime/scene_cinematic_runtime_awaitable_adapter.dart`
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- `examples/playable_runtime_host` via recherches ciblées.

## Commandes D'Audit Exécutées

```bash
for f in reports/narrativeStudio/scenes/ns_scenes_v1_108_cinematic_manual_path_drawing_ui_v0.md reports/narrativeStudio/scenes/ns_scenes_v1_108_evidence_pack.md reports/narrativeStudio/scenes/road_map_scenes.md reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md reports/narrativeStudio/scenes/ns_scenes_v1_40_cinematic_runtime_adapter_v0.md reports/narrativeStudio/scenes/ns_scenes_v1_41_cinematic_builder_v0_scope_runtime_playback_contract.md reports/narrativeStudio/scenes/ns_scenes_v1_51_cinematic_timeline_time_axis_bar_layout_v0.md reports/narrativeStudio/scenes/ns_scenes_v1_52_cinematic_timeline_selection_cursor_playhead_placeholder_v0.md reports/narrativeStudio/scenes/ns_scenes_v1_53_cinematic_timeline_transport_controls_placeholder_v0.md reports/narrativeStudio/scenes/ns_scenes_v1_61_cinematic_timeline_mouse_playhead_scrub_prep_contract.md reports/narrativeStudio/scenes/ns_scenes_v1_62_cinematic_timeline_mouse_time_probe_playhead_drag_v0.md reports/narrativeStudio/scenes/ns_scenes_v1_67_cinematic_timeline_duration_editing_resize_prep_contract.md reports/narrativeStudio/scenes/ns_scenes_v1_68_cinematic_timeline_duration_inspector_editing_v0.md reports/narrativeStudio/scenes/ns_scenes_v1_69_cinematic_timeline_duration_resize_handles_v0.md reports/narrativeStudio/scenes/ns_scenes_v1_107_cinematic_manual_path_core_model_v0.md reports/narrativeStudio/scenes/ns_scenes_v1_107_bis_cinematic_manual_path_evidence_json_cleanup_hardening.md; do if [ -f "$f" ]; then printf 'FOUND %s\n' "$f"; else printf 'MISSING %s\n' "$f"; fi; done
```

Sortie :

```text
FOUND reports/narrativeStudio/scenes/ns_scenes_v1_108_cinematic_manual_path_drawing_ui_v0.md
FOUND reports/narrativeStudio/scenes/ns_scenes_v1_108_evidence_pack.md
FOUND reports/narrativeStudio/scenes/road_map_scenes.md
FOUND reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
FOUND reports/narrativeStudio/scenes/ns_scenes_v1_40_cinematic_runtime_adapter_v0.md
FOUND reports/narrativeStudio/scenes/ns_scenes_v1_41_cinematic_builder_v0_scope_runtime_playback_contract.md
FOUND reports/narrativeStudio/scenes/ns_scenes_v1_51_cinematic_timeline_time_axis_bar_layout_v0.md
FOUND reports/narrativeStudio/scenes/ns_scenes_v1_52_cinematic_timeline_selection_cursor_playhead_placeholder_v0.md
FOUND reports/narrativeStudio/scenes/ns_scenes_v1_53_cinematic_timeline_transport_controls_placeholder_v0.md
FOUND reports/narrativeStudio/scenes/ns_scenes_v1_61_cinematic_timeline_mouse_playhead_scrub_prep_contract.md
FOUND reports/narrativeStudio/scenes/ns_scenes_v1_62_cinematic_timeline_mouse_time_probe_playhead_drag_v0.md
FOUND reports/narrativeStudio/scenes/ns_scenes_v1_67_cinematic_timeline_duration_editing_resize_prep_contract.md
FOUND reports/narrativeStudio/scenes/ns_scenes_v1_68_cinematic_timeline_duration_inspector_editing_v0.md
FOUND reports/narrativeStudio/scenes/ns_scenes_v1_69_cinematic_timeline_duration_resize_handles_v0.md
FOUND reports/narrativeStudio/scenes/ns_scenes_v1_107_cinematic_manual_path_core_model_v0.md
FOUND reports/narrativeStudio/scenes/ns_scenes_v1_107_bis_cinematic_manual_path_evidence_json_cleanup_hardening.md
```

## Recherches `rg` Utiles

```bash
rg -n "class Cinematic|enum Cinematic|durationMs|manualPath|ManualPath|actorMove|actorFace|fade|camera|timeline|StagePoint|MovementTarget|toJson|fromJson" packages/map_core/lib/src/models/cinematic_asset.dart packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart packages/map_core/lib/src/read_models/cinematic_actor_display_preview_model.dart packages/map_core/lib/src/read_models/cinematic_timeline_lane_read_model.dart packages/map_core/lib/src/read_models/cinematic_timeline_time_layout_read_model.dart packages/map_core/lib/map_core.dart
```

Résultat utile :

- `CinematicTimelineTimeLayoutReadModel` dérive `startMs`, `endMs`, `visualDurationMs`, `durationSource` et `totalDurationMs`.
- `cinematicTimelineFallbackVisualDurationMs = 300`.
- `CinematicStageContext` contient `stagePoints`, `movementTargetBindings`, `initialPlacements`, `manualPaths`.
- `CinematicManualPath` reste owned par `ownerActorMoveStepId`.
- Les opérations d'authoring manual path existent et restent hors scope de V1-109.

```bash
rg -n "Cinematic|playback|Playback|SceneRuntimeExecutor|CinematicRuntimeAdapter|Flame|GameState|PlayableMapGame|AnimationController|Ticker|Timer|Future.delayed" packages/map_runtime examples/playable_runtime_host
```

Résultat utile :

- `SceneCinematicRuntimeAwaitableAdapter` existe côté runtime.
- `SceneCinematicRuntimeNoVisualPlayer` attend une durée via `Future.delayed` puis retourne `completed`.
- `PlayableMapGame` branche cet adapter pour les intents Scene cinematic.
- Ce chemin runtime est no-visual et ne doit pas devenir la preview editor-only.

```bash
rg -n "Selection|selectedStepId|mouse|probe|playhead|Reset|Play|Stop|transport|duration|AnimationController|Ticker|Timer|Future.delayed|CinematicManualPathPreviewOverlay|ManualPath|actorMove|actorFace" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_manual_path_preview_overlay.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_stage_point_preview_overlay.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_display_preview_overlay.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_viewport_transform.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
```

Résultat utile :

- `selectedStepId` est le Selection Cursor logique de l'auteur.
- le Mouse Time Probe existe via `_timelineProbeTimeMs` et ses widgets dédiés.
- les boutons transport existent en placeholders.
- `CinematicManualPathPreviewOverlay` dit explicitement que playback interpolation/pathfinding/runtime movement sont hors scope.

## Décision D'Architecture

Option retenue : **Option C — Plan de playback pur dans `map_core` + état/ticker/rendu dans `map_editor`**.

Options refusées :

- A : Flame / `PlayableMapGame` dans le Builder.
- B : simulation entièrement dans les widgets.
- D : réutilisation de `SceneRuntimeExecutor` / runtime adapter.
- E : aucun playback à terme.
- F : transport actif immédiat sans plan pur.

## Fichiers Modifiés

- `reports/narrativeStudio/scenes/ns_scenes_v1_109_cinematic_preview_playback_prep_contract.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_109_evidence_pack.md`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

## Fichiers Créés

- `reports/narrativeStudio/scenes/ns_scenes_v1_109_cinematic_preview_playback_prep_contract.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_109_evidence_pack.md`

Contenu complet créé :

- Le contenu complet du rapport principal est dans `ns_scenes_v1_109_cinematic_preview_playback_prep_contract.md`.
- Le contenu complet de cet Evidence Pack est ce fichier. Le dupliquer intégralement dans lui-même créerait une récursion documentaire ; l'écart est documenté ici au lieu d'inventer une preuve impossible.

## Tests / Analyse / Build

Tests Dart/Flutter non lancés, volontairement :

```text
Non applicable : V1-109 est doc-only et aucun fichier sous packages/ ou examples/ ne doit être modifié.
```

Analyse Dart/Flutter non lancée, volontairement :

```text
Non applicable : aucun code Dart/Flutter modifié.
```

Build non lancé, volontairement :

```text
Non applicable : aucun package produit modifié ; validation documentaire attendue = git diff --check.
```

## Checks Finaux

```bash
git diff --check
```

Sortie :

```text
Sortie : <vide>
```

```bash
git diff --stat
```

Sortie :

```text
 .../scenes/road_map_scene_builder_authoring.md       | 17 +++++++++++++++--
 reports/narrativeStudio/scenes/road_map_scenes.md    | 20 +++++++++++++++++---
 2 files changed, 32 insertions(+), 5 deletions(-)
```

Note : `git diff --stat` ne liste pas les fichiers non suivis ; les rapports créés apparaissent dans le status final.

```bash
git diff --name-only
```

Sortie :

```text
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

```bash
git status --short --untracked-files=all
```

Sortie :

```text
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_109_cinematic_preview_playback_prep_contract.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_109_evidence_pack.md
```

```bash
git diff --name-only -- packages/map_core packages/map_editor packages/map_runtime packages/map_gameplay packages/map_battle examples/playable_runtime_host
```

Sortie :

```text
Sortie : <vide>
```

```bash
git diff --name-only -- examples/playable_runtime_host/macos/Runner.xcodeproj/project.pbxproj packages/map_editor/macos/Runner.xcodeproj/project.pbxproj
```

Sortie :

```text
Sortie : <vide>
```

```bash
find reports/narrativeStudio/scenes/screenshots -maxdepth 1 -name '*v1_109*' -print
```

Sortie :

```text
Sortie : <vide>
```

## Sub-Agents / Passes Séparées

- Sub-agent Audit / Architecture : valide, Option C retenue.
- Sub-agent Implémentation : valide, docs/roadmaps uniquement.
- Sub-agent Tests : valide, tests non applicables au scope doc-only.
- Sub-agent Build / Validation : valide, `git diff --check` sortie vide.
- Sub-agent Critique finale : valide, anti-scope packages/Xcode/screenshots vide.

## Confirmations Anti-Scope

- aucun package Dart/Flutter modifié ;
- aucun screenshot créé ou modifié ;
- aucun runtime/Flame/playback ajouté ;
- V1-110 non démarré.
