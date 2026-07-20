import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/services/raster_asset_grid_normalizer.dart';
import 'package:map_editor/src/application/services/tileset_atlas_builder.dart';
import 'package:map_editor/src/features/border_studio/application/border_project_element_asset_service.dart';
import 'package:path/path.dart' as p;

const selbrumeStoneChainAtlasId = 'ts_selbrume_cliff_stone_chain_v1';
const selbrumeStoneChainAtlasFileName =
    'falaises_selbrume_pierres_chaine_v1.png';
const selbrumeStoneChainSourceRelativePath =
    'assets/sources/border_studio/stone_chain_v1';
const selbrumeStoneChainAtlasRelativePath =
    'assets/tilesets/$selbrumeStoneChainAtlasFileName';
const selbrumeStoneChainManifestRelativePath =
    'assets/provenance/selbrume_stone_chain_v1.json';

const _tileSize = 32;
const _atlasColumns = 4;
const _atlasRows = 4;
const _anchorX = 16;
const _anchorY = 29;
const _collisionIntent = 'visual_only_no_collision';
const _licenseStatus = 'unverified';
const _generationDate = '2026-07-17';
const _rawContactSheetSha256 =
    '685be70e81d3f566d29b89787f726fdb0792432a43362a5b457ec2cc8ea6fb73';
const _chromaRemovedContactSheetSha256 =
    '77642e18161ab56dde5431c7d0262f2eecf3ccc18776fbce402088c1102278d9';
const _correctiveRawContactSheetSha256 =
    'f3fbf78b6d2dd512c5e6bc2ee0d906a792cae06eb7245bc01a17a181e28b1d35';
const _correctiveChromaRemovedContactSheetSha256 =
    '2ec72f056cf2bb9bc0c1f63be376716ea7763bae74a341e75f59d0721f6bfd7c';
const _replacementRawContactSheetSha256 =
    'a2da7f3b3ace55006033102d8f9cbf82d7b015a31381fbc82100512a4461c528';
const _stoneChainBlueprintId = 'border-blueprint-3';
const _generationPrompt =
    'Create a brand-new ORIGINAL pixel-art contact sheet of exactly 16 '
    'isolated individual coastal cliff stones, arranged in a precise 4 '
    'columns by 4 rows grid. These are source modules for a tile-map editor, '
    'not a finished cliff and not copied/cropped from either reference. Use '
    'the references only to understand the warm grey/taupe/charcoal Selbrume '
    'stone language and upper-left lighting. Every cell must contain exactly '
    'ONE compact stone or pebble with generous empty space around it; no '
    'connected wall segments, no piles spanning cells. Row 1: four medium '
    'squat primary stones. Row 2: one additional medium primary followed by '
    'three smaller secondary stones. Row 3: one secondary stone followed by '
    'three tiny filler pebbles. Row 4: two compact corner-anchor stones '
    'followed by two tapered cap stones. All 16 silhouettes must visibly '
    'differ. Strict crisp low-resolution pixel art, hard pixel edges, no '
    'antialiasing, no blur, no drop shadows, no outlines outside the sprite. '
    'Background must be a single uniform pure chroma magenta #FF00FF across '
    'all empty space. STONES ONLY: absolutely no green, grass, moss, plants, '
    'sand, dirt, soil, water, ocean, foam, waves, beach, wood, text, labels, '
    'grid lines, frame, or scenery. Keep highlights upper-left, darkest '
    'pixels lower-right. Square contact sheet, orthographic game-sprite '
    'view, coherent Pokemon-like coastal village pixel-art style, but '
    'entirely original.';
const _referencePrompt =
    'Original isolated Selbrume stone-only pixel-art sprite; upper-left light; '
    'warm grey, taupe and charcoal palette; transparent background; no grass, '
    'green, moss, sand, soil, water, foam, shadow, text or copied reference '
    'pixels.';
