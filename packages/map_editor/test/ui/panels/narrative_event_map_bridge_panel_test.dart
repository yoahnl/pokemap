import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/narrative/state/narrative_event_map_bridge_state.dart';
import 'package:map_editor/src/application/models/narrative_event_registry_persistence_models.dart';
import 'package:map_editor/src/application/ports/narrative_event_registry_persistence_gateway.dart';
import 'package:map_editor/src/application/use_cases/create_narrative_event_from_map_source_use_case.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';
import 'package:map_editor/src/ui/panels/map_inspector_panel.dart';
import 'package:map_editor/src/ui/panels/narrative_event_map_bridge_panel.dart';

import '../../support/event_registry_persistence_fixtures.dart';

const _eventA = 'evt_019abcde-0000-7000-8000-000000000401';
const _eventB = 'evt_019abcde-0000-7000-8000-000000000402';
const _additionalEvent = 'evt_019abcde-0000-7000-8000-000000000499';

void main() {
  group('NS-EVENT-V2-23 Map Inspector bridge panel', () {
    testWidgets('offers map, selected eligible entity and trigger actions',
        (tester) async {
      final container = _testContainer();
      container.read(editorNotifierProvider.notifier).state = EditorState(
        projectRootPath: '/tmp/v2_23_panel',
        project: _project(),
        activeMap: _sourceMap(),
        selectedEntityId: 'entity_a',
        selectedTriggerId: 'trigger_a',
        selectedMapEventId: 'legacy_event',
      );

      await _pumpPanel(tester, container);

      expect(
        find.byKey(const ValueKey('narrative-event-map-source-map-map_a')),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey('narrative-event-map-source-entity-entity_a'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey('narrative-event-map-source-trigger-trigger_a'),
        ),
        findsOneWidget,
      );
      expect(find.byType(PokeMapPanel), findsOneWidget);
      expect(find.byType(PokeMapButton), findsNWidgets(3));

      await tester.tap(
        find.byKey(
          const ValueKey('narrative-event-map-source-entity-entity_a'),
        ),
      );
      await tester.pump();
      expect(
        container
            .read(narrativeEventMapBridgeControllerProvider)
            .pendingIntent
            ?.source,
        NarrativeEventSourceRef.entityInteract('map_a', 'entity_a'),
      );
      expect(
        container.read(editorNotifierProvider).selectedMapEventId,
        'legacy_event',
      );

      await tester.tap(
        find.byKey(const ValueKey('narrative-event-map-bridge-cancel')),
      );
      await tester.pump();
      expect(
        container.read(narrativeEventMapBridgeControllerProvider).pendingIntent,
        isNull,
      );

      await tester.tap(
        find.byKey(
          const ValueKey('narrative-event-map-source-trigger-trigger_a'),
        ),
      );
      await tester.pump();
      expect(
        container
            .read(narrativeEventMapBridgeControllerProvider)
            .pendingIntent
            ?.source,
        NarrativeEventSourceRef.triggerEnter('map_a', 'trigger_a'),
      );
    });

    testWidgets('hides spawn and system trigger actions', (tester) async {
      final container = _testContainer();
      container.read(editorNotifierProvider.notifier).state = EditorState(
        projectRootPath: '/tmp/v2_23_panel',
        project: _project(),
        activeMap: _sourceMap(
          entityKind: MapEntityKind.spawn,
          triggerType: TriggerType.camera,
        ),
        selectedEntityId: 'entity_a',
        selectedTriggerId: 'trigger_a',
      );

      await _pumpPanel(tester, container);

      expect(
        find.byKey(const ValueKey('narrative-event-map-source-map-map_a')),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey('narrative-event-map-source-entity-entity_a'),
        ),
        findsNothing,
      );
      expect(
        find.byKey(
          const ValueKey('narrative-event-map-source-trigger-trigger_a'),
        ),
        findsNothing,
      );
    });

    testWidgets('contains no map, layer, coordinate, or raw ID form input',
        (tester) async {
      final container = _testContainer();
      container.read(editorNotifierProvider.notifier).state = EditorState(
        projectRootPath: '/tmp/v2_23_panel',
        project: _project(),
        activeMap: _sourceMap(),
        selectedEntityId: 'entity_a',
        selectedTriggerId: 'trigger_a',
      );

      await _pumpPanel(tester, container);

      expect(find.byType(TextField), findsNothing);
      expect(find.byType(CupertinoTextField), findsNothing);
      expect(find.textContaining('layerId'), findsNothing);
      expect(find.textContaining('coordonnée'), findsNothing);
      expect(find.textContaining('Carte cible'), findsNothing);
      expect(find.textContaining('ID technique'), findsNothing);
    });

    testWidgets('lists every existing link without writing a duplicate',
        (tester) async {
      final source = NarrativeEventSourceRef.entityInteract(
        'map_a',
        'entity_a',
      );
      final fixture = (await tester.runAsync(
        () => createPersistenceFixture(
          registry: _existingRegistry(source),
          map: _sourceMap(),
        ),
      ))!;
      addTearDown(() => tester.runAsync(fixture.dispose));
      final beforeBytes = (await tester.runAsync(
        () => File(fixture.projectPath).readAsBytes(),
      ))!;
      final gateway = _NeverWriteGateway();
      final container = _testContainer(overrides: [
        createNarrativeEventFromMapSourceUseCaseProvider.overrideWithValue(
          CreateNarrativeEventFromMapSourceUseCase(
            persistenceGateway: gateway,
            prepareSession: (_) async => fixture.session,
          ),
        ),
      ]);
      final project = _project().copyWith(
        eventRegistry: _existingRegistry(source),
      );
      container.read(editorNotifierProvider.notifier).state = EditorState(
        projectRootPath: fixture.root.path,
        project: project,
        activeMap: _sourceMap(),
        selectedEntityId: 'entity_a',
        selectedMapEventId: 'legacy_event',
      );
      await _pumpPanel(tester, container);

      await tester.tap(
        find.byKey(
          const ValueKey('narrative-event-map-source-entity-entity_a'),
        ),
      );
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey('narrative-event-map-bridge-confirm')),
      );
      await tester.pump();
      await tester.pump();
      expect(
        container.read(narrativeEventMapBridgeControllerProvider).isSubmitting,
        isFalse,
      );

      expect(
        find.byKey(const ValueKey('narrative-event-map-existing-$_eventA')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('narrative-event-map-existing-$_eventB')),
        findsOneWidget,
      );
      expect(gateway.persistCalls, 0);
      expect(
        await tester.runAsync(
          () => File(fixture.projectPath).readAsBytes(),
        ),
        beforeBytes,
      );
      expect(
        container
            .read(narrativeEventMapBridgeControllerProvider)
            .selectedNarrativeEventV2Id,
        isNull,
      );

      await tester.tap(
        find.byKey(const ValueKey('narrative-event-map-existing-$_eventB')),
      );
      await tester.pump();
      expect(
        container
            .read(narrativeEventMapBridgeControllerProvider)
            .selectedNarrativeEventV2Id,
        _eventB,
      );
      expect(
        container.read(editorNotifierProvider).selectedMapEventId,
        'legacy_event',
      );

      await tester.tap(
        find.byKey(const ValueKey('narrative-event-map-existing-back')),
      );
      await tester.pump();
      expect(gateway.persistCalls, 0);
      expect(
        find.byKey(
          const ValueKey('narrative-event-map-source-entity-entity_a'),
        ),
        findsOneWidget,
      );
    });

    testWidgets(
        'additional Event action requires explicit no-code confirmation and writes once',
        (tester) async {
      final source = NarrativeEventSourceRef.entityInteract(
        'map_a',
        'entity_a',
      );
      final fixture = (await tester.runAsync(
        () => createPersistenceFixture(
          registry: _existingRegistry(source),
          map: _sourceMap(),
        ),
      ))!;
      addTearDown(() => tester.runAsync(fixture.dispose));
      final gateway = _RecordingWriteGateway();
      final container = _testContainer(overrides: [
        createNarrativeEventFromMapSourceUseCaseProvider.overrideWithValue(
          CreateNarrativeEventFromMapSourceUseCase(
            persistenceGateway: gateway,
            prepareSession: (_) async => fixture.session,
            eventIdGeneratorFactory: () => NarrativeEventIdGenerator(
              rawUuidFactory: () => _additionalEvent.substring(4),
            ),
            operationIdFactory: () => 'v2_23_additional',
          ),
        ),
      ]);
      container.read(editorNotifierProvider.notifier).state = EditorState(
        projectRootPath: fixture.root.path,
        project: _project().copyWith(eventRegistry: _existingRegistry(source)),
        activeMap: _sourceMap(),
        selectedEntityId: 'entity_a',
      );
      await _pumpPanel(tester, container);

      await tester.tap(
        find.byKey(
          const ValueKey('narrative-event-map-source-entity-entity_a'),
        ),
      );
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey('narrative-event-map-bridge-confirm')),
      );
      await tester.pump();
      await tester.pump();

      expect(gateway.persistCalls, 0);
      expect(
        find.byKey(
          const ValueKey('narrative-event-map-existing-create-additional'),
        ),
        findsOneWidget,
      );
      expect(find.text('Créer un Event supplémentaire'), findsOneWidget);
      expect(find.textContaining(_eventA), findsNothing);
      expect(find.textContaining(_eventB), findsNothing);

      await tester.tap(
        find.byKey(
          const ValueKey('narrative-event-map-existing-create-additional'),
        ),
      );
      await tester.pump();
      expect(find.text('Confirmer l’Event supplémentaire'), findsOneWidget);
      expect(find.text('Créer l’Event supplémentaire'), findsOneWidget);
      expect(gateway.persistCalls, 0);

      await tester.tap(
        find.byKey(const ValueKey('narrative-event-map-bridge-cancel')),
      );
      await tester.pump();
      expect(
        find.byKey(
          const ValueKey('narrative-event-map-existing-create-additional'),
        ),
        findsOneWidget,
      );
      expect(gateway.persistCalls, 0);

      await tester.tap(
        find.byKey(
          const ValueKey('narrative-event-map-existing-create-additional'),
        ),
      );
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey('narrative-event-map-bridge-confirm')),
      );
      await tester.pump();
      await tester.pump();

      expect(gateway.persistCalls, 1);
      expect(gateway.requests, hasLength(1));
      final created = gateway.requests.single.nextRegistry.records
          .singleWhere((record) => record.id == _additionalEvent)
          .draftOrNull!;
      expect(created.source, source);
      expect(
        container
            .read(narrativeEventMapBridgeControllerProvider)
            .selectedNarrativeEventV2Id,
        _additionalEvent,
      );
    });

    testWidgets('out-of-sync recovery blocks reload while dirty and can cancel',
        (tester) async {
      final source = NarrativeEventSourceRef.mapEnter('map_a');
      final fixture = (await tester.runAsync(
        () => createPersistenceFixture(
          registry: persistenceRegistry(
            records: [],
            mode: EventSystemMode.dualRead,
          ),
          map: _sourceMap(),
        ),
      ))!;
      addTearDown(() => tester.runAsync(fixture.dispose));
      final gateway = _RecordingWriteGateway();
      final container = _testContainer(overrides: [
        createNarrativeEventFromMapSourceUseCaseProvider.overrideWithValue(
          CreateNarrativeEventFromMapSourceUseCase(
            persistenceGateway: gateway,
            prepareSession: (_) async => fixture.session,
            eventIdGeneratorFactory: () => NarrativeEventIdGenerator(
              rawUuidFactory: () => _additionalEvent.substring(4),
            ),
            operationIdFactory: () => 'v2_23_out_of_sync_cancel',
          ),
        ),
      ]);
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        projectRootPath: fixture.root.path,
        project: _project().copyWith(
          eventRegistry: _existingRegistry(source),
        ),
        activeMap: _sourceMap(),
      );
      await _pumpPanel(tester, container);

      await tester.tap(
        find.byKey(const ValueKey('narrative-event-map-source-map-map_a')),
      );
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey('narrative-event-map-bridge-confirm')),
      );
      await tester.pump();
      await tester.pump();

      expect(
        container.read(narrativeEventMapBridgeControllerProvider).recovery,
        isNotNull,
      );
      expect(find.text('Recharger le projet'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('narrative-event-map-recovery-reload')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('narrative-event-map-recovery-cancel')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('narrative-event-map-bridge-confirm')),
        findsNothing,
      );

      notifier.state = notifier.state.copyWith(isDirty: true);
      await tester.pump();
      expect(
        tester
            .widget<PokeMapButton>(
              find.byKey(
                const ValueKey('narrative-event-map-recovery-reload'),
              ),
            )
            .onPressed,
        isNull,
      );

      notifier.state = notifier.state.copyWith(
        isDirty: false,
        isProjectDirty: true,
      );
      await tester.pump();
      expect(
        tester
            .widget<PokeMapButton>(
              find.byKey(
                const ValueKey('narrative-event-map-recovery-reload'),
              ),
            )
            .onPressed,
        isNull,
      );

      notifier.state = notifier.state.copyWith(
        isProjectDirty: false,
        isSaving: true,
      );
      await tester.pump();
      expect(
        tester
            .widget<PokeMapButton>(
              find.byKey(
                const ValueKey('narrative-event-map-recovery-reload'),
              ),
            )
            .onPressed,
        isNull,
      );

      notifier.state = notifier.state.copyWith(isSaving: false);
      await tester.pump();
      expect(
        tester
            .widget<PokeMapButton>(
              find.byKey(
                const ValueKey('narrative-event-map-recovery-reload'),
              ),
            )
            .onPressed,
        isNotNull,
      );

      await tester.tap(
        find.byKey(const ValueKey('narrative-event-map-recovery-cancel')),
      );
      await tester.pump();
      expect(
        container.read(narrativeEventMapBridgeControllerProvider).recovery,
        isNull,
      );
      expect(
        container.read(narrativeEventMapBridgeControllerProvider).pendingIntent,
        isNull,
      );
      expect(gateway.persistCalls, 1);
    });

    testWidgets('gateway exception restores actions with a human message',
        (tester) async {
      final fixture = (await tester.runAsync(
        () => createPersistenceFixture(map: _sourceMap()),
      ))!;
      addTearDown(() => tester.runAsync(fixture.dispose));
      final gateway = _ThrowingPanelGateway();
      final container = _testContainer(overrides: [
        createNarrativeEventFromMapSourceUseCaseProvider.overrideWithValue(
          CreateNarrativeEventFromMapSourceUseCase(
            persistenceGateway: gateway,
            prepareSession: (_) async => fixture.session,
          ),
        ),
      ]);
      container.read(editorNotifierProvider.notifier).state = EditorState(
        projectRootPath: fixture.root.path,
        project: _project(),
        activeMap: _sourceMap(),
      );
      await _pumpPanel(tester, container);

      await tester.tap(
        find.byKey(const ValueKey('narrative-event-map-source-map-map_a')),
      );
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey('narrative-event-map-bridge-confirm')),
      );
      await tester.pump();
      await tester.pump();

      expect(
        container.read(narrativeEventMapBridgeControllerProvider).isSubmitting,
        isFalse,
      );
      expect(find.textContaining('n’a pas pu être enregistré'), findsOneWidget);
      expect(
        tester
            .widget<PokeMapButton>(
              find.byKey(
                const ValueKey('narrative-event-map-bridge-confirm'),
              ),
            )
            .onPressed,
        isNotNull,
      );
      expect(gateway.persistCalls, 1);
    });

    testWidgets('MapEvent inspector remains separate and visibly legacy',
        (tester) async {
      final container = _testContainer();
      container.read(editorNotifierProvider.notifier).state = EditorState(
        projectRootPath: '/tmp/v2_23_panel',
        project: _project(),
        activeMap: _sourceMap(includeLegacyEvent: true),
        selectedMapEventId: 'legacy_event',
      );

      await _pump(
        tester,
        container,
        const SizedBox(width: 420, height: 900, child: MapInspectorPanel()),
      );

      expect(find.textContaining('Legacy'), findsWidgets);
      expect(find.text('Événements de carte'), findsOneWidget);
      expect(find.byType(NarrativeEventMapBridgePanel), findsOneWidget);
    });
  });
}

