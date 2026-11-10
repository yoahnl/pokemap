import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/pokemon/data/local_pokemon_workspace_adapter.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_external_import_models.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_workspace_models.dart';
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

import '../../../../packages/map_distribution/test/support/spatial_feature_capabilities_fixture.dart';
import '../support/pokemon_external_source_fixture.dart';

final class _PngTransport implements PokemonBoundedExternalHttpTransport {
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
      'sha256': sha256.convert(id == 'icon' ? iconBytes : id == 'shiny-atlas' ? shinyBytes : bytes).toString(),
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

final class _NoGen5 implements PokemonBoundedExternalHttpTransport {
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
  test('preview retains available PNGs when existing files are kept', () async {
    final transport = _PngTransport();
    final selection = await AvelunePokemonPngSource(
      media: AvelunePokemonMediaSource(client: transport, release: 'test'),
    ).fetch(speciesId: 'bulbasaur', formId: 'bulbasaur');
    final document = {'id': 'bulbasaur', 'refs': <String, String>{}};
    final preview = PokemonExternalImportPreview(
      speciesId: 'bulbasaur',
      name: 'Bulbizarre',
      projectRevision: 'r',
      inventorySignature: '',
      warnings: const [],
      documents: [
        PokemonExternalDocument(
          family: PokemonDocumentFamily.species,
          relativePath: 'species/bulbasaur.json',
          beforeBytes: utf8.encode(jsonEncode(document)),
          document: document,
        ),
      ],
      pngSelection: selection,
    );
    final plan = preview.plan(PokemonExternalConflictPolicy.skipExisting);
    expect(plan.selected, isEmpty);
    expect(plan.kept, 1);
    expect(preview.pngSelection!.media, hasLength(5));
    expect(preview.pngSelection, same(selection));
  });

