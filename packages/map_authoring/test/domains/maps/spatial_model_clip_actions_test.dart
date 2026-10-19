import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/src/domains/maps/spatial_map_actions.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../../support/glb_fixture.dart';
import '../assets/resource_library_actions_test.dart' show librarySnapshot;
import '../assets/resource_pack_import_fixture.dart';

void main() {
  test(
      'discovers static clipped spatial instances and Smart Tile source semantics',
      () {
    for (final id in ['map3d.instance.upsert', 'map3d.instance.upsert_batch']) {
      final descriptor =
          SpatialMapActions.descriptors.singleWhere((d) => d.id == id);
      expect(descriptor.extensions['model3dClip'], isA<Map>());
      final schema = descriptor.extensions['inputSchema'] as Map;
      final properties = schema['properties'] as Map;
      final instance = id.endsWith('_batch')
          ? (properties['instances'] as Map)['items'] as Map
          : properties['instance'] as Map;
      expect((instance['properties'] as Map)['clip'], isA<Map>());
    }
    final descriptor = SmartTileCatalogActions.descriptors
        .singleWhere((d) => d.id == 'smart_tile.pattern.upsert');
    expect(descriptor.extensions['model3dSpatialClip'], isA<Map>());
    expect(descriptor.extensions['model3dTerrainSample'],
        'unclipped_final_anchor');
    expect(
        (descriptor.extensions['model3dSpatialClip'] as Map)['terrainSampling'],
        'visible_clip_support_center');
    expect(
        (descriptor.extensions['model3dSpatialClip'] as Map)['channels'],
        ['ground', 'understory', 'canopy']);
    expect(
        (descriptor.extensions['model3dSpatialClip'] as Map)['boundaryOwnership'],
        'closed_rectangle_preserves_isolated_outer_faces');
  });

  for (final batch in [false, true]) {
    test(
        'canonical ${batch ? 'batch' : 'single'} placement preserves a static source clip',
        () {
      final fixture = _fixture();
      final instance = _instance();
      final draft = const SpatialMapActions().build(_context(fixture.snapshot,
          batch ? 'map3d.instance.upsert_batch' : 'map3d.instance.upsert', {
        'mapId': 'map',
        if (batch)
          'instances': [instance.toJson()]
        else
          'instance': instance.toJson()
      }));
      final after = MapData.fromJson(
          jsonDecode(utf8.decode(draft.changeSet.changes.single.afterBytes!))
              as Map<String, dynamic>);
      expect(after.spatialScene!.instances.single, instance);
    });

    test(
        'canonical ${batch ? 'batch' : 'single'} rejects an animated GLB even without animationIndex',
        () {
      final fixture = _fixture(animated: true);
      expect(fixture.project.models3d.single.inspection.animations, isNotEmpty);
      expect(
          () => const SpatialMapActions().build(_context(
                  fixture.snapshot,
                  batch
                      ? 'map3d.instance.upsert_batch'
                      : 'map3d.instance.upsert',
                  {
                    'mapId': 'map',
                    if (batch)
                      'instances': [_instance().toJson()]
                    else
                      'instance': _instance().toJson()
                  })),
          throwsA(isA<MapAuthoringException>().having(
              (e) => e.code, 'code', 'map3d.instance.clip_animated_model')));
    });

    test(
        'source replacement ${batch ? 'batch' : 'single'} rejects real animation for an existing clipped instance',
        () async {
      final fixture = _fixture(placed: true);
      final store = MemoryArtifactStore(maximumArtifactBytes: 1024 * 1024);
      final staged = await store.put(animatedGlb());
      await expectLater(
          Model3dActions(artifactStore: store).build(_context(
              fixture.snapshot,
              batch ? 'model3d.source.replace_batch' : 'model3d.source.replace',
              batch
                  ? {
                      'models': [
                        {
                          'modelId': 'unit',
                          'artifactHandle': staged.reference.handle
                        }
                      ]
                    }
                  : {
                      'modelId': 'unit',
                      'artifactHandle': staged.reference.handle
                    })),
          throwsA(isA<FormatException>()
              .having((e) => e.message, 'message', contains('static'))));
      expect(store.list(), isEmpty);
    });

    test(
        'configuration ${batch ? 'batch' : 'single'} refuses attached navigation on a clipped model',
        () async {
      final fixture = _fixture(placed: true);
      final parameters = {
        'modelId': 'unit',
        'rampProfile': Model3dRampProfile(
                x: 0,
                z: 0,
                width: 1,
                depth: 1,
                lowHeight: 0,
                highHeight: .5,
                direction: SpatialRampDirection.east)
            .toJson()
      };
      await expectLater(
          const Model3dActions().build(_context(
              fixture.snapshot,
              batch ? 'model3d.configure_batch' : 'model3d.configure',
              batch
                  ? {
                      'models': [parameters]
                    }
                  : parameters)),
          throwsA(isA<FormatException>()
              .having((e) => e.message, 'message', contains('clipped'))));
    });
  }

  test('unclipped animated placements retain existing behavior', () {
    final fixture = _fixture(animated: true);
    final instance = _instance().copyWith(clearClip: true, animationIndex: 0);
    final draft = const SpatialMapActions().build(_context(
        fixture.snapshot,
        'map3d.instance.upsert',
        {'mapId': 'map', 'instance': instance.toJson()}));
    expect(draft.changeSet.changes, hasLength(1));
  });

  test(
      'material-only animation is animated source admission even without a node clip',
      () {
    final fixture = _fixture(bytes: _materialAnimatedGlb());
    expect(fixture.project.models3d.single.inspection.animations, hasLength(1));
    expect(
        () => const SpatialMapActions().build(_context(
            fixture.snapshot,
            'map3d.instance.upsert',
            {'mapId': 'map', 'instance': _instance().toJson()})),
        throwsA(isA<MapAuthoringException>().having(
            (e) => e.code, 'code', 'map3d.instance.clip_animated_model')));
  });

  test('unpainted model patterns still prevent animated replacement', () async {
    final fixture = _fixture();
    final project = fixture.project.copyWith(
        smartTileCatalog: ProjectSmartTileCatalog(patterns: [
      ProjectSmartTilePattern(
          id: 'half',
          name: 'Half',
          usage: SmartTileUsage.path,
          width: 1,
          height: 1,
          cells: [
            SmartTilePatternCell(x: 0, y: 0, parts: [
              SmartTileVisualPart(
                  source: const SmartTileVisualSource.model3d(modelId: 'unit'),
                  spatialClip: SmartTileSpatialClip(
                      left: 0, top: 0, right: .5, bottom: 1))
            ])
          ])
    ]));
    final snapshot = librarySnapshot(fixture.snapshot.maps, project: project);
    final store = MemoryArtifactStore(maximumArtifactBytes: 1024 * 1024);
    final staged = await store.put(_materialAnimatedGlb());
    await expectLater(
        Model3dActions(artifactStore: store).build(_context(
            snapshot,
            'model3d.source.replace',
            {'modelId': 'unit', 'artifactHandle': staged.reference.handle})),
        throwsA(isA<FormatException>()
            .having((e) => e.message, 'message', contains('static'))));
    expect(store.list(), isEmpty);
  });

  test('canonical resource pack export import and reopen retain model clipping',
      () async {
    final original = _fixture();
    final part = SmartTileVisualPart(
        source: const SmartTileVisualSource.model3d(modelId: 'unit'),
        spatialClip:
            SmartTileSpatialClip(left: 0, top: 0, right: .5, bottom: 1));
    final source = original.project.copyWith(
        smartTileCatalog: ProjectSmartTileCatalog(
      materials: const [
        ProjectSmartTileMaterial(
            id: 'grass', name: 'Grass', connectionGroupId: 'grass')
      ],
      presets: [
        ProjectSmartTilePreset(
            id: 'clip',
            name: 'Clip',
                  status: SmartTilePresetStatus.published,
            usage: SmartTileUsage.path,
            topology: SmartTileTopology.uniform,
            templateHint: SmartTileTemplateHint.simple,
            coveragePolicy: SmartTileCoveragePolicy.sparse,
            coverageProfile: const SmartTileCoverageProfile(
                mode: SmartTileCoverageMode.template),
            transformPolicy: const SmartTileTransformPolicy(),
            defaultMaterialId: 'grass',
            allowedMaterialIds: [
              'grass'
            ],
            rules: [
              SmartTileRule(
                  id: 'unit',
                  centerMatch: const SmartTileSlotMatch.material('grass'),
                  candidates: [
                    SmartTileCandidate(id: 'unit', parts: [part])
                  ])
            ])
      ],
    ));
    final bytes = triangleGlb();
    final fixture = await NativeResourcePackImportFixture.create(
        sourceManifest: source,
        sourceFiles: [
          NativeResourcePackFile(
              id: 'model3d_unit',
              logicalPath: 'assets/models3d/unit.glb',
              byteLength: bytes.length,
              rawSha256: sha256.convert(bytes).toString(),
              mediaType: 'model/gltf-binary',
              openRead: () => Stream.value(bytes))
        ],
        roots: [
          NativeResourcePackRef(
              kind: ResourcePackKind.smartTilePreset, id: 'clip')
        ],
        target: original.project.copyWith(maps: [], models3d: []));
    try {
      final catalog = fixture.source.archive.inspection.catalog;
      expect(
          fixture.source.archive.inspection.manifest.compatibility
              .requiredCapabilities,
          contains(SpatialModelClipCapabilities.resourcePackCapabilityId));
      final prepared = await fixture.prepare(
          selection: await fixture.select(roots: [
        ResourcePackRef(
            kind: ResourcePackKind.smartTilePreset,
            id: catalog.smartTileCatalog.presets.single.id)
      ]));
      await fixture.apply(await fixture.plan(prepared));
      await fixture.close();
      await fixture.open();
      final saved =
          (await fixture.loader.load(fixture.opened.projectHandle)).manifest;
      final imported = saved.smartTileCatalog.presets.single.rules.single
          .candidates.single.parts.single;
      expect(imported.spatialClip, part.spatialClip);
      expect((imported.source as SmartTileModel3dSource).modelId,
          saved.models3d.single.id);
      expect(saved.models3d.single.inspection,
          original.project.models3d.single.inspection);
      expect(saved.models3d.single.id, isNot('unit'));
    } finally {
      await fixture.dispose();
    }
  });
}

