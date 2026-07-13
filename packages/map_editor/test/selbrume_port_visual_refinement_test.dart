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
    expect(requiredPortVisualModuleIds, hasLength(14));
    expect(
      requiredPortVisualModuleIds,
      isNot(contains(anyOf(<String>[
        'module_port_ref_wall_h_short',
        'module_port_ref_wall_h_long',
        'module_port_ref_wall_end_left',
        'module_port_ref_wall_end_right',
        'module_port_ref_garden_gate_open',
        'module_port_ref_quay_pier_join',
        'module_port_ref_pier_endcap',
        'module_port_ref_wall_west_left_run',
        'module_port_ref_wall_west_right_run',
        'module_port_ref_wall_captain_left_run',
        'module_port_ref_wall_captain_right_run',
        'module_port_ref_flower_bed_compact',
        'module_port_ref_pier_t_open',
        'module_port_ref_pier_vertical_open',
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
    expect(
      portVisualComposition
          .where(
            (placement) => <String>{
              'west_house_garden',
              'harbor_master_terrace',
            }.contains(placement.group),
          )
          .map(
            (placement) => (
              placement.group,
              placement.moduleId,
              placement.layerId,
              placement.x,
              placement.y,
            ),
          )
          .toList(),
      <(String, String, String, int, int)>[
        (
          'west_house_garden',
          'module_port_ref_west_house_garden_complete',
          'l_tile_port_ref_backdrop',
          7,
          5,
        ),
        (
          'harbor_master_terrace',
          'module_port_ref_captain_terrace_complete',
          'l_tile_port_ref_backdrop',
          18,
          5,
        ),
      ],
    );
    final steps = portVisualComposition.singleWhere(
      (placement) => placement.moduleId == 'module_port_ref_quay_steps_compact',
    );
    expect((steps.x, steps.y), (17, 16));
    expect(
      portVisualComposition
          .where(
            (placement) => <String>{
              'module_port_ref_pier_west_l',
              'module_port_ref_pier_center_u',
              'module_port_ref_pier_east_hook',
            }.contains(placement.moduleId),
          )
          .map(
            (placement) => (placement.moduleId, placement.x, placement.y),
          )
          .toList(),
      <(String, int, int)>[
        ('module_port_ref_pier_west_l', 7, 20),
        ('module_port_ref_pier_center_u', 17, 20),
        ('module_port_ref_pier_east_hook', 31, 20),
      ],
    );
    expect(
      portVisualEntryComposition
          .map(
            (placement) => (placement.entryId, placement.x, placement.y),
          )
          .toList(),
      <(String, int, int)>[
        ('el_port_ref_coast_west_continuous', 0, 0),
      ],
    );
    final quay = portVisualComposition.singleWhere(
      (placement) => placement.moduleId == 'module_port_ref_quay_continuous',
    );
    expect((quay.x, quay.y), (5, 17));
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

  test('moves the visual north avenue to the north-east reference corridor',
      () {
    final cells = buildVisualPavementCells();

    expect(cells[28], isFalse, reason: 'the old central avenue is removed');
    expect(cells[42], isTrue, reason: 'the reference exits north-east');
    expect(cells[9 * portVisualMapWidth + 40], isTrue);
  });

  test('builds continuous visual water below and underneath every dock', () {
    final cells = buildVisualWaterCells();
    bool waterAt(int x, int y) => cells[y * portVisualMapWidth + x];

    for (final x in <int>[5, 9, 18, 22, 31, 36]) {
      expect(waterAt(x, 21), isTrue, reason: 'water below dock at x=$x');
    }
    expect(waterAt(36, 23), isTrue);
    expect(waterAt(37, 23), isFalse);
    expect(waterAt(39, 24), isTrue);
    expect(waterAt(40, 24), isFalse);
    expect(waterAt(42, 25), isTrue);
    expect(waterAt(43, 25), isFalse);
    expect(waterAt(44, 26), isTrue);
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
    for (final layerId in <String>{'l_tile_port_ref_overhead'}) {
      expect(
        (_layer(after, layerId)['tiles'] as List).where((value) => value != 0),
        isEmpty,
        reason: 'the restrained pass has no justified $layerId pixels',
      );
    }
    expect(
      after['properties'],
      containsPair('visualRefinerStatus', 'candidate_pending_owner_approval'),
    );
    expect(
      _layer(after, 'l_path_secondary')['cells'],
      buildVisualWaterCells(),
      reason: 'the refiner owns the deterministic visual water mask only',
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
      <String, dynamic>{
        'id': 'l_path_secondary',
        'runtimeType': 'path',
        'opacity': 1.0,
        'presetId': 'path_selbrume_port_water_v3',
        'cells': <bool>[
          ...List<bool>.filled(portVisualMapCellCount - 1, false),
          true,
        ],
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
