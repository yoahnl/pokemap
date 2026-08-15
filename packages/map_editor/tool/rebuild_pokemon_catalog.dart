import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import 'package:map_editor/src/application/services/pokemon_catalog_rebuild_transaction.dart';
import 'package:map_editor/src/application/services/pokemon_catalog_generation_sanitizer.dart';
import 'package:map_editor/src/application/services/pokemon_external_query_resolver.dart';
import 'package:map_editor/src/application/services/pokemon_project_data_reader.dart';
import 'package:map_editor/src/application/services/pokemon_project_validator.dart';
import 'package:map_editor/src/application/use_cases/import_external_pokemon_use_cases.dart';
import 'package:map_editor/src/application/use_cases/resolve_external_pokemon_batch_selection_use_case.dart';
import 'package:map_editor/src/infrastructure/external/pokeapi_live_source.dart';
import 'package:map_editor/src/infrastructure/external/showdown_snapshot_source.dart';
import 'package:map_editor/src/infrastructure/filesystem/project_filesystem.dart';
import 'package:map_editor/src/infrastructure/repositories/http_pokemon_external_source_repository.dart';
import 'package:map_editor/src/infrastructure/repositories/pokemon_file_write_repository.dart';

const _confirmation = 'REBUILD_GENERATIONS_1_TO_6';
const _firstNationalDex = 1;
const _lastNationalDex = 721;

Future<void> main(List<String> arguments) async {
  try {
    final options = _Options.parse(arguments);
    if (options.confirmation != _confirmation) {
      throw ArgumentError('Expected --confirm=$_confirmation');
    }
    await _rebuild(options);
  } on Object catch (error, stackTrace) {
    stderr.writeln('Catalog rebuild failed: $error');
    stderr.writeln(stackTrace);
    exitCode = 1;
  }
}

Future<void> _rebuild(_Options options) async {
  final project = await _canonicalProject(options.projectPath);
  final timestamp = _timestamp();
  final baseName = p.basename(project.path);
  final staging = options.stagingPath == null
      ? Directory(
          p.join(project.parent.path, '.$baseName.catalog-staging-$timestamp'),
        )
      : Directory(p.normalize(Directory(options.stagingPath!).absolute.path));
  final backup = Directory(
    p.join(project.parent.path, '$baseName.catalog-backup-$timestamp'),
  );
  if (options.stagingPath != null) {
    if (!await staging.exists()) {
      throw FileSystemException(
        'Resume staging directory does not exist',
        staging.path,
      );
    }
    stdout.writeln('RESUME_STAGING ${staging.path}');
    await _validateAndReplace(
      project: project,
      staging: staging,
      backup: backup,
    );
    return;
  }
  await _prepareStaging(project: project, staging: staging);
  stdout.writeln('STAGING ${staging.path}');

  final client = http.Client();
  try {
    final externalRepository = HttpPokemonExternalSourceRepository(
      pokeApiSource: PokeApiLiveSource(client: client),
      showdownSource: ShowdownSnapshotSource(client: client),
    );
    final selection = await ResolveExternalPokemonBatchSelectionUseCase(
      externalSourceRepository: externalRepository,
      queryResolver: const PokemonExternalQueryResolver(),
    ).execute('$_firstNationalDex-$_lastNationalDex');
    if (!selection.canDryRun || selection.targets.length != _lastNationalDex) {
      throw StateError(
        'Expected $_lastNationalDex base species, resolved '
        '${selection.targets.length}: ${selection.message ?? selection.kind.name}',
      );
    }

    final workspace = ProjectFileSystem(staging.path);
    final reader = PokemonProjectDataReader();
    final batchUseCase = BatchImportExternalPokemonSpeciesUseCase(
      ImportExternalPokemonSpeciesUseCase(
        externalSourceRepository: externalRepository,
        writeRepository: FilePokemonWriteRepository(reader: reader),
        dataReader: reader,
      ),
    );
    var pending = selection.resolvedSpeciesIds;
    for (var attempt = 1; attempt <= 3 && pending.isNotEmpty; attempt++) {
      stdout.writeln('IMPORT attempt=$attempt count=${pending.length}');
      final result = await batchUseCase.execute(
        workspace,
        speciesIds: pending,
        mergePolicy: PokemonExternalImportMergePolicy.overwriteExisting,
        onProgress: (progress) {
          if (progress.completedCount % 10 == 0 ||
              progress.completedCount == progress.totalCount ||
              progress.failedCount > 0) {
            stdout.writeln(
              'PROGRESS attempt=$attempt completed=${progress.completedCount}/'
              '${progress.totalCount} failed=${progress.failedCount} '
              'last=${progress.lastCompletedSpeciesId}',
            );
          }
        },
      );
      pending = result.entries
          .where((entry) => entry.isFailed || entry.isConflict)
          .map((entry) => entry.speciesId)
          .toList(growable: false);
      for (final entry in result.entries.where((entry) => entry.isFailed)) {
        stderr.writeln(
          'IMPORT_ERROR ${entry.speciesId}: ${entry.errorMessage}',
        );
      }
    }
    if (pending.isNotEmpty) {
      throw StateError(
        'Import still fails after 3 attempts: ${pending.join(', ')}',
      );
    }

    await _validateAndReplace(
      project: project,
      staging: staging,
      backup: backup,
    );
  } finally {
    client.close();
  }
}

