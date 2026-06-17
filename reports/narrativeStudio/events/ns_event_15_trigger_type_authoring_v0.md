# NS-EVENT-15 — Event Builder Trigger Type Authoring V0

## 1. Résumé exécutif

NS-EVENT-15 est implémenté.

Le workspace Événements permet maintenant de modifier le type métier du déclencheur d'un événement via des labels no-code :

- `Interaction avec un PNJ` -> `MapEventType.actor`
- `Interaction avec un objet` -> `MapEventType.object`
- `Entrée dans une zone` -> `MapEventType.triggerZone`

Le type `MapEventType.effect` reste hors MVP et n'est pas exposé comme choix éditable. Si un événement existant utilise ce type, l'UI affiche un état lecture seule compréhensible.

La mutation ne touche que `MapEventDefinition.type`. Les pages, conditions, `sceneTarget`, `script`, `message`, metadata, position, titre, id et sélection restent préservés.

## 2. Décision types authorables MVP

Types authorables retenus :

| Type core | Label UI | Décision |
|---|---|---|
| `MapEventType.actor` | Interaction avec un PNJ | Authorable MVP |
| `MapEventType.object` | Interaction avec un objet | Authorable MVP |
| `MapEventType.triggerZone` | Entrée dans une zone | Authorable MVP |
| `MapEventType.effect` | Interaction / effet | Lecture seule, hors MVP |

Justification : `effect` mélange une intention d'effet/interaction avancée avec la grammaire no-code d'un déclencheur. Le lot garde donc le MVP sur les trois types lisibles par un créateur.

## 3. Opération notifier ajoutée

Fichier : `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`

Opération ajoutée :

```dart
bool updateEventBuilderTriggerType({
  required String eventId,
  required MapEventType type,
}) {
  final map = state.activeMap;
  if (map == null) {
    state = state.copyWith(
      errorMessage: 'Aucune map active pour modifier le déclencheur.',
    );
    return false;
  }
  // NS-EVENT-15 exposes only the MVP trigger grammar. MapEventType.effect is
  // intentionally kept out of authoring because it mixes visual/effect intent
  // with event launch semantics for no-code users.
  if (!_isEventBuilderAuthorableTriggerType(type)) {
    state = state.copyWith(
      errorMessage: 'Ce type de déclencheur n’est pas éditable dans ce lot.',
    );
    return false;
  }
  final event = findMapEventById(map, eventId);
  if (event == null) {
    state = state.copyWith(errorMessage: 'Événement introuvable : $eventId');
    return false;
  }
  if (event.type == type) {
    return true;
  }

  try {
    final updated = updateMapEventOnMap(
      map,
      eventId: eventId,
      type: type,
    );
    MapValidator.validate(
      updated,
      projectDialogueContext: state.project,
    );
    _applyMapMutation(
      previousMap: map,
      updatedMap: updated,
      preferredActiveLayerId: state.activeLayerId,
      preferredSelectedMapEventId: eventId,
      statusMessage: 'Déclencheur d’événement mis à jour',
    );
    return true;
  } catch (e) {
    state = state.copyWith(
      errorMessage: 'Impossible de modifier le déclencheur : $e',
    );
    return false;
  }
}
```

Helper ajouté :

```dart
bool _isEventBuilderAuthorableTriggerType(MapEventType type) {
  return switch (type) {
    MapEventType.actor ||
    MapEventType.object ||
    MapEventType.triggerZone =>
      true,
    MapEventType.effect => false,
  };
}
```

## 4. UI Déclencheur ajoutée

Fichier : `packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart`

Le widget reçoit maintenant :

```dart
typedef EventBuilderTriggerTypeUpdateCallback = bool Function({
  required String eventId,
  required MapEventType type,
});
```

Le bloc `Déclencheur` affiche toujours le type et la source, puis ajoute trois boutons bornés si le type courant est authorable :

