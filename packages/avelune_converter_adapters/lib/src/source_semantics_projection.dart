import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as image;
import 'package:map_core/map_core.dart';

import 'literal_tile_composer.dart';
import 'native_project_writer.dart';
import 'source_player_character_import.dart';

final class SourceOcclusionLayout {
  factory SourceOcclusionLayout.resolve({
    required int priority,
    required int sourcePlayerDepthOffsetPx,
    required int x,
    required int y,
    required GridSize mapSize,
  }) {
    if (priority < 1 ||
        priority > 5 ||
        (sourcePlayerDepthOffsetPx != 1 && sourcePlayerDepthOffsetPx != 32) ||
        x < 0 ||
        y < 0 ||
        x >= mapSize.width ||
        y >= mapSize.height ||
        mapSize.height < priority + 1) {
      throw const NativeWriteException('semantics.occlusion.geometry',
          'A qualified player depth and an in-bounds complete priority frame are required');
    }
    final shift = (y + priority + 1 - mapSize.height).clamp(0, priority);
    final topPadding = sourcePlayerDepthOffsetPx - 1;
    return SourceOcclusionLayout._(
        priority + 1,
        topPadding,
        priority * 32 - topPadding,
        GridPos(x: x, y: y - shift),
        shift * 32 - topPadding);
  }

  const SourceOcclusionLayout._(this.frameHeightTiles, this.topPaddingPx,
      this.bottomPaddingPx, this.logicalPos, this.atlasOffsetY);
  final int topPaddingPx;
  final int bottomPaddingPx;
  final int frameHeightTiles;
  final GridPos logicalPos;
  final int atlasOffsetY;
  int get visualTopPx => logicalPos.y * 32 + atlasOffsetY;
  int get depthSortYPx => visualTopPx + frameHeightTiles * 32;
}

ElementCollisionPixelMask sourceBoundaryCollisionMask(int mask) {
  if (mask <= 0 || mask & ~10 != 0) {
    throw const NativeWriteException('semantics.collision.mask',
        'Owned boundaries can only occupy the top and left edges');
  }
  final pixels = List<bool>.filled(1024, false);
  if (mask & SourceCardinalDirection.up.bit != 0) {
    for (var x = 0; x < 32; x++) {
      pixels[x] = true;
    }
  }
  if (mask & SourceCardinalDirection.left.bit != 0) {
    for (var y = 0; y < 32; y++) {
      pixels[y * 32] = true;
    }
  }
  return ElementCollisionPixelMask(
      widthPx: 32,
      heightPx: 32,
      dataBase64: ElementCollisionMaskCodec.encodePackedBits(
          widthPx: 32, heightPx: 32, solidPixels: pixels));
}

final class SourceCollisionProjection {
  SourceCollisionProjection._(
      List<bool> blocked,
      Map<int, int> walls,
      List<int> allowed,
      List<SourceTransitionPassage> transitions,
      this.unqualifiedTransitionCount)
      : fullyBlockedCells = List.unmodifiable(blocked),
        wallMasksByCell = Map.unmodifiable(walls),
        allowedTransitions = List.unmodifiable(allowed),
        transitions = List.unmodifiable(transitions);

