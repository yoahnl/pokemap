import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/narrative_event_authoring_session.dart';
import 'package:map_editor/src/application/models/narrative_event_registry_persistence_models.dart';
import 'package:map_editor/src/infrastructure/repositories/narrative_event_registry_persistence.dart';
import 'package:path/path.dart' as p;

import 'support/event_registry_persistence_fixtures.dart';

void main() {
  group('NS-EVENT-V2 Phase E-bis-B map revalidation', () {
    for (final sourceCase in [
      (
        'entity removed',
        NarrativeEventSourceRef.entityInteract('map_a', 'entity_a'),
      ),
      (
        'trigger removed',
        NarrativeEventSourceRef.triggerEnter('map_a', 'trigger_a'),
      ),
    ]) {
      test('${sourceCase.$1} before fresh replay creates no artifact',
          () async {
        final fixture = await createPersistenceFixture(map: _sourceMap());
        addTearDown(fixture.dispose);
        final request = persistenceRequest(
          fixture: fixture,
          operationId: 'e_bis_${sourceCase.$1.replaceAll(' ', '_')}',
          previousRegistry: null,
          nextRegistry: persistenceRegistry(
            records: [persistenceDraft(source: sourceCase.$2)],
          ),
        );
        final mapPath = fixture.session.mapPaths['map_a']!;
        final current = decodeValidatedNarrativeEventAuthoringMap(
          await File(mapPath).readAsBytes(),
          mapPath,
        );
        final changed = sourceCase.$1.startsWith('entity')
            ? current.copyWith(entities: const [])
            : current.copyWith(triggers: const []);
        await _writeMap(mapPath, changed);

        final result = await NarrativeEventRegistryPersistence().write(request);

        expect(
          result.status,
          NarrativeEventRegistryPersistenceStatus.staleAuthoringSnapshot,
        );
        expect(result.code, 'staleMapRevision');
        expect(
          await File(narrativeEventRegistryJournalPath(
            fixture.projectPath,
            request.operationId,
          )).exists(),
          isFalse,
        );
        expect(await fixture.readBytes(), fixture.initialBytes);
      });
    }

    test('map-backed outcome stale before replay creates no artifact',
        () async {
      final outcome = NarrativeOutcomeRef(
        producerKind: NarrativeOutcomeProducerKind.scene,
        producerId: 'scene_a',
        outcomeId: 'done',
      );
      final fixture = await createPersistenceFixture(
        map: _sourceMap(includeMapEvent: true),
        scene: _mapBackedOutcomeScene(),
      );
      addTearDown(fixture.dispose);
      final request = persistenceRequest(
        fixture: fixture,
        operationId: 'e_bis_map_backed_outcome',
        previousRegistry: null,
        nextRegistry: persistenceRegistry(
          records: [
            persistenceDraft(
              source: NarrativeEventSourceRef.outcomeReceived(outcome),
            ),
          ],
        ),
      );
      final mapPath = fixture.session.mapPaths['map_a']!;
      final current = decodeValidatedNarrativeEventAuthoringMap(
        await File(mapPath).readAsBytes(),
        mapPath,
      );
      await _writeMap(mapPath, current.copyWith(events: const []));

      final result = await NarrativeEventRegistryPersistence().write(request);

      expect(
        result.status,
        NarrativeEventRegistryPersistenceStatus.staleAuthoringSnapshot,
      );
      expect(result.code, 'staleMapRevision');
      expect(
        await File(narrativeEventRegistryJournalPath(
          fixture.projectPath,
          request.operationId,
        )).exists(),
        isFalse,
      );
      expect(await fixture.readBytes(), fixture.initialBytes);
    });

    for (final checkpoint in [
      NarrativeEventRegistryWriteCheckpoint.afterJournalPrepared,
      NarrativeEventRegistryWriteCheckpoint.afterTempFlush,
      NarrativeEventRegistryWriteCheckpoint.beforeRename,
    ]) {
      test('map changed at ${checkpoint.name} never reaches rename', () async {
        final fixture = await createPersistenceFixture();
        addTearDown(fixture.dispose);
        final mapPath = fixture.session.mapPaths['map_a']!;
        var changed = false;
        final service = NarrativeEventRegistryPersistence(
          faultInjector: (current) async {
            if (current != checkpoint || changed) return;
            changed = true;
            final map = decodeValidatedNarrativeEventAuthoringMap(
              await File(mapPath).readAsBytes(),
              mapPath,
            );
            await _writeMap(
              mapPath,
              map.copyWith(properties: {'race': checkpoint.name}),
            );
          },
        );
        final operationId = 'e_bis_race_${checkpoint.name}';

        final result = await service.write(
          persistenceRequest(
            fixture: fixture,
            operationId: operationId,
            previousRegistry: null,
            nextRegistry: persistenceRegistry(),
          ),
        );

        expect(changed, isTrue);
        expect(
          result.status,
          NarrativeEventRegistryPersistenceStatus.staleAuthoringSnapshot,
        );
        expect(result.code, 'staleMapRevision');
        expect(await fixture.readBytes(), fixture.initialBytes);
        final journalPath = narrativeEventRegistryJournalPath(
          fixture.projectPath,
          operationId,
        );
        final journal = NarrativeEventRegistryWriteJournal.fromJson(
          jsonObject(decodeNarrativeEventJsonStrict(
            await File(journalPath).readAsString(),
          )),
        );
        expect(journal.state, NarrativeEventRegistryJournalState.recovered);
        expect(await File(journal.tempPath).exists(), isFalse);
        expect(await File(journal.backupPath).exists(), isFalse);
        final unchangedSentinels = await fixture.readSentinelBytes();
        for (final entry in fixture.initialSentinelBytes.entries) {
          if (entry.key.endsWith('/maps/map_a.json')) continue;
          expect(unchangedSentinels[entry.key], entry.value);
        }
      });
    }

    test('canonical map path retarget uses the stable stale-map result',
        () async {
      final fixture = await createPersistenceFixture();
      addTearDown(fixture.dispose);
      final mapPath = fixture.session.mapPaths['map_a']!;
      final targetPath = '$mapPath.retargeted';
      const operationId = 'e_bis_path_retarget';
      final service = NarrativeEventRegistryPersistence(
        faultInjector: (checkpoint) async {
          if (checkpoint !=
              NarrativeEventRegistryWriteCheckpoint.beforeRename) {
            return;
          }
          await File(mapPath).rename(targetPath);
          await Link(mapPath).create(targetPath);
        },
      );

      final result = await service.write(
        persistenceRequest(
          fixture: fixture,
          operationId: operationId,
          previousRegistry: null,
          nextRegistry: persistenceRegistry(),
        ),
      );

      expect(
        result.status,
        NarrativeEventRegistryPersistenceStatus.staleAuthoringSnapshot,
      );
      expect(result.code, 'staleMapRevision');
      expect(await fixture.readBytes(), fixture.initialBytes);
      final journalPath = narrativeEventRegistryJournalPath(
        fixture.projectPath,
        operationId,
      );
      final journal = NarrativeEventRegistryWriteJournal.fromJson(
        jsonObject(decodeNarrativeEventJsonStrict(
          await File(journalPath).readAsString(),
        )),
      );
      expect(journal.state, NarrativeEventRegistryJournalState.recovered);
      expect(await File(journal.tempPath).exists(), isFalse);
      expect(await File(journal.backupPath).exists(), isFalse);
      expect(
        await File(narrativeEventRegistryUndoPath(
          fixture.projectPath,
          operationId,
        )).exists(),
        isFalse,
      );
    });

    test('manifest map symlink retarget is rejected before rename', () async {
      final fixture = await createPersistenceFixture(
        mapViaSymbolicLink: true,
      );
      addTearDown(fixture.dispose);
      final aliasPath = p.join(fixture.root.path, 'maps', 'map_alias.json');
      final initialTarget = fixture.session.mapPaths['map_a']!;
      final retargetPath = p.join(
        fixture.root.path,
        'maps',
        'map_retarget.json',
      );
      await File(retargetPath).writeAsBytes(
        await File(initialTarget).readAsBytes(),
        flush: true,
      );
      const operationId = 'e_bis_manifest_symlink_retarget';
      final service = NarrativeEventRegistryPersistence(
        faultInjector: (checkpoint) async {
          if (checkpoint !=
              NarrativeEventRegistryWriteCheckpoint.beforeRename) {
            return;
          }
          await Link(aliasPath).delete();
          await Link(aliasPath).create('map_retarget.json');
        },
      );

      final result = await service.write(
        persistenceRequest(
          fixture: fixture,
          operationId: operationId,
          previousRegistry: null,
          nextRegistry: persistenceRegistry(),
        ),
      );

      expect(
        result.status,
        NarrativeEventRegistryPersistenceStatus.staleAuthoringSnapshot,
      );
      expect(result.code, 'staleMapRevision');
      expect(await fixture.readBytes(), fixture.initialBytes);
      final journalPath = narrativeEventRegistryJournalPath(
        fixture.projectPath,
        operationId,
      );
      final journal = NarrativeEventRegistryWriteJournal.fromJson(
        jsonObject(decodeNarrativeEventJsonStrict(
          await File(journalPath).readAsString(),
        )),
      );
      expect(journal.state, NarrativeEventRegistryJournalState.recovered);
      expect(await File(journal.tempPath).exists(), isFalse);
      expect(await File(journal.backupPath).exists(), isFalse);
    });
  });
}

