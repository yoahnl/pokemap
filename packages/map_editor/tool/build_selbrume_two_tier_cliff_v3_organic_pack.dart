import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

const selbrumeTwoTierCliffV3OrganicSourceRelativePath =
    'assets/sources/border_studio/two_tier_cliff_v3_organic';
const selbrumeTwoTierCliffV3OrganicAtlasRelativePath =
    'assets/tilesets/falaises_selbrume_deux_etages_v3_organic.png';
const selbrumeTwoTierCliffV3OrganicProvenanceRelativePath =
    'assets/provenance/selbrume_two_tier_cliff_v3_organic.json';

const _topRawRelativePath =
    '$selbrumeTwoTierCliffV3OrganicSourceRelativePath/raw/'
    'top_lip_stones_6x4.png';
const _faceRawRelativePath =
    '$selbrumeTwoTierCliffV3OrganicSourceRelativePath/raw/'
    'individual_face_stones_7x4.png';
const _cornerRawRelativePath =
    '$selbrumeTwoTierCliffV3OrganicSourceRelativePath/raw/'
    'individual_turn_stones_6x4.png';
const _tileSize = 32;
const _topSourceColumns = 6;
const _faceSourceColumns = 7;
const _straightSourceRows = 4;
const _cornerGridColumns = 6;
const _cornerGridRows = 4;
const _minimumSourceComponentPixelCount = 32;
const _atlasColumns = 10;
const _atlasRows = 8;
const _collisionIntent = 'visual_only_no_collision';
const _sourceLabel =
    'OpenAI ImageGen stone contact sheets guided by Selbrume cliff.png';
const _licenseLabel = 'project-owned generated asset';
const _status = 'candidate';
const _normalizationPolicy =
    'nearest_palette_compact_visible_stone_v10_diverse';

const _palette = <(int, int, int)>[
  (200, 187, 159),
  (182, 169, 141),
  (174, 161, 134),
  (161, 149, 125),
  (142, 133, 113),
  (126, 118, 101),
  (111, 105, 90),
  (98, 94, 82),
  (88, 85, 75),
  (76, 75, 69),
  (65, 65, 61),
  (56, 56, 54),
  (37, 40, 43),
];

// Five compact lips share a mutually compatible 18..22 px envelope so texture
// selection is not forced into a short geometric cadence. The sixth remains a
// full-width bridge for one-cell topology runs where no compact stone can join
// both reserved turn shoulders; its publication weight keeps it exceptional.
const _topTangentSpans = <int>[18, 19, 20, 21, 22, 32];
const _topVisibleNormalSpans = <int>[11, 12, 11, 12, 12, 13];
const _topLandwardProtrusionPx = 3;
const _topNormalSpans = <int>[14, 15, 14, 15, 15, 16];
const _topVisibleTangentSpans = <int>[14, 15, 16, 17, 18, 24];
// Face textures stay visually different while their contact envelopes remain
// close enough that every ordinary variant can follow every other variant.
const _faceTangentSpans = <int>[18, 19, 20, 20, 21, 22];
const _faceNormalSpans = <int>[25, 26, 25, 27, 28, 29];
const _faceFrontGaps = <int>[2, 2, 2, 2, 3, 3];
const _cornerTangentSpans = <int>[14, 16, 15, 17, 16, 18];
const _cornerNormalSpans = <int>[12, 14, 13, 15, 14, 16];
const _cornerVisibleTangentSpans = <int>[10, 12, 11, 13, 12, 14];
const _capTangentSpans = <int>[16, 18];
const _capNormalSpans = <int>[9, 11];
const _capVisibleTangentSpans = <int>[12, 14];
// The map coastline changes terrain exactly on the authored grid edge. A lip
// ending on that mathematical edge can leave the last animated ocean pixels
// visible after raster scaling. Move only the flat top tier four pixels onto
// the land side while retaining four or more pixels of overlap with the face.
const _topLandwardOverlapPx = 4;
// A one-pixel rear contact technically separates terrain from ocean, but it
// disappears perceptually once the map is scaled and leaves blue pinholes
// immediately behind irregular stones. Keep a shallow stone-coloured backing
// only on the landward side; the water-facing silhouette stays untouched.
const _topLandwardSealDepthPx = 4;
const _cornerAnchorNormalSpans = <int>[9, 10, 9, 10, 10, 11];
// Keep every authored top stone and six face stones. Face column 5 is omitted
// because its north-facing source reverses the pack's upper-left lighting.
const _topSelectedColumns = <int>[0, 1, 2, 3, 4, 5];
const _faceSelectedColumns = <int>[0, 1, 2, 3, 4, 6];
// Turns use one compact individual boulder instead of a preassembled corner.
// The topology resolver supplies the handedness; the sprite stays organic.
const _cornerSelectedColumns = <int>[0, 1, 2, 3, 4, 5];
const _capSelectedColumns = <int>[1, 3];

enum _StoneTier { top, face, corner, cap }

enum _SourceSheet { top, face, corner }

enum _StoneOrientation { north, east, south, west }

final class SelbrumeTwoTierCliffV3OrganicPackOptions {
  const SelbrumeTwoTierCliffV3OrganicPackOptions({
    required this.topSheet,
    required this.faceSheet,
    required this.cornerSheet,
    required this.projectRoot,
    required this.outputAtlas,
    required this.provenance,
    this.chromaRgb = 0xFF00FF,
    this.chromaTolerance = 48,
  });

  final File topSheet;
  final File faceSheet;
  final File cornerSheet;
  final Directory projectRoot;
  final File outputAtlas;
  final File provenance;
  final int chromaRgb;
  final int chromaTolerance;
}

final class SelbrumeTwoTierCliffV3OrganicPackBuildResult {
  const SelbrumeTwoTierCliffV3OrganicPackBuildResult({
    required this.sourceFiles,
    required this.outputAtlas,
    required this.provenance,
    required this.atlasSha256,
  });

  final List<File> sourceFiles;
  final File outputAtlas;
  final File provenance;
  final String atlasSha256;
}

