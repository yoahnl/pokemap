# NS-SCENES-V1-136-bis — Evidence Pack

## Gate 0

Commande :

```bash
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git log --oneline -n 10
```

Sorties utiles exactes :

```text
/Users/karim/Project/pokemonProject
main
git status --short --untracked-files=all
Sortie : <vide>
git diff --stat
Sortie : <vide>
git diff --name-only
Sortie : <vide>
0f9c5cfe NS-SCENES-V1-136 — Cinematic Builder V1 Closure Readiness Audit
2bd11dda NS-SCENES-V1-135 — Cinematic Builder V1 Camera Closure Polish Gate
179cd6aa NS-SCENES-V1-134 — Cinematic Camera Geometry Preview UI V0
28d0e46e NS-SCENES-V1-133 — Cinematic Camera Geometry Playback State V0
d4e0b28b NS-SCENES-V1-132 — Cinematic Camera Target Zoom Editor UI V0
882c2c23 NS-SCENES-V1-131 — Cinematic Camera Target Zoom Core Model V0
```

Worktree initial propre.

## Règles lues

Fichiers lus :

- `AGENTS.md`
- `agent_rules.md`
- `codex_rule.md`
- `skills/README.md`
- `skills/using-superpowers/SKILL.md`
- `skills/test-driven-development/SKILL.md`
- `skills/verification-before-completion/SKILL.md`
- `skills/writing-plans/SKILL.md`

Vérification pluriel :

```text
ls: codex_rules.md: No such file or directory
codex_rule.md
```

## Préconditions V1-136

Vérifiés :

- `reports/narrativeStudio/scenes/ns_scenes_v1_136_cinematic_builder_v1_closure_readiness_audit.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_136_evidence_pack.md`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`
- présence de `NS-SCENES-V1-136`
- présence de `Cinematic Builder V1 Closure / Readiness Audit`
- présence de `CLOSABLE AVEC RÉSERVES NON BLOQUANTES`
- mention de `NS-SCENES-V1-136-bis — Cinematic Builder Legacy Widget Expectations Cleanup`

## RED initial

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart
```

Sortie utile exacte :

