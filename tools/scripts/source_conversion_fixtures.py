def geometry_policy():
    return {
        'schemaVersion': 1,
        'scene': {'unitsPerCell': 16, 'objectNodePrefixes': ['prop-'],
                  'terrainNodePrefixes': ['ground-'], 'omittedMaterials': {}},
        'ground': {'excludedMaterials': {},
                   'floorRules': [{'kind': 'terrain', 'selector': {'exact': ['copper']}}],
                   'waterRules': [{'selector': {'exact': ['liquid']}, 'maxBoundsY': None}],
                   'minimumNormalY': .45, 'maximumSourceHeight': None,
                   'sideOmissions': {}, 'grassTerrain': {'exact': ['copper']}},
        'models': {'categories': [{'kind': 'building', 'selector': {'exact': ['brick']}}],
                   'omittedMaterials': {}, 'rootMaterials': {}, 'footprintGroups': {},
                   'nonBlockingMaterials': {}},
        'output': {'namespace': 'independent', 'assetDirectory': 'assets/generated',
                   'tags': [], 'cliffSelectors': []},
    }


def rotor_recipe():
    return {'schemaVersion': 1, 'id': 'synthetic-rotor', 'clipName': 'rotation',
            'parentNode': 'root', 'fixedNode': 'static-parts',
            'rotorNodes': ['spindle', 'ring'],
            'cabinNodes': ['pod-' + str(index) for index in range(7)],
            'staticCabinCount': 9, 'cabinMaterials': list(range(5)),
            'frontMaterial': 0, 'connectorMaterial': 3, 'frameRate': 60}


def water_recipe():
    return {
        'schemaVersion': 1, 'id': 'synthetic-water', 'mapId': 'basin',
        'SOURCE_ID': 'synthetic-source', 'ARCHIVE_SHA256': '0' * 64,
        'DAE_SHA256': '1' * 64, 'TEXTURE_SHA256': '2' * 64,
        'SOURCE_ORIGIN': [-24, 0, -33], 'WORLD_HEIGHT': -2.0625,
        'MODULE_SIZES': [[16, 16], [8, 16], [16, 2], [8, 2]],
        'ANIMATION_SHA256': '3' * 64, 'ANIMATION_FRAME_RATE': 60,
        'ANIMATION_SPEED': .5, 'SURFACE_HEIGHT': -.4375,
        'width': 56, 'depth': 82, 'moduleCellSize': 16,
        'modulePrefix': 'basin-backing-', 'waterPrefix': 'basin-water-',
        'surfaceModelId': 'basin-surface', 'label': 'Synthetic water',
        'material': 'liquid', 'clip': 'flow', 'textureSize': [32, 32],
        'uvTransform': [[.25, 0, 0], [0, .25, 1]], 'uvRepeatCells': [4, 4],
        'nativeOriginUv': [-6, -7.25], 'referenceSeabedWorldHeight': -2,
        'sourceToNativeY': 5.25, 'surfaceOpacity': .516129017,
        'excludedMaterialPrefixes': ['foam-', 'ripple-'],
        'excludedMaterials': ['shallow', 'seabed'],
        'animationFrameCount': 240, 'durationSeconds': 4,
        'sourcePolicy': geometry_policy(), 'sourceModelNames': ['sector-a', 'sector-b'],
        'sourceModelFiles': [],
    }
