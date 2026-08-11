import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/use_cases/load_pokemon_items_catalog_use_case.dart';
import 'package:map_editor/src/application/use_cases/project_management_use_cases.dart';
import 'package:map_editor/src/infrastructure/filesystem/project_filesystem.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;
  late ProjectFileSystem workspace;
  late LoadPokemonItemsCatalogUseCase loader;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('strict-items-loader-');
    workspace = ProjectFileSystem(root.path);
    loader = const LoadPokemonItemsCatalogUseCase();
    await CreateProjectUseCase(
      FileProjectRepository(),
      const FileProjectWorkspaceFactory(),
    ).execute('Strict Item Catalog', root.path);
  });

  tearDown(() => root.delete(recursive: true));

  test('loads, sorts, and exposes the strict canonical catalog', () async {
    final catalog = ProjectItemCatalog(
      schemaVersion: 1,
      entries: [
        ProjectItemDefinition(
          id: 'zeta',
          displayName: 'Zeta',
          pocketId: 'items',
        ),
        ProjectItemDefinition(
          id: 'alpha',
          displayName: 'Alpha',
          pocketId: 'items',
          buyPrice: 100,
        ),
      ],
    ).normalized();
    await _writeCatalog(root, encodeProjectItemCatalog(catalog));

    final result = await loader.execute(workspace);

    expect(result.loadState, PokemonItemsCatalogLoadState.ready);
    expect(result.canonicalCatalog, catalog);
    expect(result.entries.map((entry) => entry.id), ['alpha', 'zeta']);
  });

  test('returns missingCatalog when the strict file is absent', () async {
    final result = await loader.execute(workspace);

    expect(result.loadState, PokemonItemsCatalogLoadState.missingCatalog);
    expect(result.canonicalCatalog, isNull);
  });

  test('rejects invalid JSON and duplicate canonical ids', () async {
    final file = File(
      p.join(root.path, 'data', 'pokemon', 'catalogs', 'items.json'),
    );
    await file.create(recursive: true);
    await file.writeAsString('{ invalid');

    expect(
      (await loader.execute(workspace)).loadState,
      PokemonItemsCatalogLoadState.loadError,
    );

    await _writeCatalog(root, {
      'schemaVersion': 1,
      'entries': [_entry('duplicate'), _entry('duplicate')],
    });
    final duplicate = await loader.execute(workspace);

    expect(duplicate.loadState, PokemonItemsCatalogLoadState.loadError);
    expect(duplicate.message, contains('Duplicate'));
  });

  test(
    'rejects a PokeAPI-shaped local file without compatibility parsing',
    () async {
      await _writeCatalog(root, {
        'catalog': 'items',
        'entries': [
          {
            'id': 'poke-ball',
            'name': 'Poké Ball',
            'category': {'name': 'standard-balls'},
            'effect_entries': [
              {'effect': 'Catches a Pokémon.'},
            ],
          },
        ],
      });

      final result = await loader.execute(workspace);

      expect(result.loadState, PokemonItemsCatalogLoadState.loadError);
      expect(result.canonicalCatalog, isNull);
    },
  );

  test('resolves the configured strict catalog path', () async {
    final manifestFile = File(workspace.projectManifestPath);
    final manifest = ProjectManifest.fromJson(
      jsonDecode(await manifestFile.readAsString()) as Map<String, dynamic>,
    );
    await manifestFile.writeAsString(
      jsonEncode(
        manifest
            .copyWith(
              pokemon: manifest.pokemon.copyWith(
                catalogFiles: const {'items': 'custom/items.json'},
              ),
            )
            .toJson(),
      ),
    );
    final customFile = File(p.join(root.path, 'custom', 'items.json'));
    await customFile.create(recursive: true);
    await customFile.writeAsString(
      jsonEncode(
        encodeProjectItemCatalog(
          ProjectItemCatalog(
            schemaVersion: 1,
            entries: [_item('custom-item')],
          ).normalized(),
        ),
      ),
    );

    final result = await loader.execute(workspace);

    expect(result.loadState, PokemonItemsCatalogLoadState.ready);
    expect(result.catalogRelativePath, 'custom/items.json');
    expect(result.canonicalCatalog?.entries.single.id, 'custom-item');
  });
}

ProjectItemDefinition _item(String id) {
  return ProjectItemDefinition(
    id: id,
    displayName: id,
    pocketId: 'items',
    buyPrice: 100,
  );
}

Map<String, Object?> _entry(String id) {
  return {'id': id, 'displayName': id, 'pocketId': 'items', 'buyPrice': 100};
}

Future<void> _writeCatalog(Directory root, Map<String, Object?> json) async {
  final file = File(
    p.join(root.path, 'data', 'pokemon', 'catalogs', 'items.json'),
  );
  await file.create(recursive: true);
  await file.writeAsString(jsonEncode(json));
}
