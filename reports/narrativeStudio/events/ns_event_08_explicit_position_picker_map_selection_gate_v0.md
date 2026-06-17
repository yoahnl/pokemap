# NS-EVENT-08 — Event Builder Explicit Position Picker / Map Selection Gate V0

## 1. Résumé exécutif

Verdict : **DONE**.

Le workspace `Événements` dispose maintenant d’un gate de création de draft basé sur une position explicitement choisie dans une grille de map et sur une couche active strictement validée. La création réelle est branchée via `createEventBuilderDraftEventOnMap(...)` depuis `EditorNotifier.createEventBuilderDraftEventAt(...)`.

Ce lot ne crée pas un éditeur complet d’événement. Il ferme uniquement le verrou : “où voulez-vous créer l’événement ?”.

Points clés :

- aucun usage de `hoveredTile` ;
- aucun fallback `x=0/y=0` ;
- aucun fallback `map.layers.first` ;
- couche valide = couche active existante et authorable comme `ObjectLayer` ;
- création bloquée si position absente ou couche invalide ;
- draft créé avec titre `Nouvel événement`, id généré par `map_core`, page 0 et metadata Event Builder ;
- pas de `sceneTarget`, pas de `script`, pas de `message`, pas de `condition`.

## 2. Audit position/layer existants

### État inspecté

Fichiers lus :

- `packages/map_editor/lib/src/features/editor/state/editor_state.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`
- `packages/map_core/lib/src/authoring/event_builder_draft_creation_operations.dart`
- `packages/map_core/lib/src/operations/map_events.dart`
- `packages/map_core/lib/src/validation/validators.dart`

Commandes/recherches utiles :

```bash
rg -n "hoveredTile|selected.*Tile|selected.*Cell|selected.*Position|activeLayerId|selectedLayer|GridPos|addMapEventAt|MapEvent|EventPosition|placement|cursor|tap.*map|on.*tile|select.*tile" packages/map_editor/lib packages/map_editor/test
rg -n "addMapEventAt|_resolveEventPlacementLayerId|_applyMapMutation|class EditorNotifier" packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
```

Réponses explicites demandées par le prompt :

1. Position authoring stable existante : aucune position stable dédiée au Builder d’événements n’existait. `hoveredTile` est transitoire et `selectedMapEventId` pointe un événement existant, pas une cellule de création.
2. Nouvel état minimal : `GridPos? _selectedDraftPosition` local au `EventBuilderWorkspace`. J’ai évité `EditorState` pour ne pas générer de nouveaux fichiers Freezed/build_runner pour un gate V0 editor-only.
3. Choix du `layerId` : le canvas Narrative Studio transmet `activeLayerId` seulement s’il correspond à une couche existante et authorable (`ObjectLayer`). Sinon le gate reste visible mais bloque la création avec `Couche requise`.
4. Évitement de `hoveredTile` : aucun nouveau code ne lit `EditorState.hoveredTile`.
5. Évitement fallback layer : le nouveau chemin n’appelle pas `addMapEventAt` ni `_resolveEventPlacementLayerId`; il exige un `EventPosition.layerId` explicite, vérifié dans la map active.

## 3. Décision state/UX retenue

Décision : **UI intermédiaire explicite et testable dans le workspace Événements**.

Au lieu de brancher directement le canvas de map, le lot ajoute un picker borné dans `EventBuilderWorkspace` :

- affiche `Position sélectionnée : aucune` ou `Position sélectionnée : x N, y M` ;
- affiche `Couche : <label>` si la couche active est valide ;
- affiche `Couche requise` si la couche active est absente ou non authorable ;
- rend le bouton `Nouvel événement` actif seulement si position + couche sont valides ;
- permet d’effacer la position pour rebloquer la création.

Limite assumée : ce n’est pas encore un mode clic-sur-map. C’est volontairement un gate V0 propre, explicite et vérifiable.

