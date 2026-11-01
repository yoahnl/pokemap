import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as img;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:test/test.dart';

import '../../../map_distribution/test/support/spatial_feature_capabilities_fixture.dart';

final class _CountingReader
    implements
        ProjectFileReader,
        ProjectResourceStreamReader,
        ProjectResourceProbeReader {
  final paths = <String>[];
  final delegate = const LocalProjectFileReader();
  @override
  bool get supportsStreamingResources => true;
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
  Stream<List<int>> openRead(
      {required String projectRoot, required String relativePath}) {
    paths.add(relativePath);
    return delegate.openRead(
        projectRoot: projectRoot, relativePath: relativePath);
  }

  @override
  Future<ProjectResourceProbe> probeResource(
          {required String projectRoot, required String relativePath}) =>
      delegate.probeResource(
          projectRoot: projectRoot, relativePath: relativePath);
}

final class _RecipeApi implements PokemonBoundedExternalHttpTransport {
  _RecipeApi(this.recipe, this.particle, this.png);
  final List<int> recipe, particle, png;
  @override
  Future<PokemonExternalHttpResponse> getBounded(Uri uri,
      {required Map<String, String> headers,
      required int maximumBytes,
      required Duration timeout}) async {
    Map<String, Object> item(String id, List<int> bytes, String type,
            String representation, Map<String, Object> metadata) =>
        {
          'id': id,
          'sha256': sha256.convert(bytes).toString(),
          'contentType': type,
          'usage': 'battle',
          'representation': representation,
          'style': 'synthetic',
          'metadata': metadata
        };
    final owner = uri.path.endsWith('/owners/move/catalog');
    final data = owner
        ? utf8.encode(jsonEncode([
            item('recipe', recipe, 'application/vnd.avelune.battle-recipe+json',
                'recipe', {
              'recipeId': 'visual',
              'revision': '1',
              'moveSourceId': 'source',
              'variant': 'default',
              'bindings': {'tex': 'texture', 'particle': 'particle'},
            }),
            item('texture', png, 'image/png', 'sprite2d', {}),
            item('particle', particle, 'application/vnd.avelune.particle+json',
                'particle', {}),
          ]))
        : uri.path.endsWith('/recipe')
            ? recipe
            : uri.path.endsWith('/particle')
                ? particle
                : png;
    return PokemonExternalHttpResponse(
        statusCode: 200,
        headers: const {},
        body: owner ? utf8.decode(data) : '',
        bodyBytes: Uint8List.fromList(data));
  }
}