  for (final scenario in [
    'normal',
    'existing',
    'legacy',
    'keep',
    'shared',
    'dex',
    'form',
    'offline',
    'corrupt',
  ]) {
    test('Studio imports PNGs safely: $scenario', () async {
      final parent = Directory(
        Platform.environment['AVELUNE_QA_ROOT'] ?? '/Users/karim/Library/Caches/AveluneQA/studio-t01-retirement-20261109',
      );
      await parent.create(recursive: true);
      final root = await parent.createTemp('studio-png-');
      addTearDown(() => root.delete(recursive: true));
      final files = spatialFeaturePayload('companion');
      final manifest = ProjectManifest.fromJson(
        jsonDecode(utf8.decode(files['project/project.json']!))
            as Map<String, dynamic>,
      );
      final store = await CatalogStorageStore.open(projectRoot: root.path);
      final working = await WorkingProjectCatalog.create(
        store: store,
        projectId: 'studio-png',
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
        sessionId: 'studio-png',
        name: 'PNG',
        directoryPath: root.path,
        storage: ProjectSessionStorage.workingCatalog,
      );
      final maps = LocalMapWorkspaceAdapter();
      await maps.loadCatalog(session);
      final transport = _PngTransport();
      final adapter = LocalPokemonWorkspaceAdapter(
        session: session,
        mapAdapter: maps,
        externalSource: const PokemonExternalSourceFixture(),
        gen5Source: AveluneGen5BattleSource(client: _NoGen5(), release: 'test'),
        pngSource: AvelunePokemonPngSource(
          media: AvelunePokemonMediaSource(client: transport, release: 'test'),
        ),
      );
      addTearDown(adapter.close);
      final mediaFile = File('${root.path}/data/pokemon/media/bulbasaur.json');
      final isKept = const {'keep', 'shared', 'dex', 'form'}.contains(scenario);
      if (isKept) {
        transport.offline = true;
        final first = await adapter.previewExternal('bulbasaur');
        await adapter.applyExternal(
          first,
          PokemonExternalConflictPolicy.failOnConflict,
        );
        transport.offline = false;
      }
      if (scenario == 'existing' || scenario == 'legacy' || isKept) {
        await mediaFile.parent.create(recursive: true);
        await mediaFile.writeAsString(
          jsonEncode({
            'schemaVersion': scenario == 'legacy' ? 1 : 2,
            'speciesId': 'bulbasaur',
            'defaultFormId': 'base',
            'vendorExtension': {'keep': true},
            'variants': {
              'base': {'icon': 'assets/custom.png'},
            },
          }),
        );
      }
      if (scenario == 'shared') {
        final other = jsonDecode(
          utf8.decode(files['project/data/pokemon/species/bronze-bird.json']!),
        ) as Map;
        other['id'] = 'shared-owner';
        other['slug'] = 'shared-owner';
        (other['refs'] as Map)['media'] = 'bulbasaur';
        await File('${root.path}/data/pokemon/species/shared-owner.json')
            .writeAsString(jsonEncode(other));
      }
      if (scenario == 'dex' || scenario == 'form') {
        final file = File('${root.path}/data/pokemon/species/bulbasaur.json');
        final doc = jsonDecode(await file.readAsString()) as Map;
        if (scenario == 'dex') doc['nationalDex'] = 2;
        if (scenario == 'form') (doc['forms'] as Map)['isBaseForm'] = false;
        await file.writeAsString(jsonEncode(doc));
      }
      if (scenario == 'offline') transport.offline = true;
      if (scenario == 'corrupt') transport.corrupt = true;
      final before = await mediaFile.exists()
          ? await mediaFile.readAsBytes()
          : null;
      final preview = await adapter.previewExternal('bulbasaur');
      final result = await adapter.applyExternal(
        preview,
        isKept
            ? PokemonExternalConflictPolicy.skipExisting
            : PokemonExternalConflictPolicy.failOnConflict,
      );
      if (const {'offline', 'corrupt'}.contains(scenario)) {
        expect(result.warnings.join(' '), contains('images'));
        expect(await mediaFile.exists(), isFalse);
        return;
      }
      if (const {'shared', 'dex', 'form'}.contains(scenario)) {
        expect(await mediaFile.readAsBytes(), before);
        return;
      }
      expect(
        await mediaFile.exists(),
        isTrue,
        reason: result.warnings.join(' '),
      );
      final media = jsonDecode(await mediaFile.readAsString()) as Map;
      expect(media['schemaVersion'], scenario == 'legacy' ? 1 : 2);
      final variant = media['variants']['base'] as Map;
      final path =
          'assets/pokemon/images/${sha256.convert(transport.bytes)}.png';
      final iconPath =
          'assets/pokemon/images/${sha256.convert(transport.iconBytes)}.png';
      final shinyPath =
          'assets/pokemon/images/${sha256.convert(transport.shinyBytes)}.png';
      expect(variant['frontStatic'], path);
      expect(variant['backStatic'], path);
      expect(variant['overworld'], path);
      expect(variant['overworldShiny'], shinyPath);
      expect(
        variant['icon'],
        scenario == 'normal' ? iconPath : 'assets/custom.png',
      );
      if (scenario != 'normal') {
        expect(media['vendorExtension'], {'keep': true});
      }
      expect(await File('${root.path}/$path').readAsBytes(), transport.bytes);
      if (scenario == 'normal') {
        await _verifyOfflineExport(
          root,
          path,
          transport.bytes,
          iconPath,
          transport.iconBytes,
          shinyPath,
          transport.shinyBytes,
        );
      }
    });
  }
}

Future<void> _verifyOfflineExport(
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
    () => follower.resolve(const PlayerPokemon(
      speciesId: 'bulbasaur',
      formId: 'base',
      natureId: 'hardy',
      abilityId: 'calm',
      isShiny: true,
    )),
    createHttpClient: (_) => throw StateError('Network disabled'),
  );
  expect(shinyFollower, '${runtimeRoot.path}/$shinyPath');
}
