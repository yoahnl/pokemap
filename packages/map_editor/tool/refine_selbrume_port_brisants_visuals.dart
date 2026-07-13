import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

const int portVisualDivergenceExitCode = 2;
const int portVisualMapWidth = 45;
const int portVisualMapHeight = 34;
const int portVisualMapCellCount = portVisualMapWidth * portVisualMapHeight;
const String portVisualMapId = 'map_port_brisants';
const String portVisualMapRelativePath = 'maps/map_port_brisants.json';
const String portVisualManifestRelativePath =
    'assets/provenance/selbrume_port_reference_v3.json';
const String portPrimaryPathLayerId = 'l_path_primary';

const List<String> portVisualTileLayerIds = <String>[
  'l_tile_port_ref_ground',
  'l_tile_port_ref_backdrop',
  'l_tile_port_ref_overhead',
  'l_tile_port_ref_structures',
];

/// Existing visual composites that are replaced by tiles in the four
/// established visual layers. The refiner never creates a placed element.
const List<String> portVisualReplaceablePlacementIds = <String>[
  'pe_port_garden_backdrop_west',
  'pe_port_garden_backdrop_captain_west',
  'pe_port_garden_backdrop_captain_east',
  'pe_port_garden_backdrop_east_orange',
  'pe_port_garden_backdrop_east_blue',
  'pe_port_flower_bed',
  'pe_port_quay_5',
  'pe_port_quay_17',
  'pe_port_quay_29',
  'pe_port_pier_west',
  'pe_port_pier_center',
  'pe_port_pier_east',
  'pe_port_quay_steps',
  'pe_port_coast_west',
  'pe_port_coast_east',
  'pe_port_foam_quay_west',
  'pe_port_foam_quay_center',
  'pe_port_foam_quay_east',
  'pe_port_foam_wake_medium',
  'pe_port_foam_wake_large',
  'pe_port_foam_wake_small',
  'pe_port_foam_cluster_south',
];

/// The only existing props whose position may be adjusted by this pass.
const List<String> portVisualMovablePropPlacementIds = <String>[
  'pe_port_net_rack_east',
  'pe_port_fish_basket_west',
  'pe_port_fish_basket_east',
  'pe_port_lobster_pots_center',
  'pe_port_barrel_buoy_center',
];

const List<String> requiredPortVisualModuleIds = <String>[
  'module_port_ref_wall_h_short',
  'module_port_ref_wall_h_long',
  'module_port_ref_wall_end_left',
  'module_port_ref_wall_end_right',
  'module_port_ref_garden_gate_open',
  'module_port_ref_flower_bed_compact',
  'module_port_ref_quay_steps_compact',
  'module_port_ref_quay_pier_join',
  'module_port_ref_pier_endcap',
  'module_port_ref_coast_east_complete',
  'module_port_ref_coast_quay_join',
  'module_port_ref_coast_quay_join_mirrored',
  'module_port_ref_foam_h_short',
  'module_port_ref_foam_corner',
  'module_port_ref_foam_wake_short',
];

const List<String> requiredPortVisualEntryIds = <String>[
  'el_port_ref_quay_horizontal',
  'el_port_ref_pier_vertical',
  'el_port_ref_pier_t',
  'el_port_ref_coast_west_continuous',
];

const Set<String> _visualRefinerPropertyKeys = <String>{
  'visualRefinerVersion',
  'visualRefinerManifestSchema',
  'visualRefinerComposition',
  'visualRefinerStatus',
};

final class SelbrumePortVisualRefinerOptions {
  SelbrumePortVisualRefinerOptions({
    required Directory projectRoot,
    this.write = false,
  }) : projectRoot = Directory(p.normalize(p.absolute(projectRoot.path)));

  final Directory projectRoot;
  final bool write;
}

final class SelbrumePortVisualRefinerResult {
  const SelbrumePortVisualRefinerResult({
    required this.exitCode,
    required this.divergentRelativePaths,
    required this.pavementCellCount,
    required this.paintedTileCount,
    required this.removedPlacementCount,
  });

  final int exitCode;
  final List<String> divergentRelativePaths;
  final int pavementCellCount;
  final int paintedTileCount;
  final int removedPlacementCount;
}

