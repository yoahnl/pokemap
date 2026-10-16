const _nativeShapes = <String, Map<String, String?>>{
  'EnvironmentPreset': {
    'id': null,
    'name': null,
    'templateId': null,
    'palette': 'EnvironmentPaletteItem',
    'defaultParams': 'EnvironmentGenerationParams',
    'categoryId': null,
    'sortOrder': null,
  },
  'EnvironmentPaletteItem': {
    'elementId': null,
    'modelId': null,
    'cellOffsetWorld': 'Model3dVector3',
    'weight': null,
    'collisionMode': null,
    'tags': null,
  },
  'EnvironmentGenerationParams': {
    'density': null,
    'variation': null,
    'edgeDensity': null,
    'minSpacingCells': null,
  },
  'Model3dVector3': {'x': null, 'y': null, 'z': null},
  'CharacterAnimation': {
    'state': null,
    'direction': null,
    'sourceAssetId': null,
    'frames': 'CharacterAnimationFrame',
    'loop': null,
  },
  'CharacterAnimationFrame': {
    'source': 'TilesetSourceRect',
    'durationMs': null,
  },
  'CharacterCustomAnimationClip': {
    'definitionId': null,
    'direction': null,
    'sourceAssetId': null,
    'frames': 'CharacterAnimationFrame',
    'loop': null,
  },
  'CharacterCustomAnimationDefinition': {
    'id': null,
    'displayName': null,
    'mode': null,
    'sortOrder': null,
  },
  'CharacterPortraitStateDefinition': {
    'id': null,
    'displayName': null,
    'sortOrder': null,
  },
  'CharacterPortraitVariant': {
    'portraitStateId': null,
    'assetId': null,
    'fitMode': null,
  },
  'ElementCollisionPixelMask': {
    'widthPx': null,
    'heightPx': null,
    'encoding': null,
    'dataBase64': null,
  },
  'ElementCollisionProfile': {
    'source': null,
    'visualMask': 'ElementCollisionPixelMask',
    'pixelMask': 'ElementCollisionPixelMask',
    'occlusionMask': 'ElementCollisionPixelMask',
    'padding': 'WarpTriggerPadding',
    'shapeCells': 'GridPos',
    'cells': 'GridPos',
    'manualAddedCells': 'GridPos',
    'manualRemovedCells': 'GridPos',
  },
  'GridPos': {'x': null, 'y': null},
  'ProjectCharacterEntry': {
    'id': null,
    'name': null,
    'tilesetId': null,
    'frameWidth': null,
    'frameHeight': null,
    'portraits': 'CharacterPortraitVariant',
    'animations': 'CharacterAnimation',
    'customAnimations': 'CharacterCustomAnimationClip',
    'tags': null,
    'sortOrder': null,
  },
  'ProjectCharacterStudioCatalog': {
    'portraitStates': 'CharacterPortraitStateDefinition',
    'customAnimationDefinitions': 'CharacterCustomAnimationDefinition',
  },
  'ProjectElementCategory': {
    'id': null,
    'name': null,
    'parentCategoryId': null,
    'sortOrder': null,
  },
  'ProjectElementEntry': {
    'id': null,
    'name': null,
    'tilesetId': null,
    'categoryId': null,
    'tilesetGroupId': null,
    'frames': 'TilesetVisualFrame',
    'presetKind': null,
    'collisionProfile': 'ElementCollisionProfile',
    'groupId': null,
    'recommendedLayerId': null,
    'tags': null,
    'sortOrder': null,
  },
  'ProjectImageCollectionAnimationFrame': {'tileId': null, 'durationMs': null},
  'ProjectImageCollectionPage': {
    'id': null,
    'assetId': null,
    'pixelWidth': null,
    'pixelHeight': null,
  },
  'ProjectImageCollectionTileDefinition': {
    'tileId': null,
    'pageId': null,
    'sourceRect': 'ProjectTilesetPixelRect',
    'offsetX': null,
    'offsetY': null,
    'animation': 'ProjectImageCollectionAnimationFrame',
    'properties': 'ProjectTilesetProperty',
    'collisionObjects': 'ProjectTilesetCollisionObject',
  },
  'ProjectRegularAtlasTileAnimation': {
    'tileId': null,
    'frames': 'ProjectImageCollectionAnimationFrame',
  },
  'ProjectSmartTileAnimation': {
    'id': null,
    'name': null,
    'frames': 'ProjectSmartTileAnimationFrame',
    'sync': null,
    'loop': null,
  },
  'ProjectSmartTileAnimationFrame': {
    'frame': 'SmartTileFrameRef',
    'durationMs': null,
  },
  'ProjectSmartTileAtlas': {
    'id': null,
    'name': null,
    'tilesetId': null,
    'cellWidth': null,
    'cellHeight': null,
    'originX': null,
    'originY': null,
    'marginX': null,
    'marginY': null,
    'spacingX': null,
    'spacingY': null,
    'columns': null,
    'rows': null,
    'pixelOffsetX': null,
    'pixelOffsetY': null,
  },
  'ProjectSmartTileCategory': {'id': null, 'name': null, 'sortOrder': null},
  'ProjectSmartTileMaterial': {
    'id': null,
    'name': null,
    'connectionGroupId': null,
    'categoryId': null,
    'terrainType': null,
    'pathSurfaceKind': null,
    'isEmpty': null,
    'sortOrder': null,
    'editorColorArgb': null,
  },
  'ProjectSmartTilePattern': {
    'id': null,
    'name': null,
    'categoryId': null,
    'usage': null,
    'width': null,
    'height': null,
    'anchorX': null,
    'anchorY': null,
    'repeatMode': null,
    'cells': 'SmartTilePatternCell',
    'drawOrder': null,
    'tags': null,
    'sortOrder': null,
  },
  'ProjectSmartTilePreset': {
    'id': null,
    'name': null,
    'categoryId': null,
    'usage': null,
    'topology': null,
    'templateHint': null,
    'boundaryPolicy': null,
    'status': null,
    'coveragePolicy': null,
    'coverageProfile': 'SmartTileCoverageProfile',
    'transformPolicy': 'SmartTileTransformPolicy',
    'defaultMaterialId': null,
    'allowedMaterialIds': null,
    'rules': 'SmartTileRule',
    'tags': null,
    'sortOrder': null,
    'seedSalt': null,
    'fallbackRuleId': null,
  },
  'ProjectTilesetCollisionObject': {
    'id': null,
    'name': null,
    'type': null,
    'shape': null,
    'x': null,
    'y': null,
    'width': null,
    'height': null,
    'rotation': null,
    'points': 'ProjectTilesetPixelPoint',
    'properties': 'ProjectTilesetProperty',
  },
  'ProjectTilesetEntry': {
    'id': null,
    'name': null,
    'relativePath': null,
    'source': 'ProjectTilesetSource',
    'scope': null,
    'groupId': null,
    'folderId': null,
    'sortOrder': null,
    'isWorldTileset': null,
    'transparentColor': null,
    'elementGroups': 'TilesetElementGroup',
    'paletteEntries': 'TilesetPaletteEntry',
  },
  'ProjectTilesetFolder': {
    'id': null,
    'name': null,
    'parentFolderId': null,
    'sortOrder': null,
  },
  'ProjectTilesetPixelPoint': {'x': null, 'y': null},
  'ProjectTilesetPixelRect': {
    'x': null,
    'y': null,
    'width': null,
    'height': null,
  },
  'ProjectTilesetProperty': {
    'name': null,
    'type': null,
    'value': null,
    'customType': null,
  },
  'ProjectTilesetSource': {},
  'SmartTileAnimationSource': {'animationId': null},
  'SmartTileCandidate': {
    'id': null,
    'label': null,
    'weight': null,
    'parts': 'SmartTileVisualPart',
  },
  'SmartTileCoverageProfile': {
    'mode': null,
    'requiredScenarios': 'SmartTileCoverageScenario',
    'allowFallback': null,
  },
  'SmartTileCoverageScenario': {
    'id': null,
    'centerMaterialId': null,
    'signature': 'SmartTileExactSignature',
  },
  'SmartTileExactSignature': {
    'northEdge': null,
    'northEastCorner': null,
    'eastEdge': null,
    'southEastCorner': null,
    'southEdge': null,
    'southWestCorner': null,
    'westEdge': null,
    'northWestCorner': null,
  },
  'SmartTileFrameRef': {
    'atlasId': null,
    'column': null,
    'row': null,
    'columnSpan': null,
    'rowSpan': null,
  },
  'SmartTileFrameSource': {'frame': 'SmartTileFrameRef'},
  'SmartTileModel3dSource': {
    'modelId': null,
    'scale': null,
    'offsetX': null,
    'offsetY': null,
    'offsetZ': null,
    'animationIndex': null,
    'followTerrain': null,
    'replacesGround': null,
  },
  'SmartTilePatternCell': {
    'x': null,
    'y': null,
    'parts': 'SmartTileVisualPart',
    'eraseMaterial': null,
    'collision': null,
  },
  'SmartTileRule': {
    'id': null,
    'centerMatch': 'SmartTileSlotMatch',
    'signature': 'SmartTileSignature',
    'candidates': 'SmartTileCandidate',
  },
  'SmartTileSignature': {
    'northWestCorner': 'SmartTileSlotMatch',
    'northEdge': 'SmartTileSlotMatch',
    'northEastCorner': 'SmartTileSlotMatch',
    'eastEdge': 'SmartTileSlotMatch',
    'southEastCorner': 'SmartTileSlotMatch',
    'southEdge': 'SmartTileSlotMatch',
    'southWestCorner': 'SmartTileSlotMatch',
    'westEdge': 'SmartTileSlotMatch',
  },
  'SmartTileSlotMatch': {'kind': null, 'materialId': null},
  'SmartTileSpatialClip': {
    'left': null,
    'top': null,
    'right': null,
    'bottom': null,
  },
  'SmartTileSpriteTransform': {'quarterTurns': null, 'flipX': null},
  'SmartTileTransformPolicy': {
    'allowHFlip': null,
    'allowVFlip': null,
    'allowQuarterTurns': null,
    'preferUntransformed': null,
  },
  'SmartTileVisualPart': {
    'source': 'SmartTileVisualSource',
    'transform': 'SmartTileSpriteTransform',
    'channel': null,
    'frameSampling': null,
    'offsetUnit': null,
    'offsetX': null,
    'offsetY': null,
    'spatialHeightOffset': null,
    'spatialFollowTerrain': null,
    'spatialClip': 'SmartTileSpatialClip',
    'footprintWidth': null,
    'footprintHeight': null,
    'anchorX': null,
    'anchorY': null,
    'drawOrder': null,
  },
  'SmartTileVisualSource': {},
  'TilesetElementGroup': {
    'id': null,
    'name': null,
    'parentGroupId': null,
    'sortOrder': null,
  },
  'TilesetPaletteEntry': {
    'id': null,
    'name': null,
    'category': null,
    'frames': 'TilesetVisualFrame',
    'recommendedLayerId': null,
  },
  'TilesetSourceRect': {'x': null, 'y': null, 'width': null, 'height': null},
  'TilesetVisualFrame': {
    'tilesetId': null,
    'source': 'TilesetSourceRect',
    'durationMs': null,
  },
  'VisualTileProperty': {'tileId': null, 'passable': null, 'tags': null},
  'WarpTriggerPadding': {
    'top': null,
    'right': null,
    'bottom': null,
    'left': null,
  },
};