  factory SourceCollisionProjection.resolve({
    required List<SourceSemanticCell> cells,
    required SourceSemanticResolver resolver,
    required GridSize mapSize,
  }) {
    if (mapSize.width < 1 ||
        mapSize.height < 1 ||
        cells.length != mapSize.width * mapSize.height ||
        cells.indexed.any((entry) =>
            entry.$2.x != entry.$1 % mapSize.width ||
            entry.$2.y != entry.$1 ~/ mapSize.width ||
            entry.$2.width != mapSize.width ||
            entry.$2.height != mapSize.height)) {
      throw const NativeWriteException('semantics.collision.geometry',
          'Source cells must form a complete ordered map grid');
    }
    final transitions = <SourceTransitionPassage>[];
    final allowed = List<int>.filled(cells.length, 0);
    final blocked = List<bool>.filled(cells.length, false);
    var unqualified = 0;
    for (var index = 0; index < cells.length; index++) {
      final from = cells[index];
      var blockedMask = 0;
      for (final direction in SourceCardinalDirection.values) {
        final x = from.x + direction.dx, y = from.y + direction.dy;
        final to = x >= 0 && y >= 0 && x < mapSize.width && y < mapSize.height
            ? cells[y * mapSize.width + x]
            : SourceSemanticCell(
                sourceMapId: from.sourceMapId,
                x: x,
                y: y,
                width: mapSize.width,
                height: mapSize.height,
                stack: const [
                    SourceSemanticTile(sourceZ: 2, tileId: 0),
                    SourceSemanticTile(sourceZ: 1, tileId: 0),
                    SourceSemanticTile(sourceZ: 0, tileId: 0),
                  ]);
        final transition = resolver.resolveTransition(from, to, direction);
        transitions.add(transition);
        if (transition.status == SourcePassageStatus.allowed) {
          allowed[index] |= direction.bit;
        } else if (transition.status == SourcePassageStatus.blocked) {
          blockedMask |= direction.bit;
        } else {
          unqualified++;
        }
      }
      blocked[index] = blockedMask == 15 &&
          resolver.resolveConnectionEntryTile(from).isPassable != true;
    }
    final walls = <int, int>{};
    for (var index = 0; index < cells.length; index++) {
      final cell = cells[index];
      for (final direction in [
        SourceCardinalDirection.right,
        SourceCardinalDirection.down
      ]) {
        final x = cell.x + direction.dx, y = cell.y + direction.dy;
        if (x >= mapSize.width || y >= mapSize.height) continue;
        final neighbor = y * mapSize.width + x;
        if (blocked[index] || blocked[neighbor]) continue;
        if (allowed[index] & direction.bit != 0 &&
            allowed[neighbor] & direction.reverse.bit != 0) {
          continue;
        }
        walls[neighbor] = (walls[neighbor] ?? 0) | direction.reverse.bit;
      }
    }
    return SourceCollisionProjection._(
        blocked, walls, allowed, transitions, unqualified);
  }

  final List<bool> fullyBlockedCells;
  final Map<int, int> wallMasksByCell;
  final List<int> allowedTransitions;
  final List<SourceTransitionPassage> transitions;
  final int unqualifiedTransitionCount;
  bool get qualified => unqualifiedTransitionCount == 0;
}

final class SourceSemanticsProjection {
  SourceSemanticsProjection._(
      {required Map<int, MapData> maps,
      required List<NativeArtifact> artifacts,
      required List<NativeMutation> mutations,
      required Map<String, Object?> evidence,
      required this.staticSemanticsQualified})
      : nativeMaps = Map.unmodifiable(maps),
        artifacts = List.unmodifiable(artifacts),
        mutations = List.unmodifiable(mutations),
        semanticEvidence =
            _freezeProjectionJson(jsonDecode(canonicalJsonOf(evidence)))
                as Map<String, Object?>;

  final Map<int, MapData> nativeMaps;
  final List<NativeArtifact> artifacts;
  final List<NativeMutation> mutations;
  final Map<String, Object?> semanticEvidence;
  final bool staticSemanticsQualified;
  bool get playableCertified => false;
  List<ConverterId> get operationIds =>
      List.unmodifiable(mutations.map((mutation) => mutation.operationId));
}

