import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/narrative_event_authoring_session.dart';
import 'package:map_editor/src/application/models/narrative_event_registry_persistence_models.dart';
import 'package:map_editor/src/application/ports/narrative_event_registry_persistence_gateway.dart';
import 'package:map_editor/src/application/use_cases/narrative_event_builder_v2_use_case.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:path/path.dart' as p;

import 'support/event_builder_v2_product_route_fixture.dart';

void main() {
  group('NS-EVENT-V2 Phase 2 H3/H4 authoring coordinator', () {
    test('creates source-first, persists, closes and reopens without loss',
        () async {
      final fixture = await EventBuilderV2ProductRouteFixture.create(
        mode: EventSystemMode.dualRead,
      );
      addTearDown(fixture.dispose);
      final useCase = NarrativeEventBuilderV2UseCase(
        persistenceGateway: FileProjectRepository(),
        operationIdFactory: () => 'phase2_create_reopen',
      );
      final source = NarrativeEventSourceRef.mapEnter('map_forest');

      final result = await useCase.createDraft(
        projectPath: fixture.projectPath,
        name: 'Entrée dans la brume',
        source: source,
        environment: const NarrativeEventBuilderV2WriteEnvironment.clean(),
      );

      expect(result.status, NarrativeEventBuilderV2WriteStatus.committed);
      expect(result.eventId, isNotNull);
      final reopened = await NarrativeEventAuthoringSession.prepare(
        fixture.projectPath,
      );
      final record = reopened.context.registryOrNull!.records.singleWhere(
        (candidate) => candidate.id == result.eventId,
      );
      expect(record.draftOrNull!.name, 'Entrée dans la brume');
      expect(record.draftOrNull!.source, source);
    });

    test('publishes all four atomic source kinds without touching map bytes',
        () async {
      final fixture = await EventBuilderV2ProductRouteFixture.create(
        mode: EventSystemMode.dualRead,
      );
      addTearDown(fixture.dispose);
      final mapPaths = [
        p.join(fixture.root.path, 'maps', 'port.json'),
        p.join(fixture.root.path, 'maps', 'forest.json'),
      ];
      final mapBytesBefore = [
        for (final path in mapPaths) await File(path).readAsBytes(),
      ];
      var operation = 0;
      final useCase = NarrativeEventBuilderV2UseCase(
        persistenceGateway: FileProjectRepository(),
        operationIdFactory: () => 'phase2_source_kind_${operation++}',
      );
      final sources = <String, NarrativeEventSourceRef>{
        'Entité existante':
            NarrativeEventSourceRef.entityInteract('map_port', 'npc_rival'),
        'Zone existante': NarrativeEventSourceRef.triggerEnter(
            'map_port', 'trigger_map_port'),
        'Entrée de map': NarrativeEventSourceRef.mapEnter('map_forest'),
        'Résultat existant': NarrativeEventSourceRef.outcomeReceived(
          NarrativeOutcomeRef(
            producerKind: NarrativeOutcomeProducerKind.scene,
            producerId: 'scene_rival',
            outcomeId: 'victory',
          ),
        ),
      };

      for (final entry in sources.entries) {
        final result = await useCase.create(
          projectPath: fixture.projectPath,
          request: NarrativeEventBuilderV2CreationRequest(
            name: entry.key,
            source: entry.value,
            sceneId: 'scene_action',
            reusePolicy: NarrativeEventReusePolicy.oneShot,
            publish: true,
          ),
          environment: const NarrativeEventBuilderV2WriteEnvironment.clean(),
        );
        expect(result.status, NarrativeEventBuilderV2WriteStatus.committed);
        expect(result.hasDurableDraft, isTrue);
        expect(result.finalRecord!.definitionOrNull!.source, entry.value);
        expect(result.finalRecord!.enabledOrNull, isFalse);
      }

      for (var index = 0; index < mapPaths.length; index++) {
        expect(
            await File(mapPaths[index]).readAsBytes(), mapBytesBefore[index]);
      }
    });

    test('Decide later persists a non-publishable source-less draft', () async {
      final fixture = await EventBuilderV2ProductRouteFixture.create(
        mode: EventSystemMode.dualRead,
      );
      addTearDown(fixture.dispose);
      final useCase = NarrativeEventBuilderV2UseCase(
        persistenceGateway: FileProjectRepository(),
        operationIdFactory: () => 'phase2_decide_later',
      );

      final result = await useCase.create(
        projectPath: fixture.projectPath,
        request: const NarrativeEventBuilderV2CreationRequest(
          name: 'Décider plus tard',
          publish: false,
        ),
        environment: const NarrativeEventBuilderV2WriteEnvironment.clean(),
      );

      expect(result.status, NarrativeEventBuilderV2WriteStatus.committed);
      expect(result.finalRecord!.draftOrNull!.source, isNull);
      expect(result.finalRecord!.definitionOrNull, isNull);
    });

    test('keeps the durable draft when a later creation step conflicts',
        () async {
      final fixture = await EventBuilderV2ProductRouteFixture.create(
        mode: EventSystemMode.dualRead,
      );
      addTearDown(fixture.dispose);
      final gateway = _FailOnSecondGateway(FileProjectRepository());
      var operation = 0;
      final useCase = NarrativeEventBuilderV2UseCase(
        persistenceGateway: gateway,
        operationIdFactory: () => 'phase2_partial_${operation++}',
      );

      final result = await useCase.create(
        projectPath: fixture.projectPath,
        request: NarrativeEventBuilderV2CreationRequest(
          name: 'Brouillon durable',
          source: NarrativeEventSourceRef.mapEnter('map_port'),
          sceneId: 'scene_action',
          reusePolicy: NarrativeEventReusePolicy.oneShot,
          publish: true,
        ),
        environment: const NarrativeEventBuilderV2WriteEnvironment.clean(),
      );

      expect(result.status, NarrativeEventBuilderV2WriteStatus.conflict);
      expect(result.failedStep, NarrativeEventBuilderV2CreationStep.scene);
      expect(result.hasDurableDraft, isTrue);
      final reopened = await NarrativeEventAuthoringSession.prepare(
        fixture.projectPath,
      );
      final durable = reopened.context.registryOrNull!.records.singleWhere(
        (record) => record.id == result.eventId,
      );
      expect(durable.draftOrNull!.name, 'Brouillon durable');
      expect(durable.draftOrNull!.sceneId, isNull);
    });

    test('blocks dirty project state before preparing or writing', () async {
      var prepareCalls = 0;
      final gateway = _RecordingGateway();
      final useCase = NarrativeEventBuilderV2UseCase(
        persistenceGateway: gateway,
        prepareSession: (path) async {
          prepareCalls++;
          throw StateError('prepare must not run');
        },
      );

      final result = await useCase.createDraft(
        projectPath: '/tmp/project.json',
        name: 'Ne doit pas être créé',
        source: NarrativeEventSourceRef.mapEnter('map_a'),
        environment: const NarrativeEventBuilderV2WriteEnvironment(
          mapDirty: false,
          projectDirty: true,
          saving: false,
        ),
      );

      expect(result.status, NarrativeEventBuilderV2WriteStatus.blocked);
      expect(result.code, 'projectDirty');
      expect(prepareCalls, 0);
      expect(gateway.persistCalls, 0);
    });

    test('reports a revision conflict without pretending the draft was saved',
        () async {
      final fixture = await EventBuilderV2ProductRouteFixture.create(
        mode: EventSystemMode.dualRead,
      );
      addTearDown(fixture.dispose);
      final gateway = _RecordingGateway(
        persistResult: NarrativeEventRegistryPersistenceResult(
          status: NarrativeEventRegistryPersistenceStatus.staleRevision,
          code: 'staleRevision',
          message: 'Le projet a changé.',
        ),
      );
      final useCase = NarrativeEventBuilderV2UseCase(
        persistenceGateway: gateway,
        operationIdFactory: () => 'phase2_stale_create',
      );

      final result = await useCase.createDraft(
        projectPath: fixture.projectPath,
        name: 'Brouillon conservé dans la feuille',
        source: NarrativeEventSourceRef.mapEnter('map_port'),
        environment: const NarrativeEventBuilderV2WriteEnvironment.clean(),
      );

      expect(result.status, NarrativeEventBuilderV2WriteStatus.conflict);
      expect(result.code, 'staleRevision');
      expect(result.eventId, isNotNull);
      expect(gateway.persistCalls, 1);
      final reopened = await NarrativeEventAuthoringSession.prepare(
        fixture.projectPath,
      );
      expect(
        reopened.context.registryOrNull!.records
            .where((record) => record.id == result.eventId),
        isEmpty,
      );
    });

    test('surfaces a recovery-required journal state without adopting bytes',
        () async {
      final fixture = await EventBuilderV2ProductRouteFixture.create(
        mode: EventSystemMode.dualRead,
      );
      addTearDown(fixture.dispose);
      final gateway = _RecordingGateway(
        persistResult: NarrativeEventRegistryPersistenceResult(
          status: NarrativeEventRegistryPersistenceStatus.recoveryRequired,
          code: 'recoveryRequired',
          message: 'Une écriture interrompue doit être récupérée.',
        ),
      );
      final useCase = NarrativeEventBuilderV2UseCase(
        persistenceGateway: gateway,
      );

      final result = await useCase.setConditions(
        projectPath: fixture.projectPath,
        eventId: productRouteDraftEventId,
        conditions: [
          NarrativeEventCondition.fact('fact_port_open', true),
        ],
        environment: const NarrativeEventBuilderV2WriteEnvironment.clean(),
      );

      expect(
        result.status,
        NarrativeEventBuilderV2WriteStatus.recoveryRequired,
      );
      final reopened = await NarrativeEventAuthoringSession.prepare(
        fixture.projectPath,
      );
      expect(
        reopened.context.registryOrNull!.records
            .singleWhere((record) => record.id == productRouteDraftEventId)
            .draftOrNull!
            .conditions,
        isEmpty,
      );
    });

    test('persists every Event-owned field then publishes and activates',
        () async {
      final fixture = await EventBuilderV2ProductRouteFixture.create(
        mode: EventSystemMode.dualRead,
      );
      addTearDown(fixture.dispose);
      var operation = 0;
      final useCase = NarrativeEventBuilderV2UseCase(
        persistenceGateway: FileProjectRepository(),
        operationIdFactory: () => 'phase2_edit_${operation++}',
      );
      const environment = NarrativeEventBuilderV2WriteEnvironment.clean();
      final source = NarrativeEventSourceRef.mapEnter('map_forest');
      final created = await useCase.createDraft(
        projectPath: fixture.projectPath,
        name: 'Passage secret',
        source: source,
        environment: environment,
      );
      final eventId = created.eventId!;

      expect(
        (await useCase.rename(
          projectPath: fixture.projectPath,
          eventId: eventId,
          name: 'Passage secret révélé',
          environment: environment,
        ))
            .succeeded,
        isTrue,
      );
      expect(
        (await useCase.setConditions(
          projectPath: fixture.projectPath,
          eventId: eventId,
          conditions: [
            NarrativeEventCondition.narrativeEventConsumed(
              productRoutePortEventId,
              false,
            ),
          ],
          environment: environment,
        ))
            .succeeded,
        isTrue,
      );
      expect(
        (await useCase.setScene(
          projectPath: fixture.projectPath,
          eventId: eventId,
          sceneId: 'scene_action',
          environment: environment,
        ))
            .succeeded,
        isTrue,
      );
      expect(
        (await useCase.setReusePolicy(
          projectPath: fixture.projectPath,
          eventId: eventId,
          reusePolicy: NarrativeEventReusePolicy.reusable,
          environment: environment,
        ))
            .succeeded,
        isTrue,
      );
      expect(
        (await useCase.setPriority(
          projectPath: fixture.projectPath,
          eventId: eventId,
          priority: 7,
          environment: environment,
        ))
            .succeeded,
        isTrue,
      );
      expect(
        (await useCase.setOrder(
          projectPath: fixture.projectPath,
          eventId: eventId,
          order: 17,
          environment: environment,
        ))
            .succeeded,
        isTrue,
      );
      expect(
        (await useCase.publish(
          projectPath: fixture.projectPath,
          eventId: eventId,
          environment: environment,
        ))
            .succeeded,
        isTrue,
      );
      expect(
        (await useCase.setEnabled(
          projectPath: fixture.projectPath,
          eventId: eventId,
          enabled: true,
          environment: environment,
        ))
            .succeeded,
        isTrue,
      );

      final reopened = await NarrativeEventAuthoringSession.prepare(
        fixture.projectPath,
      );
      final record = reopened.context.registryOrNull!.records.singleWhere(
        (candidate) => candidate.id == eventId,
      );
      final definition = record.definitionOrNull!;
      expect(definition.name, 'Passage secret révélé');
      expect(definition.source, source);
      expect(definition.conditions.single.toJson(), {
        'kind': 'narrativeEventConsumed',
        'eventId': productRoutePortEventId,
        'expectedValue': false,
      });
      expect(definition.sceneId, 'scene_action');
      expect(definition.reusePolicy, NarrativeEventReusePolicy.reusable);
      expect(definition.priority, 7);
      expect(definition.order, 17);
      expect(record.enabledOrNull, isTrue);
    });

    test('rejects mutation of an enabled Event until it is disabled', () async {
      final fixture = await EventBuilderV2ProductRouteFixture.create(
        mode: EventSystemMode.dualRead,
      );
      addTearDown(fixture.dispose);
      final gateway = _RecordingGateway();
      final useCase = NarrativeEventBuilderV2UseCase(
        persistenceGateway: gateway,
      );

      final result = await useCase.setScene(
        projectPath: fixture.projectPath,
        eventId: productRoutePortEventId,
        sceneId: 'scene_action',
        environment: const NarrativeEventBuilderV2WriteEnvironment.clean(),
      );

      expect(result.status, NarrativeEventBuilderV2WriteStatus.rejected);
      expect(result.code, 'mustDisableFirst');
      expect(gateway.persistCalls, 0);
    });

    test('duplicates, unpublishes, deletes and undoes through durable writes',
        () async {
      final fixture = await EventBuilderV2ProductRouteFixture.create(
        mode: EventSystemMode.dualRead,
      );
      addTearDown(fixture.dispose);
      var operation = 0;
      final useCase = NarrativeEventBuilderV2UseCase(
        persistenceGateway: FileProjectRepository(),
        operationIdFactory: () => 'nsc40_lifecycle_${operation++}',
      );
      const environment = NarrativeEventBuilderV2WriteEnvironment.clean();

      final duplicate = await useCase.duplicate(
        projectPath: fixture.projectPath,
        eventId: productRoutePortEventId,
        environment: environment,
      );
      expect(duplicate.status, NarrativeEventBuilderV2WriteStatus.committed);
      expect(duplicate.eventId, isNot(productRoutePortEventId));
      final cloneId = duplicate.eventId!;
      var reopened = await NarrativeEventAuthoringSession.prepare(
        fixture.projectPath,
      );
      final clone = reopened.context.registryOrNull!.records.singleWhere(
        (record) => record.id == cloneId,
      );
      expect(clone.draftOrNull, isNotNull);
      expect(clone.draftOrNull!.name, contains('copie'));

      final unpublish = await useCase.unpublish(
        projectPath: fixture.projectPath,
        eventId: productRoutePortEventId,
        environment: environment,
      );
      expect(unpublish.status, NarrativeEventBuilderV2WriteStatus.committed);
      reopened = await NarrativeEventAuthoringSession.prepare(
        fixture.projectPath,
      );
      final unpublished = reopened.context.registryOrNull!.records.singleWhere(
        (record) => record.id == productRoutePortEventId,
      );
      expect(unpublished.draftOrNull, isNotNull);
      expect(unpublished.draftOrNull!.source, isNotNull);
      expect(unpublished.draftOrNull!.sceneId, isNotNull);
      expect(unpublished.draftOrNull!.reusePolicy, isNotNull);

      final deletion = await useCase.delete(
        projectPath: fixture.projectPath,
        eventId: cloneId,
        environment: environment,
      );
      expect(deletion.status, NarrativeEventBuilderV2WriteStatus.committed);
      expect(deletion.persistenceResult!.undoPath, isNotNull);
      reopened = await NarrativeEventAuthoringSession.prepare(
        fixture.projectPath,
      );
      expect(
        reopened.context.registryOrNull!.records
            .where((record) => record.id == cloneId),
        isEmpty,
      );

      final undo = await useCase.undo(
        undoPath: deletion.persistenceResult!.undoPath!,
      );
      expect(undo.status, NarrativeEventBuilderV2WriteStatus.committed);
      reopened = await NarrativeEventAuthoringSession.prepare(
        fixture.projectPath,
      );
      expect(
        reopened.context.registryOrNull!.records
            .where((record) => record.id == cloneId),
        hasLength(1),
      );
    });

    test('maps a lifecycle persistence exception without adopting bytes',
        () async {
      final fixture = await EventBuilderV2ProductRouteFixture.create(
        mode: EventSystemMode.dualRead,
      );
      addTearDown(fixture.dispose);
      final useCase = NarrativeEventBuilderV2UseCase(
        persistenceGateway: _ThrowingGateway(),
      );
      final before = await NarrativeEventAuthoringSession.prepare(
        fixture.projectPath,
      );
      final beforeIds = [
        for (final record in before.context.registryOrNull!.records) record.id,
      ];

      final result = await useCase.duplicate(
        projectPath: fixture.projectPath,
        eventId: productRoutePortEventId,
        environment: const NarrativeEventBuilderV2WriteEnvironment.clean(),
      );

      expect(result.status, NarrativeEventBuilderV2WriteStatus.failed);
      expect(result.code, 'persistenceException');
      final reopened = await NarrativeEventAuthoringSession.prepare(
        fixture.projectPath,
      );
      expect(
        [
          for (final record in reopened.context.registryOrNull!.records)
            record.id
        ],
        beforeIds,
      );
    });

    test('previews canonical consumers before deleting an Event', () async {
      final fixture = await EventBuilderV2ProductRouteFixture.create(
        mode: EventSystemMode.dualRead,
      );
      addTearDown(fixture.dispose);
      final useCase = NarrativeEventBuilderV2UseCase(
        persistenceGateway: _RecordingGateway(),
      );

      final preview = await useCase.previewDelete(
        projectPath: fixture.projectPath,
        eventId: productRouteForestEventId,
      );

      expect(preview.rejectionCode, 'eventReferenced');
      expect(preview.deletionPreview!.canDelete, isFalse);
      expect(
        preview.deletionPreview!.consumers.map((usage) => usage.owner),
        contains(const NarrativeDependencyKey.eventV2(productRoutePortEventId)),
      );
    });
  });
}

