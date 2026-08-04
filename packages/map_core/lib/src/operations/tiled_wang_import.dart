import 'dart:math' as math;

import 'package:meta/meta.dart' show immutable;
import 'package:xml/xml.dart';

import '../models/smart_tile.dart';

enum TiledWangSetType { corner, edge, mixed }

enum TiledPropertyValueType {
  string,
  integer,
  decimal,
  boolean,
  color,
  file,
  object,
  structured,
}

enum TiledCollisionShape { rectangle, ellipse, polygon, polyline, point }

@immutable
final class TiledTilesetImportException implements Exception {
  const TiledTilesetImportException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'TiledTilesetImportException($code): $message';
}

@Deprecated('Use TiledTilesetImportException for the generalized TSX parser.')
typedef TiledWangImportException = TiledTilesetImportException;

@immutable
final class TiledAnimationFrame {
  const TiledAnimationFrame({required this.tileId, required this.durationMs});

  final int tileId;
  final int durationMs;
}

@immutable
final class TiledProperty {
  TiledProperty({
    required this.name,
    required this.type,
    this.value,
    this.customType,
    Iterable<TiledProperty> members = const <TiledProperty>[],
  }) : members = List<TiledProperty>.unmodifiable(members);

  final String name;
  final TiledPropertyValueType type;
  final Object? value;
  final String? customType;
  final List<TiledProperty> members;
}

@immutable
final class TiledPoint {
  const TiledPoint({required this.x, required this.y});

  final double x;
  final double y;
}

@immutable
final class TiledCollisionObject {
  TiledCollisionObject({
    required this.id,
    required this.name,
    required this.className,
    required this.shape,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.rotation,
    required Iterable<TiledPoint> points,
    required Iterable<TiledProperty> properties,
  })  : points = List<TiledPoint>.unmodifiable(points),
        properties = List<TiledProperty>.unmodifiable(properties);

  final int id;
  final String name;
  final String className;
  final TiledCollisionShape shape;
  final double x;
  final double y;
  final double width;
  final double height;
  final double rotation;
  final List<TiledPoint> points;
  final List<TiledProperty> properties;
}

@immutable
final class TiledTileMetadata {
  TiledTileMetadata({
    required this.tileId,
    required this.probability,
    this.image,
    Iterable<TiledAnimationFrame> animation = const <TiledAnimationFrame>[],
    Iterable<TiledProperty> properties = const <TiledProperty>[],
    Iterable<TiledCollisionObject> collisionObjects =
        const <TiledCollisionObject>[],
  })  : animation = List<TiledAnimationFrame>.unmodifiable(animation),
        properties = List<TiledProperty>.unmodifiable(properties),
        collisionObjects =
            List<TiledCollisionObject>.unmodifiable(collisionObjects);

  final int tileId;
  final double probability;
  final TiledTilesetImageReference? image;
  final List<TiledAnimationFrame> animation;
  final List<TiledProperty> properties;
  final List<TiledCollisionObject> collisionObjects;
}

@immutable
final class TiledWangColor {
  const TiledWangColor({
    required this.name,
    required this.colorArgb,
    required this.representativeTileId,
  });

  final String name;
  final int colorArgb;
  final int? representativeTileId;
}

@immutable
final class TiledWangTile {
  TiledWangTile({required this.tileId, required Iterable<int> wangIds})
      : wangIds = List<int>.unmodifiable(wangIds);

  final int tileId;
  final List<int> wangIds;
}

@immutable
final class TiledWangSet {
  TiledWangSet({
    required this.name,
    required this.type,
    required Iterable<TiledWangColor> colors,
    required Iterable<TiledWangTile> tiles,
  })  : colors = List<TiledWangColor>.unmodifiable(colors),
        tiles = List<TiledWangTile>.unmodifiable(tiles);

  final String name;
  final TiledWangSetType type;
  final List<TiledWangColor> colors;
  final List<TiledWangTile> tiles;
}

@immutable
final class TiledTilesetImageReference {
  const TiledTilesetImageReference({
    required this.source,
    required this.pixelWidth,
    required this.pixelHeight,
  });

  final String source;
  final int pixelWidth;
  final int pixelHeight;
}

/// One unique external image required by a parsed TSX document.
///
/// [tileIds] is empty for a regular atlas and contains every sparse local tile
/// identity that refers to the image for a collection. Repeated references to
/// the same normalized source are represented once.
@immutable
final class TiledTilesetImageDependency {
  TiledTilesetImageDependency({
    required this.source,
    required this.pixelWidth,
    required this.pixelHeight,
    Iterable<int> tileIds = const <int>[],
  }) : tileIds = List<int>.unmodifiable(tileIds);

  final String source;
  final int pixelWidth;
  final int pixelHeight;
  final List<int> tileIds;
}

@immutable
final class TiledTilesetDependencyClosure {
  TiledTilesetDependencyClosure({
    required Iterable<TiledTilesetImageDependency> images,
  }) : images = List<TiledTilesetImageDependency>.unmodifiable(images);

  final List<TiledTilesetImageDependency> images;
}

sealed class TiledTilesetLayout {
  const TiledTilesetLayout();
}

@immutable
final class TiledRegularAtlasLayout extends TiledTilesetLayout {
  const TiledRegularAtlasLayout({
    required this.image,
    required this.columns,
    required this.rows,
    required this.margin,
    required this.spacing,
  });

  final TiledTilesetImageReference image;
  final int columns;
  final int rows;
  final int margin;
  final int spacing;
}

@immutable
final class TiledImageCollectionLayout extends TiledTilesetLayout {
  TiledImageCollectionLayout({required Iterable<int> tileIds})
      : tileIds = List<int>.unmodifiable(tileIds);

  final List<int> tileIds;
}

