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
  _RecipeApi(this.recipe, this.resources);
  final List<int> recipe;
  final Map<String, List<int>> resources;
  final requestedLimits = <String, int>{};
  @override
  Future<PokemonExternalHttpResponse> getBounded(Uri uri,
      {required Map<String, String> headers,
      required int maximumBytes,
      required Duration timeout}) async {
    requestedLimits[uri.path] = maximumBytes;
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
    final definition = jsonDecode(utf8.decode(recipe)) as Map<String, dynamic>;
    final declared =
        (definition['resources'] as List).cast<Map<String, dynamic>>();
    final owner = uri.path.endsWith('/owners/move/catalog');
    final data = owner
        ? utf8.encode(jsonEncode([
            item('recipe', recipe, 'application/vnd.avelune.battle-recipe+json',
                'recipe', {
              'recipeId': definition['recipeId'],
              'revision': definition['revision'],
              'moveSourceId': definition['moveSourceId'],
              'variant': definition['variant'],
              'bindings': {
                for (final resource in declared) resource['id']: resource['id'],
              },
            }),
            for (final resource in declared)
              item(
                resource['id'] as String,
                resources[resource['id']]!,
                resource['mediaType'] as String,
                switch (resource['role']) {
                  'texture' => 'sprite2d',
                  'particleDefinition' => 'particle',
                  'sound' => 'audio',
                  _ => throw StateError('Unexpected test resource'),
                },
                {},
              ),
          ]))
        : uri.path.endsWith('/recipe')
            ? recipe
            : resources[uri.pathSegments.last]!;
    return PokemonExternalHttpResponse(
        statusCode: 200,
        headers: const {},
        body: owner ? utf8.decode(data) : '',
        bodyBytes: Uint8List.fromList(data));
  }
}