final class PortVisualTileModule {
  const PortVisualTileModule({
    required this.id,
    required this.sourceX,
    required this.sourceY,
    required this.width,
    required this.height,
    required this.tileIds,
  });

  final String id;
  final int sourceX;
  final int sourceY;
  final int width;
  final int height;
  final List<int> tileIds;

  int tileIdAt(int x, int y) {
    if (x < 0 || x >= width || y < 0 || y >= height) {
      throw RangeError('Tile coordinate ($x, $y) is outside $id.');
    }
    return tileIds[y * width + x];
  }
}

final class PortVisualModulePlacement {
  const PortVisualModulePlacement({
    required this.group,
    required this.moduleId,
    required this.layerId,
    required this.x,
    required this.y,
  });

  final String group;
  final String moduleId;
  final String layerId;
  final int x;
  final int y;
}

final class _PortVisualEntryPlacement {
  const _PortVisualEntryPlacement({
    required this.entryId,
    required this.layerId,
    required this.x,
    required this.y,
  });

  final String entryId;
  final String layerId;
  final int x;
  final int y;
}

/// Semantic first-pass composition. Keeping the table public makes every
/// manifest dependency and coordinate reviewable without reading imperative
/// painting code.
const List<PortVisualModulePlacement> portVisualComposition =
    <PortVisualModulePlacement>[
  // West house: short stone returns with a deliberate opening at the door.
  PortVisualModulePlacement(
    group: 'west_house_garden',
    moduleId: 'module_port_ref_wall_h_short',
    layerId: 'l_tile_port_ref_backdrop',
    x: 8,
    y: 8,
  ),
  PortVisualModulePlacement(
    group: 'west_house_garden',
    moduleId: 'module_port_ref_wall_end_left',
    layerId: 'l_tile_port_ref_structures',
    x: 11,
    y: 8,
  ),
  PortVisualModulePlacement(
    group: 'west_house_garden',
    moduleId: 'module_port_ref_garden_gate_open',
    layerId: 'l_tile_port_ref_structures',
    x: 13,
    y: 8,
  ),
  PortVisualModulePlacement(
    group: 'west_house_garden',
    moduleId: 'module_port_ref_wall_end_right',
    layerId: 'l_tile_port_ref_structures',
    x: 16,
    y: 8,
  ),

  // Capitainerie: a broad terrace, centered gate and two side returns.
  PortVisualModulePlacement(
    group: 'harbor_master_terrace',
    moduleId: 'module_port_ref_wall_h_long',
    layerId: 'l_tile_port_ref_backdrop',
    x: 18,
    y: 8,
  ),
  PortVisualModulePlacement(
    group: 'harbor_master_terrace',
    moduleId: 'module_port_ref_garden_gate_open',
    layerId: 'l_tile_port_ref_structures',
    x: 23,
    y: 8,
  ),
  PortVisualModulePlacement(
    group: 'harbor_master_terrace',
    moduleId: 'module_port_ref_wall_h_long',
    layerId: 'l_tile_port_ref_backdrop',
    x: 26,
    y: 8,
  ),
  PortVisualModulePlacement(
    group: 'central_square',
    moduleId: 'module_port_ref_flower_bed_compact',
    layerId: 'l_tile_port_ref_ground',
    x: 21,
    y: 12,
  ),

  // Existing dock bodies are repainted tile-only; these modules repair their
  // junctions and remove the former oversized stone-on-wood composite.
  PortVisualModulePlacement(
    group: 'quay_connections',
    moduleId: 'module_port_ref_quay_steps_compact',
    layerId: 'l_tile_port_ref_structures',
    x: 18,
    y: 16,
  ),
  PortVisualModulePlacement(
    group: 'quay_connections',
    moduleId: 'module_port_ref_quay_pier_join',
    layerId: 'l_tile_port_ref_structures',
    x: 8,
    y: 18,
  ),
  PortVisualModulePlacement(
    group: 'quay_connections',
    moduleId: 'module_port_ref_quay_pier_join',
    layerId: 'l_tile_port_ref_structures',
    x: 19,
    y: 18,
  ),
  PortVisualModulePlacement(
    group: 'quay_connections',
    moduleId: 'module_port_ref_quay_pier_join',
    layerId: 'l_tile_port_ref_structures',
    x: 32,
    y: 18,
  ),
  PortVisualModulePlacement(
    group: 'quay_connections',
    moduleId: 'module_port_ref_pier_endcap',
    layerId: 'l_tile_port_ref_structures',
    x: 8,
    y: 28,
  ),
  PortVisualModulePlacement(
    group: 'quay_connections',
    moduleId: 'module_port_ref_pier_endcap',
    layerId: 'l_tile_port_ref_structures',
    x: 19,
    y: 28,
  ),
  PortVisualModulePlacement(
    group: 'quay_connections',
    moduleId: 'module_port_ref_pier_endcap',
    layerId: 'l_tile_port_ref_structures',
    x: 32,
    y: 28,
  ),

  PortVisualModulePlacement(
    group: 'east_coast',
    moduleId: 'module_port_ref_coast_east_complete',
    layerId: 'l_tile_port_ref_structures',
    x: 36,
    y: 20,
  ),
  PortVisualModulePlacement(
    group: 'east_coast',
    moduleId: 'module_port_ref_coast_quay_join',
    layerId: 'l_tile_port_ref_structures',
    x: 36,
    y: 18,
  ),
  PortVisualModulePlacement(
    group: 'east_coast',
    moduleId: 'module_port_ref_coast_quay_join_mirrored',
    layerId: 'l_tile_port_ref_structures',
    x: 3,
    y: 17,
  ),

  // Short local reactions replace the three long mechanical foam strips.
  PortVisualModulePlacement(
    group: 'local_foam',
    moduleId: 'module_port_ref_foam_h_short',
    layerId: 'l_tile_port_ref_ground',
    x: 5,
    y: 20,
  ),
  PortVisualModulePlacement(
    group: 'local_foam',
    moduleId: 'module_port_ref_foam_h_short',
    layerId: 'l_tile_port_ref_ground',
    x: 17,
    y: 20,
  ),
  PortVisualModulePlacement(
    group: 'local_foam',
    moduleId: 'module_port_ref_foam_h_short',
    layerId: 'l_tile_port_ref_ground',
    x: 29,
    y: 20,
  ),
  PortVisualModulePlacement(
    group: 'local_foam',
    moduleId: 'module_port_ref_foam_corner',
    layerId: 'l_tile_port_ref_ground',
    x: 36,
    y: 20,
  ),
  PortVisualModulePlacement(
    group: 'local_foam',
    moduleId: 'module_port_ref_foam_wake_short',
    layerId: 'l_tile_port_ref_ground',
    x: 1,
    y: 26,
  ),
  PortVisualModulePlacement(
    group: 'local_foam',
    moduleId: 'module_port_ref_foam_wake_short',
    layerId: 'l_tile_port_ref_ground',
    x: 22,
    y: 25,
  ),
  PortVisualModulePlacement(
    group: 'local_foam',
    moduleId: 'module_port_ref_foam_wake_short',
    layerId: 'l_tile_port_ref_ground',
    x: 30,
    y: 28,
  ),
];

