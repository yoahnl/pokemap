import 'dart:ui' as ui;

import 'package:avelune_studio/presentation/features/map_workspace/map_canvas_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('hidden markers, passages, story zones, gameplay zones and collision layers leave no editor pixels', () async {
    const map = MapData(
      id: 'overlays',
      name: 'Overlays',
      size: GridSize(width: 5, height: 1),
      layers: [
        CollisionLayer(
          id: 'collision',
          name: 'Collision',
          collisions: [false, false, false, false, true],
        ),
      ],
      entities: [
        MapEntity(
          id: 'spawn',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 0, y: 0),
        ),
      ],
      warps: [
        MapWarp(
          id: 'door',
          pos: GridPos(x: 1, y: 0),
          targetMapId: 'overlays',
          targetPos: GridPos(x: 0, y: 0),
        ),
      ],
      triggers: [
        MapTrigger(
          id: 'story',
          type: TriggerType.event,
          area: MapRect(
            pos: GridPos(x: 2, y: 0),
            size: GridSize(width: 1, height: 1),
          ),
        ),
      ],
      gameplayZones: [
        MapGameplayZone(
          id: 'zone',
          kind: GameplayZoneKind.special,
          area: MapRect(
            pos: GridPos(x: 3, y: 0),
            size: GridSize(width: 1, height: 1),
          ),
        ),
      ],
    );
    final baseline = await _paint(map, MapEditorState());
    expect(baseline.every((count) => count > 0), isTrue);
    final keys = [
      'entity:spawn',
      'warp:door',
      'trigger:story',
      'zone:zone',
      'layer:collision',
    ];
    for (final (index, key) in keys.indexed) {
      final hidden = await _paint(map, MapEditorState(hiddenElements: {key}));
      expect(hidden[index], 0, reason: key);
      for (var other = 0; other < hidden.length; other++) {
        if (other != index) {
          expect(
            hidden[other],
            baseline[other],
            reason: '$key leaves $other unchanged',
          );
        }
      }
    }
    expect(
      await _paint(
        map,
        MapEditorState(
          lockedFamilies: {'entity', 'warp', 'trigger', 'zone', 'layer'},
        ),
      ),
      baseline,
    );
    expect(
      await _paint(
        map,
        MapEditorState(
          hiddenFamilies: {'entity', 'warp', 'trigger', 'zone', 'layer'},
        ),
      ),
      [0, 0, 0, 0, 0],
    );
  });
}

Future<List<int>> _paint(MapData map, MapEditorState state) async {
  final painter = MapCanvasOverlay(
    map: map,
    project: ProjectManifest(
      name: 'Overlays',
      maps: const [],
      tilesets: const [],
    ),
    selected: null,
    cellWidth: 16,
    cellHeight: 16,
    grid: false,
    color: const Color(0xffff0000),
    collisionColor: const Color(0xffff0000),
    isHidden: state.isHidden,
  );
  final recorder = ui.PictureRecorder();
  painter.paint(Canvas(recorder), const Size(80, 16));
  final picture = recorder.endRecording();
  final image = await picture.toImage(80, 16);
  picture.dispose();
  try {
    final bytes = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    return [
      for (var cell = 0; cell < 5; cell++)
        [
          for (var y = 0; y < 16; y++)
            for (var x = cell * 16; x < cell * 16 + 16; x++)
              if (bytes.getUint8((y * 80 + x) * 4 + 3) > 0) 1,
        ].length,
    ];
  } finally {
    image.dispose();
  }
}
