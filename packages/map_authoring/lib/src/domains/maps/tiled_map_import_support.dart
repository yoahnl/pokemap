part of 'tiled_map_import_actions.dart';

TiledMapDocument _parseMap(String source) {
  try {
    return parseTiledMap(source);
  } on TiledMapImportException catch (error) {
    throw semanticFailure(error.code, error.message);
  }
}

void _requireExactTilesetClosure(
  TiledMapDocument document,
  List<_TiledMapTilesetSpec> specs,
) {
  final expected = document.tilesets.map((item) => item.source).toSet();
  final actual = specs.map((item) => item.source).toSet();
  if (actual.length != specs.length ||
      expected.length != specs.length ||
      !expected.containsAll(actual)) {
    final missing = expected.difference(actual).toList()..sort();
    final unknown = actual.difference(expected).toList()..sort();
    throw semanticFailure(
      'map.tiled.tileset_dependency_mismatch',
      'TSX inputs must exactly match the TMX dependency closure.',
      details: <String, Object?>{
        'missingSources': missing,
        'unknownSources': unknown,
      },
    );
  }
}

void _validateReferencedTileIds(
  TiledMapDocument map,
  List<_PreparedTiledTileset> tilesets,
) {
  final documents = <String, TiledTilesetDocument>{
    for (final item in tilesets) item.source: item.document,
  };
  void validateTile(TiledMapTileReference tile) {
    final document = documents[tile.tileset.source]!;
    final valid = switch (document.layout) {
      TiledRegularAtlasLayout() => tile.localTileId < document.tileCount,
      TiledImageCollectionLayout() =>
        document.tiles.containsKey(tile.localTileId),
    };
    if (!valid) {
      throw semanticFailure(
        'map.tiled.tile_id_out_of_range',
        'The TMX references a tile identity absent from its TSX.',
        details: <String, Object?>{
          'source': tile.tileset.source,
          'localTileId': tile.localTileId,
        },
      );
    }
  }

  void visit(TiledMapLayer layer) {
    switch (layer) {
      case TiledMapTileLayer():
        for (final tile in layer.cells) {
          if (tile != null) {
            validateTile(tile);
          }
        }
      case TiledMapObjectLayer():
        for (final object in layer.objects) {
          if (object.tile case final tile?) {
            validateTile(tile);
          }
        }
      case TiledMapGroupLayer():
        for (final child in layer.layers) {
          visit(child);
        }
    }
  }

  for (final layer in map.layers) {
    visit(layer);
  }
}

void _requireAvailableMapTarget(
  ProjectManifest manifest, {
  required String mapId,
  required String? groupId,
}) {
  if (manifest.maps.any((entry) => entry.id.toLowerCase() == mapId)) {
    throw semanticFailure(
      'map.id_conflict',
      'A map already owns the requested import identity.',
      details: <String, Object?>{'mapId': mapId},
    );
  }
  final path = 'maps/$mapId.json';
  if (manifest.maps.any(
    (entry) => entry.relativePath.toLowerCase() == path.toLowerCase(),
  )) {
    throw semanticFailure(
      'map.path_conflict',
      'A map already owns the requested import document path.',
      details: <String, Object?>{'mapId': mapId},
    );
  }
  if (groupId != null && !manifest.groups.any((group) => group.id == groupId)) {
    throw semanticFailure(
      'map.group_missing',
      'The requested map group does not exist.',
      details: <String, Object?>{'groupId': groupId},
    );
  }
}

String _mapId(String value) {
  if (value.length > 64 ||
      !RegExp(r'^[a-z0-9](?:[a-z0-9_-]*[a-z0-9])?$').hasMatch(value) ||
      _windowsReservedMapIds.contains(value)) {
    throw semanticFailure(
      'map.id_invalid',
      'Map IDs must be portable lowercase filename-safe identifiers.',
      details: <String, Object?>{'mapId': value},
    );
  }
  return value;
}

String _mapName(String value) {
  if (value.length > 160) {
    throw semanticFailure(
      'map.name_invalid',
      'Map names must contain at most 160 characters.',
    );
  }
  return value;
}

MapRole _mapRole(String value) {
  for (final role in MapRole.values) {
    if (role.name == value) return role;
  }
  throw semanticFailure(
    'map.role_invalid',
    'The requested map role is unsupported.',
    details: <String, Object?>{'role': value},
  );
}

List<_TiledMapTilesetSpec> _parseTilesetSpecs(List<Object?> values) =>
    List<_TiledMapTilesetSpec>.unmodifiable(
      <_TiledMapTilesetSpec>[
        for (var index = 0; index < values.length; index++)
          _TiledMapTilesetSpec.fromJson(values[index], index),
      ],
    );