/// Pure, format-boundary representation of one TSX tileset.
///
/// Parsing this document performs no filesystem or image-decoding I/O. The
/// complete normalized dependency closure is exposed for the authoring layer
/// to stage, decode, validate and pack atomically.
@immutable
final class TiledTilesetDocument {
  TiledTilesetDocument({
    required this.name,
    required this.tileWidth,
    required this.tileHeight,
    required this.tileCount,
    required this.tileOffsetX,
    required this.tileOffsetY,
    required this.layout,
    required this.dependencyClosure,
    required Iterable<TiledProperty> properties,
    required Map<int, TiledTileMetadata> tiles,
    required Iterable<TiledWangSet> wangSets,
  })  : properties = List<TiledProperty>.unmodifiable(properties),
        tiles = Map<int, TiledTileMetadata>.unmodifiable(tiles),
        wangSets = List<TiledWangSet>.unmodifiable(wangSets);

  final String name;
  final int tileWidth;
  final int tileHeight;
  final int tileCount;
  final int tileOffsetX;
  final int tileOffsetY;
  final TiledTilesetLayout layout;
  final TiledTilesetDependencyClosure dependencyClosure;
  final List<TiledProperty> properties;
  final Map<int, TiledTileMetadata> tiles;
  final List<TiledWangSet> wangSets;
}

/// Neutral representation of the portable subset of a Tiled TSX tileset.
///
/// PokeMap does not retain or execute this format. The document only feeds the
/// native Smart Tile compiler during an explicit import.
@immutable
final class TiledWangTilesetDocument {
  TiledWangTilesetDocument({
    required this.name,
    required this.imageSource,
    required this.imageWidth,
    required this.imageHeight,
    required this.tileWidth,
    required this.tileHeight,
    required this.tileCount,
    required this.columns,
    required this.rows,
    required this.margin,
    required this.spacing,
    required this.tileOffsetX,
    required this.tileOffsetY,
    required Map<int, TiledTileMetadata> tiles,
    required Iterable<TiledWangSet> wangSets,
  })  : tiles = Map<int, TiledTileMetadata>.unmodifiable(tiles),
        wangSets = List<TiledWangSet>.unmodifiable(wangSets);

  final String name;
  final String imageSource;
  final int imageWidth;
  final int imageHeight;
  final int tileWidth;
  final int tileHeight;
  final int tileCount;
  final int columns;
  final int rows;
  final int margin;
  final int spacing;
  final int tileOffsetX;
  final int tileOffsetY;
  final Map<int, TiledTileMetadata> tiles;
  final List<TiledWangSet> wangSets;
}

@immutable
final class TiledWangSetSelection {
  const TiledWangSetSelection({
    required this.wangSetIndex,
    required this.usage,
  });

  final int wangSetIndex;
  final SmartTileUsage usage;
}

@immutable
final class TiledWangImportBundle {
  TiledWangImportBundle({
    required this.atlas,
    required Iterable<ProjectSmartTileMaterial> materials,
    required Iterable<ProjectSmartTileAnimation> animations,
    required Iterable<ProjectSmartTilePreset> presets,
  })  : materials = List<ProjectSmartTileMaterial>.unmodifiable(materials),
        animations = List<ProjectSmartTileAnimation>.unmodifiable(animations),
        presets = List<ProjectSmartTilePreset>.unmodifiable(presets);

  final ProjectSmartTileAtlas atlas;
  final List<ProjectSmartTileMaterial> materials;
  final List<ProjectSmartTileAnimation> animations;
  final List<ProjectSmartTilePreset> presets;

  Map<String, Object?> toJson() => <String, Object?>{
        'atlas': atlas.toJson(),
        'materials': materials.map((item) => item.toJson()).toList(),
        'animations': animations.map((item) => item.toJson()).toList(),
        'presets': presets.map((item) => item.toJson()).toList(),
      };
}

