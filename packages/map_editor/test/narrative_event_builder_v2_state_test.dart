import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/narrative_event_map_bridge_models.dart';
import 'package:map_editor/src/features/narrative/state/narrative_event_builder_v2_state.dart';
import 'package:map_editor/src/features/narrative/state/narrative_event_map_bridge_state.dart';

const _portEventId = 'evt_00000000-0000-7000-8000-000000000101';
const _forestEventId = 'evt_00000000-0000-7000-8000-000000000102';
const _draftEventId = 'evt_00000000-0000-7000-8000-000000000103';
const _missingEventId = 'evt_00000000-0000-7000-8000-000000000104';
const _outcomeEventId = 'evt_00000000-0000-7000-8000-000000000105';

void main() {
  group('NS-EVENT-V2-26 project-level Event Builder state', () {
    test('preserves every project group without an active-map input', () {
      final readModel = _projectReadModel();

      final state = NarrativeEventBuilderV2State(readModel: readModel);

      expect(
        state.visibleGroups.map((group) => group.stableKey),
        readModel.groups.map((group) => group.stableKey),
      );
      expect(
        state.visibleGroups.map((group) => group.kind).toSet(),
        containsAll(<NarrativeEventProjectGroupKind>{
          NarrativeEventProjectGroupKind.map,
          NarrativeEventProjectGroupKind.outcomes,
          NarrativeEventProjectGroupKind.drafts,
          NarrativeEventProjectGroupKind.missingReferences,
          NarrativeEventProjectGroupKind.legacyCompatibility,
        }),
      );
      expect(
        state.visibleGroups
            .where((group) => group.kind == NarrativeEventProjectGroupKind.map)
            .map((group) => group.label),
        containsAll(<String>['Port des Brisants', 'Forêt Brumeuse']),
      );
    });

    test('searches only human-facing text and keeps source ordering', () {
      final readModel = _projectReadModel();
      final controller = NarrativeEventBuilderV2Controller(
        readModel: readModel,
        selectEvent: _rejectSelection,
      );

      controller.setQuery('foret brumeuse');

      expect(controller.state.visibleEvents, hasLength(1));
      expect(controller.state.visibleEvents.single.eventId, _forestEventId);
      expect(
        controller.state.visibleGroups.map((group) => group.stableKey),
        readModel.groups
            .where((group) =>
                group.events.any((event) => event.eventId == _forestEventId))
            .map((group) => group.stableKey),
      );

      controller.setQuery('evt_00000000');
      expect(controller.state.visibleEvents, isEmpty);
    });

    test('offers deterministic human filters without re-sorting groups', () {
      final readModel = _projectReadModel();
      final controller = NarrativeEventBuilderV2Controller(
        readModel: readModel,
        selectEvent: _rejectSelection,
      );

      final expectedGroupOrder = readModel.groups
          .map((group) => group.stableKey)
          .toList(growable: false);
      for (final filter in NarrativeEventBuilderV2Filter.values) {
        expect(filter.label, isNotEmpty);
        expect(filter.label, isNot(contains('legacy')));
        controller.setFilter(filter);
        final actualOrder = controller.state.visibleGroups
            .map((group) => group.stableKey)
            .toList(growable: false);
        expect(
          actualOrder,
          orderedEquals([
            for (final key in expectedGroupOrder)
              if (actualOrder.contains(key)) key,
          ]),
        );
      }

      controller.setFilter(NarrativeEventBuilderV2Filter.active);
      expect(
        controller.state.visibleEvents.map((event) => event.eventId).toSet(),
        {_portEventId, _outcomeEventId},
      );

      controller.setFilter(NarrativeEventBuilderV2Filter.drafts);
      expect(
        controller.state.visibleEvents.map((event) => event.eventId),
        [_draftEventId],
      );

      controller.setFilter(NarrativeEventBuilderV2Filter.attention);
      expect(
        controller.state.visibleEvents.map((event) => event.eventId),
        [_missingEventId],
      );

      controller.setFilter(NarrativeEventBuilderV2Filter.oldFormat);
      expect(
        controller.state.visibleEvents,
        everyElement(
          predicate<NarrativeEventProjectSummary>(
            (event) => event.origin != NarrativeEventProjectOrigin.v2,
          ),
        ),
      );
    });

    test('immutable query and filter helpers preserve the read snapshot', () {
      final initial = NarrativeEventBuilderV2State(
        readModel: _projectReadModel(),
      );

      final queried = initial.withQuery('port');
      final filtered = queried.withFilter(
        NarrativeEventBuilderV2Filter.active,
      );

      expect(initial.query, isEmpty);
      expect(initial.filter, NarrativeEventBuilderV2Filter.all);
      expect(queried.query, 'port');
      expect(queried.filter, NarrativeEventBuilderV2Filter.all);
      expect(filtered.query, 'port');
      expect(filtered.filter, NarrativeEventBuilderV2Filter.active);
      expect(filtered.readModel, same(initial.readModel));
      expect(filtered.selectedCompatibilityStableKey, isNull);
    });

    test('distinguishes an empty project from a search with no result', () {
      final nonEmpty = NarrativeEventBuilderV2Controller(
        readModel: _projectReadModel(),
        selectEvent: _rejectSelection,
      )..setQuery('aucun résultat imaginable');

      expect(nonEmpty.state.isProjectEmpty, isFalse);
      expect(nonEmpty.state.hasNoMatchingEvents, isTrue);

      final empty = NarrativeEventBuilderV2State(
        readModel: NarrativeEventBuilderProjectReadModel(
          groups: const [],
          diagnostics: const [],
        ),
      );
      expect(empty.isProjectEmpty, isTrue);
      expect(empty.hasNoMatchingEvents, isFalse);
    });

    test('keeps invalid project diagnostics read-only instead of falling back',
        () {
      final invalid = NarrativeEventBuilderV2State(
        readModel: NarrativeEventBuilderProjectReadModel(
          groups: const [],
          diagnostics: [
            NarrativeEventProjectReadDiagnostic(
              code: 'unsupportedRegistry',
              severity: NarrativeEventProjectSummarySeverity.error,
              message: 'Ce registre est non disponible dans cette version.',
            ),
          ],
        ),
      );

      expect(invalid.isReadOnly, isTrue);
      expect(invalid.isProjectEmpty, isTrue);
      expect(invalid.readModel.diagnostics.single.code, 'unsupportedRegistry');
    });

    test('delegates selection to the map bridge without storing a second copy',
        () {
      String? selectedEventId;
      NarrativeEventGroupContext? selectedGroup;
      final controller = NarrativeEventBuilderV2Controller(
        readModel: _projectReadModel(),
        selectEvent: ({required eventId, required groupContext}) {
          selectedEventId = eventId;
          selectedGroup = groupContext;
          return true;
        },
      );

      expect(controller.selectEvent('v2:$_portEventId'), isTrue);
      expect(selectedEventId, _portEventId);
      expect(
        selectedGroup,
        const NarrativeEventGroupContext.map('map_port'),
      );

      final bridgeState = NarrativeEventMapBridgeState(
        selectedNarrativeEventV2Id: selectedEventId,
        selectedGroupContext: selectedGroup,
      );
      expect(
        selectedNarrativeEventBuilderV2Event(
          state: controller.state,
          bridgeState: bridgeState,
        )?.eventId,
        _portEventId,
      );
    });

    test('resolves stable selection again after a project snapshot refresh',
        () {
      final controller = NarrativeEventBuilderV2Controller(
        readModel: _projectReadModel(portTitle: 'Rencontre au port'),
        selectEvent: _rejectSelection,
      )..setQuery('port');
      const bridgeState = NarrativeEventMapBridgeState(
        selectedNarrativeEventV2Id: _portEventId,
        selectedGroupContext: NarrativeEventGroupContext.map('map_port'),
      );
      final before = selectedNarrativeEventBuilderV2Event(
        state: controller.state,
        bridgeState: bridgeState,
      );

      controller.replaceReadModel(
        _projectReadModel(portTitle: 'Rival au port'),
      );
      final after = selectedNarrativeEventBuilderV2Event(
        state: controller.state,
        bridgeState: bridgeState,
      );

      expect(before?.eventId, _portEventId);
      expect(after?.eventId, _portEventId);
      expect(after?.title, 'Rival au port');
      expect(after, isNot(same(before)));
      expect(controller.state.query, 'port');
    });

    test('selects compatibility rows locally without forging a V2 identity',
        () {
      var bridgeWrites = 0;
      final controller = NarrativeEventBuilderV2Controller(
        readModel: _projectReadModel(),
        selectEvent: ({required eventId, required groupContext}) {
          bridgeWrites++;
          return true;
        },
      );
      final legacy = controller.state.readModel.events
          .firstWhere((event) => event.readOnly);

      expect(legacy.eventId, isNull);
      expect(controller.selectEvent(legacy.stableKey), isTrue);
      expect(controller.state.selectedCompatibilityStableKey, legacy.stableKey);
      expect(bridgeWrites, 0);
      expect(
        selectedNarrativeEventBuilderV2Event(
          state: controller.state,
          bridgeState: const NarrativeEventMapBridgeState(),
        ),
        same(legacy),
      );
    });

    test('a successful V2 selection clears the local compatibility row', () {
      final controller = NarrativeEventBuilderV2Controller(
        readModel: _projectReadModel(),
        selectEvent: ({required eventId, required groupContext}) => true,
      );
      final legacy = controller.state.readModel.events
          .firstWhere((event) => event.readOnly);

      expect(controller.selectEvent(legacy.stableKey), isTrue);
      expect(controller.state.selectedCompatibilityStableKey, isNotNull);
      expect(controller.selectEvent('v2:$_portEventId'), isTrue);
      expect(controller.state.selectedCompatibilityStableKey, isNull);
    });

    test('rejects a contradictory spatial group selection', () {
      final controller = NarrativeEventBuilderV2Controller(
        readModel: _projectReadModel(),
        selectEvent: ({required eventId, required groupContext}) => true,
      );

      expect(
        controller.selectEvent(
          'v2:$_portEventId',
          groupContext: const NarrativeEventGroupContext.global(),
        ),
        isFalse,
      );
    });
  });
}

