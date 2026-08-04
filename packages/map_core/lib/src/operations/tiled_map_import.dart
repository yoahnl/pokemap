import 'dart:convert';
import 'dart:io' show gzip, zlib;
import 'dart:typed_data';

import 'package:meta/meta.dart' show immutable;
import 'package:xml/xml.dart';

import 'tiled_wang_import.dart';

const _tiledHorizontalFlag = 0x80000000;
const _tiledVerticalFlag = 0x40000000;
const _tiledDiagonalFlag = 0x20000000;
const _tiledHexagonal120Flag = 0x10000000;
const _tiledTileIdMask = 0x0fffffff;
const _tiledMaxUint32 = 0xffffffff;

enum TiledMapOrientation { orthogonal }

enum TiledMapRenderOrder { rightDown, rightUp, leftDown, leftUp }

enum TiledMapBlendMode {
  normal,
  add,
  multiply,
  screen,
  overlay,
  darken,
  lighten,
  colorDodge,
  colorBurn,
  hardLight,
  softLight,
  difference,
  exclusion,
}

enum TiledMapObjectDrawOrder { indexOrder, topDown }

enum TiledMapObjectShape {
  rectangle,
  ellipse,
  capsule,
  point,
  polygon,
  polyline,
  text,
  tile,
}

@immutable
final class TiledMapImportException implements Exception {
  const TiledMapImportException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'TiledMapImportException($code): $message';
}

/// Explicit resource budgets for the untrusted TMX format boundary.
///
/// The defaults cover maps far larger than the current editor can reasonably
/// author while preventing an XML document or compressed layer from turning
/// import inspection into an unbounded allocation.
@immutable
final class TiledMapParserLimits {
  const TiledMapParserLimits({
    this.maxSourceCharacters = 64 * 1024 * 1024,
    this.maxXmlNodes = 2 * 1024 * 1024,
    this.maxMapWidth = 8192,
    this.maxMapHeight = 8192,
    this.maxMapCells = 16 * 1024 * 1024,
    this.maxTotalLayerCells = 32 * 1024 * 1024,
    this.maxTileSize = 16384,
    this.maxTilesets = 4096,
    this.maxLayers = 4096,
    this.maxGroupDepth = 32,
    this.maxObjects = 1024 * 1024,
    this.maxProperties = 128 * 1024,
    this.maxPropertyDepth = 16,
    this.maxPoints = 4 * 1024 * 1024,
    this.maxStringLength = 4096,
    this.maxLayerDataBytes = 64 * 1024 * 1024,
    this.maxCompressedLayerBytes = 64 * 1024 * 1024,
  });

  final int maxSourceCharacters;
  final int maxXmlNodes;
  final int maxMapWidth;
  final int maxMapHeight;
  final int maxMapCells;
  final int maxTotalLayerCells;
  final int maxTileSize;
  final int maxTilesets;
  final int maxLayers;
  final int maxGroupDepth;
  final int maxObjects;
  final int maxProperties;
  final int maxPropertyDepth;
  final int maxPoints;
  final int maxStringLength;
  final int maxLayerDataBytes;
  final int maxCompressedLayerBytes;
}

@immutable
final class TiledMapTilesetReference {
  const TiledMapTilesetReference({
    required this.firstGid,
    required this.source,
  });

  final int firstGid;
  final String source;
}

@immutable
final class TiledMapDependencyClosure {
  TiledMapDependencyClosure({
    required Iterable<TiledMapTilesetReference> tilesets,
  }) : tilesets = List<TiledMapTilesetReference>.unmodifiable(tilesets);

  final List<TiledMapTilesetReference> tilesets;
}

/// One non-empty TMX GID resolved to its external TSX and sparse local ID.
///
/// The four high bits remain explicit. STN-10.3 owns their conversion to the
/// native D4 representation, so this parser never guesses transform semantics.
@immutable
final class TiledMapTileReference {
  const TiledMapTileReference({
    required this.rawGid,
    required this.globalTileId,
    required this.localTileId,
    required this.tileset,
    required this.flipHorizontally,
    required this.flipVertically,
    required this.flipDiagonally,
    required this.hexagonal120Flag,
  });

  final int rawGid;
  final int globalTileId;
  final int localTileId;
  final TiledMapTilesetReference tileset;
  final bool flipHorizontally;
  final bool flipVertically;
  final bool flipDiagonally;
  final bool hexagonal120Flag;
}

@immutable
sealed class TiledMapLayer {
  TiledMapLayer({
    required this.id,
    required this.name,
    required this.className,
    required this.tileX,
    required this.tileY,
    required this.visible,
    required this.opacity,
    required this.tintColor,
    required this.offsetX,
    required this.offsetY,
    required this.parallaxX,
    required this.parallaxY,
    required this.blendMode,
    required Iterable<TiledProperty> properties,
  }) : properties = List<TiledProperty>.unmodifiable(properties);

  final int id;
  final String name;
  final String className;
  final int tileX;
  final int tileY;
  final bool visible;
  final double opacity;
  final String? tintColor;
  final double offsetX;
  final double offsetY;
  final double parallaxX;
  final double parallaxY;
  final TiledMapBlendMode blendMode;
  final List<TiledProperty> properties;
}

@immutable
final class TiledMapTileLayer extends TiledMapLayer {
  TiledMapTileLayer({
    required super.id,
    required super.name,
    required super.className,
    required super.tileX,
    required super.tileY,
    required super.visible,
    required super.opacity,
    required super.tintColor,
    required super.offsetX,
    required super.offsetY,
    required super.parallaxX,
    required super.parallaxY,
    required super.blendMode,
    required super.properties,
    required this.width,
    required this.height,
    required Iterable<TiledMapTileReference?> cells,
  }) : cells = List<TiledMapTileReference?>.unmodifiable(cells);

  final int width;
  final int height;
  final List<TiledMapTileReference?> cells;
}

@immutable
final class TiledMapObject {
  TiledMapObject({
    required this.id,
    required this.name,
    required this.className,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.rotation,
    required this.opacity,
    required this.visible,
    required this.shape,
    required this.tile,
    required Iterable<TiledPoint> points,
    required this.text,
    required Iterable<TiledProperty> properties,
  })  : points = List<TiledPoint>.unmodifiable(points),
        properties = List<TiledProperty>.unmodifiable(properties);

