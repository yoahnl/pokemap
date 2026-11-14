import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/src/domains/maps/map3d_edit_batch_actions.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../assets/resource_library_actions_test.dart' show librarySnapshot;
import 'border_spatial_actions_test.dart' show context;
import 'spatial_terrain_relief_fixture.dart';

void main() {
  final base = reliefBaseMap();

  test('raising a rectangle paints one surface and closes one cliff', () {
    final result = paintRelief(base, rect(6, 4, 10, 8), level: 2);
    final cliff = reliefStrokes(result.map, 'relief-1').single;
    expect(cliff.closed, isTrue);
    expect(cliff.points, hasLength(36));
    expect(reliefFeatureIds(result.map), ['relief-1']);
    expect(result.map.spatialScene!.worldHeightAt(8.5, 6.5), 2);
    expect(reliefDiagnostics(reliefProject, result.map, 'relief-1'), isEmpty);
    expect(result.preview['traces'], [
      {
        'lowerHeight': 1.0,
        'upperHeight': 2.0,
        'layerId': 'border',
        'featureId': 'relief-1',
        'blueprintId': 'fence',
        'change': 'created',
      },
    ]);
    expect(result.preview['warnings'], ['zone_unreachable']);
  });

  test('painting next to a plateau extends its cliff instead of adding one',
      () {
    final first = paintRelief(base, rect(6, 4, 4, 4), level: 2).map;
    final grown = paintRelief(first, rect(10, 4, 3, 4), level: 2);
    expect(reliefFeatureIds(grown.map), ['relief-1']);
    expect(reliefStrokes(grown.map, 'relief-1').single.points, hasLength(22));
    expect((grown.preview['traces'] as List).single,
        containsPair('change', 'updated'));
  });

  test('painting a lower level digs a hole and removing it clears the cliff',
      () {
    final plateau = paintRelief(base, rect(6, 4, 10, 8), level: 2).map;
    final holed = paintRelief(plateau, rect(9, 7, 3, 3), level: 1).map;
    expect(holed.spatialScene!.worldHeightAt(10.5, 8.5), 1);
    expect(reliefFeatureIds(holed), ['relief-1']);
    expect(reliefStrokes(holed, 'relief-1').map((s) => s.closed), [true, true]);
    final flat = paintRelief(holed, rect(6, 4, 10, 8), level: 1);
    expect(reliefFeatureIds(flat.map), isEmpty);
    expect(flat.map.spatialScene!.instances.map((i) => i.modelId).toSet(),
        {'tree'});
    expect((flat.preview['traces'] as List).single,
        containsPair('change', 'deleted'));
  });

  test('a terrace on the contour uses the two-level profile for 1 to 3', () {
    final project = withTwoLevelProfile(reliefProject);
    final plateau =
        paintRelief(base, rect(6, 4, 10, 8), level: 2, project: project).map;
    final terrace = paintRelief(plateau, rect(6, 6, 3, 3),
        level: 3, project: project, twoLevel: 'fence-2');
    final traces = {
      for (final trace in (terrace.preview['traces'] as List).cast<Map>())
        (trace['lowerHeight'], trace['upperHeight']): trace,
    };
    expect(traces.keys.toSet(), {(1.0, 2.0), (1.0, 3.0), (2.0, 3.0)});
    expect(traces[(1.0, 3.0)]!['blueprintId'], 'fence-2');
    expect(traces[(1.0, 2.0)]!['change'], 'updated');
    expect(
        reliefStrokes(terrace.map, traces[(1.0, 3.0)]!['featureId'])
            .single
            .points,
        [for (var y = 9; y >= 6; y--) GridPos(x: 6, y: y)]);
    for (final trace in traces.values) {
      expect(
          reliefDiagnostics(project, terrace.map, trace['featureId']), isEmpty);
    }
  });

  test('refusals name their cause and keep the map unchanged', () {
    final plateau = paintRelief(base, rect(6, 4, 10, 8), level: 2).map;
    expect(() => paintRelief(plateau, rect(6, 6, 3, 3), level: 3),
        throwsRelief('spatial.relief.two_level_profile_missing'));
    expect(() => paintRelief(base, rect(6, 4, 4, 4), level: 4),
        throwsRelief('spatial.relief.step_too_high'));
    expect(
        () => paintRelief(base, rect(6, 4, 4, 4),
            level: 2, project: leftHanded(reliefProject)),
        throwsRelief('spatial.relief.profile_faces_high_side'));
    expect(
        () => paintRelief(base, rect(6, 4, 4, 4),
            level: 2,
            project: withTwoLevelProfile(reliefProject),
            blueprint: 'fence-2'),
        throwsRelief('spatial.relief.profile_level_span'));
    expect(
        () => paintRelief(
            base,
            [
              ...rect(8, 5, 6, 2),
              ...rect(8, 7, 1, 1),
            ],
            level: 2,
            project: innerCornerJoins(reliefProject, 1)),
        throwsA(isA<MapAuthoringException>()
            .having((e) => e.code, 'code', 'spatial.relief.trace_refused')
            .having((e) => e.details['diagnostics'], 'diagnostics',
                contains('border.spatial.corner_join_conflict'))));
    expect(() => paintRelief(base, rect(6, 4, 4, 4), level: 2000),
        throwsRelief('spatial.relief.level_invalid'));
  });

  test('the action composes inside one atomic map edit', () {
    final draft = const Map3dEditBatchActions().build(context(
        librarySnapshot([base], project: reliefProject), 'map3d.edit_batch', {
      'mapId': 'map',
      'operations': [
        {
          'actionId': 'map3d.terrain.paint_height',
          'actionVersion': 1,
          'parameters': {
            'level': 2,
            'blueprintId': 'fence',
            'region': {'x': 6, 'y': 4, 'width': 10, 'height': 8},
          },
        },
      ],
    }));
    final map = MapData.fromJson(Map<String, dynamic>.from(
        jsonDecode(utf8.decode(draft.changeSet.changes.single.afterBytes!))
            as Map));
    expect(reliefFeatureIds(map), ['relief-1']);
    expect(draft.preview['status'], 'changed');
  });

  test('a relief edit resolves only its own cliff and the nearby ones', () {
    final far = paintRelief(base, rect(16, 4, 4, 4), level: 2).map;
    final first = paintRelief(far, rect(4, 4, 4, 4), level: 2);
    expect((first.preview['work'] as Map)['resolvedBorderFeatures'],
        ['border/relief-2']);
    final near = paintRelief(first.map, rect(10, 4, 3, 4), level: 2);
    final work = near.preview['work'] as Map;
    expect(work['resolvedBorderFeatures'], contains('border/relief-3'));
    expect(work['resolvedBorderFeatures'], contains('border/relief-2'));
    expect(work['resolvedBorderFeatures'], isNot(contains('border/relief-1')));
    expect(reliefFeatureIds(near.map), ['relief-1', 'relief-2', 'relief-3']);
  });
}