## 4. Position picker ajouté

Zone importante ajoutée dans `packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart` :

```dart
class EventBuilderDraftCreationGate {
  const EventBuilderDraftCreationGate.positionPicker({
    required this.mapId,
    required this.mapWidth,
    required this.mapHeight,
    required this.layerId,
    required this.layerLabel,
    required this.layerValid,
    required this.onCreateDraftAt,
    this.disabledReason =
        'Sélectionnez une position sur la carte pour créer un événement.',
  })  : onCreateDraft = null,
        readyLabel = 'Position requise';

  final String? Function(EventPosition position)? onCreateDraftAt;
  final String? mapId;
  final int? mapWidth;
  final int? mapHeight;
  final String? layerId;
  final String? layerLabel;
  final bool layerValid;

  bool get hasPositionPicker {
    final width = mapWidth;
    final height = mapHeight;
    return mapId != null &&
        width != null &&
        height != null &&
        width > 0 &&
        height > 0;
  }
}
```

Création effective côté widget :

```dart
VoidCallback? get _createDraftAction {
  final gate = widget.draftCreationGate;
  final legacyAction = gate.onCreateDraft;
  if (legacyAction != null) {
    return legacyAction;
  }
  final position = _selectedDraftPosition;
  final layerId = gate.layerId?.trim();
  final create = gate.onCreateDraftAt;
  if (!gate.hasPositionPicker ||
      position == null ||
      layerId == null ||
      layerId.isEmpty ||
      !gate.layerValid ||
      create == null) {
    return null;
  }
  return () {
    final eventId = create(
      EventPosition(layerId: layerId, x: position.x, y: position.y),
    );
    if (eventId != null && eventId.trim().isNotEmpty) {
      setState(() => _selectedEventId = eventId);
    }
  };
}
```

## 5. Layer gate ajouté

Dans `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`, le gate est construit depuis la map active :

```dart
EventBuilderDraftCreationGate _buildEventBuilderDraftCreationGate(
  EditorState editor,
  EditorNotifier editorNotifier,
) {
  final activeMap = editor.activeMap;
  if (activeMap == null) {
    return const EventBuilderDraftCreationGate.disabled(
      disabledReason:
          'Ouvrez une map active pour choisir la position de l’événement.',
    );
  }
  final activeLayerId = editor.activeLayerId?.trim();
  final activeLayer = activeLayerId == null || activeLayerId.isEmpty
      ? null
      : _findMapLayerById(activeMap, activeLayerId);
  final layerIsValid = activeLayer is ObjectLayer;
  final layerId = layerIsValid ? activeLayer.id : activeLayerId;
  final layerLabel = layerIsValid
      ? activeLayer.name
      : activeLayer?.name ?? activeLayerId ?? 'Aucune couche';
  return EventBuilderDraftCreationGate.positionPicker(
    mapId: activeMap.id,
    mapWidth: activeMap.size.width,
    mapHeight: activeMap.size.height,
    layerId: layerId,
    layerLabel: layerLabel,
    layerValid: layerIsValid,
    onCreateDraftAt: (position) {
      return editorNotifier
          .createEventBuilderDraftEventAt(position: position)
          ?.id;
    },
  );
}
```

Option retenue du prompt : **Option A stricte**.

- `activeLayerId` est utilisé uniquement s’il existe dans `activeMap.layers`.
- Il doit être une `ObjectLayer`.
- Aucun fallback vers `map.layers.first`.
- Aucun layer inventé (`events`, `objects`, etc.).

## 6. Création draft branchée

Nouvelle opération editor-side dans `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart` :

