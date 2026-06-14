# NS-SCENES-V1-124 — Cinematic Camera Preview Playback UI V0

## 1. Resume executif

Statut : DONE.

V1-124 branche `CinematicPreviewPlaybackFrame.cameraPose` dans le Cinematic Builder et affiche un overlay camera editor-only dans la preview quand un bloc Camera est actif. L'UI reste honnete : elle montre un cadre symbolique et un label no-code, sans inventer de centre, zoom, cible, follow actor, pan camera ou runtime.

Verdict des passes :
- Passe A audit/regles : PASS, avec `codex_rules.md` absent documente.
- Passe B TDD/implementation : PASS, tests RED observes puis GREEN.
- Passe C visual/anti-scope : PASS, Visual Gate creee et anti-scope runtime/couleurs vide sur le diff code.

## 2. Gate 0

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
5fd4d2f4 NS-SCENES-V1-123 — Cinematic Camera Playback State Read Model V0
636613af NS-SCENES-V1-122 — Cinematic Camera Preview Playback Prep Contract
d6081a24 NS-SCENES-V1-121 — Cinematic Fade Preview Playback V0
035e3346 ns_scenes_v1_120: add cinematic preview playback scrub seek UI and evidence pack
e87152f2 docs(narrativeStudio): add cinematic preview playback scrub seek prep contract and evidence pack
1706e6d3 feat(narrativeStudio): add cinematic playback preview fallback diagnostics and polish
c1692b7d feat(narrativeStudio): integrate cinematic actor walking animation renderer and fix actor move destination isolation
f99e235c feat: cinematic actor walking animation frame resolver v1.115
0ed41a86 docs: mise à jour rapports et roadmaps v1.114
a6b197c0 docs: préparation contrat animation marche acteur cinematic v1.114
```

Etat dirty initial : aucun fichier dirty, `selbrume/project.json` non dirty.

## 3. Fichiers lus

Regles lues : `AGENTS.md`, `agent_rules.md`, `codex_rule.md`, `skills/README.md`, `skills/using-superpowers/SKILL.md`, `skills/test-driven-development/SKILL.md`, `skills/verification-before-completion/SKILL.md`, `skills/writing-plans/SKILL.md`.

Fichier absent : `codex_rules.md`.

Rapports/roadmaps lus : V1-110, V1-118, V1-120, V1-121, V1-122, V1-123, `road_map_scenes.md`, `road_map_scene_builder_authoring.md`.

Code lu : playback plan core, time layout, cinematic asset, barrel `map_core.dart`, Builder, preview panel, viewport transform, fade/fallback/actor/path overlays, library workspace et tests associes.

## 4. Rappel V1-123

V1-123 expose `cameraPose` comme etat pur du playback. Il contient `isActive`, `isSupported`, `supported`, `activeStepId`, `mode`, `progress` et `diagnostics`, mais pas de geometrie camera exploitable (`centerX`, `centerY`, `zoom`, cible ou follow actor).

## 5. Decision d'implementation

V1-124 consomme `playbackFrame.cameraPose` dans le Builder, le transmet au panneau de preview, puis rend un helper editor-only `CinematicCameraPreviewOverlay`.

Le choix discutable est le cadre symbolique : il aide l'utilisateur a comprendre qu'un bloc Camera est actif, mais ne transforme pas le viewport et ne pretend pas a un vrai cadrage.

## 6. Consommation cameraPose

Hunk principal :

```diff
+                                  cameraPose: playbackFrame.cameraPose,
...
+    required this.cameraPose,
...
+  final CinematicCameraPlaybackPose cameraPose;
...
+              cameraPose: cameraPose,
```

## 7. Forme visuelle retenue

Forme retenue : cadre discret dans la preview + badge `Caméra active` + statut no-code.

Supported : `Cadrage caméra prêt`.

Unsupported : premier diagnostic no-code de `cameraPose.diagnostics`, sinon `Prévisualisation caméra partielle`.

## 8. Placement overlay

L'overlay est place dans les stacks de preview bitmap, layer-bitmap et primitives. Il est rendu au-dessus du decor et du fade comme chrome de preview/diagnostic. Une vraie transformation camera future devra s'appliquer sous le fade.

L'overlay est `IgnorePointer`, donc il ne bloque ni seek, ni scrub, ni interactions de preview.

## 9. Design system / couleur

Le helper utilise `context.pokeMapColors` et `PokeMapTone.info/warning`. Aucune couleur hardcodee n'a ete ajoutee : pas de `Colors.black`, `Colors.white`, `Color(0x...)` ou `withOpacity`.

## 10. Supported camera state

Un bloc Camera avec mode V0 supporte (`hold` ou `reset`) affiche le cadre, `Caméra active` et `Cadrage caméra prêt`.

## 11. Unsupported camera state

Un mode inconnu affiche `Caméra non prévisualisée dans cette version.` sans exposer `cameraPose`, `activeStepId`, `unsupported`, `progress`, runtime ou metadata.

## 12. Inactive camera state

Quand `cameraPose.isActive == false`, le helper renvoie `SizedBox.shrink()` et la preview ne montre aucun cadre camera.

## 13. Play / Pause / Stop / Reset

Les tests prouvent que Play revele l'overlay pendant le bloc Camera, Pause fige l'etat visible, Stop et Reset reviennent a l'etat de time 0 sans mutation projet.

## 14. Seek / Scrub

Les tests prouvent que click-to-seek et drag-to-scrub mettent a jour l'overlay camera, sans creer de Mouse Time Probe et sans changer la selection.

## 15. Relation fade / actors / paths

Les regressions V1-121, V1-120, V1-118, V1-117, V1-117-bis et V1-116 restent vertes. Le fade, les acteurs, animations, fallbacks, manual paths, selection cursor, mouse probe et playback playhead restent separes.

## 16. Diagnostics no-code

L'UI affiche un seul message camera principal. Les diagnostics viennent du read model et restent en francais no-code.

## 17. Non-mutation

Les tests V1-124 capturent `project.toJson()`, `asset.toJson()` et `mapData.toJson()` avant/apres interactions. Resultat : aucun changement et `projectChangeCount == 0`.

## 18. Non-objectifs confirmes

Non demarre : V1-125, nouveau modele camera core, centre/zoom/cible, follow actor, pan camera, runtime, Flame, GameState, map_runtime, map_gameplay, map_battle, examples, assets, Selbrume, pathfinding, collision, nouveau fade, nouvelle animation acteur.

## 19. Hygiene de diff

Fichiers modifies :
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart` : passage de `playbackFrame.cameraPose`.
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart` : propagation de `cameraPose` et insertion de l'overlay dans les rendus de preview.
- `packages/map_editor/test/cinematic_builder_workspace_test.dart` : tests V1-124 et Visual Gate.
- `reports/narrativeStudio/scenes/road_map_scenes.md` : V1-124 DONE, V1-125 recommande.
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md` : V1-124 DONE, V1-125 recommande.

