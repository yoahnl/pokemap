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
  late Directory tempProjectRoot;
  late ProjectFileSystem workspace;
  late LoadPokemonItemsCatalogUseCase loadUseCase;

  setUp(() async {
    tempProjectRoot = await Directory.systemTemp.createTemp('items_catalog_8d_');
    workspace = ProjectFileSystem(tempProjectRoot.path);
    loadUseCase = const LoadPokemonItemsCatalogUseCase(
      readRepository: FilePokemonReadRepository(),
    );

    await CreateProjectUseCase(
      FileProjectRepository(),
      const FileProjectWorkspaceFactory(),
    ).execute('Items Catalog Test Project', tempProjectRoot.path);
  });

  tearDown(() async {
    if (await tempProjectRoot.exists()) {
      await tempProjectRoot.delete(recursive: true);
    }
  });

  test('loads local items from the project items catalog', () async {
    await _writeItemsCatalog(
      tempProjectRoot,
      entries: <Map<String, Object?>>[
        <String, Object?>{
          'id': 'poke-ball',
          'name': 'Poké Ball',
          'categoryId': 'standard-balls',
          'pocketId': 'poke-balls',
          'cost': 200,
          'flingPower': 10,
          'flingEffectId': null,
          'effectText': 'Used to catch wild Pokémon.',
          'shortEffectText': 'Catches wild Pokémon.',
          'flavorText': 'A device for catching wild Pokémon.',
          'spriteUrl':
              'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/items/poke-ball.png',
          'localSpritePath': 'data/pokemon/assets/items/poke-ball.png',
        },
      ],
    );

    final result = await loadUseCase.execute(workspace);

    expect(result.loadState, PokemonItemsCatalogLoadState.ready);
    expect(result.entries, hasLength(1));
    final item = result.entries.single;
    expect(item.id, 'poke-ball');
    expect(item.name, 'Poké Ball');
    expect(item.categoryId, 'standard-balls');
    expect(item.pocketId, 'poke-balls');
    expect(item.cost, 200);
    expect(item.flingPower, 10);
    expect(item.flingEffectId, isNull);
    expect(item.effectText, 'Used to catch wild Pokémon.');
    expect(item.shortEffectText, 'Catches wild Pokémon.');
    expect(item.flavorText, 'A device for catching wild Pokémon.');
    expect(
      item.spriteUrl,
      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/items/poke-ball.png',
    );
    expect(item.localSpritePath, 'data/pokemon/assets/items/poke-ball.png');
    expect(result.diagnostics, isEmpty);
  });

  test('returns missingCatalog when the items catalog is missing', () async {
    final result = await loadUseCase.execute(workspace);

    expect(result.loadState, PokemonItemsCatalogLoadState.missingCatalog);
    expect(result.entries, isEmpty);
    expect(result.diagnostics, isEmpty);
    expect(result.catalogRelativePath, 'data/pokemon/catalogs/items.json');
  });

  test('keeps valid items when another catalog entry is invalid', () async {
    await _writeItemsCatalog(
      tempProjectRoot,
      entries: <Map<String, Object?>>[
        <String, Object?>{
          'id': 'potion',
          'name': 'Potion',
        },
        <String, Object?>{
          'id': 'broken-item',
          'name': '',
        },
      ],
    );

    final result = await loadUseCase.execute(workspace);

    expect(result.loadState, PokemonItemsCatalogLoadState.ready);
    expect(result.entries.map((entry) => entry.id), <String>['potion']);
    expect(result.diagnostics, hasLength(1));
    expect(result.diagnostics.single.message, contains('broken-item'));
  });

  test('keeps valid items when another catalog entry is badly typed', () async {
    await _writeItemsCatalog(
      tempProjectRoot,
      entries: <Map<String, Object?>>[
        <String, Object?>{
          'id': 'potion',
          'name': 'Potion',
        },
        <String, Object?>{
          'id': 42,
          'name': 'Broken Item',
          'cost': 'expensive',
        },
      ],
    );

    final result = await loadUseCase.execute(workspace);

    expect(result.loadState, PokemonItemsCatalogLoadState.ready);
    expect(result.entries.map((entry) => entry.id), <String>['potion']);
    expect(result.diagnostics, hasLength(1));
  });

  test('sorts items by display name then id case-insensitively', () async {
    await _writeItemsCatalog(
      tempProjectRoot,
      entries: <Map<String, Object?>>[
        <String, Object?>{'id': 'zeta-item', 'name': 'Zeta Item'},
        <String, Object?>{'id': 'alpha-late', 'name': 'Alpha Item'},
        <String, Object?>{'id': 'alpha-early', 'name': 'alpha item'},
      ],
    );

    final result = await loadUseCase.execute(workspace);

    expect(
      result.entries.map((entry) => entry.id).toList(),
      <String>['alpha-early', 'alpha-late', 'zeta-item'],
    );
  });

  test('deduplicates duplicate item ids with a diagnostic', () async {
    await _writeItemsCatalog(
      tempProjectRoot,
      entries: <Map<String, Object?>>[
        <String, Object?>{'id': 'potion', 'name': 'Potion'},
        <String, Object?>{'id': 'potion', 'name': 'Potion Copy'},
      ],
    );

    final result = await loadUseCase.execute(workspace);

    expect(result.entries, hasLength(1));
    expect(result.entries.single.name, 'Potion');
    expect(result.diagnostics, hasLength(1));
    expect(result.diagnostics.single.message, contains('potion'));
  });

  test('parses nullable item fields without crashing', () async {
    await _writeItemsCatalog(
      tempProjectRoot,
      entries: <Map<String, Object?>>[
        <String, Object?>{
          'id': 'mystery-item',
          'name': 'Mystery Item',
          'cost': null,
          'flingPower': null,
          'effectText': null,
        },
      ],
    );

    final result = await loadUseCase.execute(workspace);

    expect(result.loadState, PokemonItemsCatalogLoadState.ready);
    expect(result.entries, hasLength(1));
    final item = result.entries.single;
    expect(item.cost, isNull);
    expect(item.flingPower, isNull);
    expect(item.effectText, isNull);
  });

  test('returns loadError when items catalog json is invalid', () async {
    final file = File(
      p.join(tempProjectRoot.path, 'data', 'pokemon', 'catalogs', 'items.json'),
    );
    await file.create(recursive: true);
    await file.writeAsString('{ invalid json');

    final result = await loadUseCase.execute(workspace);

    expect(result.loadState, PokemonItemsCatalogLoadState.loadError);
    expect(result.entries, isEmpty);
    expect(result.message, isNotEmpty);
  });

  test('resolves the configured items catalog path from pokemon data root',
      () async {
    final manifestFile = File(workspace.projectManifestPath);
    final manifest = ProjectManifest.fromJson(
      jsonDecode(await manifestFile.readAsString()) as Map<String, dynamic>,
    );
    await manifestFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(
        manifest
            .copyWith(
              pokemon: manifest.pokemon.copyWith(
                dataRoot: 'custom/pokemon',
              ),
            )
            .toJson(),
      ),
    );

    final bootstrapManifest = File(
      p.join(
        tempProjectRoot.path,
        'custom',
        'pokemon',
        'pokemon_data_manifest.json',
      ),
    );
    await bootstrapManifest.create(recursive: true);
    await bootstrapManifest.writeAsString(
      const JsonEncoder.withIndent('  ').convert(
        <String, Object?>{
          'schemaVersion': 1,
          'kind': 'pokemon_data_manifest',
          'meta': <String, Object?>{
            'description': 'Custom bootstrap manifest.',
          },
          'catalogFiles': <String, Object?>{
            'items': 'catalogs/project-items.json',
          },
          'futureDataFolders': <String, Object?>{},
        },
      ),
    );

    final result = await loadUseCase.execute(workspace);

    expect(result.loadState, PokemonItemsCatalogLoadState.missingCatalog);
    expect(
      result.catalogRelativePath,
      'custom/pokemon/catalogs/project-items.json',
    );
  });

  test('accepts a PokeAPI-like local item entry shape', () async {
    await _writeItemsCatalog(
      tempProjectRoot,
      entries: <Map<String, Object?>>[
        <String, Object?>{
          'id': 'poke-ball',
          'name': 'poke-ball',
          'names': <String, Object?>{
            'en': 'Poké Ball',
            'fr': 'Poké Ball',
          },
          'category': <String, Object?>{'name': 'standard-balls'},
          'pocket': <String, Object?>{'name': 'poke-balls'},
          'cost': 200,
          'fling_power': 10,
          'fling_effect': null,
          'effect_entries': <Object?>[
            <String, Object?>{
              'language': <String, Object?>{'name': 'en'},
              'effect': 'Used to catch a wild Pokémon.',
              'short_effect': 'Catches wild Pokémon.',
            },
          ],
          'flavor_text_entries': <Object?>[
            <String, Object?>{
              'language': <String, Object?>{'name': 'en'},
              'text': 'A device for catching wild Pokémon.',
            },
          ],
          'sprites': <String, Object?>{
            'default':
                'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/items/poke-ball.png',
          },
        },
      ],
    );

    final result = await loadUseCase.execute(workspace);

    expect(result.loadState, PokemonItemsCatalogLoadState.ready);
    expect(result.entries, hasLength(1));
    final item = result.entries.single;
    expect(item.name, 'Poké Ball');
    expect(item.categoryId, 'standard-balls');
    expect(item.pocketId, 'poke-balls');
    expect(item.cost, 200);
    expect(item.flingPower, 10);
    expect(item.effectText, 'Used to catch a wild Pokémon.');
    expect(item.shortEffectText, 'Catches wild Pokémon.');
    expect(item.flavorText, 'A device for catching wild Pokémon.');
    expect(
      item.spriteUrl,
      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/items/poke-ball.png',
    );
  });

  test(
      'falls back to the configured items catalog path when the bootstrap manifest is invalid',
      () async {
    final manifestFile = File(workspace.projectManifestPath);
    final manifest = ProjectManifest.fromJson(
      jsonDecode(await manifestFile.readAsString()) as Map<String, dynamic>,
    );
    await manifestFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(
        manifest
            .copyWith(
              pokemon: manifest.pokemon.copyWith(
                dataRoot: 'custom/pokemon',
                catalogFiles: <String, String>{
                  ...manifest.pokemon.catalogFiles,
                  'items': 'custom/pokemon/catalogs/project-items.json',
                },
              ),
            )
            .toJson(),
      ),
    );

    final bootstrapManifest = File(
      p.join(
        tempProjectRoot.path,
        'custom',
        'pokemon',
        'pokemon_data_manifest.json',
      ),
    );
    await bootstrapManifest.create(recursive: true);
    await bootstrapManifest.writeAsString('{ invalid json');

    final file = File(
      p.join(
        tempProjectRoot.path,
        'custom',
        'pokemon',
        'catalogs',
        'project-items.json',
      ),
    );
    await file.create(recursive: true);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(
        <String, Object?>{
          'schemaVersion': 1,
          'kind': 'pokemon_catalog',
          'catalog': 'items',
          'meta': <String, Object?>{
            'description': 'Custom items catalog.',
          },
          'entries': <Map<String, Object?>>[
            <String, Object?>{
              'id': 'potion',
              'name': 'Potion',
              'categoryId': 'medicine',
              'pocketId': 'medicine',
            },
          ],
        },
      ),
    );

    final result = await loadUseCase.execute(workspace);

    expect(result.loadState, PokemonItemsCatalogLoadState.ready);
    expect(result.catalogRelativePath, 'custom/pokemon/catalogs/project-items.json');
    expect(result.entries.map((entry) => entry.id), <String>['potion']);
  });
}

Future<void> _writeItemsCatalog(
  Directory projectRoot, {
  required List<Map<String, Object?>> entries,
}) async {
  final file = File(
    p.join(projectRoot.path, 'data', 'pokemon', 'catalogs', 'items.json'),
  );
  await file.create(recursive: true);
  await file.writeAsString(
    const JsonEncoder.withIndent('  ').convert(
      <String, Object?>{
        'schemaVersion': 1,
        'kind': 'pokemon_catalog',
        'catalog': 'items',
        'meta': <String, Object?>{
          'description': 'Local items catalog.',
        },
        'entries': entries,
      },
    ),
  );
}