Future<SelbrumeTwoTierCliffV3OrganicPackBuildResult>
    buildSelbrumeTwoTierCliffV3OrganicPack(
  SelbrumeTwoTierCliffV3OrganicPackOptions options,
) async {
  _validateOptions(options);
  final topBytes = options.topSheet.readAsBytesSync();
  final faceBytes = options.faceSheet.readAsBytesSync();
  final cornerBytes = options.cornerSheet.readAsBytesSync();
  final topSheet = img.decodePng(topBytes);
  final faceSheet = img.decodePng(faceBytes);
  final cornerSheet = img.decodePng(cornerBytes);
  if (topSheet == null) {
    throw StateError('V3 organic top contact sheet is not a valid PNG.');
  }
  if (faceSheet == null) {
    throw StateError('V3 organic face contact sheet is not a valid PNG.');
  }
  if (cornerSheet == null) {
    throw StateError('V3 organic corner contact sheet is not a valid PNG.');
  }

  final componentsBySheet = <_SourceSheet, List<_OpaqueComponent>>{
    _SourceSheet.top: _extractOrderedComponents(
      topSheet,
      label: 'top',
      chromaRgb: options.chromaRgb,
      chromaTolerance: options.chromaTolerance,
      columns: _topSourceColumns,
      rows: _straightSourceRows,
    ),
    _SourceSheet.face: _extractOrderedComponents(
      faceSheet,
      label: 'face',
      chromaRgb: options.chromaRgb,
      chromaTolerance: options.chromaTolerance,
      columns: _faceSourceColumns,
      rows: _straightSourceRows,
    ),
    _SourceSheet.corner: _extractOrderedComponents(
      cornerSheet,
      label: 'corner',
      chromaRgb: options.chromaRgb,
      chromaTolerance: options.chromaTolerance,
      columns: _cornerGridColumns,
      rows: _cornerGridRows,
    ),
  };
  final sheetsBySource = <_SourceSheet, img.Image>{
    _SourceSheet.top: topSheet,
    _SourceSheet.face: faceSheet,
    _SourceSheet.corner: cornerSheet,
  };
  final specs = _spriteSpecs();
  final prepared = <_PreparedSprite>[];
  for (final spec in specs) {
    final components = componentsBySheet[spec.sourceSheet]!;
    final source = _componentImage(
      sheetsBySource[spec.sourceSheet]!,
      components[spec.sourceRow * spec.sourceColumnCount + spec.sourceColumn],
    );
    final sprite = _normalizeSprite(source, spec);
    _validateSprite(sprite, spec);
    final bytes = Uint8List.fromList(img.encodePng(sprite));
    prepared.add(
      _PreparedSprite(
        spec: spec,
        bytes: bytes,
        sha256: _sha256(bytes),
        alphaMaskSha256: _alphaMaskSha256(sprite),
        opaqueBounds: _opaqueBounds(sprite),
        rearContactRunPx: _rearContactRun(sprite, spec.orientation),
        tangentStartContactRunPx:
            _tangentStartContactRun(sprite, spec.orientation),
        tangentEndContactRunPx: _tangentEndContactRun(sprite, spec.orientation),
      ),
    );
  }
  _requireUniqueValues(
    prepared.map((entry) => entry.sha256),
    message: 'V3 organic stones must have unique PNG hashes.',
  );
  _requireUniqueValues(
    prepared.map((entry) => entry.alphaMaskSha256),
    message: 'V3 organic stones must have unique alpha silhouettes.',
  );

  final atlas = img.Image(
    width: _atlasColumns * _tileSize,
    height: _atlasRows * _tileSize,
    numChannels: 4,
  );
  for (var index = 0; index < prepared.length; index += 1) {
    img.compositeImage(
      atlas,
      img.decodePng(prepared[index].bytes)!,
      dstX: (index % _atlasColumns) * _tileSize,
      dstY: (index ~/ _atlasColumns) * _tileSize,
    );
  }
  final atlasBytes = Uint8List.fromList(img.encodePng(atlas));
  final atlasSha256 = _sha256(atlasBytes);
  final provenanceBytes = Uint8List.fromList(
    utf8.encode(
      '${const JsonEncoder.withIndent('  ').convert(<String, Object?>{
            'schemaVersion': 1,
            'packVersion': 3,
            'packId': 'selbrume_two_tier_cliff_v3_organic',
            'source': _sourceLabel,
            'license': _licenseLabel,
            'status': _status,
            'collisionIntent': _collisionIntent,
            'normalizationPolicy': _normalizationPolicy,
            'usesToneRedistribution': false,
            'chroma': _hexRgb(options.chromaRgb),
            'chromaTolerance': options.chromaTolerance,
            'tileSize': <String, int>{'width': _tileSize, 'height': _tileSize},
            'sourceGrid': <String, int>{
              'columns': _topSourceColumns,
              'rows': _straightSourceRows,
            },
            'atlasGrid': <String, int>{
              'columns': _atlasColumns,
              'rows': _atlasRows,
            },
            'rawSheets': <String, Map<String, Object?>>{
              'top': <String, Object?>{
                'relativePath': _topRawRelativePath,
                'sha256': _sha256(topBytes),
                'selectedColumns': _topSelectedColumns,
                'grid': <String, int>{
                  'columns': _topSourceColumns,
                  'rows': _straightSourceRows,
                },
              },
              'face': <String, Object?>{
                'relativePath': _faceRawRelativePath,
                'sha256': _sha256(faceBytes),
                'selectedColumns': _faceSelectedColumns,
                'grid': <String, int>{
                  'columns': _faceSourceColumns,
                  'rows': _straightSourceRows,
                },
              },
              'corner': <String, Object?>{
                'relativePath': _cornerRawRelativePath,
                'sha256': _sha256(cornerBytes),
                'selectedColumns': _cornerSelectedColumns,
                'grid': <String, int>{
                  'columns': _cornerGridColumns,
                  'rows': _cornerGridRows,
                },
                'role': 'lineCorner',
              },
            },
            'atlasSha256': atlasSha256,
            'palette': <String>[
              for (final color in _palette)
                '#${color.$1.toRadixString(16).padLeft(2, '0').toUpperCase()}'
                    '${color.$2.toRadixString(16).padLeft(2, '0').toUpperCase()}'
                    '${color.$3.toRadixString(16).padLeft(2, '0').toUpperCase()}',
            ],
            'assets': <String, Map<String, String>>{
              _relativeToAssetRoot(
                      selbrumeTwoTierCliffV3OrganicAtlasRelativePath):
                  _inventoryRecord(),
              _relativeToAssetRoot(_topRawRelativePath): _inventoryRecord(),
              _relativeToAssetRoot(_faceRawRelativePath): _inventoryRecord(),
              _relativeToAssetRoot(_cornerRawRelativePath): _inventoryRecord(),
              for (final entry in prepared)
                _relativeToAssetRoot(
                  '$selbrumeTwoTierCliffV3OrganicSourceRelativePath/'
                  '${entry.spec.fileName}',
                ): _inventoryRecord(),
            },
            'entries': <Map<String, Object?>>[
              for (var index = 0; index < prepared.length; index += 1)
                _provenanceEntry(prepared[index], index),
            ],
          })}\n',
    ),
  );

  final sourceDirectory = Directory(
    p.joinAll(<String>[
      p.normalize(p.absolute(options.projectRoot.path)),
      ...selbrumeTwoTierCliffV3OrganicSourceRelativePath.split('/'),
    ]),
  );
  final sourceFiles = <File>[
    for (final entry in prepared)
      File(p.join(sourceDirectory.path, entry.spec.fileName)),
  ];
  await _replacePackAtomically(
    projectRoot: options.projectRoot,
    artifacts: <_OutputArtifact>[
      for (var index = 0; index < prepared.length; index += 1)
        _OutputArtifact(sourceFiles[index], prepared[index].bytes),
      _OutputArtifact(options.outputAtlas, atlasBytes),
      _OutputArtifact(options.provenance, provenanceBytes),
    ],
  );

  return SelbrumeTwoTierCliffV3OrganicPackBuildResult(
    sourceFiles: List<File>.unmodifiable(sourceFiles),
    outputAtlas: options.outputAtlas,
    provenance: options.provenance,
    atlasSha256: atlasSha256,
  );
}

void _validateOptions(SelbrumeTwoTierCliffV3OrganicPackOptions options) {
  for (final entry in <(String, File)>[
    ('top', options.topSheet),
    ('face', options.faceSheet),
    ('corner', options.cornerSheet),
  ]) {
    if (!entry.$2.existsSync()) {
      throw StateError(
          'Missing V3 organic ${entry.$1} sheet: ${entry.$2.path}');
    }
  }
  if (!options.projectRoot.existsSync()) {
    throw StateError(
        'Project root does not exist: ${options.projectRoot.path}');
  }
  if (options.chromaRgb < 0 || options.chromaRgb > 0xFFFFFF) {
    throw ArgumentError.value(options.chromaRgb, 'chromaRgb');
  }
  if (options.chromaTolerance < 0 || options.chromaTolerance > 441) {
    throw ArgumentError.value(options.chromaTolerance, 'chromaTolerance');
  }
}

List<_OpaqueComponent> _extractOrderedComponents(
  img.Image sheet, {
  required String label,
  required int chromaRgb,
  required int chromaTolerance,
  required int columns,
  required int rows,
}) {
  final width = sheet.width;
  final height = sheet.height;
  final background = List<bool>.filled(width * height, false);
  final pending = Queue<int>();

  void seed(int x, int y) {
    final index = y * width + x;
    if (background[index] ||
        !_isChroma(sheet.getPixel(x, y), chromaRgb, chromaTolerance)) {
      return;
    }
    background[index] = true;
    pending.add(index);
  }

  for (var x = 0; x < width; x += 1) {
    seed(x, 0);
    seed(x, height - 1);
  }
  for (var y = 0; y < height; y += 1) {
    seed(0, y);
    seed(width - 1, y);
  }
  while (pending.isNotEmpty) {
    final index = pending.removeFirst();
    final y = index ~/ width;
    final x = index - y * width;
    for (final delta in const <(int, int)>[
      (-1, 0),
      (1, 0),
      (0, -1),
      (0, 1),
    ]) {
      final nextX = x + delta.$1;
      final nextY = y + delta.$2;
      if (nextX < 0 || nextY < 0 || nextX >= width || nextY >= height) {
        continue;
      }
      final nextIndex = nextY * width + nextX;
      if (background[nextIndex] ||
          !_isChroma(
            sheet.getPixel(nextX, nextY),
            chromaRgb,
            chromaTolerance,
          )) {
        continue;
      }
      background[nextIndex] = true;
      pending.add(nextIndex);
    }
  }

  final visited = List<bool>.filled(width * height, false);
  final components = <_OpaqueComponent>[];
  for (var y = 0; y < height; y += 1) {
    for (var x = 0; x < width; x += 1) {
      final index = y * width + x;
      if (visited[index] || background[index]) continue;
      if (sheet.getPixel(x, y).a.toInt() == 0) {
        visited[index] = true;
        continue;
      }
      final pixels = <int>[];
      var left = x;
      var right = x;
      var top = y;
      var bottom = y;
      var sumX = 0;
      var sumY = 0;
      final componentPending = <int>[index];
      visited[index] = true;
      while (componentPending.isNotEmpty) {
        final current = componentPending.removeLast();
        final currentY = current ~/ width;
        final currentX = current - currentY * width;
        pixels.add(current);
        sumX += currentX;
        sumY += currentY;
        left = math.min(left, currentX);
        right = math.max(right, currentX);
        top = math.min(top, currentY);
        bottom = math.max(bottom, currentY);
        for (final delta in const <(int, int)>[
          (-1, 0),
          (1, 0),
          (0, -1),
          (0, 1),
        ]) {
          final nextX = currentX + delta.$1;
          final nextY = currentY + delta.$2;
          if (nextX < 0 || nextY < 0 || nextX >= width || nextY >= height) {
            continue;
          }
          final nextIndex = nextY * width + nextX;
          if (visited[nextIndex] || background[nextIndex]) continue;
          if (sheet.getPixel(nextX, nextY).a.toInt() == 0) {
            visited[nextIndex] = true;
            continue;
          }
          visited[nextIndex] = true;
          componentPending.add(nextIndex);
        }
      }
      components.add(
        _OpaqueComponent(
          pixels: pixels,
          left: left,
          right: right,
          top: top,
          bottom: bottom,
          centroidX: sumX / pixels.length,
          centroidY: sumY / pixels.length,
        ),
      );
    }
  }
  components.removeWhere(
    (component) => component.pixels.length < _minimumSourceComponentPixelCount,
  );
  final expectedComponentCount = columns * rows;
  if (components.length != expectedComponentCount) {
    throw StateError(
      'V3 organic $label contact sheet must contain exactly '
      '$expectedComponentCount isolated stones; found ${components.length}.',
    );
  }
  if (components.any(
    (component) =>
        component.left == 0 ||
        component.top == 0 ||
        component.right == width - 1 ||
        component.bottom == height - 1,
  )) {
    throw StateError('V3 organic $label stone touches the sheet edge.');
  }
  return _orderGrid(
    components,
    label: label,
    columns: columns,
    rows: rows,
  );
}

