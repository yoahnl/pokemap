# NS-EVENT-07 — Event Builder Draft Creation UI Entry / Explicit Position Gate V0

## Résumé exécutif

Verdict : `NS-EVENT-07 : DONE`, avec création volontairement bloquée dans le workspace réel.

Le lot ajoute une entrée UI `Nouvel événement` dans l'Event Builder, mais elle reste désactivée tant qu'aucune position explicite, stable et authorable n'est disponible. Le message no-code affiché est :

```text
Sélectionnez une position sur la carte pour créer un événement.
```

La création effective via `createEventBuilderDraftEventOnMap(...)` n'est pas branchée dans l'app réelle, parce que l'audit a trouvé seulement :

- `activeMap` : disponible ;
- `activeLayerId` : disponible mais pas suffisant seul ;
- `hoveredTile` : disponible mais transitoire, donc refusé comme position d'authoring stable ;
- aucune sélection explicite de tuile/cellule dédiée à la création d'événement dans le workspace Narrative Studio.

Décision : ne pas inventer `x=0`, `y=0`, ni `layerId=events`, et ne pas réutiliser le fallback legacy `addMapEventAt` qui prend la première couche si aucune couche active valide n'existe.

## Rappel NS-EVENT-06

NS-EVENT-06 a ajouté l'opération core de création de brouillon d'événement avec position explicite :

```text
createEventBuilderDraftEventOnMap(...)
```

Ses règles importantes pour NS-EVENT-07 :

- le caller fournit explicitement la map ;
- le caller fournit explicitement `x`, `y` et `layerId` ;
- l'opération ne crée pas de `sceneTarget`, `script`, `message` ou condition ;
- l'opération laisse le read model afficher l'événement comme `Brouillon`.

NS-EVENT-07 ne réimplémente pas cette logique dans l'éditeur. Il prépare seulement une entrée UI qui pourra appeler une opération sûre quand le contexte de position sera disponible.

## Audit initial

Commande Gate 0 :

```bash
pwd && git branch --show-current && git status --short --untracked-files=all && git diff --stat && git diff --name-only && git log --oneline -n 12
```

Sortie utile :

