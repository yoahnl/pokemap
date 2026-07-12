import 'dart:io';
import 'dart:typed_data';

import 'package:map_editor/src/application/services/raster_asset_grid_normalizer.dart';
import 'package:path/path.dart' as p;

const normalizeTilesetUsageExitCode = 64;
const normalizeTilesetDataExitCode = 65;
const normalizeTilesetInputExitCode = 66;
const normalizeTilesetOutputExitCode = 73;

const _usage = 'Usage: dart run tool/normalize_tileset_asset.dart '
    '--input <path> --output <path> --grid-width <pixels> '
    '--grid-height <pixels> [--target-width <pixels> '
    '--target-height <pixels>] --anchor top-left|center|bottom-center '
    '--resize none|contain-nearest [--trim-alpha]';

Future<void> main(List<String> args) async {
  exitCode = await runNormalizeTilesetAsset(args);
}

Future<int> runNormalizeTilesetAsset(
  List<String> args, {
  StringSink? out,
  StringSink? error,
  Future<void> Function()? beforeOutputCreateForTesting,
}) async {
  final outputSink = out ?? stdout;
  final errorSink = error ?? stderr;

  late final _NormalizeOptions options;
  try {
    options = _parseOptions(args);
  } on _UsageException catch (exception) {
    errorSink.writeln('error: ${exception.message}');
    errorSink.writeln(_usage);
    return normalizeTilesetUsageExitCode;
  }

  final inputPath = p.normalize(p.absolute(options.input));
  final outputPath = p.normalize(p.absolute(options.output));
  if (p.equals(inputPath, outputPath)) {
    errorSink.writeln('error: input and output resolve to the same file.');
    return normalizeTilesetOutputExitCode;
  }

  final inputFile = File(inputPath);
  final outputFile = File(outputPath);
  if (await outputFile.exists()) {
    errorSink.writeln('error: output already exists: $outputPath');
    return normalizeTilesetOutputExitCode;
  }
  if (!await inputFile.exists()) {
    errorSink.writeln('error: input file does not exist: $inputPath');
    return normalizeTilesetInputExitCode;
  }

  late final Uint8List inputBytes;
  try {
    inputBytes = await inputFile.readAsBytes();
  } on FileSystemException catch (exception) {
    errorSink.writeln('error: cannot read input: ${exception.message}');
    return normalizeTilesetInputExitCode;
  }

  late final Uint8List normalizedBytes;
  try {
    normalizedBytes = normalizeRasterAssetToGrid(
      RasterAssetGridNormalizationRequest(
        bytes: inputBytes,
        gridWidth: options.gridWidth,
        gridHeight: options.gridHeight,
        targetWidth: options.targetWidth,
        targetHeight: options.targetHeight,
        anchor: options.anchor,
        resizeMode: options.resizeMode,
        trimTransparentBorder: options.trimAlpha,
      ),
    );
  } on ArgumentError catch (exception) {
    errorSink.writeln('error: ${exception.message}');
    return normalizeTilesetDataExitCode;
  } on FormatException catch (exception) {
    errorSink.writeln('error: ${exception.message}');
    return normalizeTilesetDataExitCode;
  } on StateError catch (exception) {
    errorSink.writeln('error: ${exception.message}');
    return normalizeTilesetDataExitCode;
  }

  try {
    await outputFile.parent.create(recursive: true);
    await beforeOutputCreateForTesting?.call();
    await _writeNewFileExclusively(outputFile, normalizedBytes);
  } on FileSystemException catch (exception) {
    errorSink.writeln('error: cannot write output: ${exception.message}');
    return normalizeTilesetOutputExitCode;
  }

  outputSink.writeln('Wrote normalized raster asset: $outputPath');
  return 0;
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

_NormalizeOptions _parseOptions(List<String> args) {
  final values = <String, String>{};
  var trimAlpha = false;
  for (var index = 0; index < args.length; index += 1) {
    final argument = args[index];
    if (argument == '--trim-alpha') {
      if (trimAlpha) {
        throw const _UsageException('Duplicate option: --trim-alpha.');
      }
      trimAlpha = true;
      continue;
    }
    if (!_valueOptions.contains(argument)) {
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

  for (final requiredOption in _requiredOptions) {
    if (!values.containsKey(requiredOption)) {
      throw _UsageException('Missing required option: $requiredOption.');
    }
  }

  final gridWidth = _parseInt(values, '--grid-width');
  final gridHeight = _parseInt(values, '--grid-height');
  final hasTargetWidth = values.containsKey('--target-width');
  final hasTargetHeight = values.containsKey('--target-height');
  if (hasTargetWidth != hasTargetHeight) {
    throw const _UsageException(
      '--target-width and --target-height must be supplied together.',
    );
  }

  final anchor = switch (values['--anchor']) {
    'top-left' => RasterAssetAnchor.topLeft,
    'center' => RasterAssetAnchor.center,
    'bottom-center' => RasterAssetAnchor.bottomCenter,
    _ => throw const _UsageException(
        '--anchor must be top-left|center|bottom-center.',
      ),
  };
  final resizeMode = switch (values['--resize']) {
    'none' => RasterAssetResizeMode.none,
    'contain-nearest' => RasterAssetResizeMode.containNearest,
    _ => throw const _UsageException(
        '--resize must be none|contain-nearest.',
      ),
  };

  return _NormalizeOptions(
    input: values['--input']!,
    output: values['--output']!,
    gridWidth: gridWidth,
    gridHeight: gridHeight,
    targetWidth: hasTargetWidth ? _parseInt(values, '--target-width') : null,
    targetHeight: hasTargetHeight ? _parseInt(values, '--target-height') : null,
    anchor: anchor,
    resizeMode: resizeMode,
    trimAlpha: trimAlpha,
  );
}

int _parseInt(Map<String, String> values, String option) {
  final parsed = int.tryParse(values[option]!);
  if (parsed == null) {
    throw _UsageException('$option must be an integer.');
  }
  return parsed;
}

const _valueOptions = <String>{
  '--input',
  '--output',
  '--grid-width',
  '--grid-height',
  '--target-width',
  '--target-height',
  '--anchor',
  '--resize',
};

const _requiredOptions = <String>{
  '--input',
  '--output',
  '--grid-width',
  '--grid-height',
  '--anchor',
  '--resize',
};

final class _NormalizeOptions {
  const _NormalizeOptions({
    required this.input,
    required this.output,
    required this.gridWidth,
    required this.gridHeight,
    required this.targetWidth,
    required this.targetHeight,
    required this.anchor,
    required this.resizeMode,
    required this.trimAlpha,
  });

  final String input;
  final String output;
  final int gridWidth;
  final int gridHeight;
  final int? targetWidth;
  final int? targetHeight;
  final RasterAssetAnchor anchor;
  final RasterAssetResizeMode resizeMode;
  final bool trimAlpha;
}

final class _UsageException implements Exception {
  const _UsageException(this.message);

  final String message;
}
