# NS-EVENT-06 — Event Builder Draft Creation Core Operation V0

## 1. Résumé exécutif

Verdict : `NS-EVENT-06 : DONE`.

Le lot ajoute une opération pure côté `map_core` pour créer un événement draft Event Builder dans une `MapData` existante :

- API publique : `createEventBuilderDraftEventOnMap(...)`.
- Résultat typé : `EventBuilderDraftCreationResult`.
- Création d'un `MapEventDefinition` draft avec page `0`.
- ID stable depuis le titre humain, avec suffixes `_2`, `_3`, etc. en cas de collision.
- Position obligatoire fournie par l'appelant, sans fallback `(0, 0)`.
- Validation déléguée à `addMapEventToMap(...)`.
- Métadonnées Event Builder sur la page : `eventBuilder.schemaVersion=1` et `eventBuilder.reusePolicy`.
- Read model Event Builder capable de voir le draft comme `Brouillon` avec diagnostic `missingSceneAction`.

Le lot n'a pas modifié `map_editor`, `map_runtime`, `map_gameplay`, `map_battle`, `examples`, `assets`, `selbrume` ou `pubspec.yaml`.

## 2. Confirmation du scope

Inclus :

- opération pure de création de draft dans `map_core`;
- tests unitaires ciblés;
- export public dans `map_core.dart`;
- rapport avec preuves.

Exclus et respecté :

- pas d'UI;
- pas de runtime;
- pas de Flame;
- pas de `GameState`;
- pas de modification Selbrume;
- pas de fixture golden slice;
- pas de génération build_runner;
- pas de commit;
- pas de NS-EVENT-07.

## 3. Audit initial

### État Git initial

Commande :

```bash
pwd && git branch --show-current && git status --short --untracked-files=all && git diff --stat && git diff --name-only && git log --oneline -n 20
```

Sortie utile :

```text
/Users/karim/Project/pokemonProject
main
6fe430d9 ns_event_05: Polissage des détails en lecture seule et diagnostics
1a551f41 ns_event_04: Ajout de l'espace de travail pour l'éditeur d'événements en lecture seule
7eed36b2 FG-NS-EVENT-003: Ajout du read model et diagnostics pour le builder d'événements
93b655dd FG-NS-EVENT-002-BIS: Préservation des conditions legacy et corrections dans le builder d'événements
6279df74 Remove legacy Narrative Studio steps entry
f54a8243 FG-NS-EVENT-002: Ajout des contrats et opérations pour le builder d'événements (core + tests)
410be446 FG-NS-EVENT-001: Alignement des contrats existants pour le builder d'événements
```

`git status`, `git diff --stat` et `git diff --name-only` étaient vides au début du lot.

### Fichiers et contrats audités

- `packages/map_core/lib/src/operations/map_events.dart`
  - `addMapEventToMap(...)` normalise l'event puis valide l'id, les bornes et les pages.
  - `_validateEvent(...)` rejette les positions hors map, les pages absentes, les ids vides et les metadata invalides.
- `packages/map_core/lib/src/models/map_event_definition.dart`
  - `MapEventDefinition`, `EventPosition`, `MapEventPage`, `MapEventType`.
- `packages/map_core/lib/src/authoring/event_builder_authoring_operations.dart`
  - `readEventBuilderContractFromMapEvent(...)`.
  - Le contrat Event Builder lit le comportement depuis `MapEventPage.metadata`.
- `packages/map_core/lib/src/authoring/event_builder_contract.dart`
  - `EventBuilderMetadataKeys`.
  - `EventBuilderReusePolicy`.
  - `EventBuilderContractView`.
- `packages/map_core/lib/src/read_models/event_builder_read_model.dart`
  - Un event sans `sceneTarget` est résumé en `draft` avec `missingSceneAction`.
- `packages/map_core/lib/map_core.dart`
  - barrel public à compléter.

### Décisions d'implémentation

