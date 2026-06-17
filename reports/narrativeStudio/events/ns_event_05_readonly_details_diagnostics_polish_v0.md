# NS-EVENT-05 — Event Builder Read-only Details & Diagnostics Polish V0

## 1. Résumé exécutif

Verdict : `NS-EVENT-05 — DONE`.

Le lot améliore uniquement le workspace `EventBuilderWorkspace` en lecture seule :

- KPIs enrichis avec `Actifs` et `Brouillons`.
- Liste d'événements plus lisible pour les diagnostics et les actions manquantes.
- Panneau détail branché sur `EventBuilderSectionReadModel`.
- Sections enrichies avec résumé, compteur de diagnostics et badge `Bloquant`.
- Diagnostics lisibles avec gravité, section cible, chemin et référence si disponible.
- Condition legacy mixte clarifiée avec un message no-code en trois lignes.
- Informations techniques déplacées en zone secondaire.
- Visual Gate NS-EVENT-05 produite.

Non-objectifs respectés :

- aucun authoring d'événement ;
- aucun bouton de création / édition / sauvegarde ;
- aucun `map_core` modifié ;
- aucun runtime / gameplay / battle modifié ;
- aucun fichier Selbrume modifié ;
- aucun commit effectué.

## 2. UI read-only améliorée

Fichier modifié :

```text
packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart
```

Zones modifiées :

- `_EventBuilderWorkspaceState.build`
  - Ajout des compteurs `activeCount` et `draftCount`.
  - Ajout des KPIs `Actifs` et `Brouillons`.
- `_EventListCard`
  - Affichage `Aucune action principale` pour les brouillons sans scène.
  - Badge diagnostic `Aucun diagnostic` / `N diagnostic(s)` avec icône et tonalité selon présence d'erreur.
- `_EventDetailsPanel`
  - Passage du détail en `SingleChildScrollView + Column` pour rendre toute la structure testable et lisible.
  - Exploitation de `selected.sections` comme source des résumés et compteurs.
  - Ajout de la section `Informations techniques`.
- `_DetailSection`
  - Ajout des badges de compteur et de l'état `Bloquant`.
- `_DiagnosticNotice`
  - Ajout de la gravité no-code et des détails secondaires.
  - Découpage des messages multi-lignes pour rendre les phrases lisibles.

Extrait de diff :

```diff
+    final activeCount = widget.readModel.events
+        .where((event) => event.status == EventBuilderEventStatus.active)
+        .length;
+    final draftCount = widget.readModel.events
+        .where((event) => event.status == EventBuilderEventStatus.draft)
+        .length;
```

```diff
+              PokeMapStatusTile(
+                label: 'Actifs',
+                value: '$activeCount',
+                icon: CupertinoIcons.checkmark_circle,
+                tone: activeCount == 0
+                    ? PokeMapTone.neutral
+                    : PokeMapTone.success,
+              ),
+              PokeMapStatusTile(
+                label: 'Brouillons',
+                value: '$draftCount',
+                icon: CupertinoIcons.pencil_ellipsis_rectangle,
+                tone:
+                    draftCount == 0 ? PokeMapTone.neutral : PokeMapTone.warning,
+              ),
```

## 3. Sections affichées

Le panneau détail affiche maintenant :

- `Déclencheur`
- `Conditions`
- `Action principale`
- `Comportement`
- `Changements du monde`
- `Diagnostics`
- `Informations techniques`

Chaque section issue du read model affiche :

- son résumé ;
- `0 diagnostic` ou `N diagnostic(s)` ;
- un badge `Bloquant` si `hasBlockingDiagnostic == true`.

Extrait de diff :

```diff
+    final sections = {
+      for (final section in selected.sections) section.key: section,
+    };
```

```diff
+            _DetailSection(
+              title: 'Conditions',
+              section: sections['conditions'],
+              summaryOverride: selected.conditionEditingLocked
+                  ? 'Condition avancée conservée en lecture seule'
+                  : null,
```

## 4. Diagnostics améliorés

Les diagnostics affichent maintenant :

- une gravité no-code : `Erreur`, `Avertissement`, `Information`, `OK` ;
- la section cible : par exemple `Section : Action principale` ;
- le chemin technique secondaire : par exemple `Chemin : page.metadata.eventBuilder.reusePolicy` ;
- la référence secondaire si `referencedId` est disponible.

Extrait de diff :

