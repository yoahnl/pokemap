# NS-SCENES-V1-129 — Cinematic Emote Preview Playback UI V0

Verdict : **DONE**.

## 1. Résumé exécutif

V1-129 branche un overlay editor-only dans la preview du Cinematic Builder pour afficher les emotes actives au-dessus des acteurs.

Le rendu consomme uniquement :

- `CinematicPreviewPlaybackFrame.activeEmotes` pour savoir quelle emote afficher ;
- `CinematicPreviewPlaybackFrame.actorPoses` pour positionner l’emote ;
- le catalogue `CinematicEmoteCatalogEntry.frame` pour découper l’atlas.

Aucun runtime, Flame, GameState, Camera Target / Zoom, pathfinding, collision ou recalcul de timeline n’a été ajouté.

## 2. Gate 0

Commande initiale :

```bash
pwd && git branch --show-current && git status --short --untracked-files=all && git diff --stat && git diff --name-only && git log --oneline -n 10
```

Sortie initiale utile :

```text
/Users/karim/Project/pokemonProject
main
6da6410f NS-SCENES-V1-128 — Cinematic Emote Block Editor UI V0
af8be4ac update selbrume
d864d502 NS-SCENES-V1-128 — Cinematic Timeline Zoom Controller V0
9e6d5c6e NS-SCENES-V1-127 — Cinematic Emote Playback State Read Model V0
bf27192e NS-SCENES-V1-126 — Cinematic Emote Core Model Asset Catalog V0
7806431f NS-SCENES-V1-125 — Cinematic Emote Assets Reaction Bubble Prep Contract V0
c5329014 NS-SCENES-V1-124 — Cinematic Camera Preview Playback UI V0
5fd4d2f4 NS-SCENES-V1-123 — Cinematic Camera Playback State Read Model V0
636613af NS-SCENES-V1-122 — Cinematic Camera Preview Playback Prep Contract
d6081a24 NS-SCENES-V1-121 — Cinematic Fade Preview Playback V0
```

`git status`, `git diff --stat` et `git diff --name-only` étaient vides au début.

## 3. Fichiers lus

- `AGENTS.md`
- `agent_rules.md`
- `codex_rule.md`
- `skills/README.md`
- `skills/using-superpowers/SKILL.md`
- `skills/test-driven-development/SKILL.md`
- `skills/writing-plans/SKILL.md`
- `skills/verification-before-completion/SKILL.md`
- `packages/map_core/lib/src/models/cinematic_emote_catalog.dart`
- `packages/map_core/lib/src/read_models/cinematic_preview_playback_plan.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_display_preview_overlay.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_preview_playback_actor_overlay_adapter.dart`
- `packages/map_editor/test/cinematic_builder_workspace_test.dart`
- `packages/map_editor/pubspec.yaml`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

Note : `codex_rules.md` n’existe pas ; le fichier de règles disponible et lu est `codex_rule.md`.

## 4. Rappel V1-126 / V1-127 / V1-128

- V1-126 a posé le modèle `actorEmote` et le catalogue avec `assetKey`, `atlasId` et `frame`.
- V1-127 a exposé `CinematicPreviewPlaybackFrame.activeEmotes`.
- V1-128 a rendu le bloc Émotion authorable dans le Builder, sans renderer.

V1-129 consomme ces trois fondations sans les redéfinir.

## 5. Audit rendu / assets / overlay

Assets racine audités :

```text
emotions.png:  PNG image data, 128 x 48, 8-bit colormap, non-interlaced
emotions2.png: PNG image data, 128 x 48, 8-bit colormap, non-interlaced
```

Empreintes racine et copies officielles :

```text
09b9627648f16012042610ec159b95167e84559c6b4ae0fef09eb834d283ac9f  emotions.png
f337639b596d145b306d3300b5f8144bc9387f329fd9fda743accfccb03643b0  emotions2.png
09b9627648f16012042610ec159b95167e84559c6b4ae0fef09eb834d283ac9f  packages/map_editor/assets/cinematics/emotes/emotions.png
f337639b596d145b306d3300b5f8144bc9387f329fd9fda743accfccb03643b0  packages/map_editor/assets/cinematics/emotes/emotions2.png
```

Les assets racine sont conservés. Les copies officielles sont déclarées dans `packages/map_editor/pubspec.yaml`.

## 6. Décision d’architecture

Le builder calcule déjà un `playbackFrame`. V1-129 le transmet à la preview sandbox, puis au panneau backdrop. Le nouvel overlay ne reconstruit pas le playback plan et ne lit pas la timeline pour décider l’état actif.

Ordre de composition retenu :

