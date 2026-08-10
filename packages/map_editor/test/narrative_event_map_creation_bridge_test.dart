import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import './support/riverpod_notifier_harness.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/app/providers/core/repository_providers.dart';
import 'package:map_editor/src/application/models/map_history_snapshot.dart';
import 'package:map_editor/src/application/models/narrative_event_authoring_session.dart';
import 'package:map_editor/src/application/models/narrative_event_map_bridge_models.dart';
import 'package:map_editor/src/application/models/narrative_event_registry_persistence_models.dart';
import 'package:map_editor/src/application/ports/narrative_event_registry_persistence_gateway.dart';
import 'package:map_editor/src/application/use_cases/create_narrative_event_from_map_source_use_case.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/narrative/state/narrative_event_map_bridge_state.dart';

import 'support/event_registry_persistence_fixtures.dart';

const _eventA = 'evt_019abcde-0000-7000-8000-000000000201';
const _eventB = 'evt_019abcde-0000-7000-8000-000000000202';
const _eventC = 'evt_019abcde-0000-7000-8000-000000000203';
const _createdEvent = 'evt_019abcde-0000-7000-8000-000000000299';

void main() {
  group('NS-EVENT-V2-23 atomic map creation intent', () {
    test('carries one source ref and a human name only', () {
      final source = NarrativeEventSourceRef.entityInteract(
        'map_a',
        'entity_a',
      );

      final intent = NarrativeEventMapCreationIntent(
        source: source,
        humanName: 'Parler au rival',
      );

      expect(intent.source, source);
      expect(intent.humanName, 'Parler au rival');
      expect(intent.toString(), isNot(contains('layerId')));
      expect(intent.toString(), isNot(contains('coordinate')));
    });

    test('rejects a non-map outcome source', () {
      expect(
        () => NarrativeEventMapCreationIntent(
          source: NarrativeEventSourceRef.outcomeReceived(
            NarrativeOutcomeRef(
              producerKind: NarrativeOutcomeProducerKind.scene,
              producerId: 'scene_a',
              outcomeId: 'done',
            ),
          ),
          humanName: 'Résultat de scène',
        ),
        throwsArgumentError,
      );
    });
  });

  group('NS-EVENT-V2-23 create/open use case', () {
    for (final sourceCase in <(String, NarrativeEventSourceRef)>[
      ('entity', NarrativeEventSourceRef.entityInteract('map_a', 'entity_a')),
      ('trigger', NarrativeEventSourceRef.triggerEnter('map_a', 'trigger_a')),
      ('map', NarrativeEventSourceRef.mapEnter('map_a')),
    ]) {
      test(
        'creates one source-prefilled draft from ${sourceCase.$1}',
        () async {
          final fixture = await createPersistenceFixture(map: _sourceMap());
          addTearDown(fixture.dispose);
          final gateway = _RecordingGateway();
          final useCase = _useCase(gateway);

          final result = await useCase(
            projectPath: fixture.projectPath,
            intent: NarrativeEventMapCreationIntent(
              source: sourceCase.$2,
              humanName: 'Event ${sourceCase.$1}',
            ),
            mapDirty: false,
            projectDirty: false,
            saving: false,
          );

          expect(result.status, NarrativeEventMapCreationStatus.committed);
          expect(result.eventId, _createdEvent);
          expect(result.nextRegistry, gateway.requests.single.nextRegistry);
          expect(gateway.requests, hasLength(1));
          final created = result.nextRegistry!.records.single.draftOrNull!;
          expect(created.source, sourceCase.$2);
          expect(created.name, 'Event ${sourceCase.$1}');
        },
      );
    }

    test(
      'finds exact links in draft, enabled and disabled configured records',
      () async {
        final source = NarrativeEventSourceRef.entityInteract(
          'map_a',
          'entity_a',
        );
        final registry = persistenceRegistry(
          records: [
            _draft(_eventB, source: source, order: 20),
            _configured(_eventC, source: source, enabled: false, order: 30),
            _configured(_eventA, source: source, enabled: true, order: 10),
          ],
        );
        final fixture = await createPersistenceFixture(
          registry: registry,
          map: _sourceMap(),
        );
        addTearDown(fixture.dispose);
        final gateway = _RecordingGateway();

        final result = await _useCase(gateway)(
          projectPath: fixture.projectPath,
          intent: NarrativeEventMapCreationIntent(
            source: source,
            humanName: 'Ne doit pas être créé',
          ),
          mapDirty: false,
          projectDirty: false,
          saving: false,
        );

        expect(result.status, NarrativeEventMapCreationStatus.existingLinks);
        expect(result.linkedEvents.map((event) => event.eventId), [
          _eventA,
          _eventB,
          _eventC,
        ]);
        expect(result.linkedEvents.map((event) => event.enabled), [
          true,
          null,
          false,
        ]);
        expect(gateway.requests, isEmpty);
      },
    );

    test(
      'multiple links are deterministic and never trigger a write',
      () async {
        final source = NarrativeEventSourceRef.triggerEnter(
          'map_a',
          'trigger_a',
        );
        final fixture = await createPersistenceFixture(
          registry: persistenceRegistry(
            records: [
              _configured(_eventC, source: source, enabled: false, order: 2),
              _draft(_eventB, source: source, order: 1),
              _configured(_eventA, source: source, enabled: true, order: 1),
            ],
          ),
          map: _sourceMap(),
        );
        addTearDown(fixture.dispose);
        final gateway = _RecordingGateway();

        final result = await _useCase(gateway)(
          projectPath: fixture.projectPath,
          intent: NarrativeEventMapCreationIntent(
            source: source,
            humanName: 'Zone du rival',
          ),
          mapDirty: false,
          projectDirty: false,
          saving: false,
        );

        expect(result.linkedEvents.map((event) => event.eventId), [
          _eventA,
          _eventB,
          _eventC,
        ]);
        expect(gateway.persistCalls, 0);
      },
    );

    test(
      'explicit additional-event opt-in creates exactly one new link',
      () async {
        final source = NarrativeEventSourceRef.entityInteract(
          'map_a',
          'entity_a',
        );
        final registry = persistenceRegistry(
          records: [
            _draft(_eventA, source: source, order: 0),
            _configured(_eventB, source: source, enabled: false, order: 1),
          ],
        );
        final fixture = await createPersistenceFixture(
          registry: registry,
          map: _sourceMap(),
        );
        addTearDown(fixture.dispose);
        final gateway = _RecordingGateway();

        final result = await _useCase(gateway)(
          projectPath: fixture.projectPath,
          intent: NarrativeEventMapCreationIntent(
            source: source,
            humanName: 'Rencontre alternative',
          ),
          mapDirty: false,
          projectDirty: false,
          saving: false,
          allowAdditionalEvent: true,
        );

        expect(result.status, NarrativeEventMapCreationStatus.committed);
        expect(result.eventId, _createdEvent);
        expect(gateway.persistCalls, 1);
        expect(gateway.requests, hasLength(1));
        expect(result.nextRegistry!.records, hasLength(3));
        final created = result.nextRegistry!.records
            .singleWhere((record) => record.id == _createdEvent)
            .draftOrNull!;
        expect(created.source, source);
        expect(created.name, 'Rencontre alternative');
      },
    );

    test(
      'additional-event opt-in still obeys dirty gates before preparation',
      () async {
        final fixture = await createPersistenceFixture(map: _sourceMap());
        addTearDown(fixture.dispose);
        var prepareCalls = 0;
        final gateway = _RecordingGateway();
        final useCase = CreateNarrativeEventFromMapSourceUseCase(
          persistenceGateway: gateway,
          prepareSession: (path) async {
            prepareCalls++;
            return fixture.session;
          },
        );

        final result = await useCase(
          projectPath: fixture.projectPath,
          intent: NarrativeEventMapCreationIntent(
            source: NarrativeEventSourceRef.mapEnter('map_a'),
            humanName: 'Entrée supplémentaire',
          ),
          mapDirty: true,
          projectDirty: false,
          saving: false,
          allowAdditionalEvent: true,
        );

        expect(result.status, NarrativeEventMapCreationStatus.blocked);
        expect(prepareCalls, 0);
        expect(gateway.persistCalls, 0);
      },
    );

    for (final dirtyCase in <(String, bool, bool, bool)>[
      ('map dirty', true, false, false),
      ('project dirty', false, true, false),
      ('saving', false, false, true),
    ]) {
      test(
        '${dirtyCase.$1} blocks before session preparation and write',
        () async {
          final fixture = await createPersistenceFixture(map: _sourceMap());
          addTearDown(fixture.dispose);
          var prepareCalls = 0;
          final gateway = _RecordingGateway();
          final useCase = CreateNarrativeEventFromMapSourceUseCase(
            persistenceGateway: gateway,
            prepareSession: (path) async {
              prepareCalls++;
              return fixture.session;
            },
            eventIdGeneratorFactory: () => NarrativeEventIdGenerator(
              rawUuidFactory: () => _createdEvent.substring(4),
            ),
            operationIdFactory: () => 'v2_23_dirty_guard',
          );

          final result = await useCase(
            projectPath: fixture.projectPath,
            intent: NarrativeEventMapCreationIntent(
              source: NarrativeEventSourceRef.mapEnter('map_a'),
              humanName: 'Entrée map',
            ),
            mapDirty: dirtyCase.$2,
            projectDirty: dirtyCase.$3,
            saving: dirtyCase.$4,
          );

          expect(result.status, NarrativeEventMapCreationStatus.blocked);
          expect(prepareCalls, 0);
          expect(gateway.persistCalls, 0);
        },
      );
    }

    test(
      'stale persistence result is propagated without duplicate creation',
      () async {
        final fixture = await createPersistenceFixture(map: _sourceMap());
        addTearDown(fixture.dispose);
        final gateway = _RecordingGateway(
          result: NarrativeEventRegistryPersistenceResult(
            status: NarrativeEventRegistryPersistenceStatus.staleRevision,
            code: 'staleRevision',
            message: 'Projet modifié.',
          ),
        );

        final result = await _useCase(gateway)(
          projectPath: fixture.projectPath,
          intent: NarrativeEventMapCreationIntent(
            source: NarrativeEventSourceRef.mapEnter('map_a'),
            humanName: 'Entrée map',
          ),
          mapDirty: false,
          projectDirty: false,
          saving: false,
        );

        expect(
          result.status,
          NarrativeEventMapCreationStatus.persistenceRejected,
        );
        expect(
          result.persistenceResult?.status,
          NarrativeEventRegistryPersistenceStatus.staleRevision,
        );
        expect(gateway.persistCalls, 1);
        expect(gateway.requests, hasLength(1));
        expect(gateway.requests.single.nextRegistry.records, hasLength(1));
      },
    );

    for (final rejectedStatus in [
      NarrativeEventRegistryPersistenceStatus.recoveryRequired,
      NarrativeEventRegistryPersistenceStatus.rejected,
    ]) {
      test('${rejectedStatus.name} is propagated without retry', () async {
        final fixture = await createPersistenceFixture(map: _sourceMap());
        addTearDown(fixture.dispose);
        final gateway = _RecordingGateway(
          result: NarrativeEventRegistryPersistenceResult(
            status: rejectedStatus,
            code: rejectedStatus.name,
            message: 'Writer rejected the request.',
          ),
        );

        final result = await _useCase(gateway)(
          projectPath: fixture.projectPath,
          intent: NarrativeEventMapCreationIntent(
            source: NarrativeEventSourceRef.mapEnter('map_a'),
            humanName: 'Entrée map',
          ),
          mapDirty: false,
          projectDirty: false,
          saving: false,
        );

        expect(
          result.status,
          NarrativeEventMapCreationStatus.persistenceRejected,
        );
        expect(result.persistenceResult?.status, rejectedStatus);
        expect(gateway.persistCalls, 1);
      });
    }

    test(
      'recovered persistence outcome returns the committed registry',
      () async {
        final fixture = await createPersistenceFixture(map: _sourceMap());
        addTearDown(fixture.dispose);
        final gateway = _RecordingGateway(
          result: NarrativeEventRegistryPersistenceResult(
            status: NarrativeEventRegistryPersistenceStatus.recovered,
            code: 'recovered',
            message: 'Recovered committed write.',
          ),
        );

        final result = await _useCase(gateway)(
          projectPath: fixture.projectPath,
          intent: NarrativeEventMapCreationIntent(
            source: NarrativeEventSourceRef.mapEnter('map_a'),
            humanName: 'Entrée map',
          ),
          mapDirty: false,
          projectDirty: false,
          saving: false,
        );

        expect(result.status, NarrativeEventMapCreationStatus.committed);
        expect(
          result.persistenceResult?.status,
          NarrativeEventRegistryPersistenceStatus.recovered,
        );
        expect(result.nextRegistry, gateway.requests.single.nextRegistry);
        expect(gateway.persistCalls, 1);
      },
    );

    test(
      'authoring rejection is returned without a persistence request',
      () async {
        final fixture = await createPersistenceFixture();
        addTearDown(fixture.dispose);
        final gateway = _RecordingGateway();

        final result = await _useCase(gateway)(
          projectPath: fixture.projectPath,
          intent: NarrativeEventMapCreationIntent(
            source: NarrativeEventSourceRef.entityInteract(
              'map_a',
              'missing_entity',
            ),
            humanName: 'Source absente',
          ),
          mapDirty: false,
          projectDirty: false,
          saving: false,
        );

        expect(
          result.status,
          NarrativeEventMapCreationStatus.authoringRejected,
        );
        expect(result.code, 'sourceMissing');
        expect(gateway.persistCalls, 0);
      },
    );

    test(
      'gateway exception becomes a typed human persistence rejection',
      () async {
        final fixture = await createPersistenceFixture(map: _sourceMap());
        addTearDown(fixture.dispose);
        final gateway = _ThrowingGateway();

        final result = await _useCase(gateway)(
          projectPath: fixture.projectPath,
          intent: NarrativeEventMapCreationIntent(
            source: NarrativeEventSourceRef.mapEnter('map_a'),
            humanName: 'Erreur d’écriture',
          ),
          mapDirty: false,
          projectDirty: false,
          saving: false,
        );

        expect(
          result.status,
          NarrativeEventMapCreationStatus.persistenceRejected,
        );
        expect(result.code, 'persistenceException');
        expect(result.message, contains('n’a pas pu être enregistré'));
        expect(result.message, isNot(contains('StateError')));
        expect(gateway.persistCalls, 1);
      },
    );
  });

  group('NS-EVENT-V2-23 editor and feature state integration', () {
    test(
      'project switch before confirm resets the bridge and writes nowhere',
      () async {
        final fixtureA = await createPersistenceFixture(map: _sourceMap());
        final fixtureB = await createPersistenceFixture(map: _sourceMap());
        addTearDown(fixtureA.dispose);
        addTearDown(fixtureB.dispose);
        final gateway = _RecordingGateway();
        final container = ProviderContainer(
          overrides: [
            createNarrativeEventFromMapSourceUseCaseProvider.overrideWithValue(
              _useCase(gateway),
            ),
          ],
        );
        addTearDown(container.dispose);
        final editor = container.read(editorNotifierProvider.notifier);
        editor.state = EditorState(
          projectRootPath: fixtureA.root.path,
          project: _project(),
          activeMap: _sourceMap(),
        );
        final controller = container.read(
          narrativeEventMapBridgeControllerProvider.notifier,
        );
        final sessionToken = controller.state.projectSessionToken;
        controller.request(
          NarrativeEventMapCreationIntent(
            source: NarrativeEventSourceRef.mapEnter('map_a'),
            humanName: 'Entrée A',
          ),
          projectRootPath: fixtureA.root.path,
        );

        editor.state = EditorState(
          projectRootPath: fixtureB.root.path,
          project: _project(),
          activeMap: _sourceMap(),
        );

        expect(controller.state.projectRootPath, fixtureB.root.path);
        expect(controller.state.projectSessionToken, greaterThan(sessionToken));
        expect(controller.state.pendingIntent, isNull);
        expect(controller.state.linkedEvents, isEmpty);
        expect(controller.state.selectedNarrativeEventV2Id, isNull);
        expect(controller.state.recovery, isNull);

        final result = await controller.confirm(
          projectRootPath: fixtureB.root.path,
          mapDirty: false,
          projectDirty: false,
          saving: false,
          applyPersistedRegistry: editor.applyPersistedNarrativeEventRegistry,
        );

        expect(result, isNull);
        expect(gateway.persistCalls, 0);
      },
    );

    test(
      'late project A response never mutates project B bridge state',
      () async {
        final fixtureA = await createPersistenceFixture(map: _sourceMap());
        final fixtureB = await createPersistenceFixture(map: _sourceMap());
        addTearDown(fixtureA.dispose);
        addTearDown(fixtureB.dispose);
        final prepared = Completer<NarrativeEventAuthoringSession>();
        final gateway = _RecordingGateway();
        final useCase = CreateNarrativeEventFromMapSourceUseCase(
          persistenceGateway: gateway,
          prepareSession: (_) => prepared.future,
          eventIdGeneratorFactory: () => NarrativeEventIdGenerator(
            rawUuidFactory: () => _createdEvent.substring(4),
          ),
          operationIdFactory: () => 'v2_23_late_project_a',
        );
        final container = ProviderContainer(
          overrides: [
            createNarrativeEventFromMapSourceUseCaseProvider.overrideWithValue(
              useCase,
            ),
          ],
        );
        addTearDown(container.dispose);
        final editor = container.read(editorNotifierProvider.notifier);
        editor.state = EditorState(
          projectRootPath: fixtureA.root.path,
          project: _project(),
          activeMap: _sourceMap(),
        );
        final controller = container.read(
          narrativeEventMapBridgeControllerProvider.notifier,
        );
        controller.request(
          NarrativeEventMapCreationIntent(
            source: NarrativeEventSourceRef.entityInteract('map_a', 'entity_a'),
            humanName: 'Réponse tardive A',
          ),
          projectRootPath: fixtureA.root.path,
        );

        final confirmation = controller.confirm(
          projectRootPath: fixtureA.root.path,
          mapDirty: false,
          projectDirty: false,
          saving: false,
          applyPersistedRegistry: editor.applyPersistedNarrativeEventRegistry,
        );
        await Future<void>.delayed(Duration.zero);
        expect(controller.state.isSubmitting, isTrue);

        editor.state = EditorState(
          projectRootPath: fixtureB.root.path,
          project: _project(),
          activeMap: _sourceMap(),
        );
        prepared.complete(fixtureA.session);
        await confirmation;

        expect(gateway.persistCalls, 1);
        expect(gateway.requests.single.projectPath, fixtureA.projectPath);
        expect(controller.state.projectRootPath, fixtureB.root.path);
        expect(controller.state.isSubmitting, isFalse);
        expect(controller.state.pendingIntent, isNull);
        expect(controller.state.selectedNarrativeEventV2Id, isNull);
        expect(controller.state.lastResult, isNull);
        expect(controller.state.recovery, isNull);
        expect(editor.state.projectRootPath, fixtureB.root.path);
        expect(editor.state.project!.eventRegistry, isNull);
      },
    );

    test(
      'disposing the provider during confirm suppresses late memory adoption',
      () async {
        final fixture = await createPersistenceFixture(map: _sourceMap());
        addTearDown(fixture.dispose);
        final prepared = Completer<NarrativeEventAuthoringSession>();
        final gateway = _RecordingGateway();
        final useCase = CreateNarrativeEventFromMapSourceUseCase(
          persistenceGateway: gateway,
          prepareSession: (_) => prepared.future,
          eventIdGeneratorFactory: () => NarrativeEventIdGenerator(
            rawUuidFactory: () => _createdEvent.substring(4),
          ),
          operationIdFactory: () => 'riverpod_3_disposed_confirm',
        );
        final container = ProviderContainer(
          overrides: [
            narrativeEventMapBridgeControllerProvider.overrideWith(
              () => NarrativeEventMapBridgeController(
                useCase: useCase,
                projectRootPath: fixture.root.path,
              ),
            ),
          ],
        );
        final controller = container.read(
          narrativeEventMapBridgeControllerProvider.notifier,
        );
        controller.request(
          NarrativeEventMapCreationIntent(
            source: NarrativeEventSourceRef.entityInteract('map_a', 'entity_a'),
            humanName: 'Réponse après disposal',
          ),
          projectRootPath: fixture.root.path,
        );
        var memoryAdoptionCalls = 0;

        final confirmation = controller.confirm(
          projectRootPath: fixture.root.path,
          mapDirty: false,
          projectDirty: false,
          saving: false,
          applyPersistedRegistry:
              ({
                required String expectedProjectRootPath,
                required NarrativeEventRegistry? expectedPreviousRegistry,
                required NarrativeEventRegistry nextRegistry,
              }) {
                memoryAdoptionCalls++;
                return true;
              },
        );
        await Future<void>.delayed(Duration.zero);
        expect(controller.state.isSubmitting, isTrue);

        container.dispose();
        prepared.complete(fixture.session);

        await expectLater(confirmation, completes);
        expect(gateway.persistCalls, 1);
        expect(memoryAdoptionCalls, 0);
      },
    );

    test(
      'same-root replacement after a durable V2-23 commit enters explicit recovery',
      () async {
        final fixture = await createPersistenceFixture(map: _sourceMap());
        addTearDown(fixture.dispose);
        final gateway = _BlockingGateway();
        final container = ProviderContainer(
          overrides: [
            createNarrativeEventFromMapSourceUseCaseProvider.overrideWithValue(
              _useCase(gateway),
            ),
          ],
        );
        addTearDown(container.dispose);
        final editor = container.read(editorNotifierProvider.notifier);
        final project = _project();
        editor.state = EditorState(
          projectRootPath: fixture.root.path,
          project: project,
          activeMap: _sourceMap(),
        );
        final controller = container.read(
          narrativeEventMapBridgeControllerProvider.notifier,
        );
        controller.request(
          NarrativeEventMapCreationIntent(
            source: NarrativeEventSourceRef.entityInteract('map_a', 'entity_a'),
            humanName: 'Commit tardif même projet',
          ),
          projectRootPath: fixture.root.path,
        );

        final confirmation = controller.confirm(
          projectRootPath: fixture.root.path,
          mapDirty: false,
          projectDirty: false,
          saving: false,
          applyPersistedRegistry: editor.applyPersistedNarrativeEventRegistry,
        );
        while (gateway.persistCalls == 0) {
          await Future<void>.delayed(Duration.zero);
        }
        editor.state = editor.state.copyWith(
          project: project.copyWith(name: 'Projet rechargé au même chemin'),
        );
        gateway.completeCommitted();
        final result = await confirmation;

        expect(
          result?.status,
          NarrativeEventMapCreationStatus.committedOutOfSync,
        );
        expect(gateway.persistCalls, 1);
        expect(controller.state.isSubmitting, isFalse);
        expect(controller.state.pendingIntent, isNull);
        expect(controller.state.selectedNarrativeEventV2Id, isNull);
        expect(controller.state.lastResult, same(result));
        expect(controller.state.recovery?.result, same(result));
        expect(controller.state.recovery?.projectRootPath, fixture.root.path);
        expect(editor.state.project?.name, 'Projet rechargé au même chemin');
        expect(editor.state.project?.eventRegistry, isNull);
      },
    );

    test(
      'repository providers expose the exact same file repository instance',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final projectRepository = container.read(projectRepositoryProvider);
        final registryGateway = container.read(
          narrativeEventRegistryPersistenceGatewayProvider,
        );

        expect(identical(projectRepository, registryGateway), isTrue);
      },
    );

    test('cancel clears pending intent without preparing or writing', () async {
      final fixture = await createPersistenceFixture(map: _sourceMap());
      addTearDown(fixture.dispose);
      var prepareCalls = 0;
      final gateway = _RecordingGateway();
      final controller = mountNarrativeEventMapBridgeController(
        useCase: CreateNarrativeEventFromMapSourceUseCase(
          persistenceGateway: gateway,
          prepareSession: (path) async {
            prepareCalls++;
            return fixture.session;
          },
        ),
        projectRootPath: fixture.root.path,
      );

      controller.request(
        NarrativeEventMapCreationIntent(
          source: NarrativeEventSourceRef.mapEnter('map_a'),
          humanName: 'Entrée map',
        ),
        projectRootPath: fixture.root.path,
      );
      controller.cancel();

      expect(controller.state.pendingIntent, isNull);
      expect(prepareCalls, 0);
      expect(gateway.persistCalls, 0);
    });

    test(
      'committed controller flow updates registry and V2 selection only',
      () async {
        final fixture = await createPersistenceFixture(map: _sourceMap());
        addTearDown(fixture.dispose);
        final gateway = _RecordingGateway();
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final editorSubscription = container.listen(
          editorNotifierProvider,
          (_, _) {},
          fireImmediately: true,
        );
        addTearDown(editorSubscription.close);
        final notifier = container.read(editorNotifierProvider.notifier);
        notifier.state = EditorState(
          projectRootPath: fixture.root.path,
          project: _project(),
          activeMap: _sourceMap(),
          selectedMapEventId: 'legacy_event',
        );
        final controller = mountNarrativeEventMapBridgeController(
          useCase: _useCase(gateway),
          projectRootPath: fixture.root.path,
        );
        controller.request(
          NarrativeEventMapCreationIntent(
            source: NarrativeEventSourceRef.entityInteract('map_a', 'entity_a'),
            humanName: 'Parler au rival',
          ),
          projectRootPath: fixture.root.path,
        );

        final result = await controller.confirm(
          projectRootPath: fixture.root.path,
          mapDirty: false,
          projectDirty: false,
          saving: false,
          applyPersistedRegistry: notifier.applyPersistedNarrativeEventRegistry,
        );

        expect(result?.status, NarrativeEventMapCreationStatus.committed);
        expect(notifier.state.project!.eventRegistry, result!.nextRegistry);
        expect(notifier.state.selectedMapEventId, 'legacy_event');
        expect(controller.state.selectedNarrativeEventV2Id, _createdEvent);
        expect(controller.state.pendingIntent, isNull);
        expect(gateway.persistCalls, 1);
      },
    );

    test('persisted registry replacement preserves all map document state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final beforeMap = _sourceMap();
      const undoSnapshot = MapHistorySnapshot(
        map: MapData(
          id: 'map_a',
          name: 'Before',
          size: GridSize(width: 8, height: 6),
        ),
      );
      final nextRegistry = persistenceRegistry(
        records: [
          _draft(
            _eventA,
            source: NarrativeEventSourceRef.mapEnter('map_a'),
            order: 0,
          ),
        ],
      );
      notifier.state = EditorState(
        projectRootPath: '/tmp/project_a',
        project: _project(),
        activeMap: beforeMap,
        activeMapPath: '/tmp/maps/map_a.json',
        activeLayerId: 'objects',
        selectedEntityId: 'entity_a',
        selectedMapEventId: 'legacy_event',
        selectedTriggerId: 'trigger_a',
        mapUndoStack: const [undoSnapshot],
        mapRedoStack: const [undoSnapshot],
        canUndoMap: true,
        canRedoMap: true,
        isDirty: true,
        isProjectDirty: false,
      );

      final applied = notifier.applyPersistedNarrativeEventRegistry(
        expectedProjectRootPath: '/tmp/project_a',
        expectedPreviousRegistry: null,
        nextRegistry: nextRegistry,
      );
      final after = container.read(editorNotifierProvider);

      expect(applied, isTrue);
      expect(after.project!.eventRegistry, nextRegistry);
      expect(identical(after.activeMap, beforeMap), isTrue);
      expect(after.activeMapPath, '/tmp/maps/map_a.json');
      expect(after.activeLayerId, 'objects');
      expect(after.selectedEntityId, 'entity_a');
      expect(after.selectedMapEventId, 'legacy_event');
      expect(after.selectedTriggerId, 'trigger_a');
      expect(after.mapUndoStack, const [undoSnapshot]);
      expect(after.mapRedoStack, const [undoSnapshot]);
      expect(after.isDirty, isTrue);
      expect(after.isProjectDirty, isFalse);
    });

    test('same-project registry merge preserves unrelated dirty changes', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final previousRegistry = persistenceRegistry(
        records: [
          _draft(
            _eventA,
            source: NarrativeEventSourceRef.mapEnter('map_a'),
            order: 0,
          ),
        ],
      );
      final nextRegistry = persistenceRegistry(
        records: [
          _draft(
            _eventA,
            source: NarrativeEventSourceRef.mapEnter('map_a'),
            order: 0,
          ),
          _draft(
            _eventB,
            source: NarrativeEventSourceRef.mapEnter('map_a'),
            order: 1,
          ),
        ],
      );
      final locallyEditedProject = _project().copyWith(
        name: 'Nom modifié localement',
        globalProperties: const {'unrelated': 'preserved'},
        eventRegistry: previousRegistry,
      );
      notifier.state = EditorState(
        projectRootPath: '/tmp/project_a',
        project: locallyEditedProject,
        activeMap: _sourceMap(),
        isProjectDirty: true,
      );

      final applied = notifier.applyPersistedNarrativeEventRegistry(
        expectedProjectRootPath: '/tmp/project_a',
        expectedPreviousRegistry: previousRegistry,
        nextRegistry: nextRegistry,
      );

      expect(applied, isTrue);
      expect(notifier.state.project!.eventRegistry, nextRegistry);
      expect(notifier.state.project!.name, 'Nom modifié localement');
      expect(notifier.state.project!.globalProperties, const {
        'unrelated': 'preserved',
      });
      expect(notifier.state.isProjectDirty, isTrue);
    });

    test(
      'registry merge rejects another project root or concurrent registry',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final notifier = container.read(editorNotifierProvider.notifier);
        final previousRegistry = persistenceRegistry(records: []);
        final concurrentRegistry = persistenceRegistry(
          records: [
            _draft(
              _eventA,
              source: NarrativeEventSourceRef.mapEnter('map_a'),
              order: 0,
            ),
          ],
        );
        final nextRegistry = persistenceRegistry(
          records: [
            _draft(
              _eventB,
              source: NarrativeEventSourceRef.mapEnter('map_a'),
              order: 0,
            ),
          ],
        );
        final project = _project().copyWith(eventRegistry: concurrentRegistry);
        notifier.state = EditorState(
          projectRootPath: '/tmp/project_a',
          project: project,
          isProjectDirty: true,
        );

        expect(
          notifier.applyPersistedNarrativeEventRegistry(
            expectedProjectRootPath: '/tmp/project_b',
            expectedPreviousRegistry: concurrentRegistry,
            nextRegistry: nextRegistry,
          ),
          isFalse,
        );
        expect(notifier.state.project, project);
        expect(notifier.state.isProjectDirty, isTrue);

        expect(
          notifier.applyPersistedNarrativeEventRegistry(
            expectedProjectRootPath: '/tmp/project_a',
            expectedPreviousRegistry: previousRegistry,
            nextRegistry: nextRegistry,
          ),
          isFalse,
        );
        expect(notifier.state.project, project);
        expect(notifier.state.isProjectDirty, isTrue);
      },
    );

    test(
      'failed memory adoption becomes non-repeatable out-of-sync recovery',
      () async {
        final fixture = await createPersistenceFixture(map: _sourceMap());
        addTearDown(fixture.dispose);
        final gateway = _RecordingGateway();
        final controller = mountNarrativeEventMapBridgeController(
          useCase: _useCase(gateway),
          projectRootPath: fixture.root.path,
        );
        controller.request(
          NarrativeEventMapCreationIntent(
            source: NarrativeEventSourceRef.mapEnter('map_a'),
            humanName: 'Commit désynchronisé',
          ),
          projectRootPath: fixture.root.path,
        );

        final result = await controller.confirm(
          projectRootPath: fixture.root.path,
          mapDirty: false,
          projectDirty: false,
          saving: false,
          applyPersistedRegistry: _rejectRegistryApply,
        );

        expect(
          result?.status,
          NarrativeEventMapCreationStatus.committedOutOfSync,
        );
        expect(
          controller.state.lastResult?.status,
          NarrativeEventMapCreationStatus.committedOutOfSync,
        );
        expect(controller.state.pendingIntent, isNull);
        expect(controller.state.selectedNarrativeEventV2Id, isNull);
        expect(controller.state.recovery, isNotNull);
        expect(controller.state.recovery!.projectRootPath, fixture.root.path);
        expect(gateway.persistCalls, 1);

        final repeated = await controller.confirm(
          projectRootPath: fixture.root.path,
          mapDirty: false,
          projectDirty: false,
          saving: false,
          applyPersistedRegistry: _rejectRegistryApply,
        );
        expect(repeated, isNull);
        expect(gateway.persistCalls, 1);

        expect(
          controller.finishRecoveryReload(
            projectRootPath: fixture.root.path,
            loadedRegistry: persistenceRegistry(records: []),
          ),
          isFalse,
        );
        expect(controller.state.recovery, isNotNull);
        expect(
          controller.finishRecoveryReload(
            projectRootPath: fixture.root.path,
            loadedRegistry: result!.nextRegistry,
          ),
          isTrue,
        );
        expect(controller.state.recovery, isNull);
        expect(controller.state.pendingIntent, isNull);
        expect(controller.state.lastResult, isNull);
      },
    );

    test(
      'memory adoption exception becomes out-of-sync and releases submit',
      () async {
        final fixture = await createPersistenceFixture(map: _sourceMap());
        addTearDown(fixture.dispose);
        final gateway = _RecordingGateway();
        final controller = mountNarrativeEventMapBridgeController(
          useCase: _useCase(gateway),
          projectRootPath: fixture.root.path,
        );
        controller.request(
          NarrativeEventMapCreationIntent(
            source: NarrativeEventSourceRef.mapEnter('map_a'),
            humanName: 'Adoption impossible',
          ),
          projectRootPath: fixture.root.path,
        );

        final result = await controller.confirm(
          projectRootPath: fixture.root.path,
          mapDirty: false,
          projectDirty: false,
          saving: false,
          applyPersistedRegistry: _throwingRegistryApply,
        );

        expect(
          result?.status,
          NarrativeEventMapCreationStatus.committedOutOfSync,
        );
        expect(controller.state.isSubmitting, isFalse);
        expect(controller.state.pendingIntent, isNull);
        expect(controller.state.recovery, isNotNull);
        expect(gateway.persistCalls, 1);
      },
    );

    test(
      'project binding clears an out-of-sync recovery and stale selection',
      () async {
        final fixture = await createPersistenceFixture(map: _sourceMap());
        addTearDown(fixture.dispose);
        final gateway = _RecordingGateway();
        final controller = mountNarrativeEventMapBridgeController(
          useCase: _useCase(gateway),
          projectRootPath: fixture.root.path,
        );
        controller.request(
          NarrativeEventMapCreationIntent(
            source: NarrativeEventSourceRef.mapEnter('map_a'),
            humanName: 'Recovery A',
          ),
          projectRootPath: fixture.root.path,
        );
        await controller.confirm(
          projectRootPath: fixture.root.path,
          mapDirty: false,
          projectDirty: false,
          saving: false,
          applyPersistedRegistry: _rejectRegistryApply,
        );
        expect(controller.state.recovery, isNotNull);

        controller.bindProjectRootPath('/tmp/project_b');

        expect(controller.state.projectRootPath, '/tmp/project_b');
        expect(controller.state.recovery, isNull);
        expect(controller.state.pendingIntent, isNull);
        expect(controller.state.linkedEvents, isEmpty);
        expect(controller.state.selectedNarrativeEventV2Id, isNull);
        expect(controller.state.lastResult, isNull);
        expect(gateway.persistCalls, 1);
      },
    );
  });
}