void validateResourcePackNativeJson(
  Object? value,
  String type, {
  String path = r'$',
}) {
  if (value is! Map<String, dynamic>) {
    throw FormatException('$path: expected $type object');
  }
  _validateScalars(value, type, path);
  if (type == 'ProjectTilesetSource') {
    final kind = value['kind'];
    final shape = switch (kind) {
      'regular_atlas' => <String, String?>{
        'kind': null,
        'assetId': null,
        'pixelWidth': null,
        'pixelHeight': null,
        'tileWidth': null,
        'tileHeight': null,
        'marginX': null,
        'marginY': null,
        'spacingX': null,
        'spacingY': null,
        'pixelOffsetX': null,
        'pixelOffsetY': null,
        'tileProperties': 'VisualTileProperty',
        'tileAnimations': 'ProjectRegularAtlasTileAnimation',
      },
      'image_collection' => <String, String?>{
        'kind': null,
        'pages': 'ProjectImageCollectionPage',
        'tileDefinitions': 'ProjectImageCollectionTileDefinition',
        'properties': 'ProjectTilesetProperty',
      },
      _ => throw FormatException('$path: unsupported tileset source kind'),
    };
    if (kind == 'regular_atlas') {
      _validateScalars(value, 'ProjectRegularAtlasTilesetSource', path);
    }
    _validateShape(value, shape, path);
    return;
  }
  if (type == 'SmartTileVisualSource') {
    final selected = switch (value['kind']) {
      'frame' => 'SmartTileFrameSource',
      'animation' => 'SmartTileAnimationSource',
      'model3d' => 'SmartTileModel3dSource',
      _ => throw FormatException('$path: unsupported visual source'),
    };
    _validateScalars(value, selected, path);
    _validateShape(value, {'kind': null, ..._nativeShapes[selected]!}, path);
    return;
  }
  if (type == 'ProjectTilesetProperty') {
    if (value['type'] == 'structured') {
      throw FormatException('$path: pack.property_reference_unsupported');
    }
    final propertyValue = value['value'];
    final valid = switch (value['type']) {
      'string' => propertyValue is String,
      'integer' || 'object_reference' => propertyValue is int,
      'decimal' => propertyValue is num && propertyValue.isFinite,
      'boolean' => propertyValue is bool,
      'color' =>
        propertyValue is String &&
            RegExp(
              r'^#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$',
            ).hasMatch(propertyValue),
      'asset_reference' =>
        propertyValue is String && propertyValue.trim().isNotEmpty,
      _ => false,
    };
    if (!valid) {
      throw FormatException('$path.value: invalid native property value');
    }
  }
  _validateShape(value, _nativeShapes[type]!, path);
}

