# FG-181 — Annexe : contenu complet des fichiers créés

Cette annexe reproduit intégralement les fichiers texte et source créés par le lot.
Les PNG et le manifeste d’audit généré sont des artefacts binaires/volumineux
référencés par chemin et hash dans le rapport principal.

## `packages/map_editor/tool/refine_selbrume_port_brisants_visuals.dart`

~~~~dart
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
~~~~

## `packages/map_editor/test/selbrume_port_visual_contract_freeze_test.dart`

~~~~dart
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import '../tool/refine_selbrume_port_brisants_visuals.dart';

void main() {
  test('accepts only the declared visual refinement surface', () {
    final before = _fixtureMap();
    final after = _clone(before);

    _layer(after, portPrimaryPathLayerId)['cells'] = List<bool>.filled(
      portVisualMapCellCount,
      true,
    );
    for (final layerId in portVisualTileLayerIds) {
      _layer(after, layerId)['tiles'] = List<int>.filled(
        portVisualMapCellCount,
        7,
      );
    }
    (after['placedElements'] as List).removeWhere(
      (entry) => portVisualReplaceablePlacementIds.contains(
        (entry as Map)['id'],
      ),
    );
    (after['properties'] as Map<String, dynamic>)
      ..['visualRefinerVersion'] = 1
      ..['visualRefinerManifestSchema'] = 1
      ..['visualRefinerComposition'] = 'port_reference_v3_modules'
      ..['visualRefinerStatus'] = 'candidate_pending_owner_approval';

    expect(
      () => verifyOnlyPortVisualChanges(before: before, after: after),
      returnsNormally,
    );
  });

  test('rejects a change outside the visual whitelist', () {
    final before = _fixtureMap();
    final after = _clone(before)..['name'] = 'Renamed';

    expect(
      () => verifyOnlyPortVisualChanges(before: before, after: after),
      throwsStateError,
    );
  });

  test('rejects a non-cell change on the pavement layer', () {
    final before = _fixtureMap();
    final after = _clone(before);
    _layer(after, portPrimaryPathLayerId)['opacity'] = 0.5;

    expect(
      () => verifyOnlyPortVisualChanges(before: before, after: after),
      throwsStateError,
    );
  });

  test('rejects movement of a protected placement', () {
    final before = _fixtureMap();
    final after = _clone(before);
    final protected = (after['placedElements'] as List)
        .cast<Map<String, dynamic>>()
        .singleWhere((entry) => entry['id'] == 'pe_port_protected');
    protected['pos'] = <String, dynamic>{'x': 4, 'y': 4};

    expect(
      () => verifyOnlyPortVisualChanges(before: before, after: after),
      throwsStateError,
    );
  });

  test('rejects undeclared visualRefiner metadata', () {
    final before = _fixtureMap();
    final after = _clone(before);
    (after['properties'] as Map<String, dynamic>)['visualRefinerUnknown'] =
        true;

    expect(
      () => verifyOnlyPortVisualChanges(before: before, after: after),
      throwsStateError,
    );
  });
}

Map<String, dynamic> _fixtureMap() {
  return <String, dynamic>{
    'id': portVisualMapId,
    'name': 'Port des Brisants',
    'size': <String, dynamic>{
      'width': portVisualMapWidth,
      'height': portVisualMapHeight,
    },
    'properties': <String, dynamic>{'authoringGenerator': 'fixture'},
    'layers': <Map<String, dynamic>>[
      <String, dynamic>{
        'id': portPrimaryPathLayerId,
        'runtimeType': 'path',
        'opacity': 1.0,
        'cells': List<bool>.filled(portVisualMapCellCount, false),
      },
      for (final id in portVisualTileLayerIds)
        <String, dynamic>{
          'id': id,
          'runtimeType': 'tile',
          'opacity': 1.0,
          'tiles': List<int>.filled(portVisualMapCellCount, 0),
        },
      <String, dynamic>{
        'id': 'l_visual_protected',
        'runtimeType': 'tile',
        'tiles': List<int>.filled(portVisualMapCellCount, 0),
      },
    ],
    'placedElements': <Map<String, dynamic>>[
      <String, dynamic>{
        'id': portVisualReplaceablePlacementIds.first,
        'pos': <String, dynamic>{'x': 1, 'y': 1},
      },
      <String, dynamic>{
        'id': portVisualMovablePropPlacementIds.first,
        'pos': <String, dynamic>{'x': 2, 'y': 2},
      },
      <String, dynamic>{
        'id': 'pe_port_protected',
        'pos': <String, dynamic>{'x': 3, 'y': 3},
      },
    ],
    'opaqueContract': <String, dynamic>{'unchanged': true},
  };
}

Map<String, dynamic> _layer(Map<String, dynamic> map, String id) {
  return (map['layers'] as List)
      .cast<Map<String, dynamic>>()
      .singleWhere((layer) => layer['id'] == id);
}

Map<String, dynamic> _clone(Map<String, dynamic> value) {
  return jsonDecode(jsonEncode(value)) as Map<String, dynamic>;
}
~~~~

## `packages/map_editor/test/selbrume_port_visual_refinement_test.dart`

~~~~dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../tool/refine_selbrume_port_brisants_visuals.dart';