final class _FailOnSecondGateway
    implements NarrativeEventRegistryPersistenceGateway {
  _FailOnSecondGateway(this.delegate);

  final NarrativeEventRegistryPersistenceGateway delegate;
  int persistCalls = 0;

  @override
  Future<NarrativeEventRegistryPersistenceResult> persist(
    NarrativeEventRegistryWriteRequest request,
  ) {
    persistCalls++;
    if (persistCalls == 2) {
      return Future.value(
        NarrativeEventRegistryPersistenceResult(
          status: NarrativeEventRegistryPersistenceStatus.staleRevision,
          code: 'staleRevision',
          message: 'Le projet a changé pendant la création.',
        ),
      );
    }
    return delegate.persist(request);
  }

  @override
  Future<NarrativeEventRegistryRecoveryInspection> inspectRecovery(
    String projectPath,
  ) =>
      delegate.inspectRecovery(projectPath);

  @override
  Future<List<NarrativeEventRegistryPersistenceResult>> recover(
    String projectPath,
  ) =>
      delegate.recover(projectPath);

  @override
  Future<NarrativeEventRegistryPersistenceResult> undo(String undoPath) =>
      delegate.undo(undoPath);
}

final class _RecordingGateway
    implements NarrativeEventRegistryPersistenceGateway {
  _RecordingGateway({this.persistResult});

  final NarrativeEventRegistryPersistenceResult? persistResult;
  int persistCalls = 0;

  @override
  Future<NarrativeEventRegistryPersistenceResult> persist(
    NarrativeEventRegistryWriteRequest request,
  ) async {
    persistCalls++;
    return persistResult ??
        NarrativeEventRegistryPersistenceResult(
          status: NarrativeEventRegistryPersistenceStatus.committed,
          code: 'committed',
          message: 'Enregistré.',
        );
  }

  @override
  Future<NarrativeEventRegistryRecoveryInspection> inspectRecovery(
    String projectPath,
  ) async {
    return NarrativeEventRegistryRecoveryInspection(
      status: NarrativeEventRegistryRecoveryGateStatus.clear,
      issues: const [],
    );
  }

  @override
  Future<List<NarrativeEventRegistryPersistenceResult>> recover(
    String projectPath,
  ) async =>
      const [];

  @override
  Future<NarrativeEventRegistryPersistenceResult> undo(String undoPath) async {
    return NarrativeEventRegistryPersistenceResult(
      status: NarrativeEventRegistryPersistenceStatus.noOp,
      code: 'noOp',
      message: 'Aucune annulation.',
    );
  }
}

final class _ThrowingGateway
    implements NarrativeEventRegistryPersistenceGateway {
  @override
  Future<NarrativeEventRegistryPersistenceResult> persist(
    NarrativeEventRegistryWriteRequest request,
  ) =>
      throw const FileSystemException('write failed');

  @override
  Future<NarrativeEventRegistryRecoveryInspection> inspectRecovery(
    String projectPath,
  ) async =>
      NarrativeEventRegistryRecoveryInspection(
        status: NarrativeEventRegistryRecoveryGateStatus.clear,
        issues: const [],
      );

  @override
  Future<List<NarrativeEventRegistryPersistenceResult>> recover(
    String projectPath,
  ) async =>
      const [];

  @override
  Future<NarrativeEventRegistryPersistenceResult> undo(String undoPath) =>
      throw const FileSystemException('undo failed');
}
