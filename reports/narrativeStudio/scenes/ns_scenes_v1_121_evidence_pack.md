# NS-SCENES-V1-121 — Evidence Pack

Verdict : `NS-SCENES-V1-121 — Cinematic Fade Preview Playback V0` est DONE.

## Portee

Objectif execute : previsualiser les blocs `Fondu` dans le Cinematic Builder pendant la lecture locale, en consommant `CinematicPreviewPlaybackFrame.fadeState`.

Non-objectifs respectes :

- pas de runtime ;
- pas de Flame ;
- pas de GameState ;
- pas de modification `map_core` ;
- pas de pathfinding ;
- pas de collision ;
- pas de nouvelle interpolation acteur ;
- pas de persistance de temps playback ;
- pas de mutation projet ;
- pas de V1-122 demarre.

## Audit initial

Etat initial :

```text
pwd
/Users/karim/Project/pokemonProject

git branch --show-current
main

git status --short --untracked-files=all
<vide>

git diff --stat
<vide>

git diff --name-only
<vide>
```

Lecture obligatoire faite : prompt V1-121, `AGENTS.md`, `codex_rule.md`, `skills/README.md`, skills locales selectionnees, rapports/evidence V1-110/V1-111/V1-118/V1-119/V1-120, roadmaps scenes, code core/editor/tests ciblé.

## Inventaire fichiers

Modifies :

```text
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

Crees :

```text
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_fade_preview_overlay.dart
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_121_cinematic_fade_preview_playback_v0.png
reports/narrativeStudio/scenes/ns_scenes_v1_121_cinematic_fade_preview_playback_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_121_evidence_pack.md
```

## Diffs et zones

```text
git diff --stat
 .../cinematics/cinematic_builder_workspace.dart    |   4 +
 .../cinematic_map_backdrop_preview_panel.dart      |  29 ++
 .../test/cinematic_builder_workspace_test.dart     | 354 ++++++++++++++++++++-
 .../scenes/road_map_scene_builder_authoring.md     |  39 ++-
 reports/narrativeStudio/scenes/road_map_scenes.md  |  44 ++-
 5 files changed, 442 insertions(+), 28 deletions(-)
```

Note : ce stat ne compte pas les fichiers non suivis non stages, dont le nouveau helper, la capture et les rapports.

Zones exactes :

- `cinematic_builder_workspace.dart` : ajout du passage de `fadeState: playbackFrame.fadeState`.
- `cinematic_map_backdrop_preview_panel.dart` : propagation du `fadeState` et insertion de `CinematicFadePreviewOverlay` dans les trois rendus de preview.
- `cinematic_fade_preview_overlay.dart` : widget overlay passif.
- `cinematic_builder_workspace_test.dart` : tests V1-121 + fixture fade + helper opacite + Visual Gate.
- Roadmaps : V1-121 DONE et V1-122 recommande.

## Contenu complet du fichier de code cree

```dart
import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../../theme/theme.dart';

class CinematicFadePreviewOverlay extends StatelessWidget {
  const CinematicFadePreviewOverlay({
    super.key,
    required this.fadeState,
  });

