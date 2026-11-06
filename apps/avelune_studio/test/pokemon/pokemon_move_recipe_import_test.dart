import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/pokemon/application/pokemon_workspace_controller.dart';
import 'package:avelune_studio/features/pokemon/data/local_pokemon_workspace_adapter.dart';
import 'package:avelune_studio/features/pokemon/data/http_pokemon_external_transport.dart';
import 'package:avelune_studio/features/pokemon/data/pokemon_move_recipe_import.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_move_recipe_choice.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_move_recipe_port.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_workspace_models.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/presentation/features/pokemon/pokemon_moves_library.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:http/http.dart' as http;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/presentation/flame/battle_offline_move_recipe_loader.dart';

import '../../../../packages/map_distribution/test/support/spatial_feature_capabilities_fixture.dart';
import '../support/m2_ui_fixture.dart' show WidgetResourcePort, pumpIo;
import '../support/ui_pokemon_port.dart';

final class _UiRecipePort extends UiPokemonPort
    implements PokemonMoveRecipePort, PokemonMoveRecipeBatchPort {
  _UiRecipePort(this.adapter, WidgetTester tester) : super(adapter, tester);

  final LocalPokemonWorkspaceAdapter adapter;

  @override
  bool get supportsMoveRecipes => adapter.supportsMoveRecipes;

  @override
  Future<void> prepareMoveRecipeBatchProject() async =>
      WidgetResourcePort.serial(tester, adapter.prepareMoveRecipeBatchProject);

  @override
  Future<BattleMoveRecipeBatchResult> importMoveRecipeBatch({
    required String operationId,
    int startIndex = 0,
    int limit = BattleMoveRecipeBatchImporter.maximumBatchSize,
    String? expectedInventoryRevision,
    bool Function()? isCancelled,
    void Function(BattleMoveRecipeBatchEntry entry)? onProgress,
  }) async => (await WidgetResourcePort.serial(
    tester,
    () => adapter.importMoveRecipeBatch(
      operationId: operationId,
      startIndex: startIndex,
      limit: limit,
      expectedInventoryRevision: expectedInventoryRevision,
      isCancelled: isCancelled,
      onProgress: onProgress,
    ),
  ))!;

  @override
  Future<void> prepareMoveRecipes() async =>
      WidgetResourcePort.serial(tester, adapter.prepareMoveRecipes);

  @override
  Future<List<PokemonMoveRecipeChoice>> listMoveRecipes(String id) async =>
      (await WidgetResourcePort.serial(
        tester,
        () => adapter.listMoveRecipes(id),
      ))!;

  @override
  Future<bool> importMoveRecipe(
    String id,
    PokemonMoveRecipeChoice choice, {
    bool Function()? isCurrent,
  }) async => (await WidgetResourcePort.serial(
    tester,
    () => adapter.importMoveRecipe(id, choice, isCurrent: isCurrent),
  ))!;
}

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
  Future<List<int>> readBytes({
    required String projectRoot,
    required String relativePath,
  }) {
    paths.add(relativePath);
    return delegate.readBytes(
      projectRoot: projectRoot,
      relativePath: relativePath,
    );
  }

  @override
  Stream<List<int>> openRead({
    required String projectRoot,
    required String relativePath,
  }) {
    paths.add(relativePath);
    return delegate.openRead(
      projectRoot: projectRoot,
      relativePath: relativePath,
    );
  }

  @override
  Future<ProjectResourceProbe> probeResource({
    required String projectRoot,
    required String relativePath,
  }) => delegate.probeResource(
    projectRoot: projectRoot,
    relativePath: relativePath,
  );
}

final class _RecipeTransport implements PokemonBoundedExternalHttpTransport {
  _RecipeTransport(this.particle, this.texture, {this.sound}) {
    recipe = utf8.encode(
      jsonEncode({
        'schemaVersion': 1,
        'recipeId': 'flame',
        'revision': '1',
        'moveSourceId': 'flamethrower',
        'variant': 'default',
        'requiredCapabilities': [
          'startParticle',
          'splParticleV2',
          if (sound != null) 'sequence',
          if (sound != null) 'sound',
        ],
        'provenance': {
          'source': 'synthetic',
          'sourceRevision': '1',
          'sourcePaths': <String>[],
          'converter': 'test',
        },
        'resources': [
          _resource('tex', texture, 'texture', 'image/png'),
          {
            ..._resource(
              'particle',
              particle,
              'particleDefinition',
              'application/vnd.avelune.particle+json',
            ),
            'definitionVersion': 2,
            'dependencies': ['tex'],
          },
          if (sound != null) _resource('sound', sound!, 'sound', 'audio/wav'),
        ],
        'program': sound == null
            ? {
                'kind': 'startParticle',
                'resourceId': 'particle',
                'from': 'userMouth',
                'to': 'targetImpact',
              }
            : {
                'kind': 'sequence',
                'steps': [
                  {'kind': 'sound', 'resourceId': 'sound'},
                  {
                    'kind': 'startParticle',
                    'resourceId': 'particle',
                    'from': 'userMouth',
                    'to': 'targetImpact',
                  },
                ],
              },
      }),
    );
  }

