import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../../../map_distribution/test/support/spatial_feature_capabilities_fixture.dart';

void main() {
  test('imports, undoes, redoes and exports one verified source', () async {
    final root = await Directory.systemTemp.createTemp('gen5-import-');
    final handles = WorkspaceHandleStore();
    LocalMapAuthoringMutationApi? service;
    OpenedProject? opened;
    addTearDown(() async {
      if (service != null && opened != null) {
        await service!.detachWorkspace(opened!.workspaceHandle);
        handles.closeWorkspace(opened!.workspaceHandle);
      }
      if (await root.exists()) await root.delete(recursive: true);
    });
    final files = spatialFeaturePayload('companion');
    final project = ProjectManifest.fromJson(
      jsonDecode(utf8.decode(files['project/project.json']!))
          as Map<String, dynamic>,
    );
    final storage = await CatalogStorageStore.open(projectRoot: root.path);
    final working = await WorkingProjectCatalog.create(
      store: storage,
      projectId: 'gen5-import',
      project: project,
    );
    await working.close();
    for (final entry in files.entries) {
      if (entry.key == 'project/project.json') continue;
      final file =
          File('${root.path}/${entry.key.substring('project/'.length)}');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(entry.value);
    }
    await File('${root.path}/${project.pokemon.catalogFiles['items']}')
        .writeAsString(
      jsonEncode(encodeProjectItemCatalog(
          const ProjectItemCatalog(schemaVersion: 1, entries: []))),
    );
    const speciesPath = 'data/pokemon/species/bronze-bird.json';
    final speciesFile = File('${root.path}/$speciesPath');
    final originalSpecies = await speciesFile.readAsBytes();
    final unrelated = File('${root.path}/data/pokemon/species/unrelated.json');
    await unrelated.writeAsString('{malformed');
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: [root.path],
      fileReader: reader,
    );
    final opener = ProjectOpenService(
        policy: policy,
        fileReader: reader,
        handles: handles,
        catalogMetadataFields: {});
    final current = await opener.openProject(root.path);
    opened = current;
    final snapshots = ProjectSnapshotLoader(handles: handles);
    final api =
        LocalMapAuthoringMutationApi(policy: policy, snapshotLoader: snapshots);
    service = api;
    await api.attachProject(
        projectRootPath: root.path,
        workspaceHandle: current.workspaceHandle,
        projectHandle: current.projectHandle);
    final bundle = Gen5BattleSourceBundle(
      species: 'syntheticmon',
      nationalDex: 1,
      release: 'synthetic-release',
      sourceRepository: 'fuddlesworth/pokebw2',
      sourceRevision: 'a' * 40,
      sourceDirectory: 'res/pokemon/syntheticmon',
      reconstruction: 'a\u0300 verifier',
      redistributionStatus: 'unverified',
      assets: {
        for (var i = 0; i < gen5BattleBundleAssetNames.length; i++)
          gen5BattleBundleAssetNames[i]: Uint8List.fromList([i + 1]),
      },
    );
    final binding = Gen5BattleSourceBinding.fromBundle(
      projectSpeciesId: 'clockbird',
      projectNationalDex: 1,
      bundle: bundle,
    );
    final staged = await api.artifacts
        .put(bundle.encode(), declaredMediaType: 'application/json');
    final parameters = <String, Object?>{
      'binding': jsonDecode(utf8.decode(binding.encode())),
      'bundleHandle': staged.reference.handle,
      'speciesPath': speciesPath,
    };
    AveluneGen5BattleSourceImport importer({bool unavailable = false}) =>
        AveluneGen5BattleSourceImport(
          source: AveluneGen5BattleSource(
            client: _SourceTransport(bundle, unavailable: unavailable),
            release: 'synthetic-release',
          ),
          authoring: api,
          projectHandle: current.projectHandle,
          workspaceHandle: current.workspaceHandle,
        );
    final missing = await importer(unavailable: true).import(
      sourceSpecies: 'syntheticmon',
      projectSpeciesId: 'clockbird',
      nationalDex: 1,
      speciesPath: speciesPath,
      operationId: 'missing',
    );
    expect(missing.status, AveluneGen5ImportStatus.unavailable);
    var checks = 0;
    await expectLater(
        importer().import(
          sourceSpecies: 'syntheticmon',
          projectSpeciesId: 'clockbird',
          nationalDex: 1,
          speciesPath: speciesPath,
          operationId: 'cancelled',
          isCurrent: () => ++checks < 3,
        ),
        throwsStateError);
    expect(api.artifacts.list(), hasLength(1));
    checks = 0;
    await expectLater(
        importer().import(
          sourceSpecies: 'syntheticmon',
          projectSpeciesId: 'clockbird',
          nationalDex: 1,
          speciesPath: speciesPath,
          operationId: 'cancel-at-apply',
          isCurrent: () => ++checks < 6,
        ),
        throwsStateError);
    expect(await File('${root.path}/${binding.bindingPath}').exists(), isFalse);
    expect(await File('${root.path}/${binding.bundlePath}').exists(), isFalse);
    expect(api.artifacts.list(), hasLength(1));
    Future<AuthoringMutationPlanResult> plan(String operation) async {
      final snapshot = await api.readWorkshopSnapshot(current.projectHandle,
          actionId: 'pokemon.gen5_battle_source.import',
          parameters: parameters);
      return api.planMutation(
          current.projectHandle,
          AuthoringRequest(
            requestId: operation,
            actionId: 'pokemon.gen5_battle_source.import',
            actionVersion: 1,
            workspaceHandle: current.workspaceHandle.value,
            expectedRevision: snapshot.revision,
            idempotencyKey: operation,
            parameters: parameters,
            extensions: const {'workshopScope': true},
          ));
    }

    final initial = await plan('import');
    final applied = await api.applyMutation(current.projectHandle,
        planId: initial.planId, operationId: 'import');
    final bindingFile = File('${root.path}/${binding.bindingPath}');
    final bundleFile = File('${root.path}/${binding.bundlePath}');
    expect(await bindingFile.readAsBytes(), binding.encode());
    expect(await bundleFile.readAsBytes(), bundle.encode());
    expect(await speciesFile.readAsBytes(), originalSpecies);
    await api.undoMutation(current.projectHandle,
        entryId: applied.receipt.receiptId, idempotencyKey: 'undo');
    expect(await bindingFile.exists(), isFalse);
    expect(await bundleFile.exists(), isFalse);
    final stale = await plan('stale');
    final changedSpecies =
        jsonDecode(utf8.decode(originalSpecies)) as Map<String, dynamic>;
    changedSpecies['nationalDex'] = 2;
    await speciesFile.writeAsString(jsonEncode(changedSpecies));
    await expectLater(
      api.applyMutation(current.projectHandle,
          planId: stale.planId, operationId: 'stale'),
      throwsA(isA<CatalogStorageException>().having(
          (error) => error.code, 'code', 'catalog.project_revision_conflict')),
    );
    expect(await bindingFile.exists(), isFalse);
    expect(await bundleFile.exists(), isFalse);
    await speciesFile.writeAsBytes(originalSpecies);
    await api.redoMutation(current.projectHandle,
        entryId: applied.receipt.receiptId, idempotencyKey: 'redo');
    expect(await bindingFile.readAsBytes(), binding.encode());
    expect(await bundleFile.readAsBytes(), bundle.encode());
    expect((await plan('retry')).applicable, isFalse);
    await api.undoMutation(current.projectHandle,
        entryId: applied.receipt.receiptId, idempotencyKey: 'undo-again');
    final imported = await importer().import(
      sourceSpecies: 'syntheticmon',
      projectSpeciesId: 'clockbird',
      nationalDex: 1,
      speciesPath: speciesPath,
      operationId: 'api-import',
    );
    expect(imported.status, AveluneGen5ImportStatus.imported);
    expect(imported.receiptId, isNotNull);
    expect(await bindingFile.readAsBytes(), binding.encode());
    expect(await bundleFile.readAsBytes(), bundle.encode());
    expect(api.artifacts.list(), hasLength(1));
    final repeated = await importer().import(
      sourceSpecies: 'syntheticmon',
      projectSpeciesId: 'clockbird',
      nationalDex: 1,
      speciesPath: speciesPath,
      operationId: 'api-repeat',
    );
    expect(repeated.status, AveluneGen5ImportStatus.alreadyPresent);
    await api.undoMutation(current.projectHandle,
        entryId: imported.receiptId!, idempotencyKey: 'undo-api-import');
    final wire = JsonlWorker(
      api: AuthoringReadApi(openService: opener, snapshotLoader: snapshots),
      mutations: api,
    );
    final wireSnapshot = await api.readWorkshopSnapshot(current.projectHandle,
        actionId: 'pokemon.gen5_battle_source.import', parameters: parameters);
    Future<Map<String, Object?>> call(
        String command, Map<String, Object?> args) async {
      final line = await wire.processLine(
          jsonEncode({'id': command, 'command': command, 'args': args}));
      final result =
          AuthoringResult.fromJson(jsonDecode(line) as Map<String, dynamic>);
      expect(result.status, AuthoringResultStatus.success, reason: line);
      return result.data;
    }

    final wirePlan = await call('plan', {
      'projectHandle': current.projectHandle.value,
      'request': AuthoringRequest(
        requestId: 'wire-import',
        actionId: 'pokemon.gen5_battle_source.import',
        actionVersion: 1,
        workspaceHandle: current.workspaceHandle.value,
        expectedRevision: wireSnapshot.revision,
        idempotencyKey: 'wire-import',
        parameters: parameters,
        extensions: const {'workshopScope': true},
      ).toJson(),
    });
    await call('apply', {
      'projectHandle': current.projectHandle.value,
      'planId': wirePlan['planId'],
      'operationId': 'wire-import',
    });
    await wire.close();
    expect(await bindingFile.readAsBytes(), binding.encode());
    expect(await bundleFile.readAsBytes(), bundle.encode());
    await api.detachWorkspace(current.workspaceHandle);
    handles.closeWorkspace(current.workspaceHandle);
    final reopened = await opener.openProject(root.path);
    opened = reopened;
    final reopenedApi = LocalMapAuthoringMutationApi(
      policy: policy,
      snapshotLoader: ProjectSnapshotLoader(handles: handles),
    );
    service = reopenedApi;
    await reopenedApi.attachProject(
        projectRootPath: root.path,
        workspaceHandle: reopened.workspaceHandle,
        projectHandle: reopened.projectHandle);
    final reread = await reopenedApi.readWorkshopSnapshot(
        reopened.projectHandle,
        actionId: 'pokemon.gen5_battle_source.import',
        parameters: parameters);
    expect(reread.findResourceBytes('gen5BattleSource:${binding.bindingPath}'),
        binding.encode());
    expect(reread.findResourceBytes('gen5BattleSource:${binding.bundlePath}'),
        bundle.encode());
    await unrelated.delete();
    final exported = await const CanonicalGamePackageExportService().build(
      projectRoot: root,
      mode: GamePackageExportMode.localTest,
      profile: GamePackageExportProfile(
          gameId: 'games.example.gen5',
          gameVersion: '0.1.0',
          title: 'Synthetic',
          authorName: 'Example',
          defaultLocale: 'fr',
          supportedLocales: ['fr']),
    );
    final archive =
        ZipDecoder().decodeBytes(exported.packageBytes, verify: true);
    expect(archive.findFile('project/${binding.bindingPath}')!.content,
        binding.encode());
    expect(archive.findFile('project/${binding.bundlePath}')!.content,
        bundle.encode());
  });
}

final class _SourceTransport implements PokemonBoundedExternalHttpTransport {
  _SourceTransport(this.bundle, {this.unavailable = false});

  final Gen5BattleSourceBundle bundle;
  final bool unavailable;

  @override
  Future<PokemonExternalHttpResponse> getBounded(Uri uri,
      {required Map<String, String> headers,
      required int maximumBytes,
      required Duration timeout}) async {
    final document =
        jsonDecode(utf8.decode(bundle.encode())) as Map<String, dynamic>
          ..remove('kind')
          ..remove('schemaVersion')
          ..['format'] = 'gen5-battle-source-v1';
    final body = jsonEncode(document);
    return PokemonExternalHttpResponse(
      statusCode: unavailable ? 404 : 200,
      headers: {'x-source-revision': bundle.sourceRevision},
      body: body,
      bodyBytes: Uint8List.fromList(utf8.encode(body)),
    );
  }
}
