import 'dart:convert';
import 'dart:io';

import 'package:map_editor/src/infrastructure/repositories/journaled_file_promotion_repository.dart';
import 'package:path/path.dart' as p;

Future<void> main(List<String> args) async {
  String option(String name) {
    final index = args.indexOf(name);
    if (index < 0 || index + 1 >= args.length) {
      throw ArgumentError('Missing $name');
    }
    return args[index + 1];
  }

  final root = await Directory(
    option('--repository-root'),
  ).resolveSymbolicLinks();
  final project = await File(option('--project')).resolveSymbolicLinks();
  final recipe =
      jsonDecode(await File(option('--recipe')).readAsString())
          as Map<String, dynamic>;
  if (recipe['schemaVersion'] != 1 ||
      recipe.keys.any(
        (key) => !{
          'schemaVersion',
          'id',
          'projectManifest',
          'promotionManifest',
          'allowedDestinations',
          'provenance',
        }.contains(key),
      )) {
    throw const FormatException('Invalid fixture promotion recipe');
  }
  String confined(String relative) {
    if (p.isAbsolute(relative) ||
        relative.contains('\\') ||
        relative
            .split('/')
            .any((part) => part.isEmpty || part == '.' || part == '..') ||
        !p.isWithin(root, p.join(root, relative))) {
      throw const FormatException('Unsafe fixture promotion path');
    }
    return p.join(root, relative);
  }

  if (project != confined(recipe['projectManifest'] as String)) {
    throw const FormatException('The recipe targets another project');
  }
  final result = await JournaledFilePromotionRepository(
    repositoryRoot: root,
    projectManifestPath: project,
    manifestPath: confined(recipe['promotionManifest'] as String),
    allowedDestinations: (recipe['allowedDestinations'] as List).map((value) {
      confined(value as String);
      return value;
    }).toSet(),
  ).promote();
  stdout.writeln(
    jsonEncode({
      'status': result.status.name,
      'code': result.code,
      'message': result.message,
      'journalPath': result.journalPath,
    }),
  );
  if (!result.succeeded) exitCode = 1;
}