TiledTilesetDocument parseTiledTileset(String source) {
  final XmlDocument xml;
  try {
    xml = XmlDocument.parse(source.trim());
  } on XmlParserException catch (error) {
    throw TiledWangImportException(
      'smart_tile.tiled.xml_invalid',
      'Le fichier TSX est invalide : ${error.message}',
    );
  }
  final root = xml.rootElement;
  if (root.name.local != 'tileset') {
    throw const TiledWangImportException(
      'smart_tile.tiled.root_invalid',
      'Le document doit contenir un tileset TSX à sa racine.',
    );
  }

  final name = _canonicalName(root.getAttribute('name'), 'Tileset Tiled');
  final tileWidth = _positiveIntAttribute(root, 'tilewidth');
  final tileHeight = _positiveIntAttribute(root, 'tileheight');
  final tileCount = _positiveIntAttribute(root, 'tilecount');
  final columns = _nonNegativeIntAttribute(root, 'columns', fallback: 0);
  final isImageCollection = columns == 0;
  final margin = _nonNegativeIntAttribute(root, 'margin', fallback: 0);
  final spacing = _nonNegativeIntAttribute(root, 'spacing', fallback: 0);
  final rootImages = root.findElements('image').toList(growable: false);
  if (!isImageCollection && rootImages.length != 1) {
    throw const TiledWangImportException(
      'smart_tile.tiled.source_image_required',
      'Le TSX doit référencer exactement une image atlas.',
    );
  }
  if (isImageCollection && rootImages.isNotEmpty) {
    throw const TiledWangImportException(
      'smart_tile.tiled.layout_mixed',
      'Un TSX ne peut pas mélanger image atlas et collection d’images.',
    );
  }
  final atlasImage = isImageCollection
      ? null
      : _parseTilesetImage(rootImages.single, context: 'atlas');
  final tileOffsets = root.findElements('tileoffset').toList(growable: false);
  if (tileOffsets.length > 1) {
    throw const TiledWangImportException(
      'smart_tile.tiled.tile_offset_duplicate',
      'Le TSX contient plusieurs offsets de dessin concurrents.',
    );
  }
  final tileOffsetX =
      tileOffsets.isEmpty ? 0 : _requiredIntAttribute(tileOffsets.single, 'x');
  final tileOffsetY =
      tileOffsets.isEmpty ? 0 : _requiredIntAttribute(tileOffsets.single, 'y');
  final properties = _parseTiledProperties(root, context: 'tileset');

  final tileMetadata = <int, TiledTileMetadata>{};
  for (final tile in root.findElements('tile')) {
    final tileId = _tileId(
      tile,
      tileCount: tileCount,
      sparse: isImageCollection,
    );
    if (tileMetadata.containsKey(tileId)) {
      throw TiledWangImportException(
        'smart_tile.tiled.tile_duplicate',
        'La tuile locale $tileId est déclarée plusieurs fois.',
      );
    }
    final tileImages = tile.findElements('image').toList(growable: false);
    final TiledTilesetImageReference? tileImage;
    if (isImageCollection) {
      if (tileImages.isEmpty) {
        throw TiledWangImportException(
          'smart_tile.tiled.tile_image_required',
          'La tuile locale $tileId ne référence aucune image.',
        );
      }
      if (tileImages.length > 1) {
        throw TiledWangImportException(
          'smart_tile.tiled.tile_image_duplicate',
          'La tuile locale $tileId référence plusieurs images concurrentes.',
        );
      }
      tileImage = _parseTilesetImage(
        tileImages.single,
        context: 'tuile $tileId',
      );
    } else {
      if (tileImages.isNotEmpty) {
        throw TiledWangImportException(
          'smart_tile.tiled.layout_mixed',
          'La tuile locale $tileId ajoute une image à un atlas régulier.',
        );
      }
      tileImage = null;
    }
    final probability = _probability(tile.getAttribute('probability'));
    final animation = <TiledAnimationFrame>[];
    final animationElements = tile.findElements('animation').toList();
    if (animationElements.length > 1) {
      throw TiledWangImportException(
        'smart_tile.tiled.animation_invalid',
        'La tuile $tileId possède plusieurs blocs d’animation.',
      );
    }
    if (animationElements.isNotEmpty) {
      for (final frame in animationElements.single.findElements('frame')) {
        final frameTileId = _requiredIntAttribute(frame, 'tileid');
        final durationMs = _positiveIntAttribute(frame, 'duration');
        if (frameTileId < 0 ||
            (!isImageCollection && frameTileId >= tileCount)) {
          throw TiledWangImportException(
            'smart_tile.tiled.animation_frame_out_of_bounds',
            'L’animation de la tuile $tileId référence la tuile $frameTileId hors atlas.',
          );
        }
        animation.add(
          TiledAnimationFrame(tileId: frameTileId, durationMs: durationMs),
        );
      }
      if (animation.isEmpty) {
        throw TiledWangImportException(
          'smart_tile.tiled.animation_invalid',
          'L’animation de la tuile $tileId ne contient aucune image.',
        );
      }
    }
    tileMetadata[tileId] = TiledTileMetadata(
      tileId: tileId,
      probability: probability,
      image: tileImage,
      animation: animation,
      properties: _parseTiledProperties(tile, context: 'tuile $tileId'),
      collisionObjects: _parseTiledCollisionObjects(tile, tileId: tileId),
    );
  }

  if (isImageCollection && tileMetadata.isEmpty) {
    throw const TiledWangImportException(
      'smart_tile.tiled.tile_image_required',
      'Une collection d’images doit déclarer au moins une tuile illustrée.',
    );
  }
  if (isImageCollection) {
    if (tileMetadata.length != tileCount) {
      throw TiledWangImportException(
        'smart_tile.tiled.tile_count_mismatch',
        'La collection annonce $tileCount tuiles mais en déclare '
            '${tileMetadata.length}.',
      );
    }
    for (final tile in tileMetadata.values) {
      for (final frame in tile.animation) {
        if (!tileMetadata.containsKey(frame.tileId)) {
          throw TiledWangImportException(
            'smart_tile.tiled.image_reference_invalid',
            'L’animation de la tuile ${tile.tileId} référence la tuile '
                '${frame.tileId}, absente de la collection.',
          );
        }
      }
    }
  }

  final wangSets = <TiledWangSet>[];
  final wangSetContainers = root.findElements('wangsets').toList();
  if (wangSetContainers.length > 1) {
    throw const TiledWangImportException(
      'smart_tile.tiled.wang_sets_invalid',
      'Le TSX contient plusieurs catalogues Wang concurrents.',
    );
  }
  if (wangSetContainers.isNotEmpty) {
    for (final wangSet in wangSetContainers.single.findElements('wangset')) {
      final colors = <TiledWangColor>[];
      for (final color in wangSet.findElements('wangcolor')) {
        final rawTileId = _requiredIntAttribute(color, 'tile');
        if ((!isImageCollection && rawTileId >= tileCount) ||
            (isImageCollection &&
                rawTileId >= 0 &&
                !tileMetadata.containsKey(rawTileId))) {
          throw TiledWangImportException(
            'smart_tile.tiled.image_reference_invalid',
            'Un matériau Wang référence la tuile locale $rawTileId, absente '
                'du tileset.',
          );
        }
        colors.add(
          TiledWangColor(
            name: _canonicalName(
              color.getAttribute('name'),
              'Matériau ${colors.length + 1}',
            ),
            colorArgb: _parseColor(color.getAttribute('color')),
            representativeTileId: rawTileId < 0 ? null : rawTileId,
          ),
        );
      }
      if (colors.isEmpty) {
        throw const TiledWangImportException(
          'smart_tile.tiled.wang_colors_required',
          'Un Wang Set importé doit contenir au moins un matériau.',
        );
      }
      final wangTiles = <TiledWangTile>[];
      for (final wangTile in wangSet.findElements('wangtile')) {
        final tileId = _tileId(
          wangTile,
          tileCount: tileCount,
          field: 'tileid',
          sparse: isImageCollection,
        );
        if (isImageCollection && !tileMetadata.containsKey(tileId)) {
          throw TiledWangImportException(
            'smart_tile.tiled.image_reference_invalid',
            'Le Wang Set référence la tuile locale $tileId, absente de la '
                'collection.',
          );
        }
        final rawWangId = wangTile.getAttribute('wangid')?.trim() ?? '';
        final values = rawWangId
            .split(',')
            .map((value) => int.tryParse(value.trim()))
            .toList(growable: false);
        if (values.length != 8 || values.any((value) => value == null)) {
          throw TiledWangImportException(
            'smart_tile.tiled.wang_id_invalid',
            'La tuile Wang $tileId doit définir exactement huit positions.',
          );
        }
        final wangIds = values.cast<int>();
        if (wangIds.any((value) => value < 0 || value > colors.length)) {
          throw TiledWangImportException(
            'smart_tile.tiled.wang_color_out_of_bounds',
            'La tuile Wang $tileId référence un matériau inexistant.',
          );
        }
        wangTiles.add(TiledWangTile(tileId: tileId, wangIds: wangIds));
      }
      if (wangTiles.isEmpty) {
        throw const TiledWangImportException(
          'smart_tile.tiled.wang_tiles_required',
          'Un Wang Set importé doit contenir au moins une tuile Wang.',
        );
      }
      wangSets.add(
        TiledWangSet(
          name: _canonicalName(
            wangSet.getAttribute('name'),
            'Wang Set ${wangSets.length + 1}',
          ),
          type: _wangSetType(wangSet.getAttribute('type')),
          colors: colors,
          tiles: wangTiles,
        ),
      );
    }
  }

  final TiledTilesetLayout layout;
  final TiledTilesetDependencyClosure dependencyClosure;
  if (isImageCollection) {
    final sortedTiles = tileMetadata.values.toList(growable: false)
      ..sort((left, right) => left.tileId.compareTo(right.tileId));
    final dependenciesBySource =
        <String, (TiledTilesetImageReference, List<int>)>{};
    for (final tile in sortedTiles) {
      final image = tile.image!;
      final existing = dependenciesBySource[image.source];
      if (existing == null) {
        dependenciesBySource[image.source] = (image, <int>[tile.tileId]);
      } else {
        if (existing.$1.pixelWidth != image.pixelWidth ||
            existing.$1.pixelHeight != image.pixelHeight) {
          throw TiledWangImportException(
            'smart_tile.tiled.image_dimensions_conflict',
            'L’image ${image.source} possède plusieurs dimensions déclarées.',
          );
        }
        existing.$2.add(tile.tileId);
      }
    }
    layout = TiledImageCollectionLayout(
      tileIds: sortedTiles.map((tile) => tile.tileId),
    );
    dependencyClosure = TiledTilesetDependencyClosure(
      images: <TiledTilesetImageDependency>[
        for (final entry in dependenciesBySource.values)
          TiledTilesetImageDependency(
            source: entry.$1.source,
            pixelWidth: entry.$1.pixelWidth,
            pixelHeight: entry.$1.pixelHeight,
            tileIds: entry.$2,
          ),
      ],
    );
  } else {
    final image = atlasImage!;
    final rows = (tileCount + columns - 1) ~/ columns;
    layout = TiledRegularAtlasLayout(
      image: image,
      columns: columns,
      rows: rows,
      margin: margin,
      spacing: spacing,
    );
    dependencyClosure = TiledTilesetDependencyClosure(
      images: <TiledTilesetImageDependency>[
        TiledTilesetImageDependency(
          source: image.source,
          pixelWidth: image.pixelWidth,
          pixelHeight: image.pixelHeight,
        ),
      ],
    );
  }

  return TiledTilesetDocument(
    name: name,
    tileWidth: tileWidth,
    tileHeight: tileHeight,
    tileCount: tileCount,
    tileOffsetX: tileOffsetX,
    tileOffsetY: tileOffsetY,
    layout: layout,
    dependencyClosure: dependencyClosure,
    properties: properties,
    tiles: tileMetadata,
    wangSets: wangSets,
  );
}

