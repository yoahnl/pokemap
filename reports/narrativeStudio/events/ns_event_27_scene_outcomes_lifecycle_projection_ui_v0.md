# NS-EVENT-27 — Event Builder Scene Outcomes / Lifecycle Projection UI V0

## 1. Résumé exécutif

NS-EVENT-27 est implémenté côté `map_editor` uniquement.

Le workspace Événements consomme maintenant les projections read-only exposées par NS-EVENT-26 :

- `EventBuilderEventSummary.sceneOutcomes` pour afficher les issues déclarées par la Scene liée ;
- `EventBuilderEventSummary.lifecycle` pour expliquer la cohérence entre `oneShot` / `reusable` et les conséquences Scene `markEventConsumed`.

Décision principale : les résultats restent propriétaires de la Scene. L'Event Builder les affiche comme projection passive dans le bloc `Action principale`, attachée à `Jouer une scène`, et non comme une nouvelle phase authorable de l'Event.

## 2. Décision UI / Architecture

### Résultats possibles

Le bloc visible s'appelle :

```text
Issues de la scène liée
```

Il affiche :

- les issues déclarées par la Scene liée ;
- les descriptions quand elles existent ;
- des badges `Lecture seule` et `Défini dans la scène` ;
- les états no-code `Aucune scène liée`, `Scène introuvable`, `Aucun résultat déclaré`.

Il n'ajoute aucun bouton :

```text
Ajouter un résultat
Ajouter une réaction
Modifier le résultat
```

### Lifecycle

Le bloc `Comportement` affiche maintenant la projection lifecycle :

- `Réutilisable` : aucune consommation d'événement nécessaire ;
- `Une seule fois` sans preuve Scene : intention non garantie au runtime ;
- `Une seule fois` avec `markEventConsumed` ciblant l'event courant : compatible, mais fragile si la Scene est réutilisée ;
- `Une seule fois` avec consommation d'un autre event : alerte no-code.

### Inspector

L'inspecteur droit reste secondaire. Il ajoute seulement deux lignes de synthèse :

```text
Résultats Scene
Lifecycle
```

Il ne contient aucune nouvelle action.

## 3. Sous-agents utilisés

Conformément au style PokeMap pour les surfaces transverses, cinq sous-agents ont été utilisés en lecture seule.

| Sous-agent | Verdict utile |
|---|---|
| A — UI Structure / Builder Central | Afficher les issues dans `Action principale`, pas comme phase Event-owned. |
| B — Read Model Consumer | `map_editor` ne passait pas encore `scenes` à `buildEventBuilderReadModel`; correction nécessaire. |
| C — Tests / Regression | Ajouter des tests widget sur les états `sceneOutcomes` et `lifecycle`. |
| D — UX No-code / Wording | Préférer `Issues de la scène liée`, `Lecture seule`, `Défini dans la scène`, éviter de promettre une garantie runtime. |
| E — Contradictory Reviewer | Refuser toute authoring de résultats/réactions/monde dans ce lot. |

Contradiction arbitrée : le prompt parlait d'un bloc `Résultats possibles` entre action et comportement, mais les sous-agents A/E ont signalé que cela pouvait faire croire à une ownership Event. L'arbitrage retenu est un sous-bloc visible dans `Action principale`, intitulé `Issues de la scène liée`, pour respecter le contrat NS-EVENT-25.

## 4. Gate 0

Commande :

```bash
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git log --oneline -n 20
```

Sorties :

```text
/Users/karim/Project/pokemonProject
main
<git status initial vide>
<git diff --stat initial vide>
<git diff --name-only initial vide>
b7fce79e NS-EVENT-26: Implement Event Builder Scene Outcomes and Lifecycle Projection Read Model V0
36a8f362 NS-EVENT-25: Add outcomes, reactions, and consequences contract alignment audit report
8c2bb4b2 ns_event_v1: Ajout des composants de l'éditeur d'événements et rapports associés
54c59fba ns_event_16: Consolidation de la disposition des blocs et disponibilité de la création d'activation de carte
8b3866a8 ns_event_15: Ajout de l'auteur des types de déclencheurs pour les événements
8a5996be ns_event_14: Ajout des conditions de consommation d'événements
7f490b9e ns_event_13: Ajout de l'auteur des conditions de fait pour les événements
26bec474 ns_event_12: Ajout de l'auteur des comportements pour les événements
00698aea ns_event_11: Ajout de l'auteur des actions de scène pour les événements
fc0e0be0 ns_event_10: Ajout de la saisie du titre pour les brouillons d'événements
cdedbe6e ns_event_09: Fermeture du flux de création de brouillon
d3f1866f ns_event_08: Ajout du sélecteur de position explicite sur la carte pour la création de brouillon
30ae9429 ns_event_07: Ajout de l'entrée UI explicite pour la création de brouillon avec position
3bd06d2b ns_event_06: Ajout des opérations de création de brouillon pour l'éditeur d'événements
6fe430d9 ns_event_05: Polissage des détails en lecture seule et diagnostics
1a551f41 ns_event_04: Ajout de l'espace de travail pour l'éditeur d'événements en lecture seule
7eed36b2 FG-NS-EVENT-003: Ajout du read model et diagnostics pour le builder d'événements
93b655dd FG-NS-EVENT-002-BIS: Préservation des conditions legacy et corrections dans le builder d'événements
6279df74 Remove legacy Narrative Studio steps entry
f54a8243 FG-NS-EVENT-002: Ajout des contrats et opérations pour le builder d'événements (core + tests)
```

