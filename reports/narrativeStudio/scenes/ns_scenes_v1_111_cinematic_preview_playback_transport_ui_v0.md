# NS-SCENES-V1-111 — Cinematic Preview Playback Transport UI V0

## 1. Résumé exécutif

V1-111 est implémenté : les contrôles transport du Cinematic Builder sont actifs côté éditeur, consomment le `CinematicPreviewPlaybackPlan` V1-110, et restent locaux au widget. Play/Pause/Stop/Reset pilotent un temps de preview local, un Playback Playhead `Lecture` apparaît dans la timeline, et les statuts no-code distinguent la lecture (`Lecture en cours`) de la capacité du plan (`Prévisualisation partielle`).

Le lot ne démarre pas V1-112 : aucun acteur n'est déplacé par playback dans la preview, aucun scrubber/seek timeline n'est ajouté, aucun runtime/Flame/GameState n'est touché.

## 2. Gate 0

Prompt audité : `/Users/karim/.codex/attachments/6d424ac5-6f22-40a3-b262-d40eff0ec93b/pasted-text.txt`.

Règles lues :

- `AGENTS.md`
- `agent_rules.md`
- `codex_rule.md`
- `codex_rules.md` : absent, sortie exacte `MISSING codex_rules.md`

État git initial capturé :

```text
/Users/karim/Project/pokemonProject
main
git status --short --untracked-files=all : <vide>
git diff --stat : <vide>
git diff --name-only : <vide>
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

Interprétation : V1-111 est cohérent avec V1-110. Aucune remise en cause bloquante du prompt. Ajustement mineur documenté : `cinematic_preview_playback_transport.dart` n'a pas été créé, car les helpers privés de géométrie timeline existaient déjà dans `cinematic_builder_workspace.dart`.

## 3. Fichiers lus

Rapports/roadmaps : V1-109, V1-110, roadmaps scènes et authoring, rapports timeline/transport/probe V1-51/V1-52/V1-53/V1-61/V1-62/V1-64/V1-65/V1-66.

Core : `cinematic_preview_playback_plan.dart`, `cinematic_timeline_time_layout_read_model.dart`, `cinematic_actor_display_preview_model.dart`, `cinematic_asset.dart`, `map_core.dart`, tests core associés.

Editor : `cinematic_builder_workspace.dart`, overlays preview/path/actor, backdrop panel/transform, library workspace, canvas narrative, tests builder/library/stage overlay.

## 4. Rappel V1-110

V1-110 expose un plan pur côté `map_core` : `CinematicPreviewPlaybackPlan`, `CinematicPreviewPlaybackFrame`, `CinematicActorPlaybackPose`, `buildCinematicPreviewPlaybackPlan(...)`, `evaluateCinematicPreviewPlaybackFrame(...)`, `plan.frameAt(timeMs)`. V1-111 consomme ces API et ne recalcule pas localement l'interpolation actorMove.

## 5. Décision UI transport

Les anciens placeholders sont remplacés par des boutons design-system :

- Reset : revient à `0 ms` sans lancer.
- Play : démarre la lecture locale.
- Pause : remplace Play pendant la lecture.
- Stop : stoppe et revient à `0 ms`.

Les contrôles conservent les clés existantes `cinematic-builder-transport-*-button` et ajoutent tooltips/semantics no-code.

## 6. État local playback

Ajout local dans `_CinematicBuilderWorkspaceState` :

- `_playbackController`
- `_playbackTimelineSignature`
- `_isPlaybackPlaying`

Le temps affiché vient de `_playbackController.value * playbackPlan.totalDurationMs`, clampé par le plan. La signature timeline déclenche un reset local quand la timeline change structurellement.

## 7. Ticker local editor-only

Le ticker utilise `AnimationController` avec `SingleTickerProviderStateMixin`, créé en `initState` et disposé en `dispose`. Aucun `Timer.periodic`, `Future.delayed` loop, `Stream.periodic`, runtime ticker, Flame ou game loop n'est ajouté.

## 8. Consommation de CinematicPreviewPlaybackPlan

`build` construit :

```dart
final playbackPlan = buildCinematicPreviewPlaybackPlan(
  cinematic: widget.asset,
  actorDisplayPreviewModel: widget.actorDisplayPreviewModel,
);
final playbackFrame = playbackPlan.frameAt(playbackTimeMs);
```

L'UI consomme `totalDurationMs`, `frameAt(...)`, `visibleDiagnostics` et `capabilities` pour le temps et les statuts.

## 9. Comportement Play/Pause/Stop/Reset

Tests V1-111 couvrent :

- timeline avec blocs : Reset/Play actifs, Stop inactif à `0 ms`;
- timeline vide : tous contrôles inactifs et `Aucun bloc à lire`;
- Play avance le temps;
- Pause conserve le temps;
- Stop revient à `0 ms`;
- Reset revient à `0 ms` sans lancer;
- fin de lecture à `3 s / 3 s` avec `Fin de prévisualisation`.

## 10. Playback Playhead timeline

Ajout de `_TimelinePlaybackPlayhead`, rendu au-dessus de la grille temporelle via la même géométrie que les ticks/barres. Clé : `cinematic-builder-playback-playhead`. Libellé visible : `Lecture`.

## 11. Séparation Selection / Probe / Playback

La sélection auteur reste distincte du Playback Playhead. Le Mouse Time Probe reste distinct et ne pilote pas `playbackTimeMs`. Sélectionner un bloc pendant la lecture met la lecture en pause et conserve la sélection demandée.

## 12. Diagnostics/capabilities affichés

Le badge principal affiche l'état de transport. Un badge de capacité apparaît pendant lecture/pause si nécessaire : `Prévisualisation partielle` ou `Prévisualisation prête`. Aucun message principal n'expose `activeStepIds`, `frameAt`, `GameState`, `Flame` ou `runtime`.

## 13. Changements réalisés

- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`
  - `_CinematicBuilderWorkspaceState` passe à `SingleTickerProviderStateMixin`.
  - Transport local Play/Pause/Stop/Reset ajouté.
  - Playback Playhead distinct ajouté à la timeline.
  - Footer timeline rendu responsive pour éviter les overflows.
  - Texte sandbox retiré de la mention visible `runtime`.
