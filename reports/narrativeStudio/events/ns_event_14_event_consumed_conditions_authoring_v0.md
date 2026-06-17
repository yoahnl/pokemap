# NS-EVENT-14 — Event Builder Event Consumed Conditions Authoring V0

## 1. Résumé exécutif

NS-EVENT-14 est implémenté côté `map_editor` uniquement.

Le workspace Événements permet maintenant d'ajouter et retirer des conditions no-code basées sur l'état de consommation d'un autre événement de la map :

- `Événement "<label>" déjà consommé`
- `Événement "<label>" pas encore consommé`

Le lot reste borné :

- pas d'édition de trigger ;
- pas d'édition de Scene action ;
- pas d'édition de behavior ;
- pas d'outcomes, réactions, World Rules, Story Step, flow editor ou drag/drop ;
- pas de modification `map_core` ;
- pas de runtime/gameplay/battle/Selbrume.

Verdict : **NS-EVENT-14 DONE**.

## 2. Décision page cible

La page authorable ciblée reste la page au plus petit `pageNumber`.

Justification :

- c'est la règle déjà appliquée par NS-EVENT-11/12/13 ;
- `readEventBuilderContractFromMapEvent(...)` accepte ce `pageNumber` ;
- les drafts créés par NS-EVENT-06 utilisent `pageNumber = 0` ;
- les anciens events peuvent avoir des pages non ordonnées.

L'opération refuse proprement un event sans page avec :

```text
Cet événement ne contient aucune page authorable.
```

## 3. Décision auto-cible

Décision V0 : l'événement courant est exclu de la liste des cibles et refusé côté notifier.

Justification :

- une condition "cet événement est déjà consommé" sur l'événement lui-même est techniquement possible mais trop ambiguë pour le premier workflow no-code ;
- l'utilisateur doit sélectionner un **autre** événement de la map ;
- le garde-fou existe à la fois en UI et en state.

Message si appel direct invalide :

```text
Un événement ne peut pas se cibler lui-même dans ce lot.
```

## 4. Opérations notifier ajoutées/modifiées

Fichier : `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`

### Ajout

```dart
bool addEventBuilderEventConsumedCondition({
  required String eventId,
  required String targetEventId,
  required bool expectedConsumed,
})
```

Comportement :

- vérifie la map active ;
- vérifie l'event source ;
- vérifie la présence d'une page ;
- cible la page au plus petit `pageNumber` ;
- lit le contrat Event Builder ;
- bloque si `legacyConditionToPreserve != null` ;
- trim `targetEventId` ;
- refuse `targetEventId` vide ;
- refuse l'auto-cible ;
- vérifie que l'event cible existe dans la map active ;
- ajoute `EventBuilderConditionBinding.eventConsumed(...)` ou `eventNotConsumed(...)` ;
- compile via le chemin Event Builder existant ;
- écrit uniquement `MapEventPage.condition` via `_updateEventBuilderPageCondition(...)` ;
- préserve `sceneTarget`, `script`, `message`, `metadata`, identité et sélection ;
- pose `statusMessage: Condition d’événement ajoutée`.

### Modification

`removeEventBuilderConditionAt(...)` accepte maintenant le retrait des kinds :

```text
factIsTrue
factIsFalse
eventConsumed
eventNotConsumed
```

Les kinds `storyStepCompleted` et `storyStepNotCompleted` restent non éditables dans ce lot.

### Extrait critique

```dart
final pageNumber = _eventBuilderAuthorablePageNumber(event);
final contract = readEventBuilderContractFromMapEvent(
  event,
  pageNumber: pageNumber,
);
if (contract.legacyConditionToPreserve != null) {
  state = state.copyWith(errorMessage: _eventBuilderConditionLockedMessage);
  return false;
}

final trimmedTargetEventId = targetEventId.trim();
if (trimmedTargetEventId.isEmpty) {
  state = state.copyWith(errorMessage: 'Événement cible obligatoire.');
  return false;
}
if (trimmedTargetEventId == eventId) {
  state = state.copyWith(
    errorMessage:
        'Un événement ne peut pas se cibler lui-même dans ce lot.',
  );
  return false;
}
```