```text
sets a local timeline time probe from mouse interaction without changing selection
Expected: text "step_face"

snaps local timeline time probe to block boundaries without changing selection
Expected: text "step_face"

navigates selected timeline blocks vertically with local keyboard focus
Expected: text "step_camera"

uses step index as vertical navigation tie break
Expected: text "step_camera_a"

adds a safe draft after selected step and inspects it
Expected: text "Statut"

polishes movement target labels and actor movement inspector
Expected: text "Professor marche vers Centre scène en 1000 ms."

00:51 +285 -6: Some tests failed.
```

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact test/cinematics_library_workspace_test.dart
```

Sortie exacte de l'échec :

```text
adds a basic block from builder and refreshes library summary
Expected: exactly one matching candidate
Actual: _TextWidgetFinder:<Found 0 widgets with text "Bloc authoring V0": []>
line 814
00:06 +20 -1: Some tests failed.
```

## Tests modifiés

Builder :

- `sets a local timeline time probe from mouse interaction without changing selection`
- `snaps local timeline time probe to block boundaries without changing selection`
- `navigates selected timeline blocks vertically with local keyboard focus`
- `uses step index as vertical navigation tie break`
- `adds a safe draft after selected step and inspects it`
- `polishes movement target labels and actor movement inspector`

Library :

- `adds a basic block from builder and refreshes library summary`

## Sections de test modifiées

### Helper ajouté

```dart
void _expectTimelineStepCardPresentWithoutRawId(
  WidgetTester tester,
  String stepId,
) {
  expect(
    find.byKey(ValueKey('cinematic-builder-step-card-$stepId')),
    findsOneWidget,
  );
  expect(find.text(stepId), findsNothing);
}
```

### Probe souris local

```dart
_expectTimelineStepSelected(tester, 'step_face');
expect(find.text('Sélection : 500 ms'), findsOneWidget);
expect(find.text('Professor turns'), findsWidgets);
_expectTimelineStepCardPresentWithoutRawId(tester, 'step_face');
```

Après placement du marqueur :

```dart
_expectTimelineStepSelected(tester, 'step_face');
expect(find.text('Marqueur : 750 ms'), findsOneWidget);
expect(find.text('Marqueur temps : 750 ms'), findsOneWidget);
expect(
  find.text('Marqueur local : inspection uniquement.'),
  findsOneWidget,
);
expect(find.text('Sélection : 500 ms'), findsNothing);
expect(find.text('Professor turns'), findsWidgets);
_expectTimelineStepCardPresentWithoutRawId(tester, 'step_face');
```

### Snap probe souris local

```dart
_expectTimelineStepSelected(tester, 'step_face');
expect(find.text('Sélection : 500 ms'), findsOneWidget);
expect(find.text('Professor turns'), findsWidgets);
_expectTimelineStepCardPresentWithoutRawId(tester, 'step_face');
```

Après snap :

```dart
_expectTimelineStepSelected(tester, 'step_face');
expect(find.text('Marqueur : 500 ms · début bloc'), findsOneWidget);
expect(find.text('Marqueur temps : 500 ms'), findsOneWidget);
expect(
  find.text('Marqueur local : inspection uniquement.'),
  findsOneWidget,
);
expect(find.text('Sélection : 500 ms'), findsNothing);
expect(find.text('Professor turns'), findsWidgets);
_expectTimelineStepCardPresentWithoutRawId(tester, 'step_face');
```

### Navigation verticale

```dart
_expectTimelineStepSelected(tester, 'step_camera');
expect(find.text('Sélection : 0 ms'), findsOneWidget);
expect(find.text('Camera reveal'), findsWidgets);
_expectTimelineStepCardPresentWithoutRawId(tester, 'step_camera');
expect(find.textContaining('1. Camera reveal'), findsOneWidget);
```

```dart
_expectTimelineStepSelected(tester, 'step_face');
expect(find.text('Sélection : 500 ms'), findsOneWidget);
expect(find.text('Professor turns'), findsWidgets);
_expectTimelineStepCardPresentWithoutRawId(tester, 'step_face');
expect(find.textContaining('2. Professor turns'), findsOneWidget);
```

```dart
_expectTimelineStepSelected(tester, 'step_sound');
expect(find.text('Sélection : 2.7 s'), findsOneWidget);
expect(find.text('Cue bell'), findsWidgets);
_expectTimelineStepCardPresentWithoutRawId(tester, 'step_sound');
expect(find.textContaining('6. Cue bell'), findsOneWidget);
```

```dart
_expectTimelineStepSelected(tester, 'step_move');
expect(find.text('Sélection : 1.1 s'), findsOneWidget);
expect(find.text('Professor → Centre scène'), findsWidgets);
_expectTimelineStepCardPresentWithoutRawId(tester, 'step_move');
expect(
  find.textContaining('4. Professor → Centre scène'),
  findsOneWidget,
);
```

### Tie-break par index

```dart
_expectTimelineStepSelected(tester, 'step_camera_a');
expect(find.text('Camera left'), findsWidgets);
_expectTimelineStepCardPresentWithoutRawId(tester, 'step_camera_a');
```

### Brouillon safe

```dart
expect(find.text('Bloc brouillon'), findsWidgets);
expect(find.text('Brouillon'), findsWidgets);
expect(find.text('marker'), findsWidgets);
expect(find.text('Statut'), findsNothing);
expect(find.text('Placeholder authoring'), findsNothing);
expect(
  find.text(
    'authoring.kind = draft, authoring.source = cinematic-builder-v0',
  ),
  findsNothing,
);
final selectedDraftCard = tester.widget<PokeMapCard>(
  find.byKey(const ValueKey('cinematic-builder-step-card-step_draft')),
);
expect(selectedDraftCard.selected, isTrue);
expect(
  latestProject.cinematics.single.timeline.steps.map((step) => step.id),
  ['step_camera', 'step_dialogue', 'step_draft', 'step_sound'],
);
```

### ActorMove

```dart
expect(find.text('Professor → Centre scène'), findsWidgets);
expect(find.text('Centre scène'), findsWidgets);
expect(find.text('1000'), findsWidgets);
expect(find.text('Mode mouvement'), findsWidgets);
expect(find.text('Marche'), findsWidgets);
expect(find.text('Trajet'), findsWidgets);
expect(find.text('Direct'), findsWidgets);
expect(find.text('Manuel'), findsWidgets);
```

Après renommage :

```dart
expect(find.text('Professor → Centre du plateau'), findsWidgets);
expect(find.text('Centre du plateau'), findsWidgets);
expect(find.text('1000'), findsWidgets);
```

### Library

```dart
expect(find.text('Attente'), findsWidgets);
expect(find.text('Bloc authoring V0'), findsNothing);
```

Le test conserve ensuite :

```dart
expect(find.byKey(const ValueKey('cinematics-library-workspace')),
    findsOneWidget);
