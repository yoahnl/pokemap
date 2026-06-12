# NS-SCENES-V1-110 — Cinematic Preview Playback Plan Read Model V0

## 1. Résumé Exécutif

`NS-SCENES-V1-110` implémente le read model pur demandé par V1-109 : un plan de playback preview dans `map_core`, sans UI, sans ticker, sans runtime et sans Flame.

Le nouveau contrat public expose :

- `CinematicPreviewPlaybackPlan` ;
- `CinematicPreviewPlaybackFrame` ;
- `CinematicActorPlaybackPose` ;
- `buildCinematicPreviewPlaybackPlan(...)` ;
- `evaluateCinematicPreviewPlaybackFrame(...)` et `plan.frameAt(timeMs)`.

Le plan s'appuie sur `CinematicTimelineTimeLayoutReadModel` comme source de vérité temporelle. Il dérive les items de timeline, clamp les frames, évalue les poses acteurs, supporte `wait`, `actorFace`, `actorMove` direct, `actorMove` manual path, fade V0 et caméra placeholder unsupported.

Verdict :

```text
NS-SCENES-V1-110 : DONE.
Playback Plan : implémenté dans map_core.
Frames déterministes : disponibles.
actorMove direct/manual path : supportés côté plan pur.
Transport UI : non démarré.
Ticker : absent.
Runtime / Flame / GameState : non touchés.
Aucun map_editor.
Aucun screenshot.
V1-111 recommandé, non démarré.
```

## 2. Gate 0

Mission :

```text
Implémenter dans map_core un read model pur, déterministe et testable du futur playback preview cinématique.
```

Scope autorisé respecté :

- `packages/map_core/lib/src/read_models/cinematic_preview_playback_plan.dart` créé ;
- `packages/map_core/lib/map_core.dart` modifié pour l'export public ;
- `packages/map_core/test/cinematic_preview_playback_plan_test.dart` créé ;
- roadmaps scènes mises à jour ;
- rapports V1-110 créés.

Anti-scope respecté :

- pas de `map_editor` ;
- pas de `map_runtime` ;
- pas de `map_gameplay` ;
- pas de `map_battle` ;
- pas de `examples/playable_runtime_host` ;
- pas de transport UI ;
- pas de Play/Pause/Stop/Reset actif ;
- pas de `Timer`, `Ticker`, `AnimationController`, `Future.delayed` ;
- pas de Flutter, `dart:ui`, Widget, BuildContext, Material, CustomPainter ;
- pas de Flame, GameState, PlayableMapGame ;
- pas de screenshot / Visual Gate ;
- pas de V1-111.

## 3. Fichiers Lus

Règles :

- `AGENTS.md`
- `agent_rules.md`
- `codex_rule.md`
- `codex_rules.md` : absent dans le repo au moment de l'audit.

Skills utilisés :

- `skills/using-superpowers/SKILL.md`
- `skills/test-driven-development/SKILL.md`
- `/Users/karim/.codex/skills/dart-add-unit-test/SKILL.md`
- `skills/verification-before-completion/SKILL.md`

Rapports demandés :

