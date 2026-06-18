# NS-EVENT-28 — Event Builder World Changes Read-only Projection Polish V0

## 1. Résumé exécutif

NS-EVENT-28 est **DONE**.

Le lot polit le bloc **Changements du monde** de l'Event Builder sans ouvrir d'authoring nouveau. Le workspace affiche maintenant les effets monde comme une **projection en lecture seule**, avec des catégories no-code, un état vide honnête, des badges `Lecture seule` / `Projection`, et une explication claire du cas `event consumed`.

Le lot ne modifie pas `map_core`, ne crée aucun outcome, aucune réaction, aucune World Rule, aucune SceneConsequence, aucun drag/drop et aucun runtime bridge.

## 2. Confirmation du scope

Scope exécuté :

- améliorer le wording du bloc `Changements du monde`;
- afficher les `EventBuilderWorldImpactReadModel` existants avec des catégories humaines;
- clarifier la bibliothèque Monde en lecture seule;
- ajouter une ligne de synthèse dans l'inspecteur;
- couvrir le comportement par tests widget;
- produire une Visual Gate.

Hors scope respecté :

- pas de `EventReaction`;
- pas de `EventOutcome`;
- pas de `SceneConsequenceKind`;
- pas de mutation `map_core`;
- pas de runtime, gameplay, battle, Selbrume;
- pas de drag/drop;
- pas de bouton `Ajouter un changement`;
- pas de bouton `Créer une règle monde`.

## 3. Audit initial

### Gate 0

Commande :

```bash
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git log --oneline -n 20
```

Sortie utile :

```text
/Users/karim/Project/pokemonProject
main
```

`git status --short --untracked-files=all`, `git diff --stat` et `git diff --name-only` étaient vides au démarrage du lot.

Début de `git log --oneline -n 20` :

```text
e13ebb6e NS-EVENT-27: Implement Event Builder Scene Outcomes and Lifecycle Projection UI V0
b7fce79e NS-EVENT-26: Implement Event Builder Scene Outcomes and Lifecycle Projection Read Model V0
36a8f362 NS-EVENT-25: Add outcomes, reactions, and consequences contract alignment audit report
```

### Règles lues

- `AGENTS.md`
- `codex_rule.md`
- `skills/README.md`
- `skills/using-superpowers/SKILL.md`
- `skills/test-driven-development/SKILL.md`
- `skills/verification-before-completion/SKILL.md`
- `skills/dispatching-parallel-agents/SKILL.md`
- `skills/subagent-driven-development/SKILL.md`

### Fichiers audités

- `packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/events/event_builder_inspector_panel.dart`
- `packages/map_editor/lib/src/ui/canvas/events/event_builder_element_library.dart`
- `packages/map_editor/test/event_builder_workspace_test.dart`
- `packages/map_core/lib/src/read_models/event_builder_read_model.dart`
- `packages/map_core/lib/src/authoring/event_builder_contract.dart`
- `packages/map_core/lib/src/authoring/event_builder_authoring_operations.dart`
- `reports/narrativeStudio/events/ns_event_25_outcomes_reactions_consequences_contract_alignment_audit.md`
- `reports/narrativeStudio/events/ns_event_26_scene_outcomes_lifecycle_projection_read_model_v0.md`
- `reports/narrativeStudio/events/ns_event_27_scene_outcomes_lifecycle_projection_ui_v0.md`

### Constat

Le read model expose déjà `EventBuilderWorldImpactReadModel` avec :

```text
kind
sourceId
label
reason
```

Les kinds existants sont :

```text
fact
storyStep
consumedEvent
```

La production réelle observée côté `map_core` est volontairement limitée : l'impact `consumedEvent` est projeté pour les événements `oneShot`. Le lot devait donc rester une projection UI et ne pas inventer de nouvelles mutations monde.

## 4. Verdict des sub-agents

### Sub-agent A — UI Structure / World Block

Verdict : le bloc Monde existant était trop sec et utilisait le libellé `Piloté par les conséquences de scène.`, qui pouvait surpromettre. La recommandation retenue est un bloc dédié qui dit explicitement `Effets prévisibles en lecture seule.`

### Sub-agent B — Read Model Consumer

Verdict : l'UI doit consommer `selected.worldImpacts` sans recalcul depuis les metadata Event. Aucune modification `map_core` n'est nécessaire pour ce lot.