```dart
MapEventDefinition? createEventBuilderDraftEventAt({
  required EventPosition position,
}) {
  final map = state.activeMap;
  if (map == null) {
    state = state.copyWith(
      errorMessage: 'Aucune map active pour créer un brouillon d’événement.',
    );
    return null;
  }
  final layerId = position.layerId.trim();
  if (layerId.isEmpty) {
    state = state.copyWith(
      errorMessage: 'Couche de destination obligatoire pour l’événement.',
    );
    return null;
  }
  final layer = _findLayerById(map, layerId);
  if (layer == null) {
    state = state.copyWith(
      errorMessage:
          'Couche de destination introuvable pour l’événement : $layerId',
    );
    return null;
  }
  if (layer is! ObjectLayer) {
    state = state.copyWith(
      errorMessage: 'La couche de destination doit être une couche d’objets.',
    );
    return null;
  }

  try {
    final result = createEventBuilderDraftEventOnMap(
      map,
      title: 'Nouvel événement',
      position: position,
    );
    _applyMapMutation(
      previousMap: map,
      updatedMap: result.updatedMap,
      preferredActiveLayerId: state.activeLayerId,
      preferredSelectedMapEventId: result.createdEvent.id,
      statusMessage: 'Brouillon d’événement créé',
    );
    return result.createdEvent;
  } catch (e) {
    state = state.copyWith(
      errorMessage: 'Impossible de créer le brouillon d’événement : $e',
    );
    return null;
  }
}
```

Note importante : ce chemin s’appuie sur l’opération core `createEventBuilderDraftEventOnMap`, qui valide l’événement via `addMapEventToMap`. Il ne relance pas `MapValidator.validate` sur toute la map, afin de ne pas bloquer la création d’un draft Event Builder à cause d’une dette de layer préexistante hors lot.

## 7. Tests ajoutés/modifiés

Fichier modifié :

- `packages/map_editor/test/event_builder_workspace_test.dart`

Tests ajoutés :

- `NS-EVENT-08 selected explicit position enables draft creation gate`
- `NS-EVENT-08 invalid active layer keeps creation blocked`
- `NS-EVENT-08 clearing explicit position blocks creation again`
- `captures NS-EVENT-08 explicit position picker visual gate`

Fichier créé :

- `packages/map_editor/test/event_builder_draft_creation_notifier_test.dart`

Contenu complet du nouveau fichier :

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';

void main() {
  group('NS-EVENT-08 EditorNotifier draft event creation', () {
    test('creates a draft event from an explicit position and valid layer', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        activeMap: _map(),
        activeLayerId: 'objects',
      );

      final created = notifier.createEventBuilderDraftEventAt(
        position: const EventPosition(layerId: 'objects', x: 2, y: 1),
      );

      final state = container.read(editorNotifierProvider);
      final events = state.activeMap!.events;
      expect(created, isNotNull);
      expect(events.map((event) => event.id), [
        'evt_existing',
        'evt_nouvel_evenement',
      ]);
      expect(state.selectedMapEventId, 'evt_nouvel_evenement');
      expect(state.statusMessage, 'Brouillon d’événement créé');

      final draft = events.last;
      expect(draft.title, 'Nouvel événement');
      expect(
          draft.position, const EventPosition(layerId: 'objects', x: 2, y: 1));
      expect(draft.pages, hasLength(1));
      expect(draft.pages.single.sceneTarget, isNull);
      expect(draft.pages.single.script, isNull);
      expect(draft.pages.single.message, isNull);
      expect(draft.pages.single.condition, isNull);
    });

    test('rejects an invalid layer without falling back to the first layer',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        activeMap: _map(),
        activeLayerId: 'objects',
      );

      final created = notifier.createEventBuilderDraftEventAt(
        position: const EventPosition(layerId: 'missing', x: 1, y: 1),
      );

      final state = container.read(editorNotifierProvider);
      expect(created, isNull);
      expect(
          state.activeMap!.events.map((event) => event.id), ['evt_existing']);
      expect(state.selectedMapEventId, isNull);
      expect(
        state.errorMessage,
        'Couche de destination introuvable pour l’événement : missing',
      );
    });
  });
}