  final List<int> particle;
  final List<int> texture;
  final List<int>? sound;
  late List<int> recipe;
  String style = 'gen5';
  bool corruptTexture = false;
  Completer<void>? textureStarted;
  Completer<void>? textureGate;

  static Map<String, Object> _resource(
    String id,
    List<int> bytes,
    String role,
    String type,
  ) => {
    'id': id,
    'role': role,
    'mediaType': type,
    'sizeBytes': bytes.length,
    'sha256': sha256.convert(bytes).toString(),
  };

  @override
  Future<PokemonExternalHttpResponse> getBounded(
    Uri uri, {
    required Map<String, String> headers,
    required int maximumBytes,
    required Duration timeout,
  }) async {
    if (uri.path.endsWith('/texture') && textureGate != null) {
      textureStarted?.complete();
      await textureGate!.future;
    }
    Map<String, Object> item(
      String id,
      List<int> bytes,
      String type,
      String representation,
      Map<String, Object> metadata,
    ) => {
      'id': id,
      'sha256': sha256.convert(bytes).toString(),
      'contentType': type,
      'usage': 'battle',
      'representation': representation,
      'style': style,
      'metadata': metadata,
    };
    final listing = uri.path.endsWith('/owners/move/flamethrower');
    final bytes = listing
        ? utf8.encode(
            jsonEncode([
              item(
                'flame',
                recipe,
                'application/vnd.avelune.battle-recipe+json',
                'recipe',
                {
                  'recipeId': 'flame',
                  'revision': '1',
                  'moveSourceId': 'flamethrower',
                  'variant': 'default',
                  'bindings': {
                    'tex': 'texture',
                    'particle': 'particle',
                    if (sound != null) 'sound': 'sound',
                  },
                },
              ),
              item(
                'particle',
                particle,
                'application/vnd.avelune.particle+json',
                'particle',
                {},
              ),
              if (sound != null)
                item('sound', sound!, 'audio/wav', 'audio', {}),
              item('texture', texture, 'image/png', 'sprite2d', {}),
            ]),
          )
        : uri.path.endsWith('/flame')
        ? recipe
        : uri.path.endsWith('/particle')
        ? particle
        : uri.path.endsWith('/sound')
        ? sound!
        : corruptTexture
        ? List<int>.filled(texture.length, 0)
        : texture;
    return PokemonExternalHttpResponse(
      statusCode: 200,
      headers: const {},
      body: listing ? utf8.decode(bytes) : '',
      bodyBytes: Uint8List.fromList(bytes),
    );
  }
}