bool _rejectSelection({
  required String eventId,
  required NarrativeEventGroupContext groupContext,
}) =>
    false;

NarrativeEventBuilderProjectReadModel _projectReadModel({
  String portTitle = 'Rencontre au port',
}) {
  final port = _map(
    id: 'map_port',
    name: 'Port des Brisants',
    entityId: 'npc_lysa',
    entityName: 'Lysa',
    legacyEvent: const MapEventDefinition(
      id: 'legacy_port',
      title: 'Ancienne rumeur au port',
      pages: [
        MapEventPage(
          pageNumber: 0,
          sceneTarget: MapEventSceneTarget(sceneId: 'scene_action'),
        ),
      ],
      position: EventPosition(layerId: 'events', x: 1, y: 1),
    ),
  );
  final forest = _map(
    id: 'map_forest',
    name: 'Forêt Brumeuse',
    entityId: 'npc_spirit',
    entityName: 'Esprit de la forêt',
  );
  final project = ProjectManifest(
    name: 'Selbrume',
    maps: const [
      ProjectMapEntry(
        id: 'map_port',
        name: 'Port des Brisants',
        relativePath: 'maps/port.json',
      ),
      ProjectMapEntry(
        id: 'map_forest',
        name: 'Forêt Brumeuse',
        relativePath: 'maps/forest.json',
      ),
    ],
    tilesets: const [],
    scenes: [
      _scene('scene_action', 'Rencontre'),
      _scene('scene_rival', 'Duel du rival', outcomeId: 'victory'),
    ],
    eventRegistry: NarrativeEventRegistry(
      schemaVersion: 1,
      mode: EventSystemMode.dualRead,
      records: [
        _configured(
          _portEventId,
          portTitle,
          NarrativeEventSourceRef.entityInteract('map_port', 'npc_lysa'),
          enabled: true,
        ),
        _configured(
          _forestEventId,
          'Écho dans la brume',
          NarrativeEventSourceRef.entityInteract(
            'map_forest',
            'npc_spirit',
          ),
          enabled: false,
        ),
        _draft(_draftEventId, 'Événement à préparer'),
        _draft(
          _missingEventId,
          'Objet disparu',
          source: NarrativeEventSourceRef.entityInteract(
            'map_port',
            'npc_absent',
          ),
        ),
        _configured(
          _outcomeEventId,
          'Après la victoire',
          NarrativeEventSourceRef.outcomeReceived(
            NarrativeOutcomeRef(
              producerKind: NarrativeOutcomeProducerKind.scene,
              producerId: 'scene_rival',
              outcomeId: 'victory',
            ),
          ),
          enabled: true,
        ),
      ],
      legacyClaims: const [],
    ),
  );
  return buildNarrativeEventBuilderProjectReadModel(
    project: project,
    maps: [port, forest],
  );
}