Future<void> _validateAndReplace({
  required Directory project,
  required Directory staging,
  required Directory backup,
}) async {
  final workspace = ProjectFileSystem(staging.path);
  final reader = PokemonProjectDataReader();
  await _sanitizeStaging(workspace, reader);
  final report = await const PokemonProjectValidator().validate(workspace);
  final speciesEntries = await reader.listSpeciesIndexEntries(workspace);
  final speciesIds = speciesEntries.map((entry) => entry.id).toSet();
  final issues = <String>[
    ...const PokemonCatalogRebuildGate(
      firstNationalDex: _firstNationalDex,
      lastNationalDex: _lastNationalDex,
    ).validate(
      nationalDexIds: speciesEntries.map((entry) => entry.nationalDex).toSet(),
      speciesIds: speciesIds,
      learnsetIds: (await reader.listLearnsetIds(workspace)).toSet(),
      evolutionIds: (await reader.listEvolutionIds(workspace)).toSet(),
      mediaIds: (await reader.listMediaIds(workspace)).toSet(),
      coherenceReport: report,
    ),
    ...await _validateStarterEvolutionChains(workspace, reader),
  ];
  if (issues.isNotEmpty) {
    for (final issue in issues) {
      stderr.writeln('VALIDATION_ERROR $issue');
    }
    for (final diagnostic in report.diagnostics) {
      stderr.writeln(
        'DIAGNOSTIC ${diagnostic.severity.name} ${diagnostic.code} '
        '${diagnostic.path}: ${diagnostic.message}',
      );
    }
    throw StateError(
      'Staging validation failed with ${issues.length} issue(s)',
    );
  }

  stdout.writeln(
    'VALIDATED species=${speciesIds.length} '
    'learnsets=${(await reader.listLearnsetIds(workspace)).length} '
    'evolutions=${(await reader.listEvolutionIds(workspace)).length} '
    'media=${(await reader.listMediaIds(workspace)).length} '
    'warnings=${report.warningCount}',
  );
  final result = await const PokemonCatalogRebuildTransaction().replace(
    projectDirectory: project,
    stagingDirectory: staging,
    backupDirectory: backup,
  );
  await staging.delete(recursive: true);
  stdout.writeln('BACKUP ${result.backupDirectory.path}');
  stdout.writeln('REPLACED ${project.path}');
}

