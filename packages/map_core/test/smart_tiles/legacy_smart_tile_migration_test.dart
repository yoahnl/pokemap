import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('legacy conversion is deferred without projecting map or manifest', () {
    const project = ProjectManifest(
      name: 'Legacy project',
      version: ProjectVersion.v4,
      maps: <ProjectMapEntry>[],
      tilesets: <ProjectTilesetEntry>[],
      pathPresets: <ProjectPathPreset>[
        ProjectPathPreset(id: 'missing-pattern', name: 'Missing pattern'),
      ],
    );
    const map = MapData(
      id: 'map',
      name: 'Map',
      version: ProjectVersion.v4,
      size: GridSize(width: 1, height: 1),
      layers: <MapLayer>[
        MapLayer.path(
          id: 'path',
          name: 'Path',
          presetId: 'missing-pattern',
          cells: <bool>[true],
        ),
      ],
    );

    final result = migrateLegacyTerrainAndPathsToSmartTiles(
      project: project,
      maps: const <MapData>[map],
      removeLegacyDefinitions: true,
    );

    expect(result.project, same(project));
    expect(result.project.version, ProjectVersion.v4);
    expect(result.maps, const <MapData>[map]);
    expect(result.maps.single.version, ProjectVersion.v4);
    expect(result.maps.single.layers.single, isA<PathLayer>());
    expect(
      result.report.warnings,
      const <String>[legacySmartTileConversionDeferredCode],
    );
    expect(result.report.migratedTerrainPresets, 0);
    expect(result.report.migratedPathPresets, 0);
    expect(result.report.migratedTerrainLayers, 0);
    expect(result.report.migratedPathLayers, 0);
  });
}
