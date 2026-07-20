import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

const selbrumeTwoTierCliffSourceRelativePath =
    'assets/sources/border_studio/two_tier_cliff_v2';
const selbrumeTwoTierCliffAtlasRelativePath =
    'assets/tilesets/falaises_selbrume_deux_etages_v2.png';
const selbrumeTwoTierCliffProvenanceRelativePath =
    'assets/provenance/selbrume_two_tier_cliff_v2.json';

const _tileSize = 32;
const _atlasColumns = 6;
const _atlasRows = 4;
const _collisionIntent = 'visual_only_no_collision';
const _sourceLabel = 'OpenAI ImageGen contact sheet refined for Selbrume';
const _licenseLabel = 'project-owned generated asset';
const _status = 'approved';

const _allowedPalette = <(int, int, int)>[
  (166, 156, 123),
  (145, 136, 109),
  (126, 118, 96),
  (108, 101, 84),
  (91, 85, 72),
  (77, 72, 62),
  (62, 58, 51),
  (48, 45, 40),
];

enum _StoneTier { top, face }

enum _StoneOrientation { north, east, south, west }

final class SelbrumeTwoTierCliffPackOptions {
  const SelbrumeTwoTierCliffPackOptions({
    required this.sheet,
    required this.projectRoot,
    required this.outputAtlas,
    required this.provenance,
    this.chromaRgb = 0xFF00FF,
    this.chromaTolerance = 48,
  });

  final File sheet;
  final Directory projectRoot;
  final File outputAtlas;
  final File provenance;
  final int chromaRgb;
  final int chromaTolerance;
}

