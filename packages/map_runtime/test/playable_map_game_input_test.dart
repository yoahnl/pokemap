import 'dart:ui' show KeyEventDeviceType;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show KeyEventResult;
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlayableMapGame runtime input seam', () {
    test('public runtime input API is safe before onLoad', () {
      final game = PlayableMapGame(
        bundle: _baseBundle(),
        projectFilePath: '/tmp/project.json',
      );

      expect(
        () => game.handleRuntimeInputEvent(
          const RuntimeInputEvent.press(RuntimeInputControl.primary),
        ),
        returnsNormally,
      );
      expect(
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.press(RuntimeInputControl.primary),
        ),
        isFalse,
      );
      expect(
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.release(RuntimeInputControl.up),
        ),
        isFalse,
      );
    });

    test('onKeyEvent forwards keyboard events to the runtime input seam', () {
      final game = _RecordingPlayableMapGame(
        bundle: _baseBundle(),
        projectFilePath: '/tmp/project.json',
      );

      final result = game.onKeyEvent(
        const KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.enter,
          logicalKey: LogicalKeyboardKey.enter,
          timeStamp: Duration.zero,
        ),
        const <LogicalKeyboardKey>{},
      );

      expect(result, KeyEventResult.handled);
      expect(
        game.recordedEvents,
        const <RuntimeInputEvent>[
          RuntimeInputEvent.press(RuntimeInputControl.primary),
        ],
      );
    });

    test('onKeyEvent forwards gamepad buttons to the runtime input seam', () {
      final game = _RecordingPlayableMapGame(
        bundle: _baseBundle(),
        projectFilePath: '/tmp/project.json',
      );

      final downResult = game.onKeyEvent(
        const KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.enter,
          logicalKey: LogicalKeyboardKey.gameButtonA,
          timeStamp: Duration.zero,
          deviceType: KeyEventDeviceType.gamepad,
        ),
        const <LogicalKeyboardKey>{},
      );
      final upResult = game.onKeyEvent(
        const KeyUpEvent(
          physicalKey: PhysicalKeyboardKey.enter,
          logicalKey: LogicalKeyboardKey.gameButtonA,
          timeStamp: Duration.zero,
          deviceType: KeyEventDeviceType.gamepad,
        ),
        const <LogicalKeyboardKey>{},
      );

      expect(downResult, KeyEventResult.handled);
      expect(upResult, KeyEventResult.handled);
      expect(
        game.recordedEvents,
        const <RuntimeInputEvent>[
          RuntimeInputEvent.press(RuntimeInputControl.primary),
          RuntimeInputEvent.release(RuntimeInputControl.primary),
        ],
      );
    });
  });
}

class _RecordingPlayableMapGame extends PlayableMapGame {
  _RecordingPlayableMapGame({
    required super.bundle,
    required super.projectFilePath,
  });

  final List<RuntimeInputEvent> recordedEvents = <RuntimeInputEvent>[];

  @override
  bool handleRuntimeInputEvent(RuntimeInputEvent event) {
    recordedEvents.add(event);
    return true;
  }
}

RuntimeMapBundle _baseBundle() {
  return RuntimeMapBundle(
    manifest: const ProjectManifest(
      name: 'Test Project',
      maps: [
        ProjectMapEntry(
          id: 'test_map',
          name: 'Test Map',
          relativePath: 'maps/test_map.json',
        ),
      ],
      tilesets: [],
    ),
    map: const MapData(
      id: 'test_map',
      name: 'Test Map',
      size: GridSize(width: 8, height: 8),
      layers: [
        MapLayer.object(id: 'objects', name: 'Objects'),
      ],
    ),
    projectRootDirectory: '/tmp/project',
    tilesetAbsolutePathsById: const {},
  );
}