```text
map bitmap/background
actor overlay
emote overlay
stage/manual-path editor chrome
fade overlay
camera overlay
```

Dans le rendu par calques, l’emote reste placée avec l’acteur avant le foreground pass, afin de préserver l’occlusion future possible par les couches foreground.

## 7. Intégration assets officielle

Fichiers créés :

```text
packages/map_editor/assets/cinematics/emotes/emotions.png
packages/map_editor/assets/cinematics/emotes/emotions2.png
```

`packages/map_editor/pubspec.yaml` :

```diff
 flutter:
   uses-material-design: true
+  assets:
+    - assets/cinematics/emotes/emotions.png
+    - assets/cinematics/emotes/emotions2.png
```

## 8. Renderer emote

Fichier créé :

```text
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_emote_preview_overlay.dart
```

Extrait principal :

```dart
class CinematicEmotePreviewOverlay extends StatefulWidget {
  const CinematicEmotePreviewOverlay({
    super.key,
    required this.playbackFrame,
    required this.mapWidth,
    required this.mapHeight,
    required this.compact,
    this.atlasImagesById,
  });

  final CinematicPreviewPlaybackFrame playbackFrame;
  final int mapWidth;
  final int mapHeight;
  final bool compact;
  final Map<String, ui.Image?>? atlasImagesById;
}
```

Le painter utilise `drawImageRect` avec `FilterQuality.none` pour préserver le pixel art.

## 9. Placement au-dessus de l’acteur

L’overlay convertit la pose actor en coordonnées preview via `CinematicMapBackdropViewportTransform.tileToPreview`.

Extrait :

```dart
final pose = playbackFrame.actorPoseById(actorId);
final anchor = transform.tileToPreview(pose.x!, pose.y!);
final left = (anchor.dx - emoteSize / 2)
    .clamp(transform.frame.left, transform.frame.right - emoteSize)
    .toDouble();
final top = (anchor.dy - actorHeadOffset - emoteSize - verticalGap)
    .clamp(transform.frame.top, transform.frame.bottom - emoteSize)
    .toDouble();
```

## 10. Taille / pixel art

La taille est bornée localement et dépend de la cellule visible :

```dart
final emoteSize = math.min(
  compact ? 28.0 : 34.0,
  math.max(22.0, math.min(cellWidth, cellHeight) * 0.92),
);
```

## 11. Support / unsupported / fallbacks

Si l’atlas est absent, l’emote ou la frame non résolue, l’UI affiche un fallback `?` non bloquant. Les couleurs viennent de `context.pokeMapColors`.

## 12. Play / Pause / Stop / Reset / Seek / Scrub

Les tests V1-129 couvrent :

- seek à 1000 ms : emote visible ;
- seek à 2000 ms : emote absente hors fenêtre temporelle ;
- drag du playhead : emote visible puis absente selon le temps ;
- absence de mutation `ProjectManifest`, `CinematicAsset`, `MapData`.

## 13. Acteurs / actorMove / walking animation

Le renderer suit la pose fournie par `actorPoses`. Un test widget pur injecte deux frames avec deux positions différentes pour vérifier que l’emote suit la pose playback. Si un futur read model expose une emote active pendant un actorMove, l’overlay suivra cette pose sans changer de logique.

Limite honnête : le scénario actuel de fixture Builder est linéaire ; le chevauchement réel emote + actorMove dépendra d’un read model de timeline parallèle futur.

## 14. Preview map / fade / camera

L’emote est insérée dans les trois branches de preview :

- bitmap tile render ;
- layer render ;
- visual primitives fallback.

Fade et camera restent après l’emote dans la stack.

## 15. Non-objectifs confirmés

Non faits :

- runtime ;
- Flame ;
- GameState ;
- Camera Target / Zoom ;
- V1-130 ;
- pathfinding ;
- collision ;
- nouveau modèle core ;
- mutation projet ;
- lecture de chemins absolus racine.

## 16. Hygiène de diff

Fichiers modifiés :