- `reports/narrativeStudio/scenes/ns_scenes_v1_108_cinematic_manual_path_drawing_ui_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_108_evidence_pack.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_109_cinematic_preview_playback_prep_contract.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_109_evidence_pack.md`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`
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

Code lu :

- `packages/map_core/lib/src/models/cinematic_asset.dart`
- `packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart`
- `packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart`
- `packages/map_core/lib/src/read_models/cinematic_actor_display_preview_model.dart`
- `packages/map_core/lib/src/read_models/cinematic_timeline_lane_read_model.dart`
- `packages/map_core/lib/src/read_models/cinematic_timeline_time_layout_read_model.dart`
- `packages/map_core/lib/map_core.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_manual_path_preview_overlay.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_display_preview_overlay.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_viewport_transform.dart`

Tests lus :

- `packages/map_core/test/cinematic_asset_test.dart`
- `packages/map_core/test/cinematic_authoring_operations_test.dart`
- `packages/map_core/test/cinematic_diagnostics_test.dart`
- `packages/map_core/test/cinematic_actor_display_preview_model_test.dart`
- `packages/map_core/test/cinematic_timeline_lane_read_model_test.dart`
- `packages/map_core/test/cinematic_timeline_time_layout_read_model_test.dart`

## 4. Rappel V1-109

V1-109 a retenu :

```text
Option C — Plan de playback pur dans map_core
+ état local / ticker / rendu dans map_editor plus tard.
```

V1-110 suit cette décision : la logique temporelle est dans `map_core`, mais aucun état local de lecture editor, aucun ticker et aucun rendu de playback ne sont ajoutés.

## 5. Décision De Modèle

Le modèle est un read model immutable et synchrone. Il ne persiste aucun `startMs`, `endMs`, `currentTimeMs`, `isPlaying` ou état de transport dans `CinematicAsset`.

Décisions principales :

- les temps sont dérivés depuis `CinematicTimelineTimeLayoutReadModel` ;
- `frameAt(timeMs)` clamp `timeMs` dans `[0, totalDurationMs]` ;
- un step est actif si `startMs <= timeMs < endMs` ;
- à `timeMs == totalDurationMs`, les poses restent stables et aucun step n'est actif ;
- les coordonnées sont des `double`, jamais des `Offset` ;
- les diagnostics affichent des messages no-code, sans ID technique dans le message principal ;
- les IDs restent disponibles dans les champs techniques `stepId` / `actorId`.

## 6. Modèles Ajoutés

Fichier créé :

```text
packages/map_core/lib/src/read_models/cinematic_preview_playback_plan.dart
```

Inventaire public :

```text
10: enum CinematicPreviewPlaybackDiagnosticSeverity
16: enum CinematicPreviewPlaybackDiagnosticCode
32: enum CinematicActorPlaybackPoseSource
41: enum CinematicPreviewPlaybackPointSource
48: enum CinematicFadePlaybackMode
55: final class CinematicPreviewPlaybackDiagnostic
100: final class CinematicPreviewPlaybackCapabilities
144: final class CinematicPreviewPlaybackPoint
171: final class CinematicActorPlaybackPose
243: final class CinematicPreviewActorTrack
276: final class CinematicPreviewPlaybackTimelineItem
355: final class CinematicFadePlaybackState
379: final class CinematicCameraPlaybackPose
400: final class CinematicPreviewPlaybackFrame
459: final class CinematicPreviewPlaybackPlan
503: buildCinematicPreviewPlaybackPlan(...)
693: evaluateCinematicPreviewPlaybackFrame(...)
```

Inventaire privé utile :

```text
1276: final class _ActorMovePlaybackPlan
1293: final class _RouteSegment
1306: final class _RouteInterpolation
```

Empreinte du fichier créé :

```text
dbd29e6079230cb5231275a6ab3203d667a0b86416321904e872bb37abf8412f  packages/map_core/lib/src/read_models/cinematic_preview_playback_plan.dart
```

## 7. Fonction De Construction Du Plan

`buildCinematicPreviewPlaybackPlan(...)` construit :

- `cinematicId` ;
- `totalDurationMs` ;
- `timelineItems` ;
- `actorTracks` ;
- diagnostics de plan ;
- capabilities.

La fonction accepte :

- `required CinematicAsset cinematic` ;
- `CinematicActorDisplayPreviewModel? actorDisplayPreviewModel` ;
- `Map<String, CinematicPreviewPlaybackPoint> resolvedMovementTargets = const {}`.

Elle ne lit pas le disque, ne dépend pas du runtime, ne modifie pas l'asset et ne produit pas de side effect.

## 8. Fonction D'Évaluation De Frame

`evaluateCinematicPreviewPlaybackFrame(plan, timeMs: ...)` et `plan.frameAt(timeMs)` :

- clampent le temps ;
- listent les `activeStepIds` ;
- retournent les poses d'acteurs ;
- exposent un `fadeState` si un fade est actif ;
- exposent une `cameraPose` unsupported si une caméra est active ;
- retournent les diagnostics visibles du plan.

La fonction est pure : deux appels avec le même plan et le même temps retournent des valeurs égales.

## 9. Source De Vérité Temporelle

Le plan s'appuie sur `buildCinematicTimelineTimeLayoutReadModel(cinematic)` :

- `durationMs` explicite si valide ;
- fallback existant `cinematicTimelineFallbackVisualDurationMs = 300` ;
- `startMs` / `endMs` dérivés ;
- `totalDurationMs` dérivé ;
- aucune écriture dans `CinematicAsset`.

## 10. Résolution Des Poses Initiales

Ordre de résolution :

1. `CinematicActorDisplayPreviewModel` si fourni et résolu ;
2. `CinematicStageContext.initialPlacements` ;
3. repère `stagePoint` ou cible de déplacement liée à un repère ;
4. `resolvedMovementTargets` ;
5. diagnostic `cinematicPreviewPlaybackActorInitialPoseMissing`.

Le plan n'invente pas de fallback `(0, 0)`.

## 11. actorMove Direct

Pour un `actorMove` direct :

- départ = pose acteur au début du step ;
- destination = `targetId` résolu depuis `movementTargetBindings` ou `resolvedMovementTargets` ;
- interpolation linéaire ;
- facing = axe dominant du segment ;
- diagnostic si acteur ou destination introuvable.

Hors scope conservé :

- pathfinding ;
- collision ;
- vérité runtime ;
- animation de marche frame-by-frame.

## 12. actorMove Manual Path

Pour un `actorMove` manuel :

```text
départ -> waypoint(s) -> destination finale
```

Règles appliquées :

- les waypoints viennent de `CinematicManualPath.waypointStagePointIds` ;
- la destination finale reste séparée dans `actorMove.targetId` ;
- la destination n'est pas insérée dans `waypointStagePointIds` ;
- les segments sont pondérés par leur longueur ;
- les segments de longueur zéro sont ignorés si un segment positif existe ;
- si tout le chemin est de longueur zéro, la pose reste stable et un warning `cinematicPreviewPlaybackManualPathZeroLength` est produit.

## 13. actorFace

`actorFace` applique la direction dès le début du step. La facing persiste ensuite pendant les `wait` suivants et peut être remplacée par un `actorMove` ou un autre `actorFace`.

## 14. wait / fade / camera

`wait` :

- ne change aucune pose ;
- contribue à la durée totale.

`fade` :

- produit un `CinematicFadePlaybackState` ;
- supporte `fadeIn` et `fadeOut` ;
- retourne un diagnostic si le mode est inconnu.

`camera` :

- reste un placeholder ;
- produit `CinematicCameraPlaybackPose(supported: false)` ;
- produit un diagnostic `cinematicPreviewPlaybackCameraUnsupported` ;
- ne modifie aucun viewport editor.

## 15. Diagnostics Ajoutés

Codes ajoutés dans le read model playback :

```text
cinematicPreviewPlaybackUnsupportedStep
cinematicPreviewPlaybackActorMissing
cinematicPreviewPlaybackActorInitialPoseMissing
cinematicPreviewPlaybackMoveDestinationMissing
cinematicPreviewPlaybackManualPathMissing
cinematicPreviewPlaybackManualPathPointMissing
cinematicPreviewPlaybackManualPathZeroLength
cinematicPreviewPlaybackZeroDurationStep
cinematicPreviewPlaybackTimelineEmpty
cinematicPreviewPlaybackStageContextMissing
cinematicPreviewPlaybackMapUnavailable
cinematicPreviewPlaybackCameraUnsupported
cinematicPreviewPlaybackFadeUnsupported
```

Les messages UX principaux restent no-code, par exemple :

```text
Ce bloc n'est pas encore prévisualisé.
Impossible de prévisualiser ce bloc : l'acteur est introuvable.
Cet acteur n'a pas de position de départ.
Impossible de prévisualiser ce déplacement : la destination est introuvable.
Ce déplacement manuel n'a pas de trajet à lire.
Ce trajet manuel utilise un repère manquant.
La cinématique ne contient aucun bloc à lire.
La caméra de ce bloc sera cadrée dans un lot suivant.
```

## 16. Capabilities

`CinematicPreviewPlaybackCapabilities` expose :

- `supportsActorMoveDirect` ;
- `supportsActorMoveManualPath` ;
- `supportsActorFace` ;
- `supportsWait` ;
- `supportsFade` ;
- `supportsCamera` ;
- `hasUnsupportedSteps`.

En V0, `supportsCamera` vaut `false`.

## 17. Exports Publics

`packages/map_core/lib/map_core.dart` exporte :

```dart
export 'src/read_models/cinematic_preview_playback_plan.dart';
```

## 18. Tests Ajoutés / Modifiés

Fichier créé :

```text
packages/map_core/test/cinematic_preview_playback_plan_test.dart
```

Inventaire des tests :

```text
empty cinematic produces an empty plan and timeline diagnostic
derives timeline items and clamps frame time deterministically
uses actor display preview position before stageContext placement
reports missing initial pose without fake zero fallback
actorFace changes facing and wait preserves the pose
direct actorMove interpolates linearly and reaches destination
direct actorMove missing destination produces diagnostic
manual actorMove interpolates through waypoints by distance
manual actorMove reports missing path and missing waypoint
manual actorMove with all zero-length segments stays deterministic
fade returns fade state and camera remains an unsupported placeholder
unsupported steps produce no-code diagnostics
```

Empreinte du fichier créé :

```text
1aabb7a606582ce18c25333da7b182888c327fca5c01665a3a4f847870e3c8bf  packages/map_core/test/cinematic_preview_playback_plan_test.dart
```

## 19. Tests Exécutés

Commande :

```bash
cd packages/map_core
dart test --reporter=compact test/cinematic_preview_playback_plan_test.dart
```

Sortie finale stable :

```text
00:00 +12: All tests passed!
```

Commandes ciblées :

```bash
dart test --reporter=compact test/cinematic_timeline_time_layout_read_model_test.dart
dart test --reporter=compact test/cinematic_actor_display_preview_model_test.dart
dart test --reporter=compact test/cinematic_asset_test.dart
dart test --reporter=compact test/cinematic_authoring_operations_test.dart
dart test --reporter=compact test/cinematic_diagnostics_test.dart
```

Sorties finales stables :

```text
test/cinematic_timeline_time_layout_read_model_test.dart : 00:00 +4: All tests passed!
test/cinematic_actor_display_preview_model_test.dart : 00:00 +27: All tests passed!
test/cinematic_asset_test.dart : 00:00 +21: All tests passed!
test/cinematic_authoring_operations_test.dart : 00:00 +67: All tests passed!
test/cinematic_diagnostics_test.dart : 00:00 +53: All tests passed!
```

Suite complète :

```bash
dart test --reporter=compact
```

Sortie finale stable :

```text
00:05 +2496: All tests passed!
```

## 20. Analyse Statique

Commande :

```bash
cd packages/map_core
dart analyze
```

Sortie exacte :

```text
Analyzing map_core...
No issues found!
```

Build complet :

```text
Non applicable : map_core est un package Dart pur sans build applicatif. Validation alternative exécutée : dart analyze + dart test complet du package.
```

## 21. Checks Anti-Scope

Commande :

```bash
rg -n "Flutter|dart:ui|Material|Widget|BuildContext|Flame|GameState|PlayableMapGame|Timer|Ticker|AnimationController|Future\.delayed|Stream|DateTime\.now|CustomPainter" packages/map_core/lib/src/read_models/cinematic_preview_playback_plan.dart packages/map_core/test/cinematic_preview_playback_plan_test.dart
```

Sortie :

```text
Sortie : <vide>
```

Les checks git anti-scope finaux sont dans l'Evidence Pack et confirment :

- aucun `map_editor` modifié ;
- aucun runtime/gameplay/battle/example modifié ;
- aucun projet Xcode modifié ;
- aucun screenshot V1-110 créé.

## 22. Roadmaps Mises À Jour

- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

V1-110 est marqué DONE. Le prochain lot recommandé est :

```text
NS-SCENES-V1-111 — Cinematic Preview Playback Transport UI V0
```

## 23. Git Final

`git diff --check` :

```text
Sortie : <vide>
```

`git diff --stat` :

```text
 packages/map_core/lib/map_core.dart                  |  1 +
 .../scenes/road_map_scene_builder_authoring.md       | 17 +++++++++++++++--
 reports/narrativeStudio/scenes/road_map_scenes.md    | 20 +++++++++++++++++---
 3 files changed, 33 insertions(+), 5 deletions(-)
