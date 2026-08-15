import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_editor/src/application/models/pokemon_validation_report.dart';
import 'package:map_editor/src/application/services/pokemon_project_validator.dart';
import 'package:map_editor/src/application/use_cases/project_management_use_cases.dart';
import 'package:map_editor/src/application/use_cases/seed_pokemon_demo_data_use_case.dart';
import 'package:map_editor/src/application/use_cases/validate_pokemon_project_data_use_case.dart';
import 'package:map_editor/src/infrastructure/authoring_api/editor_project_file_reader.dart';
import 'package:map_editor/src/infrastructure/filesystem/project_filesystem.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempProjectRoot;
  late String repoRootPath;
  late ProjectFileSystem workspace;
  late _PokemonValidationFixtureSeeder seedUseCase;
  late ValidatePokemonProjectDataUseCase validateUseCase;

  setUp(() async {
    tempProjectRoot = await Directory.systemTemp.createTemp(
      'pokemon_validate_',
    );
    repoRootPath = _resolveRepositoryRootFromCurrentDirectory();
    workspace = ProjectFileSystem(tempProjectRoot.path);
    await CreateProjectUseCase(
      FileProjectRepository(),
      const FileProjectWorkspaceFactory(),
    ).execute('Pokemon Validation Test', tempProjectRoot.path);
    final pokemonRepository = FilePokemonReadRepository();
    seedUseCase = _PokemonValidationFixtureSeeder(
      SeedPokemonDemoDataUseCase(snapshotController: pokemonRepository),
    );
    validateUseCase = ValidatePokemonProjectDataUseCase(
      const PokemonProjectValidator(reader: EditorProjectFileReader()),
    );
  });

  tearDown(() async {
    if (await tempProjectRoot.exists()) {
      await tempProjectRoot.delete(recursive: true);
    }
  });

  group('ValidatePokemonProjectDataUseCase', () {
    test('returns a valid report for the seeded demo dataset', () async {
      await seedUseCase.execute(workspace);

      final report = await validateUseCase.execute(workspace);

      expect(report.isValid, isTrue);
      expect(report.errorCount, 0);
      expect(report.issues, isEmpty);
    });

    test('blocks seeded media references until their assets exist', () async {
      await seedUseCase.executeWithoutAssets(workspace);

      final report = await validateUseCase.execute(workspace);

      expect(report.isValid, isFalse);
      expect(_hasIssue(report, 'media.asset_missing'), isTrue);
    });

    test('leaves project.json strictly unchanged', () async {
      final createProjectUseCase = CreateProjectUseCase(
        FileProjectRepository(),
        const FileProjectWorkspaceFactory(),
      );
      await createProjectUseCase.execute(
        'Pokemon Validation Project',
        tempProjectRoot.path,
      );
      await seedUseCase.execute(workspace);

      final projectFile = File(workspace.projectManifestPath);
      final before = await projectFile.readAsString();

      await validateUseCase.execute(workspace);

      final after = await projectFile.readAsString();
      expect(after, before);
    });

    test(
      'reads from the workspace even when Directory.current points somewhere else',
      () async {
        await seedUseCase.execute(workspace);

        final decoy = await Directory.systemTemp.createTemp(
          'pokemon_validate_decoy_',
        );
        final originalCurrent = Directory.current;
        try {
          await Directory(
            p.join(decoy.path, 'data', 'pokemon', 'species'),
          ).create(recursive: true);
          await File(
            p.join(
              decoy.path,
              'data',
              'pokemon',
              'species',
              '0001-bulbasaur.json',
            ),
          ).writeAsString('{ invalid json');

          Directory.current = decoy.path;

          final report = await validateUseCase.execute(workspace);

          expect(report.isValid, isTrue);
          expect(Directory(p.join(repoRootPath, 'data')).existsSync(), isFalse);
          expect(
            Directory(p.join(repoRootPath, 'assets')).existsSync(),
            isFalse,
          );
        } finally {
          Directory.current = originalCurrent.path;
          if (await decoy.exists()) {
            await decoy.delete(recursive: true);
          }
        }
      },
    );

    test('reports an error when a species id is empty', () async {
      await seedUseCase.execute(workspace);
      await _mutateJsonFile(
        workspace,
        'data/pokemon/species/0001-bulbasaur.json',
        (json) => json['id'] = '',
      );

      final report = await validateUseCase.execute(workspace);

      expect(_hasIssue(report, 'species.id_empty'), isTrue);
    });

    test('reports an error when a species has duplicated types', () async {
      await seedUseCase.execute(workspace);
      await _mutateJsonFile(
        workspace,
        'data/pokemon/species/0001-bulbasaur.json',
        (json) => (json['typing'] as Map<String, dynamic>)['types'] = <String>[
          'grass',
          'grass',
        ],
      );

      final report = await validateUseCase.execute(workspace);

      expect(_hasIssue(report, 'species.type_duplicate'), isTrue);
    });

    test('reports an error when a learnset has an empty move id', () async {
      await seedUseCase.execute(workspace);
      await _mutateJsonFile(
        workspace,
        'data/pokemon/learnsets/bulbasaur.json',
        (json) =>
            ((json['levelUp'] as List<Object?>).first
                    as Map<String, dynamic>)['moveId'] =
                '',
      );

      final report = await validateUseCase.execute(workspace);

      expect(_hasIssue(report, 'learnset.level_up_move_empty'), isTrue);
    });

    test('reports an error when a learnset level is below one', () async {
      await seedUseCase.execute(workspace);
      await _mutateJsonFile(
        workspace,
        'data/pokemon/learnsets/bulbasaur.json',
        (json) =>
            ((json['levelUp'] as List<Object?>).first
                    as Map<String, dynamic>)['level'] =
                0,
      );

      final report = await validateUseCase.execute(workspace);

      expect(_hasIssue(report, 'learnset.level_up_level_invalid'), isTrue);
    });

    test('reports an error when an evolution targets itself', () async {
      await seedUseCase.execute(workspace);
      await _mutateJsonFile(
        workspace,
        'data/pokemon/evolutions/bulbasaur.json',
        (json) =>
            ((json['evolutions'] as List<Object?>).first
                    as Map<String, dynamic>)['targetSpeciesId'] =
                'bulbasaur',
      );

      final report = await validateUseCase.execute(workspace);

      expect(_hasIssue(report, 'evolution.self_target'), isTrue);
    });

    test(
      'reports an error when a species learnsetRef is missing locally',
      () async {
        await seedUseCase.execute(workspace);
        await _mutateJsonFile(
          workspace,
          'data/pokemon/species/0001-bulbasaur.json',
          (json) => (json['refs'] as Map<String, dynamic>)['learnset'] =
              'missing_learnset',
        );

        final report = await validateUseCase.execute(workspace);

        expect(_hasIssue(report, 'species.learnset_ref_missing'), isTrue);
      },
    );

    test(
      'reports an error when a species evolutionRef is missing locally',
      () async {
        await seedUseCase.execute(workspace);
        await _mutateJsonFile(
          workspace,
          'data/pokemon/species/0001-bulbasaur.json',
          (json) => (json['refs'] as Map<String, dynamic>)['evolution'] =
              'missing_evolution',
        );

        final report = await validateUseCase.execute(workspace);

        expect(_hasIssue(report, 'species.evolution_ref_missing'), isTrue);
      },
    );

    test(
      'reports an error when a species media ref is missing locally',
      () async {
        await seedUseCase.execute(workspace);
        await _mutateJsonFile(
          workspace,
          'data/pokemon/species/0001-bulbasaur.json',
          (json) =>
              (json['refs'] as Map<String, dynamic>)['media'] = 'missing_media',
        );

        final report = await validateUseCase.execute(workspace);

        expect(_hasIssue(report, 'species.media_ref_missing'), isTrue);
      },
    );

    test(
      'reports an error when an evolution target species is absent',
      () async {
        await seedUseCase.execute(workspace);
        await _mutateJsonFile(
          workspace,
          'data/pokemon/evolutions/bulbasaur.json',
          (json) =>
              ((json['evolutions'] as List<Object?>).first
                      as Map<String, dynamic>)['targetSpeciesId'] =
                  'venusaur',
        );

        final report = await validateUseCase.execute(workspace);

        expect(_hasIssue(report, 'evolution.target_species_missing'), isTrue);
      },
    );

    test(
      'reports an error when a learnset uses a move absent from moves catalog',
      () async {
        await seedUseCase.execute(workspace);
        await _mutateJsonFile(
          workspace,
          'data/pokemon/learnsets/bulbasaur.json',
          (json) =>
              ((json['levelUp'] as List<Object?>).first
                      as Map<String, dynamic>)['moveId'] =
                  'mystery_move',
        );

        final report = await validateUseCase.execute(workspace);

        expect(_hasIssue(report, 'learnset.move_missing_in_catalog'), isTrue);
      },
    );

    test(
      'reports an error when a species uses a type absent from types catalog',
      () async {
        await seedUseCase.execute(workspace);
        await _mutateJsonFile(
          workspace,
          'data/pokemon/species/0001-bulbasaur.json',
          (json) => (json['typing'] as Map<String, dynamic>)['types'] =
              <String>['shadow'],
        );

        final report = await validateUseCase.execute(workspace);

        expect(_hasIssue(report, 'species.type_missing_in_catalog'), isTrue);
      },
    );

    test(
      'reports invalid JSON as a validation issue instead of mutating data',
      () async {
        await seedUseCase.execute(workspace);
        await _writeRawFile(
          workspace,
          'data/pokemon/species/0001-bulbasaur.json',
          '{ invalid json',
        );

        final report = await validateUseCase.execute(workspace);

        expect(report.isValid, isFalse);
        expect(_hasIssue(report, 'species.read_error'), isTrue);
        expect(
          report.issues.any((issue) => issue.message.contains('Invalid JSON')),
          isTrue,
        );
      },
    );

    test(
      'blocks validation when the moves catalog is absent',
      () async {
        await seedUseCase.execute(workspace);
        final movesCatalog = File(
          workspace.resolveProjectRelativePath(
            'data/pokemon/catalogs/moves.json',
          ),
        );
        await movesCatalog.delete();

        final report = await validateUseCase.execute(workspace);

        expect(report.isValid, isFalse);
        expect(_hasIssue(report, 'catalog.moves_missing'), isTrue);
        expect(
          report.issues.any(
            (issue) =>
                issue.code == 'catalog.moves_missing' &&
                issue.severity == PokemonValidationSeverity.error,
          ),
          isTrue,
        );
      },
    );

    test(
      'blocks validation when the types catalog is absent',
      () async {
        await seedUseCase.execute(workspace);
        final typesCatalog = File(
          workspace.resolveProjectRelativePath(
            'data/pokemon/catalogs/types.json',
          ),
        );
        await typesCatalog.delete();

        final report = await validateUseCase.execute(workspace);

        expect(report.isValid, isFalse);
        expect(_hasIssue(report, 'catalog.types_missing'), isTrue);
        expect(
          report.issues.any(
            (issue) =>
                issue.code == 'catalog.types_missing' &&
                issue.severity == PokemonValidationSeverity.error,
          ),
          isTrue,
        );
        expect(_hasIssue(report, 'species.type_missing_in_catalog'), isFalse);
      },
    );

    test(
      'matches canonical validation for custom directories and item evolutions',
      () async {
        await seedUseCase.execute(workspace);
        await _movePokemonDataToCustomDirectories(workspace);
        await _mutateJsonFile(
          workspace,
          'custom/pokemon/evolutions/bulbasaur.json',
          (json) {
            final evolution =
                (json['evolutions'] as List<Object?>).first
                    as Map<String, dynamic>;
            evolution['method'] = 'use_item';
            evolution['itemId'] = 'missing-stone';
          },
        );
        await _mutateJsonFile(
          workspace,
          'custom/pokemon/learnsets/bulbasaur.json',
          (json) {
            (json['levelUp'] as List<Object?>).add(<String, Object?>{
              'moveId': 'tackle',
              'level': 101,
              'source': 'level_up',
              'versionGroup': 'beta',
            });
          },
        );

        final editorReport = await validateUseCase.execute(workspace);
        final canonicalReport = await _canonicalPokemonReport(tempProjectRoot);

        expect(editorReport.toJson(), canonicalReport);
        final missingItem = editorReport.issues.singleWhere(
          (issue) => issue.code == 'evolution.item_missing',
        );
        expect(missingItem.path, startsWith('custom/pokemon/evolutions/'));
        final invalidLevel = editorReport.issues.singleWhere(
          (issue) => issue.code == 'learnset.level_up_level_invalid',
        );
        expect(invalidLevel.path, startsWith('custom/pokemon/learnsets/'));
      },
    );
  });
}

