import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/ui/canvas/cinematics/cinematic_map_backdrop_layer_render_plan.dart';

void main() {
  test('visible Border-only backdrop reports that nothing can be rendered', () {
    const map = MapData(
      id: 'map',
      name: 'Border Map',
      version: ProjectVersion.v2,
      size: GridSize(width: 2, height: 2),
      layers: <MapLayer>[
        MapLayer.border(id: 'border', name: 'Côte'),
      ],
    );
    const manifest = ProjectManifest(
      name: 'Border Project',
      version: ProjectVersion.v2,
      maps: <ProjectMapEntry>[],
      tilesets: <ProjectTilesetEntry>[],
      surfaceCatalog: ProjectSurfaceCatalog.empty(),
    );

    final plan = buildCinematicMapBackdropLayerRenderPlan(
      mapData: map,
      manifest: manifest,
      tilesets: const {},
    );

    expect(plan.instructions, isEmpty);
    expect(
      plan.diagnostics.map((diagnostic) => diagnostic.code),
      <String>['noBitmapInstructions'],
    );
  });

  test('a hidden Border keeps the legacy empty-backdrop diagnostic', () {
    const map = MapData(
      id: 'map',
      name: 'Hidden Border Map',
      version: ProjectVersion.v2,
      size: GridSize(width: 2, height: 2),
      layers: <MapLayer>[
        MapLayer.border(
          id: 'border',
          name: 'Côte',
          isVisible: false,
        ),
      ],
    );
    const manifest = ProjectManifest(
      name: 'Border Project',
      version: ProjectVersion.v2,
      maps: <ProjectMapEntry>[],
      tilesets: <ProjectTilesetEntry>[],
      surfaceCatalog: ProjectSurfaceCatalog.empty(),
    );

    final plan = buildCinematicMapBackdropLayerRenderPlan(
      mapData: map,
      manifest: manifest,
      tilesets: const {},
    );

    expect(plan.instructions, isEmpty);
    expect(
      plan.diagnostics.map((diagnostic) => diagnostic.code),
      <String>['noBitmapInstructions'],
    );
  });
}
