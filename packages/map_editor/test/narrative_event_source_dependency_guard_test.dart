import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/map_history_snapshot.dart';
import 'package:map_editor/src/application/services/narrative_event_source_dependency_guard.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';

const _mapEvent = 'evt_019abcde-0000-7000-8000-000000000301';
const _entityEvent = 'evt_019abcde-0000-7000-8000-000000000302';
const _triggerEvent = 'evt_019abcde-0000-7000-8000-000000000303';

void main() {
  group('NS-EVENT-V2-23 source dependency guard', () {
    const guard = NarrativeEventSourceDependencyGuard();
    final registry = _registry();

    test('blocks linked map rename and delete across every record state', () {
      final rename = guard.inspectMapRename(
        registry: registry,
        mapId: 'map_a',
        newMapId: 'map_b',
      );
      final delete = guard.inspectMapDelete(
        registry: registry,
        mapId: 'map_a',
      );

      expect(rename.isAllowed, isFalse);
      expect(delete.isAllowed, isFalse);
      expect(
        rename.linkedEventIds,
        [_mapEvent, _entityEvent, _triggerEvent],
      );
      expect(delete.linkedEventIds, rename.linkedEventIds);
    });

    test('blocks linked entity identity breakage and transition to spawn', () {
      const current = MapEntity(
        id: 'entity_a',
        name: 'Rival',
        kind: MapEntityKind.npc,
        pos: GridPos(x: 1, y: 1),
      );

      expect(
        guard
            .inspectEntityUpdate(
              registry: registry,
              mapId: 'map_a',
              current: current,
              next: current.copyWith(id: 'entity_b'),
            )
            .isAllowed,
        isFalse,
      );
      expect(
        guard
            .inspectEntityUpdate(
              registry: registry,
              mapId: 'map_a',
              current: current,
              next: current.copyWith(kind: MapEntityKind.spawn),
            )
            .isAllowed,
        isFalse,
      );
      expect(
        guard
            .inspectEntityDelete(
              registry: registry,
              mapId: 'map_a',
              entityId: 'entity_a',
            )
            .isAllowed,
        isFalse,
      );
    });

    test('permits linked entity non-identity edits and interactable kinds', () {
      const current = MapEntity(
        id: 'entity_a',
        name: 'Rival',
        kind: MapEntityKind.npc,
        pos: GridPos(x: 1, y: 1),
      );
      final edited = current.copyWith(
        name: 'Rival du port',
        kind: MapEntityKind.sign,
        pos: const GridPos(x: 3, y: 2),
        size: const GridSize(width: 2, height: 1),
        properties: const {'mood': 'angry'},
      );

      expect(
        guard
            .inspectEntityUpdate(
              registry: registry,
              mapId: 'map_a',
              current: current,
              next: edited,
            )
            .isAllowed,
        isTrue,
      );
    });

    test('blocks linked trigger identity/delete and event to system transition',
        () {
      const current = MapTrigger(
        id: 'trigger_a',
        name: 'Zone port',
        type: TriggerType.event,
        area: MapRect(
          pos: GridPos(x: 2, y: 2),
          size: GridSize(width: 1, height: 1),
        ),
      );

      expect(
        guard
            .inspectTriggerUpdate(
              registry: registry,
              mapId: 'map_a',
              current: current,
              next: current.copyWith(id: 'trigger_b'),
            )
            .isAllowed,
        isFalse,
      );
      expect(
        guard
            .inspectTriggerUpdate(
              registry: registry,
              mapId: 'map_a',
              current: current,
              next: current.copyWith(type: TriggerType.camera),
            )
            .isAllowed,
        isFalse,
      );
      expect(
        guard
            .inspectTriggerDelete(
              registry: registry,
              mapId: 'map_a',
              triggerId: 'trigger_a',
            )
            .isAllowed,
        isFalse,
      );
    });

    test('permits event/custom transitions and non-identity trigger edits', () {
      const current = MapTrigger(
        id: 'trigger_a',
        name: 'Zone port',
        type: TriggerType.event,
        area: MapRect(
          pos: GridPos(x: 2, y: 2),
          size: GridSize(width: 1, height: 1),
        ),
      );
      final edited = current.copyWith(
        name: 'Zone rival',
        type: TriggerType.custom,
        area: const MapRect(
          pos: GridPos(x: 4, y: 3),
          size: GridSize(width: 2, height: 2),
        ),
        properties: const {'front': 'north'},
      );

      expect(
        guard
            .inspectTriggerUpdate(
              registry: registry,
              mapId: 'map_a',
              current: current,
              next: edited,
            )
            .isAllowed,
        isTrue,
      );
    });

    test('unlinked sources keep the existing behavior', () {
      expect(
        guard
            .inspectMapDelete(registry: registry, mapId: 'map_unlinked')
            .isAllowed,
        isTrue,
      );
      expect(
        guard
            .inspectEntityDelete(
              registry: registry,
              mapId: 'map_a',
              entityId: 'entity_unlinked',
            )
            .isAllowed,
        isTrue,
      );
      expect(
        guard
            .inspectTriggerDelete(
              registry: registry,
              mapId: 'map_a',
              triggerId: 'trigger_unlinked',
            )
            .isAllowed,
        isTrue,
      );
    });

    test('map transition blocks a resolved entity becoming absent or spawn',
        () {
      final current = _map();
      final absent = current.copyWith(entities: const []);
      final spawn = current.copyWith(
        entities: [
          current.entities.single.copyWith(kind: MapEntityKind.spawn),
        ],
      );

      for (final candidate in [absent, spawn]) {
        final decision = guard.inspectMapTransition(
          registry: registry,
          current: current,
          candidate: candidate,
          operation: 'restauration de l’historique',
        );

        expect(decision.isAllowed, isFalse);
        expect(decision.linkedEventIds, [_entityEvent]);
      }
    });

    test(
        'map transition blocks a resolved trigger becoming absent or incompatible',
        () {
      final current = _map();
      final absent = current.copyWith(triggers: const []);
      final system = current.copyWith(
        triggers: [
          current.triggers.single.copyWith(type: TriggerType.camera),
        ],
      );

      for (final candidate in [absent, system]) {
        final decision = guard.inspectMapTransition(
          registry: registry,
          current: current,
          candidate: candidate,
          operation: 'restauration de l’historique',
        );

        expect(decision.isAllowed, isFalse);
        expect(decision.linkedEventIds, [_triggerEvent]);
      }
    });

    test('map transition permits non-identity edits and event/custom changes',
        () {
      final current = _map();
      final candidate = current.copyWith(
        name: 'Map A renommée visuellement',
        entities: [
          current.entities.single.copyWith(
            name: 'Rival du port',
            pos: const GridPos(x: 3, y: 2),
          ),
        ],
        triggers: [
          current.triggers.single.copyWith(
            name: 'Zone rival',
            type: TriggerType.custom,
          ),
        ],
      );

      expect(
        guard
            .inspectMapTransition(
              registry: registry,
              current: current,
              candidate: candidate,
              operation: 'undo',
            )
            .isAllowed,
        isTrue,
      );
    });

    test('map transition permits an already broken reference and its repair',
        () {
      final broken = _map().copyWith(entities: const []);
      final stillBroken = broken.copyWith(name: 'Modification sans rapport');

      expect(
        guard
            .inspectMapTransition(
              registry: registry,
              current: broken,
              candidate: stillBroken,
              operation: 'undo',
            )
            .isAllowed,
        isTrue,
      );
      expect(
        guard
            .inspectMapTransition(
              registry: registry,
              current: broken,
              candidate: _map(),
              operation: 'redo',
            )
            .isAllowed,
        isTrue,
      );
    });
  });

  group('NS-EVENT-V2-23 notifier guard integration', () {
    test('blocks linked entity rename, spawn transition and delete', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final map = _map();
      notifier.state = EditorState(
        project: _project(registry: _registry()),
        activeMap: map,
        selectedEntityId: 'entity_a',
      );

      notifier.updateEntity(entityId: 'entity_a', id: 'entity_b');
      expect(notifier.state.activeMap, map);
      expect(notifier.state.errorMessage, contains(_entityEvent));

      notifier.updateEntity(
        entityId: 'entity_a',
        kind: MapEntityKind.spawn,
      );
      expect(notifier.state.activeMap, map);

      notifier.deleteEntity('entity_a');
      expect(notifier.state.activeMap, map);
    });

    test('blocks linked trigger identity/system transition and delete', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final map = _map();
      notifier.state = EditorState(
        project: _project(registry: _registry()),
        activeMap: map,
        selectedTriggerId: 'trigger_a',
      );

      notifier.updateTrigger(triggerId: 'trigger_a', id: 'trigger_b');
      expect(notifier.state.activeMap, map);
      expect(notifier.state.errorMessage, contains(_triggerEvent));

      notifier.updateTrigger(
        triggerId: 'trigger_a',
        type: TriggerType.camera,
      );
      expect(notifier.state.activeMap, map);

      notifier.deleteTrigger('trigger_a');
      expect(notifier.state.activeMap, map);
    });

    test('allows linked non-identity edits and event to custom transition', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        project: _project(registry: _registry()),
        activeMap: _map(),
        selectedEntityId: 'entity_a',
        selectedTriggerId: 'trigger_a',
      );

      notifier.updateEntity(
        entityId: 'entity_a',
        name: 'Rival du port',
        pos: const GridPos(x: 3, y: 2),
        properties: const {'mood': 'angry'},
      );
      notifier.updateTrigger(
        triggerId: 'trigger_a',
        name: 'Zone rival',
        type: TriggerType.custom,
      );

      expect(
        notifier.state.activeMap!.entities.single.name,
        'Rival du port',
      );
      expect(
          notifier.state.activeMap!.triggers.single.type, TriggerType.custom);
      expect(notifier.state.isDirty, isTrue);
      expect(notifier.state.errorMessage, isNull);
    });

    test('blocks linked map rename/delete before repository operations',
        () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final project = _project(registry: _registry());
      notifier.state = EditorState(
        projectRootPath: '/tmp/v2_23_guard',
        project: project,
        activeMap: _map(),
      );

      await notifier.renameMap('map_a', 'map_b');
      expect(notifier.state.project, project);
      expect(notifier.state.errorMessage, contains(_mapEvent));

      await notifier.deleteMap('map_a');
      expect(notifier.state.project, project);
    });

    test('undo keeps map and history unchanged when an entity would disappear',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final current = _map();
      final candidate = current.copyWith(entities: const []);
      final undoStack = [MapHistorySnapshot(map: candidate)];
      notifier.state = EditorState(
        project: _project(registry: _registry()),
        activeMap: current,
        selectedEntityId: 'entity_a',
        mapUndoStack: undoStack,
        canUndoMap: true,
        statusMessage: 'Prêt',
      );

      notifier.undoMap();

      expect(notifier.state.activeMap, current);
      expect(notifier.state.mapUndoStack, undoStack);
      expect(notifier.state.mapRedoStack, isEmpty);
      expect(notifier.state.canUndoMap, isTrue);
      expect(notifier.state.statusMessage, 'Prêt');
      expect(notifier.state.errorMessage, contains(_entityEvent));
    });

    test('blocked undo leaves an active stroke and its history untouched', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final current = _map();
      final candidate = current.copyWith(entities: const []);
      final strokeStart = MapHistorySnapshot(map: candidate);
      notifier.state = EditorState(
        project: _project(registry: _registry()),
        activeMap: current,
        selectedEntityId: 'entity_a',
        mapStrokeStart: strokeStart,
        canUndoMap: false,
        statusMessage: 'Trait en cours',
      );

      notifier.undoMap();

      expect(notifier.state.activeMap, current);
      expect(notifier.state.mapStrokeStart, strokeStart);
      expect(notifier.state.mapUndoStack, isEmpty);
      expect(notifier.state.mapRedoStack, isEmpty);
      expect(notifier.state.canUndoMap, isFalse);
      expect(notifier.state.statusMessage, 'Trait en cours');
      expect(notifier.state.errorMessage, contains(_entityEvent));
    });

    test('redo keeps map and history unchanged when a trigger becomes system',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final current = _map();
      final candidate = current.copyWith(
        triggers: [
          current.triggers.single.copyWith(type: TriggerType.camera),
        ],
      );
      final redoStack = [MapHistorySnapshot(map: candidate)];
      notifier.state = EditorState(
        project: _project(registry: _registry()),
        activeMap: current,
        selectedTriggerId: 'trigger_a',
        mapRedoStack: redoStack,
        canRedoMap: true,
        statusMessage: 'Prêt',
      );

      notifier.redoMap();

      expect(notifier.state.activeMap, current);
      expect(notifier.state.mapUndoStack, isEmpty);
      expect(notifier.state.mapRedoStack, redoStack);
      expect(notifier.state.canRedoMap, isTrue);
      expect(notifier.state.statusMessage, 'Prêt');
      expect(notifier.state.errorMessage, contains(_triggerEvent));
    });

    test('undo applies non-identity source edits', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final current = _map();
      final candidate = current.copyWith(
        entities: [
          current.entities.single.copyWith(name: 'Rival du port'),
        ],
        triggers: [
          current.triggers.single.copyWith(type: TriggerType.custom),
        ],
      );
      notifier.state = EditorState(
        project: _project(registry: _registry()),
        activeMap: current,
        mapUndoStack: [MapHistorySnapshot(map: candidate)],
        canUndoMap: true,
      );

      notifier.undoMap();

      expect(notifier.state.activeMap, candidate);
      expect(notifier.state.statusMessage, 'Undo');
      expect(notifier.state.errorMessage, isNull);
    });
  });
}