List<_OpaqueComponent> _orderGrid(
  List<_OpaqueComponent> components, {
  required String label,
  required int columns,
  required int rows,
}) {
  final byY = List<_OpaqueComponent>.of(components)
    ..sort((left, right) {
      final byCentroid = left.centroidY.compareTo(right.centroidY);
      return byCentroid != 0
          ? byCentroid
          : left.centroidX.compareTo(right.centroidX);
    });
  _requireGridBoundaries(
    <double>[for (final component in byY) component.centroidY],
    groupCount: rows,
    groupSize: columns,
    label: '$label rows',
  );
  final byX = List<_OpaqueComponent>.of(components)
    ..sort((left, right) {
      final byCentroid = left.centroidX.compareTo(right.centroidX);
      return byCentroid != 0
          ? byCentroid
          : left.centroidY.compareTo(right.centroidY);
    });
  _requireGridBoundaries(
    <double>[for (final component in byX) component.centroidX],
    groupCount: columns,
    groupSize: rows,
    label: '$label columns',
  );

  final ordered = <_OpaqueComponent>[];
  for (var row = 0; row < rows; row += 1) {
    final items = byY.sublist(
      row * columns,
      (row + 1) * columns,
    )..sort((left, right) => left.centroidX.compareTo(right.centroidX));
    ordered.addAll(items);
  }
  return List<_OpaqueComponent>.unmodifiable(ordered);
}

void _requireGridBoundaries(
  List<double> values, {
  required int groupCount,
  required int groupSize,
  required String label,
}) {
  final gaps = <({int index, double size})>[
    for (var index = 1; index < values.length; index += 1)
      (index: index, size: values[index] - values[index - 1]),
  ]..sort((left, right) {
      final bySize = right.size.compareTo(left.size);
      return bySize != 0 ? bySize : left.index.compareTo(right.index);
    });
  final boundaries = gaps.take(groupCount - 1).map((gap) => gap.index).toList()
    ..sort();
  final expected = <int>[
    for (var group = 1; group < groupCount; group += 1) group * groupSize,
  ];
  if (boundaries.length != expected.length ||
      !List<int>.generate(expected.length, (index) => index)
          .every((index) => boundaries[index] == expected[index])) {
    throw StateError('V3 organic component $label are ambiguous.');
  }
  final weakestBoundary =
      gaps.take(groupCount - 1).map((gap) => gap.size).reduce(math.min);
  final strongestWithin =
      gaps.skip(groupCount - 1).map((gap) => gap.size).reduce(math.max);
  if (weakestBoundary <= strongestWithin) {
    throw StateError('V3 organic component $label are ambiguous.');
  }
}

bool _isChroma(img.Pixel pixel, int chromaRgb, int tolerance) {
  if (pixel.a.toInt() == 0) return true;
  final red = (chromaRgb >> 16) & 0xFF;
  final green = (chromaRgb >> 8) & 0xFF;
  final blue = chromaRgb & 0xFF;
  final deltaRed = pixel.r.toInt() - red;
  final deltaGreen = pixel.g.toInt() - green;
  final deltaBlue = pixel.b.toInt() - blue;
  return deltaRed * deltaRed +
          deltaGreen * deltaGreen +
          deltaBlue * deltaBlue <=
      tolerance * tolerance;
}

img.Image _componentImage(img.Image sheet, _OpaqueComponent component) {
  final result = img.Image(
    width: component.right - component.left + 1,
    height: component.bottom - component.top + 1,
    numChannels: 4,
  );
  for (final index in component.pixels) {
    final sourceY = index ~/ sheet.width;
    final sourceX = index - sourceY * sheet.width;
    final pixel = sheet.getPixel(sourceX, sourceY);
    result.setPixelRgba(
      sourceX - component.left,
      sourceY - component.top,
      pixel.r.toInt(),
      pixel.g.toInt(),
      pixel.b.toInt(),
      255,
    );
  }
  return result;
}

img.Image _normalizeSprite(img.Image source, _SpriteSpec spec) {
  final normalized = _resizeStoneToPalette(
    source,
    width: spec.visibleTargetWidth,
    height: spec.visibleTargetHeight,
  );
  _connectOpaqueComponents(normalized);
  final canvas = img.Image(width: _tileSize, height: _tileSize, numChannels: 4);
  final offset = spec.visibleOpaqueOffset;
  img.compositeImage(canvas, normalized, dstX: offset.$1, dstY: offset.$2);
  final originalOpaque = <bool>[
    for (final pixel in canvas) pixel.a.toInt() != 0,
  ];
  // The rear seam is covered by the opposite cliff tier once resolved. Keep
  // it one pixel deep and ten pixels wide: enough for a real alpha contact,
  // without turning the organic silhouette into a full-width rectangular bar.
  if (spec.tier != _StoneTier.top) {
    _addRearInterlock(canvas, spec, originalOpaque);
  }
  if (spec.tier == _StoneTier.top) {
    _sealTopLandwardEdge(canvas, spec, originalOpaque);
    _addTopLandwardProtrusions(canvas, spec, originalOpaque);
  }
  if (spec.tier == _StoneTier.top ||
      spec.tier == _StoneTier.corner ||
      spec.tier == _StoneTier.cap) {
    _addTangentContacts(canvas, spec, originalOpaque);
  }
  return canvas;
}

void _sealTopLandwardEdge(
  img.Image sprite,
  _SpriteSpec spec,
  List<bool> originalOpaque,
) {
  final bounds = spec.expectedOpaqueBounds;
  final left = bounds.$1;
  final top = bounds.$2;
  final right = left + bounds.$3 - 1;
  final bottom = top + bounds.$4 - 1;
  switch (spec.orientation) {
    case _StoneOrientation.north:
      final landwardEdge = bottom - _topLandwardProtrusionPx;
      _paintTexturedLandwardSeal(
        sprite,
        bounds: bounds,
        originalOpaque: originalOpaque,
        left: left,
        top: landwardEdge - _topLandwardSealDepthPx + 1,
        right: right,
        bottom: landwardEdge,
      );
    case _StoneOrientation.east:
      final landwardEdge = left + _topLandwardProtrusionPx;
      _paintTexturedLandwardSeal(
        sprite,
        bounds: bounds,
        originalOpaque: originalOpaque,
        left: landwardEdge,
        top: top,
        right: landwardEdge + _topLandwardSealDepthPx - 1,
        bottom: bottom,
      );
    case _StoneOrientation.south:
      final landwardEdge = top + _topLandwardProtrusionPx;
      _paintTexturedLandwardSeal(
        sprite,
        bounds: bounds,
        originalOpaque: originalOpaque,
        left: left,
        top: landwardEdge,
        right: right,
        bottom: landwardEdge + _topLandwardSealDepthPx - 1,
      );
    case _StoneOrientation.west:
      final landwardEdge = right - _topLandwardProtrusionPx;
      _paintTexturedLandwardSeal(
        sprite,
        bounds: bounds,
        originalOpaque: originalOpaque,
        left: landwardEdge - _topLandwardSealDepthPx + 1,
        top: top,
        right: landwardEdge,
        bottom: bottom,
      );
  }
}