```dart
_TriggerTypeButton(
  key: const ValueKey('event-builder-trigger-actor-button'),
  label: 'Interaction avec un PNJ',
  icon: CupertinoIcons.person_crop_circle,
  type: MapEventType.actor,
  currentType: currentType,
  onSelect: (type) => _selectTriggerType(selected, type),
),
_TriggerTypeButton(
  key: const ValueKey('event-builder-trigger-object-button'),
  label: 'Interaction avec un objet',
  icon: CupertinoIcons.cube_box,
  type: MapEventType.object,
  currentType: currentType,
  onSelect: (type) => _selectTriggerType(selected, type),
),
_TriggerTypeButton(
  key: const ValueKey('event-builder-trigger-zone-button'),
  label: 'Entrée dans une zone',
  icon: CupertinoIcons.square_grid_2x2,
  type: MapEventType.triggerZone,
  currentType: currentType,
  onSelect: (type) => _selectTriggerType(selected, type),
),
```

Le type `effect` reste lisible mais non éditable :

```dart
const _DiagnosticNotice(
  title: 'Déclencheur en lecture seule',
  message: 'Ce type de déclencheur n’est pas éditable dans ce lot.',
  tone: PokeMapTone.warning,
  severityLabel: 'Action indisponible',
  details: ['Types MVP : PNJ, objet, zone'],
),
```

Le wiring product passe par `NarrativeWorkspaceCanvas` :

```dart
onUpdateTriggerType: editorNotifier.updateEventBuilderTriggerType,
```

## 5. Labels no-code

Labels visibles :

- `Interaction avec un PNJ`
- `Interaction avec un objet`
- `Entrée dans une zone`

Labels non exposés comme workflow principal :

- `actor`
- `object`
- `triggerZone`
- `effect`
- `MapEventType`

Le rapport note une adaptation : le workspace contient déjà des contrôles de conditions ajoutés par NS-EVENT-13/14. L'interdiction "aucun bouton condition" est interprétée strictement comme "ne pas ajouter de nouveaux contrôles condition/outcome/world rules/flow editor dans ce lot". Les contrôles existants des lots précédents restent en place.

## 6. Préservation des champs existants

La mutation utilise `updateMapEventOnMap(...)` avec uniquement `type`.

Tests de préservation ajoutés pour :

- `event.id`
- `event.title`
- `event.position`
- `event.metadata`
- `event.pages`
- `page.condition`
- `page.sceneTarget`
- `page.script`
- `page.message`
- `page.metadata`
- `selectedMapEventId`

`MapEventType.effect` est refusé sans mutation.

## 7. Tests ajoutés/modifiés

Fichier : `packages/map_editor/test/event_builder_draft_creation_notifier_test.dart`

Tests ajoutés :

- `NS-EVENT-15 EditorNotifier trigger type authoring updates actor object and triggerZone while preserving event fields`
- `NS-EVENT-15 EditorNotifier trigger type authoring rejects effect and unknown events without mutating the map`

Fichier : `packages/map_editor/test/event_builder_workspace_test.dart`

Tests ajoutés :

- `NS-EVENT-15 edits trigger type with no-code labels`
- `NS-EVENT-15 keeps effect trigger type read-only`
- `captures NS-EVENT-15 trigger type authoring visual gate`

Harness ajusté :

```dart
Future<ProviderContainer> _pumpNarrativeEventsShell(
  WidgetTester tester, {
  String? fontFamily,
  MapData? activeMap,
  Size surfaceSize = const Size(1440, 900),
}) async {
  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));
```

La hauteur spéciale `1440 x 1100` est utilisée seulement par la capture NS-EVENT-15 pour montrer le déclencheur, le feedback, les conditions et l'action principale.

## 8. Visual Gate

Capture générée :

```text
reports/narrativeStudio/events/screenshots/ns_event_15_trigger_type_authoring_v0.png
```

Commande :

```bash
cd packages/map_editor
flutter test --no-pub --update-goldens --reporter=compact test/event_builder_workspace_test.dart --name "captures NS-EVENT-15" --dart-define=NS_EVENT_15_CAPTURE_WORKSPACE=true
```

Sortie :

