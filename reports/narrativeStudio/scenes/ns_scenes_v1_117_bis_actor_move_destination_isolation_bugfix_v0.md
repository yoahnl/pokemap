# NS-SCENES-V1-117-bis — ActorMove Destination Isolation Bugfix V0

## 1. Resume executif

Statut : `DONE`.

Le bug signale par Karim est confirme, avec une nuance importante : le modele core ne propage pas une modification a tous les actorMove. L'operation core auditee met deja a jour par `stepId`. La cause racine etait dans le Cinematic Builder : l'ajout de plusieurs blocs `actorMove` depuis la palette reutilisait la meme `movementTarget` globale (`target_center` dans le test). Ensuite, l'inspecteur modifiait le binding de destination par `targetId`; plusieurs actorMove pouvaient donc apparaitre couples parce qu'ils pointaient volontairement ou involontairement vers la meme cible authoring.

Correction appliquee : `_addActorMove` reutilise seulement une cible de mouvement qui n'est pas deja employee par un `actorMove`. Si toutes les cibles existantes sont deja utilisees, le Builder cree une nouvelle destination authoring dediee, copie le binding initial de reference, puis assigne cette destination au nouveau step. Changer la destination d'un actorMove ne modifie plus celle de l'autre.

## 2. Gate 0

Commandes initiales :

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

Note Gate 0 : `selbrume/project.json` etait deja dirty avant ce lot. Il est documente comme changement externe hors lot et n'a pas ete modifie/restaure par V1-117-bis.

## 3. Fichiers lus

Regles et prompt :

- `AGENTS.md`
- `agent_rules.md`
- `codex_rule.md`
- `codex_rules.md` : absent.
- `skills/README.md`
- `skills/using-superpowers/SKILL.md`
- `skills/test-driven-development/SKILL.md`
- `skills/verification-before-completion/SKILL.md`
- Prompt attache `NS-SCENES-V1-117-bis — ActorMove Destination Isolation Bugfix V0`.

Rapports et roadmaps recents :

- `reports/narrativeStudio/scenes/ns_scenes_v1_104_cinematic_actor_move_target_from_stage_points_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_104_bis_actor_move_stage_point_target_evidence_quality_gate_closure.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_105_cinematic_builder_ux_simplification_destination_vocabulary_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_106_cinematic_manual_path_authoring_prep_contract.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_107_cinematic_manual_path_core_model_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_108_cinematic_manual_path_drawing_ui_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_112_cinematic_actormove_preview_playback_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_113_cinematic_actor_playback_smooth_motion_subtile_overlay_polish_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_116_cinematic_actor_walking_animation_renderer_integration_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_117_cinematic_actor_animation_cadence_playback_status_polish_v0.md`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

Core/editor/tests audites :

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

## 4. Bug utilisateur observe

Symptome verifie : deux blocs `actorMove` crees depuis la palette pouvaient partager la meme destination authoring. Modifier le repere final du premier changeait alors le binding de la cible partagee, ce qui rendait le second actorMove visuellement modifie aussi.

## 5. Reproduction

Un test widget V1-117-bis a ete ajoute dans `packages/map_editor/test/cinematic_builder_workspace_test.dart` :

```text
V1-117-bis changing one actorMove destination keeps another actorMove destination unchanged
```

La version RED reproduisait le bug apres creation de deux actorMove depuis une cinematic ne contenant qu'une cible initiale `target_center`.

## 6. Cause racine

Audit core : `updateCinematicTimelineActorMoveStep` cherche le step par `stepId` et remplace uniquement ce step. Je n'ai pas trouve de propagation globale par `actorId`.

Cause reelle : `_addActorMove()` prenait toujours `widget.asset.movementTargets.first`. Donc le second actorMove cree par la palette pointait vers la meme `movementTarget` que le premier. Comme l'inspecteur de destination edite `CinematicMovementTargetBinding(targetId: ...)`, les deux blocs partageaient leur destination finale.

## 7. Correction appliquee

Zone modifiee : `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`.

Hunk principal :

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

## 8. Isolation par stepId / actorMove

- Core : update par `stepId` explicite conserve.
- UI : chaque actorMove cree depuis la palette obtient une destination non partagee quand les destinations existantes sont deja utilisees.
- Le test verifie que le premier et le second actorMove ont des `targetId` differents.
- Le test verifie que modifier la destination du premier ne modifie pas le binding du second.

## 9. Relation Destination finale / Trajet manuel

La correction ne modifie pas le modele manual path. Le test V1-117-bis verifie explicitement que l'edition de la destination finale ne cree ni ne modifie de manual path pour les actorMove testes :

```dart
expect(
  updatedAsset.stageContext!.manualPaths
      .where((path) =>
          path.ownerActorMoveStepId == firstMove.id ||
          path.ownerActorMoveStepId == secondMove.id)
      .toList(),
  isEmpty,
);
```

Les tests V1-117 existants relances conservent aussi la non-mutation des waypoints en manual path.

## 10. Tests RED

Commande RED :

```bash
cd packages/map_editor
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-117-bis"
```