Future<void> _sanitizeStaging(
  ProjectFileSystem workspace,
  PokemonProjectDataReader reader,
) async {
  const sanitizer = PokemonCatalogGenerationSanitizer();
  final writer = FilePokemonWriteRepository(
    reader: reader,
    invalidateSpeciesSnapshotAfterSave: false,
  );
  final indexEntries = await reader.listSpeciesIndexEntries(workspace);
  final species = <PokemonSpeciesFile>[];
  for (final entry in indexEntries) {
    final speciesFile = File(
      workspace.resolveProjectRelativePath(entry.relativePath),
    );
    final speciesJson = jsonDecode(await speciesFile.readAsString());
    if (speciesJson is! Map) {
      throw FormatException(
        'Species document must be a JSON object: ${speciesFile.path}',
      );
    }
    species.add(
      PokemonSpeciesFile.fromJson(speciesJson.cast<String, dynamic>()),
    );
  }
  final relativePathsBySpeciesId = <String, String>{
    for (final entry in indexEntries) entry.id: entry.relativePath,
  };
  var removedFormReferences = 0;
  for (final value in species) {
    final forms = sanitizer.sanitizeForms(
      value.forms,
      availableFormIds: const <String>{'base'},
    );
    removedFormReferences +=
        value.forms.otherForms.length - forms.otherForms.length;
    if (forms.otherForms.length == value.forms.otherForms.length) {
      continue;
    }
    await writer.saveSpeciesAtRelativePath(
      workspace,
      relativePath: relativePathsBySpeciesId[value.id]!,
      species: PokemonSpeciesFile.fromJson(<String, dynamic>{
        ...value.toJson(),
        'forms': forms.toJson(),
      }),
    );
  }
  reader.invalidateSpeciesSnapshot(workspace);

  final speciesIds = species.map((value) => value.id).toSet();
  var removedMediaVariants = 0;
  for (final speciesId in speciesIds) {
    final mediaFile = File(
      workspace.resolveProjectRelativePath(
        'data/pokemon/media/$speciesId.json',
      ),
    );
    final mediaJson = jsonDecode(await mediaFile.readAsString());
    if (mediaJson is! Map) {
      throw FormatException(
        'Media document must be a JSON object: ${mediaFile.path}',
      );
    }
    final media = PokemonMediaFile.fromJson(mediaJson.cast<String, dynamic>());
    final sanitized = sanitizer.sanitizeMedia(
      media,
      availableFormIds: const <String>{'base'},
    );
    removedMediaVariants += media.variants.length - sanitized.variants.length;
    if (sanitized.variants.length != media.variants.length) {
      await writer.saveMedia(workspace, sanitized);
    }
  }
  var removedEvolutionEntries = 0;
  var normalizedEvolutionEntries = 0;
  for (final speciesId in speciesIds) {
    final evolutionFile = File(
      workspace.resolveProjectRelativePath(
        'data/pokemon/evolutions/$speciesId.json',
      ),
    );
    final evolutionJson = jsonDecode(await evolutionFile.readAsString());
    if (evolutionJson is! Map) {
      throw FormatException(
        'Evolution document must be a JSON object: ${evolutionFile.path}',
      );
    }
    final evolution = PokemonEvolutionFile.fromJson(
      evolutionJson.cast<String, dynamic>(),
    );
    final sanitized = sanitizer.sanitizeEvolutions(
      evolution.evolutions,
      availableSpeciesIds: speciesIds,
    );
    removedEvolutionEntries += evolution.evolutions.length - sanitized.length;
    for (var index = 0; index < sanitized.length; index++) {
      if (index >= evolution.evolutions.length ||
          sanitized[index].method != evolution.evolutions[index].method ||
          sanitized[index].minLevel != evolution.evolutions[index].minLevel) {
        normalizedEvolutionEntries += 1;
      }
    }
    await writer.saveEvolution(
      workspace,
      PokemonEvolutionFile(
        speciesId: evolution.speciesId,
        preEvolution: evolution.preEvolution,
        evolutions: sanitized,
      ),
    );
  }
  stdout.writeln(
    'SANITIZED removedFormReferences=$removedFormReferences '
    'removedMediaVariants=$removedMediaVariants '
    'removedEvolutionEntries=$removedEvolutionEntries '
    'normalizedEvolutionEntries=$normalizedEvolutionEntries',
  );
}

