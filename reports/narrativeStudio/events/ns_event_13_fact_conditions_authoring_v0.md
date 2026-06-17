# NS-EVENT-13 — Event Builder Fact Conditions Authoring V0

## 1. Résumé exécutif

NS-EVENT-13 ajoute la première édition no-code des conditions d’événement dans le workspace Événements :

- ajouter une condition `Fact vrai` ;
- ajouter une condition `Fact faux` ;
- retirer une condition Fact ;
- compiler plusieurs conditions en `allOf` ;
- remettre `MapEventPage.condition` à `null` quand la dernière condition est retirée ;
- bloquer l’édition si une condition legacy avancée est préservée.

Le lot reste volontairement borné à `MapEventPage.condition`. Aucun trigger, outcome, réaction, World Rule, flow editor, runtime, gameplay, battle, Selbrume ou `map_core` n’a été modifié.

Verdict : NS-EVENT-13 est implémenté côté `map_editor`, avec tests notifier/UI, Visual Gate et build macOS debug validés.

## 2. Décision page cible

La page authorable canonique reste la page au plus petit `pageNumber`, comme NS-EVENT-11 et NS-EVENT-12.

Raisons :

- `readEventBuilderContractFromMapEvent(...)` lit déjà cette page par défaut ;
- `EventBuilderReadModel` suit ce contrat ;
- les drafts NS-EVENT-06 créent `pageNumber = 0` ;
- les events legacy peuvent avoir des pages non ordonnées.

Le code ne suppose donc pas que `event.pages[0]` est canonique. Si l’event n’a aucune page, l’opération refuse proprement avec :

```text
Cet événement ne contient aucune page authorable.
```

## 3. Opérations notifier ajoutées

Fichier modifié :

```text
packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
```

Méthodes ajoutées :

```dart
bool addEventBuilderFactCondition({
  required String eventId,
  required String factId,
  required bool expectedValue,
})

bool removeEventBuilderConditionAt({
  required String eventId,
  required int conditionIndex,
})
```

Garde-fous ajoutés :

- active map requise ;
- project actif requis pour valider les Facts ;
- `factId.trim()` obligatoire ;
- Fact inconnu refusé ;
- event inconnu refusé ;
- event sans page refusé ;
- `legacyConditionToPreserve != null` bloque ajout/retrait ;
- index de condition hors limites refusé ;
- seuls `factIsTrue` et `factIsFalse` sont retirables dans ce lot ;
- `selectedMapEventId` reste l’event édité.

Extrait important :

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
final condition = expectedValue
    ? EventBuilderConditionBinding.factIsTrue(trimmedFactId)
    : EventBuilderConditionBinding.factIsFalse(trimmedFactId);