```text
00:03 +0: captures NS-EVENT-15 trigger type authoring visual gate
00:04 +1: captures NS-EVENT-15 trigger type authoring visual gate
00:04 +1: All tests passed!
```

Métadonnées :

```text
reports/narrativeStudio/events/screenshots/ns_event_15_trigger_type_authoring_v0.png: PNG image data, 1440 x 1100, 8-bit/color RGBA, non-interlaced
d95ac11d22722e0a59dfa0cb3fa75e3bffb12a55a6bc22a5980a60fe255b887d  reports/narrativeStudio/events/screenshots/ns_event_15_trigger_type_authoring_v0.png
pixelWidth: 1440
pixelHeight: 1100
```

## 9. Validations exécutées

### RED initial

Tests écrits avant implémentation.

Commande notifier ciblée :

```bash
cd packages/map_editor
flutter test --no-pub --reporter=compact test/event_builder_draft_creation_notifier_test.dart --name "NS-EVENT-15"
```

Signal RED observé :

```text
The method 'updateEventBuilderTriggerType' isn't defined
```

Commande workspace ciblée :

```bash
cd packages/map_editor
flutter test --no-pub --reporter=compact test/event_builder_workspace_test.dart --name "NS-EVENT-15"
```

Signal RED observé :

```text
No named parameter with the name 'onUpdateTriggerType'
```

### GREEN ciblé

Commande :

```bash
cd packages/map_editor
flutter test --no-pub --reporter=compact test/event_builder_draft_creation_notifier_test.dart --name "NS-EVENT-15"
```

Sortie :

```text
00:02 +2: All tests passed!
```

Commande :

```bash
cd packages/map_editor
flutter test --no-pub --reporter=compact test/event_builder_workspace_test.dart --name "NS-EVENT-15"
```

Sortie :

```text
00:06 +3: All tests passed!
```

### Régressions map_editor

Commande :

```bash
cd packages/map_editor
flutter test --no-pub --reporter=compact test/event_builder_workspace_test.dart
```

Sortie :

```text
00:07 +41: All tests passed!
```

Commande :

```bash
cd packages/map_editor
flutter test --no-pub --reporter=compact test/event_builder_draft_creation_notifier_test.dart
```

Sortie :

```text
00:02 +27: All tests passed!
```

Note : un premier lancement parallèle de commandes Flutter a produit un faux rouge de native asset :

```text
Failed to code sign binary: exit code: 1  /Users/karim/Project/pokemonProject/packages/map_editor/build/native_assets/macos/objective_c.dylib: No such file or directory
```

La suite a été relancée séquentiellement et est passée.

### Régressions map_core Event Builder

Commande :

```bash
cd packages/map_core
dart test --reporter=compact test/event_builder_contract_test.dart test/event_builder_authoring_operations_test.dart test/event_builder_read_model_test.dart test/event_builder_draft_creation_operations_test.dart
```

Sortie :

```text
00:00 +40: All tests passed!
```

### Analyse ciblée

Commande :

```bash
cd packages/map_editor
flutter analyze --no-pub --no-fatal-infos lib/src/features/editor/state/editor_notifier.dart lib/src/ui/canvas/events/event_builder_workspace.dart lib/src/ui/canvas/narrative_workspace_canvas.dart test/event_builder_workspace_test.dart test/event_builder_draft_creation_notifier_test.dart
```

Sortie :

```text
Analyzing 5 items...
No issues found! (ran in 3.9s)
```

### Build macOS debug

Commande :

```bash
cd packages/map_editor
flutter build macos --debug --no-pub
```

Sortie :

```text
Building macOS application...
✓ Built build/macos/Build/Products/Debug/map_editor.app
```

## 10. Non-objectifs respectés

Non-objectifs confirmés :