ProviderContainer _testContainer({
  List<Override> overrides = const [],
}) {
  final container = ProviderContainer(overrides: overrides);
  final keepAlive = container.listen<EditorState>(
    editorNotifierProvider,
    (_, __) {},
  );
  addTearDown(() {
    keepAlive.close();
    container.dispose();
  });
  return container;
}

Future<void> _pumpPanel(
  WidgetTester tester,
  ProviderContainer container,
) {
  return _pump(
    tester,
    container,
    const SizedBox(
      width: 400,
      child: NarrativeEventMapBridgePanel(),
    ),
  );
}

Future<void> _pump(
  WidgetTester tester,
  ProviderContainer container,
  Widget child,
) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: PokeMapTheme.dark(),
        builder: (context, innerChild) => PokeMapMacosCompatibilityBridge(
          child: innerChild ?? const SizedBox.shrink(),
        ),
        home: Scaffold(body: child),
      ),
    ),
  );
  await tester.pump();
}

ProjectManifest _project() => ProjectManifest(
      name: 'Bridge panel project',
      maps: const [
        ProjectMapEntry(
          id: 'map_a',
          name: 'Port Selbrume',
          relativePath: 'maps/map_a.json',
        ),
      ],
      tilesets: const [],
      scenes: [persistenceScene()],
    );

