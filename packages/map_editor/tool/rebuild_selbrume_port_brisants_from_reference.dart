import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/use_cases/tile_layer_environment_generation_use_cases.dart';
import 'package:path/path.dart' as p;

const int selbrumePortReferenceDivergenceExitCode = 2;
const int selbrumePortReferenceWidth = 45;
const int selbrumePortReferenceHeight = 34;
const String selbrumePortReferenceMapRelativePath =
    'maps/map_port_brisants.json';

const String _spriteTilesetId = 'ts_selbrume_port_reference_v3';
const String _groundTilesetId = 'ts_selbrume_port_ground_v3';
const String _waterTilesetId = 'ts_selbrume_port_water_v3';
const String _waterPathPresetId = 'path_selbrume_port_water_v3';
const String _waterPatternPresetId = 'pattern_selbrume_port_water_v3';
const String _forestClusterPresetId = 'env_selbrume_port_clusters_v3';
const String _forestTreePresetId = 'env_selbrume_port_trees_v3';
const String _referenceHash =
    '25fdc9419850028a6e79787ac53dd8e34dcf457ed2d90c1126b5e9b60ecfb219';
const JsonEncoder _prettyJson = JsonEncoder.withIndent('  ');

final class SelbrumePortReferenceRebuildOptions {
  SelbrumePortReferenceRebuildOptions({
    required Directory projectRoot,
    this.write = false,
  }) : projectRoot = Directory(p.normalize(p.absolute(projectRoot.path)));

  final Directory projectRoot;
  final bool write;
}

final class SelbrumePortReferenceRebuildResult {
  const SelbrumePortReferenceRebuildResult({
    required this.exitCode,
    required this.divergentRelativePaths,
    required this.placedElementCount,
    required this.referenceElementCount,
  });

  final int exitCode;
  final List<String> divergentRelativePaths;
  final int placedElementCount;
  final int referenceElementCount;
}

SelbrumePortReferenceRebuildOptions parseSelbrumePortReferenceRebuildOptions(
  List<String> arguments,
) {
  Directory? projectRoot;
  var write = false;
  for (var index = 0; index < arguments.length; index += 1) {
    switch (arguments[index]) {
      case '--project-root':
        if (++index >= arguments.length || arguments[index].trim().isEmpty) {
          throw const FormatException('--project-root requires a path.');
        }
        projectRoot = Directory(arguments[index]);
        break;
      case '--write':
        write = true;
        break;
      case '--check':
        write = false;
        break;
      default:
        throw FormatException('Unknown argument: ${arguments[index]}');
    }
  }
  if (projectRoot == null) {
    throw const FormatException('--project-root is required.');
  }
  return SelbrumePortReferenceRebuildOptions(
    projectRoot: projectRoot,
    write: write,
  );
}

/// Rebuilds only `map_port_brisants` and its Port-v3 catalog entries.
///
/// Existing story identifiers, trigger areas, entities and the reciprocal
/// Bourg connection are treated as protected contracts. The reference image
/// never enters the runtime graph; only normalized native PokeMap data does.
Future<SelbrumePortReferenceRebuildResult>
    rebuildSelbrumePortBrisantsFromReference(
  SelbrumePortReferenceRebuildOptions options,
) async {
  final root = await _validatedProjectRoot(options.projectRoot);
  final projectFile = File(p.join(root.path, 'project.json'));
  final mapFile = File(p.join(root.path, selbrumePortReferenceMapRelativePath));
  final provenanceFile = File(
    p.join(
      root.path,
      'assets',
      'provenance',
      'selbrume_port_reference_v3.json',
    ),
  );
  if (!await mapFile.exists() || !await provenanceFile.exists()) {
    throw StateError('Port map or reference provenance is missing.');
  }

  final projectJson = _decodeObject(await projectFile.readAsString());
  final mapJson = _decodeObject(await mapFile.readAsString());
  final provenanceJson = _decodeObject(await provenanceFile.readAsString());
  final provenanceEntries = _objectList(
    provenanceJson['entries'],
    context: 'Port reference entries',
  );
  if (provenanceEntries.isEmpty) {
    throw StateError('Port reference provenance has no normalized entries.');
  }

  final desiredProject = _buildProject(projectJson, provenanceEntries);
  final manifest = ProjectManifest.fromJson(desiredProject);
  ProjectValidator.validate(manifest);
  final environmentDiagnostics = diagnoseProjectEnvironmentPresets(manifest);
  if (environmentDiagnostics.hasErrors) {
    throw StateError(
      'Port Environment presets have ${environmentDiagnostics.errorCount} '
      'diagnostic errors.',
    );
  }
  var desiredMapModel = MapData.fromJson(_buildPortMap(mapJson));
  MapValidator.validate(desiredMapModel, projectDialogueContext: manifest);
  const environmentGenerations = <(String, String)>[
    ('l_tile_port_ref_backdrop', 'env_port_ref_clusters'),
    ('l_tile_port_ref_backdrop', 'env_port_ref_north_trees'),
    ('l_tile_port_ref_overhead', 'env_port_ref_east_trees'),
  ];
  // Use the editor's real Environment use case, not hand-authored lookalikes,
  // so masks, seeds and generated placement IDs remain editable and stable.
  final generator = GenerateTileLayerEnvironmentAreaPlacementsUseCase();
  for (final generation in environmentGenerations) {
    desiredMapModel = generator
        .execute(
          desiredMapModel,
          manifest: manifest,
          tileLayerId: generation.$1,
          areaId: generation.$2,
        )
        .map;
  }
  MapValidator.validate(desiredMapModel, projectDialogueContext: manifest);
  final authoringDiagnostics = diagnoseProjectEnvironmentAuthoring(
    manifest,
    maps: <MapData>[desiredMapModel],
  );
  if (authoringDiagnostics.hasErrors) {
    throw StateError(
      'Port Environment authoring has ${authoringDiagnostics.errorCount} '
      'diagnostic errors.',
    );
  }
  final desiredMap = desiredMapModel.toJson();

  final desired = <String, Uint8List>{
    'project.json': _encodeJson(desiredProject),
    selbrumePortReferenceMapRelativePath: _encodeJson(desiredMap),
  };
  final divergent = <String>[];
  for (final entry in desired.entries) {
    final file = File(p.join(root.path, entry.key));
    if (!await file.exists() ||
        !_sameBytes(await file.readAsBytes(), entry.value)) {
      divergent.add(entry.key);
    }
  }
  if (options.write) {
    for (final relativePath in <String>[
      selbrumePortReferenceMapRelativePath,
      'project.json',
    ]) {
      await _atomicWrite(
        File(p.join(root.path, relativePath)),
        desired[relativePath]!,
      );
    }
  }

  return SelbrumePortReferenceRebuildResult(
    exitCode: options.write || divergent.isEmpty
        ? 0
        : selbrumePortReferenceDivergenceExitCode,
    divergentRelativePaths:
        options.write ? const <String>[] : List.unmodifiable(divergent),
    placedElementCount: _objectList(
      desiredMap['placedElements'],
      context: 'desired Port placements',
    ).length,
    referenceElementCount: provenanceEntries.length,
  );
}

