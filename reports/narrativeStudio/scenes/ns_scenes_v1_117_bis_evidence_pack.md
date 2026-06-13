# NS-SCENES-V1-117-bis — Evidence Pack

## Verdict

`NS-SCENES-V1-117-bis — ActorMove Destination Isolation Bugfix V0` : DONE.

Le bug etait reel. Il ne venait pas du core qui met a jour les steps par `stepId`, mais de l'ajout UI de blocs `actorMove` qui reutilisait une destination authoring deja employee. Le correctif isole les destinations creees depuis la palette.

## Gate 0 complet

Commandes :

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
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_walking_animation_preview_resolver.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart
 M packages/map_editor/test/cinematic_actor_walking_animation_preview_resolver_test.dart
 M packages/map_editor/test/cinematic_builder_workspace_test.dart
 M packages/map_editor/test/cinematics_library_workspace_test.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
 M selbrume/project.json
?? reports/narrativeStudio/scenes/ns_scenes_v1_116_cinematic_actor_walking_animation_renderer_integration_v0.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_116_evidence_pack.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_117_cinematic_actor_animation_cadence_playback_status_polish_v0.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_117_evidence_pack.md
?? reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_116_cinematic_actor_walking_animation_renderer_integration_v0.png
?? reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_117_cinematic_actor_animation_cadence_playback_status_polish_v0.png
 ...c_actor_walking_animation_preview_resolver.dart |  83 ++-
 .../cinematics/cinematic_builder_workspace.dart    | 279 +++++++-
 .../cinematic_map_backdrop_preview_panel.dart      |  68 +-
 ...or_walking_animation_preview_resolver_test.dart | 184 +++++
 .../test/cinematic_builder_workspace_test.dart     | 775 ++++++++++++++++++++-
 .../test/cinematics_library_workspace_test.dart    |   8 +-
 .../scenes/road_map_scene_builder_authoring.md     |  46 +-
 reports/narrativeStudio/scenes/road_map_scenes.md  |  50 +-
 selbrume/project.json                              |  21 +-
 9 files changed, 1445 insertions(+), 69 deletions(-)
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_walking_animation_preview_resolver.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart
packages/map_editor/test/cinematic_actor_walking_animation_preview_resolver_test.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
packages/map_editor/test/cinematics_library_workspace_test.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
selbrume/project.json
f99e235c feat: cinematic actor walking animation frame resolver v1.115
0ed41a86 docs: mise à jour rapports et roadmaps v1.114
a6b197c0 docs: préparation contrat animation marche acteur cinematic v1.114
2dff3a1e feat: cinematic actor playback smooth motion v1.113
d41f7f22 feat: cinematic actor move preview playback v1.112
e41f5874 update selbrume
e9972298 Add cinematic preview transport UI
3411ae0b feat: cinematic preview playback plan read model v1.110
8cf3b6f6 docs: préparation contrat preview/playback cinematic v1.109
3ed90377 fix: corrections tests et rapports v1.108
```

## Etat dirty initial

`selbrume/project.json` etait deja modifie au Gate 0. Il est hors lot, non restaure, non edite.

Le worktree contenait aussi des modifications et artefacts V1-116/V1-117 preexistants. V1-117-bis s'ajoute par-dessus sans les revert.

## Fichiers lus

- `AGENTS.md`
- `agent_rules.md`
- `codex_rule.md`
- `codex_rules.md` : absent.
- `skills/README.md`
- `skills/using-superpowers/SKILL.md`
- `skills/test-driven-development/SKILL.md`
- `skills/verification-before-completion/SKILL.md`
- Prompt attache V1-117-bis.
- Rapports V1-104, V1-104-bis, V1-105, V1-106, V1-107, V1-108, V1-112, V1-113, V1-116, V1-117.
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`
- `packages/map_core/lib/src/models/cinematic_asset.dart`
- `packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart`
- `packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart`
- `packages/map_core/lib/src/read_models/cinematic_preview_playback_plan.dart`
- `packages/map_core/lib/src/read_models/cinematic_actor_display_preview_model.dart`
- `packages/map_core/lib/map_core.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_preview_playback_actor_overlay_adapter.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_display_preview_overlay.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_manual_path_preview_overlay.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_stage_point_preview_overlay.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart`
- `packages/map_core/test/cinematic_authoring_operations_test.dart`
- `packages/map_core/test/cinematic_preview_playback_plan_test.dart`
- `packages/map_editor/test/cinematic_builder_workspace_test.dart`
- `packages/map_editor/test/cinematics_library_workspace_test.dart`
- `packages/map_editor/test/cinematic_stage_point_preview_overlay_test.dart`

