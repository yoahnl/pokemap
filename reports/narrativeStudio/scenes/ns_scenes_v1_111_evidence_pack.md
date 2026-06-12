# NS-SCENES-V1-111 — Evidence Pack

## Gate 0 complet

Lot exécuté : `NS-SCENES-V1-111 — Cinematic Preview Playback Transport UI V0`.

Repo : `/Users/karim/Project/pokemonProject`.

Règles lues :

- `AGENTS.md`
- `agent_rules.md`
- `codex_rule.md`
- `codex_rules.md` absent.

Sortie exacte absence :

```text
MISSING codex_rules.md
```

État git initial :

```text
pwd
/Users/karim/Project/pokemonProject

git branch --show-current
main

git status --short --untracked-files=all
Sortie : <vide>

git diff --stat
Sortie : <vide>

git diff --name-only
Sortie : <vide>

git log --oneline -n 10
3411ae0b feat: cinematic preview playback plan read model v1.110
8cf3b6f6 docs: préparation contrat preview/playback cinematic v1.109
3ed90377 fix: corrections tests et rapports v1.108
4670f42c update selbrume
caaa7f65 feat: cinematic manual path drawing UI et rapports v1.108
b54e1cd3 docs: ajout rapports v1.107 bis (nettoyage JSON et hardening)
ecb0d64b feat: cinematic manual path core model et tests
550e6364 docs: mise à jour roadmaps et ajout rapports v1.106
73be9440 feat: cinematic builder UX simplification et tests
d93136a5 refactor: UI cinematic builder workspace et tests
```

## Sub-agents / passes

- Sub-agent Audit / Architecture : PASS. V1-111 consomme V1-110 côté editor et ne nécessite pas de modification `map_core`.
- Sub-agent Implémentation : PASS. Transport local, playhead, statuts et reset timeline ajoutés dans le Builder.
- Sub-agent Tests : PASS. RED initial observé puis ciblé V1-111, suite Builder, suites Library/Stage et régressions core passent.
- Sub-agent Build / Validation : PASS avec limite. Build complet non lancé car non obligatoire dans le prompt ; tests widget + analyse ciblée ont été exécutés.
- Sub-agent Critique finale : PASS avec réserves. L'actor overlay playback reste volontairement absent ; l'inspecteur conserve des champs techniques historiques hors scope.

## Fichiers lus

Fichiers/règles :

- `AGENTS.md`
- `agent_rules.md`
- `codex_rule.md`
- prompt V1-111 attaché

Rapports/roadmaps :

- `reports/narrativeStudio/scenes/ns_scenes_v1_109_cinematic_preview_playback_prep_contract.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_109_evidence_pack.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_110_cinematic_preview_playback_plan_read_model_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_110_evidence_pack.md`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

Fichiers code/tests :

- `packages/map_core/lib/src/read_models/cinematic_preview_playback_plan.dart`
- `packages/map_core/lib/src/read_models/cinematic_timeline_time_layout_read_model.dart`
- `packages/map_core/lib/src/read_models/cinematic_actor_display_preview_model.dart`
- `packages/map_core/lib/src/models/cinematic_asset.dart`
- `packages/map_core/lib/map_core.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_manual_path_preview_overlay.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_display_preview_overlay.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_viewport_transform.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`
- tests core/editor demandés.

## Fichiers modifiés

- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`
- `packages/map_editor/test/cinematic_builder_workspace_test.dart`
- `packages/map_editor/test/cinematics_library_workspace_test.dart`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

## Fichiers créés

- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_111_cinematic_preview_playback_transport_ui_v0.png`
- `reports/narrativeStudio/scenes/ns_scenes_v1_111_cinematic_preview_playback_transport_ui_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_111_evidence_pack.md`

## Hunks pertinents

`cinematic_builder_workspace.dart` :

- `_CinematicBuilderWorkspaceState` utilise `SingleTickerProviderStateMixin`.
- Ajout de `_playbackController`, `_playbackTimelineSignature`, `_isPlaybackPlaying`.
- Ajout de `_togglePlayback`, `_stopPlayback`, `_resetPlayback`, `_playbackTimeMs`.
- Construction de `CinematicPreviewPlaybackPlan` et `playbackFrame` dans `build`.
- Pause de lecture lors de la sélection d'un bloc.
- `_TimelinePlaceholder` reçoit le plan, la frame, le temps et les callbacks transport.
- `_TimelineTimeGrid` affiche `_TimelinePlaybackPlayhead`.
- `_TimelinePlaybackTransportControls` remplace le placeholder.
- Footer responsive pour éviter les overflows.
- Texte sandbox visible ne contient plus `runtime`.

`cinematic_builder_workspace_test.dart` :

- Tests V1-111 ajoutés pour initialisation, lecture/pause/stop/reset, playhead, sélection/probe, non-mutation et Visual Gate.
- Les anciens tests qui attendaient des transports désactivés sont réalignés sur la présence/activité V1-111.

`cinematics_library_workspace_test.dart` :

- Test real tile backdrop aligné : Reset/Play actifs, Stop inactif au temps zéro.

Roadmaps :

- V1-111 marqué DONE.
- Prochain lot exact : `NS-SCENES-V1-112 — Cinematic ActorMove Preview Playback V0`.

## Sorties exactes tests core

```bash
cd packages/map_core && dart test --reporter=compact test/cinematic_preview_playback_plan_test.dart
```

```text
00:01 +12: All tests passed!
```

```bash
cd packages/map_core && dart test --reporter=compact test/cinematic_timeline_time_layout_read_model_test.dart
```

```text
00:00 +4: All tests passed!
```

```bash
cd packages/map_core && dart test --reporter=compact test/cinematic_actor_display_preview_model_test.dart
```

