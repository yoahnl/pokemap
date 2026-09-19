import 'dart:ui' as ui;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_canvas_overlay.dart';
import '../support/map_workspace_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'saved story zones render bounded labels and outlines without showing other triggers',
    () async {
      final map = workspaceMap('a').copyWith(
        triggers: const [
          MapTrigger(
            id: 'story',
            name: 'Accueil du quai',
            type: TriggerType.event,
            area: MapRect(
              pos: GridPos(x: 1, y: 1),
              size: GridSize(width: 4, height: 2),
            ),
          ),
          MapTrigger(
            id: 'warp',
            name: 'Invisible ici',
            type: TriggerType.warp,
            area: MapRect(
              pos: GridPos(x: 6, y: 1),
              size: GridSize(width: 2, height: 2),
            ),
          ),
          MapTrigger(
            id: 'offscreen',
            name: 'Hors champ',
            type: TriggerType.event,
            area: MapRect(
              pos: GridPos(x: 10, y: 1),
              size: GridSize(width: 2, height: 2),
            ),
          ),
        ],
      );
      final restored = MapData.fromJson(
        jsonDecode(jsonEncode(map.toJson())) as Map<String, dynamic>,
      );
      final painter = MapCanvasOverlay(
        map: restored,
        project: workspaceProject,
        selected: null,
        cellWidth: 32,
        cellHeight: 32,
        grid: false,
        color: const Color(0xff00ff00),
        labelBackground: const Color(0xff0000ff),
        labelForeground: const Color(0xffffffff),
      );
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder)
        ..clipRect(const Rect.fromLTWH(0, 0, 256, 128));
      painter.paint(canvas, const Size(256, 128));
      final picture = recorder.endRecording();
      final image = await picture.toImage(256, 128);
      picture.dispose();
      final bytes = (await image.toByteData())!.buffer.asUint8List();
      image.dispose();
      List<int> pixel(int x, int y) =>
          bytes.sublist((y * 256 + x) * 4, (y * 256 + x) * 4 + 4);
      expect(pixel(32, 80)[1], greaterThan(150));
      expect(pixel(36, 35)[2], greaterThan(0));
      expect(pixel(193, 80)[3], 0);
      expect(pixel(64, 80)[3], 0);
      expect(map.triggers, restored.triggers);
    },
  );
}