## 5. Fichiers lus

Règles et skills :

```text
AGENTS.md
agent_rules.md
codex_rule.md
skills/README.md
skills/using-superpowers/SKILL.md
skills/verification-before-completion/SKILL.md
```

Code et tests :

```text
packages/map_core/lib/src/read_models/event_builder_read_model.dart
packages/map_core/lib/src/models/scene_asset.dart
packages/map_core/lib/src/models/scene_consequence.dart
packages/map_core/test/event_builder_read_model_test.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart
packages/map_editor/lib/src/ui/canvas/events/event_builder_inspector_panel.dart
packages/map_editor/lib/src/ui/canvas/events/event_builder_element_library.dart
packages/map_editor/test/event_builder_workspace_test.dart
```

Rapports :

```text
reports/narrativeStudio/events/ns_event_25_outcomes_reactions_consequences_contract_alignment_audit.md
reports/narrativeStudio/events/ns_event_26_scene_outcomes_lifecycle_projection_read_model_v0.md
```

## 6. Fichiers modifiés / créés

Modifiés :

```text
packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart
packages/map_editor/lib/src/ui/canvas/events/event_builder_inspector_panel.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/test/event_builder_workspace_test.dart
```

Créés :

```text
reports/narrativeStudio/events/ns_event_27_scene_outcomes_lifecycle_projection_ui_v0.md
reports/narrativeStudio/events/screenshots/ns_event_27_scene_outcomes_lifecycle_projection_ui_v0.png
```

## 7. Sections modifiées importantes

### `narrative_workspace_canvas.dart`

Le read model reçoit maintenant les `SceneAsset`, pas seulement les labels :

```dart
scenes: {
  for (final scene in project?.scenes ?? const <SceneAsset>[])
    scene.id: scene,
},
```

### `event_builder_workspace.dart`

Le bloc `Action principale` consomme `selected.sceneOutcomes` :

```dart
_SceneActionSlot(sceneAction: selected.sceneAction),
_SceneOutcomesProjectionSlot(
  projection: selected.sceneOutcomes,
),
```

Le bloc `Comportement` consomme `selected.lifecycle` :

```dart
_DetailLine(
  label: 'Réutilisation',
  value: selected.behavior.label,
),
_LifecycleProjectionNotice(lifecycle: selected.lifecycle),
```

### `event_builder_inspector_panel.dart`

Résumé secondaire ajouté :

```dart
_InspectorLine(
  label: 'Résultats Scene',
  value: _sceneOutcomesInspectorLabel(event.sceneOutcomes),
),
_InspectorLine(
  label: 'Lifecycle',
  value: _lifecycleInspectorLabel(event.lifecycle),
),
```

### `event_builder_workspace_test.dart`

Tests ajoutés :

```text
NS-EVENT-27 renders Scene outcomes as read-only projection
NS-EVENT-27 renders no Scene target projection
NS-EVENT-27 renders missing Scene projection
NS-EVENT-27 renders no declared outcomes projection
NS-EVENT-27 renders lifecycle states without runtime claims
captures NS-EVENT-27 scene outcomes lifecycle visual gate
```

## 8. Tests RED initiaux

Commande :

```bash
cd packages/map_editor && flutter test --reporter=compact test/event_builder_workspace_test.dart --name "NS-EVENT-27"
```

Sortie utile exacte :

```text
Expected: exactly one matching candidate
Actual: _TextWidgetFinder:<Found 0 widgets with text "Issues de la scène liée": []>
...
Expected: at least one matching candidate
Actual: _TextWidgetFinder:<Found 0 widgets with text "Intention non garantie au runtime.": []>
...
Some tests failed.
```