TiledWangTilesetDocument parseTiledWangTileset(String source) {
  final document = parseTiledTileset(source);
  final layout = document.layout;
  if (layout is! TiledRegularAtlasLayout) {
    throw const TiledWangImportException(
      'smart_tile.tiled.image_collection_unsupported',
      'La compilation Wang directe attend encore un atlas régulier packé.',
    );
  }
  if (document.wangSets.isEmpty) {
    throw const TiledWangImportException(
      'smart_tile.tiled.wang_sets_required',
      'Le TSX ne contient aucun Wang Set importable.',
    );
  }
  return TiledWangTilesetDocument(
    name: document.name,
    imageSource: layout.image.source,
    imageWidth: layout.image.pixelWidth,
    imageHeight: layout.image.pixelHeight,
    tileWidth: document.tileWidth,
    tileHeight: document.tileHeight,
    tileCount: document.tileCount,
    columns: layout.columns,
    rows: layout.rows,
    margin: layout.margin,
    spacing: layout.spacing,
    tileOffsetX: document.tileOffsetX,
    tileOffsetY: document.tileOffsetY,
    tiles: document.tiles,
    wangSets: document.wangSets,
  );
}

TiledWangImportBundle compileTiledWangImport({
  required TiledWangTilesetDocument document,
  required String importId,
  required String tilesetId,
  required Iterable<TiledWangSetSelection> selections,
}) {
  final canonicalImportId = importId.trim();
  final canonicalTilesetId = tilesetId.trim();
  if (canonicalImportId.isEmpty || canonicalImportId != importId) {
    throw const TiledWangImportException(
      'smart_tile.tiled.import_id_invalid',
      'L’identifiant technique de l’import est invalide.',
    );
  }
  if (canonicalTilesetId.isEmpty || canonicalTilesetId != tilesetId) {
    throw const TiledWangImportException(
      'smart_tile.tiled.tileset_id_invalid',
      'Le tileset canonique de destination est invalide.',
    );
  }
  final selected = selections.toList(growable: false);
  if (selected.isEmpty) {
    throw const TiledWangImportException(
      'smart_tile.tiled.selection_required',
      'Sélectionnez au moins un Wang Set et son usage.',
    );
  }
  final selectedIndexes = <int>{};
  for (final selection in selected) {
    if (selection.wangSetIndex < 0 ||
        selection.wangSetIndex >= document.wangSets.length) {
      throw const TiledWangImportException(
        'smart_tile.tiled.selection_out_of_bounds',
        'La sélection référence un Wang Set inexistant.',
      );
    }
    if (!selectedIndexes.add(selection.wangSetIndex)) {
      throw const TiledWangImportException(
        'smart_tile.tiled.selection_duplicate',
        'Un Wang Set ne peut être sélectionné qu’une seule fois.',
      );
    }
  }

  final atlasId = '$canonicalImportId-atlas';
  final atlas = ProjectSmartTileAtlas(
    id: atlasId,
    name: document.name,
    tilesetId: canonicalTilesetId,
    cellWidth: document.tileWidth,
    cellHeight: document.tileHeight,
    marginX: document.margin,
    marginY: document.margin,
    spacingX: document.spacing,
    spacingY: document.spacing,
    columns: document.columns,
    rows: document.rows,
    pixelOffsetX: document.tileOffsetX,
    pixelOffsetY: document.tileOffsetY,
  );
  final materials = <ProjectSmartTileMaterial>[];
  final animationsByTile = <int, ProjectSmartTileAnimation>{};
  final presets = <ProjectSmartTilePreset>[];

  for (final selection in selected) {
    final setIndex = selection.wangSetIndex;
    final wangSet = document.wangSets[setIndex];
    final prefix = '$canonicalImportId-w$setIndex';
    final materialIds = <String>[];
    for (var colorIndex = 0; colorIndex < wangSet.colors.length; colorIndex++) {
      final color = wangSet.colors[colorIndex];
      final materialId = '$prefix-material-${colorIndex + 1}';
      materialIds.add(materialId);
      materials.add(
        ProjectSmartTileMaterial(
          id: materialId,
          name: color.name,
          connectionGroupId: '$prefix-connection',
          editorColorArgb: color.colorArgb,
          sortOrder: colorIndex,
        ),
      );
    }

    final grouped = <String, List<TiledWangTile>>{};
    for (final tile in wangSet.tiles) {
      grouped
          .putIfAbsent(tile.wangIds.join(','), () => <TiledWangTile>[])
          .add(tile);
    }
    final rules = <SmartTileRule>[];
    final scenarios = <SmartTileCoverageScenario>[];
    var ruleIndex = 0;
    for (final tiles in grouped.values) {
      final wangIds = tiles.first.wangIds;
      final signature = _signature(
        type: wangSet.type,
        wangIds: wangIds,
        materialIds: materialIds,
      );
      final exactSignature = _exactSignature(
        type: wangSet.type,
        wangIds: wangIds,
        materialIds: materialIds,
      );
      final candidates = <SmartTileCandidate>[];
      for (var candidateIndex = 0;
          candidateIndex < tiles.length;
          candidateIndex++) {
        final tile = tiles[candidateIndex];
        final metadata = document.tiles[tile.tileId];
        final animationFrames =
            metadata?.animation ?? const <TiledAnimationFrame>[];
        final SmartTileVisualSource source;
        if (animationFrames.isEmpty) {
          source = SmartTileVisualSource.frame(
            frame: _frameRef(atlasId, document.columns, tile.tileId),
          );
        } else {
          final animation = animationsByTile.putIfAbsent(
            tile.tileId,
            () => ProjectSmartTileAnimation(
              id: '$canonicalImportId-animation-${tile.tileId}',
              name: '${document.name} — tuile ${tile.tileId}',
              frames: <ProjectSmartTileAnimationFrame>[
                for (final frame in animationFrames)
                  ProjectSmartTileAnimationFrame(
                    frame: _frameRef(
                      atlasId,
                      document.columns,
                      frame.tileId,
                    ),
                    durationMs: frame.durationMs,
                  ),
              ],
            ),
          );
          source = SmartTileVisualSource.animation(animationId: animation.id);
        }
        candidates.add(
          SmartTileCandidate(
            id: '$prefix-rule-$ruleIndex-candidate-$candidateIndex',
            weight: math.max(
              1,
              ((metadata?.probability ?? 1) * 1000).round(),
            ),
            parts: <SmartTileVisualPart>[
              SmartTileVisualPart(source: source),
            ],
          ),
        );
      }
      rules.add(
        SmartTileRule(
          id: '$prefix-rule-$ruleIndex',
          centerMatch: const SmartTileSlotMatch.any(),
          signature: signature,
          candidates: candidates,
        ),
      );
      scenarios.add(
        SmartTileCoverageScenario(
          id: '$prefix-scenario-$ruleIndex',
          centerMaterialId: materialIds.first,
          signature: exactSignature,
        ),
      );
      ruleIndex += 1;
    }
    final (topology, templateHint) = _nativeShape(wangSet.type);
    presets.add(
      ProjectSmartTilePreset(
        id: '$prefix-preset',
        name: wangSet.name,
        usage: selection.usage,
        topology: topology,
        templateHint: templateHint,
        status: SmartTilePresetStatus.draft,
        coveragePolicy: SmartTileCoveragePolicy.sparse,
        coverageProfile: SmartTileCoverageProfile(
          mode: SmartTileCoverageMode.explicit,
          requiredScenarios: scenarios,
        ),
        transformPolicy: const SmartTileTransformPolicy(),
        defaultMaterialId: materialIds.first,
        allowedMaterialIds: materialIds,
        rules: rules,
        tags: const <String>['imported', 'tiled-wang'],
        sortOrder: setIndex,
      ),
    );
  }

  return TiledWangImportBundle(
    atlas: atlas,
    materials: materials,
    animations: animationsByTile.values,
    presets: presets,
  );
}

