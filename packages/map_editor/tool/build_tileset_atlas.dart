import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:map_editor/src/application/services/tileset_atlas_builder.dart';
import 'package:path/path.dart' as p;

const buildTilesetAtlasUsageExitCode = 64;
const buildTilesetAtlasDataExitCode = 65;
const buildTilesetAtlasInputExitCode = 66;
const buildTilesetAtlasOutputExitCode = 73;

const _usage = 'Usage: dart run tool/build_tileset_atlas.dart '
    '--layout <ATLAS_LAYOUTS.json> --atlas-id <id> --input-dir <dir> '
    '--output <png>';

Future<void> main(List<String> args) async {
  exitCode = await runBuildTilesetAtlas(args);
}

Future<int> runBuildTilesetAtlas(
  List<String> args, {
  StringSink? out,
  StringSink? error,
  Future<void> Function()? beforeOutputCreateForTesting,
}) async {
  final outputSink = out ?? stdout;
  final errorSink = error ?? stderr;

  late final _BuildAtlasOptions options;
  try {
    options = _parseOptions(args);
  } on _UsageException catch (exception) {
    errorSink.writeln('error: ${exception.message}');
    errorSink.writeln(_usage);
    return buildTilesetAtlasUsageExitCode;
  }

  final layoutFile = File(p.normalize(p.absolute(options.layout)));
  final inputDirectory = Directory(
    p.normalize(p.absolute(options.inputDirectory)),
  );
  final outputFile = File(p.normalize(p.absolute(options.output)));
  if (await outputFile.exists()) {
    errorSink.writeln('error: output already exists: ${outputFile.path}');
    return buildTilesetAtlasOutputExitCode;
  }
  if (!await layoutFile.exists()) {
    errorSink.writeln('error: layout file does not exist: ${layoutFile.path}');
    return buildTilesetAtlasInputExitCode;
  }
  if (!await inputDirectory.exists()) {
    errorSink.writeln(
      'error: input directory does not exist: ${inputDirectory.path}',
    );
    return buildTilesetAtlasInputExitCode;
  }

  late final String layoutJson;
  try {
    layoutJson = await layoutFile.readAsString();
  } on FileSystemException catch (exception) {
    errorSink.writeln('error: cannot read layout: ${exception.message}');
    return buildTilesetAtlasInputExitCode;
  }

  late final Uint8List atlasBytes;
  try {
    atlasBytes = await buildTilesetAtlasFromLayoutJson(
      layoutJson: layoutJson,
      atlasId: options.atlasId,
      inputDirectory: inputDirectory,
    );
  } on FormatException catch (exception) {
    errorSink.writeln('error: ${exception.message}');
    return buildTilesetAtlasDataExitCode;
  } on ArgumentError catch (exception) {
    errorSink.writeln('error: ${exception.message}');
    return buildTilesetAtlasDataExitCode;
  } on FileSystemException catch (exception) {
    errorSink.writeln('error: cannot read atlas item: ${exception.message}');
    return buildTilesetAtlasInputExitCode;
  }

  try {
    await outputFile.parent.create(recursive: true);
    await beforeOutputCreateForTesting?.call();
    await _writeNewFileExclusively(outputFile, atlasBytes);
  } on FileSystemException catch (exception) {
    errorSink.writeln('error: cannot write output: ${exception.message}');
    return buildTilesetAtlasOutputExitCode;
  }

  outputSink.writeln('Wrote tileset atlas: ${outputFile.path}');
  return 0;
}

/// Parses and builds this supported `ATLAS_LAYOUTS.json` schema:
///
/// ```json
/// {"atlases":{"ts_id":{"widthCells":16,"heightCells":16,
/// "tileWidth":32,"tileHeight":32,"items":[{"id":"el",
/// "file":"el.png","x":0,"y":0,"width":1,"height":1}]}}}
/// ```
///
/// Every item file must be a relative path below [inputDirectory]. Absolute
/// paths, parent (`..`) segments, and symbolic-link escapes are rejected.
Future<Uint8List> buildTilesetAtlasFromLayoutJson({
  required String layoutJson,
  required String atlasId,
  required Directory inputDirectory,
  Future<void> Function()? afterItemPathResolvedForTesting,
}) async {
  final Object? decoded = jsonDecode(layoutJson);
  final root = _expectMap(decoded, 'layout root');
  final atlases = _expectMap(root['atlases'], 'atlases');
  final atlas = _expectMap(atlases[atlasId], 'atlas "$atlasId"');
  final itemDefinitions = _expectList(atlas['items'], 'items');

  if (!await inputDirectory.exists()) {
    throw ArgumentError('Input directory does not exist.');
  }
  final resolvedInputDirectory = await inputDirectory.resolveSymbolicLinks();
  final items = <TilesetAtlasItem>[];
  for (var index = 0; index < itemDefinitions.length; index += 1) {
    final item = _expectMap(itemDefinitions[index], 'items[$index]');
    final id = _expectString(item['id'], 'items[$index].id');
    final relativeFile = _expectString(
      item['file'],
      'items[$index].file',
    );
    _validateRelativeItemPath(relativeFile, index);

    final file = File(p.join(inputDirectory.path, relativeFile));
    if (!await file.exists()) {
      throw ArgumentError('Atlas item file does not exist: $relativeFile.');
    }
    final resolvedFile = await file.resolveSymbolicLinks();
    if (!p.isWithin(resolvedInputDirectory, resolvedFile)) {
      throw ArgumentError(
        'Atlas item file escapes the input directory: $relativeFile.',
      );
    }
    await afterItemPathResolvedForTesting?.call();

    items.add(
      TilesetAtlasItem(
        id: id,
        bytes: await File(resolvedFile).readAsBytes(),
        xCells: _expectInt(item['x'], 'items[$index].x'),
        yCells: _expectInt(item['y'], 'items[$index].y'),
        widthCells: _expectInt(item['width'], 'items[$index].width'),
        heightCells: _expectInt(item['height'], 'items[$index].height'),
      ),
    );
  }

  return buildTilesetAtlas(
    widthCells: _expectInt(atlas['widthCells'], 'widthCells'),
    heightCells: _expectInt(atlas['heightCells'], 'heightCells'),
    tileWidth: _expectInt(atlas['tileWidth'], 'tileWidth'),
    tileHeight: _expectInt(atlas['tileHeight'], 'tileHeight'),
    items: items,
  );
}

