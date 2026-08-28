import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('canonical dispatcher upserts an Environment preset', () async {
    final manifest = ProjectManifest(
      name: 'Environment preset fixture',
      maps: const [],
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
            tileHeight: 32,
          ),
        ),
      ],
      elementCategories: const [
        ProjectElementCategory(id: 'nature', name: 'Nature'),
      ],
      elements: const [
        ProjectElementEntry(
          id: 'tree',
          name: 'Tree',
          tilesetId: 'nature',
          categoryId: 'nature',
          frames: [
            TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
          ],
        ),
      ],
    );
    final snapshot = _snapshot(manifest);
    final dispatcher = MapMutationDispatcher.canonical();

    expect(
      dispatcher.descriptors.map((descriptor) => descriptor.id),
      contains('environment.preset.upsert'),
    );

    final draft = await dispatcher.build(
      AuthoringPlanningContext(
        snapshot: snapshot,
        request: AuthoringRequest(
          requestId: 'request-environment-preset-upsert',
          actionId: 'environment.preset.upsert',
          actionVersion: 1,
          workspaceHandle: 'workspace-environment-preset',
          expectedRevision: snapshot.revision,
          idempotencyKey: 'idem-environment-preset-upsert',
          parameters: const {
            'preset': {
              'id': 'forest-hgss',
              'name': 'Forêt HGSS',
              'templateId': 'forest_dense',
              'palette': [
                {
                  'elementId': 'tree',
                  'weight': 1,
                  'collisionMode': 'useElementDefault',
                  'tags': ['canopy'],
                },
              ],
              'defaultParams': {
                'density': 0.8,
                'variation': 0.4,
                'edgeDensity': 1.0,
                'minSpacingCells': 0,
              },
              'sortOrder': 0,
            },
          },
        ),
        planId: 'plan-environment-preset-upsert',
        seed: 1,
      ),
    );
    final projected = ProjectManifest.fromJson(
      Map<String, dynamic>.from(
        jsonDecode(
          utf8.decode(draft.changeSet.changes.single.afterBytes!),
        ) as Map,
      ),
    );

    expect(projected.environmentPresets, hasLength(1));
    expect(projected.environmentPresets.single.id, 'forest-hgss');
    expect(
      projected.environmentPresets.single.palette.single.elementId,
      'tree',
    );
  });
}

ProjectSnapshot _snapshot(ProjectManifest manifest) {
  final bytes = utf8.encode(jsonEncode(manifest.toJson()));
  final revision = computeNarrativeProjectFingerprint([
    NarrativeProjectFingerprintEntry(
      relativePath: 'project.json',
      bytes: bytes,
    ),
  ]);
  return ProjectSnapshot(
    projectHandle: const ProjectHandle('environment-preset-project'),
    revision: revision,
    manifest: manifest,
    maps: const [],
    resourceFingerprints: {'project': revision},
    resourceBytes: {'project': bytes},
  );
}
