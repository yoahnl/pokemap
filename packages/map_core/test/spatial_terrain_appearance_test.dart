import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  final project = ProjectManifest(
    name: 'Relief',
    maps: [],
    tilesets: const [
      ProjectTilesetEntry(id: 'rock', name: 'Rock', relativePath: 'rock.png'),
    ],
    settings: ProjectSettings(
      dimension: ProjectDimension.threeD,
      spatialCamera: SpatialCameraProfile(),
    ),
    smartTileCatalog: ProjectSmartTileCatalog(
      atlases: const [
        ProjectSmartTileAtlas(
          id: 'cliff',
          name: 'Cliff',
          tilesetId: 'rock',
          columns: 3,
          rows: 2,
        ),
      ],
    ),
  );
  MapData map(SmartTileFrameRef? frame) => MapData(
    id: 'map',
    name: 'Map',
    version: ProjectVersion.v9,
    size: const GridSize(width: 1, height: 1),
    spatialScene: MapSpatialScene(width: 1, depth: 1, cliffFrame: frame),
  );
  test('cliff appearance rejects missing atlases and out of bounds spans', () {
    for (final frame in const [
      SmartTileFrameRef(atlasId: 'missing', column: 0, row: 0),
      SmartTileFrameRef(atlasId: 'cliff', column: 3, row: 0),
      SmartTileFrameRef(atlasId: 'cliff', column: 2, row: 0, columnSpan: 2),
      SmartTileFrameRef(atlasId: 'cliff', column: 0, row: 1, rowSpan: 2),
    ]) {
      expect(
        () =>
            MapValidator.validate(map(frame), projectDialogueContext: project),
        throwsA(isA<ValidationException>()),
      );
    }
  });
  test('appearance updates and explicit clears preserve the terrain scene', () {
    const frame = SmartTileFrameRef(atlasId: 'cliff', column: 1, row: 1);
    final before = map(null);
    final after = const SpatialMapOperations().configureTerrainAppearance(
      before,
      cliffFrame: frame,
    );
    expect(after.spatialScene!.cliffFrame, frame);
    expect(after.spatialScene!.copyWith().cliffFrame, frame);
    expect(after.spatialScene!.copyWith(cliffFrame: null).cliffFrame, isNull);
    MapValidator.validate(after, projectDialogueContext: project);
    expect(
      const SpatialMapOperations().configureTerrainAppearance(after),
      before,
    );
  });
}