## 5. UI Event consumed conditions ajoutée

Fichier : `packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart`

Ajouts principaux :

- `EventBuilderConditionEventOption`
- `EventBuilderEventConsumedConditionAddCallback`
- bouton `Ajouter une condition d’événement`
- section `Événements disponibles`
- boutons `Déjà consommé` / `Pas encore consommé`
- message no-code si aucune cible disponible
- retrait autorisé pour conditions Fact et Event consumed supportées

Les boutons restent dans la section `Conditions`. Aucun bouton de trigger/outcome/world rules/flow editor n'est ajouté.

Extrait UI :

```dart
PokeMapButton(
  key: const ValueKey(
    'event-builder-add-event-condition-button',
  ),
  onPressed: () => _startEventConditionChoice(),
  variant: PokeMapButtonVariant.secondary,
  size: PokeMapButtonSize.small,
  leading: const Icon(CupertinoIcons.link_circle),
  child: const Text('Ajouter une condition d’événement'),
)
```

Message empty-state :

```text
Aucun autre événement disponible.
Créez d’abord un autre événement sur cette map pour ajouter cette condition.
```

## 6. Options Event / labels

Fichier : `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`

Les options d'événement sont construites depuis `activeMap.events`.

Règle de label :

```text
event.title.trim() si non vide, sinon event.id
```

Extrait :

```dart
List<EventBuilderConditionEventOption> _buildEventBuilderConditionEventOptions(
  MapData? map,
) {
  return [
    for (final event in map?.events ?? const <MapEventDefinition>[])
      EventBuilderConditionEventOption(
        id: event.id,
        label: event.title.trim().isEmpty ? event.id : event.title.trim(),
      ),
  ];
}
```

L'exclusion de l'event courant est faite dans `EventBuilderWorkspace`, afin que la liste reçue reste une projection simple de la map active.

## 7. Gestion `legacyConditionToPreserve`

Le lot respecte le verrouillage introduit par NS-EVENT-02-bis et exposé par NS-EVENT-03 :

- si `legacyConditionToPreserve != null`, l'ajout est refusé ;
- le retrait est refusé ;
- l'UI n'affiche pas les boutons add/remove ;
- la condition legacy avancée reste intacte.

Message state conservé :

```text
Cette condition contient une partie avancée préservée. Elle ne peut pas être éditée partiellement.
```

## 8. Compilation `ScriptCondition`

La compilation reste entièrement côté contrat Event Builder existant :

- `eventConsumed(id)` compile vers `ScriptConditionFactory.eventIsConsumed(id)` ;
- `eventNotConsumed(id)` compile vers `ScriptConditionFactory.not(ScriptConditionFactory.eventIsConsumed(id))` ;
- plusieurs conditions compilent en `ScriptConditionFactory.allOf(...)` ;
- retirer la dernière condition remet `MapEventPage.condition` à `null`.

Aucun modèle core n'a été ajouté.

## 9. Préservation des champs existants

Tests et implémentation vérifient la préservation de :

- `event.id`
- `event.title`
- `event.position`
- `event.type`
- `event.metadata`
- `page.sceneTarget`
- `page.script`
- `page.message`
- `page.metadata`
- `selectedMapEventId`

Le helper `_updateEventBuilderPageCondition(...)` utilise volontairement `updatePageOnMapEvent(...)` pour ne toucher que `MapEventPage.condition`.

## 10. Tests ajoutés/modifiés

### State / notifier

Fichier : `packages/map_editor/test/event_builder_draft_creation_notifier_test.dart`

Groupe ajouté :

```text
NS-EVENT-14 EditorNotifier event consumed condition authoring
```

Tests :

- ajoute une condition Event consumed sans changer les autres champs ;
- ajoute Event not consumed et compile le mix Fact + Event en `allOf` ;
- retire les conditions Event consumed et vide la dernière condition ;
- refuse target vide, inconnu et self target ;
- refuse source inconnue, event sans page et index invalide ;
- bloque ajout/retrait si condition legacy préservée.

### UI

Fichier : `packages/map_editor/test/event_builder_workspace_test.dart`

Tests ajoutés :