void _addTopLandwardProtrusions(
  img.Image sprite,
  _SpriteSpec spec,
  List<bool> originalOpaque,
) {
  final bounds = spec.expectedOpaqueBounds;
  final left = bounds.$1;
  final top = bounds.$2;
  final right = left + bounds.$3 - 1;
  final bottom = top + bounds.$4 - 1;

  void paintFrom(int x, int y, int sourceX, int sourceY) {
    final source = sprite.getPixel(sourceX, sourceY);
    sprite.setPixelRgba(
      x,
      y,
      source.r.toInt(),
      source.g.toInt(),
      source.b.toInt(),
      255,
    );
  }

  switch (spec.orientation) {
    case _StoneOrientation.north:
      final edge = bottom - _topLandwardProtrusionPx;
      for (var x = left; x <= right; x += 1) {
        var sourceY = -1;
        for (var y = edge; y >= top; y -= 1) {
          if (originalOpaque[y * sprite.width + x]) {
            sourceY = y;
            break;
          }
        }
        if (sourceY < 0 || edge - sourceY >= _topLandwardProtrusionPx) {
          continue;
        }
        final depth = _topLandwardProtrusionPx - (edge - sourceY);
        for (var step = 1; step <= depth; step += 1) {
          final sampledY = sourceY - (depth - step);
          paintFrom(
            x,
            edge + step,
            x,
            originalOpaque[sampledY * sprite.width + x] ? sampledY : sourceY,
          );
        }
      }
    case _StoneOrientation.east:
      final edge = left + _topLandwardProtrusionPx;
      for (var y = top; y <= bottom; y += 1) {
        var sourceX = sprite.width;
        for (var x = edge; x <= right; x += 1) {
          if (originalOpaque[y * sprite.width + x]) {
            sourceX = x;
            break;
          }
        }
        if (sourceX >= sprite.width ||
            sourceX - edge >= _topLandwardProtrusionPx) {
          continue;
        }
        final depth = _topLandwardProtrusionPx - (sourceX - edge);
        for (var step = 1; step <= depth; step += 1) {
          final sampledX = sourceX + (depth - step);
          paintFrom(
            edge - step,
            y,
            originalOpaque[y * sprite.width + sampledX] ? sampledX : sourceX,
            y,
          );
        }
      }
    case _StoneOrientation.south:
      final edge = top + _topLandwardProtrusionPx;
      for (var x = left; x <= right; x += 1) {
        var sourceY = sprite.height;
        for (var y = edge; y <= bottom; y += 1) {
          if (originalOpaque[y * sprite.width + x]) {
            sourceY = y;
            break;
          }
        }
        if (sourceY >= sprite.height ||
            sourceY - edge >= _topLandwardProtrusionPx) {
          continue;
        }
        final depth = _topLandwardProtrusionPx - (sourceY - edge);
        for (var step = 1; step <= depth; step += 1) {
          final sampledY = sourceY + (depth - step);
          paintFrom(
            x,
            edge - step,
            x,
            originalOpaque[sampledY * sprite.width + x] ? sampledY : sourceY,
          );
        }
      }
    case _StoneOrientation.west:
      final edge = right - _topLandwardProtrusionPx;
      for (var y = top; y <= bottom; y += 1) {
        var sourceX = -1;
        for (var x = edge; x >= left; x -= 1) {
          if (originalOpaque[y * sprite.width + x]) {
            sourceX = x;
            break;
          }
        }
        if (sourceX < 0 || edge - sourceX >= _topLandwardProtrusionPx) {
          continue;
        }
        final depth = _topLandwardProtrusionPx - (edge - sourceX);
        for (var step = 1; step <= depth; step += 1) {
          final sampledX = sourceX - (depth - step);
          paintFrom(
            edge + step,
            y,
            originalOpaque[y * sprite.width + sampledX] ? sampledX : sourceX,
            y,
          );
        }
      }
  }
}

void _paintTexturedLandwardSeal(
  img.Image sprite, {
  required (int, int, int, int) bounds,
  required List<bool> originalOpaque,
  required int left,
  required int top,
  required int right,
  required int bottom,
}) {
  final boundedLeft = left.clamp(bounds.$1, bounds.$1 + bounds.$3 - 1);
  final boundedTop = top.clamp(bounds.$2, bounds.$2 + bounds.$4 - 1);
  final boundedRight = right.clamp(bounds.$1, bounds.$1 + bounds.$3 - 1);
  final boundedBottom = bottom.clamp(bounds.$2, bounds.$2 + bounds.$4 - 1);
  final center = (
    (boundedLeft + boundedRight) ~/ 2,
    (boundedTop + boundedBottom) ~/ 2,
  );
  final nearestCenter = _nearestOriginalOpaque(
    sprite,
    originalOpaque,
    center.$1,
    center.$2,
  );
  _paintOrganicLine(sprite, bounds, center, nearestCenter);
  for (var y = boundedTop; y <= boundedBottom; y += 1) {
    for (var x = boundedLeft; x <= boundedRight; x += 1) {
      if (originalOpaque[y * sprite.width + x]) continue;
      final nearest = _nearestOriginalOpaque(
        sprite,
        originalOpaque,
        x,
        y,
      );
      final source = sprite.getPixel(nearest.$1, nearest.$2);
      final shadow = _shadowPaletteColor(source);
      sprite.setPixelRgba(
        x,
        y,
        shadow.$1,
        shadow.$2,
        shadow.$3,
        255,
      );
    }
  }
}

void _connectOpaqueComponents(img.Image image) {
  while (true) {
    final components = _opaquePixelComponents(image);
    if (components.length <= 1) return;
    final primary = components.reduce(
      (left, right) => left.length >= right.length ? left : right,
    );
    List<(int, int)>? nearestComponent;
    (int, int)? nearestPrimaryPixel;
    (int, int)? nearestOtherPixel;
    var nearestDistance = 1 << 30;
    for (final component in components) {
      if (identical(component, primary)) continue;
      for (final primaryPixel in primary) {
        for (final otherPixel in component) {
          final distance = (primaryPixel.$1 - otherPixel.$1).abs() +
              (primaryPixel.$2 - otherPixel.$2).abs();
          if (distance >= nearestDistance) continue;
          nearestDistance = distance;
          nearestComponent = component;
          nearestPrimaryPixel = primaryPixel;
          nearestOtherPixel = otherPixel;
        }
      }
    }
    if (nearestComponent == null ||
        nearestPrimaryPixel == null ||
        nearestOtherPixel == null) {
      return;
    }
    _paintOrganicLine(
      image,
      (0, 0, image.width, image.height),
      nearestPrimaryPixel,
      nearestOtherPixel,
    );
  }
}

List<List<(int, int)>> _opaquePixelComponents(img.Image image) {
  final visited = List<bool>.filled(image.width * image.height, false);
  final result = <List<(int, int)>>[];
  for (var y = 0; y < image.height; y += 1) {
    for (var x = 0; x < image.width; x += 1) {
      final startIndex = y * image.width + x;
      if (visited[startIndex] || image.getPixel(x, y).a.toInt() == 0) {
        continue;
      }
      final component = <(int, int)>[];
      final pending = <int>[startIndex];
      visited[startIndex] = true;
      while (pending.isNotEmpty) {
        final current = pending.removeLast();
        final currentY = current ~/ image.width;
        final currentX = current - currentY * image.width;
        component.add((currentX, currentY));
        for (final delta in const <(int, int)>[
          (-1, 0),
          (1, 0),
          (0, -1),
          (0, 1),
        ]) {
          final nextX = currentX + delta.$1;
          final nextY = currentY + delta.$2;
          if (nextX < 0 ||
              nextY < 0 ||
              nextX >= image.width ||
              nextY >= image.height) {
            continue;
          }
          final nextIndex = nextY * image.width + nextX;
          if (visited[nextIndex] ||
              image.getPixel(nextX, nextY).a.toInt() == 0) {
            continue;
          }
          visited[nextIndex] = true;
          pending.add(nextIndex);
        }
      }
      result.add(component);
    }
  }
  return result;
}