  final int id;
  final String name;
  final String className;
  final double x;
  final double y;
  final double width;
  final double height;
  final double rotation;
  final double opacity;
  final bool visible;
  final TiledMapObjectShape shape;
  final TiledMapTileReference? tile;
  final List<TiledPoint> points;
  final String? text;
  final List<TiledProperty> properties;
}

@immutable
final class TiledMapObjectLayer extends TiledMapLayer {
  TiledMapObjectLayer({
    required super.id,
    required super.name,
    required super.className,
    required super.tileX,
    required super.tileY,
    required super.visible,
    required super.opacity,
    required super.tintColor,
    required super.offsetX,
    required super.offsetY,
    required super.parallaxX,
    required super.parallaxY,
    required super.blendMode,
    required super.properties,
    required this.color,
    required this.drawOrder,
    required Iterable<TiledMapObject> objects,
  }) : objects = List<TiledMapObject>.unmodifiable(objects);

  final String? color;
  final TiledMapObjectDrawOrder drawOrder;
  final List<TiledMapObject> objects;
}

@immutable
final class TiledMapGroupLayer extends TiledMapLayer {
  TiledMapGroupLayer({
    required super.id,
    required super.name,
    required super.className,
    required super.tileX,
    required super.tileY,
    required super.visible,
    required super.opacity,
    required super.tintColor,
    required super.offsetX,
    required super.offsetY,
    required super.parallaxX,
    required super.parallaxY,
    required super.blendMode,
    required super.properties,
    required Iterable<TiledMapLayer> layers,
  }) : layers = List<TiledMapLayer>.unmodifiable(layers);

  final List<TiledMapLayer> layers;
}

@immutable
final class TiledMapDocument {
  TiledMapDocument({
    required this.version,
    required this.tiledVersion,
    required this.className,
    required this.orientation,
    required this.renderOrder,
    required this.width,
    required this.height,
    required this.tileWidth,
    required this.tileHeight,
    required this.backgroundColor,
    required this.nextLayerId,
    required this.nextObjectId,
    required Iterable<TiledProperty> properties,
    required Iterable<TiledMapTilesetReference> tilesets,
    required this.dependencyClosure,
    required Iterable<TiledMapLayer> layers,
  })  : properties = List<TiledProperty>.unmodifiable(properties),
        tilesets = List<TiledMapTilesetReference>.unmodifiable(tilesets),
        layers = List<TiledMapLayer>.unmodifiable(layers);

  final String version;
  final String? tiledVersion;
  final String className;
  final TiledMapOrientation orientation;
  final TiledMapRenderOrder renderOrder;
  final int width;
  final int height;
  final int tileWidth;
  final int tileHeight;
  final String? backgroundColor;
  final int? nextLayerId;
  final int? nextObjectId;
  final List<TiledProperty> properties;
  final List<TiledMapTilesetReference> tilesets;
  final TiledMapDependencyClosure dependencyClosure;
  final List<TiledMapLayer> layers;
}

/// Parses the deliberately bounded, portable TMX V1 subset without file I/O.
///
/// External TSX files are returned as dependencies and are never opened here.
/// Infinite maps, image layers and templates fail closed so later lots
/// cannot accidentally present a lossy import as faithful.
TiledMapDocument parseTiledMap(
  String source, {
  TiledMapParserLimits limits = const TiledMapParserLimits(),
}) {
  _validateLimits(limits);
  if (source.length > limits.maxSourceCharacters) {
    throw const TiledMapImportException(
      'map.tiled.source_limit_exceeded',
      'Le document TMX dépasse la taille maximale autorisée.',
    );
  }
  if (source.contains('\u0000')) {
    throw const TiledMapImportException(
      'map.tiled.xml_invalid',
      'Le document TMX contient un caractère XML interdit.',
    );
  }
  if (RegExp(r'<!DOCTYPE', caseSensitive: false).hasMatch(source)) {
    throw const TiledMapImportException(
      'map.tiled.doctype_unsupported',
      'Les déclarations de type et entités XML ne sont pas autorisées.',
    );
  }

  final XmlDocument xml;
  try {
    xml = XmlDocument.parse(source);
  } on XmlException catch (error) {
    throw TiledMapImportException(
      'map.tiled.xml_invalid',
      'Le fichier TMX est invalide : ${error.message}',
    );
  }
  var nodeCount = 0;
  for (final _ in xml.descendants) {
    nodeCount += 1;
    if (nodeCount > limits.maxXmlNodes) {
      throw const TiledMapImportException(
        'map.tiled.xml_limit_exceeded',
        'Le document TMX contient trop de nœuds XML.',
      );
    }
  }
  final root = xml.rootElement;
  if (root.name.local != 'map') {
    throw const TiledMapImportException(
      'map.tiled.root_invalid',
      'Le document doit contenir une carte TMX à sa racine.',
    );
  }
  return _TiledMapParser(limits).parse(root);
}

final class _TiledMapParser {
  _TiledMapParser(this.limits);

  final TiledMapParserLimits limits;
  final Set<int> _layerIds = <int>{};
  final Set<int> _objectIds = <int>{};
  var _layerCount = 0;
  var _decodedLayerCellCount = 0;
  var _propertyCount = 0;
  var _pointCount = 0;

