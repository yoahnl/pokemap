import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:map_runtime/src/application/load_runtime_map_bundle.dart';
import 'package:map_runtime/src/application/runtime_map_bundle.dart';
import 'package:path/path.dart' as p;

import '../../../map_distribution/test/support/spatial_feature_capabilities_fixture.dart';
import '../../../map_distribution/test/support/cs_audio_package_fixture.dart';

typedef FetchedBattleRecipe = ({
  BattleMoveRecipeBinding binding,
  InspectedBattleRecipeBundle bundle,
  String catalogMoveId,
  String recipeMediaId,
});

final class _RecipeTransport implements PokemonBoundedExternalHttpTransport {
  _RecipeTransport(this.recipe);
  final List<int> recipe;

  @override
  Future<PokemonExternalHttpResponse> getBounded(
    Uri uri, {
    required Map<String, String> headers,
    required int maximumBytes,
    required Duration timeout,
  }) async {
    final owner = uri.path.endsWith('/owners/move/catalog');
    final data = owner
        ? utf8.encode(
            jsonEncode([
              {
                'id': 'recipe',
                'sha256': sha256.convert(recipe).toString(),
                'contentType': 'application/vnd.avelune.battle-recipe+json',
                'usage': 'battle',
                'representation': 'recipe',
                'style': 'synthetic',
                'metadata': {
                  'recipeId': 'synthetic',
                  'revision': '1',
                  'moveSourceId': 'source',
                  'variant': 'default',
                  'bindings': <String, String>{},
                },
              },
            ]),
          )
        : recipe;
    return PokemonExternalHttpResponse(
      statusCode: 200,
      headers: const {},
      body: owner ? utf8.decode(data) : '',
      bodyBytes: Uint8List.fromList(data),
    );
  }
}

