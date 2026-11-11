import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/pokemon/data/pokemon_move_recipe_import.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:image/image.dart' as image;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

import '../../../../packages/map_distribution/test/support/spatial_feature_capabilities_fixture.dart';
import 'pokemon_move_recipe_transport_owner_fixture.dart';

final class PokemonMoveRecipeOwnerSetup {
  PokemonMoveRecipeOwnerSetup._(
    this.root,
    this.transport,
    this.reader,
    this.importer,
  );

  final Directory root;
  RecipeOwnerTransport transport;
  final CountingRecipeReader reader;
  PokemonMoveRecipeImport importer;

  static Future<PokemonMoveRecipeOwnerSetup> create() async {
    late Directory root;
    late PokemonMoveRecipeImport importer;
    late RecipeOwnerTransport transport;
    late CountingRecipeReader reader;
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
    transport = RecipeOwnerTransport(particle, png);
    reader = CountingRecipeReader();
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
    return PokemonMoveRecipeOwnerSetup._(root, transport, reader, importer);
  }

  Future<void> dispose() async {
    await importer.close();
    if (await root.exists()) await root.delete(recursive: true);
  }
}
