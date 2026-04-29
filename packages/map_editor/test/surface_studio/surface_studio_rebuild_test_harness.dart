import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_panel.dart';

Widget wrapSurfaceStudioForTest({
  SurfaceStudioReadModel? readModel,
  double width = 2048,
  double height = 1120,
}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(size: Size(width, height)),
      child: CupertinoPageScaffold(
        child: SizedBox(
          width: width,
          height: height,
          child: SurfaceStudioPanel(
            readModel:
                readModel ?? buildSurfaceStudioReadModelFromCatalog(_catalog()),
            projectTilesets: const <ProjectTilesetEntry>[
              ProjectTilesetEntry(
                id: 'water_tiles',
                name: 'Water Tiles',
                relativePath: 'missing/water.png',
                sortOrder: 0,
              ),
            ],
            projectRootPath: '/missing/project',
          ),
        ),
      ),
    ),
  );
}

Future<void> pumpSurfaceStudioForTest(
  WidgetTester tester, {
  SurfaceStudioReadModel? readModel,
  double width = 2048,
  double height = 1120,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, height);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    wrapSurfaceStudioForTest(
      readModel: readModel,
      width: width,
      height: height,
    ),
  );
}

ProjectSurfaceCatalog _catalog() {
  const atlasId = 'water-atlas';
  final animations = <ProjectSurfaceAnimation>[
    for (var column = 0; column < 12; column++)
      ProjectSurfaceAnimation(
        id: 'water-col-$column',
        name: 'Water Column $column',
        timeline: SurfaceAnimationTimeline(
          frames: [
            for (var row = 0; row < 32; row++)
              SurfaceAnimationFrame(
                tileRef: SurfaceAtlasTileRef(
                  atlasId: atlasId,
                  column: column,
                  row: row,
                ),
                durationMs: 120,
              ),
          ],
        ),
        syncGroupId: atlasId,
        sortOrder: column,
      ),
  ];

  return ProjectSurfaceCatalog(
    atlases: [
      ProjectSurfaceAtlas(
        id: atlasId,
        name: 'Water Atlas',
        tilesetId: 'water_tiles',
        geometry: SurfaceAtlasGeometry(
          tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
          gridSize: SurfaceAtlasGridSize(columns: 12, rows: 32),
          layout: SurfaceAtlasLayout.grid,
        ),
      ),
    ],
    animations: animations,
    presets: [
      ProjectSurfacePreset(
        id: 'water-surface',
        name: 'Water Surface',
        variantAnimations: SurfaceVariantAnimationRefSet(
          refs: [
            SurfaceVariantAnimationRef(
              role: SurfaceVariantRole.isolated,
              animationId: 'water-col-3',
            ),
            SurfaceVariantAnimationRef(
              role: SurfaceVariantRole.endNorth,
              animationId: 'water-col-4',
            ),
          ],
        ),
      ),
    ],
  );
}