## Fichiers modifies

V1-117-bis a modifie :

- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`
- `packages/map_editor/test/cinematic_builder_workspace_test.dart`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

Fichiers deja modifies avant ce lot et toujours presents dans le diff :

- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_walking_animation_preview_resolver.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart`
- `packages/map_editor/test/cinematic_actor_walking_animation_preview_resolver_test.dart`
- `packages/map_editor/test/cinematics_library_workspace_test.dart`
- `selbrume/project.json` hors lot.

## Fichiers crees

V1-117-bis cree :

- `reports/narrativeStudio/scenes/ns_scenes_v1_117_bis_actor_move_destination_isolation_bugfix_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_117_bis_evidence_pack.md`

## Test RED exact

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-117-bis"
```

Sortie RED utile :

```text
Expected: not 'target_center'
  Actual: 'target_center'
...
file:///Users/karim/Project/pokemonProject/packages/map_editor/test/cinematic_builder_workspace_test.dart line 9863
```

Verdict RED : FAIL attendu. Le second actorMove reutilisait la meme destination `target_center`.

## Cause racine

- Hypothese core rejetee : les operations core mettent a jour par `stepId`.
- Hypothese UI confirmee : `_addActorMove()` utilisait la premiere destination de `widget.asset.movementTargets` pour chaque actorMove cree depuis la palette.
- Effet : deux actorMove pouvaient partager le meme `targetId`; l'inspecteur changeait le binding par ce `targetId`, donc la destination semblait changer partout.

## Hunk de correction

```dart
final usedTargetIds = {
  for (final step in widget.asset.timeline.steps)
    if (isCinematicTimelineActorMoveStep(step) && step.targetId != null)
      step.targetId!,
};
CinematicMovementTargetRef? target;
for (final candidate in widget.asset.movementTargets) {
  if (!usedTargetIds.contains(candidate.targetId)) {
    target = candidate;
    break;
  }
}

if (target == null) {
  final seedTarget = widget.asset.movementTargets.first;
  final seedBinding = widget.asset.stageContext == null
      ? null
      : _movementTargetBindingFor(
          widget.asset.stageContext!,
          seedTarget.targetId,
        );
  // Each actorMove owns its destination choice in authoring. Reusing an
  // already-used movement target would couple blocks through the same
  // binding, so changing one final repere would visually move the others.
  final targetId = await widget.onAddMovementTarget(
    cinematicId: widget.asset.id,
  );
  if (!mounted || targetId == null) {
    return;
  }
  if (seedBinding != null) {
    await widget.onUpsertMovementTargetBinding(
      cinematicId: widget.asset.id,
      binding: CinematicMovementTargetBinding(
        targetId: targetId,
        kind: seedBinding.kind,
        sourceId: seedBinding.sourceId,
      ),
    );
    if (!mounted) {
      return;
    }
  }
  target =
      CinematicMovementTargetRef(targetId: targetId, label: 'Destination');
}
```

## Test V1-117-bis ajoute

Assertions principales :

```dart
expect(secondMove.targetId, isNot('target_center'));
expect(secondMove.targetId, isNot(firstMove.targetId));
expect(firstBinding.sourceId, 'stage_point_left');
expect(secondBinding.sourceId, 'stage_point_center');
expect(
  updatedAsset.stageContext!.manualPaths
      .where((path) =>
          path.ownerActorMoveStepId == firstMove.id ||
          path.ownerActorMoveStepId == secondMove.id)
      .toList(),
  isEmpty,
);
```

## Tests GREEN exacts

### V1-117-bis cible

```bash
cd packages/map_editor
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-117-bis"
```

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/cinematic_builder_workspace_test.dart
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/cinematic_builder_workspace_test.dart
00:01 +0: V1-117-bis changing one actorMove destination keeps another actorMove destination unchanged
00:02 +0: V1-117-bis changing one actorMove destination keeps another actorMove destination unchanged
00:02 +1: V1-117-bis changing one actorMove destination keeps another actorMove destination unchanged
00:02 +1: All tests passed!
```

