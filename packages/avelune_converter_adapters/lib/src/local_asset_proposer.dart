import 'dart:collection';
import 'dart:typed_data';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:image/image.dart' as image;

import 'literal_tile_composer.dart';
import 'native_project_writer.dart';

final class LocalAssetProposalLimits {
  const LocalAssetProposalLimits({
    this.maxSourceImages = 32,
    this.maxSourceBytes = 67108864,
    this.maxPixels = 16777216,
    this.maxMapCells = 1048576,
    this.maxComponents = 4096,
    this.maxCandidates = 256,
    this.maxPartsPerCandidate = 4096,
    this.maxTotalParts = 16384,
    this.maxUsageComparisons = 1048576,
    this.jsonLimits = const ContractLimits(),
  });

  final int maxSourceImages;
  final int maxSourceBytes;
  final int maxPixels;
  final int maxMapCells;
  final int maxComponents;
  final int maxCandidates;
  final int maxPartsPerCandidate;
  final int maxTotalParts;
  final int maxUsageComparisons;
  final ContractLimits jsonLimits;
}

final class LocalAssetCell {
  const LocalAssetCell({
    required this.mapId,
    required this.sourceZ,
    required this.x,
    required this.y,
  });

  final int mapId;
  final int sourceZ;
  final int x;
  final int y;
}

final class LocalAssetProposalDiagnostic {
  const LocalAssetProposalDiagnostic(this.code, this.message,
      {this.sourceFileId, this.mapId});

  final String code;
  final String message;
  final ConverterId? sourceFileId;
  final int? mapId;

  Map<String, Object?> toJson() => {
        'code': code,
        'message': message,
        'sourceFileId': sourceFileId?.value,
        'mapId': mapId,
      };
}

final class LocalAssetProposalSet {
  LocalAssetProposalSet._({
    required List<AssetCandidate> candidates,
    required List<LocalAssetProposalDiagnostic> diagnostics,
    required this.sourceSnapshotHash,
    required this.normalizedSourceHash,
    required this.literalCompositionHash,
    required this.canonicalHash,
  })  : candidates = List.unmodifiable(candidates),
        diagnostics = List.unmodifiable(diagnostics);

  final List<AssetCandidate> candidates;
  final List<LocalAssetProposalDiagnostic> diagnostics;
  final Sha256Hash sourceSnapshotHash;
  final Sha256Hash normalizedSourceHash;
  final Sha256Hash literalCompositionHash;
  final Sha256Hash canonicalHash;

  Map<String, Object?> toJson() => {
        'kind': 'localAssetProposals',
        'version': 1,
        'sourceSnapshotHash': sourceSnapshotHash.value,
        'normalizedSourceHash': normalizedSourceHash.value,
        'literalCompositionHash': literalCompositionHash.value,
        'candidates': candidates.map((c) => c.toJson()).toList(),
        'diagnostics': diagnostics.map((d) => d.toJson()).toList(),
      };
}

final class LocalAssetProposer {
  const LocalAssetProposer();

