import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  for (final jsonl in [false, true]) {
    test(
        '${jsonl ? 'JSONL' : 'API'} reads all Pokemon document families and orphans',
        () async {
      final f = await _Fixture.create();
      addTearDown(f.dispose);
      final page = await f.query(
          AuthoringQueryRequest(
            resourceKind: 'pokemonDocument',
            operation: AuthoringQueryOperation.list,
            pageSize: 2,
          ),
          jsonl);
      expect(page.totalAvailable, 6);
      final rows = [...page.items];
      var cursor = page.nextCursor;
      while (cursor != null) {
        final next = await f.query(
            AuthoringQueryRequest(
              resourceKind: 'pokemonDocument',
              operation: AuthoringQueryOperation.list,
              pageSize: 2,
              cursor: cursor,
            ),
            jsonl);
        rows.addAll(next.items);
        cursor = next.nextCursor;
      }
      expect(rows.map((row) => row['documentKind']).toSet(),
          {'catalog', 'species', 'media', 'learnset', 'evolution'});
      for (final row in rows) {
        final detail = await f.query(
            AuthoringQueryRequest(
              resourceKind: 'pokemonDocument',
              operation: AuthoringQueryOperation.get,
              view: AuthoringQueryView.detail,
              ids: [row['id'] as String],
            ),
            jsonl);
        expect(detail.items.single['id'], row['id']);
        expect(detail.items.single['revision'], row['revision']);
        final raw = jsonDecode(
            await File('${f.root.path}/${row['relativePath']}')
                .readAsString()) as Map<String, dynamic>;
        final kind =
            PokemonDocumentKind.values.byName(row['documentKind'] as String);
        final typed = PokemonJsonDocument.fromJson(kind, raw);
        expect(detail.items.single['document'], typed.toJson());
        expect(detail.items.single['documentId'], typed.identity);
        expect((detail.items.single['mutationResourceRef'] as Map)['id'],
            '${kind.name}:${typed.identity}');
      }
      expect(
          (await f.query(
                  AuthoringQueryRequest(
                    resourceKind: 'pokemonDocument',
                    operation: AuthoringQueryOperation.list,
                    filters: const {'documentKind': 'learnset'},
                  ),
                  jsonl))
              .items
              .single['relativePath'],
          'data/pokemon/learnsets/orphan-file.json');
      await expectLater(
          f.query(
              AuthoringQueryRequest(
                resourceKind: 'pokemonDocument',
                operation: AuthoringQueryOperation.get,
                ids: const ['species:../../outside.json'],
              ),
              jsonl),
          throwsA(anything));
      final first = await f.query(
          AuthoringQueryRequest(
            resourceKind: 'pokemonDocument',
            operation: AuthoringQueryOperation.list,
            pageSize: 1,
          ),
          jsonl);
      await File('${f.root.path}/data/pokemon/evolutions/later.json')
          .writeAsString(jsonEncode(
              {'schemaVersion': 1, 'speciesId': 'later', 'evolutions': []}));
      await expectLater(
          f.query(
              AuthoringQueryRequest(
                resourceKind: 'pokemonDocument',
                operation: AuthoringQueryOperation.list,
                pageSize: 1,
                cursor: first.nextCursor,
              ),
              jsonl),
          throwsA(anything));
      expect(
          (await f.query(
                  AuthoringQueryRequest(
                    resourceKind: 'pokemonDocument',
                    operation: AuthoringQueryOperation.list,
                  ),
                  jsonl))
              .totalAvailable,
          7);
    });
  }

  test(
      'summary and metadata masks do not decode unselected malformed or large documents',
      () async {
    final f = await _Fixture.create();
    addTearDown(f.dispose);
    final invalid = File('${f.root.path}/data/pokemon/species/invalid.json');
    await invalid.writeAsString('{invalid ${'x' * (1024 * 1024)}');
    final rows = await f.query(
        AuthoringQueryRequest(
          resourceKind: 'pokemonDocument',
          operation: AuthoringQueryOperation.list,
          filters: const {'documentKind': 'species'},
        ),
        false);
    expect(rows.totalAvailable, 2);
    final masked = await f.query(
        AuthoringQueryRequest(
          resourceKind: 'pokemonDocument',
          operation: AuthoringQueryOperation.list,
          view: AuthoringQueryView.detail,
          fieldMask: const ['id', 'revision'],
          filters: const {'documentKind': 'species'},
        ),
        false);
    expect(
        masked.items
            .every((row) => row.length == 4 && !row.containsKey('document')),
        isTrue);
    final selected = await f.query(
        AuthoringQueryRequest(
          resourceKind: 'pokemonDocument',
          operation: AuthoringQueryOperation.get,
          view: AuthoringQueryView.detail,
          ids: const ['learnset:data/pokemon/learnsets/orphan-file.json'],
          fieldMask: const ['documentId', 'document.speciesId'],
        ),
        false);
    expect(selected.items.single['documentId'], 'orphan-id');
    expect(selected.items.single['document'], {'speciesId': 'orphan-id'});
  });
  test(
      'only selected detail payloads are captured and deferred snapshots remain offloaded',
      () async {
    final f = await _Fixture.create();
    addTearDown(f.dispose);
    final snapshot = await f.loader
        .load(f.opened.projectHandle, deferPokemonDocuments: true);
    expect(snapshot.storedResources.length, greaterThanOrEqualTo(6));
    expect(
        snapshot.inlineResourceBytes.keys
            .any((key) => key.startsWith('pokemon')),
        isFalse);
    final captures = <String>[];
    final projected = ProjectSnapshot(
        projectHandle: snapshot.projectHandle,
        revision: snapshot.revision,
        manifest: snapshot.manifest,
        maps: snapshot.maps,
        resourceFingerprints: snapshot.resourceFingerprints,
        resourceStorageKeys: snapshot.resourceStorageKeys,
        resourceBytes: snapshot.inlineResourceBytes,
        storedResources: snapshot.storedResources,
        resourcePayloadReader: (handle, key, descriptor, source) {
          captures.add(key);
          return snapshot.resourcePayloadReader!(
              handle, key, descriptor, source);
        });
    const service = ProjectQueryService();
    await service.queryPokemonDocuments(
        projected,
        AuthoringQueryRequest(
            resourceKind: 'pokemonDocument',
            operation: AuthoringQueryOperation.list,
            pageSize: 1));
    expect(captures, isEmpty);
    final detail = await service.queryPokemonDocuments(
        projected,
        AuthoringQueryRequest(
            resourceKind: 'pokemonDocument',
            operation: AuthoringQueryOperation.list,
            view: AuthoringQueryView.detail,
            filters: const {'documentKind': 'learnset'},
            pageSize: 1));
    expect(detail.items.single['documentId'], 'orphan-id');
    expect(captures, ['data/pokemon/learnsets/orphan-file.json']);
  });

  test(
      'selected invalid and oversized documents fail explicitly while metadata remains readable',
      () async {
    final f = await _Fixture.create();
    addTearDown(f.dispose);
    final path = File('${f.root.path}/data/pokemon/species/oversized.json');
    await path.writeAsString('x' * (8 * 1024 * 1024 + 1));
    expect(
        (await f.query(
                AuthoringQueryRequest(
                    resourceKind: 'pokemonDocument',
                    operation: AuthoringQueryOperation.get,
                    ids: const ['species:data/pokemon/species/oversized.json']),
                false))
            .items
            .single['byteLength'],
        8388609);
    await expectLater(
        f.query(
            AuthoringQueryRequest(
                resourceKind: 'pokemonDocument',
                operation: AuthoringQueryOperation.get,
                view: AuthoringQueryView.detail,
                ids: const ['species:data/pokemon/species/oversized.json']),
            false),
        throwsA(predicate((error) =>
            error.toString().contains('query.pokemon_document_too_large'))));
    await path.writeAsString('secret-invalid-json');
    await expectLater(
        f.query(
            AuthoringQueryRequest(
                resourceKind: 'pokemonDocument',
                operation: AuthoringQueryOperation.get,
                view: AuthoringQueryView.detail,
                ids: const ['species:data/pokemon/species/oversized.json']),
            false),
        throwsA(predicate((error) =>
            error.toString().contains('query.pokemon_document_invalid') &&
            !error.toString().contains('secret-invalid-json'))));
  });

  test(
      'content filters, content sorting and unsupported query actions are rejected',
      () async {
    final f = await _Fixture.create();
    addTearDown(f.dispose);
    for (final request in [
      AuthoringQueryRequest(
          resourceKind: 'pokemonDocument',
          operation: AuthoringQueryOperation.list,
          filters: const {'document.speciesId': 'orphan-id'}),
      AuthoringQueryRequest(
          resourceKind: 'pokemonDocument',
          operation: AuthoringQueryOperation.list,
          sort: const [AuthoringQuerySort(field: 'documentId')]),
      AuthoringQueryRequest(
          resourceKind: 'pokemonDocument',
          operation: AuthoringQueryOperation.list,
          extensions: const {'actionId': 'scene.simulate'}),
    ]) {
      await expectLater(f.query(request, false), throwsA(anything));
    }
    final search = await f.query(
        AuthoringQueryRequest(
            resourceKind: 'pokemonDocument',
            operation: AuthoringQueryOperation.search,
            searchTerm: 'orphan',
            sort: const [
              AuthoringQuerySort(field: 'relativePath', descending: true)
            ]),
        false);
    expect(search.totalAvailable, 2);
    expect(search.items.first['documentKind'], 'learnset');
    final batch = await f.query(
        AuthoringQueryRequest(
            resourceKind: 'pokemonDocument',
            operation: AuthoringQueryOperation.batchGet,
            ids: const ['media:data/pokemon/media/visible.json', 'unknown']),
        false);
    expect(batch.items.single['documentKind'], 'media');
  });

  test(
      'selected payload refuses stale bytes and a directory outside the authorized project',
      () async {
    final f = await _Fixture.create();
    addTearDown(f.dispose);
    final snapshot = await f.loader
        .load(f.opened.projectHandle, deferPokemonDocuments: true);
    final file = File('${f.root.path}/data/pokemon/learnsets/orphan-file.json');
    await file.writeAsString(
        jsonEncode({'schemaVersion': 1, 'speciesId': 'concurrent'}));
    await expectLater(
        const ProjectQueryService().queryPokemonDocuments(
            snapshot,
            AuthoringQueryRequest(
                resourceKind: 'pokemonDocument',
                operation: AuthoringQueryOperation.get,
                view: AuthoringQueryView.detail,
                ids: const [
                  'learnset:data/pokemon/learnsets/orphan-file.json'
                ])),
        throwsA(anything));
    final outside = await Directory.systemTemp.createTemp('pokemon-outside-');
    addTearDown(() => outside.delete(recursive: true));
    await File('${outside.path}/secret.json').writeAsString('private-outside');
    final evolutionDirectory =
        Directory('${f.root.path}/data/pokemon/evolutions');
    await evolutionDirectory.delete(recursive: true);
    await Link(evolutionDirectory.path).create(outside.path);
    await expectLater(
        f.query(
            AuthoringQueryRequest(
                resourceKind: 'pokemonDocument',
                operation: AuthoringQueryOperation.list),
            false),
        throwsA(predicate((error) =>
            error.toString().contains('outside_project') &&
            !error.toString().contains('private-outside'))));
  });

  test(
      'readers without streaming fail explicitly before materializing Pokemon documents',
      () async {
    final reader = _NonStreamingReader();
    final f = await _Fixture.create(reader: reader);
    addTearDown(f.dispose);
    reader.paths.clear();
    await expectLater(
        f.query(
            AuthoringQueryRequest(
                resourceKind: 'pokemonDocument',
                operation: AuthoringQueryOperation.list),
            false),
        throwsA(predicate((error) =>
            error.toString().contains('project.pokemon_stream_unavailable'))));
    expect(
        reader.paths.any((path) => path.startsWith('data/pokemon/')), isFalse);
  });

  test(
      'disabled projects expose no Pokemon documents and retain the strict planning revision',
      () async {
    final f = await _Fixture.create();
    addTearDown(f.dispose);
    final manifestFile = File('${f.root.path}/project.json');
    final manifest =
        jsonDecode(await manifestFile.readAsString()) as Map<String, dynamic>;
    (manifest['pokemon'] as Map)['enabled'] = false;
    await manifestFile.writeAsString(jsonEncode(manifest));
    await File('${f.root.path}/data/pokemon/species/visible.json')
        .writeAsString('disabled invalid source');
    final page = await f.query(
        AuthoringQueryRequest(
            resourceKind: 'pokemonDocument',
            operation: AuthoringQueryOperation.list,
            view: AuthoringQueryView.detail),
        false);
    expect(page.items, isEmpty);
    expect(page.snapshotRevision,
        (await f.loader.load(f.opened.projectHandle)).revision);
  });

  test('detail page source budget is checked before any payload capture',
      () async {
    final f = await _Fixture.create();
    addTearDown(f.dispose);
    final snapshot = await f.loader
        .load(f.opened.projectHandle, deferPokemonDocuments: true);
    var captures = 0;
    final projected = ProjectSnapshot(
        projectHandle: snapshot.projectHandle,
        revision: snapshot.revision,
        manifest: snapshot.manifest,
        maps: snapshot.maps,
        resourceFingerprints: snapshot.resourceFingerprints,
        resourceStorageKeys: snapshot.resourceStorageKeys,
        resourceBytes: snapshot.inlineResourceBytes,
        storedResources: {
          for (final entry in snapshot.storedResources.entries)
            entry.key: ProjectStoredResource(
                byteLength: 3 * 1024 * 1024,
                rawSha256: entry.value.rawSha256,
                resourceRevision: entry.value.resourceRevision,
                contentDigest: entry.value.contentDigest)
        },
        resourcePayloadReader: (handle, key, descriptor, source) {
          captures++;
          throw StateError('Budget must reject before capture');
        });
    await expectLater(
        const ProjectQueryService().queryPokemonDocuments(
            projected,
            AuthoringQueryRequest(
                resourceKind: 'pokemonDocument',
                operation: AuthoringQueryOperation.list,
                view: AuthoringQueryView.detail)),
        throwsA(predicate((error) => error
            .toString()
            .contains('query.pokemon_document_page_too_large'))));
    expect(captures, 0);
  });

  test(
      'response byte budget rejects expanded results and a selected field mask remains usable',
      () async {
    final f = await _Fixture.create();
    addTearDown(f.dispose);
    final file = File('${f.root.path}/data/pokemon/species/large.json');
    await file.writeAsString(jsonEncode({
      'schemaVersion': 1,
      'id': 'large',
      'names': {'en': 'x' * (7 * 1024 * 1024)}
    }));
    final masked = await f.query(
        AuthoringQueryRequest(
            resourceKind: 'pokemonDocument',
            operation: AuthoringQueryOperation.get,
            view: AuthoringQueryView.detail,
            ids: const ['species:data/pokemon/species/large.json'],
            fieldMask: const ['documentId']),
        false);
    expect(masked.items.single['documentId'], 'large');
    await expectLater(
        f.query(
            AuthoringQueryRequest(
                resourceKind: 'pokemonDocument',
                operation: AuthoringQueryOperation.get,
                view: AuthoringQueryView.detail,
                ids: const ['species:data/pokemon/species/large.json']),
            false),
        throwsA(predicate((error) => error
            .toString()
            .contains('query.pokemon_document_page_too_large'))));
  });
  test(
      'query revision and exact preimage drive canonical write then requery without changing other documents',
      () async {
    final f = await _Fixture.create();
    addTearDown(f.dispose);
    final mutationApi = LocalMapAuthoringMutationApi(
        policy: f.policy, snapshotLoader: f.loader);
    addTearDown(() => mutationApi.detachWorkspace(f.opened.workspaceHandle));
    await mutationApi.attachProject(
        projectRootPath: f.root.path,
        workspaceHandle: f.opened.workspaceHandle,
        projectHandle: f.opened.projectHandle);
    const relativePath = 'data/pokemon/learnsets/orphan-file.json';
    final source = File('${f.root.path}/$relativePath');
    await source
        .writeAsString('  {"schemaVersion":1,"speciesId":"orphan-id"}\n\n');
    final others = <String, List<int>>{};
    await for (final entity in f.root.list(recursive: true)) {
      if (entity is File &&
          entity.path.endsWith('.json') &&
          entity.path != source.path &&
          !entity.path.contains('/.pokemap/')) {
        others[entity.path] = await entity.readAsBytes();
      }
    }
    final page = await f.query(
        AuthoringQueryRequest(
            resourceKind: 'pokemonDocument',
            operation: AuthoringQueryOperation.get,
            view: AuthoringQueryView.detail,
            ids: const ['learnset:$relativePath']),
        false);
    final detail = page.items.single;
    expect(base64Decode(detail['beforeBytesBase64'] as String),
        await source.readAsBytes());
    final ref = AuthoringResourceRef.fromJson(
        Map<String, dynamic>.from(detail['mutationResourceRef'] as Map));
    final planned = await mutationApi.planMutation(
        f.opened.projectHandle,
        AuthoringRequest(
            requestId: 'pokemon-query-write',
            actionId: 'pokemon.learnset.write',
            actionVersion: 1,
            workspaceHandle: f.opened.workspaceHandle.value,
            expectedRevision: page.snapshotRevision,
            idempotencyKey: 'pokemon-query-write',
            parameters: {
              'relativePath': relativePath,
              'beforeBytesBase64': detail['beforeBytesBase64'],
              'document': {
                ...Map<String, Object?>.from(detail['document'] as Map),
                'startingMoves': ['tackle']
              },
            }));
    expect(
        planned.plan.changeSet.changes.single.resource.toJson(), ref.toJson());
    final confirmed = await mutationApi.confirmMutation(f.opened.projectHandle,
        planId: planned.planId);
    await mutationApi.applyMutation(f.opened.projectHandle,
        planId: planned.planId,
        operationId: 'pokemon-query-write-operation',
        confirmationToken: confirmed.confirmationToken);
    final after = await f.query(
        AuthoringQueryRequest(
            resourceKind: 'pokemonDocument',
            operation: AuthoringQueryOperation.get,
            view: AuthoringQueryView.detail,
            ids: const ['learnset:$relativePath']),
        true);
    expect(after.items.single['documentId'], 'orphan-id');
    expect(
        (after.items.single['document'] as Map)['startingMoves'], ['tackle']);
    expect(after.items.single['revision'], isNot(detail['revision']));
    for (final entry in others.entries) {
      expect(await File(entry.key).readAsBytes(), entry.value,
          reason: entry.key);
    }
    await expectLater(
        mutationApi.planMutation(
            f.opened.projectHandle,
            AuthoringRequest(
                requestId: 'pokemon-query-stale',
                actionId: 'pokemon.learnset.write',
                actionVersion: 1,
                workspaceHandle: f.opened.workspaceHandle.value,
                expectedRevision: page.snapshotRevision,
                idempotencyKey: 'pokemon-query-stale',
                parameters: {
                  'relativePath': relativePath,
                  'beforeBytesBase64': detail['beforeBytesBase64'],
                  'document': detail['document'],
                })),
        throwsA(predicate((error) => error.toString().contains('plan.stale'))));
  });
}