const _correctiveGenerationPrompt = '''Use case: stylized-concept
Asset type: corrective pixel-art contact sheet for four isolated tile-map stone sprites
Input images: Image 1 is a stone-language style reference only; Image 2 is a coastal-map scale and lighting reference only; Image 3 is the existing accepted stone-chain palette and pixel-density reference only. Do not copy, crop, trace, composite, or use any reference as an underlay.
Primary request: Create one brand-new ORIGINAL square contact sheet containing exactly FOUR isolated coastal stone sprites in a precise 2 columns by 2 rows arrangement. Top-left: corner stone variant 1, a low rounded compact chain rock, naturally wide and squat, never tall, vertical, cubic, pillar-like, or monolithic. Top-right: corner stone variant 2, a visibly different low rounded compact chain rock, naturally wide and squat, able to cover a bend without becoming a block. Bottom-left: cap stone variant 1, one tiny rounded compact terminal pebble, not pointed and not elongated. Bottom-right: cap stone variant 2, one visibly different tiny rounded compact terminal pebble, not pointed and not elongated.
Scene/backdrop: perfectly flat, perfectly uniform solid chroma-key magenta #FF00FF across every empty pixel; no grid lines, borders, labels, frames, gradients, texture, lighting variation, floor, or horizon.
Style/medium: crisp handcrafted low-resolution top-down three-quarter RPG pixel art; hard pixel edges; coherent with the existing Selbrume individual stones; entirely original.
Composition/framing: exactly one fully isolated stone centered in each quadrant with generous magenta padding and no overlap between quadrants. The two corner stones must read as low horizontal rounded rocks with approximate width-to-height ratio 1.35–1.7. The two cap stones must read as very small compact rounded pebbles with approximate width-to-height ratio 1.1–1.5. No diagonal silhouette.
Lighting/mood: identical upper-left highlight and lower-right dark pixels across all four, matching the accepted stone-chain atlas.
Color palette: warm grey, taupe, muted charcoal and restrained beige highlights matching Image 3; do not use magenta in the stones.
Constraints: STONES ONLY; exactly four sprites; all four silhouettes unique; no antialiasing, blur, soft edges, cast shadow, contact shadow, detached fragments, or extra pebbles. Corners must be small low rounded chain rocks, never vertical or cubic. Caps must be compact rounded pebbles, never long diagonal slivers.
Avoid: grass, green, moss, plants, sand, dirt, soil, water, ocean, foam, waves, beach, wood, scenery, text, symbols, watermark, grid, connected wall, rock pile spanning cells, cliff segment, tall column, cube, monolith, shard, spike, slash, long diagonal fragment.''';
const _replacementGenerationPrompt = '''Create a brand-new ORIGINAL production
contact sheet for a tile-map editor. Use the supplied Selbrume objective map
and current atlas only as references for palette, scale, pixel density and
upper-left lighting; do not copy, crop, trace or composite any pixels. Exactly
16 disconnected single coastal cliff stones in a strict 4 columns by 4 rows
arrangement, one isolated stone centered in each equal cell, on uniform pure
#FF00FF. Reading order 1-5: compact primary stones, wider than or roughly as
wide as tall, with a pale cap and short darker face, never tall pillars. 6-9:
smaller secondary face stones for a staggered lower row. 10-12: tiny compact
filler pebbles. 13-14: compact corner stones covering a bend without an L, T,
cross or shelf silhouette. 15-16: tiny tapered endpoint stones. All silhouettes
unique, crisp hard-edged low-resolution RPG pixel art in warm grey, taupe,
charcoal and beige. Stones only: no grass, moss, plants, sand, soil, water,
foam, beach, shadow patch, scenery, connected wall, rock pile, grid, labels,
text, frame, antialiasing, blur, glow or watermark.''';

const _allowedOpaqueColors = <(int, int, int)>[
  (48, 45, 40),
  (62, 58, 51),
  (77, 72, 62),
  (91, 85, 72),
  (108, 101, 84),
  (126, 118, 96),
  (145, 136, 109),
  (166, 156, 123),
];

const _spriteSpecs = <_StoneSpriteSpec>[
  _StoneSpriteSpec.primary('primary_01.png', 1),
  _StoneSpriteSpec.primary('primary_02.png', 2),
  _StoneSpriteSpec.primary('primary_03.png', 3),
  _StoneSpriteSpec.primary('primary_04.png', 4),
  _StoneSpriteSpec.primary('primary_05.png', 5),
  _StoneSpriteSpec.secondary('secondary_01.png', 1),
  _StoneSpriteSpec.secondary('secondary_02.png', 2),
  _StoneSpriteSpec.secondary('secondary_03.png', 3),
  _StoneSpriteSpec.secondary('secondary_04.png', 4),
  _StoneSpriteSpec.filler('filler_01.png', 1),
  _StoneSpriteSpec.filler('filler_02.png', 2),
  _StoneSpriteSpec.filler('filler_03.png', 3),
  _StoneSpriteSpec.corner('corner_01.png', 1),
  _StoneSpriteSpec.corner('corner_02.png', 2),
  _StoneSpriteSpec.cap('cap_01.png', 1),
  _StoneSpriteSpec.cap('cap_02.png', 2),
];

