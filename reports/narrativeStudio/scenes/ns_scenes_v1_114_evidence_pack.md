# NS-SCENES-V1-114 — Evidence Pack

## Lot

```text
NS-SCENES-V1-114 — Cinematic Actor Walking Animation Prep Contract
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
<vide>
<vide>
<vide>
2dff3a1e feat: cinematic actor playback smooth motion v1.113
d41f7f22 feat: cinematic actor move preview playback v1.112
e41f5874 update selbrume
e9972298 Add cinematic preview transport UI
3411ae0b feat: cinematic preview playback plan read model v1.110
8cf3b6f6 docs: préparation contrat preview/playback cinematic v1.109
3ed90377 fix: corrections tests et rapports v1.108
4670f42c update selbrume
caaa7f65 feat: cinematic manual path drawing UI et rapports V1.108
b54e1cd3 docs: ajout rapports V1.107 bis (nettoyage JSON et hardening)
```

## Règles lues

```text
AGENTS.md : présent
agent_rules.md : présent
codex_rule.md : présent
codex_rules.md : absent
```

## Fichiers lus

```text
reports/narrativeStudio/scenes/ns_scenes_v1_110_cinematic_preview_playback_plan_read_model_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_110_evidence_pack.md
reports/narrativeStudio/scenes/ns_scenes_v1_111_cinematic_preview_playback_transport_ui_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_111_evidence_pack.md
reports/narrativeStudio/scenes/ns_scenes_v1_112_cinematic_actormove_preview_playback_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_112_evidence_pack.md
reports/narrativeStudio/scenes/ns_scenes_v1_113_cinematic_actor_playback_smooth_motion_subtile_overlay_polish_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_113_evidence_pack.md
reports/narrativeStudio/scenes/ns_scenes_v1_90_cinematic_actor_display_preview_prep_contract.md
reports/narrativeStudio/scenes/ns_scenes_v1_91_cinematic_actor_display_preview_read_model_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_92_cinematic_actor_display_preview_renderer_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_97_cinematic_actor_display_preview_sprite_resolver_prep_contract.md
reports/narrativeStudio/scenes/ns_scenes_v1_98_cinematic_actor_display_preview_sprite_resolver_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_99_cinematic_actor_display_preview_sprite_renderer_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_99_bis_cinematic_actor_sprite_real_asset_fidelity_visual_gate_polish_v0.md
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
packages/map_core/lib/src/read_models/cinematic_preview_playback_plan.dart
packages/map_core/lib/src/read_models/cinematic_actor_display_preview_model.dart
packages/map_core/lib/src/read_models/cinematic_timeline_time_layout_read_model.dart
packages/map_core/lib/src/models/cinematic_asset.dart
packages/map_core/lib/src/models/project_manifest.dart
packages/map_core/lib/src/models/enums.dart
packages/map_core/lib/map_core.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_preview_playback_actor_overlay_adapter.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_display_preview_overlay.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_sprite_preview_plan.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_sprite_preview_resolver.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_sprite_preview_renderer.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_viewport_transform.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
packages/map_editor/lib/src/ui/panels/character_library_panel.dart
packages/map_core/test/cinematic_preview_playback_plan_test.dart
packages/map_core/test/cinematic_actor_display_preview_model_test.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
packages/map_editor/test/cinematic_actor_sprite_preview_renderer_test.dart
packages/map_editor/test/cinematics_library_workspace_test.dart
```

## Commandes d'audit exécutées

Existence des fichiers obligatoires :

