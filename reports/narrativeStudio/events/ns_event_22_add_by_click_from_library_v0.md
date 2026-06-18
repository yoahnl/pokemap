# NS-EVENT-22 — Add-by-click From Library V0

## 1. Résumé exécutif

NS-EVENT-22 est DONE.

La bibliothèque d’éléments n’est plus seulement décorative : les items disponibles ouvrent maintenant le bloc compatible dans le builder central. Le lot reste borné à l’UI authoring existante.

Actions livrées :

- `Fact vrai / faux` ouvre le picker de Facts existant ;
- `Événement consommé` ouvre le picker d’événements existant ;
- `Jouer une scène` ouvre le picker de scènes existant ;
- `Interaction PNJ`, `Interaction objet`, `Entrée dans une zone` réutilisent l’opération déclencheur existante ;
- les items `À venir` affichent un message no-code sans mutation.

Aucun drag/drop, aucun runtime et aucune capacité métier nouvelle n’ont été ajoutés.

## 2. Décision d’implémentation

La bibliothèque émet une intention UI typée :

```dart
enum EventBuilderLibraryAction {
  triggerActor,
  triggerObject,
  triggerZone,
  conditionFact,
  conditionEventConsumed,
  actionScene,
}
```

Le workspace relaie cette intention au panneau détail sélectionné avec une `GlobalKey`, puis le panneau détail appelle les méthodes déjà existantes :

- `_startFactConditionChoice()`
- `_startEventConditionChoice()`
- `_startSceneChoice()`
- `_selectTriggerType(...)`

Cette décision évite de recréer un deuxième modèle d’édition ou une logique métier parallèle dans la bibliothèque.

## 3. Comportement ajouté

### Conditions Fact

Depuis la bibliothèque :

```text
Conditions -> Fact vrai / faux
```

ouvre :

```text
Facts disponibles
Départ accepté
Doit être vrai / Doit être faux
```

La sélection finale passe par l’opération déjà branchée dans le workspace.

### Conditions événement consommé

Depuis la bibliothèque :

```text
Conditions -> Événement consommé
```

ouvre :

```text
Événements disponibles
Déjà consommé / Pas encore consommé
```

L’auto-cible reste exclue par le code existant.

### Action scène

Depuis la bibliothèque :

```text
Actions -> Jouer une scène
```

ouvre le picker :

```text
Scènes disponibles
```

Le test renforcé sélectionne ensuite `Scène existante` et vérifie que `sceneTarget.sceneId == scene_existing`.

### Items futurs

Les items `À venir` affichent :

```text
Cet élément arrive dans un prochain lot.
```

et ne mutent pas l’event.

## 4. Fichiers modifiés

```text
packages/map_editor/lib/src/ui/canvas/events/event_builder_element_library.dart
packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart
packages/map_editor/test/event_builder_workspace_test.dart
```

## 5. Fichiers créés

```text
reports/narrativeStudio/events/ns_event_22_add_by_click_from_library_v0.md
reports/narrativeStudio/events/screenshots/ns_event_22_add_by_click_from_library_v0.png
```

## 6. Extraits complets des changements importants

### Action typée de bibliothèque

```dart
enum EventBuilderLibraryAction {
  triggerActor,
  triggerObject,
  triggerZone,
  conditionFact,
  conditionEventConsumed,
  actionScene,
}
```

### Activation d’un item

```dart
void _activateItem(_ElementLibraryItem item) {
  if (!item.available || item.action == null) {
    setState(() {
      _feedback = 'Cet élément arrive dans un prochain lot.';
    });
    return;
  }
  widget.onActivate?.call(item.action!);
  setState(() {
    _feedback = 'Bloc ouvert dans le builder.';
  });
}
```

### Relais workspace vers panneau détail

```dart
void _activateLibraryAction(EventBuilderLibraryAction action) {
  _eventDetailsKey.currentState?.activateLibraryAction(action);
}
```

### Dispatch dans le panneau détail