class _Fixture {
  _Fixture(
      this.root, this.api, this.opened, this.worker, this.loader, this.policy);
  final ProjectSnapshotLoader loader;
  final WorkspacePolicy policy;
  final Directory root;
  final AuthoringReadApi api;
  final OpenedProject opened;
  final JsonlWorker worker;

  static Future<_Fixture> create(
      {ProjectFileReader reader = const LocalProjectFileReader()}) async {
    final root = await Directory.systemTemp.createTemp('pokemon-query-');
    final manifest = const ProjectManifest(
        name: 'Pokemon reads',
        maps: [],
        tilesets: [],
        pokemon: ProjectPokemonConfig(
            enabled: true, ruleset: PokemonRulesetProfile.pokeMapBetaV1));
    final files = <String, Object?>{
      'project.json': manifest.toJson(),
      'data/pokemon/catalogs/items.json': {'schemaVersion': 1, 'entries': []},
      'data/pokemon/catalogs/moves.json': {
        'schemaVersion': 1,
        'catalog': 'moves',
        'entries': []
      },
      'data/pokemon/species/visible.json': {
        'schemaVersion': 1,
        'id': 'visible'
      },
      'data/pokemon/media/visible.json': {
        'schemaVersion': 1,
        'speciesId': 'visible',
        'variants': {}
      },
      'data/pokemon/learnsets/orphan-file.json': {
        'schemaVersion': 1,
        'speciesId': 'orphan-id'
      },
      'data/pokemon/evolutions/another-orphan.json': {
        'schemaVersion': 1,
        'speciesId': 'another-id',
        'evolutions': []
      },
    };
    for (final entry in files.entries) {
      final file = File('${root.path}/${entry.key}');
      await file.parent.create(recursive: true);
      await file.writeAsString(jsonEncode(entry.value));
    }
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path], fileReader: reader);
    final handles = WorkspaceHandleStore();
    final loader = ProjectSnapshotLoader(
        handles: handles, snapshotCache: ProjectSnapshotCache());
    final api = AuthoringReadApi(
        openService: ProjectOpenService(
            policy: policy, fileReader: reader, handles: handles),
        snapshotLoader: loader);
    final opened = await api.openProject(root.path);
    return _Fixture(root, api, opened, JsonlWorker(api: api), loader, policy);
  }

  Future<AuthoringQueryPage> query(
      AuthoringQueryRequest request, bool jsonl) async {
    if (!jsonl) return api.queryProject(opened.projectHandle, request);
    final result = AuthoringResult.fromJson(
        jsonDecode(await worker.processLine(jsonEncode({
      'id': 'pokemon-query',
      'command': 'query',
      'args': {
        'projectHandle': opened.projectHandle.value,
        'request': request.toJson()
      },
    }))) as Map<String, dynamic>);
    if (result.status != AuthoringResultStatus.success) {
      throw StateError(jsonEncode(result.toJson()));
    }
    return AuthoringQueryPage.fromJson(Map<String, dynamic>.from(result.data));
  }

  Future<void> dispose() async {
    await api.closeWorkspace(opened.workspaceHandle);
    await root.delete(recursive: true);
  }
}

class _NonStreamingReader implements ProjectFileReader, ProjectDirectoryReader {
  final paths = <String>[];
  final delegate = const LocalProjectFileReader();

  @override
  Future<String> canonicalizeDirectory(String path) =>
      delegate.canonicalizeDirectory(path);

  @override
  Future<List<int>> readBytes(
      {required String projectRoot, required String relativePath}) {
    paths.add(relativePath);
    return delegate.readBytes(
        projectRoot: projectRoot, relativePath: relativePath);
  }

  @override
  Future<List<String>> listFiles(
          {required String projectRoot, required String relativeDirectory}) =>
      delegate.listFiles(
          projectRoot: projectRoot, relativeDirectory: relativeDirectory);
}