### Sub-agent C — UX / Wording

Verdict : utiliser un vocabulaire no-code :

- `Fait du monde`;
- `Étape narrative`;
- `Événement consommé`;
- `Lecture seule`;
- `Projection`.

Le wording anglais du reason par défaut est remplacé côté affichage par une phrase française.

### Sub-agent D — Tests / Regression

Verdict : ajouter des tests widget NS-EVENT-28 couvrant état vide, catégories, garde-fous read-only, bibliothèque Monde et non-régression NS-EVENT-27.

### Sub-agent E — Critique contradictoire

Verdict : ne pas ajouter de bouton authoring Monde et ne pas laisser croire que World Rules sont créées depuis l'Event Builder. Le lot doit clarifier, pas élargir.

## 5. Fichiers modifiés

### `packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart`

Zones modifiées :

- remplacement du message brut du bloc Monde;
- ajout de `_WorldImpactsProjectionBlock`;
- ajout de `_WorldImpactProjectionRow`;
- ajout des helpers `_worldImpactCategoryLabel`, `_worldImpactIcon`, `_worldImpactReadableReason`;
- suppression de `_MutedText` devenu inutile.

Impact :

- le bloc Monde affiche un état vide honnête;
- les impacts sont catégorisés avec badges `Lecture seule` et `Projection`;
- le reason anglais de `consumedEvent` n'est plus exposé comme expérience principale;
- aucun contrôle d'authoring Monde n'est ajouté.

Hunk principal :

```diff
-            const _MutedText('Piloté par les conséquences de scène.'),
-            if (selected.worldImpacts.isNotEmpty) ...[
-              const SizedBox(height: 8),
-              for (final impact in selected.worldImpacts)
-                _DetailLine(label: impact.reason, value: impact.label),
-            ],
+            _WorldImpactsProjectionBlock(
+              impacts: selected.worldImpacts,
+            ),
```

### `packages/map_editor/lib/src/ui/canvas/events/event_builder_inspector_panel.dart`

Zones modifiées :

- ajout de la ligne `Changements monde`;
- ajout de `_worldImpactsInspectorLabel(...)`.

Impact :

- l'inspecteur donne une synthèse courte, sans transformer la projection Monde en éditeur.

Hunk principal :

```diff
+                  _InspectorLine(
+                    label: 'Changements monde',
+                    value: _worldImpactsInspectorLabel(event.worldImpacts),
+                  ),
```

### `packages/map_editor/lib/src/ui/canvas/events/event_builder_element_library.dart`

Zones modifiées :

- ajout de `unavailableLabel`;
- ajout de `unavailableFeedback`;
- renommage de l'item Monde en `Afficher ou masquer un élément`;
- badge `Lecture seule`;
- feedback `Cet élément se règle depuis les règles du monde.`

Impact :

- la bibliothèque garde une trace de la cible UI sans proposer une action non supportée.

Hunk principal :

```diff
-          id: 'world-enable-element',
-          label: 'Activer élément',
+          id: 'world-element',
+          label: 'Afficher ou masquer un élément',
           icon: CupertinoIcons.eye,
           tone: PokeMapTone.map,
           available: false,
+          unavailableLabel: 'Lecture seule',
+          unavailableFeedback:
+              'Cet élément se règle depuis les règles du monde.',
```

### `packages/map_editor/test/event_builder_workspace_test.dart`

Zones modifiées :

- ajout des tests NS-EVENT-28;
- ajout du helper `_readModelWithWorldImpacts(...)`;
- ajout de la capture NS-EVENT-28;
- ajustement d'anciennes assertions qui supposaient l'ancien wording ou une occurrence unique.

Tests ajoutés :

- `NS-EVENT-28 renders empty world impacts as read-only guidance`
- `NS-EVENT-28 renders world impact categories as projections`
- `NS-EVENT-28 keeps world projection free of authoring controls`
- `NS-EVENT-28 keeps world library item read-only and explanatory`
- `NS-EVENT-28 preserves NS-EVENT-27 projections`
- `captures NS-EVENT-28 world changes readonly visual gate`