SmartTileFrameRef _frameRef(String atlasId, int columns, int tileId) {
  return SmartTileFrameRef(
    atlasId: atlasId,
    column: tileId % columns,
    row: tileId ~/ columns,
  );
}

SmartTileSignature _signature({
  required TiledWangSetType type,
  required List<int> wangIds,
  required List<String> materialIds,
}) {
  SmartTileSlotMatch slot(int index, {required bool active}) {
    if (!active) return const SmartTileSlotMatch.any();
    final colorId = wangIds[index];
    return colorId == 0
        ? const SmartTileSlotMatch.empty()
        : SmartTileSlotMatch.material(materialIds[colorId - 1]);
  }

  final edges = type != TiledWangSetType.corner;
  final corners = type != TiledWangSetType.edge;
  return SmartTileSignature(
    northEdge: slot(0, active: edges),
    northEastCorner: slot(1, active: corners),
    eastEdge: slot(2, active: edges),
    southEastCorner: slot(3, active: corners),
    southEdge: slot(4, active: edges),
    southWestCorner: slot(5, active: corners),
    westEdge: slot(6, active: edges),
    northWestCorner: slot(7, active: corners),
  );
}

SmartTileExactSignature _exactSignature({
  required TiledWangSetType type,
  required List<int> wangIds,
  required List<String> materialIds,
}) {
  String? slot(int index, {required bool active}) {
    if (!active || wangIds[index] == 0) return null;
    return materialIds[wangIds[index] - 1];
  }

  final edges = type != TiledWangSetType.corner;
  final corners = type != TiledWangSetType.edge;
  return SmartTileExactSignature(
    northEdge: slot(0, active: edges),
    northEastCorner: slot(1, active: corners),
    eastEdge: slot(2, active: edges),
    southEastCorner: slot(3, active: corners),
    southEdge: slot(4, active: edges),
    southWestCorner: slot(5, active: corners),
    westEdge: slot(6, active: edges),
    northWestCorner: slot(7, active: corners),
  );
}

