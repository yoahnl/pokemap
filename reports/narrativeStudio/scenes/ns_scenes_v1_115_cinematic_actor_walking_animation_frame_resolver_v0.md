# NS-SCENES-V1-115 — Cinematic Actor Walking Animation Frame Resolver V0

## 1. Résumé exécutif

V1-115 implémente le resolver editor-only demandé pour choisir symboliquement une frame `idle | walk | run | fallback` pendant le playback preview du Cinematic Builder.

Le lot reste strictement resolver-only :

```text
Renderer integration : non démarrée.
Overlay/widget : non modifiés.
Runtime / Flame / GameState : non touchés.
Aucun screenshot.
```

Le prochain lot recommandé devient :

```text
NS-SCENES-V1-116 — Cinematic Actor Walking Animation Renderer Integration V0
```

## 2. Gate 0

Commande :

```bash
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git log --oneline -n 10
```

Sortie initiale :

```text
/Users/karim/Project/pokemonProject
main
<git status --short --untracked-files=all vide>
<git diff --stat vide>
<git diff --name-only vide>
a6b197c0 docs: préparation contrat animation marche acteur cinematic v1.114
2dff3a1e feat: cinematic actor playback smooth motion v1.113
d41f7f22 feat: cinematic actor move preview playback v1.112
e41f5874 update selbrume
e9972298 Add cinematic preview transport UI
3411ae0b feat: cinematic preview playback plan read model v1.110
8cf3b6f6 docs: préparation contrat preview/playback cinematic v1.109
3ed90377 fix: corrections tests et rapports v1.108
4670f42c update selbrume
caaa7f65 feat: cinematic manual path drawing UI et rapports v1.108
```

## 3. Fichiers lus

Règles :

```text
AGENTS.md
agent_rules.md
codex_rule.md
skills/README.md
skills/using-superpowers/SKILL.md
skills/test-driven-development/SKILL.md
skills/writing-plans/SKILL.md
skills/verification-before-completion/SKILL.md
```

Rapports / roadmaps :

```text
reports/narrativeStudio/scenes/ns_scenes_v1_114_cinematic_actor_walking_animation_prep_contract.md
reports/narrativeStudio/scenes/ns_scenes_v1_114_evidence_pack.md
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/ns_scenes_v1_97_cinematic_actor_display_preview_sprite_resolver_prep_contract.md
reports/narrativeStudio/scenes/ns_scenes_v1_98_cinematic_actor_display_preview_sprite_resolver_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_99_cinematic_actor_display_preview_sprite_renderer_v0.md
```

Code et tests audités :

```text
packages/map_core/lib/src/read_models/cinematic_actor_display_preview_model.dart
packages/map_core/lib/src/read_models/cinematic_preview_playback_plan.dart
packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart
packages/map_core/lib/src/models/cinematic_asset.dart
packages/map_core/lib/src/models/project_manifest.dart
packages/map_core/lib/src/models/enums.dart
packages/map_core/lib/map_core.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_sprite_preview_plan.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_sprite_preview_resolver.dart
packages/map_editor/test/cinematic_actor_sprite_preview_resolver_test.dart
packages/map_editor/test/cinematic_actor_sprite_preview_renderer_test.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
packages/map_core/test/cinematic_preview_playback_plan_test.dart
packages/map_core/test/cinematic_actor_display_preview_model_test.dart
```

## 4. Rappel V1-114

V1-114 a retenu `Option B + F` : resolver editor-only séparé, cadence time-based, sans runtime/Flame/GameState, puis intégration renderer repoussée à V1-116.

## 5. Décision d'architecture

Décision : créer un fichier dédié `cinematic_actor_walking_animation_preview_resolver.dart` dans `map_editor`, n'important que `package:map_core/map_core.dart`.