(GridPos, int)? sourcePreviewSpawn({
  required GridSize mapSize,
  required List<SourceSemanticCell> cells,
  required SourceCollisionProjection collision,
  required SourceSemanticResolver resolver,
  required int playerFrameHeightPx,
  required Set<int> eventCells,
  required Set<int> raisedCells,
}) {
  final seen = <int>{};
  final components = <List<int>>[];
  for (var start = 0; start < cells.length; start++) {
    if (seen.contains(start) || collision.allowedTransitions[start] == 0) {
      continue;
    }
    final component = <int>[];
    final queue = Queue<int>()..add(start);
    seen.add(start);
    while (queue.isNotEmpty) {
      final index = queue.removeFirst();
      component.add(index);
      for (final direction in SourceCardinalDirection.values) {
        if (collision.allowedTransitions[index] & direction.bit == 0) continue;
        final next = index + direction.dx + direction.dy * mapSize.width;
        if (seen.add(next)) queue.add(next);
      }
    }
    components.add(component..sort());
  }
  components.sort((a, b) => a.length != b.length
      ? b.length.compareTo(a.length)
      : a.first.compareTo(b.first));
  for (final component in components) {
    final candidates = component.where((index) {
      if (eventCells.contains(index) || raisedCells.contains(index)) {
        return false;
      }
      final cell = cells[index];
      final ground = cell.stack
          .where((tile) => tile.tileId != 0 && tile.priority == 0)
          .firstOrNull;
      if (ground == null ||
          (ground.terrainTag != 0 && ground.terrainTag != 2) ||
          resolver.resolveCell(cell).unqualifiedMask != 0) {
        return false;
      }
      final aboveRows = (playerFrameHeightPx + 31) ~/ 32;
      for (var row = 0; row < aboveRows; row++) {
        final y = cell.y - row;
        if (y < 0 || raisedCells.contains(y * mapSize.width + cell.x)) {
          return false;
        }
      }
      return true;
    }).toList();
    candidates.sort((a, b) {
      int distance(int index) =>
          (index % mapSize.width * 2 - (mapSize.width - 1)).abs() +
          (index ~/ mapSize.width * 2 - (mapSize.height - 1)).abs();
      final d = distance(a).compareTo(distance(b));
      return d == 0 ? a.compareTo(b) : d;
    });
    if (candidates.isEmpty) continue;
    final index = candidates.first;
    return (
      GridPos(x: index % mapSize.width, y: index ~/ mapSize.width),
      component.length
    );
  }
  return null;
}

final class SourceSemanticsProjector {
  const SourceSemanticsProjector();

  Future<SourceSemanticsProjection> project({
    required NormalizedSourceProject source,
    required LiteralTileComposition base,
    required SourcePlayerCharacterImport player,
    required SourceFilePort files,
    NativeWriteLimits limits = const NativeWriteLimits(),
    ScanCancellation? cancellation,
  }) async {
    limits.validate();
    final draft = base.draft;
    if (draft == null ||
        draft.normalizedSourceHash != source.canonicalHash ||
        player.sourceSnapshotHash != source.snapshot.canonicalHash) {
      throw const NativeWriteException('semantics.source.binding',
          'Projection requires exact admitted literal and player source bindings');
    }
    final resolver = SourceSemanticResolver.forProject(source);
    final run =
        _ProjectionRun(source, base, player, resolver, limits, cancellation);
    await run.project();
    return run.finish();
  }
}

final class _OcclusionDefinition {
  _OcclusionDefinition(this.id, this.crop, this.layout, this.raster,
      this.sourceColumns, this.sourceFrames);
  final String id;
  final LiteralTileCrop crop;
  final SourceOcclusionLayout layout;
  final image.Image raster;
  final int sourceColumns;
  final List<ProjectImageCollectionAnimationFrame> sourceFrames;
  final List<TilesetVisualFrame> frames = [];
}

final class _ProjectionRun {
  _ProjectionRun(this.source, this.base, this.player, this.resolver,
      this.limits, this.cancellation);

  final NormalizedSourceProject source;
  final LiteralTileComposition base;
  final SourcePlayerCharacterImport player;
  final SourceSemanticResolver resolver;
  final NativeWriteLimits limits;
  final ScanCancellation? cancellation;
  final maps = <int, MapData>{};
  final artifacts = <NativeArtifact>[];
  final mutations = <NativeMutation>[];
  final definitions = <String, _OcclusionDefinition>{};
  final elements = <ProjectElementEntry>[];
  final tilesets = <ProjectTilesetEntry>[];
  final gaps = <Map<String, Object?>>[];
  final mapEvidence = <Map<String, Object?>>[];
  final images = <String, image.Image>{};
  final wallPatterns = <int>{};
  var imagePixels = 0;
  var allQualified = true;
  static const categoryId = 'ac12-source-semantics';

