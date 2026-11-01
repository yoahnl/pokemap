import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/models/pokemon_project_data_models.dart';
import 'package:map_editor/src/application/ports/project_workspace.dart';
import 'package:map_editor/src/application/services/pokemon_project_data_reader.dart';
import 'package:map_editor/src/application/use_cases/import_pokemon_evolution_json_use_case.dart';
import 'package:map_editor/src/application/use_cases/import_pokemon_learnset_json_use_case.dart';
import 'package:map_editor/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart';
import 'package:map_editor/src/application/use_cases/project_management_use_cases.dart';
import 'package:map_editor/src/infrastructure/filesystem/project_filesystem.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:path/path.dart' as p;

void main() {
  Directory? qaRunDirectory;
  late Directory tempProjectRoot;
  late String repoRootPath;
  late ProjectFileSystem workspace;
  late InitializePokemonProjectStorageUseCase initializeStorage;
  late FilePokemonWriteRepository writeRepository;
  late FilePokemonReadRepository readRepository;

  setUpAll(() async {
    final supplied = Platform.environment['AVELUNE_QA_ROOT'];
    Directory base;
    if (Platform.isMacOS) {
      final home = Platform.environment['HOME'];
      if (home == null || home.isEmpty) {
        throw StateError('HOME is required to locate AveluneQA.');
      }
      final canonicalBase = Directory(
        p.join(home, 'Library', 'Caches', 'AveluneQA'),
      );
      await canonicalBase.create(recursive: true);
      base = supplied == null || supplied.isEmpty
          ? canonicalBase
          : Directory(supplied);
      if (!p.isAbsolute(base.path) || !await base.exists()) {
        throw ArgumentError(
          'AVELUNE_QA_ROOT must be an existing absolute path.',
        );
      }
      final allowed = await canonicalBase.resolveSymbolicLinks();
      final selected = await base.resolveSymbolicLinks();
      if (selected != allowed && !p.isWithin(allowed, selected)) {
        throw ArgumentError('AVELUNE_QA_ROOT must be inside AveluneQA.');
      }
    } else {
      base = supplied == null || supplied.isEmpty
          ? Directory.systemTemp
          : Directory(supplied);
      if (!p.isAbsolute(base.path) || !await base.exists()) {
        throw ArgumentError(
          'AVELUNE_QA_ROOT must be an existing absolute path.',
        );
      }
    }
    qaRunDirectory = await base.createTemp('pokemon_media_writer_');
  });

  tearDownAll(() async {
    final directory = qaRunDirectory;
    if (directory != null && await directory.exists()) {
      await directory.delete(recursive: true);
    }
  });

  setUp(() async {
    tempProjectRoot = await qaRunDirectory!.createTemp('pokemon_write_repo_');
    repoRootPath = _resolveRepositoryRootFromCurrentDirectory();
    workspace = ProjectFileSystem(tempProjectRoot.path);
    await CreateProjectUseCase(
      FileProjectRepository(),
      const FileProjectWorkspaceFactory(),
    ).execute('Pokemon Write Repo Project', tempProjectRoot.path);
    initializeStorage = const InitializePokemonProjectStorageUseCase();
    writeRepository = FilePokemonWriteRepository();
    readRepository = FilePokemonReadRepository();
  });

  tearDown(() async {
    if (await tempProjectRoot.exists()) {
      await tempProjectRoot.delete(recursive: true);
    }
  });

  group('FilePokemonWriteRepository', () {
    for (final kind in ['media', 'learnset', 'evolution', 'binary']) {
      test(
        'writes $kind to the checked path with a non-normalizing workspace',
        () async {
          final outside = await qaRunDirectory!.createTemp(
            'pokemon_write_outside_',
          );
          addTearDown(() => outside.delete(recursive: true));
          final bridge = await Directory(
            p.join(outside.path, 'bridge'),
          ).create();
          await Link(
            p.join(tempProjectRoot.path, 'bridge'),
          ).create(bridge.path);
          final path = switch (kind) {
            'media' => 'data/pokemon/media/bulbasaur.json',
            'learnset' => 'data/pokemon/learnsets/bulbasaur.json',
            'evolution' => 'data/pokemon/evolutions/bulbasaur.json',
            _ => 'assets/pokemon/sprites/bulbasaur.bin',
          };
          final target = File(p.join(outside.path, path));
          await target.parent.create(recursive: true);
          await target.writeAsBytes([1, 2, 3]);
          final unnormalizedWorkspace = _UnnormalizedPokemonWorkspace(
            tempProjectRoot.path,
          );
          switch (kind) {
            case 'media':
              await writeRepository.saveMedia(
                unnormalizedWorkspace,
                _bulbasaurMedia(),
              );
            case 'learnset':
              await writeRepository.saveLearnset(
                unnormalizedWorkspace,
                const PokemonLearnsetFile(speciesId: 'bulbasaur'),
              );
            case 'evolution':
              await writeRepository.saveEvolution(
                unnormalizedWorkspace,
                const PokemonEvolutionFile(speciesId: 'bulbasaur'),
              );
            default:
              await writeRepository.saveBinaryAsset(
                unnormalizedWorkspace,
                relativePath: path,
                bytes: [9, 8],
              );
          }
          expect(await target.readAsBytes(), [1, 2, 3]);
          final checkedPath = p.normalize(p.join(tempProjectRoot.path, path));
          expect(await File(checkedPath).exists(), isTrue);
          if (kind == 'binary') {
            expect(await File(checkedPath).readAsBytes(), [9, 8]);
          } else {
            expect(
              (jsonDecode(await File(checkedPath).readAsString())
                  as Map)['speciesId'],
              'bulbasaur',
            );
          }
        },
        skip: Platform.isWindows
            ? 'Symbolic link creation may require elevated privileges.'
            : false,
      );
    }

    for (final kind in ['learnset', 'evolution', 'binary']) {
      test(
        'refuses $kind writes outside the project through traversal',
        () async {
          final outside = await qaRunDirectory!.createTemp(
            'pokemon_write_outside_',
          );
          addTearDown(() => outside.delete(recursive: true));
          final target = File(
            p.join(outside.path, 'escape.${kind == 'binary' ? 'bin' : 'json'}'),
          );
          await target.writeAsBytes([1, 2, 3]);
          final name = p.basename(outside.path);
          final id = '../../../../$name/escape';
          Object? failure;
          try {
            if (kind == 'learnset') {
              await writeRepository.saveLearnset(
                workspace,
                PokemonLearnsetFile(speciesId: id),
              );
            } else if (kind == 'evolution') {
              await writeRepository.saveEvolution(
                workspace,
                PokemonEvolutionFile(speciesId: id),
              );
            } else {
              await writeRepository.saveBinaryAsset(
                workspace,
                relativePath: '../$name/escape.bin',
                bytes: [9, 8],
              );
            }
          } catch (error) {
            failure = error;
          }
          expect(await target.readAsBytes(), [1, 2, 3]);
          expect(failure, isA<EditorValidationException>());
        },
      );

      for (final fileLink in [false, true]) {
        test(
          'refuses $kind writes through an external ${fileLink ? 'file' : 'directory'} link',
          () async {
            final outside = await qaRunDirectory!.createTemp(
              'pokemon_write_outside_',
            );
            addTearDown(() => outside.delete(recursive: true));
            final target = File(
              p.join(
                outside.path,
                'bulbasaur.${kind == 'binary' ? 'bin' : 'json'}',
              ),
            );
            await target.writeAsBytes([1, 2, 3]);
            final directory = Directory(
              workspace.resolveProjectRelativePath(switch (kind) {
                'learnset' => 'data/pokemon/learnsets',
                'evolution' => 'data/pokemon/evolutions',
                _ => 'assets/pokemon/sprites',
              }),
            );
            await directory.parent.create(recursive: true);
            if (await directory.exists()) {
              await directory.delete(recursive: true);
            }
            if (fileLink) {
              await directory.create();
              await Link(
                p.join(directory.path, p.basename(target.path)),
              ).create(target.path);
            } else {
              await Link(directory.path).create(outside.path);
            }
            Object? failure;
            try {
              if (kind == 'learnset') {
                await writeRepository.saveLearnset(
                  workspace,
                  const PokemonLearnsetFile(speciesId: 'bulbasaur'),
                );
              } else if (kind == 'evolution') {
                await writeRepository.saveEvolution(
                  workspace,
                  const PokemonEvolutionFile(speciesId: 'bulbasaur'),
                );
              } else {
                await writeRepository.saveBinaryAsset(
                  workspace,
                  relativePath: 'assets/pokemon/sprites/bulbasaur.bin',
                  bytes: [9, 8],
                );
              }
            } catch (error) {
              failure = error;
            }
            expect(await target.readAsBytes(), [1, 2, 3]);
            expect(failure, isA<EditorValidationException>());
          },
          skip: Platform.isWindows
              ? 'Symbolic link creation may require elevated privileges.'
              : false,
        );
      }
    }

    for (final kind in ['learnset', 'evolution']) {
      test('refuses unsafe $kind species identifiers', () async {
        for (final id in ['nested/escape', r'nested\escape', 'bad\u0000id']) {
          await expectLater(
            () => kind == 'learnset'
                ? writeRepository.saveLearnset(
                    workspace,
                    PokemonLearnsetFile(speciesId: id),
                  )
                : writeRepository.saveEvolution(
                    workspace,
                    PokemonEvolutionFile(speciesId: id),
                  ),
            throwsA(isA<EditorValidationException>()),
            reason: id,
          );
        }
      });

      test('refuses path traversal through the $kind JSON import', () async {
        final outside = await qaRunDirectory!.createTemp(
          'pokemon_import_outside_',
        );
        addTearDown(() => outside.delete(recursive: true));
        final target = File(p.join(outside.path, 'escape.json'));
        await target.writeAsString('outside must remain unchanged');
        final id = '../../../../${p.basename(outside.path)}/escape';
        final payload = kind == 'learnset'
            ? PokemonLearnsetFile(
                speciesId: id,
                startingMoves: const ['tackle'],
              ).toJson()
            : PokemonEvolutionFile(
                speciesId: id,
                preEvolution: 'bulbasaur',
              ).toJson();
        final source = File(p.join(outside.path, 'source.json'));
        await source.writeAsString(jsonEncode(payload));
        Object? failure;
        try {
          if (kind == 'learnset') {
            await ImportPokemonLearnsetJsonUseCase(
              writeRepository,
            ).execute(workspace, absoluteSourcePath: source.path);
          } else {
            await ImportPokemonEvolutionJsonUseCase(
              writeRepository,
            ).execute(workspace, absoluteSourcePath: source.path);
          }
        } catch (error) {
          failure = error;
        }
        expect(await target.readAsString(), 'outside must remain unchanged');
        expect(failure, isA<EditorValidationException>());
      });
    }

    test('rejects absolute, foreign-platform and null binary paths', () async {
      final outside = await qaRunDirectory!.createTemp(
        'pokemon_binary_outside_',
      );
      addTearDown(() => outside.delete(recursive: true));
      final target = File(p.join(outside.path, 'asset.bin'));
      await target.writeAsBytes([1, 2, 3]);
      for (final path in [
        target.path,
        r'C:\outside\asset.bin',
        r'C:asset.bin',
        r'\\server\share\asset.bin',
        r'..\outside\asset.bin',
        'assets/bad\u0000id',
      ]) {
        await expectLater(
          () => writeRepository.saveBinaryAsset(
            workspace,
            relativePath: path,
            bytes: [9, 8],
          ),
          throwsA(isA<EditorValidationException>()),
          reason: path,
        );
        expect(await target.readAsBytes(), [1, 2, 3]);
      }
    });

    test('keeps binary paths normalized inside the project', () async {
      for (final path in [
        'assets/../front.png',
        'assets/nested/../../front-deep.png',
        r'assets\..\front-windows.png',
      ]) {
        await writeRepository.saveBinaryAsset(
          workspace,
          relativePath: path,
          bytes: [1, 2, 3],
        );
        final destination = workspace.resolveProjectRelativePath(path);
        expect(p.isWithin(tempProjectRoot.path, destination), isTrue);
        expect(await File(destination).readAsBytes(), [1, 2, 3], reason: path);
      }
    });

    test('rejects normalized binary paths that escape the project', () async {
      final outside = await qaRunDirectory!.createTemp(
        'pokemon_binary_outside_',
      );
      addTearDown(() => outside.delete(recursive: true));
      final target = File(p.join(outside.path, 'escape.bin'));
      await target.writeAsBytes([1, 2, 3]);
      final name = p.basename(outside.path);
      for (final path in [
        'assets/../../$name/escape.bin',
        r'assets\..\..\' + name + r'\escape.bin',
      ]) {
        await expectLater(
          () => writeRepository.saveBinaryAsset(
            workspace,
            relativePath: path,
            bytes: [9, 8],
          ),
          throwsA(isA<EditorValidationException>()),
          reason: path,
        );
        expect(await target.readAsBytes(), [1, 2, 3], reason: path);
      }
    });

    test(
      'rejects an external file link after normalizing a binary path',
      () async {
        final outside = await qaRunDirectory!.createTemp(
          'pokemon_binary_outside_',
        );
        addTearDown(() => outside.delete(recursive: true));
        final target = File(p.join(outside.path, 'front.png'));
        await target.writeAsBytes([1, 2, 3]);
        await Link(
          p.join(tempProjectRoot.path, 'front.png'),
        ).create(target.path);
        await expectLater(
          () => writeRepository.saveBinaryAsset(
            workspace,
            relativePath: 'assets/../front.png',
            bytes: [9, 8],
          ),
          throwsA(isA<EditorValidationException>()),
        );
        expect(await target.readAsBytes(), [1, 2, 3]);
      },
      skip: Platform.isWindows
          ? 'Symbolic link creation may require elevated privileges.'
          : false,
    );

    test('keeps valid binary paths and Pokemon identities', () async {
      for (final id in ['mr-mime', 'Forme Étoile_1', 'type.feu']) {
        await writeRepository.saveLearnset(
          workspace,
          PokemonLearnsetFile(speciesId: id),
        );
        await writeRepository.saveEvolution(
          workspace,
          PokemonEvolutionFile(speciesId: id),
        );
        expect(
          await File(
            workspace.resolveProjectRelativePath(
              'data/pokemon/learnsets/$id.json',
            ),
          ).exists(),
          isTrue,
        );
        expect(
          await File(
            workspace.resolveProjectRelativePath(
              'data/pokemon/evolutions/$id.json',
            ),
          ).exists(),
          isTrue,
        );
      }
      final path = p.join(
        'assets',
        'pokemon',
        'sprites',
        'nested',
        'bulbasaur.bin',
      );
      await writeRepository.saveBinaryAsset(
        workspace,
        relativePath: path,
        bytes: [1, 2, 3],
      );
      expect(
        await File(workspace.resolveProjectRelativePath(path)).readAsBytes(),
        [1, 2, 3],
      );
    });

    for (final kind in ['learnset', 'evolution', 'binary']) {
      test(
        'keeps $kind directory links whose targets stay in the project',
        () async {
          final internal = await Directory(
            p.join(tempProjectRoot.path, 'internal_$kind'),
          ).create();
          final directory = Directory(
            workspace.resolveProjectRelativePath(switch (kind) {
              'learnset' => 'data/pokemon/learnsets',
              'evolution' => 'data/pokemon/evolutions',
              _ => 'assets/pokemon/sprites',
            }),
          );
          await directory.parent.create(recursive: true);
          if (await directory.exists()) await directory.delete(recursive: true);
          await Link(directory.path).create(internal.path);
          if (kind == 'learnset') {
            await writeRepository.saveLearnset(
              workspace,
              const PokemonLearnsetFile(speciesId: 'bulbasaur'),
            );
          } else if (kind == 'evolution') {
            await writeRepository.saveEvolution(
              workspace,
              const PokemonEvolutionFile(speciesId: 'bulbasaur'),
            );
          } else {
            await writeRepository.saveBinaryAsset(
              workspace,
              relativePath: 'assets/pokemon/sprites/bulbasaur.bin',
              bytes: [1, 2, 3],
            );
          }
          expect(
            await File(
              p.join(
                internal.path,
                'bulbasaur.${kind == 'binary' ? 'bin' : 'json'}',
              ),
            ).exists(),
            isTrue,
          );
        },
        skip: Platform.isWindows
            ? 'Symbolic link creation may require elevated privileges.'
            : false,
      );

      test(
        'refuses $kind writes through a dangling link',
        () async {
          final outside = await qaRunDirectory!.createTemp(
            'pokemon_write_outside_',
          );
          addTearDown(() => outside.delete(recursive: true));
          final target = File(
            p.join(
              outside.path,
              'missing.${kind == 'binary' ? 'bin' : 'json'}',
            ),
          );
          final directory = Directory(
            workspace.resolveProjectRelativePath(switch (kind) {
              'learnset' => 'data/pokemon/learnsets',
              'evolution' => 'data/pokemon/evolutions',
              _ => 'assets/pokemon/sprites',
            }),
          );
          await directory.create(recursive: true);
          await Link(
            p.join(
              directory.path,
              'bulbasaur.${kind == 'binary' ? 'bin' : 'json'}',
            ),
          ).create(target.path);
          await expectLater(
            () => switch (kind) {
              'learnset' => writeRepository.saveLearnset(
                workspace,
                const PokemonLearnsetFile(speciesId: 'bulbasaur'),
              ),
              'evolution' => writeRepository.saveEvolution(
                workspace,
                const PokemonEvolutionFile(speciesId: 'bulbasaur'),
              ),
              _ => writeRepository.saveBinaryAsset(
                workspace,
                relativePath: 'assets/pokemon/sprites/bulbasaur.bin',
                bytes: [1],
              ),
            },
            throwsA(isA<EditorValidationException>()),
          );
          expect(await target.exists(), isFalse);
        },
        skip: Platform.isWindows
            ? 'Symbolic link creation may require elevated privileges.'
            : false,
      );
    }

    test(
      'refuses media write through a directory link outside the project',
      () async {
        final outside = await qaRunDirectory!.createTemp(
          'pokemon_media_outside_',
        );
        addTearDown(() => outside.delete(recursive: true));
        final externalFile = File(p.join(outside.path, 'bulbasaur.json'));
        await externalFile.writeAsString('outside must remain unchanged');
        final mediaDirectory = Directory(
          workspace.resolveProjectRelativePath('data/pokemon/media'),
        );
        if (await mediaDirectory.exists()) {
          await mediaDirectory.delete(recursive: true);
        }
        await mediaDirectory.parent.create(recursive: true);
        await Link(mediaDirectory.path).create(outside.path);

        Object? failure;
        try {
          await writeRepository.saveMedia(workspace, _bulbasaurMedia());
        } catch (error) {
          failure = error;
        }

        expect(
          await externalFile.readAsString(),
          'outside must remain unchanged',
        );
        expect(failure, isA<EditorValidationException>());
      },
      skip: Platform.isWindows
          ? 'Symbolic link creation may require elevated privileges.'
          : false,
    );

    test(
      'refuses media write through a file link outside the project',
      () async {
        final outside = await qaRunDirectory!.createTemp(
          'pokemon_media_outside_',
        );
        addTearDown(() => outside.delete(recursive: true));
        final externalFile = File(p.join(outside.path, 'external.json'));
        await externalFile.writeAsString('outside must remain unchanged');
        final mediaDirectory = Directory(
          workspace.resolveProjectRelativePath('data/pokemon/media'),
        );
        await mediaDirectory.create(recursive: true);
        await Link(
          p.join(mediaDirectory.path, 'bulbasaur.json'),
        ).create(externalFile.path);

        Object? failure;
        try {
          await writeRepository.saveMedia(workspace, _bulbasaurMedia());
        } catch (error) {
          failure = error;
        }

        expect(
          await externalFile.readAsString(),
          'outside must remain unchanged',
        );
        expect(failure, isA<EditorValidationException>());
      },
      skip: Platform.isWindows
          ? 'Symbolic link creation may require elevated privileges.'
          : false,
    );

    test(
      'refuses media write through an ancestor link outside the project',
      () async {
        final outside = await qaRunDirectory!.createTemp(
          'pokemon_media_outside_',
        );
        addTearDown(() => outside.delete(recursive: true));
        final externalDirectory = await Directory(
          p.join(outside.path, 'media'),
        ).create();
        final externalFile = File(
          p.join(externalDirectory.path, 'bulbasaur.json'),
        );
        await externalFile.writeAsString('outside must remain unchanged');
        final pokemonDirectory = Directory(
          workspace.resolveProjectRelativePath('data/pokemon'),
        );
        if (await pokemonDirectory.exists()) {
          await pokemonDirectory.delete(recursive: true);
        }
        await pokemonDirectory.parent.create(recursive: true);
        await Link(pokemonDirectory.path).create(outside.path);

        Object? failure;
        try {
          await writeRepository.saveMedia(workspace, _bulbasaurMedia());
        } catch (error) {
          failure = error;
        }

        expect(
          await externalFile.readAsString(),
          'outside must remain unchanged',
        );
        expect(failure, isA<EditorValidationException>());
      },
      skip: Platform.isWindows
          ? 'Symbolic link creation may require elevated privileges.'
          : false,
    );

    test(
      'keeps an existing media directory link inside the project',
      () async {
        final internalDirectory = await Directory(
          p.join(tempProjectRoot.path, 'internal_media'),
        ).create();
        final mediaDirectory = Directory(
          workspace.resolveProjectRelativePath('data/pokemon/media'),
        );
        if (await mediaDirectory.exists()) {
          await mediaDirectory.delete(recursive: true);
        }
        await mediaDirectory.parent.create(recursive: true);
        await Link(mediaDirectory.path).create(internalDirectory.path);

        await writeRepository.saveMedia(workspace, _bulbasaurMedia());

        final saved = File(p.join(internalDirectory.path, 'bulbasaur.json'));
        expect(
          (jsonDecode(await saved.readAsString()) as Map)['speciesId'],
          'bulbasaur',
        );
      },
      skip: Platform.isWindows
          ? 'Symbolic link creation may require elevated privileges.'
          : false,
    );

    test(
      'keeps an existing media file link inside the project',
      () async {
        final internalFile = File(
          p.join(tempProjectRoot.path, 'internal.json'),
        );
        await internalFile.writeAsString('before');
        final mediaDirectory = Directory(
          workspace.resolveProjectRelativePath('data/pokemon/media'),
        );
        await mediaDirectory.create(recursive: true);
        await Link(
          p.join(mediaDirectory.path, 'bulbasaur.json'),
        ).create(internalFile.path);

        await writeRepository.saveMedia(workspace, _bulbasaurMedia());

        expect(
          (jsonDecode(await internalFile.readAsString()) as Map)['speciesId'],
          'bulbasaur',
        );
      },
      skip: Platform.isWindows
          ? 'Symbolic link creation may require elevated privileges.'
          : false,
    );

    for (final targetIsExternal in [false, true]) {
      test(
        'refuses a dangling media file link with external=$targetIsExternal',
        () async {
          final outside = await qaRunDirectory!.createTemp(
            'pokemon_media_outside_',
          );
          addTearDown(() => outside.delete(recursive: true));
          final target = File(
            p.join(
              targetIsExternal ? outside.path : tempProjectRoot.path,
              'missing.json',
            ),
          );
          final mediaDirectory = Directory(
            workspace.resolveProjectRelativePath('data/pokemon/media'),
          );
          await mediaDirectory.create(recursive: true);
          await Link(
            p.join(mediaDirectory.path, 'bulbasaur.json'),
          ).create(target.path);

          await expectLater(
            () => writeRepository.saveMedia(workspace, _bulbasaurMedia()),
            throwsA(isA<EditorValidationException>()),
          );
          expect(await target.exists(), isFalse);
        },
        skip: Platform.isWindows
            ? 'Symbolic link creation may require elevated privileges.'
            : false,
      );
    }

    test('refuses path separators in Pokemon media identities', () async {
      for (final id in ['nested/escape', r'nested\escape', 'bad\u0000id']) {
        final media = PokemonMediaFile(
          speciesId: id,
          defaultFormId: 'base',
          variants: const {
            'base': PokemonMediaVariant(frontStatic: 'front.png'),
          },
        );
        await expectLater(
          () => writeRepository.saveMedia(workspace, media),
          throwsA(isA<EditorValidationException>()),
          reason: id,
        );
      }
    });

    test('retains valid Pokemon media identities as filenames', () async {
      for (final id in ['mr-mime', 'Forme Étoile_1', 'type.feu']) {
        final media = PokemonMediaFile(
          speciesId: id,
          defaultFormId: 'base',
          variants: const {
            'base': PokemonMediaVariant(frontStatic: 'front.png'),
          },
        );
        await writeRepository.saveMedia(workspace, media);
        final file = File(
          workspace.resolveProjectRelativePath('data/pokemon/media/$id.json'),
        );
        expect(await file.exists(), isTrue, reason: id);
        expect((jsonDecode(await file.readAsString()) as Map)['speciesId'], id);
      }
    });

    test('saves a species file in the project workspace', () async {
      final species = _bulbasaurSpecies();

      await writeRepository.saveSpecies(workspace, species);

      final file = File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/species/0001-bulbasaur.json',
        ),
      );
      expect(await file.exists(), isTrue);

      final decoded =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      expect(decoded['id'], 'bulbasaur');

      final readBack = await readRepository.readSpeciesById(
        workspace,
        'bulbasaur',
      );
      expect(readBack.id, 'bulbasaur');
      expect(readBack.gameplayFlags.starterEligible, isTrue);
    });

    test(
      'can defer species snapshot invalidation for a controlled batch',
      () async {
        final reader = _TrackingPokemonProjectDataReader();
        final repository = FilePokemonWriteRepository(
          reader: reader,
          invalidateSpeciesSnapshotAfterSave: false,
        );

        await repository.saveSpecies(workspace, _bulbasaurSpecies());

        expect(reader.invalidationCount, 0);
      },
    );

    test(
      'writes a validated species to an already resolved relative path',
      () async {
        await writeRepository.saveSpeciesAtRelativePath(
          workspace,
          relativePath: 'data/pokemon/species/0001-bulbasaur.json',
          species: _bulbasaurSpecies(),
        );

        final file = File(
          workspace.resolveProjectRelativePath(
            'data/pokemon/species/0001-bulbasaur.json',
          ),
        );
        expect(await file.exists(), isTrue);
        expect(
          (jsonDecode(await file.readAsString()) as Map<String, dynamic>)['id'],
          'bulbasaur',
        );
      },
    );

    test('saves a learnset file in the project workspace', () async {
      final learnset = _bulbasaurLearnset();

      await writeRepository.saveLearnset(workspace, learnset);

      final file = File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/learnsets/bulbasaur.json',
        ),
      );
      expect(await file.exists(), isTrue);

      final readBack = await readRepository.readLearnsetById(
        workspace,
        'bulbasaur',
      );
      expect(readBack.speciesId, 'bulbasaur');
      expect(readBack.levelUp.first.moveId, 'tackle');
      expect(readBack.levelUp.first.level, 1);
    });

    test('saves an evolution file in the project workspace', () async {
      final evolution = _bulbasaurEvolution();

      await writeRepository.saveEvolution(workspace, evolution);

      final file = File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/evolutions/bulbasaur.json',
        ),
      );
      expect(await file.exists(), isTrue);

      final readBack = await readRepository.readEvolutionById(
        workspace,
        'bulbasaur',
      );
      expect(readBack.speciesId, 'bulbasaur');
      expect(readBack.evolutions.single.targetSpeciesId, 'ivysaur');
      expect(readBack.evolutions.single.minLevel, 16);
    });

    test('saves a media file in the project workspace', () async {
      final media = _bulbasaurMedia();

      await writeRepository.saveMedia(workspace, media);

      final file = File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/media/bulbasaur.json',
        ),
      );
      expect(await file.exists(), isTrue);

      final readBack = await readRepository.readMediaById(
        workspace,
        'bulbasaur',
      );
      expect(readBack.speciesId, 'bulbasaur');
      expect(
        readBack.variants['base']?.frontStatic,
        'assets/pokemon/sprites/bulbasaur/front.png',
      );
    });

    test('saves a catalog file in the project workspace', () async {
      await initializeStorage.execute(workspace);
      final movesCatalog = _movesCatalog();

      await writeRepository.saveCatalogByKey(workspace, 'moves', movesCatalog);

      final file = File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/catalogs/moves.json',
        ),
      );
      expect(await file.exists(), isTrue);

      final readBack = await readRepository.readCatalogByKey(
        workspace,
        'moves',
      );
      expect(readBack.catalog, 'moves');
      expect(
        readBack.entries.map((entry) => entry['id']),
        containsAll(<String>['tackle', 'growl']),
      );
    });

    test(
      'writes in the workspace project and not at the monorepo root',
      () async {
        final species = _bulbasaurSpecies();
        final decoy = await qaRunDirectory!.createTemp('pokemon_write_decoy_');
        final originalCurrent = Directory.current;
        try {
          Directory.current = decoy.path;

          await writeRepository.saveSpecies(workspace, species);

          expect(
            File(
              workspace.resolveProjectRelativePath(
                'data/pokemon/species/0001-bulbasaur.json',
              ),
            ).existsSync(),
            isTrue,
          );
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

    test('leaves project.json strictly unchanged', () async {
      await initializeStorage.execute(workspace);

      final projectFile = File(workspace.projectManifestPath);
      final before = await projectFile.readAsString();

      await writeRepository.saveSpecies(workspace, _bulbasaurSpecies());
      await writeRepository.saveLearnset(workspace, _bulbasaurLearnset());
      await writeRepository.saveEvolution(workspace, _bulbasaurEvolution());
      await writeRepository.saveMedia(workspace, _bulbasaurMedia());
      await writeRepository.saveCatalogByKey(
        workspace,
        'moves',
        _movesCatalog(),
      );

      final after = await projectFile.readAsString();
      expect(after, before);
    });

    test('overwrites the target species file predictably', () async {
      final originalSpecies = _bulbasaurSpecies();
      const updatedSpecies = PokemonSpeciesFile(
        id: 'bulbasaur',
        slug: 'bulbasaur',
        nationalDex: 1,
        names: <String, String>{'en': 'Bulbasaur Updated'},
        speciesName: <String, String>{'en': 'Seed Pokemon'},
        genIntroduced: 1,
        typing: PokemonSpeciesTyping(types: <String>['grass', 'poison']),
        baseStats: PokemonSpeciesBaseStats(
          hp: 45,
          atk: 49,
          def: 49,
          spa: 65,
          spd: 65,
          spe: 45,
          bst: 318,
        ),
        abilities: PokemonSpeciesAbilities(
          primary: 'overgrow',
          hidden: 'chlorophyll',
        ),
        breeding: PokemonSpeciesBreeding(
          genderRatio: <String, double>{'male': 0.875, 'female': 0.125},
          eggGroups: <String>['monster', 'grass'],
          hatchCycles: 20,
        ),
        progression: PokemonSpeciesProgression(
          growthRateId: 'medium_slow',
          baseExp: 64,
          catchRate: 45,
          baseFriendship: 50,
        ),
        refs: PokemonSpeciesRefs(
          learnset: 'bulbasaur',
          evolution: 'bulbasaur',
          media: 'bulbasaur',
        ),
        dexContent: PokemonSpeciesDexContent(
          heightM: 0.7,
          weightKg: 6.9,
          color: 'green',
          flavorText: 'Updated demo entry',
        ),
        gameplayFlags: PokemonSpeciesGameplayFlags(starterEligible: false),
        sourceMeta: PokemonSpeciesSourceMeta(seededBy: 'test', seedVersion: 2),
      );

      await writeRepository.saveSpecies(workspace, originalSpecies);
      await writeRepository.saveSpecies(workspace, updatedSpecies);

      final readBack = await readRepository.readSpeciesById(
        workspace,
        'bulbasaur',
      );
      expect(readBack.names['en'], 'Bulbasaur Updated');
      expect(readBack.gameplayFlags.starterEligible, isFalse);
      expect(readBack.sourceMeta.seedVersion, 2);
    });

    test(
      'does not create a duplicate species file when the slug changes',
      () async {
        final originalSpecies = _bulbasaurSpecies();
        const updatedSpecies = PokemonSpeciesFile(
          id: 'bulbasaur',
          slug: 'bulbizarre-custom',
          nationalDex: 1,
          names: <String, String>{'en': 'Bulbasaur Custom'},
          speciesName: <String, String>{'en': 'Seed Pokemon'},
          genIntroduced: 1,
          typing: PokemonSpeciesTyping(types: <String>['grass', 'poison']),
          baseStats: PokemonSpeciesBaseStats(
            hp: 45,
            atk: 49,
            def: 49,
            spa: 65,
            spd: 65,
            spe: 45,
            bst: 318,
          ),
          abilities: PokemonSpeciesAbilities(
            primary: 'overgrow',
            hidden: 'chlorophyll',
          ),
          breeding: PokemonSpeciesBreeding(
            genderRatio: <String, double>{'male': 0.875, 'female': 0.125},
            eggGroups: <String>['monster', 'grass'],
            hatchCycles: 20,
          ),
          progression: PokemonSpeciesProgression(
            growthRateId: 'medium_slow',
            baseExp: 64,
            catchRate: 45,
            baseFriendship: 50,
          ),
          refs: PokemonSpeciesRefs(
            learnset: 'bulbasaur',
            evolution: 'bulbasaur',
            media: 'bulbasaur',
          ),
          dexContent: PokemonSpeciesDexContent(
            heightM: 0.7,
            weightKg: 6.9,
            color: 'green',
            flavorText: 'Updated demo entry after slug change.',
          ),
          gameplayFlags: PokemonSpeciesGameplayFlags(starterEligible: true),
          sourceMeta: PokemonSpeciesSourceMeta(
            seededBy: 'test',
            seedVersion: 3,
          ),
        );

        await writeRepository.saveSpecies(workspace, originalSpecies);
        await writeRepository.saveSpecies(workspace, updatedSpecies);

        final speciesDir = Directory(
          workspace.resolveProjectRelativePath('data/pokemon/species'),
        );
        final speciesFiles = await speciesDir
            .list()
            .where(
              (entity) => entity is File && p.extension(entity.path) == '.json',
            )
            .cast<File>()
            .toList();

        expect(speciesFiles, hasLength(1));
        expect(p.basename(speciesFiles.single.path), '0001-bulbasaur.json');

        final readBack = await readRepository.readSpeciesById(
          workspace,
          'bulbasaur',
        );
        expect(readBack.id, 'bulbasaur');
        expect(readBack.slug, 'bulbizarre-custom');
        expect(readBack.names['en'], 'Bulbasaur Custom');
        expect(readBack.sourceMeta.seedVersion, 3);
      },
    );

    test(
      'reuses an existing non-canonical species path instead of creating a duplicate canonical file',
      () async {
        await initializeStorage.execute(workspace);

        final speciesDir = Directory(
          workspace.resolveProjectRelativePath('data/pokemon/species'),
        );
        final customFile = File(
          p.join(speciesDir.path, '0001-bulbizarre-custom.json'),
        );
        await customFile.writeAsString(
          const JsonEncoder.withIndent(
            '  ',
          ).convert(_bulbasaurSpecies().toJson()),
        );

        const updatedSpecies = PokemonSpeciesFile(
          id: 'bulbasaur',
          slug: 'bulbasaur-refreshed',
          nationalDex: 1,
          names: <String, String>{'en': 'Bulbasaur Refreshed'},
          speciesName: <String, String>{'en': 'Seed Pokemon'},
          genIntroduced: 1,
          typing: PokemonSpeciesTyping(types: <String>['grass', 'poison']),
          baseStats: PokemonSpeciesBaseStats(
            hp: 45,
            atk: 49,
            def: 49,
            spa: 65,
            spd: 65,
            spe: 45,
            bst: 318,
          ),
          abilities: PokemonSpeciesAbilities(
            primary: 'overgrow',
            hidden: 'chlorophyll',
          ),
          breeding: PokemonSpeciesBreeding(
            genderRatio: <String, double>{'male': 0.875, 'female': 0.125},
            eggGroups: <String>['monster', 'grass'],
            hatchCycles: 20,
          ),
          progression: PokemonSpeciesProgression(
            growthRateId: 'medium_slow',
            baseExp: 64,
            catchRate: 45,
            baseFriendship: 50,
          ),
          refs: PokemonSpeciesRefs(
            learnset: 'bulbasaur',
            evolution: 'bulbasaur',
            media: 'bulbasaur',
          ),
          dexContent: PokemonSpeciesDexContent(
            heightM: 0.7,
            weightKg: 6.9,
            color: 'green',
            flavorText: 'Rewrite uses the already-present custom file path.',
          ),
          gameplayFlags: PokemonSpeciesGameplayFlags(starterEligible: true),
          sourceMeta: PokemonSpeciesSourceMeta(
            seededBy: 'test',
            seedVersion: 4,
          ),
        );

        await writeRepository.saveSpecies(workspace, updatedSpecies);

        final canonicalFile = File(
          workspace.resolveProjectRelativePath(
            'data/pokemon/species/0001-bulbasaur.json',
          ),
        );
        expect(await customFile.exists(), isTrue);
        expect(await canonicalFile.exists(), isFalse);

        final speciesFiles = await speciesDir
            .list()
            .where(
              (entity) => entity is File && p.extension(entity.path) == '.json',
            )
            .cast<File>()
            .toList();
        expect(speciesFiles, hasLength(1));
        expect(
          p.basename(speciesFiles.single.path),
          '0001-bulbizarre-custom.json',
        );

        final readBack = await readRepository.readSpeciesById(
          workspace,
          'bulbasaur',
        );
        expect(readBack.slug, 'bulbasaur-refreshed');
        expect(readBack.names['en'], 'Bulbasaur Refreshed');
        expect(readBack.sourceMeta.seedVersion, 4);
      },
    );

    test(
      'ignores a misleading species basename whose JSON declares another id',
      () async {
        await writeRepository.saveSpecies(workspace, _bulbasaurSpecies());

        final misleadingFile = File(
          workspace.resolveProjectRelativePath(
            'data/pokemon/species/9999-bulbasaur.json',
          ),
        );
        await misleadingFile.parent.create(recursive: true);
        final misleadingJson = _bulbasaurSpecies().toJson()
          ..['id'] = 'something_else'
          ..['slug'] = 'something-else';
        await misleadingFile.writeAsString(
          const JsonEncoder.withIndent('  ').convert(misleadingJson),
        );

        const updatedSpecies = PokemonSpeciesFile(
          id: 'bulbasaur',
          slug: 'bulbasaur-rewritten',
          nationalDex: 1,
          names: <String, String>{'en': 'Bulbasaur Rewritten Cleanly'},
          speciesName: <String, String>{'en': 'Seed Pokemon'},
          genIntroduced: 1,
          typing: PokemonSpeciesTyping(types: <String>['grass', 'poison']),
          baseStats: PokemonSpeciesBaseStats(
            hp: 45,
            atk: 49,
            def: 49,
            spa: 65,
            spd: 65,
            spe: 45,
            bst: 318,
          ),
          abilities: PokemonSpeciesAbilities(
            primary: 'overgrow',
            hidden: 'chlorophyll',
          ),
          breeding: PokemonSpeciesBreeding(
            genderRatio: <String, double>{'male': 0.875, 'female': 0.125},
            eggGroups: <String>['monster', 'grass'],
            hatchCycles: 20,
          ),
          progression: PokemonSpeciesProgression(
            growthRateId: 'medium_slow',
            baseExp: 64,
            catchRate: 45,
            baseFriendship: 50,
          ),
          refs: PokemonSpeciesRefs(
            learnset: 'bulbasaur',
            evolution: 'bulbasaur',
            media: 'bulbasaur',
          ),
          dexContent: PokemonSpeciesDexContent(
            heightM: 0.7,
            weightKg: 6.9,
            color: 'green',
            flavorText: 'Misleading filename should not block overwrite.',
          ),
          gameplayFlags: PokemonSpeciesGameplayFlags(starterEligible: true),
          sourceMeta: PokemonSpeciesSourceMeta(
            seededBy: 'test',
            seedVersion: 6,
          ),
        );

        await writeRepository.saveSpecies(workspace, updatedSpecies);

        final canonicalFile = File(
          workspace.resolveProjectRelativePath(
            'data/pokemon/species/0001-bulbasaur.json',
          ),
        );
        expect(await canonicalFile.exists(), isTrue);
        expect(await misleadingFile.exists(), isTrue);

        final readBack = await readRepository.readSpeciesById(
          workspace,
          'bulbasaur',
        );
        expect(readBack.slug, 'bulbasaur-rewritten');
        expect(readBack.names['en'], 'Bulbasaur Rewritten Cleanly');
        expect(readBack.sourceMeta.seedVersion, 6);
      },
    );

    test(
      'rewrites an existing species even when another unrelated species json is invalid',
      () async {
        final originalSpecies = _bulbasaurSpecies();
        const updatedSpecies = PokemonSpeciesFile(
          id: 'bulbasaur',
          slug: 'bulbasaur',
          nationalDex: 1,
          names: <String, String>{'en': 'Bulbasaur Rewritten'},
          speciesName: <String, String>{'en': 'Seed Pokemon'},
          genIntroduced: 1,
          typing: PokemonSpeciesTyping(types: <String>['grass', 'poison']),
          baseStats: PokemonSpeciesBaseStats(
            hp: 45,
            atk: 49,
            def: 49,
            spa: 65,
            spd: 65,
            spe: 45,
            bst: 318,
          ),
          abilities: PokemonSpeciesAbilities(
            primary: 'overgrow',
            hidden: 'chlorophyll',
          ),
          breeding: PokemonSpeciesBreeding(
            genderRatio: <String, double>{'male': 0.875, 'female': 0.125},
            eggGroups: <String>['monster', 'grass'],
            hatchCycles: 20,
          ),
          progression: PokemonSpeciesProgression(
            growthRateId: 'medium_slow',
            baseExp: 64,
            catchRate: 45,
            baseFriendship: 50,
          ),
          refs: PokemonSpeciesRefs(
            learnset: 'bulbasaur',
            evolution: 'bulbasaur',
            media: 'bulbasaur',
          ),
          dexContent: PokemonSpeciesDexContent(
            heightM: 0.7,
            weightKg: 6.9,
            color: 'green',
            flavorText: 'Rewrite succeeds despite unrelated invalid JSON.',
          ),
          gameplayFlags: PokemonSpeciesGameplayFlags(starterEligible: true),
          sourceMeta: PokemonSpeciesSourceMeta(
            seededBy: 'test',
            seedVersion: 4,
          ),
        );

        await writeRepository.saveSpecies(workspace, originalSpecies);

        final invalidSpeciesFile = File(
          workspace.resolveProjectRelativePath(
            'data/pokemon/species/9999-unrelated.json',
          ),
        );
        await invalidSpeciesFile.parent.create(recursive: true);
        await invalidSpeciesFile.writeAsString('{ invalid json');

        await writeRepository.saveSpecies(workspace, updatedSpecies);

        final rewrittenFile = File(
          workspace.resolveProjectRelativePath(
            'data/pokemon/species/0001-bulbasaur.json',
          ),
        );
        final decoded =
            jsonDecode(await rewrittenFile.readAsString())
                as Map<String, dynamic>;

        expect(decoded['id'], 'bulbasaur');
        expect(
          (decoded['names'] as Map<String, dynamic>)['en'],
          'Bulbasaur Rewritten',
        );
        expect(
          (decoded['sourceMeta'] as Map<String, dynamic>)['seedVersion'],
          4,
        );
      },
    );

    test(
      'throws explicit conflict when multiple species files match the same id',
      () async {
        final originalSpecies = _bulbasaurSpecies();
        await writeRepository.saveSpecies(workspace, originalSpecies);

        final conflictingFile = File(
          workspace.resolveProjectRelativePath(
            'data/pokemon/species/9999-bulbasaur-duplicate.json',
          ),
        );
        await conflictingFile.parent.create(recursive: true);
        final conflictingJson = _bulbasaurSpecies().toJson()
          ..['slug'] = 'bulbasaur-duplicate'
          ..['sourceMeta'] = const <String, dynamic>{
            'seededBy': 'test',
            'seedVersion': 7,
          };
        await conflictingFile.writeAsString(
          const JsonEncoder.withIndent('  ').convert(conflictingJson),
        );

        expect(
          () => writeRepository.saveSpecies(
            workspace,
            const PokemonSpeciesFile(
              id: 'bulbasaur',
              slug: 'bulbasaur',
              nationalDex: 1,
              names: <String, String>{'en': 'Bulbasaur'},
              speciesName: <String, String>{'en': 'Seed Pokemon'},
              genIntroduced: 1,
              typing: PokemonSpeciesTyping(types: <String>['grass', 'poison']),
              baseStats: PokemonSpeciesBaseStats(
                hp: 45,
                atk: 49,
                def: 49,
                spa: 65,
                spd: 65,
                spe: 45,
                bst: 318,
              ),
              abilities: PokemonSpeciesAbilities(
                primary: 'overgrow',
                hidden: 'chlorophyll',
              ),
              breeding: PokemonSpeciesBreeding(
                genderRatio: <String, double>{'male': 0.875, 'female': 0.125},
                eggGroups: <String>['monster', 'grass'],
                hatchCycles: 20,
              ),
              progression: PokemonSpeciesProgression(
                growthRateId: 'medium_slow',
                baseExp: 64,
                catchRate: 45,
                baseFriendship: 50,
              ),
              refs: PokemonSpeciesRefs(
                learnset: 'bulbasaur',
                evolution: 'bulbasaur',
                media: 'bulbasaur',
              ),
              dexContent: PokemonSpeciesDexContent(
                heightM: 0.7,
                weightKg: 6.9,
                color: 'green',
                flavorText: 'Conflict test.',
              ),
              gameplayFlags: PokemonSpeciesGameplayFlags(starterEligible: true),
              sourceMeta: PokemonSpeciesSourceMeta(
                seededBy: 'test',
                seedVersion: 5,
              ),
            ),
          ),
          throwsA(
            isA<EditorConflictException>().having(
              (error) => error.message,
              'message',
              contains(
                'Multiple Pokemon species files match the id "bulbasaur"',
              ),
            ),
          ),
        );
      },
    );

    test(
      'throws explicit error when catalog key does not match payload',
      () async {
        await initializeStorage.execute(workspace);
        final before = await File(
          workspace.resolveProjectRelativePath(
            'data/pokemon/catalogs/moves.json',
          ),
        ).readAsString();

        const abilitiesCatalog = PokemonCatalogFile(
          schemaVersion: 1,
          kind: 'pokemon_catalog',
          catalog: 'abilities',
          meta: PokemonDataMeta(
            description: 'Ability catalog for mismatch test.',
            sourcePriority: <String>['internal'],
            notes: <String>[],
          ),
          entries: <Map<String, dynamic>>[
            <String, dynamic>{'id': 'overgrow', 'name': 'Overgrow'},
          ],
        );

        expect(
          () => writeRepository.saveCatalogByKey(
            workspace,
            'moves',
            abilitiesCatalog,
          ),
          throwsA(
            isA<EditorValidationException>().having(
              (error) => error.message,
              'message',
              contains('Pokemon catalog key mismatch'),
            ),
          ),
        );

        final after = await File(
          workspace.resolveProjectRelativePath(
            'data/pokemon/catalogs/moves.json',
          ),
        ).readAsString();
        expect(after, before);
      },
    );
  });
}

