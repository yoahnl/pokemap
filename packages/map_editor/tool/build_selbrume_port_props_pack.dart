import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

const int selbrumePortPropsPackDivergenceExitCode = 2;
const int _tileSize = 32;

const String selbrumePortPropsPackDirectory =
    'assets/sources/port_reference_v3/props_pack_v1';
const String selbrumePortPropsGeneratedSheetPath =
    '$selbrumePortPropsPackDirectory/generated_missing_props_alpha.png';
const String _barrelSourcePath = 'assets/sources/v2/props/13_baril_haut.png';
const String _cargoCratesSourcePath =
    'assets/sources/v2/port/03_caisses_port.png';
const String _legacyPortPropsPath = 'assets/tilesets/selbrume_port_props.png';

const String selbrumePortBarrelPlainPath =
    '$selbrumePortPropsPackDirectory/barrel_plain.png';
const String selbrumePortBarrelPairPath =
    '$selbrumePortPropsPackDirectory/barrel_pair.png';
const String selbrumePortCargoCratesClosedPath =
    '$selbrumePortPropsPackDirectory/cargo_crates_closed.png';
const String selbrumePortRopeCoilPlainPath =
    '$selbrumePortPropsPackDirectory/rope_coil_plain.png';
const String selbrumePortGreenNettedBarrelPath =
    '$selbrumePortPropsPackDirectory/green_netted_barrel.png';
const String selbrumePortGroundNetRopeHeapPath =
    '$selbrumePortPropsPackDirectory/ground_net_rope_heap.png';
const String selbrumePortFishingGearBucketPath =
    '$selbrumePortPropsPackDirectory/fishing_gear_bucket.png';
const String selbrumePortFishNoticeBoardPath =
    '$selbrumePortPropsPackDirectory/fish_notice_board.png';
const String selbrumePortBarrelPlanterPath =
    '$selbrumePortPropsPackDirectory/barrel_planter.png';
const String selbrumePortPropsPackContactSheetPath =
    '$selbrumePortPropsPackDirectory/port_props_pack_contact_sheet.png';

const List<String> selbrumePortPropsPackOutputPaths = <String>[
  selbrumePortBarrelPlainPath,
  selbrumePortBarrelPairPath,
  selbrumePortCargoCratesClosedPath,
  selbrumePortRopeCoilPlainPath,
  selbrumePortGreenNettedBarrelPath,
  selbrumePortGroundNetRopeHeapPath,
  selbrumePortFishingGearBucketPath,
  selbrumePortFishNoticeBoardPath,
  selbrumePortBarrelPlanterPath,
  selbrumePortPropsPackContactSheetPath,
];

final class SelbrumePortPropsPackOptions {
  SelbrumePortPropsPackOptions({
    required Directory projectRoot,
    this.write = false,
  }) : projectRoot = Directory(p.normalize(p.absolute(projectRoot.path)));

  final Directory projectRoot;
  final bool write;
}

final class SelbrumePortPropsPackResult {
  const SelbrumePortPropsPackResult({
    required this.exitCode,
    required this.divergentRelativePaths,
    required this.outputCount,
  });

  final int exitCode;
  final List<String> divergentRelativePaths;
  final int outputCount;
}

SelbrumePortPropsPackOptions parseSelbrumePortPropsPackOptions(
  List<String> arguments,
) {
  Directory? projectRoot;
  bool? write;
  for (var index = 0; index < arguments.length; index += 1) {
    switch (arguments[index]) {
      case '--project-root':
        if (++index >= arguments.length || arguments[index].trim().isEmpty) {
          throw const FormatException('--project-root requires a path.');
        }
        projectRoot = Directory(arguments[index]);
        break;
      case '--write':
        if (write != null) {
          throw const FormatException(
              'Choose exactly one of --check or --write.');
        }
        write = true;
        break;
      case '--check':
        if (write != null) {
          throw const FormatException(
              'Choose exactly one of --check or --write.');
        }
        write = false;
        break;
      default:
        throw FormatException('Unknown argument: ${arguments[index]}');
    }
  }
  if (projectRoot == null) {
    throw const FormatException('--project-root is required.');
  }
  if (write == null) {
    throw const FormatException('Choose exactly one of --check or --write.');
  }
  return SelbrumePortPropsPackOptions(
    projectRoot: projectRoot,
    write: write,
  );
}