```text
OK AGENTS.md
OK agent_rules.md
OK codex_rule.md
MISSING codex_rules.md
OK reports/narrativeStudio/scenes/ns_scenes_v1_110_cinematic_preview_playback_plan_read_model_v0.md
OK reports/narrativeStudio/scenes/ns_scenes_v1_110_evidence_pack.md
OK reports/narrativeStudio/scenes/ns_scenes_v1_111_cinematic_preview_playback_transport_ui_v0.md
OK reports/narrativeStudio/scenes/ns_scenes_v1_111_evidence_pack.md
OK reports/narrativeStudio/scenes/ns_scenes_v1_112_cinematic_actormove_preview_playback_v0.md
OK reports/narrativeStudio/scenes/ns_scenes_v1_112_evidence_pack.md
OK reports/narrativeStudio/scenes/ns_scenes_v1_113_cinematic_actor_playback_smooth_motion_subtile_overlay_polish_v0.md
OK reports/narrativeStudio/scenes/ns_scenes_v1_113_evidence_pack.md
OK reports/narrativeStudio/scenes/ns_scenes_v1_97_cinematic_actor_display_preview_sprite_resolver_prep_contract.md
OK reports/narrativeStudio/scenes/ns_scenes_v1_98_cinematic_actor_display_preview_sprite_resolver_v0.md
OK reports/narrativeStudio/scenes/ns_scenes_v1_99_cinematic_actor_display_preview_sprite_renderer_v0.md
OK reports/narrativeStudio/scenes/ns_scenes_v1_99_bis_cinematic_actor_sprite_real_asset_fidelity_visual_gate_polish_v0.md
OK reports/narrativeStudio/scenes/ns_scenes_v1_90_cinematic_actor_display_preview_prep_contract.md
OK reports/narrativeStudio/scenes/ns_scenes_v1_91_cinematic_actor_display_preview_read_model_v0.md
OK reports/narrativeStudio/scenes/ns_scenes_v1_92_cinematic_actor_display_preview_renderer_v0.md
```

Recherches utiles :

```bash
rg -n "class ProjectCharacterEntry|class CharacterAnimation|class CharacterAnimationFrame|enum CharacterAnimationState|enum EntityFacing|animations|frameWidth|frameHeight|durationMs|sourceRect|source:" packages/map_core/lib/src packages/map_core/lib/map_core.dart
rg -n "class CinematicActorSpritePreview|CinematicActorSpritePreviewActor|CinematicActorSpriteRef|sourceTileRect|frameWidthTiles|frameHeightTiles|direction|placeholderFallback|spriteReady|missing|out of bounds|source rect" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_sprite_preview_plan.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_sprite_preview_renderer.dart packages/map_editor/test/cinematic_actor_sprite_preview_renderer_test.dart
rg -n "class CinematicActorPlaybackPose|isInterpolated|activeStepId|actorPoseById|CinematicPreviewPlaybackFrame|actorPoses|movementMode|actorMove" packages/map_core/lib/src/read_models/cinematic_preview_playback_plan.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_preview_playback_actor_overlay_adapter.dart packages/map_editor/test/cinematic_builder_workspace_test.dart
rg -n "CharacterAnimationState\\.walk|CharacterAnimationState\\.run|state: CharacterAnimationState\\.walk|state: CharacterAnimationState\\.run|movementMode.*run|movementMode.*walk|actor\\.movementMode" packages/map_core packages/map_editor packages/map_editor/test
```

## Résultats d'audit clés

Character Library :

```text
ProjectCharacterEntry contient frameWidth, frameHeight et animations.
CharacterAnimation contient state, direction et frames.
CharacterAnimationFrame contient source et durationMs avec défaut 150.
CharacterAnimationState contient idle, walk et run.
EntityFacing contient north, south, east et west.
```

Playback :

```text
CinematicActorPlaybackPose contient x/y double?, facing, source, isInterpolated et activeStepId.
_poseForMove met isInterpolated = clampedTimeMs < item.endMs && progress > 0.
V1-113 consomme actorPoseById et expose les coordonnées sub-tile sans round/toInt.
```

Sprite preview :

```text
CinematicActorSpritePreviewPlan existe.
CinematicActorSpriteRef contient sourceTileRect, frameWidthTiles, frameHeightTiles et direction.
cinematic_actor_sprite_preview_resolver.dart filtre seulement CharacterAnimationState.idle.
cinematic_actor_display_preview_overlay.dart vérifie les source rects hors atlas et fallback placeholder.
```