### V1-117 non-regression

```bash
cd packages/map_editor
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-117"
```

```text
Waiting for another flutter command to release the startup lock...
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/cinematic_builder_workspace_test.dart
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/cinematic_builder_workspace_test.dart
00:02 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/cinematic_builder_workspace_test.dart
00:02 +0: V1-117 fast actorMove uses playback velocity cadence for rendered frame
00:03 +0: V1-117 fast actorMove uses playback velocity cadence for rendered frame
00:03 +1: V1-117 fast actorMove uses playback velocity cadence for rendered frame
00:03 +1: V1-117 run playback advances sprite cadence faster than walk
00:04 +1: V1-117 run playback advances sprite cadence faster than walk
00:04 +2: V1-117 run playback advances sprite cadence faster than walk
00:04 +2: V1-117 playback status chips stay coherent during active and paused animation
00:04 +3: V1-117 playback status chips stay coherent during active and paused animation
00:04 +3: V1-117 fallback animation status is partial and stop returns idle
00:05 +3: V1-117 fallback animation status is partial and stop returns idle
00:05 +4: V1-117 fallback animation status is partial and stop returns idle
00:05 +4: V1-117 manual path playback uses cadence hint without mutating waypoints
00:05 +5: V1-117 manual path playback uses cadence hint without mutating waypoints
00:05 +5: captures V1-117 cinematic actor animation cadence playback status polish visual gate
00:05 +6: captures V1-117 cinematic actor animation cadence playback status polish visual gate
00:05 +6: V1-117-bis changing one actorMove destination keeps another actorMove destination unchanged
00:06 +6: V1-117-bis changing one actorMove destination keeps another actorMove destination unchanged
00:06 +7: V1-117-bis changing one actorMove destination keeps another actorMove destination unchanged
00:06 +7: All tests passed!
```

### V1-116 non-regression