MapData _map() {
  return const MapData(
    id: 'map_port',
    name: 'Port Selbrume',
    size: GridSize(width: 4, height: 3),
    layers: [
      MapLayer.tile(id: 'ground', name: 'Sol'),
      MapLayer.object(id: 'objects', name: 'Objets'),
    ],
    events: [
      MapEventDefinition(
        id: 'evt_existing',
        title: 'Événement existant',
        position: EventPosition(layerId: 'objects', x: 0, y: 0),
        pages: [
          MapEventPage(
            pageNumber: 0,
            sceneTarget: MapEventSceneTarget(sceneId: 'scene_existing'),
          ),
        ],
      ),
    ],
  );
}
```

## 8. Visual Gate

Capture créée :

```text
reports/narrativeStudio/events/screenshots/ns_event_08_explicit_position_picker_v0.png
```

Preuves :

```bash
ls -lh reports/narrativeStudio/events/screenshots/ns_event_08_explicit_position_picker_v0.png
```

Sortie :

```text
-rw-r--r--  1 karim  staff    57K Jun 17 16:54 reports/narrativeStudio/events/screenshots/ns_event_08_explicit_position_picker_v0.png
```

```bash
file reports/narrativeStudio/events/screenshots/ns_event_08_explicit_position_picker_v0.png
```

Sortie :

```text
reports/narrativeStudio/events/screenshots/ns_event_08_explicit_position_picker_v0.png: PNG image data, 1280 x 820, 8-bit/color RGBA, non-interlaced
```

```bash
shasum -a 256 reports/narrativeStudio/events/screenshots/ns_event_08_explicit_position_picker_v0.png
```

Sortie :

```text
9265c9b9fd5e47a1a1f7c624de60ec3cab3919881a7233878e25bf1630e788e4  reports/narrativeStudio/events/screenshots/ns_event_08_explicit_position_picker_v0.png
```

Limite visuelle du harness : les libellés internes de certains `PokeMapButton` restent rendus comme des blocs par le golden test font/test renderer. La capture montre malgré tout le workspace, la position explicitement sélectionnée, la couche validée et le badge `Position prête`.

## 9. Validations exécutées

### RED initial

```bash
cd packages/map_editor
flutter test --reporter=compact test/event_builder_workspace_test.dart --name "NS-EVENT-08"
```

Sortie utile :

```text
test/event_builder_workspace_test.dart:276:56: Error: Member not found: 'EventBuilderDraftCreationGate.positionPicker'.
test/event_builder_workspace_test.dart:320:56: Error: Member not found: 'EventBuilderDraftCreationGate.positionPicker'.
test/event_builder_workspace_test.dart:360:56: Error: Member not found: 'EventBuilderDraftCreationGate.positionPicker'.
Some tests failed.
```

```bash
cd packages/map_editor
flutter test --reporter=compact test/event_builder_draft_creation_notifier_test.dart
```

Sortie utile :

```text
test/event_builder_draft_creation_notifier_test.dart:18:32: Error: The method 'createEventBuilderDraftEventAt' isn't defined for the type 'EditorNotifier'.
test/event_builder_draft_creation_notifier_test.dart:52:32: Error: The method 'createEventBuilderDraftEventAt' isn't defined for the type 'EditorNotifier'.
Some tests failed.
```

### GREEN ciblé

```bash
cd packages/map_editor
flutter test --reporter=compact test/event_builder_workspace_test.dart --name "NS-EVENT-08"
flutter test --reporter=compact test/event_builder_draft_creation_notifier_test.dart
```

Sortie utile :

```text
00:02 +3: All tests passed!
00:02 +2: All tests passed!
```

### Suite widget complète

```bash
cd packages/map_editor
flutter test --reporter=compact test/event_builder_workspace_test.dart
```

Sortie utile :

```text
00:03 +18: All tests passed!
```

### Core regression NS-EVENT-06

```bash
cd packages/map_core
dart test --reporter=compact \
  test/event_builder_contract_test.dart \
  test/event_builder_authoring_operations_test.dart \
  test/event_builder_read_model_test.dart \
  test/event_builder_draft_creation_operations_test.dart