SpatialModelInstance _instance() => SpatialModelInstance(
    id: 'placed',
    modelId: 'unit',
    position: Model3dVector3(x: 2, y: 0, z: 2),
    blocksMovement: false,
    clip: SpatialModelClip(left: 0, top: 0, right: 1, bottom: 1));

({ProjectManifest project, ProjectSnapshot snapshot}) _fixture(
    {bool animated = false, bool placed = false, List<int>? bytes}) {
  bytes ??= animated ? animatedGlb() : triangleGlb();
  final model = ProjectModel3dEntry(
      id: 'unit',
      name: 'Unit',
      sourceAssetId: 'model3d_unit',
      relativePath: 'assets/models3d/unit.glb',
      inspection: const GlbModel3dInspector().inspect(bytes));
  final map = MapData(
      id: 'map',
      name: 'Map',
      version: ProjectVersion.v9,
      size: const GridSize(width: 8, height: 8),
      layers: [],
      spatialScene: MapSpatialScene(
          width: 8, depth: 8, instances: [if (placed) _instance()]));
  final project = ProjectManifest(
      name: 'Clip admission',
      version: ProjectVersion.v9,
      maps: [
        const ProjectMapEntry(
            id: 'map', name: 'Map', relativePath: 'maps/map.json')
      ],
      tilesets: [],
      models3d: [model],
      settings: ProjectSettings(
          dimension: ProjectDimension.threeD,
          spatialCamera: SpatialCameraProfile()));
  final snapshot = librarySnapshot([map], project: project);
  return (project: project, snapshot: snapshot);
}

