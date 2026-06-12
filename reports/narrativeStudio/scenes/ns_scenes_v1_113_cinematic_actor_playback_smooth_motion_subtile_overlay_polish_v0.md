# NS-SCENES-V1-113 — Cinematic Actor Playback Smooth Motion / Sub-tile Overlay Polish V0

## 1. Resume executif

V1-113 supprime l'effet de deplacement par cases dans la preview playback acteur du Cinematic Builder.

Le playback continue de consommer `CinematicPreviewPlaybackFrame.actorPoses` comme source de verite. Le correctif conserve maintenant les coordonnees `double` `pose.x` / `pose.y` dans un override editor-only transmis a l'overlay acteur, au lieu de projeter ces poses en tuiles entieres avec `round()`.

Statut : `DONE` avec preuves.

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

Sortie :

```text
/Users/karim/Project/pokemonProject
main
<vide>
<vide>
<vide>
d41f7f22 feat: cinematic actor move preview playback v1.112
e41f5874 update selbrume
e9972298 Add cinematic preview transport UI
3411ae0b feat: cinematic preview playback plan read model v1.110
8cf3b6f6 docs: préparation contrat preview/playback cinematic v1.109
3ed90377 fix: corrections tests et rapports v1.108
4670f42c update selbrume
caaa7f65 feat: cinematic manual path drawing UI et rapports v1.108
b54e1cd3 docs: ajout rapports v1.107 bis (nettoyage JSON et hardening)
ecb0d64b feat: cinematic manual path core model et tests
```

Regles lues :

```text
AGENTS.md : present
agent_rules.md : present
codex_rule.md : present
codex_rules.md : absent
```

## 3. Fichiers lus

Rapports / roadmaps :

```text
reports/narrativeStudio/scenes/ns_scenes_v1_110_cinematic_preview_playback_plan_read_model_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_110_evidence_pack.md
reports/narrativeStudio/scenes/ns_scenes_v1_111_cinematic_preview_playback_transport_ui_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_111_evidence_pack.md
reports/narrativeStudio/scenes/ns_scenes_v1_112_cinematic_actormove_preview_playback_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_112_evidence_pack.md
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
```

Core playback :

```text
packages/map_core/lib/src/read_models/cinematic_preview_playback_plan.dart
packages/map_core/lib/src/read_models/cinematic_actor_display_preview_model.dart
packages/map_core/lib/src/read_models/cinematic_timeline_time_layout_read_model.dart
packages/map_core/lib/src/models/cinematic_asset.dart
packages/map_core/lib/map_core.dart
```

Editor :

```text
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_preview_playback_actor_overlay_adapter.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_display_preview_overlay.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_manual_path_preview_overlay.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_viewport_transform.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
```

Tests :

```text
packages/map_core/test/cinematic_preview_playback_plan_test.dart
packages/map_core/test/cinematic_actor_display_preview_model_test.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
packages/map_editor/test/cinematics_library_workspace_test.dart
packages/map_editor/test/cinematic_actor_sprite_preview_renderer_test.dart
packages/map_editor/test/cinematic_stage_point_preview_overlay_test.dart
```

## 4. Rappel V1-112

V1-112 a branche les poses acteur de `CinematicPreviewPlaybackFrame.actorPoses` dans l'overlay de preview, mais via une projection entiere :

```dart
x: pose.x!.round(),
y: pose.y!.round(),
```

Le mouvement etait donc fonctionnel, mais l'acteur sautait visuellement d'une tuile a l'autre.

## 5. Probleme du mouvement rigide

Le plan V1-110 calcule deja des positions interpolees en `double`. Le probleme etait uniquement dans la couche editor : l'adaptateur V1-112 arrondissait les positions avant le rendu.

V1-113 corrige cette perte de precision dans `map_editor`, sans modifier `map_core`.

## 6. Decision technique retenue

La decision retenue est de garder le read model core intact et d'ajouter une couche de rendu editor-only :

```text
CinematicActorDisplayPreviewModel
+
Map<String, CinematicActorPlaybackOverlayPose>
```

Le modele statique continue de porter labels, apparence, diagnostics et fallback. Les overrides portent uniquement les coordonnees sub-tile actives pendant le playback.

## 7. Choix Option A/B/C

Option retenue : `Option A — Ajouter un override sub-tile cote overlay`.

Raison :

```text
- pas de modification map_core ;
- pas de changement JSON ;
- pas de migration ;
- diff limite aux fichiers editor autorises ;
- fallback statique preserve ;
- source de verite dynamique toujours actorPoses.
```