Fichiers crees :
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_camera_preview_overlay.dart`
- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_124_cinematic_camera_preview_playback_ui_v0.png`
- ce rapport
- `reports/narrativeStudio/scenes/ns_scenes_v1_124_evidence_pack.md`

Format global : non lance. Format cible uniquement : `dart format test/cinematic_builder_workspace_test.dart`, sortie `Formatted 1 file (0 changed) in 0.13 seconds.`

`map_core`, runtime, Flame et GameState : intacts.

## 20. Tests RED

Tests ajoutes avant implementation :
- `V1-124 active supported camera shows camera preview overlay`
- `V1-124 unsupported camera shows no-code camera fallback message`

Sortie RED observee :

```text
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-124"
Exit 1
Failures:
- V1-124 active supported camera shows camera preview overlay: overlay key absent
- V1-124 unsupported camera shows no-code camera fallback message: overlay key absent
- V1-124 missing camera mode shows Cadrage caméra incomplet: message absent
- V1-124 Play Pause Stop and Reset update camera overlay from playback time: overlay key absent
- V1-124 seek and scrub update camera overlay without probe or selection changes: overlay key absent
```

## 21. Tests GREEN

```text
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-124"
00:03 +7: All tests passed!
```

## 22. Tests executes

```text
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-121"
00:02 +5: All tests passed!

flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-120"
00:04 +9: All tests passed!

flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-118"
00:03 +4: All tests passed!

flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-117"
00:04 +7: All tests passed!

flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-117-bis"
00:02 +1: All tests passed!

flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-116"
00:03 +4: All tests passed!

flutter test --reporter=compact test/cinematic_builder_workspace_test.dart
00:36 +257: All tests passed!

flutter test --reporter=compact test/cinematics_library_workspace_test.dart test/cinematic_stage_point_preview_overlay_test.dart
00:06 +26: All tests passed!

flutter test --reporter=compact test/cinematic_playback_preview_fallback_summary_test.dart
00:01 +5: All tests passed!
```

