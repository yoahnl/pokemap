import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/pokemon/data/local_pokemon_workspace_adapter.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_external_import_models.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart' show loadProjectManifestFromFile;
import 'package:map_runtime/src/presentation/flame/battle_pokemon_sprite_resolver.dart';

import '../../../../packages/map_distribution/test/support/spatial_feature_capabilities_fixture.dart';
import '../support/pokemon_external_source_fixture.dart';

final class GifTransport implements PokemonBoundedExternalHttpTransport {
  final gif = base64Decode('R0lGODlhAQABAIAAAAAAAP///ywAAAAAAQABAAACAUwAOw==');
  bool offline = false;
  bool missingBack = false;
  int calls = 0;

  @override
  Future<PokemonExternalHttpResponse> getBounded(
    Uri uri, {
    required Map<String, String> headers,
    required int maximumBytes,
    required Duration timeout,
  }) async {
    calls++;
    if (offline) throw const SocketException('offline');
    Object? body;
    if (uri.path.contains('/pokemon-species/')) {
      body = {
        'id': 1,
        'name': 'bulbasaur',
        'varieties': [
          {
            'is_default': true,
            'pokemon': {'name': 'bulbasaur'},
          },
        ],
      };
    } else if (uri.path.contains('/owners/pokemon/')) {
      body = [
        for (final view in ['front', 'back'])
          for (final shiny in [false, true])
            if (!(missingBack && view == 'back' && !shiny))
              {
                'id': '$view-$shiny',
                'sha256': sha256.convert(gif).toString(),
                'contentType': 'image/gif',
                'usage': 'battle',
                'representation': 'sprite2d',
                'style': 'gen5',
                'metadata': {
                  'formId': 'bulbasaur',
                  'view': view,
                  'shiny': shiny,
                },
              },
      ];
    }
    final bytes = body == null
        ? gif
        : Uint8List.fromList(utf8.encode(jsonEncode(body)));
    return PokemonExternalHttpResponse(
      statusCode: 200,
      headers: const {},
      body: body == null ? '' : utf8.decode(bytes),
      bodyBytes: bytes,
    );
  }
}

final class MissingGen5Transport
    implements PokemonBoundedExternalHttpTransport {
  @override
  Future<PokemonExternalHttpResponse> getBounded(
    Uri uri, {
    required Map<String, String> headers,
    required int maximumBytes,
    required Duration timeout,
  }) async => PokemonExternalHttpResponse(
    statusCode: 404,
    headers: const {},
    body: '',
    bodyBytes: Uint8List(0),
  );
}