const List<_PortVisualEntryPlacement> _portVisualEntryComposition =
    <_PortVisualEntryPlacement>[
  _PortVisualEntryPlacement(
    entryId: 'el_port_ref_coast_west_continuous',
    layerId: 'l_tile_port_ref_structures',
    x: 0,
    y: 0,
  ),
  _PortVisualEntryPlacement(
    entryId: 'el_port_ref_quay_horizontal',
    layerId: 'l_tile_port_ref_structures',
    x: 5,
    y: 18,
  ),
  _PortVisualEntryPlacement(
    entryId: 'el_port_ref_quay_horizontal',
    layerId: 'l_tile_port_ref_structures',
    x: 17,
    y: 18,
  ),
  _PortVisualEntryPlacement(
    entryId: 'el_port_ref_quay_horizontal',
    layerId: 'l_tile_port_ref_structures',
    x: 29,
    y: 18,
  ),
  _PortVisualEntryPlacement(
    entryId: 'el_port_ref_pier_vertical',
    layerId: 'l_tile_port_ref_structures',
    x: 8,
    y: 21,
  ),
  _PortVisualEntryPlacement(
    entryId: 'el_port_ref_pier_t',
    layerId: 'l_tile_port_ref_structures',
    x: 18,
    y: 21,
  ),
  _PortVisualEntryPlacement(
    entryId: 'el_port_ref_pier_vertical',
    layerId: 'l_tile_port_ref_structures',
    x: 32,
    y: 21,
  ),
];