final class _BundleRecipeTransport
    implements PokemonBoundedExternalHttpTransport {
  _BundleRecipeTransport(
    this.move,
    this.recipe,
    Map<String, List<int>> resources,
  ) {
    final definition = jsonDecode(utf8.decode(recipe)) as Map<String, dynamic>;
    final declared = (definition['resources'] as List)
        .cast<Map<String, dynamic>>();
    final bindings = <String, String>{};
    for (var i = 0; i < declared.length; i++) {
      final resource = declared[i];
      final id = 'resource-$i';
      final data = resources[resource['id']]!;
      bindings[resource['id'] as String] = id;
      files[id] = data;
      listing.add({
        'id': id,
        'sha256': sha256.convert(data).toString(),
        'contentType': resource['mediaType'],
        'usage': 'battle',
        'representation': switch (resource['role']) {
          'texture' => 'sprite2d',
          'particleDefinition' => 'particle',
          'sound' => 'audio',
          _ => throw StateError('Unexpected media'),
        },
        'style': 'gen5-bw2',
        'metadata': <String, Object>{},
      });
    }
    files['recipe'] = recipe;
    listing.add({
      'id': 'recipe',
      'sha256': sha256.convert(recipe).toString(),
      'contentType': 'application/vnd.avelune.battle-recipe+json',
      'usage': 'battle',
      'representation': 'recipe',
      'style': 'gen5-bw2',
      'metadata': {
        'recipeId': definition['recipeId'],
        'revision': definition['revision'],
        'moveSourceId': definition['moveSourceId'],
        'variant': definition['variant'],
        'bindings': bindings,
      },
    });
  }

  final String move;
  final List<int> recipe;
  final files = <String, List<int>>{};
  final listing = <Map<String, Object?>>[];

  @override
  Future<PokemonExternalHttpResponse> getBounded(
    Uri uri, {
    required Map<String, String> headers,
    required int maximumBytes,
    required Duration timeout,
  }) async {
    final isListing = uri.path.endsWith('/owners/move/$move');
    final bytes = isListing
        ? utf8.encode(jsonEncode(listing))
        : files[uri.pathSegments.last]!;
    if (bytes.length > maximumBytes) {
      throw const FormatException('Media exceeds limit');
    }
    return PokemonExternalHttpResponse(
      statusCode: 200,
      headers: const {},
      body: isListing ? utf8.decode(bytes) : '',
      bodyBytes: Uint8List.fromList(bytes),
    );
  }
}

Uint8List _largeWav() {
  const samples = 300000;
  final bytes = Uint8List(44 + samples);
  final data = ByteData.sublistView(bytes);
  bytes.setRange(0, 4, ascii.encode('RIFF'));
  data.setUint32(4, bytes.length - 8, Endian.little);
  bytes.setRange(8, 16, ascii.encode('WAVEfmt '));
  data.setUint32(16, 16, Endian.little);
  data.setUint16(20, 1, Endian.little);
  data.setUint16(22, 1, Endian.little);
  data.setUint32(24, 8000, Endian.little);
  data.setUint32(28, 8000, Endian.little);
  data.setUint16(32, 1, Endian.little);
  data.setUint16(34, 8, Endian.little);
  bytes.setRange(36, 40, ascii.encode('data'));
  data.setUint32(40, samples, Endian.little);
  return bytes;
}