Après première implémentation, un bug de layout a aussi été capturé :

```text
A RenderFlex overflowed by 95 pixels on the right.
Row:file:///Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart:2706:22
```

Correction : les badges `Lecture seule` / `Défini dans la scène` ont été repliés sous le label de l'issue dans un `Wrap`.

## 9. Tests GREEN finaux

Commande :

```bash
cd packages/map_editor && flutter test --reporter=compact test/event_builder_workspace_test.dart --name "NS-EVENT-27"
```

Sortie :

```text
00:05 +5: All tests passed!
```

Commande :

```bash
cd packages/map_editor && flutter test --reporter=compact test/event_builder_workspace_test.dart
```

Sortie :

```text
00:09 +80: All tests passed!
```

Commande :

```bash
cd packages/map_core && dart test --reporter=compact test/event_builder_read_model_test.dart
```

Sortie :

```text
00:00 +22: All tests passed!
```

## 10. Analyse et build

Commande :

```bash
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/events/event_builder_workspace.dart lib/src/ui/canvas/events/event_builder_inspector_panel.dart lib/src/ui/canvas/events/event_builder_element_library.dart lib/src/ui/canvas/narrative_workspace_canvas.dart test/event_builder_workspace_test.dart
```

Sortie :

```text
Analyzing 5 items...
No issues found! (ran in 1.4s)
```

Commande :

```bash
cd packages/map_editor && flutter build macos --debug
```

Sortie :

```text
Building macOS application...
✓ Built build/macos/Build/Products/Debug/map_editor.app
```

Note : une exécution parallèle de l'analyse avec les tests a échoué sur un fichier Flutter éphémère :

```text
Unable to delete file or directory at ".../macos/Flutter/ephemeral/Packages/.packages".
```

Elle a été relancée seule et est passée.

## 11. Visual Gate

Commande :

```bash
cd packages/map_editor && flutter test --update-goldens --reporter=compact --dart-define=NS_EVENT_27_CAPTURE_WORKSPACE=true test/event_builder_workspace_test.dart --name "captures NS-EVENT-27"
```

Sortie :

```text
00:02 +1: All tests passed!
```

Capture :

```text
reports/narrativeStudio/events/screenshots/ns_event_27_scene_outcomes_lifecycle_projection_ui_v0.png
PNG image data, 1440 x 1100, 8-bit/color RGBA, non-interlaced
SHA-256: 234edb2d927f8300b520b523be2a0798be16f0f8d21ed71730d8083e86f93c3d
```

La capture montre :

- liste d'événements ;
- bibliothèque d'éléments ;
- builder central scrollé sur `Issues de la scène liée` ;
- lifecycle `Consommation explicite trouvée dans la Scene.` ;
- changements du monde read-only ;
- inspecteur droit avec `Résultats Scene` et `Lifecycle`.

## 12. Non-objectifs respectés

Confirmé :

- aucun runtime modifié ;
- aucun `map_core` modifié ;
- aucun `map_gameplay`, `map_battle`, `map_runtime` modifié ;
- aucun fichier Selbrume modifié ;
- aucun authoring d'outcome, réaction ou world rule ajouté ;
- aucun drag/drop ajouté ;
- aucun recalcul de `declaredOutcomes` dans l'UI ;
- aucun bouton `Ajouter un résultat` ou `Ajouter une réaction` dans le builder central.

## 13. Impact sur NS-EVENT-28

NS-EVENT-28 peut partir sur une projection plus fine des changements du monde ou sur un polish de bibliothèque, mais il ne doit pas démarrer l'authoring des réactions avant un contrat explicite Scene-owned.

Recommandation :

```text
NS-EVENT-28 — Event Builder World Changes Read-only Projection Polish V0
```

Objectif : améliorer la lecture des impacts Scene déjà projetés, sans créer d'authoring Event-owned.

## 14. Limites restantes

- Les issues Scene sont visibles mais non éditables dans l'Event Builder.
- Les réactions restent à configurer côté Scene, pas Event.
- Le wording `runtime` existe encore dans le message d'intention non garantie, parce que le read model NS-EVENT-26 expose ce vocabulaire ; l'UI ne promet pas de garantie.
- L'inspecteur est volontairement synthétique.

## 15. Auto-review critique

Points vérifiés :

