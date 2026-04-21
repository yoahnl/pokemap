import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/use_cases/project_management_use_cases.dart';
import 'package:map_editor/src/application/use_cases/sync_pokemon_moves_catalog_use_case.dart';
import 'package:map_editor/src/infrastructure/filesystem/project_filesystem.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempProjectRoot;
  late ProjectFileSystem workspace;
  late LoadPokemonMovesCatalogUseCase loadUseCase;

  setUp(() async {
    tempProjectRoot = await Directory.systemTemp.createTemp('moves_catalog_8c_');
    workspace = ProjectFileSystem(tempProjectRoot.path);
    loadUseCase = const LoadPokemonMovesCatalogUseCase(
      readRepository: FilePokemonReadRepository(),
    );

    await CreateProjectUseCase(
      FileProjectRepository(),
      const FileProjectWorkspaceFactory(),
    ).execute('Moves Catalog Test Project', tempProjectRoot.path);
  });

  tearDown(() async {
    if (await tempProjectRoot.exists()) {
      await tempProjectRoot.delete(recursive: true);
    }
  });

  test('loads local moves from the project moves catalog', () async {
    await _writeMovesCatalog(
      tempProjectRoot,
      entries: <Map<String, Object?>>[
        <String, Object?>{
          'id': 'water-gun',
          'name': 'Water Gun',
          'typeId': 'water',
          'damageClass': 'special',
          'power': 40,
          'accuracy': 100,
          'pp': 25,
          'priority': 0,
          'target': 'selected-pokemon',
          'generationId': 'generation-i',
          'effectText': 'Inflicts regular damage.',
          'shortEffectText': 'Inflicts regular damage.',
        },
      ],
    );

    final result = await loadUseCase.execute(workspace);

    expect(result.loadState, PokemonMovesCatalogLoadState.ready);
    expect(result.entries, hasLength(1));
    final move = result.entries.single;
    expect(move.id, 'water-gun');
    expect(move.name, 'Water Gun');
    expect(move.type, 'water');
    expect(move.category, 'special');
    expect(move.power, 40);
    expect(move.accuracy, 100);
    expect(move.pp, 25);
    expect(move.priority, 0);
    expect(move.target, 'selected-pokemon');
    expect(move.generationId, 'generation-i');
    expect(move.effectText, 'Inflicts regular damage.');
    expect(move.shortEffectText, 'Inflicts regular damage.');
    expect(result.diagnostics, isEmpty);
  });

  test('returns an empty result when the moves catalog is missing', () async {
    final result = await loadUseCase.execute(workspace);

    expect(result.loadState, PokemonMovesCatalogLoadState.missingCatalog);
    expect(result.entries, isEmpty);
    expect(result.diagnostics, isEmpty);
    expect(result.catalogRelativePath, 'data/pokemon/catalogs/moves.json');
  });

  test('keeps valid moves when another catalog entry is invalid', () async {
    await _writeMovesCatalog(
      tempProjectRoot,
      entries: <Map<String, Object?>>[
        <String, Object?>{
          'id': 'water-gun',
          'name': 'Water Gun',
          'typeId': 'water',
          'damageClass': 'special',
          'power': 40,
          'accuracy': 100,
          'pp': 25,
        },
        <String, Object?>{
          'id': 'broken-move',
          'name': '',
        },
      ],
    );

    final result = await loadUseCase.execute(workspace);

    expect(result.loadState, PokemonMovesCatalogLoadState.ready);
    expect(result.entries.map((entry) => entry.id), <String>['water-gun']);
    expect(result.diagnostics, hasLength(1));
    expect(result.diagnostics.single.message, contains('broken-move'));
  });

  test('keeps valid moves when another catalog entry is badly typed', () async {
    await _writeMovesCatalog(
      tempProjectRoot,
      entries: <Map<String, Object?>>[
        <String, Object?>{
          'id': 'water-gun',
          'name': 'Water Gun',
        },
        <String, Object?>{
          'id': 42,
          'name': <String, Object?>{'en': 'Broken Move'},
        },
      ],
    );

    final result = await loadUseCase.execute(workspace);

    expect(result.loadState, PokemonMovesCatalogLoadState.ready);
    expect(result.entries.map((entry) => entry.id), <String>['water-gun']);
    expect(result.diagnostics, hasLength(1));
    expect(
      result.diagnostics.single.message,
      contains('field "id" must be a string'),
    );
  });

  test('sorts moves by display name then id case-insensitively', () async {
    await _writeMovesCatalog(
      tempProjectRoot,
      entries: <Map<String, Object?>>[
        <String, Object?>{'id': 'zeta-move', 'name': 'Zeta Move'},
        <String, Object?>{'id': 'alpha-late', 'name': 'Alpha Move'},
        <String, Object?>{'id': 'alpha-early', 'name': 'alpha move'},
      ],
    );

    final result = await loadUseCase.execute(workspace);

    expect(
      result.entries.map((entry) => entry.id).toList(),
      <String>['alpha-early', 'alpha-late', 'zeta-move'],
    );
  });

  test('deduplicates duplicate move ids with a diagnostic', () async {
    await _writeMovesCatalog(
      tempProjectRoot,
      entries: <Map<String, Object?>>[
        <String, Object?>{'id': 'water-gun', 'name': 'Water Gun'},
        <String, Object?>{'id': 'water-gun', 'name': 'Water Gun Copy'},
      ],
    );

    final result = await loadUseCase.execute(workspace);

    expect(result.entries, hasLength(1));
    expect(result.entries.single.name, 'Water Gun');
    expect(result.diagnostics, hasLength(1));
    expect(result.diagnostics.single.message, contains('water-gun'));
  });

  test('parses nullable move numeric fields without crashing', () async {
    await _writeMovesCatalog(
      tempProjectRoot,
      entries: <Map<String, Object?>>[
        <String, Object?>{
          'id': 'growl',
          'name': 'Growl',
          'damageClass': 'status',
          'power': null,
          'accuracy': null,
          'pp': null,
        },
      ],
    );

    final result = await loadUseCase.execute(workspace);

    expect(result.loadState, PokemonMovesCatalogLoadState.ready);
    expect(result.entries, hasLength(1));
    final move = result.entries.single;
    expect(move.power, isNull);
    expect(move.accuracy, isNull);
    expect(move.pp, isNull);
    expect(result.diagnostics, isEmpty);
  });

  test('returns a load error when moves catalog json is invalid', () async {
    final file = File(
      p.join(tempProjectRoot.path, 'data', 'pokemon', 'catalogs', 'moves.json'),
    );
    await file.create(recursive: true);
    await file.writeAsString('{ invalid json');

    final result = await loadUseCase.execute(workspace);

    expect(result.loadState, PokemonMovesCatalogLoadState.loadError);
    expect(result.entries, isEmpty);
    expect(result.message, isNotEmpty);
  });

  test('resolves the configured moves catalog path from pokemon data root',
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
            'moves': 'catalogs/project-moves.json',
          },
          'futureDataFolders': <String, Object?>{},
        },
      ),
    );

    final result = await loadUseCase.execute(workspace);

    expect(result.loadState, PokemonMovesCatalogLoadState.missingCatalog);
    expect(
      result.catalogRelativePath,
      'custom/pokemon/catalogs/project-moves.json',
    );
  });
}

Future<void> _writeMovesCatalog(
  Directory projectRoot, {
  required List<Map<String, Object?>> entries,
}) async {
  final file = File(
    p.join(projectRoot.path, 'data', 'pokemon', 'catalogs', 'moves.json'),
  );
  await file.create(recursive: true);
  await file.writeAsString(
    const JsonEncoder.withIndent('  ').convert(
      <String, Object?>{
        'schemaVersion': 1,
        'kind': 'pokemon_catalog',
        'catalog': 'moves',
        'meta': <String, Object?>{
          'description': 'Local moves catalog.',
        },
        'entries': entries,
      },
    ),
  );
}
