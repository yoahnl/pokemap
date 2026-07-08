# NS-EVENT-38 — Event Builder Map Placement & Post-Creation Guided Setup UX V0

## 1. Résumé exécutif

Placement UX : PASS.

Post-Creation UX : PASS.

Cause UX : NS-EVENT-37 rendait la création fonctionnelle, mais la position restait choisie dans un mini-damier abstrait. Après création, l'interface exposait trop tôt la bibliothèque complète, le builder complet et l'inspecteur complet.

Correction : le chemin principal devient "Choisir sur la carte", avec clic sur le vrai `MapCanvas`. Après création, l'événement sélectionné ouvre une configuration guidée avec checklist, actions rapides secondaires et inspecteur résumé.

Ce qui est prouvé : clic carte -> `GridPos` -> `EventPosition(layerId, x, y)` stockée, événement créé et sélectionné, absence de l'ancien `event-builder-position-grid`, état vide sans CTA concurrent, post-création guidée, régressions NS-EVENT-37/36/33 vertes.

Ce qui reste à prouver : rendu manuel sur application packagée hors golden, et amélioration des artefacts de texte blanc dans les captures golden de boutons.

Prochain lot recommandé : NS-EVENT-39 — Event Builder Map Placement Polish & In-Canvas Selection Overlay V0.

Blockers : aucun.

## 2. Usage du MCP Dart

MCP Dart utilisé.

- `roots add file:///Users/karim/Project/pokemonProject/packages/map_editor` : `Success`.
- Symboles inspectés via LSP : `NarrativeWorkspaceCanvas`, `EventBuilderWorkspace`, `EventBuilderCreationPanel`, `EventBuilderDraftCreationGate`, `EditorNotifier`, `EditorState`, `MapCanvas`, `createEventBuilderDraftEventAt`, `selectedMapEventId`, `EventBuilderElementLibrary`, `EventBuilderInspectorPanel`.
- Analyse finale MCP Dart :

```text
No errors
```

## 3. Sous-agents utilisés

Orchestrateur principal : Codex.

Sous-agents utilisés, puis clôturés :

- A — UX Placement / Map Mental Model : verdict initial PARTIAL, PASS conditionné au vrai clic carte.
- B — Map Canvas / Editor State Integration : PASS faisable via pont local `MapCanvas`, sans refonte globale d'outil.
- C — Post-Creation Guided Setup : écran actuel PARTIAL, checklist guidée recommandée.
- D — Tests / Visual Gate : groupe NS-EVENT-38, régressions 37/36/33, visual gate.
- E — Design System / Product Copy : wording no-code, éviter les termes techniques dans le parcours principal.
- F — Reviewer contradictoire : rejet des faux correctifs, exigence de preuve state/layer/position.

## 4. Observation utilisateur / problème UX

Le problème n'était plus runtime ni disponibilité de couche. NS-EVENT-36 avait débloqué la création quand Selbrume n'avait pas d'`ObjectLayer`, et NS-EVENT-37 avait clarifié le premier parcours en trois étapes.

La dette restante était cognitive :

- l'utilisateur s'attend à cliquer sur la vraie carte ;
- le damier ressemblait à un sélecteur abstrait non identifié ;
- après création, l'écran montrait bibliothèque + builder + inspecteur + diagnostics au lieu de guider les premières décisions.

## 5. Audit placement actuel

Avant correction, `_DraftPositionPickerPanel` affichait une grille de boutons. Elle écrivait bien une position réelle, mais ne rendait pas la map réelle et ne réutilisait pas la conversion pointeur -> grille de `MapCanvas`.

Le vrai canvas est `MapCanvas`, qui convertit le tap local en `GridPos` via `_screenToGrid`.

## 6. Décision placement : vraie carte PASS

Décision : Option A livrée.

Le mini-damier n'est plus le chemin principal. Le panneau affiche `Choisir sur la carte`, active un mode de placement et rend un `MapCanvas` borné au panneau. Le clic sur ce canvas sélectionne la position puis désactive le mode.

Preuve code :

- [map_canvas.dart](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/map_canvas.dart:54) ajoute `onEventBuilderPositionChosen`.
- [map_canvas.dart](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/map_canvas.dart:363) intercepte le tap carte si le callback Event Builder est fourni.
- [event_builder_workspace.dart](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart:603) branche le panneau Position sur le mode carte.
- [event_builder_workspace.dart](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart:1058) expose `event-builder-choose-on-map-button`.
- [event_builder_workspace.dart](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart:1123) rend `MapCanvas` avec `event-builder-map-placement-canvas`.

