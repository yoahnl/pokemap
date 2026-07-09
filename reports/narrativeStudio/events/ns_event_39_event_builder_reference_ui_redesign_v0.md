# NS-EVENT-39 — Event Builder Reference UI Redesign / Flow-Based Layout V0

Date : 2026-07-08

Repo : `/Users/karim/Project/pokemonProject`

Package concerné : `packages/map_editor`

## 1. Résumé exécutif

Verdict Reference UI Redesign : PASS, avec réserves de pixel-polish.

Image de référence utilisée : `/Users/karim/Downloads/ChatGPT Image Jul 8, 2026, 06_53_40 PM.png`.

Cause UX : après NS-EVENT-38, le placement carte et le setup guidé étaient fonctionnels, mais l'écran Event Builder ne ressemblait pas encore à un outil de flow clair. L'inspecteur était imbriqué dans le panneau central, le flow gardait un bloc `Comportement` séparé, et les conséquences monde n'étaient pas présentées comme une projection unifiée.

Correction : le workspace expose maintenant une structure visuelle `Liste d’événements / Bibliothèque d’éléments / Éditeur d’événement / Inspecteur d’événement`, avec un flow central `Déclencheur -> Conditions -> Action principale -> Conséquences projetées -> Diagnostics`, connecteurs visuels, bibliothèque read-only explicite, liste avec recherche, et inspecteur factuel.

Ce qui est prouvé : tests NS-EVENT-39, régressions NS-EVENT-38/37/36/33, suite complète `event_builder_workspace_test.dart`, notifier, analyse ciblée, MCP Dart, build macOS debug, Visual Gate PNG.

Ce qui reste à prouver : comparaison manuelle dans l'application desktop réelle hors golden, et polish pixel-perfect du chrome global supérieur qui n'est pas dans le scope direct du widget Event Builder.

Prochain lot recommandé : NS-EVENT-40 — Event Builder Shell-Level Pixel Polish & Real App Visual QA V0.

Blockers : aucun.

## 2. Image de référence utilisée

Référence fournie par l'utilisateur :

```text
/Users/karim/Downloads/ChatGPT Image Jul 8, 2026, 06_53_40 PM.png
```

Signaux repris :

- colonne navigation latérale déjà fournie par `NarrativeWorkspaceCanvas`;
- header `Événements` avec métriques et CTA `Préparer un événement`;
- quatre colonnes principales : liste, bibliothèque, flow central, inspecteur;
- flow central vertical avec blocs colorés et connecteurs;
- bibliothèque catégorisée avec disponibilité / lecture seule;
- inspecteur résumé factuel à droite.

Écarts assumés :

- le top chrome global exact de l'image n'a pas été refait, car le lot autorise `packages/map_editor` et le composant visé est l'Event Builder;
- la Visual Gate Flutter golden affiche encore certains glyphes d'icônes/boutons sous forme de blocs, déjà observé sur les lots précédents;
- aucune nouvelle fonctionnalité runtime ou authoring outcome/reaction/world rule n'a été ajoutée pour remplir artificiellement la maquette.

## 3. Usage du MCP Dart

MCP Dart utilisé.

Commandes MCP utiles :

```text
mcp__dart.roots add file:///Users/karim/Project/pokemonProject/packages/map_editor
Result: Success
```

Symboles résolus via LSP :

```text
EventBuilderWorkspace
EventBuilderElementLibrary
EventBuilderInspectorPanel
```

Analyse MCP :

```text
mcp__dart.analyze_files
Paths:
- lib/src/ui/canvas/events/event_builder_workspace.dart
- lib/src/ui/canvas/events/event_builder_central_flow.dart
- lib/src/ui/canvas/events/event_builder_element_library.dart
- lib/src/ui/canvas/events/event_builder_inspector_panel.dart
- test/event_builder_workspace_test.dart
- test/event_builder_draft_creation_notifier_test.dart

Result:
No errors
```

## 4. Sous-agents ou passes utilisées

Orchestrateur principal : Codex.

Passes spécialisées exécutées :

| Passe | Verdict | Synthèse |
|---|---|---|
| Audit / Architecture | PASS | `EventBuilderWorkspace` contenait déjà la matière fonctionnelle NS-EVENT-38, mais l'inspecteur restait imbriqué dans le flow. |
| UX Reference Layout | PASS | Structure quatre colonnes appliquée avec keys stables `event-builder-reference-*`. |
| Design System / Product Copy | PASS | Primitives PokeMap conservées, pas de couleur brute, wording no-code. |
| Tests / Visual Gate | PASS | Groupe NS-EVENT-39 ajouté, Visual Gate générée, anciennes attentes mises à jour. |
| Build / Validation | PASS | Tests, analyze, MCP Dart et build macOS debug passent. |
| Critique finale | PASS avec réserves | Le layout suit fortement la référence, mais pas le chrome global pixel-perfect hors scope. |