Future<void> _movePokemonDataToCustomDirectories(
  ProjectFileSystem workspace,
) async {
  final customRoot = Directory(
    workspace.resolveProjectRelativePath('custom/pokemon'),
  );
  await customRoot.create(recursive: true);
  for (final directory in const <String>[
    'species',
    'learnsets',
    'evolutions',
    'media',
    'catalogs',
  ]) {
    await Directory(
      workspace.resolveProjectRelativePath('data/pokemon/$directory'),
    ).rename(workspace.resolveProjectRelativePath('custom/pokemon/$directory'));
  }
  await _mutateJsonFile(workspace, 'project.json', (json) {
    final pokemon = json['pokemon'] as Map<String, dynamic>;
    pokemon['speciesDir'] = 'custom/pokemon/species';
    pokemon['learnsetsDir'] = 'custom/pokemon/learnsets';
    pokemon['evolutionsDir'] = 'custom/pokemon/evolutions';
    pokemon['mediaDir'] = 'custom/pokemon/media';
    final catalogs = pokemon['catalogFiles'] as Map<String, dynamic>;
    for (final key in catalogs.keys.toList(growable: false)) {
      catalogs[key] = (catalogs[key] as String).replaceFirst(
        'data/pokemon/catalogs/',
        'custom/pokemon/catalogs/',
      );
    }
  });
}