MapData _map({
  required String id,
  required String name,
  required String entityId,
  required String entityName,
  MapEventDefinition? legacyEvent,
}) {
  return MapData(
    id: id,
    name: name,
    size: const GridSize(width: 8, height: 8),
    layers: const [MapLayer.object(id: 'events', name: 'Événements')],
    entities: [
      MapEntity(
        id: entityId,
        name: entityName,
        kind: MapEntityKind.npc,
        pos: const GridPos(x: 1, y: 1),
      ),
    ],
    events: [if (legacyEvent != null) legacyEvent],
  );
}

NarrativeEventRecord _configured(
  String id,
  String name,
  NarrativeEventSourceRef source, {
  required bool enabled,
}) {
  return NarrativeEventRecord.configuredStructurallyUnchecked(
    NarrativeEventDefinition(
      id: id,
      name: name,
      source: source,
      conditions: const [],
      sceneId: 'scene_action',
      reusePolicy: NarrativeEventReusePolicy.oneShot,
      priority: 0,
      order: 0,
    ),
    enabled: enabled,
  );
}

NarrativeEventRecord _draft(
  String id,
  String name, {
  NarrativeEventSourceRef? source,
}) {
  return NarrativeEventRecord.draft(
    NarrativeEventDraft(
      id: id,
      name: name,
      source: source,
      conditions: const [],
      priority: 0,
      order: 0,
    ),
  );
}

SceneAsset _scene(String id, String name, {String? outcomeId}) {
  return SceneAsset(
    id: id,
    name: name,
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'end',
          kind: SceneNodeKind.end,
          payload: SceneEndPayload(sceneOutcomeId: outcomeId),
        ),
      ],
      edges: [
        SceneEdge(
          id: 'edge_end',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'end',
          kind: SceneEdgeKind.defaultFlow,
        ),
      ],
    ),
    declaredOutcomes: outcomeId == null
        ? const []
        : [SceneOutcome(id: outcomeId, label: 'Victoire')],
  );
}