  TiledMapDocument parse(XmlElement root) {
    final orientation = switch (root.getAttribute('orientation')) {
      'orthogonal' => TiledMapOrientation.orthogonal,
      _ => throw const TiledMapImportException(
          'map.tiled.orientation_unsupported',
          'Seules les cartes TMX orthogonales sont prises en charge.',
        ),
    };
    if (_boolAttribute(root, 'infinite', fallback: false)) {
      throw const TiledMapImportException(
        'map.tiled.infinite_unsupported',
        'Les cartes TMX infinies et leurs chunks ne sont pas pris en charge.',
      );
    }
    final width = _positiveIntAttribute(root, 'width');
    final height = _positiveIntAttribute(root, 'height');
    final tileWidth = _positiveIntAttribute(root, 'tilewidth');
    final tileHeight = _positiveIntAttribute(root, 'tileheight');
    final cellCount = width * height;
    if (width > limits.maxMapWidth ||
        height > limits.maxMapHeight ||
        cellCount > limits.maxMapCells) {
      throw const TiledMapImportException(
        'map.tiled.map_size_limit_exceeded',
        'La grille TMX dépasse les limites d’import autorisées.',
      );
    }
    if (tileWidth > limits.maxTileSize || tileHeight > limits.maxTileSize) {
      throw const TiledMapImportException(
        'map.tiled.tile_size_limit_exceeded',
        'La taille de cellule TMX dépasse la limite autorisée.',
      );
    }
    final children = root.childElements.toList(growable: false);
    _validateChildOrder(children);
    if (children
        .where((child) => child.name.local == 'imagelayer')
        .isNotEmpty) {
      throw const TiledMapImportException(
        'map.tiled.image_layer_unsupported',
        'Les calques image TMX ne sont pas pris en charge en V1.',
      );
    }
    final tilesetElements = children
        .where((child) => child.name.local == 'tileset')
        .toList(growable: false);
    if (tilesetElements.length > limits.maxTilesets) {
      throw const TiledMapImportException(
        'map.tiled.tileset_limit_exceeded',
        'La carte TMX référence trop de tilesets.',
      );
    }
    final tilesets = _parseTilesets(tilesetElements);
    final layers = <TiledMapLayer>[];
    for (final element in children) {
      if (element.name.local == 'layer' ||
          element.name.local == 'objectgroup' ||
          element.name.local == 'group') {
        layers.add(
          _parseLayerElement(
            element,
            mapWidth: width,
            mapHeight: height,
            tilesets: tilesets,
            groupDepth: 0,
          ),
        );
      }
    }

    return TiledMapDocument(
      version: _requiredStringAttribute(root, 'version'),
      tiledVersion: _optionalStringAttribute(root, 'tiledversion'),
      className: _className(root),
      orientation: orientation,
      renderOrder: _renderOrder(root.getAttribute('renderorder')),
      width: width,
      height: height,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      backgroundColor: _optionalColorAttribute(root, 'backgroundcolor'),
      nextLayerId: _optionalPositiveIntAttribute(root, 'nextlayerid'),
      nextObjectId: _optionalPositiveIntAttribute(root, 'nextobjectid'),
      properties: _parseProperties(root, context: 'carte', depth: 0),
      tilesets: tilesets,
      dependencyClosure: TiledMapDependencyClosure(tilesets: tilesets),
      layers: layers,
    );
  }

  TiledMapLayer _parseLayerElement(
    XmlElement element, {
    required int mapWidth,
    required int mapHeight,
    required List<TiledMapTilesetReference> tilesets,
    required int groupDepth,
  }) {
    return switch (element.name.local) {
      'layer' => _parseTileLayer(
          element,
          mapWidth: mapWidth,
          mapHeight: mapHeight,
          tilesets: tilesets,
        ),
      'objectgroup' => _parseObjectLayer(element, tilesets: tilesets),
      'group' => _parseGroupLayer(
          element,
          mapWidth: mapWidth,
          mapHeight: mapHeight,
          tilesets: tilesets,
          groupDepth: groupDepth,
        ),
      _ => throw StateError('Unsupported TMX layer dispatch.'),
    };
  }

  TiledMapGroupLayer _parseGroupLayer(
    XmlElement element, {
    required int mapWidth,
    required int mapHeight,
    required List<TiledMapTilesetReference> tilesets,
    required int groupDepth,
  }) {
    if (groupDepth >= limits.maxGroupDepth) {
      throw const TiledMapImportException(
        'map.tiled.group_depth_limit_exceeded',
        'Les groupes de calques TMX sont trop profondément imbriqués.',
      );
    }
    final common = _parseLayerCommon(element);
    final layers = <TiledMapLayer>[];
    for (final child in element.childElements) {
      if (child.name.local == 'imagelayer') {
        throw const TiledMapImportException(
          'map.tiled.image_layer_unsupported',
          'Les calques image TMX ne sont pas pris en charge en V1.',
        );
      }
      if (child.name.local == 'layer' ||
          child.name.local == 'objectgroup' ||
          child.name.local == 'group') {
        layers.add(
          _parseLayerElement(
            child,
            mapWidth: mapWidth,
            mapHeight: mapHeight,
            tilesets: tilesets,
            groupDepth: groupDepth + 1,
          ),
        );
      }
    }
    return TiledMapGroupLayer(
      id: common.id,
      name: common.name,
      className: common.className,
      tileX: common.tileX,
      tileY: common.tileY,
      visible: common.visible,
      opacity: common.opacity,
      tintColor: common.tintColor,
      offsetX: common.offsetX,
      offsetY: common.offsetY,
      parallaxX: common.parallaxX,
      parallaxY: common.parallaxY,
      blendMode: common.blendMode,
      properties: common.properties,
      layers: layers,
    );
  }

  void _validateChildOrder(List<XmlElement> children) {
    var layersStarted = false;
    for (final child in children) {
      final name = child.name.local;
      if (name == 'layer' ||
          name == 'objectgroup' ||
          name == 'imagelayer' ||
          name == 'group') {
        layersStarted = true;
      } else if (name == 'tileset' && layersStarted) {
        throw const TiledMapImportException(
          'map.tiled.tileset_order_invalid',
          'Les tilesets TMX doivent précéder tous les calques.',
        );
      }
    }
  }

  List<TiledMapTilesetReference> _parseTilesets(
    List<XmlElement> elements,
  ) {
    final references = <TiledMapTilesetReference>[];
    final sources = <String>{};
    var previousFirstGid = 0;
    for (final element in elements) {
      final source = element.getAttribute('source');
      if (source == null || source.trim().isEmpty) {
        throw const TiledMapImportException(
          'map.tiled.inline_tileset_unsupported',
          'Les tilesets intégrés au TMX ne sont pas pris en charge en V1.',
        );
      }
      if (element.childElements.isNotEmpty) {
        throw const TiledMapImportException(
          'map.tiled.inline_tileset_unsupported',
          'Une référence TSX externe ne peut pas contenir un tileset intégré.',
        );
      }
      final firstGid = _positiveIntAttribute(element, 'firstgid');
      if ((references.isEmpty && firstGid != 1) ||
          firstGid <= previousFirstGid ||
          firstGid > _tiledTileIdMask) {
        throw const TiledMapImportException(
          'map.tiled.tileset_first_gid_invalid',
          'Les firstgid TMX doivent commencer à 1 et être strictement croissants.',
        );
      }
      final normalized = _normalizeDependencyReference(source);
      if (!sources.add(normalized)) {
        throw const TiledMapImportException(
          'map.tiled.tileset_source_duplicate',
          'Un même TSX ne peut pas être référencé plusieurs fois.',
        );
      }
      references.add(
        TiledMapTilesetReference(firstGid: firstGid, source: normalized),
      );
      previousFirstGid = firstGid;
    }
    return List<TiledMapTilesetReference>.unmodifiable(references);
  }