## 5. Audit initial

Gate 0 avant modification :

```text
Command: pwd
Result:
/Users/karim/Project/pokemonProject

Command: git branch --show-current
Result:
main

Command: git status --short --untracked-files=all
Result:
 M packages/map_editor/pubspec.lock

Command: git diff --stat
Result:
 packages/map_editor/pubspec.lock | 16 ++++++++--------
 1 file changed, 8 insertions(+), 8 deletions(-)

Command: git diff --name-only
Result:
packages/map_editor/pubspec.lock
```

Historique récent :

```text
6fab98e4 NS-EVENT-38: Event Builder Map Placement & Post-Creation Guided Setup UX V0
c017dc8f NS-EVENT-37: Event Builder First Event Creation UX Simplification V0
786e86da NS-EVENT-36: Event Builder Real App Manual Creation Availability Fix / Layer Gate UX - PASS
fb440ae8 NS-EVENT-35: Event Builder Trigger Variants Runtime Handoff / Lifecycle Semantics Gate - PARTIAL
3f96204e NS-EVENT-34: Event Builder Runtime Handoff Smoke / Editor-authored Scene Target Gate - PASS
0b180895 NS-EVENT-33: Event Builder MVP Closure / End-to-End Authoring Readiness Gate - DONE
25cdf062 NS-EVENT-32: Event Builder World Rules Projection UX Closure / Validation Gate - DONE
972c73ad NS-EVENT-31: Implement Passive World Rules Projection UI V0 - DONE
a1480aeb NS-EVENT-30: Implement Passive World Rules Projection Read Model V0
3502ca74 NS-EVENT-29: Implement Linked Scene Consequences World Impact Projection Read Model V0
906809bb NS-EVENT-28: Polish Event Builder World Changes Read-only Projection UI
e13ebb6e NS-EVENT-27: Implement Event Builder Scene Outcomes and Lifecycle Projection UI V0
b7fce79e NS-EVENT-26: Implement Event Builder Scene Outcomes and Lifecycle Projection Read Model V0
36a8f362 NS-EVENT-25: Add outcomes, reactions, and consequences contract alignment audit report
8c2bb4b2 ns_event_v1: Ajout des composants de l'éditeur d'événements et rapports associés
54c59fba ns_event_16: Consolidation de la disposition des blocs et disponibilité de la création d'activation de carte
8b3866a8 ns_event_15: Ajout de l'auteur des types de déclencheurs pour les événements
8a5996be ns_event_14: Ajout des conditions de consommation d'événements
7f490b9e ns_event_13: Ajout de l'auteur des conditions de fait pour les événements
26bec474 ns_event_12: Ajout des comportements pour les événements
```

Drift préexistant :

```text
packages/map_editor/pubspec.lock
```

Il est resté hors scope : non revert, non volontairement modifié.

## 6. Diagnostic UX avant modification

Avant NS-EVENT-39 :

- la surface active ressemblait déjà à un builder, mais l'inspecteur était contenu dans `_EventDetailsPanel`;
- le layout n'avait pas de repères directs prouvant les quatre colonnes de l'image;
- le flow central affichait `Comportement` comme bloc principal séparé, alors que la référence met l'accent sur déclencheur, conditions, action, conséquences et diagnostics;
- les issues de scène étaient encore dans l'action principale au lieu d'être regroupées avec les conséquences projetées;
- la bibliothèque affichait des éléments read-only, mais pas assez de variantes `Résultats / Réactions / Monde`;
- certains tests et textes historiques acceptaient encore le mot `runtime` dans l'UI.

## 7. Décision UI finale

Décision : appliquer une refonte de layout, sans ajouter de fonctionnalités.

Le flux devient :

```text
Liste d’événements
Bibliothèque d’éléments
Éditeur d’événement
Inspecteur d’événement
```

Le flow central devient :

```text
Déclencheur
Conditions
Action principale
Conséquences projetées
Diagnostics
```

Le comportement reste éditable, mais comme sous-section de `Action principale`; cela conserve le contrat NS-EVENT-12 sans ajouter un sixième bloc principal.

## 8. Comparaison à l’image de référence

Reproduit fidèlement :