- `NS-EVENT-14 adds and removes Event consumed conditions`
- `NS-EVENT-14 explains that no other event target is available`
- `NS-EVENT-14 keeps locked legacy event conditions read-only`
- `captures NS-EVENT-14 event consumed authoring visual gate`

Le test de retrait tape le libellé `Retirer` dans le bouton ciblé : le widget design-system peut avoir une surface visuelle plus large que la zone hittable dans certains layouts de test, et ce choix évite de modifier le design system dans ce lot.

## 11. Visual Gate

Capture générée :

```text
reports/narrativeStudio/events/screenshots/ns_event_14_event_consumed_conditions_authoring_v0.png
```

Commande :

```bash
cd packages/map_editor
flutter test --no-pub --update-goldens --reporter=compact test/event_builder_workspace_test.dart --name "captures NS-EVENT-14" --dart-define=NS_EVENT_14_CAPTURE_WORKSPACE=true
```

Résultat :

```text
00:09 +1: All tests passed!
```

Image :

```text
PNG image data, 1440 x 900, 8-bit/color RGBA, non-interlaced
pixelWidth: 1440
pixelHeight: 900
sha256: eba81fcfaba341bf6586c92f54a7e149a5393051f663cdca3c406001193f6f8d
```

## 12. Validations exécutées

Note : les commandes Flutter ont été lancées avec `--no-pub` pour éviter une mutation dépendances/native-assets hors scope. Une tentative parallèle de deux commandes Flutter a déclenché un échec natif transitoire :

```text
Failed to code sign binary: exit code: 1 ... objective_c.dylib: No such file or directory
```

La commande concernée a été relancée seule et a produit le signal fiable.

### RED initial

Commande notifier :

```bash
cd packages/map_editor
flutter test --no-pub --reporter=compact test/event_builder_draft_creation_notifier_test.dart --name "NS-EVENT-14"
```

Échec attendu avant implémentation :

```text
The method 'addEventBuilderEventConsumedCondition' isn't defined for the type 'EditorNotifier'.
```

Commande workspace :

```bash
cd packages/map_editor
flutter test --no-pub --reporter=compact test/event_builder_workspace_test.dart --name "NS-EVENT-14"
```

Échecs attendus avant implémentation :

```text
EventBuilderConditionEventOption not found
EventBuilderEventConsumedConditionAddCallback not found
No named parameter with the name 'eventConditionOptions'
```

### Tests ciblés GREEN

```bash
cd packages/map_editor
flutter test --no-pub --reporter=compact test/event_builder_workspace_test.dart --name "NS-EVENT-14"
```

Résultat :

```text
00:03 +4: All tests passed!
```

```bash
cd packages/map_editor
flutter test --no-pub --reporter=compact test/event_builder_draft_creation_notifier_test.dart --name "NS-EVENT-14"
```

Résultat :

```text
00:02 +6: All tests passed!
```

### Suites complètes demandées

```bash
cd packages/map_editor
flutter test --no-pub --reporter=compact test/event_builder_workspace_test.dart
```

Résultat final :

```text
00:08 +38: All tests passed!
```

```bash
cd packages/map_editor
flutter test --no-pub --reporter=compact test/event_builder_draft_creation_notifier_test.dart
```

Résultat :

```text
00:02 +25: All tests passed!
```

```bash
cd packages/map_core
dart test --reporter=compact test/event_builder_contract_test.dart test/event_builder_authoring_operations_test.dart test/event_builder_read_model_test.dart test/event_builder_draft_creation_operations_test.dart
```

Résultat :

```text
00:00 +40: All tests passed!
```

### Analyse ciblée

```bash
cd packages/map_editor
flutter analyze --no-pub --no-fatal-infos lib/src/features/editor/state/editor_notifier.dart lib/src/ui/canvas/events/event_builder_workspace.dart lib/src/ui/canvas/narrative_workspace_canvas.dart test/event_builder_workspace_test.dart test/event_builder_draft_creation_notifier_test.dart
```

Résultat :

```text
Analyzing 5 items...
No issues found! (ran in 1.7s)
```

### Build macOS debug

```bash
cd packages/map_editor
flutter build macos --debug --no-pub
```

