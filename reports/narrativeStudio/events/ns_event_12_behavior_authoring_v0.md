# NS-EVENT-12 — Event Builder Behavior Authoring V0

## 1. Résumé exécutif

NS-EVENT-12 ajoute l’édition no-code bornée du comportement de réutilisation d’un événement dans le workspace Événements :

- `Une seule fois` ;
- `Réutilisable`.

Le lot reste volontairement `map_editor` :

- aucune modification `map_core` ;
- aucune modification runtime/gameplay/battle ;
- aucune donnée Selbrume modifiée ;
- aucune édition trigger/condition/outcome/world rule/flow editor ajoutée.

Verdict : NS-EVENT-12 est implémenté côté UI/state editor avec tests ciblés, Visual Gate et build macOS debug.

## 2. Décision page cible

La page cible retenue est la page au plus petit `pageNumber`, identique à NS-EVENT-11.

Raison :

- `readEventBuilderContractFromMapEvent(...)` sélectionne cette page par défaut ;
- `EventBuilderReadModel` consomme ce contrat ;
- les drafts NS-EVENT-06 créent `pageNumber = 0` ;
- les anciens events peuvent avoir des pages non ordonnées.

Décision d’implémentation :

- refuser un event sans page ;
- ne pas supposer que `event.pages[0]` est canonique ;
- ne pas créer de page implicite ;
- ne pas modifier toutes les pages.

## 3. Opération notifier ajoutée

Fichier : `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`

Méthode ajoutée :

```dart
bool updateEventBuilderEventReusePolicy({
  required String eventId,
  required EventBuilderReusePolicy reusePolicy,
}) {
  final map = state.activeMap;
  if (map == null) {
    state = state.copyWith(
      errorMessage:
          'Aucune map active pour modifier le comportement de l’événement.',
    );
    return false;
  }
  final event = findMapEventById(map, eventId);
  if (event == null) {
    state = state.copyWith(errorMessage: 'Événement introuvable : $eventId');
    return false;
  }
  if (event.pages.isEmpty) {
    state = state.copyWith(
      errorMessage: 'Cet événement ne contient aucune page authorable.',
    );
    return false;
  }

  // NS-EVENT-12 édite uniquement les metadata Event Builder de la page
  // canonique. Les champs sceneTarget/condition/script/message restent
  // volontairement sous la responsabilité des lots dédiés.
  final pageNumber = _eventBuilderAuthorablePageNumber(event);
  final pageIndex =
      event.pages.indexWhere((page) => page.pageNumber == pageNumber);
  final page = event.pages[pageIndex];
  final nextMetadata = Map<String, String>.unmodifiable({
    ...page.metadata,
    EventBuilderMetadataKeys.schemaVersion:
        EventBuilderMetadataKeys.currentSchemaVersion,
    EventBuilderMetadataKeys.reusePolicy: reusePolicy.name,
  });
  try {
    final updated = updatePageOnMapEvent(
      map,
      eventId: eventId,
      pageIndex: pageIndex,
      metadata: nextMetadata,
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
      statusMessage: 'Comportement d’événement mis à jour',
    );
    return true;
  } catch (e) {
    state = state.copyWith(
      errorMessage:
          'Impossible de mettre à jour le comportement de l’événement : $e',
    );
    return false;
  }
}
```

## 4. UI Behavior ajoutée

Fichier : `packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart`

Callback ajouté :

```dart
typedef EventBuilderReusePolicyUpdateCallback = bool Function({
  required String eventId,
  required EventBuilderReusePolicy reusePolicy,
});
```

Le workspace reçoit `onUpdateReusePolicy`, transmis au panneau détail.

La section `Comportement` utilise maintenant `_buildBehaviorBlock(...)` :