img.Image _resizeStoneToPalette(
  img.Image source, {
  required int width,
  required int height,
}) {
  final normalized = img.Image(
    width: width,
    height: height,
    numChannels: 4,
  );
  for (var y = 0; y < normalized.height; y += 1) {
    for (var x = 0; x < normalized.width; x += 1) {
      final sourceX = x * source.width ~/ normalized.width;
      final sourceY = y * source.height ~/ normalized.height;
      final pixel = source.getPixel(sourceX, sourceY);
      if (pixel.a.toInt() == 0) continue;
      final color = _nearestPaletteColor(pixel);
      normalized.setPixelRgba(x, y, color.$1, color.$2, color.$3, 255);
    }
  }
  for (var sourceY = 0; sourceY < source.height; sourceY += 1) {
    for (var sourceX = 0; sourceX < source.width; sourceX += 1) {
      final pixel = source.getPixel(sourceX, sourceY);
      if (pixel.a.toInt() == 0) continue;
      final targetX = source.width == 1
          ? 0
          : (sourceX * (normalized.width - 1) / (source.width - 1)).round();
      final targetY = source.height == 1
          ? 0
          : (sourceY * (normalized.height - 1) / (source.height - 1)).round();
      final color = _nearestPaletteColor(pixel);
      normalized.setPixelRgba(
        targetX,
        targetY,
        color.$1,
        color.$2,
        color.$3,
        255,
      );
    }
  }
  return normalized;
}

void _addRearInterlock(
  img.Image sprite,
  _SpriteSpec spec,
  List<bool> originalOpaque,
) {
  final bounds = spec.expectedOpaqueBounds;
  final left = bounds.$1;
  final top = bounds.$2;
  final right = left + bounds.$3 - 1;
  final bottom = top + bounds.$4 - 1;
  final centerX = (left + right) ~/ 2;
  final centerY = (top + bottom) ~/ 2;
  const contactRun = 10;
  final horizontalStart = centerX - (contactRun - 1) ~/ 2;
  final horizontalEnd = horizontalStart + contactRun - 1;
  final verticalStart = centerY - (contactRun - 1) ~/ 2;
  final verticalEnd = verticalStart + contactRun - 1;
  switch (spec.orientation) {
    case _StoneOrientation.north:
      _paintCompactContact(
        sprite,
        bounds: bounds,
        originalOpaque: originalOpaque,
        left: horizontalStart,
        top: bottom,
        right: horizontalEnd,
        bottom: bottom,
      );
    case _StoneOrientation.east:
      _paintCompactContact(
        sprite,
        bounds: bounds,
        originalOpaque: originalOpaque,
        left: left,
        top: verticalStart,
        right: left,
        bottom: verticalEnd,
      );
    case _StoneOrientation.south:
      _paintCompactContact(
        sprite,
        bounds: bounds,
        originalOpaque: originalOpaque,
        left: horizontalStart,
        top: top,
        right: horizontalEnd,
        bottom: top,
      );
    case _StoneOrientation.west:
      _paintCompactContact(
        sprite,
        bounds: bounds,
        originalOpaque: originalOpaque,
        left: right,
        top: verticalStart,
        right: right,
        bottom: verticalEnd,
      );
  }
}

void _addTangentContacts(
  img.Image sprite,
  _SpriteSpec spec,
  List<bool> originalOpaque,
) {
  final bounds = spec.expectedOpaqueBounds;
  final left = bounds.$1;
  final top = bounds.$2;
  final right = left + bounds.$3 - 1;
  final bottom = top + bounds.$4 - 1;
  final normalCenter = switch (spec.orientation) {
    _StoneOrientation.north ||
    _StoneOrientation.west =>
      spec.tier == _StoneTier.corner ? 9 : 6,
    _StoneOrientation.east ||
    _StoneOrientation.south =>
      _tileSize - (spec.tier == _StoneTier.corner ? 9 : 6) - 1,
  };
  if (spec.orientation == _StoneOrientation.north ||
      spec.orientation == _StoneOrientation.south) {
    final centerY = normalCenter.clamp(top + 1, bottom - 1);
    _paintCompactContact(
      sprite,
      bounds: bounds,
      originalOpaque: originalOpaque,
      left: left,
      top: centerY - 1,
      right: left + 1,
      bottom: centerY + 1,
    );
    _paintCompactContact(
      sprite,
      bounds: bounds,
      originalOpaque: originalOpaque,
      left: right - 1,
      top: centerY - 1,
      right: right,
      bottom: centerY + 1,
    );
    return;
  }
  final centerX = normalCenter.clamp(left + 1, right - 1);
  _paintCompactContact(
    sprite,
    bounds: bounds,
    originalOpaque: originalOpaque,
    left: centerX - 1,
    top: top,
    right: centerX + 1,
    bottom: top + 1,
  );
  _paintCompactContact(
    sprite,
    bounds: bounds,
    originalOpaque: originalOpaque,
    left: centerX - 1,
    top: bottom - 1,
    right: centerX + 1,
    bottom: bottom,
  );
}

void _paintCompactContact(
  img.Image sprite, {
  required (int, int, int, int) bounds,
  required List<bool> originalOpaque,
  required int left,
  required int top,
  required int right,
  required int bottom,
}) {
  final boundedLeft = left.clamp(bounds.$1, bounds.$1 + bounds.$3 - 1);
  final boundedTop = top.clamp(bounds.$2, bounds.$2 + bounds.$4 - 1);
  final boundedRight = right.clamp(bounds.$1, bounds.$1 + bounds.$3 - 1);
  final boundedBottom = bottom.clamp(bounds.$2, bounds.$2 + bounds.$4 - 1);
  final center = (
    (boundedLeft + boundedRight) ~/ 2,
    (boundedTop + boundedBottom) ~/ 2,
  );
  final nearest = _nearestOriginalOpaque(
    sprite,
    originalOpaque,
    center.$1,
    center.$2,
  );
  _paintOrganicLine(sprite, bounds, center, nearest);
  for (var y = boundedTop; y <= boundedBottom; y += 1) {
    for (var x = boundedLeft; x <= boundedRight; x += 1) {
      _paintContactPixel(sprite, bounds, x, y);
    }
  }
}

(int, int) _nearestOriginalOpaque(
  img.Image image,
  List<bool> originalOpaque,
  int x,
  int y,
) {
  var best = (x, y);
  var bestDistance = 1 << 30;
  for (var candidateY = 0; candidateY < image.height; candidateY += 1) {
    for (var candidateX = 0; candidateX < image.width; candidateX += 1) {
      if (!originalOpaque[candidateY * image.width + candidateX]) continue;
      final distance = (candidateX - x).abs() + (candidateY - y).abs();
      if (distance < bestDistance) {
        best = (candidateX, candidateY);
        bestDistance = distance;
      }
    }
  }
  return best;
}

void _paintOrganicLine(
  img.Image image,
  (int, int, int, int) bounds,
  (int, int) from,
  (int, int) to,
) {
  var x = from.$1;
  var y = from.$2;
  final deltaX = (to.$1 - x).abs();
  final stepX = x < to.$1 ? 1 : -1;
  final deltaY = -(to.$2 - y).abs();
  final stepY = y < to.$2 ? 1 : -1;
  var error = deltaX + deltaY;
  while (true) {
    _paintContactPixel(image, bounds, x, y);
    if (x == to.$1 && y == to.$2) return;
    final previousX = x;
    final previousY = y;
    final doubled = error * 2;
    if (doubled >= deltaY) {
      error += deltaY;
      x += stepX;
    }
    if (doubled <= deltaX) {
      error += deltaX;
      y += stepY;
    }
    if (x != previousX && y != previousY) {
      // Bresenham may otherwise join two pixels only diagonally. The alpha
      // contract is four-connected so contacts remain one physical stone.
      _paintContactPixel(image, bounds, x, previousY);
    }
  }
}

void _paintContactPixel(
  img.Image image,
  (int, int, int, int) bounds,
  int x,
  int y,
) {
  if (x < bounds.$1 ||
      y < bounds.$2 ||
      x >= bounds.$1 + bounds.$3 ||
      y >= bounds.$2 + bounds.$4) {
    return;
  }
  final localX = x - bounds.$1;
  final localY = y - bounds.$2;
  final isUpperLeft = localX + localY < (bounds.$3 + bounds.$4 - 2) / 2;
  final color = isUpperLeft ? _palette[4] : _palette[8];
  image.setPixelRgba(x, y, color.$1, color.$2, color.$3, 255);
}

(int, int, int) _nearestPaletteColor(img.Pixel pixel) {
  var best = _palette.first;
  var bestDistance = 1 << 62;
  for (final candidate in _palette) {
    final deltaRed = pixel.r.toInt() - candidate.$1;
    final deltaGreen = pixel.g.toInt() - candidate.$2;
    final deltaBlue = pixel.b.toInt() - candidate.$3;
    final distance =
        deltaRed * deltaRed + deltaGreen * deltaGreen + deltaBlue * deltaBlue;
    if (distance < bestDistance) {
      best = candidate;
      bestDistance = distance;
    }
  }
  return best;
}

(int, int, int) _shadowPaletteColor(img.Pixel pixel) {
  final nearest = _nearestPaletteColor(pixel);
  final index = _palette.indexOf(nearest);
  return _palette[math.min(_palette.length - 2, index + 3)];
}

