import 'dart:convert';
import 'dart:io' show File;

import 'package:path/path.dart' as p;

import '../../infrastructure/external/pokemon_sdk_studio_source.dart';
import '../services/pokemon_sdk_move_catalog_converter.dart';

final class ExportPokemonSdkStudioCatalogCli {
  const ExportPokemonSdkStudioCatalogCli({
    required this.stdout,
    required this.stderr,
    this.source = const PokemonSdkStudioSource(),
    this.moveConverter = const PokemonSdkMoveCatalogConverter(),
  });

  final StringSink stdout;
  final StringSink stderr;
  final PokemonSdkStudioSource source;
  final PokemonSdkMoveCatalogConverter moveConverter;

  Future<int> run(List<String> args) async {
    try {
      final config = _ExportPokemonSdkStudioCatalogConfig.parse(args);
      if (config.help) {
        stdout.writeln(_usage);
        return 0;
      }
      if (config.projectRootPath == null) {
        throw const _UsageException('Missing required --project-root option.');
      }
      if (config.catalog != 'moves') {
        throw _UsageException(
          'Unsupported catalog "${config.catalog}". Only "moves" is supported.',
        );
      }

      final payload = await source.loadProject(config.projectRootPath!);
      final catalog = moveConverter.convertCatalog(
        payload.moves.cast<Map<String, Object?>>(),
      );
      final json = const JsonEncoder.withIndent('  ').convert(
        catalog.toJson(),
      );

      final outputPath = config.outputPath;
      if (outputPath == null) {
        stdout.write(json);
      } else {
        final outputFile = File(outputPath);
        await outputFile.parent.create(recursive: true);
        await outputFile.writeAsString(json);
        stdout.writeln('Wrote ${catalog.entries.length} moves to $outputPath');
      }
      return 0;
    } on _UsageException catch (error) {
      stderr.writeln(error.message);
      stderr.writeln(_usage);
      return 64;
    } catch (error) {
      stderr.writeln(error);
      return 65;
    }
  }

  static const String _usage = '''
Usage: dart run tool/export_pokemon_sdk_studio_catalog.dart --project-root <path> [--catalog moves] [--output <path>]

Options:
  --project-root  Pokemon SDK Studio project root containing Data/Studio.
  --catalog       Catalog to export. Currently only "moves" is supported.
  --output        Optional output JSON path. Prints to stdout when omitted.
''';
}

final class _ExportPokemonSdkStudioCatalogConfig {
  const _ExportPokemonSdkStudioCatalogConfig({
    required this.projectRootPath,
    required this.catalog,
    required this.outputPath,
    required this.help,
  });

  final String? projectRootPath;
  final String catalog;
  final String? outputPath;
  final bool help;

  static _ExportPokemonSdkStudioCatalogConfig parse(List<String> args) {
    String? projectRootPath;
    String catalog = 'moves';
    String? outputPath;
    var help = false;

    for (var index = 0; index < args.length; index++) {
      final arg = args[index];
      switch (arg) {
        case '--help':
        case '-h':
          help = true;
        case '--project-root':
          projectRootPath = _readOptionValue(args, index, arg);
          index += 1;
        case '--catalog':
          catalog = _readOptionValue(args, index, arg);
          index += 1;
        case '--output':
          outputPath = p.normalize(_readOptionValue(args, index, arg));
          index += 1;
        default:
          throw _UsageException('Unknown argument "$arg".');
      }
    }

    return _ExportPokemonSdkStudioCatalogConfig(
      projectRootPath: projectRootPath,
      catalog: catalog.trim(),
      outputPath: outputPath,
      help: help,
    );
  }

  static String _readOptionValue(
    List<String> args,
    int optionIndex,
    String option,
  ) {
    final valueIndex = optionIndex + 1;
    if (valueIndex >= args.length || args[valueIndex].startsWith('--')) {
      throw _UsageException('Missing value for $option.');
    }
    final value = args[valueIndex].trim();
    if (value.isEmpty) {
      throw _UsageException('Missing value for $option.');
    }
    return value;
  }
}

final class _UsageException implements Exception {
  const _UsageException(this.message);

  final String message;
}
