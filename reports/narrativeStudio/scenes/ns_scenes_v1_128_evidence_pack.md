# NS-SCENES-V1-128 — Evidence Pack

## Statut

```text
NS-SCENES-V1-128 : DONE.
V1-129 : recommandé, non démarré.
```

## Gate 0 complet

```text
$ pwd
/Users/karim/Project/pokemonProject

$ git branch --show-current
main

$ git status --short --untracked-files=all
Sortie : <vide>

$ git diff --stat
Sortie : <vide>

$ git diff --name-only
Sortie : <vide>

$ git log --oneline -n 10
d864d502 NS-SCENES-V1-128 — Cinematic Timeline Zoom Controller V0
9e6d5c6e NS-SCENES-V1-127 — Cinematic Emote Playback State Read Model V0
bf27192e NS-SCENES-V1-126 — Cinematic Emote Core Model Asset Catalog V0
7806431f NS-SCENES-V1-125 — Cinematic Emote Assets Reaction Bubble Prep Contract V0
c5329014 NS-SCENES-V1-124 — Cinematic Camera Preview Playback UI V0
5fd4d2f4 NS-SCENES-V1-123 — Cinematic Camera Playback State Read Model V0
636613af NS-SCENES-V1-122 — Cinematic Camera Preview Playback Prep Contract
d6081a24 NS-SCENES-V1-121 — Cinematic Fade Preview Playback V0
035e3346 ns_scenes_v1_120: add cinematic preview playback scrub seek UI and evidence pack
e87152f2 docs(narrativeStudio): add cinematic preview playback scrub seek prep contract and evidence pack
```

Dirty initial : aucun fichier dirty, aucun `selbrume/project.json` dirty.

## Règles lues

```text
AGENTS.md
agent_rules.md
codex_rule.md
skills/README.md
skills/using-superpowers/SKILL.md
skills/test-driven-development/SKILL.md
skills/verification-before-completion/SKILL.md
skills/writing-plans/SKILL.md
```

Absent : `codex_rules.md`.

## Passes A-I

```text
Passe A — Audit initial UI/palette/inspector : PASS.
Passe B — Design UI no-code actorEmote : PASS.
Passe C — Tests RED : PASS, tests V1-128 échouaient avant implémentation.
Passe D — Implémentation : PASS.
Passe E — Tests GREEN : PASS.
Passe F — Visual Gate : PASS.
Passe G — Analyse / anti-scope : PASS.
Passe H — Rapport / Evidence Pack / Roadmaps : PASS.
Passe I — Auto-critique finale : PASS.
```

Sub-agents : non utilisés ; les passes manuelles équivalentes étaient suffisantes et le scope était localisé.

## Fichiers modifiés

```text
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
packages/map_editor/test/cinematics_library_workspace_test.dart
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
```

## Fichiers créés

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_128_cinematic_emote_block_editor_ui_v0.png
reports/narrativeStudio/scenes/ns_scenes_v1_128_cinematic_emote_block_editor_ui_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_128_evidence_pack.md
```

La capture est binaire ; son contenu est prouvé par `file` et SHA-256. Les deux fichiers Markdown créés contiennent directement leur contenu complet.

## Hunks pertinents

Builder :

```text
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
- callbacks Add/Update actorEmote ajoutés ;
- `_addActorEmote()` ajouté ;
- `_updateActorEmote()` ajouté ;
- `_ActorEmotePaletteTile` ajouté ;
- `_ActorEmoteControls` ajouté ;
- résumé `_actorEmoteSummary` branché dans l’inspecteur ;
- resize durée actorEmote supporté via conventions existantes.
```

Parent / Library :

```text
packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
- callbacks actorEmote exposés au Builder.

packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
- add/update actorEmote branchés aux opérations pures core.
```

Tests :

```text
packages/map_editor/test/cinematic_builder_workspace_test.dart
- V1-128 palette adds actor emote block
- V1-128 actor emote inspector lets user choose actor
- V1-128 actor emote inspector lets user choose no-code emote and duration
- captures V1-128 cinematic emote block editor ui visual gate
```

## Code généré inclus

Callbacks :

```dart
typedef AddCinematicActorEmoteStepCallback = Future<String?> Function({
  required String cinematicId,
  required String actorId,
  required String emoteId,
  int? durationMs,
  String? afterStepId,
});

typedef UpdateCinematicActorEmoteStepCallback = Future<bool> Function({
  required String cinematicId,
  required String stepId,
  String? actorId,
  String? emoteId,
  int? durationMs,
});
```

Opérations parent :

```dart
final result = addCinematicTimelineActorEmoteStep(
  project,
  cinematicId: cinematicId,
  actorId: actorId,
  emoteId: emoteId,
  durationMs: durationMs,
  afterStepId: afterStepId,
);
widget.editorNotifier.applyInMemoryProjectManifest(
  result.updatedProject,
  statusMessage: 'Cinematic actor emote block created',
);
```

Picker réaction :

```dart
for (final emote in cinematicEmoteCatalog)
  _InlineControlAction(
    label: emote.label,
    button: PokeMapButton(
      key: ValueKey('cinematic-builder-actor-emote-emote-${emote.id}'),
      onPressed: () {
        onUpdateActorEmote(step, emoteId: emote.id);
      },
      variant: PokeMapButtonVariant.secondary,
      size: PokeMapButtonSize.small,
      isSelected: selectedEmoteId == emote.id,
      leading: const Icon(CupertinoIcons.chat_bubble),
      child: const SizedBox.shrink(),
    ),
  )
```

## Tests RED exacts

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-128"
```

Résultat RED :

```text
Exit code: 1
Expected Émotion, found 0.
Expected Réaction, found 0.
Bad state: No element for missing emote button key before implementation.
```

## Tests GREEN exacts

```text
$ flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-128"
... +4: All tests passed!

$ flutter test --update-goldens --reporter=compact --dart-define=NS_SCENES_V1_128_CAPTURE_CINEMATIC_EMOTE_BLOCK_EDITOR_UI=true test/cinematic_builder_workspace_test.dart --name "captures V1-128"
... +1: All tests passed!

$ flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-124"
... +7: All tests passed!

$ flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-121"
... +5: All tests passed!

$ flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-120"
... +9: All tests passed!

$ flutter test --reporter=compact test/cinematics_library_workspace_test.dart test/cinematic_stage_point_preview_overlay_test.dart
... +26: All tests passed!
```

Builder complet :

```text
$ flutter test --reporter=compact test/cinematic_builder_workspace_test.dart
... +263: All tests passed!
```

Régression intermédiaire corrigée :

```text
$ flutter test --reporter=expanded test/cinematic_builder_workspace_test.dart
Exit code: 1
Failing test: adds a required actor before enabling actor facing.
Expected one "Ajoutez d’abord un acteur requis", found 2.

$ flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "adds a required actor before enabling actor facing"
... +1: All tests passed!
```

Correction appliquée : le texte disabled du bloc Émotion sans acteur est devenu `Ajoutez un acteur pour afficher une réaction`, pour éviter de dupliquer le message attendu par le test actorFace existant.

## Tests map_core

```text
$ dart test --reporter=compact test/cinematic_emote_catalog_test.dart
... +3: All tests passed!

$ dart test --reporter=compact test/cinematic_authoring_operations_test.dart
... +71: All tests passed!

$ dart test --reporter=compact test/cinematic_diagnostics_test.dart
... +55: All tests passed!

$ dart test --reporter=compact test/cinematic_preview_playback_plan_test.dart
... +20: All tests passed!

$ dart analyze
Analyzing map_core...
No issues found!
```

## Analyse ciblée

