import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:map_editor/src/application/services/raster_asset_grid_normalizer.dart';
import 'package:map_editor/src/application/services/tileset_atlas_builder.dart';
import 'package:path/path.dart' as p;

const _atlasFileName = 'selbrume_v2_world.png';
const _atlasWidthCells = 32;
const _tileSize = 32;
const _expectedEntryCount = 68;

final class SelbrumeVisualKitOptions {
  SelbrumeVisualKitOptions({
    required Directory projectRoot,
    Directory? outputDirectory,
    File? manifestFile,
  })  : projectRoot = Directory(p.normalize(p.absolute(projectRoot.path))),
        outputDirectory = Directory(
          p.normalize(
            p.absolute(
              (outputDirectory ??
                      Directory(
                        p.join(
                          projectRoot.path,
                          'assets',
                          'tilesets',
                          'v2',
                        ),
                      ))
                  .path,
            ),
          ),
        ),
        manifestFile = File(
          p.normalize(
            p.absolute(
              (manifestFile ??
                      File(
                        p.join(
                          projectRoot.path,
                          'assets',
                          'provenance',
                          'selbrume_v2_visual_kit.json',
                        ),
                      ))
                  .path,
            ),
          ),
        );

  final Directory projectRoot;
  final Directory outputDirectory;
  final File manifestFile;
}

final class SelbrumeVisualKitBuildResult {
  const SelbrumeVisualKitBuildResult({
    required this.atlasFile,
    required this.manifestFile,
    required this.atlasSha256,
    required this.entryCount,
  });

  final File atlasFile;
  final File manifestFile;
  final String atlasSha256;
  final int entryCount;
}

final class _CategoryPolicy {
  const _CategoryPolicy({
    required this.directoryName,
    required this.idSegment,
    required this.defaultLayerId,
    required this.collisionIntent,
  });

  final String directoryName;
  final String idSegment;
  final String defaultLayerId;
  final String collisionIntent;
}

const _categoryPolicies = <_CategoryPolicy>[
  _CategoryPolicy(
    directoryName: 'houses',
    idSegment: 'village_house',
    defaultLayerId: 'l_tile_structures',
    collisionIntent: 'solid_building_footprint_with_authored_door_access',
  ),
  _CategoryPolicy(
    directoryName: 'vegetation',
    idSegment: 'nature',
    defaultLayerId: 'l_tile_ground',
    collisionIntent: 'decorative_by_default_tree_trunks_authored_per_map',
  ),
  _CategoryPolicy(
    directoryName: 'props',
    idSegment: 'village_prop',
    defaultLayerId: 'l_tile_structures',
    collisionIntent: 'small_solid_prop_unless_authored_as_ground_decor',
  ),
  _CategoryPolicy(
    directoryName: 'rocks',
    idSegment: 'coast_rock',
    defaultLayerId: 'l_tile_structures',
    collisionIntent: 'solid_natural_obstacle',
  ),
  _CategoryPolicy(
    directoryName: 'port',
    idSegment: 'port_module',
    defaultLayerId: 'l_tile_structures',
    collisionIntent: 'solid_port_structure_with_authored_walkable_decks',
  ),
  _CategoryPolicy(
    directoryName: 'marsh',
    idSegment: 'marsh_module',
    defaultLayerId: 'l_tile_ground',
    collisionIntent: 'authored_per_module_water_or_walkable_deck',
  ),
];