void main() {
  for (final scenario in [
    'normal',
    'offline',
    'existing',
    'legacy',
    'partial',
    'skip-legacy',
    'skip-v2',
    'skip-ambiguous',
    'skip-dex',
    'skip-form',
    'skip-shared',
  ]) {
    test('imports GIFs through Studio with $scenario media', () async {
      final parent = Directory(
        Platform.environment['AVELUNE_QA_ROOT'] ??
            '${Platform.environment['HOME']}/Library/Caches/AveluneQA',
      );
      await parent.create(recursive: true);
      final root = await parent.createTemp('studio-gif-import-');
      addTearDown(() => root.delete(recursive: true));
      final files = spatialFeaturePayload('companion');
      final manifest = ProjectManifest.fromJson(
        jsonDecode(utf8.decode(files['project/project.json']!))
            as Map<String, dynamic>,
      );
      final store = await CatalogStorageStore.open(projectRoot: root.path);
      final working = await WorkingProjectCatalog.create(
        store: store,
        projectId: 'studio-gif',
        project: manifest,
      );
      await working.close();
      for (final entry in files.entries) {
        if (entry.key == 'project/project.json') continue;
        final file = File(
          '${root.path}/${entry.key.substring('project/'.length)}',
        );
        await file.parent.create(recursive: true);
        await file.writeAsBytes(entry.value);
      }
      final session = ProjectSession(
        sessionId: 'studio-gif',
        name: 'GIF',
        directoryPath: root.path,
        storage: ProjectSessionStorage.workingCatalog,
      );
      final existingMedia = File(
        '${root.path}/data/pokemon/media/bulbasaur.json',
      );
      final originalMedia = utf8.encode(
        jsonEncode({
          'schemaVersion':
              scenario == 'legacy' ||
                  scenario == 'skip-legacy' ||
                  scenario == 'skip-ambiguous'
              ? 1
              : 2,
          'speciesId': 'bulbasaur',
          'defaultFormId': 'base',
          'vendorExtension': {'keep': true},
          'variants': {
            'base': {
              if (scenario != 'skip-legacy')
                'frontAnimated': 'assets/chosen.gif',
              'frontStatic': 'assets/chosen.png',
            },
            'alternative': {'frontStatic': 'assets/alternative.png'},
          },
        }),
      );
      if (scenario == 'existing' ||
          scenario == 'legacy' ||
          scenario.startsWith('skip-')) {
        await existingMedia.parent.create(recursive: true);
        await existingMedia.writeAsBytes(originalMedia);
      }
      if (scenario == 'skip-shared') {
        final other = jsonDecode(
          utf8.decode(files['project/data/pokemon/species/bronze-bird.json']!),
        ) as Map<String, dynamic>;
        other['id'] = 'shared-owner';
        other['slug'] = 'shared-owner';
        (other['refs'] as Map)['media'] = 'bulbasaur';
        await File('${root.path}/data/pokemon/species/shared-owner.json')
            .writeAsString(jsonEncode(other));
      }
      final maps = LocalMapWorkspaceAdapter();
      await maps.loadCatalog(session);
      final transport = GifTransport();
      if (scenario == 'offline') transport.offline = true;
      if (scenario == 'partial') transport.missingBack = true;
      var adapter = LocalPokemonWorkspaceAdapter(
        session: session,
        mapAdapter: maps,
        externalSource: const PokemonExternalSourceFixture(),
        gen5Source: AveluneGen5BattleSource(
          client: MissingGen5Transport(),
          release: 'test',
        ),
        gifSource: AveluneBattleGifSource(client: transport, release: 'test'),
      );
      addTearDown(() => adapter.close());
      if (scenario.startsWith('skip-')) {
        transport.offline = true;
        final initial = await adapter.previewExternal('bulbasaur');
        await adapter.applyExternal(
          initial,
          PokemonExternalConflictPolicy.failOnConflict,
        );
        transport.offline = false;
        if (scenario == 'skip-dex' || scenario == 'skip-form') {
          final species = File(
            '${root.path}/data/pokemon/species/bulbasaur.json',
          );
          final document = jsonDecode(await species.readAsString()) as Map;
          if (scenario == 'skip-dex') document['nationalDex'] = 2;
          if (scenario == 'skip-form') {
            (document['forms'] as Map)['isBaseForm'] = false;
          }
          await species.writeAsString(jsonEncode(document));
        }
      }
      final preview = await adapter.previewExternal('bulbasaur');
      expect(
        preview.gifSelection?.media.length,
        scenario == 'offline'
            ? null
            : scenario == 'partial'
            ? 3
            : 4,
      );
      final result = await adapter.applyExternal(
        preview,
        scenario.startsWith('skip-')
            ? PokemonExternalConflictPolicy.skipExisting
            : PokemonExternalConflictPolicy.failOnConflict,
      );
      expect(
        result.gifImported,
        scenario == 'normal' ||
            scenario == 'existing' ||
            scenario == 'partial' ||
            scenario == 'skip-legacy' ||
            scenario == 'skip-v2',
      );
      final path =
          'assets/pokemon/battle-gifs/${sha256.convert(transport.gif)}.gif';
      if (scenario == 'legacy') {
        expect(await existingMedia.readAsBytes(), originalMedia);
        expect(await File('${root.path}/$path').exists(), isFalse);
        return;
      }
      if (const {
        'skip-ambiguous',
        'skip-dex',
        'skip-form',
        'skip-shared',
      }.contains(scenario)) {
        expect(await existingMedia.readAsBytes(), originalMedia);
        expect(await File('${root.path}/$path').exists(), isFalse);
        return;
      }
      if (scenario == 'existing' || scenario.startsWith('skip-')) {
        final media = jsonDecode(await existingMedia.readAsString()) as Map;
        expect(media['schemaVersion'], 2);
        expect(media['vendorExtension'], {'keep': true});
        expect(
          media['variants']['base']['frontAnimated'],
          scenario == 'skip-legacy' ? path : 'assets/chosen.gif',
        );
        expect(media['variants']['base']['frontStatic'], 'assets/chosen.png');
        expect(media['variants']['base']['backAnimated'], path);
        expect(media['variants']['base']['frontShinyAnimated'], path);
        expect(media['variants']['base']['backShinyAnimated'], path);
        expect(media['variants']['alternative'], {
          'frontStatic': 'assets/alternative.png',
        });
        expect(await File('${root.path}/$path').readAsBytes(), transport.gif);
        if (scenario == 'skip-legacy') {
          await _verifyOfflineExport(root, path, transport.gif);
        }
        return;
      }
      if (scenario == 'offline') {
        expect(
          await File('${root.path}/data/pokemon/species/bulbasaur.json')
              .exists(),
          isTrue,
        );
        expect(await existingMedia.exists(), isFalse);
        expect(result.warnings.join(' '), contains('GIF'));
        return;
      }
      expect(await File('${root.path}/$path').readAsBytes(), transport.gif);
      await adapter.close();
      transport.offline = true;
      final calls = transport.calls;
      final reopenedMaps = LocalMapWorkspaceAdapter();
      await reopenedMaps.loadCatalog(session);
      adapter = LocalPokemonWorkspaceAdapter(
        session: session,
        mapAdapter: reopenedMaps,
        externalSource: const PokemonExternalSourceFixture(
          networkFailure: true,
        ),
        gen5Source: AveluneGen5BattleSource(
          client: MissingGen5Transport(),
          release: 'test',
        ),
        gifSource: AveluneBattleGifSource(client: transport, release: 'test'),
      );
      final index = await adapter.loadIndex();
      final bundle = await adapter.loadSpecies(
        index.entries.firstWhere((entry) => entry.id == 'bulbasaur'),
      );
      final variant =
          (bundle.media!.document!['variants'] as Map)['base'] as Map;
      for (final role in [
        'frontAnimated',
        'backAnimated',
        'frontShinyAnimated',
        'backShinyAnimated',
      ]) {
        expect(
          variant[role],
          scenario == 'partial' && role == 'backAnimated' ? null : path,
        );
      }
      expect(
        await const LocalProjectFileReader().readBytes(
          projectRoot: root.path,
          relativePath: path,
        ),
        transport.gif,
      );
      expect(transport.calls, calls);
    });
  }
}

