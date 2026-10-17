import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../assets/resource_library_actions_test.dart' show librarySnapshot;
import 'border_spatial_actions_test.dart'
    show spatialBorderAuthoringFixture, context;

void main() {
  for (final materialized in [false, true]) {
    test(
        'native move preserves a manually varied primitive with stale output $materialized',
        () async {
      final fixture = spatialBorderAuthoringFixture(published: true);
      final raw = encodeBorderBlueprintRecordJson(
          fixture.project.borderCatalog.records.single,
          formatVersion: 5);
      for (final key in ['draft', 'latestPublished']) {
        final primitives =
            ((raw[key] as Map)['definition'] as Map)['primitives'] as List;
        final straight = Map<String, Object?>.from(
            primitives.singleWhere((p) => p['role'] == 'lineStraight') as Map);
        primitives.add({...straight, 'id': 'lineStraight-variant'});
      }
      final project = fixture.project.copyWith(
          borderCatalog: ProjectBorderCatalog(formatVersion: 5, records: [
        decodeBorderBlueprintRecordJson(raw, formatVersion: 5)
      ]));
      SpatialBorderResolutionResult resolve(MapData map) =>
          resolveSpatialBorderFeature(
              manifest: project,
              map: map,
              layerId: 'border',
              featureId: 'fence');
      final base = resolve(fixture.map);
      final source = materialized
          ? applySpatialBorderFeaturePreview(fixture.map,
              manifest: project, proposedResult: base)
          : fixture.map;
      final slot = base.result.materialization!.spatialPlacements
          .singleWhere((p) => p.primitiveId.startsWith('lineStraight'));
      final varied = await _mutate(
          source,
          project,
          'border_layer.feature_set_variation',
          {'slotKey': slot.slotKey, 'variationSalt': '44'});
      final original = resolve(varied);
      final moved = await _mutate(
          varied, project, 'border_layer.feature_move', {'dx': 1, 'dy': 1});
      final result = resolve(moved);
      expect(result.result.canApply, isTrue);
      expect(
          result.result.materialization!.spatialPlacements
              .singleWhere((p) => p.primitiveId.startsWith('lineStraight'))
              .primitiveId,
          original.result.materialization!.spatialPlacements
              .singleWhere((p) => p.primitiveId.startsWith('lineStraight'))
              .primitiveId);
      final applied = applySpatialBorderFeaturePreview(moved,
          manifest: project, proposedResult: result);
      final reopened =
          MapData.fromJson(jsonDecode(jsonEncode(applied.toJson())));
      expect(resolve(reopened).result.materialization!.spatialPlacements,
          result.result.materialization!.spatialPlacements);
      final corrected = reopened.layers
          .whereType<BorderLayer>()
          .single
          .content
          .features
          .single
          .overrides
          .single;
      expect(
          corrected.replacementPrimitiveId,
          original.result.materialization!.spatialPlacements
              .singleWhere((p) => p.primitiveId.startsWith('lineStraight'))
              .primitiveId);
      final cleared = await _mutate(
          reopened,
          project,
          'border_layer.feature_set_replacement',
          {'slotKey': corrected.slotKey, 'primitiveId': null});
      final restored = cleared.layers
          .whereType<BorderLayer>()
          .single
          .content
          .features
          .single
          .overrides
          .single;
      expect(restored.replacementPrimitiveId, isNull);
      expect(restored.variationSalt, BorderSignedInt64.fromInt(44));
    });
  }
  test('native move tolerates an overridden slot excluded from output',
      () async {
    final fixture = spatialBorderAuthoringFixture(published: true);
    final base = resolveSpatialBorderFeature(
        manifest: fixture.project,
        map: fixture.map,
        layerId: 'border',
        featureId: 'fence');
    var map = updateBorderFeatureOverrides(fixture.map,
        layerId: 'border',
        featureId: 'fence',
        overrides: [
          BorderSlotOverride(
              slotKey:
                  base.result.materialization!.spatialPlacements.first.slotKey,
              variationSalt: BorderSignedInt64.fromInt(44),
              suppressed: false,
              locked: false)
        ]);
    map = updateBorderFeatureKeepOutRegions(map,
        layerId: 'border',
        featureId: 'fence',
        keepOutRegions: [
          BorderKeepOutRegion(
              id: 'excluded',
              region: BorderRegionGeometry(
                  width: map.size.width,
                  height: map.size.height,
                  cells: List.filled(map.size.width * map.size.height, true)))
        ]);
    final moved = await _mutate(
        map, fixture.project, 'border_layer.feature_move', {'dx': 1, 'dy': 1});
    final result = resolveSpatialBorderFeature(
        manifest: fixture.project,
        map: moved,
        layerId: 'border',
        featureId: 'fence');
    expect(result.result.canApply, isTrue);
    expect(result.modelInstances, isEmpty);
    expect(
        moved.layers
            .whereType<BorderLayer>()
            .single
            .content
            .features
            .single
            .overrides
            .single
            .replacementPrimitiveId,
        isNull);
  });
  test('native move refuses locked slots and leaves source data intact',
      () async {
    final fixture = spatialBorderAuthoringFixture(published: true);
    final base = resolveSpatialBorderFeature(
        manifest: fixture.project,
        map: fixture.map,
        layerId: 'border',
        featureId: 'fence');
    var map = applySpatialBorderFeaturePreview(fixture.map,
        manifest: fixture.project, proposedResult: base);
    final slot = base.result.materialization!.spatialPlacements.first;
    map = updateBorderFeatureOverrides(map,
        layerId: 'border',
        featureId: 'fence',
        overrides: [
          BorderSlotOverride(
              slotKey: slot.slotKey,
              variationSalt: BorderSignedInt64.zero,
              suppressed: false,
              locked: true,
              lockedInstanceId: slot.instanceId)
        ]);
    final bytes = jsonEncode(map.toJson());
    await expectLater(
        _mutate(map, fixture.project, 'border_layer.feature_move',
            {'dx': 1, 'dy': 1}),
        throwsA(isA<ValidationException>().having((error) => error.toString(),
            'message', contains('Unlock spatial Border'))));
    expect(jsonEncode(map.toJson()), bytes);
  });
  test('native move refuses out of bounds geometry without changes', () async {
    final fixture = spatialBorderAuthoringFixture(published: true);
    final bytes = jsonEncode(fixture.map.toJson());
    await expectLater(
        _mutate(fixture.map, fixture.project, 'border_layer.feature_move',
            {'dx': -2, 'dy': 0}),
        throwsA(isA<MapAuthoringException>().having(
            (error) => error.code, 'code', 'border.feature_out_of_bounds')));
    expect(jsonEncode(fixture.map.toJson()), bytes);
  });
  for (final corrected in [false, true]) {
    test(
        'native move preserves erased fragments with local correction $corrected',
        () async {
      final fixture = spatialBorderAuthoringFixture(published: true);
      var map = fixture.map.copyWith(
          size: const GridSize(width: 10, height: 5),
          spatialScene: MapSpatialScene(
              width: 10, depth: 5, heightLevels: List.filled(50, 1)));
      map = updateBorderFeatureGeometry(map,
          layerId: 'border',
          featureId: 'fence',
          geometry: BorderStrokeGeometry(strokes: [
            BorderStroke(
                id: 'line',
                points: [for (var x = 1; x <= 7; x++) GridPos(x: x, y: 1)],
                closed: false)
          ]));
      map = const BorderActions().eraseStroke(
          manifest: fixture.project,
          map: map,
          layerId: 'border',
          featureId: 'fence',
          sampledPoints: const [GridPos(x: 4, y: 1)]);
      final fragments = (map.layers
              .whereType<BorderLayer>()
              .single
              .content
              .features
              .single
              .geometry as BorderStrokeGeometry)
          .strokes;
      expect(fragments, hasLength(2));
      expect(
          fragments.every(
              (s) => resolveBorderStrokeLineageIdentityV1(s).preserveTraversal),
          isTrue);
      SpatialBorderResolutionResult resolve(MapData value) =>
          resolveSpatialBorderFeature(
              manifest: fixture.project,
              map: value,
              layerId: 'border',
              featureId: 'fence');
      if (corrected) {
        final base = resolve(map);
        final instance =
            base.modelInstances.singleWhere((i) => i.position.x == 2.5);
        final slot = base.result.materialization!.spatialPlacements
            .singleWhere((p) => p.instanceId == instance.id);
        map = await _mutate(
            map, fixture.project, 'border_layer.feature_set_transform', {
          'slotKey': slot.slotKey,
          'transformOverride': {'quarterTurns': 2, 'flipX': false}
        });
      }
      final before = resolve(map);
      final moved = await _mutate(map, fixture.project,
          'border_layer.feature_move', {'dx': 1, 'dy': 1});
      final result = resolve(moved);
      expect(result.result.canApply, isTrue,
          reason: result.result.diagnostics.map((d) => d.code).join(','));
      expect(result.modelInstances, hasLength(6));
      for (var i = 0; i < result.modelInstances.length; i++) {
        final original = before.modelInstances[i],
            after = result.modelInstances[i];
        expect(after.modelId, original.modelId);
        expect(after.rotationDegrees, original.rotationDegrees);
        expect(after.position.x - original.position.x, closeTo(1, 1e-10));
        expect(after.position.z - original.position.z, closeTo(1, 1e-10));
      }
      final saved = applySpatialBorderFeaturePreview(moved,
          manifest: fixture.project, proposedResult: result);
      final reopened = MapData.fromJson(jsonDecode(jsonEncode(saved.toJson())));
      expect(resolve(reopened).result.materialization,
          result.result.materialization);
    });
  }
  for (final materialized in [false, true]) {
    test(
        'native move carries replacement, transform and suppression ${materialized ? 'after materialization' : 'before materialization'}',
        () async {
      final fixture = spatialBorderAuthoringFixture(published: true);
      var map = fixture.map;
      SpatialBorderResolutionResult resolve(MapData value) =>
          resolveSpatialBorderFeature(
              manifest: fixture.project,
              map: value,
              layerId: 'border',
              featureId: 'fence');
      final placements = resolve(map).result.materialization!.spatialPlacements;
      final body =
          placements.singleWhere((p) => p.primitiveId == 'lineStraight');
      final cap = placements.firstWhere((p) => p.primitiveId == 'lineCap');
      map = updateBorderFeatureOverrides(map,
          layerId: 'border',
          featureId: 'fence',
          overrides: [
            BorderSlotOverride(
                slotKey: body.slotKey,
                variationSalt: BorderSignedInt64.fromInt(44),
                suppressed: false,
                locked: false,
                replacementPrimitiveId: 'lineStraight',
                transformOverride:
                    BorderSpriteTransform(quarterTurns: 2, flipX: false)),
            BorderSlotOverride(
                slotKey: cap.slotKey,
                variationSalt: BorderSignedInt64.fromInt(7),
                suppressed: true,
                locked: false),
          ]);
      final original = resolve(map);
      expect(original.result.canApply, isTrue);
        if (materialized) {
        map = applySpatialBorderFeaturePreview(map,
            manifest: fixture.project, proposedResult: original);
        }
      final draft = await MapMutationDispatcher.canonical().build(context(
          librarySnapshot([map], project: fixture.project),
          'border_layer.feature_move', {
        'mapId': 'map',
        'layerId': 'border',
        'featureId': 'fence',
        'dx': 1,
        'dy': 1
      }));
      final moved = MapData.fromJson(
          jsonDecode(utf8.decode(draft.changeSet.changes.single.afterBytes!)));
      final result = resolve(moved);
      expect(result.result.canApply, isTrue,
          reason: result.result.diagnostics.map((d) => d.code).join(','));
      expect(result.modelInstances, hasLength(2));
      final feature =
          moved.layers.whereType<BorderLayer>().single.content.features.single;
      expect(feature.overrides, hasLength(2));
      final replacement = feature.overrides.singleWhere((o) => !o.suppressed);
      expect(replacement.slotKey, isNot(body.slotKey));
      expect(replacement.variationSalt, BorderSignedInt64.fromInt(44));
      expect(replacement.replacementPrimitiveId, 'lineStraight');
      expect(replacement.transformOverride!.quarterTurns, 2);
      for (var i = 0; i < result.modelInstances.length; i++) {
        final before = original.modelInstances[i];
        final after = result.modelInstances[i];
        expect(after.modelId, before.modelId);
        expect(after.rotationDegrees, before.rotationDegrees);
        expect(after.position.x - before.position.x, closeTo(1, 1e-10));
        expect(after.position.z - before.position.z, closeTo(1, 1e-10));
      }
      final applied = applySpatialBorderFeaturePreview(moved,
          manifest: fixture.project, proposedResult: result);
      expect(applied.spatialScene!.instances, hasLength(2));
      expect(MapData.fromJson(applied.toJson()), applied);
    });
  }
  for (final directed in [false, true]) {
    test('native region move carries overrides with directed contour $directed',
        () async {
      final fixture = spatialBorderAuthoringFixture(published: true);
      var project = fixture.project;
      if (directed) {
        final raw = encodeBorderBlueprintRecordJson(
            project.borderCatalog.records.single,
            formatVersion: 5);
        for (final key in ['draft', 'latestPublished']) {
          final definition = (raw[key] as Map)['definition'] as Map;
          definition['followContourDirection'] = true;
          final primitives = definition['primitives'] as List;
          final corner = Map<String, Object?>.from(
              primitives.singleWhere((p) => p['role'] == 'lineCorner') as Map);
          primitives.removeWhere((p) => p['role'] == 'lineCorner');
          primitives
              .add({...corner, 'id': 'corner-right', 'cornerTurn': 'right'});
          primitives
              .add({...corner, 'id': 'corner-left', 'cornerTurn': 'left'});
        }
        project = project.copyWith(
            borderCatalog: ProjectBorderCatalog(formatVersion: 5, records: [
          decodeBorderBlueprintRecordJson(raw, formatVersion: 5)
        ]));
      }
      var map = fixture.map.copyWith(
          size: const GridSize(width: 6, height: 6),
          spatialScene: MapSpatialScene(
              width: 6, depth: 6, heightLevels: List.filled(36, 1)));
      map = updateBorderFeatureGeometry(map,
          layerId: 'border',
          featureId: 'fence',
          geometry: BorderRegionGeometry(width: 6, height: 6, cells: [
            for (var y = 0; y < 6; y++)
              for (var x = 0; x < 6; x++)
                x >= 1 && x <= 3 && y >= 1 && y <= 3 && !(x == 2 && y == 2),
          ]));
      SpatialBorderResolutionResult resolve(MapData value) =>
          resolveSpatialBorderFeature(
              manifest: project,
              map: value,
              layerId: 'border',
              featureId: 'fence');
      final base = resolve(map);
      expect(base.result.canApply, isTrue);
      final placement = base.result.materialization!.spatialPlacements.first;
      map = updateBorderFeatureOverrides(map,
          layerId: 'border',
          featureId: 'fence',
          overrides: [
            BorderSlotOverride(
                slotKey: placement.slotKey,
                variationSalt: BorderSignedInt64.fromInt(19),
                suppressed: true,
                locked: false),
          ]);
      final original = resolve(map);
      map = applySpatialBorderFeaturePreview(map,
          manifest: project, proposedResult: original);
      final draft = await MapMutationDispatcher.canonical().build(context(
          librarySnapshot([map], project: project),
          'border_layer.feature_move', {
        'mapId': 'map',
        'layerId': 'border',
        'featureId': 'fence',
        'dx': 1,
        'dy': 1
      }));
      final moved = MapData.fromJson(
          jsonDecode(utf8.decode(draft.changeSet.changes.single.afterBytes!)));
      final result = resolve(moved);
      expect(result.result.canApply, isTrue,
          reason: result.result.diagnostics.map((d) => d.code).join(','));
      expect(result.modelInstances.length, original.modelInstances.length);
      final override = moved.layers
          .whereType<BorderLayer>()
          .single
          .content
          .features
          .single
          .overrides
          .single;
      expect(override.slotKey, isNot(placement.slotKey));
      expect(override.suppressed, isTrue);
      expect(override.variationSalt, BorderSignedInt64.fromInt(19));
      final expectedPositions = original.modelInstances
          .map((i) => '${i.position.x + 1},${i.position.y},${i.position.z + 1}')
          .toSet();
      expect(
          result.modelInstances
              .map((i) => '${i.position.x},${i.position.y},${i.position.z}')
              .toSet(),
          expectedPositions);
    });
  }
}

Future<MapData> _mutate(MapData map, ProjectManifest project, String action,
    Map<String, Object?> parameters) async {
  final draft = await MapMutationDispatcher.canonical().build(context(
      librarySnapshot([map], project: project), action, {
    'mapId': 'map',
    'layerId': 'border',
    'featureId': 'fence',
    ...parameters
  }));
  return MapData.fromJson(
      jsonDecode(utf8.decode(draft.changeSet.changes.single.afterBytes!)));
}