```text
$ flutter analyze --no-fatal-infos lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart test/cinematic_builder_workspace_test.dart
Analyzing 2 items...

   info • Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation • lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:1718:9 • prefer_const_constructors
   info • Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation • lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:1719:18 • prefer_const_constructors
   info • Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation • lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:1727:9 • prefer_const_constructors
   info • Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation • lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:1736:9 • prefer_const_constructors
   info • Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation • lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:3586:19 • prefer_const_constructors
   info • Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation • lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:3623:23 • prefer_const_constructors
   info • Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation • lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:3634:23 • prefer_const_constructors
   info • Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation • lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:3642:23 • prefer_const_constructors
   info • Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation • lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:3650:23 • prefer_const_constructors
   info • Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation • lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:5976:13 • prefer_const_constructors
   info • Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation • lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:6036:11 • prefer_const_constructors
   info • Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation • lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:13028:26 • prefer_const_constructors
   info • Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation • test/cinematic_builder_workspace_test.dart:14770:38 • prefer_const_constructors
   info • Use 'const' literals as arguments to constructors of '@immutable' classes. Try adding 'const' before the literal • test/cinematic_builder_workspace_test.dart:14771:17 • prefer_const_literals_to_create_immutables
   info • Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation • test/cinematic_builder_workspace_test.dart:14772:11 • prefer_const_constructors
   info • Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation • test/cinematic_builder_workspace_test.dart:14806:11 • prefer_const_constructors
   info • Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation • test/cinematic_builder_workspace_test.dart:14976:38 • prefer_const_constructors
   info • Use 'const' literals as arguments to constructors of '@immutable' classes. Try adding 'const' before the literal • test/cinematic_builder_workspace_test.dart:14977:17 • prefer_const_literals_to_create_immutables
   info • Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation • test/cinematic_builder_workspace_test.dart:14978:11 • prefer_const_constructors
   info • Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation • test/cinematic_builder_workspace_test.dart:15012:11 • prefer_const_constructors
   info • Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation • test/cinematic_builder_workspace_test.dart:15040:11 • prefer_const_constructors
   info • Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation • test/cinematic_builder_workspace_test.dart:15047:15 • prefer_const_constructors
   info • Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation • test/cinematic_builder_workspace_test.dart:15051:19 • prefer_const_constructors
   info • Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation • test/cinematic_builder_workspace_test.dart:15743:11 • prefer_const_constructors
   info • Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation • test/cinematic_builder_workspace_test.dart:15750:15 • prefer_const_constructors
   info • Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation • test/cinematic_builder_workspace_test.dart:15754:19 • prefer_const_constructors
   info • Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation • test/cinematic_builder_workspace_test.dart:15804:38 • prefer_const_constructors
   info • Use 'const' literals as arguments to constructors of '@immutable' classes. Try adding 'const' before the literal • test/cinematic_builder_workspace_test.dart:15805:17 • prefer_const_literals_to_create_immutables
   info • Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation • test/cinematic_builder_workspace_test.dart:15806:11 • prefer_const_constructors
   info • Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation • test/cinematic_builder_workspace_test.dart:15998:9 • prefer_const_constructors
   info • Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation • test/cinematic_builder_workspace_test.dart:16005:13 • prefer_const_constructors
   info • Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation • test/cinematic_builder_workspace_test.dart:16009:17 • prefer_const_constructors
   info • Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation • test/cinematic_builder_workspace_test.dart:16059:36 • prefer_const_constructors
   info • Use 'const' literals as arguments to constructors of '@immutable' classes. Try adding 'const' before the literal • test/cinematic_builder_workspace_test.dart:16060:15 • prefer_const_literals_to_create_immutables
   info • Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation • test/cinematic_builder_workspace_test.dart:16061:9 • prefer_const_constructors

35 issues found. (ran in 1.9s)
```

Exit code : 0 avec `--no-fatal-infos`.

## Build macOS debug

