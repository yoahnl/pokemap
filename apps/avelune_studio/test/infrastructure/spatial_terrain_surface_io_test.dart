import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/spatial_terrain_stroke.dart';
import 'package:avelune_studio/features/map_workspace/application/spatial_terrain_surface_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring_documents.dart';
import 'package:map_core/map_core.dart';

import '../../../../packages/map_authoring/test/domains/assets/resource_information_fixture.dart';

void main() {
  test(
    'Studio terrain drawing save reopen matches its canonical semantic action',
    () async {
      final manifest = ProjectManifest(
        name: 'Terrain',
        version: ProjectVersion.v9,
        maps: [],
        tilesets: [],
        settings: ProjectSettings(
          dimension: ProjectDimension.threeD,
          spatialCamera: SpatialCameraProfile(),
        ),
      );
      final host = await ResourceInformationFixture.create(manifest);
      addTearDown(host.dispose);
      final root = Directory(await host.root.resolveSymbolicLinks());
      const entry = ProjectMapEntry(
        id: 'map',
        name: 'Terrain',
        relativePath: 'maps/map.json',
      );
      final source = MapData(
        id: 'map',
        name: 'Terrain',
        version: ProjectVersion.v9,
        size: const GridSize(width: 8, height: 6),
        spatialScene: MapSpatialScene(width: 8, depth: 6, levelHeight: .25),
        properties: const {'keep': 'unchanged'},
        layers: [
          MapLayer.collision(
            id: 'solid',
            name: 'Collisions',
            collisions: List.filled(48, false),
          ),
        ],
      );
      final file = File('${root.path}/maps/map.json');
      await file.parent.create(recursive: true);
      final before = encodeMapDocumentBytes(source);
      await file.writeAsBytes(before);
      final projectBytes = utf8.encode(
        jsonEncode(manifest.copyWith(maps: [entry]).toJson()),
      );
      await File('${root.path}/project.json').writeAsBytes(projectBytes);
      final session = ProjectSession(
        sessionId: root.path,
        name: 'Terrain',
        directoryPath: root.path,
      );
      final port = LocalMapWorkspaceAdapter();
      await port.loadProject(session);
      final loaded = await port.loadMap(session, entry);
      final stroke = SpatialTerrainStroke(
        source: loaded.map,
        mode: SpatialTerrainMode.relief,
        level: 0,
        erase: false,
        origin: const GridPos(x: 1, y: 1),
        surfaceBrush: const SpatialTerrainSurfaceBrush(
          lowLevel: 2.5,
          highLevel: 6.25,
          direction: SpatialRampDirection.east,
        ),
      );
      stroke.paint(const GridPos(x: 3, y: 2));
      final painted = stroke.commit();
      expect(await file.readAsBytes(), before);
      final revision = await port.saveMap(session, loaded, painted);
      final reopenedPort = LocalMapWorkspaceAdapter();
      await reopenedPort.loadProject(session);
      final reopened = await reopenedPort.loadMap(session, entry);
      expect(reopened.map, painted);
      expect(reopened.revision, revision);
      expect(reopened.map.layers, source.layers);
      expect(reopened.map.properties, source.properties);
      expect(
        reopened.map.spatialScene!.heightLevels,
        source.spatialScene!.heightLevels,
      );
      expect(
        await File('${root.path}/project.json').readAsBytes(),
        projectBytes,
      );
      await file.writeAsBytes(before);
      await host.mutate('map3d.terrain.surface.upsert_batch', {
        'mapId': 'map',
        'surfaces': painted.spatialScene!.terrainSurfaces.surfaces
            .map((surface) => surface.toJson())
            .toList(),
      });
      final canonical = MapData.fromJson(
        jsonDecode(await file.readAsString()) as Map<String, dynamic>,
      );
      expect(canonical, painted);
      expect(
        await File('${root.path}/project.json').readAsBytes(),
        projectBytes,
      );
    },
  );
}
