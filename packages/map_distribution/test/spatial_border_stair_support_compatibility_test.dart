import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:test/test.dart';

import 'support/spatial_package_fixture.dart';

void main() {
  test(
      'historical model-ramp Border receipts survive package inspection unchanged',
      () {
    final files = spatialPayload();
    final project = ProjectManifest.fromJson(
        jsonDecode(utf8.decode(files['project/project.json']!))
            as Map<String, dynamic>);
    final source = MapData.fromJson(
        jsonDecode(utf8.decode(files['project/maps/map.json']!))
            as Map<String, dynamic>);
    final definition = BorderBlueprintPublishedDefinition(
      name: 'Fence',
      previewSeed: BorderSignedInt64.zero,
      template: BorderBlueprintTemplate.connectedLine,
      straightOnly: true,
      primitives: [
        for (final role in [
          BorderPrimitiveRole.lineCap,
          BorderPrimitiveRole.lineStraight
        ])
          BorderPublishedPrimitive(
              id: role.name,
              sourceModelId: 'model',
              role: role,
              weight: 1,
              anchorWorld: Model3dVector3.zero,
              transforms: BorderTransformPolicy(
                  allowFlipX: false, allowedQuarterTurns: [0, 1, 2, 3]))
      ],
      defaults: BorderGenerationParams(
          irregularityPermille: 0,
          detailDensityPermille: 0,
          variationPermille: 0,
          maxOverlapPx: 0,
          gapTolerancePx: 0,
          depthRows: 1),
      sortOrder: 0,
    );
    final manifest = project.copyWith(
        borderCatalog: ProjectBorderCatalog(formatVersion: 5, records: [
      BorderBlueprintRecord(
          id: 'fence',
          draft: BorderBlueprintDraft(
              baseRevision: 1,
              definition: BorderBlueprintDraftDefinition(
                  name: definition.name,
                  previewSeed: definition.previewSeed,
                  template: definition.template,
                  straightOnly: true,
                  primitives: [
                    for (final primitive in definition.primitives)
                      BorderPrimitiveDraft(
                          id: primitive.id,
                          sourceModelId: primitive.sourceModelId,
                          role: primitive.role,
                          weight: primitive.weight,
                          anchorWorld: primitive.anchorWorld,
                          transforms: primitive.transforms)
                  ],
                  defaults: definition.defaults,
                  sortOrder: 0)),
          latestPublished:
              BorderBlueprintRevision(revision: 1, definition: definition))
    ]));
    final feature = BorderFeature(
        id: 'fence',
        name: 'Fence',
        blueprintId: 'fence',
        seed: BorderSignedInt64.zero,
        geometry: BorderStrokeGeometry(strokes: [
          BorderStroke(
              id: 'edge',
              closed: false,
              points: [GridPos(x: 2, y: 2), GridPos(x: 2, y: 3)])
        ]),
        overrides: [],
        keepOutRegions: []);
    final map = source.copyWith(
        layers: [
          MapLayer.border(
              id: 'border',
              name: 'Border',
              content: BorderLayerContent(features: [feature]))
        ],
        spatialScene: source.spatialScene!.copyWith(
            heightLevels: [
              for (var z = 0; z < 8; z++)
                for (var x = 0; x < 8; x++)
                  z <= 1
                      ? 2
                      : z < 4
                          ? 1
                          : 0
            ],
            instances: [
              source.spatialScene!.instances.single.copyWith(
                  position: Model3dVector3(x: 2, y: 1, z: 2),
                  blocksMovement: false)
            ],
            navigation: SpatialNavigationProfile(
                spawn: SpatialSpawn(x: 6, z: 6),
                ramps: [
                  SpatialRamp(
                      id: 'stairs',
                      x: 2,
                      z: 2,
                      width: 1,
                      depth: 2,
                      lowLevel: 0,
                      highLevel: 2,
                      direction: SpatialRampDirection.north,
                      surfaceInstanceId: 'placement')
                ])));
    final context = SpatialBorderResolutionContext.fromMap(map);
    final legacy = resolveSpatialBorderFeatureInContext(
        manifest: manifest,
        context: SpatialBorderResolutionContext(
            mapId: context.mapId,
            size: context.size,
            layers: context.layers,
            instances: context.instances,
            worldHeightAt: map.spatialScene!.worldHeightAt,
            fingerprintContext: context.fingerprintContext,
            groundModeledAt: context.groundModeledAt),
        layerId: 'border',
        featureId: 'fence');
    expect(legacy.modelInstances.map((instance) => instance.position.y),
        [1.5, .5]);
    final saved = upsertBorderFeature(
        map.copyWith(
            spatialScene: map.spatialScene!.copyWith(instances: [
          ...map.spatialScene!.instances,
          ...legacy.modelInstances
        ])),
        layerId: 'border',
        feature: BorderFeature(
            id: feature.id,
            name: feature.name,
            blueprintId: feature.blueprintId,
            seed: feature.seed,
            geometry: feature.geometry,
            overrides: [],
            keepOutRegions: [],
            materialization: legacy.result.materialization));
    final mapBytes = utf8.encode(jsonEncode(saved.toJson()));
    files['project/project.json'] = utf8.encode(jsonEncode(manifest.toJson()));
    files['project/maps/map.json'] = mapBytes;
    final built = const GamePackageBuilder()
        .build(manifest: spatialManifest(), payloadFiles: files);
    final inspection = const GamePackageInspector().inspect(built.packageBytes);
    expect(inspection.manifest.gameId, spatialManifest().gameId);
    final archive = ZipDecoder().decodeBytes(built.packageBytes);
    final preserved = archive.findFile('project/maps/map.json')!.content;
    expect(preserved, mapBytes);
    final loaded = MapData.fromJson(
        jsonDecode(utf8.decode(preserved)) as Map<String, dynamic>);
    expect(
        (loaded.layers.single as BorderLayer)
            .content
            .features
            .single
            .materialization,
        legacy.result.materialization);
    expect(
        diagnoseSpatialBorderFeature(
                manifest: manifest,
                map: loaded,
                layerId: 'border',
                featureId: 'fence')
            .diagnostics
            .where((diagnostic) =>
                diagnostic.code == 'border.spatial.materialization_stale'),
        isEmpty);
  });
}