Future<SelbrumePortPropsPackResult> buildSelbrumePortPropsPack(
  SelbrumePortPropsPackOptions options,
) async {
  final root = await _validatedProjectRoot(options.projectRoot);
  final generatedSheet =
      await _decodePng(root, selbrumePortPropsGeneratedSheetPath);
  final barrelSource = await _decodePng(root, _barrelSourcePath);
  final cargoCratesSource = await _decodePng(root, _cargoCratesSourcePath);
  final legacyPortProps = await _decodePng(root, _legacyPortPropsPath);

  if (generatedSheet.width % 3 != 0 || generatedSheet.height % 2 != 0) {
    throw StateError('The generated props sheet must use an exact 3x2 grid.');
  }
  if (legacyPortProps.width < 91 || legacyPortProps.height < 224) {
    throw StateError(
        'The legacy port props atlas is too small for the rope crop.');
  }

  final barrelPlain = _normalizeBottomCenter(
    barrelSource,
    widthCells: 1,
    heightCells: 2,
  );
  final barrelPair = _buildBarrelPair(barrelSource);
  final cargoCrates = _normalizeBottomCenter(
    cargoCratesSource,
    widthCells: 2,
    heightCells: 2,
  );
  final ropeCoil = _normalizeBottomCenter(
    img.copyCrop(
      legacyPortProps,
      x: 36,
      y: 193,
      width: 55,
      height: 31,
    ),
    widthCells: 2,
    heightCells: 2,
  );

  final generated = <String, img.Image>{};
  for (final spec in _generatedPropSpecs) {
    generated[spec.relativePath] = _normalizeBottomCenter(
      _generatedSheetSlot(
        generatedSheet,
        column: spec.column,
        row: spec.row,
      ),
      widthCells: spec.widthCells,
      heightCells: spec.heightCells,
    );
  }

  final images = <String, img.Image>{
    selbrumePortBarrelPlainPath: barrelPlain,
    selbrumePortBarrelPairPath: barrelPair,
    selbrumePortCargoCratesClosedPath: cargoCrates,
    selbrumePortRopeCoilPlainPath: ropeCoil,
    ...generated,
  };
  images[selbrumePortPropsPackContactSheetPath] =
      _buildContactSheet(<img.Image>[
    for (final path in selbrumePortPropsPackOutputPaths.take(9)) images[path]!,
  ]);

  final desiredBytes = <String, Uint8List>{
    for (final path in selbrumePortPropsPackOutputPaths)
      path: Uint8List.fromList(img.encodePng(images[path]!)),
  };
  final divergent = <String>[];
  for (final entry in desiredBytes.entries) {
    final file = File(p.join(root.path, entry.key));
    if (!await file.exists() ||
        !_sameBytes(await file.readAsBytes(), entry.value)) {
      divergent.add(entry.key);
    }
  }

  if (options.write) {
    for (final path in selbrumePortPropsPackOutputPaths) {
      final file = File(p.join(root.path, path));
      final bytes = desiredBytes[path]!;
      if (await file.exists() && _sameBytes(await file.readAsBytes(), bytes)) {
        continue;
      }
      await _atomicWrite(file, bytes);
    }
  }

  return SelbrumePortPropsPackResult(
    exitCode: options.write || divergent.isEmpty
        ? 0
        : selbrumePortPropsPackDivergenceExitCode,
    divergentRelativePaths:
        options.write ? const <String>[] : List<String>.unmodifiable(divergent),
    outputCount: desiredBytes.length,
  );
}

img.Image _generatedSheetSlot(
  img.Image source, {
  required int column,
  required int row,
}) {
  final cellWidth = source.width ~/ 3;
  final cellHeight = source.height ~/ 2;
  return img.copyCrop(
    source,
    x: column * cellWidth,
    y: row * cellHeight,
    width: cellWidth,
    height: cellHeight,
  );
}

img.Image _buildBarrelPair(img.Image source) {
  final barrel = _cleanAndTrim(source);
  final pairSource = img.Image(
    width: barrel.width * 2 - math.max(2, barrel.width ~/ 6),
    height: barrel.height + math.max(2, barrel.height ~/ 10),
    numChannels: 4,
  );
  img.compositeImage(pairSource, barrel);
  img.compositeImage(
    pairSource,
    barrel,
    dstX: pairSource.width - barrel.width,
    dstY: pairSource.height - barrel.height,
  );
  return _normalizeBottomCenter(
    pairSource,
    widthCells: 2,
    heightCells: 2,
  );
}

img.Image _normalizeBottomCenter(
  img.Image source, {
  required int widthCells,
  required int heightCells,
}) {
  final clean = _cleanAndTrim(source);
  final targetWidth = widthCells * _tileSize;
  final targetHeight = heightCells * _tileSize;
  final scale = math.min(
    (targetWidth - 4) / clean.width,
    (targetHeight - 2) / clean.height,
  );
  final resized = img.copyResize(
    clean,
    width: math.max(1, (clean.width * scale).floor()),
    height: math.max(1, (clean.height * scale).floor()),
    interpolation: img.Interpolation.nearest,
  );
  final result = img.Image(
    width: targetWidth,
    height: targetHeight,
    numChannels: 4,
  );
  img.compositeImage(
    result,
    resized,
    dstX: (targetWidth - resized.width) ~/ 2,
    dstY: targetHeight - resized.height,
  );
  return result;
}