```

Note : `git diff --stat` et `git diff --name-only` ne listent pas les fichiers non suivis. Les fichiers créés apparaissent dans `git status --short --untracked-files=all`.

`git diff --name-only` :

```text
packages/map_core/lib/map_core.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

`git status --short --untracked-files=all` :

```text
 M packages/map_core/lib/map_core.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? packages/map_core/lib/src/read_models/cinematic_preview_playback_plan.dart
?? packages/map_core/test/cinematic_preview_playback_plan_test.dart
?? reports/narrativeStudio/scenes/ns_scenes_v1_110_cinematic_preview_playback_plan_read_model_v0.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_110_evidence_pack.md
```

## 24. Sub-Agents / Passes Séparées

Sub-agent Audit / Architecture :

```text
PASS — V1-110 est cohérent avec V1-109. Le scope map_core pur est valide. Aucun conflit bloquant avec le repo.
```

Sub-agent Implémentation :

```text
PASS — Le plan pur est isolé dans un nouveau read model, exporté par map_core, sans dépendance UI/runtime.
```

Sub-agent Tests :

```text
PASS — Test dédié V1-110 +12, tests ciblés existants verts, suite complète map_core +2496.
```

Sub-agent Build / Validation :

```text
PASS — dart analyze sans issue, anti-scope textuel vide, aucun dossier runtime/editor modifié.
```