  TiledMapTileLayer _parseTileLayer(
    XmlElement element, {
    required int mapWidth,
    required int mapHeight,
    required List<TiledMapTilesetReference> tilesets,
  }) {
    final common = _parseLayerCommon(element);
    final width = _positiveIntAttribute(element, 'width');
    final height = _positiveIntAttribute(element, 'height');
    if (common.tileX != 0 ||
        common.tileY != 0 ||
        width != mapWidth ||
        height != mapHeight) {
      throw const TiledMapImportException(
        'map.tiled.layer_dimensions_invalid',
        'Un calque fini doit couvrir exactement la grille de la carte.',
      );
    }
    final dataElements = element.findElements('data').toList(growable: false);
    if (dataElements.length != 1) {
      throw const TiledMapImportException(
        'map.tiled.layer_data_invalid',
        'Un calque de tuiles doit contenir exactement un bloc data.',
      );
    }
    final rawGids = _decodeLayerData(
      dataElements.single,
      expectedCellCount: width * height,
    );
    final cells = <TiledMapTileReference?>[
      for (final gid in rawGids) _resolveGid(gid, tilesets),
    ];
    return TiledMapTileLayer(
      id: common.id,
      name: common.name,
      className: common.className,
      tileX: common.tileX,
      tileY: common.tileY,
      visible: common.visible,
      opacity: common.opacity,
      tintColor: common.tintColor,
      offsetX: common.offsetX,
      offsetY: common.offsetY,
      parallaxX: common.parallaxX,
      parallaxY: common.parallaxY,
      blendMode: common.blendMode,
      properties: common.properties,
      width: width,
      height: height,
      cells: cells,
    );
  }

  TiledMapObjectLayer _parseObjectLayer(
    XmlElement element, {
    required List<TiledMapTilesetReference> tilesets,
  }) {
    final common = _parseLayerCommon(element);
    final objects = <TiledMapObject>[];
    for (final object in element.findElements('object')) {
      objects.add(_parseObject(object, tilesets: tilesets));
    }
    return TiledMapObjectLayer(
      id: common.id,
      name: common.name,
      className: common.className,
      tileX: common.tileX,
      tileY: common.tileY,
      visible: common.visible,
      opacity: common.opacity,
      tintColor: common.tintColor,
      offsetX: common.offsetX,
      offsetY: common.offsetY,
      parallaxX: common.parallaxX,
      parallaxY: common.parallaxY,
      blendMode: common.blendMode,
      properties: common.properties,
      color: _optionalColorAttribute(element, 'color'),
      drawOrder: switch (element.getAttribute('draworder') ?? 'topdown') {
        'index' => TiledMapObjectDrawOrder.indexOrder,
        'topdown' => TiledMapObjectDrawOrder.topDown,
        _ => throw const TiledMapImportException(
            'map.tiled.object_draw_order_invalid',
            'L’ordre de dessin du calque d’objets est invalide.',
          ),
      },
      objects: objects,
    );
  }

  TiledMapObject _parseObject(
    XmlElement element, {
    required List<TiledMapTilesetReference> tilesets,
  }) {
    if (element.getAttribute('template') != null) {
      throw const TiledMapImportException(
        'map.tiled.object_template_unsupported',
        'Les templates d’objet externes ne sont pas pris en charge en V1.',
      );
    }
    final id = _positiveIntAttribute(element, 'id');
    if (_objectIds.length >= limits.maxObjects) {
      throw const TiledMapImportException(
        'map.tiled.object_limit_exceeded',
        'La carte TMX contient trop d’objets.',
      );
    }
    if (!_objectIds.add(id)) {
      throw const TiledMapImportException(
        'map.tiled.object_id_duplicate',
        'Les identifiants d’objet TMX doivent être uniques.',
      );
    }
    final rawGid = element.getAttribute('gid');
    final tile = rawGid == null
        ? null
        : _resolveGid(_parseGid(rawGid), tilesets) ??
            (throw const TiledMapImportException(
              'map.tiled.object_gid_invalid',
              'Un objet tuile ne peut pas utiliser le GID vide.',
            ));
    final shapeElements = <XmlElement>[
      ...element.findElements('ellipse'),
      ...element.findElements('capsule'),
      ...element.findElements('point'),
      ...element.findElements('polygon'),
      ...element.findElements('polyline'),
      ...element.findElements('text'),
    ];
    if (shapeElements.length > 1 ||
        (tile != null && shapeElements.isNotEmpty)) {
      throw const TiledMapImportException(
        'map.tiled.object_shape_invalid',
        'Un objet TMX ne peut posséder qu’une seule forme visuelle.',
      );
    }
    final shape = tile != null
        ? TiledMapObjectShape.tile
        : switch (shapeElements.firstOrNull?.name.local) {
            'ellipse' => TiledMapObjectShape.ellipse,
            'capsule' => TiledMapObjectShape.capsule,
            'point' => TiledMapObjectShape.point,
            'polygon' => TiledMapObjectShape.polygon,
            'polyline' => TiledMapObjectShape.polyline,
            'text' => TiledMapObjectShape.text,
            _ => TiledMapObjectShape.rectangle,
          };
    final points = switch (shape) {
      TiledMapObjectShape.polygon ||
      TiledMapObjectShape.polyline =>
        _parsePoints(shapeElements.single),
      _ => const <TiledPoint>[],
    };
    if ((shape == TiledMapObjectShape.polygon && points.length < 3) ||
        (shape == TiledMapObjectShape.polyline && points.length < 2)) {
      throw const TiledMapImportException(
        'map.tiled.object_shape_invalid',
        'La forme de l’objet TMX ne contient pas assez de points.',
      );
    }
    final width = _finiteDoubleAttribute(element, 'width', fallback: 0);
    final height = _finiteDoubleAttribute(element, 'height', fallback: 0);
    if (width < 0 || height < 0) {
      throw const TiledMapImportException(
        'map.tiled.object_dimensions_invalid',
        'Les dimensions d’un objet TMX doivent être positives ou nulles.',
      );
    }
    final text = shape == TiledMapObjectShape.text
        ? _boundedString(shapeElements.single.innerText, 'texte d’objet')
        : null;
    return TiledMapObject(
      id: id,
      name: _boundedString(element.getAttribute('name') ?? '', 'nom d’objet'),
      className: _className(element),
      x: _finiteDoubleAttribute(element, 'x', fallback: 0),
      y: _finiteDoubleAttribute(element, 'y', fallback: 0),
      width: width,
      height: height,
      rotation: _finiteDoubleAttribute(element, 'rotation', fallback: 0),
      opacity: _opacity(element),
      visible: _boolAttribute(element, 'visible', fallback: true),
      shape: shape,
      tile: tile,
      points: points,
      text: text,
      properties: _parseProperties(
        element,
        context: 'objet $id',
        depth: 0,
      ),
    );
  }