SelbrumePortVisualRefinerOptions parseSelbrumePortVisualRefinerOptions(
  List<String> arguments,
) {
  Directory? projectRoot;
  var write = false;
  var modeWasSet = false;
  for (var index = 0; index < arguments.length; index += 1) {
    switch (arguments[index]) {
      case '--project-root':
        if (++index >= arguments.length || arguments[index].trim().isEmpty) {
          throw const FormatException('--project-root requires a path.');
        }
        projectRoot = Directory(arguments[index]);
      case '--write':
        if (modeWasSet) {
          throw const FormatException('Choose exactly one of --check/--write.');
        }
        write = true;
        modeWasSet = true;
      case '--check':
        if (modeWasSet) {
          throw const FormatException('Choose exactly one of --check/--write.');
        }
        write = false;
        modeWasSet = true;
      default:
        throw FormatException('Unknown argument: ${arguments[index]}');
    }
  }
  if (projectRoot == null) {
    throw const FormatException('--project-root is required.');
  }
  return SelbrumePortVisualRefinerOptions(
    projectRoot: projectRoot,
    write: write,
  );
}

List<PortVisualTileModule> parsePortVisualTileModules(
  Map<String, dynamic> manifest,
) {
  final rawModules = manifest['tileModules'];
  if (rawModules is! List) {
    throw const FormatException('Port manifest tileModules must be a list.');
  }
  final modules = <PortVisualTileModule>[];
  final ids = <String>{};
  for (var index = 0; index < rawModules.length; index += 1) {
    final raw = rawModules[index];
    if (raw is! Map) {
      throw FormatException('tileModules[$index] must be an object.');
    }
    final module = Map<String, dynamic>.from(raw);
    final id = module['id'];
    final rawSource = module['source'];
    final rawTileIds = module['tileIds'];
    if (id is! String || id.isEmpty || !ids.add(id)) {
      throw FormatException('tileModules[$index] has an invalid/duplicate id.');
    }
    if (rawSource is! Map || rawTileIds is! List) {
      throw FormatException('$id requires source and row-major tileIds.');
    }
    final source = Map<String, dynamic>.from(rawSource);
    final x = source['x'];
    final y = source['y'];
    final width = source['width'];
    final height = source['height'];
    if (x is! int ||
        y is! int ||
        width is! int ||
        height is! int ||
        x < 0 ||
        y < 0 ||
        width <= 0 ||
        height <= 0) {
      throw FormatException('$id has an invalid source rectangle.');
    }
    final tileIds = <int>[];
    for (final value in rawTileIds) {
      if (value is! int || value <= 0) {
        throw FormatException('$id tileIds must contain positive integers.');
      }
      tileIds.add(value);
    }
    if (tileIds.length != width * height) {
      throw FormatException(
        '$id has ${tileIds.length} tileIds for a $width x $height source.',
      );
    }
    modules.add(
      PortVisualTileModule(
        id: id,
        sourceX: x,
        sourceY: y,
        width: width,
        height: height,
        tileIds: List<int>.unmodifiable(tileIds),
      ),
    );
  }
  return List<PortVisualTileModule>.unmodifiable(modules);
}

List<String> missingPortVisualModuleIds(Map<String, dynamic> manifest) {
  final available =
      parsePortVisualTileModules(manifest).map((module) => module.id).toSet();
  return List<String>.unmodifiable(
    requiredPortVisualModuleIds.where((id) => !available.contains(id)),
  );
}

