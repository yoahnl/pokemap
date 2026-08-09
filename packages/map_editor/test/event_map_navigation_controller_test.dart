import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import './support/riverpod_notifier_harness.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/narrative_event_authoring_session.dart';
import 'package:map_editor/src/application/models/narrative_event_map_bridge_models.dart';
import 'package:map_editor/src/application/models/narrative_event_registry_persistence_models.dart';
import 'package:map_editor/src/application/ports/narrative_event_registry_persistence_gateway.dart';
import 'package:map_editor/src/application/use_cases/create_narrative_event_from_map_source_use_case.dart';
import 'package:map_editor/src/application/use_cases/narrative_event_spatial_source_link_use_case.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/narrative/state/narrative_event_map_bridge_state.dart';

import 'support/event_registry_persistence_fixtures.dart';

const _eventId = 'evt_019abcde-0000-7000-8000-000000000301';

void main() {
  group('NS-EVENT-V2-24 map navigation controller', () {
    test(
      'same-map dirty view never reloads and returns to the exact Event',
      () async {
        final source = NarrativeEventSourceRef.entityInteract(
          'map_a',
          'entity_a',
        );
        final project = _project(source: source);
        final map = _mapA();
        final controller = _controller();
        var snapshotReads = 0;
        var activations = 0;
        NarrativeEditorFocusTarget? appliedFocus;

        final result = await controller.openMapForEvent(
          eventId: _eventId,
          groupContext: const NarrativeEventGroupContext.map('map_a'),
          mode: NarrativeEventMapNavigationMode.view,
          project: project,
          activeMap: map,
          mapDirty: true,
          loadMapSnapshot: (_) async {
            snapshotReads++;
            return null;
          },
          activateMapSnapshot: (_) {
            activations++;
            return true;
          },
          applyFocus: (focus) {
            appliedFocus = focus;
            return true;
          },
        );

        expect(result.status, NarrativeEventMapNavigationStatus.ready);
        expect(snapshotReads, 0);
        expect(activations, 0);
        expect(appliedFocus?.kind, NarrativeEditorFocusTargetKind.entity);
        expect(appliedFocus?.ownerId, 'entity_a');
        expect(controller.state.pendingReturn?.eventId, _eventId);
        expect(
          controller.state.pendingReturn?.groupContext,
          const NarrativeEventGroupContext.map('map_a'),
        );
        expect(controller.state.focusRequest?.cameraApplied, isFalse);
        expect(controller.state.focusRequest?.source, source);
        expect(
          controller.state.focusRequest?.mode,
          NarrativeEventMapNavigationMode.view,
        );

        String? selectedEvent;
        NarrativeEventGroupContext? selectedGroup;
        final returned = controller.returnToEvent(
          project: project,
          openExactEvent: ({required eventId, required groupContext}) {
            selectedEvent = eventId;
            selectedGroup = groupContext;
          },
        );

        expect(returned, isTrue);
        expect(selectedEvent, _eventId);
        expect(selectedGroup, const NarrativeEventGroupContext.map('map_a'));
        expect(controller.state.pendingReturn, isNull);
        expect(controller.state.focusRequest, isNull);
      },
    );

    test('cross-map dirty refusal happens before any snapshot read', () async {
      final controller = _controller();
      var snapshotReads = 0;
      var activations = 0;

      final result = await controller.openMapForEvent(
        eventId: _eventId,
        groupContext: const NarrativeEventGroupContext.map('map_b'),
        mode: NarrativeEventMapNavigationMode.choose,
        project: _project(
          source: NarrativeEventSourceRef.triggerEnter('map_b', 'trigger_b'),
          maps: const [
            ProjectMapEntry(
              id: 'map_a',
              name: 'Map A',
              relativePath: 'maps/map_a.json',
            ),
            ProjectMapEntry(
              id: 'map_b',
              name: 'Map B',
              relativePath: 'maps/map_b.json',
            ),
          ],
        ),
        activeMap: _mapA(),
        mapDirty: true,
        loadMapSnapshot: (_) async {
          snapshotReads++;
          return _mapB();
        },
        activateMapSnapshot: (_) {
          activations++;
          return true;
        },
        applyFocus: (_) => true,
      );

      expect(result.status, NarrativeEventMapNavigationStatus.blockedDirtyMap);
      expect(snapshotReads, 0);
      expect(activations, 0);
      expect(controller.state.pendingReturn, isNull);
      expect(controller.state.focusRequest, isNull);
    });

    test(
      'missing and nonspatial sources never create navigation state',
      () async {
        final cases = <NarrativeEventSourceRef>[
          NarrativeEventSourceRef.entityInteract('map_a', 'missing_entity'),
          NarrativeEventSourceRef.outcomeReceived(
            NarrativeOutcomeRef(
              producerKind: NarrativeOutcomeProducerKind.scene,
              producerId: 'scene_a',
              outcomeId: 'done',
            ),
          ),
        ];

        for (final source in cases) {
          final controller = _controller();
          var snapshotReads = 0;
          final result = await controller.openMapForEvent(
            eventId: _eventId,
            groupContext:
                source.kind == NarrativeEventSourceKind.outcomeReceived
                ? const NarrativeEventGroupContext.global()
                : const NarrativeEventGroupContext.map('map_a'),
            mode: NarrativeEventMapNavigationMode.view,
            project: _project(source: source),
            activeMap: _mapA(),
            mapDirty: false,
            loadMapSnapshot: (_) async {
              snapshotReads++;
              return null;
            },
            activateMapSnapshot: (_) => true,
            applyFocus: (_) => true,
          );

          expect(result.status, NarrativeEventMapNavigationStatus.unavailable);
          expect(snapshotReads, 0);
          expect(controller.state.pendingReturn, isNull);
          expect(controller.state.focusRequest, isNull);
        }
      },
    );

    test(
      'clean cross-map navigation reads and activates one snapshot',
      () async {
        final controller = _controller();
        final snapshot = _mapB();
        var reads = 0;
        var activations = 0;
        MapData? activated;
        NarrativeEditorFocusTarget? focused;

        final result = await controller.openMapForEvent(
          eventId: _eventId,
          groupContext: const NarrativeEventGroupContext.map('map_b'),
          mode: NarrativeEventMapNavigationMode.view,
          project: _project(
            source: NarrativeEventSourceRef.triggerEnter('map_b', 'trigger_b'),
            maps: const [
              ProjectMapEntry(
                id: 'map_a',
                name: 'Map A',
                relativePath: 'maps/map_a.json',
              ),
              ProjectMapEntry(
                id: 'map_b',
                name: 'Map B',
                relativePath: 'maps/map_b.json',
              ),
            ],
          ),
          activeMap: _mapA(),
          mapDirty: false,
          loadMapSnapshot: (_) async {
            reads++;
            return snapshot;
          },
          activateMapSnapshot: (map) {
            activations++;
            activated = map;
            return true;
          },
          applyFocus: (focus) {
            focused = focus;
            return true;
          },
        );

        expect(result.status, NarrativeEventMapNavigationStatus.ready);
        expect(reads, 1);
        expect(activations, 1);
        expect(activated, same(snapshot));
        expect(focused?.kind, NarrativeEditorFocusTargetKind.trigger);
        expect(focused?.ownerId, 'trigger_b');
      },
    );

    test(
      'mapEnter focus has no fake owner and camera request is one-shot',
      () async {
        final controller = _controller();
        final result = await controller.openMapForEvent(
          eventId: _eventId,
          groupContext: const NarrativeEventGroupContext.map('map_a'),
          mode: NarrativeEventMapNavigationMode.view,
          project: _project(source: NarrativeEventSourceRef.mapEnter('map_a')),
          activeMap: _mapA(),
          mapDirty: false,
          loadMapSnapshot: (_) async => null,
          activateMapSnapshot: (_) => true,
          applyFocus: (_) => true,
        );
        final request = controller.state.focusRequest!;

        expect(result.status, NarrativeEventMapNavigationStatus.ready);
        expect(request.focusTarget.kind, NarrativeEditorFocusTargetKind.map);
        expect(request.focusTarget.ownerId, isNull);
        expect(controller.markFocusCameraApplied(request.requestId), isTrue);
        expect(controller.markFocusCameraApplied(request.requestId), isFalse);
        expect(controller.state.focusRequest?.cameraApplied, isTrue);
      },
    );

    test(
      'group mismatch and ambiguous owner refuse without changing workspace',
      () async {
        final mismatchController = _controller();
        var mismatchReads = 0;
        final mismatch = await mismatchController.openMapForEvent(
          eventId: _eventId,
          groupContext: const NarrativeEventGroupContext.map('map_b'),
          mode: NarrativeEventMapNavigationMode.view,
          project: _project(source: NarrativeEventSourceRef.mapEnter('map_a')),
          activeMap: _mapA(),
          mapDirty: false,
          loadMapSnapshot: (_) async {
            mismatchReads++;
            return null;
          },
          activateMapSnapshot: (_) => true,
          applyFocus: (_) => true,
        );
        expect(
          mismatch.status,
          NarrativeEventMapNavigationStatus.sourceMismatch,
        );
        expect(mismatchReads, 0);

        final ambiguousController = _controller();
        final ambiguous = await ambiguousController.openMapForEvent(
          eventId: _eventId,
          groupContext: const NarrativeEventGroupContext.map('map_a'),
          mode: NarrativeEventMapNavigationMode.view,
          project: _project(
            source: NarrativeEventSourceRef.entityInteract('map_a', 'entity_a'),
          ),
          activeMap: _mapA().copyWith(
            entities: [
              ..._mapA().entities,
              const MapEntity(
                id: 'entity_a',
                name: 'Duplicate',
                kind: MapEntityKind.npc,
                pos: GridPos(x: 7, y: 6),
              ),
            ],
          ),
          mapDirty: false,
          loadMapSnapshot: (_) async => null,
          activateMapSnapshot: (_) => true,
          applyFocus: (_) => true,
        );
        expect(ambiguous.status, NarrativeEventMapNavigationStatus.unavailable);
        expect(ambiguousController.state.pendingReturn, isNull);
      },
    );

    test(
      'cancel clears token/highlight and deleted Event never falls back',
      () async {
        final source = NarrativeEventSourceRef.mapEnter('map_a');
        final controller = _controller();
        await controller.openMapForEvent(
          eventId: _eventId,
          groupContext: const NarrativeEventGroupContext.map('map_a'),
          mode: NarrativeEventMapNavigationMode.choose,
          project: _project(source: source),
          activeMap: _mapA(),
          mapDirty: false,
          loadMapSnapshot: (_) async => null,
          activateMapSnapshot: (_) => true,
          applyFocus: (_) => true,
        );
        controller.cancelMapNavigation();
        expect(controller.state.pendingReturn, isNull);
        expect(controller.state.focusRequest, isNull);

        await controller.openMapForEvent(
          eventId: _eventId,
          groupContext: const NarrativeEventGroupContext.map('map_a'),
          mode: NarrativeEventMapNavigationMode.view,
          project: _project(source: source),
          activeMap: _mapA(),
          mapDirty: false,
          loadMapSnapshot: (_) async => null,
          activateMapSnapshot: (_) => true,
          applyFocus: (_) => true,
        );
        var opened = false;
        final returned = controller.returnToEvent(
          project: const ProjectManifest(
            name: 'Deleted event project',
            maps: [],
            tilesets: [],
          ),
          openExactEvent: ({required eventId, required groupContext}) {
            opened = true;
          },
        );
        expect(returned, isFalse);
        expect(opened, isFalse);
        expect(
          controller.state.lastNavigationResult?.status,
          NarrativeEventMapNavigationStatus.eventMissing,
        );
        expect(controller.state.selectedNarrativeEventV2Id, isNull);
      },
    );

    test(
      'choose preview accepts only an existing source and performs no write',
      () async {
        final controller = _controller();
        final map = _mapA().copyWith(
          triggers: [
            const MapTrigger(
              id: 'trigger_a',
              name: 'Trigger A',
              type: TriggerType.event,
              area: MapRect(
                pos: GridPos(x: 5, y: 4),
                size: GridSize(width: 1, height: 2),
              ),
            ),
          ],
        );
        final project = _project(
          source: NarrativeEventSourceRef.entityInteract('map_a', 'entity_a'),
        );
        await controller.openMapForEvent(
          eventId: _eventId,
          groupContext: const NarrativeEventGroupContext.map('map_a'),
          mode: NarrativeEventMapNavigationMode.choose,
          project: project,
          activeMap: map,
          mapDirty: false,
          loadMapSnapshot: (_) async => null,
          activateMapSnapshot: (_) => true,
          applyFocus: (_) => true,
        );

        final previewed = controller.previewChosenSource(
          project: project,
          map: map,
          source: NarrativeEventSourceRef.triggerEnter('map_a', 'trigger_a'),
        );
        final missing = controller.previewChosenSource(
          project: project,
          map: map,
          source: NarrativeEventSourceRef.triggerEnter('map_a', 'missing'),
        );

        expect(previewed, isTrue);
        expect(missing, isFalse);
        expect(
          controller.state.focusRequest?.source,
          NarrativeEventSourceRef.triggerEnter('map_a', 'trigger_a'),
        );
        expect(controller.state.pendingReturn?.eventId, _eventId);
      },
    );

    test('return rejects a different exact source on the same map', () async {
      final originalSource = NarrativeEventSourceRef.entityInteract(
        'map_a',
        'entity_a',
      );
      final controller = _controller();
      await controller.openMapForEvent(
        eventId: _eventId,
        groupContext: const NarrativeEventGroupContext.map('map_a'),
        mode: NarrativeEventMapNavigationMode.view,
        project: _project(source: originalSource),
        activeMap: _mapA(),
        mapDirty: false,
        loadMapSnapshot: (_) async => null,
        activateMapSnapshot: (_) => true,
        applyFocus: (_) => true,
      );
      var opened = false;

      final returned = controller.returnToEvent(
        project: _project(
          source: NarrativeEventSourceRef.triggerEnter('map_a', 'trigger_a'),
        ),
        openExactEvent: ({required eventId, required groupContext}) {
          opened = true;
        },
      );

      expect(returned, isFalse);
      expect(opened, isFalse);
      expect(controller.state.pendingReturn?.expectedSource, originalSource);
      expect(controller.state.pendingReturn, isNotNull);
      expect(controller.state.focusRequest, isNotNull);
      expect(
        controller.state.lastNavigationResult?.status,
        NarrativeEventMapNavigationStatus.sourceMismatch,
      );
    });

    test(
      'source-less draft keeps an explicit map group and is never global',
      () {
        final project = _project(source: null);
        final controller = _controller();

        expect(
          controller.selectNarrativeEventV2(
            project,
            _eventId,
            groupContext: const NarrativeEventGroupContext.map('map_a'),
          ),
          isTrue,
        );
        expect(
          controller.state.selectedGroupContext,
          const NarrativeEventGroupContext.map('map_a'),
        );

        final withoutContext = _controller();
        expect(
          withoutContext.selectNarrativeEventV2(project, _eventId),
          isTrue,
        );
        expect(withoutContext.state.selectedGroupContext, isNull);
      },
    );

    test(
      'source-less create flow returns to the exact draft before any write',
      () async {
        final project = _project(source: null);
        final controller = _controller();

        final openedMap = await controller.openMapForMissingSource(
          eventId: _eventId,
          groupContext: const NarrativeEventGroupContext.map('map_a'),
          project: project,
          activeMap: _mapA(),
          mapDirty: false,
          loadMapSnapshot: (_) async => null,
          activateMapSnapshot: (_) => true,
        );

        expect(openedMap.status, NarrativeEventMapNavigationStatus.ready);
        expect(controller.state.pendingReturn?.expectedSource, isNull);

        String? selectedEvent;
        NarrativeEventGroupContext? selectedGroup;
        final returned = controller.returnToEvent(
          project: project,
          openExactEvent: ({required eventId, required groupContext}) {
            selectedEvent = eventId;
            selectedGroup = groupContext;
          },
        );

        expect(returned, isTrue);
        expect(selectedEvent, _eventId);
        expect(selectedGroup, const NarrativeEventGroupContext.map('map_a'));
        expect(controller.state.pendingReturn, isNull);
      },
    );

    test(
      'double source submit writes once and cancel cannot clear in-flight token',
      () async {
        final project = _project(
          source: NarrativeEventSourceRef.entityInteract('map_a', 'entity_a'),
        );
        final fixture = await createPersistenceFixture(
          registry: project.eventRegistry,
          map: _mapA(),
        );
        addTearDown(fixture.dispose);
        final prepared = Completer<NarrativeEventAuthoringSession>();
        final gateway = _CountingGateway();
        final controller = mountNarrativeEventMapBridgeController(
          useCase: CreateNarrativeEventFromMapSourceUseCase(
            persistenceGateway: gateway,
          ),
          sourceLinkUseCase: NarrativeEventSpatialSourceLinkUseCase(
            persistenceGateway: gateway,
            prepareSession: (_) => prepared.future,
          ),
        );
        controller.bindProjectRootPath(fixture.root.path);
        await controller.openMapForEvent(
          eventId: _eventId,
          groupContext: const NarrativeEventGroupContext.map('map_a'),
          mode: NarrativeEventMapNavigationMode.choose,
          project: project,
          activeMap: _mapA(),
          mapDirty: false,
          loadMapSnapshot: (_) async => null,
          activateMapSnapshot: (_) => true,
          applyFocus: (_) => true,
        );

        final first = controller.linkChosenSource(
          projectRootPath: fixture.root.path,
          project: project,
          activeMap: _mapA(),
          source: NarrativeEventSourceRef.mapEnter('map_a'),
          mapDirty: false,
          projectDirty: false,
          saving: false,
          applyPersistedRegistry:
              ({
                required expectedProjectRootPath,
                required expectedPreviousRegistry,
                required nextRegistry,
              }) => true,
        );
        await Future<void>.delayed(Duration.zero);
        final token = controller.state.pendingReturn;

        final second = await controller.linkChosenSource(
          projectRootPath: fixture.root.path,
          project: project,
          activeMap: _mapA(),
          source: NarrativeEventSourceRef.mapEnter('map_a'),
          mapDirty: false,
          projectDirty: false,
          saving: false,
          applyPersistedRegistry:
              ({
                required expectedProjectRootPath,
                required expectedPreviousRegistry,
                required nextRegistry,
              }) => true,
        );
        controller.cancelMapNavigation();

        expect(controller.state.isLinkingSource, isTrue);
        expect(controller.state.pendingReturn, same(token));
        expect(second?.code, 'linkInProgress');
        prepared.complete(fixture.session);
        final firstResult = await first;

        expect(
          firstResult?.status,
          NarrativeEventSpatialSourceLinkStatus.committed,
        );
        expect(gateway.persistCalls, 1);
        expect(controller.state.isLinkingSource, isFalse);
      },
    );

    test(
      'same-root project replacement invalidates a delayed cross-map load',
      () async {
        final project = _project(
          source: NarrativeEventSourceRef.triggerEnter('map_b', 'trigger_b'),
          maps: const [
            ProjectMapEntry(
              id: 'map_a',
              name: 'Map A',
              relativePath: 'maps/map_a.json',
            ),
            ProjectMapEntry(
              id: 'map_b',
              name: 'Map B',
              relativePath: 'maps/map_b.json',
            ),
          ],
        );
        final controller = _controller();
        controller.bindProjectSession(
          projectRootPath: '/project',
          project: project,
        );
        final loaded = Completer<MapData?>();
        var activations = 0;
        final navigation = controller.openMapForEvent(
          eventId: _eventId,
          groupContext: const NarrativeEventGroupContext.map('map_b'),
          mode: NarrativeEventMapNavigationMode.view,
          project: project,
          activeMap: _mapA(),
          mapDirty: false,
          loadMapSnapshot: (_) => loaded.future,
          activateMapSnapshot: (_) {
            activations++;
            return true;
          },
          applyFocus: (_) => true,
        );
        await Future<void>.delayed(Duration.zero);

        controller.bindProjectSession(
          projectRootPath: '/project',
          project: project.copyWith(name: 'Reloaded project'),
        );
        loaded.complete(_mapB());
        final result = await navigation;

        expect(result.status, NarrativeEventMapNavigationStatus.unavailable);
        expect(activations, 0);
        expect(controller.state.pendingReturn, isNull);
        expect(controller.state.focusRequest, isNull);
      },
    );

    test(
      'same-root project replacement invalidates a delayed cross-map activation',
      () async {
        final project = _project(
          source: NarrativeEventSourceRef.triggerEnter('map_b', 'trigger_b'),
          maps: const [
            ProjectMapEntry(
              id: 'map_a',
              name: 'Map A',
              relativePath: 'maps/map_a.json',
            ),
            ProjectMapEntry(
              id: 'map_b',
              name: 'Map B',
              relativePath: 'maps/map_b.json',
            ),
          ],
        );
        final controller = _controller();
        controller.bindProjectSession(
          projectRootPath: '/project',
          project: project,
        );
        final activationStarted = Completer<void>();
        final releaseActivation = Completer<bool>();
        var focusCalls = 0;
        final navigation = controller.openMapForEvent(
          eventId: _eventId,
          groupContext: const NarrativeEventGroupContext.map('map_b'),
          mode: NarrativeEventMapNavigationMode.view,
          project: project,
          activeMap: _mapA(),
          mapDirty: false,
          loadMapSnapshot: (_) async => _mapB(),
          activateMapSnapshot: (_) {
            activationStarted.complete();
            return releaseActivation.future;
          },
          applyFocus: (_) {
            focusCalls++;
            return true;
          },
        );
        await activationStarted.future;

        controller.bindProjectSession(
          projectRootPath: '/project',
          project: project.copyWith(name: 'Reloaded during activation'),
        );
        releaseActivation.complete(true);
        final result = await navigation;

        expect(result.status, NarrativeEventMapNavigationStatus.unavailable);
        expect(focusCalls, 0);
        expect(controller.state.pendingReturn, isNull);
        expect(controller.state.focusRequest, isNull);
      },
    );

    test(
      'same-root project replacement wins over a stale failed activation',
      () async {
        final project = _project(
          source: NarrativeEventSourceRef.triggerEnter('map_b', 'trigger_b'),
          maps: const [
            ProjectMapEntry(
              id: 'map_a',
              name: 'Map A',
              relativePath: 'maps/map_a.json',
            ),
            ProjectMapEntry(
              id: 'map_b',
              name: 'Map B',
              relativePath: 'maps/map_b.json',
            ),
          ],
        );
        final controller = _controller();
        controller.bindProjectSession(
          projectRootPath: '/project',
          project: project,
        );
        final activationStarted = Completer<void>();
        final releaseActivation = Completer<bool>();
        final navigation = controller.openMapForEvent(
          eventId: _eventId,
          groupContext: const NarrativeEventGroupContext.map('map_b'),
          mode: NarrativeEventMapNavigationMode.view,
          project: project,
          activeMap: _mapA(),
          mapDirty: false,
          loadMapSnapshot: (_) async => _mapB(),
          activateMapSnapshot: (_) {
            activationStarted.complete();
            return releaseActivation.future;
          },
          applyFocus: (_) => true,
        );
        await activationStarted.future;

        controller.bindProjectSession(
          projectRootPath: '/project',
          project: project.copyWith(name: 'Reloaded during failed activation'),
        );
        releaseActivation.complete(false);
        final result = await navigation;

        expect(result.status, NarrativeEventMapNavigationStatus.unavailable);
        expect(controller.state.pendingReturn, isNull);
        expect(controller.state.focusRequest, isNull);
      },
    );

    test(
      'committed stale link remains explicit and is never silently dropped',
      () async {
        final project = _project(
          source: NarrativeEventSourceRef.entityInteract('map_a', 'entity_a'),
        );
        final fixture = await createPersistenceFixture(
          registry: project.eventRegistry,
          map: _mapA(),
        );
        addTearDown(fixture.dispose);
        final gateway = _BlockingCountingGateway();
        final controller = mountNarrativeEventMapBridgeController(
          useCase: CreateNarrativeEventFromMapSourceUseCase(
            persistenceGateway: gateway,
          ),
          sourceLinkUseCase: NarrativeEventSpatialSourceLinkUseCase(
            persistenceGateway: gateway,
            prepareSession: (_) async => fixture.session,
          ),
        );
        controller.bindProjectSession(
          projectRootPath: fixture.root.path,
          project: project,
        );
        await controller.openMapForEvent(
          eventId: _eventId,
          groupContext: const NarrativeEventGroupContext.map('map_a'),
          mode: NarrativeEventMapNavigationMode.choose,
          project: project,
          activeMap: _mapA(),
          mapDirty: false,
          loadMapSnapshot: (_) async => null,
          activateMapSnapshot: (_) => true,
          applyFocus: (_) => true,
        );
        final token = controller.state.pendingReturn;
        var adoptions = 0;

        final linking = controller.linkChosenSource(
          projectRootPath: fixture.root.path,
          project: project,
          activeMap: _mapA(),
          source: NarrativeEventSourceRef.mapEnter('map_a'),
          mapDirty: false,
          projectDirty: false,
          saving: false,
          applyPersistedRegistry:
              ({
                required expectedProjectRootPath,
                required expectedPreviousRegistry,
                required nextRegistry,
              }) {
                adoptions++;
                return true;
              },
        );
        while (gateway.persistCalls == 0) {
          await Future<void>.delayed(Duration.zero);
        }
        controller.bindProjectSession(
          projectRootPath: fixture.root.path,
          project: project.copyWith(name: 'Concurrent reload'),
        );
        gateway.completeCommitted();
        final result = await linking;

        expect(
          result?.status,
          NarrativeEventSpatialSourceLinkStatus.committedOutOfSync,
        );
        expect(adoptions, 0);
        expect(controller.state.pendingReturn, same(token));
        expect(controller.state.isLinkingSource, isFalse);
        expect(
          controller.state.lastSourceLinkResult?.status,
          NarrativeEventSpatialSourceLinkStatus.committedOutOfSync,
        );
      },
    );
  });

  group('NS-EVENT-V2-24 EditorNotifier map focus', () {
    test('same-map activation preserves the dirty document and viewport', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final active = _mapA();
      notifier.state = EditorState(
        project: _project(source: NarrativeEventSourceRef.mapEnter('map_a')),
        activeMap: active,
        activeMapPath: '/project/maps/map_a.json',
        isDirty: true,
        panOffset: const Offset(17, 23),
        zoom: 1.75,
      );

      final activated = notifier.activateNarrativeEventMapSnapshot(_mapA());

      expect(activated, isTrue);
      expect(notifier.state.activeMap, same(active));
      expect(notifier.state.isDirty, isTrue);
      expect(notifier.state.panOffset, const Offset(17, 23));
      expect(notifier.state.zoom, 1.75);
    });

    test(
      'focus selects one exact owner atomically without dirtying the map',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final notifier = container.read(editorNotifierProvider.notifier);
        final map = _mapA().copyWith(
          triggers: [
            const MapTrigger(
              id: 'trigger_a',
              name: 'Trigger A',
              type: TriggerType.event,
              area: MapRect(
                pos: GridPos(x: 5, y: 4),
                size: GridSize(width: 2, height: 1),
              ),
            ),
          ],
        );
        notifier.state = EditorState(
          activeMap: map,
          selectedTriggerId: 'trigger_a',
          savedMapSnapshot: map,
        );

        final entityFocused = notifier.focusNarrativeEventMapSource(
          NarrativeEditorFocusTarget.entity(
            'map_a',
            'entity_a',
            const MapRect(
              pos: GridPos(x: 3, y: 2),
              size: GridSize(width: 1, height: 1),
            ),
          ),
        );

        expect(entityFocused, isTrue);
        expect(notifier.state.selectedEntityId, 'entity_a');
        expect(notifier.state.selectedTriggerId, isNull);
        expect(notifier.state.isDirty, isFalse);

        final triggerFocused = notifier.focusNarrativeEventMapSource(
          NarrativeEditorFocusTarget.trigger(
            'map_a',
            'trigger_a',
            const MapRect(
              pos: GridPos(x: 5, y: 4),
              size: GridSize(width: 2, height: 1),
            ),
          ),
        );
        expect(triggerFocused, isTrue);
        expect(notifier.state.selectedEntityId, isNull);
        expect(notifier.state.selectedTriggerId, 'trigger_a');
        expect(notifier.state.isDirty, isFalse);
      },
    );

    test('one-shot pan setter changes only the viewport', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final map = _mapA();
      notifier.state = EditorState(
        activeMap: map,
        savedMapSnapshot: map,
        zoom: 2,
      );

      notifier.setNarrativeEventMapPanOffset(const Offset(-120, 45));

      expect(notifier.state.panOffset, const Offset(-120, 45));
      expect(notifier.state.zoom, 2);
      expect(notifier.state.activeMap, same(map));
      expect(notifier.state.isDirty, isFalse);
    });
  });
}