void _validateSprite(img.Image sprite, _SpriteSpec spec) {
  if ((sprite.width, sprite.height) != (_tileSize, _tileSize)) {
    throw StateError('${spec.fileName} is not 32x32.');
  }
  final alpha = <int>{for (final pixel in sprite) pixel.a.toInt()};
  if (!alpha.every((value) => value == 0 || value == 255) ||
      !alpha.contains(255)) {
    throw StateError('${spec.fileName} must have binary non-empty alpha.');
  }
  if (_opaqueComponentCount(sprite) != 1) {
    throw StateError('${spec.fileName} must contain one connected stone.');
  }
  final expectedBounds = (
    spec.opaqueOffset.$1,
    spec.opaqueOffset.$2,
    spec.targetWidth,
    spec.targetHeight,
  );
  if (_opaqueBounds(sprite) != expectedBounds) {
    throw StateError(
      '${spec.fileName} bounds ${_opaqueBounds(sprite)} do not match '
      '$expectedBounds.',
    );
  }
  for (final pixel in sprite) {
    if (pixel.a.toInt() == 0) continue;
    if (!_palette.contains(
      (pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt()),
    )) {
      throw StateError('${spec.fileName} contains an off-palette pixel.');
    }
  }
}

int _opaqueComponentCount(img.Image image) {
  final visited = List<bool>.filled(image.width * image.height, false);
  var count = 0;
  for (var y = 0; y < image.height; y += 1) {
    for (var x = 0; x < image.width; x += 1) {
      final index = y * image.width + x;
      if (visited[index] || image.getPixel(x, y).a.toInt() == 0) continue;
      count += 1;
      final pending = <int>[index];
      visited[index] = true;
      while (pending.isNotEmpty) {
        final current = pending.removeLast();
        final currentY = current ~/ image.width;
        final currentX = current - currentY * image.width;
        for (final delta in const <(int, int)>[
          (-1, 0),
          (1, 0),
          (0, -1),
          (0, 1),
        ]) {
          final nextX = currentX + delta.$1;
          final nextY = currentY + delta.$2;
          if (nextX < 0 ||
              nextY < 0 ||
              nextX >= image.width ||
              nextY >= image.height) {
            continue;
          }
          final nextIndex = nextY * image.width + nextX;
          if (visited[nextIndex] ||
              image.getPixel(nextX, nextY).a.toInt() == 0) {
            continue;
          }
          visited[nextIndex] = true;
          pending.add(nextIndex);
        }
      }
    }
  }
  return count;
}

(int, int, int, int) _opaqueBounds(img.Image image) {
  var left = image.width;
  var top = image.height;
  var right = -1;
  var bottom = -1;
  for (var y = 0; y < image.height; y += 1) {
    for (var x = 0; x < image.width; x += 1) {
      if (image.getPixel(x, y).a.toInt() == 0) continue;
      left = math.min(left, x);
      top = math.min(top, y);
      right = math.max(right, x);
      bottom = math.max(bottom, y);
    }
  }
  if (right < left || bottom < top) return (0, 0, 0, 0);
  return (left, top, right - left + 1, bottom - top + 1);
}

int _rearContactRun(img.Image image, _StoneOrientation orientation) {
  final bounds = _opaqueBounds(image);
  return switch (orientation) {
    _StoneOrientation.north => _opaqueHorizontalRun(
        image,
        y: bounds.$2 + bounds.$4 - 1,
        fromX: bounds.$1,
        toX: bounds.$1 + bounds.$3 - 1,
      ),
    _StoneOrientation.east => _opaqueVerticalRun(
        image,
        x: bounds.$1,
        fromY: bounds.$2,
        toY: bounds.$2 + bounds.$4 - 1,
      ),
    _StoneOrientation.south => _opaqueHorizontalRun(
        image,
        y: bounds.$2,
        fromX: bounds.$1,
        toX: bounds.$1 + bounds.$3 - 1,
      ),
    _StoneOrientation.west => _opaqueVerticalRun(
        image,
        x: bounds.$1 + bounds.$3 - 1,
        fromY: bounds.$2,
        toY: bounds.$2 + bounds.$4 - 1,
      ),
  };
}

int _tangentStartContactRun(img.Image image, _StoneOrientation orientation) {
  final bounds = _opaqueBounds(image);
  return orientation == _StoneOrientation.north ||
          orientation == _StoneOrientation.south
      ? _opaqueVerticalRun(
          image,
          x: bounds.$1,
          fromY: bounds.$2,
          toY: bounds.$2 + bounds.$4 - 1,
        )
      : _opaqueHorizontalRun(
          image,
          y: bounds.$2,
          fromX: bounds.$1,
          toX: bounds.$1 + bounds.$3 - 1,
        );
}

int _tangentEndContactRun(img.Image image, _StoneOrientation orientation) {
  final bounds = _opaqueBounds(image);
  return orientation == _StoneOrientation.north ||
          orientation == _StoneOrientation.south
      ? _opaqueVerticalRun(
          image,
          x: bounds.$1 + bounds.$3 - 1,
          fromY: bounds.$2,
          toY: bounds.$2 + bounds.$4 - 1,
        )
      : _opaqueHorizontalRun(
          image,
          y: bounds.$2 + bounds.$4 - 1,
          fromX: bounds.$1,
          toX: bounds.$1 + bounds.$3 - 1,
        );
}

int _opaqueHorizontalRun(
  img.Image image, {
  required int y,
  required int fromX,
  required int toX,
}) =>
    <int>[
      for (var x = fromX; x <= toX; x += 1)
        if (image.getPixel(x, y).a.toInt() != 0) x,
    ].length;

int _opaqueVerticalRun(
  img.Image image, {
  required int x,
  required int fromY,
  required int toY,
}) =>
    <int>[
      for (var y = fromY; y <= toY; y += 1)
        if (image.getPixel(x, y).a.toInt() != 0) y,
    ].length;

String _alphaMaskSha256(img.Image image) => _sha256(<int>[
      for (final pixel in image) pixel.a.toInt() == 0 ? 0 : 1,
    ]);

List<_SpriteSpec> _spriteSpecs() {
  final result = <_SpriteSpec>[];
  void addFamily(
    _StoneTier tier,
    _StoneOrientation first,
    _StoneOrientation second,
    int variantCount,
  ) {
    for (final orientation in <_StoneOrientation>[first, second]) {
      for (var variant = 1; variant <= variantCount; variant += 1) {
        result.add(
          _SpriteSpec(
            tier: tier,
            orientation: orientation,
            variant: variant,
          ),
        );
      }
    }
  }

  addFamily(_StoneTier.top, _StoneOrientation.north, _StoneOrientation.east, 6);
  addFamily(_StoneTier.top, _StoneOrientation.south, _StoneOrientation.west, 6);
  addFamily(
      _StoneTier.face, _StoneOrientation.north, _StoneOrientation.east, 6);
  addFamily(
      _StoneTier.face, _StoneOrientation.south, _StoneOrientation.west, 6);
  addFamily(
      _StoneTier.corner, _StoneOrientation.north, _StoneOrientation.east, 6);
  addFamily(
      _StoneTier.corner, _StoneOrientation.south, _StoneOrientation.west, 6);
  addFamily(_StoneTier.cap, _StoneOrientation.north, _StoneOrientation.east, 2);
  addFamily(_StoneTier.cap, _StoneOrientation.south, _StoneOrientation.west, 2);
  return List<_SpriteSpec>.unmodifiable(result);
}

