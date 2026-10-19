import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('batch publishes 50 presets in one manifest change and preserves maps',
      () async {
    final snapshot = _snapshot();
    final before = snapshot.manifest.toJson();
    final draft = await _build(
        snapshot, [for (var i = 0; i < 50; i++) _preset('forest-$i')]);
    final change = draft.changeSet.changes.single;
    expect(change.storageKey, 'project.json');
    final projected = ProjectManifest.fromJson(
      jsonDecode(utf8.decode(change.afterBytes!)) as Map<String, dynamic>,
    );
    expect(projected.environmentPresets, hasLength(51));
    expect(
        projected.environmentPresets.firstWhere((p) => p.id == 'existing').name,
        'Keep');
    expect(projected.maps, snapshot.manifest.maps);
    expect(projected.elements, snapshot.manifest.elements);
    expect(projected.tilesets, snapshot.manifest.tilesets);
    expect(snapshot.manifest.toJson(), before);
  });

  test('invalid second palette rejects the entire batch', () async {
    final snapshot = _snapshot();
    final before = snapshot.manifest.toJson();
    await expectLater(
      _build(snapshot,
          [_preset('valid'), _preset('invalid', elementId: 'missing')]),
      throwsA(isA<VisualLibraryException>()
          .having((e) => e.code, 'code', 'environment.palette_invalid')),
    );
    expect(snapshot.manifest.toJson(), before);
  });

  test('batch supports original 3D model palettes and mixed 2D presets',
      () async {
    final snapshot = _snapshot();
    final modelPreset = {
      ..._preset('model-forest'),
      'palette': [
        {
          'modelId': 'tree3d',
          'weight': 1,
          'collisionMode': 'useElementDefault',
          'tags': <String>[]
        },
      ]
    };
    final draft =
        await _build(snapshot, [_preset('sprite-forest'), modelPreset]);
    final projected = ProjectManifest.fromJson(jsonDecode(
      utf8.decode(draft.changeSet.changes.single.afterBytes!),
    ) as Map<String, dynamic>);
    expect(
        projected.environmentPresets
            .firstWhere((p) => p.id == 'model-forest')
            .palette
            .single
            .modelId,
        'tree3d');
    expect(projected.models3d, snapshot.manifest.models3d);
  });

  test('duplicate identities are rejected without partial publication',
      () async {
    final snapshot = _snapshot();
    await expectLater(
      _build(snapshot, [_preset('same'), _preset('same')]),
      throwsA(isA<VisualLibraryException>()
          .having((e) => e.code, 'code', 'environment.preset_batch_duplicate')),
    );
    expect(snapshot.manifest.environmentPresets.map((p) => p.id), ['existing']);
  });

  test('empty and over-limit batches are rejected', () async {
    for (final rows in [
      <Map<String, Object?>>[],
      [for (var i = 0; i < 51; i++) _preset('forest-$i')]
    ]) {
      await expectLater(
        _build(_snapshot(), rows),
        throwsA(isA<VisualLibraryException>()
            .having((e) => e.code, 'code', 'environment.preset_batch_invalid')),
      );
    }
  });

  test(
      'existing preset is replaced with the same semantics as the single action',
      () async {
    final snapshot = _snapshot();
    final dispatcher = MapMutationDispatcher.canonical();
    final preset = {..._preset('existing'), 'name': 'Updated'};
    final batch = await _build(snapshot, [preset]);
    final single = await dispatcher.build(
        _context(snapshot, 'environment.preset.upsert', {'preset': preset}));
    expect(batch.changeSet.changes.single.afterBytes,
        single.changeSet.changes.single.afterBytes);
    final descriptor = dispatcher.descriptors
        .singleWhere((d) => d.id == 'environment.preset.upsert_batch');
    final schema = descriptor.extensions['inputSchema'] as Map;
    expect(((schema['properties'] as Map)['presets'] as Map)['maxItems'], 50);
    expect(descriptor.resourceKinds, contains('environmentPreset'));
  });
}

Future<AuthoringMutationDraft> _build(
        ProjectSnapshot snapshot, List<Map<String, Object?>> presets) async =>
    await MapMutationDispatcher.canonical().build(_context(
        snapshot, 'environment.preset.upsert_batch', {'presets': presets}));

AuthoringPlanningContext _context(ProjectSnapshot snapshot, String action,
        Map<String, Object?> parameters) =>
    AuthoringPlanningContext(
      snapshot: snapshot,
      request: AuthoringRequest(
        requestId: 'environment-batch',
        actionId: action,
        actionVersion: 1,
        workspaceHandle: 'workspace',
        expectedRevision: snapshot.revision,
        idempotencyKey: 'environment-batch',
        parameters: parameters,
      ),
      planId: 'environment-batch-plan',
      seed: 1,
    );

Map<String, Object?> _preset(String id, {String elementId = 'tree'}) => {
      'id': id,
      'name': id,
      'templateId': 'forest',
      'palette': [
        {
          'elementId': elementId,
          'weight': 1,
          'collisionMode': 'useElementDefault',
          'tags': <String>[]
        }
      ],
      'defaultParams': {
        'density': 1,
        'variation': 0,
        'edgeDensity': 1,
        'minSpacingCells': 0
      },
      'sortOrder': 0,
    };

ProjectSnapshot _snapshot() {
  final manifest = ProjectManifest(
    name: 'Batch presets',
    maps: const [
      ProjectMapEntry(id: 'garden', name: 'Garden', relativePath: 'garden.json')
    ],
    tilesets: const [
      ProjectTilesetEntry(
        id: 'nature',
        name: 'Nature',
        relativePath: 'assets/nature.png',
        source: ProjectRegularAtlasTilesetSource(
            assetId: 'nature-asset',
            pixelWidth: 32,
            pixelHeight: 32,
            tileWidth: 32,
            tileHeight: 32),
      )
    ],
    elementCategories: const [
      ProjectElementCategory(id: 'nature', name: 'Nature')
    ],
    elements: const [
      ProjectElementEntry(
        id: 'tree',
        name: 'Tree',
        tilesetId: 'nature',
        categoryId: 'nature',
        frames: [TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0))],
      )
    ],
    models3d: [
      ProjectModel3dEntry(
        id: 'tree3d',
        name: 'Tree 3D',
        sourceAssetId: 'tree3d-source',
        relativePath: 'assets/models3d/tree3d.glb',
        inspection: Model3dInspection(
          bounds: Model3dBounds(
              min: Model3dVector3(x: 0, y: 0, z: 0),
              max: Model3dVector3(x: 1, y: 1, z: 1)),
          meshCount: 1,
          triangleCount: 2,
        ),
      )
    ],
    environmentPresets: [
      decodeEnvironmentPreset({..._preset('existing'), 'name': 'Keep'})
    ],
  );
  final bytes = utf8.encode(jsonEncode(manifest.toJson()));
  final revision = computeNarrativeProjectFingerprint([
    NarrativeProjectFingerprintEntry(
        relativePath: 'project.json', bytes: bytes),
  ]);
  return ProjectSnapshot(
      projectHandle: const ProjectHandle('batch-project'),
      revision: revision,
      manifest: manifest,
      maps: const [],
      resourceFingerprints: {'project': revision},
      resourceBytes: {'project': bytes});
}