NarrativeEventRegistry _registry() => NarrativeEventRegistry(
      schemaVersion: 1,
      mode: EventSystemMode.dualRead,
      records: [
        _record(
          id: _mapEvent,
          source: NarrativeEventSourceRef.mapEnter('map_a'),
          order: 0,
          configured: false,
        ),
        _record(
          id: _entityEvent,
          source: NarrativeEventSourceRef.entityInteract(
            'map_a',
            'entity_a',
          ),
          order: 1,
          configured: true,
          enabled: false,
        ),
        _record(
          id: _triggerEvent,
          source: NarrativeEventSourceRef.triggerEnter(
            'map_a',
            'trigger_a',
          ),
          order: 2,
          configured: true,
          enabled: true,
        ),
      ],
      legacyClaims: const [],
    );

NarrativeEventRecord _record({
  required String id,
  required NarrativeEventSourceRef source,
  required int order,
  required bool configured,
  bool enabled = false,
}) {
  if (!configured) {
    return NarrativeEventRecord.draft(
      NarrativeEventDraft(
        id: id,
        name: id,
        source: source,
        conditions: const [],
        priority: 0,
        order: order,
      ),
    );
  }
  return NarrativeEventRecord.configuredStructurallyUnchecked(
    NarrativeEventDefinition(
      id: id,
      name: id,
      source: source,
      conditions: const [],
      sceneId: 'scene_a',
      reusePolicy: NarrativeEventReusePolicy.oneShot,
      priority: 0,
      order: order,
    ),
    enabled: enabled,
  );
}

MapData _map() => const MapData(
      id: 'map_a',
      name: 'Map A',
      size: GridSize(width: 8, height: 6),
      entities: [
        MapEntity(
          id: 'entity_a',
          name: 'Rival',
          kind: MapEntityKind.npc,
          pos: GridPos(x: 1, y: 1),
        ),
      ],
      triggers: [
        MapTrigger(
          id: 'trigger_a',
          name: 'Zone port',
          type: TriggerType.event,
          area: MapRect(
            pos: GridPos(x: 2, y: 2),
            size: GridSize(width: 1, height: 1),
          ),
        ),
      ],
    );

ProjectManifest _project({NarrativeEventRegistry? registry}) => ProjectManifest(
      name: 'Guard project',
      maps: const [
        ProjectMapEntry(
          id: 'map_a',
          name: 'Map A',
          relativePath: 'maps/map_a.json',
        ),
      ],
      tilesets: const [],
      eventRegistry: registry,
    );