```text
/Users/karim/Project/pokemonProject
main
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

`git status`, `git diff --stat` et `git diff --name-only` étaient vides au Gate 0.

Règles lues :

- `AGENTS.md` fourni dans le contexte ;
- `codex_rule.md` ;
- `agent_rules.md` ;
- `skills/README.md` ;
- `skills/test-driven-development/SKILL.md` ;
- `skills/verification-before-completion/SKILL.md` ;
- skill système `flutter-add-widget-test`.

## Passes indépendantes

Passe 1 — audit produit :

- verdict : le lot doit rester UI gate, pas création réelle ;
- raison : pas de position stable sélectionnée dans l'Event Builder.

Passe 2 — audit code :

- verdict : `EditorState` expose `activeMap`, `activeLayerId`, `hoveredTile`, `selectedMapEventId` ;
- risque identifié : `hoveredTile` est un état de survol et ne doit pas devenir une position authoring persistante.

Passe 3 — TDD :

- verdict : tests RED écrits avant implémentation ;
- preuve : le premier run échouait car `EventBuilderDraftCreationGate` et le paramètre `draftCreationGate` n'existaient pas.

Passe 4 — vérification :

- verdict : tests widget, tests core, analyse ciblée et Visual Gate passent.

## Audit position / couche / création existante

Symboles audités :

```text
packages/map_editor/lib/src/features/editor/state/editor_state.dart
packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart
```

État éditeur disponible :

```dart
MapData? activeMap;
String? activeLayerId;
GridPos? hoveredTile;
String? selectedMapEventId;
```

Création legacy existante :

```dart
void addMapEventAt(GridPos pos) {
  final map = state.activeMap;
  if (map == null) return;
  final layerId = _resolveEventPlacementLayerId(map);
  if (layerId == null) {
    state = state.copyWith(
      errorMessage: 'No layer available to place a map event',
    );
    return;
  }
  final eventId = _generateUniqueMapEventId(map);
  final created = MapEventDefinition(
    id: eventId,
    title: eventId,
    position: EventPosition(layerId: layerId, x: pos.x, y: pos.y),
    pages: const [
      MapEventPage(
        pageNumber: 0,
        message: '',
      ),
    ],
  );
  ...
}
```

Fallback legacy audité :

```dart
String? _resolveEventPlacementLayerId(MapData map) {
  final activeLayerId = state.activeLayerId?.trim();
  if (activeLayerId != null &&
      activeLayerId.isNotEmpty &&
      map.layers.any((layer) => layer.id == activeLayerId)) {
    return activeLayerId;
  }
  if (map.layers.isNotEmpty) {
    return map.layers.first.id;
  }
  return null;
}
```

Conclusion : ce fallback n'est pas acceptable pour NS-EVENT-07, car le prompt interdit d'inventer une couche ou un contexte. Le lot n'utilise donc pas `addMapEventAt`.

## Décisions d'implémentation

Décision 1 : ajouter une classe `EventBuilderDraftCreationGate`.

Objectif :

- porter un callback de création uniquement quand le contexte est explicitement prêt ;
- exposer un état disabled par défaut ;
- garder le workspace testable sans muter le projet.

Décision 2 : afficher `Nouvel événement`, mais désactivé par défaut.

Objectif :

- rendre le prochain flux visible ;
- éviter une création silencieuse ou incorrecte.

Décision 3 : ajouter le message de position sous les métriques.

Objectif :

- dire clairement ce qui manque ;
- ne pas exposer d'ID technique ou de JSON.

Décision 4 : ne pas modifier `NarrativeWorkspaceCanvas`.

Raison :

- aucune position explicitement sélectionnée n'existe à passer au workspace ;
- passer `hoveredTile` aurait créé une position implicite et fragile.

## Fichiers modifiés

```text
packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart
packages/map_editor/test/event_builder_workspace_test.dart
```

## Fichiers créés

```text
reports/narrativeStudio/events/screenshots/ns_event_07_draft_creation_ui_gate_v0.png
reports/narrativeStudio/events/ns_event_07_draft_creation_ui_entry_explicit_position_gate_v0.md
```

## Code généré / zones modifiées

### Gate UI

```dart
class EventBuilderDraftCreationGate {
  const EventBuilderDraftCreationGate.disabled({
    this.disabledReason =
        'Sélectionnez une position sur la carte pour créer un événement.',
  })  : onCreateDraft = null,
        readyLabel = 'Position requise';

  const EventBuilderDraftCreationGate.enabled({
    required this.onCreateDraft,
    this.readyLabel = 'Position prête',
  }) : disabledReason = null;

  final VoidCallback? onCreateDraft;
  final String? disabledReason;
  final String readyLabel;

  bool get canCreate => onCreateDraft != null;
}
```

### Bouton d'entrée

```dart
PokeMapButton(
  key: const ValueKey('event-builder-new-event-button'),
  onPressed: widget.draftCreationGate.onCreateDraft,
  variant: PokeMapButtonVariant.secondary,
  size: PokeMapButtonSize.medium,
  leading: const Icon(CupertinoIcons.plus),
  child: const Text('Nouvel événement'),
),
PokeMapBadge(
  label: widget.draftCreationGate.readyLabel,
  variant: widget.draftCreationGate.canCreate
      ? PokeMapBadgeVariant.success
      : PokeMapBadgeVariant.warning,
  icon: Icon(widget.draftCreationGate.canCreate
      ? CupertinoIcons.checkmark_circle
      : CupertinoIcons.location),
),
```

### Notice position

```dart
class _DraftCreationGateNotice extends StatelessWidget {
  const _DraftCreationGateNotice({required this.gate});