Map<String, Object?> _provenanceEntry(_PreparedSprite entry, int index) =>
    <String, Object?>{
      'id': entry.spec.id,
      'fileName': entry.spec.fileName,
      'sourceRelativePath': '$selbrumeTwoTierCliffV3OrganicSourceRelativePath/'
          '${entry.spec.fileName}',
      'sha256': entry.sha256,
      'alphaMaskSha256': entry.alphaMaskSha256,
      'role': entry.spec.provenanceRole,
      'assetFamily': entry.spec.rolePrefix,
      'authoredOrientation': entry.spec.orientationName,
      'variant': entry.spec.variant,
      'anchorPx': <String, int>{
        'x': entry.spec.anchor.$1,
        'y': entry.spec.anchor.$2,
      },
      'frontGapPx': entry.spec.frontGap,
      'landwardOverlapPx': entry.spec.landwardOverlap,
      'landwardSealDepthPx':
          entry.spec.tier == _StoneTier.top ? _topLandwardSealDepthPx : 0,
      'landwardSealStyle': entry.spec.tier == _StoneTier.top
          ? 'nearest_original_stone_shadow'
          : 'none',
      'landwardProtrusionPx':
          entry.spec.tier == _StoneTier.top ? _topLandwardProtrusionPx : 0,
      'opaqueBoundsPx': <String, int>{
        'x': entry.opaqueBounds.$1,
        'y': entry.opaqueBounds.$2,
        'width': entry.opaqueBounds.$3,
        'height': entry.opaqueBounds.$4,
      },
      'tangentSpanPx': entry.spec.tangentSpan,
      'visibleTangentSpanPx': entry.spec.visibleTangentSpan,
      'normalSpanPx': entry.spec.normalSpan,
      'visibleNormalSpanPx': entry.spec.visibleNormalSpan,
      'rearContactRunPx': entry.rearContactRunPx,
      'tangentStartContactRunPx': entry.tangentStartContactRunPx,
      'tangentEndContactRunPx': entry.tangentEndContactRunPx,
      'selectedSourceSheet': entry.spec.sourceSheetName,
      'selectedSourceCell': <String, int>{
        'column': entry.spec.sourceColumn,
        'row': entry.spec.sourceRow,
      },
      'sourceStoneCount': 1,
      'atlasCell': <String, int>{
        'column': index % _atlasColumns,
        'row': index ~/ _atlasColumns,
      },
      'normalizationPolicy': _normalizationPolicy,
      'collisionIntent': _collisionIntent,
      'source': _sourceLabel,
      'license': _licenseLabel,
      'status': _status,
    };

Map<String, String> _inventoryRecord() => <String, String>{
      'source': _sourceLabel,
      'license': _licenseLabel,
      'status': _status,
    };

String _relativeToAssetRoot(String relativePath) {
  const prefix = 'assets/';
  if (!relativePath.startsWith(prefix)) {
    throw StateError('Expected an assets-relative path: $relativePath');
  }
  return relativePath.substring(prefix.length);
}

final class _OpaqueComponent {
  const _OpaqueComponent({
    required this.pixels,
    required this.left,
    required this.right,
    required this.top,
    required this.bottom,
    required this.centroidX,
    required this.centroidY,
  });

  final List<int> pixels;
  final int left;
  final int right;
  final int top;
  final int bottom;
  final double centroidX;
  final double centroidY;
}

final class _PreparedSprite {
  const _PreparedSprite({
    required this.spec,
    required this.bytes,
    required this.sha256,
    required this.alphaMaskSha256,
    required this.opaqueBounds,
    required this.rearContactRunPx,
    required this.tangentStartContactRunPx,
    required this.tangentEndContactRunPx,
  });

  final _SpriteSpec spec;
  final Uint8List bytes;
  final String sha256;
  final String alphaMaskSha256;
  final (int, int, int, int) opaqueBounds;
  final int rearContactRunPx;
  final int tangentStartContactRunPx;
  final int tangentEndContactRunPx;
}

final class _SpriteSpec {
  const _SpriteSpec({
    required this.tier,
    required this.orientation,
    required this.variant,
  });

  final _StoneTier tier;
  final _StoneOrientation orientation;
  final int variant;

  int get _index => variant - 1;

  String get rolePrefix => switch (tier) {
        _StoneTier.top => 'top',
        _StoneTier.face => 'face',
        _StoneTier.corner => 'corner',
        _StoneTier.cap => 'cap',
      };

  String get provenanceRole => switch (tier) {
        _StoneTier.corner => 'lineCorner',
        _StoneTier.cap => 'lineCap',
        _StoneTier.top => 'top',
        _StoneTier.face => 'face',
      };

  String get orientationWire => switch (orientation) {
        _StoneOrientation.north => 'n',
        _StoneOrientation.east => 'e',
        _StoneOrientation.south => 's',
        _StoneOrientation.west => 'w',
      };

  String get orientationName => switch (orientation) {
        _StoneOrientation.north => 'north',
        _StoneOrientation.east => 'east',
        _StoneOrientation.south => 'south',
        _StoneOrientation.west => 'west',
      };

  String get id => 'selbrume-cliff-v3-organic-$rolePrefix-$orientationWire-'
      '${variant.toString().padLeft(2, '0')}';

  String get fileName => '${rolePrefix}_${orientationWire}_'
      '${variant.toString().padLeft(2, '0')}.png';

  int get tangentSpan => switch (tier) {
        _StoneTier.top => _topTangentSpans[_index],
        _StoneTier.face => _faceTangentSpans[_index],
        _StoneTier.corner => _cornerTangentSpans[_index],
        _StoneTier.cap => _capTangentSpans[_index],
      };

  int get visibleTangentSpan => switch (tier) {
        _StoneTier.top => _topVisibleTangentSpans[_index],
        _StoneTier.face => _faceTangentSpans[_index],
        _StoneTier.corner => _cornerVisibleTangentSpans[_index],
        _StoneTier.cap => _capVisibleTangentSpans[_index],
      };

  int get normalSpan => switch (tier) {
        _StoneTier.top => _topNormalSpans[_index],
        _StoneTier.face => _faceNormalSpans[_index],
        _StoneTier.corner => _cornerNormalSpans[_index],
        _StoneTier.cap => _capNormalSpans[_index],
      };

  int get visibleNormalSpan => switch (tier) {
        _StoneTier.top => _topVisibleNormalSpans[_index],
        _StoneTier.face || _StoneTier.corner || _StoneTier.cap => normalSpan,
      };

  int get frontGap => tier == _StoneTier.face ? _faceFrontGaps[_index] : 0;

  int get landwardOverlap => tier == _StoneTier.top ? _topLandwardOverlapPx : 0;

  _SourceSheet get sourceSheet => switch (tier) {
        _StoneTier.top || _StoneTier.cap => _SourceSheet.top,
        _StoneTier.face => _SourceSheet.face,
        _StoneTier.corner => _SourceSheet.corner,
      };

  String get sourceSheetName => switch (sourceSheet) {
        _SourceSheet.top => 'top',
        _SourceSheet.face => 'face',
        _SourceSheet.corner => 'corner',
      };

  int get sourceColumnCount => sourceSheet == _SourceSheet.corner
      ? _cornerGridColumns
      : sourceSheet == _SourceSheet.face
          ? _faceSourceColumns
          : _topSourceColumns;

  int get sourceColumn => switch (tier) {
        _StoneTier.top => _topSelectedColumns[_index],
        _StoneTier.face => _faceSelectedColumns[_index],
        _StoneTier.corner => _cornerSelectedColumns[_index],
        _StoneTier.cap => _capSelectedColumns[_index],
      };

  int get sourceRow => orientation.index;

  int get targetWidth => switch (orientation) {
        _StoneOrientation.north || _StoneOrientation.south => tangentSpan,
        _StoneOrientation.east || _StoneOrientation.west => normalSpan,
      };

  int get targetHeight => switch (orientation) {
        _StoneOrientation.north || _StoneOrientation.south => normalSpan,
        _StoneOrientation.east || _StoneOrientation.west => tangentSpan,
      };

  int get visibleTargetWidth => switch (orientation) {
        _StoneOrientation.north ||
        _StoneOrientation.south =>
          visibleTangentSpan,
        _StoneOrientation.east || _StoneOrientation.west => visibleNormalSpan,
      };

  int get visibleTargetHeight => switch (orientation) {
        _StoneOrientation.north || _StoneOrientation.south => visibleNormalSpan,
        _StoneOrientation.east || _StoneOrientation.west => visibleTangentSpan,
      };

  (int, int) get opaqueOffset {
    final tangentStart = (_tileSize - tangentSpan) ~/ 2;
    return switch (orientation) {
      _StoneOrientation.north => (tangentStart, 0),
      _StoneOrientation.east => (_tileSize - normalSpan, tangentStart),
      _StoneOrientation.south => (tangentStart, _tileSize - normalSpan),
      _StoneOrientation.west => (0, tangentStart),
    };
  }

  (int, int) get visibleOpaqueOffset {
    final tangentInset = (tangentSpan - visibleTangentSpan) ~/ 2;
    final protrusion = tier == _StoneTier.top ? _topLandwardProtrusionPx : 0;
    return switch (orientation) {
      _StoneOrientation.north => (
          opaqueOffset.$1 + tangentInset,
          opaqueOffset.$2,
        ),
      _StoneOrientation.east => (
          opaqueOffset.$1 + protrusion,
          opaqueOffset.$2 + tangentInset,
        ),
      _StoneOrientation.south => (
          opaqueOffset.$1 + tangentInset,
          opaqueOffset.$2 + protrusion,
        ),
      _StoneOrientation.west => (
          opaqueOffset.$1,
          opaqueOffset.$2 + tangentInset,
        ),
    };
  }

  (int, int, int, int) get expectedOpaqueBounds => (
        opaqueOffset.$1,
        opaqueOffset.$2,
        targetWidth,
        targetHeight,
      );