Map<String, dynamic> _buildProject(
  Map<String, dynamic> project,
  List<Map<String, dynamic>> provenanceEntries,
) {
  _replaceEntries(
    project,
    key: 'tilesets',
    remove: (entry) => const <String>{
      'ts_selbrume_boat',
      'ts_selbrume_open_sea_loop',
      'ts_selbrume_port_props',
      _spriteTilesetId,
      _groundTilesetId,
      _waterTilesetId,
    }.contains(entry['id']),
    replacements: <Map<String, dynamic>>[
      _tileset(
        id: 'ts_selbrume_open_sea_loop',
        name: 'Boucle marine de Selbrume',
        relativePath: 'assets/tilesets/selbrume_open_sea_loop.png',
        sortOrder: 0,
      ),
      _tileset(
        id: _spriteTilesetId,
        name: 'Port des Brisants - Famille visuelle de reference',
        relativePath:
            'assets/tilesets/port_reference_v3/selbrume_port_reference_v3.png',
        sortOrder: 10,
      ),
      _tileset(
        id: _groundTilesetId,
        name: 'Port des Brisants - Sols de reference',
        relativePath:
            'assets/tilesets/port_reference_v3/selbrume_port_ground_v3.png',
        sortOrder: 11,
      ),
      _tileset(
        id: _waterTilesetId,
        name: 'Port des Brisants - Eau animee de reference',
        relativePath:
            'assets/tilesets/port_reference_v3/selbrume_port_water_v3.png',
        sortOrder: 12,
      ),
    ],
  );

  _replaceEntries(
    project,
    key: 'elements',
    remove: (entry) {
      final id = entry['id'];
      return id is String &&
          (id.startsWith('el_selbrume_port_') || id.startsWith('el_port_ref_'));
    },
    replacements: <Map<String, dynamic>>[
      for (var index = 0; index < provenanceEntries.length; index += 1)
        _projectElement(provenanceEntries[index], index),
    ],
  );

  _replaceEntries(
    project,
    key: 'pathPresets',
    remove: (entry) => entry['id'] == _waterPathPresetId,
    replacements: <Map<String, dynamic>>[
      <String, dynamic>{
        'id': _waterPathPresetId,
        'name': 'Eau calme du Port des Brisants',
        'surfaceKind': 'water',
        'categoryId': null,
        'tilesetId': _waterTilesetId,
        'variants': <Object?>[],
        'sortOrder': 210,
      },
    ],
  );
  _replaceEntries(
    project,
    key: 'pathPatternPresets',
    remove: (entry) => const <String>{
      'pp_selbrume_open_sea_loop',
      _waterPatternPresetId,
    }.contains(entry['id']),
    replacements: <Map<String, dynamic>>[
      _legacyOpenSeaPatternPreset(),
      _waterPatternPreset(),
    ],
  );
  _replaceEntries(
    project,
    key: 'environmentPresets',
    remove: (entry) => const <String>{
      _forestClusterPresetId,
      _forestTreePresetId,
    }.contains(entry['id']),
    replacements: <Map<String, dynamic>>[
      _environmentPreset(
        id: _forestClusterPresetId,
        name: 'Lisiere dense du Port des Brisants',
        elementId: 'el_port_ref_forest_cluster',
        sortOrder: 210,
      ),
      _environmentPreset(
        id: _forestTreePresetId,
        name: 'Grands arbres du Port des Brisants',
        elementId: 'el_port_ref_tree',
        sortOrder: 211,
      ),
    ],
  );
  return project;
}

Map<String, dynamic> _tileset({
  required String id,
  required String name,
  required String relativePath,
  required int sortOrder,
}) {
  return <String, dynamic>{
    'id': id,
    'name': name,
    'relativePath': relativePath,
    'scope': 'global',
    'groupId': null,
    'folderId': 'tsf_selbrume_beta_port',
    'sortOrder': sortOrder,
    'isWorldTileset': false,
    'elementGroups': <Object?>[],
    'paletteEntries': <Object?>[],
  };
}

Map<String, dynamic> _projectElement(
  Map<String, dynamic> entry,
  int sortOrder,
) {
  final id = _requiredString(entry, 'id');
  final source = _requiredObject(entry, 'source');
  final collisionIntent = _requiredString(entry, 'collisionIntent');
  final width = _requiredInt(source, 'width');
  final height = _requiredInt(source, 'height');
  return <String, dynamic>{
    'id': id,
    'name': _requiredString(entry, 'name'),
    'tilesetId': _spriteTilesetId,
    'categoryId': 'cat_selbrume_port_props',
    'tilesetGroupId': null,
    'frames': <Object?>[
      <String, dynamic>{
        'tilesetId': '',
        'source': <String, dynamic>{
          'x': _requiredInt(source, 'x'),
          'y': _requiredInt(source, 'y'),
          'width': width,
          'height': height,
        },
        'durationMs': null,
      },
    ],
    'presetKind': 'generic',
    'collisionProfile': _collisionProfile(
      collisionIntent,
      width: width,
      height: height,
    ),
    'shadow': null,
    'groupId': null,
    'recommendedLayerId': entry['recommendedLayerId'],
    'tags': <String>[
      'selbrume',
      'port',
      'map_reference',
      'reference_sha256_$_referenceHash',
      _requiredString(entry, 'category'),
    ],
    'sortOrder': sortOrder,
  };
}