- quatre colonnes principales;
- liste avec recherche et regroupement;
- bibliothèque catégorisée;
- flow central vertical avec connecteurs `+`;
- inspecteur factuel à droite;
- blocs colorés selon les tons PokeMap existants;
- CTA `Préparer un événement`;
- conséquences projetées en lecture seule.

Écarts restants :

- le shell supérieur global de la référence n'est pas redessiné;
- l'image de référence a une densité plus large et plus d'événements fictifs;
- la Visual Gate Flutter ne rend pas parfaitement certains glyphes d'icônes/boutons;
- l'inspecteur `Voir sur la carte` est présent mais désactivé, car aucune navigation dédiée n'a été ajoutée dans ce lot.

## 9. Modifications appliquées

### `packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart`

Zones modifiées :

- `_EventBuilderWorkspaceState.build` : ajout du body quatre colonnes avec keys `event-builder-reference-body`, `event-builder-reference-list-column`, `event-builder-reference-library-column`, `event-builder-reference-flow-column`, `event-builder-reference-inspector-column`.
- `_inspectorPanelFor` : extraction de l'inspecteur hors `_EventDetailsPanel`, en conservant la key NS-EVENT-38 `event-builder-inspector-summary-panel` pour les événements fraîchement créés.
- `_EventListPanel` : conversion en `StatefulWidget`, ajout d'une recherche locale, regroupement par `groupKey`, empty result.
- `_EventDetailsPanel` : titre `Éditeur d’événement`, retrait de l'inspecteur imbriqué, ordre des blocs revu.
- `_FlowSubsection` : sous-section `Comportement` dans `Action principale`.
- `_ProjectedConsequencesBlock` : regroupe issues de scène, sources monde et règles concernées.
- `_ConditionDetailLine` : layout vertical pour éviter les overflows dans la colonne centrale plus étroite.
- `_lifecycleUiInfo` : remplace `Intention non garantie au runtime.` par `Intention à vérifier côté jeu.`.

Impact attendu : l'Event Builder lit comme un flow de configuration, pas comme un cockpit imbriqué.

### `packages/map_editor/lib/src/ui/canvas/events/event_builder_central_flow.dart`

Zones modifiées :

- ajout de `_FlowConnector`;
- insertion d'un connecteur visuel entre les blocs.

Impact attendu : le flow central ressemble davantage à une séquence de construction.

### `packages/map_editor/lib/src/ui/canvas/events/event_builder_element_library.dart`

Zones modifiées :

- `_ElementLibraryItemCard` : badge placé sous le bouton pour éviter les overflows;
- catégories enrichies : `Résultats`, `Réactions`, `Monde`;
- items read-only explicites : `Victoire`, `Défaite`, `Échec`, `Définir un Fact`, `Débloquer une quête`, `Fact du monde`, `Règle du monde`, `Source projetée`.

Impact attendu : la bibliothèque ressemble à la référence tout en restant honnête sur ce qui est authorable.

### `packages/map_editor/lib/src/ui/canvas/events/event_builder_inspector_panel.dart`

Zones modifiées :

- inspecteur refondu en résumé factuel;
- champs : `Nom`, `ID technique`, `Statut`, `Type de déclencheur`, `Cible`, `Portée`, `Conditions`, `Scène liée`, `Comportement`, `Position sur la carte`, `Issues de la scène`, `Changements du monde`, `Règles concernées`;
- bouton désactivé `Voir sur la carte`.

Impact attendu : l'inspecteur devient secondaire et lisible, comme dans l'image.

### `packages/map_editor/test/event_builder_workspace_test.dart`

Zones modifiées :

- ajout du groupe `NS-EVENT-39 reference UI redesign`;
- tests de layout quatre colonnes, ordre flow, read-only projections, garde-fous, placement NS-EVENT-38, inspecteur factuel, Visual Gate;
- adaptation des tests historiques aux libellés `Conséquences projetées`, `Règles concernées`, `Éditeur d’événement`;
- helpers de scroll stabilisés pour la liste et la bibliothèque.

Impact attendu : le redesign est prouvé sans casser les lots précédents.

## 10. Tests ajoutés / modifiés

Tests ajoutés sous `NS-EVENT-39` :

- `renders reference four-column event builder layout`
- `renders central flow blocks in expected order`
- `keeps Scene outcomes and world consequences read-only`
- `keeps forbidden Event-owned authoring absent`
- `keeps map placement creation flow working`
- `renders inspector summary with event facts`
- `captures reference UI visual gate`

Tests modifiés :

- NS-EVENT-05/12/16/19/20/21/27/28/31/33 : attentes ajustées au nouveau wording et au nouvel inspecteur.
- Helpers `_tapEventCard`, `_eventBuilderLibraryScrollable`.

