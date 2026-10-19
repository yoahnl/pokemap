import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../assets/resource_library_actions_test.dart' show librarySnapshot;
import 'border_slot_override_actions_test.dart' show borderSlotOverrideFixture;
import 'border_spatial_actions_test.dart'
    show context, spatialBorderAuthoringFixture;

const _action = 'border_layer.materialize_batch_apply';
const _features = [
  {'layerId': 'border', 'featureId': 'fence'},
  {'layerId': 'other-border', 'featureId': 'other-fence'},
];

void main() {
  test('bounded atomic materialization contract is discoverable', () {
    final descriptor = MapMutationDispatcher.canonical()
        .descriptors
        .singleWhere((d) => d.id == _action);
    expect(descriptor.extensions['batchAtomicity'], 'all_or_nothing');
    expect(descriptor.extensions['maximumFeatureCount'], 128);
    final schema = descriptor.extensions['inputSchema'] as Map;
    expect(schema['additionalProperties'], false);
  });

  test('two layers equal sequential canonical materialization in one change',
      () async {
    final fixture = _fixture();
    final before = jsonEncode(fixture.map.toJson());
    var sequential = fixture.map;
    for (final feature in _features) {
      sequential = await _apply(fixture.project, sequential,
          'border_layer.materialize_apply', {'mapId': 'map', ...feature});
    }
    final draft = await _build(
        fixture.project, fixture.map, {'mapId': 'map', 'features': _features});
    expect(draft.changeSet.changes, hasLength(1));
    final result = _decode(draft);
    expect(result.toJson(), sequential.toJson());
    expect(result.layers.first, fixture.map.layers.first);
    expect(jsonEncode(fixture.map.toJson()), before);
    expect(draft.preview['featureCount'], 2);
  });

  test('invalid last target leaves the first target and source untouched',
      () async {
    final fixture = _fixture();
    final before = jsonEncode(fixture.map.toJson());
    await expectLater(
        _build(fixture.project, fixture.map, {
          'mapId': 'map',
          'features': [
            _features.first,
            {'layerId': 'border', 'featureId': 'absent'}
          ]
        }),
        throwsA(isA<MapAuthoringException>()
            .having((e) => e.code, 'code', 'border.feature_missing')));
    expect(jsonEncode(fixture.map.toJson()), before);
    expect(
        fixture.map.layers
            .whereType<BorderLayer>()
            .first
            .content
            .features
            .single
            .materialization,
        isNull);
  });

  test('spatial generation equals the unit action and keeps foreign instances',
      () async {
    final fixture = spatialBorderAuthoringFixture(published: true);
    final unit = await _apply(
        fixture.project, fixture.map, 'border_layer.materialize_apply', {
      'mapId': 'map',
      'layerId': 'border',
      'featureId': 'fence',
    });
    final draft = await _build(fixture.project, fixture.map, {
      'mapId': 'map',
      'features': [_features.first],
    });
    expect(_decode(draft).toJson(), unit.toJson());
  });

  test('duplicate targets are rejected before resolution', () async {
    final fixture = _fixture();
    await expectLater(
        _build(fixture.project, fixture.map, {
          'mapId': 'map',
          'features': [_features.first, _features.first]
        }),
        throwsA(isA<MapAuthoringException>()
            .having((e) => e.code, 'code', 'border.batch_duplicate_target')));
  });

  test('empty and excessive batches are rejected', () async {
    final fixture = _fixture();
    for (final targets in [
      <Map<String, String>>[],
      List.filled(129, _features.first)
    ]) {
      await expectLater(
          _build(fixture.project, fixture.map,
              {'mapId': 'map', 'features': targets}),
          throwsA(isA<MapAuthoringException>()
              .having((e) => e.code, 'code', 'border.batch_bounds_exceeded')));
    }
  });

  test('unknown fields and fractional dimensions fail closed', () async {
    final fixture = _fixture();
    for (final extras in [
      <String, Object?>{'unknown': true},
      <String, Object?>{'tileWidthPx': 16.5},
    ]) {
      await expectLater(
          _build(fixture.project, fixture.map,
              {'mapId': 'map', 'features': _features, ...extras}),
          throwsA(isA<MapAuthoringException>()));
    }
  });
}

({ProjectManifest project, MapData map}) _fixture() {
  final seed = borderSlotOverrideFixture();
  final layer = seed.map.layers.whereType<BorderLayer>().single;
  final base = layer.content.features.single;
  final feature = BorderFeature(
      id: base.id,
      name: base.name,
      blueprintId: base.blueprintId,
      seed: base.seed,
      geometry: base.geometry,
      overrides: base.overrides,
      keepOutRegions: base.keepOutRegions);
  return (
    project: seed.project,
    map: seed.map.copyWith(layers: [
      seed.map.layers.first,
      layer.copyWith(
          content: BorderLayerContent(formatVersion: 2, features: [feature])),
      layer.copyWith(
          id: 'other-border',
          content: BorderLayerContent(formatVersion: 2, features: [
            BorderFeature(
                id: 'other-fence',
                name: base.name,
                blueprintId: base.blueprintId,
                seed: base.seed,
                overrides: base.overrides,
                keepOutRegions: base.keepOutRegions,
                geometry: BorderStrokeGeometry(strokes: [
                  BorderStroke(id: 'other-line', closed: false, points: [
                    for (var x = 1; x <= 7; x++) GridPos(x: x, y: 3)
                  ])
                ]))
          ]))
    ])
  );
}

Future<AuthoringMutationDraft> _build(ProjectManifest project, MapData map,
        Map<String, Object?> parameters) async =>
    MapMutationDispatcher.canonical()
        .build(context(librarySnapshot([map], project: project), _action, {
      'tileWidthPx': 16,
      'tileHeightPx': 16,
      'resolverVersion': borderResolverVersion,
      ...parameters,
    }));

Future<MapData> _apply(ProjectManifest project, MapData map, String action,
    Map<String, Object?> parameters) async {
  final draft = await MapMutationDispatcher.canonical()
      .build(context(librarySnapshot([map], project: project), action, {
    'tileWidthPx': 16,
    'tileHeightPx': 16,
    'resolverVersion': borderResolverVersion,
    ...parameters,
  }));
  return _decode(draft);
}

MapData _decode(AuthoringMutationDraft draft) => MapData.fromJson(
    jsonDecode(utf8.decode(draft.changeSet.changes.single.afterBytes!)));
