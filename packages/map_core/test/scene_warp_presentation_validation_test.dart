import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  final command = SceneInteractiveCommand.warp(
    destinationMapId: 'cave', warpId: 'arrival',
    presentation: SceneWarpPresentation(
      mode: SceneWarpPresentationMode.illustrated,
      illustrationElementId: 'cave-picture',
    ),
  );
  test('known static native illustration is publishable', () {
    expect(diagnoseInteractiveCommand(command: command, project: project()), isEmpty);
  });
  test('missing duplicate and animated illustrations are rejected', () {
    final p = project();
    for (final invalid in [
      p.copyWith(elements: []),
      p.copyWith(elements: [p.elements.single, p.elements.single]),
      p.copyWith(elements: [p.elements.single.copyWith(frames: [
        p.elements.single.frames.single, p.elements.single.frames.single,
      ])]),
      p.copyWith(tilesets: []),
      p.copyWith(tilesets: [p.tilesets.single, p.tilesets.single]),
      p.copyWith(elements: [p.elements.single.copyWith(frames: [
        const TilesetVisualFrame(source: TilesetSourceRect(x: 1, y: 0)),
      ])]),
      p.copyWith(settings: p.settings.copyWith(dimension: ProjectDimension.threeD)),
    ]) {
      expect(diagnoseInteractiveCommand(command: command, project: invalid),
          isNotEmpty, reason: '${invalid.toJson()}');
    }
  });
  test('basic warp still supports projects without an illustration', () {
    final plain = SceneInteractiveCommand.warp(destinationMapId: 'cave', warpId: 'arrival');
    final p = project();
    expect(diagnoseInteractiveCommand(command: plain,
        project: p.copyWith(elements: [], settings: p.settings.copyWith(
          dimension: ProjectDimension.threeD))), isEmpty);
  });
}

ProjectManifest project() => ProjectManifest(
  name: 'Cave',
  maps: const [ProjectMapEntry(id: 'cave', name: 'Cave', relativePath: 'maps/cave.json')],
  tilesets: [ProjectTilesetEntry(id: 'picture', name: 'Cave illustration',
    relativePath: 'tilesets/picture.png',
    source: ProjectRegularAtlasTilesetSource(assetId: 'picture',
      pixelWidth: 512, pixelHeight: 384, tileWidth: 512, tileHeight: 384))],
  elements: const [ProjectElementEntry(id: 'cave-picture', name: 'Cave',
    tilesetId: 'picture', categoryId: 'transitions',
    frames: [TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0))])],
);
