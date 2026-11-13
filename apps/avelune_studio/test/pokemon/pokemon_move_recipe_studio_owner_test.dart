import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/pokemon/data/http_pokemon_external_transport.dart';
import 'package:avelune_studio/features/pokemon/data/pokemon_move_recipe_import.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
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
      await setup.importer.close();
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
      setup.importer = await PokemonMoveRecipeImport.open(
        session: ProjectSession(
          sessionId: 'recipe-test',
          name: 'Recipe test',
          directoryPath: setup.root.path,
          storage: ProjectSessionStorage.workingCatalog,
        ),
        mapAdapter: LocalMapWorkspaceAdapter(),
        media: AvelunePokemonMediaSource(
          client: liveRelease == null
              ? BundleRecipeOwnerTransport('surf', recipe, resources)
              : HttpPokemonExternalTransport(httpClient),
          release: liveRelease ?? 'test',
        ),
      );
      final choices = await setup.importer.listForMove('surf');
      expect(choices, hasLength(1));
      expect(await setup.importer.importChoice('surf', choices.single), isTrue);
      httpClient.close();
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
            '${setup.root.path}/runtime-copy',
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

}
