import 'dart:async';

import 'package:path/path.dart' as p;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/narrative/state/narrative_event_map_bridge_state.dart';
import 'package:map_editor/src/app/providers/core/repository_providers.dart';
import 'package:map_editor/src/application/models/narrative_event_registry_persistence_models.dart';
import 'package:map_editor/src/application/models/narrative_event_map_bridge_models.dart';
import 'package:map_editor/src/application/models/narrative_event_spatial_link_journal_models.dart';
import 'package:map_editor/src/application/ports/narrative_event_registry_persistence_gateway.dart';
import 'package:map_editor/src/application/ports/narrative_event_spatial_source_creation_gateway.dart';
import 'package:map_editor/src/application/use_cases/narrative_event_spatial_source_link_use_case.dart';
import 'package:map_editor/src/ui/canvas/events/narrative_event_map_return_panel.dart';
import 'package:map_editor/src/ui/canvas/map_canvas/narrative_event_map_banner.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';
import 'package:map_editor/src/ui/panels/narrative_event_map_bridge_panel.dart';
import 'package:map_editor/src/ui/shared/pokemap_macos_ui_shim.dart';

import 'support/event_registry_persistence_fixtures.dart';

const _eventId = 'evt_019abcde-0000-7000-8000-000000000331';

void main() {
  group('NS-EVENT-V2-24 Event to Map return widget flow', () {
    testWidgets('same-map dirty flow returns to the exact V2 Event and group',
        (tester) async {
      final source =
          NarrativeEventSourceRef.entityInteract('map_a', 'entity_a');
      final project = _project(source);
      final container = _container();
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        projectRootPath: '/project',
        project: project,
        workspaceMode: EditorWorkspaceMode.events,
        activeMap: _map(),
        activeMapPath: '/project/maps/map_a.json',
        savedMapSnapshot: _map(),
        isDirty: true,
      );
      final controller =
          container.read(narrativeEventMapBridgeControllerProvider.notifier);
      expect(controller.selectNarrativeEventV2(project, _eventId), isTrue);

      await _pumpFlow(tester, container);
      await tester.tap(
        find.byKey(const ValueKey('narrative-event-view-on-map')),
      );
      await tester.pumpAndSettle();

      expect(notifier.state.workspaceMode, EditorWorkspaceMode.map);
      expect(notifier.state.isDirty, isTrue);
      expect(notifier.state.activeMap?.id, 'map_a');
      expect(controller.state.pendingReturn?.eventId, _eventId);
      expect(
        controller.state.pendingReturn?.groupContext.mapId,
        'map_a',
      );
      expect(find.byKey(const ValueKey('narrative-event-map-banner')),
          findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('narrative-event-map-return')),
      );
      await tester.pumpAndSettle();

      expect(notifier.state.workspaceMode, EditorWorkspaceMode.events);
      expect(controller.state.selectedNarrativeEventV2Id, _eventId);
      expect(controller.state.selectedGroupContext?.mapId, 'map_a');
      expect(controller.state.pendingReturn, isNull);
      expect(controller.state.focusRequest, isNull);
    });

    testWidgets('nonspatial Event exposes no map CTA', (tester) async {
      final project = _project(
        NarrativeEventSourceRef.outcomeReceived(
          NarrativeOutcomeRef(
            producerKind: NarrativeOutcomeProducerKind.scene,
            producerId: 'scene_a',
            outcomeId: 'done',
          ),
        ),
      );
      final container = _container();
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        project: project,
        workspaceMode: EditorWorkspaceMode.events,
        activeMap: _map(),
      );
      final controller =
          container.read(narrativeEventMapBridgeControllerProvider.notifier);
      expect(controller.selectNarrativeEventV2(project, _eventId), isTrue);

      await _pumpFlow(tester, container);

      expect(
        find.byKey(const ValueKey('narrative-event-view-on-map')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('narrative-event-choose-on-map')),
        findsNothing,
      );
      expect(find.textContaining('global'), findsWidgets);
    });

    testWidgets(
        'source-less map draft shows a missing-source diagnostic without map navigation',
        (tester) async {
      final project = _project(null);
      final container = _container();
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        project: project,
        workspaceMode: EditorWorkspaceMode.events,
        activeMap: _map(),
      );
      final controller =
          container.read(narrativeEventMapBridgeControllerProvider.notifier);
      expect(
        controller.selectNarrativeEventV2(
          project,
          _eventId,
          groupContext: const NarrativeEventGroupContext.map('map_a'),
        ),
        isTrue,
      );

      await _pumpFlow(tester, container);

      expect(find.textContaining('Source manquante'), findsOneWidget);
      expect(find.textContaining('Event global'), findsNothing);
      expect(
        find.byKey(const ValueKey('narrative-event-view-on-map')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('narrative-event-choose-on-map')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('narrative-event-create-source-on-map')),
        findsOneWidget,
      );
    });

    testWidgets('choose mode proposes selected source and map without picker',
        (tester) async {
      final project = _project(
        NarrativeEventSourceRef.entityInteract('map_a', 'entity_a'),
      );
      final container = _container();
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        projectRootPath: '/project',
        project: project,
        workspaceMode: EditorWorkspaceMode.events,
        activeMap: _map(),
        selectedEntityId: 'entity_a',
      );
      final controller =
          container.read(narrativeEventMapBridgeControllerProvider.notifier);
      expect(controller.selectNarrativeEventV2(project, _eventId), isTrue);
      await _pumpFlow(tester, container);

      await tester.tap(
        find.byKey(const ValueKey('narrative-event-choose-on-map')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const ValueKey('narrative-event-choose-source-entity-entity_a'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey('narrative-event-choose-source-map-map_a'),
        ),
        findsOneWidget,
      );
      expect(find.textContaining('layerId'), findsNothing);
      expect(find.textContaining('coordonnée'), findsNothing);
    });

    testWidgets('candidate confirmation persists once and returns exactly',
        (tester) async {
      final project = _project(
        NarrativeEventSourceRef.entityInteract('map_a', 'entity_a'),
      );
      final fixture = (await tester.runAsync(
        () => createPersistenceFixture(
          registry: project.eventRegistry,
          map: _map(),
        ),
      ))!;
      addTearDown(() => tester.runAsync(fixture.dispose));
      final gateway = _RecordingGateway();
      final container = _container(
        gateway: gateway,
        sourceLinkUseCase: NarrativeEventSpatialSourceLinkUseCase(
          persistenceGateway: gateway,
          prepareSession: (_) async => fixture.session,
        ),
      );
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        projectRootPath: p.dirname(fixture.projectPath),
        project: project,
        workspaceMode: EditorWorkspaceMode.events,
        activeMap: _map(),
        activeMapPath: p.join(
          p.dirname(fixture.projectPath),
          'maps',
          'map_a.json',
        ),
        savedMapSnapshot: _map(),
        selectedEntityId: 'entity_a',
      );
      final controller =
          container.read(narrativeEventMapBridgeControllerProvider.notifier);
      expect(controller.selectNarrativeEventV2(project, _eventId), isTrue);
      await _pumpFlow(tester, container);
      await tester.tap(
        find.byKey(const ValueKey('narrative-event-choose-on-map')),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(
          const ValueKey('narrative-event-choose-source-map-map_a'),
        ),
      );
      await tester.pumpAndSettle();

      expect(gateway.requests, hasLength(1));
      expect(notifier.state.workspaceMode, EditorWorkspaceMode.events);
      expect(controller.state.selectedNarrativeEventV2Id, _eventId);
      expect(controller.state.pendingReturn, isNull);
      expect(
        notifier
            .state.project!.eventRegistry!.records.single.draftOrNull!.source,
        NarrativeEventSourceRef.mapEnter('map_a'),
      );
    });

    testWidgets(
        'source link disables repeat and cancel actions while one write is in flight',
        (tester) async {
      final project = _project(
        NarrativeEventSourceRef.entityInteract('map_a', 'entity_a'),
      );
      final fixture = (await tester.runAsync(
        () => createPersistenceFixture(
          registry: project.eventRegistry,
          map: _map(),
        ),
      ))!;
      addTearDown(() => tester.runAsync(fixture.dispose));
      final gateway = _BlockingGateway();
      final container = _container(
        gateway: gateway,
        sourceLinkUseCase: NarrativeEventSpatialSourceLinkUseCase(
          persistenceGateway: gateway,
          prepareSession: (_) async => fixture.session,
        ),
      );
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        projectRootPath: p.dirname(fixture.projectPath),
        project: project,
        workspaceMode: EditorWorkspaceMode.events,
        activeMap: _map(),
        savedMapSnapshot: _map(),
        selectedEntityId: 'entity_a',
      );
      final controller =
          container.read(narrativeEventMapBridgeControllerProvider.notifier);
      expect(controller.selectNarrativeEventV2(project, _eventId), isTrue);
      await _pumpFlow(tester, container);
      await tester.tap(
        find.byKey(const ValueKey('narrative-event-choose-on-map')),
      );
      await tester.pumpAndSettle();

      final mapAction = find.byKey(
        const ValueKey('narrative-event-choose-source-map-map_a'),
      );
      await tester.tap(mapAction);
      await tester.pump();
      final token = controller.state.pendingReturn;

      expect(gateway.requests, hasLength(1));
      expect(controller.state.isLinkingSource, isTrue);
      expect(tester.widget<PokeMapButton>(mapAction).onPressed, isNull);
      expect(
        tester
            .widget<PokeMapButton>(
              find.byKey(const ValueKey('narrative-event-map-cancel')),
            )
            .onPressed,
        isNull,
      );
      await tester.tap(mapAction);
      controller.cancelMapNavigation();
      await tester.pump();
      expect(gateway.requests, hasLength(1));
      expect(controller.state.pendingReturn, same(token));

      gateway.completeCommitted();
      await tester.pumpAndSettle();
      expect(controller.state.isLinkingSource, isFalse);
      expect(notifier.state.workspaceMode, EditorWorkspaceMode.events);
    });

    testWidgets(
        'deleted Event while away shows diagnostic and never falls back',
        (tester) async {
      final project = _project(
        NarrativeEventSourceRef.entityInteract('map_a', 'entity_a'),
      );
      final container = _container();
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        project: project,
        workspaceMode: EditorWorkspaceMode.events,
        activeMap: _map(),
      );
      final controller =
          container.read(narrativeEventMapBridgeControllerProvider.notifier);
      expect(controller.selectNarrativeEventV2(project, _eventId), isTrue);
      await _pumpFlow(tester, container);
      await tester.tap(
        find.byKey(const ValueKey('narrative-event-view-on-map')),
      );
      await tester.pumpAndSettle();

      notifier.state = notifier.state.copyWith(
        project: project.copyWith(
          eventRegistry: NarrativeEventRegistry(
            schemaVersion: 1,
            mode: EventSystemMode.dualRead,
            records: const [],
            legacyClaims: const [],
          ),
        ),
      );
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey('narrative-event-map-return')),
      );
      await tester.pump();

      expect(notifier.state.workspaceMode, EditorWorkspaceMode.map);
      expect(controller.state.selectedNarrativeEventV2Id, isNull);
      expect(controller.state.pendingReturn, isNotNull);
      expect(controller.state.focusRequest, isNotNull);
      expect(
        controller.state.lastNavigationResult?.status,
        NarrativeEventMapNavigationStatus.eventMissing,
      );
      expect(find.textContaining('supprimé'), findsWidgets);
    });
  });
}