```text
$ flutter build macos --debug
Building macOS application...
✓ Built build/macos/Build/Products/Debug/map_editor.app
```

## Visual Gate

```text
$ ls -lh reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_128_cinematic_emote_block_editor_ui_v0.png
-rw-r--r--  1 karim  staff   196K Jun 14 18:39 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_128_cinematic_emote_block_editor_ui_v0.png

$ file reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_128_cinematic_emote_block_editor_ui_v0.png
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_128_cinematic_emote_block_editor_ui_v0.png: PNG image data, 1663 x 926, 8-bit/color RGBA, non-interlaced

$ shasum -a 256 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_128_cinematic_emote_block_editor_ui_v0.png
9b5996752af56ec06f9fd1752704f357162116c0e1edaeab708e28c7e7d3e7e1  reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_128_cinematic_emote_block_editor_ui_v0.png
```

## Format ciblé

```text
$ dart format lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart test/cinematic_builder_workspace_test.dart
Formatted 2 files (0 changed) in 0.21 seconds.
```

## Anti-scope

```text
$ git diff --unified=0 | rg -n "package:flame|GameState|PlayableMapGame|SceneRuntimeExecutor|CinematicRuntimeAdapter|map_runtime|map_gameplay|ImageProvider|ui\.Image|rootBundle|decodeImage|Image\.asset|Timer\.periodic|Future\.delayed|Stream\.periodic|DateTime\.now|V1-129" || true
Sortie : <vide>

$ git diff --name-only -- assets emotions.png emotions2.png pubspec.yaml packages/map_editor/pubspec.yaml packages/map_runtime/pubspec.yaml
Sortie : <vide>

$ git diff --unified=0 | rg -n "EmotePreviewOverlay|emote overlay|drawEmote|paintEmote|activeEmotes.*Widget|activeEmotes.*paint|emotions\.png|emotions2\.png" || true
Sortie : <vide>

$ git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle examples/playable_runtime_host assets selbrume emotions.png emotions2.png pubspec.yaml
Sortie : <vide>

$ find reports/narrativeStudio/scenes/screenshots -maxdepth 1 -name '*v1_129*' -print
Sortie : <vide>
```

## Confirmations

```text
Aucun runtime modifié.
Aucun map_gameplay modifié.
Aucun map_battle modifié.
Aucun example modifié.
Aucun asset modifié.
Aucun asset racine déplacé ou copié.
Aucun pubspec modifié.
Aucune donnée Selbrume modifiée.
Aucun renderer emote démarré.
Aucun asset loading ajouté.
V1-129 non démarré.
```

## Roadmaps

```text
road_map_scenes.md : V1-128 DONE, prochain lot recommandé V1-129.
road_map_scene_builder_authoring.md : V1-128 DONE, prochain lot recommandé V1-129.
```

## Roadmap verification