Future<List<String>> _validateStarterEvolutionChains(
  ProjectFileSystem workspace,
  PokemonProjectDataReader reader,
) async {
  const requiredTargets = <String, String>{
    'chikorita': 'bayleef',
    'bayleef': 'meganium',
    'cyndaquil': 'quilava',
    'quilava': 'typhlosion',
    'froakie': 'frogadier',
    'frogadier': 'greninja',
  };
  final issues = <String>[];
  for (final requirement in requiredTargets.entries) {
    final evolution = await reader.readEvolutionById(
      workspace,
      requirement.key,
    );
    if (!evolution.evolutions.any(
      (entry) => entry.targetSpeciesId == requirement.value,
    )) {
      issues.add(
        'Evolution ${requirement.key} -> ${requirement.value} is missing',
      );
    }
  }
  return issues;
}

Future<Directory> _canonicalProject(String rawPath) async {
  final directory = Directory(p.normalize(Directory(rawPath).absolute.path));
  if (!await directory.exists()) {
    throw FileSystemException(
      'Project directory does not exist',
      directory.path,
    );
  }
  final canonical = Directory(await directory.resolveSymbolicLinks());
  if (!await File(p.join(canonical.path, 'project.json')).exists()) {
    throw FileSystemException('project.json is missing', canonical.path);
  }
  return canonical;
}

Future<void> _prepareStaging({
  required Directory project,
  required Directory staging,
}) async {
  if (await staging.exists()) {
    throw FileSystemException('Staging directory already exists', staging.path);
  }
  await staging.create(recursive: true);
  await File(
    p.join(project.path, 'project.json'),
  ).copy(p.join(staging.path, 'project.json'));
  await _copyDirectory(
    Directory(p.join(project.path, 'data', 'pokemon')),
    Directory(p.join(staging.path, 'data', 'pokemon')),
  );
  for (final name in const <String>[
    'species',
    'learnsets',
    'evolutions',
    'media',
  ]) {
    final directory = Directory(p.join(staging.path, 'data', 'pokemon', name));
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
    await directory.create(recursive: true);
  }
  await Directory(
    p.join(staging.path, 'assets', 'pokemon'),
  ).create(recursive: true);
}

Future<void> _copyDirectory(Directory source, Directory destination) async {
  if (!await source.exists()) {
    throw FileSystemException('Source directory is missing', source.path);
  }
  await destination.create(recursive: true);
  await for (final entity in source.list(followLinks: false)) {
    final targetPath = p.join(destination.path, p.basename(entity.path));
    if (entity is Directory) {
      await _copyDirectory(entity, Directory(targetPath));
    } else if (entity is File) {
      await entity.copy(targetPath);
    } else {
      throw FileSystemException(
        'Symbolic links are not supported',
        entity.path,
      );
    }
  }
}

String _timestamp() {
  final now = DateTime.now();
  String twoDigits(int value) => value.toString().padLeft(2, '0');
  return '${now.year}${twoDigits(now.month)}${twoDigits(now.day)}-'
      '${twoDigits(now.hour)}${twoDigits(now.minute)}${twoDigits(now.second)}';
}

final class _Options {
  const _Options({
    required this.projectPath,
    required this.confirmation,
    this.stagingPath,
  });

  final String projectPath;
  final String confirmation;
  final String? stagingPath;

  factory _Options.parse(List<String> arguments) {
    String? projectPath;
    String? confirmation;
    String? stagingPath;
    for (var index = 0; index < arguments.length; index++) {
      final argument = arguments[index];
      if (argument == '--project' && index + 1 < arguments.length) {
        projectPath = arguments[++index];
      } else if (argument.startsWith('--project=')) {
        projectPath = argument.substring('--project='.length);
      } else if (argument == '--confirm' && index + 1 < arguments.length) {
        confirmation = arguments[++index];
      } else if (argument.startsWith('--confirm=')) {
        confirmation = argument.substring('--confirm='.length);
      } else if (argument == '--staging' && index + 1 < arguments.length) {
        stagingPath = arguments[++index];
      } else if (argument.startsWith('--staging=')) {
        stagingPath = argument.substring('--staging='.length);
      } else {
        throw ArgumentError('Unsupported argument: $argument');
      }
    }
    if (projectPath == null || projectPath.trim().isEmpty) {
      throw ArgumentError('Missing --project=<absolute path>');
    }
    return _Options(
      projectPath: projectPath,
      confirmation: confirmation ?? '',
      stagingPath: stagingPath,
    );
  }
}
