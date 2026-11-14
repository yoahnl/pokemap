import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart'
    show loadProjectManifestFromFile, RuntimePokemonMediaIdentity;
import 'package:map_runtime/src/player/runtime_pokemon_summary_media_resolver.dart';
import 'package:map_runtime/src/player/runtime_pokemon_overworld_resolver.dart';
import 'package:map_runtime/src/presentation/flame/battle_pokemon_sprite_resolver.dart';

final class PngTransport implements PokemonBoundedExternalHttpTransport {
  final bytes = Uint8List.fromList(
    image.encodePng(image.Image(width: 128, height: 128)),
  );
  final iconBytes = Uint8List.fromList(
    image.encodePng(
      image.Image(width: 32, height: 32)..setPixelRgba(0, 0, 255, 0, 0, 255),
    ),
  );
  final shinyBytes = Uint8List.fromList(
    image.encodePng(
      image.Image(width: 128, height: 128)..setPixelRgba(0, 0, 0, 0, 255, 255),
    ),
  );
  bool offline = false;
  bool corrupt = false;

  @override
  Future<PokemonExternalHttpResponse> getBounded(
    Uri uri, {
    required Map<String, String> headers,
    required int maximumBytes,
    required Duration timeout,
  }) async {
    if (offline) throw const SocketException('offline');
    final list = uri.path.contains('/owners/pokemon/');
    Map<String, Object?> entry(
      String id,
      String usage,
      String style,
      Map<String, Object?> extra,
    ) => {
      'id': id,
      'sha256': sha256
          .convert(
            id == 'icon'
                ? iconBytes
                : id == 'shiny-atlas'
                ? shinyBytes
                : bytes,
          )
          .toString(),
      'contentType': 'image/png',
      'usage': usage,
      'representation': 'sprite2d',
      'style': style,
      'metadata': {'formId': 'bulbasaur', ...extra},
    };
    final data = list
        ? Uint8List.fromList(
            utf8.encode(
              jsonEncode([
                entry('front', 'battle', 'gen5', {'view': 'front'}),
                entry('back', 'battle', 'gen5', {'view': 'back'}),
                entry('icon', 'menu', 'gen5', {}),
                entry('atlas', 'overworld', 'hgss-inspired', {
                  'variant': 'regular',
                  'atlas': {
                    'rows': 4,
                    'columns': 4,
                    'tileWidth': 32,
                    'tileHeight': 32,
                  },
                }),
                entry('shiny-atlas', 'overworld', 'hgss-inspired', {
                  'variant': 'shiny',
                  'atlas': {
                    'rows': 4,
                    'columns': 4,
                    'tileWidth': 32,
                    'tileHeight': 32,
                  },
                }),
              ]),
            ),
          )
        : corrupt
        ? Uint8List.fromList([1, 2, 3])
        : uri.path.endsWith('/icon')
        ? iconBytes
        : uri.path.endsWith('/shiny-atlas')
        ? shinyBytes
        : bytes;
    return PokemonExternalHttpResponse(
      statusCode: 200,
      headers: const {},
      body: list ? utf8.decode(data) : '',
      bodyBytes: data,
    );
  }
}

final class NoGen5Transport implements PokemonBoundedExternalHttpTransport {
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

Future<void> verifyPngOfflineExport(
  Directory root,
  String path,
  List<int> png,
  String iconPath,
  List<int> icon,
  String shinyPath,
  List<int> shiny,
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
  final exported = await HttpOverrides.runZoned(
    () => const CanonicalGamePackageExportService().build(
      projectRoot: root,
      profile: GamePackageExportProfile(
        gameId: 'games.example.png',
        gameVersion: '0.1.0',
        title: 'PNG',
        authorName: 'Test',
        defaultLocale: 'fr',
        supportedLocales: ['fr'],
      ),
      mode: GamePackageExportMode.localTest,
    ),
    createHttpClient: (_) => throw StateError('Network disabled'),
  );
  final archive = ZipDecoder().decodeBytes(exported.packageBytes, verify: true);
  expect(archive.findFile('project/$path')?.content, png);
  expect(archive.findFile('project/$iconPath')?.content, icon);
  expect(archive.findFile('project/$shinyPath')?.content, shiny);
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
  expect(result.explicitImageAbsolutePath, '${runtimeRoot.path}/$path');
  expect(await File(result.explicitImageAbsolutePath!).readAsBytes(), png);
  final menuResolver = RuntimePokemonSummaryMediaResolver(
    projectRootDirectory: runtimeRoot.path,
    pokemonConfig: manifest.pokemon,
  );
  final menu = await HttpOverrides.runZoned(
    () => menuResolver.resolve(
      const RuntimePokemonMediaIdentity(speciesId: 'bulbasaur'),
    ),
    createHttpClient: (_) => throw StateError('Network disabled'),
  );
  expect(menu.thumbnail?.absoluteFilePath, '${runtimeRoot.path}/$iconPath');
  expect(await File(menu.thumbnail!.absoluteFilePath).readAsBytes(), icon);
  final follower = RuntimePokemonOverworldResolver(
    projectRootDirectory: runtimeRoot.path,
    pokemonConfig: manifest.pokemon,
  );
  final shinyFollower = await HttpOverrides.runZoned(
    () => follower.resolve(
      const PlayerPokemon(
        speciesId: 'bulbasaur',
        formId: 'base',
        natureId: 'hardy',
        abilityId: 'calm',
        isShiny: true,
      ),
    ),
    createHttpClient: (_) => throw StateError('Network disabled'),
  );
  expect(shinyFollower, '${runtimeRoot.path}/$shinyPath');
}