Future<SelbrumeVisualKitBuildResult> buildSelbrumeVisualKit(
  SelbrumeVisualKitOptions options,
) async {
  final sourceRoot = Directory(
    p.join(options.projectRoot.path, 'assets', 'sources', 'v2'),
  );
  if (!await sourceRoot.exists()) {
    throw StateError('Missing approved V2 source root: ${sourceRoot.path}');
  }

  final prepared = <_PreparedSource>[];
  for (final policy in _categoryPolicies) {
    final directory = Directory(p.join(sourceRoot.path, policy.directoryName));
    if (!await directory.exists()) {
      throw StateError('Missing V2 source category: ${directory.path}');
    }
    final files = directory
        .listSync(followLinks: false)
        .whereType<File>()
        .where((file) => p.extension(file.path).toLowerCase() == '.png')
        .toList(growable: false)
      ..sort((left, right) => p.basename(left.path).compareTo(
            p.basename(right.path),
          ));
    for (final file in files) {
      final bytes = await file.readAsBytes();
      final source = img.decodePng(bytes);
      if (source == null) {
        throw FormatException('Invalid PNG source: ${file.path}');
      }
      final normalizedBytes = normalizeRasterAssetToGrid(
        RasterAssetGridNormalizationRequest(
          bytes: bytes,
          gridWidth: _tileSize,
          gridHeight: _tileSize,
          anchor: RasterAssetAnchor.bottomCenter,
          resizeMode: RasterAssetResizeMode.none,
        ),
      );
      final normalized = img.decodePng(normalizedBytes)!;
      prepared.add(
        _PreparedSource(
          policy: policy,
          file: file,
          id: 'el_selbrume_v2_${policy.idSegment}_'
              '${_slug(p.basenameWithoutExtension(file.path))}',
          sourceWidth: source.width,
          sourceHeight: source.height,
          hasRealAlpha: _hasRealAlpha(source),
          sourceSha256: await _sha256Bytes(bytes),
          normalizedBytes: normalizedBytes,
          normalizedSha256: await _sha256Bytes(normalizedBytes),
          widthCells: normalized.width ~/ _tileSize,
          heightCells: normalized.height ~/ _tileSize,
        ),
      );
    }
  }
  if (prepared.length != _expectedEntryCount) {
    throw StateError(
      'Expected $_expectedEntryCount approved V2 sources, found '
      '${prepared.length}.',
    );
  }
  final ids = prepared.map((entry) => entry.id).toSet();
  if (ids.length != prepared.length) {
    throw StateError('V2 source filenames produce duplicate element IDs.');
  }

  var x = 0;
  var y = 0;
  var rowHeight = 0;
  final packed = <_PackedSource>[];
  for (final source in prepared) {
    if (source.widthCells > _atlasWidthCells) {
      throw StateError('${source.id} exceeds the atlas width.');
    }
    if (x + source.widthCells > _atlasWidthCells) {
      y += rowHeight;
      x = 0;
      rowHeight = 0;
    }
    packed.add(_PackedSource(source: source, xCells: x, yCells: y));
    x += source.widthCells;
    rowHeight = math.max(rowHeight, source.heightCells);
  }
  final atlasHeightCells = y + rowHeight;
  final atlasBytes = buildTilesetAtlas(
    widthCells: _atlasWidthCells,
    heightCells: atlasHeightCells,
    tileWidth: _tileSize,
    tileHeight: _tileSize,
    items: [
      for (final entry in packed)
        TilesetAtlasItem(
          id: entry.source.id,
          bytes: entry.source.normalizedBytes,
          xCells: entry.xCells,
          yCells: entry.yCells,
          widthCells: entry.source.widthCells,
          heightCells: entry.source.heightCells,
        ),
    ],
  );
  final atlasSha256 = await _sha256Bytes(atlasBytes);

  await options.outputDirectory.create(recursive: true);
  final atlasFile = File(p.join(options.outputDirectory.path, _atlasFileName));
  await atlasFile.writeAsBytes(atlasBytes, flush: true);

  final manifest = <String, dynamic>{
    'schemaVersion': 1,
    'sourceCorpus': 'chatGPT_user_supplied_2026-07-12',
    'licenseDecision': 'user_supplied_project_owner_approved',
    'referenceImagesUsedAsUnderlays': false,
    'tileSize': _tileSize,
    'atlasRelativePath': 'assets/tilesets/v2/$_atlasFileName',
    'atlasWidthCells': _atlasWidthCells,
    'atlasHeightCells': atlasHeightCells,
    'atlasSha256': atlasSha256,
    'entries': [
      for (final entry in packed)
        <String, dynamic>{
          'id': entry.source.id,
          'name': _humanName(
            p.basenameWithoutExtension(entry.source.file.path),
          ),
          'category': entry.source.policy.directoryName,
          'sourceRelativePath': p.posix.join(
            'assets',
            'sources',
            'v2',
            entry.source.policy.directoryName,
            p.basename(entry.source.file.path),
          ),
          'sourceSha256': entry.source.sourceSha256,
          'normalizedSha256': entry.source.normalizedSha256,
          'sourcePixelSize': <String, int>{
            'width': entry.source.sourceWidth,
            'height': entry.source.sourceHeight,
          },
          'hasRealAlpha': entry.source.hasRealAlpha,
          'anchor': 'bottom_center',
          'recommendedLayerId': _recommendedLayer(entry.source),
          'collisionIntent': entry.source.policy.collisionIntent,
          'source': <String, int>{
            'x': entry.xCells,
            'y': entry.yCells,
            'width': entry.source.widthCells,
            'height': entry.source.heightCells,
          },
        },
    ],
  };
  await options.manifestFile.parent.create(recursive: true);
  await options.manifestFile.writeAsString(
    '${const JsonEncoder.withIndent('  ').convert(manifest)}\n',
    flush: true,
  );

  return SelbrumeVisualKitBuildResult(
    atlasFile: atlasFile,
    manifestFile: options.manifestFile,
    atlasSha256: atlasSha256,
    entryCount: packed.length,
  );
}