void main() {
  Future<void> runScenario({
    required bool spl,
    bool withSound = false,
    bool explicitAudio = false,
    bool gen5 = false,
    bool splV5 = false,
    bool sourceProgram = false,
    String? bundlePath,
  }) async {
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
    final splBytes = spl
        ? await File('../map_core/test/fixtures/spl_particle_v2.json')
            .readAsBytes()
        : null;
    final splData = splBytes == null
        ? null
        : jsonDecode(utf8.decode(splBytes)) as Map<String, dynamic>;
    if (gen5 || splV5) {
      splData!['schemaVersion'] = splV5 ? 5 : 3;
      for (final emitter in splData['emitters'] as List) {
        (emitter['emission'] as Map<String, dynamic>)['positionVelocity'] = 0;
        if (splV5) {
          (emitter['emission'] as Map<String, dynamic>).addAll({'emissionAxis': 'z', 'velocityVariance': 0});
          (emitter['appearance'] as Map<String, dynamic>).addAll({'hasRotation': false, 'minRotation': 0, 'maxRotation': 0, 'dirFromPosition': false});
          (emitter['motion'] as Map<String, dynamic>)['magnet'] = null;
        }
      }
    }
    final particle = spl
        ? gen5 || splV5
            ? utf8.encode(jsonEncode(splData))
            : splBytes!
        : utf8.encode(jsonEncode({
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
    final sound = withSound
        ? await File('../map_runtime/assets/audio/overworld/jump.wav')
            .readAsBytes()
        : null;
    final soundHash = sound == null ? null : sha256.convert(sound).toString();
    final syntheticRecipe = utf8.encode(jsonEncode({
      'schemaVersion': explicitAudio || gen5 ? 2 : 1,
      'recipeId': 'visual',
      'revision': '1',
      'moveSourceId': 'source',
      'variant': 'default',
      'requiredCapabilities': [
        'startParticle',
        if (spl) splV5 ? 'splParticleV5' : gen5 ? 'splParticleV3' : 'splParticleV2',
        if (withSound || gen5) 'sequence',
        if (withSound) 'sound',
        if (explicitAudio || gen5) 'audioSelectionV2',
        if (gen5) 'gen5Swing',
        if (gen5) 'gen5SpritePause',
      ],
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
          'definitionVersion': spl ? (splV5 ? 5 : gen5 ? 3 : 2) : 1,
          'dependencies': ['tex']
        },
        if (sound != null)
          {
            'id': 'sound',
            'role': 'sound',
            'mediaType': 'audio/wav',
            'sizeBytes': sound.length,
            'sha256': soundHash,
          },
      ],
      if (explicitAudio) 'audio': {'kind': 'clip', 'resourceId': 'sound'},
      if (gen5) 'audio': {'kind': 'none'},
      'program': gen5
          ? {
              'kind': 'sequence',
              'steps': [
                {
                  'kind': 'gen5Swing',
                  'target': 'user',
                  'channel': 'position',
                  'x': 4096,
                  'y': 0,
                  'frames': 4,
                  'wait': 1,
                  'count': 1
                },
                {
                  'kind': 'startParticle',
                  'resourceId': 'particle',
                  'from': 'userMouth',
                  'to': 'targetImpact'
                },
                {'kind': 'gen5SpritePause', 'target': 'target', 'paused': true},
              ],
            }
          : withSound && !explicitAudio
              ? {
                  'kind': 'sequence',
                  'steps': [
                    {'kind': 'sound', 'resourceId': 'sound'},
                    {
                      'kind': 'startParticle',
                      'resourceId': 'particle',
                      'from': 'userMouth',
                      'to': 'targetImpact'
                    },
                  ],
                }
              : {
                  'kind': 'startParticle',
                  'resourceId': 'particle',
                  'from': 'userMouth',
                  'to': 'targetImpact'
                },
    }));
    final bundle = bundlePath == null
        ? null
        : jsonDecode(await File(bundlePath).readAsString())
            as Map<String, dynamic>;
    final recipe = bundle == null
        ? syntheticRecipe
        : base64.decode(bundle['recipe'] as String);
    final resources = bundle == null
        ? <String, List<int>>{
            'tex': png,
            'particle': particle,
            if (sound != null) 'sound': sound,
          }
        : <String, List<int>>{
            for (final entry
                in (bundle['media'] as Map<String, dynamic>).entries)
              entry.key: base64.decode(entry.value as String),
          };
    final recipeData = jsonDecode(utf8.decode(recipe)) as Map<String, dynamic>;
    final declaredResources =
        (recipeData['resources'] as List).cast<Map<String, dynamic>>();
    final digest = sha256.convert(recipe).toString();
    final external = _RecipeApi(recipe, resources);
    final fetched = await AveluneMoveRecipeSource(
      AvelunePokemonMediaSource(client: external, release: 'test'),
    ).fetch(
        catalogMoveId: 'catalog',
        sourceMoveId: recipeData['moveSourceId'] as String,
        projectMoveId: 'one',
        mediaId: 'recipe',
        limits: BattleRecipeBundleLimits(
            maxTextures: bundle == null ? 2 : 16,
            maxTextureBytes: bundle == null ? 10000 : 1024 * 1024,
            maxBundleBytes: 64 * 1024 * 1024,
            maxDimension: bundle == null ? 16 : 2048,
            maxTexturePixels: bundle == null ? 256 : 4000000,
            maxTotalPixels: bundle == null ? 256 : 16000000),
        availableCapabilities:
            BattleMoveAnimationRecipe.recognizedCapabilities);
    if (sound != null && bundle == null) {
      expect(
          external.requestedLimits.entries
              .singleWhere((entry) => entry.key.endsWith('/test/sound'))
              .value,
          BattleRecipeBundleInspector.maxSoundBytes);
    }
    final staged = await service.artifacts.put(fetched.bundle.recipeBytes);
    final resourceHandles = <String, String>{};
    for (final entry in fetched.bundle.media.entries) {
      resourceHandles[entry.key] =
          (await service.artifacts.put(entry.value)).reference.handle;
    }
    Map<String, Object?> parametersFor(String id) {
      final binding = BattleMoveRecipeBinding.fromJson({
        'schemaVersion': 1,
        'projectMoveId': id,
        'sourceMoveId': recipeData['moveSourceId'],
        'catalogReleaseId': 'test',
        'recipeId': recipeData['recipeId'],
        'variant': recipeData['variant'],
        'revision': recipeData['revision'],
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
          for (final resource in declaredResources)
            {
              'id': resource['id'],
              'sha256': resource['sha256'],
              'mediaType': resource['mediaType'],
              'artifactHandle': resourceHandles[resource['id']],
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
    for (final resource in declaredResources) {
      final path = battleRecipeBlobPath(
          resource['sha256'] as String, resource['mediaType'] as String,
          projectMoveId: 'one');
      expect(await File('${root.path}/$path').readAsBytes(),
          resources[resource['id']]);
    }
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
    if (sourceProgram) {
      await expectLater(
        const CanonicalGamePackageExportService().build(
          projectRoot: root,
          profile: GamePackageExportProfile(
            gameId: 'games.example.recipe', gameVersion: '0.1.0', title: 'Recipe',
            authorName: 'Yoahn', defaultLocale: 'fr', supportedLocales: ['fr'],
          ),
          mode: GamePackageExportMode.localTest,
        ),
        throwsA(isA<GamePackageExportException>()
            .having((error) => error.code, 'code', 'capabilityUnsupported')),
      );
      return;
    }
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
    if (splV5) {
      final inspected = const GamePackageInspector().inspect(exported.packageBytes);
      expect(inspected.manifest.compatibility.requiredCapabilities,
          contains(BattleMoveAnimationRecipe.splV5RuntimeCapability));
      final manifestJson = inspected.manifest.toJson();
      (manifestJson['compatibility'] as Map)['requiredCapabilities'] = inspected
          .manifest.compatibility.requiredCapabilities
          .where((value) => value != BattleMoveAnimationRecipe.splV5RuntimeCapability)
          .toList();
      final stripped = const GamePackageManifestCodec().decodeJson(manifestJson);
      final payload = <String, List<int>>{for (final file in archive.files)
        if (file.name != 'game-manifest.json') file.name: file.content as List<int>};
      expect(() => const GamePackageProjectValidator(GamePackageSecurityPolicy()).validate(
        stripped, Uint8List.fromList(payload['project/project.json']!),
        payloadPaths: payload.keys.toSet(), readPayload: (path) => payload[path],
      ), throwsA(isA<GamePackageFormatException>().having((error) => error.message,
        'message', contains(BattleMoveAnimationRecipe.splV5RuntimeCapability))));
    }
    expect(archive.findFile('project/$recipePath')!.content, recipe);
    for (final resource in declaredResources) {
      final path = battleRecipeBlobPath(
          resource['sha256'] as String, resource['mediaType'] as String,
          projectMoveId: 'two');
      expect(archive.findFile('project/$path')!.content,
          resources[resource['id']]);
    }
    final archivedBinding = BattleRecipeProjectBinding.fromJson(jsonDecode(
      utf8.decode(archive
          .findFile('project/${battleRecipeBindingPath('two')}')!
          .content as List<int>),
    ));
    expect(archivedBinding.binding.projectMoveId, 'two');
  }

  test('imports, exports and undoes version 1 move recipes',
      () => runScenario(spl: false));
  test('imports, exports and undoes version 2 SPL move recipes',
      () => runScenario(spl: true));
  test('imports and exports a mixed sound and SPL recipe through API and JSONL',
      () => runScenario(spl: true, withSound: true));
  test('imports and exports an explicit audio v2 recipe through API and JSONL',
      () => runScenario(spl: true, withSound: true, explicitAudio: true));
  test('imports and exports Gen 5 motion with SPL v3 through API and JSONL',
      () => runScenario(spl: true, gen5: true));
  test('imports and exports SPL v5 with an explicit Player capability',
      () => runScenario(spl: true, splV5: true));
  test(
      'imports and exports a converted BW2 Tackle bundle through API and JSONL',
      () => runScenario(
          spl: true,
          bundlePath: Platform.environment['AVELUNE_BW2_TACKLE_BUNDLE']),
      skip: Platform.environment['AVELUNE_BW2_TACKLE_BUNDLE'] == null);
  test('imports a complete BW2 source bundle and blocks unsupported export',
      () => runScenario(spl: true, sourceProgram: true,
          bundlePath: Platform.environment['AVELUNE_BW2_SOURCE_BUNDLE']),
      skip: Platform.environment['AVELUNE_BW2_SOURCE_BUNDLE'] == null);
}