Movement mode :

```text
actor.movementMode est stocké dans les metadata actorMove.
Les tests existants couvrent walk et run dans le Builder.
```

## Fichiers modifiés

```text
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
```

## Fichiers créés

```text
reports/narrativeStudio/scenes/ns_scenes_v1_114_cinematic_actor_walking_animation_prep_contract.md
reports/narrativeStudio/scenes/ns_scenes_v1_114_evidence_pack.md
```

## Contenu complet des fichiers créés

Fichiers créés :

```text
reports/narrativeStudio/scenes/ns_scenes_v1_114_cinematic_actor_walking_animation_prep_contract.md
reports/narrativeStudio/scenes/ns_scenes_v1_114_evidence_pack.md
```

Ces deux fichiers sont des documents Markdown autoportants créés pour V1-114. Aucun fichier de code source n'a été créé.

## Checks anti-scope

Commande :

```bash
git diff --check
git diff --stat
git diff --name-only
git status --short --untracked-files=all
git diff --name-only -- packages/map_core packages/map_editor packages/map_runtime packages/map_gameplay packages/map_battle examples/playable_runtime_host
find reports/narrativeStudio/scenes/screenshots -maxdepth 1 -name '*v1_114*' -print
find reports/narrativeStudio/scenes/screenshots -maxdepth 1 -name '*v1_115*' -print
```

Sortie :

```text
<git diff --check vide>
 .../scenes/road_map_scene_builder_authoring.md     | 15 +++++++++++++++
 reports/narrativeStudio/scenes/road_map_scenes.md  | 22 +++++++++++++++++++---
 2 files changed, 34 insertions(+), 3 deletions(-)
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_114_cinematic_actor_walking_animation_prep_contract.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_114_evidence_pack.md
<diff packages produit vide>
<screenshot v1_114 vide>
<screenshot v1_115 vide>
```

## git final

```text
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_114_cinematic_actor_walking_animation_prep_contract.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_114_evidence_pack.md
```

## V1-114-bis — Roadmap Header Alignment Closure

Correction documentaire :
- le header global des roadmaps pointe maintenant vers NS-SCENES-V1-115 ;
- l'ancien header obsolète vers NS-SCENES-V1-112 a été supprimé ;
- les anciennes phrases qui présentaient V1-114 comme prochain lot recommandé ont été reformulées comme historique ;
- aucun package Dart/Flutter n'a été modifié ;
- aucun screenshot n'a été créé ;
- V1-115 n'a pas été démarré.

Commande initiale :

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

Commande de contrôle roadmap :

```bash
rg -n "Prochain lot exact recommande|Prochain lot exact recommandé|NS-SCENES-V1-112 — Cinematic ActorMove Preview Playback V0|NS-SCENES-V1-115 — Cinematic Actor Walking Animation Frame Resolver V0" reports/narrativeStudio/scenes/road_map_scenes.md reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
```

Sortie de contrôle roadmap :