```dart
Widget _buildBehaviorBlock(
  BuildContext context,
  EventBuilderEventSummary selected,
) {
  final colors = context.pokeMapColors;
  final canUpdateBehavior = widget.onUpdateReusePolicy != null;
  final currentPolicy = selected.behavior.reusePolicy;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _DetailLine(
        label: 'Réutilisation',
        value: selected.behavior.label,
      ),
      if (canUpdateBehavior) ...[
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            PokeMapButton(
              key: const ValueKey('event-builder-reuse-oneShot-button'),
              onPressed: currentPolicy == EventBuilderReusePolicy.oneShot
                  ? null
                  : () => _selectReusePolicy(
                        selected,
                        EventBuilderReusePolicy.oneShot,
                      ),
              variant: PokeMapButtonVariant.secondary,
              size: PokeMapButtonSize.small,
              isSelected: currentPolicy == EventBuilderReusePolicy.oneShot,
              leading: const Icon(CupertinoIcons.checkmark_circle),
              child: const Text('Une seule fois'),
            ),
            PokeMapButton(
              key: const ValueKey('event-builder-reuse-reusable-button'),
              onPressed: currentPolicy == EventBuilderReusePolicy.reusable
                  ? null
                  : () => _selectReusePolicy(
                        selected,
                        EventBuilderReusePolicy.reusable,
                      ),
              variant: PokeMapButtonVariant.secondary,
              size: PokeMapButtonSize.small,
              isSelected: currentPolicy == EventBuilderReusePolicy.reusable,
              leading: const Icon(CupertinoIcons.repeat),
              child: const Text('Réutilisable'),
            ),
            if (_behaviorFeedback != null)
              PokeMapBadge(
                label: _behaviorFeedback!,
                variant: PokeMapBadgeVariant.success,
                icon: const Icon(CupertinoIcons.checkmark_circle),
              ),
          ],
        ),
        if (_behaviorError != null) ...[
          const SizedBox(height: 6),
          Text(
            _behaviorError!,
            style: TextStyle(
              color: colors.error,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ],
    ],
  );
}
```

Sélection UI :

```dart
void _selectReusePolicy(
  EventBuilderEventSummary selected,
  EventBuilderReusePolicy reusePolicy,
) {
  final updated = widget.onUpdateReusePolicy?.call(
        eventId: selected.eventId,
        reusePolicy: reusePolicy,
      ) ??
      false;
  if (!updated) {
    setState(() {
      _behaviorError = 'Impossible de modifier ce comportement.';
      _behaviorFeedback = null;
    });
    return;
  }
  setState(() {
    _behaviorError = null;
    _behaviorFeedback = 'Comportement mis à jour.';
  });
}
```

Branchage dans `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart` :

```dart
onUpdateReusePolicy:
    editorNotifier.updateEventBuilderEventReusePolicy,
```

## 5. Metadata Event Builder

Écriture effectuée uniquement sur `MapEventPage.metadata` de la page authorable canonique :

```text
eventBuilder.schemaVersion = 1
eventBuilder.reusePolicy = oneShot | reusable
```

Les metadata legacy existantes sont préservées via :

```dart
final nextMetadata = Map<String, String>.unmodifiable({
  ...page.metadata,
  EventBuilderMetadataKeys.schemaVersion:
      EventBuilderMetadataKeys.currentSchemaVersion,
  EventBuilderMetadataKeys.reusePolicy: reusePolicy.name,
});
```

## 6. Préservation des champs existants

Les tests prouvent la préservation de :

- `MapEventDefinition.id` ;
- `MapEventDefinition.title` ;
- `MapEventDefinition.position` ;
- `MapEventDefinition.type` ;
- `MapEventDefinition.metadata` ;
- `MapEventPage.sceneTarget` ;
- `MapEventPage.condition` ;
- `MapEventPage.script` ;
- `MapEventPage.message` ;
- `MapEventPage.isDisabled` ;
- `MapEventPage.isHidden` ;
- metadata legacy de page ;
- `selectedMapEventId`.

## 7. Tests ajoutés/modifiés

Fichier : `packages/map_editor/test/event_builder_draft_creation_notifier_test.dart`

Tests ajoutés :

```text
NS-EVENT-12 EditorNotifier behavior authoring updates reuse policy metadata on the lowest page only
NS-EVENT-12 EditorNotifier behavior authoring rejects an unknown event without mutating the map
NS-EVENT-12 EditorNotifier behavior authoring rejects an event without page without mutating the map
```

Fichier : `packages/map_editor/test/event_builder_workspace_test.dart`

Tests ajoutés :

```text
NS-EVENT-12 changes reuse policy without changing id or scene action
NS-EVENT-12 keeps behavior read-only without update callback
captures NS-EVENT-12 behavior authoring visual gate
```

## 8. Visual Gate

Fichier créé :

```text
reports/narrativeStudio/events/screenshots/ns_event_12_behavior_authoring_v0.png
```

Métadonnées :

```text
PNG image data, 1440 x 900, 8-bit/color RGBA, non-interlaced
pixelWidth: 1440
pixelHeight: 900
sha256: 4f19de3e2cf35a410453c1da67d76a186e9812fbaa6c19b067d03306f810610b
```

La capture montre :