```

## 4. UI Fact conditions ajoutée

Fichiers modifiés :

```text
packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
```

UI ajoutée dans la section `Conditions` :

- bouton `Ajouter une condition Fact` ;
- panneau `Facts disponibles` ;
- actions `Doit être vrai` / `Doit être faux` ;
- bouton `Retirer` sur les conditions Fact éditables ;
- message no-code si aucun Fact n’existe ;
- message no-code si les conditions sont verrouillées.

Le workspace reçoit maintenant :

```dart
final List<EventBuilderFactOption> factOptions;
final EventBuilderFactConditionAddCallback? onAddFactCondition;
final EventBuilderConditionRemoveCallback? onRemoveCondition;
```

Le `NarrativeWorkspaceCanvas` construit les options depuis `project.facts` :

```dart
List<EventBuilderFactOption> _buildEventBuilderFactOptions(
  ProjectManifest? project,
) {
  return [
    for (final fact in project?.facts ?? const <NarrativeFactDefinition>[])
      EventBuilderFactOption(
        id: fact.id,
        label: fact.label.trim().isEmpty ? fact.id : fact.label.trim(),
      ),
  ];
}
```

## 5. Options Fact / labels

Règle de label :

```text
fact.label.trim() si non vide, sinon fact.id
```

Le label humain est le workflow principal. Aucun champ libre `factId`, JSON ou `ScriptCondition` n’est exposé.

## 6. Gestion `legacyConditionToPreserve`

Audit :

- `readEventBuilderContractFromMapEvent(...)` expose `legacyConditionToPreserve` quand une condition contient une partie avancée non éditable par l’Event Builder V0.
- `EventBuilderReadModel.conditionEditingLocked` et `conditionEditingMessage` existaient déjà.
- `addEventBuilderCondition(...)` / `removeEventBuilderCondition(...)` protègent aussi cette frontière côté core.

Décision :

- l’UI masque les actions add/remove si `conditionEditingLocked == true` ;
- le notifier relit le contrat et refuse également si `legacyConditionToPreserve != null`.

Message notifier :

```text
Cette condition contient une partie avancée préservée. Elle ne peut pas être éditée partiellement.
```

Message UI :

```text
Conditions verrouillées
Cette condition contient une partie avancée préservée.
Elle est lisible, mais pas encore éditable partiellement.
La condition complète est conservée telle quelle.
```

## 7. Compilation ScriptCondition

Le lot utilise le contrat core existant :

```text
EventBuilderConditionBinding.factIsTrue(...)
EventBuilderConditionBinding.factIsFalse(...)
compileEventBuilderConditionsToScriptCondition(...)
```

Comportement vérifié :

- 1 condition true -> `ScriptConditionFactory.flagIsSet(factId)` ;
- 1 condition false -> `ScriptConditionFactory.flagIsUnset(factId)` ;
- plusieurs conditions -> `ScriptConditionFactory.allOf([...])` ;
- 0 condition après retrait -> `MapEventPage.condition == null`.

## 8. Préservation des champs existants

Le notifier n’applique pas tout le contrat Event Builder pour écrire les conditions. Il compile uniquement les bindings Fact, puis utilise `updatePageOnMapEvent(...)` avec `condition` / `clearCondition`.

Raison : NS-EVENT-13 ne possède que `MapEventPage.condition` et ne doit pas réécrire `sceneTarget`, `metadata`, `script` ou `message`.

Champs préservés par tests :

- `event.id` ;
- `event.title` ;
- `event.position` ;
- `event.type` ;
- `event.metadata` ;
- `page.sceneTarget` ;
- `page.script` ;
- `page.message` ;
- `page.metadata` ;
- `selectedMapEventId`.

## 9. Tests ajoutés/modifiés

Fichiers :

```text
packages/map_editor/test/event_builder_draft_creation_notifier_test.dart
packages/map_editor/test/event_builder_workspace_test.dart
```

Tests notifier NS-EVENT-13 ajoutés :

- `adds a true Fact condition without changing other event fields`
- `adds false Fact conditions and compiles multiple conditions as allOf`
- `removes conditions and clears the page condition when none remain`
- `rejects empty or unknown facts without mutating the event`
- `rejects unknown events without pages and out of range removal`
- `refuses to edit preserved legacy conditions`

Tests UI NS-EVENT-13 ajoutés :

- `NS-EVENT-13 adds and removes Fact conditions from details`
- `NS-EVENT-13 explains that no Fact is available`
- `NS-EVENT-13 keeps locked legacy conditions read-only`
- `captures NS-EVENT-13 fact conditions authoring visual gate`

## 10. Visual Gate

Capture créée :

```text
reports/narrativeStudio/events/screenshots/ns_event_13_fact_conditions_authoring_v0.png
```

Métadonnées :

```text
PNG image data, 1440 x 900, 8-bit/color RGBA, non-interlaced
pixelWidth: 1440
pixelHeight: 900
sha256: 4aafa0d79c63ee17c00739c623d73e8c2bb947e9091d552f3fe6b6e80762ecfb
```

La capture montre :

- workspace Événements ;
- event sélectionné ;
- section `Conditions` avec `Fact "Départ accepté" est vrai` ;
- action principale Scene toujours visible ;
- comportement toujours visible ;
- aucun éditeur trigger/outcome/world rules/flow editor.

## 11. Validations exécutées

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
<git status vide>
<git diff --stat vide>
<git diff --name-only vide>
26bec474 ns_event_12: Ajout de l'auteur des comportements pour les événements
00698aea ns_event_11: Ajout de l'auteur des actions de scène pour les événements
fc0e0be0 ns_event_10: Ajout de la saisie du titre pour les brouillons d'événements
```