```text
$ rg -n "Prochain lot exact recommande|NS-SCENES-V1-128 — Cinematic Emote Block Editor UI V0|NS-SCENES-V1-129 — Cinematic Emote Preview Playback UI V0" reports/narrativeStudio/scenes/road_map_scenes.md reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md:9:## Prochain lot exact recommande
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md:12:NS-SCENES-V1-129 — Cinematic Emote Preview Playback UI V0
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md:199:Prochain lot recommande : `NS-SCENES-V1-129 — Cinematic Emote Preview Playback UI V0`.
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md:211:Suite realisee : V1-128 a rendu le bloc actorEmote authorable dans le Builder. Prochain lot recommande : `NS-SCENES-V1-129 — Cinematic Emote Preview Playback UI V0`.
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md:221:Suite realisee : V1-127 puis V1-128 ont ete realises. Prochain lot global actuel : `NS-SCENES-V1-129 — Cinematic Emote Preview Playback UI V0`.
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md:233:Suite historique : les lots recommandes V1-126, V1-127 et V1-128 ont ete realises. Prochain lot global actuel : `NS-SCENES-V1-129 — Cinematic Emote Preview Playback UI V0`.
reports/narrativeStudio/scenes/road_map_scenes.md:195:| NS-SCENES-V1-129 — Cinematic Emote Preview Playback UI V0 | TODO | Afficher les emotes actives au-dessus des acteurs dans la preview playback, seek/scrub inclus. |
reports/narrativeStudio/scenes/road_map_scenes.md:198:## Prochain lot exact recommande
reports/narrativeStudio/scenes/road_map_scenes.md:200:`NS-SCENES-V1-129 — Cinematic Emote Preview Playback UI V0`
reports/narrativeStudio/scenes/road_map_scenes.md:234:30. `NS-SCENES-V1-129 — Cinematic Emote Preview Playback UI V0` (recommande, non demarre)
reports/narrativeStudio/scenes/road_map_scenes.md:249:Prochain lot recommande : `NS-SCENES-V1-129 — Cinematic Emote Preview Playback UI V0`.
reports/narrativeStudio/scenes/road_map_scenes.md:263:Suite realisee : V1-128 a rendu le bloc actorEmote authorable dans le Builder. Prochain lot recommande : `NS-SCENES-V1-129 — Cinematic Emote Preview Playback UI V0`.
reports/narrativeStudio/scenes/road_map_scenes.md:277:Suite realisee : V1-127 puis V1-128 ont ete realises. Prochain lot global actuel : `NS-SCENES-V1-129 — Cinematic Emote Preview Playback UI V0`.
reports/narrativeStudio/scenes/road_map_scenes.md:291:Suite historique : les lots recommandes V1-126, V1-127 et V1-128 ont ete realises. Prochain lot global actuel : `NS-SCENES-V1-129 — Cinematic Emote Preview Playback UI V0`. Camera Target / Zoom reste en backlog sous `NS-SCENES-V1-130 — Cinematic Camera Target / Zoom Authoring Prep Contract`.
```

## Git final

```text
$ git diff --check
Sortie : <vide>

$ git diff --stat
 .../cinematics/cinematic_builder_workspace.dart    | 338 +++++++++++++++++++--
 .../cinematics/cinematics_library_workspace.dart   |  22 ++
 .../src/ui/canvas/narrative_workspace_canvas.dart  |  62 ++++
 .../test/cinematic_builder_workspace_test.dart     | 310 +++++++++++++++++++
 .../test/cinematics_library_workspace_test.dart    |  36 +++
 .../scenes/road_map_scene_builder_authoring.md     |  54 ++--
 reports/narrativeStudio/scenes/road_map_scenes.md  |  58 ++--
 7 files changed, 812 insertions(+), 68 deletions(-)

$ git diff --name-only
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
packages/map_editor/test/cinematics_library_workspace_test.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md

$ git status --short --untracked-files=all
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
 M packages/map_editor/test/cinematic_builder_workspace_test.dart
 M packages/map_editor/test/cinematics_library_workspace_test.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_128_cinematic_emote_block_editor_ui_v0.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_128_evidence_pack.md
?? reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_128_cinematic_emote_block_editor_ui_v0.png
```

Note : `git diff --stat` et `git diff --name-only` ne listent que les fichiers suivis modifiés. Les fichiers créés non suivis apparaissent dans `git status --short --untracked-files=all`.

## Verdict final

```text
NS-SCENES-V1-128 : DONE.
Emote Block Editor UI : implémenté.
Palette Émotion : active.
Inspecteur actorEmote : actif.
Picker acteur : actif.
Picker réaction : actif.
Durée : visible/éditable.
Diagnostics : visibles en no-code.
Timeline label : humain.
Rendu visuel emote : non démarré.
Assets racine : non déplacés, non copiés.
pubspec : non modifié.
Runtime / Flame / GameState : non touchés.
Visual Gate : créée.
V1-129 : recommandé, non démarré.
```