Remise en cause mineure du prompt : la signature indicative proposait `CinematicActorSpritePreviewActor? spriteActor`, mais ce type vit dans un fichier editor qui importe Flutter. Pour respecter l'anti-scope "resolver n'importe pas Flutter", le resolver V1-115 n'importe pas ce plan sprite et se base sur `CinematicActorDisplayPreviewActor.appearance/renderHint` plus `ProjectCharacterEntry`.

## 6. Modèles créés

```text
CinematicActorWalkingAnimationPreviewKind : idle, walk, run, fallback
CinematicActorWalkingAnimationFallbackReason : none, actorNotRenderable, missingSprite, missingCharacter, missingAnimation, missingDirection, emptyFrames, invalidFrame, stationary, missingPlaybackPose
CinematicActorWalkingAnimationPreviewDiagnosticSeverity : info, warning, error
CinematicActorWalkingAnimationPreviewDiagnosticCode : walkingAnimationMissing, walkingAnimationDirectionMissing, walkingAnimationFrameMissing, walkingAnimationSourceRectInvalid, walkingAnimationNoSprite, walkingAnimationCharacterMissing, walkingAnimationPoseMissing, walkingAnimationFallbackToIdle, walkingAnimationUnsupportedActorKind
CinematicActorWalkingAnimationPreviewDiagnostic
CinematicActorWalkingAnimationPreviewFrame
```

## 7. Fonction resolver

Fonction créée :

```dart
CinematicActorWalkingAnimationPreviewFrame
    resolveCinematicActorWalkingAnimationPreviewFrame({
  required CinematicActorDisplayPreviewActor actor,
  required CinematicPreviewPlaybackFrame? playbackFrame,
  required int playbackTimeMs,
  required bool isPlaybackPlaying,
  required List<CinematicTimelineStep> timelineSteps,
  required ProjectCharacterEntry? character,
})
```

`isPlaybackPlaying` est volontairement non utilisé pour forcer idle : une pause conserve la frame correspondant au temps figé.

## 8. Détection moving/stationary

Moving si :

```text
actorPose existe
actorPose.hasPosition == true
actorPose.isInterpolated == true
actorPose.activeStepId != null
```

Sinon stationary.

## 9. Lecture movementMode

Le resolver retrouve le step actif par `activeStepId`, puis utilise `cinematicTimelineActorMovementModeOf(step)`.

```text
run => CharacterAnimationState.run
walk ou inconnu => CharacterAnimationState.walk
```

## 10. Direction/facing

Priorité :

```text
actorPose.facing
actor.direction
fallback direction disponible
fallback placeholder
```

Les mappings `north/south/east/west` sont testés.

## 11. Choix idle/walk/run/fallback

Ordre en mouvement run :

```text
run directionnelle
walk directionnelle
run autre direction
walk autre direction
idle directionnelle
idle autre direction
placeholder
```

Ordre en mouvement walk :

```text
walk directionnelle
walk autre direction
idle directionnelle
idle autre direction
placeholder
```

Stationary :

```text
idle directionnelle
idle autre direction
placeholder
```

## 12. Cadence de frame

Règles implémentées :

```text
durationMs > 0 => durée de la frame
run duration invalide => 90 ms
walk/idle/fallback duration invalide => 140 ms
playbackTimeMs négatif => clamp 0
cycleDurationMs = somme des durées positives ou fallback
frameIndex déterministe par playbackTimeMs
```

## 13. Fallbacks et diagnostics

Fallbacks testés :

```text
pose playback manquante
pose sans position
run absent -> walk
walk absent -> idle
idle absent -> placeholder
frames vides
source rect invalide
personnage absent
sprite non prêt
direction manquante
```

Les messages restent no-code et n'exposent pas `sourceRect`, `tilesetId`, JSON ou payload comme workflow principal.

## 14. Relation avec le resolver sprite existant

`cinematic_actor_sprite_preview_resolver.dart` reste inchangé et idle-only. V1-115 crée un resolver walking séparé pour préserver le contrat V1-98/V1-99 et éviter de transformer le resolver statique en moteur d'animation.