  final EventBuilderDraftCreationGate gate;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return PokeMapPanel(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            CupertinoIcons.location,
            color: colors.warning,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              gate.disabledReason ??
                  'Sélectionnez une position sur la carte pour créer un événement.',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

### Tests ajoutés

```dart
testWidgets(
    'NS-EVENT-07 keeps draft creation blocked without explicit position',
    (tester) async {
  await _pumpWorkspace(
    tester,
    buildEventBuilderReadModel(
      events: const [],
      mapId: 'map_port',
      mapTitle: 'Port Selbrume',
    ),
  );

  expect(find.byKey(const ValueKey('event-builder-new-event-button')),
      findsOneWidget);
  expect(find.text('Nouvel événement'), findsWidgets);
  expect(find.text('Position requise'), findsOneWidget);
  expect(
    find.text(
        'Sélectionnez une position sur la carte pour créer un événement.'),
    findsWidgets,
  );

  await tester
      .tap(find.byKey(const ValueKey('event-builder-new-event-button')));
  await tester.pumpAndSettle();

  expect(find.byKey(const ValueKey('event-builder-event-list')), findsNothing);
  expect(find.text('Brouillon'), findsNothing);
  expect(find.textContaining('0,0'), findsNothing);
  expect(find.textContaining('0, 0'), findsNothing);
});

testWidgets('NS-EVENT-07 calls the creation entry only when gate is ready',
    (tester) async {
  var calls = 0;
  await _pumpWorkspace(
    tester,
    buildEventBuilderReadModel(
      events: const [],
      mapId: 'map_port',
      mapTitle: 'Port Selbrume',
    ),
    draftCreationGate: EventBuilderDraftCreationGate.enabled(
      onCreateDraft: () => calls++,
    ),
  );

  expect(find.text('Position prête'), findsOneWidget);
  await tester
      .tap(find.byKey(const ValueKey('event-builder-new-event-button')));
  await tester.pumpAndSettle();

  expect(calls, 1);
});
```

## Tests RED

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact test/event_builder_workspace_test.dart --name "NS-EVENT-07"
```

Sortie utile :

```text
test/event_builder_workspace_test.dart:416:3: Error: Type 'EventBuilderDraftCreationGate' not found.
test/event_builder_workspace_test.dart:235:26: Error: Undefined name 'EventBuilderDraftCreationGate'.
test/event_builder_workspace_test.dart:438:15: Error: No named parameter with the name 'draftCreationGate'.
Some tests failed.
```

## Tests GREEN et validations

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact test/event_builder_workspace_test.dart --name "NS-EVENT-07"
```

Résultat :

```text
All tests passed!
```

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact test/event_builder_workspace_test.dart
```

Résultat :

```text
All tests passed!
```

Commande :

```bash
cd packages/map_core
dart test --reporter=compact test/event_builder_contract_test.dart test/event_builder_authoring_operations_test.dart test/event_builder_read_model_test.dart test/event_builder_draft_creation_operations_test.dart
```

Résultat :

```text
All tests passed!
```

Commande :

```bash
cd packages/map_editor
flutter analyze --no-fatal-infos lib/src/ui/canvas/events/event_builder_workspace.dart test/event_builder_workspace_test.dart
```

Résultat :

```text
No issues found! (ran in 2.8s)
```

Commandes non lancées :

- `test/ui/canvas/narrative_overview_shell_navigation_test.dart` : non lancé, la navigation/shell Narrative Studio n'a pas été modifiée.
- `flutter build macos --debug` : non lancé, le lot ne touche ni shell app, ni runtime, ni intégration macOS ; la validation ciblée widget/analyze est plus pertinente.

## Visual Gate

Commande :

```bash
cd packages/map_editor
flutter test --update-goldens --dart-define=NS_EVENT_07_CAPTURE_WORKSPACE=true --reporter=compact test/event_builder_workspace_test.dart --name "captures NS-EVENT-07"
```

Résultat :

```text
All tests passed!
```

Capture :

```text
reports/narrativeStudio/events/screenshots/ns_event_07_draft_creation_ui_gate_v0.png
```

Preuves fichier :

```text
-rw-r--r--  1 karim  staff    51K Jun 17 15:55 reports/narrativeStudio/events/screenshots/ns_event_07_draft_creation_ui_gate_v0.png
reports/narrativeStudio/events/screenshots/ns_event_07_draft_creation_ui_gate_v0.png: PNG image data, 1280 x 820, 8-bit/color RGBA, non-interlaced
0b5ce7630929d6527af37485208ad2bbdf89d83f2fedfd5bdf6b2fd167637181  reports/narrativeStudio/events/screenshots/ns_event_07_draft_creation_ui_gate_v0.png
```

## Anti-scope

Respecté :

- aucun `packages/map_runtime` ;
- aucun `packages/map_gameplay` ;
- aucun `packages/map_battle` ;
- aucun `examples` ;
- aucun `assets` ;
- aucun `selbrume` ;
- aucun `pubspec.yaml` ;
- aucun runtime ;
- aucun Flame ;
- aucun GameState ;
- aucun build_runner ;
- aucun fichier généré.

Commandes finales :

```bash
git diff --check
```

Sortie :

```text
<vide>
```

```bash
git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle examples assets selbrume pubspec.yaml
```

Sortie :

```text
<vide>
```

```bash
find reports/narrativeStudio/events/screenshots -maxdepth 1 -name '*event_07*' -print
find reports/narrativeStudio/events/screenshots -maxdepth 1 -name '*event_08*' -print
```

Sortie :

```text
reports/narrativeStudio/events/screenshots/ns_event_07_draft_creation_ui_gate_v0.png
<vide>
```

État git final :

```text
 M packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart
 M packages/map_editor/test/event_builder_workspace_test.dart
?? reports/narrativeStudio/events/ns_event_07_draft_creation_ui_entry_explicit_position_gate_v0.md
?? reports/narrativeStudio/events/screenshots/ns_event_07_draft_creation_ui_gate_v0.png
```

`git diff --stat` final :

```text
 .../ui/canvas/events/event_builder_workspace.dart  | 106 ++++++++++++++--
 .../test/event_builder_workspace_test.dart         | 139 +++++++++++++++++++--
 2 files changed, 230 insertions(+), 15 deletions(-)
```

`git diff --name-only` final :

```text
packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart
packages/map_editor/test/event_builder_workspace_test.dart
```

## Limites restantes

La création réelle reste bloquée tant qu'il n'existe pas une sélection stable de position de création d'événement dans l'éditeur.

Il faudra un lot futur qui ajoute explicitement :

- un mode de sélection de position événement ;
- une position `GridPos` persistée temporairement dans l'état d'authoring ;
- une validation de couche authorable ;
- puis seulement le branchement vers `createEventBuilderDraftEventOnMap(...)`.

## Impact NS-EVENT-08

NS-EVENT-08 devrait traiter le vrai “position picking” ou l'intégration de création si et seulement si la position explicite existe.

Recommandation :

```text
NS-EVENT-08 — Event Builder Explicit Position Picker / Map Selection Gate V0
```

Non-objectif recommandé pour NS-EVENT-08 : ne pas encore éditer trigger/conditions/actions.

## Auto-critique finale

Le lot est volontairement conservateur. Il n'apporte pas la création réelle, mais c'est la bonne décision car le contexte sûr n'existe pas encore. Brancher `hoveredTile` aurait donné une UX instable et difficile à expliquer. Réutiliser `addMapEventAt` aurait contredit le contrat NS-EVENT-06 à cause du fallback de layer.

La capture Visual Gate montre le message et le badge de gate. Le rendu de certains textes de bouton dans le moteur de golden test est moins lisible que l'app réelle, mais le message principal et le badge `Position requise` sont visibles.

## Critique du prompt

Le prompt est sain sur le fond : il force à ne pas inventer de coordonnées. Le point délicat est qu'il prévoit deux issues possibles, création réelle ou gate bloqué. Le repo actuel pousse clairement vers la deuxième issue.

La prochaine étape ne devrait pas être un éditeur complet d'événement. Elle devrait fermer le gap de position explicite, sinon chaque lot suivant risque d'être tenté d'utiliser un contexte implicite.