## 6. Tests RED

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact test/event_builder_workspace_test.dart --name "NS-EVENT-28"
```

Sorties RED utiles :

```text
Expected: exactly one matching candidate
Actual: _TextWidgetFinder:<Found 0 widgets with text "Effets prévisibles en lecture seule.">
```

Après un premier ajustement de test, le RED utile a aussi confirmé l'absence des catégories :

```text
Expected: exactly one matching candidate
Actual: _TextWidgetFinder:<Found 0 widgets with text "Fait du monde">
```

Ces échecs confirmaient que les tests couvraient bien le polish attendu avant l'implémentation.

## 7. Tests GREEN et régressions

### Tests NS-EVENT-28 ciblés

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact test/event_builder_workspace_test.dart --name "NS-EVENT-28"
```

Résultat :

```text
00:03 +5: All tests passed!
```

### Visual Gate NS-EVENT-28

Commande :

```bash
cd packages/map_editor
flutter test --update-goldens --reporter=compact --dart-define=NS_EVENT_28_CAPTURE_WORKSPACE=true test/event_builder_workspace_test.dart --name "captures NS-EVENT-28"
```

Résultat :

```text
00:02 +1: All tests passed!
```

### Suite widget Event Builder complète

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact test/event_builder_workspace_test.dart
```

Résultat :

```text
00:09 +86: All tests passed!
```

### Test core read model

Commande :

```bash
cd packages/map_core
dart test --reporter=compact test/event_builder_read_model_test.dart
```

Résultat :

```text
00:00 +22: All tests passed!
```

## 8. Analyse et build

### Analyse ciblée

Commande :

```bash
cd packages/map_editor
flutter analyze --no-fatal-infos lib/src/ui/canvas/events/event_builder_workspace.dart lib/src/ui/canvas/events/event_builder_inspector_panel.dart lib/src/ui/canvas/events/event_builder_element_library.dart test/event_builder_workspace_test.dart
```

Résultat :

```text
Analyzing 4 items...
No issues found! (ran in 1.7s)
```

### Build macOS debug

Commande :

```bash
cd packages/map_editor
flutter build macos --debug
```

Résultat :

```text
Building macOS application...
✓ Built build/macos/Build/Products/Debug/map_editor.app
```

## 9. Visual Gate

Fichier :

```text
reports/narrativeStudio/events/screenshots/ns_event_28_world_changes_readonly_projection_polish_v0.png
```

Preuve :

```text
PNG image data, 1280 x 820, 8-bit/color RGBA, non-interlaced
SHA-256: 3f5e1bce2c90f31c39e3713a49c75e4d6e7e8ebbd0c0cd0c514d3c9e38027509
```

La capture montre le workspace Event Builder avec le bloc Monde en lecture seule, les catégories de projection et les badges attendus.

## 10. Non-objectifs respectés

Vérifications :

- aucun fichier `packages/map_core` modifié;
- aucun fichier `packages/map_runtime` modifié;
- aucun fichier `packages/map_gameplay` modifié;
- aucun fichier `packages/map_battle` modifié;
- aucun fichier `selbrume` modifié;
- aucune donnée `assets` modifiée;
- aucun `pubspec.yaml` modifié;
- aucun bouton authoring Monde ajouté;
- aucun drag/drop ajouté;
- aucun runtime bridge ajouté.

## 11. Impact sur NS-EVENT-29

NS-EVENT-29 peut s'appuyer sur un bloc Monde plus clair pour décider la suite.

Recommandation : continuer par un lot contractuel ou read-model centré sur la projection Scene/World Rules si le produit veut enrichir ce bloc. Ne pas démarrer par l'authoring direct des World Rules depuis Event Builder.

## 12. Limites restantes

- Les catégories `fact` et `storyStep` sont couvertes UI via fixtures de test, mais le producteur `map_core` observé ne génère pas encore toutes ces projections depuis des conséquences réelles.
- Le bloc Monde reste volontairement read-only.
- Les World Rules impactées ne sont pas simulées.
- La fiabilité de `event consumed` reste détaillée dans le bloc Comportement / lifecycle.

## 13. Evidence Pack

### Gate final

Commande :

```bash
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git diff --check
```

Sortie :

```text
 M packages/map_editor/lib/src/ui/canvas/events/event_builder_element_library.dart
 M packages/map_editor/lib/src/ui/canvas/events/event_builder_inspector_panel.dart
 M packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart
 M packages/map_editor/test/event_builder_workspace_test.dart