img.Image _cleanAndTrim(img.Image source) {
  final clean = source.convert(numChannels: 4);
  var left = clean.width;
  var top = clean.height;
  var right = -1;
  var bottom = -1;
  for (var y = 0; y < clean.height; y += 1) {
    for (var x = 0; x < clean.width; x += 1) {
      final pixel = clean.getPixel(x, y);
      if (pixel.a.toInt() < 64) {
        clean.setPixelRgba(x, y, 0, 0, 0, 0);
        continue;
      }
      clean.setPixelRgba(
        x,
        y,
        pixel.r.toInt(),
        pixel.g.toInt(),
        pixel.b.toInt(),
        255,
      );
      left = math.min(left, x);
      right = math.max(right, x);
      top = math.min(top, y);
      bottom = math.max(bottom, y);
    }
  }
  if (right < left || bottom < top) {
    throw StateError('A props source slot is fully transparent.');
  }
  return img.copyCrop(
    clean,
    x: left,
    y: top,
    width: right - left + 1,
    height: bottom - top + 1,
  );
}

img.Image _buildContactSheet(List<img.Image> images) {
  const columns = 3;
  const slotWidth = 3 * _tileSize;
  const slotHeight = 2 * _tileSize;
  final result = img.Image(
    width: columns * slotWidth,
    height: 3 * slotHeight,
    numChannels: 4,
  );
  for (var index = 0; index < images.length; index += 1) {
    final image = images[index];
    final column = index % columns;
    final row = index ~/ columns;
    img.compositeImage(
      result,
      image,
      dstX: column * slotWidth + (slotWidth - image.width) ~/ 2,
      dstY: row * slotHeight + slotHeight - image.height,
    );
  }
  return result;
}

Future<img.Image> _decodePng(Directory root, String relativePath) async {
  final file = File(p.join(root.path, relativePath));
  if (!await file.exists()) {
    throw StateError('Missing props source: $relativePath');
  }
  final decoded = img.decodePng(await file.readAsBytes());
  if (decoded == null) {
    throw StateError('Invalid PNG props source: $relativePath');
  }
  return decoded.convert(numChannels: 4);
}

Future<Directory> _validatedProjectRoot(Directory requested) async {
  if (!await requested.exists()) {
    throw StateError('Project root does not exist: ${requested.path}');
  }
  final resolved = Directory(await requested.resolveSymbolicLinks());
  if (!await File(p.join(resolved.path, 'project.json')).exists()) {
    throw StateError('Missing project.json in ${resolved.path}.');
  }
  return resolved;
}

Future<void> _atomicWrite(File destination, Uint8List bytes) async {
  await destination.parent.create(recursive: true);
  final temporary = File('${destination.path}.props-pack-$pid.tmp');
  try {
    if (await temporary.exists()) await temporary.delete();
    await temporary.writeAsBytes(bytes, flush: true);
    await temporary.rename(destination.path);
  } finally {
    if (await temporary.exists()) await temporary.delete();
  }
}

bool _sameBytes(List<int> left, List<int> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index += 1) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

const List<_GeneratedPropSpec> _generatedPropSpecs = <_GeneratedPropSpec>[
  _GeneratedPropSpec(
    relativePath: selbrumePortGreenNettedBarrelPath,
    column: 0,
    row: 0,
    widthCells: 2,
    heightCells: 2,
  ),
  _GeneratedPropSpec(
    relativePath: selbrumePortGroundNetRopeHeapPath,
    column: 1,
    row: 0,
    widthCells: 3,
    heightCells: 2,
  ),
  _GeneratedPropSpec(
    relativePath: selbrumePortFishingGearBucketPath,
    column: 2,
    row: 0,
    widthCells: 2,
    heightCells: 2,
  ),
  _GeneratedPropSpec(
    relativePath: selbrumePortFishNoticeBoardPath,
    column: 0,
    row: 1,
    widthCells: 2,
    heightCells: 2,
  ),
  _GeneratedPropSpec(
    relativePath: selbrumePortBarrelPlanterPath,
    column: 1,
    row: 1,
    widthCells: 1,
    heightCells: 2,
  ),
];

final class _GeneratedPropSpec {
  const _GeneratedPropSpec({
    required this.relativePath,
    required this.column,
    required this.row,
    required this.widthCells,
    required this.heightCells,
  });

  final String relativePath;
  final int column;
  final int row;
  final int widthCells;
  final int heightCells;
}

Future<void> main(List<String> arguments) async {
  try {
    final options = parseSelbrumePortPropsPackOptions(arguments);
    final result = await buildSelbrumePortPropsPack(options);
    if (result.divergentRelativePaths.isEmpty) {
      stdout.writeln('Selbrume Port props pack is up to date.');
    } else {
      stderr.writeln('Selbrume Port props pack divergence:');
      for (final path in result.divergentRelativePaths) {
        stderr.writeln('  $path');
      }
    }
    exitCode = result.exitCode;
  } catch (error, stackTrace) {
    stderr.writeln('Selbrume Port props pack build failed: $error');
    stderr.writeln(stackTrace);
    exitCode = 1;
  }
}