  (int, int) get anchor {
    // A corner sprite contains both arms of the turn, so its opaque rectangle
    // is intentionally deeper than a lip stone. Anchor it on the matching lip
    // neck; anchoring on the rectangle's far edge would hide 8–11 px of the
    // vertical face and detach it from neighbouring top stones.
    final anchorNormalSpan = tier == _StoneTier.corner
        ? _cornerAnchorNormalSpans[_index]
        : tier == _StoneTier.top
            ? visibleNormalSpan
            : normalSpan;
    return switch (orientation) {
      _StoneOrientation.north => (
          16,
          tier == _StoneTier.face
              ? anchorNormalSpan + frontGap - 1
              : anchorNormalSpan - landwardOverlap - 1,
        ),
      _StoneOrientation.east => (
          tier == _StoneTier.face
              ? _tileSize - anchorNormalSpan - frontGap
              : _tileSize - anchorNormalSpan + landwardOverlap,
          16,
        ),
      _StoneOrientation.south => (
          16,
          tier == _StoneTier.face
              ? _tileSize - anchorNormalSpan - frontGap
              : _tileSize - anchorNormalSpan + landwardOverlap,
        ),
      _StoneOrientation.west => (
          tier == _StoneTier.face
              ? anchorNormalSpan + frontGap - 1
              : anchorNormalSpan - landwardOverlap - 1,
          16,
        ),
    };
  }
}

final class _OutputArtifact {
  const _OutputArtifact(this.destination, this.bytes);

  final File destination;
  final Uint8List bytes;
}

final class _PackCommit {
  _PackCommit({required this.destination, required this.createdParents});

  final File destination;
  final List<Directory> createdParents;
  File? backup;
  bool installed = false;
}

Future<void> _replacePackAtomically({
  required Directory projectRoot,
  required List<_OutputArtifact> artifacts,
}) async {
  final rootPath = p.normalize(p.absolute(projectRoot.path));
  final destinations = <String>{};
  for (final artifact in artifacts) {
    final destinationPath = p.normalize(p.absolute(artifact.destination.path));
    if (!p.isWithin(rootPath, destinationPath)) {
      throw StateError('V3 organic output must stay inside the project root.');
    }
    if (!destinations.add(destinationPath)) {
      throw StateError('V3 organic pack contains a duplicate output.');
    }
  }

  final stagingDirectory = await projectRoot.createTemp(
    '.two-tier-cliff-v3-organic-$pid-',
  );
  final payloadDirectory = Directory(p.join(stagingDirectory.path, 'payload'));
  final backupDirectory = Directory(p.join(stagingDirectory.path, 'backup'));
  final staged = <File>[];
  final commits = <_PackCommit>[];
  try {
    await payloadDirectory.create();
    await backupDirectory.create();
    for (var index = 0; index < artifacts.length; index += 1) {
      final stagedFile = File(
        p.join(payloadDirectory.path, index.toString().padLeft(3, '0')),
      );
      await stagedFile.writeAsBytes(artifacts[index].bytes, flush: true);
      staged.add(stagedFile);
    }
    for (var index = 0; index < artifacts.length; index += 1) {
      final destination = File(
        p.normalize(p.absolute(artifacts[index].destination.path)),
      );
      if (Directory(destination.path).existsSync()) {
        throw StateError(
          'V3 organic output is occupied by a directory: ${destination.path}',
        );
      }
      final createdParents = await _createMissingDirectories(
        destination.parent,
        stopAt: projectRoot,
      );
      final commit = _PackCommit(
        destination: destination,
        createdParents: createdParents,
      );
      commits.add(commit);
      if (destination.existsSync()) {
        final backup = File(
          p.join(backupDirectory.path, index.toString().padLeft(3, '0')),
        );
        await destination.rename(backup.path);
        commit.backup = backup;
      }
      await staged[index].rename(destination.path);
      commit.installed = true;
    }
  } catch (error, stackTrace) {
    Object? rollbackError;
    for (final commit in commits.reversed) {
      try {
        if (commit.installed && commit.destination.existsSync()) {
          await commit.destination.delete();
        }
        if (commit.backup case final backup? when backup.existsSync()) {
          await backup.rename(commit.destination.path);
        }
        for (final directory in commit.createdParents.reversed) {
          if (directory.existsSync() && directory.listSync().isEmpty) {
            await directory.delete();
          }
        }
      } catch (currentRollbackError) {
        rollbackError ??= currentRollbackError;
      }
    }
    if (rollbackError != null) {
      Error.throwWithStackTrace(
        StateError(
          'V3 organic replacement failed ($error) and rollback failed '
          '($rollbackError).',
        ),
        stackTrace,
      );
    }
    Error.throwWithStackTrace(error, stackTrace);
  } finally {
    if (stagingDirectory.existsSync()) {
      await stagingDirectory.delete(recursive: true);
    }
  }
}

Future<List<Directory>> _createMissingDirectories(
  Directory destination, {
  required Directory stopAt,
}) async {
  final rootPath = p.normalize(p.absolute(stopAt.path));
  var current = Directory(p.normalize(p.absolute(destination.path)));
  final missing = <Directory>[];
  while (p.normalize(current.path) != rootPath && !current.existsSync()) {
    if (File(current.path).existsSync()) {
      throw StateError('V3 organic output parent is occupied by a file.');
    }
    missing.add(current);
    current = current.parent;
  }
  if (!current.existsSync() || File(current.path).existsSync()) {
    throw StateError('V3 organic output has no valid project parent.');
  }
  for (final directory in missing.reversed) {
    await directory.create();
  }
  return List<Directory>.unmodifiable(missing.reversed);
}

void _requireUniqueValues(
  Iterable<String> values, {
  required String message,
}) {
  final list = values.toList(growable: false);
  if (list.toSet().length != list.length) throw StateError(message);
}

String _sha256(List<int> bytes) => sha256.convert(bytes).toString();

String _hexRgb(int rgb) =>
    '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';

Future<void> main(List<String> arguments) async {
  String? topSheetPath;
  String? faceSheetPath;
  String? cornerSheetPath;
  String? projectRootPath;
  String? outputAtlasPath;
  String? provenancePath;
  var chromaRgb = 0xFF00FF;
  var chromaTolerance = 48;
  for (var index = 0; index < arguments.length; index += 1) {
    final argument = arguments[index];
    if (index + 1 >= arguments.length) {
      throw ArgumentError('Missing value for $argument.');
    }
    final value = arguments[++index];
    switch (argument) {
      case '--top-sheet':
        topSheetPath = value;
      case '--face-sheet':
        faceSheetPath = value;
      case '--corner-sheet':
        cornerSheetPath = value;
      case '--project-root':
        projectRootPath = value;
      case '--output-atlas':
        outputAtlasPath = value;
      case '--provenance':
        provenancePath = value;
      case '--chroma':
        chromaRgb = int.parse(
          value.startsWith('#') ? value.substring(1) : value,
          radix: 16,
        );
      case '--chroma-tolerance':
        chromaTolerance = int.parse(value);
      default:
        throw ArgumentError('Unknown argument: $argument');
    }
  }
  if (topSheetPath == null ||
      faceSheetPath == null ||
      cornerSheetPath == null ||
      projectRootPath == null ||
      outputAtlasPath == null ||
      provenancePath == null) {
    throw ArgumentError(
      'Usage: dart run '
      'tool/build_selbrume_two_tier_cliff_v3_organic_pack.dart '
      '--top-sheet <png> --face-sheet <png> --corner-sheet <png> '
      '--project-root <dir> '
      '--output-atlas <path> --provenance <path> '
      '[--chroma #FF00FF] [--chroma-tolerance 48]',
    );
  }
  final projectRoot = Directory(p.normalize(p.absolute(projectRootPath)));
  File resolve(String value) => File(
        p.isAbsolute(value)
            ? p.normalize(value)
            : p.normalize(p.join(projectRoot.path, value)),
      );
  final result = await buildSelbrumeTwoTierCliffV3OrganicPack(
    SelbrumeTwoTierCliffV3OrganicPackOptions(
      topSheet: File(p.normalize(p.absolute(topSheetPath))),
      faceSheet: File(p.normalize(p.absolute(faceSheetPath))),
      cornerSheet: File(p.normalize(p.absolute(cornerSheetPath))),
      projectRoot: projectRoot,
      outputAtlas: resolve(outputAtlasPath),
      provenance: resolve(provenancePath),
      chromaRgb: chromaRgb,
      chromaTolerance: chromaTolerance,
    ),
  );
  stdout.writeln(
    jsonEncode(<String, Object?>{
      'sourceCount': result.sourceFiles.length,
      'atlas': result.outputAtlas.path,
      'atlasSha256': result.atlasSha256,
      'provenance': result.provenance.path,
    }),
  );
}