  Future<void> project() async {
    final ids = base.nativeMaps.keys.toList()..sort();
    for (final id in ids) {
      cancellation?.check();
      final original =
          source.maps.singleWhere((map) => map.map.sourceMapId == id).map;
      final native = base.nativeMaps[id]!;
      final cells = [
        for (var y = 0; y < original.height; y++)
          for (var x = 0; x < original.width; x++) resolver.cellAt(id, x, y)
      ];
      final collision = SourceCollisionProjection.resolve(
          cells: cells, resolver: resolver, mapSize: native.size);
      allQualified &= collision.qualified;
      if (!collision.qualified) {
        gaps.add({
          'code': 'semantics.passage.unqualified',
          'sourceMapId': id,
          'unqualifiedTransitionCount': collision.unqualifiedTransitionCount,
          'nativePolicy': 'closedBoundaryUntilQualified'
        });
      }
      final layers = native.layers.toList();
      final placed = native.placedElements.toList();
      final collisionLayer = '${native.id}_ac12_collision';
      layers.insert(
          0,
          MapLayer.collision(
              id: collisionLayer,
              name: 'Source passages',
              collisions: collision.fullyBlockedCells));
      final wallLayer = '${native.id}_ac12_boundaries';
      if (collision.wallMasksByCell.isNotEmpty) {
        layers.insert(
            0,
            MapLayer.tile(
                id: wallLayer,
                name: 'Source boundaries',
                cells: List<int>.filled(cells.length, 0)));
        for (final entry in collision.wallMasksByCell.entries) {
          wallPatterns.add(entry.value);
          placed.add(MapPlacedElement(
              id: 'ac12-wall-$id-${entry.key}',
              layerId: wallLayer,
              elementId: 'ac12-wall-${entry.value}',
              pos: GridPos(
                  x: entry.key % original.width,
                  y: entry.key ~/ original.width),
              properties: const {
                pokemapPlacementOriginProperty: pokemapPlacementOriginAuthored
              }));
        }
      }
      final raised = <int>{};
      var reflectiveTileCount = 0;
      for (final layer in original.layers) {
        final provenance = base.layerProvenance.singleWhere((entry) =>
            entry.sourceMapId == id && entry.sourceZ == layer.sourceZ);
        final targetIndex =
            layers.indexWhere((entry) => entry.id == provenance.nativeLayerId);
        final target = layers[targetIndex] as TileLayer;
        final targetCells = target.cells.toList();
        for (var index = 0; index < layer.cells.length; index++) {
          final tile = layer.cells[index];
          if (tile == 0) continue;
          final crop = base.crops.singleWhere((entry) =>
              entry.sourceTilesetId == original.sourceTilesetId &&
              entry.sourceTileId == tile);
          if (crop.terrainTag == 6 || crop.terrainTag == 16) {
            reflectiveTileCount++;
            continue;
          }
          if (crop.priority == 0) continue;
          raised.add(index);
          final x = index % original.width, y = index ~/ original.width;
          SourceOcclusionLayout layout;
          try {
            layout = SourceOcclusionLayout.resolve(
                priority: crop.priority,
                sourcePlayerDepthOffsetPx: player.depthOffsetPx,
                x: x,
                y: y,
                mapSize: native.size);
          } on NativeWriteException catch (error) {
            allQualified = false;
            gaps.add({
              'code': error.code,
              'sourceMapId': id,
              'sourceZ': layer.sourceZ,
              'x': x,
              'y': y,
              'tileId': tile
            });
            continue;
          }
          final key = canonicalHashOf({
            'crop': crop.toJson(),
            'atlasOffsetY': layout.atlasOffsetY,
            'sourcePlayerDepthOffsetPx': player.depthOffsetPx
          }).value.substring(0, 24);
          final definitionId = 'ac12-occ-$key';
          if (!definitions.containsKey(definitionId)) {
            final atlas = _atlas(crop.nativeTilesetId);
            final animation = atlas.$2.tileAnimations
                .where((entry) => entry.tileId == crop.nativeLocalTileId)
                .firstOrNull;
            definitions[definitionId] = _OcclusionDefinition(
                definitionId,
                crop,
                layout,
                atlas.$1,
                atlas.$2.columns,
                animation?.frames ??
                    [
                      ProjectImageCollectionAnimationFrame(
                          tileId: crop.nativeLocalTileId, durationMs: 0)
                    ]);
          }
          targetCells[index] = 0;
          placed.add(MapPlacedElement(
              id: 'ac12-occ-$id-${layer.sourceZ}-$index',
              layerId: target.id,
              elementId: definitionId,
              pos: layout.logicalPos,
              applyCollision: false,
              visualOrder: layer.sourceZ * layer.cells.length + index,
              properties: const {
                pokemapPlacementOriginProperty: pokemapPlacementOriginAuthored
              }));
        }
        layers[targetIndex] = target.copyWith(cells: targetCells);
      }
      if (reflectiveTileCount > 0) {
        allQualified = false;
        gaps.add({
          'code': 'semantics.render.reflections.unqualified',
          'sourceMapId': id,
          'sourceTileCount': reflectiveTileCount,
          'sourceDepthZ': -100,
          'nativePolicy': 'baseBelowActorsReflectionEffectsUnsupported'
        });
      }
      final spawn = sourcePreviewSpawn(
          mapSize: native.size,
          cells: cells,
          collision: collision,
          resolver: resolver,
          playerFrameHeightPx: player.frameHeightPx,
          eventCells: {
            for (final event in original.events)
              event.y * original.width + event.x
          },
          raisedCells: raised);
      var output = native.copyWith(layers: layers, placedElements: placed);
      if (spawn != null) {
        final spawnId = 'ac12-preview-start-$id';
        output = output.copyWith(entities: [
          ...output.entities,
          MapEntity(
              id: spawnId,
              name: 'Conversion preview start',
              kind: MapEntityKind.spawn,
              pos: spawn.$1,
              blocksMovement: false,
              spawn: const MapEntitySpawnData(
                  role: EntitySpawnRole.playerStart,
                  facing: EntityFacing.south))
        ], mapMetadata: output.mapMetadata.copyWith(defaultSpawnId: spawnId));
      } else {
        allQualified = false;
        gaps.add(
            {'code': 'semantics.preview_spawn.unavailable', 'sourceMapId': id});
      }
      maps[id] = output;
      mapEvidence.add({
        'sourceMapId': id,
        'nativeMapId': native.id,
        'sourceMapHash': canonicalHashOf(original.toJson()).value,
        'nativeMapHash': canonicalHashOf(output.toJson()).value,
        'fullyBlockedCellCount':
            collision.fullyBlockedCells.where((cell) => cell).length,
        'boundaryInstanceCount': collision.wallMasksByCell.length,
        'sourceReflectiveTileCount': reflectiveTileCount,
        'allowedTransitionCount': collision.transitions
            .where((entry) => entry.status == SourcePassageStatus.allowed)
            .length,
        'unqualifiedTransitionCount': collision.unqualifiedTransitionCount,
        'transitionsHash': (await _transitionHash(collision.transitions)).value,
        'transitionsHashEncoding': 'canonicalSourceTraceRowsV1',
        'previewSpawn': spawn == null
            ? null
            : {
                'x': spawn.$1.x,
                'y': spawn.$1.y,
                'componentSize': spawn.$2,
                'sourceGameStart': false,
                'policy': 'largestKnownComponentWithSafeGroundNearestMapCenter'
              },
        'sourceEventCount': original.events.length,
        'sourceEventsImported': 0,
        'sourceEventsScope': 'AC13Deferred'
      });
      await Future<void>.delayed(Duration.zero);
    }
    _packOcclusion();
    _buildWalls();
    if (elements.isNotEmpty) {
      final category = const ProjectElementCategory(
          id: categoryId, name: 'Source semantics');
      mutations.add(_mutation('ac12-category', 'element_category.upsert',
          [ConverterId(categoryId)], {'category': category.toJson()}));
    }
    elements.sort((a, b) => a.id.compareTo(b.id));
    for (final element in elements) {
      mutations.add(_mutation('ac12-element-${element.id}', 'element.upsert',
          [ConverterId(element.id)], {'element': element.toJson()}));
    }
    for (final id in maps.keys.toList()..sort()) {
      final map = maps[id]!;
      mutations.add(_mutation('ac12-save-${map.id}', 'map.save',
          [ConverterId(map.id)], {'map': map.toJson()},
          sourceIds: [source.mapIdentity(id)]));
    }
    if (mutations.length + base.draft!.mutations.length > limits.maxMutations ||
        artifacts.length +
                base.draft!.artifacts.length +
                base.draft!.sourceArtifacts.length >
            limits.maxArtifacts) {
      throw const NativeWriteException('semantics.quota.draft',
          'Projection exceeds the aggregate native draft entry budget');
    }
  }