void _validateShape(
  Map<String, dynamic> value,
  Map<String, String?> shape,
  String path,
) {
  for (final key in value.keys) {
    if (!shape.containsKey(key)) {
      throw FormatException('$path.$key: unknown portable native field');
    }
    final childType = shape[key];
    final child = value[key];
    if (childType != null && child != null) {
      if (child is List) {
        for (var i = 0; i < child.length; i++) {
          validateResourcePackNativeJson(
            child[i],
            childType,
            path: '$path.$key[$i]',
          );
        }
      } else {
        validateResourcePackNativeJson(child, childType, path: '$path.$key');
      }
    }
  }
}

const _nativeScalars = <String, Map<String, String>>{
  'ProjectRegularAtlasTilesetSource': {
    'assetId': 'string',
    'pixelWidth': 'integer',
    'pixelHeight': 'integer',
    'tileWidth': 'integer',
    'tileHeight': 'integer',
    'marginX': 'integer',
    'marginY': 'integer',
    'spacingX': 'integer',
    'spacingY': 'integer',
    'pixelOffsetX': 'integer',
    'pixelOffsetY': 'integer',
  },
  'CharacterAnimation': {
    'state': 'string',
    'direction': 'string',
    'sourceAssetId': 'string',
    'loop': 'boolean',
  },
  'CharacterAnimationFrame': {'durationMs': 'integer'},
  'CharacterCustomAnimationClip': {
    'definitionId': 'string',
    'direction': 'string',
    'sourceAssetId': 'string',
    'loop': 'boolean',
  },
  'CharacterCustomAnimationDefinition': {
    'id': 'string',
    'displayName': 'string',
    'mode': 'string',
    'sortOrder': 'integer',
  },
  'CharacterPortraitStateDefinition': {
    'id': 'string',
    'displayName': 'string',
    'sortOrder': 'integer',
  },
  'CharacterPortraitVariant': {
    'portraitStateId': 'string',
    'assetId': 'string',
    'fitMode': 'string',
  },
  'ElementCollisionPixelMask': {
    'widthPx': 'integer',
    'heightPx': 'integer',
    'encoding': 'string',
    'dataBase64': 'string',
  },
  'ElementCollisionProfile': {'source': 'string'},
  'EnvironmentGenerationParams': {
    'density': 'number',
    'variation': 'number',
    'edgeDensity': 'number',
    'minSpacingCells': 'integer',
  },
  'EnvironmentPaletteItem': {
    'elementId': 'string',
    'modelId': 'string',
    'weight': 'integer',
    'collisionMode': 'string',
    'tags': 'strings',
  },
  'EnvironmentPreset': {
    'id': 'string',
    'name': 'string',
    'templateId': 'string',
    'categoryId': 'string',
    'sortOrder': 'integer',
  },
  'GridPos': {'x': 'integer', 'y': 'integer'},
  'Model3dVector3': {'x': 'number', 'y': 'number', 'z': 'number'},
  'ProjectCharacterEntry': {
    'id': 'string',
    'name': 'string',
    'tilesetId': 'string',
    'frameWidth': 'integer',
    'frameHeight': 'integer',
    'tags': 'strings',
    'sortOrder': 'integer',
  },
  'ProjectElementCategory': {
    'id': 'string',
    'name': 'string',
    'parentCategoryId': 'string',
    'sortOrder': 'integer',
  },
  'ProjectElementEntry': {
    'id': 'string',
    'name': 'string',
    'tilesetId': 'string',
    'categoryId': 'string',
    'tilesetGroupId': 'string',
    'presetKind': 'string',
    'groupId': 'string',
    'recommendedLayerId': 'string',
    'tags': 'strings',
    'sortOrder': 'integer',
  },
  'ProjectImageCollectionAnimationFrame': {
    'tileId': 'integer',
    'durationMs': 'integer',
  },
  'ProjectImageCollectionPage': {
    'id': 'string',
    'assetId': 'string',
    'pixelWidth': 'integer',
    'pixelHeight': 'integer',
  },
  'ProjectImageCollectionTileDefinition': {
    'tileId': 'integer',
    'pageId': 'string',
    'offsetX': 'integer',
    'offsetY': 'integer',
  },
  'ProjectRegularAtlasTileAnimation': {'tileId': 'integer'},
  'ProjectSmartTileAnimation': {
    'id': 'string',
    'name': 'string',
    'sync': 'string',
    'loop': 'string',
  },
  'ProjectSmartTileAnimationFrame': {'durationMs': 'integer'},
  'ProjectSmartTileAtlas': {
    'id': 'string',
    'name': 'string',
    'tilesetId': 'string',
    'cellWidth': 'integer',
    'cellHeight': 'integer',
    'originX': 'integer',
    'originY': 'integer',
    'marginX': 'integer',
    'marginY': 'integer',
    'spacingX': 'integer',
    'spacingY': 'integer',
    'columns': 'integer',
    'rows': 'integer',
    'pixelOffsetX': 'integer',
    'pixelOffsetY': 'integer',
  },
  'ProjectSmartTileCategory': {
    'id': 'string',
    'name': 'string',
    'sortOrder': 'integer',
  },
  'ProjectSmartTileMaterial': {
    'id': 'string',
    'name': 'string',
    'connectionGroupId': 'string',
    'categoryId': 'string',
    'terrainType': 'string',
    'pathSurfaceKind': 'string',
    'isEmpty': 'boolean',
    'sortOrder': 'integer',
    'editorColorArgb': 'integer',
  },
  'ProjectSmartTilePattern': {
    'id': 'string',
    'name': 'string',
    'categoryId': 'string',
    'usage': 'string',
    'width': 'integer',
    'height': 'integer',
    'anchorX': 'integer',
    'anchorY': 'integer',
    'repeatMode': 'string',
    'drawOrder': 'integer',
    'tags': 'strings',
    'sortOrder': 'integer',
  },
  'ProjectSmartTilePreset': {
    'id': 'string',
    'name': 'string',
    'categoryId': 'string',
    'usage': 'string',
    'topology': 'string',
    'templateHint': 'string',
    'boundaryPolicy': 'string',
    'status': 'string',
    'coveragePolicy': 'string',
    'defaultMaterialId': 'string',
    'allowedMaterialIds': 'strings',
    'tags': 'strings',
    'sortOrder': 'integer',
    'seedSalt': 'integer',
    'fallbackRuleId': 'string',
  },
  'ProjectTilesetCollisionObject': {
    'id': 'integer',
    'name': 'string',
    'type': 'string',
    'shape': 'string',
    'x': 'number',
    'y': 'number',
    'width': 'number',
    'height': 'number',
    'rotation': 'number',
  },
  'ProjectTilesetEntry': {
    'id': 'string',
    'name': 'string',
    'relativePath': 'string',
    'scope': 'string',
    'groupId': 'string',
    'folderId': 'string',
    'sortOrder': 'integer',
    'isWorldTileset': 'boolean',
  },
  'ProjectTilesetFolder': {
    'id': 'string',
    'name': 'string',
    'parentFolderId': 'string',
    'sortOrder': 'integer',
  },
  'ProjectTilesetPixelPoint': {'x': 'number', 'y': 'number'},
  'ProjectTilesetPixelRect': {
    'x': 'integer',
    'y': 'integer',
    'width': 'integer',
    'height': 'integer',
  },
  'ProjectTilesetProperty': {
    'name': 'string',
    'type': 'string',
    'customType': 'string',
  },
  'SmartTileAnimationSource': {'animationId': 'string'},
  'SmartTileCandidate': {
    'id': 'string',
    'label': 'string',
    'weight': 'integer',
  },
  'SmartTileCoverageProfile': {'mode': 'string', 'allowFallback': 'boolean'},
  'SmartTileCoverageScenario': {'id': 'string', 'centerMaterialId': 'string'},
  'SmartTileExactSignature': {
    'northEdge': 'string',
    'northEastCorner': 'string',
    'eastEdge': 'string',
    'southEastCorner': 'string',
    'southEdge': 'string',
    'southWestCorner': 'string',
    'westEdge': 'string',
    'northWestCorner': 'string',
  },
  'SmartTileFrameRef': {
    'atlasId': 'string',
    'column': 'integer',
    'row': 'integer',
    'columnSpan': 'integer',
    'rowSpan': 'integer',
  },
  'SmartTileModel3dSource': {
    'modelId': 'string',
    'scale': 'number',
    'offsetX': 'number',
    'offsetY': 'number',
    'offsetZ': 'number',
    'animationIndex': 'integer',
    'followTerrain': 'boolean',
    'replacesGround': 'boolean',
  },
  'SmartTilePatternCell': {
    'x': 'integer',
    'y': 'integer',
    'eraseMaterial': 'boolean',
    'collision': 'string',
  },
  'SmartTileRule': {'id': 'string'},
  'SmartTileSlotMatch': {'kind': 'string', 'materialId': 'string'},
  'SmartTileSpatialClip': {
    'left': 'number',
    'top': 'number',
    'right': 'number',
    'bottom': 'number',
  },
  'SmartTileSpriteTransform': {'quarterTurns': 'integer', 'flipX': 'boolean'},
  'SmartTileTransformPolicy': {
    'allowHFlip': 'boolean',
    'allowVFlip': 'boolean',
    'allowQuarterTurns': 'boolean',
    'preferUntransformed': 'boolean',
  },
  'SmartTileVisualPart': {
    'channel': 'string',
    'frameSampling': 'string',
    'offsetUnit': 'string',
    'offsetX': 'integer',
    'offsetY': 'integer',
    'spatialHeightOffset': 'number',
    'spatialFollowTerrain': 'boolean',
    'footprintWidth': 'integer',
    'footprintHeight': 'integer',
    'anchorX': 'integer',
    'anchorY': 'integer',
    'drawOrder': 'integer',
  },
  'TilesetElementGroup': {
    'id': 'string',
    'name': 'string',
    'parentGroupId': 'string',
    'sortOrder': 'integer',
  },
  'TilesetPaletteEntry': {
    'id': 'string',
    'name': 'string',
    'category': 'string',
    'recommendedLayerId': 'string',
  },
  'TilesetSourceRect': {
    'x': 'integer',
    'y': 'integer',
    'width': 'integer',
    'height': 'integer',
  },
  'TilesetVisualFrame': {'tilesetId': 'string', 'durationMs': 'integer'},
  'VisualTileProperty': {
    'tileId': 'integer',
    'passable': 'boolean',
    'tags': 'strings',
  },
  'WarpTriggerPadding': {
    'top': 'integer',
    'right': 'integer',
    'bottom': 'integer',
    'left': 'integer',
  },
};

void _validateScalars(Map<String, dynamic> value, String type, String path) {
  for (final entry
      in (_nativeScalars[type] ?? const <String, String>{}).entries) {
    final field = value[entry.key];
    if (field == null) continue;
    final valid = switch (entry.value) {
      'integer' => field is int,
      'number' => field is num && field.isFinite,
      'boolean' => field is bool,
      'string' => field is String,
      'strings' => field is List && field.every((item) => item is String),
      'integers' => field is List && field.every((item) => item is int),
      _ => false,
    };
    if (!valid) {
      throw FormatException(
        '$path.${entry.key}: expected native ${entry.value}',
      );
    }
  }
}