- pas d'édition position ;
- pas d'édition couche ;
- pas d'édition taille de zone ;
- pas d'édition sprite ;
- pas d'édition NPC target ;
- pas d'édition Scene action ;
- pas d'édition titre ;
- pas d'édition behavior ;
- pas de nouvelle édition conditions ;
- pas d'outcomes ;
- pas de réactions ;
- pas de World Rules ;
- pas de flow editor ;
- pas de drag/drop ;
- pas de modification `map_runtime` ;
- pas de modification `map_gameplay` ;
- pas de modification `map_battle` ;
- pas de modification `map_core` ;
- pas de modification Selbrume ;
- pas de modification `project.json` ;
- pas de generated files ;
- pas de commit.

## 11. Impact sur NS-EVENT-16

NS-EVENT-16 peut partir d'un bloc `Déclencheur` authorable pour le type métier, mais il devra rester prudent sur les sous-surfaces non traitées :

- target PNJ/objet non authorée ;
- géométrie/zone size non authorée ;
- position/layer déjà traités par les lots précédents mais non réouverts ici ;
- `effect` toujours hors MVP.

Le prochain lot peut donc cibler soit le choix de source/cible du déclencheur, soit une fermeture/polish du bloc Déclencheur avant d'ouvrir une nouvelle sous-surface.

## 12. Limites restantes

- L'UI mappe le type courant depuis le label du read model pour éviter une modification `map_core` dans ce lot editor-only. C'est acceptable pour NS-EVENT-15, mais un futur lot pourrait exposer un champ typé dans `EventBuilderReadModel` si plusieurs surfaces ont besoin de l'identité `MapEventType`.
- Les contrôles de conditions existants restent visibles, car ils appartiennent à NS-EVENT-13/14. NS-EVENT-15 n'en ajoute aucun.
- `effect` reste lisible en legacy, mais non authorable.

## 13. Evidence Pack complet

### Règles lues

Fichiers lus avant modification :

- `AGENTS.md`
- `agent_rules.md`
- `codex_rule.md`
- `skills/README.md`
- `skills/using-superpowers/SKILL.md`
- `skills/test-driven-development/SKILL.md`
- `skills/verification-before-completion/SKILL.md`

### Gate 0

Commande :

```bash
pwd && git branch --show-current && git status --short --untracked-files=all && git diff --stat && git diff --name-only && git log --oneline -n 20
```

Sortie :

```text
/Users/karim/Project/pokemonProject
main
```

`git status --short --untracked-files=all`, `git diff --stat` et `git diff --name-only` étaient vides au Gate 0.

Log :

```text
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
410be446 FG-NS-EVENT-001: Alignement des contrats existants pour le builder d'événements
7b3b2151 FG-NS-EVENT-001: Ajout du plan MVP v1 pour le builder d'événements Narrative Studio
05e70a57 NS-STUDIO-PRODUCT-BETA-READINESS — Audit de préparation pour la bêta de Narrative Studio
da9cce15 NS-SCENES-V1-138 — Selbrume Golden Slice Content Inventory Asset Gap Audit
80dd997a NS-SCENES-V1-137 — Narrative Studio Golden Slice Authoring Readiness Selbrume Demo Content Plan
```

### Audit préalable

Fichiers audités :

- `packages/map_core/lib/src/models/map_event_definition.dart`
- `packages/map_core/lib/src/operations/map_events.dart`
- `packages/map_core/lib/src/read_models/event_builder_read_model.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`
- `packages/map_editor/test/event_builder_workspace_test.dart`
- `packages/map_editor/test/event_builder_draft_creation_notifier_test.dart`

Réponses d'audit :

- Le déclencheur est actuellement affiché par `EventBuilderReadModel.trigger.label` et `trigger.sourceLabel`.
- `MapEventType` contient `actor`, `object`, `triggerZone`, `effect`.
- Les types MVP authorables sont `actor`, `object`, `triggerZone`.
- `effect` n'est pas exposé car son label `Interaction / effet` reste ambigu pour un workflow no-code.
- `updateMapEventOnMap(...)` permet de modifier uniquement `type`.
- `selectedMapEventId` est préservé via `_applyMapMutation(... preferredSelectedMapEventId: eventId)`.

### Fichiers modifiés

```text
packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/test/event_builder_draft_creation_notifier_test.dart
packages/map_editor/test/event_builder_workspace_test.dart
```