  (image.Image, ProjectRegularAtlasTilesetSource) _atlas(String id) {
    final draft = base.draft!;
    final imported = draft.mutations.singleWhere((mutation) =>
        mutation.actionId == 'tileset.import_image' &&
        mutation.parameters['tilesetId'] == id);
    final artifact = draft.artifacts.singleWhere(
        (artifact) => artifact.handle == imported.parameters['artifactHandle']);
    final raster = images.putIfAbsent(id, () {
      final size =
          const NativePngValidator().validate(artifact.bytes, limits: limits);
      imagePixels += size.$1 * size.$2;
      if (imagePixels > limits.maxImagePixels) {
        throw const NativeWriteException('semantics.quota.pixels',
            'Projection image pixels exceed their budget');
      }
      final decoded = image.decodePng(Uint8List.fromList(artifact.bytes));
      if (decoded == null) {
        throw const NativeWriteException(
            'semantics.image.decode', 'Admitted atlas cannot be decoded');
      }
      return decoded;
    });
    final upsert = draft.mutations
        .where((mutation) =>
            mutation.actionId == 'tileset.upsert' &&
            (mutation.parameters['tileset'] as Map)['id'] == id)
        .firstOrNull;
    final atlas = upsert == null
        ? ProjectRegularAtlasTilesetSource(
            assetId: 'image_$id',
            pixelWidth: raster.width,
            pixelHeight: raster.height,
            tileWidth: 32,
            tileHeight: 32)
        : ProjectTilesetEntry.fromJson(
                Map<String, dynamic>.from(upsert.parameters['tileset'] as Map))
            .source as ProjectRegularAtlasTilesetSource;
    return (raster, atlas);
  }