## 11. Visual Gate

Capture créée :

```text
reports/narrativeStudio/events/screenshots/ns_event_39_event_builder_reference_ui_redesign_v0.png
```

Commande de génération :

```bash
cd packages/map_editor
flutter test --update-goldens --reporter=compact --dart-define=NS_EVENT_39_CAPTURE_WORKSPACE=true test/event_builder_workspace_test.dart --name "NS-EVENT-39 reference UI redesign captures reference UI visual gate"
```

Résultat :

```text
NS-EVENT-39 reference UI redesign captures reference UI visual gate
All tests passed!
```

## 12. Validations exécutées

RED TDD initial :

```bash
flutter test --reporter=compact test/event_builder_workspace_test.dart --name "NS-EVENT-39"
```

Résultat attendu avant code :

```text
0 passed, 6 failed, 1 skipped
Causes principales : event-builder-reference-body absent, event-builder-flow-block-consequences absent, inspector facts absents.
```

Tests ciblés finaux :

```bash
flutter test --reporter=compact test/event_builder_workspace_test.dart --name "NS-EVENT-39"
```

Résultat final :

```text
NS-EVENT-39 reference UI redesign captures reference UI visual gate
All tests passed!
```

Régressions :

```bash
flutter test --reporter=compact test/event_builder_workspace_test.dart --name "NS-EVENT-38"
flutter test --reporter=compact test/event_builder_workspace_test.dart --name "NS-EVENT-37"
flutter test --reporter=compact test/event_builder_workspace_test.dart --name "NS-EVENT-36"
flutter test --reporter=compact test/event_builder_workspace_test.dart --name "NS-EVENT-33"
```

Résultats :

```text
NS-EVENT-38 ... All tests passed!
NS-EVENT-37 ... All tests passed!
NS-EVENT-36 ... All tests passed!
NS-EVENT-33 ... All tests passed!
```

Suite complète :

```bash
flutter test --reporter=compact test/event_builder_workspace_test.dart
```

Résultat :

```text
00:14 +124: All tests passed!
```

Notifier :

```bash
flutter test --reporter=compact test/event_builder_draft_creation_notifier_test.dart
```

Résultat :

```text
00:01 +28: All tests passed!
```

Analyse ciblée :

```bash
flutter analyze --no-fatal-infos \
  lib/src/ui/canvas/events/event_builder_workspace.dart \
  lib/src/ui/canvas/events/event_builder_element_library.dart \
  lib/src/ui/canvas/events/event_builder_inspector_panel.dart \
  lib/src/ui/canvas/events/event_builder_creation_panel.dart \
  lib/src/ui/canvas/map_canvas.dart \
  test/event_builder_workspace_test.dart \
  test/event_builder_draft_creation_notifier_test.dart
```

Résultat :

```text
Analyzing 7 items...
No issues found! (ran in 8.4s)
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

## 13. Verdict Reference UI Redesign : PASS

PASS parce que :

- la structure quatre colonnes est livrée et testée;
- le flow central reprend l'ordre demandé;
- les conséquences sont projetées et read-only;
- l'inspecteur reprend les faits clés de l'image;
- NS-EVENT-38 reste fonctionnel;
- aucun runtime/core/gameplay/battle n'est modifié.

Réserve : PASS au niveau workspace Event Builder, pas pixel-perfect sur le shell global complet.

## 14. Non-objectifs respectés

Respecté :

- pas de modification `map_core`;
- pas de modification `map_runtime`;
- pas de modification `map_gameplay`;
- pas de modification `map_battle`;
- pas de modification `examples`;
- pas de modification `assets`;
- pas de modification `selbrume`;
- pas de modification `pubspec.yaml`;
- pas de drag/drop ajouté;
- pas d'authoring outcome ajouté;
- pas d'authoring reaction ajouté;
- pas d'authoring World Rule ajouté;
- pas de build_runner;
- pas de generated files.

Le fichier `packages/map_editor/pubspec.lock` est un drift préexistant hors scope.

## 15. Risques résiduels

- Le rendu exact du top chrome global de l'image reste hors scope.
- Les captures golden conservent des artefacts de glyphes, même si les assertions widget prouvent les textes.
- `Voir sur la carte` est volontairement désactivé; un lot dédié pourrait brancher une navigation réelle vers la carte.
- La colonne bibliothèque est scrollable : elle est plus riche, mais demande parfois un scroll pour atteindre `Monde`.

## 16. Prochain lot recommandé

```text
NS-EVENT-40 — Event Builder Shell-Level Pixel Polish & Real App Visual QA V0
```

Objectif recommandé :

- vérifier le rendu dans l'application desktop réelle;
- rapprocher le chrome global de l'image de référence;
- tester une capture intégrée hors golden si possible;
- décider si `Voir sur la carte` doit devenir une vraie navigation.

## 17. Evidence Pack

Fichiers modifiés par le lot :

```text
packages/map_editor/lib/src/ui/canvas/events/event_builder_central_flow.dart
packages/map_editor/lib/src/ui/canvas/events/event_builder_element_library.dart
packages/map_editor/lib/src/ui/canvas/events/event_builder_inspector_panel.dart
packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart
packages/map_editor/test/event_builder_workspace_test.dart
```

Fichiers créés :

```text
reports/narrativeStudio/events/screenshots/ns_event_39_event_builder_reference_ui_redesign_v0.png
reports/narrativeStudio/events/ns_event_39_event_builder_reference_ui_redesign_v0.md
```

Fichier modifié préexistant hors scope :

```text
packages/map_editor/pubspec.lock
```

Contrôles scope :

```text
Command: git status --short --untracked-files=all
Result:
 M packages/map_editor/lib/src/ui/canvas/events/event_builder_central_flow.dart
 M packages/map_editor/lib/src/ui/canvas/events/event_builder_element_library.dart
 M packages/map_editor/lib/src/ui/canvas/events/event_builder_inspector_panel.dart
 M packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart
 M packages/map_editor/pubspec.lock
 M packages/map_editor/test/event_builder_workspace_test.dart