```text
00:00 +27: All tests passed!
```

```bash
cd packages/map_core && dart analyze
```

```text
Analyzing map_core...
No issues found!
```

## Sorties exactes tests editor

```bash
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-111"
```

```text
00:05 +4: All tests passed!
```

```bash
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart
```

Commande exécutée avec capture de log et conversion CR/LF pour obtenir une sortie terminal exploitable :

```text
00:33 +208: V1-108 — Cinematic Manual Path Drawing UI V0
00:33 +209: V1-108 — Cinematic Manual Path Drawing UI V0
00:33 +209: V1-108 — manual mode reuses an existing path owned by a direct actorMove
00:33 +210: V1-108 — manual mode reuses an existing path owned by a direct actorMove
00:33 +210: captures V1-108 cinematic manual path drawing ui visual gate when requested
00:33 +211: captures V1-108 cinematic manual path drawing ui visual gate when requested
00:33 +211: All tests passed!

EXIT_STATUS=0
LOG_LINES=     457
```

```bash
cd packages/map_editor && flutter test --reporter=compact test/cinematics_library_workspace_test.dart test/cinematic_stage_point_preview_overlay_test.dart
```

```text
00:07 +26: All tests passed!
```

## Sortie exacte analyse editor

```bash
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart test/cinematic_builder_workspace_test.dart test/cinematics_library_workspace_test.dart
```

```text
Analyzing 5 items...
37 issues found. (ran in 7.6s)
```

Exit code : 0. Issues : infos `prefer_const_*` non fatales.

`cinematic_preview_playback_transport.dart` retiré de la commande car non créé.

## Build

Build complet non lancé. Justification : le prompt indique qu'un build complet n'est pas obligatoire si les tests widget et l'analyse ciblée passent. Validation alternative effectuée : tests core/editor ciblés et suite Builder complète.

## Visual Gate

Commande :

```bash
cd packages/map_editor && flutter test --update-goldens --reporter=compact --dart-define=NS_SCENES_V1_111_CAPTURE_CINEMATIC_PREVIEW_PLAYBACK_TRANSPORT_UI=true test/cinematic_builder_workspace_test.dart --name "captures V1-111 cinematic preview playback transport UI when requested"
```

Résultat :

```text
00:03 +1: All tests passed!
```

Preuve fichier :

```text
-rw-r--r--  1 karim  staff   189K Jun 12 16:10 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_111_cinematic_preview_playback_transport_ui_v0.png
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_111_cinematic_preview_playback_transport_ui_v0.png: PNG image data, 1663 x 926, 8-bit/color RGBA, non-interlaced
2bb8db8e7679576d49d6fa62f4688f2e12482024712f48de5214eeca7afafcba  reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_111_cinematic_preview_playback_transport_ui_v0.png
```

## Incident corrigé

Pendant les commandes de validation, des fichiers suivis `.dart_tool` de `packages/map_gameplay` sont apparus supprimés alors qu'ils sont hors scope. Ils ont été restaurés depuis `HEAD` via `git show` sans commande Git d'écriture. Ils ne figurent plus dans le diff final.

## Checks anti-scope

```bash
git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle examples/playable_runtime_host
```

```text
Sortie : <vide>
```

```bash
git diff --name-only -- examples/playable_runtime_host/macos/Runner.xcodeproj/project.pbxproj packages/map_editor/macos/Runner.xcodeproj/project.pbxproj
```

```text
Sortie : <vide>
```

```bash
find reports/narrativeStudio/scenes/screenshots -maxdepth 1 -name '*v1_112*' -print
```

```text
Sortie : <vide>
```

```bash
rg -n "Timer\\.periodic|Future\\.delayed|Stream\\.periodic|DateTime\\.now|Flame|GameState|PlayableMapGame|manualPathId|Scrubber|Seek|scrubber|seek|V1-112" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart || true
```

```text
919:        manualPathId: path.id,
937:        manualPathId: path.id,
956:        manualPathId: path.id,
```

Ces occurrences appartiennent aux opérations de chemins manuels existantes V1-108 et ne correspondent pas à un `manualPathId` ajouté côté actorMove par V1-111.

## Git final

```bash
git diff --check
```

```text
Sortie : <vide>
```

```bash
git diff --stat
```

```text
 .../cinematics/cinematic_builder_workspace.dart    |  1164 +-
 .../test/cinematic_builder_workspace_test.dart     | 13886 ++++++++++---------
 .../test/cinematics_library_workspace_test.dart    |    28 +-
 .../scenes/road_map_scene_builder_authoring.md     |    17 +-
 reports/narrativeStudio/scenes/road_map_scenes.md  |    20 +-
 5 files changed, 7875 insertions(+), 7240 deletions(-)
```

```bash
git diff --name-only
```

```text
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
packages/map_editor/test/cinematics_library_workspace_test.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

```bash
git status --short --untracked-files=all
```

```text
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
 M packages/map_editor/test/cinematic_builder_workspace_test.dart
 M packages/map_editor/test/cinematics_library_workspace_test.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_111_cinematic_preview_playback_transport_ui_v0.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_111_evidence_pack.md
?? reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_111_cinematic_preview_playback_transport_ui_v0.png
```

## Confirmations

- Aucun fichier sous `packages/map_runtime` modifié.
- Aucun fichier sous `packages/map_gameplay` modifié au diff final attendu.
- Aucun fichier sous `packages/map_battle` modifié.
- Aucun fichier sous `examples/playable_runtime_host` modifié.
- Aucun fichier Xcode modifié.
- Aucun playback runtime / Flame / GameState ajouté.
- Aucun scrubber/seek ajouté.
- `manualPathId` côté actorMove non ajouté.
- Waypoints libres/coordonnées libres non ajoutés.
- V1-112 non démarré.