Résultat :

```text
Building macOS application...
✓ Built build/macos/Build/Products/Debug/map_editor.app
```

## 13. Non-objectifs respectés

Confirmé :

- pas d'édition trigger ;
- pas d'édition Scene action ;
- pas d'édition behavior ;
- pas d'édition titre ;
- pas d'édition position/couche ;
- pas de Story Step condition ;
- pas de conditions OR/groupes imbriqués ;
- pas d'outcome/réaction/World Rule ;
- pas de flow editor ;
- pas de drag/drop ;
- pas de `map_runtime`, `map_gameplay`, `map_battle`, `GameState` ;
- pas de Selbrume/project.json/assets/pubspec ;
- pas de generated files ;
- aucun commit.

## 14. Impact sur NS-EVENT-15

NS-EVENT-15 peut maintenant s'appuyer sur :

- une section Conditions qui supporte Fact true/false et Event consumed/not consumed ;
- un retrait commun des conditions supportées ;
- la protection legacy avancée ;
- une source d'options event basée sur la map active ;
- des tests UI/state couvrant add/remove, empty-state, verrouillage et auto-cible.

Prochain lot recommandé : ouvrir un autre sous-ensemble borné de conditions ou conséquences, sans flow editor libre.

## 15. Limites restantes

- L'auto-cible est volontairement refusée en V0.
- Les conditions Story Step restent lues mais non éditables.
- Les conditions avancées legacy verrouillent toujours toute édition partielle.
- L'UI liste les events de la map active uniquement.
- Les options Event utilisent `title` puis fallback `id`; il n'existe pas encore de picker de scope global multi-map.

## 16. Evidence Pack complet

### Règles lues

```text
AGENTS.md
agent_rules.md
codex_rule.md
skills/README.md
skills/using-superpowers/SKILL.md
skills/test-driven-development/SKILL.md
skills/verification-before-completion/SKILL.md
skills/systematic-debugging/SKILL.md
```

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
7f490b9e ns_event_13: Ajout de l'auteur des conditions de fait pour les événements
26bec474 ns_event_12: Ajout de l'auteur des comportements pour les événements
00698aea ns_event_11: Ajout de l'auteur des actions de scène pour les événements
fc0e0be0 ns_event_10: Ajout de la saisie du titre pour les brouillons d'événements
```

`git status`, `git diff --stat` et `git diff --name-only` étaient vides au Gate 0.

### Fichiers lus / audités

```text
packages/map_core/lib/src/authoring/event_builder_authoring_operations.dart
packages/map_core/lib/src/read_models/event_builder_read_model.dart
packages/map_core/lib/src/models/map_event.dart
packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/test/event_builder_workspace_test.dart
packages/map_editor/test/event_builder_draft_creation_notifier_test.dart
```

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
reports/narrativeStudio/events/ns_event_14_event_consumed_conditions_authoring_v0.md
reports/narrativeStudio/events/screenshots/ns_event_14_event_consumed_conditions_authoring_v0.png
```

### Fichiers supprimés

```text
<aucun>
```

### Zones modifiées par fichier

`editor_notifier.dart` :

- ajout `addEventBuilderEventConsumedCondition(...)` ;
- extension du retrait aux conditions Event consumed/not consumed ;
- renommage du garde `_isEventBuilderEditableConditionKind(...)` ;
- message compile unsupported rendu générique à l'authoring scope courant.

`event_builder_workspace.dart` :

- ajout option/callback event condition ;
- injection des options dans l'inspecteur ;
- UI `Ajouter une condition d’événement` ;
- choix `Déjà consommé` / `Pas encore consommé` ;
- empty-state "Aucun autre événement disponible" ;
- retrait commun Fact/Event.

`narrative_workspace_canvas.dart` :

- construction des options depuis `activeMap.events` ;
- wiring vers `EditorNotifier.addEventBuilderEventConsumedCondition`.

Tests :

- ajout tests state NS-EVENT-14 ;
- ajout tests widget NS-EVENT-14 ;
- ajout Visual Gate NS-EVENT-14.

### Diff stat avant rapport