final class _UnnormalizedPokemonWorkspace extends ProjectFileSystem {
  _UnnormalizedPokemonWorkspace(super.projectRoot);

  @override
  String resolveProjectRelativePath(String relativePath) =>
      '$projectRoot${p.separator}bridge${p.separator}..${p.separator}$relativePath';
}

final class _TrackingPokemonProjectDataReader extends PokemonProjectDataReader {
  int invalidationCount = 0;

  @override
  Future<String?> resolveSpeciesWriteRelativePathById(
    ProjectWorkspace workspace,
    String speciesId,
  ) async {
    return null;
  }

  @override
  void invalidateSpeciesSnapshot(ProjectWorkspace workspace) {
    invalidationCount += 1;
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

PokemonSpeciesFile _bulbasaurSpecies() {
  return const PokemonSpeciesFile(
    id: 'bulbasaur',
    slug: 'bulbasaur',
    nationalDex: 1,
    names: <String, String>{'en': 'Bulbasaur', 'fr': 'Bulbizarre'},
    speciesName: <String, String>{'en': 'Seed Pokemon'},
    genIntroduced: 1,
    typing: PokemonSpeciesTyping(types: <String>['grass', 'poison']),
    baseStats: PokemonSpeciesBaseStats(
      hp: 45,
      atk: 49,
      def: 49,
      spa: 65,
      spd: 65,
      spe: 45,
      bst: 318,
    ),
    abilities: PokemonSpeciesAbilities(
      primary: 'overgrow',
      hidden: 'chlorophyll',
    ),
    breeding: PokemonSpeciesBreeding(
      genderRatio: <String, double>{'male': 0.875, 'female': 0.125},
      eggGroups: <String>['monster', 'grass'],
      hatchCycles: 20,
    ),
    progression: PokemonSpeciesProgression(
      growthRateId: 'medium_slow',
      baseExp: 64,
      catchRate: 45,
      baseFriendship: 50,
    ),
    refs: PokemonSpeciesRefs(
      learnset: 'bulbasaur',
      evolution: 'bulbasaur',
      media: 'bulbasaur',
    ),
    dexContent: PokemonSpeciesDexContent(
      heightM: 0.7,
      weightKg: 6.9,
      color: 'green',
      flavorText: 'A strange seed was planted on its back at birth.',
    ),
    gameplayFlags: PokemonSpeciesGameplayFlags(starterEligible: true),
    sourceMeta: PokemonSpeciesSourceMeta(seededBy: 'test', seedVersion: 1),
  );
}

PokemonLearnsetFile _bulbasaurLearnset() {
  return const PokemonLearnsetFile(
    speciesId: 'bulbasaur',
    startingMoves: <String>['tackle', 'growl'],
    relearnMoves: <String>['tackle', 'growl', 'vine_whip'],
    levelUp: <PokemonLearnsetLevelUpEntry>[
      PokemonLearnsetLevelUpEntry(
        moveId: 'tackle',
        level: 1,
        source: 'level_up',
        versionGroup: 'demo',
      ),
      PokemonLearnsetLevelUpEntry(
        moveId: 'vine_whip',
        level: 7,
        source: 'level_up',
        versionGroup: 'demo',
      ),
    ],
    tm: <PokemonLearnsetMoveEntry>[
      PokemonLearnsetMoveEntry(moveId: 'growl', versionGroup: 'demo'),
    ],
  );
}

PokemonEvolutionFile _bulbasaurEvolution() {
  return const PokemonEvolutionFile(
    speciesId: 'bulbasaur',
    preEvolution: null,
    evolutions: <PokemonEvolutionEntry>[
      PokemonEvolutionEntry(
        targetSpeciesId: 'ivysaur',
        method: 'level_up',
        minLevel: 16,
        conditionText: <String, String>{'en': 'Evolves at level 16'},
      ),
    ],
  );
}

PokemonMediaFile _bulbasaurMedia() {
  return const PokemonMediaFile(
    speciesId: 'bulbasaur',
    defaultFormId: 'base',
    variants: <String, PokemonMediaVariant>{
      'base': PokemonMediaVariant(
        frontStatic: 'assets/pokemon/sprites/bulbasaur/front.png',
        backStatic: 'assets/pokemon/sprites/bulbasaur/back.png',
        icon: 'assets/pokemon/sprites/bulbasaur/icon.png',
        party: 'assets/pokemon/sprites/bulbasaur/party.png',
        overworld: 'assets/pokemon/sprites/bulbasaur/overworld.png',
        portrait: 'assets/pokemon/portraits/bulbasaur.png',
        cry: 'assets/pokemon/cries/bulbasaur.ogg',
        animations: <String, PokemonMediaAnimationRef>{
          'battleFront': PokemonMediaAnimationRef(
            sheet: 'assets/pokemon/sprites/bulbasaur/battle_front_sheet.png',
            animationId: 'battle_front',
          ),
        },
      ),
    },
  );
}

PokemonCatalogFile _movesCatalog() {
  return const PokemonCatalogFile(
    schemaVersion: 1,
    kind: 'pokemon_catalog',
    catalog: 'moves',
    meta: PokemonDataMeta(
      description: 'Move catalog for the local Pokemon project database.',
      sourcePriority: <String>['internal'],
      notes: <String>['Write repository integration test data.'],
    ),
    entries: <Map<String, dynamic>>[
      <String, dynamic>{
        'id': 'tackle',
        'name': 'Tackle',
        'names': <String, String>{'en': 'Tackle', 'fr': 'Charge'},
        'type': 'normal',
        'category': 'physical',
        'power': 40,
        'accuracy': 100,
        'pp': 35,
        'priority': 0,
        'target': 'adjacent',
        'shortDesc': 'A physical attack in which the user charges and slams.',
        'generation': 1,
      },
      <String, dynamic>{
        'id': 'growl',
        'name': 'Growl',
        'names': <String, String>{'en': 'Growl', 'fr': 'Rugissement'},
        'type': 'normal',
        'category': 'status',
        'power': null,
        'accuracy': 100,
        'pp': 40,
        'priority': 0,
        'target': 'adjacent',
        'shortDesc': 'Lowers the target Attack by one stage.',
        'generation': 1,
      },
    ],
  );
}
