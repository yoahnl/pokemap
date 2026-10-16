import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/load_runtime_map_bundle.dart';
import 'package:map_runtime/src/application/runtime_manifest_tilesets.dart';
import 'package:map_runtime/src/infrastructure/tile_image_loader.dart';
import 'package:map_runtime/src/presentation/flame/warp_presentation_renderer.dart';
import 'package:map_runtime/src/application/warp_presentation_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final presentation = SceneWarpPresentation(mode: SceneWarpPresentationMode.illustrated, illustrationElementId: 'picture');
  final map = MapData(id: 'room', name: 'Room', size: const GridSize(width: 8, height: 8), warps: const [MapWarp(id: 'arrival', pos: GridPos(x: 2, y: 3), targetMapId: 'room', targetPos: GridPos(x: 2, y: 3), triggerMode: MapWarpTriggerMode.sceneOnly)]);
  final manifest = ProjectManifest(name: 'Illustrated warp', maps: const [
    ProjectMapEntry(id: 'room', name: 'Room', relativePath: 'maps/room.json')],
    tilesets: const [ProjectTilesetEntry(id: 'sheet', name: 'Picture', relativePath: 'tilesets/picture.png',
      source: ProjectRegularAtlasTilesetSource(assetId: 'sheet', pixelWidth: 4, pixelHeight: 3, tileWidth: 4, tileHeight: 3))],
    elementCategories: const [ProjectElementCategory(id: 'pictures', name: 'Pictures')],
    elements: const [ProjectElementEntry(id: 'picture', name: 'Picture', tilesetId: 'sheet', categoryId: 'pictures',
      frames: [TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0))])],
    scenes: [SceneAsset(id: 'travel', name: 'Travel', graph: SceneGraph(startNodeId: 'start', nodes: [SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(id: 'warp', kind: SceneNodeKind.action, payload: SceneActionPayload.interactive(
        SceneInteractiveCommand.warp(destinationMapId: 'room', warpId: 'arrival', presentation: presentation))), SceneNode(id: 'end', kind: SceneNodeKind.end)], edges: [
      SceneEdge(id: 'begin', fromNodeId: 'start', fromPortId: 'completed', toNodeId: 'warp', kind: SceneEdgeKind.defaultFlow),
      for (final port in ['completed', 'blocked']) SceneEdge(id: port, fromNodeId: 'warp', fromPortId: port, toNodeId: 'end', kind: SceneEdgeKind.actionCompleted)]))]);
  test('Scene illustration closes the atlas set without a placed element', () {
    expect(map.placedElements, isEmpty); expect(map.entities, isEmpty);
    expect(collectAllRuntimeTilesetIds(map, manifest), {'sheet'});
  });
  test('normal native bundle loader decodes and paints the registered image', () async {
    final dir = await Directory.systemTemp.createTemp('warp-real-atlas-');
    addTearDown(() => dir.delete(recursive: true));
    await Directory('${dir.path}/maps').create(); await Directory('${dir.path}/tilesets').create();
    await File('${dir.path}/project.json').writeAsString(jsonEncode(manifest.toJson()));
    await File('${dir.path}/maps/room.json').writeAsString(jsonEncode(map.toJson()));
    final recorder = ui.PictureRecorder(); ui.Canvas(recorder).drawColor(const ui.Color(0xFF0000FF), ui.BlendMode.src);
    final picture = recorder.endRecording(); final authored = await picture.toImage(4, 3);
    await File('${dir.path}/tilesets/picture.png').writeAsBytes((await authored.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List());
    authored.dispose(); picture.dispose();
    final bundle = await loadRuntimeMapBundle(projectFilePath: '${dir.path}/project.json', mapId: 'room');
    expect(bundle.tilesetAbsolutePathsById.keys, ['sheet']);
    final images = await loadTilesetImagesById(bundle.tilesetAbsolutePathsById);
    addTearDown(() { for (final image in images.values) { image.dispose(); } });
    final renderer = RuntimeWarpPresentationRenderer(presentation: presentation,
      project: bundle.manifest, images: images);
    final outputRecorder = ui.PictureRecorder(); renderer.render(ui.Canvas(outputRecorder), const ui.Size(4, 3),
      const RuntimeWarpPresentationFrame(worldOpacity: 1, illustrationOpacity: 1));
    final outputPicture = outputRecorder.endRecording(); final output = await outputPicture.toImage(4, 3);
    final pixels = (await output.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    expect([for (var i = 0; i < 4; i++) pixels.getUint8(i)], [0, 0, 255, 255]);
    output.dispose(); outputPicture.dispose();
  });
}