Map<String, dynamic>? _collisionProfile(
  String intent, {
  required int width,
  required int height,
}) {
  final cells = <(int, int)>[];
  switch (intent) {
    case 'solid_building_base':
      for (var y = height - 2; y < height; y += 1) {
        for (var x = 0; x < width; x += 1) {
          cells.add((x, y));
        }
      }
      break;
    case 'solid_shop_base':
      for (var y = height - 3; y < height; y += 1) {
        for (var x = 0; x < width; x += 1) {
          cells.add((x, y));
        }
      }
      break;
    case 'solid_tree_trunk':
      cells.add((width ~/ 2, height - 1));
      break;
    case 'solid_tree_trunks':
      for (final x in <int>[1, width ~/ 2, width - 2]) {
        cells.add((x, height - 1));
      }
      break;
    case 'solid_garden_border':
      for (var x = 0; x < width; x += 1) {
        cells.add((x, 0));
        if (x != width ~/ 2 && x != width ~/ 2 + 1) {
          cells.add((x, height - 1));
        }
      }
      for (var y = 1; y < height - 1; y += 1) {
        cells.add((0, y));
        cells.add((width - 1, y));
      }
      break;
    case 'solid_boat':
    case 'solid_cliff':
    case 'solid_rocks':
      for (var y = 0; y < height; y += 1) {
        for (var x = 0; x < width; x += 1) {
          cells.add((x, y));
        }
      }
      break;
    case 'solid_prop_base':
    case 'solid_furniture_base':
      cells.add((width ~/ 2, height - 1));
      break;
    case 'walkable_deck':
    case 'walkable_steps':
    case 'decorative':
    case 'decorative_interaction':
      return null;
    default:
      throw StateError('Unknown Port collision intent: $intent.');
  }
  final jsonCells = <Map<String, int>>[
    for (final cell in cells) <String, int>{'x': cell.$1, 'y': cell.$2},
  ];
  return <String, dynamic>{
    'source': 'manual',
    'visualMask': null,
    'pixelMask': null,
    'occlusionMask': null,
    'padding': <String, int>{'top': 0, 'right': 0, 'bottom': 0, 'left': 0},
    'shapeCells': jsonCells,
    'cells': jsonCells,
    'manualAddedCells': <Object?>[],
    'manualRemovedCells': <Object?>[],
  };
}

Map<String, dynamic> _waterPatternPreset() {
  return <String, dynamic>{
    'id': _waterPatternPresetId,
    'name': 'Motif anime de la mer du Port des Brisants',
    'basePathPresetId': _waterPathPresetId,
    'centerPattern': <String, dynamic>{
      'size': <String, int>{'width': 8, 'height': 8},
      'cells': <Object?>[
        for (var localY = 0; localY < 8; localY += 1)
          for (var localX = 0; localX < 8; localX += 1)
            <String, dynamic>{
              'localX': localX,
              'localY': localY,
              'frames': <Object?>[
                for (var frame = 0; frame < 8; frame += 1)
                  <String, dynamic>{
                    'tilesetId': _waterTilesetId,
                    'source': <String, int>{
                      'x': frame * 8 + localX,
                      'y': localY,
                      'width': 1,
                      'height': 1,
                    },
                    'durationMs': 180,
                  },
              ],
            },
      ],
    },
    'sortOrder': 210,
  };
}

Map<String, dynamic> _legacyOpenSeaPatternPreset() {
  return <String, dynamic>{
    'id': 'pp_selbrume_open_sea_loop',
    'name': 'Boucle marine ouverte de Selbrume',
    'basePathPresetId': 'nouveau-chemin',
    'centerPattern': <String, dynamic>{
      'size': <String, int>{'width': 2, 'height': 2},
      'cells': <Object?>[
        for (var localY = 0; localY < 2; localY += 1)
          for (var localX = 0; localX < 2; localX += 1)
            <String, dynamic>{
              'localX': localX,
              'localY': localY,
              'frames': <Object?>[
                for (var frame = 0; frame < 32; frame += 1)
                  <String, dynamic>{
                    'tilesetId': 'ts_selbrume_open_sea_loop',
                    'source': <String, int>{
                      'x': frame * 2 + localX,
                      'y': localY,
                      'width': 1,
                      'height': 1,
                    },
                    'durationMs': 100,
                  },
              ],
            },
      ],
    },
    'sortOrder': 0,
  };
}

Map<String, dynamic> _environmentPreset({
  required String id,
  required String name,
  required String elementId,
  required int sortOrder,
}) {
  return <String, dynamic>{
    'id': id,
    'name': name,
    'templateId': 'selbrume_port_reference_forest',
    'palette': <Object?>[
      <String, dynamic>{
        'elementId': elementId,
        'weight': 1,
        'collisionMode': 'useElementDefault',
        'tags': <String>['canopy', 'port_reference'],
      },
    ],
    'defaultParams': <String, dynamic>{
      'density': 1.0,
      'variation': 0.0,
      'edgeDensity': 1.0,
      'minSpacingCells': 0,
    },
    'sortOrder': sortOrder,
    'categoryId': 'cat_selbrume_port_props',
  };
}