NarrativeEventMapBridgeController _controller() {
  return mountNarrativeEventMapBridgeController(
    useCase: CreateNarrativeEventFromMapSourceUseCase(
      persistenceGateway: _UnusedGateway(),
    ),
  );
}

ProjectManifest _project({
  required NarrativeEventSourceRef? source,
  List<ProjectMapEntry> maps = const [
    ProjectMapEntry(
      id: 'map_a',
      name: 'Map A',
      relativePath: 'maps/map_a.json',
    ),
  ],
}) {
  return ProjectManifest(
    name: 'Navigation project',
    maps: maps,
    tilesets: const [],
    scenes: const [],
    eventRegistry: NarrativeEventRegistry(
      schemaVersion: 1,
      mode: EventSystemMode.dualRead,
      records: [
        NarrativeEventRecord.draft(
          NarrativeEventDraft(
            id: _eventId,
            name: 'Rencontre au port',
            source: source,
            conditions: const [],
            priority: 0,
            order: 0,
          ),
        ),
      ],
      legacyClaims: const [],
    ),
  );
}

MapData _mapA() => const MapData(
  id: 'map_a',
  name: 'Map A',
  size: GridSize(width: 10, height: 8),
  layers: [ObjectLayer(id: 'objects', name: 'Objects')],
  entities: [
    MapEntity(
      id: 'entity_a',
      name: 'Rival',
      kind: MapEntityKind.npc,
      pos: GridPos(x: 3, y: 2),
    ),
  ],
);

