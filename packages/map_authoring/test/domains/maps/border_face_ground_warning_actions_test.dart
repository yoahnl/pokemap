import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../assets/resource_library_actions_test.dart' show librarySnapshot;
import 'border_spatial_actions_test.dart'
    show context, spatialBorderAuthoringFixture;

const _target = {'layerId': 'border', 'featureId': 'fence'};

void main() {
  test('materialization plans expose face warnings with their slots',
      () async {
    final fixture = directedCliffAuthoringFixture(levels: List.filled(24, 1));
    final single = await _build(fixture, 'border_layer.materialize_apply',
        {'mapId': 'map', ..._target});
    expect(single.preview['warningCount'], 3);
    final warnings = (single.preview['warnings'] as List).cast<Map>();
    expect(warnings.map((warning) => warning['code']).toSet(),
        {'border.spatial.face_base_mismatch'});
    final persisted = _decode(single);
    final slots = persisted.layers
        .whereType<BorderLayer>()
        .single
        .content
        .features
        .single
        .materialization!
        .spatialPlacements
        .map((placement) => placement.slotKey)
        .toSet();
    expect(warnings.map((warning) => warning['slotKey']).toSet(), slots);
    final first = warnings.first;
    expect(first['layerId'], 'border');
    expect(first['featureId'], 'fence');
    expect(first['cell'], isA<Map>());
    expect(first['suggestedAction'], 'border.action.support_lower_ground');
    expect((first['parameters'] as Map)['lowerGroundHeight'], 1.0);
    expect((first['parameters'] as Map)['baseHeight'], 0.0);
    expect(jsonDecode(jsonEncode(single.preview)), isA<Map>());

    final batch = await _build(fixture, 'border_layer.materialize_batch_apply', {
      'mapId': 'map',
      'features': [_target],
    });
    expect(batch.preview['featureCount'], 1);
    expect(batch.preview['warningCount'], 3);
    expect(batch.preview['warnings'], single.preview['warnings']);
    expect(batch.preview.containsKey('warningsTruncated'), isFalse);
    expect(_decode(batch).toJson(), persisted.toJson());
  });

  test('faces that bridge their step report an empty warning list', () async {
    final fixture = directedCliffAuthoringFixture(levels: [
      for (var z = 0; z < 4; z++)
        for (var x = 0; x < 6; x++) z >= 1 ? 1 : 0,
    ]);
    final single = await _build(fixture, 'border_layer.materialize_apply',
        {'mapId': 'map', ..._target});
    expect(single.preview['warningCount'], 0);
    expect(single.preview['warnings'], isEmpty);
    final batch = await _build(fixture, 'border_layer.materialize_batch_apply', {
      'mapId': 'map',
      'features': [_target],
    });
    expect(batch.preview['warningCount'], 0);
    expect(batch.preview['warnings'], isEmpty);
  });

  test('materialization failures name the failing slot', () async {
    final fixture = directedCliffAuthoringFixture(levels: List.filled(24, 1));
    final layer = fixture.map.layers.whereType<BorderLayer>().single;
    final base = layer.content.features.single;
    const missingSlot = 'border3d-slot:missing';
    final broken = (
      project: fixture.project,
      map: upsertBorderFeature(fixture.map,
          layerId: 'border',
          feature: BorderFeature(
              id: base.id,
              name: base.name,
              blueprintId: base.blueprintId,
              seed: base.seed,
              geometry: base.geometry,
              overrides: [
                BorderSlotOverride(
                    slotKey: missingSlot,
                    variationSalt: BorderSignedInt64.fromInt(0),
                    suppressed: true,
                    locked: false),
              ],
              keepOutRegions: const [])),
    );
    await expectLater(
        _build(broken, 'border_layer.materialize_apply',
            {'mapId': 'map', ..._target}),
        throwsA(isA<MapAuthoringException>()
            .having((e) => e.code, 'code', 'border.materialization_failed')
            .having(
                (e) => (e.details['diagnostics'] as List)
                    .cast<Map>()
                    .where((d) =>
                        d['code'] == 'border.spatial.override_slot_missing')
                    .single['slotKey'],
                'slotKey',
                missingSlot)));
    await expectLater(
        _build(broken, 'border_layer.materialize_batch_apply', {
          'mapId': 'map',
          'features': [_target],
        }),
        throwsA(isA<MapAuthoringException>()
            .having((e) => e.details['diagnostics'], 'codes',
                contains('border.spatial.override_slot_missing'))
            .having(
                (e) => (e.details['diagnosticDetails'] as List)
                    .cast<Map>()
                    .where((d) =>
                        d['code'] == 'border.spatial.override_slot_missing')
                    .single['slotKey'],
                'slotKey',
                missingSlot)));
  });
}

Future<AuthoringMutationDraft> _build(
        ({ProjectManifest project, MapData map}) fixture,
        String action,
        Map<String, Object?> parameters) async =>
    MapMutationDispatcher.canonical().build(context(
        librarySnapshot([fixture.map], project: fixture.project), action, {
      'tileWidthPx': 16,
      'tileHeightPx': 16,
      'resolverVersion': borderResolverVersion,
      ...parameters,
    }));

MapData _decode(AuthoringMutationDraft draft) => MapData.fromJson(
    jsonDecode(utf8.decode(draft.changeSet.changes.single.afterBytes!)));

({ProjectManifest project, MapData map}) directedCliffAuthoringFixture(
    {required List<int> levels}) {
  final fixture = spatialBorderAuthoringFixture(published: true);
  final raw = encodeBorderBlueprintRecordJson(
      fixture.project.borderCatalog.records.single,
      formatVersion: 5);
  for (final key in ['draft', 'latestPublished']) {
    final definition = (raw[key] as Map)['definition'] as Map;
    definition['followContourDirection'] = true;
    final primitives = definition['primitives'] as List;
    for (final primitive in primitives.cast<Map>()) {
      primitive['sourceModelId'] = 'cliff';
      primitive['authoredOrientation'] = 'east';
      primitive['anchorWorld'] = {'x': 0.0, 'y': 0.0, 'z': 0.0};
    }
    final corner = Map<String, Object?>.from(
        primitives.singleWhere((p) => p['role'] == 'lineCorner') as Map);
    primitives.removeWhere((p) => p['role'] == 'lineCorner');
    primitives.add({...corner, 'id': 'corner-right', 'cornerTurn': 'right'});
    primitives.add({...corner, 'id': 'corner-left', 'cornerTurn': 'left'});
  }
  final project = fixture.project.copyWith(
    models3d: [
      ...fixture.project.models3d,
      ProjectModel3dEntry(
        id: 'cliff',
        name: 'Cliff face',
        sourceAssetId: 'cliff-source',
        relativePath: 'assets/models3d/cliff.glb',
        inspection: Model3dInspection(
          bounds: Model3dBounds(
            min: Model3dVector3(x: -.2, y: -1, z: -.2),
            max: Model3dVector3(x: .2, y: 0, z: .2),
          ),
          meshCount: 1,
          triangleCount: 1,
        ),
      ),
    ],
    borderCatalog: ProjectBorderCatalog(
        formatVersion: 5,
        records: [decodeBorderBlueprintRecordJson(raw, formatVersion: 5)]),
  );
  final scene = fixture.map.spatialScene!;
  return (
    project: project,
    map: fixture.map.copyWith(
        spatialScene: MapSpatialScene(
            width: scene.width, depth: scene.depth, heightLevels: levels)),
  );
}
