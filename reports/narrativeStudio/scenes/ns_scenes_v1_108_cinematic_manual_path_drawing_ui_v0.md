# NS-SCENES-V1-108 — Cinematic Manual Path Drawing UI V0

## Verdict V1-108-ter

`NS-SCENES-V1-108-ter : DONE — clôture preuve/Visual Gate uniquement.`

V1-108 est considéré **DONE uniquement parce que la Visual Gate V1-108-ter a été régénérée, inspectée visuellement et validée**. Cette passe ne démarre pas V1-109.

Les anciens rapports/addendums `V1-108-bis` sont conservés comme notes de correction historiques. La source principale de clôture est maintenant ce rapport et `ns_scenes_v1_108_evidence_pack.md`.

## Audit Initial

Règles lues avant mise à jour du rapport :

- `AGENTS.md` via les instructions repo actives.
- `agent_rules.md`.
- `codex_rule.md`.
- `codex_rules.md` : absent, sortie observée `codex_rules.md MISSING`.

État initial rappelé par la session avant cette clôture :

```text
/Users/karim/Project/pokemonProject
main
 M selbrume/project.json
 selbrume/project.json | 39 +++++++++++++++++++++++++++++++++++----
 1 file changed, 35 insertions(+), 4 deletions(-)
selbrume/project.json
```

Pendant la clôture, aucun `git add`, `git commit`, `git reset`, `git restore`, `git checkout`, `git stash` ou autre commande Git d'écriture n'a été lancé.

## Scope Réel

Inclus :

- régénération de `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_108_cinematic_manual_path_drawing_ui_v0.png` ;
- correction test-only du scénario de capture pour montrer deux points de passage et recadrer l'inspecteur sur `Trajet` ;
- relance des tests demandés ;
- analyse ciblée demandée ;
- alignement des deux roadmaps vers `NS-SCENES-V1-109 — Cinematic Preview Playback Prep Contract` ;
- mise à jour des rapports.

Exclus :

- runtime ;
- Flame ;
- playback ;
- interpolation ;
- pathfinding ;
- collision ;
- nouvelle feature audio ;
- nouveau système multi-acteurs ;
- V1-109 ;
- `manualPathId` côté `actorMove` ;
- waypoints libres ;
- coordonnées libres.

## Visual Gate

Capture régénérée :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_108_cinematic_manual_path_drawing_ui_v0.png
```

Commande de génération :

```bash
cd packages/map_editor
flutter test --update-goldens --reporter=compact --dart-define=NS_SCENES_V1_108_CAPTURE_MANUAL_PATH_DRAWING_UI=true test/cinematic_builder_workspace_test.dart --plain-name "captures V1-108 cinematic manual path drawing ui visual gate when requested"
```

Sortie :

```text
00:03 +1: All tests passed!
```

Inspection visuelle Codex :

- Cinematic Builder ouvert.
- Bloc `Déplacer un acteur` / actorMove sélectionné.
- Inspecteur `Action` visible.
- Section `Trajet` visible.
- Mode `Manuel` visible et sélectionné.
- Liste de points de passage visible avec `Point 3` et `Point 4`.
- Ligne de trajet visible dans la preview.
- Badges numérotés visibles dans la preview et dans la liste.
- Timeline `Déroulé` visible.
- Aucun ID technique n'est utilisé comme workflow principal ; les contrôles visibles restent no-code (`Trajet`, `Manuel`, `Repère`, `Destination`, `Point`).

Preuves fichier demandées :

```bash
ls -lh reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_108_cinematic_manual_path_drawing_ui_v0.png
file reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_108_cinematic_manual_path_drawing_ui_v0.png
shasum -a 256 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_108_cinematic_manual_path_drawing_ui_v0.png
```

Sorties exactes :

```text
-rw-r--r--@ 1 karim  staff   259K Jun 12 00:49 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_108_cinematic_manual_path_drawing_ui_v0.png
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_108_cinematic_manual_path_drawing_ui_v0.png: PNG image data, 1663 x 926, 8-bit/color RGBA, non-interlaced
f016199226ef426bdb8a28554d0221f130b06471af7f3246113b0853230dd1fe  reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_108_cinematic_manual_path_drawing_ui_v0.png
```

## Fichiers Modifiés Pendant V1-108-ter

- `packages/map_editor/test/cinematic_builder_workspace_test.dart`
  - zone capture Visual Gate V1-108 : ajout de `Point 4` dans la fixture de capture ;
  - ajout de `Point 4` comme second point de passage ;
  - `ensureVisible(find.text('Trajet'))` avant screenshot pour cadrer l'inspecteur sur la section demandée.
- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_108_cinematic_manual_path_drawing_ui_v0.png`
  - PNG régénéré.
- `reports/narrativeStudio/scenes/road_map_scenes.md`
  - preuve V1-108 mise à jour avec checksum frais et prochaine étape V1-109.
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`
  - V1-109 remis en `TODO / prochain lot`, pas DONE.
- `reports/narrativeStudio/scenes/ns_scenes_v1_108_cinematic_manual_path_drawing_ui_v0.md`
  - rapport principal régénéré.
- `reports/narrativeStudio/scenes/ns_scenes_v1_108_evidence_pack.md`
  - Evidence Pack régénéré.

Snippet test-only ajouté pour la capture :

```dart
CinematicStagePoint(
    id: 'stage_point_4', label: 'Point 4', x: 31.5, y: 24.5),
