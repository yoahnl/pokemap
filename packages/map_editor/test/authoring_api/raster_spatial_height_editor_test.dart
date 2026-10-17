import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/authoring_api/authoring_mutation_adapter.dart';
import 'package:map_editor/src/application/authoring_api/authoring_query_adapter.dart';
import 'package:map_editor/src/infrastructure/authoring_api/editor_project_file_reader.dart';

void main() {
  test(
    'editor publishes paints reopens and undoes raster height profiles',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'raster-height-editor-',
      );
      addTearDown(() => root.delete(recursive: true));
      final map = MapData(
        id: 'map',
        name: 'Map',
        version: ProjectVersion.v9,
        size: const GridSize(width: 3, height: 3),
        spatialScene: MapSpatialScene(
          width: 3,
          depth: 3,
          heightLevels: List.filled(9, 8),
        ),
      );
      final project = ProjectManifest(
        name: 'Ground',
        version: ProjectVersion.v9,
        tilesets: [],
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
      final mapFile = File('${root.path}/maps/map.json');
      await mapFile.parent.create(recursive: true);
      await mapFile.writeAsString(jsonEncode(map.toJson()));
      final projectFile = File('${root.path}/project.json');
      await projectFile.writeAsString(jsonEncode(project.toJson()));
      final source = File('${root.path}/grass.png');
      await source.writeAsBytes(
        base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
        ),
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
        final plan = await mutations.plan(
          path,
          actionId: action,
          parameters: parameters,
          idempotencyKey: 'height-plan-${serial++}',
        );
        expect(await mapFile.readAsBytes(), before);
        return mutations.apply(plan, operationId: 'height-apply-${serial++}');
      }

      final staged = await mutations.stageArtifact(
        path,
        sourcePath: source.path,
      );
      await mutate('tileset.import_image', {
        'artifactHandle': staged.reference.handle,
        'tilesetId': 'grass',
        'name': 'Grass',
        'tileWidth': 1,
        'tileHeight': 1,
      });
      await mutate('smart_tile.atlas.upsert', {
        'atlas': {
          'id': 'atlas',
          'name': 'Grass',
          'tilesetId': 'grass',
          'cellWidth': 1,
          'cellHeight': 1,
          'columns': 1,
          'rows': 1,
        },
      });
      await mutate('smart_tile.material.upsert', {
        'material': {
          'id': 'grass',
          'name': 'Grass',
          'connectionGroupId': 'grass',
        },
      });
      final parts = [
        for (final height in [0, -1, -2.5])
          {
            'source': {
              'kind': 'frame',
              'frame': {'atlasId': 'atlas', 'column': 0, 'row': 0},
            },
            'spatialHeightOffset': height,
            if (height == -1) 'spatialFollowTerrain': false,
            'spatialClip': {'left': 0.0, 'top': .0625, 'right': 1.0, 'bottom': 1.0},
          },
      ];
      await mutate('smart_tile.preset.publish', {
        'preset': {
          'id': 'ground',
          'name': 'Ground',
          'usage': 'terrain',
          'topology': 'uniform',
          'templateHint': 'simple',
          'defaultMaterialId': 'grass',
          'allowedMaterialIds': ['grass'],
          'coveragePolicy': 'complete',
          'coverageProfile': {'mode': 'template'},
          'transformPolicy': {},
          'rules': [
            {
              'id': 'base',
              'centerMatch': {'kind': 'material', 'materialId': 'grass'},
              'candidates': [
                {'id': 'supports', 'parts': parts},
              ],
            },
          ],
        },
      });
      await mutate('smart_tile.layer.create', {
        'mapId': 'map',
        'layerId': 'ground',
        'name': 'Ground',
        'presetId': 'ground',
      });
      await mutate('smart_tile.material.upsert', {
        'material': {
          'id': 'relief',
          'name': 'Relief',
          'connectionGroupId': 'grass',
        },
      });
      final existing = ProjectManifest.fromJson(
        jsonDecode(await projectFile.readAsString()),
      ).smartTileCatalog.presets.single;
      await mutate('smart_tile.preset.publish', {
        'preset': existing
            .copyWith(
              allowedMaterialIds: ['grass', 'relief'],
              rules: [
                ...existing.rules,
                existing.rules.single.copyWith(
                  id: 'relief',
                  centerMatch: SmartTileSlotMatch.material('relief'),
                ),
              ],
            )
            .toJson(),
      });
      final beforePaint = await mapFile.readAsBytes();
      final painted = await mutate('smart_tile.cell.paint_batch', {
        'mapId': 'map',
        'layerId': 'ground',
        'strokes': [
          {
            'materialId': 'grass',
            'cells': [
              {'x': 1, 'y': 1},
            ],
          },
          {
            'materialId': 'relief',
            'cells': [
              {'x': 2, 'y': 1},
            ],
          },
        ],
      });
      final saved = await mapFile.readAsBytes();
      expect(
        (MapData.fromJson(jsonDecode(utf8.decode(saved))).layers.single
                as SmartTileLayer)
            .materialPalette,
        ['', 'grass', 'relief'],
      );
      final published = ProjectManifest.fromJson(
        jsonDecode(await projectFile.readAsString()),
      );
      expect(published.smartTileCatalog.formatVersion, ProjectSmartTileCatalog.currentFormatVersion);
      expect(
        published
            .smartTileCatalog
            .presets
            .single
            .rules
            .first
            .candidates
            .single
            .parts
            .map((part) => part.spatialHeightOffset),
        [0, -1, -2.5],
      );
      expect(published.smartTileCatalog.presets.single.rules.first.candidates.single.parts.map((part) => part.spatialClip?.top), [.0625, .0625, .0625]);
      expect(published.smartTileCatalog.presets.single.rules.first.candidates.single.parts.map((part) => part.spatialFollowTerrain), [true, false, true]);
      await mutations.closeProject(path);
      await queries.closeAll();
      await queries.retainOnly(path);
      expect(await mutations.readRevision(path), isNotEmpty);
      expect(await mapFile.readAsBytes(), saved);
      expect(
        ProjectManifest.fromJson(jsonDecode(await projectFile.readAsString())),
        published,
      );
      expect(
        MapData.fromJson(jsonDecode(await mapFile.readAsString())).spatialScene,
        map.spatialScene,
      );
      await mutations.undo(
        path,
        entryId: painted.receipt.receiptId,
        idempotencyKey: 'undo-height-paint',
      );
      expect(await mapFile.readAsBytes(), beforePaint);
    },
  );
}