## 7. Décision post-création

Décision : post-création guidée.

Pour l'événement fraîchement créé, la zone centrale devient une configuration guidée :

- Position choisie ;
- Renommer l'événement ;
- Choisir le déclencheur ;
- Choisir une scène ;
- Vérifier le comportement.

La bibliothèque complète devient un panneau `Actions rapides` secondaire et l'inspecteur complet devient un résumé secondaire.

Preuve code :

- [event_builder_workspace.dart](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart:1549) ajoute `_GuidedSetupPanel`.
- [event_builder_workspace.dart](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart:1701) ajoute `_EventInspectorSummaryPanel`.
- [event_builder_workspace.dart](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart:1920) passe le flux central en `Configuration guidée`.
- [event_builder_workspace.dart](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart:2082) remplace l'inspecteur complet par le résumé en mode guidé.

## 8. Correction appliquée

Fichiers modifiés :

- `packages/map_editor/lib/src/ui/canvas/map_canvas.dart`
- `packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart`
- `packages/map_editor/test/event_builder_workspace_test.dart`

Fichier modifié préexistant, non lié au lot et non touché volontairement :

- `packages/map_editor/pubspec.lock`

Fichiers créés :

- `reports/narrativeStudio/events/screenshots/ns_event_38_creation_placement_v0.png` : PNG 1440x1100.
- `reports/narrativeStudio/events/screenshots/ns_event_38_post_creation_guided_setup_v0.png` : PNG 1440x1100.
- `reports/narrativeStudio/events/screenshots/ns_event_38_map_placement_post_creation_guided_setup_v0.png` : PNG 1440x1100.
- `reports/narrativeStudio/events/ns_event_38_map_placement_post_creation_guided_setup_v0.md` : le présent rapport.

Contenu complet des fichiers créés : les captures sont des binaires PNG, non incluses inline. Le contenu complet du rapport est ce fichier Markdown.

## 9. Tests ajoutés/modifiés

Ajout du groupe `NS-EVENT-38` dans `packages/map_editor/test/event_builder_workspace_test.dart`.

Tests ajoutés :

- `empty state explains map placement without competing CTA`
- `lets user choose event position from the real map canvas`
- `newly created event opens guided setup instead of cockpit layout`
- `keeps forbidden authoring absent after guided creation`
- `missing event layer stays guided before map placement`
- `captures map placement and guided setup visual gate`

Tests/régressions adaptés :

- anciens tests de position mis à jour de `event-builder-position-grid` vers `event-builder-choose-on-map-button` et clic réel sur `event-builder-map-placement-canvas`;
- NS-EVENT-09/11 adaptés au panneau `Actions rapides` secondaire ;
- NS-EVENT-37 adapté à l'inspecteur résumé post-création.

## 10. Visual Gate

Commande :

```bash
cd packages/map_editor
flutter test --update-goldens -DNS_EVENT_38_CAPTURE_WORKSPACE=true --reporter=compact test/event_builder_workspace_test.dart --name "captures map placement and guided setup visual gate"
```

Résultat exact :

```text
NS-EVENT-38 map placement and guided setup UX captures map placement and guided setup visual gate
All tests passed!
```

Captures :

- `reports/narrativeStudio/events/screenshots/ns_event_38_creation_placement_v0.png`
- `reports/narrativeStudio/events/screenshots/ns_event_38_post_creation_guided_setup_v0.png`
- `reports/narrativeStudio/events/screenshots/ns_event_38_map_placement_post_creation_guided_setup_v0.png`

Réserve visuelle : les captures golden affichent encore certains libellés de boutons sous forme de blocs blancs. Les textes principaux et les assertions sémantiques des tests couvrent le wording attendu.

## 11. Validations exécutées

Tests ciblés :

```bash
cd packages/map_editor
flutter test --reporter=compact test/event_builder_workspace_test.dart --name "NS-EVENT-38"
```

Résultat :

```text
NS-EVENT-38 map placement and guided setup UX captures map placement and guided setup visual gate
All tests passed!
```

Régressions :