```dart
void activateLibraryAction(EventBuilderLibraryAction action) {
  final selected = widget.event;
  if (selected == null) {
    return;
  }
  switch (action) {
    case EventBuilderLibraryAction.triggerActor:
      _selectTriggerTypeFromLibrary(selected, MapEventType.actor);
      break;
    case EventBuilderLibraryAction.triggerObject:
      _selectTriggerTypeFromLibrary(selected, MapEventType.object);
      break;
    case EventBuilderLibraryAction.triggerZone:
      _selectTriggerTypeFromLibrary(selected, MapEventType.triggerZone);
      break;
    case EventBuilderLibraryAction.conditionFact:
      _startFactConditionChoiceFromLibrary(selected);
      break;
    case EventBuilderLibraryAction.conditionEventConsumed:
      _startEventConditionChoiceFromLibrary(selected);
      break;
    case EventBuilderLibraryAction.actionScene:
      _startSceneChoiceFromLibrary();
      break;
  }
}
```

## 7. Tests ajoutés/modifiés

Tests NS-EVENT-22 :

```text
NS-EVENT-22 clicking Fact condition library item opens fact choice
NS-EVENT-22 clicking Event condition library item opens event choice
NS-EVENT-22 clicking Scene action library item focuses scene action
NS-EVENT-22 unsupported library item shows not available message
captures NS-EVENT-22 add-by-click library visual gate
```

Le test Scene a été renforcé après auto-review subagent : il ne vérifie plus seulement l’ouverture du picker, il sélectionne aussi la scène et vérifie la mutation `sceneTarget`.

## 8. Visual Gate

Capture :

```text
reports/narrativeStudio/events/screenshots/ns_event_22_add_by_click_from_library_v0.png
```

Propriétés :

```text
PNG image data, 1440 x 1100, 8-bit/color RGBA, non-interlaced
sha256: 1578e4798c14e840ee38ef39c36c8f35607aabd3480e200aec9bf7ad1c2c1be8
```

La capture montre :

- bibliothèque visible ;
- feedback `Bloc ouvert dans le builder.` ;
- picker Fact ouvert dans le bloc Conditions ;
- builder central et inspecteur visibles ;
- aucun drag/drop.

## 9. Validations exécutées

### RED

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact test/event_builder_workspace_test.dart --name "NS-EVENT-22"
```

Sorties rouges utiles :

```text
Expected: exactly one matching candidate
Actual: Found 0 widgets with text "Facts disponibles"

Expected: exactly one matching candidate
Actual: Found 0 widgets with text "Événements disponibles"

Expected: exactly one matching candidate
Actual: Found 0 widgets with text "Scènes disponibles"

Expected: exactly one matching candidate
Actual: Found 0 widgets with text "Cet élément arrive dans un prochain lot."
```

### GREEN ciblé

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact test/event_builder_workspace_test.dart --name "NS-EVENT-21|NS-EVENT-22"
```

Résultat :

```text
00:04 +10: All tests passed!
```

### Suite complète Event Builder workspace

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact test/event_builder_workspace_test.dart
```

Résultat :

```text
00:08 +69: All tests passed!
```

### Analyse ciblée

Commande :

```bash
cd packages/map_editor
flutter analyze --no-fatal-infos \
  lib/src/ui/canvas/events/event_builder_workspace.dart \
  lib/src/ui/canvas/events/event_builder_central_flow.dart \
  lib/src/ui/canvas/events/event_builder_flow_blocks.dart \
  lib/src/ui/canvas/events/event_builder_creation_panel.dart \
  lib/src/ui/canvas/events/event_builder_inspector_panel.dart \
  lib/src/ui/canvas/events/event_builder_element_library.dart \
  test/event_builder_workspace_test.dart