Map<String, dynamic> buildRefinedPortVisualMap({
  required Map<String, dynamic> mapJson,
  required Map<String, dynamic> manifestJson,
}) {
  _validateMapSurface(mapJson);
  final missingModules = missingPortVisualModuleIds(manifestJson);
  if (missingModules.isNotEmpty) {
    throw StateError(
      'Port visual manifest is missing modules: ${missingModules.join(', ')}',
    );
  }
  final manifestModules = <String, PortVisualTileModule>{
    for (final module in parsePortVisualTileModules(manifestJson))
      module.id: module,
  };
  final entryModules = _parseEntryModules(manifestJson);
  final missingEntries = requiredPortVisualEntryIds
      .where((id) => !entryModules.containsKey(id))
      .toList(growable: false);
  if (missingEntries.isNotEmpty) {
    throw StateError(
      'Port visual manifest is missing source entries: '
      '${missingEntries.join(', ')}',
    );
  }

  final desired = _cloneObject(mapJson);
  _layerById(desired, portPrimaryPathLayerId)['cells'] =
      buildVisualPavementCells();

  for (final layerId in portVisualTileLayerIds) {
    _layerById(desired, layerId)['tiles'] =
        List<int>.filled(portVisualMapCellCount, 0);
  }
  for (final placement in _portVisualEntryComposition) {
    _paintModule(
      map: desired,
      module: entryModules[placement.entryId]!,
      layerId: placement.layerId,
      x: placement.x,
      y: placement.y,
    );
  }
  for (final placement in portVisualComposition) {
    _paintModule(
      map: desired,
      module: manifestModules[placement.moduleId]!,
      layerId: placement.layerId,
      x: placement.x,
      y: placement.y,
    );
  }

  final placements = _objectList(
    desired['placedElements'],
    context: 'Port placedElements',
  );
  placements.removeWhere(
    (entry) => portVisualReplaceablePlacementIds.contains(entry['id']),
  );
  for (final placement in placements) {
    final id = placement['id'];
    final position = _refinedPropPositions[id];
    if (position != null) {
      placement['pos'] = <String, dynamic>{
        'x': position.$1,
        'y': position.$2,
      };
    }
  }
  desired['placedElements'] = placements;

  final properties = _object(
    desired['properties'],
    context: 'Port properties',
  );
  properties
    ..['visualRefinerVersion'] = 1
    ..['visualRefinerManifestSchema'] = manifestJson['schemaVersion'] ?? 1
    ..['visualRefinerComposition'] = 'port_reference_v3_modules'
    ..['visualRefinerStatus'] = 'candidate_pending_owner_approval';
  desired['properties'] = properties;

  verifyOnlyPortVisualChanges(before: mapJson, after: desired);
  return desired;
}

const Map<String, (int, int)> _refinedPropPositions = <String, (int, int)>{
  'pe_port_net_rack_east': (39, 13),
  'pe_port_fish_basket_west': (14, 16),
  'pe_port_fish_basket_east': (35, 17),
  'pe_port_lobster_pots_center': (23, 18),
  'pe_port_barrel_buoy_center': (28, 19),
};

List<bool> buildVisualPavementCells() {
  final cells = List<bool>.filled(portVisualMapCellCount, false);
  for (var y = 0; y < portVisualMapHeight; y += 1) {
    for (var x = 0; x < portVisualMapWidth; x += 1) {
      var painted = false;

      // The real northern connection is centered, so the visual avenue stays
      // centered rather than imitating the reference's north-east exit.
      if (y <= 10 && x >= 26 && x <= 30) painted = true;

      // Broad, slightly irregular village square instead of rectangular loops.
      if (y >= 9 && y <= 18) {
        final left = switch (y) {
          9 || 10 => 7,
          11 || 12 => 6,
          13 || 14 || 15 => 5,
          16 || 17 => 6,
          _ => 8,
        };
        final right = switch (y) {
          9 || 10 => 41,
          11 || 12 || 13 => 42,
          14 || 15 || 16 => 43,
          _ => 41,
        };
        if (x >= left && x <= right) painted = true;
      }

      // Short approaches make every visible northern threshold read clearly.
      if ((x >= 12 && x <= 14 && y >= 6 && y <= 10) ||
          (x >= 31 && x <= 33 && y >= 7 && y <= 10) ||
          (x >= 38 && x <= 40 && y >= 7 && y <= 10)) {
        painted = true;
      }

      // A strong central approach visually connects the square to the quay.
      if (x >= 19 && x <= 28 && y >= 14 && y <= 19) painted = true;

      // Small asymmetric planted islands keep the pavement organic.
      if (_insideEllipse(x, y, centerX: 23, centerY: 13, rx: 2, ry: 1)) {
        painted = false;
      }
      cells[y * portVisualMapWidth + x] = painted;
    }
  }
  return List<bool>.unmodifiable(cells);
}

