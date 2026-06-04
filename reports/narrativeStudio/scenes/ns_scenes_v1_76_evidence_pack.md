# NS-SCENES-V1-76 — Evidence Pack

## Gate 0

Commande :

```bash
pwd && git branch --show-current && git status --short --untracked-files=all && git diff --stat && git diff --name-only && git log --oneline -n 15
```

Sortie :

```text
/Users/karim/Project/pokemonProject
main
bea04114 feat(narrative): add cinematic map entity event source audit picker prep contract (NS-SCENES-V1-75)
fe619092 feat(narrative): add cinematic stage map context editor and diagnostics preview readiness polish v0 (NS-SCENES-V1-73-V1-74)
632e3747 feat(narrative): add cinematic stage map context core model v0 (NS-SCENES-V1-72)
e77212ff feat(narrative): add cinematic stage map context prep contract (NS-SCENES-V1-71)
edf3d1bd feat(narrative): add cinematic timeline duration validation diagnostics polish v0 (NS-SCENES-V1-70)
875404af feat(narrative): add cinematic timeline duration resize handles v0 (NS-SCENES-V1-69)
263233b4 feat(narrative): add cinematic timeline duration inspector editing v0 (NS-SCENES-V1-68)
c8bb19a2 feat(narrative): add cinematic timeline duration editing resize prep contract (NS-SCENES-V1-67)
e67e71c7 feat(narrative): add cinematic timeline mouse probe help selection explanation v0 (NS-SCENES-V1-66)
46cc0eb4 feat(narrative): add cinematic timeline mouse probe UX polish clear controls v0 (NS-SCENES-V1-65)
95e79063 feat(narrative): add cinematic timeline mouse probe boundary snap v0 (NS-SCENES-V1-64)
86004392 feat(narrative): add cinematic timeline mouse probe polish boundary snap prep v0 (NS-SCENES-V1-63)
79414165 feat(narrative): add cinematic timeline mouse time probe playhead drag v0 (NS-SCENES-V1-62)
044155fc feat(narrative): add cinematic timeline mouse playhead scrub prep contract (NS-SCENES-V1-61)
32f92c54 feat(narrative): add cinematic timeline keyboard navigation polish help overlay v0 (NS-SCENES-V1-60)
```

`git status`, `git diff --stat` et `git diff --name-only` etaient vides.

## RED test output

Commande :

```bash
cd packages/map_core && dart test --reporter=compact test/cinematic_stage_map_source_catalog_test.dart
```

Sortie :

```text
Failed to load "test/cinematic_stage_map_source_catalog_test.dart":
test/cinematic_stage_map_source_catalog_test.dart:7:23: Error: Method not found: 'buildCinematicStageMapSourceCatalog'.
test/cinematic_stage_map_source_catalog_test.dart:37:30: Error: Undefined name 'CinematicStageMapSourceCatalogStatus'.
test/cinematic_stage_map_source_catalog_test.dart:84:9: Error: Undefined name 'CinematicStageMapSourceDiagnosticCode'.
Some tests failed.
```

Le RED est valide : le test echoue parce que le catalogue n'existe pas encore.

## GREEN test output

Commande :

```bash
cd packages/map_core && dart test --reporter=compact test/cinematic_stage_map_source_catalog_test.dart
```

Sortie :

```text
00:00 +0: loading test/cinematic_stage_map_source_catalog_test.dart
00:00 +0: CinematicStageMapSourceCatalog builds cinematic stage map source catalog from real map data
00:00 +1: CinematicStageMapSourceCatalog returns missing stage map status without stage map
00:00 +2: CinematicStageMapSourceCatalog returns unavailable status without map data
00:00 +3: CinematicStageMapSourceCatalog returns map id mismatch status when map data does not match stage map
00:00 +4: CinematicStageMapSourceCatalog uses entity id as fallback label only when no better label exists
00:00 +5: CinematicStageMapSourceCatalog uses event id as fallback label only when title is empty
00:00 +6: CinematicStageMapSourceCatalog handles empty entity and event lists
00:00 +7: All tests passed!
```

## Nouveau fichier : cinematic_stage_map_source_catalog.dart