```diff
+                    details: [
+                      'Section : ${_diagnosticSectionLabel(diagnostic.sectionTarget)}',
+                      if (diagnostic.path.isNotEmpty)
+                        'Chemin : ${diagnostic.path}',
+                      if (diagnostic.referencedId != null)
+                        'Référence : ${diagnostic.referencedId}',
+                    ],
```

## 5. Conditions legacy verrouillées

Le message de condition legacy mixte est maintenant clair et non-actionnable :

```text
Cette condition contient une partie avancée préservée.
Elle est lisible, mais pas encore éditable partiellement.
La condition complète est conservée telle quelle.
```

Le workspace affiche toujours les parties supportées visibles, par exemple :

```text
Fact "Départ accepté" est vrai
```

Il n'affiche aucune invitation à éditer ou ajouter une condition.

## 6. Empty / edge states couverts

Cas couverts par les tests et la fixture :

- aucun événement ;
- événement actif sans diagnostic ;
- événement brouillon sans action principale ;
- événement sans page ;
- événement inactif ;
- condition legacy mixte ;
- script/message legacy ;
- metadata malformée.

Le lot ne modifie pas le read model `map_core` : ces cas existaient déjà côté contrat, NS-EVENT-05 améliore seulement leur représentation UI.

## 7. Tests ajoutés / modifiés

Fichier modifié :

```text
packages/map_editor/test/event_builder_workspace_test.dart
```

Tests ajoutés :

```text
NS-EVENT-05 displays read-only sections with summaries
NS-EVENT-05 shows missing action diagnostic only for draft selection
NS-EVENT-05 explains locked legacy conditions clearly
NS-EVENT-05 surfaces legacy script and message warnings
NS-EVENT-05 surfaces malformed metadata warning
NS-EVENT-05 keeps the workspace read-only
captures NS-EVENT-05 readonly diagnostics visual gate
```

Tests NS-EVENT-04 adaptés :

- `NS-EVENT-04 renders statuses and no-code details`
  - Remplacement du wording legacy `Action principale manquante` en liste par `Aucune action principale`.
  - Utilisation de `_tapEventCard(...)` pour les événements hors viewport.
  - Alignement sur le nouveau message de condition legacy.
  - `ID technique` accepté comme zone secondaire répétée.

Extrait de diff :

```diff
+  testWidgets('NS-EVENT-05 displays read-only sections with summaries',
+      (tester) async {
+    await _pumpWorkspace(tester, _sampleReadModel());
+
+    expect(find.text('Déclencheur'), findsOneWidget);
+    expect(find.text('Conditions'), findsOneWidget);
+    expect(find.text('Action principale'), findsOneWidget);
+    expect(find.text('Comportement'), findsOneWidget);
+    expect(find.text('Changements du monde'), findsOneWidget);
+    expect(find.text('Diagnostics'), findsWidgets);
+    expect(find.text('Informations techniques'), findsOneWidget);
+  });
```

## 8. Visual Gate

Capture créée :

```text
reports/narrativeStudio/events/screenshots/ns_event_05_readonly_details_diagnostics_v0.png
```

Sorties exactes :

```bash
$ ls -lh ../../reports/narrativeStudio/events/screenshots/ns_event_05_readonly_details_diagnostics_v0.png
-rw-r--r--  1 karim  staff   171K Jun 17 14:27 ../../reports/narrativeStudio/events/screenshots/ns_event_05_readonly_details_diagnostics_v0.png

$ file ../../reports/narrativeStudio/events/screenshots/ns_event_05_readonly_details_diagnostics_v0.png
../../reports/narrativeStudio/events/screenshots/ns_event_05_readonly_details_diagnostics_v0.png: PNG image data, 1280 x 820, 8-bit/color RGBA, non-interlaced

$ shasum -a 256 ../../reports/narrativeStudio/events/screenshots/ns_event_05_readonly_details_diagnostics_v0.png
dfa7bf1701529bd429b27b004da77f5ac946531a4233bbca05d20c59fb830d2b  ../../reports/narrativeStudio/events/screenshots/ns_event_05_readonly_details_diagnostics_v0.png
```

La capture montre :

- le workspace `Événements` ;
- le badge `Lecture seule` ;
- les KPIs `Total`, `Actifs`, `Brouillons`, `Diagnostics`, `Portée` ;
- un événement avec condition legacy verrouillée ;
- le panneau détail enrichi ;
- les compteurs de diagnostics par section.

## 9. Validations exécutées

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

Sortie utile exacte :