```text
.../src/features/editor/state/editor_notifier.dart | 105 ++++++-
.../ui/canvas/events/event_builder_workspace.dart  | 257 +++++++++++++--
.../src/ui/canvas/narrative_workspace_canvas.dart  |  16 +
...event_builder_draft_creation_notifier_test.dart | 346 +++++++++++++++++++++
.../test/event_builder_workspace_test.dart         | 328 ++++++++++++++++++-
5 files changed, 1024 insertions(+), 28 deletions(-)
```

### Gate final

Commande :

```bash
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git diff --check
```

Sortie exacte utile :

```text
 M packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
 M packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
 M packages/map_editor/test/event_builder_draft_creation_notifier_test.dart
 M packages/map_editor/test/event_builder_workspace_test.dart
?? reports/narrativeStudio/events/ns_event_14_event_consumed_conditions_authoring_v0.md
?? reports/narrativeStudio/events/screenshots/ns_event_14_event_consumed_conditions_authoring_v0.png
 .../src/features/editor/state/editor_notifier.dart | 105 ++++++-
 .../ui/canvas/events/event_builder_workspace.dart  | 257 +++++++++++++--
 .../src/ui/canvas/narrative_workspace_canvas.dart  |  16 +
 ...event_builder_draft_creation_notifier_test.dart | 346 +++++++++++++++++++++
 .../test/event_builder_workspace_test.dart         | 328 ++++++++++++++++++-
 5 files changed, 1024 insertions(+), 28 deletions(-)
packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/test/event_builder_draft_creation_notifier_test.dart
packages/map_editor/test/event_builder_workspace_test.dart
```

`git diff --check` : aucune sortie.

### Anti-scope final

Commande :

```bash
git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle packages/map_core examples assets selbrume pubspec.yaml
```

Sortie exacte :

```text
<vide>
```

Screenshots :

```bash
find reports/narrativeStudio/events/screenshots -maxdepth 1 -name '*ns_event_14*' -print
find reports/narrativeStudio/events/screenshots -maxdepth 1 -name '*ns_event_15*' -print
```

Sortie exacte :

```text
reports/narrativeStudio/events/screenshots/ns_event_14_event_consumed_conditions_authoring_v0.png
```

La recherche `*ns_event_15*` est vide.

## 17. Sub-agent passes / verdicts

### Sub-agent Audit / Architecture

Verdict : **OK**.

Le core Event Builder avait déjà les bindings `eventConsumed` / `eventNotConsumed`, la compilation `ScriptCondition`, le read model labelisé et le verrou `legacyConditionToPreserve`. Aucune modification `map_core` n'était nécessaire.

### Sub-agent Implémentation

Verdict : **OK**.

L'implémentation reste dans `map_editor`, écrit uniquement `MapEventPage.condition`, préserve la page authorable canonique et garde l'UI no-code.

### Sub-agent Tests

Verdict : **OK**.

Les tests couvrent add true/false, mix Fact + Event, retrait, dernière condition à `null`, target vide/inconnu/self, event inconnu/sans page, index invalide, legacy lock et UI.

### Sub-agent Build / Validation

Verdict : **OK**.

Tests targeted, suites complètes, analyse ciblée, Visual Gate et build macOS debug passent.

### Sub-agent Critique finale

Verdict : **OK avec réserve mineure**.

Réserve : le test de retrait tape le texte `Retirer` dans le bouton parce que le centre du `PokeMapButton` peut ne pas être hittable dans ce layout de test. Cela ne justifie pas de modifier le design system dans ce lot, mais mérite d'être gardé en tête si d'autres tests rencontrent le même symptôme.

## 18. Auto-review critique

Points vérifiés :

- aucun scope runtime ;
- aucun scope core ;
- aucun scope Selbrume ;
- pas de trigger/action/behavior ajouté ;
- pas de flow editor ;
- condition legacy avancée conservée ;
- auto-cible bloquée ;
- événements inconnus refusés ;
- options no-code basées sur labels humains ;
- tests significatifs, non skipped ;
- Visual Gate produite.

Risque restant : si le produit veut finalement autoriser les conditions auto-référentes, cela devra être un choix UX explicite d'un lot ultérieur, avec wording dédié.