## 15. Non-objectifs confirmés

```text
Pas d'intégration renderer.
Pas de widget.
Pas d'overlay.
Pas de screenshot.
Pas de Visual Gate.
Pas de runtime.
Pas de Flame.
Pas de GameState.
Pas de chargement d'image.
Pas de cadence distance-based.
Pas de mutation ProjectManifest/CinematicAsset/MapData.
```

## 16. Hygiène de diff

```text
Format ciblé uniquement sur les deux nouveaux fichiers Dart.
Pas de format global.
Pas de fichier renderer/overlay/widget modifié.
Roadmaps modifiées uniquement dans les sections scènes nécessaires.
```

## 17. Tests ajoutés/modifiés

Créé :

```text
packages/map_editor/test/cinematic_actor_walking_animation_preview_resolver_test.dart
```

Couverture :

```text
moving/stationary
pose manquante / pose sans position
walk/run + fallback run -> walk
priorité walk directionnelle avant run hors direction
directions north/south/east/west
direction manquante et unknown facing
cadence durationMs/cycle/durée invalide/pause stable
single frame
missing walk/idle/character/sprite
empty frames
invalid source rect
déterminisme et non-mutation
```

## 18. Tests exécutés

RED ciblé :

```text
flutter test --reporter=compact test/cinematic_actor_walking_animation_preview_resolver_test.dart
Résultat : échec attendu, fichier resolver absent, méthode/types introuvables.
```

RED priorité run/walk :

```text
flutter test --reporter=compact test/cinematic_actor_walking_animation_preview_resolver_test.dart --name "run mode selects run"
Résultat : échec attendu, kind run obtenu au lieu de walk.
```

GREEN final :

```text
flutter test --reporter=compact test/cinematic_actor_walking_animation_preview_resolver_test.dart
Résultat : +9, All tests passed!
```

Régressions map_editor :

```text
flutter test --reporter=compact test/cinematic_actor_sprite_preview_renderer_test.dart
Résultat : +21, All tests passed!

flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-113"
Résultat : +5, All tests passed!
```

Régressions map_core :

```text
dart test --reporter=compact test/cinematic_preview_playback_plan_test.dart
Résultat : +12, All tests passed!

dart test --reporter=compact test/cinematic_actor_display_preview_model_test.dart
Résultat : +27, All tests passed!
```

## 19. Analyse statique

```text
flutter analyze --no-fatal-infos lib/src/ui/canvas/cinematics/cinematic_actor_walking_animation_preview_resolver.dart test/cinematic_actor_walking_animation_preview_resolver_test.dart
Analyzing 2 items...
No issues found! (ran in 3.4s)

dart analyze
Analyzing map_core...
No issues found!
```

## 20. Build non lancé ou justification

Build complet non lancé : V1-115 ne modifie aucun widget, renderer, app shell, runtime ou intégration visuelle. La validation adaptée est la suite de tests ciblés, l'analyse ciblée et les checks anti-scope.

## 21. Checks anti-scope

Commandes :

```bash
rg -n "dart:ui|package:flutter|package:flame|GameState|PlayableMapGame|SceneRuntimeExecutor|CinematicRuntimeAdapter|map_runtime|map_gameplay|Timer\\.periodic|Future\\.delayed|Stream\\.periodic|DateTime\\.now" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_walking_animation_preview_resolver.dart || true
rg -n "lerp|lerpDouble|sqrt|hypot|RouteSegment|manualPath.*segment|segment.*manualPath|waypoint.*distance|distance.*waypoint|pathfinding|collision" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_walking_animation_preview_resolver.dart || true
git diff --name-only -- packages/map_core packages/map_runtime packages/map_gameplay packages/map_battle examples/playable_runtime_host assets selbrume
find reports/narrativeStudio/scenes/screenshots -maxdepth 1 -name '*v1_115*' -print
find reports/narrativeStudio/scenes/screenshots -maxdepth 1 -name '*v1_116*' -print
```