(SmartTileTopology, SmartTileTemplateHint) _nativeShape(
  TiledWangSetType type,
) {
  return switch (type) {
    TiledWangSetType.corner => (
        SmartTileTopology.wangCorner4,
        SmartTileTemplateHint.corner16,
      ),
    TiledWangSetType.edge => (
        SmartTileTopology.wangEdge4,
        SmartTileTemplateHint.edge16,
      ),
    TiledWangSetType.mixed => (
        SmartTileTopology.wang8,
        SmartTileTemplateHint.mixed256,
      ),
  };
}

TiledWangSetType _wangSetType(String? value) {
  return switch (value?.trim().toLowerCase()) {
    'corner' => TiledWangSetType.corner,
    'edge' => TiledWangSetType.edge,
    'mixed' => TiledWangSetType.mixed,
    _ => throw TiledWangImportException(
        'smart_tile.tiled.wang_type_unsupported',
        'Le type de Wang Set « ${value ?? ''} » n’est pas pris en charge.',
      ),
  };
}

List<TiledProperty> _parseTiledProperties(
  XmlElement owner, {
  required String context,
}) {
  final containers = owner.findElements('properties').toList(growable: false);
  if (containers.length > 1) {
    throw TiledWangImportException(
      'smart_tile.tiled.properties_duplicate',
      'Le $context contient plusieurs blocs de propriétés concurrents.',
    );
  }
  if (containers.isEmpty) return const <TiledProperty>[];

  final names = <String>{};
  final result = <TiledProperty>[];
  for (final property in containers.single.findElements('property')) {
    final name = property.getAttribute('name')?.trim() ?? '';
    if (name.isEmpty) {
      throw TiledWangImportException(
        'smart_tile.tiled.property_name_invalid',
        'Une propriété du $context ne possède pas de nom.',
      );
    }
    if (!names.add(name)) {
      throw TiledWangImportException(
        'smart_tile.tiled.property_duplicate',
        'La propriété $name est déclarée plusieurs fois sur le $context.',
      );
    }
    final rawType = property.getAttribute('type')?.trim().toLowerCase();
    final customType = property.getAttribute('propertytype')?.trim();
    final rawValue = property.getAttribute('value') ?? property.innerText;
    final TiledPropertyValueType type;
    final Object? value;
    final List<TiledProperty> members;
    switch (rawType == null || rawType.isEmpty ? 'string' : rawType) {
      case 'string':
        type = TiledPropertyValueType.string;
        value = rawValue;
        members = const <TiledProperty>[];
      case 'int':
        type = TiledPropertyValueType.integer;
        value = int.tryParse(rawValue.trim());
        members = const <TiledProperty>[];
      case 'float':
        type = TiledPropertyValueType.decimal;
        final parsed = double.tryParse(rawValue.trim());
        value = parsed != null && parsed.isFinite ? parsed : null;
        members = const <TiledProperty>[];
      case 'bool':
        type = TiledPropertyValueType.boolean;
        value = switch (rawValue.trim().toLowerCase()) {
          'true' || '1' => true,
          'false' || '0' => false,
          _ => null,
        };
        members = const <TiledProperty>[];
      case 'color':
        type = TiledPropertyValueType.color;
        final canonical = rawValue.trim();
        value =
            RegExp(r'^#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$').hasMatch(canonical)
                ? canonical
                : null;
        members = const <TiledProperty>[];
      case 'file':
        type = TiledPropertyValueType.file;
        value = _normalizeImageReference(rawValue);
        members = const <TiledProperty>[];
      case 'object':
        type = TiledPropertyValueType.object;
        final parsed = int.tryParse(rawValue.trim());
        value = parsed != null && parsed >= 0 ? parsed : null;
        members = const <TiledProperty>[];
      case 'class':
        type = TiledPropertyValueType.structured;
        value = null;
        members = _parseTiledProperties(
          property,
          context: 'propriété structurée $name',
        );
      default:
        throw TiledWangImportException(
          'smart_tile.tiled.property_type_unsupported',
          'La propriété $name du $context utilise un type non pris en charge.',
        );
    }
    if (type == TiledPropertyValueType.structured) {
      if (customType == null || customType.isEmpty) {
        throw TiledWangImportException(
          'smart_tile.tiled.property_value_invalid',
          'La propriété structurée $name du $context ne possède pas de type.',
        );
      }
    } else if (value == null) {
      throw TiledWangImportException(
        'smart_tile.tiled.property_value_invalid',
        'La valeur de la propriété $name du $context est invalide.',
      );
    }
    result.add(
      TiledProperty(
        name: name,
        type: type,
        value: value,
        customType:
            customType == null || customType.isEmpty ? null : customType,
        members: members,
      ),
    );
  }
  return List<TiledProperty>.unmodifiable(result);
}