```

Résultat :

```text
Analyzing 7 items...
No issues found! (ran in 1.9s)
```

### Build macOS debug

Commande :

```bash
cd packages/map_editor
flutter build macos --debug
```

Résultat :

```text
✓ Built build/macos/Build/Products/Debug/map_editor.app
```

## 10. Auto-review subagent

Verdict subagent : GO avec une réserve mineure.

Constats :

- les clics bibliothèque passent par `onActivate`, puis par le panneau détail ;
- les items `À venir` retournent après le message no-code ;
- pas de drag/drop ;
- pas de diff `map_core`, runtime, gameplay, battle, examples, assets, Selbrume ou `pubspec.yaml` ;
- design system respecté ;
- tests présents pour Fact, Event consumed, Scene action et unsupported.

Réserve :

```text
Le test Scene action vérifie l’ouverture du picker, mais pas la sélection finale.
```

Action prise :

```text
Le test NS-EVENT-22 Scene action sélectionne maintenant `scene_existing` et vérifie `sceneTarget.sceneId`.
```

## 11. Non-objectifs respectés

Confirmé :

- pas de drag/drop ;
- pas de outcomes ;
- pas de réactions riches ;
- pas de battle authoring ;
- pas de world rules inline ;
- pas de runtime ;
- pas de `map_core` ;
- pas de Selbrume ;
- pas de nouveau modèle métier.

## 12. Gate final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie :

```text
 M packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart
 M packages/map_editor/test/event_builder_workspace_test.dart
?? packages/map_editor/lib/src/ui/canvas/events/event_builder_central_flow.dart
?? packages/map_editor/lib/src/ui/canvas/events/event_builder_creation_panel.dart
?? packages/map_editor/lib/src/ui/canvas/events/event_builder_element_library.dart
?? packages/map_editor/lib/src/ui/canvas/events/event_builder_flow_blocks.dart
?? packages/map_editor/lib/src/ui/canvas/events/event_builder_inspector_panel.dart
?? reports/narrativeStudio/events/ns_event_17_target_layout_alignment_plan.md
?? reports/narrativeStudio/events/ns_event_18_creation_panel_compact_collapsible_v0.md
?? reports/narrativeStudio/events/ns_event_19_event_builder_central_blocks_layout_v0.md
?? reports/narrativeStudio/events/ns_event_20_event_inspector_split_v0.md
?? reports/narrativeStudio/events/ns_event_21_element_library_readonly_v0.md
?? reports/narrativeStudio/events/ns_event_v1_drag_drop_detailed_lot_plan.md
?? reports/narrativeStudio/events/screenshots/ns_event_18_creation_panel_compact_collapsible_v0.png
?? reports/narrativeStudio/events/screenshots/ns_event_19_event_builder_central_blocks_layout_v0.png
?? reports/narrativeStudio/events/screenshots/ns_event_20_event_inspector_split_v0.png
?? reports/narrativeStudio/events/screenshots/ns_event_21_element_library_readonly_v0.png
?? reports/narrativeStudio/events/screenshots/ns_event_22_add_by_click_from_library_v0.png
```

Commande :

```bash
git diff --stat
```

Sortie :

```text
 .../ui/canvas/events/event_builder_workspace.dart  |  709 +++++------
 .../test/event_builder_workspace_test.dart         | 1239 +++++++++++++++++---
 2 files changed, 1454 insertions(+), 494 deletions(-)
```

Commande :

```bash
git diff --name-only
```

Sortie :

```text
packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart
packages/map_editor/test/event_builder_workspace_test.dart
```

Commande :

```bash
git diff --check
```

Sortie :

```text

```

Commande anti-scope :

```bash
git diff --name-only -- packages/map_core packages/map_runtime packages/map_gameplay packages/map_battle examples assets selbrume pubspec.yaml
```

Sortie :

```text

```

## 13. Impact sur NS-EVENT-23

NS-EVENT-23 peut se concentrer sur le polish des blocs Actions/Conditions :

- améliorer l’ancrage visuel des zones ouvertes par la bibliothèque ;
- mieux distinguer item ouvert, picker ouvert et état déjà configuré ;
- préparer les futurs slots sans activer le drag/drop.

NS-EVENT-23 ne doit pas démarrer le drag/drop.

## 14. Auto-critique finale

Ce lot fait avancer l’UI cible : la bibliothèque est maintenant utile par clic, ce qui évite d’attendre le drag/drop pour la rendre fonctionnelle.

Points solides :

- TDD respecté avec RED explicite ;
- tests verts après renforcement subagent ;
- aucune couche métier parallèle ;
- aucun runtime ;
- design system utilisé.

Limite assumée :

- le feedback bibliothèque est global au panneau, pas encore un état sélectionné par item. C’est suffisant pour V0, mais NS-EVENT-23 pourra rendre l’état actif plus lisible dans le bloc ouvert.