- La validation est volontairement déléguée à `addMapEventToMap(...)`, pour éviter un second validateur.
- Les metadata Event Builder sont écrites sur la page, car le contrat existant les lit depuis `MapEventPage.metadata`.
- Le slug helper reste privé au nouveau fichier, car les helpers existants de `scene`, `fact` et `world_rule` sont eux-mêmes privés à leur domaine.
- Le helper privé normalise les accents latins courants afin que `Nouvel événement` produise `evt_nouvel_evenement`.
- Aucun champ `sceneTarget`, `script`, `message` ou `condition` n'est créé par le draft.

## 4. Fichiers modifiés

### Créés

- `packages/map_core/lib/src/authoring/event_builder_draft_creation_operations.dart`
- `packages/map_core/test/event_builder_draft_creation_operations_test.dart`
- `reports/narrativeStudio/events/ns_event_06_event_builder_draft_creation_core_operation_v0.md`

### Modifiés

- `packages/map_core/lib/map_core.dart`

### Supprimés

Aucun.

## 5. Implémentation

### Nouveau fichier : `packages/map_core/lib/src/authoring/event_builder_draft_creation_operations.dart`

```dart
import '../models/map_data.dart';
import '../models/map_event_definition.dart';
import '../operations/map_events.dart';
import 'event_builder_authoring_operations.dart';
import 'event_builder_contract.dart';

/// Résultat atomique de création d'un draft Event Builder sur une map.
///
/// Le lot NS-EVENT-06 doit rester côté `map_core` et retourner à la fois la
/// map immuable mise à jour, l'événement normalisé par les opérations de map,
/// et la vue de contrat Event Builder que l'UI pourra consommer sans relire les
/// metadata brutes.
final class EventBuilderDraftCreationResult {
  const EventBuilderDraftCreationResult({
    required this.updatedMap,
    required this.createdEvent,
    required this.createdContract,
  });

  final MapData updatedMap;
  final MapEventDefinition createdEvent;
  final EventBuilderContractView createdContract;
}

/// Crée un événement de map minimal, valide et lisible comme draft Event Builder.
///
/// Cette opération ne choisit jamais une position par défaut : l'appelant doit
/// fournir une [EventPosition] explicite pour éviter un faux draft placé en
/// `(0, 0)`. La validation des bornes, de l'id et des pages reste déléguée à
/// [addMapEventToMap] afin de ne pas créer un second validateur parallèle.
EventBuilderDraftCreationResult createEventBuilderDraftEventOnMap(
  MapData map, {
  required String title,
  required EventPosition position,
  MapEventType type = MapEventType.actor,
  EventBuilderReusePolicy reusePolicy = EventBuilderReusePolicy.oneShot,
}) {
  final normalizedTitle = _normalizeDraftTitle(title);
  final draftId = _uniqueDraftEventId(
    normalizedTitle,
    map.events.map((event) => event.id),
  );
  final draftEvent = MapEventDefinition(
    id: draftId,
    title: normalizedTitle,
    position: position,
    type: type,
    pages: [
      MapEventPage(
        pageNumber: 0,
        metadata: _eventBuilderDraftMetadata(reusePolicy),
      ),
    ],
  );

  final updatedMap = addMapEventToMap(map, event: draftEvent);
  final createdEvent = findMapEventById(updatedMap, draftId);
  if (createdEvent == null) {
    throw StateError('Created Event Builder draft cannot be found: $draftId');
  }

  return EventBuilderDraftCreationResult(
    updatedMap: updatedMap,
    createdEvent: createdEvent,
    createdContract: readEventBuilderContractFromMapEvent(createdEvent),
  );
}

String _normalizeDraftTitle(String title) {
  final trimmed = title.trim();
  if (trimmed.isEmpty) {
    return 'Nouvel événement';
  }
  return trimmed;
}

Map<String, String> _eventBuilderDraftMetadata(
  EventBuilderReusePolicy reusePolicy,
) {
  return Map<String, String>.unmodifiable({
    EventBuilderMetadataKeys.schemaVersion:
        EventBuilderMetadataKeys.currentSchemaVersion,
    EventBuilderMetadataKeys.reusePolicy: reusePolicy.name,
  });
}

String _uniqueDraftEventId(String title, Iterable<String> existingIds) {
  final slug = _slugifyDraftEventTitle(title);
  final base = 'evt_${slug.isEmpty ? 'nouvel_evenement' : slug}';
  final existing = existingIds.toSet();
  if (!existing.contains(base)) {
    return base;
  }

  var suffix = 2;
  while (existing.contains('${base}_$suffix')) {
    suffix++;
  }
  return '${base}_$suffix';
}

String _slugifyDraftEventTitle(String value) {
  final lower = value.trim().toLowerCase();
  final buffer = StringBuffer();
  var wroteSeparator = false;

  for (final rune in lower.runes) {
    final normalized = _latinAsciiOverride(rune);
    for (final codeUnit in normalized.codeUnits) {
      final isDigit = codeUnit >= 48 && codeUnit <= 57;
      final isAsciiLetter = codeUnit >= 97 && codeUnit <= 122;
      if (isDigit || isAsciiLetter) {
        buffer.writeCharCode(codeUnit);
        wroteSeparator = false;
      } else if (!wroteSeparator && buffer.isNotEmpty) {
        buffer.write('_');
        wroteSeparator = true;
      }
    }
  }

  final slug = buffer.toString();
  return slug.endsWith('_') ? slug.substring(0, slug.length - 1) : slug;
}

String _latinAsciiOverride(int rune) {
  return switch (rune) {
    0x00E0 || 0x00E1 || 0x00E2 || 0x00E3 || 0x00E4 || 0x00E5 => 'a',
    0x00E6 => 'ae',
    0x00E7 => 'c',
    0x00E8 || 0x00E9 || 0x00EA || 0x00EB => 'e',
    0x00EC || 0x00ED || 0x00EE || 0x00EF => 'i',
    0x00F1 => 'n',
    0x00F2 || 0x00F3 || 0x00F4 || 0x00F5 || 0x00F6 || 0x00F8 => 'o',
    0x0153 => 'oe',
    0x00F9 || 0x00FA || 0x00FB || 0x00FC => 'u',
    0x00FD || 0x00FF => 'y',
    _ => String.fromCharCode(rune),
  };
}
```

