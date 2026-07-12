import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../tool/rebuild_selbrume_port_brisants_from_reference.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('rebuilds only Port des Brisants as an editable reference map',
      () async {
    final fixture = _copyFixture();
    addTearDown(() => fixture.parent.delete(recursive: true));

    final dryRun = await rebuildSelbrumePortBrisantsFromReference(
      SelbrumePortReferenceRebuildOptions(projectRoot: fixture),
    );
    expect(dryRun.exitCode, selbrumePortReferenceDivergenceExitCode);
    expect(dryRun.divergentRelativePaths, <String>[
      'project.json',
      selbrumePortReferenceMapRelativePath,
    ]);

    final first = await rebuildSelbrumePortBrisantsFromReference(
      SelbrumePortReferenceRebuildOptions(
        projectRoot: fixture,
        write: true,
      ),
    );
    expect(first.exitCode, 0);
    expect(first.placedElementCount, 68);
    expect(first.referenceElementCount, 35);

    final projectFile = File(p.join(fixture.path, 'project.json'));
    final mapFile = File(
      p.join(fixture.path, selbrumePortReferenceMapRelativePath),
    );
    final firstProjectBytes = projectFile.readAsBytesSync();
    final firstMapBytes = mapFile.readAsBytesSync();
    final manifest = ProjectManifest.fromJson(
      _decodeObject(projectFile.readAsStringSync()),
    );
    final map = MapData.fromJson(_decodeObject(mapFile.readAsStringSync()));

    expect(map.size, const GridSize(width: 45, height: 34));
    expect(map.properties['tileLayerOrder'], 'bottom_to_top');
    expect(map.properties['referenceRuntimeUnderlay'], isFalse);
    expect(
      map.properties['referenceVisualStatus'],
      'candidate_pending_owner_approval',
    );

    final tilesetIds = manifest.tilesets.map((entry) => entry.id).toSet();
    expect(
      tilesetIds,
      containsAll(<String>{
        'ts_selbrume_port_reference_v3',
        'ts_selbrume_port_ground_v3',
        'ts_selbrume_port_water_v3',
      }),
    );
    expect(
      tilesetIds.intersection(<String>{
        'ts_selbrume_boat',
        'ts_selbrume_port_props',
      }),
      isEmpty,
    );
    expect(tilesetIds, contains('ts_selbrume_open_sea_loop'));
    final nativePavement = manifest.pathPresets.singleWhere(
      (preset) => preset.id == 'pavement_path',
    );
    expect(nativePavement.name, 'pavement path');
    expect(nativePavement.tilesetId, 'pavement_path');
    expect(nativePavement.variants, isNotEmpty);

    final provenance = _decodeObject(
      File(
        p.join(
          fixture.path,
          'assets',
          'provenance',
          'selbrume_port_reference_v3.json',
        ),
      ).readAsStringSync(),
    );
    final referenceIds = ((provenance['entries'] as List)
        .cast<Map>()
        .map((entry) => entry['id'] as String)
        .toSet());
    final registeredReferenceIds = manifest.elements
        .map((entry) => entry.id)
        .where((id) => id.startsWith('el_port_ref_'))
        .toSet();
    final usedReferenceIds = map.placedElements
        .map((entry) => entry.elementId)
        .where((id) => id.startsWith('el_port_ref_'))
        .toSet();
    expect(referenceIds, hasLength(35));
    expect(registeredReferenceIds, referenceIds);
    expect(usedReferenceIds, referenceIds);
    expect(
      manifest.elements
          .any((entry) => entry.id.startsWith('el_selbrume_port_')),
      isFalse,
    );

    final pathLayers = <String, PathLayer>{
      for (final layer in map.layers.whereType<PathLayer>()) layer.id: layer,
    };
    expect(pathLayers['l_path_secondary']!.cells.where((cell) => cell),
        hasLength(560));
    expect(pathLayers['l_path_secondary']!.animationMode,
        PathAnimationMode.alwaysActive);
    expect(pathLayers['l_path_primary']!.isVisible, isTrue);
    for (var index = 0;
        index < pathLayers['l_path_primary']!.cells.length;
        index += 1) {
      expect(
        pathLayers['l_path_primary']!.cells[index] &&
            pathLayers['l_path_secondary']!.cells[index],
        isFalse,
        reason: 'pavement and open sea must be exclusive at cell $index',
      );
    }

    final patterns = manifest.pathPatternPresets.where(
      (preset) => preset.id == 'pattern_selbrume_port_water_v3',
    );
    expect(patterns, hasLength(1));
    expect(patterns.single.centerPattern.size.width, 8);
    expect(patterns.single.centerPattern.size.height, 8);
    expect(patterns.single.centerPattern.cells, hasLength(64));
    expect(
      patterns.single.centerPattern.cells
          .every((cell) => cell.frames.length == 8),
      isTrue,
    );
    expect(
      patterns.single.centerPattern.cells
          .expand((cell) => cell.frames)
          .every((frame) => frame.durationMs == 180),
      isTrue,
    );

    final environmentLayers = map.layers.whereType<EnvironmentLayer>().toList();
    expect(environmentLayers, hasLength(2));
    final generatedIds = <String>{
      for (final layer in environmentLayers)
        for (final area in layer.content.areas) ...area.generatedPlacementIds,
    };
    expect(generatedIds, hasLength(11));
    final placedById = <String, MapPlacedElement>{
      for (final placed in map.placedElements) placed.id: placed,
    };
    for (final id in generatedIds) {
      expect(placedById, contains(id));
      expect(
        placedById[id]!.properties['pokemapPlacementOrigin'],
        'environment',
      );
    }

    expect(placedById['pe_port_bateau']!.elementId, 'el_port_ref_boat_large');
    expect(placedById['pe_port_bateau']!.pos, const GridPos(x: 0, y: 22));
    expect(
      placedById['pe_port_hangar']!.elementId,
      'el_port_ref_chandlery',
    );
    expect(placedById['pe_port_hangar']!.pos, const GridPos(x: 31, y: 11));
    expect(
      placedById['pe_port_nid_goelise']!.elementId,
      'el_port_ref_nest',
    );
    expect(
      placedById['pe_port_nid_goelise']!.pos,
      const GridPos(x: 7, y: 9),
    );
    expect(
      placedById['pe_port_nid_goelise']!.properties['reservedForNarrative'],
      'true',
    );

    final collisions = map.layers.whereType<CollisionLayer>().single;
    expect(collisions.collisions, hasLength(45 * 34));
    expect(_collisionAt(collisions, 10, 25), isFalse,
        reason: 'left pier stays walkable');
    expect(_collisionAt(collisions, 22, 27), isFalse,
        reason: 'center pier stays walkable');
    expect(_collisionAt(collisions, 34, 27), isFalse,
        reason: 'right pier stays walkable');
    expect(_collisionAt(collisions, 15, 27), isTrue,
        reason: 'open sea remains blocked');
    expect(_collisionAt(collisions, 26, 0), isFalse,
        reason: 'north connection corridor stays open');
    final baseGround = map.layers
        .whereType<TileLayer>()
        .singleWhere((layer) => layer.id == 'l_tile_port_ref_base');
    final pavement = map.layers
        .whereType<PathLayer>()
        .singleWhere((layer) => layer.id == 'l_path_primary');
    final waterPath = map.layers
        .whereType<PathLayer>()
        .singleWhere((layer) => layer.id == 'l_path_secondary');
    final spriteGround = map.layers
        .whereType<TileLayer>()
        .singleWhere((layer) => layer.id == 'l_tile_port_ref_ground');
    expect(baseGround.tiles[25 * 45 + 10], 66,
        reason: 'static water remains under the walkable left pier');
    expect(baseGround.tilesetId, 'ts_selbrume_port_ground_v3');
    expect(spriteGround.tilesetId, 'ts_selbrume_port_reference_v3');
    expect(pavement.isVisible, isTrue);
    expect(pavement.presetId, 'pavement_path');
    expect(
      pavement.properties['paintAfterTileLayerId'],
      'l_tile_port_ref_base',
    );
    expect(pavement.cells.where((cell) => cell), isNotEmpty);
    expect(
      map.layers.indexOf(baseGround),
      lessThan(map.layers.indexOf(pavement)),
      reason: 'native pavement renders over the grass base',
    );
    expect(
      map.layers.indexOf(pavement),
      lessThan(map.layers.indexOf(waterPath)),
      reason: 'water remains above the land circulation layer',
    );

    expect(
      map.connections.single,
      const MapConnection(
        direction: MapConnectionDirection.north,
        targetMapId: 'map_bourg_selbrume',
        offset: 0,
      ),
    );
    expect(
        _triggerArea(map, 'zone_port_entry'),
        const MapRect(
            pos: GridPos(x: 26, y: 0), size: GridSize(width: 5, height: 4)));
    expect(
        _triggerArea(map, 'zone_port_center'),
        const MapRect(
            pos: GridPos(x: 17, y: 10), size: GridSize(width: 14, height: 8)));
    expect(
        _triggerArea(map, 'tr_port_rival_scene'),
        const MapRect(
            pos: GridPos(x: 23, y: 15), size: GridSize(width: 8, height: 3)));
    expect(
        _triggerArea(map, 'tr_port_nest'),
        const MapRect(
            pos: GridPos(x: 7, y: 9), size: GridSize(width: 2, height: 2)));

    final clean = await rebuildSelbrumePortBrisantsFromReference(
      SelbrumePortReferenceRebuildOptions(projectRoot: fixture),
    );
    expect(clean.exitCode, 0);
    expect(clean.divergentRelativePaths, isEmpty);
    await rebuildSelbrumePortBrisantsFromReference(
      SelbrumePortReferenceRebuildOptions(
        projectRoot: fixture,
        write: true,
      ),
    );
    expect(projectFile.readAsBytesSync(), firstProjectBytes);
    expect(mapFile.readAsBytesSync(), firstMapBytes);
  });
}