  void _packOcclusion() {
    final groups = <int, List<_OcclusionDefinition>>{};
    for (final definition in definitions.values) {
      groups
          .putIfAbsent(definition.layout.atlasOffsetY, () => [])
          .add(definition);
    }
    for (final offset in groups.keys.toList()..sort()) {
      cancellation?.check();
      final group = groups[offset]!..sort((a, b) => a.id.compareTo(b.id));
      final height = group.fold<int>(
          0,
          (sum, definition) =>
              sum +
              definition.layout.frameHeightTiles *
                  32 *
                  ((definition.sourceFrames.length + 7) ~/ 8));
      imagePixels += 256 * height;
      if (imagePixels > limits.maxImagePixels) {
        throw const NativeWriteException('semantics.quota.pixels',
            'Padded occlusion atlas exceeds its pixel budget');
      }
      final format = group.any(
              (definition) => definition.raster.format == image.Format.uint16)
          ? image.Format.uint16
          : image.Format.uint8;
      final raster = image.Image(
          width: 256, height: height, numChannels: 4, format: format);
      final id = 'ac12-occlusion-${offset < 0 ? 'n${-offset}' : 'p$offset'}';
      var cursorY = 0;
      for (final definition in group) {
        final maskPixels = List<bool>.filled(
            32 * definition.layout.frameHeightTiles * 32, false);
        for (var y = 0; y < 32; y++) {
          for (var x = 0; x < 32; x++) {
            maskPixels[(y + definition.layout.topPaddingPx) * 32 + x] = true;
          }
        }
        for (var frameIndex = 0;
            frameIndex < definition.sourceFrames.length;
            frameIndex++) {
          final frame = definition.sourceFrames[frameIndex];
          final x = frameIndex % 8 * 32;
          final y = cursorY +
              frameIndex ~/ 8 * definition.layout.frameHeightTiles * 32;
          final sourceX = frame.tileId % definition.sourceColumns * 32;
          final sourceY = frame.tileId ~/ definition.sourceColumns * 32;
          if (sourceX + 32 > definition.raster.width ||
              sourceY + 32 > definition.raster.height) {
            throw const NativeWriteException('semantics.crop.bounds',
                'Occlusion source crop exceeds its admitted atlas');
          }
          for (var py = 0; py < 32; py++) {
            for (var px = 0; px < 32; px++) {
              final pixel =
                  definition.raster.getPixel(sourceX + px, sourceY + py);
              final scale = format == image.Format.uint16 &&
                      definition.raster.format != image.Format.uint16
                  ? 257
                  : 1;
              raster.setPixelRgba(
                  x + px,
                  y + definition.layout.topPaddingPx + py,
                  pixel.r * scale,
                  pixel.g * scale,
                  pixel.b * scale,
                  pixel.a * scale);
            }
          }
          definition.frames.add(TilesetVisualFrame(
              tilesetId: id,
              source: TilesetSourceRect(
                  x: x ~/ 32,
                  y: y ~/ 32,
                  width: 1,
                  height: definition.layout.frameHeightTiles),
              durationMs: frame.durationMs == 0 ? null : frame.durationMs));
        }
        cursorY += definition.layout.frameHeightTiles *
            32 *
            ((definition.sourceFrames.length + 7) ~/ 8);
        elements.add(ProjectElementEntry(
            id: definition.id,
            name: 'Source tile ${definition.crop.sourceTileId}',
            categoryId: categoryId,
            tilesetId: id,
            frames: definition.frames,
            collisionProfile: ElementCollisionProfile(
                source: ElementCollisionProfileSource.manual,
                occlusionMask: ElementCollisionPixelMask(
                    widthPx: 32,
                    heightPx: definition.layout.frameHeightTiles * 32,
                    dataBase64: ElementCollisionMaskCodec.encodePackedBits(
                        widthPx: 32,
                        heightPx: definition.layout.frameHeightTiles * 32,
                        solidPixels: maskPixels)))));
      }
      _importAtlas(id, 'Source depth $offset', raster, offset);
    }
  }