ProviderContainer _container({
  NarrativeEventRegistryPersistenceGateway? gateway,
  NarrativeEventSpatialSourceLinkUseCase? sourceLinkUseCase,
}) {
  final container = ProviderContainer(
    overrides: [
      narrativeEventSpatialSourceCreationGatewayProvider.overrideWithValue(
        _ClearSourceCreationGateway(),
      ),
      if (gateway != null)
        narrativeEventRegistryPersistenceGatewayProvider.overrideWithValue(
          gateway,
        ),
      if (sourceLinkUseCase != null)
        narrativeEventSpatialSourceLinkUseCaseProvider.overrideWithValue(
          sourceLinkUseCase,
        ),
    ],
  );
  final editor = container.listen<EditorState>(
    editorNotifierProvider,
    (_, __) {},
    fireImmediately: true,
  );
  final bridge = container.listen<NarrativeEventMapBridgeState>(
    narrativeEventMapBridgeControllerProvider,
    (_, __) {},
    fireImmediately: true,
  );
  addTearDown(() {
    bridge.close();
    editor.close();
    container.dispose();
  });
  return container;
}

final class _ClearSourceCreationGateway
    implements NarrativeEventSpatialSourceCreationGateway {
  @override
  Future<NarrativeEventSpatialLinkInspection> inspectProject(
    String projectPath,
  ) async {
    return NarrativeEventSpatialLinkInspection(
      status: NarrativeEventSpatialLinkInspectionStatus.clear,
    );
  }

  @override
  Future<NarrativeEventSpatialLinkOperationResult> commitMap(
    NarrativeEventSpatialLinkMapCommitRequest request,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<NarrativeEventSpatialLinkOperationResult> recoverProject({
    required String projectPath,
    required String expectedOperationId,
    required String expectedEventId,
    required String expectedMapId,
    required NarrativeEventSourceRef expectedSource,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<NarrativeEventSpatialLinkOperationResult> markEventCommitted({
    required String projectPath,
    required String operationId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<NarrativeEventSpatialLinkOperationResult> acknowledgeEventCommitted({
    required String projectPath,
    required String operationId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<NarrativeEventSpatialLinkOperationResult> cleanupSource({
    required String projectPath,
    required String operationId,
    required bool confirmed,
  }) {
    throw UnimplementedError();
  }
}

Future<void> _pumpFlow(
  WidgetTester tester,
  ProviderContainer container,
) async {
  await tester.binding.setSurfaceSize(const Size(900, 700));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MacosTheme(
        data: MacosThemeData.light(),
        child: const MaterialApp(
          home: CupertinoPageScaffold(
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.bottomCenter,
                  child: NarrativeEventMapReturnPanel(),
                ),
                Positioned(
                  left: 12,
                  top: 12,
                  child: NarrativeEventMapBanner(),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: 330,
                    child: NarrativeEventMapBridgePanel(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

ProjectManifest _project(NarrativeEventSourceRef? source) {
  return ProjectManifest(
    name: 'Flow project',
    maps: const [
      ProjectMapEntry(
        id: 'map_a',
        name: 'Map A',
        relativePath: 'maps/map_a.json',
      ),
    ],
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

MapData _map() => const MapData(
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

final class _RecordingGateway
    implements NarrativeEventRegistryPersistenceGateway {
  final List<NarrativeEventRegistryWriteRequest> requests = [];

  @override
  Future<NarrativeEventRegistryPersistenceResult> persist(
    NarrativeEventRegistryWriteRequest request,
  ) async {
    requests.add(request);
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

final class _BlockingGateway
    implements NarrativeEventRegistryPersistenceGateway {
  final requests = <NarrativeEventRegistryWriteRequest>[];
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
    requests.add(request);
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