  Future<LocalAssetProposalSet> propose({
    required NormalizedSourceProject source,
    required SourceFilePort files,
    required LiteralTileComposition literal,
    AssetOutputMode outputMode = AssetOutputMode.sharedAtlas,
    LocalAssetProposalLimits limits = const LocalAssetProposalLimits(),
    ScanCancellation? cancellation,
  }) async {
    cancellation?.check();
    final inputs = _AssetInputs(source, literal, outputMode, limits);
    final diagnostics = <LocalAssetProposalDiagnostic>[];
    final alpha = <ConverterId, Uint8List>{};
    final candidates = <ConverterId, AssetCandidate>{};
    var totalParts = 0;
    var components = 0;
    for (final info in inputs.images.values) {
      cancellation?.check();
      final List<int> bytes;
      try {
        bytes = await files.read(info.entry.fileId);
      } on Object {
        cancellation?.check();
        throw ContractError('asset.proposal.read', info.entry.relativePath,
            'Source image cannot be read');
      }
      cancellation?.check();
      if (bytes.length != info.entry.byteLength ||
          crypto.sha256.convert(bytes).toString() != info.entry.sha256!.value) {
        throw ContractError(
            'asset.proposal.source_changed',
            info.entry.relativePath,
            'Source image bytes differ from the admitted snapshot');
      }
      const NativePngValidator().validate(bytes,
          limits: NativeWriteLimits(maxImagePixels: limits.maxPixels));
      final decoded = image.decodePng(Uint8List.fromList(bytes));
      if (decoded == null ||
          decoded.width != info.width ||
          decoded.height != info.height) {
        throw ContractError('asset.proposal.image', info.entry.relativePath,
            'Source image geometry could not be decoded');
      }
      final columns = info.width ~/ 32;
      final rows = info.height ~/ 32;
      final occupied = Uint8List(columns * rows);
      for (var cy = 0; cy < rows; cy++) {
        cancellation?.check();
        for (var cx = 0; cx < columns; cx++) {
          var nonzero = false;
          for (var y = 0; y < 32 && !nonzero; y++) {
            for (var x = 0; x < 32; x++) {
              if (decoded.getPixel(cx * 32 + x, cy * 32 + y).a > 0) {
                nonzero = true;
                break;
              }
            }
          }
          occupied[cy * columns + cx] = nonzero ? 1 : 0;
        }
        await Future<void>.delayed(Duration.zero);
      }
      alpha[info.entry.fileId] = occupied;
      final used = inputs.crops.values
          .where((crop) => crop.imageFileId == info.entry.fileId)
          .map((crop) => (crop.y ~/ 32) * columns + crop.x ~/ 32)
          .toSet();
      final seen = Uint8List(occupied.length);
      for (var seed = 0; seed < occupied.length; seed++) {
        if (occupied[seed] == 0 || seen[seed] != 0) continue;
        if (++components > limits.maxComponents) {
          _quota('Alpha component budget exceeded');
        }
        final queue = Queue<int>()..add(seed);
        seen[seed] = 1;
        final region = <int>[];
        var placed = false;
        while (queue.isNotEmpty) {
          final cell = queue.removeFirst();
          region.add(cell);
          placed = placed || used.contains(cell);
          for (final next in _neighbors(cell, columns, rows)) {
            if (occupied[next] != 0 && seen[next] == 0) {
              seen[next] = 1;
              queue.add(next);
            }
          }
        }
        if (!placed) {
          if (region.length > limits.maxPartsPerCandidate ||
              region.length + totalParts > limits.maxTotalParts ||
              candidates.length >= limits.maxCandidates) {
            _quota('Unplaced alpha region budget exceeded');
          }
          final candidate = inputs.alphaCandidate(info, region);
          candidates[candidate.candidateId] = candidate;
          totalParts += region.length;
        }
        cancellation?.check();
        await Future<void>.delayed(Duration.zero);
      }
    }
    var usageChecks = 0;
    for (final map in inputs.maps.values) {
      cancellation?.check();
      final layers = inputs.layerCells[map.sourceMapId]!;
      final occupied = Uint8List(map.width * map.height);
      for (var index = 0; index < occupied.length; index++) {
        occupied[index] =
            layers.values.any((cells) => cells[index] != 0) ? 1 : 0;
      }
      final seen = Uint8List(occupied.length);
      for (var seed = 0; seed < occupied.length; seed++) {
        if (occupied[seed] == 0 || seen[seed] != 0) continue;
        cancellation?.check();
        if (++components > limits.maxComponents) {
          _quota('Placement component budget exceeded');
        }
        final queue = Queue<int>()..add(seed);
        seen[seed] = 1;
        final cells = <LocalAssetCell>[];
        while (queue.isNotEmpty) {
          final cell = queue.removeFirst();
          for (final layer in layers.entries) {
            if (layer.value[cell] == 0) continue;
            if (cells.length >= limits.maxPartsPerCandidate ||
                totalParts + cells.length + 1 > limits.maxTotalParts) {
              _quota('Placement parts budget exceeded');
            }
            cells.add(LocalAssetCell(
                mapId: map.sourceMapId,
                sourceZ: layer.key,
                x: cell % map.width,
                y: cell ~/ map.width));
          }
          for (final next in _neighbors(cell, map.width, map.height)) {
            if (occupied[next] != 0 && seen[next] == 0) {
              seen[next] = 1;
              queue.add(next);
            }
          }
        }
        if (cells.any((cell) =>
            layers[cell.sourceZ]![cell.y * map.width + cell.x] < 384)) {
          diagnostics.add(LocalAssetProposalDiagnostic(
              'asset.proposal.animated_deferred',
              'Autotile parts remain literal; a verified per-frame object composition is not proposed.',
              mapId: map.sourceMapId));
          continue;
        }
        var candidate = inputs.candidate(cells, manual: false);
        final parts = candidate.parts;
        final geometry = Map<String, Object?>.from(candidate.toJson());
        final evidence = (geometry['evidence'] as List).toList();
        var transparent = false;
        for (final part in parts) {
          final info = inputs.images[part.sourceFileId]!;
          final mask = alpha[part.sourceFileId]!;
          if (mask[(part.sourceRect.y ~/ 32) * (info.width ~/ 32) +
                  part.sourceRect.x ~/ 32] ==
              0) {
            transparent = true;
          }
        }
        evidence.add({
          'type': 'alphaRegion',
          'summary':
              'Alpha occupancy on the confirmed 32 pixel grid; connectivity does not certify an object.',
          'reference': 'snapshot:${source.snapshot.canonicalHash.value}'
        });
        final duplicateTiles = parts
            .map((p) =>
                '${p.sourceFileId}:${p.sourceLayer}:${p.sourceRect.x}:${p.sourceRect.y}')
            .toList();
        final ambiguous =
            duplicateTiles.toSet().length != duplicateTiles.length;
        final uncertainties =
            (geometry['uncertainties'] as List).cast<String>().toList();
        if (ambiguous) {
          uncertainties.add(
              'The connected group is ambiguous: repeated source cells may be separate objects.');
          diagnostics.add(LocalAssetProposalDiagnostic(
              'asset.proposal.ambiguous',
              'Touching placements contain repeated source cells; keep the literal group until human review.',
              mapId: map.sourceMapId));
        }
        if (transparent) {
          uncertainties.add(
              'Fully transparent source cells are retained, including their hidden RGB.');
        }
        final occurrences = <String>[];
        var occurrenceTextLength = 0;
        final first = parts.first;
        for (final other in inputs.maps.values) {
          final otherLayers = inputs.layerCells[other.sourceMapId]!;
          final firstLayer = otherLayers[first.sourceLayer];
          if (firstLayer == null ||
              other.sourceTilesetId != map.sourceTilesetId) {
            continue;
          }
          for (var index = 0; index < firstLayer.length; index++) {
            if (++usageChecks > limits.maxUsageComparisons) {
              _quota('Repeated usage comparison budget exceeded');
            }
            if (firstLayer[index] != first.locator.tileId) continue;
            final ox = index % other.width - first.destinationOffset.x ~/ 32;
            final oy = index ~/ other.width - first.destinationOffset.y ~/ 32;
            var matches = true;
            for (final part in parts) {
              if (++usageChecks > limits.maxUsageComparisons) {
                _quota('Repeated usage comparison budget exceeded');
              }
              final x = ox + part.destinationOffset.x ~/ 32;
              final y = oy + part.destinationOffset.y ~/ 32;
              if (x < 0 ||
                  y < 0 ||
                  x >= other.width ||
                  y >= other.height ||
                  otherLayers[part.sourceLayer]?[y * other.width + x] !=
                      part.locator.tileId) {
                matches = false;
                break;
              }
            }
            if (matches) {
              final occurrence = 'map:${other.sourceMapId};x:$ox;y:$oy';
              occurrenceTextLength +=
                  occurrence.length + (occurrences.isEmpty ? 0 : 1);
              if (occurrences.length >= 256 || occurrenceTextLength > 2048) {
                _quota('Usage evidence budget exceeded');
              }
              occurrences.add(occurrence);
            }
          }
        }
        evidence.add({
          'type':
              occurrences.length > 1 ? 'repeatedPlacement' : 'formatMetadata',
          'summary':
              '${occurrences.length} exact placement occurrence(s); repetition does not certify business identity.',
          'reference': occurrences.join('|')
        });
        geometry['evidence'] = evidence;
        geometry['uncertainties'] = uncertainties;
        candidate =
            AssetCandidate.fromJson(geometry, limits: limits.jsonLimits);
        final existing = candidates[candidate.candidateId];
        if (existing == null) {
          if (candidates.length >= limits.maxCandidates) {
            _quota('Candidate budget exceeded');
          }
          totalParts += cells.length;
          candidates[candidate.candidateId] = candidate;
        }
        await Future<void>.delayed(Duration.zero);
      }
    }
    cancellation?.check();
    final ordered = candidates.values.toList()
      ..sort((a, b) => a.candidateId.value.compareTo(b.candidateId.value));
    diagnostics.sort(
        (a, b) => '${a.mapId}:${a.code}'.compareTo('${b.mapId}:${b.code}'));
    final record = {
      'kind': 'localAssetProposals',
      'version': 1,
      'sourceSnapshotHash': source.snapshot.canonicalHash.value,
      'normalizedSourceHash': source.canonicalHash.value,
      'literalCompositionHash': literal.compositionHash.value,
      'candidates': ordered.map((c) => c.toJson()).toList(),
      'diagnostics': diagnostics.map((d) => d.toJson()).toList()
    };
    return LocalAssetProposalSet._(
        candidates: ordered,
        diagnostics: diagnostics,
        sourceSnapshotHash: source.snapshot.canonicalHash,
        normalizedSourceHash: source.canonicalHash,
        literalCompositionHash: literal.compositionHash,
        canonicalHash: canonicalHashOf(record, limits: limits.jsonLimits));
  }