expect(find.text('3 action(s)'), findsWidgets);
expect(find.text('1750 ms estimé(s)'), findsWidgets);
```

## Justification des nouvelles attentes

- `step_face`, `step_camera`, `step_camera_a`, `step_sound`, `step_move` ne sont plus des textes UI attendus. Les tests vérifient maintenant la carte par key et l'absence du texte brut.
- `Statut`, `Placeholder authoring` et `authoring.kind = draft...` appartiennent aux détails techniques désormais masqués. Le test vérifie le brouillon visible et la mutation contrôlée du manifeste.
- Les phrases actorMove longues ont été remplacées par le résumé actuel, destination, durée et mode mouvement.
- `Bloc authoring V0` est explicitement absent côté Library; l'ajout reste prouvé par `Attente`, puis par le résumé Library mis à jour.

## GREEN ciblé

Commande :

```bash
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "sets a local timeline time probe from mouse interaction without changing selection|snaps local timeline time probe to block boundaries without changing selection|navigates selected timeline blocks vertically with local keyboard focus|uses step index as vertical navigation tie break|adds a safe draft after selected step and inspects it|polishes movement target labels and actor movement inspector"
```

Sortie exacte :

```text
00:06 +6: All tests passed!
```

Commande :

```bash
flutter test --reporter=compact test/cinematics_library_workspace_test.dart --name "adds a basic block from builder and refreshes library summary"
```

Sortie exacte :

```text
00:03 +1: All tests passed!
```

## GREEN suites complètes

Commande :

```bash
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart
```

Sortie exacte :

```text
00:44 +291: All tests passed!
```

Commande :

```bash
flutter test --reporter=compact test/cinematics_library_workspace_test.dart
```

Sortie exacte :

```text
00:07 +21: All tests passed!
```

## Régression récente

Commande :

```bash
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-135|V1-134|V1-132|V1-129|V1-128|V1-124|V1-121|V1-120|V1-118|V1-117-bis|V1-116|V1-112|V1-108|V1-105|V1-102"
```

Sortie exacte :

```text
00:15 +73: All tests passed!
```

## Analyse

Commande :

```bash
flutter analyze --no-fatal-infos test/cinematic_builder_workspace_test.dart test/cinematics_library_workspace_test.dart
```

Sortie exacte utile :

```text
Analyzing 2 items...
info • Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation • test/cinematic_builder_workspace_test.dart:16311:38 • prefer_const_constructors
info • Use 'const' literals as arguments to constructors of '@immutable' classes. Try adding 'const' before the literal • test/cinematic_builder_workspace_test.dart:16312:17 • prefer_const_literals_to_create_immutables
info • Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation • test/cinematic_builder_workspace_test.dart:16313:11 • prefer_const_constructors
info • Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation • test/cinematic_builder_workspace_test.dart:16347:11 • prefer_const_constructors
info • Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation • test/cinematic_builder_workspace_test.dart:16517:38 • prefer_const_constructors
info • Use 'const' literals as arguments to constructors of '@immutable' classes. Try adding 'const' before the literal • test/cinematic_builder_workspace_test.dart:16518:17 • prefer_const_literals_to_create_immutables
info • Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation • test/cinematic_builder_workspace_test.dart:16519:11 • prefer_const_constructors
info • Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation • test/cinematic_builder_workspace_test.dart:16553:11 • prefer_const_constructors
info • Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation • test/cinematic_builder_workspace_test.dart:16581:11 • prefer_const_constructors
info • Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation • test/cinematic_builder_workspace_test.dart:16588:15 • prefer_const_constructors
info • Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation • test/cinematic_builder_workspace_test.dart:16592:19 • prefer_const_constructors
info • Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation • test/cinematic_builder_workspace_test.dart:17284:11 • prefer_const_constructors
info • Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation • test/cinematic_builder_workspace_test.dart:17291:15 • prefer_const_constructors
info • Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation • test/cinematic_builder_workspace_test.dart:17295:19 • prefer_const_constructors
info • Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation • test/cinematic_builder_workspace_test.dart:17345:38 • prefer_const_constructors
info • Use 'const' literals as arguments to constructors of '@immutable' classes. Try adding 'const' before the literal • test/cinematic_builder_workspace_test.dart:17346:17 • prefer_const_literals_to_create_immutables
info • Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation • test/cinematic_builder_workspace_test.dart:17347:11 • prefer_const_constructors
info • Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation • test/cinematic_builder_workspace_test.dart:17539:9 • prefer_const_constructors
info • Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation • test/cinematic_builder_workspace_test.dart:17546:13 • prefer_const_constructors
info • Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation • test/cinematic_builder_workspace_test.dart:17550:17 • prefer_const_constructors
info • Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation • test/cinematic_builder_workspace_test.dart:17600:36 • prefer_const_constructors
info • Use 'const' literals as arguments to constructors of '@immutable' classes. Try adding 'const' before the literal • test/cinematic_builder_workspace_test.dart:17601:15 • prefer_const_literals_to_create_immutables
info • Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation • test/cinematic_builder_workspace_test.dart:17602:9 • prefer_const_constructors
23 issues found. (ran in 1.6s)
Exit code: 0
```

## Build

Build macOS non lancé : le lot ne modifie aucun code produit. Le prompt ne l'exigeait qu'en cas de modification produit.

## Roadmaps modifiées

Sections ajoutées :

```text
NS-SCENES-V1-136-bis — Cinematic Builder Legacy Widget Expectations Cleanup | DONE
```

```text
Prochain lot recommande : NS-SCENES-V1-137 — Narrative Studio Golden Slice Authoring Readiness / Selbrume Demo Content Plan
```

V1-137 est recommandé, non démarré.

## Fichiers créés

- `reports/narrativeStudio/scenes/ns_scenes_v1_136_bis_cinematic_builder_legacy_widget_expectations_cleanup.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_136_bis_evidence_pack.md`

## Fichiers modifiés

- `packages/map_editor/test/cinematic_builder_workspace_test.dart`
- `packages/map_editor/test/cinematics_library_workspace_test.dart`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

## Fichiers supprimés

Aucun.

## Git diff check final

Commande :

```bash
git diff --check
```

Sortie exacte :

```text
<vide>
```

## Anti-scope final

Commande :

```bash
git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle examples/playable_runtime_host assets selbrume pubspec.yaml
```

Sortie exacte :

```text
<vide>
```

Commande :

```bash
git diff --name-only -- packages/map_core packages/map_editor/lib
```

Sortie exacte :

```text
<vide>
```

Commande :

```bash
find reports/narrativeStudio/scenes/screenshots -maxdepth 1 -name '*v1_136_bis*' -print
```

Sortie exacte :

```text
<vide>
```

Commande :

```bash
find reports/narrativeStudio/scenes/screenshots -maxdepth 1 -name '*v1_137*' -print
```

Sortie exacte :

```text
<vide>
```

## Git final

Commande :

```bash
git diff --stat
git diff --name-only
git status --short --untracked-files=all
```

Sortie exacte :

```text
 .../test/cinematic_builder_workspace_test.dart     | 53 ++++++++++++----------
 .../test/cinematics_library_workspace_test.dart    |  2 +-
 .../scenes/road_map_scene_builder_authoring.md     | 13 +++++-
 reports/narrativeStudio/scenes/road_map_scenes.md  | 16 ++++++-
 4 files changed, 56 insertions(+), 28 deletions(-)
