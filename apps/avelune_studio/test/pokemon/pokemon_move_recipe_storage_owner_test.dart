import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/pokemon/data/pokemon_move_recipe_import.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/presentation/flame/battle_offline_move_recipe_loader.dart';

import '../../../../packages/map_distribution/test/support/spatial_feature_capabilities_fixture.dart';
import '../support/pokemon_move_recipe_owner_fixture.dart';
import '../support/pokemon_move_recipe_transport_owner_fixture.dart';

void main() {
  late PokemonMoveRecipeOwnerSetup setup;
  setUp(() async => setup = await PokemonMoveRecipeOwnerSetup.create());
  tearDown(() => setup.dispose());

  test(
    'reimports a valid WAV larger than the particle-definition limit',
    () async {
      await setup.importer.close();
      setup.transport = RecipeOwnerTransport(
        setup.transport.particle,
        setup.transport.texture,
        sound: largeRecipeWav(),
      );
      setup.importer = await PokemonMoveRecipeImport.open(
        session: ProjectSession(
          sessionId: 'recipe-audio',
          name: 'Recipe test',
          directoryPath: setup.root.path,
          storage: ProjectSessionStorage.workingCatalog,
        ),
        mapAdapter: LocalMapWorkspaceAdapter(),
        media: AvelunePokemonMediaSource(
          client: setup.transport,
          release: 'test',
        ),
        reader: setup.reader,
      );
      final choice = (await setup.importer.listForMove('flamethrower')).single;
      expect(await setup.importer.importChoice('flamethrower', choice), isTrue);
      expect(
        await setup.importer.importChoice('flamethrower', choice),
        isFalse,
      );
    },
  );

  test('rejects oversized stored audio without changing its binding', () async {
    await setup.importer.close();
    final sound = largeRecipeWav();
    setup.transport = RecipeOwnerTransport(
      setup.transport.particle,
      setup.transport.texture,
      sound: sound,
    );
    setup.importer = await PokemonMoveRecipeImport.open(
      session: ProjectSession(
        sessionId: 'recipe-oversized-audio',
        name: 'Recipe test',
        directoryPath: setup.root.path,
        storage: ProjectSessionStorage.workingCatalog,
      ),
      mapAdapter: LocalMapWorkspaceAdapter(),
      media: AvelunePokemonMediaSource(
        client: setup.transport,
        release: 'test',
      ),
      reader: setup.reader,
    );
    final choice = (await setup.importer.listForMove('flamethrower')).single;
    expect(await setup.importer.importChoice('flamethrower', choice), isTrue);
    final binding = File(
      '${setup.root.path}/${battleRecipeBindingPath('flamethrower')}',
    );
    final originalBinding = await binding.readAsBytes();
    final audio = File(
      '${setup.root.path}/${battleRecipeBlobPath(sha256.convert(sound).toString(), 'audio/wav', projectMoveId: 'flamethrower')}',
    );
    final writer = await audio.open(mode: FileMode.append);
    try {
      await writer.truncate(8 * 1024 * 1024 + 1);
    } finally {
      await writer.close();
    }
    await expectLater(
      setup.importer.importChoice('flamethrower', choice),
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
      final choice = (await setup.importer.listForMove('flamethrower')).single;
      expect(await setup.importer.importChoice('flamethrower', choice), isTrue);
      final file = File(
        '${setup.root.path}/${battleRecipeBindingPath('flamethrower')}',
      );
      final original = await file.readAsBytes();
      setup.transport.recipe = [...setup.transport.recipe, 32];
      final replacement = (await setup.importer.listForMove('flamethrower'))
          .single;
      await expectLater(
        setup.importer.importChoice('flamethrower', replacement),
        throwsA(isA<Exception>()),
      );
      expect(await file.readAsBytes(), original);
    },
  );

  test(
    'exports the imported recipe and keeps the offline Player fallback',
    () async {
      final choice = (await setup.importer.listForMove('flamethrower')).single;
      await setup.importer.importChoice('flamethrower', choice);
      final fixture = spatialFeaturePayload('companion');
      final map = MapData.fromJson(
        jsonDecode(utf8.decode(fixture['project/maps/map.json']!)),
      );
      for (var i = 0; i < 40; i++) {
        await File('${setup.root.path}/maps/foreign-$i.json').writeAsString(
          jsonEncode(map.copyWith(id: 'foreign-$i', name: 'Foreign').toJson()),
        );
      }
      final items = File('${setup.root.path}/data/pokemon/catalogs/items.json');
      await items.parent.create(recursive: true);
      await items.writeAsString(
        jsonEncode(
          encodeProjectItemCatalog(
            const ProjectItemCatalog(schemaVersion: 1, entries: []),
          ),
        ),
      );
      final exported = await const CanonicalGamePackageExportService().build(
        projectRoot: setup.root,
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
      final runtime = await Directory('${setup.root.path}/runtime-copy')
          .create();
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
}
