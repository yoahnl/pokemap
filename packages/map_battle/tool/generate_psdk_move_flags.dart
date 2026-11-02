import 'dart:convert';
import 'dart:io';

void main(List<String> arguments) {
  try {
    String? sourcePath;
    var outputPath = 'lib/src/data/generated/psdk_move_flags.dart';
    var check = false;
    for (var index = 0; index < arguments.length; index++) {
      switch (arguments[index]) {
        case '--source-directory':
          if (sourcePath != null || index + 1 >= arguments.length) {
            throw const FormatException('Expected one --source-directory path');
          }
          sourcePath = arguments[++index];
        case '--output':
          if (index + 1 >= arguments.length) {
            throw const FormatException('Expected an --output path');
          }
          outputPath = arguments[++index];
        case '--check':
          check = true;
        default:
          throw FormatException('Unknown argument: ${arguments[index]}');
      }
    }
    if (sourcePath == null) {
      throw const FormatException('Required: --source-directory');
    }
    final sourceDirectory = Directory(sourcePath);
    final sourceFiles = sourceDirectory
        .listSync(followLinks: false)
        .whereType<File>()
        .where((file) => file.path.endsWith('.json'));
    final sources = <String, String>{
      for (final file in sourceFiles)
        file.uri.pathSegments.last: file.readAsStringSync(),
    };
    final output = renderPsdkMoveFlags(sources);
    final target = File(outputPath);
    if (check) {
      if (!target.existsSync() || target.readAsStringSync() != output) {
        stderr.writeln('Generated move flags differ: ${target.path}');
        exitCode = 1;
        return;
      }
      stdout.writeln('Verified ${sources.length} native Studio move flags');
      return;
    }
    target.parent.createSync(recursive: true);
    target.writeAsStringSync(output);
    stdout.writeln('Generated ${sources.length} native Studio move flags');
  } on FormatException catch (error) {
    stderr.writeln(error.message);
    exitCode = 64;
  } on FileSystemException catch (error) {
    stderr.writeln(error);
    exitCode = 64;
  }
}

String renderPsdkMoveFlags(Map<String, String> sources) {
  if (sources.isEmpty) {
    throw const FormatException('No native Studio move JSON files');
  }
  final flags = <String, bool>{};
  final sourceNames = sources.keys.toList()..sort();
  for (final name in sourceNames) {
    final decoded = jsonDecode(sources[name]!);
    if (decoded is! Map<String, dynamic>) {
      throw FormatException('Expected native Studio move object: $name');
    }
    final symbol = decoded['dbSymbol'];
    final kingRockUtility = decoded['isKingRockUtility'];
    if (symbol is! String || kingRockUtility is! bool) {
      throw FormatException('Expected dbSymbol and isKingRockUtility: $name');
    }
    final normalized = symbol.trim().toLowerCase();
    final separated = normalized.replaceAll('-', '_').replaceAll(' ', '_');
    final key = separated.replaceAll('_', '');
    if (!RegExp(r'^[a-z0-9]+$').hasMatch(key)) {
      throw FormatException('Invalid native Studio move identity: $name');
    }
    if (flags.containsKey(key)) {
      throw FormatException('Ambiguous native Studio move identity: $symbol');
    }
    flags[key] = kingRockUtility;
  }
  final ids = flags.keys.toList()..sort();
  final result =
      StringBuffer('''bool? psdkMoveKingRockUtilityForMoveId(String moveId) {
  final normalized = moveId.trim().toLowerCase();
  final separated = normalized.replaceAll('-', '_').replaceAll(' ', '_');
  return _psdkKingRockUtilityByMoveId[separated.replaceAll('_', '')];
}

const _psdkKingRockUtilityByMoveId = <String, bool>{
''');
  for (final id in ids) {
    result.writeln("  '$id': ${flags[id]},");
  }
  result.writeln('};');
  return result.toString();
}
