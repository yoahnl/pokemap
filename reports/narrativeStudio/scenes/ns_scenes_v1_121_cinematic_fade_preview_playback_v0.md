# NS-SCENES-V1-121 — Cinematic Fade Preview Playback V0

Verdict : `NS-SCENES-V1-121 — Cinematic Fade Preview Playback V0` est DONE.

## Synthese

V1-121 ajoute la previsualisation editor-only des blocs `Fondu` dans le Cinematic Builder. L'UI consomme uniquement `CinematicPreviewPlaybackFrame.fadeState`, deja expose par le read model V1-110, puis peint un overlay passif dans la frame de preview. Le fade suit Play/Pause/Stop/Reset, click-to-seek et drag-to-scrub, sans muter `CinematicAsset`, `ProjectManifest` ou `MapData`.

Le lot ne demarre pas V1-122. Le prochain lot recommande reste seulement : `NS-SCENES-V1-122 — Cinematic Camera Preview Playback Prep Contract`.

## Audit initial

- Prompt lu : `/Users/karim/.codex/attachments/6fe569c7-5c49-44f2-9fcb-27c5f3b93a14/pasted-text.txt`.
- Regles lues : `AGENTS.md`, `codex_rule.md`, `skills/README.md`, skills locales `using-superpowers`, `writing-plans`, `test-driven-development`, `verification-before-completion`.
- Rapports/audits relus : V1-110, V1-111, V1-118, V1-119, V1-120 et historiques timeline/visual V1-45/V1-51/V1-68/V1-69/V1-70.
- Code audite : `cinematic_preview_playback_plan.dart`, `cinematic_builder_workspace.dart`, `cinematic_map_backdrop_preview_panel.dart`, tests Builder et tests read-model core.

Etat Git initial :

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

Dernier log initial :

```text
035e3346 ns_scenes_v1_120: add cinematic preview playback scrub seek UI and evidence pack
e87152f2 docs(narrativeStudio): add cinematic preview playback scrub seek prep contract and evidence pack
1706e6d3 feat(narrativeStudio): add cinematic playback preview fallback diagnostics and polish
c1692b7d feat(narrativeStudio): integrate cinematic actor walking animation renderer and fix actor move destination isolation
f99e235c feat: cinematic actor walking animation frame resolver v1.115
0ed41a86 docs: mise à jour rapports et roadmaps v1.114
a6b197c0 docs: préparation contrat animation marche acteur cinematic v1.114
2dff3a1e feat: cinematic actor playback smooth motion v1.113
d41f5874 feat: cinematic actorMove preview playback v1.112
e41f5874 update selbrume
```

## Decisions

- Source de verite : `CinematicPreviewPlaybackFrame.fadeState`.
- Aucun second moteur de fade dans l'UI : l'UI ne calcule ni `fadeIn` ni `fadeOut`; elle clamp uniquement l'opacite recue avant peinture.
- Placement : l'overlay est ajoute dans la preview map frame, au-dessus du decor, des acteurs, du trajet manuel et des badges, mais pas au-dessus de la timeline, de la palette ou de l'inspecteur.
- Interaction : l'overlay est `IgnorePointer`, donc il ne capture ni clics ni drags.
- Couleur : aucun `Colors.black`, `Colors.white`, `Color(0x...)` ou `withOpacity`; le helper choisit le token theme le plus sombre entre `textPrimary` et `textInverse`, puis applique `Opacity`.
- Limite volontaire : hors d'un `fadeState` actif, l'overlay n'est pas peint. Le lot ne prolonge pas artificiellement un fondu apres la fin du bloc.

## Fichiers modifies

- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart`
- `packages/map_editor/test/cinematic_builder_workspace_test.dart`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

## Fichiers crees

- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_fade_preview_overlay.dart`
- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_121_cinematic_fade_preview_playback_v0.png`
- `reports/narrativeStudio/scenes/ns_scenes_v1_121_cinematic_fade_preview_playback_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_121_evidence_pack.md`

## Contenu complet du helper cree

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

## Zones modifiees

- Builder : passage de `playbackFrame.fadeState` vers `_PreviewSandbox`, puis vers `CinematicMapBackdropPreviewPanel`.
- Backdrop preview panel : propagation optionnelle de `fadeState` dans les trois chemins de rendu existants, bitmap map, layer bitmap map et primitive fallback.
- Overlay : nouveau widget passif editor-only.
- Tests : ajout de tests V1-121 pour fade out, fade in, seek, drag-to-scrub, non-mutation et Visual Gate.
- Roadmaps : V1-121 marque DONE et prochain lot recommande aligne sur V1-122.

## TDD

RED initial apres ajout des tests :

```text
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-121"
Exit 1
Bad state: No element
Cause attendue : l'overlay `cinematic-builder-fade-preview-opacity` n'existait pas encore.
```

GREEN final :

```text
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-121"
00:04 +5: All tests passed!
```

## Tests et analyses

Toutes les commandes ont ete lancees depuis le package indique.

```text
cd packages/map_editor
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