AuthoringPlanningContext _context(ProjectSnapshot snapshot, String action,
        Map<String, Object?> parameters) =>
    AuthoringPlanningContext(
        snapshot: snapshot,
        request: AuthoringRequest(
            requestId: 'clip',
            actionId: action,
            actionVersion: 1,
            workspaceHandle: 'clip-workspace',
            parameters: parameters),
        planId: 'clip-plan',
        seed: 1);

List<int> _materialAnimatedGlb() {
  final bytes = Uint8List.fromList(texturedGlb());
  final length = ByteData.sublistView(bytes).getUint32(12, Endian.little);
  final json = jsonDecode(utf8.decode(bytes.sublist(20, 20 + length)))
      as Map<String, dynamic>;
  json['extras'] = {
    'aveluneMaterialAnimations': {
      'schemaVersion': 1,
      'clips': [
        {
          'name': 'Material movement',
          'durationSeconds': 1,
          'tracks': [
            {
              'materialIndex': 0,
              'times': [0, 1],
              'transforms': [
                [1, 0, 0, 1, 0, 0],
                [1, 0, 0, 1, 0, 1]
              ],
              'interpolation': 'LINEAR'
            }
          ]
        }
      ]
    }
  };
  return encodeGlb(json, bytes.sublist(28 + length));
}