### RED initial

Commande :

```bash
cd packages/map_editor
flutter test --no-pub --reporter=compact test/event_builder_draft_creation_notifier_test.dart --name "NS-EVENT-13"
```

Sortie utile :

```text
Failed to load "test/event_builder_draft_creation_notifier_test.dart":
The method 'addEventBuilderFactCondition' isn't defined for the type 'EditorNotifier'.
The method 'removeEventBuilderConditionAt' isn't defined for the type 'EditorNotifier'.
```

Commande :

```bash
cd packages/map_editor
flutter test --no-pub --reporter=compact test/event_builder_workspace_test.dart --name "NS-EVENT-13"
```

Sortie utile :

```text
Failed to load "test/event_builder_workspace_test.dart":
Type 'EventBuilderFactOption' not found.
Type 'EventBuilderFactConditionAddCallback' not found.
Type 'EventBuilderConditionRemoveCallback' not found.
No named parameter with the name 'factOptions'.
```

Note : une relance parallèle pendant la reprise a aussi produit un échec environnemental transient côté native assets :

```text
Failed to get the install name of LocalFile: '.../objective_c.dylib'
```

La commande relancée seule a ensuite passé sans modification de code.

### Tests ciblés GREEN

Commande :

```bash
cd packages/map_editor
flutter test --no-pub --reporter=compact test/event_builder_draft_creation_notifier_test.dart --name "NS-EVENT-13"
```

Sortie :

```text
00:05 +6: All tests passed!
```

Commande :

```bash
cd packages/map_editor
flutter test --no-pub --reporter=compact test/event_builder_workspace_test.dart --name "NS-EVENT-13"
```

Sortie :

```text
00:06 +4: All tests passed!
```

### Suites complètes demandées

Commande :

```bash
cd packages/map_editor
flutter test --no-pub --reporter=compact test/event_builder_workspace_test.dart
```

Sortie :

```text
00:15 +34: All tests passed!
```

Commande :

```bash
cd packages/map_editor
flutter test --no-pub --reporter=compact test/event_builder_draft_creation_notifier_test.dart
```

Sortie :

```text
00:02 +19: All tests passed!
```

Commande :

```bash
cd packages/map_core
dart test --reporter=compact test/event_builder_contract_test.dart test/event_builder_authoring_operations_test.dart test/event_builder_read_model_test.dart test/event_builder_draft_creation_operations_test.dart
```

Sortie :

```text
00:00 +40: All tests passed!
```

### Visual Gate

Commande :

```bash
cd packages/map_editor
flutter test --no-pub --update-goldens --reporter=compact test/event_builder_workspace_test.dart --name "captures NS-EVENT-13" --dart-define=NS_EVENT_13_CAPTURE_WORKSPACE=true
```

Sortie :