  List<TiledPoint> _parsePoints(XmlElement element) {
    final raw = element.getAttribute('points')?.trim() ?? '';
    final result = <TiledPoint>[];
    var tokenStart = -1;
    void addPoint(int start, int end) {
      if (end - start > 128) {
        throw const TiledMapImportException(
          'map.tiled.object_shape_invalid',
          'Les coordonnées d’un objet TMX sont trop longues.',
        );
      }
      final comma = raw.indexOf(',', start);
      final x = comma > start && comma < end
          ? double.tryParse(raw.substring(start, comma))
          : null;
      final y = comma > start && comma < end - 1
          ? double.tryParse(raw.substring(comma + 1, end))
          : null;
      if (x == null || y == null || !x.isFinite || !y.isFinite) {
        throw const TiledMapImportException(
          'map.tiled.object_shape_invalid',
          'Les points d’un objet TMX sont invalides.',
        );
      }
      _pointCount += 1;
      if (_pointCount > limits.maxPoints) {
        throw const TiledMapImportException(
          'map.tiled.point_limit_exceeded',
          'La carte TMX contient trop de points d’objet.',
        );
      }
      result.add(TiledPoint(x: x, y: y));
    }

    for (var index = 0; index <= raw.length; index++) {
      final atEnd = index == raw.length;
      final whitespace = !atEnd && raw.codeUnitAt(index) <= 0x20;
      if (tokenStart < 0) {
        if (!atEnd && !whitespace) tokenStart = index;
      } else if (atEnd || whitespace) {
        addPoint(tokenStart, index);
        tokenStart = -1;
      }
    }
    return result;
  }

  _TiledLayerCommon _parseLayerCommon(XmlElement element) {
    _layerCount += 1;
    if (_layerCount > limits.maxLayers) {
      throw const TiledMapImportException(
        'map.tiled.layer_limit_exceeded',
        'La carte TMX contient trop de calques.',
      );
    }
    final id = _positiveIntAttribute(element, 'id');
    if (!_layerIds.add(id)) {
      throw const TiledMapImportException(
        'map.tiled.layer_id_duplicate',
        'Les identifiants de calque TMX doivent être uniques.',
      );
    }
    return _TiledLayerCommon(
      id: id,
      name: _boundedString(element.getAttribute('name') ?? '', 'nom de calque'),
      className: _className(element),
      tileX: _nonNegativeIntAttribute(element, 'x', fallback: 0),
      tileY: _nonNegativeIntAttribute(element, 'y', fallback: 0),
      visible: _boolAttribute(element, 'visible', fallback: true),
      opacity: _opacity(element),
      tintColor: _optionalColorAttribute(element, 'tintcolor'),
      offsetX: _finiteDoubleAttribute(element, 'offsetx', fallback: 0),
      offsetY: _finiteDoubleAttribute(element, 'offsety', fallback: 0),
      parallaxX: _finiteDoubleAttribute(element, 'parallaxx', fallback: 1),
      parallaxY: _finiteDoubleAttribute(element, 'parallaxy', fallback: 1),
      blendMode: _blendMode(element.getAttribute('mode')),
      properties: _parseProperties(
        element,
        context: 'calque $id',
        depth: 0,
      ),
    );
  }