void main() {
  late Directory root;
  late PokemonMoveRecipeImport importer;
  late _RecipeTransport transport;
  late _CountingReader reader;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('studio-move-recipe-');
    final fixture = spatialFeaturePayload('companion');
    final base = ProjectManifest.fromJson(
      jsonDecode(utf8.decode(fixture['project/project.json']!)),
    );
    final project = base.copyWith(
      pokemon: base.pokemon.copyWith(catalogRelease: 'test'),
      maps: [
        ...base.maps,
        for (var i = 0; i < 40; i++)
          ProjectMapEntry(
            id: 'foreign-$i',
            name: 'Foreign',
            relativePath: 'maps/foreign-$i.json',
          ),
      ],
    );
    final store = await CatalogStorageStore.open(projectRoot: root.path);
    await WorkingProjectCatalog.create(
      store: store,
      projectId: 'recipe-test',
      project: project,
    );
    for (final entry in fixture.entries) {
      if (entry.key == 'project/project.json') continue;
      final file = File(
        '${root.path}/${entry.key.substring('project/'.length)}',
      );
      await file.parent.create(recursive: true);
      await file.writeAsBytes(entry.value);
    }
    for (var i = 0; i < 40; i++) {
      final file = File('${root.path}/maps/foreign-$i.json');
      await file.parent.create(recursive: true);
      await file.writeAsString('unrelated map must not be read');
    }
    final moves = File('${root.path}/${project.pokemon.catalogFiles['moves']}');
    await moves.parent.create(recursive: true);
    await moves.writeAsString(
      jsonEncode({
        'schemaVersion': 1,
        'catalog': 'moves',
        'entries': [
          PokemonMove(
            id: 'flamethrower',
            name: 'Flamethrower',
            source: 'heartgold-fr-rom',
            type: 'fire',
            category: PokemonMoveCategory.special,
            accuracy: const PokemonMoveAccuracy.alwaysHits(),
          ).toJson(),
          PokemonMove(
            id: 'surf',
            name: 'Surf',
            type: 'water',
            category: PokemonMoveCategory.special,
            accuracy: const PokemonMoveAccuracy.alwaysHits(),
          ).toJson(),
          PokemonMove(
            id: 'smoke_screen',
            name: 'Smokescreen',
            type: 'normal',
            category: PokemonMoveCategory.status,
            accuracy: const PokemonMoveAccuracy.alwaysHits(),
          ).toJson(),
        ],
      }),
    );
    final particle = await File(
      '../../packages/map_core/test/fixtures/spl_particle_v2.json',
    ).readAsBytes();
    final png = image.encodePng(image.Image(width: 2, height: 2));
    transport = _RecipeTransport(particle, png);
    reader = _CountingReader();
    importer = await PokemonMoveRecipeImport.open(
      session: ProjectSession(
        sessionId: 'recipe-test',
        name: 'Recipe test',
        directoryPath: root.path,
        storage: ProjectSessionStorage.workingCatalog,
      ),
      mapAdapter: LocalMapWorkspaceAdapter(),
      media: AvelunePokemonMediaSource(client: transport, release: 'test'),
      reader: reader,
    );
  });

  tearDown(() async {
    await importer.close();
    if (await root.exists()) await root.delete(recursive: true);
  });

  test('imports an API recipe through the scoped authoring boundary', () async {
    final choices = await importer.listForMove('flamethrower');
    expect(choices, hasLength(1));
    expect(choices.single.variant, 'default');
    reader.paths.clear();
    expect(await importer.importChoice('flamethrower', choices.single), isTrue);
    expect(
      reader.paths.where((path) => path.startsWith('maps/foreign-')),
      isEmpty,
    );
    expect(
      reader.paths.where((path) => path.endsWith('history.jsonl')),
      isEmpty,
    );
    final bindingFile = File(
      '${root.path}/${battleRecipeBindingPath('flamethrower')}',
    );
    final binding = BattleRecipeProjectBinding.fromJson(
      jsonDecode(await bindingFile.readAsString()) as Map<String, dynamic>,
    );
    expect(
      binding.binding.recipeSha256,
      sha256.convert(transport.recipe).toString(),
    );
    expect(binding.catalogMoveId, 'flamethrower');
    expect(binding.recipeMediaId, 'flame');
    reader.paths.clear();
    expect(
      await importer.importChoice('flamethrower', choices.single),
      isFalse,
    );
    expect(
      reader.paths.where((path) => path.startsWith('maps/foreign-')),
      isEmpty,
    );
    expect(
      reader.paths.where((path) => path.endsWith('history.jsonl')),
      isEmpty,
    );
  });

  test(
    'Studio delegates a bounded batch to the shared authoring importer',
    () async {
      transport.style = 'gen5-bw2';
      final result = await importer.importBatch(
        operationId: 'studio-batch',
        limit: 1,
      );
      expect(
        result.results.single.status,
        BattleMoveRecipeBatchStatus.imported,
      );
      expect(result.remaining, 2);
      expect(
        await File('${root.path}/${battleRecipeBindingPath('flamethrower')}')
            .exists(),
        isTrue,
      );
    },
  );

  test(
    'prepares an older project through the canonical authoring service',
    () async {
      transport.style = 'gen5-bw2';
      final pendingIndex = File(
        '${root.path}/.pokemap/authoring/transactions/pending-journals.json',
      );
      if (await pendingIndex.exists()) await pendingIndex.delete();
      final blocked = await importer.importBatch(
        operationId: 'before-preparation',
        limit: 1,
      );
      expect(blocked.stopped, 'preparationRequired');
      await importer.prepareBatchProject();
      final result = await importer.importBatch(
        operationId: 'after-preparation',
        limit: 1,
      );
      expect(
        result.results.single.status,
        BattleMoveRecipeBatchStatus.imported,
      );
    },
  );

  test('imports a recipe using the HGSS smokescreen alias', () async {
    await importer.close();
    final definition =
        jsonDecode(utf8.decode(transport.recipe)) as Map<String, dynamic>;
    definition['moveSourceId'] = 'smokescreen';
    final aliasTransport = _BundleRecipeTransport(
      'smokescreen',
      utf8.encode(jsonEncode(definition)),
      {'particle': transport.particle, 'tex': transport.texture},
    );
    importer = await PokemonMoveRecipeImport.open(
      session: ProjectSession(
        sessionId: 'recipe-alias',
        name: 'Recipe test',
        directoryPath: root.path,
        storage: ProjectSessionStorage.workingCatalog,
      ),
      mapAdapter: LocalMapWorkspaceAdapter(),
      media: AvelunePokemonMediaSource(client: aliasTransport, release: 'test'),
      reader: reader,
    );
    final choice = (await importer.listForMove('smoke_screen')).single;
    expect(choice.catalogMoveId, 'smokescreen');
    expect(await importer.importChoice('smoke_screen', choice), isTrue);
    final stored = BattleRecipeProjectBinding.fromJson(
      jsonDecode(
        await File('${root.path}/${battleRecipeBindingPath('smoke_screen')}')
            .readAsString(),
      ) as Map<String, dynamic>,
    );
    expect(stored.catalogMoveId, 'smokescreen');
    expect(stored.binding.projectMoveId, 'smoke_screen');
  });

  test(
    'rejects altered API resource bytes without creating a binding',
    () async {
      final choice = (await importer.listForMove('flamethrower')).single;
      transport.corruptTexture = true;
      await expectLater(
        importer.importChoice('flamethrower', choice),
        throwsFormatException,
      );
      expect(
        await File('${root.path}/${battleRecipeBindingPath('flamethrower')}')
            .exists(),
        isFalse,
      );
    },
  );

  test('refuses a stale selection before changing the project', () async {
    final choice = (await importer.listForMove('flamethrower')).single;
    await expectLater(
      importer.importChoice('flamethrower', choice, isCurrent: () => false),
      throwsStateError,
    );
    expect(
      await File('${root.path}/${battleRecipeBindingPath('flamethrower')}')
          .exists(),
      isFalse,
    );
  });

  test(
    'cancels an import if the selected attack changes during download',
    () async {
      final choice = (await importer.listForMove('flamethrower')).single;
      transport.textureStarted = Completer<void>();
      transport.textureGate = Completer<void>();
      var current = true;
      final pending = importer.importChoice(
        'flamethrower',
        choice,
        isCurrent: () => current,
      );
      await transport.textureStarted!.future;
      current = false;
      transport.textureGate!.complete();
      await expectLater(pending, throwsStateError);
      expect(
        await File('${root.path}/${battleRecipeBindingPath('flamethrower')}')
            .exists(),
        isFalse,
      );
    },
  );

  test('refuses a recipe that changed after the user selected it', () async {
    final choice = (await importer.listForMove('flamethrower')).single;
    transport.recipe = [...transport.recipe, 32];
    await expectLater(
      importer.importChoice('flamethrower', choice),
      throwsStateError,
    );
    expect(
      await File('${root.path}/${battleRecipeBindingPath('flamethrower')}')
          .exists(),
      isFalse,
    );
  });

  test('reopens the project and recognizes the persisted recipe', () async {
    final choice = (await importer.listForMove('flamethrower')).single;
    await importer.importChoice('flamethrower', choice);
    await importer.close();
    importer = await PokemonMoveRecipeImport.open(
      session: ProjectSession(
        sessionId: 'recipe-reopened',
        name: 'Recipe test',
        directoryPath: root.path,
        storage: ProjectSessionStorage.workingCatalog,
      ),
      mapAdapter: LocalMapWorkspaceAdapter(),
      media: AvelunePokemonMediaSource(client: transport, release: 'test'),
      reader: reader,
    );
    final reopenedChoice = (await importer.listForMove('flamethrower')).single;
    expect(
      await importer.importChoice('flamethrower', reopenedChoice),
      isFalse,
    );
    expect(
      await File('${root.path}/${battleRecipeBindingPath('flamethrower')}')
          .exists(),
      isTrue,
    );
  });

  test(
    'reimports a valid WAV larger than the particle-definition limit',
    () async {
      await importer.close();
      transport = _RecipeTransport(
        transport.particle,
        transport.texture,
        sound: _largeWav(),
      );
      importer = await PokemonMoveRecipeImport.open(
        session: ProjectSession(
          sessionId: 'recipe-audio',
          name: 'Recipe test',
          directoryPath: root.path,
          storage: ProjectSessionStorage.workingCatalog,
        ),
        mapAdapter: LocalMapWorkspaceAdapter(),
        media: AvelunePokemonMediaSource(client: transport, release: 'test'),
        reader: reader,
      );
      final choice = (await importer.listForMove('flamethrower')).single;
      expect(await importer.importChoice('flamethrower', choice), isTrue);
      expect(await importer.importChoice('flamethrower', choice), isFalse);
    },
  );

  test('rejects oversized stored audio without changing its binding', () async {
    await importer.close();
    final sound = _largeWav();
    transport = _RecipeTransport(
      transport.particle,
      transport.texture,
      sound: sound,
    );
    importer = await PokemonMoveRecipeImport.open(
      session: ProjectSession(
        sessionId: 'recipe-oversized-audio',
        name: 'Recipe test',
        directoryPath: root.path,
        storage: ProjectSessionStorage.workingCatalog,
      ),
      mapAdapter: LocalMapWorkspaceAdapter(),
      media: AvelunePokemonMediaSource(client: transport, release: 'test'),
      reader: reader,
    );
    final choice = (await importer.listForMove('flamethrower')).single;
    expect(await importer.importChoice('flamethrower', choice), isTrue);
    final binding = File(
      '${root.path}/${battleRecipeBindingPath('flamethrower')}',
    );
    final originalBinding = await binding.readAsBytes();
    final audio = File(
      '${root.path}/${battleRecipeBlobPath(sha256.convert(sound).toString(), 'audio/wav', projectMoveId: 'flamethrower')}',
    );
    final writer = await audio.open(mode: FileMode.append);
    try {
      await writer.truncate(8 * 1024 * 1024 + 1);
    } finally {
      await writer.close();
    }
    await expectLater(
      importer.importChoice('flamethrower', choice),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          'Battle recipe dependency exceeds its limit',
        ),
      ),
    );
    expect(await binding.readAsBytes(), originalBinding);
    expect(await audio.length(), 8 * 1024 * 1024 + 1);
  });

  test(
    'preserves an existing binding when a different recipe is selected',
    () async {
      final choice = (await importer.listForMove('flamethrower')).single;
      expect(await importer.importChoice('flamethrower', choice), isTrue);
      final file = File(
        '${root.path}/${battleRecipeBindingPath('flamethrower')}',
      );
      final original = await file.readAsBytes();
      transport.recipe = [...transport.recipe, 32];
      final replacement = (await importer.listForMove('flamethrower')).single;
      await expectLater(
        importer.importChoice('flamethrower', replacement),
        throwsA(isA<Exception>()),
      );
      expect(await file.readAsBytes(), original);
    },
  );

  test(
    'exports the imported recipe and keeps the offline Player fallback',
    () async {
      final choice = (await importer.listForMove('flamethrower')).single;
      await importer.importChoice('flamethrower', choice);
      final fixture = spatialFeaturePayload('companion');
      final map = MapData.fromJson(
        jsonDecode(utf8.decode(fixture['project/maps/map.json']!)),
      );
      for (var i = 0; i < 40; i++) {
        await File('${root.path}/maps/foreign-$i.json').writeAsString(
          jsonEncode(map.copyWith(id: 'foreign-$i', name: 'Foreign').toJson()),
        );
      }
      final items = File('${root.path}/data/pokemon/catalogs/items.json');
      await items.parent.create(recursive: true);
      await items.writeAsString(
        jsonEncode(
          encodeProjectItemCatalog(
            const ProjectItemCatalog(schemaVersion: 1, entries: []),
          ),
        ),
      );
      final exported = await const CanonicalGamePackageExportService().build(
        projectRoot: root,
        profile: GamePackageExportProfile(
          gameId: 'games.example.studio-recipe',
          gameVersion: '0.1.0',
          title: 'Recipe',
          authorName: 'Yoahn',
          defaultLocale: 'fr',
          supportedLocales: ['fr'],
        ),
        mode: GamePackageExportMode.localTest,
      );
      final archive = ZipDecoder().decodeBytes(
        exported.packageBytes,
        verify: true,
      );
      final runtime = await Directory('${root.path}/runtime-copy').create();
      for (final entry in archive.files.where(
        (entry) => entry.isFile && entry.name.startsWith('project/'),
      )) {
        final relative = entry.name.substring('project/'.length);
        expect(relative.split('/'), isNot(contains('..')));
        final file = File('${runtime.path}/$relative');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(entry.content as List<int>);
      }
      final result = await BattleOfflineMoveRecipeLoader(
        projectRootDirectory: runtime.path,
      ).load('flamethrower');
      expect(
        result.fallbackReason,
        BattleRecipeFallbackReason.unavailableCapabilities,
      );
      expect(result.prepared, isNull);
      expect(result.unavailableCapabilities, contains('splParticleV2'));
    },
  );

  test(
    'imports and exports a real BW2 source recipe for offline use',
    () async {
      final path = Platform.environment['AVELUNE_BW2_STUDIO_BUNDLE']!;
      final bundle =
          jsonDecode(await File(path).readAsString()) as Map<String, dynamic>;
      final recipe = base64.decode(bundle['recipe'] as String);
      final resources = <String, List<int>>{
        for (final entry in (bundle['media'] as Map<String, dynamic>).entries)
          entry.key: base64.decode(entry.value as String),
      };
      await importer.close();
      final liveRelease = Platform.environment['AVELUNE_BW2_STUDIO_RELEASE'];
      final previousOverrides = HttpOverrides.current;
      late final http.Client httpClient;
      try {
        if (liveRelease != null) HttpOverrides.global = null;
        httpClient = http.Client();
      } finally {
        HttpOverrides.global = previousOverrides;
      }
      addTearDown(httpClient.close);
      importer = await PokemonMoveRecipeImport.open(
        session: ProjectSession(
          sessionId: 'recipe-test',
          name: 'Recipe test',
          directoryPath: root.path,
          storage: ProjectSessionStorage.workingCatalog,
        ),
        mapAdapter: LocalMapWorkspaceAdapter(),
        media: AvelunePokemonMediaSource(
          client: liveRelease == null
              ? _BundleRecipeTransport('surf', recipe, resources)
              : HttpPokemonExternalTransport(httpClient),
          release: liveRelease ?? 'test',
        ),
      );
      final choices = await importer.listForMove('surf');
      expect(choices, hasLength(1));
      expect(await importer.importChoice('surf', choices.single), isTrue);
      httpClient.close();
      final fixture = spatialFeaturePayload('companion');
      final map = MapData.fromJson(
        jsonDecode(utf8.decode(fixture['project/maps/map.json']!)),
      );
      for (var i = 0; i < 40; i++) {
        await File('${root.path}/maps/foreign-$i.json').writeAsString(
          jsonEncode(map.copyWith(id: 'foreign-$i', name: 'Foreign').toJson()),
        );
      }
      final items = File('${root.path}/data/pokemon/catalogs/items.json');
      await items.parent.create(recursive: true);
      await items.writeAsString(
        jsonEncode(
          encodeProjectItemCatalog(
            const ProjectItemCatalog(schemaVersion: 1, entries: []),
          ),
        ),
      );
      final exported = await const CanonicalGamePackageExportService().build(
        projectRoot: root,
        profile: GamePackageExportProfile(
          gameId: 'games.example.studio-bw2',
          gameVersion: '0.1.0',
          title: 'BW2',
          authorName: 'Yoahn',
          defaultLocale: 'fr',
          supportedLocales: ['fr'],
        ),
        mode: GamePackageExportMode.localTest,
      );
      final archive = ZipDecoder().decodeBytes(
        exported.packageBytes,
        verify: true,
      );
      final runtime = await Directory(
        Platform.environment['AVELUNE_BW2_STUDIO_EXPORT_DIR'] ??
            '${root.path}/runtime-copy',
      ).create();
      for (final entry in archive.files.where(
        (entry) => entry.isFile && entry.name.startsWith('project/'),
      )) {
        final relative = entry.name.substring('project/'.length);
        expect(relative.split('/'), isNot(contains('..')));
        final file = File('${runtime.path}/$relative');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(entry.content as List<int>);
      }
      final result = await BattleOfflineMoveRecipeLoader(
        projectRootDirectory: runtime.path,
      ).load('surf', retainVerifiedMedia: true);
      expect(result.verifiedMedia, isNotNull);
      expect(result.verifiedMedia!.bundle.recipeBytes, recipe);
      expect(
        result.verifiedMedia!.bundle.media.keys.toSet(),
        resources.keys.toSet(),
      );
      result.verifiedMedia!.release();
    },
    skip: Platform.environment['AVELUNE_BW2_STUDIO_BUNDLE'] == null,
  );

  testWidgets(
    'Studio imports from the attack panel into the canonical project',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final session = ProjectSession(
        sessionId: 'ui-recipe-test',
        name: 'Recipe',
        directoryPath: root.path,
        storage: ProjectSessionStorage.workingCatalog,
      );
      final adapter = (await tester.runAsync(
        () async => LocalPokemonWorkspaceAdapter(
          session: session,
          mapAdapter: LocalMapWorkspaceAdapter(),
          reader: reader,
          recipeMediaSource: AvelunePokemonMediaSource(
            client: transport,
            release: 'test',
          ),
        ),
      ))!;
      final port = _UiRecipePort(adapter, tester);
      void Function() changed = () {};
      final controller = PokemonWorkspaceController(
        port,
        changed: () => changed(),
      );
      controller.index = const PokemonWorkspaceIndex(
        enabled: true,
        entries: [],
        types: [],
        items: {},
        moves: PokemonMovesCatalogView(
          relativePath: 'moves',
          entries: [
            PokemonMoveSummary(id: 'flamethrower', name: 'Lance-Flammes'),
          ],
        ),
      );
      controller.selectMove('flamethrower');
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              changed = () => setState(() {});
              return Scaffold(
                body: PokemonMovesLibrary(controller: controller),
              );
            },
          ),
        ),
      );
      controller.setView(PokemonWorkspaceView.moves);
      await pumpIo(tester);
      expect(controller.recipeReady, isTrue);
      await tester.ensureVisible(find.text('Rechercher des animations'));
      await tester.tap(find.text('Rechercher des animations'));
      await pumpIo(tester);
      expect(
        find.text('Noir et Blanc · Version par défaut · v1'),
        findsOneWidget,
      );
      reader.paths.clear();
      await tester.ensureVisible(find.text('Ajouter au projet'));
      await tester.tap(find.text('Ajouter au projet'));
      await pumpIo(tester);
      expect(find.text('Animation ajoutée au projet.'), findsOneWidget);
      expect(
        reader.paths.where((path) => path.startsWith('maps/foreign-')),
        isEmpty,
      );
      expect(
        reader.paths.where((path) => path.endsWith('history.jsonl')),
        isEmpty,
      );
      expect(
        (await tester.runAsync(
          () =>
              File('${root.path}/${battleRecipeBindingPath('flamethrower')}')
                  .exists(),
        ))!,
        isTrue,
      );
      reader.paths.clear();
      await tester.ensureVisible(find.text('Ajouter au projet'));
      await tester.tap(find.text('Ajouter au projet'));
      await pumpIo(tester);
      expect(
        find.text('Cette animation est déjà présente dans le projet.'),
        findsOneWidget,
      );
      expect(
        reader.paths.where((path) => path.startsWith('maps/foreign-')),
        isEmpty,
      );
      expect(
        reader.paths.where((path) => path.endsWith('history.jsonl')),
        isEmpty,
      );
      controller.dispose();
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(adapter.close);
    },
  );

  testWidgets('Studio batch button imports into the real project and retries', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    transport.style = 'gen5-bw2';
    final adapter = (await tester.runAsync(
      () async => LocalPokemonWorkspaceAdapter(
        session: ProjectSession(
          sessionId: 'batch-ui',
          name: 'Batch',
          directoryPath: root.path,
          storage: ProjectSessionStorage.workingCatalog,
        ),
        mapAdapter: LocalMapWorkspaceAdapter(),
        reader: reader,
        recipeMediaSource: AvelunePokemonMediaSource(
          client: transport,
          release: 'test',
        ),
      ),
    ))!;
    final port = _UiRecipePort(adapter, tester);
    void Function() changed = () {};
    final controller = PokemonWorkspaceController(
      port,
      changed: () => changed(),
    );
    controller.index = const PokemonWorkspaceIndex(
      enabled: true,
      entries: [],
      types: [],
      items: {},
      moves: PokemonMovesCatalogView(
        relativePath: 'moves',
        entries: [
          PokemonMoveSummary(id: 'flamethrower', name: 'Lance-Flammes'),
          PokemonMoveSummary(id: 'surf', name: 'Surf'),
          PokemonMoveSummary(id: 'smoke_screen', name: 'Brouillard'),
        ],
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            changed = () => setState(() {});
            return Scaffold(body: PokemonMovesLibrary(controller: controller));
          },
        ),
      ),
    );
    reader.paths.clear();
    await tester.tap(find.text('Importer les animations disponibles'));
    await pumpIo(tester);
    expect(find.textContaining('1 animation ajoutée'), findsOneWidget);
    expect(
      (await tester.runAsync(
        () =>
            File('${root.path}/${battleRecipeBindingPath('flamethrower')}')
                .exists(),
      ))!,
      isTrue,
    );
    expect(
      reader.paths.where((path) => path.startsWith('maps/foreign-')),
      isEmpty,
    );
    expect(
      reader.paths.where((path) => path.endsWith('history.jsonl')),
      isEmpty,
    );
    await tester.tap(find.text('Importer les animations disponibles'));
    await pumpIo(tester);
    expect(find.textContaining('1 déjà présente'), findsOneWidget);
    controller.dispose();
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(adapter.close);
  });
}