```bash
cd packages/map_editor
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-116"
```

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/cinematic_builder_workspace_test.dart
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/cinematic_builder_workspace_test.dart
00:02 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/cinematic_builder_workspace_test.dart
00:02 +0: V1-116 actorMove walk renders walking sprite frame and stop returns idle
00:03 +0: V1-116 actorMove walk renders walking sprite frame and stop returns idle
00:03 +1: V1-116 actorMove walk renders walking sprite frame and stop returns idle
00:03 +1: V1-116 actorMove run renders run frame and falls back to walk
00:04 +1: V1-116 actorMove run renders run frame and falls back to walk
00:04 +2: V1-116 actorMove run renders run frame and falls back to walk
00:04 +2: V1-116 manual path actorMove renders walking sprite frame while moving
00:05 +2: V1-116 manual path actorMove renders walking sprite frame while moving
00:05 +3: V1-116 manual path actorMove renders walking sprite frame while moving
00:05 +3: captures V1-116 cinematic actor walking animation renderer integration visual gate
00:05 +4: captures V1-116 cinematic actor walking animation renderer integration visual gate
00:05 +4: All tests passed!
```

### Builder complet

```bash
cd packages/map_editor
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart
```

```text
00:34 +232: All tests passed!
```

### Library + Stage Point overlay

```bash
cd packages/map_editor
flutter test --reporter=compact test/cinematics_library_workspace_test.dart test/cinematic_stage_point_preview_overlay_test.dart
```

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/cinematics_library_workspace_test.dart
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/cinematics_library_workspace_test.dart
00:01 +0: /Users/karim/Project/pokemonProject/packages/map_editor/test/cinematics_library_workspace_test.dart: shows empty state and creates a cinematic shell
00:01 +1: /Users/karim/Project/pokemonProject/packages/map_editor/test/cinematics_library_workspace_test.dart: shows empty state and creates a cinematic shell
00:01 +2: /Users/karim/Project/pokemonProject/packages/map_editor/test/cinematics_library_workspace_test.dart: shows empty state and creates a cinematic shell
00:02 +2: /Users/karim/Project/pokemonProject/packages/map_editor/test/cinematics_library_workspace_test.dart: shows empty state and creates a cinematic shell
00:02 +3: /Users/karim/Project/pokemonProject/packages/map_editor/test/cinematics_library_workspace_test.dart: shows empty state and creates a cinematic shell
00:02 +4: /Users/karim/Project/pokemonProject/packages/map_editor/test/cinematics_library_workspace_test.dart: shows empty state and creates a cinematic shell
00:02 +5: /Users/karim/Project/pokemonProject/packages/map_editor/test/cinematics_library_workspace_test.dart: shows empty state and creates a cinematic shell
00:02 +6: /Users/karim/Project/pokemonProject/packages/map_editor/test/cinematics_library_workspace_test.dart: shows empty state and creates a cinematic shell
00:06 +26: All tests passed!
```

## Analyse ciblee

```bash
cd packages/map_editor
flutter analyze --no-fatal-infos lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart test/cinematic_builder_workspace_test.dart
```

```text
Analyzing 2 items...
37 issues found. (ran in 1.3s)
```

Details : sortie 0, infos non fatales uniquement (`prefer_const_constructors`, `prefer_const_literals_to_create_immutables`).

## Build

Non lance. Justification : le prompt rend le build non obligatoire pour un changement authoring/tests. Le correctif ne touche pas runtime, Flame, GameState, fichiers natifs, assets ou build config. Les tests widget compilent le Builder et couvrent la regression.

## Roadmaps

Mis a jour :

- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

Les deux roadmaps indiquent maintenant V1-117-bis `DONE`, et conservent V1-118 comme prochain lot recommande.

## Confirmation V1-118

V1-118 n'a pas ete demarre.

Aucun screenshot V1-118 cree.

Aucun runtime, Flame ou GameState touche.

## Checks finaux

### Roadmap grep

Commande :

```bash
rg -n "NS-SCENES-V1-117-bis|NS-SCENES-V1-118|Prochain lot exact recommande|Prochain lot exact recommandé" reports/narrativeStudio/scenes/road_map_scenes.md reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
```

Sortie utile :

```text
reports/narrativeStudio/scenes/road_map_scenes.md:183:| NS-SCENES-V1-117-bis — ActorMove Destination Isolation Bugfix V0 | DONE | Corriger l’isolation des destinations actorMove pour que modifier la destination d’un acteur ou d’un step ne modifie pas les destinations des autres actorMove, acteurs ou trajets manuels. |
reports/narrativeStudio/scenes/road_map_scenes.md:185:## Prochain lot exact recommande
reports/narrativeStudio/scenes/road_map_scenes.md:187:`NS-SCENES-V1-118 — Cinematic Playback Preview Diagnostics / Fallback Detail Polish V0`
reports/narrativeStudio/scenes/road_map_scenes.md:209:18. `NS-SCENES-V1-117-bis — ActorMove Destination Isolation Bugfix V0` (DONE)
reports/narrativeStudio/scenes/road_map_scenes.md:210:19. `NS-SCENES-V1-118 — Cinematic Playback Preview Diagnostics / Fallback Detail Polish V0`
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md:9:## Prochain lot exact recommande
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md:12:NS-SCENES-V1-118 — Cinematic Playback Preview Diagnostics / Fallback Detail Polish V0
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md:172:| NS-SCENES-V1-117-bis | ActorMove Destination Isolation Bugfix V0 | editor / bugfix | Corriger l’isolation des destinations actorMove pour que modifier la destination d’un acteur ou d’un step ne modifie pas les destinations des autres actorMove, acteurs ou trajets manuels. | Pas de V1-118, runtime, Flame, GameState, pathfinding, collision, nouveau playback, nouvelle animation, refonte Stage Points ou modification Selbrume. | `cinematic_builder_workspace.dart`, test widget V1-117-bis, rapports, roadmaps. | Test RED/GREEN multi-actorMove, V1-117, V1-116, Builder complet, Library/overlay, analyse ciblée. | Confondre une cible authoring partagée avec un bug core ; casser les bindings initiaux ; modifier manual path par accident. | DONE : chaque nouvel actorMove reçoit une destination authoring non partagée quand les cibles existantes sont déjà utilisées, et le test prouve que modifier une destination ne change pas l'autre. | V1-117 |
```