  List<int> _decodeLayerData(
    XmlElement data, {
    required int expectedCellCount,
  }) {
    if (data.findElements('chunk').isNotEmpty) {
      throw const TiledMapImportException(
        'map.tiled.infinite_unsupported',
        'Les chunks de carte infinie ne sont pas pris en charge.',
      );
    }
    final expectedBytes = expectedCellCount * 4;
    _decodedLayerCellCount += expectedCellCount;
    if (_decodedLayerCellCount > limits.maxTotalLayerCells) {
      throw const TiledMapImportException(
        'map.tiled.total_layer_data_limit_exceeded',
        'La somme des cellules de calque dépasse la limite autorisée.',
      );
    }
    if (expectedBytes > limits.maxLayerDataBytes) {
      throw const TiledMapImportException(
        'map.tiled.layer_data_limit_exceeded',
        'Les données décodées du calque dépassent la limite autorisée.',
      );
    }
    final encoding = data.getAttribute('encoding')?.trim();
    final compression = data.getAttribute('compression')?.trim();
    if (encoding == null || encoding.isEmpty) {
      if (compression != null && compression.isNotEmpty) {
        throw const TiledMapImportException(
          'map.tiled.compression_invalid',
          'La compression TMX requiert un encodage base64.',
        );
      }
      final tiles = data.findElements('tile').toList(growable: false);
      if (tiles.length != expectedCellCount) {
        throw const TiledMapImportException(
          'map.tiled.layer_data_size_invalid',
          'Le nombre de tuiles XML ne correspond pas à la grille.',
        );
      }
      return <int>[
        for (final tile in tiles) _parseGid(tile.getAttribute('gid') ?? '0'),
      ];
    }
    if (encoding == 'csv') {
      if (compression != null && compression.isNotEmpty) {
        throw const TiledMapImportException(
          'map.tiled.compression_invalid',
          'Les données CSV TMX ne peuvent pas être compressées.',
        );
      }
      return _decodeCsvGids(
        data.innerText,
        expectedCellCount: expectedCellCount,
      );
    }
    if (encoding != 'base64') {
      throw const TiledMapImportException(
        'map.tiled.layer_encoding_unsupported',
        'L’encodage du calque TMX n’est pas pris en charge.',
      );
    }
    final normalized = data.innerText.replaceAll(RegExp(r'\s+'), '');
    if (normalized.length > limits.maxCompressedLayerBytes * 2) {
      throw const TiledMapImportException(
        'map.tiled.layer_data_limit_exceeded',
        'Le bloc base64 du calque dépasse la limite autorisée.',
      );
    }
    if ((compression == null || compression.isEmpty) &&
        normalized.length > ((expectedBytes + 2) ~/ 3) * 4) {
      throw const TiledMapImportException(
        'map.tiled.layer_data_size_invalid',
        'Le bloc base64 non compressé dépasse la taille de grille attendue.',
      );
    }
    final Uint8List encoded;
    try {
      encoded = base64.decode(normalized);
    } on FormatException {
      throw const TiledMapImportException(
        'map.tiled.layer_data_invalid',
        'Le bloc base64 du calque TMX est invalide.',
      );
    }
    if (encoded.length > limits.maxCompressedLayerBytes) {
      throw const TiledMapImportException(
        'map.tiled.layer_data_limit_exceeded',
        'Le bloc binaire du calque dépasse la limite autorisée.',
      );
    }
    final bytes = switch (compression) {
      null || '' => encoded,
      'gzip' =>
        _decompress(encoded, expectedBytes: expectedBytes, useGzip: true),
      'zlib' =>
        _decompress(encoded, expectedBytes: expectedBytes, useGzip: false),
      'zstd' => throw const TiledMapImportException(
          'map.tiled.compression_unsupported',
          'La compression zstd n’est pas prise en charge en V1.',
        ),
      _ => throw const TiledMapImportException(
          'map.tiled.compression_unsupported',
          'La compression du calque TMX n’est pas prise en charge.',
        ),
    };
    if (bytes.length != expectedBytes) {
      throw const TiledMapImportException(
        'map.tiled.layer_data_size_invalid',
        'La taille binaire du calque ne correspond pas à la grille.',
      );
    }
    final view = ByteData.sublistView(bytes);
    return <int>[
      for (var offset = 0; offset < bytes.length; offset += 4)
        view.getUint32(offset, Endian.little),
    ];
  }

  List<int> _decodeCsvGids(
    String source, {
    required int expectedCellCount,
  }) {
    final result = <int>[];
    var tokenStart = 0;
    for (var index = 0; index <= source.length; index++) {
      final atEnd = index == source.length;
      if (!atEnd && source.codeUnitAt(index) != 0x2c) continue;
      final token = source.substring(tokenStart, index).trim();
      tokenStart = index + 1;
      if (token.isEmpty) {
        if (atEnd && result.length == expectedCellCount) break;
        throw const TiledMapImportException(
          'map.tiled.layer_data_invalid',
          'Les données CSV contiennent une cellule vide.',
        );
      }
      if (result.length >= expectedCellCount) {
        throw const TiledMapImportException(
          'map.tiled.layer_data_size_invalid',
          'Le nombre de GID CSV dépasse la taille de la grille.',
        );
      }
      if (token.length > 10) {
        throw const TiledMapImportException(
          'map.tiled.gid_invalid',
          'Un GID TMX doit être un entier non signé sur 32 bits.',
        );
      }
      result.add(_parseGid(token));
    }
    if (result.length != expectedCellCount) {
      throw const TiledMapImportException(
        'map.tiled.layer_data_size_invalid',
        'Le nombre de GID CSV ne correspond pas à la grille.',
      );
    }
    return result;
  }

  Uint8List _decompress(
    Uint8List encoded, {
    required int expectedBytes,
    required bool useGzip,
  }) {
    final sink = _BoundedLayerByteSink(expectedBytes);
    try {
      final decoder = useGzip
          ? gzip.decoder.startChunkedConversion(sink)
          : zlib.decoder.startChunkedConversion(sink);
      decoder.add(encoded);
      decoder.close();
    } on _TiledLayerOutputOverflow {
      throw const TiledMapImportException(
        'map.tiled.layer_data_size_invalid',
        'Les données décompressées dépassent la taille de grille attendue.',
      );
    } on Object {
      throw const TiledMapImportException(
        'map.tiled.layer_data_invalid',
        'Les données compressées du calque TMX sont invalides.',
      );
    }
    if (sink.length != expectedBytes) {
      throw const TiledMapImportException(
        'map.tiled.layer_data_size_invalid',
        'Les données décompressées ne remplissent pas exactement la grille.',
      );
    }
    return sink.bytes;
  }