### Fichiers créés

```text
reports/narrativeStudio/events/ns_event_15_trigger_type_authoring_v0.md
reports/narrativeStudio/events/screenshots/ns_event_15_trigger_type_authoring_v0.png
```

Le contenu complet du rapport est le présent document.

### Fichiers supprimés

```text
<aucun>
```

### Diff stat avant rapport

```text
.../src/features/editor/state/editor_notifier.dart |  65 +++++++++
.../ui/canvas/events/event_builder_workspace.dart  | 157 ++++++++++++++++++++-
.../src/ui/canvas/narrative_workspace_canvas.dart  |   1 +
...event_builder_draft_creation_notifier_test.dart | 133 +++++++++++++++++
.../test/event_builder_workspace_test.dart         | 155 +++++++++++++++++++-
5 files changed, 507 insertions(+), 4 deletions(-)
```

### Hunk notifier principal

```diff
+  bool updateEventBuilderTriggerType({
+    required String eventId,
+    required MapEventType type,
+  }) {
+    final map = state.activeMap;
+    if (map == null) {
+      state = state.copyWith(
+        errorMessage: 'Aucune map active pour modifier le déclencheur.',
+      );
+      return false;
+    }
+    if (!_isEventBuilderAuthorableTriggerType(type)) {
+      state = state.copyWith(
+        errorMessage: 'Ce type de déclencheur n’est pas éditable dans ce lot.',
+      );
+      return false;
+    }
+    final event = findMapEventById(map, eventId);
+    if (event == null) {
+      state = state.copyWith(errorMessage: 'Événement introuvable : $eventId');
+      return false;
+    }
+    if (event.type == type) {
+      return true;
+    }
+
+    try {
+      final updated = updateMapEventOnMap(
+        map,
+        eventId: eventId,
+        type: type,
+      );
+      MapValidator.validate(
+        updated,
+        projectDialogueContext: state.project,
+      );
+      _applyMapMutation(
+        previousMap: map,
+        updatedMap: updated,
+        preferredActiveLayerId: state.activeLayerId,
+        preferredSelectedMapEventId: eventId,
+        statusMessage: 'Déclencheur d’événement mis à jour',
+      );
+      return true;
+    } catch (e) {
+      state = state.copyWith(
+        errorMessage: 'Impossible de modifier le déclencheur : $e',
+      );
+      return false;
+    }
+  }
```

### Hunk UI principal

```diff
+              _TriggerTypeButton(
+                key: const ValueKey('event-builder-trigger-actor-button'),
+                label: 'Interaction avec un PNJ',
+                icon: CupertinoIcons.person_crop_circle,
+                type: MapEventType.actor,
+                currentType: currentType,
+                onSelect: (type) => _selectTriggerType(selected, type),
+              ),
+              _TriggerTypeButton(
+                key: const ValueKey('event-builder-trigger-object-button'),
+                label: 'Interaction avec un objet',
+                icon: CupertinoIcons.cube_box,
+                type: MapEventType.object,
+                currentType: currentType,
+                onSelect: (type) => _selectTriggerType(selected, type),
+              ),
+              _TriggerTypeButton(
+                key: const ValueKey('event-builder-trigger-zone-button'),
+                label: 'Entrée dans une zone',
+                icon: CupertinoIcons.square_grid_2x2,
+                type: MapEventType.triggerZone,
+                currentType: currentType,
+                onSelect: (type) => _selectTriggerType(selected, type),
+              ),
```

### Hunk test principal

```diff
+  testWidgets('NS-EVENT-15 edits trigger type with no-code labels',
+      (tester) async {
+    final container = await _pumpNarrativeEventsShell(tester);
+    expect(find.text('Interaction avec un PNJ'), findsWidgets);
+    await tester.tap(
+      find.byKey(const ValueKey('event-builder-trigger-object-button')),
+    );
+    await tester.pumpAndSettle();
+    var state = container.read(editorNotifierProvider);
+    var event = state.activeMap!.events.single;
+    expect(event.type, MapEventType.object);
+    expect(event.id, 'evt_existing');
+    expect(event.title, 'Événement existant');
+    expect(event.pages.single.sceneTarget?.sceneId, 'scene_existing');
+    expect(state.selectedMapEventId, 'evt_existing');
+    expect(state.statusMessage, 'Déclencheur d’événement mis à jour');
+  });
```