Sub-agent Critique finale :

```text
PASS avec limites — La caméra reste volontairement unsupported, fade reste V0, et le plan ne garantit pas la vérité runtime. Ces limites sont documentées.
```

## 25. Risques Restants

- La consommation UI V1-111 devra choisir comment représenter `visibleDiagnostics` sans confondre diagnostics permanents et diagnostics actifs.
- `fade` est volontairement simple ; si un futur modèle de fade devient plus riche, le read model devra suivre.
- La caméra est un placeholder unsupported ; V1-110 ne tente pas de cadrer le viewport editor.
- L'interpolation actorMove est editor-only et ne promet ni pathfinding ni collision.

## 26. Auto-Critique

Solide :

- source temporelle dérivée unique ;
- pas de fallback silencieux `(0, 0)` ;
- manual path borné par les repères existants ;
- tests positifs, négatifs et garde-fous ;
- package `map_core` complet vert.

Potentiellement ambitieux pour un V0 :

- `CinematicPreviewPlaybackPlan` contient déjà fade/camera placeholder/capabilities ; c'est utile pour V1-111, mais cela devra rester lisible côté UI.

Découpage :

- V1-111 reste pertinent pour connecter les contrôles transport à un état local editor-only ;
- aucun bis n'est recommandé avant V1-111, sauf si l'UI révèle un besoin d'affiner `visibleDiagnostics`.

## 27. Verdict Final

```text
NS-SCENES-V1-110 : DONE.
Playback Plan : implémenté dans map_core.
Frames déterministes : disponibles.
actorMove direct/manual path : supportés côté plan pur.
Transport UI : non démarré.
Ticker : absent.
Runtime / Flame / GameState : non touchés.
Aucun map_editor.
Aucun screenshot.
V1-111 recommandé, non démarré.
```

## 28. Prochain Lot Recommandé

```text
NS-SCENES-V1-111 — Cinematic Preview Playback Transport UI V0
```