Future<({RuntimeMapBundle bundle, GameState state})>
offlineRecipePackageFixture({
  bool spatial = true,
  FetchedBattleRecipe? fetchedRecipe,
  bool cameraRecipe = false,
}) async {
  final owner = await Directory.systemTemp.createTemp(
    'offline-recipe-package-',
  );
  addTearDown(() async {
    if (await owner.exists()) await owner.delete(recursive: true);
  });
  final root = await Directory(p.join(owner.path, 'authoring')).create();
  final files = spatialFeaturePayload('companion');
  if (!spatial) {
    final pokemonProject = ProjectManifest.fromJson(
      jsonDecode(utf8.decode(files['project/project.json']!)),
    );
    final twoDimensional = csAudioPayload(ProjectDimension.twoD);
    final base = ProjectManifest.fromJson(
      jsonDecode(utf8.decode(twoDimensional['project/project.json']!)),
    );
    twoDimensional['project/project.json'] = utf8.encode(
      jsonEncode(base.copyWith(pokemon: pokemonProject.pokemon).toJson()),
    );
    files.addAll(twoDimensional);
  }
  final project = ProjectManifest.fromJson(
    jsonDecode(utf8.decode(files['project/project.json']!)),
  );
  final species = jsonDecode(
    utf8.decode(files['project/data/pokemon/species/bronze-bird.json']!),
  ) as Map<String, dynamic>;
  (species['progression'] as Map)['growthRateId'] = 'medium_slow';
  files['project/data/pokemon/species/bronze-bird.json'] = utf8.encode(
    jsonEncode(species),
  );
  files['project/data/pokemon/learnsets/clockbird.json'] = utf8.encode(
    jsonEncode(
      const PokemonLearnsetFile(
        speciesId: 'clockbird',
        startingMoves: ['tackle'],
      ).toJson(),
    ),
  );
  files['project/${project.pokemon.catalogFiles['growth_rates']}'] = utf8
      .encode(
        jsonEncode({
          'schemaVersion': 1,
          'catalog': 'growth_rates',
          'entries': [
            {'id': 'medium_slow'},
          ],
        }),
      );
  files['project/${project.pokemon.catalogFiles['moves']}'] = utf8.encode(
    jsonEncode({
      'schemaVersion': 1,
      'catalog': 'moves',
      'entries': [
        const PokemonMove(
          id: 'tackle',
          name: 'Tackle',
          type: 'normal',
          category: PokemonMoveCategory.physical,
          basePower: 40,
          pp: 35,
          accuracy: PokemonMoveAccuracy.percent(value: 100),
          engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
        ).toJson(),
      ],
    }),
  );
  files['project/${project.pokemon.catalogFiles['items']}'] = utf8.encode(
    jsonEncode(
      encodeProjectItemCatalog(
        const ProjectItemCatalog(schemaVersion: 1, entries: []),
      ),
    ),
  );
  for (final entry in files.entries) {
    if (entry.key == 'project/project.json') continue;
    final file = File(
      p.join(root.path, entry.key.substring('project/'.length)),
    );
    await file.parent.create(recursive: true);
    await file.writeAsBytes(entry.value);
  }
  final storage = await CatalogStorageStore.open(projectRoot: root.path);
  await WorkingProjectCatalog.create(
    store: storage,
    projectId: 'fixture',
    project: project,
  );
  final handles = WorkspaceHandleStore();
  final reader = const LocalProjectFileReader();
  final policy = await WorkspacePolicy.create(
    allowedRootPaths: [root.path],
    fileReader: reader,
  );
  final opener = ProjectOpenService(
    policy: policy,
    fileReader: reader,
    handles: handles,
    catalogMetadataFields: {},
  );
  final opened = await opener.openProject(root.path);
  final api = LocalMapAuthoringMutationApi(
    policy: policy,
    snapshotLoader: ProjectSnapshotLoader(handles: handles),
    catalogFileReader: reader,
  );
  await api.attachProject(
    projectRootPath: root.path,
    workspaceHandle: opened.workspaceHandle,
    projectHandle: opened.projectHandle,
  );
  addTearDown(() async {
    await api.detachWorkspace(opened.workspaceHandle);
    handles.closeWorkspace(opened.workspaceHandle);
  });
  final bytes = utf8.encode(
    jsonEncode({
      'schemaVersion': 1,
      'recipeId': 'synthetic',
      'revision': '1',
      'moveSourceId': 'source',
      'variant': 'default',
      'requiredCapabilities': cameraRecipe
          ? ['sequence', 'cameraFocus', 'wait']
          : ['wait'],
      'provenance': {
        'source': 'synthetic',
        'sourceRevision': '1',
        'sourcePaths': <String>[],
        'converter': 'test',
      },
      'resources': <Object>[],
      'program': cameraRecipe
          ? {
              'kind': 'sequence',
              'steps': [
                {'kind': 'cameraFocus', 'target': 'user', 'durationMs': 321},
                {'kind': 'wait', 'durationMs': 1234},
              ],
            }
          : {'kind': 'wait', 'durationMs': 1234},
    }),
  );
  final fetched =
      fetchedRecipe ??
      await AveluneMoveRecipeSource(
        AvelunePokemonMediaSource(
          client: _RecipeTransport(bytes),
          release: 'fixture',
        ),
      ).fetch(
        catalogMoveId: 'catalog',
        sourceMoveId: 'source',
        projectMoveId: 'tackle',
        mediaId: 'recipe',
        limits: const BattleRecipeBundleLimits(
          maxTextures: 0,
          maxTextureBytes: 0,
          maxBundleBytes: 10000,
          maxDimension: 16,
          maxTexturePixels: 256,
          maxTotalPixels: 256,
        ),
        availableCapabilities: BattleMoveAnimationRecipe.recognizedCapabilities,
      );
  final staged = await api.artifacts.put(fetched.bundle.recipeBytes);
  final stagedResources = <Map<String, Object?>>[];
  for (final resource in fetched.bundle.recipe.resources) {
    final artifact = await api.artifacts.put(
      fetched.bundle.media[resource.id]!,
    );
    stagedResources.add({
      'id': resource.id,
      'sha256': resource.sha256Hex,
      'mediaType': resource.mediaType,
      'artifactHandle': artifact.reference.handle,
    });
  }
  final params = <String, Object?>{
    'projectBinding': BattleRecipeProjectBinding(
      binding: fetched.binding,
      catalogMoveId: fetched.catalogMoveId,
      recipeMediaId: fetched.recipeMediaId,
    ).toJson(),
    'recipeHandle': staged.reference.handle,
    'resources': stagedResources,
  };
  final snapshot = await api.readWorkshopSnapshot(
    opened.projectHandle,
    actionId: 'pokemon.move_recipe.import',
    parameters: params,
  );
  final plan = await api.planMutation(
    opened.projectHandle,
    AuthoringRequest(
      requestId: 'import',
      actionId: 'pokemon.move_recipe.import',
      actionVersion: 1,
      workspaceHandle: opened.workspaceHandle.value,
      expectedRevision: snapshot.revision,
      idempotencyKey: 'import',
      parameters: params,
      extensions: const {'workshopScope': true},
    ),
  );
  await api.applyMutation(
    opened.projectHandle,
    planId: plan.planId,
    operationId: 'import',
  );
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
  final archive = ZipDecoder().decodeBytes(exported.packageBytes, verify: true);
  final projectMoveId = fetched.binding.projectMoveId;
  expect(
    archive
        .findFile(
          'project/${battleRecipeBlobPath(fetched.binding.recipeSha256, 'application/vnd.avelune.battle-recipe+json', projectMoveId: projectMoveId)}',
        )
        ?.content,
    orderedEquals(fetched.bundle.recipeBytes),
  );
  for (final resource in fetched.bundle.recipe.resources) {
    expect(
      archive
          .findFile(
            'project/${battleRecipeBlobPath(resource.sha256Hex, resource.mediaType, projectMoveId: projectMoveId)}',
          )
          ?.content,
      orderedEquals(fetched.bundle.media[resource.id]!),
    );
  }
  final install = await Directory(p.join(owner.path, 'installed')).create();
  for (final entry in archive.files) {
    if (!entry.isFile || !entry.name.startsWith('project/')) continue;
    final relative = entry.name.substring('project/'.length);
    final path = p.normalize(p.join(install.path, relative));
    if (!p.isWithin(install.path, path)) {
      throw StateError('Invalid package path');
    }
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(entry.content as List<int>);
  }
  final bundle = await loadRuntimeMapBundle(
    projectFilePath: p.join(install.path, 'project.json'),
    mapId: 'map',
  );
  final savePath = p.join(
    Directory.current.path,
    '..',
    '..',
    'examples',
    'playable_runtime_host',
    'golden_battle_slice',
    'runtime_host_launch_save.json',
  );
  final save =
      jsonDecode(await File(savePath).readAsString()) as Map<String, dynamic>;
  final party = (save['party'] as Map)['members'] as List;
  final member = Map<String, dynamic>.from(party.first as Map);
  member.addAll({
    'speciesId': 'clockbird',
    'abilityId': 'calm',
    'level': 5,
    'knownMoveIds': ['tackle'],
    'currentPpByMoveId': {'tackle': 35},
    'currentHp': 10,
  });
  save['party'] = {
    'members': [member],
  };
  save['currentMapId'] = 'map';
  final state = gameStateFromSaveData(SaveData.fromJson(save))
      .copyWith(playerSpatialPosition: PlayerSpatialPosition(x: 1.25, z: 1.5));
  return (bundle: bundle, state: state);
}