?? reports/narrativeStudio/events/ns_event_28_world_changes_readonly_projection_polish_v0.md
?? reports/narrativeStudio/events/screenshots/ns_event_28_world_changes_readonly_projection_polish_v0.png
 .../events/event_builder_element_library.dart      |  17 +-
 .../events/event_builder_inspector_panel.dart      |  13 +
 .../ui/canvas/events/event_builder_workspace.dart  | 213 +++++++++++--
 .../test/event_builder_workspace_test.dart         | 338 ++++++++++++++++++++-
 4 files changed, 550 insertions(+), 31 deletions(-)
packages/map_editor/lib/src/ui/canvas/events/event_builder_element_library.dart
packages/map_editor/lib/src/ui/canvas/events/event_builder_inspector_panel.dart
packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart
packages/map_editor/test/event_builder_workspace_test.dart
```

`git diff --check` n'a produit aucune sortie.

Commande anti-scope :

```bash
git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle packages/map_core examples assets selbrume pubspec.yaml
```

Sortie :

```text
<vide>
```

Commande screenshots :

```bash
find reports/narrativeStudio/events/screenshots -maxdepth 1 -name '*ns_event_28*' -print
```

Sortie :

```text
reports/narrativeStudio/events/screenshots/ns_event_28_world_changes_readonly_projection_polish_v0.png
```

### Fichiers créés

```text
reports/narrativeStudio/events/ns_event_28_world_changes_readonly_projection_polish_v0.md
reports/narrativeStudio/events/screenshots/ns_event_28_world_changes_readonly_projection_polish_v0.png
```

### Fichiers modifiés

```text
packages/map_editor/lib/src/ui/canvas/events/event_builder_element_library.dart
packages/map_editor/lib/src/ui/canvas/events/event_builder_inspector_panel.dart
packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart
packages/map_editor/test/event_builder_workspace_test.dart
```

### Diff stat avant rapport

```text
.../events/event_builder_element_library.dart      |  17 +-
.../events/event_builder_inspector_panel.dart      |  13 +
.../ui/canvas/events/event_builder_workspace.dart  | 213 +++++++++++--
.../test/event_builder_workspace_test.dart         | 338 ++++++++++++++++++++-
4 files changed, 550 insertions(+), 31 deletions(-)
```

### Commandes exécutées

```bash
cd packages/map_editor && flutter test --reporter=compact test/event_builder_workspace_test.dart --name "NS-EVENT-28"
cd packages/map_editor && flutter test --update-goldens --reporter=compact --dart-define=NS_EVENT_28_CAPTURE_WORKSPACE=true test/event_builder_workspace_test.dart --name "captures NS-EVENT-28"
cd packages/map_editor && flutter test --reporter=compact test/event_builder_workspace_test.dart
cd packages/map_core && dart test --reporter=compact test/event_builder_read_model_test.dart
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/events/event_builder_workspace.dart lib/src/ui/canvas/events/event_builder_inspector_panel.dart lib/src/ui/canvas/events/event_builder_element_library.dart test/event_builder_workspace_test.dart
cd packages/map_editor && flutter build macos --debug
```

### Notes sur les sorties

Les commandes Flutter affichent les avertissements habituels de dépendances obsolètes incompatibles avec les contraintes actuelles. Elles n'ont pas bloqué les tests, l'analyse ou le build.

## 14. Auto-review critique

- Le lot ne modifie pas la source de vérité : l'UI consomme seulement `worldImpacts`.
- Le wording ne vend pas une exécution runtime ou une authoring capability inexistante.
- Les boutons dangereux restent absents.
- Le remplacement du reason anglais par une phrase française est uniquement un mapping d'affichage.
- Les tests couvrent l'état vide, les catégories, la bibliothèque Monde, la non-régression NS-EVENT-27 et la capture.
- Le seul risque restant est que le terme `impact(s) prévisible(s)` reste un peu générique; il est acceptable pour V0 car il est immédiatement encadré par `Lecture seule` et `Projection`.

## 15. Critique du prompt

Le prompt était cohérent avec NS-EVENT-25/26/27. La seule prudence importante est que la demande de polish des catégories `Fact` / `Step` pourrait faire croire que ces impacts sont tous déjà produits par `map_core`; l'audit a montré que ce n'est pas encore le cas. Le lot a donc utilisé des fixtures UI pour prouver le rendu de catégories existantes dans le contrat, sans prétendre que toutes sont générées par le pipeline actuel.