```dart
import 'package:meta/meta.dart' show immutable;

import '../models/enums.dart';
import '../models/map_data.dart';
import '../models/map_event_definition.dart';
import '../models/project_manifest.dart';

enum CinematicStageMapSourceCatalogStatus {
  missingStageMap,
  mapDataUnavailable,
  mapIdMismatch,
  available,
}

enum CinematicStageMapSourceDiagnosticCode {
  stageMapMissing,
  stageMapDataUnavailable,
  stageMapDataIdMismatch,
  stageMapHasNoEntities,
  stageMapHasNoEvents,
  entityMissingLabelFallbackToId,
  eventMissingTitleFallbackToId,
}

@immutable
final class CinematicStageMapSourceDiagnostic {
  const CinematicStageMapSourceDiagnostic({
    required this.code,
    required this.message,
    this.sourceId,
  });

  final CinematicStageMapSourceDiagnosticCode code;
  final String message;
  final String? sourceId;
}

@immutable
final class CinematicStageMapSourceCatalog {
  CinematicStageMapSourceCatalog({
    required this.status,
    required this.stageMapId,
    required this.stageMapLabel,
    required this.stageMapRelativePath,
    required this.mapDataId,
    required List<CinematicStageMapEntitySource> entities,
    required List<CinematicStageMapEventSource> events,
    required List<CinematicStageMapSourceDiagnostic> diagnostics,
  })  : entities = List<CinematicStageMapEntitySource>.unmodifiable(entities),
        events = List<CinematicStageMapEventSource>.unmodifiable(events),
        diagnostics =
            List<CinematicStageMapSourceDiagnostic>.unmodifiable(diagnostics);

  final CinematicStageMapSourceCatalogStatus status;
  final String? stageMapId;
  final String? stageMapLabel;
  final String? stageMapRelativePath;
  final String? mapDataId;
  final List<CinematicStageMapEntitySource> entities;
  final List<CinematicStageMapEventSource> events;
  final List<CinematicStageMapSourceDiagnostic> diagnostics;

  bool get isAvailable =>
      status == CinematicStageMapSourceCatalogStatus.available;

  CinematicStageMapEntitySource? entityById(String entityId) {
    final normalizedId = entityId.trim();
    for (final entity in entities) {
      if (entity.id == normalizedId) {
        return entity;
      }
    }
    return null;
  }

  CinematicStageMapEventSource? eventById(String eventId) {
    final normalizedId = eventId.trim();
    for (final event in events) {
      if (event.id == normalizedId) {
        return event;
      }
    }
    return null;
  }
}

@immutable
final class CinematicStageMapEntitySource {
  CinematicStageMapEntitySource({
    required this.id,
    required this.label,
    required this.secondaryLabel,
    required this.kindLabel,
    required this.canBindActor,
    required this.canBeMovementTarget,
    required this.positionSummary,
    required List<CinematicStageMapSourceDiagnostic> diagnostics,
  }) : diagnostics =
            List<CinematicStageMapSourceDiagnostic>.unmodifiable(diagnostics);

  final String id;
  final String label;
  final String secondaryLabel;
  final String kindLabel;
  final bool canBindActor;
  final bool canBeMovementTarget;
  final String positionSummary;
  final List<CinematicStageMapSourceDiagnostic> diagnostics;
}

@immutable
final class CinematicStageMapEventSource {
  CinematicStageMapEventSource({
    required this.id,
    required this.label,
    required this.secondaryLabel,
    required this.kindLabel,
    required this.canBeMovementTarget,
    required this.positionSummary,
    required List<CinematicStageMapSourceDiagnostic> diagnostics,
  }) : diagnostics =
            List<CinematicStageMapSourceDiagnostic>.unmodifiable(diagnostics);

  final String id;
  final String label;
  final String secondaryLabel;
  final String kindLabel;
  bool get canBindActor => false;
  final bool canBeMovementTarget;
  final String positionSummary;
  final List<CinematicStageMapSourceDiagnostic> diagnostics;
}

CinematicStageMapSourceCatalog buildCinematicStageMapSourceCatalog({
  required ProjectMapEntry? stageMap,
  required MapData? mapData,
}) {
  if (stageMap == null) {
    return CinematicStageMapSourceCatalog(
      status: CinematicStageMapSourceCatalogStatus.missingStageMap,
      stageMapId: null,
      stageMapLabel: null,
      stageMapRelativePath: null,
      mapDataId: mapData?._normalizedId,
      entities: const [],
      events: const [],
      diagnostics: const [
        CinematicStageMapSourceDiagnostic(
          code: CinematicStageMapSourceDiagnosticCode.stageMapMissing,
          message: 'Aucune map de scene selectionnee.',
        ),
      ],
    );
  }

  final stageMapId = stageMap._normalizedId;
  final stageMapLabel = _labelOrId(stageMap.name, stageMapId);
  final stageMapRelativePath = stageMap.relativePath.trim();

  if (mapData == null) {
    return CinematicStageMapSourceCatalog(
      status: CinematicStageMapSourceCatalogStatus.mapDataUnavailable,
      stageMapId: stageMapId,
      stageMapLabel: stageMapLabel,
      stageMapRelativePath: stageMapRelativePath,
      mapDataId: null,
      entities: const [],
      events: const [],
      diagnostics: const [
        CinematicStageMapSourceDiagnostic(
          code: CinematicStageMapSourceDiagnosticCode.stageMapDataUnavailable,
          message: 'La MapData de la map de scene est indisponible.',
        ),
      ],
    );
  }

  final mapDataId = mapData._normalizedId;
  if (mapDataId != stageMapId) {
    return CinematicStageMapSourceCatalog(
      status: CinematicStageMapSourceCatalogStatus.mapIdMismatch,
      stageMapId: stageMapId,
      stageMapLabel: stageMapLabel,
      stageMapRelativePath: stageMapRelativePath,
      mapDataId: mapDataId,
      entities: const [],
      events: const [],
      diagnostics: [
        CinematicStageMapSourceDiagnostic(
          code: CinematicStageMapSourceDiagnosticCode.stageMapDataIdMismatch,
          message:
              'La MapData "$mapDataId" ne correspond pas a la map "$stageMapId".',
        ),
      ],
    );
  }

  final diagnostics = <CinematicStageMapSourceDiagnostic>[];
  final entities = <CinematicStageMapEntitySource>[];
  final events = <CinematicStageMapEventSource>[];

  if (mapData.entities.isEmpty) {
    diagnostics.add(
      const CinematicStageMapSourceDiagnostic(
        code: CinematicStageMapSourceDiagnosticCode.stageMapHasNoEntities,
        message: 'La map de scene ne contient aucune entite.',
      ),
    );
  } else {
    for (final entity in mapData.entities) {
      final source = _buildEntitySource(
        mapId: stageMapId,
        entity: entity,
      );
      entities.add(source);
      diagnostics.addAll(source.diagnostics);
    }
  }

  if (mapData.events.isEmpty) {
    diagnostics.add(
      const CinematicStageMapSourceDiagnostic(
        code: CinematicStageMapSourceDiagnosticCode.stageMapHasNoEvents,
        message: 'La map de scene ne contient aucun event.',
      ),
    );
  } else {
    for (final event in mapData.events) {
      final source = _buildEventSource(
        mapId: stageMapId,
        event: event,
      );
      events.add(source);
      diagnostics.addAll(source.diagnostics);
    }
  }

  return CinematicStageMapSourceCatalog(
    status: CinematicStageMapSourceCatalogStatus.available,
    stageMapId: stageMapId,
    stageMapLabel: stageMapLabel,
    stageMapRelativePath: stageMapRelativePath,
    mapDataId: mapDataId,
    entities: entities,
    events: events,
    diagnostics: diagnostics,
  );
}

CinematicStageMapEntitySource _buildEntitySource({
  required String mapId,
  required MapEntity entity,
}) {
  final entityId = entity._normalizedId;
  final label = _entityLabel(entity);
  final diagnostics = <CinematicStageMapSourceDiagnostic>[];
  if (label == entityId) {
    diagnostics.add(
      CinematicStageMapSourceDiagnostic(
        code: CinematicStageMapSourceDiagnosticCode
            .entityMissingLabelFallbackToId,
        message: 'L entite "$entityId" utilise son id comme libelle.',
        sourceId: entityId,
      ),
    );
  }

  return CinematicStageMapEntitySource(
    id: entityId,
    label: label,
    secondaryLabel: '$mapId:$entityId',
    kindLabel: _entityKindLabel(entity.kind),
    canBindActor: entity.kind == MapEntityKind.npc || entity.npc != null,
    canBeMovementTarget: true,
    positionSummary: _gridPositionSummary(entity.pos.x, entity.pos.y),
    diagnostics: diagnostics,
  );
}

CinematicStageMapEventSource _buildEventSource({
  required String mapId,
  required MapEventDefinition event,
}) {
  final eventId = event._normalizedId;
  final label = _labelOrId(event.title, eventId);
  final diagnostics = <CinematicStageMapSourceDiagnostic>[];
  if (label == eventId) {
    diagnostics.add(
      CinematicStageMapSourceDiagnostic(
        code:
            CinematicStageMapSourceDiagnosticCode.eventMissingTitleFallbackToId,
        message: 'L event "$eventId" utilise son id comme libelle.',
        sourceId: eventId,
      ),
    );
  }

  return CinematicStageMapEventSource(
    id: eventId,
    label: label,
    secondaryLabel: '$mapId:$eventId',
    kindLabel: _eventKindLabel(event.type),
    canBeMovementTarget: true,
    positionSummary: _gridPositionSummary(event.position.x, event.position.y),
    diagnostics: diagnostics,
  );
}

String _entityLabel(MapEntity entity) {
  switch (entity.kind) {
    case MapEntityKind.npc:
      final displayName = entity.npc?.displayName.trim();
      if (displayName != null && displayName.isNotEmpty) {
        return displayName;
      }
    case MapEntityKind.sign:
      final title = entity.sign?.title.trim();
      if (title != null && title.isNotEmpty) {
        return title;
      }
    case MapEntityKind.item:
      final gameItemId = entity.item?.gameItemId.trim();
      if (gameItemId != null && gameItemId.isNotEmpty) {
        return gameItemId;
      }
    case MapEntityKind.spawn:
      final spawnKey = entity.spawn?.spawnKey.trim();
      if (spawnKey != null && spawnKey.isNotEmpty) {
        return spawnKey;
      }
    case MapEntityKind.custom:
      break;
  }

  return _labelOrId(entity.name, entity._normalizedId);
}

String _entityKindLabel(MapEntityKind kind) {
  return switch (kind) {
    MapEntityKind.npc => 'PNJ',
    MapEntityKind.sign => 'Panneau',
    MapEntityKind.item => 'Objet',
    MapEntityKind.spawn => 'Spawn',
    MapEntityKind.custom => 'Custom',
  };
}

String _eventKindLabel(MapEventType type) {
  return switch (type) {
    MapEventType.actor => 'Acteur event',
    MapEventType.object => 'Objet event',
    MapEventType.triggerZone => 'Zone trigger',
    MapEventType.effect => 'Effet',
  };
}

String _gridPositionSummary(int x, int y) => 'Tuile $x, $y';

String _labelOrId(String label, String id) {
  final trimmedLabel = label.trim();
  return trimmedLabel.isEmpty ? id : trimmedLabel;
}

extension on ProjectMapEntry {
  String get _normalizedId => id.trim();
}

extension on MapData {
  String get _normalizedId => id.trim();
}

extension on MapEntity {
  String get _normalizedId => id.trim();
}

extension on MapEventDefinition {
  String get _normalizedId => id.trim();
}
```