```text
/Users/karim/Project/pokemonProject
main
1a551f41 ns_event_04: Ajout de l'espace de travail pour l'éditeur d'événements en lecture seule
7eed36b2 FG-NS-EVENT-003: Ajout du read model et diagnostics pour le builder d'événements
93b655dd FG-NS-EVENT-002-BIS: Préservation des conditions legacy et corrections dans le builder d'événements
6279df74 Remove legacy Narrative Studio steps entry
f54a8243 FG-NS-EVENT-002: Ajout des contrats et opérations pour le builder d'événements (core + tests)
410be446 FG-NS-EVENT-001: Alignement des contrats existants pour le builder d'événements
7b3b2151 FG-NS-EVENT-001: Ajout du plan MVP v1 pour le builder d'événements Narrative Studio
05e70a57 NS-STUDIO-PRODUCT-BETA-READINESS — Audit de préparation pour la bêta de Narrative Studio
da9cce15 NS-SCENES-V1-138 — Selbrume Golden Slice Content Inventory Asset Gap Audit
80dd997a NS-SCENES-V1-137 — Narrative Studio Golden Slice Authoring Readiness Selbrume Demo Content Plan
703c5702 NS-SCENES-V1-136-BIS — Cinematic Builder Legacy Widget Expectations Cleanup
0f9c5cfe NS-SCENES-V1-136 — Cinematic Builder V1 Closure Readiness Audit
2bd11dda NS-SCENES-V1-135 — Cinematic Builder V1 Camera Closure Polish Gate
179cd6aa NS-SCENES-V1-134 — Cinematic Camera Geometry Preview UI V0
28d0e46e NS-SCENES-V1-133 — Cinematic Camera Geometry Playback State V0
d4e0b28b NS-SCENES-V1-132 — Cinematic Camera Target Zoom Editor UI V0
882c2c23 NS-SCENES-V1-131 — Cinematic Camera Target Zoom Core Model V0
a7bb9b42 update selbrume
4c3040a3 update selbrume
47660d78 NS-SCENES-V1-130 — Cinematic Camera Target Zoom Authoring Prep Contract
```

`git status`, `git diff --stat` et `git diff --name-only` initiaux étaient vides.

### RED

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact test/event_builder_workspace_test.dart --name "NS-EVENT-05"
```

Sortie utile exacte :

```text
00:05 +1 -5: Some tests failed.
Expected: exactly one matching candidate
Actual: _TextWidgetFinder:<Found 0 widgets with text "Informations techniques": []>
Expected: exactly one matching candidate
Actual: _TextWidgetFinder:<Found 0 widgets with text "Section : Action principale": []>
Expected: at least one matching candidate
Actual: _TextWidgetFinder:<Found 0 widgets with text "Cette condition contient une partie avancée préservée.": []>
Expected: at least one matching candidate
Actual: _TextWidgetFinder:<Found 0 widgets with text "Avertissement": []>
Expected: exactly one matching candidate
Actual: _TextWidgetFinder:<Found 0 widgets with text "Section : Comportement": []>
```

Interprétation : les tests échouaient sur les manques UI attendus par NS-EVENT-05.

### GREEN ciblé NS-EVENT-05

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact test/event_builder_workspace_test.dart --name "NS-EVENT-05"
```

Sortie exacte :

```text
00:02 +0: NS-EVENT-05 displays read-only sections with summaries
00:02 +1: NS-EVENT-05 displays read-only sections with summaries
00:02 +1: NS-EVENT-05 shows missing action diagnostic only for draft selection
00:02 +2: NS-EVENT-05 shows missing action diagnostic only for draft selection
00:02 +2: NS-EVENT-05 explains locked legacy conditions clearly
00:02 +3: NS-EVENT-05 explains locked legacy conditions clearly
00:02 +3: NS-EVENT-05 surfaces legacy script and message warnings
00:02 +4: NS-EVENT-05 surfaces legacy script and message warnings
00:02 +4: NS-EVENT-05 surfaces malformed metadata warning
00:02 +5: NS-EVENT-05 surfaces malformed metadata warning
00:02 +5: NS-EVENT-05 keeps the workspace read-only
00:02 +6: NS-EVENT-05 keeps the workspace read-only
00:02 +6: All tests passed!
```

