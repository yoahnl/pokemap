import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/narrative_event_authoring_session.dart';
import 'package:map_editor/src/application/models/narrative_event_migration_persistence_models.dart';
import 'package:map_editor/src/application/use_cases/narrative_event_v2_mode_activation_use_case.dart';
import 'package:map_editor/src/infrastructure/repositories/narrative_event_migration_persistence_repository.dart';

import 'support/event_registry_persistence_fixtures.dart';

void main() {
  group('Phase J0 explicit Event V2 mode activation', () {
    test('activates an empty legacy-free project and is idempotent', () async {
      final fixture = await createPersistenceFixture(
        registry: _emptyRegistry(),
        map: _emptyMap(),
      );
      addTearDown(fixture.dispose);
      final useCase = NarrativeEventV2ModeActivationUseCase(
        gateway: NarrativeEventMigrationPersistenceRepository(),
      );

      final first = await useCase.activate(fixture.projectPath);
      expect(
        first.status,
        NarrativeEventMigrationPersistenceStatus.committed,
        reason: '${first.code}: ${first.message}',
      );
      final reloaded = await NarrativeEventAuthoringSession.prepare(
        fixture.projectPath,
      );
      expect(reloaded.manifest.eventRegistry?.mode, EventSystemMode.v2Only);
      expect(reloaded.manifest.eventRegistry?.records, isEmpty);
      expect(reloaded.manifest.eventRegistry?.legacyClaims, isEmpty);

      final afterFirst = await File(fixture.projectPath).readAsBytes();
      final second = await useCase.activate(fixture.projectPath);
      expect(second.status, NarrativeEventMigrationPersistenceStatus.noOp);
      expect(await File(fixture.projectPath).readAsBytes(), afterFirst);
    });

    test('uses dualRead when legacy map sources must keep their fallback',
        () async {
      final fixture = await createPersistenceFixture(
        registry: _emptyRegistry(),
        map: _legacyMap(),
      );
      addTearDown(fixture.dispose);
      final result = await NarrativeEventV2ModeActivationUseCase(
        gateway: NarrativeEventMigrationPersistenceRepository(),
      ).activate(fixture.projectPath);

      expect(
        result.status,
        NarrativeEventMigrationPersistenceStatus.committed,
      );
      final reloaded = await NarrativeEventAuthoringSession.prepare(
        fixture.projectPath,
      );
      expect(reloaded.manifest.eventRegistry?.mode, EventSystemMode.dualRead);
      expect(reloaded.maps.single.events, hasLength(1));
    });

    test('repository refuses a stale activation revision', () async {
      final fixture = await createPersistenceFixture(
        registry: _emptyRegistry(),
        map: _emptyMap(),
      );
      addTearDown(fixture.dispose);
      final before = await fixture.readBytes();

      final result =
          await NarrativeEventMigrationPersistenceRepository().activateV2(
        NarrativeEventV2ModeActivationRequest(
          projectPath: fixture.projectPath,
          expectedProjectRevision:
              'sha256:0000000000000000000000000000000000000000000000000000000000000000',
          targetMode: EventSystemMode.v2Only,
        ),
      );

      expect(
        result.status,
        NarrativeEventMigrationPersistenceStatus.staleRevision,
      );
      expect(await fixture.readBytes(), before);
    });
  });
}

NarrativeEventRegistry _emptyRegistry() => NarrativeEventRegistry(
      schemaVersion: 1,
      mode: EventSystemMode.legacyOnly,
      records: <NarrativeEventRecord>[],
      legacyClaims: <LegacySourceClaim>[],
    );

MapData _emptyMap() => const MapData(
      id: 'map_a',
      name: 'Map A',
      size: GridSize(width: 8, height: 6),
    );

MapData _legacyMap() => MapData(
      id: 'map_a',
      name: 'Map A',
      size: const GridSize(width: 8, height: 6),
      layers: const <MapLayer>[
        MapLayer.object(id: 'events', name: 'Events'),
      ],
      entities: const <MapEntity>[
        MapEntity(
          id: 'npc_a',
          name: 'NPC A',
          kind: MapEntityKind.npc,
          pos: GridPos(x: 1, y: 1),
        ),
      ],
      events: const <MapEventDefinition>[
        MapEventDefinition(
          id: 'legacy_event',
          title: 'Legacy Event',
          position: EventPosition(layerId: 'events', x: 1, y: 1),
          metadata: <String, String>{
            LegacyMapEventCompatibilityMetadataKeys.entityId: 'npc_a',
          },
          pages: <MapEventPage>[
            MapEventPage(
              pageNumber: 0,
              sceneTarget: MapEventSceneTarget(sceneId: 'scene_a'),
            ),
          ],
        ),
      ],
    );