## Nouveau fichier : cinematic_stage_map_source_catalog_test.dart

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('CinematicStageMapSourceCatalog', () {
    test('builds cinematic stage map source catalog from real map data', () {
      final catalog = buildCinematicStageMapSourceCatalog(
        stageMap: _stageMap(),
        mapData: _mapData(
          entities: const [
            MapEntity(
              id: 'entity_professor',
              kind: MapEntityKind.npc,
              pos: GridPos(x: 4, y: 6),
              npc: MapEntityNpcData(displayName: 'Professor Willow'),
            ),
            MapEntity(
              id: 'entity_notice',
              name: 'Notice board',
              kind: MapEntityKind.sign,
              pos: GridPos(x: 7, y: 2),
              sign: MapEntitySignData(title: 'Daily notice'),
            ),
          ],
          events: const [
            MapEventDefinition(
              id: 'event_arrival',
              title: 'Arrival trigger',
              position: EventPosition(layerId: 'ground', x: 9, y: 3),
              pages: [MapEventPage(pageNumber: 0)],
              type: MapEventType.triggerZone,
            ),
          ],
        ),
      );

      expect(catalog.status, CinematicStageMapSourceCatalogStatus.available);
      expect(catalog.stageMapId, 'map_lab');
      expect(catalog.stageMapLabel, 'Research Lab');
      expect(catalog.entities, hasLength(2));
      expect(catalog.events, hasLength(1));

      final npc = catalog.entityById('entity_professor');
      expect(npc, isNotNull);
      expect(npc!.label, 'Professor Willow');
      expect(npc.secondaryLabel, 'map_lab:entity_professor');
      expect(npc.kindLabel, 'PNJ');
      expect(npc.canBindActor, isTrue);
      expect(npc.canBeMovementTarget, isTrue);
      expect(npc.positionSummary, 'Tuile 4, 6');
      expect(npc.diagnostics, isEmpty);

      final sign = catalog.entityById('entity_notice');
      expect(sign, isNotNull);
      expect(sign!.label, 'Daily notice');
      expect(sign.secondaryLabel, 'map_lab:entity_notice');
      expect(sign.kindLabel, 'Panneau');
      expect(sign.canBindActor, isFalse);
      expect(sign.canBeMovementTarget, isTrue);

      final event = catalog.eventById('event_arrival');
      expect(event, isNotNull);
      expect(event!.label, 'Arrival trigger');
      expect(event.secondaryLabel, 'map_lab:event_arrival');
      expect(event.kindLabel, 'Zone trigger');
      expect(event.canBindActor, isFalse);
      expect(event.canBeMovementTarget, isTrue);
      expect(event.positionSummary, 'Tuile 9, 3');
    });

    test('returns missing stage map status without stage map', () {
      final catalog = buildCinematicStageMapSourceCatalog(
        stageMap: null,
        mapData: _mapData(),
      );

      expect(
        catalog.status,
        CinematicStageMapSourceCatalogStatus.missingStageMap,
      );
      expect(catalog.entities, isEmpty);
      expect(catalog.events, isEmpty);
      expect(catalog.diagnostics.map((diagnostic) => diagnostic.code), [
        CinematicStageMapSourceDiagnosticCode.stageMapMissing,
      ]);
    });

    test('returns unavailable status without map data', () {
      final catalog = buildCinematicStageMapSourceCatalog(
        stageMap: _stageMap(),
        mapData: null,
      );

      expect(
        catalog.status,
        CinematicStageMapSourceCatalogStatus.mapDataUnavailable,
      );
      expect(catalog.stageMapId, 'map_lab');
      expect(catalog.entities, isEmpty);
      expect(catalog.events, isEmpty);
      expect(catalog.diagnostics.map((diagnostic) => diagnostic.code), [
        CinematicStageMapSourceDiagnosticCode.stageMapDataUnavailable,
      ]);
    });

    test(
        'returns map id mismatch status when map data does not match stage map',
        () {
      final catalog = buildCinematicStageMapSourceCatalog(
        stageMap: _stageMap(),
        mapData: _mapData(id: 'map_other'),
      );

      expect(
        catalog.status,
        CinematicStageMapSourceCatalogStatus.mapIdMismatch,
      );
      expect(catalog.entities, isEmpty);
      expect(catalog.events, isEmpty);
      expect(catalog.diagnostics.map((diagnostic) => diagnostic.code), [
        CinematicStageMapSourceDiagnosticCode.stageMapDataIdMismatch,
      ]);
    });

    test('uses entity id as fallback label only when no better label exists',
        () {
      final catalog = buildCinematicStageMapSourceCatalog(
        stageMap: _stageMap(),
        mapData: _mapData(
          entities: const [
            MapEntity(
              id: 'entity_custom_fallback',
              kind: MapEntityKind.custom,
              pos: GridPos(x: 1, y: 1),
            ),
          ],
        ),
      );

      final entity = catalog.entityById('entity_custom_fallback');
      expect(entity, isNotNull);
      expect(entity!.label, 'entity_custom_fallback');
      expect(entity.diagnostics.map((diagnostic) => diagnostic.code), [
        CinematicStageMapSourceDiagnosticCode.entityMissingLabelFallbackToId,
      ]);
      expect(
        catalog.diagnostics.map((diagnostic) => diagnostic.code),
        contains(CinematicStageMapSourceDiagnosticCode.stageMapHasNoEvents),
      );
      expect(
        catalog.diagnostics.map((diagnostic) => diagnostic.code),
        contains(
          CinematicStageMapSourceDiagnosticCode.entityMissingLabelFallbackToId,
        ),
      );
    });

    test('uses event id as fallback label only when title is empty', () {
      final catalog = buildCinematicStageMapSourceCatalog(
        stageMap: _stageMap(),
        mapData: _mapData(
          events: const [
            MapEventDefinition(
              id: 'event_without_title',
              position: EventPosition(layerId: 'ground', x: 3, y: 5),
              pages: [MapEventPage(pageNumber: 0)],
            ),
          ],
        ),
      );

      final event = catalog.eventById('event_without_title');
      expect(event, isNotNull);
      expect(event!.label, 'event_without_title');
      expect(event.diagnostics.map((diagnostic) => diagnostic.code), [
        CinematicStageMapSourceDiagnosticCode.eventMissingTitleFallbackToId,
      ]);
      expect(
        catalog.diagnostics.map((diagnostic) => diagnostic.code),
        contains(CinematicStageMapSourceDiagnosticCode.stageMapHasNoEntities),
      );
      expect(
        catalog.diagnostics.map((diagnostic) => diagnostic.code),
        contains(
          CinematicStageMapSourceDiagnosticCode.eventMissingTitleFallbackToId,
        ),
      );
    });

    test('handles empty entity and event lists', () {
      final catalog = buildCinematicStageMapSourceCatalog(
        stageMap: _stageMap(),
        mapData: _mapData(),
      );

      expect(catalog.status, CinematicStageMapSourceCatalogStatus.available);
      expect(catalog.entities, isEmpty);
      expect(catalog.events, isEmpty);
      expect(catalog.diagnostics.map((diagnostic) => diagnostic.code), [
        CinematicStageMapSourceDiagnosticCode.stageMapHasNoEntities,
        CinematicStageMapSourceDiagnosticCode.stageMapHasNoEvents,
      ]);
    });
  });
}

