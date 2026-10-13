import 'dart:convert';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';
import '../../support/border_replacement_fixture.dart';

AuthoringMutationDraft replacementDraft(BorderReplacementFixture f, MapData map,
    {String? slotKey, String primitiveId = 'south-alternate'}) {
  final bytes = <String, List<int>>{
    'project': utf8.encode(jsonEncode(f.project.toJson())),
    'map:${map.id}': utf8.encode(jsonEncode(map.toJson())),
  };
  final storage = {
    'project': 'project.json',
    'map:${map.id}': 'maps/original-map.pokemap.json'
  };
  final snapshot = ProjectSnapshot(
    projectHandle: const ProjectHandle('original'),
    revision: computeAuthoringBytesFingerprint(bytes['project']!,
        logicalName: 'project.json'),
    manifest: f.project,
    maps: [map],
    resourceBytes: bytes,
    resourceStorageKeys: storage,
    resourceFingerprints: {
      for (final e in bytes.entries)
        e.key: computeAuthoringBytesFingerprint(e.value,
            logicalName: storage[e.key]!)
    },
  );
  return const BorderActions().build(AuthoringPlanningContext(
    snapshot: snapshot,
    planId: 'replacement',
    seed: 0,
    request: AuthoringRequest(
        requestId: 'replacement',
        actionId: 'border_layer.feature_set_replacement',
        actionVersion: 1,
        workspaceHandle: 'original',
        expectedRevision: snapshot.revision,
        idempotencyKey: 'replacement',
        parameters: {
          'mapId': map.id,
          'layerId': 'original-borders',
          'featureId': 'ledge-feature',
          'slotKey': slotKey ?? f.evidence.edges.single.finalPlacement.slotKey,
          'primitiveId': primitiveId,
        }),
  ));
}

MapData replacementMap(AuthoringMutationDraft draft) => MapData.fromJson(
    jsonDecode(utf8.decode(draft.changeSet.changes.single.afterBytes!))
        as Map<String, dynamic>);

void main() {
  test('canonical descriptor exposes exact typed replacement parameters', () {
    final descriptor = MapMutationDispatcher.canonical()
        .descriptors
        .singleWhere(
            (value) => value.id == 'border_layer.feature_set_replacement');
    expect(descriptor.version, 1);
    expect(descriptor.extensions['visualKinds'], ['element']);
    final schema = descriptor.extensions['inputSchema'] as Map;
    expect(schema['additionalProperties'], false);
    expect(schema['required'],
        ['mapId', 'layerId', 'featureId', 'slotKey', 'primitiveId']);
  });
  test('replacement preserves identity geometry seed and unrelated overrides',
      () {
    final f = BorderReplacementFixture(extraVariant: true);
    final slot = f.evidence.edges.single.finalPlacement.slotKey;
    final map = updateBorderFeatureOverrides(f.map,
        layerId: 'original-borders',
        featureId: 'ledge-feature',
        overrides: [
          BorderSlotOverride(
              slotKey: slot,
              variationSalt: BorderSignedInt64.fromInt(13),
              suppressed: false,
              locked: false,
              offsetDeltaPx: const BorderPixelOffset(x: 0, y: 0),
              transformOverride:
                  BorderSpriteTransform(quarterTurns: 0, flipX: false))
        ]);
    final updated = replacementMap(replacementDraft(f, map));
    final feature =
        (updated.layers.first as BorderLayer).content.features.single;
    expect(feature.id, f.feature.id);
    expect(feature.seed, f.feature.seed);
    expect(feature.geometry, f.feature.geometry);
    expect(feature.lineSide, f.feature.lineSide);
    final override = feature.overrides.single;
    expect(override.variationSalt, BorderSignedInt64.fromInt(13));
    expect(override.offsetDeltaPx, const BorderPixelOffset(x: 0, y: 0));
    expect(override.transformOverride,
        BorderSpriteTransform(quarterTurns: 0, flipX: false));
    expect(override.replacementPrimitiveId, 'south-alternate');
    final preview = const BorderActions().preview(
        manifest: f.project,
        map: updated,
        layerId: 'original-borders',
        featureId: 'ledge-feature',
        projectRevision: 'original',
        tileSizePx: const GridSize(width: 32, height: 32),
        resolverVersion: borderResolverVersion);
    expect(preview.result.materialization!.placements.single.primitiveId,
        'south-alternate');
  });
  test('replacement resolves an authored slot before its first materialization',
      () {
    final f = BorderReplacementFixture(extraVariant: true);
    final map = upsertBorderFeature(f.map,
        layerId: 'original-borders',
        feature: BorderFeature(
            id: f.feature.id,
            name: f.feature.name,
            blueprintId: f.feature.blueprintId,
            seed: f.feature.seed,
            geometry: f.feature.geometry,
            lineSide: f.feature.lineSide,
            overrides: const [],
            keepOutRegions: const []));
    final feature =
        (replacementMap(replacementDraft(f, map)).layers.first as BorderLayer)
            .content
            .features
            .single;
    expect(feature.materialization, isNull);
    expect(feature.overrides.single.replacementPrimitiveId, 'south-alternate');
  });
  for (final invalid in ['slot', 'primitive', 'orientation']) {
    test(
        'replacement refuses unknown or incompatible $invalid without mutating the map',
        () {
      final f = BorderReplacementFixture(extraVariant: true);
      final before = jsonEncode(f.map.toJson());
      expect(
          () => replacementDraft(f, f.map,
              slotKey: invalid == 'slot' ? 'missing-slot' : null,
              primitiveId: invalid == 'primitive'
                  ? 'missing-primitive'
                  : invalid == 'orientation'
                      ? 'north'
                      : 'south-alternate'),
          throwsA(isA<MapAuthoringException>().having(
              (error) => error.code,
              'code',
              invalid == 'slot'
                  ? 'border.slot_not_resolved'
                  : invalid == 'primitive'
                      ? 'border.primitive_missing'
                      : 'border.replacement_invalid')));
      expect(jsonEncode(f.map.toJson()), before);
    });
  }
}