  final CinematicFadePlaybackState fadeState;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final opacity = fadeState.opacity.clamp(0.0, 1.0).toDouble();
    return IgnorePointer(
      key: const ValueKey('cinematic-builder-fade-preview-overlay'),
      child: Opacity(
        key: const ValueKey('cinematic-builder-fade-preview-opacity'),
        opacity: opacity,
        child: ColoredBox(
          color: _darkestTokenColor(colors),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

Color _darkestTokenColor(PokeMapColorTokens colors) {
  final primaryLuminance = colors.textPrimary.computeLuminance();
  final inverseLuminance = colors.textInverse.computeLuminance();
  return primaryLuminance <= inverseLuminance
      ? colors.textPrimary
      : colors.textInverse;
}
```

## Preuve TDD

RED :

```text
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-121"
Exit 1
Bad state: No element
```

Cause : les tests cherchaient `cinematic-builder-fade-preview-opacity` et `cinematic-builder-fade-preview-overlay` avant implementation.

GREEN :

```text
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-121"
00:04 +5: All tests passed!
```

## Commandes tests

`packages/map_editor` :

```text
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-121"
00:04 +5: All tests passed!

flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-120"
00:08 +9: All tests passed!

flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-118"
00:04 +4: All tests passed!

flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-117"
00:04 +7: All tests passed!

flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-117-bis"
00:02 +1: All tests passed!

flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-116"
00:06 +4: All tests passed!

flutter test --reporter=compact test/cinematic_builder_workspace_test.dart
00:44 +250: All tests passed!

flutter test --reporter=compact test/cinematics_library_workspace_test.dart test/cinematic_stage_point_preview_overlay_test.dart
00:07 +26: All tests passed!

flutter test --reporter=compact test/cinematic_playback_preview_fallback_summary_test.dart
00:01 +5: All tests passed!
```

`packages/map_core` :

```text
dart test --reporter=compact test/cinematic_preview_playback_plan_test.dart
+12: All tests passed!

dart test --reporter=compact test/cinematic_timeline_time_layout_read_model_test.dart
+4: All tests passed!

dart test --reporter=compact test/cinematic_actor_display_preview_model_test.dart
+27: All tests passed!

dart analyze
Analyzing map_core...
No issues found!
```

## Analyse et build

```text
flutter analyze --no-fatal-infos lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart lib/src/ui/canvas/cinematics/cinematic_fade_preview_overlay.dart test/cinematic_builder_workspace_test.dart test/cinematics_library_workspace_test.dart
Analyzing 5 items...
37 issues found. (ran in 2.8s)
```

Exit 0. Les 37 issues sont uniquement des infos `prefer_const_*`.

```text
flutter build macos --debug
Building macOS application...
✓ Built build/macos/Build/Products/Debug/map_editor.app
```

## Visual Gate

Commande :

```text
flutter test --update-goldens --reporter=compact --dart-define=NS_SCENES_V1_121_CAPTURE_CINEMATIC_FADE_PREVIEW_PLAYBACK=true test/cinematic_builder_workspace_test.dart --name "captures V1-121 cinematic fade preview playback visual gate"
00:05 +1: All tests passed!
```

Fichier :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_121_cinematic_fade_preview_playback_v0.png
```

Preuves :

```text
ls -lh reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_121_cinematic_fade_preview_playback_v0.png
-rw-r--r--  1 karim  staff   207K Jun 13 23:19 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_121_cinematic_fade_preview_playback_v0.png

file reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_121_cinematic_fade_preview_playback_v0.png
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_121_cinematic_fade_preview_playback_v0.png: PNG image data, 1663 x 926, 8-bit/color RGBA, non-interlaced

shasum -a 256 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_121_cinematic_fade_preview_playback_v0.png
e728869979d5cfdca17c5e456051b5449ded1c7045759f667097d69330fa0c8e  reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_121_cinematic_fade_preview_playback_v0.png
```

Checklist visuelle :

- Cinematic Builder ouvert : oui.
- Preview visible : oui.
- Bloc Fondu visible dans la timeline : oui.
- Playhead a temps non nul pendant fade : oui.
- Overlay fade visible : oui.
- Transport visible : oui.
- Statut lecture/pause visible : oui.
- Aucun runtime/Flame/GameState visible : oui.

## Anti-scope

```text
git diff --unified=0 | rg -n "package:flame|GameState|PlayableMapGame|SceneRuntimeExecutor|CinematicRuntimeAdapter|map_runtime|map_gameplay|Timer\\.periodic|Future\\.delayed|Stream\\.periodic|DateTime\\.now|RouteSegment|pathfinding|collision|V1-122"
73:-      expect(find.text('GameState'), findsNothing);
```

Verdict : match uniquement dans une ligne supprimee avant rapports; aucun ajout produit. Les occurrences finales de V1-122 sont documentaires dans roadmaps/rapports.

```text
git diff --unified=0 | rg -n "Colors\\.black|Colors\\.white|Color\\(0x|withOpacity\\("
<vide>

rg -n "Colors\\.black|Colors\\.white|Color\\(0x|withOpacity\\(|package:flame|GameState|PlayableMapGame|SceneRuntimeExecutor|CinematicRuntimeAdapter|map_runtime|map_gameplay|Timer\\.periodic|Future\\.delayed|Stream\\.periodic|DateTime\\.now|RouteSegment|pathfinding|collision|V1-122" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_fade_preview_overlay.dart
<vide>

git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle examples/playable_runtime_host assets selbrume
<vide>

find reports/narrativeStudio/scenes/screenshots -maxdepth 1 -name '*v1_122*' -print
<vide>
```

## Roadmap evidence

Roadmaps alignees :

```text
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
```

Header global et sections recentes pointent vers :

```text
NS-SCENES-V1-122 — Cinematic Camera Preview Playback Prep Contract
```

V1-121 est marque DONE; V1-122 n'est pas demarre.

## Controles finaux apres rapports

```text
rg -n "Prochain lot exact recommande|Prochain lot exact recommandé|NS-SCENES-V1-121 — Cinematic Fade Preview Playback V0|NS-SCENES-V1-122 — Cinematic Camera Preview Playback Prep Contract" reports/narrativeStudio/scenes/road_map_scenes.md reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md:187:| NS-SCENES-V1-121 — Cinematic Fade Preview Playback V0 | DONE | Prévisualiser les blocs Fondu dans le Cinematic Builder avec un overlay editor-only piloté par `CinematicPreviewPlaybackFrame.fadeState`, réactif à Play/Pause/Stop/Reset/seek/scrub, sans runtime, Flame, GameState, mutation projet ni couleurs hardcodées. |
reports/narrativeStudio/scenes/road_map_scenes.md:189:## Prochain lot exact recommande
reports/narrativeStudio/scenes/road_map_scenes.md:191:`NS-SCENES-V1-122 — Cinematic Camera Preview Playback Prep Contract`
reports/narrativeStudio/scenes/road_map_scenes.md:217:22. `NS-SCENES-V1-121 — Cinematic Fade Preview Playback V0` (DONE)
reports/narrativeStudio/scenes/road_map_scenes.md:218:23. `NS-SCENES-V1-122 — Cinematic Camera Preview Playback Prep Contract` (recommande, non demarre)
reports/narrativeStudio/scenes/road_map_scenes.md:222:Statut : `NS-SCENES-V1-121 — Cinematic Fade Preview Playback V0` est DONE.
reports/narrativeStudio/scenes/road_map_scenes.md:232:Prochain lot recommande : `NS-SCENES-V1-122 — Cinematic Camera Preview Playback Prep Contract`.
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md:9:## Prochain lot exact recommande
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md:12:NS-SCENES-V1-122 — Cinematic Camera Preview Playback Prep Contract
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md:180:Statut : `NS-SCENES-V1-121 — Cinematic Fade Preview Playback V0` est DONE.
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md:188:Prochain lot recommande : `NS-SCENES-V1-122 — Cinematic Camera Preview Playback Prep Contract`.
```

Sortie complete plus longue : les autres occurrences V1-122 sont des notes historiques alignees dans les memes roadmaps; aucune section recente ne presente V1-121 comme prochain lot.

```text
git diff --check
<vide>

git diff --stat
 .../cinematics/cinematic_builder_workspace.dart    |   4 +
 .../cinematic_map_backdrop_preview_panel.dart      |  29 ++
 .../test/cinematic_builder_workspace_test.dart     | 354 ++++++++++++++++++++-
 .../scenes/road_map_scene_builder_authoring.md     |  39 ++-
 reports/narrativeStudio/scenes/road_map_scenes.md  |  44 ++-
 5 files changed, 442 insertions(+), 28 deletions(-)

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
?? packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_fade_preview_overlay.dart
?? reports/narrativeStudio/scenes/ns_scenes_v1_121_cinematic_fade_preview_playback_v0.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_121_evidence_pack.md
?? reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_121_cinematic_fade_preview_playback_v0.png
```

Anti-scope final :

```text
git diff --unified=0 | rg -n "package:flame|GameState|PlayableMapGame|SceneRuntimeExecutor|CinematicRuntimeAdapter|map_runtime|map_gameplay|Timer\\.periodic|Future\\.delayed|Stream\\.periodic|DateTime\\.now|RouteSegment|pathfinding|collision|V1-122"
73:-      expect(find.text('GameState'), findsNothing);
436:+NS-SCENES-V1-122 — Cinematic Camera Preview Playback Prep Contract
438:+| NS-SCENES-V1-121 | Cinematic Fade Preview Playback V0 | editor / preview-sandbox | Prévisualiser les blocs Fondu dans le Cinematic Builder avec un overlay editor-only piloté par `CinematicPreviewPlaybackFrame.fadeState`. | Pas de V1-122, runtime, Flame, GameState, map_core, pathfinding, collision, interpolation acteur, nouvelle persistance, mutation projet ou couleurs hardcodées. | `cinematic_builder_workspace.dart`, `cinematic_map_backdrop_preview_panel.dart`, `cinematic_fade_preview_overlay.dart`, tests Builder, Visual Gate, rapport, Evidence Pack, roadmaps. | Tests V1-121, regressions V1-120/V1-118/V1-117/V1-117-bis/V1-116, Builder complet, Library/overlay, fallback summary, core ciblé, analyse ciblée, build macOS debug. | Recalculer le fade dans l'UI ; couvrir timeline/inspecteur ; bloquer les interactions ; hardcoder une couleur noire. | DONE : fadeState du playback frame consommé, overlay dans la preview uniquement, Play/Pause/Stop/Reset/seek/scrub couverts, non-mutation et anti-scope confirmés. | V1-120 |
448:+Limites : aucun runtime, Flame, GameState, map_core, pathfinding, collision, interpolation acteur, nouvelle persistance, couleurs hardcodées ou V1-122 n'a ete demarre.
450:+Prochain lot recommande : `NS-SCENES-V1-122 — Cinematic Camera Preview Playback Prep Contract`.
492:+| NS-SCENES-V1-121 — Cinematic Fade Preview Playback V0 | DONE | Prévisualiser les blocs Fondu dans le Cinematic Builder avec un overlay editor-only piloté par `CinematicPreviewPlaybackFrame.fadeState`, réactif à Play/Pause/Stop/Reset/seek/scrub, sans runtime, Flame, GameState, mutation projet ni couleurs hardcodées. |
495:+`NS-SCENES-V1-122 — Cinematic Camera Preview Playback Prep Contract`
502:+23. `NS-SCENES-V1-122 — Cinematic Camera Preview Playback Prep Contract` (recommande, non demarre)
514:+Limites : l'overlay ne prolonge pas artificiellement un fade au-dela du `fadeState` fourni par le plan. Aucun runtime, Flame, GameState, map_core, pathfinding, collision, interpolation acteur, mutation projet ou V1-122 n'a ete demarre.
516:+Prochain lot recommande : `NS-SCENES-V1-122 — Cinematic Camera Preview Playback Prep Contract`.
```

Interpretation : matches documentaires dans les roadmaps et ligne `GameState` retiree du test; aucun ajout produit interdit.

```text
git diff --unified=0 | rg -n "Colors\\.black|Colors\\.white|Color\\(0x|withOpacity\\("
<vide>

git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle examples/playable_runtime_host assets selbrume
<vide>

find reports/narrativeStudio/scenes/screenshots -maxdepth 1 -name '*v1_122*' -print
<vide>
```

## Passes / sub-agents

Aucun sub-agent separe n'a ete lance.

- Audit contrat/read-model : PASS.
- TDD : PASS.
- Implementation UI : PASS.
- Visual Gate : PASS.
- Anti-scope : PASS.
- Documentation/roadmaps : PASS.

## Limites restantes

- Le fade visible suit strictement `fadeState`; il ne simule pas une persistence post-bloc.
- La Visual Gate reste produite par harness de test.
- L'analyse editor ciblée garde des infos `prefer_const_*` hors scope, non bloquantes.
- Le helper utilise des tokens existants; un futur token scrim pourrait ameliorer la semantique.

## Auto-critique

Le lot respecte le contrat preview-only. Le choix le plus fragile est le token de couleur derive par luminance, mais il evite les hardcodes et reste localise. Les tests couvrent les chemins essentiels : fade in/out, seek, scrub, pause, stop, non-mutation et passivite de l'overlay.

## Verdict final

`NS-SCENES-V1-121 : DONE — Cinematic Fade Preview Playback V0.`

Prochain lot recommande : `NS-SCENES-V1-122 — Cinematic Camera Preview Playback Prep Contract`.