### Nouveau fichier : `packages/map_core/test/event_builder_draft_creation_operations_test.dart`

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Event Builder draft creation operations', () {
    test('creates a valid draft actor event with page zero', () {
      final result = createEventBuilderDraftEventOnMap(
        _map(),
        title: 'Rencontre rival au port',
        position: const EventPosition(layerId: 'events', x: 2, y: 3),
      );

      final event = result.createdEvent;
      final page = event.pages.single;

      expect(result.updatedMap.events, [event]);
      expect(event.id, 'evt_rencontre_rival_au_port');
      expect(event.title, 'Rencontre rival au port');
      expect(event.type, MapEventType.actor);
      expect(
          event.position, const EventPosition(layerId: 'events', x: 2, y: 3));
      expect(page.pageNumber, 0);
      expect(result.createdContract.source.eventId, event.id);
    });

    test('generates a stable slug id from a human title', () {
      final result = createEventBuilderDraftEventOnMap(
        _map(),
        title: '  Rencontre rival au port  ',
        position: const EventPosition(layerId: 'events', x: 1, y: 1),
      );

      expect(result.createdEvent.id, 'evt_rencontre_rival_au_port');
      expect(result.createdEvent.title, 'Rencontre rival au port');
    });

    test('suffixes the generated id when the base id already exists', () {
      final map = _map(
        events: [
          _event('evt_rencontre_rival_au_port'),
          _event('evt_rencontre_rival_au_port_2'),
        ],
      );

      final result = createEventBuilderDraftEventOnMap(
        map,
        title: 'Rencontre rival au port',
        position: const EventPosition(layerId: 'events', x: 3, y: 4),
      );

      expect(result.createdEvent.id, 'evt_rencontre_rival_au_port_3');
      expect(result.updatedMap.events.map((event) => event.id), [
        'evt_rencontre_rival_au_port',
        'evt_rencontre_rival_au_port_2',
        'evt_rencontre_rival_au_port_3',
      ]);
    });

    test('falls back to a readable title and stable id for blank title', () {
      final result = createEventBuilderDraftEventOnMap(
        _map(),
        title: '   ',
        position: const EventPosition(layerId: 'events', x: 1, y: 2),
      );

      expect(result.createdEvent.title, 'Nouvel événement');
      expect(result.createdEvent.id, 'evt_nouvel_evenement');
    });

    test('normalizes accented title characters before id generation', () {
      final result = createEventBuilderDraftEventOnMap(
        _map(),
        title: 'Événement du phare',
        position: const EventPosition(layerId: 'events', x: 1, y: 2),
      );

      expect(result.createdEvent.id, 'evt_evenement_du_phare');
    });

    test('respects the caller supplied position without defaults', () {
      const position = EventPosition(layerId: 'events', x: 5, y: 6);

      final result = createEventBuilderDraftEventOnMap(
        _map(),
        title: 'Coffre abandonné',
        position: position,
      );

      expect(result.createdEvent.position, position);
    });

    test('propagates map event validation when position is out of bounds', () {
      expect(
        () => createEventBuilderDraftEventOnMap(
          _map(),
          title: 'Sortie carte',
          position: const EventPosition(layerId: 'events', x: 99, y: 1),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('stores one-shot Event Builder metadata by default', () {
      final result = createEventBuilderDraftEventOnMap(
        _map(),
        title: 'Rival au port',
        position: const EventPosition(layerId: 'events', x: 1, y: 1),
      );

      final metadata = result.createdEvent.pages.single.metadata;

      expect(
        metadata[EventBuilderMetadataKeys.schemaVersion],
        EventBuilderMetadataKeys.currentSchemaVersion,
      );
      expect(
        metadata[EventBuilderMetadataKeys.reusePolicy],
        EventBuilderReusePolicy.oneShot.name,
      );
      expect(
        result.createdContract.behavior.reusePolicy,
        EventBuilderReusePolicy.oneShot,
      );
    });

    test('stores reusable Event Builder metadata when requested', () {
      final result = createEventBuilderDraftEventOnMap(
        _map(),
        title: 'Rumeur au comptoir',
        position: const EventPosition(layerId: 'events', x: 1, y: 1),
        reusePolicy: EventBuilderReusePolicy.reusable,
      );

      final metadata = result.createdEvent.pages.single.metadata;

      expect(
        metadata[EventBuilderMetadataKeys.reusePolicy],
        EventBuilderReusePolicy.reusable.name,
      );
      expect(
        result.createdContract.behavior.reusePolicy,
        EventBuilderReusePolicy.reusable,
      );
    });

    test('does not create scene target, script, message or condition', () {
      final result = createEventBuilderDraftEventOnMap(
        _map(),
        title: 'Garde somnolent',
        position: const EventPosition(layerId: 'events', x: 1, y: 1),
      );

      final page = result.createdEvent.pages.single;

      expect(page.sceneTarget, isNull);
      expect(page.script, isNull);
      expect(page.message, isNull);
      expect(page.condition, isNull);
    });

    test('is visible in the read model as draft with missing scene action', () {
      final result = createEventBuilderDraftEventOnMap(
        _map(),
        title: 'Pêcheur en détresse',
        position: const EventPosition(layerId: 'events', x: 1, y: 1),
      );

      final readModel = buildEventBuilderReadModel(
        events: [result.createdEvent],
      );
      final summary = readModel.events.single;

      expect(summary.status, EventBuilderEventStatus.draft);
      expect(summary.statusLabel, 'Brouillon');
      expect(summary.sceneAction.isMissing, isTrue);
      expect(summary.diagnostics.single.kind,
          EventBuilderDiagnosticReadModelKind.missingSceneAction);
    });

    test('preserves existing events unchanged', () {
      final existing = _event(
        'evt_existing',
        title: 'Déjà là',
        page: const MapEventPage(
          pageNumber: 0,
          sceneTarget: MapEventSceneTarget(sceneId: 'scene_existing'),
        ),
      );
      final map = _map(events: [existing]);

      final result = createEventBuilderDraftEventOnMap(
        map,
        title: 'Nouveau draft',
        position: const EventPosition(layerId: 'events', x: 2, y: 2),
      );

      expect(result.updatedMap.events.first, existing);
      expect(result.updatedMap.events, hasLength(2));
    });
  });
}

MapData _map({List<MapEventDefinition> events = const []}) {
  return MapData(
    id: 'map_selbrume',
    name: 'Selbrume',
    size: const GridSize(width: 8, height: 8),
    layers: const [
      MapLayer.tile(id: 'events', name: 'Events', tiles: []),
    ],
    events: events,
  );
}

MapEventDefinition _event(
  String id, {
  String title = 'Existing',
  MapEventPage page = const MapEventPage(pageNumber: 0),
}) {
  return MapEventDefinition(
    id: id,
    title: title,
    position: const EventPosition(layerId: 'events', x: 0, y: 0),
    pages: [page],
  );
}
```

### Modification : `packages/map_core/lib/map_core.dart`

Diff :

```diff
 export 'src/authoring/event_builder_authoring_operations.dart';
 export 'src/authoring/event_builder_contract.dart';
+export 'src/authoring/event_builder_draft_creation_operations.dart';
 export 'src/authoring/narrative_event_source_authoring_operations.dart';
```

## 6. TDD

### RED

Commande :

```bash
cd packages/map_core
dart test --reporter=compact test/event_builder_draft_creation_operations_test.dart
```

Sortie utile exacte :

```text
Failed to load "test/event_builder_draft_creation_operations_test.dart":
test/event_builder_draft_creation_operations_test.dart:7:22: Error: Method not found: 'createEventBuilderDraftEventOnMap'.
      final result = createEventBuilderDraftEventOnMap(
                     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
...
00:00 +0 -1: Some tests failed.
```

Cause de l'échec : API absente, ce qui valide le RED attendu pour le lot.

### GREEN ciblé

Commande :

```bash
cd packages/map_core
dart test --reporter=compact test/event_builder_draft_creation_operations_test.dart
```

Sortie utile exacte :

```text
00:00 +12: All tests passed!
```

## 7. Tests exécutés

### Régressions Event Builder demandées

Commande :

```bash
cd packages/map_core
dart test --reporter=compact test/event_builder_contract_test.dart test/event_builder_authoring_operations_test.dart test/event_builder_read_model_test.dart test/event_builder_draft_creation_operations_test.dart
```

Sortie utile exacte :

```text
00:00 +40: All tests passed!
```

### Suite complète `map_core`

Commande :

```bash
cd packages/map_core
dart test --reporter=compact
```

Sortie utile exacte :

```text
00:06 +2571: All tests passed!
```

Note : la sortie complète de la suite `map_core` contient 2571 tests et est très volumineuse. Le signal utile exact est la fin de commande ci-dessus avec code de sortie `0`.

## 8. Analyse

Commande :

```bash
cd packages/map_core
dart analyze
```

Sortie exacte :

```text
Analyzing map_core...
No issues found!
```

## 9. Build

Build applicatif non applicable : le lot touche uniquement `packages/map_core`, package Dart pur sans cible Flutter/macOS.

Validation alternative exécutée :

- `dart test --reporter=compact` sur tout `map_core`;
- `dart analyze` sur `map_core`.

## 10. Anti-scope

Commandes finales :

```bash
git diff --name-only -- packages/map_editor packages/map_runtime packages/map_gameplay packages/map_battle examples assets selbrume pubspec.yaml
git status --short --untracked-files=all -- packages/map_editor packages/map_runtime packages/map_gameplay packages/map_battle examples assets selbrume pubspec.yaml
git diff --check
```

Sorties exactes :

```text
git diff --name-only -- packages/map_editor packages/map_runtime packages/map_gameplay packages/map_battle examples assets selbrume pubspec.yaml
<vide>

git status --short --untracked-files=all -- packages/map_editor packages/map_runtime packages/map_gameplay packages/map_battle examples assets selbrume pubspec.yaml
<vide>

git diff --check
<vide>
```

Aucune modification volontaire n'a été apportée dans ces chemins.

État Git final utile :

```text
 M packages/map_core/lib/map_core.dart
?? packages/map_core/lib/src/authoring/event_builder_draft_creation_operations.dart
?? packages/map_core/test/event_builder_draft_creation_operations_test.dart
?? reports/narrativeStudio/events/ns_event_06_event_builder_draft_creation_core_operation_v0.md
```

## 11. Passes type sub-agent

### Sub-agent Audit / Architecture

Verdict : OK.

- `MapData` et `MapEventDefinition` fournissent déjà le stockage nécessaire.
- `addMapEventToMap(...)` couvre la validation à réutiliser.
- Le contrat Event Builder lit déjà les metadata `reusePolicy` depuis la page.
- Aucun besoin de modifier le modèle JSON ou de générer du code.

### Sub-agent Implémentation

Verdict : OK.

- L'opération reste pure et immutable.
- Aucun fallback de position n'est inventé.
- Les drafts restent sans action, sans script, sans message et sans condition.
- L'id est déterministe et collision-safe.

### Sub-agent Tests

Verdict : OK.

Les tests couvrent :

- création positive;
- id slugifié;
- collision;
- titre vide;
- accents;
- position fournie;
- position hors bornes;
- metadata one-shot;
- metadata reusable;
- absence de scene/script/message/condition;
- read model draft;
- non-mutation des events existants.

### Sub-agent Build / Validation

Verdict : OK.

- Tests ciblés : pass.
- Régressions Event Builder : pass.
- Suite complète `map_core` : pass.
- Analyse statique : pass.

### Sub-agent Critique finale

Verdict : OK avec limites assumées.

- Le helper de slug reste privé, comme les helpers existants `scene/fact/world_rule`.
- La normalisation d'accents couvre les caractères latins courants, pas une translittération Unicode exhaustive. C'est acceptable pour NS-EVENT-06.
- L'opération ne crée pas de Scene action : le read model signale donc volontairement `missingSceneAction`.
- Aucune UI ne consomme encore cette opération : ce sera le rôle d'un lot ultérieur.

## 12. Limites conservées

- Pas de création de scène liée.
- Pas de conditions.
- Pas de script legacy.
- Pas de message legacy.
- Pas d'édition UI.
- Pas de persistance disque.
- Pas de mutation `ProjectManifest`.
- Pas de modification Selbrume.
- Pas de runtime.

## 13. Risques restants

- Le slug helper est local au domaine Event Builder. Si plusieurs futurs lots ont besoin d'une convention identique, un helper partagé `map_core` pourrait être extrait plus tard, mais ce serait hors scope NS-EVENT-06.
- Le read model affiche le draft comme incomplet, ce qui est voulu : il faudra NS-EVENT-07+ pour connecter l'UI à l'ajout puis l'édition d'action Scene.

## 14. Prochain lot recommandé

Recommandation : continuer avec le prochain lot Event Builder prévu après NS-EVENT-06, probablement l'intégration UI de création de draft ou une opération d'édition de scène selon la roadmap active.

Ne pas démarrer NS-EVENT-07 dans ce lot.

## 15. Auto-critique finale

- Le scope est resté très étroit.
- Les tests prouvent l'opération publique plutôt qu'un helper test-only.
- L'anti-scope runtime/editor reste intact.
- Le rapport inclut le code complet des nouveaux fichiers.
- La seule réserve technique est la translittération volontairement bornée du slug.