List<TiledCollisionObject> _parseTiledCollisionObjects(
  XmlElement tile, {
  required int tileId,
}) {
  final groups = tile.findElements('objectgroup').toList(growable: false);
  if (groups.length > 1) {
    throw TiledWangImportException(
      'smart_tile.tiled.collision_group_duplicate',
      'La tuile $tileId contient plusieurs groupes de collision.',
    );
  }
  if (groups.isEmpty) return const <TiledCollisionObject>[];

  final objectIds = <int>{};
  final result = <TiledCollisionObject>[];
  for (final object in groups.single.findElements('object')) {
    final id = _requiredIntAttribute(object, 'id');
    if (id < 0 || !objectIds.add(id)) {
      throw TiledWangImportException(
        'smart_tile.tiled.collision_object_duplicate',
        'La tuile $tileId possède un objet de collision dupliqué : $id.',
      );
    }
    if (object.getAttribute('gid') != null ||
        object.findElements('text').isNotEmpty) {
      throw TiledWangImportException(
        'smart_tile.tiled.collision_shape_unsupported',
        'L’objet $id de la tuile $tileId n’est pas une forme de collision.',
      );
    }
    final shapeElements = <XmlElement>[
      ...object.findElements('ellipse'),
      ...object.findElements('polygon'),
      ...object.findElements('polyline'),
      ...object.findElements('point'),
    ];
    if (shapeElements.length > 1) {
      throw TiledWangImportException(
        'smart_tile.tiled.collision_shape_invalid',
        'L’objet $id de la tuile $tileId possède plusieurs formes.',
      );
    }
    final shape = switch (shapeElements.firstOrNull?.name.local) {
      'ellipse' => TiledCollisionShape.ellipse,
      'polygon' => TiledCollisionShape.polygon,
      'polyline' => TiledCollisionShape.polyline,
      'point' => TiledCollisionShape.point,
      _ => TiledCollisionShape.rectangle,
    };
    final points = switch (shape) {
      TiledCollisionShape.polygon ||
      TiledCollisionShape.polyline =>
        _parseTiledPoints(shapeElements.single, tileId: tileId, objectId: id),
      _ => const <TiledPoint>[],
    };
    final x = _finiteDoubleAttribute(object, 'x');
    final y = _finiteDoubleAttribute(object, 'y');
    final width = _finiteDoubleAttribute(object, 'width', fallback: 0);
    final height = _finiteDoubleAttribute(object, 'height', fallback: 0);
    final rotation = _finiteDoubleAttribute(object, 'rotation', fallback: 0);
    final dimensionsAreValid = switch (shape) {
      TiledCollisionShape.rectangle ||
      TiledCollisionShape.ellipse =>
        width > 0 && height > 0,
      TiledCollisionShape.polygon => points.length >= 3,
      TiledCollisionShape.polyline => points.length >= 2,
      TiledCollisionShape.point => width == 0 && height == 0,
    };
    if (!dimensionsAreValid) {
      throw TiledWangImportException(
        'smart_tile.tiled.collision_shape_invalid',
        'La forme de l’objet $id de la tuile $tileId est invalide.',
      );
    }
    result.add(
      TiledCollisionObject(
        id: id,
        name: object.getAttribute('name')?.trim() ?? '',
        className:
            (object.getAttribute('class') ?? object.getAttribute('type') ?? '')
                .trim(),
        shape: shape,
        x: x,
        y: y,
        width: width,
        height: height,
        rotation: rotation,
        points: points,
        properties: _parseTiledProperties(
          object,
          context: 'objet $id de la tuile $tileId',
        ),
      ),
    );
  }
  return List<TiledCollisionObject>.unmodifiable(result);
}