?? reports/narrativeStudio/events/ns_event_39_event_builder_reference_ui_redesign_v0.md
?? reports/narrativeStudio/events/screenshots/ns_event_39_event_builder_reference_ui_redesign_v0.png

Command: git diff --stat
Result:
 .../canvas/events/event_builder_central_flow.dart  |  41 +-
 .../events/event_builder_element_library.dart      | 112 +++-
 .../events/event_builder_inspector_panel.dart      | 145 +++--
 .../ui/canvas/events/event_builder_workspace.dart  | 675 ++++++++++++---------
 packages/map_editor/pubspec.lock                   |  16 +-
 .../test/event_builder_workspace_test.dart         | 398 ++++++++++--
 6 files changed, 970 insertions(+), 417 deletions(-)

Command: git diff --name-only
Result:
packages/map_editor/lib/src/ui/canvas/events/event_builder_central_flow.dart
packages/map_editor/lib/src/ui/canvas/events/event_builder_element_library.dart
packages/map_editor/lib/src/ui/canvas/events/event_builder_inspector_panel.dart
packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart
packages/map_editor/pubspec.lock
packages/map_editor/test/event_builder_workspace_test.dart

Command: git diff --check
Result: no output

Command: git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle packages/map_core examples assets selbrume pubspec.yaml
Result: no output
```

Contenu complet des fichiers créés :

- `ns_event_39_event_builder_reference_ui_redesign_v0.png` : binaire PNG, non inclus inline.
- `ns_event_39_event_builder_reference_ui_redesign_v0.md` : le présent rapport.

## 18. Auto-review critique

Ce qui est solide :

- le scope reste dans `packages/map_editor`;
- les tests prouvent la structure et les garde-fous;
- les overflows découverts pendant la suite complète ont été corrigés;
- le wording `runtime` a été retiré du parcours principal;
- la bibliothèque ne promet pas d'authoring non livré.

Ce qui pourrait être amélioré :

- la capture pourrait être plus proche encore si le shell global était inclus;
- les tests vérifient la structure et le wording, pas une comparaison pixel par pixel contre l'image fournie;
- les catégories bibliothèque enrichissent l'UI, mais restent statiques.

Verdict critique : acceptable pour NS-EVENT-39, avec NS-EVENT-40 recommandé pour le pixel polish réel.

## 19. Critique du prompt

Le prompt est cohérent avec la continuité NS-EVENT-38 : il demande une refonte UI bornée et interdit explicitement le runtime.

Point de tension : la demande "quasi pixel-perfect" dépasse légèrement le scope d'un widget `EventBuilderWorkspace`, car l'image montre aussi un top chrome global. Interprétation appliquée : reproduire fortement la structure et les hiérarchies dans l'Event Builder, sans refaire le shell global.

Autre point : le prompt demande de ne pas ajouter de fonctionnalités. Les ajouts `Source projetée`, `Victoire`, `Défaite`, `Échec`, `Débloquer une quête` dans la bibliothèque sont des éléments read-only de présentation, pas des fonctionnalités authorables.