### Suite complète du fichier Event Builder

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact test/event_builder_workspace_test.dart
```

Sortie exacte :

```text
00:03 +10: All tests passed!
```

### Visual Gate

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact --update-goldens --dart-define=NS_EVENT_05_CAPTURE_WORKSPACE=true test/event_builder_workspace_test.dart --name "captures NS-EVENT-05"
```

Sortie exacte :

```text
00:06 +0: captures NS-EVENT-05 readonly diagnostics visual gate
00:06 +1: captures NS-EVENT-05 readonly diagnostics visual gate
00:06 +1: All tests passed!
```

### Analyse ciblée

Commande :

```bash
cd packages/map_editor
flutter analyze --no-fatal-infos lib/src/ui/canvas/events/event_builder_workspace.dart test/event_builder_workspace_test.dart
```

Sortie exacte :

```text
Analyzing 2 items...
No issues found! (ran in 1.2s)
```

### Build macOS debug

Commande :

```bash
cd packages/map_editor
flutter build macos --debug
```

Sortie exacte :

```text
Building macOS application...
✓ Built build/macos/Build/Products/Debug/map_editor.app
```

## 10. Non-objectifs respectés

Vérifié par inspection du diff :

- pas de bouton `Nouvel événement` ajouté ;
- pas de bouton `Créer`, `Sauvegarder`, `Supprimer`, `Ajouter une condition`, `Ajouter une action` ;
- pas de modification de `packages/map_core` ;
- pas de modification runtime/gameplay/battle ;
- pas de modification Selbrume ;
- pas de `build_runner` ;
- pas de fichier generated ;
- pas de commit.

## 11. Impact sur NS-EVENT-06

NS-EVENT-05 rend NS-EVENT-06 plus simple si le prochain lot reste read-only ou prépare l'authoring :

- la liste dispose déjà d'une hiérarchie plus lisible ;
- le détail affiche les sections du read model ;
- les diagnostics sont déjà localisés par section ;
- les cas legacy sont explicitement non éditables ;
- les tests couvrent les garde-fous read-only.

Le prochain lot peut donc se concentrer sur sa responsabilité propre sans réécrire le détail read-only.

## 12. Possibilité de grouper NS-EVENT-06 + NS-EVENT-07

Recommandation : possible seulement si les deux lots restent petits et cohérents.

Regroupement acceptable :

```text
NS-EVENT-06 + NS-EVENT-07 peuvent être groupés si le périmètre reste
read-only / sélection / filtres / préparation UX sans mutation de données.
```

Regroupement déconseillé :

```text
Ne pas grouper si l'un des deux lots démarre l'authoring, la sauvegarde,
les pickers de création, le runtime bridge ou la mutation MapEventDefinition.
```

## 13. Evidence Pack complet

### Fichiers lus

```text
/Users/karim/.codex/attachments/0d6b1cad-c808-44f0-960a-c69aaf9f338b/pasted-text.txt
AGENTS.md
agent_rules.md
codex_rule.md
skills/README.md
skills/test-driven-development/SKILL.md
skills/verification-before-completion/SKILL.md
packages/map_core/lib/src/read_models/event_builder_read_model.dart
packages/map_core/test/event_builder_read_model_test.dart
packages/map_core/lib/src/authoring/event_builder_contract.dart
packages/map_core/lib/src/authoring/event_builder_authoring_operations.dart
packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart
packages/map_editor/test/event_builder_workspace_test.dart
packages/map_editor/lib/src/ui/design_system/pokemap_badge.dart
packages/map_editor/lib/src/ui/design_system/pokemap_card.dart
```

### Fichiers modifiés

```text
packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart
packages/map_editor/test/event_builder_workspace_test.dart
```

### Fichiers créés

```text
reports/narrativeStudio/events/ns_event_05_readonly_details_diagnostics_polish_v0.md
reports/narrativeStudio/events/screenshots/ns_event_05_readonly_details_diagnostics_v0.png
```

### Fichiers supprimés

```text
<aucun>
```

### Sub-agents / passes séparées

Sub-agent Audit / Architecture :

- Verdict : `OK`.
- `map_core` expose déjà `sections`, `diagnosticCount`, `hasBlockingDiagnostic`, `conditionEditingLocked`.
- Aucune modification core nécessaire.

Sub-agent Implémentation :

- Verdict : `OK`.
- Changements limités au widget Event Builder read-only.
- Design system conservé : `PokeMapStatusTile`, `PokeMapBadge`, `PokeMapCard`, `PokeMapPanel`, `PokeMapTone`, `context.pokeMapColors`.

Sub-agent Tests :