ProjectImageCollectionTilesetSource _imageCollectionSource(
  TiledTilesetDocument document,
  TiledImageCollectionPackingResult packing,
  Map<String, AssetRecord> assetsByPageId,
) {
  final tiles = document.tiles.values.toList()
    ..sort((left, right) => left.tileId.compareTo(right.tileId));
  return ProjectImageCollectionTilesetSource(
    pages: <ProjectImageCollectionPage>[
      for (final page in packing.pages)
        ProjectImageCollectionPage(
          id: page.id,
          assetId: assetsByPageId[page.id]!.id,
          pixelWidth: page.pixelWidth,
          pixelHeight: page.pixelHeight,
        ),
    ],
    tileDefinitions: <ProjectImageCollectionTileDefinition>[
      for (final tile in tiles) _imageCollectionTile(document, packing, tile),
    ],
    properties: _projectProperties(document.properties),
  );
}

ProjectImageCollectionTileDefinition _imageCollectionTile(
  TiledTilesetDocument document,
  TiledImageCollectionPackingResult packing,
  TiledTileMetadata tile,
) {
  final image = tile.image;
  if (image == null) {
    throw semanticFailure(
      'map.tiled.image_reference_missing',
      'Every image collection tile must reference one image.',
      details: <String, Object?>{'tileId': tile.tileId},
    );
  }
  final placement = packing.placementForSource(image.source);
  return ProjectImageCollectionTileDefinition(
    tileId: tile.tileId,
    pageId: placement.pageId,
    sourceRect: placement.sourceRect,
    offsetX: document.tileOffsetX,
    offsetY: document.tileOffsetY,
    animation: <ProjectImageCollectionAnimationFrame>[
      for (final frame in tile.animation)
        ProjectImageCollectionAnimationFrame(
          tileId: frame.tileId,
          durationMs: frame.durationMs,
        ),
    ],
    properties: <ProjectTilesetProperty>[
      ..._projectProperties(tile.properties),
      if (tile.probability != 1)
        ProjectTilesetProperty(
          name: 'tiled:probability',
          type: ProjectTilesetPropertyType.decimal,
          value: tile.probability,
        ),
    ],
    collisionObjects: <ProjectTilesetCollisionObject>[
      for (final object in tile.collisionObjects)
        ProjectTilesetCollisionObject(
          id: object.id,
          name: object.name,
          type: object.className,
          shape: _projectCollisionShape(object.shape),
          x: object.x,
          y: object.y,
          width: object.width,
          height: object.height,
          rotation: object.rotation,
          points: <ProjectTilesetPixelPoint>[
            for (final point in object.points)
              ProjectTilesetPixelPoint(x: point.x, y: point.y),
          ],
          properties: _projectProperties(object.properties),
        ),
    ],
  );
}

List<ProjectTilesetProperty> _projectProperties(
  Iterable<TiledProperty> properties,
) =>
    List<ProjectTilesetProperty>.unmodifiable(
      properties.map(
        (property) => ProjectTilesetProperty(
          name: property.name,
          type: _projectPropertyType(property.type),
          value: _projectPropertyValue(property),
          customType: property.customType,
        ),
      ),
    );

Object? _projectPropertyValue(TiledProperty property) =>
    property.type == TiledPropertyValueType.structured
        ? <String, Object?>{
            for (final member in property.members)
              member.name: _projectPropertyValue(member),
          }
        : property.value;

ProjectTilesetPropertyType _projectPropertyType(TiledPropertyValueType type) =>
    switch (type) {
      TiledPropertyValueType.string => ProjectTilesetPropertyType.string,
      TiledPropertyValueType.integer => ProjectTilesetPropertyType.integer,
      TiledPropertyValueType.decimal => ProjectTilesetPropertyType.decimal,
      TiledPropertyValueType.boolean => ProjectTilesetPropertyType.boolean,
      TiledPropertyValueType.color => ProjectTilesetPropertyType.color,
      TiledPropertyValueType.file => ProjectTilesetPropertyType.assetReference,
      TiledPropertyValueType.object =>
        ProjectTilesetPropertyType.objectReference,
      TiledPropertyValueType.structured =>
        ProjectTilesetPropertyType.structured,
    };

ProjectTilesetCollisionShape _projectCollisionShape(
  TiledCollisionShape shape,
) =>
    switch (shape) {
      TiledCollisionShape.rectangle => ProjectTilesetCollisionShape.rectangle,
      TiledCollisionShape.ellipse => ProjectTilesetCollisionShape.ellipse,
      TiledCollisionShape.polygon => ProjectTilesetCollisionShape.polygon,
      TiledCollisionShape.polyline => ProjectTilesetCollisionShape.polyline,
      TiledCollisionShape.point => ProjectTilesetCollisionShape.point,
    };
