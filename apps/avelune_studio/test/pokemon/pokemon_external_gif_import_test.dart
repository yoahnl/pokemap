import 'dart:convert';
import 'dart:io';

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
import 'pokemon_external_gif_import_support.dart';

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
          await verifyGifOfflineExport(root, path, transport.gif);
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