  List<TiledProperty> _parseProperties(
    XmlElement owner, {
    required String context,
    required int depth,
  }) {
    final containers = owner.findElements('properties').toList(growable: false);
    if (containers.length > 1) {
      throw TiledMapImportException(
        'map.tiled.properties_duplicate',
        'Le $context contient plusieurs blocs de propriétés.',
      );
    }
    if (containers.isEmpty) return const <TiledProperty>[];
    if (depth >= limits.maxPropertyDepth) {
      throw const TiledMapImportException(
        'map.tiled.property_depth_limit_exceeded',
        'Les propriétés structurées TMX sont trop profondément imbriquées.',
      );
    }
    final names = <String>{};
    final result = <TiledProperty>[];
    for (final property in containers.single.findElements('property')) {
      _propertyCount += 1;
      if (_propertyCount > limits.maxProperties) {
        throw const TiledMapImportException(
          'map.tiled.property_limit_exceeded',
          'La carte TMX contient trop de propriétés.',
        );
      }
      final name = _boundedString(
        property.getAttribute('name')?.trim() ?? '',
        'nom de propriété',
      );
      if (name.isEmpty) {
        throw const TiledMapImportException(
          'map.tiled.property_name_invalid',
          'Une propriété TMX ne possède pas de nom.',
        );
      }
      if (!names.add(name)) {
        throw const TiledMapImportException(
          'map.tiled.property_duplicate',
          'Une propriété TMX est déclarée plusieurs fois.',
        );
      }
      final rawType = property.getAttribute('type')?.trim().toLowerCase();
      final customType = _optionalBoundedString(
        property.getAttribute('propertytype'),
        'type de propriété',
      );
      final rawValue = property.getAttribute('value') ?? property.innerText;
      final TiledPropertyValueType type;
      final Object? value;
      final List<TiledProperty> members;
      switch (rawType == null || rawType.isEmpty ? 'string' : rawType) {
        case 'string':
          type = TiledPropertyValueType.string;
          value = _boundedString(rawValue, 'valeur de propriété');
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
          value = _isColor(canonical) ? canonical : null;
          members = const <TiledProperty>[];
        case 'file':
          type = TiledPropertyValueType.file;
          value = _normalizeDependencyReference(rawValue);
          members = const <TiledProperty>[];
        case 'object':
          type = TiledPropertyValueType.object;
          final parsed = int.tryParse(rawValue.trim());
          value = parsed != null && parsed >= 0 ? parsed : null;
          members = const <TiledProperty>[];
        case 'class':
          type = TiledPropertyValueType.structured;
          value = null;
          members = _parseProperties(
            property,
            context: 'propriété structurée $name',
            depth: depth + 1,
          );
        default:
          throw const TiledMapImportException(
            'map.tiled.property_type_unsupported',
            'Un type de propriété TMX n’est pas pris en charge.',
          );
      }
      if ((type == TiledPropertyValueType.structured &&
              (customType == null || customType.isEmpty)) ||
          (type != TiledPropertyValueType.structured && value == null)) {
        throw const TiledMapImportException(
          'map.tiled.property_value_invalid',
          'Une valeur de propriété TMX est invalide.',
        );
      }
      result.add(
        TiledProperty(
          name: name,
          type: type,
          value: value,
          customType: customType,
          members: members,
        ),
      );
    }
    return result;
  }

  TiledMapTileReference? _resolveGid(
    int rawGid,
    List<TiledMapTilesetReference> tilesets,
  ) {
    final globalTileId = rawGid & _tiledTileIdMask;
    if (globalTileId == 0) {
      if (rawGid != 0) {
        throw const TiledMapImportException(
          'map.tiled.gid_empty_flags_invalid',
          'Un GID vide ne peut pas porter de flags de transformation.',
        );
      }
      return null;
    }
    TiledMapTilesetReference? tileset;
    for (var index = tilesets.length - 1; index >= 0; index--) {
      if (tilesets[index].firstGid <= globalTileId) {
        tileset = tilesets[index];
        break;
      }
    }
    if (tileset == null) {
      throw const TiledMapImportException(
        'map.tiled.gid_tileset_missing',
        'Un GID TMX ne correspond à aucun tileset déclaré.',
      );
    }
    return TiledMapTileReference(
      rawGid: rawGid,
      globalTileId: globalTileId,
      localTileId: globalTileId - tileset.firstGid,
      tileset: tileset,
      flipHorizontally: rawGid & _tiledHorizontalFlag != 0,
      flipVertically: rawGid & _tiledVerticalFlag != 0,
      flipDiagonally: rawGid & _tiledDiagonalFlag != 0,
      hexagonal120Flag: rawGid & _tiledHexagonal120Flag != 0,
    );
  }

  int _parseGid(String raw) {
    final value = int.tryParse(raw.trim());
    if (value == null || value < 0 || value > _tiledMaxUint32) {
      throw const TiledMapImportException(
        'map.tiled.gid_invalid',
        'Un GID TMX doit être un entier non signé sur 32 bits.',
      );
    }
    return value;
  }

  String _normalizeDependencyReference(String raw) {
    final value = raw.trim().replaceAll('\\', '/');
    if (value.startsWith(':/')) {
      throw const TiledMapImportException(
        'map.tiled.internal_dependency_unsupported',
        'Les ressources internes d’automapping Tiled ne sont pas importables.',
      );
    }
    final hasScheme = RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*:').hasMatch(value);
    if (value.isEmpty ||
        value.length > limits.maxStringLength ||
        value.contains('\u0000') ||
        value.startsWith('/') ||
        value.startsWith('//') ||
        hasScheme) {
      throw const TiledMapImportException(
        'map.tiled.dependency_reference_invalid',
        'Une dépendance TMX possède une référence locale invalide.',
      );
    }
    final normalized = <String>[];
    for (final segment in value.split('/')) {
      if (segment.isEmpty || segment == '.') continue;
      if (segment == '..' && normalized.isNotEmpty && normalized.last != '..') {
        normalized.removeLast();
      } else {
        normalized.add(segment);
      }
    }
    if (normalized.isEmpty) {
      throw const TiledMapImportException(
        'map.tiled.dependency_reference_invalid',
        'Une dépendance TMX possède une référence locale invalide.',
      );
    }
    return normalized.join('/');
  }

  String _className(XmlElement element) => _boundedString(
        element.getAttribute('class') ?? element.getAttribute('type') ?? '',
        'classe Tiled',
      );

  String _requiredStringAttribute(XmlElement element, String field) {
    final value = _boundedString(
      element.getAttribute(field)?.trim() ?? '',
      'attribut $field',
    );
    if (value.isEmpty) {
      throw TiledMapImportException(
        'map.tiled.attribute_invalid',
        'L’attribut $field est obligatoire.',
      );
    }
    return value;
  }

  String? _optionalStringAttribute(XmlElement element, String field) =>
      _optionalBoundedString(element.getAttribute(field), 'attribut $field');

  String _boundedString(String value, String field) {
    if (value.length > limits.maxStringLength || value.contains('\u0000')) {
      throw TiledMapImportException(
        'map.tiled.string_limit_exceeded',
        'Le $field dépasse la limite autorisée.',
      );
    }
    return value;
  }

  String? _optionalBoundedString(String? value, String field) {
    final canonical = value?.trim();
    if (canonical == null || canonical.isEmpty) return null;
    return _boundedString(canonical, field);
  }