Options refusees :

```text
Option B : inutilement plus large pour V1-113.
Option C : aurait transforme CinematicActorDisplayPreviewModel en double dans map_core, trop large et non necessaire.
```

## 8. Conservation des positions sub-tile

Nouveaux types editor-only :

```dart
final class CinematicActorPlaybackOverlayPose {
  const CinematicActorPlaybackOverlayPose({
    required this.actorId,
    required this.x,
    required this.y,
  });

  final String actorId;
  final double x;
  final double y;
}
```

L'adaptateur copie maintenant :

```dart
poseOverrides[actor.actorId] = CinematicActorPlaybackOverlayPose(
  actorId: actor.actorId,
  x: pose.x!,
  y: pose.y!,
);
```

## 9. Suppression du round/toInt/floor/ceil playback

Commande :

```bash
rg -n "pose\\.x!\\.round|pose\\.y!\\.round|pose\\.x\\.round|pose\\.y\\.round|pose\\.x!\\.toInt|pose\\.y!\\.toInt|pose\\.x\\.toInt|pose\\.y\\.toInt|pose\\.x!\\.floor|pose\\.y!\\.floor|pose\\.x!\\.ceil|pose\\.y!\\.ceil" packages/map_editor/lib/src/ui/canvas/cinematics || true
```

Sortie :

```text
<vide>
```

## 10. Integration overlay acteur

`CinematicActorDisplayPreviewOverlay` accepte maintenant `playbackPoseOverrides` et choisit l'ancre ainsi :

```dart
final override = playbackPoseOverrides[actor.actorId];
if (override != null) {
  return transform.tileToPreview(override.x, override.y);
}
return transform.tileCenterBottom(
  tileX: actor.position.x ?? 0,
  tileY: actor.position.y ?? 0,
);
```

L'overlay conserve le fallback statique quand aucune pose playback n'est disponible.

## 11. Direct actorMove smooth motion

Test ajoute :

```text
V1-113 direct actorMove preserves sub-tile playback positions
```

Le test prouve qu'a `100 ms / 1 s`, l'acteur a deja bouge visuellement avant le seuil d'arrondi demi-tuile. Ce test echouait avec l'ancien `round()`.

## 12. Manual path smooth motion

Test ajoute :

```text
V1-113 manual path actorMove moves before tile rounding threshold
```

Le test prouve qu'un actorMove en trajet manuel bouge avant d'atteindre la tuile suivante et que les waypoints restent inchanges.

## 13. Pause / Stop / Reset

Couvert dans le test direct :

```text
- Pause fige la position sub-tile courante.
- Stop revient a la pose initiale statique.
- Reset revient a la pose initiale statique.
```

## 14. Fallbacks et diagnostics

Tests ajoutes :

```text
V1-113 overlay applies sub-tile playback overrides and static fallback
V1-113 adapter falls back when playback pose has no position
```

Cas couverts :

```text
- acteur avec override : position double utilisee ;
- acteur sans override : position statique conservee ;
- actorPose sans x/y : pas de crash, pas d'override, direction possible.
```

## 15. Non-objectifs confirmes

Non ajoutes :

```text
runtime
Flame
GameState
PlayableMapGame
SceneRuntimeExecutor
CinematicRuntimeAdapter
pathfinding
collision
scrubber/seek
walking animation
cycle de marche
manualPathId cote actorMove
waypoints libres
coordonnees libres
```

## 16. Hygiene de diff

Fichiers touches :

```text
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_preview_playback_actor_overlay_adapter.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_display_preview_overlay.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_113_cinematic_actor_playback_smooth_motion_subtile_overlay_polish_v0.png
reports/narrativeStudio/scenes/ns_scenes_v1_113_cinematic_actor_playback_smooth_motion_subtile_overlay_polish_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_113_evidence_pack.md
```

Justification :

```text
- adaptateur : porter les overrides sub-tile ;
- overlay : consommer les doubles pour l'ancrage ;
- workspace/panel : propager le modele playback overlay ;
- test builder : couvrir direct/manual path, fallback, pause/stop/reset et Visual Gate ;
- roadmaps : marquer V1-113 DONE et pointer V1-114 ;
- rapports/screenshot : preuves du lot.
```

Aucun formatage global n'a ete lance.

Le fichier de test depasse 200 lignes de diff parce que V1-113 ajoute plusieurs tests widget complets et la Visual Gate dans la suite existante du Cinematic Builder.

## 17. Tests ajoutes/modifies