- `packages/map_editor/test/cinematic_builder_workspace_test.dart`
  - Tests V1-111 ajoutés.
  - Tests historiques alignés avec le nouveau playhead `Lecture`.
  - Visual Gate V1-111 ajoutée.
- `packages/map_editor/test/cinematics_library_workspace_test.dart`
  - Attente transport mise à jour : Reset/Play actifs, Stop inactif au temps zéro.
- Roadmaps scènes mises à jour vers V1-112.
- Visual Gate PNG créée.

## 14. Changements refusés / hors scope

Refusés et non implémentés : actor overlay playback, interpolation visuelle des acteurs, animation de marche, scrubber, seek par clic timeline, drag playhead, runtime cinematic playback, Flame, `PlayableMapGame`, `GameState`, pathfinding, collision, persistance `playbackTimeMs`, mutation `ProjectManifest`, `CinematicAsset` ou `MapData`.

## 15. Tests ajoutés/modifiés

Ajoutés :

- `V1-111 initializes transport from playback plan and handles empty timeline`
- `V1-111 plays pauses stops and resets local playback time`
- `V1-111 keeps playback playhead separate from selection probe and editing`
- `captures V1-111 cinematic preview playback transport UI when requested`

Modifiés :

- tests historiques de transport placeholder remplacés par présence/état réel;
- test Library réel tileset mis à jour pour le transport actif.

Phase TDD RED : le ciblé `--name "V1-111"` a d'abord échoué sur boutons désactivés, absence `Lecture en cours` et absence `cinematic-builder-playback-playhead`. La phase GREEN passe après implémentation.

## 16. Tests exécutés

```bash
cd packages/map_core && dart test --reporter=compact test/cinematic_preview_playback_plan_test.dart
```

Résultat :

```text
00:01 +12: All tests passed!
```

```bash
cd packages/map_core && dart test --reporter=compact test/cinematic_timeline_time_layout_read_model_test.dart
```

Résultat :

```text
00:00 +4: All tests passed!
```

```bash
cd packages/map_core && dart test --reporter=compact test/cinematic_actor_display_preview_model_test.dart
```

Résultat :

```text
00:00 +27: All tests passed!
```

```bash
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-111"
```

Résultat :

```text
00:05 +4: All tests passed!
```

```bash
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart
```

Résultat contrôlé depuis le log :

```text
00:33 +211: All tests passed!
EXIT_STATUS=0
LOG_LINES=457
```

