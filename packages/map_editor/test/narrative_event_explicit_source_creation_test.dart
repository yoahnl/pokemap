import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/map_history_snapshot.dart';
import 'package:map_editor/src/application/models/narrative_event_spatial_source_creation_models.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';

void main() {
  group('NS-EVENT-V2-25 explicit physical source proposal', () {
    test('proposes authorable entity owners with their real dimensions', () {
      final cases = <(
        NarrativeEventPhysicalSourceKind,
        MapEntityKind,
        GridSize,
      )>[
        (
          NarrativeEventPhysicalSourceKind.npc,
          MapEntityKind.npc,
          const GridSize(width: 2, height: 2),
        ),
        (
          NarrativeEventPhysicalSourceKind.sign,
          MapEntityKind.sign,
          const GridSize(width: 1, height: 1),
        ),
        (
          NarrativeEventPhysicalSourceKind.item,
          MapEntityKind.item,
          const GridSize(width: 1, height: 1),
        ),
        (
          NarrativeEventPhysicalSourceKind.invisible,
          MapEntityKind.custom,
          const GridSize(width: 1, height: 1),
        ),
      ];

      for (final (physicalKind, entityKind, size) in cases) {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final notifier = container.read(editorNotifierProvider.notifier);
        final map = _map();
        final beforeState = EditorState(
          activeMap: map,
          savedMapSnapshot: map,
          selectedEntityId: 'selected_before',
          selectedTriggerId: 'trigger_before',
          isDirty: false,
        );
        notifier.state = beforeState;

        final proposal = notifier.proposeNarrativeEventSourceAt(
          position: const GridPos(x: 3, y: 4),
          kind: physicalKind,
        );

        expect(proposal, isNotNull, reason: physicalKind.name);
        final created = proposal!.afterMap.entities.single;
        expect(created.kind, entityKind, reason: physicalKind.name);
        expect(created.pos, const GridPos(x: 3, y: 4));
        expect(created.size, size);
        expect(
          proposal.bounds,
          MapRect(pos: const GridPos(x: 3, y: 4), size: size),
        );
        expect(
          proposal.source,
          NarrativeEventSourceRef.entityInteract(map.id, created.id),
        );
        expect(
            created.npc, entityKind == MapEntityKind.npc ? isNotNull : isNull);
        expect(
          created.sign,
          entityKind == MapEntityKind.sign ? isNotNull : isNull,
        );
        expect(
          created.item,
          entityKind == MapEntityKind.item ? isNotNull : isNull,
        );
        if (physicalKind == NarrativeEventPhysicalSourceKind.invisible) {
          expect(created.blocksMovement, isFalse);
          expect(created.editorVisual, isNull);
        }
        expect(proposal.beforeMap, same(map));
        expect(proposal.afterMap.events, isEmpty);
        expect(proposal.afterMap.layers, map.layers);
        expect(notifier.state, same(beforeState));
      }
    });

    test('proposes an exact 1x1 event trigger without a legacy MapEvent', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final map = _map();
      final beforeState = EditorState(
        activeMap: map,
        savedMapSnapshot: map,
        selectedEntityId: 'entity_before',
      );
      notifier.state = beforeState;

      final proposal = notifier.proposeNarrativeEventSourceAt(
        position: const GridPos(x: 7, y: 2),
        kind: NarrativeEventPhysicalSourceKind.zone1x1,
      );

      expect(proposal, isNotNull);
      final created = proposal!.afterMap.triggers.single;
      expect(created.type, TriggerType.event);
      expect(
        created.area,
        const MapRect(
          pos: GridPos(x: 7, y: 2),
          size: GridSize(width: 1, height: 1),
        ),
      );
      expect(proposal.bounds, created.area);
      expect(
        proposal.source,
        NarrativeEventSourceRef.triggerEnter(map.id, created.id),
      );
      expect(proposal.afterMap.entities, isEmpty);
      expect(proposal.afterMap.events, isEmpty);
      expect(notifier.state, same(beforeState));
    });

    test('proposal leaves dirty state, history, selection and messages intact',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final map = _map();
      final undo = [MapHistorySnapshot(map: map, selectedEntityId: 'undo')];
      final redo = [MapHistorySnapshot(map: map, selectedTriggerId: 'redo')];
      final beforeState = EditorState(
        activeMap: map,
        savedMapSnapshot: _map(name: 'persisted'),
        selectedEntityId: 'entity_before',
        selectedTriggerId: 'trigger_before',
        selectedMapEventId: 'legacy_event_before',
        mapUndoStack: undo,
        mapRedoStack: redo,
        canUndoMap: true,
        canRedoMap: true,
        isDirty: true,
        isProjectDirty: true,
        statusMessage: 'status before',
        errorMessage: 'error before',
      );
      notifier.state = beforeState;

      final proposal = notifier.proposeNarrativeEventSourceAt(
        position: const GridPos(x: 1, y: 1),
        kind: NarrativeEventPhysicalSourceKind.sign,
      );

      expect(proposal, isNotNull);
      expect(notifier.state, same(beforeState));
      expect(notifier.state.mapUndoStack, undo);
      expect(notifier.state.mapRedoStack, redo);
    });

    test('uses deterministic IDs unique against existing physical owners', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final map = _map(
        entities: const [
          MapEntity(
            id: 'npc',
            kind: MapEntityKind.npc,
            pos: GridPos(x: 0, y: 0),
          ),
          MapEntity(
            id: 'entity',
            kind: MapEntityKind.custom,
            pos: GridPos(x: 5, y: 5),
          ),
        ],
        triggers: const [
          MapTrigger(
            id: 'trigger',
            type: TriggerType.event,
            area: MapRect(
              pos: GridPos(x: 8, y: 8),
              size: GridSize(width: 1, height: 1),
            ),
          ),
        ],
      );
      notifier.state = EditorState(activeMap: map, savedMapSnapshot: map);

      final firstNpc = notifier.proposeNarrativeEventSourceAt(
        position: const GridPos(x: 2, y: 2),
        kind: NarrativeEventPhysicalSourceKind.npc,
      )!;
      final secondNpc = notifier.proposeNarrativeEventSourceAt(
        position: const GridPos(x: 2, y: 2),
        kind: NarrativeEventPhysicalSourceKind.npc,
      )!;
      final invisible = notifier.proposeNarrativeEventSourceAt(
        position: const GridPos(x: 3, y: 3),
        kind: NarrativeEventPhysicalSourceKind.invisible,
      )!;
      final zone = notifier.proposeNarrativeEventSourceAt(
        position: const GridPos(x: 4, y: 4),
        kind: NarrativeEventPhysicalSourceKind.zone1x1,
      )!;

      expect(firstNpc.source.toJson()['entityId'], 'npc_1');
      expect(secondNpc.source, firstNpc.source);
      expect(secondNpc.ownerFingerprint, firstNpc.ownerFingerprint);
      expect(invisible.source.toJson()['entityId'], 'entity_1');
      expect(zone.source.toJson()['triggerId'], 'trigger_1');
    });

    test('envelops owner JSON and computes a stable canonical fingerprint', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final map = _map();
      notifier.state = EditorState(activeMap: map, savedMapSnapshot: map);

      final entityProposal = notifier.proposeNarrativeEventSourceAt(
        position: const GridPos(x: 2, y: 3),
        kind: NarrativeEventPhysicalSourceKind.item,
      )!;
      final triggerProposal = notifier.proposeNarrativeEventSourceAt(
        position: const GridPos(x: 6, y: 7),
        kind: NarrativeEventPhysicalSourceKind.zone1x1,
      )!;

      for (final (proposal, ownerKind) in [
        (entityProposal, 'mapEntity'),
        (triggerProposal, 'mapTrigger'),
      ]) {
        expect(proposal.ownerJson['schemaVersion'], 1);
        expect(proposal.ownerJson['ownerKind'], ownerKind);
        expect(proposal.ownerJson['mapId'], map.id);
        expect(
          proposal.ownerJson['sourceId'],
          proposal.source.when(
            entityInteract: (_, entityId) => entityId,
            triggerEnter: (_, triggerId) => triggerId,
            mapEnter: (_) => fail('A created source cannot be mapEnter.'),
            outcomeReceived: (_) =>
                fail('A created source cannot be outcomeReceived.'),
          ),
        );
        expect(proposal.ownerJson['owner'], isA<Map<String, Object?>>());
        expect(
          proposal.ownerFingerprint,
          'sha256:${narrativeEventCanonicalSha256(proposal.ownerJson)}',
        );
        expect(
          () => proposal.ownerJson['mapId'] = 'mutated',
          throwsUnsupportedError,
        );
        expect(
          () => (proposal.ownerJson['owner']! as Map<String, Object?>)['id'] =
              'mutated',
          throwsUnsupportedError,
        );
      }
    });

    test('refuses out-of-bounds placement without clamping or state writes',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final map = _map(size: const GridSize(width: 5, height: 5));
      final beforeState = EditorState(
        activeMap: map,
        savedMapSnapshot: map,
        statusMessage: 'unchanged',
      );
      notifier.state = beforeState;

      expect(
        notifier.proposeNarrativeEventSourceAt(
          position: const GridPos(x: 4, y: 4),
          kind: NarrativeEventPhysicalSourceKind.npc,
        ),
        isNull,
      );
      expect(
        notifier.proposeNarrativeEventSourceAt(
          position: const GridPos(x: -1, y: 0),
          kind: NarrativeEventPhysicalSourceKind.sign,
        ),
        isNull,
      );
      expect(
        notifier.proposeNarrativeEventSourceAt(
          position: const GridPos(x: 5, y: 4),
          kind: NarrativeEventPhysicalSourceKind.zone1x1,
        ),
        isNull,
      );

      final edgeProposal = notifier.proposeNarrativeEventSourceAt(
        position: const GridPos(x: 4, y: 4),
        kind: NarrativeEventPhysicalSourceKind.item,
      );
      expect(edgeProposal, isNotNull);
      expect(edgeProposal!.bounds.pos, const GridPos(x: 4, y: 4));
      expect(notifier.state, same(beforeState));
    });

    test('returns null when no map is active', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final beforeState = notifier.state;

      final proposal = notifier.proposeNarrativeEventSourceAt(
        position: const GridPos(x: 0, y: 0),
        kind: NarrativeEventPhysicalSourceKind.sign,
      );

      expect(proposal, isNull);
      expect(notifier.state, same(beforeState));
    });

    test('adopts the persisted map only when the proposal baseline is current',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final map = _map();
      final undo = [MapHistorySnapshot(map: map)];
      notifier.state = EditorState(
        activeMap: map,
        savedMapSnapshot: map,
        mapUndoStack: undo,
        canUndoMap: true,
        selectedTriggerId: 'old_trigger',
      );
      final proposal = notifier.proposeNarrativeEventSourceAt(
        position: const GridPos(x: 2, y: 2),
        kind: NarrativeEventPhysicalSourceKind.sign,
      )!;

      final adopted = notifier.adoptPersistedNarrativeEventSourceProposal(
        proposal,
      );

      expect(adopted, isTrue);
      expect(notifier.state.activeMap, same(proposal.afterMap));
      expect(notifier.state.savedMapSnapshot, same(proposal.afterMap));
      expect(notifier.state.isDirty, isFalse);
      expect(notifier.state.mapUndoStack, undo);
      expect(notifier.state.canUndoMap, isTrue);
      expect(
        notifier.state.selectedEntityId,
        proposal.source.toJson()['entityId'],
      );
      expect(notifier.state.selectedTriggerId, isNull);
    });

    test('persisted adoption never overwrites a map changed after proposal',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final map = _map();
      notifier.state = EditorState(activeMap: map, savedMapSnapshot: map);
      final proposal = notifier.proposeNarrativeEventSourceAt(
        position: const GridPos(x: 2, y: 2),
        kind: NarrativeEventPhysicalSourceKind.zone1x1,
      )!;
      final concurrentlyChanged = map.copyWith(name: 'Changed concurrently');
      final changedState = notifier.state.copyWith(
        activeMap: concurrentlyChanged,
        isDirty: true,
      );
      notifier.state = changedState;

      final adopted = notifier.adoptPersistedNarrativeEventSourceProposal(
        proposal,
      );

      expect(adopted, isFalse);
      expect(notifier.state, same(changedState));
      expect(notifier.state.activeMap, same(concurrentlyChanged));
      expect(notifier.state.activeMap!.triggers, isEmpty);
    });
  });
}

MapData _map({
  String name = 'Map A',
  GridSize size = const GridSize(width: 12, height: 10),
  List<MapEntity> entities = const [],
  List<MapTrigger> triggers = const [],
}) {
  return MapData(
    id: 'map_a',
    name: name,
    size: size,
    entities: entities,
    triggers: triggers,
  );
}