Depuis `packages/map_core` :

```text
dart test --reporter=compact test/cinematic_preview_playback_plan_test.dart
00:00 +17: All tests passed!

dart test --reporter=compact test/cinematic_timeline_time_layout_read_model_test.dart
00:00 +4: All tests passed!

dart test --reporter=compact test/cinematic_actor_display_preview_model_test.dart
00:00 +27: All tests passed!

dart analyze
Analyzing map_core...
No issues found!
```

## 23. Analyse statique

```text
flutter analyze --no-fatal-infos lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart lib/src/ui/canvas/cinematics/cinematic_camera_preview_overlay.dart test/cinematic_builder_workspace_test.dart test/cinematics_library_workspace_test.dart
Analyzing 5 items...
37 issues found. (ran in 1.6s)
Exit 0
```

Les 37 issues sont des infos `prefer_const_*` existantes dans le gros fichier Builder/test. Aucune erreur analyzer et aucune issue bloquante.

## 24. Build macOS debug

```text
flutter build macos --debug
Building macOS application...
✓ Built build/macos/Build/Products/Debug/map_editor.app
```

## 25. Visual Gate

Fichier :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_124_cinematic_camera_preview_playback_ui_v0.png
```

Preuves :

```text
ls -lh reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_124_cinematic_camera_preview_playback_ui_v0.png
-rw-r--r--  1 karim  staff   212K Jun 14 12:27 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_124_cinematic_camera_preview_playback_ui_v0.png

file reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_124_cinematic_camera_preview_playback_ui_v0.png
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_124_cinematic_camera_preview_playback_ui_v0.png: PNG image data, 1663 x 926, 8-bit/color RGBA, non-interlaced

shasum -a 256 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_124_cinematic_camera_preview_playback_ui_v0.png
f32320c3bccd6047dbc88f094ca6baf336b1a903559dc85f36b3764f2937f67f  reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_124_cinematic_camera_preview_playback_ui_v0.png
```

La capture montre le Builder, la preview, la timeline, un bloc Camera, le playhead `Lecture`, le cadre camera, `Caméra active`, `Cadrage caméra prêt` et les transports.

## 26. Checks anti-scope

Avant ajout des rapports, sur le diff code :

```text
git diff --unified=0 | rg -n "package:flame|GameState|PlayableMapGame|SceneRuntimeExecutor|CinematicRuntimeAdapter|map_runtime|map_gameplay|CameraComponent|Timer\\.periodic|Future\\.delayed|Stream\\.periodic|DateTime\\.now|V1-125" || true
Sortie : <vide>

git diff --unified=0 | rg -n "Colors\\.black|Colors\\.white|Color\\(0x|withOpacity\\(" || true
Sortie : <vide>

git diff --name-only -- packages/map_core packages/map_runtime packages/map_gameplay packages/map_battle examples/playable_runtime_host assets selbrume
Sortie : <vide>

find reports/narrativeStudio/scenes/screenshots -maxdepth 1 -name '*v1_125*' -print
Sortie : <vide>
```

Recherche technique dans le code : les occurrences de `cameraPose` sont des variables/types, pas des labels UX principaux.

## 27. Roadmaps mises a jour

Roadmaps modifiees :
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

Elles marquent V1-124 DONE et recommandent :

```text
NS-SCENES-V1-125 — Cinematic Camera Target / Zoom Authoring Prep Contract
```

## 28. git diff --check/stat/name-only/status final

```text
git diff --check
Sortie : <vide>

git diff --stat
 .../cinematics/cinematic_builder_workspace.dart    |   4 +
 .../cinematic_map_backdrop_preview_panel.dart      |  31 ++
 .../test/cinematic_builder_workspace_test.dart     | 527 +++++++++++++++++++++
 .../scenes/road_map_scene_builder_authoring.md     |  43 +-
 reports/narrativeStudio/scenes/road_map_scenes.md  |  48 +-
 5 files changed, 622 insertions(+), 31 deletions(-)

git diff --name-only
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md

git status --short --untracked-files=all
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart
 M packages/map_editor/test/cinematic_builder_workspace_test.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_camera_preview_overlay.dart
