import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/app/providers/core/repository_providers.dart';
import 'package:map_editor/src/application/models/narrative_authoring_transaction.dart';
import 'package:map_editor/src/application/ports/narrative_authoring_persistence_gateway.dart';
import 'package:map_editor/src/application/use_cases/execute_narrative_authoring_transaction.dart';
import 'package:map_editor/src/domain/repositories/repositories.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';

void main() {
  group('ExecuteNarrativeAuthoringTransaction', () {
    test('Rejected and NoChange never reach persistence', () async {
      final gateway = _RecordingGateway();
      final execute = ExecuteNarrativeAuthoringTransaction(gateway);
      final project = _project();
      final asset = _cinematic();
      final projectWithAsset = _project(cinematics: [asset]);

      final rejected = await execute.execute(
        projectPath: '/projects/selbrume',
        operationId: 'reject-1',
        mutation: NarrativeAssetMutation.createCinematic(
          project,
          title: '   ',
        ),
      );
      final noChange = await execute.execute(
        projectPath: '/projects/selbrume',
        operationId: 'no-change-1',
        mutation: NarrativeAssetMutation.updateCinematic(
          projectWithAsset,
          cinematicId: asset.id,
          cinematic: asset,
        ),
      );

      expect(rejected.status, NarrativeAuthoringTransactionStatus.rejected);
      expect(rejected.transaction.before, same(project));
      expect(rejected.transaction.after, same(project));
      expect(rejected.transaction.mutation, isA<NarrativeAssetRejected>());
      expect(noChange.status, NarrativeAuthoringTransactionStatus.noChange);
      expect(noChange.transaction.before, same(projectWithAsset));
      expect(noChange.transaction.after, same(projectWithAsset));
      expect(noChange.transaction.mutation, isA<NarrativeAssetNoChange>());
      expect(gateway.calls, 0);
    });

    test('an applicable mutation is persisted exactly once', () async {
      final gateway = _RecordingGateway();
      final execute = ExecuteNarrativeAuthoringTransaction(gateway);
      final project = _project();
      final mutation = NarrativeAssetMutation.createCinematic(
        project,
        title: 'Arrivée au port',
      );

      final result = await execute.execute(
        projectPath: '/projects/selbrume',
        operationId: 'create-cinematic-1',
        mutation: mutation,
      );

      expect(result.status, NarrativeAuthoringTransactionStatus.committed);
      expect(result.succeeded, isTrue);
      expect(gateway.calls, 1);
      expect(gateway.lastTransaction, same(result.transaction));
      expect(result.transaction.projectPath, '/projects/selbrume');
      expect(result.transaction.operationId, 'create-cinematic-1');
      expect(result.transaction.before, same(mutation.before));
      expect(result.transaction.after, same(mutation.after));
      expect(result.transaction.mutation, same(mutation));
      expect(result.persistenceResult, same(gateway.result));
    });

    test('persistence failure and recovery-required statuses are preserved',
        () async {
      final cases = <(
        NarrativeAuthoringPersistenceStatus,
        NarrativeAuthoringTransactionStatus,
      )>[
        (
          NarrativeAuthoringPersistenceStatus.persistenceFailed,
          NarrativeAuthoringTransactionStatus.persistenceFailed,
        ),
        (
          NarrativeAuthoringPersistenceStatus.recoveryRequired,
          NarrativeAuthoringTransactionStatus.recoveryRequired,
        ),
      ];

      for (final (persistenceStatus, expectedStatus) in cases) {
        final gateway = _RecordingGateway(
          result: NarrativeAuthoringPersistenceResult(
            status: persistenceStatus,
            code: persistenceStatus.name,
            message: 'Persistence outcome: ${persistenceStatus.name}',
          ),
        );
        final result =
            await ExecuteNarrativeAuthoringTransaction(gateway).execute(
          projectPath: '/projects/selbrume',
          operationId: 'failure-${persistenceStatus.name}',
          mutation: NarrativeAssetMutation.createCinematic(
            _project(),
            title: 'Tempête',
          ),
        );

        expect(result.status, expectedStatus);
        expect(result.code, persistenceStatus.name);
        expect(result.succeeded, isFalse);
        expect(gateway.calls, 1);
      }
    });

    test('a reentrant transaction is refused while persistence is pending',
        () async {
      final persistence = Completer<NarrativeAuthoringPersistenceResult>();
      final gateway = _RecordingGateway(handler: (_) => persistence.future);
      final execute = ExecuteNarrativeAuthoringTransaction(gateway);
      final firstMutation = NarrativeAssetMutation.createCinematic(
        _project(),
        title: 'Première',
      );
      final secondMutation = NarrativeAssetMutation.createCinematic(
        _project(),
        title: 'Deuxième',
      );

      final first = execute.execute(
        projectPath: '/projects/selbrume',
        operationId: 'first',
        mutation: firstMutation,
      );
      await gateway.started.future;

      final rejectedWhileBusy = await execute.execute(
        projectPath: '/projects/selbrume',
        operationId: 'rejected-while-busy',
        mutation: NarrativeAssetMutation.createCinematic(
          _project(),
          title: '   ',
        ),
      );
      final existing = _cinematic();
      final projectWithExisting = _project(cinematics: [existing]);
      final noChangeWhileBusy = await execute.execute(
        projectPath: '/projects/selbrume',
        operationId: 'no-change-while-busy',
        mutation: NarrativeAssetMutation.updateCinematic(
          projectWithExisting,
          cinematicId: existing.id,
          cinematic: existing,
        ),
      );

      final second = await execute.execute(
        projectPath: '/projects/selbrume',
        operationId: 'second',
        mutation: secondMutation,
      );

      expect(second.status, NarrativeAuthoringTransactionStatus.busy);
      expect(second.code, 'transactionBusy');
      expect(second.transaction.mutation, same(secondMutation));
      expect(
        rejectedWhileBusy.status,
        NarrativeAuthoringTransactionStatus.rejected,
      );
      expect(
        noChangeWhileBusy.status,
        NarrativeAuthoringTransactionStatus.noChange,
      );
      expect(gateway.calls, 1);

      persistence
          .complete(const NarrativeAuthoringPersistenceResult.committed());
      expect(
        (await first).status,
        NarrativeAuthoringTransactionStatus.committed,
      );

      final third = await execute.execute(
        projectPath: '/projects/selbrume',
        operationId: 'third',
        mutation: NarrativeAssetMutation.createCinematic(
          _project(),
          title: 'Troisième',
        ),
      );
      expect(third.status, NarrativeAuthoringTransactionStatus.committed);
      expect(gateway.calls, 2);
    });

    test('an unexpected gateway error becomes a persistence failure', () async {
      final gateway = _RecordingGateway(
        handler: (_) => Future<NarrativeAuthoringPersistenceResult>.error(
          const FormatException('disk payload'),
        ),
      );

      final result =
          await ExecuteNarrativeAuthoringTransaction(gateway).execute(
        projectPath: '/projects/selbrume',
        operationId: 'throws',
        mutation: NarrativeAssetMutation.createCinematic(
          _project(),
          title: 'Erreur',
        ),
      );

      expect(
        result.status,
        NarrativeAuthoringTransactionStatus.persistenceFailed,
      );
      expect(result.code, 'unexpectedPersistenceFailure');
      expect(result.persistenceError, isA<FormatException>());
      expect(gateway.calls, 1);
    });
  });

  group('NarrativeAuthoringTransaction', () {
    test('rejects blank persistence identities', () {
      final mutation = NarrativeAssetMutation.createCinematic(
        _project(),
        title: 'Intro',
      );

      expect(
        () => NarrativeAuthoringTransaction.fromMutation(
          projectPath: ' ',
          operationId: 'operation',
          mutation: mutation,
        ),
        throwsArgumentError,
      );
      expect(
        () => NarrativeAuthoringTransaction.fromMutation(
          projectPath: '/projects/selbrume',
          operationId: ' ',
          mutation: mutation,
        ),
        throwsArgumentError,
      );
    });
  });

  group('EditorNotifier narrative authoring adoption', () {
    test(
        'publishes dirty state before commit and cleans only after confirmation',
        () async {
      final root = await Directory.systemTemp.createTemp('narrative_tx_state_');
      addTearDown(() => root.delete(recursive: true));
      final persistence = Completer<NarrativeAuthoringPersistenceResult>();
      final gateway = _RecordingGateway(handler: (_) => persistence.future);
      final container = ProviderContainer(
        overrides: [
          narrativeAuthoringPersistenceGatewayProvider.overrideWithValue(
            gateway,
          ),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final before = _project();
      notifier.state = EditorState(
        projectRootPath: root.path,
        project: before,
      );

      final pending = notifier.executeNarrativeAuthoringMutation(
        (project) => NarrativeAssetMutation.createCinematic(
          project,
          title: 'Port',
        ),
        operationId: 'create-port',
      );
      await gateway.started.future;

      expect(notifier.state.project!.cinematics.single.title, 'Port');
      expect(notifier.state.isProjectDirty, isTrue);
      expect(notifier.state.isSaving, isTrue);
      expect(
        notifier.state.statusMessage,
        isNot(contains('enregistrée.')),
      );

      persistence.complete(
        const NarrativeAuthoringPersistenceResult.committed(),
      );
      final result = await pending;

      expect(result!.status, NarrativeAuthoringTransactionStatus.committed);
      expect(notifier.state.isProjectDirty, isFalse);
      expect(notifier.state.isSaving, isFalse);
      expect(
          notifier.state.statusMessage, 'Modification narrative enregistrée.');
    });

    test('persistence failure keeps the authored document visible and dirty',
        () async {
      final root = await Directory.systemTemp.createTemp('narrative_tx_fail_');
      addTearDown(() => root.delete(recursive: true));
      final gateway = _RecordingGateway(
        result: const NarrativeAuthoringPersistenceResult(
          status: NarrativeAuthoringPersistenceStatus.persistenceFailed,
          code: 'staleProjectRevision',
          message: 'The project changed externally.',
        ),
      );
      final projectRepository = _RecordingProjectRepository();
      final container = ProviderContainer(
        overrides: [
          narrativeAuthoringPersistenceGatewayProvider.overrideWithValue(
            gateway,
          ),
          projectRepositoryProvider.overrideWithValue(projectRepository),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        projectRootPath: root.path,
        project: _project(),
      );

      final result = await notifier.executeNarrativeAuthoringMutation(
        (project) => NarrativeAssetMutation.createCinematic(
          project,
          title: 'Local only',
        ),
        operationId: 'create-local-only',
      );

      expect(
        result!.status,
        NarrativeAuthoringTransactionStatus.persistenceFailed,
      );
      expect(notifier.state.project!.cinematics.single.title, 'Local only');
      expect(notifier.state.isProjectDirty, isTrue);
      expect(notifier.state.isSaving, isFalse);
      expect(
        notifier.state.errorMessage,
        contains('Modification locale conservée'),
      );

      final genericSave = await notifier.saveProjectManifest();

      expect(genericSave, isFalse);
      expect(projectRepository.calls, 0);
      expect(
          notifier.state.errorMessage, contains('Sauvegarde projet bloquée'));
      expect(notifier.state.errorMessage, contains('Rechargez le projet'));
    });

    test('a dirty no-op retry cannot become a false persistence success',
        () async {
      final root = await Directory.systemTemp.createTemp('narrative_tx_retry_');
      addTearDown(() => root.delete(recursive: true));
      final gateway = _RecordingGateway(
        result: const NarrativeAuthoringPersistenceResult(
          status: NarrativeAuthoringPersistenceStatus.persistenceFailed,
          code: 'staleProjectRevision',
          message: 'The project changed externally.',
        ),
      );
      final container = ProviderContainer(
        overrides: [
          narrativeAuthoringPersistenceGatewayProvider.overrideWithValue(
            gateway,
          ),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final original = _cinematic();
      notifier.state = EditorState(
        projectRootPath: root.path,
        project: _project(cinematics: [original]),
      );

      final first = await notifier.executeNarrativeAuthoringMutation(
        (project) => NarrativeAssetMutation.updateCinematic(
          project,
          cinematicId: original.id,
          cinematic: CinematicAsset(
            id: original.id,
            title: 'Intro locale',
            timeline: original.timeline,
          ),
        ),
        operationId: 'update-local-first',
      );
      final localAsset = notifier.state.project!.cinematics.single;
      final retry = await notifier.executeNarrativeAuthoringMutation(
        (project) => NarrativeAssetMutation.updateCinematic(
          project,
          cinematicId: localAsset.id,
          cinematic: localAsset,
        ),
        operationId: 'update-local-retry',
      );

      expect(
        first!.status,
        NarrativeAuthoringTransactionStatus.persistenceFailed,
      );
      expect(retry!.status, NarrativeAuthoringTransactionStatus.rejected);
      expect(retry.code, 'unsavedLocalSnapshot');
      expect(gateway.calls, 1);
      expect(notifier.state.isProjectDirty, isTrue);
      expect(notifier.state.project!.cinematics.single.title, 'Intro locale');
      expect(notifier.state.errorMessage, contains('seulement localement'));
      expect(notifier.state.statusMessage, isNot('Modification enregistrée.'));
    });

    test('a newer local edit remains dirty after the older snapshot commits',
        () async {
      final root = await Directory.systemTemp.createTemp('narrative_tx_race_');
      addTearDown(() => root.delete(recursive: true));
      final persistence = Completer<NarrativeAuthoringPersistenceResult>();
      final gateway = _RecordingGateway(handler: (_) => persistence.future);
      final container = ProviderContainer(
        overrides: [
          narrativeAuthoringPersistenceGatewayProvider.overrideWithValue(
            gateway,
          ),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        projectRootPath: root.path,
        project: _project(),
      );

      final pending = notifier.executeNarrativeAuthoringMutation(
        (project) => NarrativeAssetMutation.createCinematic(
          project,
          title: 'Persisted snapshot',
        ),
        operationId: 'persist-snapshot',
      );
      await gateway.started.future;
      final newer = notifier.state.project!.copyWith(name: 'Newer local edit');
      notifier.applyInMemoryProjectManifest(newer);
      persistence.complete(
        const NarrativeAuthoringPersistenceResult.committed(),
      );
      await pending;

      expect(notifier.state.project, same(newer));
      expect(notifier.state.isProjectDirty, isTrue);
      expect(notifier.state.statusMessage, contains('plus récentes'));
    });

    test('a result from the previous project cannot contaminate a new session',
        () async {
      final rootA = await Directory.systemTemp.createTemp('narrative_tx_a_');
      final rootB = await Directory.systemTemp.createTemp('narrative_tx_b_');
      addTearDown(() => rootA.delete(recursive: true));
      addTearDown(() => rootB.delete(recursive: true));
      final persistence = Completer<NarrativeAuthoringPersistenceResult>();
      final gateway = _RecordingGateway(handler: (_) => persistence.future);
      final container = ProviderContainer(
        overrides: [
          narrativeAuthoringPersistenceGatewayProvider.overrideWithValue(
            gateway,
          ),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        projectRootPath: rootA.path,
        project: _project(),
      );

      final pending = notifier.executeNarrativeAuthoringMutation(
        (project) => NarrativeAssetMutation.createCinematic(
          project,
          title: 'Projet A',
        ),
        operationId: 'project-a-write',
      );
      await gateway.started.future;
      final projectB = _project().copyWith(name: 'Projet B');
      notifier.state = EditorState(
        projectRootPath: rootB.path,
        project: projectB,
        statusMessage: 'Projet B actif',
      );
      persistence.complete(
        const NarrativeAuthoringPersistenceResult(
          status: NarrativeAuthoringPersistenceStatus.persistenceFailed,
          code: 'staleProjectRevision',
          message: 'Projet A obsolète.',
        ),
      );

      final supersededResult = await pending;

      expect(supersededResult, isNull);
      expect(notifier.state.project, same(projectB));
      expect(notifier.state.projectRootPath, rootB.path);
      expect(notifier.state.isProjectDirty, isFalse);
      expect(notifier.state.isSaving, isFalse);
      expect(notifier.state.statusMessage, 'Projet B actif');
      expect(notifier.state.errorMessage, isNull);
    });

    test('referenced delete is rejected before persistence with exact path',
        () async {
      final root = await Directory.systemTemp.createTemp('narrative_tx_refs_');
      addTearDown(() => root.delete(recursive: true));
      final gateway = _RecordingGateway();
      final container = ProviderContainer(
        overrides: [
          narrativeAuthoringPersistenceGatewayProvider.overrideWithValue(
            gateway,
          ),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final cinematic = _cinematic();
      final scene = SceneAsset(
        id: 'scene_intro',
        name: 'Intro',
        graph: SceneGraph(
          startNodeId: 'start',
          nodes: [
            SceneNode(id: 'start', kind: SceneNodeKind.start),
            SceneNode(
              id: 'cinematic',
              kind: SceneNodeKind.cinematic,
              payload: SceneCinematicPayload(cinematicId: cinematic.id),
            ),
          ],
        ),
      );
      final project = _project(cinematics: [cinematic]).copyWith(
        scenes: [scene],
      );
      notifier.state = EditorState(
        projectRootPath: root.path,
        project: project,
      );

      final result = await notifier.executeNarrativeAuthoringMutation(
        (current) => NarrativeAssetMutation.deleteCinematic(
          current,
          cinematicId: cinematic.id,
        ),
        operationId: 'delete-referenced',
      );

      expect(result!.status, NarrativeAuthoringTransactionStatus.rejected);
      expect(result.transaction.mutation, isA<NarrativeAssetRejected>());
      expect(notifier.state.project, same(project));
      expect(notifier.state.isProjectDirty, isFalse);
      expect(gateway.calls, 0);
      expect(
        notifier.state.errorMessage,
        contains('scenes[scene_intro].graph.nodes[1].payload.cinematicId'),
      );
    });
  });
}

final class _RecordingGateway implements NarrativeAuthoringPersistenceGateway {
  _RecordingGateway({
    NarrativeAuthoringPersistenceResult? result,
    this.handler,
  }) : result = result ?? const NarrativeAuthoringPersistenceResult.committed();

  final NarrativeAuthoringPersistenceResult result;
  final Future<NarrativeAuthoringPersistenceResult> Function(
    NarrativeAuthoringTransaction transaction,
  )? handler;
  final Completer<void> started = Completer<void>();
  int calls = 0;
  NarrativeAuthoringTransaction? lastTransaction;

  @override
  Future<NarrativeAuthoringPersistenceResult> persist(
    NarrativeAuthoringTransaction transaction,
  ) {
    calls += 1;
    lastTransaction = transaction;
    if (!started.isCompleted) started.complete();
    return handler?.call(transaction) ?? Future.value(result);
  }

  @override
  Future<NarrativeAuthoringPersistenceResult> persistProjectDocument({
    required String projectPath,
    required String operationId,
    required ProjectManifest before,
    required ProjectManifest after,
    String? expectedRevision,
  }) {
    throw UnsupportedError('Project document persistence is not expected.');
  }
}

final class _RecordingProjectRepository implements ProjectRepository {
  int calls = 0;

  @override
  Future<ProjectManifest> loadProject(String path) {
    throw UnimplementedError();
  }

  @override
  Future<void> saveProject(ProjectManifest project, String path) async {
    calls += 1;
  }
}

ProjectManifest _project({
  List<CinematicAsset> cinematics = const <CinematicAsset>[],
}) {
  return ProjectManifest(
    name: 'Narrative transaction test',
    maps: const [],
    tilesets: const [],
    cinematics: cinematics,
  );
}

CinematicAsset _cinematic() {
  return CinematicAsset(
    id: 'cinematic_intro',
    title: 'Intro',
    timeline: CinematicTimeline(),
  );
}
