import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/src/domains/maps/map3d_edit_batch_actions.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../../support/reliability_map_fixture.dart';
import '../assets/resource_library_actions_test.dart' show librarySnapshot;
import 'border_spatial_actions_test.dart' show context;

void main() {
  test('an unknown intent version is rejected before projection',() {
    final f=ReliabilityMapContent.create(ReliabilityMapVariant.interiorHole);
    expect(()=>const Map3dEditBatchActions().build(context(librarySnapshot([f.map],project:f.project),
      'map3d.edit_batch',{'mapId':'map','operations':[{'actionId':'intent.ground.fill','actionVersion':999,
        'parameters':{'cells':[{'x':12,'y':8}]}}]})),throwsA(isA<MapAuthoringException>()
          .having((error)=>(error.details['cause'] as Map)['code'],'cause','intent.version_unsupported')));
    expect(_material(f.map,12,8),isNull);
  });
  test(
      'named material is canonical and ambiguity has candidates without mutation',
      () {
    final f = ReliabilityMapContent.create(ReliabilityMapVariant.healthy);
    final after = _decode(_build(f.project, f.map, 'smart_tile.cell.paint', {
      'layerId': 'terrain',
      'material': {'name': ' MER '},
      'cells': [
        {'x': 12, 'y': 8}
      ],
    }));
    expect(_material(after, 12, 8), 'sea');
    final ambiguous =
        ReliabilityMapContent.create(ReliabilityMapVariant.ambiguousMaterial);
    final original = ambiguous.map.toJson();
    expect(
        () =>
            _build(ambiguous.project, ambiguous.map, 'smart_tile.cell.paint', {
              'layerId': 'terrain',
              'material': {'name': 'mer'},
              'cells': [
                {'x': 12, 'y': 8}
              ],
            }),
        throwsA(isA<MapAuthoringException>()
            .having((e) => (e.details['cause'] as Map)['code'], 'cause',
                'intent.material_ambiguous')
            .having(
                (e) => ((e.details['cause'] as Map)['details']
                    as Map)['candidates'],
                'candidates',
                hasLength(2))));
    expect(ambiguous.map.toJson(), original);
  });

  test('fill infers a unique native ground and refuses an unsupported void',
      () {
    final f = ReliabilityMapContent.create(ReliabilityMapVariant.interiorHole);
    final after = _decode(_build(f.project, f.map, 'intent.ground.fill', {
      'cells': [
        {'x': 12, 'y': 8}
      ],
    }));
    expect(_material(after, 12, 8), 'grass');
    expect(_material(after, 11, 8), _material(f.map, 11, 8));
  });

  test('removing a real ground-replacing shore restores its footprint', () {
    final f = ReliabilityMapContent.create(ReliabilityMapVariant.shoreGap);
    final before = inspectSpatialMapIntegrity(manifest: f.project, map: f.map);
    expect(before.exposedCellCount, 0);
    final draft =
        _build(f.project, f.map, 'intent.border.remove_keeping_ground', {
      'layerId': 'border',
      'featureId': 'fence',
      'groundLayerId': 'terrain',
    });
    final after = _decode(draft);
    final resolved=((draft.preview['operations'] as List).single as Map)['resolvedOperations'] as List;
    expect((resolved.last as Map)['actionId'],'border_layer.feature_delete');
    expect((resolved.first as Map)['actionId'],'smart_tile.cell.paint_batch');
    expect(
        after.layers.whereType<BorderLayer>().single.content.features, isEmpty);
    for (var x = 3; x <= 6; x++) {
      expect(_material(after, x, f.contourY), 'grass');
    }
    expect(
        inspectSpatialMapIntegrity(manifest: f.project, map: after)
            .exposedCellCount,
        0);
  });

  test(
      'clear over object removes only colliding slots and preserves the object',
      () {
    final f = ReliabilityMapContent.create(ReliabilityMapVariant.dockOverlap);
    final report = inspectSpatialMapIntegrity(manifest: f.project, map: f.map);
    final overlap = report.borderObjectOverlaps.first;
    final original = f.feature.materialization!.spatialPlacements;
    final after =
        _decode(_build(f.project, f.map, 'intent.border.clear_over_object', {
      'layerId': 'border',
      'featureId': 'fence',
      'instanceId': overlap.instanceId,
    }));
    final feature =
        after.layers.whereType<BorderLayer>().single.content.features.single;
    expect(
        feature.materialization!.spatialPlacements
            .map((slot) => slot.slotKey)
            .toSet(),
        original
            .map((slot) => slot.slotKey)
            .toSet()
            .difference(overlap.slotKeys.toSet()));
    expect(
        after.spatialScene!.instances
            .any((instance) => instance.id == overlap.instanceId),
        isTrue);
  });

  test(
      'trace uses the real height step and preserves existing feature identity',
      () {
    for (final repair in [false, true]) {
      final f = ReliabilityMapContent.create(repair
          ? ReliabilityMapVariant.healthy
          : ReliabilityMapVariant.missingCliff);
      var map = f.map;
      if (repair) {
        map = updateBorderFeatureGeometry(map,
            layerId: 'border',
            featureId: 'fence',
            geometry: BorderStrokeGeometry(strokes: [
              BorderStroke(
                  id: 'step',
                  closed: false,
                  points: [for (var x = 3; x <= 6; x++) GridPos(x: x, y: 6)])
            ]));
      }
      final draft = _build(f.project, map, 'intent.border.trace_step', {
        'layerId': 'border',
        'featureId': repair ? 'fence' : 'new-step',
        'blueprintId': 'fence',
        'lowerHeight': 0,
        'upperHeight': 1,
        'region': {'x': 2, 'y': 2, 'width': 6, 'height': 5},
      });
      final after = _decode(draft);
      final feature =
          after.layers.whereType<BorderLayer>().single.content.features.single;
      expect(feature.id, repair ? 'fence' : 'new-step');
      expect((feature.geometry as BorderStrokeGeometry).alignment,
          BorderStrokeAlignment.gridEdges);
      final diagnostics = diagnoseSpatialBorderFeature(
              manifest: f.project,
              map: after,
              layerId: 'border',
              featureId: feature.id)
          .diagnostics;
      expect(
          diagnostics.where((d) =>
              d.code.endsWith('face_crown_mismatch') ||
              d.code.endsWith('face_base_mismatch')),
          isEmpty);
      expect(feature.materialization, isNotNull);
      expect(diagnostics.where((d) => d.code.endsWith('materialization_stale')),
          isEmpty);
    }
  });
}

AuthoringMutationDraft _build(ProjectManifest project, MapData map,
    String action, Map<String, Object?> parameters) {
  return const Map3dEditBatchActions().build(
      context(librarySnapshot([map], project: project), 'map3d.edit_batch', {
    'mapId': map.id,
    'operations': [
      {'actionId': action, 'actionVersion': 1, 'parameters': parameters}
    ],
  }));
}

MapData _decode(AuthoringMutationDraft draft) =>
    MapData.fromJson(Map<String, dynamic>.from(
        jsonDecode(utf8.decode(draft.changeSet.changes.single.afterBytes!))
            as Map));

String? _material(MapData map, int x, int y) =>
    smartTileMaterialIdAt(map.layers.whereType<SmartTileLayer>().first,
        mapSize: map.size, x: x, y: y);