  AssetCandidate manualFromCells({
    required NormalizedSourceProject source,
    required LiteralTileComposition literal,
    required List<LocalAssetCell> cells,
    AssetOutputMode outputMode = AssetOutputMode.sharedAtlas,
    LocalAssetProposalLimits limits = const LocalAssetProposalLimits(),
  }) =>
      _AssetInputs(source, literal, outputMode, limits)
          .candidate(cells, manual: true);
}

Never _quota(String message) =>
    throw ContractError('asset.proposal.quota', r'$', message);

Iterable<int> _neighbors(int index, int columns, int rows) sync* {
  final x = index % columns;
  final y = index ~/ columns;
  if (x > 0) yield index - 1;
  if (x + 1 < columns) yield index + 1;
  if (y > 0) yield index - columns;
  if (y + 1 < rows) yield index + columns;
}

final class _AssetImage {
  const _AssetImage(this.entry, this.width, this.height);
  final SourceFileEntry entry;
  final int width;
  final int height;
}

final class _AssetInputs {
  _AssetInputs(this.source, this.literal, this.outputMode, this.limits) {
    for (final pair in [
      (limits.maxSourceImages, 32),
      (limits.maxSourceBytes, 67108864),
      (limits.maxPixels, 16777216),
      (limits.maxMapCells, 1048576),
      (limits.maxComponents, 4096),
      (limits.maxCandidates, 1024),
      (limits.maxPartsPerCandidate, 4096),
      (limits.maxTotalParts, 65536),
      (limits.maxUsageComparisons, 16777216),
      (limits.jsonLimits.maxDepth, 64),
      (limits.jsonLimits.maxNodes, 1000000),
      (limits.jsonLimits.maxStringCodeUnits, 1048576),
      (limits.jsonLimits.maxTextCodeUnits, 4194304),
    ]) {
      if (pair.$1 <= 0 || pair.$1 > pair.$2) {
        throw ContractError(
            'asset.proposal.limits', r'$', 'Invalid proposal limits');
      }
    }
    if (outputMode == AssetOutputMode.packedObjects) {
      throw ContractError('asset.proposal.output_mode', r'$',
          'Packed objects are not admitted in this lot');
    }
    if (!source.canPlan ||
        source.snapshot.state != SourceScanState.complete ||
        literal.draft == null ||
        literal.draft!.source.canonicalHash != source.canonicalHash ||
        literal.draft!.source.snapshot.canonicalHash !=
            source.snapshot.canonicalHash) {
      throw ContractError('asset.proposal.binding', r'$',
          'A current complete source and literal composition are required');
    }
    var mapCells = 0;
    for (final ir in source.maps) {
      final map = ir.map;
      if (!literal.mapIds.containsKey(map.sourceMapId)) continue;
      mapCells += map.width * map.height * map.layers.length;
      if (mapCells > limits.maxMapCells) {
        _quota('Source map cell budget exceeded');
      }
      if (map.tileWidth != 32 || map.tileHeight != 32) {
        throw ContractError('asset.proposal.grid', r'$',
            'The admitted source grid must be 32 pixels');
      }
      maps[map.sourceMapId] = map;
    }
    if (maps.length != literal.mapIds.length) {
      throw ContractError('asset.proposal.binding', r'$',
          'Literal map selection differs from normalized source');
    }
    final sortedMaps = maps.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    maps
      ..clear()
      ..addEntries(sortedMaps);
    for (final map in maps.values) {
      layerCells[map.sourceMapId] = {
        for (final layer in map.layers) layer.sourceZ: layer.cells
      };
    }
    var sourceBytes = 0;
    var sourcePixels = 0;
    for (final crop in literal.crops) {
      if (crop.autotileSlot != null) continue;
      final key = (crop.sourceTilesetId, crop.sourceTileId);
      if (crops.containsKey(key)) {
        throw ContractError(
            'asset.proposal.binding', r'$', 'Duplicate source crop');
      }
      crops[key] = crop;
      if (images.containsKey(crop.imageFileId)) continue;
      if (images.length >= limits.maxSourceImages) {
        _quota('Source image count budget exceeded');
      }
      final entries = source.snapshot.entries
          .where((entry) => entry.fileId == crop.imageFileId);
      if (entries.length != 1 ||
          entries.single.sha256 != crop.imageSha256 ||
          entries.single.kind != SourceNodeKind.file ||
          entries.single.format != 'raster') {
        throw ContractError('asset.proposal.binding', r'$',
            'Crop source is not an admitted image');
      }
      final entry = entries.single;
      sourceBytes += entry.byteLength;
      if (sourceBytes > limits.maxSourceBytes) {
        _quota('Source image byte budget exceeded');
      }
      final artifacts = literal.draft!.artifacts
          .where((artifact) => artifact.rawSha256 == crop.imageSha256);
      if (artifacts.length != 1) {
        throw ContractError('asset.proposal.binding', r'$',
            'Original static source artifact is missing');
      }
      final size =
          const NativePngValidator().headerDimensions(artifacts.single.bytes);
      sourcePixels += size.$1 * size.$2;
      if (sourcePixels > limits.maxPixels) {
        _quota('Source image pixel budget exceeded');
      }
      images[crop.imageFileId] = _AssetImage(entry, size.$1, size.$2);
    }
    final sortedImages = images.entries.toList()
      ..sort((a, b) => a.key.value.compareTo(b.key.value));
    images
      ..clear()
      ..addEntries(sortedImages);
  }

