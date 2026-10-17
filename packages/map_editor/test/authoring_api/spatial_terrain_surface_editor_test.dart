import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/authoring_api/authoring_mutation_adapter.dart';
import 'package:map_editor/src/application/authoring_api/authoring_query_adapter.dart';
import 'package:map_editor/src/infrastructure/authoring_api/editor_project_file_reader.dart';

void main() {
  test(
    'editor bridge saves reopens edits deletes and undoes native terrain surfaces',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'terrain-surface-editor-',
      );
      addTearDown(() => root.delete(recursive: true));
      final map = MapData(
        id: 'map',
        name: 'Terrain',
        version: ProjectVersion.v9,
        size: const GridSize(width: 3, height: 3),
        spatialScene: MapSpatialScene(width: 3, depth: 3),
      );
      final project = ProjectManifest(
        name: 'Terrain',
        version: ProjectVersion.v9,
        tilesets: [],
        maps: const [
          ProjectMapEntry(
            id: 'map',
            name: 'Terrain',
            relativePath: 'maps/map.json',
          ),
        ],
        settings: ProjectSettings(
          dimension: ProjectDimension.threeD,
          spatialCamera: SpatialCameraProfile(),
        ),
      );
      final file = File('${root.path}/maps/map.json');
      await file.parent.create(recursive: true);
      await file.writeAsString(jsonEncode(map.toJson()));
      await File(
        '${root.path}/project.json',
      ).writeAsString(jsonEncode(project.toJson()));
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
      var sequence = 0;
      Future<EditorAuthoringMutationResult> mutate(
        String action,
        Map<String, Object?> parameters,
      ) async {
        final before = await file.readAsBytes();
        final planned = await mutations.plan(
          path,
          actionId: action,
          parameters: parameters,
          idempotencyKey: 'plan-${sequence++}',
        );
        expect(await file.readAsBytes(), before);
        return mutations.apply(planned, operationId: 'apply-${sequence++}');
      }

      final surface = SpatialTerrainSurface(
        id: 'hill',
        x: 1,
        z: 1,
        height: 2,
        gradientX: .25,
        footprints: [
          BorderGroundFootprint(
            points: [
              BorderGroundPoint(x: 0, z: 0),
              BorderGroundPoint(x: 1, z: 0),
              BorderGroundPoint(x: 1, z: 1),
              BorderGroundPoint(x: 0, z: 1),
            ],
          ),
        ],
      );
      await mutate('map3d.terrain.surface.upsert_batch', {
        'mapId': 'map',
        'surfaces': [surface.toJson()],
      });
      final created = await file.readAsBytes();
      MapData saved() => MapData.fromJson(
        jsonDecode(file.readAsStringSync()) as Map<String, dynamic>,
      );
      expect(saved().spatialScene!.worldHeightAt(1.5, 1.5), 2.125);
      await mutations.closeProject(path);
      await queries.closeAll();
      await queries.retainOnly(path);
      expect(await mutations.readRevision(path), isNotEmpty);
      expect(await file.readAsBytes(), created);
      await mutate('map3d.terrain.surface.upsert_batch', {
        'mapId': 'map',
        'surfaces': [surface.copyWith(height: 3).toJson()],
      });
      expect(saved().spatialScene!.worldHeightAt(1.5, 1.5), 3.125);
      final beforeDelete = await file.readAsBytes();
      final deleted = await mutate('map3d.terrain.surface.delete_batch', {
        'mapId': 'map',
        'surfaceIds': ['hill'],
      });
      expect(saved().spatialScene!.terrainSurfaces.surfaces, isEmpty);
      await mutations.undo(
        path,
        entryId: deleted.receipt.receiptId,
        idempotencyKey: 'undo-delete',
      );
      expect(await file.readAsBytes(), beforeDelete);
    },
  );
}