/// Produces the complete native layer stack while retaining gameplay payloads.
Map<String, dynamic> _buildPortMap(Map<String, dynamic> previous) {
  if (previous['id'] != 'map_port_brisants') {
    throw StateError('Expected map_port_brisants, got ${previous['id']}.');
  }
  final geographicWater = _waterMask();
  final walkableDocks = _walkableDockMask();
  final water = List<bool>.generate(
    geographicWater.length,
    (index) => geographicWater[index] && !walkableDocks[index],
    growable: false,
  );
  final pavementSource = _sandMask();
  final pavement = List<bool>.generate(
    pavementSource.length,
    (index) => pavementSource[index] && !geographicWater[index],
    growable: false,
  );
  final collisions = _collisionMask(water);
  final groundTiles = List<int>.generate(
    selbrumePortReferenceWidth * selbrumePortReferenceHeight,
    (index) {
      if (water[index]) return 0;
      // Walkable wooden piers still need an opaque sea pixel underneath their
      // transparent sprite gaps; tile 66 is the Port atlas static-water tile.
      if (geographicWater[index] && walkableDocks[index]) return 66;
      final x = index % selbrumePortReferenceWidth;
      final y = index ~/ selbrumePortReferenceWidth;
      return 1 + (y % 8) * 8 + x % 8;
    },
    growable: false,
  );
  final emptyTiles = List<int>.filled(
    selbrumePortReferenceWidth * selbrumePortReferenceHeight,
    0,
    growable: false,
  );
  final semanticTerrain = List<String>.generate(
    selbrumePortReferenceWidth * selbrumePortReferenceHeight,
    (index) => geographicWater[index] ? 'none' : 'grass',
    growable: false,
  );

  final placements = _portPlacements();
  final properties = Map<String, dynamic>.from(
    previous['properties'] is Map
        ? (previous['properties'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{},
  )..addAll(<String, dynamic>{
      'tileLayerOrder': 'bottom_to_top',
      'referenceMapSha256': _referenceHash,
      'referenceRuntimeUnderlay': false,
      'referenceVisualStatus': 'candidate_pending_owner_approval',
      'authoringGenerator':
          'rebuild_selbrume_port_brisants_from_reference.dart',
      'authoringGeneratorVersion': '3',
    });

  return <String, dynamic>{
    'id': 'map_port_brisants',
    'name': previous['name'] ?? 'Port des Brisants',
    'size': <String, int>{
      'width': selbrumePortReferenceWidth,
      'height': selbrumePortReferenceHeight,
    },
    'version': previous['version'] ?? 'v1',
    'tilesetId': '',
    'layers': <Object?>[
      <String, dynamic>{
        'id': 'l_terrain',
        'name': 'Semantique du terrain portuaire',
        'isVisible': false,
        'opacity': 1.0,
        'terrains': semanticTerrain,
        'runtimeType': 'terrain',
      },
      _tileLayer(
        id: 'l_tile_port_ref_base',
        name: 'Sol herbe de reference',
        tilesetId: _groundTilesetId,
        tiles: groundTiles,
      ),
      <String, dynamic>{
        'id': 'l_path_primary',
        'name': 'Chemins paves editables du Port des Brisants',
        'isVisible': true,
        'opacity': 1.0,
        'presetId': 'pavement_path',
        'cells': pavement,
        'properties': <String, String>{
          'visualSource': 'pathPreset:pavement_path',
          // Runtime grouping normally paints paths before tile layers. This
          // explicit opt-in keeps the editable pavement above this grass base
          // while every structure, placed element and shadow remains above it.
          'paintAfterTileLayerId': 'l_tile_port_ref_base',
        },
        'animationMode': 'triggered',
        'animationTriggers': <Object?>[],
        'runtimeType': 'path',
      },
      <String, dynamic>{
        'id': 'l_path_secondary',
        'name': 'Mer animee du Port des Brisants',
        'isVisible': true,
        'opacity': 1.0,
        'presetId': _waterPathPresetId,
        'cells': water,
        'properties': <String, String>{
          'referenceFamily': 'port_reference_v3',
        },
        'animationMode': 'always_active',
        'animationTriggers': <Object?>[],
        'runtimeType': 'path',
      },
      _tileLayer(
        id: 'l_tile_port_ref_ground',
        name: 'Petits decors poses au sol',
        tilesetId: _spriteTilesetId,
        tiles: emptyTiles,
      ),
      _tileLayer(
        id: 'l_tile_port_ref_backdrop',
        name: 'Lisiere forestiere arriere',
        tilesetId: _spriteTilesetId,
        tiles: emptyTiles,
      ),
      _environmentLayer(
        id: 'l_environment_port_ref_north',
        name: 'Environment - lisiere nord',
        targetTileLayerId: 'l_tile_port_ref_backdrop',
        areas: <Map<String, dynamic>>[
          _environmentArea(
            id: 'env_port_ref_clusters',
            name: 'Bosquets denses du nord',
            presetId: _forestClusterPresetId,
            activeCells: const <(int, int)>[
              (5, 0),
              (12, 0),
              (31, 0),
              (34, 0),
            ],
            seed: 1347375700,
          ),
          _environmentArea(
            id: 'env_port_ref_north_trees',
            name: 'Arbres de liaison du nord',
            presetId: _forestTreePresetId,
            activeCells: const <(int, int)>[(18, 0), (21, 0), (40, 0)],
            seed: 1347375701,
          ),
        ],
      ),
      _tileLayer(
        id: 'l_tile_port_ref_overhead',
        name: 'Premier plan vegetal',
        tilesetId: _spriteTilesetId,
        tiles: emptyTiles,
      ),
      _environmentLayer(
        id: 'l_environment_port_ref_east',
        name: 'Environment - rideau vegetal est',
        targetTileLayerId: 'l_tile_port_ref_overhead',
        areas: <Map<String, dynamic>>[
          _environmentArea(
            id: 'env_port_ref_east_trees',
            name: 'Rideau arbore de la peninsule',
            presetId: _forestTreePresetId,
            activeCells: const <(int, int)>[
              (40, 4),
              (40, 8),
              (40, 12),
              (40, 16),
            ],
            seed: 1347375702,
          ),
        ],
      ),
      _tileLayer(
        id: 'l_tile_port_ref_structures',
        name: 'Architecture, quais et mobilier',
        tilesetId: _spriteTilesetId,
        tiles: emptyTiles,
      ),
      <String, dynamic>{
        'id': 'l_collisions',
        'name': 'Collisions du Port des Brisants',
        'isVisible': false,
        'opacity': 1.0,
        'collisions': collisions,
        'runtimeType': 'collision',
      },
    ],
    'placedElements': placements,
    'entities': _repositionEntities(previous['entities']),
    'connections': previous['connections'] ?? <Object?>[],
    'warps': previous['warps'] ?? <Object?>[],
    'triggers': _repositionTriggers(previous['triggers']),
    'gameplayZones': _repositionGameplayZones(previous['gameplayZones']),
    'mapMetadata': previous['mapMetadata'] ?? <String, dynamic>{},
    'properties': properties,
    'events': previous['events'] ?? <Object?>[],
  };
}

Map<String, dynamic> _tileLayer({
  required String id,
  required String name,
  required String tilesetId,
  required List<int> tiles,
}) {
  return <String, dynamic>{
    'id': id,
    'name': name,
    'tilesetId': tilesetId,
    'isVisible': true,
    'opacity': 1.0,
    'tiles': List<int>.from(tiles, growable: false),
    'runtimeType': 'tile',
  };
}

Map<String, dynamic> _environmentLayer({
  required String id,
  required String name,
  required String targetTileLayerId,
  required List<Map<String, dynamic>> areas,
}) {
  return <String, dynamic>{
    'id': id,
    'name': name,
    'isVisible': true,
    'opacity': 1.0,
    'content': <String, dynamic>{
      'targetTileLayerId': targetTileLayerId,
      'areas': areas,
    },
    'properties': <String, String>{
      'referenceFamily': 'port_reference_v3',
    },
    'runtimeType': 'environment',
  };
}

Map<String, dynamic> _environmentArea({
  required String id,
  required String name,
  required String presetId,
  required List<(int, int)> activeCells,
  required int seed,
}) {
  final mask = List<bool>.filled(
    selbrumePortReferenceWidth * selbrumePortReferenceHeight,
    false,
    growable: false,
  );
  for (final cell in activeCells) {
    mask[_index(cell.$1, cell.$2)] = true;
  }
  return <String, dynamic>{
    'id': id,
    'name': name,
    'presetId': presetId,
    'mask': <String, dynamic>{
      'width': selbrumePortReferenceWidth,
      'height': selbrumePortReferenceHeight,
      'cells': mask,
    },
    'seed': seed,
    'paramsOverride': <String, dynamic>{
      'density': 1.0,
      'variation': 0.0,
      'edgeDensity': 1.0,
      'minSpacingCells': 0,
    },
    'generatedPlacementIds': <String>[],
  };
}

List<Map<String, dynamic>> _portPlacements() {
  final placements = <Map<String, dynamic>>[];
  void authored(
    String id,
    String elementId,
    int x,
    int y, {
    String layerId = 'l_tile_port_ref_structures',
    bool applyCollision = true,
    double opacity = 1.0,
    Map<String, String> properties = const <String, String>{},
  }) {
    placements.add(
      _placement(
        id: id,
        elementId: elementId,
        layerId: layerId,
        x: x,
        y: y,
        applyCollision: applyCollision,
        opacity: opacity,
        properties: <String, String>{
          'pokemapPlacementOrigin': 'authored',
          ...properties,
        },
      ),
    );
  }

  authored('pe_port_house_west', 'el_port_ref_house_orange', 10, 4);
  authored('pe_port_capitainerie', 'el_port_ref_harbor_master', 20, 2);
  authored('pe_port_house_blue', 'el_port_ref_house_blue', 29, 5);
  authored('pe_port_house_east', 'el_port_ref_house_orange', 35, 4);
  authored('pe_port_market', 'el_port_ref_fish_market', 10, 11);
  authored('pe_port_hangar', 'el_port_ref_chandlery', 31, 11);

  for (final garden in const <(String, int, int)>[
    ('west', 8, 5),
    ('captain_west', 18, 5),
    ('captain_east', 25, 5),
    ('east_blue', 28, 6),
    ('east_orange', 35, 5),
  ]) {
    authored(
      'pe_port_garden_backdrop_${garden.$1}',
      'el_port_ref_walled_garden',
      garden.$2,
      garden.$3,
      layerId: 'l_tile_port_ref_backdrop',
      applyCollision: false,
    );
  }

  authored(
    'pe_port_flower_bed',
    'el_port_ref_flower_bed',
    21,
    11,
    layerId: 'l_tile_port_ref_ground',
    applyCollision: false,
  );
  authored('pe_port_garden_east', 'el_port_ref_walled_garden', 37, 16);
  authored(
    'pe_port_nid_goelise',
    'el_port_ref_nest',
    7,
    9,
    layerId: 'l_tile_port_ref_ground',
    applyCollision: false,
    properties: const <String, String>{
      'eventId': 'event_goelise_nest_found',
      'reservedForNarrative': 'true',
    },
  );

  for (final position in const <(int, int)>[
    (21, 8),
    (26, 8),
    (18, 12),
    (42, 9),
  ]) {
    authored(
      'pe_port_lamp_${position.$1}_${position.$2}',
      'el_port_ref_lamp',
      position.$1,
      position.$2,
    );
  }
  authored('pe_port_bench_east', 'el_port_ref_bench', 39, 18);
  authored('pe_port_sign_center', 'el_port_ref_sign_small', 19, 15);

  for (final x in <int>[5, 17, 29]) {
    authored(
      'pe_port_quay_$x',
      'el_port_ref_quay_horizontal',
      x,
      18,
      applyCollision: false,
    );
  }
  authored(
    'pe_port_quay_steps',
    'el_port_ref_quay_steps',
    17,
    15,
    applyCollision: false,
  );
  authored(
    'pe_port_pier_west',
    'el_port_ref_pier_vertical',
    8,
    21,
    applyCollision: false,
  );
  authored(
    'pe_port_pier_center',
    'el_port_ref_pier_t',
    18,
    21,
    applyCollision: false,
  );
  authored(
    'pe_port_pier_east',
    'el_port_ref_pier_vertical',
    32,
    21,
    applyCollision: false,
  );
  authored('pe_port_bateau', 'el_port_ref_boat_large', 0, 22);
  authored('pe_port_boat_medium', 'el_port_ref_boat_medium', 22, 21);
  authored('pe_port_boat_small', 'el_port_ref_boat_small', 29, 25);

  for (final prop in const <(String, String, int, int, bool)>[
    ('fish_crates_west', 'el_port_ref_fish_crates_small', 6, 16, true),
    ('fish_crates_pier', 'el_port_ref_fish_crates_small', 10, 23, true),
    ('rope_coil_west', 'el_port_ref_rope_coil_small', 8, 16, true),
    ('rope_coil_pier', 'el_port_ref_rope_coil_small', 23, 26, true),
    ('net_rack_west', 'el_port_ref_net_rack_small', 8, 13, true),
    ('net_rack_east', 'el_port_ref_net_rack_small', 39, 13, false),
    ('fish_basket_west', 'el_port_ref_fish_basket_small', 15, 17, false),
    ('fish_basket_east', 'el_port_ref_fish_basket_small', 34, 18, false),
    ('lobster_pots_center', 'el_port_ref_lobster_pots_small', 24, 18, false),
    ('lobster_pots_pier', 'el_port_ref_lobster_pots_small', 19, 24, true),
    ('barrel_buoy_center', 'el_port_ref_barrel_buoy_small', 27, 19, false),
    ('barrel_buoy_east', 'el_port_ref_barrel_buoy_small', 35, 23, true),
  ]) {
    authored(
      'pe_port_${prop.$1}',
      prop.$2,
      prop.$3,
      prop.$4,
      applyCollision: prop.$5,
    );
  }

  for (final foam in const <(String, String, int, int)>[
    ('quay_west', 'el_port_ref_foam_quay_horizontal', 5, 20),
    ('quay_center', 'el_port_ref_foam_quay_horizontal', 17, 20),
    ('quay_east', 'el_port_ref_foam_quay_horizontal', 29, 20),
    ('cluster_south', 'el_port_ref_foam_rock_cluster', 39, 29),
    ('wake_large', 'el_port_ref_foam_boat_wake', 0, 25),
    ('wake_medium', 'el_port_ref_foam_boat_wake', 21, 24),
    ('wake_small', 'el_port_ref_foam_boat_wake', 29, 27),
  ]) {
    authored(
      'pe_port_foam_${foam.$1}',
      foam.$2,
      foam.$3,
      foam.$4,
      applyCollision: false,
      opacity: 0.65,
    );
  }

  authored(
    'pe_port_coast_west',
    'el_port_ref_coast_west_continuous',
    0,
    0,
    applyCollision: false,
  );
  authored(
    'pe_port_coast_east',
    'el_port_ref_coast_east_peninsula',
    36,
    20,
    applyCollision: false,
  );
  authored('pe_port_rocks_south_east', 'el_port_ref_rock_cluster', 39, 29);

  const smallRocks = <(String, String, int, int)>[
    ('trio_quay_transition', 'el_port_ref_rock_trio', 3, 16),
    ('small_south_west', 'el_port_ref_rock_small', 4, 30),
    ('small_south_mid', 'el_port_ref_rock_small', 11, 31),
    ('pair_south_center', 'el_port_ref_rock_pair', 22, 31),
    ('trio_south_east', 'el_port_ref_rock_trio', 31, 31),
  ];
  for (final rock in smallRocks) {
    authored(
      'pe_port_rock_${rock.$1}',
      rock.$2,
      rock.$3,
      rock.$4,
    );
  }
  placements.sort((left, right) {
    final priority =
        _placementPriority(left).compareTo(_placementPriority(right));
    if (priority != 0) return priority;
    final leftPos = (left['pos'] as Map).cast<String, dynamic>();
    final rightPos = (right['pos'] as Map).cast<String, dynamic>();
    final y = (leftPos['y'] as int).compareTo(rightPos['y'] as int);
    if (y != 0) return y;
    final x = (leftPos['x'] as int).compareTo(rightPos['x'] as int);
    if (x != 0) return x;
    return (left['id'] as String).compareTo(right['id'] as String);
  });
  return placements;
}

int _placementPriority(Map<String, dynamic> placement) {
  final elementId = placement['elementId'] as String;
  if (elementId.contains('foam')) return -20;
  if (elementId.contains('coast_')) return -15;
  if (elementId.contains('rock')) return -10;
  if (elementId.contains('cliff')) return 0;
  if (elementId.contains('house') ||
      elementId.contains('harbor_master') ||
      elementId.contains('market') ||
      elementId.contains('chandlery')) {
    return 10;
  }
  if (elementId.contains('garden') || elementId.contains('flower')) return 20;
  if (elementId.contains('quay_steps')) return 35;
  if (elementId.contains('quay') || elementId.contains('pier')) return 30;
  if (elementId.contains('boat')) return 40;
  return 50;
}

Map<String, dynamic> _placement({
  required String id,
  required String elementId,
  required String layerId,
  required int x,
  required int y,
  required bool applyCollision,
  required double opacity,
  required Map<String, String> properties,
}) {
  return <String, dynamic>{
    'id': id,
    'layerId': layerId,
    'elementId': elementId,
    'pos': <String, int>{'x': x, 'y': y},
    'applyCollision': applyCollision,
    'opacity': opacity,
    'animation': null,
    'shadowOverride': null,
    'behaviors': <Object?>[],
    'properties': properties,
  };
}

List<bool> _waterMask() {
  final mask = List<bool>.filled(
    selbrumePortReferenceWidth * selbrumePortReferenceHeight,
    false,
    growable: false,
  );
  void fill(int yStart, int yEnd, int xStart, int xEnd) {
    for (var y = yStart; y <= yEnd; y += 1) {
      for (var x = xStart; x <= xEnd; x += 1) {
        mask[_index(x, y)] = true;
      }
    }
  }

  fill(0, 6, 0, 4);
  fill(7, 9, 0, 5);
  fill(10, 10, 0, 6);
  fill(11, 18, 0, 5);
  fill(19, 22, 0, 34);
  fill(23, 23, 0, 35);
  fill(24, 24, 0, 39);
  fill(25, 33, 0, 44);
  return mask;
}

List<bool> _sandMask() {
  final mask = List<bool>.filled(
    selbrumePortReferenceWidth * selbrumePortReferenceHeight,
    false,
    growable: false,
  );
  void run(int yStart, int yEnd, int xStart, int xEnd) {
    for (var y = yStart; y <= yEnd; y += 1) {
      for (var x = xStart; x <= xEnd; x += 1) {
        mask[_index(x, y)] = true;
      }
    }
  }

  run(0, 2, 26, 30);
  run(3, 3, 27, 31);
  run(3, 3, 40, 44);
  run(4, 6, 28, 31);
  run(4, 6, 38, 41);
  run(7, 8, 12, 14);
  run(7, 8, 23, 25);
  run(7, 8, 28, 33);
  run(7, 8, 37, 41);
  run(9, 9, 7, 41);
  run(10, 10, 6, 41);
  run(11, 11, 6, 9);
  run(11, 11, 18, 30);
  run(11, 11, 39, 41);
  run(12, 14, 6, 9);
  run(12, 14, 26, 30);
  run(12, 14, 39, 41);
  run(15, 15, 6, 9);
  run(15, 15, 17, 30);
  run(15, 15, 39, 41);
  run(16, 16, 6, 9);
  run(16, 16, 18, 36);
  run(16, 16, 44, 44);
  run(17, 18, 6, 44);
  run(19, 20, 35, 44);
  run(21, 22, 37, 44);
  run(23, 23, 36, 44);
  run(24, 24, 40, 44);
  return mask;
}

List<bool> _walkableDockMask() {
  final mask = List<bool>.filled(
    selbrumePortReferenceWidth * selbrumePortReferenceHeight,
    false,
    growable: false,
  );
  void fill(int xStart, int yStart, int xEnd, int yEnd) {
    for (var y = yStart; y <= yEnd; y += 1) {
      for (var x = xStart; x <= xEnd; x += 1) {
        mask[_index(x, y)] = true;
      }
    }
  }

  fill(5, 19, 40, 21);
  fill(18, 15, 22, 21);
  fill(9, 21, 11, 29);
  fill(19, 21, 25, 23);
  fill(21, 24, 23, 29);
  fill(33, 21, 35, 29);
  return mask;
}

List<bool> _collisionMask(List<bool> water) {
  final mask = List<bool>.from(water, growable: false);
  void setRect(
    int xStart,
    int yStart,
    int xEnd,
    int yEnd,
    bool value,
  ) {
    for (var y = yStart; y <= yEnd; y += 1) {
      for (var x = xStart; x <= xEnd; x += 1) {
        if (x >= 0 &&
            y >= 0 &&
            x < selbrumePortReferenceWidth &&
            y < selbrumePortReferenceHeight) {
          mask[_index(x, y)] = value;
        }
      }
    }
  }

  // Quais et pontons : surfaces marchables explicitement creusées dans l'eau.
  setRect(5, 19, 40, 21, false);
  setRect(18, 15, 22, 21, false);
  setRect(9, 21, 11, 29, false);
  setRect(19, 21, 25, 23, false);
  setRect(21, 24, 23, 29, false);
  setRect(33, 21, 35, 29, false);

  // Bases des six bâtiments, conformes aux footprints de la composition.
  setRect(20, 6, 27, 7, true);
  setRect(10, 7, 16, 8, true);
  setRect(29, 8, 35, 9, true);
  setRect(35, 7, 41, 8, true);
  setRect(10, 14, 17, 16, true);
  setRect(31, 14, 38, 16, true);

  // La lèvre arrière du quai protège la falaise, sauf au grand escalier.
  setRect(5, 18, 40, 18, true);
  setRect(18, 18, 22, 18, false);

  // Jardin clos est : deux cellules d'entrée restent libres au sud.
  setRect(37, 16, 37, 20, true);
  setRect(43, 16, 43, 20, true);
  setRect(37, 20, 39, 20, true);
  setRect(42, 20, 43, 20, true);
  setRect(40, 20, 41, 20, false);

  // Troncs Environment. Les couronnes se chevauchent pour former une vraie
  // lisiere, mais seules les bases bloquent le joueur.
  for (final point in const <(int, int)>[
    (6, 6),
    (10, 6),
    (14, 6),
    (13, 6),
    (17, 6),
    (21, 6),
    (32, 6),
    (36, 6),
    (40, 6),
    (35, 6),
    (39, 6),
    (43, 6),
    (20, 5),
    (23, 5),
    (42, 5),
    (42, 9),
    (42, 13),
    (42, 17),
    (42, 21),
  ]) {
    mask[_index(point.$1, point.$2)] = true;
  }

  // Mobilier portuaire : empreintes étroites pour conserver une circulation claire.
  for (final point in const <(int, int)>[
    (21, 10),
    (26, 10),
    (18, 14),
    (42, 11),
    (40, 19),
    (20, 16),
    (8, 18),
    (14, 19),
    (28, 21),
    (23, 29),
  ]) {
    mask[_index(point.$1, point.$2)] = true;
  }

  // La mer bloque deja le cote eau. Seule la premiere cellule de terre de la
  // cote naturelle reste solide, afin de suivre les rochers sans condamner
  // une large bande de pelouse comme les anciennes falaises rectangulaires.
  setRect(5, 0, 5, 6, true);
  setRect(6, 7, 6, 9, true);
  setRect(7, 10, 7, 10, true);
  setRect(6, 11, 6, 17, true);
  setRect(35, 22, 35, 22, true);
  setRect(36, 23, 39, 23, true);
  setRect(40, 24, 44, 24, true);
  setRect(39, 29, 44, 32, true);
  for (final rect in const <(int, int, int, int)>[
    (4, 30, 4, 30),
    (11, 31, 11, 31),
    (22, 31, 23, 32),
    (31, 31, 33, 32),
  ]) {
    setRect(rect.$1, rect.$2, rect.$3, rect.$4, true);
  }

  // Le couloir nord et l'aire de rival sont des vides intentionnels.
  setRect(26, 0, 30, 1, false);
  setRect(23, 15, 30, 17, false);
  final walkableDocks = _walkableDockMask();
  for (var index = 0; index < mask.length; index += 1) {
    if (walkableDocks[index]) mask[index] = false;
  }
  setRect(5, 18, 40, 18, true);
  setRect(18, 18, 22, 18, false);
  return mask;
}

List<Map<String, dynamic>> _repositionEntities(Object? raw) {
  final entities = _objectList(raw, context: 'Port entities');
  final desired = <String, (int, int)>{
    'anchor_port_lysa': (26, 16),
    'anchor_port_soline': (39, 10),
    'anchor_port_pecheurs': (13, 17),
  };
  for (final entry in desired.entries) {
    final entity = _singleById(entities, entry.key, context: 'Port entity');
    entity['pos'] = <String, int>{
      'x': entry.value.$1,
      'y': entry.value.$2,
    };
  }
  return entities;
}

List<Map<String, dynamic>> _repositionTriggers(Object? raw) {
  final triggers = _objectList(raw, context: 'Port triggers');
  _setArea(triggers, 'zone_port_entry', 26, 0, 5, 4, 'Port trigger');
  _setArea(triggers, 'zone_port_center', 17, 10, 14, 8, 'Port trigger');
  _setArea(triggers, 'tr_port_rival_scene', 23, 15, 8, 3, 'Port trigger');
  _setArea(triggers, 'tr_port_nest', 7, 9, 2, 2, 'Port trigger');
  return triggers;
}

List<Map<String, dynamic>> _repositionGameplayZones(Object? raw) {
  final zones = _objectList(raw, context: 'Port gameplay zones');
  _setArea(zones, 'zone_port_entry', 26, 0, 5, 4, 'Port gameplay zone');
  _setArea(zones, 'zone_port_center', 17, 10, 14, 8, 'Port gameplay zone');
  return zones;
}

void _setArea(
  List<Map<String, dynamic>> entries,
  String id,
  int x,
  int y,
  int width,
  int height,
  String context,
) {
  final entry = _singleById(entries, id, context: context);
  entry['area'] = <String, dynamic>{
    'pos': <String, int>{'x': x, 'y': y},
    'size': <String, int>{'width': width, 'height': height},
  };
}

Map<String, dynamic> _singleById(
  List<Map<String, dynamic>> entries,
  String id, {
  required String context,
}) {
  final matches = entries.where((entry) => entry['id'] == id).toList();
  if (matches.length != 1) {
    throw StateError('$context $id must exist exactly once.');
  }
  return matches.single;
}

void _replaceEntries(
  Map<String, dynamic> object, {
  required String key,
  required bool Function(Map<String, dynamic>) remove,
  required List<Map<String, dynamic>> replacements,
}) {
  final existing = _objectList(object[key], context: 'project $key');
  object[key] = <Object?>[
    for (final entry in existing)
      if (!remove(entry)) entry,
    ...replacements,
  ];
}

int _index(int x, int y) => y * selbrumePortReferenceWidth + x;

Future<Directory> _validatedProjectRoot(Directory root) async {
  if (!await File(p.join(root.path, 'project.json')).exists()) {
    throw StateError('Not a Selbrume project root: ${root.path}.');
  }
  return root;
}

Map<String, dynamic> _decodeObject(String source) {
  final decoded = jsonDecode(source);
  if (decoded is! Map) throw const FormatException('Expected a JSON object.');
  return decoded.cast<String, dynamic>();
}

List<Map<String, dynamic>> _objectList(
  Object? value, {
  required String context,
}) {
  if (value is! List) throw FormatException('$context must be a JSON list.');
  return <Map<String, dynamic>>[
    for (final entry in value)
      if (entry is Map)
        entry.map((key, value) => MapEntry(key.toString(), value))
      else
        throw FormatException('$context contains a non-object entry.'),
  ];
}

Map<String, dynamic> _requiredObject(
  Map<String, dynamic> object,
  String key,
) {
  final value = object[key];
  if (value is! Map) throw FormatException('$key must be a JSON object.');
  return value.map((key, value) => MapEntry(key.toString(), value));
}

String _requiredString(Map<String, dynamic> object, String key) {
  final value = object[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('$key must be a non-empty string.');
  }
  return value;
}

int _requiredInt(Map<String, dynamic> object, String key) {
  final value = object[key];
  if (value is! int) throw FormatException('$key must be an integer.');
  return value;
}

Uint8List _encodeJson(Map<String, dynamic> object) {
  return Uint8List.fromList(utf8.encode('${_prettyJson.convert(object)}\n'));
}

bool _sameBytes(List<int> left, List<int> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index += 1) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

Future<void> _atomicWrite(File target, Uint8List bytes) async {
  await target.parent.create(recursive: true);
  final temporary = File('${target.path}.port-reference-v3.tmp');
  await temporary.writeAsBytes(bytes, flush: true);
  if (await target.exists()) await target.delete();
  await temporary.rename(target.path);
}

Future<void> main(List<String> arguments) async {
  try {
    final options = parseSelbrumePortReferenceRebuildOptions(arguments);
    final result = await rebuildSelbrumePortBrisantsFromReference(options);
    if (result.divergentRelativePaths.isEmpty) {
      stdout.writeln(
        'Port des Brisants reference rebuild is up to date '
        '(${result.placedElementCount} placements, '
        '${result.referenceElementCount} reference elements).',
      );
    } else {
      stderr.writeln('Port des Brisants reference divergence:');
      for (final path in result.divergentRelativePaths) {
        stderr.writeln('  $path');
      }
    }
    exitCode = result.exitCode;
  } catch (error, stackTrace) {
    stderr.writeln('Port des Brisants reference rebuild failed: $error');
    stderr.writeln(stackTrace);
    exitCode = 1;
  }
}