  void _buildWalls() {
    if (wallPatterns.isEmpty) return;
    _importAtlas('ac12-boundaries', 'Source boundary collision',
        image.Image(width: 32, height: 32, numChannels: 4), 0);
    for (final mask in wallPatterns.toList()..sort()) {
      elements.add(ProjectElementEntry(
          id: 'ac12-wall-$mask',
          name: 'Source boundary $mask',
          categoryId: categoryId,
          tilesetId: 'ac12-boundaries',
          frames: const [
            TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0))
          ],
          collisionProfile: ElementCollisionProfile(
              source: ElementCollisionProfileSource.manual,
              collisionMask: sourceBoundaryCollisionMask(mask))));
    }
  }

  void _importAtlas(String id, String name, image.Image raster, int offset) {
    final artifact = NativeArtifact(
        bytes: image.encodePng(raster, level: 6), limits: limits);
    if (!artifacts.any((entry) => entry.handle == artifact.handle)) {
      artifacts.add(artifact);
    }
    final tileset = ProjectTilesetEntry(
        id: id,
        name: name,
        relativePath: 'assets/studio/$id.png',
        source: ProjectRegularAtlasTilesetSource(
            assetId: 'image_$id',
            pixelWidth: raster.width,
            pixelHeight: raster.height,
            tileWidth: 32,
            tileHeight: 32,
            pixelOffsetY: offset));
    tilesets.add(tileset);
    mutations.add(_mutation('ac12-import-$id', 'tileset.import_image', [
      ConverterId(id),
      ConverterId('image_$id')
    ], {
      'artifactHandle': artifact.handle,
      'tilesetId': id,
      'name': name,
      'tileWidth': 32,
      'tileHeight': 32
    }));
    if (offset != 0) {
      mutations.add(_mutation('ac12-atlas-$id', 'tileset.upsert',
          [ConverterId(id)], {'tileset': tileset.toJson()}));
    }
  }

  NativeMutation _mutation(String operation, String action,
          List<ConverterId> targets, Map<String, Object?> parameters,
          {List<ConverterId>? sourceIds}) =>
      NativeMutation(
          operationId: ConverterId(operation),
          actionId: action,
          sourceEntityIds: sourceIds ??
              [
                SourceIdentity(source.snapshot.logicalProjectNamespace,
                        ConverterId('source-semantics'), 1)
                    .stableId
              ],
          targetEntityIds: targets,
          parameters: parameters,
          limits: limits);

  Future<Sha256Hash> _transitionHash(
      List<SourceTransitionPassage> transitions) async {
    List<Object?> trace(SourceTilePassageTrace entry) => [
          entry.tile.sourceZ,
          entry.tile.tileId,
          entry.tile.passage,
          entry.tile.priority,
          entry.tile.terrainTag,
          entry.reason.name,
        ];
    final rows = transitions.map((entry) => utf8.encode('${canonicalJsonOf([
              entry.from.x,
              entry.from.y,
              entry.exit.direction.sourceValue,
              entry.status.name,
              entry.reason.name,
              entry.exit.status.name,
              entry.exit.reason.name,
              entry.exit.trace.map(trace).toList(),
              entry.entry.status.name,
              entry.entry.reason.name,
              entry.entry.trace.map(trace).toList(),
            ], limits: limits.jsonLimits)}\n'));
    final digest =
        await sha256.bind(Stream<List<int>>.fromIterable(rows)).first;
    return Sha256Hash(digest.toString());
  }

  SourceSemanticsProjection finish() {
    final evidence = <String, Object?>{
      'kind': 'sourceSemanticsProjection',
      'version': 1,
      'sourceSnapshotHash': source.snapshot.canonicalHash.value,
      'normalizedSourceHash': source.canonicalHash.value,
      'literalCompositionHash': base.compositionHash.value,
      'profile': resolver.profile.toJson(),
      'player': player.evidence,
      'context': const SourceSemanticContext().toJson(),
      'qualified': allQualified && resolver.profile.isQualified,
      'playableCertified': false,
      'nativeCollisionPolicy': 'symmetricCardinalGraphPixelBoundaries',
      'collisionContactPolicy': 'native12x8PixelsSweptEveryPixel',
      'sourceGridPixelContactParity': false,
      'nativeDepthPolicy': 'sourceTileZMinusFixedSourcePlayerDepthBonus',
      'sourceScriptsExecuted': 0,
      'aiCalls': 0,
      'sourceEventsScope': 'AC13Deferred',
      'unsupportedContexts': [
        'npc',
        'follower',
        'cycling',
        'surf',
        'jump',
        'dynamicBridge',
        'dynamicCharset',
        'diagonalSourceMovement'
      ],
      'maps': mapEvidence,
      'gaps': gaps,
      'operationIds':
          mutations.map((mutation) => mutation.operationId.value).toList(),
      'artifacts': artifacts
          .map((artifact) => {
                'handle': artifact.handle,
                'rawSha256': artifact.rawSha256.value
              })
          .toList()
    };
    canonicalJsonOf(evidence, limits: limits.jsonLimits);
    return SourceSemanticsProjection._(
        maps: maps,
        artifacts: artifacts,
        mutations: mutations,
        evidence: evidence,
        staticSemanticsQualified: allQualified && resolver.profile.isQualified);
  }
}

Object? _freezeProjectionJson(Object? value) => switch (value) {
      Map<String, Object?> map => Map<String, Object?>.unmodifiable(
          map.map((key, value) => MapEntry(key, _freezeProjectionJson(value)))),
      List list => List<Object?>.unmodifiable(list.map(_freezeProjectionJson)),
      _ => value,
    };