  final NormalizedSourceProject source;
  final LiteralTileComposition literal;
  final AssetOutputMode outputMode;
  final LocalAssetProposalLimits limits;
  final maps = <int, SourceMapData>{};
  final layerCells = <int, Map<int, List<int>>>{};
  final crops = <(int, int), LiteralTileCrop>{};
  final images = <ConverterId, _AssetImage>{};

  AssetCandidate alphaCandidate(_AssetImage info, List<int> input) {
    final cells = input.toList()..sort();
    final columns = info.width ~/ 32;
    var minX = columns;
    var minY = info.height ~/ 32;
    var maxX = 0;
    var maxY = 0;
    for (final cell in cells) {
      final x = cell % columns;
      final y = cell ~/ columns;
      if (x < minX) minX = x;
      if (y < minY) minY = y;
      if (x > maxX) maxX = x;
      if (y > maxY) maxY = y;
    }
    final geometry = [
      for (final cell in cells)
        {
          'sourceFileId': info.entry.fileId.value,
          'sourceRect': {
            'x': (cell % columns) * 32,
            'y': (cell ~/ columns) * 32,
            'width': 32,
            'height': 32
          },
          'destinationOffset': {
            'x': (cell % columns - minX) * 32,
            'y': (cell ~/ columns - minY) * 32
          },
          'sourceLayer': null,
          'sourcePriority': null,
          'quarterTurns': 0,
          'reflected': false
        }
    ];
    final candidateId = 'asset_${canonicalHashOf({
          'namespace': source.snapshot.logicalProjectNamespace.value,
          'sourceSnapshotHash': source.snapshot.canonicalHash.value,
          'geometry': geometry
        }).value}';
    return AssetCandidate.fromJson({
      'schemaVersion': '1.0',
      'kind': 'assetCandidate',
      'exampleOnly': false,
      'candidateId': candidateId,
      'revision': 1,
      'logicalProjectNamespace': source.snapshot.logicalProjectNamespace.value,
      'sourceSnapshotHash': source.snapshot.canonicalHash.value,
      'sources': [
        {
          'fileId': info.entry.fileId.value,
          'contentHash': info.entry.sha256!.value,
          'pixelWidth': info.width,
          'pixelHeight': info.height
        }
      ],
      'name': 'Proposition ${candidateId.substring(6, 18)}',
      'category': 'unclassified',
      'state': 'needsReview',
      'parts': [
        for (var i = 0; i < geometry.length; i++)
          {
            ...geometry[i],
            'partId': 'part:$i',
            'locator': {
              'file': info.entry.relativePath,
              'mapId': null,
              'eventId': null,
              'pageIndex': null,
              'commandIndex': null,
              'tileId': null,
              'line': null
            }
          }
      ],
      'canvasSize': {
        'width': (maxX - minX + 1) * 32,
        'height': (maxY - minY + 1) * 32
      },
      'anchor': {
        'unit': 'pixel',
        'x': (maxX - minX + 1) * 16,
        'y': (maxY - minY + 1) * 32,
        'convention': 'bottomCenter'
      },
      'integrationMode': 'libraryOnly',
      'outputMode': outputMode.name,
      'evidence': [
        {
          'type': 'alphaRegion',
          'summary':
              'Connected nonzero-alpha cells on the confirmed grid; no selected map placement was observed.',
          'reference':
              'snapshot:${source.snapshot.canonicalHash.value};file:${info.entry.fileId.value}'
        }
      ],
      'uncertainties': [
        'Category and business identity are unverified.',
        'Alpha connectivity may join unrelated pixels; no placement or collision is inferred.',
        'The bottom-center anchor is a proposal; native placement semantics are not certified.'
      ],
      'approvedRevision': null,
    }, limits: limits.jsonLimits);
  }

  AssetCandidate candidate(List<LocalAssetCell> input, {required bool manual}) {
    if (input.isEmpty ||
        input.length > limits.maxPartsPerCandidate ||
        input.length > limits.maxTotalParts) {
      throw ContractError('asset.proposal.cells', r'$',
          'A bounded nonempty cell selection is required');
    }
    final cells = input.toList()
      ..sort((a, b) {
        var order = a.sourceZ.compareTo(b.sourceZ);
        if (order == 0) order = a.y.compareTo(b.y);
        if (order == 0) order = a.x.compareTo(b.x);
        return order;
      });
    final map = maps[cells.first.mapId];
    if (map == null) {
      throw ContractError(
          'asset.proposal.cells', r'$', 'Unknown selected source map');
    }
    final layers = layerCells[map.sourceMapId]!;
    final unique = <(int, int, int)>{};
    var minX = map.width;
    var minY = map.height;
    var maxX = 0;
    var maxY = 0;
    final resolved = <(LocalAssetCell, LiteralTileCrop)>[];
    for (final cell in cells) {
      if (cell.mapId != map.sourceMapId ||
          cell.x < 0 ||
          cell.y < 0 ||
          cell.x >= map.width ||
          cell.y >= map.height ||
          !layers.containsKey(cell.sourceZ) ||
          !unique.add((cell.sourceZ, cell.x, cell.y))) {
        throw ContractError('asset.proposal.cells', r'$',
            'Cell selection is duplicated or outside its source map');
      }
      final tile = layers[cell.sourceZ]![cell.y * map.width + cell.x];
      final crop = crops[(map.sourceTilesetId, tile)];
      if (crop == null || tile < 384) {
        throw ContractError('asset.proposal.cells', r'$',
            'Cell has no admitted static regular source crop');
      }
      resolved.add((cell, crop));
      if (cell.x < minX) minX = cell.x;
      if (cell.y < minY) minY = cell.y;
      if (cell.x > maxX) maxX = cell.x;
      if (cell.y > maxY) maxY = cell.y;
    }
    if ((maxX - minX + 1) * 32 * (maxY - minY + 1) * 32 > limits.maxPixels) {
      _quota('Candidate canvas pixel budget exceeded');
    }
    final geometry = [
      for (final row in resolved)
        {
          'sourceFileId': row.$2.imageFileId.value,
          'sourceRect': {
            'x': row.$2.x,
            'y': row.$2.y,
            'width': 32,
            'height': 32
          },
          'destinationOffset': {
            'x': (row.$1.x - minX) * 32,
            'y': (row.$1.y - minY) * 32
          },
          'sourceLayer': row.$1.sourceZ,
          'sourcePriority': row.$2.priority,
          'quarterTurns': 0,
          'reflected': false
        },
    ];
    final candidateId = 'asset_${canonicalHashOf({
          'namespace': source.snapshot.logicalProjectNamespace.value,
          'sourceSnapshotHash': source.snapshot.canonicalHash.value,
          'geometry': geometry
        }).value}';
    final sourceIds = resolved.map((row) => row.$2.imageFileId).toSet().toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    final mapEntry = source.snapshot.entries
        .singleWhere((entry) => entry.fileId == map.sourceFileId);
    return AssetCandidate.fromJson({
      'schemaVersion': '1.0',
      'kind': 'assetCandidate',
      'exampleOnly': false,
      'candidateId': candidateId,
      'revision': 1,
      'logicalProjectNamespace': source.snapshot.logicalProjectNamespace.value,
      'sourceSnapshotHash': source.snapshot.canonicalHash.value,
      'sources': [
        for (final id in sourceIds)
          {
            'fileId': id.value,
            'contentHash': images[id]!.entry.sha256!.value,
            'pixelWidth': images[id]!.width,
            'pixelHeight': images[id]!.height
          }
      ],
      'name': 'Proposition ${candidateId.substring(6, 18)}',
      'category': 'unclassified',
      'state': 'needsReview',
      'parts': [
        for (var i = 0; i < geometry.length; i++)
          {
            ...geometry[i],
            'partId': 'part:$i',
            'locator': {
              'file': mapEntry.relativePath,
              'mapId': map.sourceMapId,
              'eventId': null,
              'pageIndex': null,
              'commandIndex': null,
              'tileId': resolved[i].$2.sourceTileId,
              'line': null
            }
          }
      ],
      'canvasSize': {
        'width': (maxX - minX + 1) * 32,
        'height': (maxY - minY + 1) * 32
      },
      'anchor': {
        'unit': 'pixel',
        'x': (maxX - minX + 1) * 16,
        'y': (maxY - minY + 1) * 32,
        'convention': 'bottomCenter'
      },
      'integrationMode': 'libraryOnly',
      'outputMode': outputMode.name,
      'evidence': [
        {
          'type': manual ? 'human' : 'formatMetadata',
          'summary': manual
              ? 'Explicit cell selection is a proposal, not an approval.'
              : 'Connected map usages on the confirmed source grid.',
          'reference': 'map:${map.sourceMapId};x:$minX;y:$minY'
        }
      ],
      'uncertainties': [
        'Category and business identity are unverified.',
        'The bottom-center anchor is a proposal; native placement semantics are not certified.',
        if (resolved.map((r) => r.$2.priority).toSet().length > 1)
          'Mixed source priorities are preserved; a single object cannot certify actor occlusion.'
      ],
      'approvedRevision': null,
    }, limits: limits.jsonLimits);
  }
}