```

Snippet de cadrage de capture :

```dart
await tester.tap(find.descendant(
  of: find.byWidgetPredicate((w) => w is PopupMenuItem),
  matching: find.text('Point 4'),
));
await tester.pumpAndSettle();
await tester.ensureVisible(find.text('Trajet'));
await tester.pumpAndSettle();
```

## Tests Relancés

### Ciblé V1-108

```bash
cd packages/map_editor
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-108"
```

Sortie utile exacte :

```text
00:03 +3: All tests passed!
```

### Builder Complet

```bash
cd packages/map_editor
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart
```

Sortie utile exacte :

```text
00:25 +207: All tests passed!
```

### Library + Overlay Points

```bash
cd packages/map_editor
flutter test --reporter=compact test/cinematics_library_workspace_test.dart test/cinematic_stage_point_preview_overlay_test.dart
```

Sortie utile exacte :

```text
00:06 +26: All tests passed!
```

## Analyse Ciblée

```bash
cd packages/map_editor
flutter analyze --no-fatal-infos \
  lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart \
  lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart \
  lib/src/ui/canvas/cinematics/cinematic_manual_path_preview_overlay.dart \
  lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart \
  lib/src/ui/canvas/narrative_workspace_canvas.dart \
  test/cinematic_builder_workspace_test.dart
```

Sortie :

```text
Analyzing 6 items...
37 issues found. (ran in 10.1s)
```

Résultat : sortie 0 grâce à `--no-fatal-infos`. Les 37 issues sont des infos `prefer_const_constructors` / `prefer_const_literals_to_create_immutables`, non bloquantes et déjà présentes dans la zone analysée.

## Git / Anti-Scope

```bash
git diff --check
```

Sortie : vide, exit 0.

```bash
git diff --stat
```

Sortie observée avant insertion finale de ce rapport :

```text
 .../test/cinematic_builder_workspace_test.dart     |  47 +++++++++++++--------
 .../scenes/road_map_scene_builder_authoring.md     |   6 +--
 reports/narrativeStudio/scenes/road_map_scenes.md  |   4 +-
 ..._v1_108_cinematic_manual_path_drawing_ui_v0.png | Bin 261252 -> 264918 bytes
 4 files changed, 35 insertions(+), 22 deletions(-)
```

```bash
git diff --name-only
```

Sortie observée avant insertion finale de ce rapport :

```text
packages/map_editor/test/cinematic_builder_workspace_test.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_108_cinematic_manual_path_drawing_ui_v0.png
```

```bash
git status --short --untracked-files=all
```

Sortie observée avant insertion finale de ce rapport :

```text
 M packages/map_editor/test/cinematic_builder_workspace_test.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
 M reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_108_cinematic_manual_path_drawing_ui_v0.png
```

```bash
git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle examples/playable_runtime_host
```

Sortie : vide.

```bash
git diff --name-only -- examples/playable_runtime_host/macos/Runner.xcodeproj/project.pbxproj packages/map_editor/macos/Runner.xcodeproj/project.pbxproj
```

Sortie : vide.

## Verdict Des Passes

- Audit règles : valide, `codex_rule.md` et `agent_rules.md` lus ; `codex_rules.md` absent documenté.
- Passe Visual Gate : valide après correction test-only du cadrage et des repères de capture.
- Passe tests : valide sur les trois commandes demandées.
- Passe analyse : valide en sortie 0, avec infos non fatales.
- Passe anti-scope : valide, aucune modification runtime/gameplay/battle/host/Xcode observée.
- Sub-agents : aucun sub-agent lancé ; la clôture était séquentielle et bornée.

## Limites Honnêtes

- La suite complète `flutter test` du package `map_editor` n'a pas été demandée ni relancée ; seules les suites listées par le prompt ont été exécutées.
- L'analyse globale du package `map_editor` n'a pas été relancée ; seule l'analyse ciblée demandée est prouvée.
- La capture est une Visual Gate de harness widget, pas une preuve de playback runtime.
- Les infos `prefer_const_*` restent présentes et non bloquantes.
- Le sous-titre de l'entrée de test reste secondaire ; le workflow principal visible est no-code.

## Auto-Critique Finale

La première régénération montrait seulement un point de passage et la seconde cachait encore le titre `Trajet`. La correction finale a volontairement touché uniquement la fixture/capture du test pour rendre la preuve visuelle lisible : deux repères distincts, ligne visible, section `Trajet` et mode `Manuel` à l'écran. Aucun code runtime ou système de playback n'a été ajouté.

## Prochain Lot

La suite reste :

```text
NS-SCENES-V1-109 — Cinematic Preview Playback Prep Contract
```

V1-109 est uniquement pointé par les roadmaps ; il n'est pas démarré dans cette clôture.