MapData _sourceMap({bool includeMapEvent = false}) {
  return MapData(
    id: 'map_a',
    name: 'Map A',
    size: const GridSize(width: 8, height: 6),
    entities: const [
      MapEntity(
        id: 'entity_a',
        name: 'Entity A',
        kind: MapEntityKind.custom,
        pos: GridPos(x: 1, y: 1),
      ),
    ],
    triggers: const [
      MapTrigger(
        id: 'trigger_a',
        name: 'Trigger A',
        type: TriggerType.event,
        area: MapRect(
          pos: GridPos(x: 2, y: 2),
          size: GridSize(width: 1, height: 1),
        ),
      ),
    ],
    layers: includeMapEvent
        ? const [ObjectLayer(id: 'events', name: 'Events')]
        : const [],
    events: includeMapEvent
        ? const [
            MapEventDefinition(
              id: 'map_event_a',
              pages: [MapEventPage(pageNumber: 0)],
              position: EventPosition(layerId: 'events', x: 3, y: 3),
            ),
          ]
        : const [],
  );
}

SceneAsset _mapBackedOutcomeScene() {
  return SceneAsset(
    id: 'scene_a',
    name: 'Scene A',
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'action',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.consequence(
            SceneConsequence.markEventConsumed(
              mapId: 'map_a',
              eventId: 'map_event_a',
            ),
          ),
        ),
        SceneNode(
          id: 'end',
          kind: SceneNodeKind.end,
          payload: SceneEndPayload(sceneOutcomeId: 'done'),
        ),
      ],
      edges: [
        SceneEdge(
          id: 'edge_start_action',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'action',
          kind: SceneEdgeKind.defaultFlow,
        ),
        SceneEdge(
          id: 'edge_action_end',
          fromNodeId: 'action',
          fromPortId: 'completed',
          toNodeId: 'end',
          kind: SceneEdgeKind.defaultFlow,
        ),
      ],
    ),
    declaredOutcomes: [SceneOutcome(id: 'done', label: 'Done')],
  );
}

Future<void> _writeMap(String path, MapData map) {
  return File(path).writeAsString(
    const JsonEncoder.withIndent('  ').convert(map.toJson()),
    flush: true,
  );
}