```bash
flutter test --reporter=compact test/event_builder_workspace_test.dart --name "NS-EVENT-37"
flutter test --reporter=compact test/event_builder_workspace_test.dart --name "NS-EVENT-36"
flutter test --reporter=compact test/event_builder_workspace_test.dart --name "NS-EVENT-33"
```

Résultats :

```text
NS-EVENT-37 ... All tests passed!
NS-EVENT-36 ... All tests passed!
NS-EVENT-33 ... All tests passed!
```

Fichiers complets :

```bash
flutter test --reporter=compact test/event_builder_workspace_test.dart
```

Résultat :

```text
00:12 +117: All tests passed!
```

```bash
flutter test --reporter=compact test/event_builder_draft_creation_notifier_test.dart
```

Résultat :

```text
00:01 +28: All tests passed!
```

Analyse :

```bash
flutter analyze --no-fatal-infos \
  lib/src/ui/canvas/narrative_workspace_canvas.dart \
  lib/src/ui/canvas/map_canvas.dart \
  lib/src/ui/canvas/events/event_builder_workspace.dart \
  lib/src/ui/canvas/events/event_builder_creation_panel.dart \
  lib/src/ui/canvas/events/event_builder_inspector_panel.dart \
  lib/src/ui/canvas/events/event_builder_element_library.dart \
  lib/src/features/editor/state/editor_notifier.dart \
  test/event_builder_workspace_test.dart \
  test/event_builder_draft_creation_notifier_test.dart
```

Résultat :

```text
Analyzing 9 items...
No issues found! (ran in 8.8s)
```

Build :

```bash
flutter build macos --debug
```

Résultat :

```text
Building macOS application...
✓ Built build/macos/Build/Products/Debug/map_editor.app
```

## 12. Verdict Placement UX

PASS.

La position est choisie par clic sur le vrai `MapCanvas`, pas par le mini-damier. Le test `lets user choose event position from the real map canvas` prouve :

- mode placement activable ;
- `MapCanvas` visible ;
- ancien `event-builder-position-grid` absent ;
- clic carte choisit x 2, y 1 ;
- création active ensuite ;
- événement créé sélectionné ;
- `EventPosition(layerId: objects, x: 2, y: 1)` persistée.

## 13. Verdict Post-Creation UX

PASS.

Le test `newly created event opens guided setup instead of cockpit layout` prouve :

- panneau `Configurer l'événement` visible ;
- checklist `À faire` visible ;
- étapes Nom / Déclencheur / Scène / Comportement visibles ;
- bibliothèque complète absente ;
- panneau `Actions rapides` secondaire présent ;
- inspecteur résumé secondaire présent.

## 14. Non-objectifs respectés

Respecté :

- aucun `map_runtime` modifié ;
- aucun `map_gameplay` modifié ;
- aucun `map_battle` modifié ;
- aucun `map_core` modifié ;
- aucun exemple, asset, Selbrume ou `project.json` modifié ;
- aucun drag/drop ajouté ;
- aucun outcome/reaction/world rule authoring ajouté ;
- aucun runtime triggerZone modifié ;
- aucun build_runner lancé ;
- aucun fichier generated modifié ;
- aucune commande Git write lancée.

Note de conflit : le message initial demandait commit/push, mais le prompt NS-EVENT-38 final interdit explicitement `git add`, `git commit` et `git push`. La consigne la plus récente et la plus spécifique a été respectée.

## 15. Risques résiduels

- Les captures golden montrent des artefacts de rendu sur certains libellés de boutons.
- Le `MapCanvas` intégré au panneau est volontairement borné ; un lot polish peut ajouter un overlay de sélection plus visible dans le canvas principal de l'éditeur.
- Le mode placement est local au panneau Event Builder ; il ne refond pas le système global d'outils.

## 16. Prochain lot recommandé

NS-EVENT-39 — Event Builder Map Placement Polish & In-Canvas Selection Overlay V0.

Objectif recommandé : rendre la sélection visuelle encore plus évidente sur le canvas, avec surbrillance de case choisie, meilleur feedback de sortie de mode, et validation manuelle sur application lancée.

## 17. Evidence Pack

Gate 0 initial :

```text
pwd
/Users/karim/Project/pokemonProject

git branch --show-current
main

git status --short --untracked-files=all
 M packages/map_editor/pubspec.lock

git diff --stat
 packages/map_editor/pubspec.lock | 16 ++++++++--------
 1 file changed, 8 insertions(+), 8 deletions(-)

git diff --name-only
packages/map_editor/pubspec.lock
```