List<TiledPoint> _parseTiledPoints(
  XmlElement shape, {
  required int tileId,
  required int objectId,
}) {
  final raw = shape.getAttribute('points')?.trim() ?? '';
  final result = <TiledPoint>[];
  for (final pair in raw.split(RegExp(r'\s+'))) {
    if (pair.isEmpty) continue;
    final coordinates = pair.split(',');
    final x = coordinates.length == 2 ? double.tryParse(coordinates[0]) : null;
    final y = coordinates.length == 2 ? double.tryParse(coordinates[1]) : null;
    if (x == null || y == null || !x.isFinite || !y.isFinite) {
      throw TiledWangImportException(
        'smart_tile.tiled.collision_shape_invalid',
        'Les points de l’objet $objectId de la tuile $tileId sont invalides.',
      );
    }
    result.add(TiledPoint(x: x, y: y));
  }
  return List<TiledPoint>.unmodifiable(result);
}

double _finiteDoubleAttribute(
  XmlElement element,
  String field, {
  double? fallback,
}) {
  final raw = element.getAttribute(field);
  if (raw == null && fallback != null) return fallback;
  final value = double.tryParse(raw ?? '');
  if (value == null || !value.isFinite) {
    throw TiledWangImportException(
      'smart_tile.tiled.number_invalid',
      'L’attribut $field doit être un nombre fini.',
    );
  }
  return value;
}

TiledTilesetImageReference _parseTilesetImage(
  XmlElement image, {
  required String context,
}) {
  final source = _normalizeImageReference(image.getAttribute('source'));
  final width = int.tryParse(image.getAttribute('width') ?? '');
  final height = int.tryParse(image.getAttribute('height') ?? '');
  if (width == null || height == null || width <= 0 || height <= 0) {
    throw TiledWangImportException(
      'smart_tile.tiled.image_dimensions_invalid',
      'L’image du $context doit déclarer une largeur et une hauteur '
          'strictement positives.',
    );
  }
  return TiledTilesetImageReference(
    source: source,
    pixelWidth: width,
    pixelHeight: height,
  );
}

String _normalizeImageReference(String? raw) {
  final value = raw?.trim().replaceAll('\\', '/') ?? '';
  final hasScheme = RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*:').hasMatch(value);
  if (value.isEmpty ||
      value.contains('\u0000') ||
      value.startsWith('/') ||
      value.startsWith('//') ||
      value.startsWith(':/') ||
      hasScheme) {
    throw const TiledWangImportException(
      'smart_tile.tiled.image_reference_invalid',
      'Une image du TSX possède une référence locale invalide.',
    );
  }
  final normalized = <String>[];
  for (final segment in value.split('/')) {
    if (segment.isEmpty || segment == '.') continue;
    if (segment == '..' && normalized.isNotEmpty && normalized.last != '..') {
      normalized.removeLast();
      continue;
    }
    normalized.add(segment);
  }
  if (normalized.isEmpty) {
    throw const TiledWangImportException(
      'smart_tile.tiled.image_reference_invalid',
      'Une image du TSX possède une référence locale invalide.',
    );
  }
  return normalized.join('/');
}

int _tileId(
  XmlElement element, {
  required int tileCount,
  String field = 'id',
  bool sparse = false,
}) {
  final value = _requiredIntAttribute(element, field);
  if (value < 0 || (!sparse && value >= tileCount)) {
    throw TiledWangImportException(
      'smart_tile.tiled.tile_out_of_bounds',
      'La tuile $value est hors des limites du tileset.',
    );
  }
  return value;
}

int _positiveIntAttribute(XmlElement element, String field) {
  final value = _requiredIntAttribute(element, field);
  if (value <= 0) {
    throw TiledWangImportException(
      'smart_tile.tiled.number_invalid',
      'L’attribut $field doit être strictement positif.',
    );
  }
  return value;
}

int _nonNegativeIntAttribute(
  XmlElement element,
  String field, {
  int? fallback,
}) {
  final raw = element.getAttribute(field);
  if (raw == null && fallback != null) return fallback;
  final value = int.tryParse(raw ?? '');
  if (value == null || value < 0) {
    throw TiledWangImportException(
      'smart_tile.tiled.number_invalid',
      'L’attribut $field doit être un entier positif ou nul.',
    );
  }
  return value;
}

int _requiredIntAttribute(XmlElement element, String field) {
  final value = int.tryParse(element.getAttribute(field) ?? '');
  if (value == null) {
    throw TiledWangImportException(
      'smart_tile.tiled.number_invalid',
      'L’attribut $field doit être un entier.',
    );
  }
  return value;
}

double _probability(String? raw) {
  if (raw == null) return 1;
  final value = double.tryParse(raw);
  if (value == null || !value.isFinite || value < 0) {
    throw const TiledWangImportException(
      'smart_tile.tiled.probability_invalid',
      'Une probabilité de tuile Tiled est invalide.',
    );
  }
  return value;
}

int _parseColor(String? raw) {
  final value = raw?.trim() ?? '';
  if (!value.startsWith('#')) {
    throw const TiledWangImportException(
      'smart_tile.tiled.color_invalid',
      'Une couleur Wang est invalide.',
    );
  }
  final hex = value.substring(1);
  final parsed = int.tryParse(hex, radix: 16);
  if (parsed == null || (hex.length != 6 && hex.length != 8)) {
    throw const TiledWangImportException(
      'smart_tile.tiled.color_invalid',
      'Une couleur Wang est invalide.',
    );
  }
  return hex.length == 6 ? 0xff000000 | parsed : parsed;
}

String _canonicalName(String? value, String fallback) {
  final canonical = value?.trim() ?? '';
  return canonical.isEmpty ? fallback : canonical;
}