Future<Map<String, Object?>> _canonicalPokemonReport(Directory root) async {
  const reader = LocalProjectFileReader();
  final policy = await WorkspacePolicy.create(
    allowedRootPaths: <String>[root.path],
    fileReader: reader,
  );
  final handles = WorkspaceHandleStore();
  final api = AuthoringReadApi(
    openService: ProjectOpenService(
      policy: policy,
      fileReader: reader,
      handles: handles,
    ),
    snapshotLoader: ProjectSnapshotLoader(handles: handles),
  );
  final opened = await api.openProject(root.path);
  try {
    final validation = await api.validate(opened.projectHandle);
    return Map<String, Object?>.from(validation['pokemonCatalog']! as Map);
  } finally {
    await api.close(opened.workspaceHandle);
  }
}

String _resolveRepositoryRootFromCurrentDirectory() {
  var current = Directory.current.absolute;

  while (true) {
    final agentsFile = File(p.join(current.path, 'AGENTS.md'));
    final mapEditorDir = Directory(
      p.join(current.path, 'packages', 'map_editor'),
    );
    if (agentsFile.existsSync() && mapEditorDir.existsSync()) {
      return current.path;
    }

    final parent = current.parent;
    if (parent.path == current.path) {
      throw StateError(
        'Could not resolve repository root from Directory.current: '
        '${Directory.current.path}',
      );
    }
    current = parent;
  }
}