- l'UI consomme `selected.sceneOutcomes` et `selected.lifecycle` ;
- `NarrativeWorkspaceCanvas` passe les `SceneAsset` au read model ;
- aucune lecture directe de `SceneAsset.declaredOutcomes` n'a été ajoutée dans l'UI ;
- les résultats restent attachés à `Action principale` pour ne pas créer une ownership Event ;
- les états no-code couvrent no scene, missing scene, no outcomes, outcomes déclarés ;
- lifecycle oneShot ne vend pas une vraie garantie runtime ;
- Visual Gate montre le bloc attendu.

Risque restant : le terme `Résultats` reste présent dans la bibliothèque en tant que groupe disabled `À venir`. C'est acceptable pour NS-EVENT-27 tant qu'il reste non actionnable ; un futur lot devra éventuellement renommer ce groupe en lecture Scene pour réduire l'ambiguïté.

## 16. Critique du prompt

Le prompt demandait un bloc `Résultats possibles` entre Action et Comportement. Après audit contradictoire, ce choix était risqué : il pouvait suggérer que l'Event Builder possède ses propres outcomes. L'adaptation retenue garde la visibilité demandée tout en affichant clairement que les issues appartiennent à la Scene.

L'usage du skill `product-design:image-to-code` a été adapté : la cible visuelle fournie sert de direction, mais ce lot n'était pas une reproduction pixel-perfect. L'objectif réel était d'intégrer une projection read-only dans le Flutter existant.

## 17. Evidence Pack

### Commandes exécutées

```bash
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git log --oneline -n 20
cd packages/map_editor && flutter test --reporter=compact test/event_builder_workspace_test.dart --name "NS-EVENT-27"
cd packages/map_editor && flutter test --update-goldens --reporter=compact --dart-define=NS_EVENT_27_CAPTURE_WORKSPACE=true test/event_builder_workspace_test.dart --name "captures NS-EVENT-27"
cd packages/map_editor && flutter test --reporter=compact test/event_builder_workspace_test.dart
cd packages/map_core && dart test --reporter=compact test/event_builder_read_model_test.dart
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/events/event_builder_workspace.dart lib/src/ui/canvas/events/event_builder_inspector_panel.dart lib/src/ui/canvas/events/event_builder_element_library.dart lib/src/ui/canvas/narrative_workspace_canvas.dart test/event_builder_workspace_test.dart
cd packages/map_editor && flutter build macos --debug
file reports/narrativeStudio/events/screenshots/ns_event_27_scene_outcomes_lifecycle_projection_ui_v0.png
shasum -a 256 reports/narrativeStudio/events/screenshots/ns_event_27_scene_outcomes_lifecycle_projection_ui_v0.png
```

### Diff stat avant rapport

```text
.../events/event_builder_inspector_panel.dart      |  40 +++
.../ui/canvas/events/event_builder_workspace.dart  | 281 ++++++++++++++++++
.../src/ui/canvas/narrative_workspace_canvas.dart  |   4 +
.../test/event_builder_workspace_test.dart         | 314 ++++++++++++++++++++-
4 files changed, 633 insertions(+), 6 deletions(-)
```

### Fichiers modifiés avant rapport

```text
packages/map_editor/lib/src/ui/canvas/events/event_builder_inspector_panel.dart
packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/test/event_builder_workspace_test.dart
```

### Gate final après écriture du rapport

```bash
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git diff --check
git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle packages/map_core examples assets selbrume pubspec.yaml
```

Sorties :

```text
 M packages/map_editor/lib/src/ui/canvas/events/event_builder_inspector_panel.dart
 M packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
 M packages/map_editor/test/event_builder_workspace_test.dart
?? reports/narrativeStudio/events/ns_event_27_scene_outcomes_lifecycle_projection_ui_v0.md
?? reports/narrativeStudio/events/screenshots/ns_event_27_scene_outcomes_lifecycle_projection_ui_v0.png

.../events/event_builder_inspector_panel.dart      |  40 +++
.../ui/canvas/events/event_builder_workspace.dart  | 281 ++++++++++++++++++
.../src/ui/canvas/narrative_workspace_canvas.dart  |   4 +
.../test/event_builder_workspace_test.dart         | 314 ++++++++++++++++++++-
4 files changed, 633 insertions(+), 6 deletions(-)

packages/map_editor/lib/src/ui/canvas/events/event_builder_inspector_panel.dart
packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/test/event_builder_workspace_test.dart

git diff --check: <vide>
anti-scope runtime/core/Selbrume: <vide>
```

Capture V1-27 :

```text
reports/narrativeStudio/events/screenshots/ns_event_27_scene_outcomes_lifecycle_projection_ui_v0.png
```