### Git diff check intermédiaire

Commande :

```bash
git diff --check
```

Sortie :

```text
<vide>
```

### Anti-scope intermédiaire

Commande :

```bash
git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle packages/map_core examples assets selbrume pubspec.yaml
```

Sortie attendue au final :

```text
<vide>
```

### Gate final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie :

```text
 M packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
 M packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
 M packages/map_editor/test/event_builder_draft_creation_notifier_test.dart
 M packages/map_editor/test/event_builder_workspace_test.dart
?? reports/narrativeStudio/events/ns_event_15_trigger_type_authoring_v0.md
?? reports/narrativeStudio/events/screenshots/ns_event_15_trigger_type_authoring_v0.png
```

Commande :

```bash
git diff --stat
```

Sortie :

```text
.../src/features/editor/state/editor_notifier.dart |  65 +++++++++
.../ui/canvas/events/event_builder_workspace.dart  | 157 ++++++++++++++++++++-
.../src/ui/canvas/narrative_workspace_canvas.dart  |   1 +
...event_builder_draft_creation_notifier_test.dart | 133 +++++++++++++++++
.../test/event_builder_workspace_test.dart         | 155 +++++++++++++++++++-
5 files changed, 507 insertions(+), 4 deletions(-)
```

Note : `git diff --stat` ne liste pas les fichiers untracked. Ils sont visibles dans `git status --short --untracked-files=all`.

Commande :

```bash
git diff --name-only
```

Sortie :

```text
packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/test/event_builder_draft_creation_notifier_test.dart
packages/map_editor/test/event_builder_workspace_test.dart
```

Commande :

```bash
git diff --check
```

Sortie :

```text
<vide>
```

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
find reports/narrativeStudio/events/screenshots -maxdepth 1 -name '*ns_event_15*' -print
find reports/narrativeStudio/events/screenshots -maxdepth 1 -name '*ns_event_16*' -print
```

Sortie :

```text
reports/narrativeStudio/events/screenshots/ns_event_15_trigger_type_authoring_v0.png
```

La seconde commande ne retourne aucune ligne.

## 14. Auto-review critique

Passes indépendantes :

| Passe | Verdict | Note |
|---|---|---|
| Audit modèle | OK | `MapEventDefinition.type` est le bon champ. Pas de changement core requis. |
| Scope UI | OK | Le lot ajoute seulement le choix de type déclencheur. |
| Préservation | OK | Tests couvrent id, titre, position, metadata, pages et contenu de page. |
| Type `effect` | OK | Refusé côté notifier et non éditable côté UI. |
| Tests | OK | Suites ciblées map_editor et map_core vertes. |
| Visual Gate | OK | Capture produite en 1440 x 1100. |
| Anti-scope | OK à confirmer en gate final | Aucun fichier runtime/core/Selbrume modifié avant rapport. |

Critique :

- Le read model ne donne pas encore directement un `MapEventType` typé au widget. L'UI fait donc une petite correspondance label -> type pour rester editor-only. C'est acceptable pour ce lot, mais ce serait fragile si les labels étaient localisés ou reformulés plus largement.
- Le prompt demande qu'aucun bouton condition ne soit ajouté. Les boutons de conditions déjà livrés par NS-EVENT-13/14 restent visibles. Le lot n'en ajoute aucun ; le rapport le documente explicitement.
- Le commentaire ajouté dans `EditorNotifier` explique pourquoi `effect` est exclu. Il est utile mais pourrait être retiré si l'équipe veut une règle stricte "zéro commentaire" sur les prochains lots.

Verdict final attendu après gate :

```text
NS-EVENT-15 — DONE
```