```

Sortie utile :

```text
00:00 +40: All tests passed!
```

### Analyse ciblée

```bash
cd packages/map_editor
flutter analyze --no-fatal-infos \
  lib/src/ui/canvas/events/event_builder_workspace.dart \
  lib/src/ui/canvas/narrative_workspace_canvas.dart \
  lib/src/features/editor/state/editor_notifier.dart \
  test/event_builder_workspace_test.dart \
  test/event_builder_draft_creation_notifier_test.dart
```

Sortie :

```text
Analyzing 5 items...
No issues found! (ran in 1.8s)
```

### Build macOS debug

```bash
cd packages/map_editor
flutter build macos --debug
```

Sortie :

```text
Building macOS application...
✓ Built build/macos/Build/Products/Debug/map_editor.app
```

### Visual Gate generation

```bash
cd packages/map_editor
flutter test --update-goldens --dart-define=NS_EVENT_08_CAPTURE_WORKSPACE=true --reporter=compact test/event_builder_workspace_test.dart --name "captures NS-EVENT-08"
```

Sortie utile :

```text
00:02 +1: All tests passed!
```

### Interdits ciblés

```bash
git diff --unified=0 -- packages/map_editor/lib/src/features/editor/state/editor_notifier.dart packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart | rg -n "hoveredTile|map\\.layers\\.first|addMapEventAt|x:\\s*0|y:\\s*0|layerId\\s*=\\s*'events'" || true
```

Sortie :

```text
<vide>
```

## 10. Non-objectifs respectés

Confirmé :

- pas de `map_runtime` ;
- pas de `map_gameplay` ;
- pas de `map_battle` ;
- pas de `examples` ;
- pas de `assets` ;
- pas de `selbrume` ;
- pas de `pubspec.yaml` ;
- pas de build_runner ;
- pas de fichier généré modifié ;
- pas de commit ;
- pas d’éditeur trigger/condition/action ;
- pas de flow editor ;
- pas de drag/drop.

## 11. Impact sur NS-EVENT-09

NS-EVENT-09 peut partir d’un verrou propre :

- le Builder sait obtenir une position stable ;
- l’UI expose déjà position + layer gate ;
- le notifier crée un vrai draft sélectionné dans la map active ;
- le prochain lot peut commencer à remplacer la grille V0 par une interaction map/cell plus naturelle, ou avancer vers l’édition no-code du draft si ce choix produit est validé.

Recommandation : garder NS-EVENT-09 petit. Deux trajectoires raisonnables :

1. **NS-EVENT-09 — Event Builder Map Cell Selection Integration V0** : brancher la sélection sur la vraie preview map.
2. **NS-EVENT-09 — Event Builder Draft Details Minimal Authoring V0** : éditer seulement titre/statut/source du draft créé, sans conditions/actions.

Le choix dépend de la priorité produit : ergonomie de placement ou premiers champs d’authoring.

## 12. Limites restantes

- Le picker de position est une grille V0 dans le workspace, pas encore un clic direct sur la map.
- La couche authorable retenue est strictement `ObjectLayer`; si le modèle événement doit vivre sur une autre catégorie de layer plus tard, il faudra un contrat dédié.
- La capture golden affiche certains textes de boutons comme blocs à cause du renderer de test, pas du produit réel.
- Le gate ne persiste pas la position dans `EditorState`. C’est voulu pour éviter generated files et garder le lot focalisé.

## 13. Evidence Pack complet

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
<git status initial : vide>
<git diff --stat initial : vide>
<git diff --name-only initial : vide>
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
179cd6aa NS-SCENES-V1-134 — Cinematic Camera Geometry Preview UI V0
28d0e46e NS-SCENES-V1-133 — Cinematic Camera Geometry Playback State V0
d4e0b28b NS-SCENES-V1-132 — Cinematic Camera Target Zoom Editor UI V0
882c2c23 NS-SCENES-V1-131 — Cinematic Camera Target Zoom Core Model V0
```