Sortie RED exacte utile :

```text
Expected: not 'target_center'
  Actual: 'target_center'
...
file:///Users/karim/Project/pokemonProject/packages/map_editor/test/cinematic_builder_workspace_test.dart line 9863
```

Interpretation : le deuxieme actorMove reutilisait `target_center`, confirmant le couplage par destination authoring partagee.

## 11. Tests GREEN

Relance ciblee apres correction :

```bash
cd packages/map_editor
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-117-bis"
```

Sortie :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/cinematic_builder_workspace_test.dart
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/cinematic_builder_workspace_test.dart
00:01 +0: V1-117-bis changing one actorMove destination keeps another actorMove destination unchanged
00:02 +0: V1-117-bis changing one actorMove destination keeps another actorMove destination unchanged
00:02 +1: V1-117-bis changing one actorMove destination keeps another actorMove destination unchanged
00:02 +1: All tests passed!
```

## 12. Tests executes

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-117"
```

Sortie :

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

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-116"
```

Sortie :

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

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart
```

Sortie finale :

```text
00:34 +232: All tests passed!
```

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact test/cinematics_library_workspace_test.dart test/cinematic_stage_point_preview_overlay_test.dart
```

Sortie :

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

Note : un premier lancement parallele de la commande V1-117-bis a fait crasher Flutter sur un lien SwiftPM deja present (`PathExistsException ... file_picker-8.3.7`). La relance sequentielle de la meme commande est passee, et les autres suites sont vertes. Aucun fichier produit n'a ete modifie pour ce souci de tooling.

## 13. Analyse statique

Commande :

```bash
cd packages/map_editor
flutter analyze --no-fatal-infos lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart test/cinematic_builder_workspace_test.dart
```

Sortie :

```text
Analyzing 2 items...
37 issues found. (ran in 1.3s)
```

Details : sortie 0, uniquement des infos `prefer_const_constructors` / `prefer_const_literals_to_create_immutables`, non fatales avec `--no-fatal-infos`.

## 14. Build ou justification de non-build

Build macOS non lance. Justification : le prompt rend le build non obligatoire si seuls l'authoring et les tests changent. Le correctif est limite a la creation authoring des destinations actorMove dans le Builder, sans asset, runtime, Flame, GameState, build config ou integration native. La compilation du code modifie est couverte par les tests widget cibles et la suite Builder complete.

## 15. Checks anti-scope

Commandes :

```bash
git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle examples/playable_runtime_host assets selbrume
find reports/narrativeStudio/scenes/screenshots -maxdepth 1 -name '*v1_118*' -print
```

Sorties :

```text
selbrume/project.json
```

```text
Sortie : <vide>
```

Interpretation :

- aucun `packages/map_runtime`, `packages/map_gameplay`, `packages/map_battle`, `examples/playable_runtime_host` ou `assets` touche par ce lot ;
- `selbrume/project.json` etait deja dirty au Gate 0 et reste hors lot ;
- aucun screenshot V1-118 cree ;
- V1-118 reste seulement recommande.

## 16. Roadmaps mises a jour

Mis a jour :

- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

Ajout : `NS-SCENES-V1-117-bis — ActorMove Destination Isolation Bugfix V0` en `DONE`.

Prochain lot conserve : `NS-SCENES-V1-118 — Cinematic Playback Preview Diagnostics / Fallback Detail Polish V0`.

## 17. git diff --check/stat/name-only/status final

Commande :

```bash
git diff --check
```

Sortie :

```text
Sortie : <vide>
```

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

## 18. Risques restants

- Deux actorMove peuvent encore partager volontairement une meme destination si une future UI permet explicitement de choisir la meme cible stable. Ce n'est pas interdit par le modele, mais l'ajout palette ne doit plus le faire involontairement.
- Le correctif couvre la creation depuis la palette. Un audit plus large peut verifier les autres champs actorMove authoring, mais je n'ai pas observe de propagation core par `stepId`.
- Les infos analyzer existantes restent hors scope.

## 19. Auto-critique

- Cause racine : certaine pour le scenario reproduit par le test RED/GREEN.
- Couverture : le test empeche la regression principale, car il cree deux actorMove depuis la palette, change la destination du premier, puis verifie que le second conserve son target/binding.
- Origine : bug UI/authoring, pas bug core.
- Champs voisins : les manual paths restent separes dans ce test, mais un audit futur pourrait verifier d'autres champs actorMove si un symptome similaire apparait.
- Bis supplementaire : non necessaire pour ce bug precis ; V1-118 peut rester le prochain lot recommande.

## 20. Verdict final

`NS-SCENES-V1-117-bis : DONE.`

ActorMove destination isolation : corrigee.

Destination par step : independante pour les blocs crees depuis la palette.

Destination finale / Trajet manuel : separes.

Runtime / Flame / GameState : non touches.

V1-118 : recommande, non demarre.

## 21. Prochain lot recommande

`NS-SCENES-V1-118 — Cinematic Playback Preview Diagnostics / Fallback Detail Polish V0`