void main() {
  test('imports separate move-owned recipes and undo preserves the other move',
      () async {
    final root = await Directory.systemTemp.createTemp('battle-recipe-import-');
    final handles = WorkspaceHandleStore();
    LocalMapAuthoringMutationApi? api;
    OpenedProject? opened;
    addTearDown(() async {
      final currentApi = api;
      final currentProject = opened;
      if (currentProject != null && currentApi != null) {
        await currentApi.detachWorkspace(currentProject.workspaceHandle);
        handles.closeWorkspace(currentProject.workspaceHandle);
      }
      if (await root.exists()) await root.delete(recursive: true);
    });
    final fixture = spatialFeaturePayload('companion');
    final base = ProjectManifest.fromJson(
        jsonDecode(utf8.decode(fixture['project/project.json']!)));
    final map = MapData.fromJson(
        jsonDecode(utf8.decode(fixture['project/maps/map.json']!)));
    final project = base.copyWith(
      maps: [
        ...base.maps,
        for (var i = 0; i < 40; i++)
          ProjectMapEntry(
              id: 'foreign-$i',
              name: 'Foreign',
              relativePath: 'maps/foreign-$i.json')
      ],
    );
    final storage = await CatalogStorageStore.open(projectRoot: root.path);
    await WorkingProjectCatalog.create(
        store: storage, projectId: 'test', project: project);
    for (final entry in fixture.entries) {
      if (entry.key == 'project/project.json') continue;
      final file =
          File('${root.path}/${entry.key.substring('project/'.length)}');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(entry.value);
    }
    await File('${root.path}/${project.pokemon.catalogFiles['items']}')
        .writeAsString(jsonEncode(encodeProjectItemCatalog(
            const ProjectItemCatalog(schemaVersion: 1, entries: []))));
    final moves = File('${root.path}/${project.pokemon.catalogFiles['moves']}');
    await moves.parent.create(recursive: true);
    await moves.writeAsString(jsonEncode({
      'schemaVersion': 1,
      'catalog': 'moves',
      'entries': [
        for (final id in ['one', 'two'])
          PokemonMove(
            id: id,
            name: id,
            type: 'normal',
            category: PokemonMoveCategory.physical,
            accuracy: const PokemonMoveAccuracy.alwaysHits(),
          ).toJson(),
      ]
    }));
    for (var i = 0; i < 40; i++) {
      final file = File('${root.path}/maps/foreign-$i.json');
      await file.parent.create(recursive: true);
      await file.writeAsString(
          jsonEncode(map.copyWith(id: 'foreign-$i', name: 'Foreign').toJson()));
    }
    final reader = _CountingReader();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path], fileReader: reader);
    final opener = ProjectOpenService(
        policy: policy,
        fileReader: reader,
        handles: handles,
        catalogMetadataFields: {});
    final current = await opener.openProject(root.path);
    opened = current;
    final snapshots = ProjectSnapshotLoader(handles: handles);
    final service = LocalMapAuthoringMutationApi(
        policy: policy, snapshotLoader: snapshots, catalogFileReader: reader);
    api = service;
    await service.attachProject(
        projectRootPath: root.path,
        workspaceHandle: current.workspaceHandle,
        projectHandle: current.projectHandle);
    final png = img.encodePng(img.Image(width: 2, height: 2));
    final pngHash = sha256.convert(png).toString();
    final particle = utf8.encode(jsonEncode({
      'schemaVersion': 1,
      'emitters': [
        {
          'textureId': 'tex',
          'emissionDurationMs': 10,
          'emissionIntervalMs': 10,
          'particleLifetimeMs': 10,
          'particlesPerEmission': 1
        }
      ],
    }));
    final particleHash = sha256.convert(particle).toString();
    final recipe = utf8.encode(jsonEncode({
      'schemaVersion': 1,
      'recipeId': 'visual',
      'revision': '1',
      'moveSourceId': 'source',
      'variant': 'default',
      'requiredCapabilities': ['startParticle'],
      'provenance': {
        'source': 'synthetic',
        'sourceRevision': '1',
        'sourcePaths': [],
        'converter': 'test'
      },
      'resources': [
        {
          'id': 'tex',
          'role': 'texture',
          'mediaType': 'image/png',
          'sizeBytes': png.length,
          'sha256': pngHash
        },
        {
          'id': 'particle',
          'role': 'particleDefinition',
          'mediaType': 'application/vnd.avelune.particle+json',
          'sizeBytes': particle.length,
          'sha256': particleHash,
          'definitionVersion': 1,
          'dependencies': ['tex']
        },
      ],
      'program': {
        'kind': 'startParticle',
        'resourceId': 'particle',
        'from': 'userMouth',
        'to': 'targetImpact'
      },
    }));
    final digest = sha256.convert(recipe).toString();
    final fetched = await AveluneMoveRecipeSource(
      AvelunePokemonMediaSource(
          client: _RecipeApi(recipe, particle, png), release: 'test'),
    ).fetch(
        catalogMoveId: 'catalog',
        sourceMoveId: 'source',
        projectMoveId: 'one',
        mediaId: 'recipe',
        limits: const BattleRecipeBundleLimits(
            maxTextures: 2,
            maxTextureBytes: 10000,
            maxBundleBytes: 30000,
            maxDimension: 16,
            maxTexturePixels: 256,
            maxTotalPixels: 256),
        availableCapabilities:
            BattleMoveAnimationRecipe.recognizedCapabilities);
    final staged = await service.artifacts.put(fetched.bundle.recipeBytes);
    final stagedPng = await service.artifacts.put(fetched.bundle.media['tex']!);
    final stagedParticle =
        await service.artifacts.put(fetched.bundle.media['particle']!);
    Map<String, Object?> parametersFor(String id) {
      final binding = BattleMoveRecipeBinding.fromJson({
        'schemaVersion': 1,
        'projectMoveId': id,
        'sourceMoveId': 'source',
        'catalogReleaseId': 'test',
        'recipeId': 'visual',
        'variant': 'default',
        'revision': '1',
        'recipeSha256': digest,
      });
      return <String, Object?>{
        'projectBinding': BattleRecipeProjectBinding(
                binding: binding,
                catalogMoveId: 'catalog',
                recipeMediaId: 'recipe')
            .toJson(),
        'recipeHandle': staged.reference.handle,
        'resources': [
          {
            'id': 'tex',
            'sha256': pngHash,
            'mediaType': 'image/png',
            'artifactHandle': stagedPng.reference.handle
          },
          {
            'id': 'particle',
            'sha256': particleHash,
            'mediaType': 'application/vnd.avelune.particle+json',
            'artifactHandle': stagedParticle.reference.handle
          },
        ],
      };
    }

    Future<AuthoringMutationPlanResult> planFor(String id, String operation,
        {Map<String, Object?>? override}) async {
      final params = override ?? parametersFor(id);
      final snapshot = await service.readWorkshopSnapshot(current.projectHandle,
          actionId: 'pokemon.move_recipe.import', parameters: params);
      return service.planMutation(
          current.projectHandle,
          AuthoringRequest(
            requestId: operation,
            actionId: 'pokemon.move_recipe.import',
            actionVersion: 1,
            workspaceHandle: current.workspaceHandle.value,
            expectedRevision: snapshot.revision,
            idempotencyKey: operation,
            parameters: params,
            extensions: const {'workshopScope': true},
          ));
    }

    Future<AuthoringMutationResult> add(String id) async {
      final plan = await planFor(id, id);
      return service.applyMutation(current.projectHandle,
          planId: plan.planId, operationId: id);
    }

    reader.paths.clear();
    await add('one');
    expect(reader.paths.where((path) => path.startsWith('maps/foreign-')),
        isEmpty);
    expect(
        reader.paths.where((path) => path.endsWith('history.jsonl')), isEmpty);
    reader.paths.clear();
    final second = await add('two');
    expect(reader.paths.where((path) => path.startsWith('maps/foreign-')),
        isEmpty);
    expect(
        reader.paths.where((path) => path.endsWith('history.jsonl')), isEmpty);
    final one = File(
        '${root.path}/${battleRecipeBlobPath(digest, 'application/vnd.avelune.battle-recipe+json', projectMoveId: 'one')}');
    final two = File(
        '${root.path}/${battleRecipeBlobPath(digest, 'application/vnd.avelune.battle-recipe+json', projectMoveId: 'two')}');
    expect(await one.readAsBytes(), recipe);
    expect(await two.readAsBytes(), recipe);
    final particleOne = File(
        '${root.path}/${battleRecipeBlobPath(particleHash, 'application/vnd.avelune.particle+json', projectMoveId: 'one')}');
    final textureOne = File(
        '${root.path}/${battleRecipeBlobPath(pngHash, 'image/png', projectMoveId: 'one')}');
    expect(await particleOne.readAsBytes(), particle);
    expect(await textureOne.readAsBytes(), png);
    await service.undoMutation(current.projectHandle,
        entryId: second.receipt.receiptId, idempotencyKey: 'undo-two');
    expect(await two.exists(), isFalse);
    expect(await one.readAsBytes(), recipe);
    expect(
        await File('${root.path}/${battleRecipeBindingPath('one')}').exists(),
        isTrue);
    await service.redoMutation(current.projectHandle,
        entryId: second.receipt.receiptId, idempotencyKey: 'redo-two');
    expect(await two.readAsBytes(), recipe);
    expect(await one.readAsBytes(), recipe);
    await service.undoMutation(current.projectHandle,
        entryId: second.receipt.receiptId, idempotencyKey: 'undo-two-again');
    expect(await two.exists(), isFalse);
    expect(await one.readAsBytes(), recipe);
    final retry = await planFor('one', 'retry-one');
    expect(retry.applicable, isFalse);
    final invalid = parametersFor('two');
    final resourceList =
        (invalid['resources'] as List).cast<Map<String, Object?>>();
    invalid['resources'] = [
      {...resourceList.first, 'sha256': '0' * 64},
      resourceList.last,
    ];
    await expectLater(
        planFor('two', 'bad-two', override: invalid), throwsFormatException);
    expect(await two.exists(), isFalse);
    final stale = await planFor('two', 'stale-two');
    final originalMoves = await moves.readAsBytes();
    await moves.writeAsString(jsonEncode({
      'catalog': 'moves',
      'entries': [
        {'id': 'one'}
      ]
    }));
    await expectLater(
      service.applyMutation(current.projectHandle,
          planId: stale.planId, operationId: 'stale-two'),
      throwsA(isA<CatalogStorageException>().having(
          (error) => error.code, 'code', 'catalog.project_revision_conflict')),
    );
    expect(await two.exists(), isFalse);
    await moves.writeAsBytes(originalMoves);
    final wire = JsonlWorker(
      api: AuthoringReadApi(openService: opener, snapshotLoader: snapshots),
      mutations: service,
    );
    final wireParams = parametersFor('two');
    final wireSnapshot = await service.readWorkshopSnapshot(
        current.projectHandle,
        actionId: 'pokemon.move_recipe.import',
        parameters: wireParams);
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
        requestId: 'wire-two',
        actionId: 'pokemon.move_recipe.import',
        actionVersion: 1,
        workspaceHandle: current.workspaceHandle.value,
        expectedRevision: wireSnapshot.revision,
        idempotencyKey: 'wire-two',
        parameters: wireParams,
        extensions: const {'workshopScope': true},
      ).toJson(),
    });
    await call('apply', {
      'projectHandle': current.projectHandle.value,
      'planId': wirePlan['planId'],
      'operationId': 'wire-two',
    });
    expect(await two.readAsBytes(), recipe);
    await service.detachWorkspace(current.workspaceHandle);
    handles.closeWorkspace(current.workspaceHandle);
    final reopened = await opener.openProject(root.path);
    opened = reopened;
    final reopenedService = LocalMapAuthoringMutationApi(
      policy: policy,
      snapshotLoader: ProjectSnapshotLoader(handles: handles),
      catalogFileReader: reader,
    );
    api = reopenedService;
    await reopenedService.attachProject(
        projectRootPath: root.path,
        workspaceHandle: reopened.workspaceHandle,
        projectHandle: reopened.projectHandle);
    final reread = await reopenedService.readWorkshopSnapshot(
        reopened.projectHandle,
        actionId: 'pokemon.move_recipe.import',
        parameters: wireParams);
    final recipePath = battleRecipeBlobPath(
        digest, 'application/vnd.avelune.battle-recipe+json',
        projectMoveId: 'two');
    expect(reread.findResourceBytes('battleRecipe:$recipePath'), recipe);
    late final GamePackageExportArtifact exported;
    try {
      exported = await const CanonicalGamePackageExportService().build(
        projectRoot: root,
        profile: GamePackageExportProfile(
          gameId: 'games.example.recipe',
          gameVersion: '0.1.0',
          title: 'Recipe',
          authorName: 'Yoahn',
          defaultLocale: 'fr',
          supportedLocales: ['fr'],
        ),
        mode: GamePackageExportMode.localTest,
      );
    } on GamePackageExportException catch (error) {
      fail('$error; cause: ${error.cause}');
    }
    final archive =
        ZipDecoder().decodeBytes(exported.packageBytes, verify: true);
    final particlePath = battleRecipeBlobPath(
        particleHash, 'application/vnd.avelune.particle+json',
        projectMoveId: 'two');
    final texturePath =
        battleRecipeBlobPath(pngHash, 'image/png', projectMoveId: 'two');
    expect(archive.findFile('project/$recipePath')!.content, recipe);
    expect(archive.findFile('project/$particlePath')!.content, particle);
    expect(archive.findFile('project/$texturePath')!.content, png);
    final archivedBinding = BattleRecipeProjectBinding.fromJson(jsonDecode(
      utf8.decode(archive
          .findFile('project/${battleRecipeBindingPath('two')}')!
          .content as List<int>),
    ));
    expect(archivedBinding.binding.projectMoveId, 'two');
  });
}