```bash
cd packages/map_editor && flutter test --reporter=compact test/cinematics_library_workspace_test.dart test/cinematic_stage_point_preview_overlay_test.dart
```

Résultat :

```text
00:07 +26: All tests passed!
```

## 17. Analyse statique

```bash
cd packages/map_core && dart analyze
```

Résultat :

```text
Analyzing map_core...
No issues found!
```

```bash
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart test/cinematic_builder_workspace_test.dart test/cinematics_library_workspace_test.dart
```

Résultat :

```text
Analyzing 5 items...
37 issues found. (ran in 7.6s)
```

Sortie 0. Les 37 issues sont des infos `prefer_const_*` non fatales sous `--no-fatal-infos`, dont plusieurs préexistantes autour de widgets/fixtures hors logique V1-111.

Build complet : non lancé. Le prompt précise qu'un build complet n'est pas obligatoire si les tests widget et l'analyse ciblée passent. Validation alternative effectuée : tests widget complets ciblés + analyse ciblée.

## 18. Visual Gate

Capture :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_111_cinematic_preview_playback_transport_ui_v0.png
```

Preuve :

```text
-rw-r--r--  1 karim  staff   189K Jun 12 16:10 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_111_cinematic_preview_playback_transport_ui_v0.png
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_111_cinematic_preview_playback_transport_ui_v0.png: PNG image data, 1663 x 926, 8-bit/color RGBA, non-interlaced
2bb8db8e7679576d49d6fa62f4688f2e12482024712f48de5214eeca7afafcba  reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_111_cinematic_preview_playback_transport_ui_v0.png
```

Vérification visuelle locale : Cinematic Builder ouvert, timeline visible, transports actifs, temps `1.2 s / 3 s`, `Lecture en cours`, `Prévisualisation partielle`, Playback Playhead `Lecture`, Selection Cursor distinct, preview visible, aucun label `runtime`/`Flame`/`GameState` visible.

## 19. Checks anti-scope

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

Ces occurrences `manualPathId` sont les appels existants de gestion des chemins manuels V1-108 (`add/remove/reorderCinematicManualPathWaypoint`), pas un stockage `manualPathId` ajouté côté actorMove par V1-111.

## 20. Roadmaps mises à jour

- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

Les deux pointent vers `NS-SCENES-V1-112 — Cinematic ActorMove Preview Playback V0`.

## 21. git diff final

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

## 22. Risques restants

- Le Playback Playhead est prouvé dans la timeline, mais les acteurs ne bougent pas encore : c'est volontairement V1-112.
- L'inspecteur conserve des champs techniques historiques pour certains blocs ; V1-111 a retiré les libellés interdits du transport/sandbox, pas refondu tout l'inspecteur.
- L'analyse ciblée garde 37 infos `prefer_const_*` non fatales.

## 23. Auto-critique

Ce qui est vraiment utilisable : lecture locale, pause, stop, reset, temps courant, playhead distinct, status no-code.

Ce qui reste limité : la preview centrale ne consomme pas encore les poses acteurs pour déplacer les sprites/placeholders.

Séparation Selection / Probe / Playback : prouvée par test, mais visuellement dense. Le label `Lecture` est utile et prioritaire.

Ticker local : propre et testable via `WidgetTester.pump`; reset sur changement de timeline.

Diagnostics : compréhensibles pour V1-111 (`Lecture en cours`, `Prévisualisation partielle`), mais les diagnostics détaillés de blocs restent perfectibles.

Visual Gate : prouve le transport et le playhead en cours de lecture, pas le futur déplacement d'acteur.

V1-112 peut brancher l'actor overlay sans refaire la logique de transport, car le plan/frame sont déjà produits dans le Builder.

Bis recommandé : non, sauf si Karim veut polir l'inspecteur technique avant de brancher l'actor playback.

## 24. Verdict final

`NS-SCENES-V1-111 : DONE.`

Transport UI : actif dans le Cinematic Builder.

Playback local : editor-only.

Playback Playhead : visible dans la timeline.

Plan V1-110 : consommé, pas recodé.

Actor overlay playback : non démarré.

Runtime / Flame / GameState : non touchés.

Aucun scrubber actif.

Aucun playback runtime.

## 25. Prochain lot recommandé

`NS-SCENES-V1-112 — Cinematic ActorMove Preview Playback V0`