Future<void> _verifyOfflineExport(
  Directory root,
  String path,
  List<int> gif,
) async {
  final species = File('${root.path}/data/pokemon/species/bulbasaur.json');
  final simplified =
      jsonDecode(await species.readAsString()) as Map<String, dynamic>;
  simplified['typing'] = {
    'types': ['normal'],
  };
  simplified['abilities'] = {'primary': 'calm'};
  (simplified['progression'] as Map)['growthRateId'] = 'steady';
  await species.writeAsString(jsonEncode(simplified));
  await File('${root.path}/data/pokemon/learnsets/bulbasaur.json')
      .writeAsString(
        jsonEncode(const PokemonLearnsetFile(speciesId: 'bulbasaur').toJson()),
      );
  await File('${root.path}/data/pokemon/evolutions/bulbasaur.json')
      .writeAsString(
        jsonEncode(const PokemonEvolutionFile(speciesId: 'bulbasaur').toJson()),
      );
  final items = File('${root.path}/data/pokemon/catalogs/items.json');
  await items.parent.create(recursive: true);
  await items.writeAsString(
    jsonEncode(
      encodeProjectItemCatalog(
        const ProjectItemCatalog(schemaVersion: 1, entries: []),
      ),
    ),
  );
  final hero = await File('${root.path}/assets/hero.png').readAsBytes();
  await File('${root.path}/assets/chosen.png').writeAsBytes(hero);
  await File('${root.path}/assets/alternative.png').writeAsBytes(hero);
  final media = File('${root.path}/data/pokemon/media/bulbasaur.json');
  final mediaDocument = jsonDecode(await media.readAsString()) as Map;
  final variants = mediaDocument['variants'] as Map;
  variants.remove('alternative');
  (variants['base'] as Map)['backStatic'] = 'assets/chosen.png';
  await media.writeAsString(jsonEncode(mediaDocument));
  final exported = await HttpOverrides.runZoned(
    () => const CanonicalGamePackageExportService().build(
      projectRoot: root,
      profile: GamePackageExportProfile(
        gameId: 'games.example.gif',
        gameVersion: '0.1.0',
        title: 'GIF',
        authorName: 'Test',
        defaultLocale: 'fr',
        supportedLocales: ['fr'],
      ),
      mode: GamePackageExportMode.localTest,
    ),
    createHttpClient: (_) => throw StateError('Network disabled'),
  );
  final archive = ZipDecoder().decodeBytes(exported.packageBytes, verify: true);
  expect(archive.findFile('project/$path')?.content, gif);
  final runtimeRoot = Directory('${root.path}/offline-runtime');
  for (final entry in archive.files.where(
    (entry) => entry.isFile && entry.name.startsWith('project/'),
  )) {
    final relative = entry.name.substring('project/'.length);
    expect(relative.split('/'), isNot(contains('..')));
    final file = File('${runtimeRoot.path}/$relative');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(entry.content as List<int>);
  }
  final manifest = await loadProjectManifestFromFile(
    '${runtimeRoot.path}/project.json',
  );
  final resolver = BattlePokemonSpriteResolver(
    manifest: manifest,
    projectRootDirectory: runtimeRoot.path,
  );
  final result = await HttpOverrides.runZoned(
    () => resolver.resolve(speciesId: 'bulbasaur', isPlayerSide: false),
    createHttpClient: (_) => throw StateError('Network disabled'),
  );
  expect(result.explicitAnimatedImageAbsolutePath, '${runtimeRoot.path}/$path');
  expect(
    await File(result.explicitAnimatedImageAbsolutePath!).readAsBytes(),
    gif,
  );
}