Ajoutes/modifies dans `packages/map_editor/test/cinematic_builder_workspace_test.dart` :

```text
- V1-113 direct actorMove preserves sub-tile playback positions
- V1-113 manual path actorMove moves before tile rounding threshold
- V1-113 overlay applies sub-tile playback overrides and static fallback
- V1-113 adapter falls back when playback pose has no position
- captures V1-113 cinematic actor playback smooth motion visual gate
```

Deux tests V1-112 existants ont ete ajustes pour comparer les positions pendant playback depuis l'ancre playback initiale, car V1-113 supprime le snapping entier qui servait implicitement de reference visuelle.

## 18. Tests executes

Sorties exactes principales :

```text
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-113"
00:05 +5: All tests passed!

flutter test --reporter=compact test/cinematic_builder_workspace_test.dart
00:33 +221: All tests passed!

dart test --reporter=compact test/cinematic_preview_playback_plan_test.dart
00:00 +12: All tests passed!

dart test --reporter=compact test/cinematic_actor_display_preview_model_test.dart
00:00 +27: All tests passed!

dart test --reporter=compact test/cinematic_timeline_time_layout_read_model_test.dart
00:00 +4: All tests passed!

flutter test --reporter=compact test/cinematics_library_workspace_test.dart test/cinematic_stage_point_preview_overlay_test.dart
00:06 +26: All tests passed!

flutter test --reporter=compact test/cinematic_actor_sprite_preview_renderer_test.dart
00:02 +21: All tests passed!
```

Note : le test sprite emet l'avertissement attendu pour une source rect hors atlas dans un cas de fallback volontaire.

## 19. Analyse statique

Core :

```text
dart analyze
Analyzing map_core...
No issues found!
```

Editor cible :

```text
flutter analyze --no-fatal-infos ...
Analyzing 6 items...
77 issues found. (ran in 3.8s)
```

Le code de sortie est `0`. Les 77 sorties sont des infos non fatales `prefer_const_*` / `unnecessary_const`, majoritairement dans les tests existants et dans les gros blocs de fixtures. Elles ne bloquent pas V1-113 avec `--no-fatal-infos`.

## 20. Build macOS debug

Commande :

```bash
flutter build macos --debug
```

Sortie :

```text
Building macOS application...
✓ Built build/macos/Build/Products/Debug/map_editor.app
```

## 21. Visual Gate avec ls/file/shasum