bool _insideEllipse(
  int x,
  int y, {
  required int centerX,
  required int centerY,
  required int rx,
  required int ry,
}) {
  final dx = x - centerX;
  final dy = y - centerY;
  return dx * dx * ry * ry + dy * dy * rx * rx <= rx * rx * ry * ry;
}

void verifyOnlyPortVisualChanges({
  required Map<String, dynamic> before,
  required Map<String, dynamic> after,
}) {
  _validateMapSurface(before);
  _validateMapSurface(after);

  final beforePlacementIds = _objectList(
    before['placedElements'],
    context: 'before placedElements',
  ).map((entry) => entry['id']).whereType<String>().toSet();
  final afterPlacementIds = _objectList(
    after['placedElements'],
    context: 'after placedElements',
  ).map((entry) => entry['id']).whereType<String>().toList(growable: false);
  if (afterPlacementIds.toSet().length != afterPlacementIds.length ||
      !beforePlacementIds.containsAll(afterPlacementIds)) {
    throw StateError('The visual refiner cannot create placed elements.');
  }
  _verifyReplaceablePlacementsStayIdentical(before: before, after: after);

  final beforeResidue = _visualResidue(before);
  final afterResidue = _visualResidue(after);
  if (_canonicalJson(beforeResidue) != _canonicalJson(afterResidue)) {
    throw StateError('A map value outside the visual whitelist changed.');
  }
}

void _verifyReplaceablePlacementsStayIdentical({
  required Map<String, dynamic> before,
  required Map<String, dynamic> after,
}) {
  final beforeById = <String, Map<String, dynamic>>{
    for (final placement in _objectList(
      before['placedElements'],
      context: 'before placedElements',
    ))
      if (placement['id'] is String) placement['id'] as String: placement,
  };
  for (final placement in _objectList(
    after['placedElements'],
    context: 'after placedElements',
  )) {
    final id = placement['id'];
    if (id is! String || !portVisualReplaceablePlacementIds.contains(id)) {
      continue;
    }
    final original = beforeById[id];
    if (original == null ||
        _canonicalJson(original) != _canonicalJson(placement)) {
      throw StateError(
        'Replaceable placement $id may stay identical or be removed only.',
      );
    }
  }
}

Future<SelbrumePortVisualRefinerResult> refineSelbrumePortBrisantsVisuals(
  SelbrumePortVisualRefinerOptions options,
) async {
  final root = options.projectRoot;
  if (!await root.exists()) {
    throw StateError('Project root does not exist: ${root.path}');
  }
  final mapFile = File(p.join(root.path, portVisualMapRelativePath));
  final manifestFile = File(p.join(root.path, portVisualManifestRelativePath));
  if (!await mapFile.exists() || !await manifestFile.exists()) {
    throw StateError('Port map or visual provenance manifest is missing.');
  }

  final mapJson = _decodeObject(await mapFile.readAsString());
  final manifestJson = _decodeObject(await manifestFile.readAsString());
  final desiredMap = buildRefinedPortVisualMap(
    mapJson: mapJson,
    manifestJson: manifestJson,
  );
  final desiredBytes = _encodeJson(desiredMap);
  final differs = !_sameBytes(await mapFile.readAsBytes(), desiredBytes);

  if (options.write && differs) {
    await _atomicWrite(mapFile, desiredBytes);
  }

  final pavementCellCount =
      buildVisualPavementCells().where((cell) => cell).length;
  var paintedTileCount = 0;
  for (final layerId in portVisualTileLayerIds) {
    paintedTileCount += (_layerById(desiredMap, layerId)['tiles'] as List)
        .where((tileId) => tileId != 0)
        .length;
  }
  final removedPlacementCount = _objectList(
        mapJson['placedElements'],
        context: 'source placedElements',
      ).length -
      _objectList(
        desiredMap['placedElements'],
        context: 'desired placedElements',
      ).length;

  return SelbrumePortVisualRefinerResult(
    exitCode: options.write || !differs ? 0 : portVisualDivergenceExitCode,
    divergentRelativePaths: !options.write && differs
        ? const <String>[portVisualMapRelativePath]
        : const <String>[],
    pavementCellCount: pavementCellCount,
    paintedTileCount: paintedTileCount,
    removedPlacementCount: removedPlacementCount,
  );
}

