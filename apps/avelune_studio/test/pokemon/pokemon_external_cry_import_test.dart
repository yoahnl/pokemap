import 'dart:convert';
import 'dart:io';

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
import 'pokemon_external_cry_import_support.dart';

void main() {
  for (final scenario in [
    'normal',
    'mp3',
    'existing',
    'legacy',
    'offline',
    'corrupt',
    'skip-existing',
    'shared',
    'form',
  ]) {
    test('Studio imports a cry with $scenario media', () async {
      final parent = Directory(
        Platform.environment['AVELUNE_QA_ROOT'] ??
            '${Platform.environment['HOME']}/Library/Caches/AveluneQA',
      );
      await parent.create(recursive: true);
      final root = await parent.createTemp('studio-cry-');
      addTearDown(() => root.delete(recursive: true));
      final files = spatialFeaturePayload('companion');
      final manifest = ProjectManifest.fromJson(
        jsonDecode(utf8.decode(files['project/project.json']!))
            as Map<String, dynamic>,
      );
      final store = await CatalogStorageStore.open(projectRoot: root.path);
      final working = await WorkingProjectCatalog.create(
        store: store,
        projectId: 'studio-cry',
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
        sessionId: 'studio-cry',
        name: 'Cry',
        directoryPath: root.path,
        storage: ProjectSessionStorage.workingCatalog,
      );
      final media = File('${root.path}/data/pokemon/media/bulbasaur.json');
      final old = utf8.encode(
        jsonEncode({
          'schemaVersion': 1,
          'speciesId': 'bulbasaur',
          'defaultFormId': 'base',
          'vendorExtension': {'keep': true},
          'variants': {
            'base': {
              'frontStatic': scenario == 'normal'
                  ? 'assets/hero.png'
                  : 'assets/chosen.png',
              if (scenario == 'normal') 'backStatic': 'assets/hero.png',
              if (scenario == 'existing') 'cry': 'assets/chosen.wav',
            },
          },
        }),
      );
      if (scenario == 'existing' ||
          scenario == 'legacy' ||
          scenario == 'normal' ||
          scenario == 'shared') {
        await media.parent.create(recursive: true);
        await media.writeAsBytes(old);
      }
      if (scenario == 'shared') {
        final other = jsonDecode(
          utf8.decode(files['project/data/pokemon/species/bronze-bird.json']!),
        ) as Map<String, dynamic>;
        other['id'] = 'shared-owner';
        other['slug'] = 'shared-owner';
        (other['refs'] as Map)['media'] = 'bulbasaur';
        await File('${root.path}/data/pokemon/species/shared-owner.json')
            .writeAsString(jsonEncode(other));
      }
      final wav = await File(
        '../../packages/map_runtime/assets/audio/overworld/jump.wav',
      ).readAsBytes();
      final mp3 = await File(
        '../../packages/map_runtime/assets/audio/battle/se/stat_fall_down.mp3',
      ).readAsBytes();
      final transport = CryTransport(wav, mp3, scenario);
      final maps = LocalMapWorkspaceAdapter();
      await maps.loadCatalog(session);
      var adapter = LocalPokemonWorkspaceAdapter(
        session: session,
        mapAdapter: maps,
        externalSource: scenario == 'form'
            ? const FormSourceFixture()
            : const PokemonExternalSourceFixture(),
        crySource: AvelunePokemonCrySource(
          media: AvelunePokemonMediaSource(
            client: transport,
            release: 'fixture',
          ),
        ),
      );
      addTearDown(() => adapter.close());
      if (scenario == 'skip-existing') {
        transport.offline = true;
        final first = await adapter.previewExternal('bulbasaur');
        final imported = await adapter.applyExternal(
          first,
          PokemonExternalConflictPolicy.failOnConflict,
        );
        expect(imported.cryImported, isFalse);
        transport.offline = false;
      }
      final species = File('${root.path}/data/pokemon/species/bulbasaur.json');
      final beforeSpecies = await species.exists()
          ? await species.readAsBytes()
          : null;
      final preview = await adapter.previewExternal('bulbasaur');
      final result = await adapter.applyExternal(
        preview,
        scenario == 'skip-existing'
            ? PokemonExternalConflictPolicy.skipExisting
            : PokemonExternalConflictPolicy.failOnConflict,
      );
      if (scenario == 'skip-existing') {
        expect(await species.readAsBytes(), beforeSpecies);
      }
      if (scenario == 'offline' || scenario == 'corrupt') {
        expect(result.cryImported, isFalse);
        expect(result.warnings.join(' '), contains('cri'));
        expect(await media.exists(), isFalse);
        return;
      }
      if (scenario == 'existing' || scenario == 'shared') {
        expect(result.cryImported, isFalse);
        expect(await media.readAsBytes(), old);
        return;
      }
      expect(result.cryImported, isTrue);
      expect(result.warnings, contains('Cri importé.'));
      final sound = scenario == 'mp3' ? mp3 : wav;
      final ext = scenario == 'mp3' ? 'mp3' : 'wav';
      final path = 'assets/pokemon/battle-cries/${sha256.convert(sound)}.$ext';
      final document = jsonDecode(await media.readAsString()) as Map;
      expect(document['variants']['base']['cry'], path);
      if (scenario == 'legacy') {
        expect(document['schemaVersion'], 1);
        expect(document['vendorExtension'], {'keep': true});
        expect(
          document['variants']['base']['frontStatic'],
          'assets/chosen.png',
        );
      }
      expect(await File('${root.path}/$path').readAsBytes(), sound);
      await adapter.close();
      transport.offline = true;
      final calls = transport.calls;
      final reopened = LocalMapWorkspaceAdapter();
      await reopened.loadCatalog(session);
      adapter = LocalPokemonWorkspaceAdapter(
        session: session,
        mapAdapter: reopened,
        externalSource: const PokemonExternalSourceFixture(
          networkFailure: true,
        ),
        crySource: AvelunePokemonCrySource(
          media: AvelunePokemonMediaSource(
            client: transport,
            release: 'fixture',
          ),
        ),
      );
      await adapter.loadIndex();
      expect(await File('${root.path}/$path').readAsBytes(), sound);
      expect(transport.calls, calls);
      if (scenario == 'normal') {
        final species = File(
          '${root.path}/data/pokemon/species/bulbasaur.json',
        );
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
              jsonEncode(
                const PokemonLearnsetFile(speciesId: 'bulbasaur').toJson(),
              ),
            );
        await File('${root.path}/data/pokemon/evolutions/bulbasaur.json')
            .writeAsString(
              jsonEncode(
                const PokemonEvolutionFile(speciesId: 'bulbasaur').toJson(),
              ),
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
          () => const CanonicalGamePackageExportService()
              .build(
                projectRoot: root,
                profile: GamePackageExportProfile(
                  gameId: 'games.example.cry',
                  gameVersion: '0.1.0',
                  title: 'Cry',
                  authorName: 'Test',
                  defaultLocale: 'fr',
                  supportedLocales: ['fr'],
                ),
                mode: GamePackageExportMode.localTest,
              )
              .catchError((Object error) {
                if (error is GamePackageExportException) {
                  throw StateError(
                    'Export ${error.code}: ${error.cause}; ${error.gameplayReadinessReport?.diagnostics.map((d) => '${d.code}: ${d.message}').toList()}',
                  );
                }
                throw error;
              }),
          createHttpClient: (_) => throw StateError('Network disabled'),
        );
        final archive = ZipDecoder().decodeBytes(
          exported.packageBytes,
          verify: true,
        );
        final packaged = archive.findFile('project/$path');
        expect(packaged, isNotNull);
        expect(packaged!.content, sound);
        final packagedMedia = jsonDecode(
          utf8.decode(
            archive
                    .findFile('project/data/pokemon/media/bulbasaur.json')!
                    .content
                as List<int>,
          ),
        );
        expect(packagedMedia['variants']['base']['cry'], path);
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
        final installedProject = await loadProjectManifestFromFile(
          '${runtimeRoot.path}/project.json',
        );
        final resolver = BattlePokemonSpriteResolver(
          manifest: installedProject,
          projectRootDirectory: runtimeRoot.path,
        );
        final resolved = await resolver.resolveCry(
          'bulbasaur',
          requireExisting: true,
        );
        expect(resolved, '${runtimeRoot.path}/$path');
        expect(await File(resolved!).readAsBytes(), sound);
        expect(transport.calls, calls);
      }
    });
  }
}