bool _rejectRegistryApply({
  required String expectedProjectRootPath,
  required NarrativeEventRegistry? expectedPreviousRegistry,
  required NarrativeEventRegistry nextRegistry,
}) {
  return false;
}

bool _throwingRegistryApply({
  required String expectedProjectRootPath,
  required NarrativeEventRegistry? expectedPreviousRegistry,
  required NarrativeEventRegistry nextRegistry,
}) {
  throw StateError('raw apply failure');
}

CreateNarrativeEventFromMapSourceUseCase _useCase(
  NarrativeEventRegistryPersistenceGateway gateway,
) {
  return CreateNarrativeEventFromMapSourceUseCase(
    persistenceGateway: gateway,
    eventIdGeneratorFactory: () => NarrativeEventIdGenerator(
      rawUuidFactory: () => _createdEvent.substring(4),
    ),
    operationIdFactory: () => 'v2_23_create',
  );
}

final class _RecordingGateway
    implements NarrativeEventRegistryPersistenceGateway {
  _RecordingGateway({NarrativeEventRegistryPersistenceResult? result})
    : result =
          result ??
          NarrativeEventRegistryPersistenceResult(
            status: NarrativeEventRegistryPersistenceStatus.committed,
            code: 'committed',
            message: 'Committed.',
          );

  final NarrativeEventRegistryPersistenceResult result;
  final List<NarrativeEventRegistryWriteRequest> requests = [];
  int persistCalls = 0;

  @override
  Future<NarrativeEventRegistryPersistenceResult> persist(
    NarrativeEventRegistryWriteRequest request,
  ) async {
    persistCalls++;
    requests.add(request);
    return result;
  }

  @override
  Future<NarrativeEventRegistryRecoveryInspection> inspectRecovery(
    String projectPath,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<List<NarrativeEventRegistryPersistenceResult>> recover(
    String projectPath,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<NarrativeEventRegistryPersistenceResult> undo(String undoPath) async {
    throw UnimplementedError();
  }
}

final class _ThrowingGateway
    implements NarrativeEventRegistryPersistenceGateway {
  int persistCalls = 0;

  @override
  Future<NarrativeEventRegistryPersistenceResult> persist(
    NarrativeEventRegistryWriteRequest request,
  ) async {
    persistCalls++;
    throw StateError('raw gateway failure');
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

NarrativeEventRecord _draft(
  String id, {
  required NarrativeEventSourceRef source,
  required int order,
}) {
  return NarrativeEventRecord.draft(
    NarrativeEventDraft(
      id: id,
      name: 'Draft $id',
      source: source,
      conditions: const [],
      priority: 0,
      order: order,
    ),
  );
}

NarrativeEventRecord _configured(
  String id, {
  required NarrativeEventSourceRef source,
  required bool enabled,
  required int order,
}) {
  return NarrativeEventRecord.configuredStructurallyUnchecked(
    NarrativeEventDefinition(
      id: id,
      name: 'Configured $id',
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

MapData _sourceMap() => const MapData(
  id: 'map_a',
  name: 'Port Selbrume',
  size: GridSize(width: 8, height: 6),
  layers: [ObjectLayer(id: 'objects', name: 'Objets')],
  entities: [
    MapEntity(
      id: 'entity_a',
      name: 'Rival',
      kind: MapEntityKind.npc,
      pos: GridPos(x: 2, y: 2),
    ),
  ],
  triggers: [
    MapTrigger(
      id: 'trigger_a',
      name: 'Zone du port',
      type: TriggerType.event,
      area: MapRect(
        pos: GridPos(x: 4, y: 3),
        size: GridSize(width: 2, height: 1),
      ),
    ),
  ],
);

ProjectManifest _project() => ProjectManifest(
  name: 'Bridge project',
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