```text
00:19 +1: All tests passed!
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
No issues found! (ran in 5.9s)
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

## 12. Non-objectifs respectés

Non modifié :

- triggers ;
- Scene action ;
- behavior ;
- titre ;
- position ;
- couche ;
- event consumed / not consumed ;
- Story Step conditions ;
- OR / groupes imbriqués ;
- variables ;
- inventaire ;
- Pokémon ;
- outcomes ;
- réactions ;
- World Rules ;
- flow editor ;
- drag/drop ;
- `map_runtime` ;
- `map_gameplay` ;
- `map_battle` ;
- `map_core` ;
- `Selbrume` ;
- `project.json`.

## 13. Impact sur NS-EVENT-14

NS-EVENT-14 peut partir d’une base où les conditions Fact simples sont éditables et compilées. Le prochain lot peut donc choisir entre :

- étendre les conditions vers Story Step ;
- ajouter une action/conséquence simple ;
- durcir le Validator Event Builder.

Décision recommandée : ne pas ouvrir les outcomes ou réactions tant que les conditions de base et les conséquences persistantes minimales ne sont pas fermées.

## 14. Limites restantes

Limites conservées volontairement :

- pas de conditions OR ;
- pas de groupement visuel ;
- pas d’édition event consumed ;
- pas de Story Step condition ;
- pas de création de Fact depuis Events ;
- pas de création automatique de Fact ;
- pas de flow editor ;
- pas de runtime bridge.

## 15. Evidence Pack complet

### Règles lues

Fichiers/règles lus :

```text
AGENTS.md
agent_rules.md
codex_rule.md
skills/README.md
skills/using-superpowers/SKILL.md
skills/test-driven-development/SKILL.md
skills/systematic-debugging/SKILL.md
skills/verification-before-completion/SKILL.md
skills/writing-plans/SKILL.md
```

### Audit prompt

Le prompt est cohérent avec l’état du repo :

- NS-EVENT-02/02-bis/03 existent côté core/read model ;
- NS-EVENT-10/11/12 existent côté UI/state ;
- la page canonique au plus petit `pageNumber` est alignée avec les lots précédents ;
- `map_core` n’a pas besoin d’être modifié.

Adaptation mineure :

- au lieu de `applyEventBuilderContractToMapEvent(...)`, le notifier utilise `updatePageOnMapEvent(...)` après compilation des seules conditions. Cette stratégie est plus petite et protège mieux `sceneTarget`, `script`, `message` et `metadata`, qui sont hors scope de NS-EVENT-13.

### Audit initial code

Éléments audités :

```text
EventBuilderConditionBinding
compileEventBuilderConditionsToScriptCondition(...)
readEventBuilderContractFromMapEvent(...)
applyEventBuilderContractToMapEvent(...)
addEventBuilderCondition(...)
removeEventBuilderCondition(...)
legacyConditionToPreserve
EventBuilderReadModel.conditionEditingLocked
EventBuilderWorkspace condition display
NarrativeFactDefinition
ProjectManifest.facts
EditorNotifier
updatePageOnMapEvent(...)
```

Réponses d’audit :

- Les conditions Fact sont lues par `readEventBuilderContractFromMapEvent(...)` puis projetées par `EventBuilderReadModel`.
- Elles sont compilées par `compileEventBuilderConditionsToScriptCondition(...)`.
- `sceneTarget`, `metadata`, `script`, `message` sont préservés en ne mettant à jour que `MapEventPage.condition`.
- `legacyConditionToPreserve` bloque ajout/retrait côté UI et notifier.
- S’il n’y a aucun Fact, l’UI affiche un message humain et ne propose pas de champ libre.
- La page ciblée est la page au plus petit `pageNumber`.

### Fichiers créés

```text
reports/narrativeStudio/events/ns_event_13_fact_conditions_authoring_v0.md
reports/narrativeStudio/events/screenshots/ns_event_13_fact_conditions_authoring_v0.png
```

### Fichiers modifiés

```text
packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/test/event_builder_draft_creation_notifier_test.dart
packages/map_editor/test/event_builder_workspace_test.dart
```

### Fichiers supprimés

```text
<aucun>
```

### Zones modifiées

`editor_notifier.dart`

- ajout des opérations `addEventBuilderFactCondition` / `removeEventBuilderConditionAt` ;
- ajout de `_updateEventBuilderPageCondition(...)` ;
- ajout de `_isEventBuilderFactConditionKind(...)` ;
- ajout du message partagé `_eventBuilderConditionLockedMessage`.

`event_builder_workspace.dart`

- ajout de `EventBuilderFactOption` ;
- ajout des callbacks Fact conditions ;
- ajout de l’UI bornée d’ajout/retrait ;
- ajout des messages empty/locked ;
- ajout des boutons no-code `Doit être vrai`, `Doit être faux`, `Retirer`.

`narrative_workspace_canvas.dart`

- construction des options Fact depuis `project.facts` ;
- passage des callbacks notifier au workspace ;
- fallback de label Fact dans le read model.

Tests :

- tests notifier positifs/négatifs/garde-fous ;
- tests UI no-code, empty state, legacy lock, Visual Gate.

### Diff final utile

```text
packages/map_editor/lib/src/features/editor/state/editor_notifier.dart | +211
packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart | +385 / -23
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart | +17 / -1
packages/map_editor/test/event_builder_draft_creation_notifier_test.dart | +328
packages/map_editor/test/event_builder_workspace_test.dart | +198
```

### Sub-agent Audit / Architecture

Verdict : PASS.

Le lot peut rester `map_editor`. Le core fournit déjà les bindings Fact, la compilation et le verrou legacy. Le choix de `updatePageOnMapEvent(...)` est le plus sûr pour préserver les surfaces hors scope.

### Sub-agent Implémentation

Verdict : PASS.

Les opérations notifier sont bornées à `MapEventPage.condition`. Les callbacks UI sont explicites. L’UI expose uniquement des Facts existants et des labels humains.

### Sub-agent Tests

Verdict : PASS.

Les tests couvrent ajout true, ajout false, `allOf`, retrait, dernier retrait -> `null`, Fact vide/inconnu, event inconnu, event sans page, index invalide, legacy lock, UI empty state, UI add/remove et non-exposition des contrôles hors scope.

### Sub-agent Build / Validation

Verdict : PASS.

Tests ciblés, suites complètes demandées, tests core Event Builder, analyse ciblée, Visual Gate et build macOS debug ont été lancés avec succès.

### Sub-agent Critique finale

Verdict : PASS avec réserves mineures.

Réserves :

- l’UI reste volontairement simple et peut devenir dense si beaucoup de Facts existent ;
- il n’y a pas encore de recherche/filtre dans le picker Facts ;
- le lot ne crée pas de Fact depuis Events, ce qui est voulu ;
- le runtime ne consomme rien de nouveau dans ce lot.

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
?? reports/narrativeStudio/events/ns_event_13_fact_conditions_authoring_v0.md
?? reports/narrativeStudio/events/screenshots/ns_event_13_fact_conditions_authoring_v0.png
```