MapData _sourceMap({
  MapEntityKind entityKind = MapEntityKind.npc,
  TriggerType triggerType = TriggerType.event,
  bool includeLegacyEvent = false,
}) {
  return MapData(
    id: 'map_a',
    name: 'Port Selbrume',
    size: const GridSize(width: 8, height: 6),
    layers: const [ObjectLayer(id: 'objects', name: 'Objets')],
    entities: [
      MapEntity(
        id: 'entity_a',
        name: 'Rival',
        kind: entityKind,
        pos: const GridPos(x: 2, y: 2),
      ),
    ],
    triggers: [
      MapTrigger(
        id: 'trigger_a',
        name: 'Zone du port',
        type: triggerType,
        area: const MapRect(
          pos: GridPos(x: 4, y: 3),
          size: GridSize(width: 2, height: 1),
        ),
      ),
    ],
    events: includeLegacyEvent
        ? const [
            MapEventDefinition(
              id: 'legacy_event',
              title: 'Ancien Event',
              position: EventPosition(layerId: 'objects', x: 1, y: 1),
              pages: [MapEventPage(pageNumber: 0)],
            ),
          ]
        : const [],
  );
}

NarrativeEventRegistry _existingRegistry(NarrativeEventSourceRef source) {
  return NarrativeEventRegistry(
    schemaVersion: 1,
    mode: EventSystemMode.dualRead,
    records: [
      NarrativeEventRecord.draft(
        NarrativeEventDraft(
          id: _eventB,
          name: 'Deuxième lien',
          source: source,
          conditions: const [],
          priority: 0,
          order: 1,
        ),
      ),
      NarrativeEventRecord.configuredStructurallyUnchecked(
        NarrativeEventDefinition(
          id: _eventA,
          name: 'Premier lien',
          source: source,
          conditions: const [],
          sceneId: 'scene_a',
          reusePolicy: NarrativeEventReusePolicy.oneShot,
          priority: 0,
          order: 0,
        ),
        enabled: false,
      ),
    ],
    legacyClaims: const [],
  );
}

final class _NeverWriteGateway
    implements NarrativeEventRegistryPersistenceGateway {
  int persistCalls = 0;

  @override
  Future<NarrativeEventRegistryPersistenceResult> persist(
    NarrativeEventRegistryWriteRequest request,
  ) {
    persistCalls++;
    throw StateError('An existing link must not be persisted.');
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

final class _RecordingWriteGateway
    implements NarrativeEventRegistryPersistenceGateway {
  final List<NarrativeEventRegistryWriteRequest> requests = [];
  int persistCalls = 0;

  @override
  Future<NarrativeEventRegistryPersistenceResult> persist(
    NarrativeEventRegistryWriteRequest request,
  ) async {
    persistCalls++;
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

final class _ThrowingPanelGateway
    implements NarrativeEventRegistryPersistenceGateway {
  int persistCalls = 0;

  @override
  Future<NarrativeEventRegistryPersistenceResult> persist(
    NarrativeEventRegistryWriteRequest request,
  ) async {
    persistCalls++;
    throw StateError('raw widget gateway failure');
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