Sortie :

```text
<vide>
```

## 22. Roadmaps mises à jour

```text
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
```

Mise à jour :

```text
V1-115 : DONE
Prochain lot recommandé : NS-SCENES-V1-116 — Cinematic Actor Walking Animation Renderer Integration V0
```

## 23. git diff --check/stat/name-only/status final

Commande :

```bash
git diff --check
git diff --stat
git diff --name-only
git status --short --untracked-files=all
git diff --name-only -- packages/map_core packages/map_runtime packages/map_gameplay packages/map_battle examples/playable_runtime_host assets selbrume
find reports/narrativeStudio/scenes/screenshots -maxdepth 1 -name '*v1_115*' -print
find reports/narrativeStudio/scenes/screenshots -maxdepth 1 -name '*v1_116*' -print
```

Sortie :

```text
<git diff --check vide>
 .../scenes/road_map_scene_builder_authoring.md     | 21 ++++++++++++++---
 reports/narrativeStudio/scenes/road_map_scenes.md  | 26 +++++++++++++++++-----
 2 files changed, 39 insertions(+), 8 deletions(-)
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_walking_animation_preview_resolver.dart
?? packages/map_editor/test/cinematic_actor_walking_animation_preview_resolver_test.dart
?? reports/narrativeStudio/scenes/ns_scenes_v1_115_cinematic_actor_walking_animation_frame_resolver_v0.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_115_evidence_pack.md
<anti-scope packages/core-runtime-gameplay-battle-examples-assets-selbrume vide>
<screenshot v1_115 vide>
<screenshot v1_116 vide>
```

## 24. Risques restants

```text
La cadence reste time-based et non distance-based.
Le resolver produit une frame symbolique, non affichée.
Le branchement renderer V1-116 devra préserver l'ancrage bottom-center et les fallbacks V1-99.
Le choix sans CinematicActorSpritePreviewActor évite Flutter mais devra être raccordé prudemment à l'intégration visuelle.
```

## 25. Auto-critique

Prêt pour V1-116 : le resolver donne une sortie déterministe, typée, avec source rect symbolique, direction, durée, index et diagnostics.

Reste symbolique : aucune image n'est chargée et aucune frame n'est dessinée.

Couplage Character Library : raisonnable pour V0, car les animations existent déjà dans `ProjectCharacterEntry`.

Cadence time-based : suffisante pour V0 ; une cadence liée à la distance peut attendre un contrat dédié.

Fallback idle/placeholder : robuste pour les cas testés, mais l'intégration renderer devra vérifier la compatibilité avec les erreurs d'atlas réelles.

Renderer non touché : respecté.

Bis recommandé : non, sauf si V1-116 révèle une incompatibilité d'interface avec l'overlay existant.

## 26. Verdict final

```text
NS-SCENES-V1-115 : DONE.
Walking Animation Frame Resolver : implémenté.
idle/walk/run/fallback : résolus symboliquement.
Cadence : testée.
Directions : testées.
Fallbacks : testés.
Renderer integration : non démarrée.
Overlay/widget : non modifiés.
Runtime / Flame / GameState : non touchés.
Aucun screenshot.
```

## 27. Prochain lot recommandé

```text
NS-SCENES-V1-116 — Cinematic Actor Walking Animation Renderer Integration V0
```

## Passes type sub-agents

```text
Sub-agent Audit / Architecture : PASS — le repo confirme que les animations walk/run existent dans Character Library et que movementMode est lisible via helper core.
Sub-agent Implémentation : PASS — resolver dédié créé, sans import Flutter/Flame/runtime.
Sub-agent Tests : PASS — RED observé, puis tests resolver/régressions ciblées verts.
Sub-agent Build / Validation : PASS — build complet non requis, analyse ciblée et map_core propres.
Sub-agent Critique finale : PASS avec limites — sortie symbolique seulement, V1-116 doit brancher le rendu.
```