```text
cd packages/map_core
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

```text
cd packages/map_editor
flutter analyze --no-fatal-infos lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart lib/src/ui/canvas/cinematics/cinematic_fade_preview_overlay.dart test/cinematic_builder_workspace_test.dart test/cinematics_library_workspace_test.dart
Analyzing 5 items...
37 issues found. (ran in 2.8s)
```

Analyse ciblée : exit 0. Les 37 issues sont des infos `prefer_const_*` historiques dans les fichiers analyses; aucune erreur ni warning bloquant.

```text
cd packages/map_editor
flutter build macos --debug
Building macOS application...
✓ Built build/macos/Build/Products/Debug/map_editor.app
```

## Visual Gate

Fichier :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_121_cinematic_fade_preview_playback_v0.png
```

Commande :

```text
cd packages/map_editor
flutter test --update-goldens --reporter=compact --dart-define=NS_SCENES_V1_121_CAPTURE_CINEMATIC_FADE_PREVIEW_PLAYBACK=true test/cinematic_builder_workspace_test.dart --name "captures V1-121 cinematic fade preview playback visual gate"
00:05 +1: All tests passed!
```

Preuves fichier :

```text
ls -lh reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_121_cinematic_fade_preview_playback_v0.png
-rw-r--r--  1 karim  staff   207K Jun 13 23:19 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_121_cinematic_fade_preview_playback_v0.png

file reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_121_cinematic_fade_preview_playback_v0.png
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_121_cinematic_fade_preview_playback_v0.png: PNG image data, 1663 x 926, 8-bit/color RGBA, non-interlaced

shasum -a 256 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_121_cinematic_fade_preview_playback_v0.png
e728869979d5cfdca17c5e456051b5449ded1c7045759f667097d69330fa0c8e  reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_121_cinematic_fade_preview_playback_v0.png
```

Validation visuelle : Cinematic Builder ouvert, preview visible avec overlay de fondu, timeline visible, bloc `Fondu sortant` visible, playhead a temps non nul, statut `Lecture en pause`, transport visible, inspecteur non technique, aucun runtime/Flame/GameState visible.

## Anti-scope

```text
git diff --unified=0 | rg -n "package:flame|GameState|PlayableMapGame|SceneRuntimeExecutor|CinematicRuntimeAdapter|map_runtime|map_gameplay|Timer\\.periodic|Future\\.delayed|Stream\\.periodic|DateTime\\.now|RouteSegment|pathfinding|collision|V1-122"
73:-      expect(find.text('GameState'), findsNothing);
```

Interpretation : seul match avant rapports = ligne retiree du diff, donc ancien faux positif supprime. Aucun ajout produit ne contient ces termes. Apres rapports/roadmaps, `V1-122` apparait uniquement comme prochain lot documentaire recommande.

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

## Roadmaps

Roadmaps mises a jour :

- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

Elles marquent V1-121 DONE et pointent vers `NS-SCENES-V1-122 — Cinematic Camera Preview Playback Prep Contract` comme prochain lot recommande, sans demarrer V1-122.

## Passes de revue

- Passe audit/architecture : PASS. La source reste `fadeState`; pas de second moteur.
- Passe UI/design-system : PASS. Overlay dans la preview seulement, tokens de theme, pas de couleur hardcodee.
- Passe tests : PASS. Tests ciblés et regressions relances.
- Passe anti-scope : PASS avec note sur un faux positif retire dans une ligne supprimee du diff.
- Passe documentation : PASS. Rapports et roadmaps alignes.

Aucun sub-agent separe n'a ete lance; les passes ci-dessus ont ete faites dans ce thread.

## Limites et risques

- La preview ne persiste pas l'etat de fondu apres la fin du bloc; elle suit strictement le read model.
- La couleur de fade est derivee des tokens disponibles; un token semantique dedie au scrim pourrait etre ajoute plus tard dans le design system si necessaire.
- L'analyse editor ciblée reste verbeuse avec 37 infos `prefer_const_*`, mais exit 0 et hors scope V1-121.
- La Visual Gate est une capture de harness test, pas une manipulation manuelle de l'application macOS.

## Auto-critique finale

Le lot est volontairement petit et conforme au contrat. Le principal risque aurait ete de recalculer une progression de fade dans l'UI; ce n'est pas fait. Le second risque etait de masquer l'outil complet avec un scrim global; l'overlay est limite a la preview map frame. Le dernier point imparfait est l'absence d'un token scrim explicite; le choix du token le plus sombre est acceptable pour V0 car il evite les couleurs hardcodees.

## Verdict

`NS-SCENES-V1-121 — Cinematic Fade Preview Playback V0` : DONE.

Prochain lot recommande uniquement : `NS-SCENES-V1-122 — Cinematic Camera Preview Playback Prep Contract`.