- workspace Événements ;
- event sélectionné ;
- section `Comportement` visible ;
- `Réutilisation : Réutilisable` ;
- feedback `Comportement mis à jour.` ;
- action principale Scene toujours visible dans la carte de liste ;
- aucun éditeur conditions/trigger/outcome/world rules.

## 9. Validations exécutées

### RED initial

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact test/event_builder_workspace_test.dart --name "NS-EVENT-12"
```

Sortie utile exacte :

```text
test/event_builder_workspace_test.dart:1098:3: Error: Type 'EventBuilderReusePolicyUpdateCallback' not found.
test/event_builder_workspace_test.dart:1130:15: Error: No named parameter with the name 'onUpdateReusePolicy'.
Some tests failed.
```

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact test/event_builder_draft_creation_notifier_test.dart --name "NS-EVENT-12"
```

Sortie utile exacte :

```text
Error: The method 'updateEventBuilderEventReusePolicy' isn't defined for the type 'EditorNotifier'.
Some tests failed.
```

Note tooling : un premier lancement Flutter parallèle a déclenché :

```text
PathExistsException: Cannot create link, path = '/Users/karim/Project/pokemonProject/packages/map_editor/macos/Flutter/ephemeral/Packages/.packages/file_picker-8.3.7'
```

Après cela, les commandes Flutter ont été lancées en séquentiel avec `--no-pub` pour éviter de retoucher le dossier `macos/Flutter/ephemeral` généré par Flutter.

### GREEN ciblé

Commande :

```bash
cd packages/map_editor
flutter test --no-pub --reporter=compact test/event_builder_draft_creation_notifier_test.dart --name "NS-EVENT-12"
```

Résultat exact :

```text
NS-EVENT-12 EditorNotifier behavior authoring updates reuse policy metadata on the lowest page only
NS-EVENT-12 EditorNotifier behavior authoring rejects an unknown event without mutating the map
NS-EVENT-12 EditorNotifier behavior authoring rejects an event without page without mutating the map
All tests passed!
```

Commande :

```bash
cd packages/map_editor
flutter test --no-pub --reporter=compact test/event_builder_workspace_test.dart --name "NS-EVENT-12"
```

Résultat exact :

```text
NS-EVENT-12 changes reuse policy without changing id or scene action
NS-EVENT-12 keeps behavior read-only without update callback
captures NS-EVENT-12 behavior authoring visual gate
All tests passed!
```

### Suites complètes map_editor ciblées

Commande :

```bash
cd packages/map_editor
flutter test --no-pub --reporter=compact test/event_builder_workspace_test.dart
```

Résultat exact :

```text
30 tests passed
All tests passed!
```

Commande :

```bash
cd packages/map_editor
flutter test --no-pub --reporter=compact test/event_builder_draft_creation_notifier_test.dart
```

Résultat exact :

```text
13 tests passed
All tests passed!
```

### Régressions core Event Builder

Commande :

```bash
cd packages/map_core
dart test --reporter=compact \
  test/event_builder_contract_test.dart \
  test/event_builder_authoring_operations_test.dart \
  test/event_builder_read_model_test.dart \
  test/event_builder_draft_creation_operations_test.dart
```

Résultat exact :

```text
40 tests passed
All tests passed!
```

### Visual Gate

Commande :

```bash
cd packages/map_editor
flutter test --no-pub --update-goldens --reporter=compact test/event_builder_workspace_test.dart --name "captures NS-EVENT-12" --dart-define=NS_EVENT_12_CAPTURE_WORKSPACE=true
```

Résultat exact :

```text
captures NS-EVENT-12 behavior authoring visual gate
All tests passed!
```

### Analyse ciblée

Commande :

```bash
cd packages/map_editor
flutter analyze --no-pub --no-fatal-infos \
  lib/src/features/editor/state/editor_notifier.dart \
  lib/src/ui/canvas/events/event_builder_workspace.dart \
  lib/src/ui/canvas/narrative_workspace_canvas.dart \
  test/event_builder_workspace_test.dart \
  test/event_builder_draft_creation_notifier_test.dart
```

Résultat exact :

```text
Analyzing 5 items...
No issues found! (ran in 4.4s)
```

### Build macOS debug

Commande :

```bash
cd packages/map_editor
flutter build macos --debug --no-pub
```

Résultat exact :

```text
Building macOS application...
✓ Built build/macos/Build/Products/Debug/map_editor.app
```

## 10. Non-objectifs respectés

Non démarrés :

