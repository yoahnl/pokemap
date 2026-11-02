import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/pokemon/data/local_pokemon_workspace_adapter.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_external_import_models.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

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
          'schemaVersion': scenario == 'legacy' ? 1 : 2,
          'speciesId': 'bulbasaur',
          'defaultFormId': 'base',
          'vendorExtension': {'keep': true},
          'variants': {
            'base': {
              'frontAnimated': 'assets/chosen.gif',
              'frontStatic': 'assets/chosen.png',
            },
            'alternative': {'frontStatic': 'assets/alternative.png'},
          },
        }),
      );
      if (scenario == 'existing' || scenario == 'legacy') {
        await existingMedia.parent.create(recursive: true);
        await existingMedia.writeAsBytes(originalMedia);
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
        PokemonExternalConflictPolicy.failOnConflict,
      );
      expect(
        result.gifImported,
        scenario == 'normal' || scenario == 'existing' || scenario == 'partial',
      );
      final path =
          'assets/pokemon/battle-gifs/${sha256.convert(transport.gif)}.gif';
      if (scenario == 'legacy') {
        expect(await existingMedia.readAsBytes(), originalMedia);
        expect(await File('${root.path}/$path').exists(), isFalse);
        return;
      }
      if (scenario == 'existing') {
        final media = jsonDecode(await existingMedia.readAsString()) as Map;
        expect(media['vendorExtension'], {'keep': true});
        expect(media['variants']['base']['frontAnimated'], 'assets/chosen.gif');
        expect(media['variants']['base']['frontStatic'], 'assets/chosen.png');
        expect(media['variants']['base']['backAnimated'], path);
        expect(media['variants']['base']['frontShinyAnimated'], path);
        expect(media['variants']['base']['backShinyAnimated'], path);
        expect(
          media['variants']['alternative']['frontStatic'],
          'assets/alternative.png',
        );
        expect(await File('${root.path}/$path').readAsBytes(), transport.gif);
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