ProjectMapEntry _stageMap() {
  return const ProjectMapEntry(
    id: 'map_lab',
    name: 'Research Lab',
    relativePath: 'maps/research_lab.json',
  );
}

MapData _mapData({
  String id = 'map_lab',
  List<MapEntity> entities = const [],
  List<MapEventDefinition> events = const [],
}) {
  return MapData(
    id: id,
    name: 'Research Lab',
    size: const GridSize(width: 12, height: 10),
    entities: entities,
    events: events,
  );
}
```

## Hunk export map_core.dart

```diff
 export 'src/read_models/cinematics_library_read_model.dart';
 export 'src/read_models/cinematic_timeline_lane_read_model.dart';
 export 'src/read_models/cinematic_timeline_time_layout_read_model.dart';
+export 'src/read_models/cinematic_stage_map_source_catalog.dart';
 export 'src/read_models/storyline_scene_links_read_model.dart';
```

## Tests core cibles

```text
test/cinematic_asset_test.dart: 00:00 +8: All tests passed!
test/project_manifest_cinematics_test.dart: 00:00 +6: All tests passed!
test/cinematic_authoring_operations_test.dart: 00:00 +37: All tests passed!
test/cinematic_diagnostics_test.dart: 00:00 +24: All tests passed!
```

## Analyze core

```text
Analyzing map_core...
No issues found!
```

## Tests editor cibles

```text
test/cinematic_builder_workspace_test.dart: 00:17 +125: All tests passed!
test/cinematics_library_workspace_test.dart: 00:03 +12: All tests passed!
```

## Analyze editor

Commande :

```bash
cd packages/map_editor && flutter analyze
```

Sortie utile observee :

```text
Analyzing map_editor...
error • The named parameter 'dbSymbol' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:58:7 • undefined_named_parameter
error • The named parameter 'battleEngineAimedTarget' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:64:7 • undefined_named_parameter
error • The method 'fetchPokemonSdkStudioProjectPayload' isn't defined for the type 'PokemonExternalSourceRepository' • lib/src/application/use_cases/sync_pokemon_sdk_moves_catalog_use_case.dart:58:10 • undefined_method
344 issues found. (ran in 3.0s)
```

Interpretation : rouge hors lot, aucun fichier `map_editor` modifie.

## Checks finaux

Les sorties ci-dessous correspondent au passage final apres creation des rapports.

### git diff --check

```text
```

### git diff --stat

```text
 packages/map_core/lib/map_core.dart                 |  1 +
 .../scenes/road_map_scene_builder_authoring.md      | 17 ++++++++++++++++-
 reports/narrativeStudio/scenes/road_map_scenes.md   | 21 ++++++++++++++++++---
 3 files changed, 35 insertions(+), 4 deletions(-)