Fichier :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_113_cinematic_actor_playback_smooth_motion_subtile_overlay_polish_v0.png
```

Preuve :

```text
-rw-r--r--  1 karim  staff   222K Jun 12 23:10 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_113_cinematic_actor_playback_smooth_motion_subtile_overlay_polish_v0.png
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_113_cinematic_actor_playback_smooth_motion_subtile_overlay_polish_v0.png: PNG image data, 1663 x 926, 8-bit/color RGBA, non-interlaced
e80b175ab26559c5890db444e68ab3b5676eb304720d2c9cdcdb3a531ee27f15  reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_113_cinematic_actor_playback_smooth_motion_subtile_overlay_polish_v0.png
```

Validation visuelle manuelle :

```text
Cinematic Builder ouvert, preview visible, timeline visible, "400 ms / 1 s",
"Lecture en cours", trajet manuel visible, acteur Lysa a une position
intermediaire, statut "Prévisualisation prête".
```

Limite visuelle : l'inspecteur affiche encore des metadonnees techniques dans une zone de details, mais aucun label runtime/Flame/GameState n'est present et ce n'est pas le workflow principal.

## 22. Checks anti-scope

Anti-round :

```text
Sortie : <vide>
```

Anti-recalcul :

```text
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_manual_path_preview_overlay.dart:297:    final distance = math.sqrt(dx * dx + dy * dy);
```

Justification : cette occurrence dessine uniquement la ligne pointillee du trajet manuel dans `_ManualPathLinePainter`. Elle ne calcule pas la pose actorMove et ne consomme pas `actorPoses`.

Anti runtime/gameplay/battle/examples :

```text
git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle examples/playable_runtime_host
Sortie : <vide>
```

Anti Xcode :

```text
git diff --name-only -- examples/playable_runtime_host/macos/Runner.xcodeproj/project.pbxproj packages/map_editor/macos/Runner.xcodeproj/project.pbxproj
Sortie : <vide>
```

Anti V1-114 screenshot :

```text
find reports/narrativeStudio/scenes/screenshots -maxdepth 1 -name '*v1_114*' -print
Sortie : <vide>
```

Grep anti-scope :

```text
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_manual_path_preview_overlay.dart:12:/// NOTE: This overlay is purely editor-only. Playback interpolation, pathfinding, and actual
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_layer_render_plan.dart:360:    final collisionCells =
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_layer_render_plan.dart:361:        element.collisionProfile?.cells.toSet() ?? const <GridPos>{};
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_layer_render_plan.dart:362:    if (collisionCells.isEmpty) {
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_layer_render_plan.dart:372:        if (collisionCells.contains(GridPos(x: localX, y: localY))) {
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_layer_render_plan.dart:856:    final collisionCells = placement.applyCollision
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_layer_render_plan.dart:857:        ? element.collisionProfile?.cells.toSet() ?? const <GridPos>{}
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_layer_render_plan.dart:860:        collisionCells.isNotEmpty && (source.width > 1 || source.height > 1);
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_layer_render_plan.dart:874:            : (splitByCollision && !collisionCells.contains(localPos)
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:948:        manualPathId: path.id,
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:966:        manualPathId: path.id,
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:985:        manualPathId: path.id,
```

Justification : occurrences preexistantes ou authoring-only. `manualPathId` reste dans la creation/edition du trajet manuel existant, pas cote actorMove runtime. Les references `collisionCells` appartiennent au plan de rendu backdrop deja present.

## 23. Roadmaps mises a jour

Fichiers mis a jour :

```text
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
```

Ajout :

```text
NS-SCENES-V1-113 — Cinematic Actor Playback Smooth Motion / Sub-tile Overlay Polish V0 | DONE
```

Prochain lot :

```text
NS-SCENES-V1-114 — Cinematic Actor Walking Animation Prep Contract
```

## 24. git diff --check/stat/name-only/status final

Dernier `git diff --check` avant creation des rapports :

```text
<vide>
```

Les sorties finales post-rapport sont reproduites dans l'Evidence Pack.

## 25. Risques restants

```text
- Pas encore d'animation de marche : les sprites glissent de facon fluide, mais ne marchent pas visuellement.
- Les infos `prefer_const_*` restent nombreuses dans les gros tests existants ; elles sont non fatales avec la commande demandee.
- La Visual Gate utilise une scene fixture claire et lisible, pas encore la maquette sombre definitive.
- L'inspecteur peut encore afficher des metadonnees techniques dans les details.
```

## 26. Auto-critique

Ce qui est vraiment plus fluide : le rendu playback acteur utilise les coordonnees `double` et bouge avant le seuil d'arrondi.

Ce qui reste rigide : l'absence volontaire de walking animation fait encore glisser le sprite/placeholder sans cycle de pas.

Robustesse sprites/placeholders : couverte par un test overlay direct et par les tests renderer existants. Le meme ancrage bottom-center est conserve.

Diff : le code est localise. Le fichier de test grossit nettement, mais c'est le prix des preuves widget et Visual Gate.

V1-114 : oui, le prochain lot doit cadrer l'animation de marche, sans l'utiliser pour masquer un mouvement saccade.

Bis recommande : non, sauf si l'on veut d'abord retirer les metadonnees techniques visibles de l'inspecteur dans une passe UX separee.

## 27. Verdict final

```text
NS-SCENES-V1-113 : DONE.
Actor playback smooth motion : actif.
Sub-tile positions : conservées en preview.
round/toInt sur poses playback : supprimé.
actorMove direct : fluide.
actorMove manual path : fluide.
Walking animation : non démarrée.
Runtime / Flame / GameState : non touchés.
Pathfinding / collision : absents.
Visual Gate : position intermédiaire prouvée.
V1-114 : Cinematic Actor Walking Animation Prep Contract recommandé, non démarré.
```

## 28. Prochain lot recommande

```text
NS-SCENES-V1-114 — Cinematic Actor Walking Animation Prep Contract
```

Raison : le mouvement sub-tile est maintenant fluide ; l'animation de marche peut etre cadree proprement sans compenser un snapping de position.

## Verdict des passes type sub-agents

```text
Sub-agent Audit / Architecture : PASS — V1-113 peut rester editor-only, map_core deja suffisant.
Sub-agent Implementation : PASS — Option A appliquee, overrides sub-tile ajoutes.
Sub-agent Tests : PASS — tests V1-113, builder, core et suites annexes relances.
Sub-agent Build / Validation : PASS — analyze cible exit 0 et build macOS debug OK.
Sub-agent Critique finale : PASS avec limites — pas de walking animation, infos analyze non fatales, metadata inspector encore visible.
```