```text
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart
packages/map_editor/pubspec.yaml
packages/map_editor/test/cinematic_builder_workspace_test.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

Fichiers créés :

```text
packages/map_editor/assets/cinematics/emotes/emotions.png
packages/map_editor/assets/cinematics/emotes/emotions2.png
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_emote_preview_overlay.dart
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_129_cinematic_emote_preview_playback_ui_v0.png
reports/narrativeStudio/scenes/ns_scenes_v1_129_cinematic_emote_preview_playback_ui_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_129_evidence_pack.md
```

## 17. Tests RED

RED attendu :

```bash
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-129"
```

Sortie :

```text
Error when reading 'lib/src/ui/canvas/cinematics/cinematic_emote_preview_overlay.dart': No such file or directory
Method not found: 'CinematicEmotePreviewOverlay'
Some tests failed.
```

Premier GREEN partiel après implémentation : échec utile sur rendu doublé, puis correction de la duplication.

## 18. Tests GREEN

Commande finale V1-129 :

```bash
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-129"
```

Sortie :

```text
00:04 +4: All tests passed!
```

## 19. Tests exécutés

```text
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-129" -> All tests passed
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-128" -> All tests passed
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-124" -> All tests passed
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-121" -> All tests passed
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-120" -> All tests passed
flutter test --reporter=compact test/cinematics_library_workspace_test.dart test/cinematic_stage_point_preview_overlay_test.dart -> All tests passed
dart test --reporter=compact test/cinematic_emote_catalog_test.dart -> All tests passed
dart test --reporter=compact test/cinematic_preview_playback_plan_test.dart -> All tests passed
dart test --reporter=compact test/cinematic_authoring_operations_test.dart -> All tests passed
dart test --reporter=compact test/cinematic_diagnostics_test.dart -> All tests passed
```

## 20. Analyse statique

```bash
flutter analyze --no-fatal-infos lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart lib/src/ui/canvas/cinematics/cinematic_actor_display_preview_overlay.dart lib/src/ui/canvas/cinematics/cinematic_preview_playback_actor_overlay_adapter.dart lib/src/ui/canvas/cinematics/cinematic_emote_preview_overlay.dart test/cinematic_builder_workspace_test.dart
```

Sortie :

```text
Analyzing 6 items...
35 issues found. (ran in 1.7s)
Exit code: 0 avec --no-fatal-infos.
```

Les 35 issues restantes sont des infos `prefer_const` existantes dans les gros fichiers ciblés ; l’import inutile introduit initialement dans le helper a été supprimé.

`map_core` :

```bash
dart analyze
```

Sortie :

```text
Analyzing map_core...
No issues found!
```

## 21. Build macOS debug

```bash
flutter build macos --debug
```

Sortie :

```text
✓ Built build/macos/Build/Products/Debug/map_editor.app
```

## 22. Visual Gate

Fichier :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_129_cinematic_emote_preview_playback_ui_v0.png
```

Preuves :

```text
-rw-r--r--  1 karim  staff   233K Jun 14 20:25 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_129_cinematic_emote_preview_playback_ui_v0.png
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_129_cinematic_emote_preview_playback_ui_v0.png: PNG image data, 1663 x 926, 8-bit/color RGBA, non-interlaced
ac71b1d68b1021acdc0225a05844bf43e66985473258ebc647f3ac817acd1ac4  reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_129_cinematic_emote_preview_playback_ui_v0.png
```

## 23. Checks anti-scope

Runtime/gameplay/battle/examples/Selbrume :

```bash
git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle examples/playable_runtime_host selbrume
```

Sortie :

```text
<vide>
```

Assets racine :

```bash
git diff --name-only -- emotions.png emotions2.png
```

Sortie :

```text
<vide>
```

Chemins absolus racine :

```bash
git diff --unified=0 | rg -n "/Users/karim/Project/pokemonProject/emotions|/Users/karim/Project/pokemonProject/emotions2" || true
```

Sortie :

```text
<vide>
```

## 24. Roadmaps

Mises à jour :

- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

V1-129 est DONE. Le prochain lot recommandé est :

```text
NS-SCENES-V1-130 — Cinematic Camera Target / Zoom Authoring Prep Contract
```

## 25. Git final

Les commandes finales exactes sont dans l’Evidence Pack. Aucun commit, add, push ou autre commande Git d’écriture n’a été exécuté.

## 26. Risques restants

- Le vrai chevauchement emote + actorMove dépend du read model si la timeline devient parallèle.
- Le z-order foreground pourra nécessiter un polish si certaines maps veulent afficher l’emote au-dessus de tout foreground.
- Les infos `prefer_const` préexistantes restent dans le scope analysé.

## 27. Auto-critique

Le prompt demandait “l’emote suit l’acteur pendant un actorMove”. Dans l’état actuel, la timeline testée est linéaire. J’ai donc verrouillé le comportement essentiel côté renderer : l’emote suit la pose fournie par `actorPoses`. C’est le bon contrat local pour V1-129 sans inventer une timeline parallèle.

## 28. Verdict final

```text
NS-SCENES-V1-129 : DONE.
Visual Gate : créée.
Prochain lot recommandé : NS-SCENES-V1-130 — Cinematic Camera Target / Zoom Authoring Prep Contract.
```