MapData _mapB() => const MapData(
  id: 'map_b',
  name: 'Map B',
  size: GridSize(width: 12, height: 9),
  layers: [ObjectLayer(id: 'objects', name: 'Objects')],
  triggers: [
    MapTrigger(
      id: 'trigger_b',
      name: 'Entrée',
      type: TriggerType.event,
      area: MapRect(
        pos: GridPos(x: 4, y: 3),
        size: GridSize(width: 2, height: 2),
      ),
    ),
  ],
);

final class _UnusedGateway implements NarrativeEventRegistryPersistenceGateway {
  @override
  Future<NarrativeEventRegistryPersistenceResult> persist(
    NarrativeEventRegistryWriteRequest request,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<NarrativeEventRegistryRecoveryInspection> inspectRecovery(
    String projectPath,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<List<NarrativeEventRegistryPersistenceResult>> recover(
    String projectPath,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<NarrativeEventRegistryPersistenceResult> undo(String undoPath) {
    throw UnimplementedError();
  }
}

final class _CountingGateway
    implements NarrativeEventRegistryPersistenceGateway {
  int persistCalls = 0;

  @override
  Future<NarrativeEventRegistryPersistenceResult> persist(
    NarrativeEventRegistryWriteRequest request,
  ) async {
    persistCalls++;
    return NarrativeEventRegistryPersistenceResult(
      status: NarrativeEventRegistryPersistenceStatus.committed,
      code: 'committed',
      message: 'Committed.',
    );
  }

  @override
  Future<NarrativeEventRegistryRecoveryInspection> inspectRecovery(
    String projectPath,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<List<NarrativeEventRegistryPersistenceResult>> recover(
    String projectPath,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<NarrativeEventRegistryPersistenceResult> undo(String undoPath) {
    throw UnimplementedError();
  }
}

final class _BlockingCountingGateway
    implements NarrativeEventRegistryPersistenceGateway {
  int persistCalls = 0;
  final _completion = Completer<NarrativeEventRegistryPersistenceResult>();

  void completeCommitted() {
    _completion.complete(
      NarrativeEventRegistryPersistenceResult(
        status: NarrativeEventRegistryPersistenceStatus.committed,
        code: 'committed',
        message: 'Committed.',
      ),
    );
  }

  @override
  Future<NarrativeEventRegistryPersistenceResult> persist(
    NarrativeEventRegistryWriteRequest request,
  ) {
    persistCalls++;
    return _completion.future;
  }

  @override
  Future<NarrativeEventRegistryRecoveryInspection> inspectRecovery(
    String projectPath,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<List<NarrativeEventRegistryPersistenceResult>> recover(
    String projectPath,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<NarrativeEventRegistryPersistenceResult> undo(String undoPath) {
    throw UnimplementedError();
  }
}