- Verdict : `OK`.
- Tests RED observés.
- Tests GREEN ciblés et suite complète du fichier passés.

Sub-agent Build / Validation :

- Verdict : `OK`.
- Analyse ciblée propre.
- Build macOS debug réussi.
- Visual Gate produite.

Sub-agent Critique finale :

- Verdict : `OK avec réserve mineure`.
- La Visual Gate montre le détail enrichi sur la partie haute du panneau ; les sections basses restent accessibles par scroll mais ne sont pas toutes visibles en une seule capture.

### Diff / zones précises modifiées

Commande :

```bash
git diff -- packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart packages/map_editor/test/event_builder_workspace_test.dart
```

Zones principales :

```text
event_builder_workspace.dart
- _EventBuilderWorkspaceState.build
- _EventListCard.build
- _EventDetailsPanel.build
- _DetailSection
- _ConditionDetailLine
- _DiagnosticNotice
- _diagnosticBadgeVariant
- _diagnosticSeverityLabel
- _diagnosticSectionLabel

event_builder_workspace_test.dart
- NS-EVENT-04 renders statuses and no-code details
- nouveaux tests NS-EVENT-05
- nouvelle capture NS-EVENT-05
- fixture _sampleReadModel enrichie
- helper _tapEventCard
```

### Notes sur les commandes

Les commandes Flutter affichent des lignes `Resolving dependencies...`, `Downloading packages...` et une liste de packages plus récents incompatibles avec les contraintes. Ces lignes sont présentes sur les tests/analyse/build et ne bloquent pas les commandes.

## 14. Auto-review critique

Points vérifiés :

- Le workspace reste read-only.
- Les diagnostics ne prétendent pas être éditables.
- La condition legacy mixte n'est pas présentée comme partiellement éditable.
- Les IDs techniques restent secondaires.
- Les tests ne réintroduisent pas de workflow par ID.
- Aucune surface runtime n'est touchée.
- Aucune donnée Selbrume n'est touchée.

Risques / limites :

- La capture Visual Gate ne montre pas toutes les sections en bas du panneau, car le panneau détail est scrollable. Ce n'est pas bloquant : les tests vérifient bien `Changements du monde`, `Diagnostics` et `Informations techniques`.
- Les diagnostics restent limités aux informations disponibles dans le read model NS-EVENT-03. Le lot n'ajoute pas de nouveau diagnostic core.
- Le wording `1 impact(s) prévisible(s)` vient du read model ; un futur polish core pourrait produire une pluralisation plus élégante.

Critique du prompt :

- Le prompt est cohérent avec NS-EVENT-04 et le repo.
- Le seul point à cadrer est la Visual Gate : demander toutes les sections visibles en une seule capture peut être incompatible avec un panneau détail riche et scrollable. J'ai privilégié une capture lisible montrant le cas legacy verrouillé, et les tests couvrent le reste.
- Le prompt ne nécessite pas de `map_core`, et l'audit confirme que modifier `map_core` aurait été un élargissement inutile.

## Gate final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie exacte :

```text
 M packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart
 M packages/map_editor/test/event_builder_workspace_test.dart
?? reports/narrativeStudio/events/ns_event_05_readonly_details_diagnostics_polish_v0.md
?? reports/narrativeStudio/events/screenshots/ns_event_05_readonly_details_diagnostics_v0.png
```

Commande :

```bash
git diff --stat
```

Sortie exacte :

```text
 .../ui/canvas/events/event_builder_workspace.dart  | 468 +++++++++++++++------
 .../test/event_builder_workspace_test.dart         | 192 ++++++++-
 2 files changed, 518 insertions(+), 142 deletions(-)
```

Note : `git diff --stat` ne liste pas les fichiers non trackés du rapport et de la capture.

Commande :

```bash
git diff --name-only
```

Sortie exacte :

```text
packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart
packages/map_editor/test/event_builder_workspace_test.dart
```

Commande :

```bash
git diff --check
```

Sortie exacte :

```text
<vide>
```

Commande anti-scope :

```bash
git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle packages/map_core examples assets selbrume pubspec.yaml
```

Sortie exacte :

```text
<vide>
```

Commande Visual Gate :

```bash
find reports/narrativeStudio/events/screenshots -maxdepth 1 -name '*ns_event_05*' -print
```

Sortie exacte :

```text
reports/narrativeStudio/events/screenshots/ns_event_05_readonly_details_diagnostics_v0.png
```