```

### git diff --name-only

```text
packages/map_core/lib/map_core.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

### git status --short --untracked-files=all

```text
 M packages/map_core/lib/map_core.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? packages/map_core/lib/src/read_models/cinematic_stage_map_source_catalog.dart
?? packages/map_core/test/cinematic_stage_map_source_catalog_test.dart
?? reports/narrativeStudio/scenes/ns_scenes_v1_76_cinematic_stage_map_source_catalog_v0.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_76_evidence_pack.md
```

### Anti-scope packages runtime/gameplay/battle/examples

```text
```

### Anti-UI picker code-scope

```text
```

### Anti-runtime/playback code-scope

```text
```

### Anti-pathfinding/runtime map code-scope

```text
packages/map_core/lib/map_core.dart:8:export 'src/models/element_collision_profile.dart';
packages/map_core/lib/map_core.dart:42:export 'src/operations/map_collision.dart';
packages/map_core/lib/map_core.dart:130:export 'src/operations/element_collision_mask_codec.dart';
packages/map_core/lib/map_core.dart:131:export 'src/operations/element_collision_profile_normalizer.dart';
packages/map_core/lib/map_core.dart:132:export 'src/collision/pixel_rect.dart';
packages/map_core/lib/map_core.dart:133:export 'src/collision/player_collision_conventions_v1.dart';
packages/map_core/lib/map_core.dart:154:export 'src/operations/map_entity_collision_footprint.dart';
packages/map_core/lib/map_core.dart:156:export 'src/operations/map_warps.dart';
```