### git diff --check

Commande :

```bash
git diff --check
```

Sortie :

```text
Sortie : <vide>
```

### git diff --stat

Commande :

```bash
git diff --stat
```

Sortie :

```text
 ...c_actor_walking_animation_preview_resolver.dart |  83 +-
 .../cinematics/cinematic_builder_workspace.dart    | 330 +++++++-
 .../cinematic_map_backdrop_preview_panel.dart      |  68 +-
 ...or_walking_animation_preview_resolver_test.dart | 184 +++++
 .../test/cinematic_builder_workspace_test.dart     | 920 ++++++++++++++++++++-
 .../test/cinematics_library_workspace_test.dart    |   8 +-
 .../scenes/road_map_scene_builder_authoring.md     |  63 +-
 reports/narrativeStudio/scenes/road_map_scenes.md  |  68 +-
 selbrume/project.json                              |  21 +-
 9 files changed, 1672 insertions(+), 73 deletions(-)
```

### git diff --name-only

Commande :

```bash
git diff --name-only
```

Sortie :

```text
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_walking_animation_preview_resolver.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart
packages/map_editor/test/cinematic_actor_walking_animation_preview_resolver_test.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
packages/map_editor/test/cinematics_library_workspace_test.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
selbrume/project.json
```

### git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie :

```text
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_walking_animation_preview_resolver.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart
 M packages/map_editor/test/cinematic_actor_walking_animation_preview_resolver_test.dart
 M packages/map_editor/test/cinematic_builder_workspace_test.dart
 M packages/map_editor/test/cinematics_library_workspace_test.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
 M selbrume/project.json
?? reports/narrativeStudio/scenes/ns_scenes_v1_116_cinematic_actor_walking_animation_renderer_integration_v0.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_116_evidence_pack.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_117_bis_actor_move_destination_isolation_bugfix_v0.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_117_bis_evidence_pack.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_117_cinematic_actor_animation_cadence_playback_status_polish_v0.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_117_evidence_pack.md
?? reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_116_cinematic_actor_walking_animation_renderer_integration_v0.png
?? reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_117_cinematic_actor_animation_cadence_playback_status_polish_v0.png
```

### Anti-scope

Commande :

```bash
git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle examples/playable_runtime_host assets selbrume
```

Sortie :

```text
selbrume/project.json
```

Interpretation : exception attendue documentee, `selbrume/project.json` etait deja dirty au Gate 0 et reste hors lot.

Commande :

```bash
find reports/narrativeStudio/scenes/screenshots -maxdepth 1 -name '*v1_118*' -print
```

Sortie :

```text
Sortie : <vide>
```

## Verdict final

`NS-SCENES-V1-117-bis : DONE.`

ActorMove destination isolation : corrigee.

Destination par step : independante.

Destination finale / Trajet manuel : separes.

Runtime / Flame / GameState : non touches.

V1-118 : recommande, non demarre.
