import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart' show loadProjectManifestFromFile;
import 'package:map_runtime/src/presentation/flame/battle_pokemon_sprite_resolver.dart';

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

Future<void> verifyGifOfflineExport(
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