?? reports/narrativeStudio/scenes/ns_scenes_v1_124_cinematic_camera_preview_playback_ui_v0.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_124_evidence_pack.md
?? reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_124_cinematic_camera_preview_playback_ui_v0.png
```

Note : `git diff --stat` et `git diff --name-only` ne listent pas les fichiers non suivis ; le statut final ci-dessus les liste explicitement.

## 29. Risques restants

Le cadre symbolique peut suggerer un cadrage alors qu'aucun centre/zoom n'existe encore. Le wording `Cadrage caméra prêt` est volontairement borne : il signifie que l'etat camera V0 est compris, pas qu'un vrai pan/zoom est rendu.

## 30. Auto-critique

L'UI est utile pour comprendre qu'un bloc Camera est actif, mais elle reste une etape intermediaire. Le cadre peut etre interprete comme une safe area reelle ; V1-125 est donc necessaire pour cadrer cible/zoom authoring avant toute geometrie. La separation viewport editor / cinematic camera reste claire dans le code grace au helper preview-only et a l'absence de mutation de framing/pan/zoom.

Bis recommande : non, sauf si l'equipe veut renommer `Cadrage caméra prêt` en `Caméra active prête` pour reduire encore l'ambiguite.

## 31. Verdict final

NS-SCENES-V1-124 : DONE.

Camera Preview UI : active.

cameraPose V1-123 : consomme.

Supported camera : overlay + label no-code.

Unsupported camera : message no-code.

Inactive camera : overlay absent.

Editor Viewport : non mute.

Pan/zoom reel : non invente.

Runtime / Flame / GameState : non touches.

map_core : non modifie.

Visual Gate : creee.

V1-125 : recommande, non demarre.

## 32. Prochain lot recommande

```text
NS-SCENES-V1-125 — Cinematic Camera Target / Zoom Authoring Prep Contract
```

## Annexe — code genere

Contenu complet du helper cree :

```dart
import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../../theme/theme.dart';
import '../../design_system/design_system.dart';

class CinematicCameraPreviewOverlay extends StatelessWidget {
  const CinematicCameraPreviewOverlay({
    super.key,
    required this.cameraPose,
    required this.compact,
  });

  final CinematicCameraPlaybackPose cameraPose;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (!cameraPose.isActive) {
      return const SizedBox.shrink();
    }

    final tone = cameraPose.isSupported
        ? PokeMapTone.info.resolve(context)
        : PokeMapTone.warning.resolve(context);
    final colors = context.pokeMapColors;
    final statusLabel = _cameraPreviewStatusLabel(cameraPose);
    final frameInset = compact ? 10.0 : 16.0;

    // This overlay is preview chrome only: V1-123 exposes camera activity and
    // diagnostics, but no center/zoom/follow geometry to apply to the editor
    // viewport. V1-124 therefore signals the active camera honestly without
    // pretending to pan or zoom the map.
    return IgnorePointer(
      key: const ValueKey('cinematic-builder-camera-preview-overlay'),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.all(frameInset),
              child: DecoratedBox(
                key: const ValueKey('cinematic-builder-camera-preview-frame'),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: tone.border,
                    width: compact ? 1.5 : 2,
                  ),
                  borderRadius: BorderRadius.circular(compact ? 8 : 10),
                ),
              ),
            ),
          ),
          Positioned(
            left: frameInset + 2,
            top: frameInset + (compact ? 34 : 42),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: compact ? 220 : 300),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: tone.soft,
                  border: Border.all(color: tone.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 8 : 10,
                    vertical: compact ? 6 : 8,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        CupertinoIcons.video_camera,
                        color: tone.icon,
                        size: compact ? 14 : 16,
                      ),
                      SizedBox(width: compact ? 6 : 8),
                      Flexible(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Caméra active',
                              key: const ValueKey(
                                'cinematic-builder-camera-preview-label',
                              ),
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: compact ? 11 : 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              statusLabel,
                              key: const ValueKey(
                                'cinematic-builder-camera-preview-status',
                              ),
                              style: TextStyle(
                                color: cameraPose.isSupported
                                    ? tone.text
                                    : colors.textPrimary,
                                fontSize: compact ? 10 : 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _cameraPreviewStatusLabel(CinematicCameraPlaybackPose cameraPose) {
  if (cameraPose.isSupported) {
    return 'Cadrage caméra prêt';
  }
  for (final diagnostic in cameraPose.diagnostics) {
    final message = diagnostic.message.trim();
    if (message.isNotEmpty) {
      return message;
    }
  }
  return 'Prévisualisation caméra partielle';
}
```