Map<String, PortVisualTileModule> _parseEntryModules(
  Map<String, dynamic> manifest,
) {
  final atlases = _object(manifest['atlases'], context: 'manifest atlases');
  final sprites = _object(atlases['sprites'], context: 'sprites atlas');
  final atlasWidth = sprites['widthCells'];
  if (atlasWidth is! int || atlasWidth <= 0) {
    throw const FormatException('sprites.widthCells must be positive.');
  }
  final modules = <String, PortVisualTileModule>{};
  for (final entry in _objectList(manifest['entries'], context: 'entries')) {
    final id = entry['id'];
    if (id is! String || !requiredPortVisualEntryIds.contains(id)) continue;
    final source = _object(entry['source'], context: '$id source');
    final x = source['x'];
    final y = source['y'];
    final width = source['width'];
    final height = source['height'];
    if (x is! int ||
        y is! int ||
        width is! int ||
        height is! int ||
        x < 0 ||
        y < 0 ||
        width <= 0 ||
        height <= 0) {
      throw FormatException('$id has an invalid source rectangle.');
    }
    final tileIds = <int>[
      for (var row = 0; row < height; row += 1)
        for (var column = 0; column < width; column += 1)
          (y + row) * atlasWidth + x + column + 1,
    ];
    modules[id] = PortVisualTileModule(
      id: id,
      sourceX: x,
      sourceY: y,
      width: width,
      height: height,
      tileIds: List<int>.unmodifiable(tileIds),
    );
  }
  return modules;
}

void _paintModule({
  required Map<String, dynamic> map,
  required PortVisualTileModule module,
  required String layerId,
  required int x,
  required int y,
}) {
  if (!portVisualTileLayerIds.contains(layerId)) {
    throw StateError('Visual module cannot target layer $layerId.');
  }
  if (x < 0 ||
      y < 0 ||
      x + module.width > portVisualMapWidth ||
      y + module.height > portVisualMapHeight) {
    throw StateError('${module.id} at ($x, $y) exceeds the Port map bounds.');
  }
  final layer = _layerById(map, layerId);
  final tiles = List<int>.from(layer['tiles'] as List);
  for (var row = 0; row < module.height; row += 1) {
    for (var column = 0; column < module.width; column += 1) {
      final tileId = module.tileIdAt(column, row);
      if (tileId != 0) {
        tiles[(y + row) * portVisualMapWidth + x + column] = tileId;
      }
    }
  }
  layer['tiles'] = tiles;
}

void _validateMapSurface(Map<String, dynamic> map) {
  if (map['id'] != portVisualMapId) {
    throw StateError('Expected $portVisualMapId.');
  }
  final size = _object(map['size'], context: 'Port map size');
  if (size['width'] != portVisualMapWidth ||
      size['height'] != portVisualMapHeight) {
    throw StateError(
      'Expected a $portVisualMapWidth x $portVisualMapHeight Port map.',
    );
  }
  final path = _layerById(map, portPrimaryPathLayerId);
  final cells = path['cells'];
  if (cells is! List || cells.length != portVisualMapCellCount) {
    throw StateError('$portPrimaryPathLayerId must expose 1530 cells.');
  }
  for (final layerId in portVisualTileLayerIds) {
    final tiles = _layerById(map, layerId)['tiles'];
    if (tiles is! List || tiles.length != portVisualMapCellCount) {
      throw StateError('$layerId must expose 1530 tiles.');
    }
  }
  _objectList(map['placedElements'], context: 'Port placedElements');
  _object(map['properties'], context: 'Port properties');
}