  int _positiveIntAttribute(XmlElement element, String field) {
    final value = int.tryParse(element.getAttribute(field) ?? '');
    if (value == null || value <= 0) {
      throw TiledMapImportException(
        'map.tiled.number_invalid',
        'L’attribut $field doit être un entier strictement positif.',
      );
    }
    return value;
  }

  int _nonNegativeIntAttribute(
    XmlElement element,
    String field, {
    required int fallback,
  }) {
    final raw = element.getAttribute(field);
    if (raw == null) return fallback;
    final value = int.tryParse(raw);
    if (value == null || value < 0) {
      throw TiledMapImportException(
        'map.tiled.number_invalid',
        'L’attribut $field doit être un entier positif ou nul.',
      );
    }
    return value;
  }

  int? _optionalPositiveIntAttribute(XmlElement element, String field) {
    final raw = element.getAttribute(field);
    if (raw == null) return null;
    return _positiveIntAttribute(element, field);
  }

  double _finiteDoubleAttribute(
    XmlElement element,
    String field, {
    required double fallback,
  }) {
    final raw = element.getAttribute(field);
    if (raw == null) return fallback;
    final value = double.tryParse(raw);
    if (value == null || !value.isFinite) {
      throw TiledMapImportException(
        'map.tiled.number_invalid',
        'L’attribut $field doit être un nombre fini.',
      );
    }
    return value;
  }

  double _opacity(XmlElement element) {
    final value = _finiteDoubleAttribute(element, 'opacity', fallback: 1);
    if (value < 0 || value > 1) {
      throw const TiledMapImportException(
        'map.tiled.opacity_invalid',
        'L’opacité TMX doit être comprise entre 0 et 1.',
      );
    }
    return value;
  }

  bool _boolAttribute(
    XmlElement element,
    String field, {
    required bool fallback,
  }) {
    final raw = element.getAttribute(field);
    if (raw == null) return fallback;
    return switch (raw.trim().toLowerCase()) {
      '1' || 'true' => true,
      '0' || 'false' => false,
      _ => throw TiledMapImportException(
          'map.tiled.boolean_invalid',
          'L’attribut $field doit être un booléen Tiled.',
        ),
    };
  }

  String? _optionalColorAttribute(XmlElement element, String field) {
    final value = element.getAttribute(field)?.trim();
    if (value == null || value.isEmpty) return null;
    if (!_isColor(value)) {
      throw TiledMapImportException(
        'map.tiled.color_invalid',
        'L’attribut $field doit être une couleur Tiled.',
      );
    }
    return value;
  }

  bool _isColor(String value) =>
      RegExp(r'^#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$').hasMatch(value);

  TiledMapRenderOrder _renderOrder(String? value) => switch (value) {
        null || 'right-down' => TiledMapRenderOrder.rightDown,
        'right-up' => TiledMapRenderOrder.rightUp,
        'left-down' => TiledMapRenderOrder.leftDown,
        'left-up' => TiledMapRenderOrder.leftUp,
        _ => throw const TiledMapImportException(
            'map.tiled.render_order_invalid',
            'L’ordre de rendu TMX est invalide.',
          ),
      };

  TiledMapBlendMode _blendMode(String? value) => switch (value) {
        null || '' || 'normal' => TiledMapBlendMode.normal,
        'add' => TiledMapBlendMode.add,
        'multiply' => TiledMapBlendMode.multiply,
        'screen' => TiledMapBlendMode.screen,
        'overlay' => TiledMapBlendMode.overlay,
        'darken' => TiledMapBlendMode.darken,
        'lighten' => TiledMapBlendMode.lighten,
        'color-dodge' => TiledMapBlendMode.colorDodge,
        'color-burn' => TiledMapBlendMode.colorBurn,
        'hard-light' => TiledMapBlendMode.hardLight,
        'soft-light' => TiledMapBlendMode.softLight,
        'difference' => TiledMapBlendMode.difference,
        'exclusion' => TiledMapBlendMode.exclusion,
        _ => throw const TiledMapImportException(
            'map.tiled.blend_mode_invalid',
            'Le mode de fusion TMX est invalide.',
          ),
      };
}

@immutable
final class _TiledLayerCommon {
  const _TiledLayerCommon({
    required this.id,
    required this.name,
    required this.className,
    required this.tileX,
    required this.tileY,
    required this.visible,
    required this.opacity,
    required this.tintColor,
    required this.offsetX,
    required this.offsetY,
    required this.parallaxX,
    required this.parallaxY,
    required this.blendMode,
    required this.properties,
  });

  final int id;
  final String name;
  final String className;
  final int tileX;
  final int tileY;
  final bool visible;
  final double opacity;
  final String? tintColor;
  final double offsetX;
  final double offsetY;
  final double parallaxX;
  final double parallaxY;
  final TiledMapBlendMode blendMode;
  final List<TiledProperty> properties;
}

final class _TiledLayerOutputOverflow implements Exception {
  const _TiledLayerOutputOverflow();
}

final class _BoundedLayerByteSink extends ByteConversionSink {
  _BoundedLayerByteSink(int expectedBytes) : bytes = Uint8List(expectedBytes);

  final Uint8List bytes;
  var length = 0;

  @override
  void add(List<int> chunk) {
    addSlice(chunk, 0, chunk.length, false);
  }

  @override
  void addSlice(List<int> chunk, int start, int end, bool isLast) {
    final count = end - start;
    if (count < 0 || count > bytes.length - length) {
      throw const _TiledLayerOutputOverflow();
    }
    bytes.setRange(length, length + count, chunk, start);
    length += count;
  }

  @override
  void close() {}
}

void _validateLimits(TiledMapParserLimits limits) {
  final values = <int>[
    limits.maxSourceCharacters,
    limits.maxXmlNodes,
    limits.maxMapWidth,
    limits.maxMapHeight,
    limits.maxMapCells,
    limits.maxTotalLayerCells,
    limits.maxTileSize,
    limits.maxTilesets,
    limits.maxLayers,
    limits.maxGroupDepth,
    limits.maxObjects,
    limits.maxProperties,
    limits.maxPropertyDepth,
    limits.maxPoints,
    limits.maxStringLength,
    limits.maxLayerDataBytes,
    limits.maxCompressedLayerBytes,
  ];
  if (values.any((value) => value <= 0)) {
    throw ArgumentError.value(limits, 'limits', 'all limits must be positive');
  }
}