final class SelbrumeTwoTierCliffPackBuildResult {
  const SelbrumeTwoTierCliffPackBuildResult({
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

Future<SelbrumeTwoTierCliffPackBuildResult> buildSelbrumeTwoTierCliffPack(
  SelbrumeTwoTierCliffPackOptions options,
) async {
  _validateOptions(options);
  final sheetBytes = options.sheet.readAsBytesSync();
  final sheet = img.decodePng(sheetBytes);
  if (sheet == null) {
    throw StateError('Two-tier cliff contact sheet is not a valid PNG.');
  }
  final components = _extractOrderedComponents(
    sheet,
    chromaRgb: options.chromaRgb,
    chromaTolerance: options.chromaTolerance,
  );
  final specs = _spriteSpecs();
  if (components.length != specs.length) {
    throw StateError(
      'Two-tier cliff contact sheet must contain exactly 24 isolated stones; '
      'found ${components.length}.',
    );
  }

  final prepared = <_PreparedSprite>[];
  for (var index = 0; index < specs.length; index += 1) {
    final spec = specs[index];
    final component = components[index];
    final source = _componentImage(sheet, component);
    final sprite = _normalizeSprite(source, spec);
    _validateSprite(sprite, spec);
    final tone = _tonePermille(sprite);
    final bytes = Uint8List.fromList(img.encodePng(sprite));
    prepared.add(
      _PreparedSprite(
        spec: spec,
        bytes: bytes,
        sha256: _sha256(bytes),
        opaqueBounds: _opaqueBounds(sprite),
        lightOrMediumPermille: tone.lightOrMedium,
        darkPermille: tone.dark,
      ),
    );
  }
  _requireUniqueHashes(prepared.map((entry) => entry.sha256));

  final atlas = img.Image(
    width: _atlasColumns * _tileSize,
    height: _atlasRows * _tileSize,
    numChannels: 4,
  );
  for (var index = 0; index < prepared.length; index += 1) {
    final sprite = img.decodePng(prepared[index].bytes)!;
    img.compositeImage(
      atlas,
      sprite,
      dstX: (index % _atlasColumns) * _tileSize,
      dstY: (index ~/ _atlasColumns) * _tileSize,
    );
  }
  final atlasBytes = Uint8List.fromList(img.encodePng(atlas));
  final atlasSha256 = _sha256(atlasBytes);
  final derivativeSnapshotAssets = _approvedDerivativeSnapshotAssets(
    options.projectRoot,
    prepared,
    existingProvenance: options.provenance,
  );
  final provenanceBytes = Uint8List.fromList(
    utf8.encode(
      '${const JsonEncoder.withIndent('  ').convert(<String, Object?>{
            'schemaVersion': 1,
            'source': _sourceLabel,
            'license': _licenseLabel,
            'status': _status,
            'collisionIntent': _collisionIntent,
            'sheetSha256': _sha256(sheetBytes),
            'atlasSha256': atlasSha256,
            'chroma': _hexRgb(options.chromaRgb),
            'chromaTolerance': options.chromaTolerance,
            'tileSize': <String, int>{'width': _tileSize, 'height': _tileSize},
            'atlasGrid': <String, int>{
              'columns': _atlasColumns,
              'rows': _atlasRows,
            },
            'palette': <String>[
              for (final color in _allowedPalette)
                '#${color.$1.toRadixString(16).padLeft(2, '0').toUpperCase()}'
                    '${color.$2.toRadixString(16).padLeft(2, '0').toUpperCase()}'
                    '${color.$3.toRadixString(16).padLeft(2, '0').toUpperCase()}',
            ],
            'assets': <String, Map<String, String>>{
              _relativeToAssetRoot(selbrumeTwoTierCliffAtlasRelativePath):
                  _inventoryProvenanceRecord(),
              for (final entry in prepared)
                _relativeToAssetRoot(
                  '$selbrumeTwoTierCliffSourceRelativePath/'
                  '${entry.spec.fileName}',
                ): _inventoryProvenanceRecord(),
              ...derivativeSnapshotAssets,
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
      ...selbrumeTwoTierCliffSourceRelativePath.split('/'),
    ]),
  );
  final sourceFiles = <File>[
    for (final entry in prepared)
      File(p.join(sourceDirectory.path, entry.spec.fileName)),
  ];

  // No destination is touched until every source, atlas and provenance byte
  // has been generated, validated and staged. The whole pack is then replaced
  // as one transaction so a late I/O failure cannot leave a mixed generation.
  await _replacePackAtomically(
    projectRoot: options.projectRoot,
    artifacts: <_OutputArtifact>[
      for (var index = 0; index < prepared.length; index += 1)
        _OutputArtifact(sourceFiles[index], prepared[index].bytes),
      _OutputArtifact(options.outputAtlas, atlasBytes),
      _OutputArtifact(options.provenance, provenanceBytes),
    ],
  );

  return SelbrumeTwoTierCliffPackBuildResult(
    sourceFiles: List<File>.unmodifiable(sourceFiles),
    outputAtlas: options.outputAtlas,
    provenance: options.provenance,
    atlasSha256: atlasSha256,
  );
}

Map<String, Map<String, String>> _approvedDerivativeSnapshotAssets(
  Directory projectRoot,
  List<_PreparedSprite> prepared, {
  required File existingProvenance,
}) {
  final result = SplayTreeMap<String, Map<String, String>>();
  final sourceFileNames = <String>{
    for (final entry in prepared) entry.spec.fileName,
  };
  _preserveValidatedHistoricalSnapshots(
    projectRoot: projectRoot,
    existingProvenance: existingProvenance,
    allowedSourceFileNames: sourceFileNames,
    result: result,
  );

  final sourcePathBySha256 = <String, String>{
    for (final entry in prepared)
      entry.sha256: _relativeToAssetRoot(
        '$selbrumeTwoTierCliffSourceRelativePath/${entry.spec.fileName}',
      ),
  };
  final snapshotsRoot = Directory(
    p.join(
      p.normalize(p.absolute(projectRoot.path)),
      'assets',
      'borders',
      'snapshots',
    ),
  );
  if (!snapshotsRoot.existsSync()) {
    return result;
  }

  final snapshotIdPattern = RegExp(r'^[0-9a-f]{64}$');
  for (final candidate in snapshotsRoot.listSync(followLinks: false)) {
    if (FileSystemEntity.typeSync(candidate.path, followLinks: false) !=
        FileSystemEntityType.directory) {
      continue;
    }
    final snapshotId = p.basename(candidate.path);
    if (!snapshotIdPattern.hasMatch(snapshotId)) continue;
    final frame = File(p.join(candidate.path, 'frame_0000.png'));
    if (FileSystemEntity.typeSync(frame.path, followLinks: false) !=
        FileSystemEntityType.file) {
      continue;
    }
    final digest = _sha256(frame.readAsBytesSync());
    final sourcePath = sourcePathBySha256[digest];
    if (sourcePath == null) continue;
    final snapshotPath = 'borders/snapshots/$snapshotId/frame_0000.png';
    result[snapshotPath] = <String, String>{
      'source': 'Byte-identical immutable Border Studio publication snapshot '
          'derived from assets/$sourcePath (sha256:$digest)',
      'license': _licenseLabel,
      'status': _status,
    };
  }
  return result;
}

void _preserveValidatedHistoricalSnapshots({
  required Directory projectRoot,
  required File existingProvenance,
  required Set<String> allowedSourceFileNames,
  required SplayTreeMap<String, Map<String, String>> result,
}) {
  if (FileSystemEntity.typeSync(
        existingProvenance.path,
        followLinks: false,
      ) !=
      FileSystemEntityType.file) {
    return;
  }

  Object? decoded;
  try {
    decoded = jsonDecode(existingProvenance.readAsStringSync());
  } on Object {
    return;
  }
  if (decoded is! Map<String, dynamic>) return;
  final assets = decoded['assets'];
  if (assets is! Map<String, dynamic>) return;

  final snapshotPathPattern = RegExp(
    r'^borders/snapshots/([0-9a-f]{64})/frame_0000\.png$',
  );
  final sourcePattern = RegExp(
    '^${RegExp.escape('Byte-identical immutable Border Studio publication snapshot derived from assets/')}'
    '([^ ]+) '
    '\\(sha256:([0-9a-f]{64})\\)\$',
  );
  for (final MapEntry(:key, :value) in assets.entries) {
    final pathMatch = snapshotPathPattern.firstMatch(key);
    if (pathMatch == null || value is! Map<String, dynamic>) continue;
    if (value['license'] != _licenseLabel || value['status'] != _status) {
      continue;
    }
    final source = value['source'];
    if (source is! String) continue;
    final sourceMatch = sourcePattern.firstMatch(source);
    if (sourceMatch == null) continue;
    final sourcePath = sourceMatch.group(1)!;
    final expectedSourcePrefix =
        '${_relativeToAssetRoot(selbrumeTwoTierCliffSourceRelativePath)}/';
    if (!sourcePath.startsWith(expectedSourcePrefix)) continue;
    final sourceFileName = sourcePath.substring(expectedSourcePrefix.length);
    if (!allowedSourceFileNames.contains(sourceFileName)) continue;

    final frame = File(
      p.join(
        p.normalize(p.absolute(projectRoot.path)),
        'assets',
        'borders',
        'snapshots',
        pathMatch.group(1)!,
        'frame_0000.png',
      ),
    );
    if (FileSystemEntity.typeSync(frame.path, followLinks: false) !=
        FileSystemEntityType.file) {
      continue;
    }
    final actualDigest = _sha256(frame.readAsBytesSync());
    if (actualDigest != sourceMatch.group(2)) continue;
    result[key] = <String, String>{
      'source': source,
      'license': _licenseLabel,
      'status': _status,
    };
  }
}

void _validateOptions(SelbrumeTwoTierCliffPackOptions options) {
  if (!options.sheet.existsSync()) {
    throw StateError('Missing two-tier cliff sheet: ${options.sheet.path}');
  }
  if (options.chromaRgb < 0 || options.chromaRgb > 0xFFFFFF) {
    throw ArgumentError.value(options.chromaRgb, 'chromaRgb');
  }
  if (options.chromaTolerance < 0 || options.chromaTolerance > 441) {
    throw ArgumentError.value(
      options.chromaTolerance,
      'chromaTolerance',
    );
  }
}

List<_OpaqueComponent> _extractOrderedComponents(
  img.Image sheet, {
  required int chromaRgb,
  required int chromaTolerance,
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
      final pixel = sheet.getPixel(x, y);
      if (pixel.a.toInt() == 0) {
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
  if (components.length == 24 &&
      components.any(
        (component) =>
            component.left == 0 ||
            component.top == 0 ||
            component.right == width - 1 ||
            component.bottom == height - 1,
      )) {
    throw StateError(
      'Two-tier cliff stone touches the contact sheet edge and may be clipped.',
    );
  }
  if (components.length != 24) return components;
  return _orderFourRowsOfSix(components);
}

List<_OpaqueComponent> _orderFourRowsOfSix(
  List<_OpaqueComponent> components,
) {
  _requireSixSeparatedColumns(components);
  final byY = List<_OpaqueComponent>.of(components)
    ..sort((left, right) {
      final byCentroid = left.centroidY.compareTo(right.centroidY);
      return byCentroid != 0
          ? byCentroid
          : left.centroidX.compareTo(right.centroidX);
    });
  final gaps = <({int index, double size})>[
    for (var index = 1; index < byY.length; index += 1)
      (
        index: index,
        size: byY[index].centroidY - byY[index - 1].centroidY,
      ),
  ]..sort((left, right) {
      final bySize = right.size.compareTo(left.size);
      return bySize != 0 ? bySize : left.index.compareTo(right.index);
    });
  final boundaries = gaps.take(3).map((gap) => gap.index).toList()..sort();
  if (boundaries.length != 3 ||
      boundaries[0] != 6 ||
      boundaries[1] != 12 ||
      boundaries[2] != 18) {
    throw StateError(
      'Two-tier cliff component centroids do not form four rows of six.',
    );
  }
  final weakestBoundary = gaps.take(3).map((gap) => gap.size).reduce(math.min);
  final strongestWithin = gaps.skip(3).map((gap) => gap.size).reduce(math.max);
  if (weakestBoundary <= strongestWithin) {
    throw StateError('Two-tier cliff component rows are ambiguous.');
  }
  final ordered = <_OpaqueComponent>[];
  for (var row = 0; row < 4; row += 1) {
    final rowItems = byY.sublist(row * 6, row * 6 + 6)
      ..sort((left, right) => left.centroidX.compareTo(right.centroidX));
    for (var index = 1; index < rowItems.length; index += 1) {
      if (rowItems[index - 1].centroidX >= rowItems[index].centroidX) {
        throw StateError('Two-tier cliff component columns are ambiguous.');
      }
    }
    ordered.addAll(rowItems);
  }
  return ordered;
}

void _requireSixSeparatedColumns(List<_OpaqueComponent> components) {
  final byX = List<_OpaqueComponent>.of(components)
    ..sort((left, right) {
      final byCentroid = left.centroidX.compareTo(right.centroidX);
      return byCentroid != 0
          ? byCentroid
          : left.centroidY.compareTo(right.centroidY);
    });
  final gaps = <({int index, double size})>[
    for (var index = 1; index < byX.length; index += 1)
      (
        index: index,
        size: byX[index].centroidX - byX[index - 1].centroidX,
      ),
  ]..sort((left, right) {
      final bySize = right.size.compareTo(left.size);
      return bySize != 0 ? bySize : left.index.compareTo(right.index);
    });
  final boundaries = gaps.take(5).map((gap) => gap.index).toList()..sort();
  const expectedBoundaries = <int>[4, 8, 12, 16, 20];
  if (boundaries.length != expectedBoundaries.length ||
      !List<int>.generate(
        expectedBoundaries.length,
        (index) => index,
      ).every((index) => boundaries[index] == expectedBoundaries[index])) {
    throw StateError(
      'Two-tier cliff component centroids do not form six columns of four.',
    );
  }
  final weakestBoundary = gaps.take(5).map((gap) => gap.size).reduce(math.min);
  final strongestWithin = gaps.skip(5).map((gap) => gap.size).reduce(math.max);
  if (weakestBoundary <= strongestWithin) {
    throw StateError('Two-tier cliff component columns are ambiguous.');
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
  final width = component.right - component.left + 1;
  final height = component.bottom - component.top + 1;
  final result = img.Image(width: width, height: height, numChannels: 4);
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
  final normalized = img.Image(
    width: spec.targetWidth,
    height: spec.targetHeight,
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
  // Nearest-neighbour inverse sampling can skip a one-pixel bridge or
  // extremum. Forward-projecting the connected source mask as well preserves
  // 4-connectivity while keeping hard pixels and the exact target bounds.
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
  _normalizeTierTone(normalized, spec);
  final canvas = img.Image(width: _tileSize, height: _tileSize, numChannels: 4);
  final offset = spec.opaqueOffset;
  if (offset.$1 < 0 ||
      offset.$2 < 0 ||
      offset.$1 + normalized.width > _tileSize ||
      offset.$2 + normalized.height > _tileSize) {
    throw StateError('${spec.fileName} would clip its 32x32 canvas.');
  }
  img.compositeImage(canvas, normalized, dstX: offset.$1, dstY: offset.$2);
  return canvas;
}

void _normalizeTierTone(img.Image image, _SpriteSpec spec) {
  final pixels = <({int x, int y, int paletteIndex, int stableOrder})>[];
  var currentLight = 0;
  for (var y = 0; y < image.height; y += 1) {
    for (var x = 0; x < image.width; x += 1) {
      final pixel = image.getPixel(x, y);
      if (pixel.a.toInt() == 0) continue;
      final color = (pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt());
      final paletteIndex = _allowedPalette.indexOf(color);
      if (paletteIndex < 0) {
        throw StateError('${spec.fileName} contains an off-palette pixel.');
      }
      if (paletteIndex < 4) currentLight += 1;
      pixels.add((
        x: x,
        y: y,
        paletteIndex: paletteIndex,
        stableOrder: (x * 37 +
                y * 61 +
                spec.variant * 17 +
                spec.orientation.index * 29) %
            997,
      ));
    }
  }
  if (pixels.isEmpty) return;

  // Nearest-colour quantization establishes the source shading first. This
  // second deterministic pass only moves the minimum required pixels across
  // the light/dark palette boundary so every authored role carries a readable
  // two-tier contrast after resizing.
  final targetLightPermille = spec.tier == _StoneTier.top ? 600 : 400;
  final targetLight = (pixels.length * targetLightPermille / 1000).round();
  if (currentLight == targetLight) return;
  final darkening = currentLight > targetLight;
  final candidates = pixels
      .where(
        (pixel) => darkening ? pixel.paletteIndex < 4 : pixel.paletteIndex >= 4,
      )
      .toList()
    ..sort((left, right) {
      final byShade = darkening
          ? right.paletteIndex.compareTo(left.paletteIndex)
          : left.paletteIndex.compareTo(right.paletteIndex);
      if (byShade != 0) return byShade;
      final byOrder = left.stableOrder.compareTo(right.stableOrder);
      if (byOrder != 0) return byOrder;
      final byY = left.y.compareTo(right.y);
      return byY != 0 ? byY : left.x.compareTo(right.x);
    });
  final changes = (currentLight - targetLight).abs();
  if (candidates.length < changes) {
    throw StateError('${spec.fileName} cannot reach its tier tone target.');
  }
  for (final pixel in candidates.take(changes)) {
    final shade = (pixel.x * 11 + pixel.y * 7 + spec.variant * 3) % 4;
    final color = _allowedPalette[darkening ? 4 + shade : shade];
    image.setPixelRgba(
      pixel.x,
      pixel.y,
      color.$1,
      color.$2,
      color.$3,
      255,
    );
  }
}

(int, int, int) _nearestPaletteColor(img.Pixel pixel) {
  var best = _allowedPalette.first;
  var bestDistance = 1 << 62;
  for (final candidate in _allowedPalette) {
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

void _validateSprite(img.Image sprite, _SpriteSpec spec) {
  if (sprite.width != _tileSize || sprite.height != _tileSize) {
    throw StateError('${spec.fileName} is not 32x32.');
  }
  final alpha = <int>{for (final pixel in sprite) pixel.a.toInt()};
  if (!alpha.every((value) => value == 0 || value == 255) ||
      !alpha.contains(255)) {
    throw StateError('${spec.fileName} does not have binary non-empty alpha.');
  }
  if (_opaqueComponentCount(sprite) != 1) {
    throw StateError('${spec.fileName} must contain one connected stone.');
  }
  final bounds = _opaqueBounds(sprite);
  final expected = (
    spec.opaqueOffset.$1,
    spec.opaqueOffset.$2,
    spec.targetWidth,
    spec.targetHeight,
  );
  if (bounds != expected) {
    throw StateError(
      '${spec.fileName} opaque bounds $bounds do not match $expected.',
    );
  }
  for (final pixel in sprite) {
    if (pixel.a.toInt() == 0) continue;
    final color = (pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt());
    if (!_allowedPalette.contains(color)) {
      throw StateError('${spec.fileName} contains an off-palette pixel.');
    }
  }
  final tone = _tonePermille(sprite);
  final intendedTone =
      spec.tier == _StoneTier.top ? tone.lightOrMedium : tone.dark;
  if (intendedTone < 550 || intendedTone > 650) {
    final label = spec.tier == _StoneTier.top ? 'light/medium' : 'dark';
    throw StateError(
      '${spec.fileName} must contain 55-65% $label pixels; '
      'found $intendedTone permille.',
    );
  }
}

({int lightOrMedium, int dark}) _tonePermille(img.Image image) {
  var opaque = 0;
  var lightOrMedium = 0;
  for (final pixel in image) {
    if (pixel.a.toInt() == 0) continue;
    opaque += 1;
    final color = (pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt());
    if (_allowedPalette.take(4).contains(color)) lightOrMedium += 1;
  }
  if (opaque == 0) return (lightOrMedium: 0, dark: 0);
  final lightPermille = (lightOrMedium * 1000 / opaque).round();
  return (lightOrMedium: lightPermille, dark: 1000 - lightPermille);
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

List<_SpriteSpec> _spriteSpecs() {
  final result = <_SpriteSpec>[];
  void addFamily(
      _StoneTier tier, _StoneOrientation first, _StoneOrientation second) {
    for (final orientation in <_StoneOrientation>[first, second]) {
      for (var variant = 1; variant <= 3; variant += 1) {
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

  addFamily(_StoneTier.top, _StoneOrientation.north, _StoneOrientation.east);
  addFamily(_StoneTier.top, _StoneOrientation.south, _StoneOrientation.west);
  addFamily(_StoneTier.face, _StoneOrientation.north, _StoneOrientation.east);
  addFamily(_StoneTier.face, _StoneOrientation.south, _StoneOrientation.west);
  return List<_SpriteSpec>.unmodifiable(result);
}

Map<String, Object?> _provenanceEntry(_PreparedSprite entry, int index) =>
    <String, Object?>{
      'id': entry.spec.id,
      'fileName': entry.spec.fileName,
      'sourceRelativePath':
          '$selbrumeTwoTierCliffSourceRelativePath/${entry.spec.fileName}',
      'sha256': entry.sha256,
      'role': entry.spec.tier.name,
      'authoredOrientation': entry.spec.orientation.name,
      'anchorPx': <String, int>{
        'x': entry.spec.anchor.$1,
        'y': entry.spec.anchor.$2,
      },
      'opaqueBoundsPx': <String, int>{
        'x': entry.opaqueBounds.$1,
        'y': entry.opaqueBounds.$2,
        'width': entry.opaqueBounds.$3,
        'height': entry.opaqueBounds.$4,
      },
      'lightOrMediumPermille': entry.lightOrMediumPermille,
      'darkPermille': entry.darkPermille,
      'atlasCell': <String, int>{
        'column': index % _atlasColumns,
        'row': index ~/ _atlasColumns,
      },
      'collisionIntent': _collisionIntent,
      'source': _sourceLabel,
      'license': _licenseLabel,
      'status': _status,
    };

Map<String, String> _inventoryProvenanceRecord() => <String, String>{
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

final class _OutputArtifact {
  const _OutputArtifact(this.destination, this.bytes);

  final File destination;
  final Uint8List bytes;
}

final class _PackCommit {
  _PackCommit({
    required this.destination,
    required this.createdParents,
  });

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
  if (!projectRoot.existsSync()) {
    throw StateError('Project root does not exist: $rootPath');
  }
  final destinations = <String>{};
  for (final artifact in artifacts) {
    final destinationPath = p.normalize(p.absolute(artifact.destination.path));
    if (!p.isWithin(rootPath, destinationPath)) {
      throw StateError(
        'Two-tier cliff output must stay inside the project root: '
        '$destinationPath',
      );
    }
    if (!destinations.add(destinationPath)) {
      throw StateError(
        'Two-tier cliff pack contains a duplicate output: $destinationPath',
      );
    }
  }

  final stagingDirectory = await projectRoot.createTemp(
    '.two-tier-cliff-pack-$pid-',
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
      final artifact = artifacts[index];
      final destination = File(
        p.normalize(p.absolute(artifact.destination.path)),
      );
      if (Directory(destination.path).existsSync()) {
        throw StateError(
          'Two-tier cliff output is occupied by a directory: '
          '${destination.path}',
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
        final backup = commit.backup;
        if (backup != null && backup.existsSync()) {
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
          'Two-tier cliff pack replacement failed ($error) and rollback '
          'also failed ($rollbackError).',
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
      throw StateError(
        'Two-tier cliff output parent is occupied by a file: ${current.path}',
      );
    }
    missing.add(current);
    current = current.parent;
  }
  if (!current.existsSync() || File(current.path).existsSync()) {
    throw StateError(
      'Two-tier cliff output has no valid project parent: ${destination.path}',
    );
  }
  for (final directory in missing.reversed) {
    await directory.create();
  }
  return List<Directory>.unmodifiable(missing.reversed);
}

void _requireUniqueHashes(Iterable<String> hashes) {
  final values = hashes.toList(growable: false);
  if (values.toSet().length != values.length) {
    throw StateError('Two-tier cliff sprites must have unique PNG hashes.');
  }
}

String _sha256(List<int> bytes) => sha256.convert(bytes).toString();

String _hexRgb(int rgb) =>
    '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';

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
    required this.opaqueBounds,
    required this.lightOrMediumPermille,
    required this.darkPermille,
  });

  final _SpriteSpec spec;
  final Uint8List bytes;
  final String sha256;
  final (int, int, int, int) opaqueBounds;
  final int lightOrMediumPermille;
  final int darkPermille;
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

  String get rolePrefix => tier == _StoneTier.top ? 'top' : 'face';

  String get orientationWire => switch (orientation) {
        _StoneOrientation.north => 'n',
        _StoneOrientation.east => 'e',
        _StoneOrientation.south => 's',
        _StoneOrientation.west => 'w',
      };

  String get id => 'selbrume-cliff-$rolePrefix-$orientationWire-'
      '${variant.toString().padLeft(2, '0')}';

  String get fileName => '${rolePrefix}_${orientationWire}_'
      '${variant.toString().padLeft(2, '0')}.png';

  // Preserve the narrow cadence of the authored individual stones. The V2
  // source sheet already contains slim rocks, but the previous normalization
  // widened them into 18-24 px modules. On a one-cell stair-step coast those
  // modules formed repeated wall blocks instead of an interlocked stone line.
  int get tangentSpan =>
      tier == _StoneTier.top ? 10 + variant * 2 : 8 + variant * 2;

  int get normalSpan =>
      tier == _StoneTier.top ? 8 + variant * 2 : 27;

  int get targetWidth => switch (orientation) {
        _StoneOrientation.north || _StoneOrientation.south => tangentSpan,
        _StoneOrientation.east || _StoneOrientation.west => normalSpan,
      };

  int get targetHeight => switch (orientation) {
        _StoneOrientation.north || _StoneOrientation.south => normalSpan,
        _StoneOrientation.east || _StoneOrientation.west => tangentSpan,
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

  (int, int) get anchor {
    final face = tier == _StoneTier.face;
    return switch (orientation) {
      // A face owns a 5 px opaque neck hidden behind the lip and 22 px of
      // visible depth. The negative cardinal axes use 31/9 instead of 32/10
      // because anchors must stay inside the 32 px raster.
      _StoneOrientation.north => (16, face ? 31 : 9),
      _StoneOrientation.east => (face ? 0 : 22, 16),
      _StoneOrientation.south => (16, face ? 0 : 22),
      _StoneOrientation.west => (face ? 31 : 9, 16),
    };
  }
}

Future<void> main(List<String> arguments) async {
  String? sheetPath;
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
      case '--sheet':
        sheetPath = value;
      case '--project-root':
        projectRootPath = value;
      case '--output-atlas':
        outputAtlasPath = value;
      case '--provenance':
        provenancePath = value;
      case '--chroma':
        final wire = value.startsWith('#') ? value.substring(1) : value;
        chromaRgb = int.parse(wire, radix: 16);
      case '--chroma-tolerance':
        chromaTolerance = int.parse(value);
      default:
        throw ArgumentError('Unknown argument: $argument');
    }
  }
  if (sheetPath == null ||
      projectRootPath == null ||
      outputAtlasPath == null ||
      provenancePath == null) {
    throw ArgumentError(
      'Usage: dart run tool/build_selbrume_two_tier_cliff_pack.dart '
      '--sheet <png> --project-root <dir> --output-atlas <path> '
      '--provenance <path> [--chroma #FF00FF] '
      '[--chroma-tolerance 48]',
    );
  }
  final projectRoot = Directory(p.normalize(p.absolute(projectRootPath)));
  File resolve(String value) => File(
        p.isAbsolute(value)
            ? p.normalize(value)
            : p.normalize(p.join(projectRoot.path, value)),
      );
  final result = await buildSelbrumeTwoTierCliffPack(
    SelbrumeTwoTierCliffPackOptions(
      sheet: File(p.normalize(p.absolute(sheetPath))),
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