### Règles lues

- `AGENTS.md`
- `codex_rule.md`
- `agent_rules.md`
- `skills/README.md`
- `skills/test-driven-development/SKILL.md`
- `skills/verification-before-completion/SKILL.md`
- `/Users/karim/.codex/skills/flutter-add-widget-test/SKILL.md`

### Fichiers modifiés

- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`
- `packages/map_editor/test/event_builder_workspace_test.dart`

### Fichiers créés

- `packages/map_editor/test/event_builder_draft_creation_notifier_test.dart`
- `reports/narrativeStudio/events/screenshots/ns_event_08_explicit_position_picker_v0.png`
- `reports/narrativeStudio/events/ns_event_08_explicit_position_picker_map_selection_gate_v0.md`

### Fichiers supprimés

Aucun.

### Diff/stat pré-rapport

```text
.../src/features/editor/state/editor_notifier.dart |  54 ++++
.../ui/canvas/events/event_builder_workspace.dart  | 277 +++++++++++++++++++--
.../src/ui/canvas/narrative_workspace_canvas.dart  |  48 ++++
.../test/event_builder_workspace_test.dart         | 170 ++++++++++++-
4 files changed, 533 insertions(+), 16 deletions(-)
```

Le fichier de test notifier et la capture étaient encore untracked au moment de cette sortie, donc listés dans `git status` plutôt que dans `git diff --stat`.

### Anti-scope

Commande :

```bash
git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle examples/playable_runtime_host assets selbrume pubspec.yaml
```

Sortie :

```text
<vide>
```

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
 M packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
 M packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
 M packages/map_editor/test/event_builder_workspace_test.dart
?? packages/map_editor/test/event_builder_draft_creation_notifier_test.dart
?? reports/narrativeStudio/events/ns_event_08_explicit_position_picker_map_selection_gate_v0.md
?? reports/narrativeStudio/events/screenshots/ns_event_08_explicit_position_picker_v0.png
 .../src/features/editor/state/editor_notifier.dart |  54 ++++
 .../ui/canvas/events/event_builder_workspace.dart  | 277 +++++++++++++++++++--
 .../src/ui/canvas/narrative_workspace_canvas.dart  |  48 ++++
 .../test/event_builder_workspace_test.dart         | 170 ++++++++++++-
 4 files changed, 533 insertions(+), 16 deletions(-)
packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/test/event_builder_workspace_test.dart
<git diff --check : vide>
```

Commande :

```bash
git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle examples assets selbrume pubspec.yaml
```

Sortie :

```text
<vide>
```

## 14. Auto-review critique

Checklist :

- UI ne lit pas `hoveredTile` : OK.
- UI ne génère pas `x=0/y=0` : OK.
- UI ne génère pas d’id : OK, `map_core` le fait.
- Notifier ne passe pas par `addMapEventAt` : OK.
- Pas de fallback `_resolveEventPlacementLayerId` : OK.
- Couche invalide bloquante : OK.
- Position affichée : OK.
- Position réinitialisable : OK.
- Draft sélectionné après création : OK.
- Aucun éditeur complet introduit : OK.
- Tests core NS-EVENT-06 toujours verts : OK.

Critique :

- La grille V0 est moins ergonomique qu’un clic direct sur la map, mais elle est testable, explicite et conforme à l’objectif de verrou.
- Le choix `ObjectLayer` est conservateur ; il faudra confirmer si les événements PokeMap doivent avoir leur propre layer type à terme.
- Le rapport mentionne la limite de rendu des textes de boutons dans la capture, car il s’agit d’un artefact du golden test renderer, pas d’une preuve produit pixel-perfect.