Future<void> _mutateJsonFile(
  ProjectFileSystem workspace,
  String relativePath,
  void Function(Map<String, dynamic> json) update,
) async {
  final file = File(workspace.resolveProjectRelativePath(relativePath));
  final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
  update(json);
  await file.writeAsString(const JsonEncoder.withIndent('  ').convert(json));
}

Future<void> _writeRawFile(
  ProjectFileSystem workspace,
  String relativePath,
  String content,
) async {
  final file = File(workspace.resolveProjectRelativePath(relativePath));
  await file.parent.create(recursive: true);
  await file.writeAsString(content);
}

bool _hasIssue(PokemonValidationReport report, String code) {
  return report.issues.any((issue) => issue.code == code);
}

final class _PokemonValidationFixtureSeeder {
  const _PokemonValidationFixtureSeeder(this.delegate);

  final SeedPokemonDemoDataUseCase delegate;

  Future<void> execute(ProjectFileSystem workspace) async {
    await executeWithoutAssets(workspace);
    await _writeReferencedPokemonAssets(workspace);
  }

  Future<void> executeWithoutAssets(ProjectFileSystem workspace) =>
      delegate.execute(workspace);
}

Future<void> _writeReferencedPokemonAssets(ProjectFileSystem workspace) async {
  final mediaDirectory = Directory(
    workspace.resolveProjectRelativePath('data/pokemon/media'),
  );
  await for (final entity in mediaDirectory.list()) {
    if (entity is! File || !entity.path.endsWith('.json')) continue;
    final media =
        jsonDecode(await entity.readAsString()) as Map<String, dynamic>;
    final variants = (media['variants'] as Map<String, dynamic>).values;
    for (final rawVariant in variants) {
      final variant = rawVariant as Map<String, dynamic>;
      final paths = <String>[
        for (final key in const <String>[
          'frontStatic',
          'backStatic',
          'frontShinyStatic',
          'backShinyStatic',
          'icon',
          'party',
          'overworld',
          'portrait',
          'cry',
        ])
          if (variant[key] case final String path) path,
        for (final animation
            in (variant['animations'] as Map<String, dynamic>? ?? const {})
                .values)
          if ((animation as Map<String, dynamic>)['sheet']
              case final String path)
            path,
      ];
      for (final relativePath in paths) {
        final file = File(workspace.resolveProjectRelativePath(relativePath));
        await file.parent.create(recursive: true);
        await file.writeAsBytes(<int>[1]);
      }
    }
  }
}