/// Creates and writes [file] without ever opening a pre-existing path.
///
/// Exclusive creation closes the overwrite race. `dart:io` does not provide
/// perfectly crash-atomic publication across create, open, write, and close;
/// a process crash can therefore leave the newly created file incomplete.
Future<void> _writeNewFileExclusively(File file, Uint8List bytes) async {
  var created = false;
  RandomAccessFile? openedFile;
  try {
    await file.create(exclusive: true);
    created = true;
    openedFile = await file.open(mode: FileMode.writeOnly);
    await openedFile.writeFrom(bytes);
    await openedFile.flush();
    await openedFile.close();
    openedFile = null;
  } catch (_) {
    if (openedFile != null) {
      try {
        await openedFile.close();
      } on FileSystemException {
        // Best effort: deletion below is the important cleanup boundary.
      }
    }
    if (created) {
      try {
        await file.delete();
      } on FileSystemException {
        // Best effort after a failed write of the file created by this call.
      }
    }
    rethrow;
  }
}

void _validateRelativeItemPath(String path, int index) {
  final hasParentSegment = p.posix.split(path).contains('..') ||
      p.windows.split(path).contains('..');
  if (path.isEmpty ||
      p.posix.isAbsolute(path) ||
      p.windows.isAbsolute(path) ||
      hasParentSegment) {
    throw ArgumentError(
      'items[$index].file must be a relative path without ".." segments.',
    );
  }
}

Map<String, dynamic> _expectMap(Object? value, String label) {
  if (value is! Map<String, dynamic>) {
    throw ArgumentError('$label must be a JSON object.');
  }
  return value;
}

List<dynamic> _expectList(Object? value, String label) {
  if (value is! List<dynamic>) {
    throw ArgumentError('$label must be a JSON array.');
  }
  return value;
}

String _expectString(Object? value, String label) {
  if (value is! String || value.isEmpty) {
    throw ArgumentError('$label must be a non-empty string.');
  }
  return value;
}

int _expectInt(Object? value, String label) {
  if (value is! int) {
    throw ArgumentError('$label must be an integer.');
  }
  return value;
}

_BuildAtlasOptions _parseOptions(List<String> args) {
  final values = <String, String>{};
  for (var index = 0; index < args.length; index += 1) {
    final argument = args[index];
    if (!_options.contains(argument)) {
      throw _UsageException('Unknown option: $argument.');
    }
    if (values.containsKey(argument)) {
      throw _UsageException('Duplicate option: $argument.');
    }
    if (index + 1 >= args.length || args[index + 1].startsWith('--')) {
      throw _UsageException('Missing value for $argument.');
    }
    values[argument] = args[index + 1];
    index += 1;
  }
  for (final option in _options) {
    if (!values.containsKey(option)) {
      throw _UsageException('Missing required option: $option.');
    }
  }
  return _BuildAtlasOptions(
    layout: values['--layout']!,
    atlasId: values['--atlas-id']!,
    inputDirectory: values['--input-dir']!,
    output: values['--output']!,
  );
}

const _options = <String>{
  '--layout',
  '--atlas-id',
  '--input-dir',
  '--output',
};

final class _BuildAtlasOptions {
  const _BuildAtlasOptions({
    required this.layout,
    required this.atlasId,
    required this.inputDirectory,
    required this.output,
  });

  final String layout;
  final String atlasId;
  final String inputDirectory;
  final String output;
}

final class _UsageException implements Exception {
  const _UsageException(this.message);

  final String message;
}