```text
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md:9:## Prochain lot exact recommande
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md:12:NS-SCENES-V1-115 — Cinematic Actor Walking Animation Frame Resolver V0
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md:182:Prochain lot recommande : `NS-SCENES-V1-115 — Cinematic Actor Walking Animation Frame Resolver V0`.
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md:196:Suite historique : V1-114 a ete realise comme contrat documentaire ; le prochain lot global actuel est `NS-SCENES-V1-115 — Cinematic Actor Walking Animation Frame Resolver V0`.
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md:200:Statut : `NS-SCENES-V1-112 — Cinematic ActorMove Preview Playback V0` est DONE.
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md:210:Historique avant V1-113 : V1-112 recommandait de corriger la précision visuelle du playback acteur. Cette limite est maintenant traitée par V1-113 ; la suite historique V1-114 a ete realisee, et le prochain lot global actuel est `NS-SCENES-V1-115 — Cinematic Actor Walking Animation Frame Resolver V0`.
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md:222:Limites historiques au moment de V1-111 : actor overlay playback non démarré ; aucun scrubber, seek, runtime, Flame, GameState ou persistance. Cette limite est traitée par V1-112, puis la fluidité sub-tile par V1-113 ; la suite historique V1-114 a ete realisee, et le prochain lot global actuel est `NS-SCENES-V1-115 — Cinematic Actor Walking Animation Frame Resolver V0`.
reports/narrativeStudio/scenes/road_map_scenes.md:177:| NS-SCENES-V1-112 — Cinematic ActorMove Preview Playback V0 | DONE | Connecter les poses `CinematicPreviewPlaybackFrame.actorPoses` au rendu preview editor-only des acteurs, avec direct/manual path visibles pendant la lecture locale, sans runtime, Flame, GameState, pathfinding, collision, scrubber/seek ni walking animation. |
reports/narrativeStudio/scenes/road_map_scenes.md:181:## Prochain lot exact recommande
reports/narrativeStudio/scenes/road_map_scenes.md:183:`NS-SCENES-V1-115 — Cinematic Actor Walking Animation Frame Resolver V0`
reports/narrativeStudio/scenes/road_map_scenes.md:199:12. `NS-SCENES-V1-112 — Cinematic ActorMove Preview Playback V0` (DONE)
reports/narrativeStudio/scenes/road_map_scenes.md:202:15. `NS-SCENES-V1-115 — Cinematic Actor Walking Animation Frame Resolver V0`
reports/narrativeStudio/scenes/road_map_scenes.md:216:Prochain lot recommande : `NS-SCENES-V1-115 — Cinematic Actor Walking Animation Frame Resolver V0`.
reports/narrativeStudio/scenes/road_map_scenes.md:230:Suite historique : V1-114 a ete realise comme contrat documentaire ; le prochain lot global actuel est `NS-SCENES-V1-115 — Cinematic Actor Walking Animation Frame Resolver V0`.
reports/narrativeStudio/scenes/road_map_scenes.md:234:Statut : `NS-SCENES-V1-112 — Cinematic ActorMove Preview Playback V0` est DONE.
reports/narrativeStudio/scenes/road_map_scenes.md:254:Limites historiques au moment de V1-111 : aucun actor overlay playback n'était branché ; aucun scrubber, seek timeline, runtime, Flame, GameState, pathfinding, collision, animation de marche ou persistance du temps n'avait été ajouté. Le branchement acteur a été traité par V1-112, puis la fluidité sub-tile par V1-113 ; la suite historique V1-114 a ete realisee, et le prochain lot global actuel est `NS-SCENES-V1-115 — Cinematic Actor Walking Animation Frame Resolver V0`.
```

Commande finale :

```bash
git diff --check
git diff --stat
git diff --name-only
git status --short --untracked-files=all
git diff --name-only -- packages examples assets selbrume
find reports/narrativeStudio/scenes/screenshots -maxdepth 1 -name '*v1_114*' -print
find reports/narrativeStudio/scenes/screenshots -maxdepth 1 -name '*v1_115*' -print
```

Sortie finale :

```text
<git diff --check vide>
 .../scenes/ns_scenes_v1_114_evidence_pack.md       | 99 ++++++++++++++++++++++
 .../scenes/road_map_scene_builder_authoring.md     |  8 +-
 reports/narrativeStudio/scenes/road_map_scenes.md  |  6 +-
 3 files changed, 106 insertions(+), 7 deletions(-)
reports/narrativeStudio/scenes/ns_scenes_v1_114_evidence_pack.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
 M reports/narrativeStudio/scenes/ns_scenes_v1_114_evidence_pack.md
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
<git diff --name-only -- packages examples assets selbrume vide>
<find screenshots *v1_114* vide>
<find screenshots *v1_115* vide>
```