Directory _copyFixture() {
  final repositoryRoot = _findRepositoryRoot();
  final source = Directory(p.join(repositoryRoot.path, 'selbrume'));
  final parent = Directory.systemTemp.createTempSync('port_ref_rebuild_');
  final fixture = Directory(p.join(parent.path, 'selbrume'))
    ..createSync(recursive: true);
  File(p.join(source.path, 'project.json'))
      .copySync(p.join(fixture.path, 'project.json'));
  final maps = Directory(p.join(fixture.path, 'maps'))..createSync();
  File(p.join(source.path, selbrumePortReferenceMapRelativePath)).copySync(
    p.join(maps.path, 'map_port_brisants.json'),
  );
  final provenance = Directory(
    p.join(fixture.path, 'assets', 'provenance'),
  )..createSync(recursive: true);
  File(
    p.join(
      source.path,
      'assets',
      'provenance',
      'selbrume_port_reference_v3.json',
    ),
  ).copySync(p.join(provenance.path, 'selbrume_port_reference_v3.json'));
  final projectFile = File(p.join(fixture.path, 'project.json'));
  final project = _decodeObject(projectFile.readAsStringSync());
  (project['tilesets'] as List).removeWhere(
    (entry) => entry is Map && entry['id'] == 'ts_selbrume_port_ground_v3',
  );
  projectFile.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(project)}\n',
  );
  final mapFile = File(p.join(maps.path, 'map_port_brisants.json'));
  final map = _decodeObject(mapFile.readAsStringSync());
  (map['size'] as Map)['height'] = 45;
  mapFile.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(map)}\n',
  );
  return fixture;
}

bool _collisionAt(CollisionLayer layer, int x, int y) {
  return layer.collisions[y * 45 + x];
}

MapRect _triggerArea(MapData map, String id) {
  return map.triggers.singleWhere((trigger) => trigger.id == id).area;
}

Map<String, dynamic> _decodeObject(String source) {
  return (jsonDecode(source) as Map).cast<String, dynamic>();
}

Directory _findRepositoryRoot() {
  var current = Directory.current.absolute;
  while (true) {
    if (File(p.join(current.path, 'AGENTS.md')).existsSync() &&
        Directory(p.join(current.path, 'selbrume')).existsSync()) {
      return current;
    }
    if (current.parent.path == current.path) {
      throw StateError('Repository root not found.');
    }
    current = current.parent;
  }
}