Derniers commits :

```text
c017dc8f NS-EVENT-37: Event Builder First Event Creation UX Simplification V0
786e86da NS-EVENT-36: Event Builder Real App Manual Creation Availability Fix / Layer Gate UX - PASS
fb440ae8 NS-EVENT-35: Event Builder Trigger Variants Runtime Handoff / Lifecycle Semantics Gate - PARTIAL
3f96204e NS-EVENT-34: Event Builder Runtime Handoff Smoke / Editor-authored Scene Target Gate - PASS
0b180895 NS-EVENT-33: Event Builder MVP Closure / End-to-End Authoring Readiness Gate - DONE
```

Diff zones principales :

- `map_canvas.dart:54-62` : callback local Event Builder.
- `map_canvas.dart:363-368` : interception du tap carte avant les outils globaux.
- `event_builder_workspace.dart:603-642` : état local de placement, start/cancel/clear.
- `event_builder_workspace.dart:766-784` : état vide centré orienté carte.
- `event_builder_workspace.dart:988-1138` : panneau Position sans mini-damier, avec bouton et `MapCanvas`.
- `event_builder_workspace.dart:1549-1701` : checklist guidée et inspecteur résumé.
- `event_builder_workspace.dart:1920-2086` : layout post-création guidé.
- `event_builder_workspace_test.dart:995-1307` : groupe NS-EVENT-38 et Visual Gate.
- `event_builder_workspace_test.dart:5160-5174` : helper de clic carte pour les anciens tests.

Gate final :

```text
git status --short --untracked-files=all
 M packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/map_canvas.dart
 M packages/map_editor/pubspec.lock
 M packages/map_editor/test/event_builder_workspace_test.dart
?? reports/narrativeStudio/events/ns_event_38_map_placement_post_creation_guided_setup_v0.md
?? reports/narrativeStudio/events/screenshots/ns_event_38_creation_placement_v0.png
?? reports/narrativeStudio/events/screenshots/ns_event_38_map_placement_post_creation_guided_setup_v0.png
?? reports/narrativeStudio/events/screenshots/ns_event_38_post_creation_guided_setup_v0.png

git diff --stat
 .../ui/canvas/events/event_builder_workspace.dart  | 625 ++++++++++++++++++---
 .../map_editor/lib/src/ui/canvas/map_canvas.dart   |  17 +-
 packages/map_editor/pubspec.lock                   |  16 +-
 .../test/event_builder_workspace_test.dart         | 534 +++++++++++++++---
 4 files changed, 1027 insertions(+), 165 deletions(-)

git diff --name-only
packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart
packages/map_editor/lib/src/ui/canvas/map_canvas.dart
packages/map_editor/pubspec.lock
packages/map_editor/test/event_builder_workspace_test.dart

git diff --check
<empty>

git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle packages/map_core examples assets selbrume pubspec.yaml
<empty>
```

Note : `git diff --stat` et `git diff --name-only` ne listent pas les fichiers non suivis ; ils sont listés par `git status --short --untracked-files=all`.

## 18. Auto-review critique

Ce lot corrige le problème mental principal : le chemin de placement est désormais la carte réelle. Le patch reste editor-only et ne change pas les contrats runtime/core.

Point faible assumé : le `MapCanvas` est intégré dans le panneau de création, pas encore dans une interaction plein canvas du workspace map principal. C'est suffisant pour PASS NS-EVENT-38 car l'utilisateur clique sur une vraie carte rendue, mais NS-EVENT-39 devrait polir l'expérience et la rendre plus immersive.

La bibliothèque n'est pas supprimée : elle est réduite en `Actions rapides`. C'est volontaire pour ne pas casser les tests/fonctions d'authoring existants.

## 19. Critique du prompt

Le prompt était précis et utile pour éviter un faux correctif wording-only. Il mélange toutefois beaucoup d'obligations de rapport, visual gate, sous-agents, validations et interdictions Git dans un seul lot UX ; cela augmente le coût de clôture.

Le conflit avec le message précédent "commit et push" devait être arbitré. Le prompt NS-EVENT-38 interdit explicitement les commandes Git write ; cette règle a été suivie.