Commande :

```bash
git diff --stat
```

Sortie :

```text
 .../src/features/editor/state/editor_notifier.dart | 211 +++++++++++
 .../ui/canvas/events/event_builder_workspace.dart  | 385 +++++++++++++++++++--
 .../src/ui/canvas/narrative_workspace_canvas.dart  |  17 +-
 ...event_builder_draft_creation_notifier_test.dart | 328 ++++++++++++++++++
 .../test/event_builder_workspace_test.dart         | 198 +++++++++++
 5 files changed, 1115 insertions(+), 24 deletions(-)
```

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
find reports/narrativeStudio/events/screenshots -maxdepth 1 -name '*ns_event_13*' -print
find reports/narrativeStudio/events/screenshots -maxdepth 1 -name '*ns_event_14*' -print
```

Sortie :

```text
reports/narrativeStudio/events/screenshots/ns_event_13_fact_conditions_authoring_v0.png
<vide>
```

## 16. Auto-review critique

Checklist :

- le lot n’a pas modifié `map_core` ;
- le lot n’a pas modifié runtime/gameplay/battle ;
- le lot n’a pas modifié Selbrume ;
- les conditions legacy avancées sont préservées ;
- les tests ne simulent pas une logique qui n’existe pas en production ;
- les IDs Fact ne sont pas le workflow principal ;
- aucun bouton trigger/outcome/world rules/flow editor n’a été ajouté ;
- la page cible est bien le plus petit `pageNumber` ;
- `sceneTarget`, `script`, `message`, `metadata` sont testés comme préservés.

Risque restant : si un projet contient des centaines de Facts, le picker V0 sera trop long. Ce n’est pas un blocker pour NS-EVENT-13 ; un futur lot UX pourra ajouter recherche ou regroupement.