- édition trigger ;
- édition conditions ;
- édition facts/steps ;
- édition outcomes/réactions ;
- édition World Rules ;
- édition position/couche ;
- édition titre ;
- édition Scene action ;
- bibliothèque de blocs ;
- flow editor ;
- drag/drop ;
- runtime / gameplay / battle / GameState ;
- Selbrume / `project.json` ;
- build_runner / fichiers générés.

## 11. Impact sur NS-EVENT-13

NS-EVENT-13 peut partir d’un event déjà éditable sur trois axes minimaux :

- titre humain ;
- action principale Scene ;
- comportement de réutilisation.

Le prochain lot peut donc viser une nouvelle surface bornée, probablement conditions simples ou trigger/source selon la roadmap Event Builder, sans devoir revenir sur le comportement.

## 12. Limites restantes

- La réutilisation est stockée et relue par le read model, mais aucun runtime Event Builder supplémentaire n’est ajouté dans ce lot.
- La section Behavior ne gère que `oneShot` / `reusable`.
- Les world impacts restent dérivés par le read model existant.
- Le souci Flutter `ephemeral/Packages/.packages` reste un problème de tooling macOS/Flutter observé uniquement pendant un lancement parallèle initial ; les validations ont été relancées proprement avec `--no-pub`.

## 13. Evidence Pack complet

### Règles lues

Fichiers lus :

```text
AGENTS.md
codex_rule.md
skills/README.md
skills/test-driven-development/SKILL.md
skills/verification-before-completion/SKILL.md
skills/writing-plans/SKILL.md
```

Skills appliqués :

```text
superpowers:test-driven-development
superpowers:verification-before-completion
superpowers:writing-plans, adapté en mini-plan local car le prompt fournit déjà le découpage et demande l’exécution directe.
```

### Gate 0 initial

Commande :

```bash
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git log --oneline -n 20
```

Sortie exacte utile :

```text
/Users/karim/Project/pokemonProject
main
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
703c5702 NS-SCENES-V1-136-BIS — Cinematic Builder Legacy Widget Expectations Cleanup
0f9c5cfe NS-SCENES-V1-136 — Cinematic Builder V1 Closure Readiness Audit
2bd11dda NS-SCENES-V1-135 — Cinematic Builder V1 Camera Closure Polish Gate
```

`git status`, `git diff --stat` et `git diff --name-only` étaient vides au Gate 0.

### Audit préalable

Audit demandé et résultat :

| Élément | Résultat |
|---|---|
| `EventBuilderReusePolicy` | existe dans `map_core`, valeurs `oneShot`, `reusable` |
| `EventBuilderBehaviorBinding` | existe dans `map_core`, factories `oneShot()` et `reusable()` |
| `EventBuilderMetadataKeys` | existe, clés `schemaVersion`, `reusePolicy`, version `1` |
| `readEventBuilderContractFromMapEvent(...)` | lit la page sélectionnée, défaut = plus petit `pageNumber` |
| `applyEventBuilderContractToMapEvent(...)` | écrit scene action, condition compilable et metadata behavior |
| `updateEventBuilderBehavior(...)` | change le binding dans une vue de contrat |
| `MapEventPage.metadata` | stockage cible demandé |
| `updatePageOnMapEvent(...)` | opération idéale pour modifier seulement `metadata` sans toucher aux autres champs |
| `EventBuilderReadModel` | lit `behavior.label` et affiche `Une seule fois` / `Réutilisable` |
| `EventBuilderWorkspace` | affichait déjà la section `Comportement` en lecture seule |
| `NarrativeWorkspaceCanvas` | branche les callbacks éditeur vers le workspace Events |
| `EditorNotifier` | avait déjà titre et scène, mais pas comportement |

Décision : utiliser `updatePageOnMapEvent(...)` plutôt que `applyEventBuilderContractToMapEvent(...)` pour éviter une réécriture indirecte de condition/sceneTarget dans un lot qui ne doit toucher que les metadata Behavior.

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
reports/narrativeStudio/events/ns_event_12_behavior_authoring_v0.md
reports/narrativeStudio/events/screenshots/ns_event_12_behavior_authoring_v0.png
```

### Diff stat avant rapport

```text
 .../src/features/editor/state/editor_notifier.dart |  65 ++++++++
 .../ui/canvas/events/event_builder_workspace.dart  | 114 +++++++++++++-
 .../src/ui/canvas/narrative_workspace_canvas.dart  |   2 +
 ...event_builder_draft_creation_notifier_test.dart | 174 +++++++++++++++++++++
 .../test/event_builder_workspace_test.dart         | 126 +++++++++++++++
 5 files changed, 477 insertions(+), 4 deletions(-)