packages/map_editor/test/cinematic_builder_workspace_test.dart
packages/map_editor/test/cinematics_library_workspace_test.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
 M packages/map_editor/test/cinematic_builder_workspace_test.dart
 M packages/map_editor/test/cinematics_library_workspace_test.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_136_bis_cinematic_builder_legacy_widget_expectations_cleanup.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_136_bis_evidence_pack.md
```

## Auto-review indépendante

- Le lot ne modifie que tests et documentation.
- Aucun ancien ID technique n'a été réintroduit dans l'UI.
- Aucun test n'a été supprimé.
- Aucun test n'a été skipped.
- Les assertions restent fonctionnelles : sélection, keys de cartes, absence d'ID visible, résumé no-code, mutation contrôlée, Library refresh.
- Les suites complètes Builder et Library passent.
- La régression V1-102 à V1-135 passe.
- Aucun runtime/Flame/GameState/Selbrume n'est touché.
- Les roadmaps gardent V1-137 comme prochain lot recommandé, non démarré.

## Critique du prompt

Les échecs étaient bien de la dette legacy de tests. La seule nuance est que les tests widget restent sensibles aux keys internes du Builder; c'est acceptable pour ce lot car l'objectif était précisément de tester la timeline et l'inspecteur, mais une future couche de helpers de test pourrait rendre ces assertions encore plus lisibles.
