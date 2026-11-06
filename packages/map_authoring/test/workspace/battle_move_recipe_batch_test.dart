import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/map_authoring_local.dart'
    show
        AuthoringPerformanceCounterName,
        AuthoringPerformanceObserver,
        AuthoringPerformanceSpan;
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../../../map_distribution/test/support/spatial_feature_capabilities_fixture.dart';

final class _Media implements PokemonBoundedExternalHttpTransport {
  final requests = <Uri>[];
  final failures = <String, int>{};
  final corrupted = <String>{};
  Future<void> Function(Uri uri)? onRequest;

  List<int> recipe(String move) => utf8.encode(jsonEncode({
        'schemaVersion': 1,
        'recipeId': '$move-recipe',
        'revision': '1',
        'moveSourceId': move,
        'variant': 'default',
        'requiredCapabilities': ['wait'],
        'provenance': {
          'source': 'synthetic',
          'sourceRevision': '1',
          'sourcePaths': <String>[],
          'converter': 'test',
        },
        'resources': <Object>[],
        'program': {'kind': 'wait', 'durationMs': 1},
      }));

  @override
  Future<PokemonExternalHttpResponse> getBounded(Uri uri,
      {required Map<String, String> headers,
      required int maximumBytes,
      required Duration timeout}) async {
    requests.add(uri);
    await onRequest?.call(uri);
    final isListing = uri.path.contains('/owners/move/');
    final id = uri.pathSegments.last;
    final move = isListing ? id : id.replaceFirst('-recipe', '');
    final status = failures[move] ?? 200;
    final bytes = isListing
        ? utf8.encode(jsonEncode([
            {
              'id': '$move-recipe',
              'sha256': sha256.convert(recipe(move)).toString(),
              'contentType': 'application/vnd.avelune.battle-recipe+json',
              'usage': 'battle',
              'representation': 'recipe',
              'style': 'gen5-bw2',
              'metadata': {
                'recipeId': '$move-recipe',
                'moveSourceId': move,
                'variant': 'default',
                'revision': '1',
                'bindings': <String, String>{},
              },
            }
          ]))
        : corrupted.contains(move)
            ? <int>[1, 2, 3]
            : recipe(move);
    return PokemonExternalHttpResponse(
        statusCode: status,
        headers: const {},
        body: isListing ? utf8.decode(bytes) : '',
        bodyBytes: Uint8List.fromList(bytes));
  }
}

final class _Counters implements AuthoringPerformanceObserver {
  final values = <String, int>{};
  @override
  void incrementCounter(String name, {int by = 1}) =>
      values.update(name, (value) => value + by, ifAbsent: () => by);
  @override
  AuthoringPerformanceSpan? startSpan(String name) => null;
}

