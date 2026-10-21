import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as image;
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';

import '../../contracts/artifact_ref.dart';
import '../assets/asset_store.dart';
import 'game_package_export_profile.dart';

final class RuntimeRegularAtlasProjection {
  const RuntimeRegularAtlasProjection(this.project, this.assets, this.files);

  final ProjectManifest project;
  final AssetCatalog assets;
  final Map<String, List<int>> files;
}

Future<RuntimeRegularAtlasProjection> projectRuntimeRegularAtlases({
  required ProjectManifest project,
  required AssetCatalog assets,
  required Future<List<int>> Function(String path) readFile,
}) async {
  const limit = GamePackageSecurityPolicy.maxImageDimensionV1;
  final oversized = {
    for (final entry in project.tilesets)
      if (entry.source case ProjectRegularAtlasTilesetSource source)
        if (source.pixelWidth > limit || source.pixelHeight > limit)
          entry.id: source,
  };
  if (oversized.isEmpty) {
    return RuntimeRegularAtlasProjection(project, assets, const {});
  }
  final entries = {
    for (final entry in project.tilesets)
      if (oversized.containsKey(entry.id)) entry.id: entry,
  };
  final imageReferences = {
    for (final entry in entries.values) entry.relativePath,
    for (final source in oversized.values) source.assetId,
  };
  final otherDefinitions = project.toJson()
    ..remove('tilesets')
    ..remove('elements');
  _rejectReferences(otherDefinitions, {...imageReferences, ...oversized.keys});
  for (final entry in project.maps) {
    final document =
        jsonDecode(utf8.decode(await readFile(entry.relativePath)));
    _rejectReferences(document, imageReferences);
    _checkMapTilesetReferences(document, oversized.keys.toSet());
  }
  final columnsById = <String, int>{};
  final files = <String, List<int>>{};
  final sources = <String, ProjectRegularAtlasTilesetSource>{};
  final cache = <String, List<int>>{};
  for (final entry in entries.values) {
    final source = oversized[entry.id]!;
    final record = assets.findByLogicalPath(entry.relativePath);
    if (record == null ||
        record.id != source.assetId ||
        source.tileWidth <= 0 ||
        source.tileHeight <= 0 ||
        source.tileWidth > limit ||
        source.tileHeight > limit ||
        source.marginX != 0 ||
        source.marginY != 0 ||
        source.spacingX != 0 ||
        source.spacingY != 0 ||
        source.pixelWidth % source.tileWidth != 0 ||
        source.pixelHeight % source.tileHeight != 0 ||
        source.pixelWidth * source.pixelHeight >
            GamePackageSecurityPolicy.maxImagePixelsV1 ||
        entry.paletteEntries.isNotEmpty) {
      _unsupported(entry.relativePath);
    }
    final count = source.columns * source.rows;
    final minimumColumns = (count / (limit ~/ source.tileHeight)).ceil();
    final columns = math.min(
        limit ~/ source.tileWidth, math.max(source.columns, minimumColumns));
    final rows = (count / columns).ceil();
    if (rows * source.tileHeight > limit) _unsupported(entry.relativePath);
    columnsById[entry.id] = columns;
    sources[entry.id] = ProjectRegularAtlasTilesetSource(
      assetId: source.assetId,
      pixelWidth: columns * source.tileWidth,
      pixelHeight: rows * source.tileHeight,
      tileWidth: source.tileWidth,
      tileHeight: source.tileHeight,
      pixelOffsetX: source.pixelOffsetX,
      pixelOffsetY: source.pixelOffsetY,
      tileProperties: source.tileProperties,
      tileAnimations: source.tileAnimations,
    );
    final key =
        '${record.artifact.digest}:${source.tileWidth}:${source.tileHeight}:$columns';
    final bytes = cache[key] ??
        await (() async {
          final original = image.decodePng(
              Uint8List.fromList(await readFile(entry.relativePath)));
          if (original == null ||
              original.width != source.pixelWidth ||
              original.height != source.pixelHeight ||
              original.format != image.Format.uint8) {
            _unsupported(entry.relativePath);
          }
          final packed = image.Image(
              width: columns * source.tileWidth,
              height: rows * source.tileHeight,
              numChannels: 4);
          for (var tile = 0; tile < count; tile++) {
            image.compositeImage(packed, original,
                dstX: tile % columns * source.tileWidth,
                dstY: tile ~/ columns * source.tileHeight,
                dstW: source.tileWidth,
                dstH: source.tileHeight,
                srcX: tile % source.columns * source.tileWidth,
                srcY: tile ~/ source.columns * source.tileHeight,
                srcW: source.tileWidth,
                srcH: source.tileHeight,
                blend: image.BlendMode.direct);
          }
          return image.encodePng(packed);
        })();
    cache[key] = bytes;
    final prior = files[entry.relativePath];
    if (prior != null && !identical(prior, bytes)) {
      _unsupported(entry.relativePath);
    }
    files[entry.relativePath] = bytes;
  }
  final elements = [
    for (final element in project.elements)
      element.copyWith(frames: [
        for (final frame in element.frames)
          if (oversized[
                  frame.tilesetId.isEmpty ? element.tilesetId : frame.tilesetId]
              case final source?)
            _repackFrame(
                frame,
                source,
                columnsById[frame.tilesetId.isEmpty
                    ? element.tilesetId
                    : frame.tilesetId]!)
          else
            frame,
      ]),
  ];
  return RuntimeRegularAtlasProjection(
    project.copyWith(tilesets: [
      for (final entry in project.tilesets)
        if (sources[entry.id] case final source?)
          entry.copyWith(source: source)
        else
          entry,
    ], elements: elements),
    AssetCatalog(records: [
      for (final record in assets.records)
        if (files[record.logicalPath] case final bytes?)
          record.copyWith(
              artifact:
                  ContentArtifactRef.fromBytes(bytes, mediaType: 'image/png'))
        else
          record,
    ]),
    files,
  );
}

TilesetVisualFrame _repackFrame(TilesetVisualFrame frame,
    ProjectRegularAtlasTilesetSource source, int columns) {
  final rect = frame.source;
  if (rect.width != 1 ||
      rect.height != 1 ||
      rect.x < 0 ||
      rect.y < 0 ||
      rect.x >= source.columns ||
      rect.y >= source.rows) {
    _unsupported('elements.frames');
  }
  final tile = rect.y * source.columns + rect.x;
  return frame.copyWith(
      source: rect.copyWith(x: tile % columns, y: tile ~/ columns));
}

void _rejectReferences(Object? value, Set<String> references) {
  if (value is String && references.contains(value)) _unsupported(value);
  if (value is Map) {
    for (final child in value.values) {
      _rejectReferences(child, references);
    }
  } else if (value is List) {
    for (final child in value) {
      _rejectReferences(child, references);
    }
  }
}

void _checkMapTilesetReferences(Object? value, Set<String> ids) {
  if (value is Map) {
    for (final entry in value.entries) {
      if (entry.value is String &&
          ids.contains(entry.value) &&
          (entry.key != 'tilesetId' || value['localTileId'] is! int)) {
        _unsupported('maps.${entry.key}');
      }
      _checkMapTilesetReferences(entry.value, ids);
    }
  } else if (value is List) {
    for (final child in value) {
      _checkMapTilesetReferences(child, ids);
    }
  }
}

Never _unsupported(String path) => throw GamePackageExportException(
    code: 'runtimeAtlasRepackUnsupported',
    path: path,
    message:
        'The oversized atlas cannot be repacked without changing its consumers.');