final class SelbrumeStoneChainPackOptions {
  SelbrumeStoneChainPackOptions({
    required Directory projectRoot,
    Directory? outputDirectory,
    File? manifestFile,
  })  : projectRoot = Directory(p.normalize(p.absolute(projectRoot.path))),
        outputDirectory = Directory(
          p.normalize(
            p.absolute(
              (outputDirectory ??
                      Directory(
                        p.join(projectRoot.path, 'assets', 'tilesets'),
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
                          'selbrume_stone_chain_v1.json',
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

final class SelbrumeStoneChainPackBuildResult {
  const SelbrumeStoneChainPackBuildResult({
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

Future<SelbrumeStoneChainPackBuildResult> buildSelbrumeStoneChainPack(
  SelbrumeStoneChainPackOptions options,
) async {
  final sourceDirectory = Directory(
    p.joinAll(<String>[
      options.projectRoot.path,
      ...selbrumeStoneChainSourceRelativePath.split('/'),
    ]),
  );
  if (!sourceDirectory.existsSync()) {
    throw StateError(
      'Missing Selbrume stone-chain source directory: ${sourceDirectory.path}',
    );
  }
  _validateExactSourceSet(sourceDirectory);

  final prepared = <_PreparedStone>[];
  for (var index = 0; index < _spriteSpecs.length; index += 1) {
    final spec = _spriteSpecs[index];
    final sourceFile = File(p.join(sourceDirectory.path, spec.fileName));
    final sourceBytes = sourceFile.readAsBytesSync();
    final sourceImage = _decodePng(sourceBytes, spec.fileName);
    final bounds = _validateSourceRaster(spec, sourceImage);
    final normalizedBytes = normalizeRasterAssetToGrid(
      RasterAssetGridNormalizationRequest(
        bytes: sourceBytes,
        gridWidth: _tileSize,
        gridHeight: _tileSize,
        targetWidth: _tileSize,
        targetHeight: _tileSize,
        anchor: RasterAssetAnchor.bottomCenter,
        resizeMode: RasterAssetResizeMode.none,
      ),
    );
    final normalized = _decodePng(normalizedBytes, spec.fileName);
    _validateSourceRaster(spec, normalized);
    prepared.add(
      _PreparedStone(
        spec: spec,
        index: index,
        sourceRelativePath:
            '$selbrumeStoneChainSourceRelativePath/${spec.fileName}',
        sourceSha256: _sha256(sourceBytes),
        normalizedSha256: _sha256(normalizedBytes),
        normalizedBytes: normalizedBytes,
        opaqueBounds: bounds,
      ),
    );
  }
  _requireUniqueHashes(
    prepared.map((entry) => entry.sourceSha256),
    label: 'source',
  );
  _requireUniqueHashes(
    prepared.map((entry) => entry.normalizedSha256),
    label: 'normalized',
  );

  final atlasBytes = buildTilesetAtlas(
    widthCells: _atlasColumns,
    heightCells: _atlasRows,
    tileWidth: _tileSize,
    tileHeight: _tileSize,
    items: <TilesetAtlasItem>[
      for (final entry in prepared)
        TilesetAtlasItem(
          id: entry.spec.id,
          bytes: entry.normalizedBytes,
          xCells: entry.index % _atlasColumns,
          yCells: entry.index ~/ _atlasColumns,
          widthCells: 1,
          heightCells: 1,
        ),
    ],
  );
  final atlasSha256 = _sha256(atlasBytes);
  final atlasFile = File(
    p.join(options.outputDirectory.path, selbrumeStoneChainAtlasFileName),
  );
  await atlasFile.parent.create(recursive: true);
  await atlasFile.writeAsBytes(atlasBytes, flush: true);

  final manifest = <String, Object?>{
    'schemaVersion': 1,
    'atlasId': selbrumeStoneChainAtlasId,
    'atlasRelativePath': selbrumeStoneChainAtlasRelativePath,
    'atlasSha256': atlasSha256,
    'tileSize': <String, int>{'width': _tileSize, 'height': _tileSize},
    'grid': <String, int>{'columns': _atlasColumns, 'rows': _atlasRows},
    'anchor': <String, int>{'x': _anchorX, 'y': _anchorY},
    'collisionIntent': _collisionIntent,
    'licenseStatus': _licenseStatus,
    'generationDate': _generationDate,
    'generationTool': 'built-in imagegen plus deterministic local processing',
    'generationPrompt': _generationPrompt,
    'rawContactSheetSha256': _rawContactSheetSha256,
    'chromaRemovedContactSheetSha256': _chromaRemovedContactSheetSha256,
    'chromaKey': '#FF00FF',
    'chromaRemoval': <String, Object?>{
      'helper': 'remove_chroma_key.py',
      'tolerance': 12,
      'spillCleanup': true,
      'partialAlphaPixels': 0,
    },
    'correctiveGeneration': <String, Object?>{
      'generationDate': _generationDate,
      'generationTool': 'built-in imagegen plus deterministic local processing',
      'generationPrompt': _correctiveGenerationPrompt,
      'rawContactSheetSha256': _correctiveRawContactSheetSha256,
      'chromaRemovedContactSheetSha256':
          _correctiveChromaRemovedContactSheetSha256,
      'chromaKey': '#FF00FF',
      'chromaRemoval': <String, Object?>{
        'helper': 'remove_chroma_key.py',
        'autoKey': 'border',
        'softMatte': true,
        'transparentThreshold': 12,
        'opaqueThreshold': 220,
        'despill': true,
        'partialAlphaPixelsBeforeNormalization': 4501,
        'partialAlphaPixelsAfterNormalization': 0,
      },
      'replacedEntries': <String>[
        'stone_chain_corner_01',
        'stone_chain_corner_02',
        'stone_chain_cap_01',
        'stone_chain_cap_02',
      ],
      'targetOpaqueFootprintsPx': <String, Object?>{
        'stone_chain_corner_01': <String, int>{'width': 22, 'height': 16},
        'stone_chain_corner_02': <String, int>{'width': 20, 'height': 15},
        'stone_chain_cap_01': <String, int>{'width': 11, 'height': 8},
        'stone_chain_cap_02': <String, int>{'width': 9, 'height': 7},
      },
    },
    'replacementGeneration': <String, Object?>{
      'generationDate': _generationDate,
      'generationTool': 'built-in imagegen plus deterministic local processing',
      'generationPrompt': _replacementGenerationPrompt,
      'rawContactSheetSha256': _replacementRawContactSheetSha256,
      'chromaKey': '#FF00FF',
      'chromaRemoval': <String, Object?>{
        'method': 'deterministic RGB threshold before palette quantization',
        'binaryAlpha': true,
      },
      'replacedEntries': <String>[
        for (final spec in _spriteSpecs) spec.id,
      ],
      'targetOpaqueFootprintsPx': <String, Object?>{
        for (var index = 0; index < _spriteSpecs.length; index += 1)
          _spriteSpecs[index].id: <String, int>{
            'width': _replacementSpecs[index].targetWidth,
            'height': _replacementSpecs[index].targetHeight,
          },
      },
    },
    'normalization': <String, Object?>{
      'cellExtraction': 'row-major 4x4 contact sheet',
      'resampling': 'nearest-neighbour',
      'alpha': 'binary',
      'palette': <String>[
        for (final color in _allowedOpaqueColors)
          '#${color.$1.toRadixString(16).padLeft(2, '0')}'
              '${color.$2.toRadixString(16).padLeft(2, '0')}'
              '${color.$3.toRadixString(16).padLeft(2, '0')}',
      ],
    },
    'referenceImages': <String>[
      'assets/tilesets/cliff.png',
      'assets/tilesets/objectif.png',
    ],
    'referenceImagesUsedAsUnderlays': false,
    'protectedReferencePixelsCopied': false,
    'entries': <Object?>[
      for (final entry in prepared)
        <String, Object?>{
          'id': entry.spec.id,
          'role': entry.spec.role,
          'sourceRelativePath': entry.sourceRelativePath,
          'prompt': '${entry.spec.prompt} $_referencePrompt',
          'sourceSha256': entry.sourceSha256,
          'normalizedSha256': entry.normalizedSha256,
          'opaqueBoundsPx': <String, int>{
            'x': entry.opaqueBounds.x,
            'y': entry.opaqueBounds.y,
            'width': entry.opaqueBounds.width,
            'height': entry.opaqueBounds.height,
          },
          'opaqueFootprintPx': <String, int>{
            'width': entry.opaqueBounds.width,
            'height': entry.opaqueBounds.height,
          },
          'anchor': <String, int>{'x': _anchorX, 'y': _anchorY},
          'atlasCell': <String, int>{
            'column': entry.index % _atlasColumns,
            'row': entry.index ~/ _atlasColumns,
            'widthCells': 1,
            'heightCells': 1,
          },
          'licenseStatus': _licenseStatus,
          'collisionIntent': _collisionIntent,
        },
    ],
  };
  await options.manifestFile.parent.create(recursive: true);
  await options.manifestFile.writeAsString(
    '${const JsonEncoder.withIndent('  ').convert(manifest)}\n',
    flush: true,
  );

  return SelbrumeStoneChainPackBuildResult(
    atlasFile: atlasFile,
    manifestFile: options.manifestFile,
    atlasSha256: atlasSha256,
    entryCount: prepared.length,
  );
}

Future<void> main(List<String> arguments) async {
  Directory? projectRoot;
  File? correctiveSheet;
  File? replacementSheet;
  var refreshProjectMetrics = false;
  for (var index = 0; index < arguments.length; index += 1) {
    if (arguments[index] == '--project-root' && index + 1 < arguments.length) {
      projectRoot = Directory(arguments[++index]);
      continue;
    }
    if (arguments[index] == '--corrective-sheet' &&
        index + 1 < arguments.length) {
      correctiveSheet = File(arguments[++index]);
      continue;
    }
    if (arguments[index] == '--replacement-sheet' &&
        index + 1 < arguments.length) {
      replacementSheet = File(arguments[++index]);
      continue;
    }
    if (arguments[index] == '--refresh-project-metrics') {
      refreshProjectMetrics = true;
      continue;
    }
    stderr.writeln(
      'Usage: dart run tool/build_selbrume_stone_chain_pack.dart '
      '--project-root <selbrume-project-root> '
      '[--corrective-sheet <chroma-removed-2x2.png>] '
      '[--replacement-sheet <raw-chroma-4x4.png>] '
      '[--refresh-project-metrics]',
    );
    exitCode = 64;
    return;
  }
  if (projectRoot == null) {
    stderr.writeln('Missing required --project-root.');
    exitCode = 64;
    return;
  }
  if (correctiveSheet != null && replacementSheet != null) {
    stderr.writeln(
      '--corrective-sheet and --replacement-sheet are mutually exclusive.',
    );
    exitCode = 64;
    return;
  }
  try {
    final replacedSources = replacementSheet == null
        ? const <File>[]
        : await applySelbrumeStoneChainReplacementSheet(
            projectRoot: projectRoot,
            rawContactSheet: replacementSheet,
          );
    final correctedSources = correctiveSheet == null
        ? const <File>[]
        : await applySelbrumeStoneChainCorrectiveSheet(
            projectRoot: projectRoot,
            chromaRemovedContactSheet: correctiveSheet,
          );
    final result = await buildSelbrumeStoneChainPack(
      SelbrumeStoneChainPackOptions(projectRoot: projectRoot),
    );
    final refreshedPrimitiveIds = refreshProjectMetrics
        ? await refreshSelbrumeStoneChainMetrics(
            projectRoot: projectRoot,
          )
        : const <String>[];
    stdout.writeln(
      jsonEncode(<String, Object?>{
        'atlas': result.atlasFile.path,
        'manifest': result.manifestFile.path,
        'atlasSha256': result.atlasSha256,
        'entryCount': result.entryCount,
        'correctedSources': <String>[
          for (final file in correctedSources) file.path,
        ],
        'replacedSources': <String>[
          for (final file in replacedSources) file.path,
        ],
        'refreshedPrimitiveIds': refreshedPrimitiveIds,
      }),
    );
  } on Object catch (error) {
    stderr.writeln(error);
    exitCode = 65;
  }
}

/// Replaces the complete 4x4 source set from an imagegen contact sheet.
///
/// The raw sheet keeps a magenta key so the generated artifact remains easy
/// to inspect. This deterministic pass removes that key, quantizes the stone
/// pixels to the approved palette, applies the role-specific footprint, and
/// restores the shared bottom-center anchor.
Future<List<File>> applySelbrumeStoneChainReplacementSheet({
  required Directory projectRoot,
  required File rawContactSheet,
}) async {
  final root = Directory(p.normalize(p.absolute(projectRoot.path)));
  final sourceDirectory = Directory(
    p.joinAll(<String>[
      root.path,
      ...selbrumeStoneChainSourceRelativePath.split('/'),
    ]),
  );
  if (!sourceDirectory.existsSync()) {
    throw StateError(
      'Missing Selbrume stone-chain source directory: ${sourceDirectory.path}',
    );
  }
  if (!rawContactSheet.existsSync()) {
    throw StateError(
      'Missing replacement contact sheet: ${rawContactSheet.path}',
    );
  }
  final sheet = _decodePng(
    rawContactSheet.readAsBytesSync(),
    p.basename(rawContactSheet.path),
  );
  if (sheet.width < 8 || sheet.height < 8) {
    throw StateError('Replacement contact sheet must contain a 4x4 grid.');
  }
  final componentImages = _orderedReplacementComponentImages(sheet);

  final written = <File>[];
  for (var index = 0; index < _spriteSpecs.length; index += 1) {
    final spec = _spriteSpecs[index];
    final target = _replacementSpecs[index];
    final normalized = _normalizeCorrectiveSprite(
      componentImages[index],
      target,
    );
    _validateSourceRaster(spec, normalized);
    final file = File(p.join(sourceDirectory.path, spec.fileName));
    await file.writeAsBytes(img.encodePng(normalized), flush: true);
    written.add(file);
  }
  return List<File>.unmodifiable(written);
}

List<img.Image> _orderedReplacementComponentImages(img.Image sheet) {
  final keyed = sheet.convert(format: img.Format.uint8, numChannels: 4);
  for (final pixel in keyed) {
    final red = pixel.r.toInt();
    final green = pixel.g.toInt();
    final blue = pixel.b.toInt();
    if (red >= 180 && blue >= 180 && red - green >= 60 && blue - green >= 60) {
      pixel
        ..r = 0
        ..g = 0
        ..b = 0
        ..a = 0;
    }
  }

  final visited = List<bool>.filled(keyed.width * keyed.height, false);
  final components = <_ReplacementOpaqueComponent>[];
  for (var y = 0; y < keyed.height; y += 1) {
    for (var x = 0; x < keyed.width; x += 1) {
      final startIndex = y * keyed.width + x;
      if (visited[startIndex] || keyed.getPixel(x, y).a.toInt() == 0) {
        continue;
      }
      final pixels = <int>[startIndex];
      final pending = <int>[startIndex];
      visited[startIndex] = true;
      var left = x;
      var right = x;
      var top = y;
      var bottom = y;
      while (pending.isNotEmpty) {
        final current = pending.removeLast();
        final currentX = current % keyed.width;
        final currentY = current ~/ keyed.width;
        left = math.min(left, currentX);
        right = math.max(right, currentX);
        top = math.min(top, currentY);
        bottom = math.max(bottom, currentY);
        for (var deltaY = -1; deltaY <= 1; deltaY += 1) {
          for (var deltaX = -1; deltaX <= 1; deltaX += 1) {
            if (deltaX == 0 && deltaY == 0) continue;
            final nextX = currentX + deltaX;
            final nextY = currentY + deltaY;
            if (nextX < 0 ||
                nextY < 0 ||
                nextX >= keyed.width ||
                nextY >= keyed.height) {
              continue;
            }
            final nextIndex = nextY * keyed.width + nextX;
            if (visited[nextIndex] ||
                keyed.getPixel(nextX, nextY).a.toInt() == 0) {
              continue;
            }
            visited[nextIndex] = true;
            pixels.add(nextIndex);
            pending.add(nextIndex);
          }
        }
      }
      components.add(
        _ReplacementOpaqueComponent(
          pixels: pixels,
          left: left,
          top: top,
          right: right,
          bottom: bottom,
        ),
      );
    }
  }
  if (components.length < _spriteSpecs.length) {
    throw StateError(
      'Replacement contact sheet must contain at least 16 isolated stones; '
      'found ${components.length}.',
    );
  }
  components.sort((left, right) => right.pixels.length.compareTo(
        left.pixels.length,
      ));
  final selected = components.take(_spriteSpecs.length).toList(growable: false)
    ..sort((left, right) {
      final byY = left.centerY.compareTo(right.centerY);
      return byY != 0 ? byY : left.centerX.compareTo(right.centerX);
    });
  final ordered = <_ReplacementOpaqueComponent>[];
  for (var row = 0; row < _atlasRows; row += 1) {
    final rowComponents = selected
        .skip(row * _atlasColumns)
        .take(_atlasColumns)
        .toList(growable: false)
      ..sort((left, right) => left.centerX.compareTo(right.centerX));
    ordered.addAll(rowComponents);
  }

  return <img.Image>[
    for (final component in ordered)
      _replacementComponentImage(keyed, component),
  ];
}

img.Image _replacementComponentImage(
  img.Image keyed,
  _ReplacementOpaqueComponent component,
) {
  final result = img.Image(
    width: component.right - component.left + 1,
    height: component.bottom - component.top + 1,
    numChannels: 4,
  );
  for (final index in component.pixels) {
    final sourceX = index % keyed.width;
    final sourceY = index ~/ keyed.width;
    final pixel = keyed.getPixel(sourceX, sourceY);
    result.setPixelRgba(
      sourceX - component.left,
      sourceY - component.top,
      pixel.r.toInt(),
      pixel.g.toInt(),
      pixel.b.toInt(),
      pixel.a.toInt(),
    );
  }
  return result;
}

/// Reanalyzes and persists the 16 draft metrics in bp3.
///
/// Source fingerprints intentionally hash the complete encoded atlas, so a
/// four-cell correction invalidates every primitive fingerprint even though
/// the other 12 cells keep identical pixels, bounds, and occupancy. The raw
/// JSON tree is patched in place so unrelated project fields, record order,
/// and historical published revisions remain byte-stable after the same
/// two-space JSON encoding pass.
Future<List<String>> refreshSelbrumeStoneChainMetrics({
  required Directory projectRoot,
}) async {
  final root = Directory(p.normalize(p.absolute(projectRoot.path)));
  final projectFile = File(p.join(root.path, 'project.json'));
  if (!projectFile.existsSync()) {
    throw StateError('Missing Selbrume project manifest: ${projectFile.path}');
  }
  final rawJson =
      jsonDecode(await projectFile.readAsString()) as Map<String, dynamic>;
  final manifest = ProjectManifest.fromJson(rawJson);
  final record = manifest.borderCatalog.recordById(_stoneChainBlueprintId);
  if (record == null) {
    throw StateError('Missing stone-chain blueprint $_stoneChainBlueprintId.');
  }

  const assetService = BorderProjectElementAssetService();
  final refreshedMetrics = <String, BorderPrimitiveAssetMetrics>{};
  for (final primitive in record.draft.definition.primitives) {
    final refreshed = await assetService.reanalyze(
      manifest: manifest,
      projectRootPath: root.path,
      primitive: primitive,
    );
    refreshedMetrics[primitive.id] = refreshed.primitive.currentMetrics;
  }
  final expectedPrimitiveIds = <String>{
    for (final primitive in record.draft.definition.primitives) primitive.id,
  };
  if (expectedPrimitiveIds.length != _spriteSpecs.length ||
      refreshedMetrics.keys
          .toSet()
          .difference(expectedPrimitiveIds)
          .isNotEmpty ||
      expectedPrimitiveIds
          .difference(refreshedMetrics.keys.toSet())
          .isNotEmpty) {
    throw StateError(
      'Expected exactly the 16 stone-chain primitives; found '
      '${refreshedMetrics.keys.toList()..sort()}.',
    );
  }

  final catalogJson = rawJson['borderCatalog'] as Map<String, dynamic>;
  final recordsJson = catalogJson['records'] as List<dynamic>;
  final recordJson = recordsJson.cast<Map<String, dynamic>>().singleWhere(
        (candidate) => candidate['id'] == _stoneChainBlueprintId,
      );
  final draftJson = recordJson['draft'] as Map<String, dynamic>;
  final definitionJson = draftJson['definition'] as Map<String, dynamic>;
  final primitivesJson = (definitionJson['primitives'] as List<dynamic>)
      .cast<Map<String, dynamic>>();
  final patched = <String>[];
  for (final primitiveJson in primitivesJson) {
    final primitiveId = primitiveJson['id'];
    if (primitiveId is! String || !expectedPrimitiveIds.contains(primitiveId)) {
      continue;
    }
    primitiveJson['currentMetrics'] = encodeBorderPrimitiveAssetMetricsJson(
      refreshedMetrics[primitiveId]!,
    );
    patched.add(primitiveId);
  }
  patched.sort();
  if (patched.toSet().length != expectedPrimitiveIds.length) {
    throw StateError(
      'Raw bp3 JSON did not contain every stone-chain primitive.',
    );
  }

  await projectFile.writeAsString(
    '${const JsonEncoder.withIndent('  ').convert(rawJson)}\n',
    flush: true,
  );
  return List<String>.unmodifiable(patched);
}

Future<List<File>> applySelbrumeStoneChainCorrectiveSheet({
  required Directory projectRoot,
  required File chromaRemovedContactSheet,
}) async {
  final root = Directory(p.normalize(p.absolute(projectRoot.path)));
  final sourceDirectory = Directory(
    p.joinAll(<String>[
      root.path,
      ...selbrumeStoneChainSourceRelativePath.split('/'),
    ]),
  );
  if (!sourceDirectory.existsSync()) {
    throw StateError(
      'Missing Selbrume stone-chain source directory: ${sourceDirectory.path}',
    );
  }
  if (!chromaRemovedContactSheet.existsSync()) {
    throw StateError(
      'Missing chroma-removed corrective sheet: '
      '${chromaRemovedContactSheet.path}',
    );
  }
  final sheet = _decodePng(
    chromaRemovedContactSheet.readAsBytesSync(),
    p.basename(chromaRemovedContactSheet.path),
  );
  if (sheet.width < 4 || sheet.height < 4) {
    throw StateError('Corrective contact sheet must contain a 2x2 grid.');
  }

  final written = <File>[];
  for (var index = 0; index < _correctiveSpecs.length; index += 1) {
    final corrective = _correctiveSpecs[index];
    final cellX = index % 2;
    final cellY = index ~/ 2;
    final x0 = cellX * sheet.width ~/ 2;
    final x1 = (cellX + 1) * sheet.width ~/ 2;
    final y0 = cellY * sheet.height ~/ 2;
    final y1 = (cellY + 1) * sheet.height ~/ 2;
    final cell = img.copyCrop(
      sheet,
      x: x0,
      y: y0,
      width: x1 - x0,
      height: y1 - y0,
    );
    final normalized = _normalizeCorrectiveSprite(cell, corrective);
    final spec = _spriteSpecs.singleWhere(
      (candidate) => candidate.fileName == corrective.fileName,
    );
    _validateSourceRaster(spec, normalized);
    final file = File(p.join(sourceDirectory.path, corrective.fileName));
    await file.writeAsBytes(img.encodePng(normalized), flush: true);
    written.add(file);
  }
  return List<File>.unmodifiable(written);
}

img.Image _normalizeCorrectiveSprite(
  img.Image source,
  _CorrectiveSpriteSpec spec,
) {
  final clean = source.convert(
    format: img.Format.uint8,
    numChannels: 4,
  );
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
      final color = _nearestOpaqueColor(
        pixel.r.toInt(),
        pixel.g.toInt(),
        pixel.b.toInt(),
      );
      clean.setPixelRgba(x, y, color.$1, color.$2, color.$3, 255);
      left = math.min(left, x);
      top = math.min(top, y);
      right = math.max(right, x);
      bottom = math.max(bottom, y);
    }
  }
  if (right < left || bottom < top) {
    throw StateError('${spec.fileName} corrective quadrant is transparent.');
  }
  final trimmed = img.copyCrop(
    clean,
    x: left,
    y: top,
    width: right - left + 1,
    height: bottom - top + 1,
  );
  final resized = img.copyResize(
    trimmed,
    width: spec.targetWidth,
    height: spec.targetHeight,
    interpolation: img.Interpolation.linear,
  );
  var resizedLeft = resized.width;
  var resizedRight = -1;
  var resizedBottom = -1;
  for (final pixel in resized) {
    if (pixel.a.toInt() < 32) {
      pixel
        ..r = 0
        ..g = 0
        ..b = 0
        ..a = 0;
      continue;
    }
    final color = _nearestOpaqueColor(
      pixel.r.toInt(),
      pixel.g.toInt(),
      pixel.b.toInt(),
    );
    pixel
      ..r = color.$1
      ..g = color.$2
      ..b = color.$3
      ..a = 255;
    resizedLeft = math.min(resizedLeft, pixel.x);
    resizedRight = math.max(resizedRight, pixel.x);
    resizedBottom = math.max(resizedBottom, pixel.y);
  }
  if (resizedRight < resizedLeft || resizedBottom < 0) {
    throw StateError('${spec.fileName} became transparent while resizing.');
  }
  final result = img.Image(width: _tileSize, height: _tileSize, numChannels: 4);
  img.compositeImage(
    result,
    resized,
    dstX: _anchorX - (resizedLeft + resizedRight) ~/ 2,
    dstY: _anchorY - resizedBottom,
  );
  return result;
}

(int, int, int) _nearestOpaqueColor(int red, int green, int blue) {
  var best = _allowedOpaqueColors.first;
  var bestDistance = 1 << 62;
  for (final candidate in _allowedOpaqueColors) {
    final deltaRed = red - candidate.$1;
    final deltaGreen = green - candidate.$2;
    final deltaBlue = blue - candidate.$3;
    final distance =
        deltaRed * deltaRed + deltaGreen * deltaGreen + deltaBlue * deltaBlue;
    if (distance < bestDistance) {
      best = candidate;
      bestDistance = distance;
    }
  }
  return best;
}

void _validateExactSourceSet(Directory sourceDirectory) {
  final actual = sourceDirectory
      .listSync(followLinks: false)
      .whereType<File>()
      .where((file) => p.extension(file.path).toLowerCase() == '.png')
      .map((file) => p.basename(file.path))
      .toSet();
  final expected = _spriteSpecs.map((spec) => spec.fileName).toSet();
  final missing = expected.difference(actual).toList()..sort();
  final unexpected = actual.difference(expected).toList()..sort();
  if (missing.isNotEmpty || unexpected.isNotEmpty) {
    throw StateError(
      'Stone-chain source set mismatch; missing=$missing; '
      'unexpected=$unexpected',
    );
  }
}

_OpaqueBounds _validateSourceRaster(_StoneSpriteSpec spec, img.Image image) {
  if (image.width != _tileSize || image.height != _tileSize) {
    throw StateError(
      '${spec.fileName} must be exactly ${_tileSize}x$_tileSize px.',
    );
  }
  var minX = image.width;
  var minY = image.height;
  var maxX = -1;
  var maxY = -1;
  var hasTransparentPixel = false;
  for (final pixel in image) {
    final alpha = pixel.a.toInt();
    if (alpha == 0) {
      hasTransparentPixel = true;
      continue;
    }
    if (alpha != 255) {
      throw StateError('${spec.fileName} must use binary alpha only.');
    }
    final color = (pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt());
    if (!_allowedOpaqueColors.contains(color)) {
      throw StateError(
        '${spec.fileName} contains an opaque color outside the approved '
        'stone-only palette: $color.',
      );
    }
    minX = minX < pixel.x ? minX : pixel.x;
    minY = minY < pixel.y ? minY : pixel.y;
    maxX = maxX > pixel.x ? maxX : pixel.x;
    maxY = maxY > pixel.y ? maxY : pixel.y;
  }
  if (!hasTransparentPixel || maxX < minX || maxY < minY) {
    throw StateError(
      '${spec.fileName} must contain real transparency and opaque stone pixels.',
    );
  }
  final bounds = _OpaqueBounds(
    x: minX,
    y: minY,
    width: maxX - minX + 1,
    height: maxY - minY + 1,
  );
  if (minX < 2 || minY < 2 || maxX > 29 || maxY > 29) {
    throw StateError('${spec.fileName} must keep a 2 px transparent margin.');
  }
  if (maxY != _anchorY) {
    throw StateError(
      '${spec.fileName} must touch its bottom-center anchor row y=$_anchorY.',
    );
  }
  if (!spec.accepts(bounds.width, bounds.height)) {
    throw StateError(
      '${spec.fileName} opaque footprint ${bounds.width}x${bounds.height} '
      'does not satisfy the ${spec.role} contract.',
    );
  }
  return bounds;
}

img.Image _decodePng(Uint8List bytes, String fileName) {
  final decoded = img.decodePng(bytes);
  if (decoded == null) {
    throw StateError('$fileName is not a valid PNG.');
  }
  return decoded;
}

void _requireUniqueHashes(Iterable<String> hashes, {required String label}) {
  final values = hashes.toList(growable: false);
  if (values.toSet().length != values.length) {
    throw StateError('Stone-chain $label PNGs must all be unique.');
  }
}

String _sha256(Uint8List bytes) => sha256.convert(bytes).toString();

final class _StoneSpriteSpec {
  const _StoneSpriteSpec._({
    required this.fileName,
    required this.role,
    required this.prompt,
    required this.minimumWidth,
    required this.maximumWidth,
    required this.minimumHeight,
    required this.maximumHeight,
  });

  const _StoneSpriteSpec.primary(String fileName, int variant)
      : this._(
          fileName: fileName,
          role: 'primary',
          prompt: 'Compact individual primary cliff-face stone variant '
              '$variant; pale cap, short darker face and never a tall pillar.',
          minimumWidth: 16,
          maximumWidth: 22,
          minimumHeight: 10,
          maximumHeight: 17,
        );

  const _StoneSpriteSpec.secondary(String fileName, int variant)
      : this._(
          fileName: fileName,
          role: 'secondary',
          prompt: 'Medium individual secondary cliff-face stone variant '
              '$variant.',
          minimumWidth: 10,
          maximumWidth: 18,
          minimumHeight: 8,
          maximumHeight: 14,
        );

  const _StoneSpriteSpec.filler(String fileName, int variant)
      : this._(
          fileName: fileName,
          role: 'filler',
          prompt: 'Tiny isolated filler pebble variant $variant.',
          minimumWidth: 5,
          maximumWidth: 10,
          minimumHeight: 4,
          maximumHeight: 8,
        );

  const _StoneSpriteSpec.corner(String fileName, int variant)
      : this._(
          fileName: fileName,
          role: 'corner',
          prompt: 'Compact individual cliff corner stone variant $variant; '
              'slightly wider than tall and never a multi-stone block.',
          minimumWidth: 15,
          maximumWidth: 24,
          minimumHeight: 13,
          maximumHeight: 20,
        );

  const _StoneSpriteSpec.cap(String fileName, int variant)
      : this._(
          fileName: fileName,
          role: 'cap',
          prompt: 'Very small rounded compact terminal pebble variant '
              '$variant; never pointed, elongated or diagonal.',
          minimumWidth: 7,
          maximumWidth: 14,
          minimumHeight: 6,
          maximumHeight: 12,
        );

  final String fileName;
  final String role;
  final String prompt;
  final int minimumWidth;
  final int maximumWidth;
  final int minimumHeight;
  final int maximumHeight;

  String get id => 'stone_chain_${p.basenameWithoutExtension(fileName)}';

  bool accepts(int width, int height) {
    final inRange = width >= minimumWidth &&
        width <= maximumWidth &&
        height >= minimumHeight &&
        height <= maximumHeight;
    if (!inRange) return false;
    return switch (role) {
      'corner' => width > height,
      'cap' => width >= height,
      _ => true,
    };
  }
}

const _correctiveSpecs = <_CorrectiveSpriteSpec>[
  _CorrectiveSpriteSpec('corner_01.png', 22, 16),
  _CorrectiveSpriteSpec('corner_02.png', 20, 15),
  _CorrectiveSpriteSpec('cap_01.png', 11, 8),
  _CorrectiveSpriteSpec('cap_02.png', 9, 7),
];

const _replacementSpecs = <_CorrectiveSpriteSpec>[
  _CorrectiveSpriteSpec('primary_01.png', 19, 14),
  _CorrectiveSpriteSpec('primary_02.png', 18, 17),
  _CorrectiveSpriteSpec('primary_03.png', 18, 17),
  _CorrectiveSpriteSpec('primary_04.png', 19, 14),
  _CorrectiveSpriteSpec('primary_05.png', 17, 17),
  _CorrectiveSpriteSpec('secondary_01.png', 14, 14),
  _CorrectiveSpriteSpec('secondary_02.png', 14, 14),
  _CorrectiveSpriteSpec('secondary_03.png', 14, 13),
  _CorrectiveSpriteSpec('secondary_04.png', 14, 10),
  _CorrectiveSpriteSpec('filler_01.png', 6, 6),
  _CorrectiveSpriteSpec('filler_02.png', 7, 6),
  _CorrectiveSpriteSpec('filler_03.png', 6, 5),
  _CorrectiveSpriteSpec('corner_01.png', 17, 15),
  _CorrectiveSpriteSpec('corner_02.png', 17, 14),
  _CorrectiveSpriteSpec('cap_01.png', 8, 8),
  _CorrectiveSpriteSpec('cap_02.png', 7, 7),
];

final class _CorrectiveSpriteSpec {
  const _CorrectiveSpriteSpec(
    this.fileName,
    this.targetWidth,
    this.targetHeight,
  );

  final String fileName;
  final int targetWidth;
  final int targetHeight;
}

final class _ReplacementOpaqueComponent {
  const _ReplacementOpaqueComponent({
    required this.pixels,
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  final List<int> pixels;
  final int left;
  final int top;
  final int right;
  final int bottom;

  int get centerX => left + right;
  int get centerY => top + bottom;
}

final class _PreparedStone {
  const _PreparedStone({
    required this.spec,
    required this.index,
    required this.sourceRelativePath,
    required this.sourceSha256,
    required this.normalizedSha256,
    required this.normalizedBytes,
    required this.opaqueBounds,
  });

  final _StoneSpriteSpec spec;
  final int index;
  final String sourceRelativePath;
  final String sourceSha256;
  final String normalizedSha256;
  final Uint8List normalizedBytes;
  final _OpaqueBounds opaqueBounds;
}

final class _OpaqueBounds {
  const _OpaqueBounds({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  final int x;
  final int y;
  final int width;
  final int height;
}