Map<String, dynamic> _visualResidue(Map<String, dynamic> source) {
  final residue = _cloneObject(source);
  final properties = _object(
    residue['properties'],
    context: 'residue properties',
  );
  for (final key in _visualRefinerPropertyKeys) {
    properties.remove(key);
  }
  residue['properties'] = properties;

  for (final layer in _objectList(residue['layers'], context: 'layers')) {
    final id = layer['id'];
    if (id == portPrimaryPathLayerId) layer.remove('cells');
    if (portVisualTileLayerIds.contains(id)) layer.remove('tiles');
  }
  final placements = _objectList(
    residue['placedElements'],
    context: 'residue placedElements',
  )..removeWhere(
      (entry) => portVisualReplaceablePlacementIds.contains(entry['id']),
    );
  for (final placement in placements) {
    if (portVisualMovablePropPlacementIds.contains(placement['id'])) {
      placement.remove('pos');
    }
  }
  residue['placedElements'] = placements;
  return residue;
}

Map<String, dynamic> _layerById(Map<String, dynamic> map, String id) {
  final matches = _objectList(map['layers'], context: 'Port layers')
      .where((layer) => layer['id'] == id)
      .toList(growable: false);
  if (matches.length != 1) {
    throw StateError('Expected exactly one layer $id.');
  }
  return matches.single;
}

Map<String, dynamic> _object(dynamic value, {required String context}) {
  if (value is! Map) throw FormatException('$context must be an object.');
  return Map<String, dynamic>.from(value);
}

List<Map<String, dynamic>> _objectList(
  dynamic value, {
  required String context,
}) {
  if (value is! List) throw FormatException('$context must be a list.');
  for (var index = 0; index < value.length; index += 1) {
    if (value[index] is! Map<String, dynamic>) {
      throw FormatException('$context[$index] must be an object.');
    }
  }
  return value.cast<Map<String, dynamic>>();
}

Map<String, dynamic> _cloneObject(Map<String, dynamic> value) {
  return _decodeObject(jsonEncode(value));
}

Map<String, dynamic> _decodeObject(String contents) {
  final decoded = jsonDecode(contents);
  if (decoded is! Map) throw const FormatException('Expected a JSON object.');
  return Map<String, dynamic>.from(decoded);
}

String _canonicalJson(dynamic value) {
  if (value is Map) {
    final keys = value.keys.map((key) => key.toString()).toList()..sort();
    return '{${keys.map((key) => '${jsonEncode(key)}:${_canonicalJson(value[key])}').join(',')}}';
  }
  if (value is List) {
    return '[${value.map(_canonicalJson).join(',')}]';
  }
  return jsonEncode(value);
}

Uint8List _encodeJson(Map<String, dynamic> value) {
  return Uint8List.fromList(
    utf8.encode('${const JsonEncoder.withIndent('  ').convert(value)}\n'),
  );
}

bool _sameBytes(List<int> left, List<int> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index += 1) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

Future<void> _atomicWrite(File destination, Uint8List bytes) async {
  await destination.parent.create(recursive: true);
  final temporary = File(
    '${destination.path}.visual-refiner-$pid-${DateTime.now().microsecondsSinceEpoch}.tmp',
  );
  try {
    await temporary.writeAsBytes(bytes, flush: true);
    await temporary.rename(destination.path);
  } finally {
    if (await temporary.exists()) await temporary.delete();
  }
}

Future<void> main(List<String> arguments) async {
  try {
    final options = parseSelbrumePortVisualRefinerOptions(arguments);
    final result = await refineSelbrumePortBrisantsVisuals(options);
    stdout.writeln(
      'Port visual refiner: ${result.pavementCellCount} pavement cells, '
      '${result.paintedTileCount} visual tiles, '
      '${result.removedPlacementCount} replaced placements.',
    );
    if (result.divergentRelativePaths.isNotEmpty) {
      stdout.writeln(
        'Visual refinement required: '
        '${result.divergentRelativePaths.join(', ')}',
      );
    }
    exitCode = result.exitCode;
  } on Object catch (error) {
    stderr.writeln('Port visual refiner failed: $error');
    exitCode = 64;
  }
}