void main() {
  late Directory root;
  late ProjectOpenService opener;
  late OpenedProject opened;
  late WorkspaceHandleStore handles;
  late LocalMapAuthoringMutationApi api;
  late _Media transport;
  late BattleMoveRecipeBatchImporter importer;
  late File moves;
  late _Counters counters;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('battle-batch-');
    final fixture = spatialFeaturePayload('companion');
    final base = ProjectManifest.fromJson(
        jsonDecode(utf8.decode(fixture['project/project.json']!)));
    final project = base.copyWith(
      pokemon: base.pokemon.copyWith(catalogRelease: 'test'),
      maps: [
        ...base.maps,
        ProjectMapEntry(
            id: 'other', name: 'Other', relativePath: 'maps/other.json'),
      ],
    );
    final store = await CatalogStorageStore.open(projectRoot: root.path);
    await WorkingProjectCatalog.create(
        store: store, projectId: 'batch-test', project: project);
    moves = File('${root.path}/${project.pokemon.catalogFiles['moves']}');
    await moves.parent.create(recursive: true);
    await moves.writeAsString(jsonEncode({
      'schemaVersion': 1,
      'catalog': 'moves',
      'entries': [
        {'id': 'tackle', 'source': 'heartgold-fr-rom'},
        {'id': 'surf', 'source': 'heartgold-fr-rom'},
        {'id': 'thunder', 'source': 'project_custom'},
      ],
    }));
    final other = File('${root.path}/maps/other.json');
    await other.parent.create(recursive: true);
    await other.writeAsString('must not be read');
    handles = WorkspaceHandleStore();
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path], fileReader: reader);
    opener = ProjectOpenService(
        policy: policy,
        fileReader: reader,
        handles: handles,
        catalogMetadataFields: {},
        initializeSceneOwners: false);
    opened = await opener.openProject(root.path);
    counters = _Counters();
    api = LocalMapAuthoringMutationApi(
        policy: policy,
        snapshotLoader: ProjectSnapshotLoader(handles: handles),
        performanceObserver: counters,
        enablePokemonRecipeNetwork: true);
    await api.attachProject(
        projectRootPath: root.path,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle);
    transport = _Media();
    importer = BattleMoveRecipeBatchImporter(
      openService: opener,
      authoring: api,
      media: AvelunePokemonMediaSource(client: transport, release: 'test'),
    );
  });

  tearDown(() async {
    await api.detachWorkspace(opened.workspaceHandle);
    handles.closeWorkspace(opened.workspaceHandle);
    if (await root.exists()) await root.delete(recursive: true);
  });

  test(
      'imports independently, skips a custom move, and resumes without duplicates',
      () async {
    final before = await moves.readAsBytes();
    final first = await importer.run(
        projectHandle: opened.projectHandle,
        workspaceHandle: opened.workspaceHandle,
        operationId: 'batch-one',
        limit: 3);
    expect(first.results.map((result) => result.status), [
      BattleMoveRecipeBatchStatus.imported,
      BattleMoveRecipeBatchStatus.imported,
      BattleMoveRecipeBatchStatus.custom,
    ]);
    expect(first.remaining, 0);
    expect(first.results.first.changeNotification, isNotNull);
    expect(await moves.readAsBytes(), before);
    expect(
        await File('${root.path}/${battleRecipeBindingPath('tackle')}')
            .exists(),
        isTrue);
    expect(
        await File('${root.path}/${battleRecipeBindingPath('surf')}').exists(),
        isTrue);
    expect(transport.requests.where((uri) => uri.path.contains('thunder')),
        isEmpty);
    expect(transport.requests, hasLength(6));
    await api.detachWorkspace(opened.workspaceHandle);
    handles.closeWorkspace(opened.workspaceHandle);
    opened = await opener.openProject(root.path);
    await api.attachProject(
        projectRootPath: root.path,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle);
    final second = await importer.run(
        projectHandle: opened.projectHandle,
        workspaceHandle: opened.workspaceHandle,
        operationId: 'batch-two',
        limit: 3);
    expect(second.results.map((result) => result.status), [
      BattleMoveRecipeBatchStatus.alreadyPresent,
      BattleMoveRecipeBatchStatus.alreadyPresent,
      BattleMoveRecipeBatchStatus.custom,
    ]);
    expect(transport.requests, hasLength(8));
  });

  test('keeps earlier imports when a later recipe is corrupted', () async {
    transport.corrupted.add('surf');
    final first = await importer.run(
        projectHandle: opened.projectHandle,
        workspaceHandle: opened.workspaceHandle,
        operationId: 'batch-corrupt',
        limit: 3);
    expect(first.results.map((result) => result.status), [
      BattleMoveRecipeBatchStatus.imported,
      BattleMoveRecipeBatchStatus.failed,
      BattleMoveRecipeBatchStatus.custom,
    ]);
    expect(
        await File('${root.path}/${battleRecipeBindingPath('surf')}').exists(),
        isFalse);
    transport.corrupted.clear();
    final retry = await importer.run(
        projectHandle: opened.projectHandle,
        workspaceHandle: opened.workspaceHandle,
        operationId: 'batch-retry',
        limit: 3);
    expect(retry.results.map((result) => result.status), [
      BattleMoveRecipeBatchStatus.alreadyPresent,
      BattleMoveRecipeBatchStatus.imported,
      BattleMoveRecipeBatchStatus.custom,
    ]);
  });

  test('a bounded slice does not read unrelated move bindings', () async {
    final unrelated = File('${root.path}/${battleRecipeBindingPath('surf')}');
    await unrelated.parent.create(recursive: true);
    await unrelated.writeAsBytes(List<int>.filled(70000, 65));
    final result = await importer.run(
        projectHandle: opened.projectHandle,
        workspaceHandle: opened.workspaceHandle,
        operationId: 'batch-scoped',
        limit: 1);
    expect(result.results.single.status, BattleMoveRecipeBatchStatus.imported);
    expect(result.remaining, 2);
    expect(await unrelated.length(), 70000);
  });

  test('an oversized binding is isolated to its move', () async {
    final unrelated = File('${root.path}/${battleRecipeBindingPath('surf')}');
    await unrelated.parent.create(recursive: true);
    await unrelated.writeAsBytes(List<int>.filled(70000, 65));
    final result = await importer.run(
        projectHandle: opened.projectHandle,
        workspaceHandle: opened.workspaceHandle,
        operationId: 'oversized-binding',
        limit: 3);
    expect(result.results.map((entry) => entry.status), [
      BattleMoveRecipeBatchStatus.imported,
      BattleMoveRecipeBatchStatus.uncertain,
      BattleMoveRecipeBatchStatus.custom,
    ]);
    expect(result.results[1].reason, 'invalidBinding');
    expect(await unrelated.length(), 70000);
  });

  test('one import does not scan unrelated transaction directories', () async {
    final gateway =
        await LocalTransactionFileGateway.open(projectRoot: root.path);
    await gateway.preparePendingJournalIndex();
    final directory = Directory('${root.path}/.pokemap/authoring/transactions');
    for (var index = 0; index < 120; index++) {
      await Directory('${directory.path}/unrelated_$index')
          .create(recursive: true);
    }
    counters.values.clear();
    final result = await importer.run(
        projectHandle: opened.projectHandle,
        workspaceHandle: opened.workspaceHandle,
        operationId: 'batch-cost',
        limit: 1);
    expect(result.results.single.status, BattleMoveRecipeBatchStatus.imported);
    final reads =
        counters.values[AuthoringPerformanceCounterName.filesystemRead] ?? 0;
    expect(reads, lessThan(120),
        reason:
            'Unrelated transactions must not be scanned. Actual filesystem reads: $reads');
  });

  test('continuation rejects a changed catalog before importing another move',
      () async {
    final first = await importer.run(
        projectHandle: opened.projectHandle,
        workspaceHandle: opened.workspaceHandle,
        operationId: 'batch-page-one',
        limit: 1);
    expect(first.nextIndex, 1);
    final requests = transport.requests.length;
    final catalog =
        jsonDecode(await moves.readAsString()) as Map<String, dynamic>;
    (catalog['entries'] as List).removeAt(0);
    await moves.writeAsString(jsonEncode(catalog));
    await expectLater(
        importer.run(
            projectHandle: opened.projectHandle,
            workspaceHandle: opened.workspaceHandle,
            operationId: 'batch-page-two',
            startIndex: first.nextIndex,
            limit: 1,
            expectedInventoryRevision: first.inventoryRevision),
        throwsA(isA<CatalogStorageException>().having(
            (error) => error.code, 'code', 'catalog.revision_conflict')));
    expect(transport.requests, hasLength(requests));
    expect(
        await File('${root.path}/${battleRecipeBindingPath('surf')}').exists(),
        isFalse);
  });

  test('continuation resumes at the next move for the same catalog revision',
      () async {
    final first = await importer.run(
        projectHandle: opened.projectHandle,
        workspaceHandle: opened.workspaceHandle,
        operationId: 'page-1',
        limit: 1);
    final second = await importer.run(
        projectHandle: opened.projectHandle,
        workspaceHandle: opened.workspaceHandle,
        operationId: 'page-2',
        startIndex: first.nextIndex,
        expectedInventoryRevision: first.inventoryRevision,
        limit: 2);
    expect(second.results.map((result) => result.status), [
      BattleMoveRecipeBatchStatus.imported,
      BattleMoveRecipeBatchStatus.custom,
    ]);
    expect(second.remaining, 0);
  });

  test('preserves a preexisting different binding', () async {
    final binding = File('${root.path}/${battleRecipeBindingPath('tackle')}');
    await binding.parent.create(recursive: true);
    final value = BattleRecipeProjectBinding(
      binding: BattleMoveRecipeBinding.fromJson({
        'schemaVersion': 1,
        'projectMoveId': 'tackle',
        'sourceMoveId': 'tackle',
        'catalogReleaseId': 'test',
        'recipeId': 'old',
        'variant': 'default',
        'revision': '1',
        'recipeSha256': 'a' * 64,
      }),
      catalogMoveId: 'tackle',
      recipeMediaId: 'old',
    );
    await binding.writeAsString(jsonEncode(value.toJson()));
    final original = await binding.readAsBytes();
    final result = await importer.run(
        projectHandle: opened.projectHandle,
        workspaceHandle: opened.workspaceHandle,
        operationId: 'preserve-bound',
        limit: 1);
    expect(result.results.single.status, BattleMoveRecipeBatchStatus.preserved);
    expect(await binding.readAsBytes(), original);
    expect(transport.requests, hasLength(1));
  });

  test('stops on a network failure and reports unprocessed moves', () async {
    transport.failures['surf'] = 503;
    final result = await importer.run(
        projectHandle: opened.projectHandle,
        workspaceHandle: opened.workspaceHandle,
        operationId: 'batch-offline',
        limit: 3);
    expect(result.results.map((result) => result.status), [
      BattleMoveRecipeBatchStatus.imported,
      BattleMoveRecipeBatchStatus.failed,
    ]);
    expect(result.stopped, 'network');
    expect(result.nextIndex, 2);
    expect(result.remaining, 1);
    expect(transport.requests.where((uri) => uri.path.contains('thunder')),
        isEmpty);
    transport.failures.clear();
    final retry = await importer.run(
        projectHandle: opened.projectHandle,
        workspaceHandle: opened.workspaceHandle,
        operationId: 'network-retry',
        limit: 3);
    expect(retry.results.map((result) => result.status), [
      BattleMoveRecipeBatchStatus.alreadyPresent,
      BattleMoveRecipeBatchStatus.imported,
      BattleMoveRecipeBatchStatus.custom,
    ]);
  });

  test('cancellation during download prevents subsequent requests and writes',
      () async {
    final started = Completer<void>();
    final resume = Completer<void>();
    var cancelled = false;
    transport.onRequest = (uri) async {
      if (uri.path.endsWith('/tackle-recipe')) {
        started.complete();
        await resume.future;
      }
    };
    final pending = importer.run(
        projectHandle: opened.projectHandle,
        workspaceHandle: opened.workspaceHandle,
        operationId: 'batch-cancel',
        limit: 3,
        isCancelled: () => cancelled);
    await started.future;
    cancelled = true;
    resume.complete();
    final result = await pending;
    expect(result.stopped, 'cancelled');
    expect(result.results, isEmpty);
    expect(result.remaining, 3);
    expect(transport.requests, hasLength(3));
    expect(
        await File('${root.path}/${battleRecipeBindingPath('tackle')}')
            .exists(),
        isFalse);
  });

  test('cancellation just before applying does not write a binding', () async {
    var cancelled = false;
    importer = BattleMoveRecipeBatchImporter(
      openService: opener,
      authoring: api,
      media: AvelunePokemonMediaSource(client: transport, release: 'test'),
      withMutation: <T>(Future<T> Function() apply) {
        cancelled = true;
        return apply();
      },
    );
    final result = await importer.run(
        projectHandle: opened.projectHandle,
        workspaceHandle: opened.workspaceHandle,
        operationId: 'before-apply',
        limit: 1,
        isCancelled: () => cancelled);
    expect(result.stopped, 'cancelled');
    expect(result.remaining, 3);
    expect(
        await File('${root.path}/${battleRecipeBindingPath('tackle')}')
            .exists(),
        isFalse);
  });

  test('a batch cancelled before starting performs no network or writes',
      () async {
    final result = await importer.run(
        projectHandle: opened.projectHandle,
        workspaceHandle: opened.workspaceHandle,
        operationId: 'cancel-before-start',
        isCancelled: () => true);
    expect(result.stopped, 'cancelled');
    expect(result.remaining, 3);
    expect(result.results, isEmpty);
    expect(transport.requests, isEmpty);
    expect(
        await File('${root.path}/${battleRecipeBindingPath('tackle')}')
            .exists(),
        isFalse);
  });

  test('detects a concurrent change to the moves catalog before writing',
      () async {
    transport.onRequest = (uri) async {
      if (uri.path.endsWith('/tackle-recipe')) {
        final catalog =
            jsonDecode(await moves.readAsString()) as Map<String, dynamic>;
        (catalog['entries'] as List).first['source'] = 'project_custom';
        await moves.writeAsString(jsonEncode(catalog));
      }
    };
    final result = await importer.run(
        projectHandle: opened.projectHandle,
        workspaceHandle: opened.workspaceHandle,
        operationId: 'batch-concurrent',
        limit: 3);
    expect(result.results.single.status, BattleMoveRecipeBatchStatus.failed);
    expect(result.results.single.reason, 'projectChanged');
    expect(result.stopped, 'projectChanged');
    expect(result.remaining, 2);
    expect(
        await File('${root.path}/${battleRecipeBindingPath('tackle')}')
            .exists(),
        isFalse);
  });

  test('requires network permission before accessing the catalog', () async {
    await api.detachWorkspace(opened.workspaceHandle);
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path], fileReader: reader);
    api = LocalMapAuthoringMutationApi(
      policy: policy,
      snapshotLoader: ProjectSnapshotLoader(handles: handles),
      actor: AuthoringActor(actorId: 'restricted', permissions: const [
        AuthoringPermissionScope.projectRead,
        AuthoringPermissionScope.projectWrite,
        AuthoringPermissionScope.importRun,
      ]),
    );
    await api.attachProject(
        projectRootPath: root.path,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle);
    importer = BattleMoveRecipeBatchImporter(
        openService: opener,
        authoring: api,
        media: AvelunePokemonMediaSource(client: transport, release: 'test'));
    await expectLater(
        importer.run(
            projectHandle: opened.projectHandle,
            workspaceHandle: opened.workspaceHandle,
            operationId: 'batch-forbidden'),
        throwsA(isA<AuthoringAuthorizationException>()));
    expect(transport.requests, isEmpty);
  });

  test('older projects report required preparation and can retry after it',
      () async {
    final index = File(
        '${root.path}/.pokemap/authoring/transactions/pending-journals.json');
    if (await index.exists()) await index.delete();
    final first = await importer.run(
        projectHandle: opened.projectHandle,
        workspaceHandle: opened.workspaceHandle,
        operationId: 'legacy-batch',
        limit: 1);
    expect(first.results, isEmpty);
    expect(first.stopped, 'preparationRequired');
    expect(transport.requests, isEmpty);
    expect(
        await File('${root.path}/${battleRecipeBindingPath('tackle')}')
            .exists(),
        isFalse);
    await api.prepareWorkshopCatalog(opened.projectHandle);
    final retry = await importer.run(
        projectHandle: opened.projectHandle,
        workspaceHandle: opened.workspaceHandle,
        operationId: 'legacy-prepared',
        limit: 1);
    expect(retry.results.single.status, BattleMoveRecipeBatchStatus.imported);
  });

  test('JSONL executes the same bounded batch and discovers the command',
      () async {
    final reads = AuthoringReadApi(
        openService: opener,
        snapshotLoader: ProjectSnapshotLoader(handles: handles));
    final worker = JsonlWorker(
        api: reads,
        mutations: api,
        moveRecipeBatch: BattleMoveRecipeBatchService(
            openService: opener, authoring: api, client: transport));
    final description = jsonDecode(await worker.processLine(jsonEncode({
      'id': 'describe-batch',
      'command': 'describe',
      'args': {},
    }))) as Map<String, dynamic>;
    expect(description['status'], 'success');
    expect(
        ((description['data'] as Map)['commands'] as List)
            .where((command) => command['id'] == 'pokemon_move_recipe_batch'),
        hasLength(1));
    final response = jsonDecode(await worker.processLine(jsonEncode({
      'id': 'batch',
      'command': 'pokemon_move_recipe_batch',
      'args': {
        'projectHandle': opened.projectHandle.value,
        'workspaceHandle': opened.workspaceHandle.value,
        'operationId': 'jsonl-batch',
        'limit': 2,
      },
    }))) as Map<String, dynamic>;
    expect(response['status'], 'success', reason: response.toString());
    final data = response['data'] as Map;
    expect((data['results'] as List).map((entry) => entry['status']),
        ['imported', 'imported']);
    expect(data['remaining'], 1);
    await worker.close();
  });

  test('discovery-only mode advertises the batch but refuses to run it',
      () async {
    final worker = JsonlWorker(
        api: AuthoringReadApi(
            openService: opener,
            snapshotLoader: ProjectSnapshotLoader(handles: handles)),
        discoveryOnly: true);
    final description = jsonDecode(await worker.processLine(jsonEncode({
      'id': 'describe-rootless',
      'command': 'describe',
      'args': {},
    }))) as Map<String, dynamic>;
    expect(
        ((description['data'] as Map)['commands'] as List)
            .where((command) => command['id'] == 'pokemon_move_recipe_batch'),
        hasLength(1));
    final refused = jsonDecode(await worker.processLine(jsonEncode({
      'id': 'forbidden',
      'command': 'pokemon_move_recipe_batch',
      'args': {},
    }))) as Map<String, dynamic>;
    expect(refused['status'], 'failure');
    expect(transport.requests, isEmpty);
    await worker.close();
  });

  test(
      'closing the JSONL session waits for the active download and stops the batch',
      () async {
    final started = Completer<void>();
    final resume = Completer<void>();
    transport.onRequest = (uri) async {
      if (uri.path.endsWith('/tackle-recipe')) {
        started.complete();
        await resume.future;
      }
    };
    final reads = AuthoringReadApi(
        openService: opener,
        snapshotLoader: ProjectSnapshotLoader(handles: handles));
    final worker = JsonlWorker(
        api: reads,
        mutations: api,
        moveRecipeBatch: BattleMoveRecipeBatchService(
            openService: opener, authoring: api, client: transport));
    final pending = worker.processLine(jsonEncode({
      'id': 'close-batch',
      'command': 'pokemon_move_recipe_batch',
      'args': {
        'projectHandle': opened.projectHandle.value,
        'workspaceHandle': opened.workspaceHandle.value,
        'operationId': 'close-batch',
        'limit': 2,
      },
    }));
    await started.future;
    var closed = false;
    final closing = worker.close().then((_) => closed = true);
    await Future<void>.delayed(const Duration(milliseconds: 30));
    final waitedForDownload = !closed;
    resume.complete();
    final response = jsonDecode(await pending) as Map<String, dynamic>;
    await closing;
    expect(waitedForDownload, isTrue);
    expect((response['data'] as Map)['stopped'], 'cancelled');
    expect(
        await File('${root.path}/${battleRecipeBindingPath('tackle')}')
            .exists(),
        isFalse);
    expect(transport.requests, hasLength(3));
  });

  test('a failed progress observer does not duplicate the committed result',
      () async {
    final result = await importer.run(
        projectHandle: opened.projectHandle,
        workspaceHandle: opened.workspaceHandle,
        operationId: 'batch-progress',
        limit: 3,
        onProgress: (_) => throw StateError('observer closed'));
    expect(result.results, hasLength(1));
    expect(result.results.single.status, BattleMoveRecipeBatchStatus.imported);
    expect(result.nextIndex, 1);
    expect(result.remaining, 2);
    expect(result.stopped, 'progressError');
  });

  test('a crash during commit stops the batch and exposes recovery identity',
      () async {
    await api.detachWorkspace(opened.workspaceHandle);
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path], fileReader: reader);
    var crashed = false;
    api = LocalMapAuthoringMutationApi(
      policy: policy,
      snapshotLoader: ProjectSnapshotLoader(handles: handles),
      enablePokemonRecipeNetwork: true,
      faultInjector: (checkpoint) {
        if (!crashed &&
            checkpoint.checkpoint ==
                AuthoringTransactionCheckpoint.afterResourcePromoted) {
          crashed = true;
          throw const AuthoringTransactionSimulatedCrash();
        }
      },
    );
    await api.attachProject(
        projectRootPath: root.path,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle);
    importer = BattleMoveRecipeBatchImporter(
        openService: opener,
        authoring: api,
        media: AvelunePokemonMediaSource(client: transport, release: 'test'));
    final result = await importer.run(
        projectHandle: opened.projectHandle,
        workspaceHandle: opened.workspaceHandle,
        operationId: 'batch-crash',
        limit: 3);
    expect(result.results, hasLength(1));
    expect(result.results.single.reason, 'recoveryRequired');
    expect(result.results.single.operationId, isNotNull);
    expect(result.stopped, 'recoveryRequired');
    expect(result.remaining, 2);
    final requests = transport.requests.length;
    await expectLater(
        importer.run(
            projectHandle: opened.projectHandle,
            workspaceHandle: opened.workspaceHandle,
            operationId: 'batch-before-recovery',
            limit: 3),
        throwsA(isA<CatalogStorageException>().having(
            (error) => error.code, 'code', 'catalog.recovery_required')));
    expect(transport.requests, hasLength(requests));
    await api.recoverMutation(opened.projectHandle,
        operationId: result.results.single.operationId!);
    final retry = await importer.run(
        projectHandle: opened.projectHandle,
        workspaceHandle: opened.workspaceHandle,
        operationId: 'batch-recovered',
        limit: 3);
    expect(
        retry.results.first.status, BattleMoveRecipeBatchStatus.alreadyPresent);
    expect(retry.results[1].status, BattleMoveRecipeBatchStatus.imported);
  });
}