Interpretation : ces lignes sont des exports historiques deja presents dans le barrel `map_core.dart`. Le hunk V1-76 ajoute seulement l'export `cinematic_stage_map_source_catalog.dart`.

Verification sur les hunks ajoutes :

```text
```

### Anti-double mapId code-scope

```text
```

### Anti-ID libre / JSON brut code-scope

```text
packages/map_core/test/cinematic_stage_map_source_catalog_test.dart:211:    relativePath: 'maps/research_lab.json',
```

Interpretation : match benign sur le chemin de fixture `ProjectMapEntry.relativePath`. Aucun `TextField`, ID libre authorable ou JSON brut UI n'est ajoute.

### Anti-coordonnees libres code-scope

```text
```

Interpretation : seule la metadata secondaire `positionSummary` contient une position lisible ; aucun workflow de coordonnees libres n'est ajoute.

### Anti-image IA code-scope

```text
```

### Anti-Selbrume code-scope

```text
```

## Auto-review

- Catalogue pur Dart : oui.
- Charge lui-meme `MapData` : non.
- Depend de `GameState` : non.
- Depend d'un repository : non.
- Depend de Flutter/runtime/editor : non.
- Entites depuis `MapData.entities` : oui.
- Events depuis `MapData.events` : oui.
- Pickers actifs : non.
- UI modifiee : non.
- Preview reelle : non.
- Runtime modifie : non.
- Pathfinding/collision/warp/spawn runtime : non.
- `stageContext.mapId` : non.
- Donnees Selbrume : non.
- Image IA : non.

Prochain lot recommande : `NS-SCENES-V1-77 — Cinematic Stage Map Entity/Event Pickers V0`.
