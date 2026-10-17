import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/authoring_api/authoring_mutation_adapter.dart';
import 'package:map_editor/src/application/authoring_api/authoring_query_adapter.dart';
import 'package:map_editor/src/infrastructure/authoring_api/editor_project_file_reader.dart';

import '../../../map_authoring/test/support/glb_fixture.dart' show encodeGlb;
import '../../../map_core/test/support/spatial_border_ground_surface_fixture.dart'
    as surfaces;

void main() {
  for (final withSurfaces in [false, true]) {
    test(
      'editor bridge publishes reopens and undoes cliff ground (plateaus: $withSurfaces)',
      () async {
        final root = await Directory.systemTemp.createTemp(
          'cliff-footprint-editor-',
        );
        addTearDown(() => root.delete(recursive: true));
        final map = MapData(
          id: 'map',
          name: 'Map',
          version: ProjectVersion.v9,
          size: const GridSize(width: 6, height: 4),
          spatialScene: MapSpatialScene(
            width: 6,
            depth: 4,
            heightLevels: List.filled(24, 1),
          ),
        );
        final project = ProjectManifest(
          name: 'Cliff',
          version: ProjectVersion.v9,
          smartTileCatalog: withSurfaces
              ? surfaces.surfaceFixture().project.smartTileCatalog
              : const ProjectSmartTileCatalog.empty(),
          tilesets: [
            if (withSurfaces)
              const ProjectTilesetEntry(
                id: 'grass',
                name: 'Grass',
                relativePath: 'assets/tilesets/grass.png',
              ),
          ],
          maps: const [
            ProjectMapEntry(
              id: 'map',
              name: 'Map',
              relativePath: 'maps/map.json',
            ),
          ],
          settings: ProjectSettings(
            dimension: ProjectDimension.threeD,
            spatialCamera: SpatialCameraProfile(),
          ),
        );
        ProjectValidator.validate(project);
        final mapFile = File('${root.path}/maps/map.json');
        await mapFile.parent.create(recursive: true);
        await mapFile.writeAsString(jsonEncode(map.toJson()));
        if (withSurfaces) {
          final texture = File('${root.path}/assets/tilesets/grass.png');
          await texture.parent.create(recursive: true);
          await texture.writeAsBytes(
            base64Decode(
              'iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAJUlEQVR4nGNsOF/3n4ECwESJ5lEDIICJgULANGoAw2gYMFAeBgCa4QLsTops2QAAAABJRU5ErkJggg==',
            ),
          );
        }
        final projectFile = File('${root.path}/project.json');
        await projectFile.writeAsString(jsonEncode(project.toJson()));
        final source = File('${root.path}/unit.glb');
        final binary = ByteData(36);
        final vertices = [-.2, 0.0, -.2, .2, 0.0, -.2, 0.0, 1.0, .2];
        for (var index = 0; index < vertices.length; index++) {
          binary.setFloat32(index * 4, vertices[index], Endian.little);
        }
        await source.writeAsBytes(
          encodeGlb({
            'asset': {'version': '2.0'},
            'scene': 0,
            'scenes': [
              {
                'nodes': [0],
              },
            ],
            'nodes': [
              {'mesh': 0},
            ],
            'buffers': [
              {'byteLength': 36},
            ],
            'bufferViews': [
              {'buffer': 0, 'byteLength': 36},
            ],
            'accessors': [
              {
                'bufferView': 0,
                'componentType': 5126,
                'count': 3,
                'type': 'VEC3',
              },
            ],
            'meshes': [
              {
                'primitives': [
                  {
                    'attributes': {'POSITION': 0},
                  },
                ],
              },
            ],
          }, binary.buffer.asUint8List()),
        );
        const reader = EditorProjectFileReader();
        final path = await reader.canonicalizeDirectory(root.path);
        final queries = AuthoringQueryAdapter(fileReader: reader);
        final mutations = AuthoringMutationAdapter(
          fileReader: reader,
          queries: queries,
          projectRoots: reader,
        );
        addTearDown(queries.closeAll);
        addTearDown(mutations.closeAll);
        await queries.retainOnly(path);
        await mutations.retainOnly(path);
        var serial = 0;
        Future<EditorAuthoringMutationResult> mutate(
          String action,
          Map<String, Object?> parameters,
        ) async {
          final before = await mapFile.readAsBytes();
          final planned = await mutations.plan(
            path,
            actionId: action,
            parameters: parameters,
            idempotencyKey: 'footprint-plan-${serial++}',
          );
          expect(await mapFile.readAsBytes(), before);
          return mutations.apply(
            planned,
            operationId: 'footprint-apply-${serial++}',
          );
        }

        final staged = await mutations.stageArtifact(
          path,
          sourcePath: source.path,
        );
        await mutate('model3d.import', {
          'modelId': 'unit',
          'name': 'Cliff',
          'artifactHandle': staged.reference.handle,
        });
        final footprints = [
          [
            {'x': -.1, 'z': -.1},
            {'x': .1, 'z': -.1},
            {'x': -.1, 'z': .1},
          ],
        ];
        await mutate('border.blueprint.draft.upsert', {
          'record': {
            'id': 'cliff',
            'draft': {
              'baseRevision': 0,
              'definition': {
                'name': 'Cliff',
                'previewSeed': '1',
                'template': 'connectedLine',
                'replacesGround': true,
                'sortOrder': 0,
                'primitives': [
                  for (final role in ['lineCap', 'lineStraight', 'lineCorner'])
                    {
                      'id': role,
                      'sourceModelId': 'unit',
                      'role': role,
                      'groundFootprints': footprints,
                      if (withSurfaces)
                        'groundSurfaces': [
                          for (final height in [0, .5])
                            {
                              'sourceSmartTilePresetId': 'grass-terrain',
                              'materialId': 'grass',
                              'height': height,
                              'footprints': footprints,
                            },
                        ],
                      'weight': 1,
                      'transforms': {
                        'allowFlipX': false,
                        'allowedQuarterTurns': [0, 1, 2, 3],
                      },
                    },
                ],
                'defaults': {
                  'irregularityPermille': 0,
                  'detailDensityPermille': 0,
                  'variationPermille': 0,
                  'maxOverlapPx': 0,
                  'gapTolerancePx': 0,
                  'depthRows': 1,
                },
              },
            },
          },
        });
        final drafted = await projectFile.readAsBytes();
        final applied = await mutate('border.blueprint.publish', {
          'blueprintId': 'cliff',
        });
        ProjectManifest saved() => ProjectManifest.fromJson(
          jsonDecode(projectFile.readAsStringSync()),
        );
        final published = saved();
        expect(published.borderCatalog.formatVersion, withSurfaces ? 9 : 8);
        final expected = [
          BorderGroundPoint(x: -.1, z: -.1),
          BorderGroundPoint(x: .1, z: -.1),
          BorderGroundPoint(x: -.1, z: .1),
        ];
        for (final primitive
            in published
                .borderCatalog
                .records
                .single
                .latestPublished!
                .definition
                .primitives) {
          expect(primitive.groundFootprints.single.points, expected);
          expect(
            primitive.groundSurfaces.map((s) => s.height),
            withSurfaces ? [0.0, .5] : <double>[],
          );
        }
        await mutations.closeProject(path);
        await queries.closeAll();
        await queries.retainOnly(path);
        expect(await mutations.readRevision(path), isNotEmpty);
        expect(saved(), published);
        expect(MapData.fromJson(jsonDecode(await mapFile.readAsString())), map);
        await mutations.undo(
          path,
          entryId: applied.receipt.receiptId,
          idempotencyKey: 'undo-publication',
        );
        expect(await projectFile.readAsBytes(), drafted);
        expect(
          saved()
              .borderCatalog
              .records
              .single
              .draft
              .definition
              .primitives
              .first
              .groundFootprints
              .single
              .points,
          expected,
        );
      },
    );
  }
}