void main() {
  test('parses source rectangles and row-major tile IDs', () {
    final modules = parsePortVisualTileModules(<String, dynamic>{
      'tileModules': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'module_test_2x2',
          'source': <String, dynamic>{
            'x': 10,
            'y': 12,
            'width': 2,
            'height': 2,
          },
          'tileIds': <int>[101, 102, 103, 104],
        },
      ],
    });

    final module = modules.single;
    expect(module.id, 'module_test_2x2');
    expect((module.sourceX, module.sourceY), (10, 12));
    expect((module.width, module.height), (2, 2));
    expect(module.tileIds, <int>[101, 102, 103, 104]);
    expect(module.tileIdAt(0, 0), 101);
    expect(module.tileIdAt(1, 0), 102);
    expect(module.tileIdAt(0, 1), 103);
    expect(module.tileIdAt(1, 1), 104);
  });

  test('rejects a tile module whose row-major payload has the wrong size', () {
    expect(
      () => parsePortVisualTileModules(<String, dynamic>{
        'tileModules': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'module_bad',
            'source': <String, dynamic>{
              'x': 0,
              'y': 0,
              'width': 2,
              'height': 2,
            },
            'tileIds': <int>[1, 2, 3],
          },
        ],
      }),
      throwsFormatException,
    );
  });

  test('publishes a restrained composition without freestanding garden walls',
      () {
    expect(requiredPortVisualModuleIds, hasLength(15));
    expect(
      requiredPortVisualModuleIds,
      isNot(contains(anyOf(<String>[
        'module_port_ref_wall_v',
        'module_port_ref_fence_h',
        'module_port_ref_foam_v_short',
        'module_port_ref_flower_patch_small',
      ]))),
    );
    expect(
      portVisualComposition.map((placement) => placement.group).toSet(),
      containsAll(<String>{
        'west_house_garden',
        'harbor_master_terrace',
        'central_square',
        'quay_connections',
        'east_coast',
        'local_foam',
      }),
    );
    expect(
      portVisualComposition.map((placement) => placement.group),
      isNot(contains('east_house_gardens')),
    );
    final steps = portVisualComposition.singleWhere(
      (placement) => placement.moduleId == 'module_port_ref_quay_steps_compact',
    );
    expect((steps.x, steps.y), (18, 16));
    expect(
      portVisualComposition
          .map((placement) => placement.moduleId)
          .toSet()
          .difference(requiredPortVisualModuleIds.toSet()),
      isEmpty,
    );
  });

  test('reports every missing composition module explicitly', () {
    final manifest = _manifestWithModules(
      requiredPortVisualModuleIds.take(3),
    );

    expect(
      missingPortVisualModuleIds(manifest),
      requiredPortVisualModuleIds.skip(3).toList(),
    );
  });

  test('keeps the visual north avenue on the real centered corridor', () {
    final cells = buildVisualPavementCells();

    for (var x = 26; x <= 30; x += 1) {
      expect(cells[x], isTrue, reason: 'north avenue cell ($x, 0)');
    }
    for (var x = 22; x <= 25; x += 1) {
      expect(cells[x], isFalse, reason: 'no false west exit at ($x, 0)');
    }
  });

  test('keeps one compact planted island inside a mostly paved square', () {
    final cells = buildVisualPavementCells();
    bool pavementAt(int x, int y) => cells[y * portVisualMapWidth + x];

    expect(pavementAt(23, 13), isFalse, reason: 'central planted island');
    expect(pavementAt(19, 15), isTrue, reason: 'west square stays paved');
    expect(pavementAt(29, 13), isTrue, reason: 'east square stays paved');
    expect(pavementAt(16, 13), isTrue, reason: 'market frontage stays paved');
    expect(pavementAt(32, 12), isTrue, reason: 'shop frontage stays paved');
    expect(pavementAt(17, 12), isTrue, reason: 'west route stays paved');
    expect(pavementAt(34, 14), isTrue, reason: 'east square stays paved');
    expect(pavementAt(39, 17), isTrue, reason: 'quay approach stays paved');
  });

  test('refines only the visual surface without adding layers or placements',
      () {
    final before = _fixtureMap();
    final manifest = _manifestWithModules(requiredPortVisualModuleIds);

    final after = buildRefinedPortVisualMap(
      mapJson: before,
      manifestJson: manifest,
    );

    verifyOnlyPortVisualChanges(before: before, after: after);
    expect((after['layers'] as List),
        hasLength((before['layers'] as List).length));
    final beforePlacementCount = (before['placedElements'] as List).length;
    final afterPlacements =
        (after['placedElements'] as List).cast<Map<String, dynamic>>();
    expect(afterPlacements.length, lessThan(beforePlacementCount));
    expect(
      afterPlacements.map((entry) => entry['id']),
      isNot(contains(anyOf(portVisualReplaceablePlacementIds))),
    );
    expect(
      afterPlacements.where(
        (entry) => !portVisualMovablePropPlacementIds.contains(entry['id']),
      ),
      hasLength(1),
    );
    expect(
      (_layer(after, portPrimaryPathLayerId)['cells'] as List)
          .where((value) => value == true),
      hasLength(greaterThan(300)),
    );
    for (final layerId in <String>{
      'l_tile_port_ref_ground',
      'l_tile_port_ref_backdrop',
      'l_tile_port_ref_structures',
    }) {
      expect(
        (_layer(after, layerId)['tiles'] as List).where((value) => value != 0),
        isNotEmpty,
        reason: '$layerId must receive a deliberate visual contribution',
      );
    }
    expect(
      (_layer(after, 'l_tile_port_ref_overhead')['tiles'] as List)
          .where((value) => value != 0),
      isEmpty,
      reason: 'the restrained pass has no justified overhead-only pixels',
    );
    expect(
      after['properties'],
      containsPair('visualRefinerStatus', 'candidate_pending_owner_approval'),
    );
  });

  test('allows movable props to change position only', () {
    final before = _fixtureMap();
    final after = buildRefinedPortVisualMap(
      mapJson: before,
      manifestJson: _manifestWithModules(requiredPortVisualModuleIds),
    );
    final movable = (after['placedElements'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere(
          (entry) => portVisualMovablePropPlacementIds.contains(entry['id']),
        );

    for (final field in <String>['elementId', 'layerId', 'opacity']) {
      final mutated = _clone(after);
      final mutatedMovable = (mutated['placedElements'] as List)
          .cast<Map<String, dynamic>>()
          .firstWhere((entry) => entry['id'] == movable['id']);
      mutatedMovable[field] = field == 'opacity' ? 0.5 : 'forbidden_change';
      expect(
        () => verifyOnlyPortVisualChanges(before: before, after: mutated),
        throwsStateError,
        reason: '$field is outside the movable-prop whitelist',
      );
    }
  });

  test('allows replaceable placements to stay unchanged or be removed only',
      () {
    final before = _fixtureMap();
    final after = _clone(before);
    final replaceable = (after['placedElements'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere(
          (entry) => portVisualReplaceablePlacementIds.contains(entry['id']),
        );
    replaceable['opacity'] = 0.5;

    expect(
      () => verifyOnlyPortVisualChanges(before: before, after: after),
      throwsStateError,
    );
  });

  test('check and atomic write are deterministic and idempotent', () async {
    final fixture = Directory.systemTemp.createTempSync('port_visual_refiner_');
    addTearDown(() => fixture.deleteSync(recursive: true));
    final mapFile = File(
      p.join(fixture.path, portVisualMapRelativePath),
    )..createSync(recursive: true);
    final manifestFile = File(
      p.join(fixture.path, portVisualManifestRelativePath),
    )..createSync(recursive: true);
    mapFile.writeAsStringSync(_pretty(_fixtureMap()));
    manifestFile.writeAsStringSync(
      _pretty(_manifestWithModules(requiredPortVisualModuleIds)),
    );
    final originalBytes = mapFile.readAsBytesSync();

    final checkBefore = await refineSelbrumePortBrisantsVisuals(
      SelbrumePortVisualRefinerOptions(projectRoot: fixture),
    );
    expect(checkBefore.exitCode, portVisualDivergenceExitCode);
    expect(checkBefore.divergentRelativePaths,
        <String>[portVisualMapRelativePath]);
    expect(mapFile.readAsBytesSync(), originalBytes);

    final write = await refineSelbrumePortBrisantsVisuals(
      SelbrumePortVisualRefinerOptions(projectRoot: fixture, write: true),
    );
    expect(write.exitCode, 0);
    final firstBytes = mapFile.readAsBytesSync();
    expect(firstBytes, isNot(originalBytes));
    expect(
      fixture
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => p.basename(file.path).contains('.tmp')),
      isEmpty,
    );

    final secondWrite = await refineSelbrumePortBrisantsVisuals(
      SelbrumePortVisualRefinerOptions(projectRoot: fixture, write: true),
    );
    final clean = await refineSelbrumePortBrisantsVisuals(
      SelbrumePortVisualRefinerOptions(projectRoot: fixture),
    );
    expect(secondWrite.exitCode, 0);
    expect(clean.exitCode, 0);
    expect(clean.divergentRelativePaths, isEmpty);
    expect(mapFile.readAsBytesSync(), firstBytes);
  });
}

Map<String, dynamic> _fixtureMap() {
  return <String, dynamic>{
    'id': portVisualMapId,
    'name': 'Port des Brisants',
    'size': <String, dynamic>{
      'width': portVisualMapWidth,
      'height': portVisualMapHeight,
    },
    'properties': <String, dynamic>{'authoringGenerator': 'fixture'},
    'layers': <Map<String, dynamic>>[
      <String, dynamic>{
        'id': portPrimaryPathLayerId,
        'runtimeType': 'path',
        'opacity': 1.0,
        'cells': List<bool>.filled(portVisualMapCellCount, false),
      },
      for (final id in portVisualTileLayerIds)
        <String, dynamic>{
          'id': id,
          'runtimeType': 'tile',
          'opacity': 1.0,
          'tiles': List<int>.filled(portVisualMapCellCount, 0),
        },
      <String, dynamic>{
        'id': 'l_visual_protected',
        'runtimeType': 'tile',
        'tiles': List<int>.filled(portVisualMapCellCount, 0),
      },
    ],
    'placedElements': <Map<String, dynamic>>[
      for (final id in portVisualReplaceablePlacementIds)
        <String, dynamic>{
          'id': id,
          'elementId': 'el_$id',
          'layerId': 'l_tile_port_ref_structures',
          'opacity': 1.0,
          'pos': <String, dynamic>{'x': 1, 'y': 1},
        },
      for (final id in portVisualMovablePropPlacementIds)
        <String, dynamic>{
          'id': id,
          'elementId': 'el_$id',
          'layerId': 'l_tile_port_ref_structures',
          'opacity': 1.0,
          'pos': <String, dynamic>{'x': 2, 'y': 2},
        },
      <String, dynamic>{
        'id': 'pe_port_protected',
        'pos': <String, dynamic>{'x': 3, 'y': 3},
      },
    ],
    'opaqueContract': <String, dynamic>{'unchanged': true},
  };
}

Map<String, dynamic> _clone(Map<String, dynamic> value) {
  return Map<String, dynamic>.from(jsonDecode(jsonEncode(value)) as Map);
}

Map<String, dynamic> _manifestWithModules(Iterable<String> moduleIds) {
  var tileId = 100;
  return <String, dynamic>{
    'schemaVersion': 3,
    'atlases': <String, dynamic>{
      'sprites': <String, dynamic>{'widthCells': 64},
    },
    'entries': <Map<String, dynamic>>[
      for (final id in requiredPortVisualEntryIds)
        <String, dynamic>{
          'id': id,
          'source': <String, dynamic>{
            'x': tileId++ % 64,
            'y': 1,
            'width': 1,
            'height': 1,
          },
        },
    ],
    'tileModules': <Map<String, dynamic>>[
      for (final id in moduleIds)
        <String, dynamic>{
          'id': id,
          'source': <String, dynamic>{
            'x': tileId,
            'y': 0,
            'width': 1,
            'height': 1,
          },
          'tileIds': <int>[tileId++],
        },
    ],
  };
}

Map<String, dynamic> _layer(Map<String, dynamic> map, String id) {
  return (map['layers'] as List)
      .cast<Map<String, dynamic>>()
      .singleWhere((layer) => layer['id'] == id);
}

String _pretty(Map<String, dynamic> json) {
  return '${const JsonEncoder.withIndent('  ').convert(json)}\n';
}
~~~~

## `packages/map_runtime/tool/selbrume_port_visual_capture_test.dart`

~~~~dart
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/runtime_map_bundle.dart';
import 'package:map_runtime/src/infrastructure/runtime_tileset_image.dart';
import 'package:map_runtime/src/infrastructure/tile_image_loader.dart';
import 'package:map_runtime/src/presentation/flame/map_layers_component.dart';
import 'package:path/path.dart' as p;

const String kPortVisualMapId = 'map_port_brisants';
const int kPortVisualCellPixels = 32;
const String _outputDirectoryEnvironmentKey =
    'SELBRUME_PORT_VISUAL_CAPTURE_OUTPUT_DIR';

final class PortVisualRegion {
  const PortVisualRegion({
    required this.id,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  final String id;
  final int left;
  final int top;
  final int width;
  final int height;

  int get pixelWidth => width * kPortVisualCellPixels;
  int get pixelHeight => height * kPortVisualCellPixels;
}

const PortVisualRegion kPortVisualOverviewRegion = PortVisualRegion(
  id: 'overview',
  left: 0,
  top: 0,
  width: 45,
  height: 34,
);

/// Regions mirror the six user review captures while staying snapped to map
/// cells. C1 intentionally repeats the complete map: the historical C1 was the
/// editor overview, while the dedicated `overview` artifact is the canonical
/// dimension contract consumed by tooling.
const List<PortVisualRegion> kPortVisualReviewRegions = <PortVisualRegion>[
  PortVisualRegion(
    id: 'c1_full_map',
    left: 0,
    top: 0,
    width: 45,
    height: 34,
  ),
  PortVisualRegion(
    id: 'c2_west_orange_house',
    left: 4,
    top: 2,
    width: 18,
    height: 16,
  ),
  PortVisualRegion(
    id: 'c3_harbor_master_blue_house',
    left: 17,
    top: 0,
    width: 28,
    height: 18,
  ),
  PortVisualRegion(
    id: 'c4_south_east_coast',
    left: 29,
    top: 16,
    width: 16,
    height: 18,
  ),
  PortVisualRegion(
    id: 'c5_east_pier',
    left: 24,
    top: 12,
    width: 21,
    height: 18,
  ),
  PortVisualRegion(
    id: 'c6_central_steps_quay',
    left: 12,
    top: 12,
    width: 21,
    height: 18,
  ),
];

final class PortVisualScene {
  const PortVisualScene({
    required this.bundle,
    required this.tileImagesByTilesetId,
  });

  final RuntimeMapBundle bundle;
  final Map<String, RuntimeTilesetImage> tileImagesByTilesetId;
}

Future<PortVisualScene> loadPortVisualScene({String? repositoryRoot}) async {
  final root = repositoryRoot == null
      ? _resolveRepositoryRoot()
      : Directory(p.normalize(p.absolute(repositoryRoot)));
  final projectRoot = p.join(root.path, 'selbrume');
  final projectFile = File(p.join(projectRoot, 'project.json'));
  final projectJson = await _readJsonObject(projectFile);
  final manifest = ProjectManifest.fromJson(projectJson);
  final mapEntry = manifest.maps.singleWhere(
    (entry) => entry.id == kPortVisualMapId,
    orElse: () => throw StateError(
      'Project does not register $kPortVisualMapId.',
    ),
  );
  final mapFile = File(p.join(projectRoot, mapEntry.relativePath));
  final mapJson = await _readJsonObject(mapFile);

  // Decode a visual projection rather than the gameplay document. Only layer
  // kinds painted by this runner are copied, and entities are removed so the
  // captures contain no labels, selection affordances or actor sprites.
  final visualMapJson = Map<String, dynamic>.from(mapJson)
    ..['layers'] = <Map<String, dynamic>>[
      for (final rawLayer in _jsonObjectList(mapJson['layers']))
        if (_visualLayerRuntimeTypes.contains(rawLayer['runtimeType']))
          rawLayer,
    ]
    ..['entities'] = <Map<String, dynamic>>[];
  final map = MapData.fromJson(visualMapJson);

  final tilesetIds = _collectVisualTilesetIds(map, manifest);
  final tilesetById = <String, ProjectTilesetEntry>{
    for (final tileset in manifest.tilesets) tileset.id: tileset,
  };
  final paths = <String, String>{};
  final transparentColors = <String, TilesetTransparentColor>{};
  for (final tilesetId in tilesetIds) {
    final tileset = tilesetById[tilesetId];
    if (tileset == null) {
      throw StateError('Visual tileset is not registered: $tilesetId');
    }
    final relativePath = tileset.relativePath.trim();
    if (relativePath.isEmpty) {
      throw StateError('Visual tileset has no file: $tilesetId');
    }
    paths[tilesetId] = p.normalize(p.join(projectRoot, relativePath));
    final transparentColor = tileset.transparentColor;
    if (transparentColor != null) {
      transparentColors[tilesetId] = transparentColor;
    }
  }

  final images = await loadTilesetImagesById(
    paths,
    transparentColorByTilesetId: transparentColors,
  );
  return PortVisualScene(
    bundle: RuntimeMapBundle(
      manifest: manifest,
      map: map,
      projectRootDirectory: projectRoot,
      tilesetAbsolutePathsById: paths,
    ),
    tileImagesByTilesetId: images,
  );
}

Future<ui.Image> renderPortVisualRegion(
  PortVisualScene scene,
  PortVisualRegion region,
) async {
  final map = scene.bundle.map;
  if (region.left < 0 ||
      region.top < 0 ||
      region.width <= 0 ||
      region.height <= 0 ||
      region.left + region.width > map.size.width ||
      region.top + region.height > map.size.height) {
    throw ArgumentError.value(
        region.id, 'region', 'Region is outside the map.');
  }

  final worldRect = ui.Rect.fromLTWH(
    region.left * scene.bundle.cellWidth,
    region.top * scene.bundle.cellHeight,
    region.width * scene.bundle.cellWidth,
    region.height * scene.bundle.cellHeight,
  );
  final background = MapLayersComponent(
    bundle: scene.bundle,
    tileImagesByTilesetId: scene.tileImagesByTilesetId,
    renderPass: MapLayerRenderPass.background,
  )..setVisibleLocalRect(worldRect);
  final foreground = MapLayersComponent(
    bundle: scene.bundle,
    tileImagesByTilesetId: scene.tileImagesByTilesetId,
    renderPass: MapLayerRenderPass.foreground,
  )..setVisibleLocalRect(worldRect);
  background.update(0);
  foreground.update(0);

  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.save();
  canvas.scale(
    kPortVisualCellPixels / scene.bundle.cellWidth,
    kPortVisualCellPixels / scene.bundle.cellHeight,
  );
  canvas.translate(
    -region.left * scene.bundle.cellWidth,
    -region.top * scene.bundle.cellHeight,
  );
  // Rendering the two map passes directly produces neutral-light source art.
  // No editor chrome, grid, annotation component or lighting overlay exists in
  // this runner.
  background.render(canvas);
  foreground.render(canvas);
  canvas.restore();
  return recorder.endRecording().toImage(
        region.pixelWidth,
        region.pixelHeight,
      );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('captures the dedicated Selbrume Port visual review set', () async {
    final outputPath =
        Platform.environment[_outputDirectoryEnvironmentKey]?.trim();
    if (outputPath == null || outputPath.isEmpty) {
      throw StateError(
        '$_outputDirectoryEnvironmentKey must point to the capture directory.',
      );
    }
    final outputDirectory = Directory(p.normalize(p.absolute(outputPath)));
    await outputDirectory.create(recursive: true);

    final scene = await loadPortVisualScene();
    expect(scene.bundle.map.id, kPortVisualMapId);
    expect(scene.bundle.map.size, const GridSize(width: 45, height: 34));

    await _renderAndWrite(
      scene: scene,
      region: kPortVisualOverviewRegion,
      outputFile: File(
        p.join(outputDirectory.path, '${kPortVisualMapId}__overview.png'),
      ),
    );
    for (final region in kPortVisualReviewRegions) {
      await _renderAndWrite(
        scene: scene,
        region: region,
        outputFile: File(
          p.join(
            outputDirectory.path,
            '${kPortVisualMapId}__${region.id}.png',
          ),
        ),
      );
    }
  });
}

const Set<Object?> _visualLayerRuntimeTypes = <Object?>{
  'terrain',
  'path',
  'tile',
};

Future<Map<String, dynamic>> _readJsonObject(File file) async {
  if (!await file.exists()) {
    throw StateError('Required visual input does not exist: ${file.path}');
  }
  final decoded = jsonDecode(await file.readAsString());
  if (decoded is! Map<String, dynamic>) {
    throw StateError('Expected a JSON object at ${file.path}');
  }
  return decoded;
}

List<Map<String, dynamic>> _jsonObjectList(Object? raw) {
  if (raw is! List) {
    throw StateError('Expected a JSON object list for visual map layers.');
  }
  return <Map<String, dynamic>>[
    for (final entry in raw)
      if (entry is Map<String, dynamic>) entry,
  ];
}

Directory _resolveRepositoryRoot() {
  var candidate = Directory.current.absolute;
  while (true) {
    if (File(p.join(candidate.path, 'selbrume', 'project.json')).existsSync() &&
        File(p.join(candidate.path, 'packages', 'map_runtime', 'pubspec.yaml'))
            .existsSync()) {
      return candidate;
    }
    final parent = candidate.parent;
    if (parent.path == candidate.path) {
      throw StateError(
        'Could not resolve the repository root from ${Directory.current.path}.',
      );
    }
    candidate = parent;
  }
}

Set<String> _collectVisualTilesetIds(
  MapData map,
  ProjectManifest manifest,
) {
  final ids = <String>{};
  void addId(String? raw) {
    final id = raw?.trim() ?? '';
    if (id.isNotEmpty) ids.add(id);
  }

  void addFrames(String baseTilesetId, List<TilesetVisualFrame> frames) {
    addId(baseTilesetId);
    for (final frame in frames) {
      addId(frame.tilesetId);
    }
  }

  addId(map.tilesetId);
  for (final layer in map.layers) {
    if (layer is TileLayer) {
      addId(layer.tilesetId ?? map.tilesetId);
      continue;
    }
    if (layer is TerrainLayer) {
      final terrainTypes = layer.terrains.toSet();
      for (final preset in manifest.terrainPresets) {
        if (!terrainTypes.contains(preset.terrainType)) continue;
        addId(preset.tilesetId);
        for (final variant in preset.variants) {
          addFrames(preset.tilesetId, variant.frames);
        }
      }
      continue;
    }
    if (layer is PathLayer) {
      for (final preset in manifest.pathPresets) {
        if (preset.id != layer.presetId) continue;
        addId(preset.tilesetId);
        for (final variant in preset.variants) {
          addFrames(preset.tilesetId, variant.frames);
        }
        for (final pattern in manifest.pathPatternPresets) {
          if (pattern.basePathPresetId != preset.id) continue;
          for (final cell in pattern.centerPattern.cells) {
            addFrames(preset.tilesetId, cell.frames);
          }
        }
      }
    }
  }

  final elementById = <String, ProjectElementEntry>{
    for (final element in manifest.elements) element.id: element,
  };
  for (final placed in map.placedElements) {
    final element = elementById[placed.elementId];
    if (element == null) continue;
    addFrames(element.tilesetId, element.frames);
  }
  return ids;
}

Future<void> _renderAndWrite({
  required PortVisualScene scene,
  required PortVisualRegion region,
  required File outputFile,
}) async {
  final image = await renderPortVisualRegion(scene, region);
  try {
    expect(
        (image.width, image.height), (region.pixelWidth, region.pixelHeight));
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) {
      throw StateError('Could not encode visual capture ${region.id}.');
    }
    await outputFile.writeAsBytes(
      bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      flush: true,
    );
  } finally {
    image.dispose();
  }
}
~~~~

## `packages/map_runtime/test/selbrume_port_visual_invariants_test.dart`

~~~~dart
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../tool/selbrume_port_visual_capture_test.dart' as visual;

const Set<String> _mutableVisualLayerIds = <String>{
  'l_tile_port_ref_ground',
  'l_tile_port_ref_backdrop',
  'l_tile_port_ref_overhead',
  'l_tile_port_ref_structures',
};

const Set<String> _baselinePlacedElementIds = <String>{
  'env_gen_env_port_ref_clusters_12_0_el_port_ref_forest_cluster',
  'env_gen_env_port_ref_clusters_31_0_el_port_ref_forest_cluster',
  'env_gen_env_port_ref_clusters_34_0_el_port_ref_forest_cluster',
  'env_gen_env_port_ref_clusters_5_0_el_port_ref_forest_cluster',
  'env_gen_env_port_ref_east_trees_40_12_el_port_ref_tree',
  'env_gen_env_port_ref_east_trees_40_16_el_port_ref_tree',
  'env_gen_env_port_ref_east_trees_40_4_el_port_ref_tree',
  'env_gen_env_port_ref_east_trees_40_8_el_port_ref_tree',
  'env_gen_env_port_ref_north_trees_18_0_el_port_ref_tree',
  'env_gen_env_port_ref_north_trees_21_0_el_port_ref_tree',
  'env_gen_env_port_ref_north_trees_40_0_el_port_ref_tree',
  'pe_port_barrel_buoy_center',
  'pe_port_barrel_buoy_east',
  'pe_port_bateau',
  'pe_port_bench_east',
  'pe_port_boat_medium',
  'pe_port_boat_small',
  'pe_port_capitainerie',
  'pe_port_coast_east',
  'pe_port_coast_west',
  'pe_port_fish_basket_east',
  'pe_port_fish_basket_west',
  'pe_port_fish_crates_pier',
  'pe_port_fish_crates_west',
  'pe_port_flower_bed',
  'pe_port_foam_cluster_south',
  'pe_port_foam_quay_center',
  'pe_port_foam_quay_east',
  'pe_port_foam_quay_west',
  'pe_port_foam_wake_large',
  'pe_port_foam_wake_medium',
  'pe_port_foam_wake_small',
  'pe_port_garden_backdrop_captain_east',
  'pe_port_garden_backdrop_captain_west',
  'pe_port_garden_backdrop_east_blue',
  'pe_port_garden_backdrop_east_orange',
  'pe_port_garden_backdrop_west',
  'pe_port_garden_east',
  'pe_port_hangar',
  'pe_port_house_blue',
  'pe_port_house_east',
  'pe_port_house_west',
  'pe_port_lamp_18_12',
  'pe_port_lamp_21_8',
  'pe_port_lamp_26_8',
  'pe_port_lamp_42_9',
  'pe_port_lobster_pots_center',
  'pe_port_lobster_pots_pier',
  'pe_port_market',
  'pe_port_net_rack_east',
  'pe_port_net_rack_west',
  'pe_port_nid_goelise',
  'pe_port_pier_center',
  'pe_port_pier_east',
  'pe_port_pier_west',
  'pe_port_quay_17',
  'pe_port_quay_29',
  'pe_port_quay_5',
  'pe_port_quay_steps',
  'pe_port_rock_pair_south_center',
  'pe_port_rock_small_south_mid',
  'pe_port_rock_small_south_west',
  'pe_port_rock_trio_quay_transition',
  'pe_port_rock_trio_south_east',
  'pe_port_rocks_south_east',
  'pe_port_rope_coil_pier',
  'pe_port_rope_coil_west',
  'pe_port_sign_center',
};

const Set<String> _baselinePortProjectElementIds = <String>{
  'el_port_ref_barrel_buoy_small',
  'el_port_ref_bench',
  'el_port_ref_boat_large',
  'el_port_ref_boat_medium',
  'el_port_ref_boat_small',
  'el_port_ref_chandlery',
  'el_port_ref_coast_east_peninsula',
  'el_port_ref_coast_west_continuous',
  'el_port_ref_fish_basket_small',
  'el_port_ref_fish_crates_small',
  'el_port_ref_fish_market',
  'el_port_ref_flower_bed',
  'el_port_ref_foam_boat_wake',
  'el_port_ref_foam_quay_horizontal',
  'el_port_ref_foam_rock_cluster',
  'el_port_ref_forest_cluster',
  'el_port_ref_harbor_master',
  'el_port_ref_house_blue',
  'el_port_ref_house_orange',
  'el_port_ref_lamp',
  'el_port_ref_lobster_pots_small',
  'el_port_ref_nest',
  'el_port_ref_net_rack_small',
  'el_port_ref_pier_t',
  'el_port_ref_pier_vertical',
  'el_port_ref_quay_horizontal',
  'el_port_ref_quay_steps',
  'el_port_ref_rock_cluster',
  'el_port_ref_rock_pair',
  'el_port_ref_rock_small',
  'el_port_ref_rock_trio',
  'el_port_ref_rope_coil_small',
  'el_port_ref_sign_small',
  'el_port_ref_tree',
  'el_port_ref_walled_garden',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Selbrume Port visual-only invariants', () {
    late visual.PortVisualScene scene;

    setUpAll(() async {
      scene = await visual.loadPortVisualScene();
    });

    test('keeps the four mutable TileLayer visual contracts', () {
      final map = scene.bundle.map;
      expect(map.id, visual.kPortVisualMapId);
      expect(map.size, const GridSize(width: 45, height: 34));
      expect(
        map.layers.every(
          (layer) =>
              layer is TerrainLayer || layer is PathLayer || layer is TileLayer,
        ),
        isTrue,
        reason: 'The QA projection may contain visual layer types only.',
      );

      final tileLayers = <String, TileLayer>{
        for (final layer in map.layers.whereType<TileLayer>()) layer.id: layer,
      };
      expect(tileLayers.keys, containsAll(_mutableVisualLayerIds));
      for (final layerId in _mutableVisualLayerIds) {
        final layer = tileLayers[layerId]!;
        expect(layer.tiles, hasLength(map.size.width * map.size.height));
        expect(layer.tilesetId, 'ts_selbrume_port_reference_v3');
      }
    });

    test('does not introduce MapPlacedElement or ProjectElement IDs', () {
      final placedIds =
          scene.bundle.map.placedElements.map((placed) => placed.id).toSet();
      expect(placedIds.difference(_baselinePlacedElementIds), isEmpty);
      expect(
        placedIds.any((id) => id.startsWith('pe_port_visual_')),
        isFalse,
      );

      final portProjectElementIds = scene.bundle.manifest.elements
          .where((element) => element.id.startsWith('el_port_'))
          .map((element) => element.id)
          .toSet();
      expect(portProjectElementIds, _baselinePortProjectElementIds);
    });

    test('keeps tile modules and placed visual frames within bounds', () {
      final map = scene.bundle.map;
      final tileSize = scene.bundle.manifest.settings.tileWidth;
      final elementById = <String, ProjectElementEntry>{
        for (final element in scene.bundle.manifest.elements)
          element.id: element,
      };

      for (final layer in map.layers.whereType<TileLayer>()) {
        final tilesetId = (layer.tilesetId ?? map.tilesetId).trim();
        if (tilesetId.isEmpty) continue;
        final image = scene.tileImagesByTilesetId[tilesetId];
        expect(image, isNotNull, reason: 'Missing visual tileset $tilesetId');
        final columns = image!.width ~/ tileSize;
        final rows = image.height ~/ tileSize;
        expect(columns, greaterThan(0));
        expect(rows, greaterThan(0));
        final maximumTileId = columns * rows;
        for (final tileId in layer.tiles) {
          expect(tileId, inInclusiveRange(0, maximumTileId));
        }
      }

      for (final placed in map.placedElements) {
        final element = elementById[placed.elementId];
        expect(element, isNotNull,
            reason: 'Unknown visual element ${placed.elementId}');
        final primary = element!.frames.primarySource;
        expect(placed.pos.x, greaterThanOrEqualTo(0));
        expect(placed.pos.y, greaterThanOrEqualTo(0));
        expect(placed.pos.x + primary.width, lessThanOrEqualTo(map.size.width));
        expect(
          placed.pos.y + primary.height,
          lessThanOrEqualTo(map.size.height),
        );

        for (final frame in element.frames) {
          final tilesetId = frame.tilesetId.trim().isEmpty
              ? element.tilesetId.trim()
              : frame.tilesetId.trim();
          final image = scene.tileImagesByTilesetId[tilesetId];
          expect(image, isNotNull, reason: 'Missing frame tileset $tilesetId');
          final source = frame.source;
          expect(
            image!.containsSourceRect(
              ui.Rect.fromLTWH(
                (source.x * tileSize).toDouble(),
                (source.y * tileSize).toDouble(),
                (source.width * tileSize).toDouble(),
                (source.height * tileSize).toDouble(),
              ),
            ),
            isTrue,
            reason: 'Out-of-bounds frame for ${element.id}',
          );
        }
      }
    });

    test('renders a non-black continuous in-bounds map at 32 px per cell',
        () async {
      final image = await visual.renderPortVisualRegion(
        scene,
        visual.kPortVisualOverviewRegion,
      );
      expect((image.width, image.height), (1440, 1088));

      final pixels = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      expect(pixels, isNotNull);
      var nonBlackPixels = 0;
      for (var offset = 0; offset < pixels!.lengthInBytes; offset += 4) {
        if (pixels.getUint8(offset) != 0 ||
            pixels.getUint8(offset + 1) != 0 ||
            pixels.getUint8(offset + 2) != 0) {
          nonBlackPixels += 1;
        }
      }
      expect(nonBlackPixels, greaterThan(0));

      for (var y = 0; y < scene.bundle.map.size.height; y += 1) {
        for (var x = 0; x < scene.bundle.map.size.width; x += 1) {
          final pixelX = x * visual.kPortVisualCellPixels +
              visual.kPortVisualCellPixels ~/ 2;
          final pixelY = y * visual.kPortVisualCellPixels +
              visual.kPortVisualCellPixels ~/ 2;
          final alphaOffset = (pixelY * image.width + pixelX) * 4 + 3;
          expect(
            pixels.getUint8(alphaOffset),
            greaterThan(0),
            reason: 'Transparent visual gap at cell ($x,$y)',
          );
        }
      }
    });

    test('renders every review crop without transparent capture gaps',
        () async {
      for (final region in visual.kPortVisualReviewRegions) {
        final image = await visual.renderPortVisualRegion(scene, region);
        final pixels =
            await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        expect(pixels, isNotNull, reason: region.id);
        var transparentPixelCount = 0;
        for (var offset = 3; offset < pixels!.lengthInBytes; offset += 4) {
          if (pixels.getUint8(offset) == 0) transparentPixelCount += 1;
        }
        expect(
          transparentPixelCount,
          0,
          reason: '${region.id} must not expose the transparent canvas',
        );
      }
    });
  });
}
~~~~

## `reports/gameplay/evidence/fg_181_selbrume_port_visual_correction/blueprint.md`

~~~~markdown
# FG-181 — Blueprint visuel du Port des Brisants

## Lot

`FG-181 / map_port_brisants / correction visuelle contrainte`

## Sources comparées

- Objectif original : `objective.png` (`1448 × 1086`).
- Objectif normalisé : `objective_normalized.png` (`1440 × 1088`, soit
  `45 × 34` cases à `32 px`).
- Rendu avant correction : `before_overview.png` (`1440 × 1088`).
- Détails avant correction : `before_C1.png` à `before_C6.png`.

L’image d’objectif reste une référence uniquement. Elle ne devient jamais un
underlay ou une texture runtime.

## Frontière absolue

Ce lot ne travaille sur aucune collision : aucune donnée, logique, validation,
capture ou correction de collision. Le propriétaire effectuera son passage
séparé après approbation visuelle.

Le lot ne crée aucun nouveau layer, `MapPlacedElement` ou `ProjectElement`.
Les nouveaux pixels sont des modules de tileset `tile-only` peints dans les
quatre `TileLayer` Port déjà présentes.

## Diagnostic avant correction

| Zone | Écart principal | Cause technique | Correction visuelle prévue |
|---|---|---|---|
| Maisons nord | portes visuellement enfermées, mêmes remparts répétés | cinq copies du jardin muré `7 × 5` | retirer les cinq composites et repeindre murs courts, embouts, ouvertures et fleurs |
| Capitainerie | parvis comprimé et murs doublés | deux jardins backdrop qui se chevauchent | conserver bâtiment et lampes, reconstruire uniquement le soutènement arrière et les ouvertures |
| Place centrale | grand rectangle d’herbe vide | pavement dessiné par bandes rectangulaires | étendre `pavement_path` et conserver un massif compact central |
| Marché ouest | décor isolé autour du commerce | props sans groupe fonctionnel | conserver le bâtiment, regrouper visuellement vente/filets/cordages |
| Accastillage est | façade chargée, props flottants | accessoires posés par coordonnées brutes | libérer la porte et organiser stockage/réparation sur les côtés |
| Quai horizontal | trois blocs identiques | un seul module `12 × 4` répété | différencier ouest, centre et est par ouvertures, raccords et accessoires |
| Marches centrales | pierre sur bois et chevauchements | composite `7 × 7` trop opaque | garder le canvas mais réduire l’alpha utile à un escalier compact |
| Pontons | silhouettes trop mécaniques | composites répétés | varier extrémités et raccords ; alléger visuellement le ponton est |
| Côte est | frontière incomplète et carrée | composite `9 × 5` trop court/translucide | repeindre une côte continue et un raccord quai–rocher dédié |
| Écume | longues bandes traversant les pieux | trois overlays `12 × 2` identiques | écume locale courte autour des pieux, coques et rochers |
| Lampadaires | lecture aléatoire | contexte de chemin/murs incohérent | conserver les quatre positions et construire le décor autour d’elles |

## Macro-composition retenue

### Bande nord — `y = 0..10`

- Conserver les six bâtiments, la forêt Environment, les quatre lampes et la
  sortie nord actuelle.
- Maison ouest : jardin ouvert devant le seuil, mur court uniquement sur les
  côtés et à l’arrière.
- Capitainerie : axe porte/parvis centré, soutènement en deux moitiés, aucune
  pierre devant la porte.
- Maisons est : privilégier clôtures et jardinières basses plutôt qu’un socle
  de pierre continu.
- Le nid narratif reste à sa position actuelle et hors de la composition
  principale.

### Place et commerces — `y = 9..18`

- Le pavement devient la masse principale.
- Conserver deux respirations végétales : un îlot central compact et un îlot
  près du marché.
- Garder un axe clair entre capitainerie, place et marches du quai.
- Libérer visuellement toutes les façades.
- Les cinq props visuels whitelistés peuvent être retirés puis repeints dans
  les layers visuels ; tous les autres restent inchangés.

### Front de quai — `y = 17..22`

- Conserver l’alignement général des trois sections horizontales.
- Ouest : fonction vente/déchargement.
- Centre : ouverture d’escalier nette et zone de travail.
- Est : raccord direct à la côte et à l’accastillage.
- Aucun bloc de pierre ne doit traverser une entrée de ponton.

### Bassin et pontons — `y = 21..33`

- Les bateaux restent inchangés.
- Ponton ouest : long ponton de service.
- Ponton central : grande plateforme de travail, silhouette en T.
- Ponton est : lecture visuellement plus légère que les deux autres.
- Les accessoires sont groupés par usage et restent entièrement posés sur le
  bois dans le rendu.

### Côte

- Ouest : conserver la grande côte continue et corriger seulement le raccord
  avec le quai.
- Est : repeindre le raccord complet du quai jusqu’au bord droit/bas, sans trou
  transparent in-bounds.
- L’écume doit réagir localement aux rochers, coques et pieux.

## Whitelist de données visuelles

Le refiner peut modifier uniquement :

1. `l_path_primary.cells` ;
2. les tableaux `tiles` de :
   - `l_tile_port_ref_ground` ;
   - `l_tile_port_ref_backdrop` ;
   - `l_tile_port_ref_overhead` ;
   - `l_tile_port_ref_structures` ;
3. la suppression/remplacement des placements suivants :
   - `pe_port_garden_backdrop_west` ;
   - `pe_port_garden_backdrop_captain_west` ;
   - `pe_port_garden_backdrop_captain_east` ;
   - `pe_port_garden_backdrop_east_blue` ;
   - `pe_port_garden_backdrop_east_orange` ;
   - `pe_port_flower_bed` ;
   - `pe_port_quay_5`, `pe_port_quay_17`, `pe_port_quay_29` ;
   - `pe_port_quay_steps` ;
   - `pe_port_pier_west`, `pe_port_pier_center`, `pe_port_pier_east` ;
   - `pe_port_coast_west`, `pe_port_coast_east` ;
   - les sept `pe_port_foam_*` ;
4. le retrait/repaint éventuel de :
   - `pe_port_net_rack_east` ;
   - `pe_port_fish_basket_west` ;
   - `pe_port_fish_basket_east` ;
   - `pe_port_lobster_pots_center` ;
   - `pe_port_barrel_buoy_center` ;
5. les métadonnées `visualRefiner*` ;
6. l’atlas Port v3 et son tableau de provenance `tileModules`.

Tout le résidu JSON avant/après doit être profondément identique.

## Répartition des modules dans les layers existants

| Layer | Familles de modules |
|---|---|
| `l_tile_port_ref_ground` | fleurs basses, massif compact, écume et wakes |
| `l_tile_port_ref_backdrop` | murs et clôtures derrière les façades |
| `l_tile_port_ref_structures` | côte, quais, pontons, marches et murs frontaux |
| `l_tile_port_ref_overhead` | parties hautes nécessaires à l’occlusion visuelle |

## Gate de comparaison

Le résultat ne passe pas sur un simple test technique. Les captures finales
doivent être comparées à `objective_normalized.png` avec la même taille et une
lumière neutre.

Minimum attendu :

- composition `≥ 4/5` ;
- cohérence de style `≥ 4/5` ;
- accès visuels `5/5` ;
- quais et raccords `5/5` ;
- côte est `5/5` ;
- finition générale `≥ 4/5` ;
- aucune grille, zone, trigger, sélection ou label dans les preuves.

## État initial

- Branche : `main`.
- État Git observé avant implémentation : propre.
- Le propriétaire a signalé une autre conversation active ; chaque écriture
  doit donc être précédée d’un contrôle du statut et les changements étrangers
  doivent être préservés.
~~~~

## `reports/gameplay/evidence/fg_181_selbrume_port_visual_correction/reference_brief_generated.md`

~~~~markdown
# Reference brief — map_port_brisants

## Evidence

- Map ID: `map_port_brisants`
- Reference role: `reference-only` (never a runtime underlay)
- Reference file: `objective.png`
- Reference SHA-256: `25fdc9419850028a6e79787ac53dd8e34dcf457ed2d90c1126b5e9b60ecfb219`
- Dimensions: `1448×1086`
- Asset inventory: `source_inventory.json`
- Inventory SHA-256 / count: `9966bffe3869eba8fb444563ceb0b9c122b5d8c3a9a0c1a563ad7ad463154526 (19 images)`

## Composition zones

| Zone | Approximate bounds/proportion | Visual purpose | Traversable? | Existing asset candidates |
|---|---|---|---|---|
| TODO | TODO | TODO | TODO | TODO |

## Landmarks and silhouettes

| Priority | Landmark | Approximate position | Footprint/anchor | Reuse, normalize, or gap | Gameplay contract |
|---|---|---|---|---|---|
| P0 | TODO | TODO | TODO | TODO | TODO |

## Navigation and protected cells

- Player route: TODO
- Entrances/exits/connections: TODO
- Door and warp approaches: TODO
- Interaction anchors: TODO
- Environment exclusions and one-cell buffers: TODO
- Foreground occlusion expectations: TODO

## Asset decisions

| Visual need | Existing candidates checked | Decision | Provenance | Source/output hashes | New asset justification |
|---|---|---|---|---|---|
| TODO | TODO | TODO | TODO | TODO | `none` unless a named gap remains |

## Environment plan

| Layer/area | Target layer | Preset | Seed | Eligible mask | Protected mask | Coverage target |
|---|---|---|---:|---|---|---|
| TODO | TODO | TODO | TODO | TODO | TODO | TODO |

Regenerate twice and compare placement IDs, element IDs, and positions byte-for-byte.

## Water contract

- Contexts present (open sea / coast / foam / marsh): TODO
- Animation frames, duration, and loop: TODO
- Required inner/outer corners and isolated pools: TODO
- Context composite (rocks, docks, reeds, beach): TODO
- Seam and last-to-first loop evidence: TODO

## Technical preservation

- Existing entities/triggers/zones/events/warps/connections to preserve: TODO
- Required IDs and narrative reservations: TODO
- Collision and traversal evidence: TODO
- Real EditorNotifier load/save/reload evidence: TODO

## Comparable capture set

| Capture | Camera/viewport | Scale | Lighting/time | Grid | Required comparison |
|---|---|---:|---|---|---|
| Overview | TODO | TODO | TODO | off | reference / current / candidate |
| Player route | TODO | TODO | TODO | off | readability and collision |

## Visual review

| Axis | Score (1–5) | Evidence / correction |
|---|---:|---|
| Composition | TODO | TODO |
| Style coherence | TODO | TODO |
| Navigation readability | TODO | TODO |
| Place identity | TODO | TODO |
| Finish | TODO | TODO |

Every axis requires 4/5 or higher plus explicit human approval.
~~~~

## `reports/gameplay/evidence/fg_181_selbrume_port_visual_correction/source_inventory.json`

~~~~json
{
  "schemaVersion": 1,
  "rootLabel": "port_reference_v3_sources",
  "summary": {
    "imageCount": 19,
    "totalBytes": 21031711,
    "duplicateGroupCount": 0,
    "decodeErrorCount": 0,
    "inspectionWarningCount": 0,
    "missingProvenanceCount": 19,
    "unapprovedProvenanceCount": 0,
    "realTransparencyCount": 9
  },
  "duplicateGroups": [],
  "decodeErrors": [],
  "inspectionWarnings": [],
  "missingProvenance": [
    "architecture_sheet_alpha.png",
    "architecture_sheet_chroma.png",
    "coast_sheet_alpha.png",
    "coast_sheet_chroma.png",
    "docks_boats_sheet_alpha.png",
    "docks_boats_sheet_chroma.png",
    "grass_texture_owner.png",
    "natural_coast_alpha.png",
    "natural_coast_chroma.png",
    "nature_sheet_alpha.png",
    "nature_sheet_chroma.png",
    "nest_alpha.png",
    "nest_chroma.png",
    "shore_foam_alpha.png",
    "shore_foam_chroma.png",
    "small_harbor_props_alpha.png",
    "small_harbor_props_chroma.png",
    "small_props_alpha.png",
    "small_props_chroma.png"
  ],
  "unapprovedProvenance": [],
  "assets": [
    {
      "path": "architecture_sheet_alpha.png",
      "sizeBytes": 1281964,
      "sha256": "b1cf19ea4ae8470ccf94615652fed3c1487b5e495d68db26e46f5b92c732383f",
      "provenance": null,
      "format": "png",
      "width": 1448,
      "height": 1086,
      "bitDepth": 8,
      "colorType": 6,
      "declaresAlpha": true,
      "alphaInspection": "used",
      "transparentPixels": 1006931,
      "translucentPixels": 23341
    },
    {
      "path": "architecture_sheet_chroma.png",
      "sizeBytes": 1718630,
      "sha256": "ca2d487ea3f1963a410e980f36c8d3f182021dc5556a5f8454530b931cb5b17e",
      "provenance": null,
      "format": "png",
      "width": 1448,
      "height": 1086,
      "bitDepth": 8,
      "colorType": 2,
      "declaresAlpha": false,
      "alphaInspection": "not-applicable",
      "transparentPixels": null,
      "translucentPixels": null
    },
    {
      "path": "coast_sheet_alpha.png",
      "sizeBytes": 918705,
      "sha256": "ebfe90c3d2d8dc7182a243f9143d9da7860b2743fa30aa21b66db39285dff130",
      "provenance": null,
      "format": "png",
      "width": 1536,
      "height": 1024,
      "bitDepth": 8,
      "colorType": 6,
      "declaresAlpha": true,
      "alphaInspection": "used",
      "transparentPixels": 1182095,
      "translucentPixels": 12985
    },
    {
      "path": "coast_sheet_chroma.png",
      "sizeBytes": 1680360,
      "sha256": "1af75ee54d4c6aa7ac1757debf2ae20732f4636f30803c1f4b1e8d99221bc479",
      "provenance": null,
      "format": "png",
      "width": 1536,
      "height": 1024,
      "bitDepth": 8,
      "colorType": 2,
      "declaresAlpha": false,
      "alphaInspection": "not-applicable",
      "transparentPixels": null,
      "translucentPixels": null
    },
    {
      "path": "docks_boats_sheet_alpha.png",
      "sizeBytes": 918021,
      "sha256": "564620ab327fbd92e0c8d29bd970b174019c1a9c6672586e1d1ae627019551aa",
      "provenance": null,
      "format": "png",
      "width": 1536,
      "height": 1024,
      "bitDepth": 8,
      "colorType": 6,
      "declaresAlpha": true,
      "alphaInspection": "used",
      "transparentPixels": 1149974,
      "translucentPixels": 12666
    },
    {
      "path": "docks_boats_sheet_chroma.png",
      "sizeBytes": 1657969,
      "sha256": "601f2e03a7e9d4e12a1615abcc7bc17717846941ac7fbd0aec0bafab2103fca3",
      "provenance": null,
      "format": "png",
      "width": 1536,
      "height": 1024,
      "bitDepth": 8,
      "colorType": 2,
      "declaresAlpha": false,
      "alphaInspection": "not-applicable",
      "transparentPixels": null,
      "translucentPixels": null
    },
    {
      "path": "grass_texture_owner.png",
      "sizeBytes": 954503,
      "sha256": "410c9dac535964b0824ffb422f1f08e2f2be3e06a6962a13ba6c847e923a8780",
      "provenance": null,
      "format": "png",
      "width": 843,
      "height": 678,
      "bitDepth": 8,
      "colorType": 2,
      "declaresAlpha": false,
      "alphaInspection": "not-applicable",
      "transparentPixels": null,
      "translucentPixels": null
    },
    {
      "path": "natural_coast_alpha.png",
      "sizeBytes": 653672,
      "sha256": "e1fcfa3f07fb2a11f26259b005b2a59ad70f8bf246b3bce8b5ecfbd01132054b",
      "provenance": null,
      "format": "png",
      "width": 1608,
      "height": 978,
      "bitDepth": 8,
      "colorType": 6,
      "declaresAlpha": true,
      "alphaInspection": "used",
      "transparentPixels": 1358923,
      "translucentPixels": 28812
    },
    {
      "path": "natural_coast_chroma.png",
      "sizeBytes": 1422070,
      "sha256": "16206f723e6676acc73f7ad0e7edcd95827cceea9fb4fc3381b919ce283ffa19",
      "provenance": null,
      "format": "png",
      "width": 1608,
      "height": 978,
      "bitDepth": 8,
      "colorType": 2,
      "declaresAlpha": false,
      "alphaInspection": "not-applicable",
      "transparentPixels": null,
      "translucentPixels": null
    },
    {
      "path": "nature_sheet_alpha.png",
      "sizeBytes": 1163894,
      "sha256": "eec26cee363ca41d0321310e06ee15bb8f76b630f20fa7295a5bddecc6ca2c34",
      "provenance": null,
      "format": "png",
      "width": 1448,
      "height": 1086,
      "bitDepth": 8,
      "colorType": 6,
      "declaresAlpha": true,
      "alphaInspection": "used",
      "transparentPixels": 1088704,
      "translucentPixels": 26789
    },
    {
      "path": "nature_sheet_chroma.png",
      "sizeBytes": 1641814,
      "sha256": "4a80364184cc294901e600122a6c94aa34dd7c8120a3e8abc2bdeeec5857a159",
      "provenance": null,
      "format": "png",
      "width": 1448,
      "height": 1086,
      "bitDepth": 8,
      "colorType": 2,
      "declaresAlpha": false,
      "alphaInspection": "not-applicable",
      "transparentPixels": null,
      "translucentPixels": null
    },
    {
      "path": "nest_alpha.png",
      "sizeBytes": 664916,
      "sha256": "d6f99da4250fe5f31478e9ae9e3c0d0d34e9d42985e6c1ae3ea1b99629d0d333",
      "provenance": null,
      "format": "png",
      "width": 1254,
      "height": 1254,
      "bitDepth": 8,
      "colorType": 6,
      "declaresAlpha": true,
      "alphaInspection": "used",
      "transparentPixels": 1138280,
      "translucentPixels": 5720
    },
    {
      "path": "nest_chroma.png",
      "sizeBytes": 1234558,
      "sha256": "0564a2222083c53d6fb379490b055d900d18656761897927a37a7e9bcb10b6f4",
      "provenance": null,
      "format": "png",
      "width": 1254,
      "height": 1254,
      "bitDepth": 8,
      "colorType": 2,
      "declaresAlpha": false,
      "alphaInspection": "not-applicable",
      "transparentPixels": null,
      "translucentPixels": null
    },
    {
      "path": "shore_foam_alpha.png",
      "sizeBytes": 229172,
      "sha256": "8fb6360b97f8c796398eb3446ac83ee0a7190f3f5586e711c65fd06a230c2cf2",
      "provenance": null,
      "format": "png",
      "width": 1536,
      "height": 1024,
      "bitDepth": 8,
      "colorType": 6,
      "declaresAlpha": true,
      "alphaInspection": "used",
      "transparentPixels": 1513582,
      "translucentPixels": 20171
    },
    {
      "path": "shore_foam_chroma.png",
      "sizeBytes": 1325156,
      "sha256": "c79ff4a4cd612fba3e99f3225377a8d7d2acd85eb704f08140c5822b7c90bd93",
      "provenance": null,
      "format": "png",
      "width": 1536,
      "height": 1024,
      "bitDepth": 8,
      "colorType": 2,
      "declaresAlpha": false,
      "alphaInspection": "not-applicable",
      "transparentPixels": null,
      "translucentPixels": null
    },
    {
      "path": "small_harbor_props_alpha.png",
      "sizeBytes": 548215,
      "sha256": "e7f3573347e1ccb897b94e9705283f0a1f0659243047f9e8d3851647cf3b1c3e",
      "provenance": null,
      "format": "png",
      "width": 1536,
      "height": 1024,
      "bitDepth": 8,
      "colorType": 6,
      "declaresAlpha": true,
      "alphaInspection": "used",
      "transparentPixels": 1357308,
      "translucentPixels": 19614
    },
    {
      "path": "small_harbor_props_chroma.png",
      "sizeBytes": 1469436,
      "sha256": "b547b10af05a875e373cec7b996b41fd81b02852bdcc170235b41e4827928552",
      "provenance": null,
      "format": "png",
      "width": 1536,
      "height": 1024,
      "bitDepth": 8,
      "colorType": 2,
      "declaresAlpha": false,
      "alphaInspection": "not-applicable",
      "transparentPixels": null,
      "translucentPixels": null
    },
    {
      "path": "small_props_alpha.png",
      "sizeBytes": 282110,
      "sha256": "ad840de07943c48eaa3113fe26722971edfc7ce4af15b5f56d62201024560b13",
      "provenance": null,
      "format": "png",
      "width": 1536,
      "height": 1024,
      "bitDepth": 8,
      "colorType": 6,
      "declaresAlpha": true,
      "alphaInspection": "used",
      "transparentPixels": 1424579,
      "translucentPixels": 7176
    },
    {
      "path": "small_props_chroma.png",
      "sizeBytes": 1266546,
      "sha256": "aa6b3b5c1f95d363743d070e5ffc48ca3c313ada147d2df16dcaa6337a4ab049",
      "provenance": null,
      "format": "png",
      "width": 1536,
      "height": 1024,
      "bitDepth": 8,
      "colorType": 2,
      "declaresAlpha": false,
      "alphaInspection": "not-applicable",
      "transparentPixels": null,
      "translucentPixels": null
    }
  ]
}
~~~~

## `reports/gameplay/evidence/fg_181_selbrume_port_visual_correction/asset_cleanup_decision.md`

~~~~markdown
# Décision de nettoyage des assets — FG-181

## Verdict

Le module tile-only `module_port_ref_foam_v_short` a été supprimé du builder,
de la provenance et de la composition finale parce que sa ligne d’écume
verticale était artificielle. L’atlas partagé a été régénéré et ne contient
plus ce module.

Aucun fichier source historique, `ProjectElement` ou atlas supplémentaire n’a
été supprimé. Les quinze modules générés restants sont tous utilisés par la
composition finale et présents dans les couches visuelles de la map.

## Audit automatisé

Le dry-run hash-locké est conservé dans `asset_usage.json` :

- 5 660 fichiers inspectés ;
- 5 546 classés comme utilisés au runtime ;
- 87 candidats automatiques à la suppression ;
- SHA du manifeste :
  `d77be7e540cb9d65f43e12e02fd34019623a3453986582155abaea590143b733`.

La suppression n’a pas été appliquée. Parmi les 87 candidats se trouvent les
18 feuilles alpha/chroma `port_reference_v3` que le builder charge par chemins
construits dynamiquement. Le scanner textuel ne sait pas reconstituer ces
chemins et produit donc des faux positifs démontrables. Les autres candidats
appartiennent à des familles v2 et à un chantier concurrent ; les supprimer
aurait dépassé le périmètre sûr du lot.

## Conclusion

Le nettoyage sûr du lot est terminé au niveau modulaire. Une suppression de
fichiers physiques demanderait d’abord d’enseigner au scanner le graphe des
sources de build dynamiques, puis de refaire un dry-run revu manuellement.
~~~~
