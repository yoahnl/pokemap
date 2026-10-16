import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/warp_presentation_controller.dart';
import 'package:map_runtime/src/infrastructure/runtime_tileset_image.dart';
import 'package:map_runtime/src/presentation/flame/warp_presentation_renderer.dart';

Future<ui.Image> image(int width, int height, ui.Color color) async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawColor(color, ui.BlendMode.src);
  final picture = recorder.endRecording();
  final result = await picture.toImage(width, height); picture.dispose(); return result;
}
Future<List<int>> pixel(RuntimeWarpPresentationRenderer renderer,
    RuntimeWarpPresentationFrame frame, {int x = 50, int y = 40}) async {
  final recorder = ui.PictureRecorder(); final canvas = ui.Canvas(recorder);
  canvas.drawColor(const ui.Color(0xFFFF0000), ui.BlendMode.src);
  renderer.render(canvas, const ui.Size(100, 80), frame);
  final picture = recorder.endRecording(); final output = await picture.toImage(100, 80);
  final data = (await output.toByteData(format: ui.ImageByteFormat.rawRgba))!;
  final offset = (y * 100 + x) * 4;
  final result = [for (var i = 0; i < 4; i++) data.getUint8(offset + i)];
  output.dispose(); picture.dispose(); return result;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final plain = SceneWarpPresentation(mode: SceneWarpPresentationMode.fade);
  test('full cover paints actual black pixels over the map', () async {
    final renderer = RuntimeWarpPresentationRenderer(presentation: plain, project: project());
    expect(await pixel(renderer, const RuntimeWarpPresentationFrame(worldOpacity: 1)), [0, 0, 0, 255]);
  });
  test('cleared presentation leaves the world visible', () async {
    final renderer = RuntimeWarpPresentationRenderer(presentation: plain, project: project());
    expect(await pixel(renderer, const RuntimeWarpPresentationFrame()), [255, 0, 0, 255]);
  });
  test('world reveal interpolates independently of image fade', () async {
    final renderer = RuntimeWarpPresentationRenderer(presentation: plain, project: project());
    final actual = await pixel(renderer, const RuntimeWarpPresentationFrame(worldOpacity: .5));
    expect(actual[0], inInclusiveRange(126, 129)); expect(actual[1], 0);
  });
  test('native image renders at its own opacity above the covered world', () async {
    final p = SceneWarpPresentation(mode: SceneWarpPresentationMode.illustrated, illustrationElementId: 'picture');
    final bitmap = await image(4, 3, const ui.Color(0xFF0000FF)); addTearDown(bitmap.dispose);
    final renderer = RuntimeWarpPresentationRenderer(presentation: p, project: project(), images: {'picture-sheet': RuntimeTilesetImage.borrowed(bitmap)});
    expect(await pixel(renderer, const RuntimeWarpPresentationFrame(worldOpacity: 1, illustrationOpacity: 1)), [0, 0, 255, 255]);
    final half = await pixel(renderer, const RuntimeWarpPresentationFrame(illustrationOpacity: .5));
    expect(half[0], inInclusiveRange(126, 129)); expect(half[2], inInclusiveRange(126, 129));
  });
  test('image letterbox uses black and clears with the image', () async {
    final p = SceneWarpPresentation(mode: SceneWarpPresentationMode.illustrated, illustrationElementId: 'picture');
    final bitmap = await image(4, 3, const ui.Color(0xFF0000FF)); addTearDown(bitmap.dispose);
    final renderer = RuntimeWarpPresentationRenderer(presentation: p, project: project(), images: {'picture-sheet': RuntimeTilesetImage.borrowed(bitmap)});
    expect(await pixel(renderer, const RuntimeWarpPresentationFrame(illustrationOpacity: 1), y: 0), [0, 0, 0, 255]);
    expect(await pixel(renderer, const RuntimeWarpPresentationFrame(), y: 0), [255, 0, 0, 255]);
  });
  test('cave entrance and exit have opposite ordered grayscale bands', () async {
    for (final entering in [true, false]) {
      final mode = entering ? SceneWarpPresentationMode.caveEntrance : SceneWarpPresentationMode.caveExit;
      final p = SceneWarpPresentation(mode: mode, illustrationElementId: entering ? 'picture' : null);
      final bitmap = await image(4, 3, const ui.Color(0xFF0000FF)); addTearDown(bitmap.dispose);
      final renderer = RuntimeWarpPresentationRenderer(presentation: p, project: project(),
        images: entering ? {'picture-sheet': RuntimeTilesetImage.borrowed(bitmap)} : {});
      final frame = const RuntimeWarpPresentationFrame(worldOpacity: 1, caveElapsedMs: 200);
      final outer = await pixel(renderer, frame, x: 0, y: 0);
      final inner = await pixel(renderer, frame);
      expect(outer[0], inInclusiveRange(126, 129));
      expect(inner[0], entering ? 255 : 0);
      expect(outer[0], outer[1]); expect(outer[1], outer[2]);
    }
  });
  test('completed cave fill is opaque and deterministic', () async {
    final p = SceneWarpPresentation(mode: SceneWarpPresentationMode.caveExit);
    final renderer = RuntimeWarpPresentationRenderer(presentation: p, project: project());
    expect(await pixel(renderer, const RuntimeWarpPresentationFrame(caveElapsedMs: 899)), [255, 255, 255, 255]);
  });
  test('missing or out-of-bounds image is rejected before starting the warp', () {
    final p = SceneWarpPresentation(mode: SceneWarpPresentationMode.illustrated, illustrationElementId: 'picture');
    expect(() => RuntimeWarpPresentationRenderer(presentation: p, project: project()), throwsStateError);
  });
}

ProjectManifest project() => ProjectManifest(name: 'Warp picture', maps: [],
  tilesets: const [ProjectTilesetEntry(id: 'picture-sheet', name: 'Picture', relativePath: 'picture.png',
    source: ProjectRegularAtlasTilesetSource(assetId: 'picture-sheet', pixelWidth: 4, pixelHeight: 3, tileWidth: 4, tileHeight: 3))],
  elements: const [ProjectElementEntry(id: 'picture', name: 'Picture', categoryId: 'pictures', tilesetId: 'picture-sheet',
    frames: [TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0))])]);