String _recommendedLayer(_PreparedSource source) {
  final name = p.basenameWithoutExtension(source.file.path).toLowerCase();
  if (source.policy.directoryName == 'vegetation') {
    return name.contains('arbre') ? 'l_tile_overhead' : 'l_tile_ground';
  }
  if (source.policy.directoryName == 'props' &&
      (name.contains('jardiniere') ||
          name.contains('tas_sel') ||
          name.contains('barque'))) {
    return 'l_tile_ground';
  }
  if (source.policy.directoryName == 'port' &&
      (name.contains('quai') || name.contains('pont'))) {
    return 'l_tile_ground';
  }
  return source.policy.defaultLayerId;
}

bool _hasRealAlpha(img.Image image) {
  for (final pixel in image) {
    if (pixel.a.toInt() < 255) return true;
  }
  return false;
}

String _slug(String input) => input
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
    .replaceAll(RegExp(r'^_+|_+$'), '');

String _humanName(String input) {
  final withoutOrdinal = input.replaceFirst(RegExp(r'^\d+_'), '');
  return withoutOrdinal.replaceAll('_', ' ');
}

Future<String> _sha256Bytes(Uint8List bytes) async {
  final process = await Process.start('shasum', const ['-a', '256']);
  process.stdin.add(bytes);
  await process.stdin.close();
  final stdoutText = await utf8.decoder.bind(process.stdout).join();
  final stderrText = await utf8.decoder.bind(process.stderr).join();
  final exitCode = await process.exitCode;
  if (exitCode != 0) {
    throw ProcessException('shasum', const ['-a', '256'], stderrText, exitCode);
  }
  final digest = stdoutText.trim().split(RegExp(r'\s+')).first;
  if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(digest)) {
    throw FormatException('Unexpected shasum output: $stdoutText');
  }
  return digest;
}

final class _PreparedSource {
  const _PreparedSource({
    required this.policy,
    required this.file,
    required this.id,
    required this.sourceWidth,
    required this.sourceHeight,
    required this.hasRealAlpha,
    required this.sourceSha256,
    required this.normalizedBytes,
    required this.normalizedSha256,
    required this.widthCells,
    required this.heightCells,
  });

  final _CategoryPolicy policy;
  final File file;
  final String id;
  final int sourceWidth;
  final int sourceHeight;
  final bool hasRealAlpha;
  final String sourceSha256;
  final Uint8List normalizedBytes;
  final String normalizedSha256;
  final int widthCells;
  final int heightCells;
}

final class _PackedSource {
  const _PackedSource({
    required this.source,
    required this.xCells,
    required this.yCells,
  });

  final _PreparedSource source;
  final int xCells;
  final int yCells;
}

Future<void> main(List<String> arguments) async {
  Directory? projectRoot;
  for (var index = 0; index < arguments.length; index += 1) {
    if (arguments[index] == '--project-root' && index + 1 < arguments.length) {
      projectRoot = Directory(arguments[++index]);
      continue;
    }
    if (arguments[index] == '--help' || arguments[index] == '-h') {
      stdout.writeln(
        'Usage: dart run tool/build_selbrume_visual_kit.dart '
        '--project-root <selbrume-directory>',
      );
      return;
    }
    throw FormatException(
        'Unknown or incomplete argument: ${arguments[index]}');
  }
  if (projectRoot == null) {
    throw const FormatException('--project-root is required.');
  }
  final result = await buildSelbrumeVisualKit(
    SelbrumeVisualKitOptions(projectRoot: projectRoot),
  );
  stdout.writeln(
    'Built ${result.entryCount} Selbrume V2 assets: '
    '${result.atlasFile.path} (${result.atlasSha256})',
  );
  stdout.writeln('Provenance: ${result.manifestFile.path}');
}