```

### Gate final après rapport

Commande :

```bash
git status --short --untracked-files=all
```

Sortie exacte :

```text
 M packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
 M packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
 M packages/map_editor/test/event_builder_draft_creation_notifier_test.dart
 M packages/map_editor/test/event_builder_workspace_test.dart
?? reports/narrativeStudio/events/ns_event_12_behavior_authoring_v0.md
?? reports/narrativeStudio/events/screenshots/ns_event_12_behavior_authoring_v0.png
```

Commande :

```bash
git diff --stat
```

Sortie exacte :

```text
 .../src/features/editor/state/editor_notifier.dart |  65 ++++++++
 .../ui/canvas/events/event_builder_workspace.dart  | 114 +++++++++++++-
 .../src/ui/canvas/narrative_workspace_canvas.dart  |   2 +
 ...event_builder_draft_creation_notifier_test.dart | 174 +++++++++++++++++++++
 .../test/event_builder_workspace_test.dart         | 126 +++++++++++++++
 5 files changed, 477 insertions(+), 4 deletions(-)
```

Commande :

```bash
git diff --name-only
```

Sortie exacte :

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

Commande screenshots :

```bash
find reports/narrativeStudio/events/screenshots -maxdepth 1 -name '*ns_event_12*' -print
find reports/narrativeStudio/events/screenshots -maxdepth 1 -name '*ns_event_13*' -print
```

Sortie exacte :

```text
reports/narrativeStudio/events/screenshots/ns_event_12_behavior_authoring_v0.png
<vide>
```

### Sub-agent Audit / Architecture

Verdict : OK.

Le lot peut rester `map_editor` parce que le core expose déjà les enums, helpers et opérations nécessaires. La stratégie la plus sûre est d’écrire uniquement les metadata de page via `updatePageOnMapEvent(...)`.

### Sub-agent Implémentation

Verdict : OK.

Implémentation bornée :

- méthode notifier ;
- callback UI ;
- boutons humains ;
- feedback no-code ;
- aucun champ metadata affiché.

### Sub-agent Tests

Verdict : OK.

Tests ajoutés couvrent :

- passage `oneShot -> reusable` ;
- retour `reusable -> oneShot` ;
- page au plus petit `pageNumber` ;
- préservation des champs ;
- event inconnu ;
- event sans page ;
- UI et absence des contrôles hors scope.

### Sub-agent Build / Validation

Verdict : OK.

Tests ciblés, régressions core, analyse ciblée, Visual Gate et build macOS debug exécutés. Le seul incident est un crash Flutter de tooling lors d’un lancement parallèle initial, contourné ensuite par exécution séquentielle et `--no-pub`.

### Sub-agent Critique finale

Verdict : OK avec réserve mineure tooling.

Points vérifiés :

- aucun `map_core` modifié ;
- aucun runtime touché ;
- aucun Selbrume touché ;
- pas d’édition conditions/triggers/outcomes/world rules ;
- feedback visible ;
- bouton actif borné à deux choix ;
- metadata non exposées à l’utilisateur ;
- Visual Gate lisible après ajustement de scroll.

Risque restant : le dossier Flutter macOS ephemeral peut gêner les commandes sans `--no-pub` si Flutter tente de régénérer les packages SwiftPM. Ce risque est tooling, non fonctionnel.

## 14. Auto-review critique

Le prompt est cohérent avec l’état du repo : NS-EVENT-06/10/11 existent, le core expose déjà `EventBuilderReusePolicy`, et la section `Comportement` existait déjà en lecture seule.

Choix discuté :

- `applyEventBuilderContractToMapEvent(...)` aurait été conceptuellement plus haut niveau, mais il réécrit aussi des surfaces contractuelles comme scene action et condition compilable. Pour NS-EVENT-12, `updatePageOnMapEvent(...)` est plus petit et protège mieux les non-objectifs.

Réserve :

- la UI affiche deux boutons inline plutôt qu’un segmented control dédié. C’est acceptable car `PokeMapButton` est déjà la primitive utilisée dans les lots précédents, et aucun composant segmented spécifique n’était nécessaire pour deux valeurs.

Prochaine étape proposée :

- NS-EVENT-13 peut s’appuyer sur titre + scène + comportement comme base authoring minimale, sans rouvrir ce lot.
