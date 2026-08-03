import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/gestures.dart' show kSecondaryButton;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/services/placed_element_instance_indexer.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/map_canvas.dart';

void main() {
  testWidgets('R rotates clockwise and Shift+R rotates counter-clockwise',
      (tester) async {
    final harness = await _pumpCanvas(tester);
    await _focusCanvas(tester);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyR);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyR);
    await tester.pump();
    expect(_quarterTurns(harness), 1);
    expect(harness.notifier.state.mapUndoStack, hasLength(1));

    harness.reset();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyR);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyR);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();
    expect(_quarterTurns(harness), 3);
    expect(harness.notifier.state.mapUndoStack, hasLength(1));
  });

  testWidgets('repeat, KeyUp, and Ctrl Meta Alt modified R are inert',
      (tester) async {
    final harness = await _pumpCanvas(tester);
    await _focusCanvas(tester);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyR);
    HardwareKeyboard.instance.handleKeyEvent(
      const KeyRepeatEvent(
        physicalKey: PhysicalKeyboardKey.keyR,
        logicalKey: LogicalKeyboardKey.keyR,
        timeStamp: Duration(milliseconds: 1),
      ),
    );
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyR);
    await tester.pump();
    expect(_quarterTurns(harness), 1);
    expect(harness.notifier.state.mapUndoStack, hasLength(1));

    for (final modifier in <LogicalKeyboardKey>[
      LogicalKeyboardKey.controlLeft,
      LogicalKeyboardKey.metaLeft,
      LogicalKeyboardKey.altLeft,
    ]) {
      harness.reset();
      await tester.sendKeyDownEvent(modifier);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyR);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyR);
      await tester.sendKeyUpEvent(modifier);
      await tester.pump();
      expect(_quarterTurns(harness), 0, reason: modifier.keyLabel);
      expect(harness.notifier.state.mapUndoStack, isEmpty);
    }
  });

  testWidgets('no selection and incompatible ownership are inert',
      (tester) async {
    final harness = await _pumpCanvas(tester);
    await _focusCanvas(tester);

    harness.notifier.state = harness.notifier.state.copyWith(
      selectedPlacedElementInstanceId: null,
    );
    await _pressR(tester);
    expect(_quarterTurns(harness), 0);
    expect(harness.notifier.state.mapUndoStack, isEmpty);

    final ownedMap = _map.copyWith(
      placedElements: <MapPlacedElement>[
        _map.placedElements.single.copyWith(
          properties: const <String, String>{
            pokemapPlacementOriginProperty: pokemapPlacementOriginEnvironment,
          },
        ),
      ],
    );
    harness.notifier.state = EditorState(
      project: _project,
      activeMap: ownedMap,
      activeLayerId: 'decor',
      selectedPlacedElementInstanceId: 'placed',
      savedMapSnapshot: ownedMap,
    );
    await _pressR(tester);
    expect(_quarterTurns(harness), 0);
    expect(harness.notifier.state.mapUndoStack, isEmpty);
  });

  testWidgets('active pointer interaction blocks rotation', (tester) async {
    final harness = await _pumpCanvas(tester);
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(MapCanvas)),
      kind: PointerDeviceKind.mouse,
    );
    await tester.pump();

    await _pressR(tester);
    expect(_quarterTurns(harness), 0);
    expect(harness.notifier.state.mapUndoStack, isEmpty);

    await gesture.up();
  });

  testWidgets('compatible rejected rotation reaches notifier feedback', (
    tester,
  ) async {
    final harness = await _pumpCanvas(tester);
    await _focusCanvas(tester);
    final constrainedMap = _map.copyWith(
      size: const GridSize(width: 3, height: 2),
      layers: const <MapLayer>[
        TileLayer(
          id: 'decor',
          name: 'Decor',
          tilesetId: 'tiles',
          tiles: <int>[0, 0, 0, 0, 0, 0],
        ),
      ],
      placedElements: const <MapPlacedElement>[
        MapPlacedElement(
          id: 'placed',
          layerId: 'decor',
          elementId: 'element-3x2',
          pos: GridPos(x: 0, y: 0),
        ),
      ],
    );
    harness.notifier.state = EditorState(
      project: _project,
      activeMap: constrainedMap,
      activeLayerId: 'decor',
      selectedPlacedElementInstanceId: 'placed',
      savedMapSnapshot: constrainedMap,
    );

    await _pressR(tester);

    expect(_quarterTurns(harness), 0);
    expect(harness.notifier.state.mapUndoStack, isEmpty);
    expect(
      harness.notifier.state.errorMessage,
      'Rotation impossible : l’empreinte tournée dépasse la carte.',
    );
  });

  testWidgets('text entry focus keeps R away from the canvas', (tester) async {
    final textController = TextEditingController();
    addTearDown(textController.dispose);
    final harness = await _pumpCanvas(
      tester,
      textField: TextField(
        key: const ValueKey<String>('rotation-shortcut-text-field'),
        controller: textController,
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('rotation-shortcut-text-field')),
    );
    await tester.pump();
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus,
      isTrue,
    );
    await _pressR(tester);

    expect(_quarterTurns(harness), 0);
    expect(harness.notifier.state.mapUndoStack, isEmpty);
  });
}

Future<void> _pressR(WidgetTester tester) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.keyR);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.keyR);
  await tester.pump();
}

int _quarterTurns(_ShortcutHarness harness) =>
    harness.notifier.state.activeMap!.placedElements.single.quarterTurns;

Future<void> _focusCanvas(WidgetTester tester) async {
  final gesture = await tester.startGesture(
    tester.getCenter(find.byType(MapCanvas)),
    kind: PointerDeviceKind.mouse,
    buttons: kSecondaryButton,
  );
  await gesture.up();
  await tester.pump();
}

Future<_ShortcutHarness> _pumpCanvas(
  WidgetTester tester, {
  Widget? textField,
}) async {
  final harness = _ShortcutHarness();
  addTearDown(harness.dispose);
  await tester.binding.setSurfaceSize(const Size(900, 700));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: harness.container,
      child: MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Scaffold(
          body: Column(
            children: [
              if (textField != null) SizedBox(height: 48, child: textField),
              const Expanded(child: MapCanvas()),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return harness;
}

final class _ShortcutHarness {
  _ShortcutHarness() {
    keepAlive = container.listen(editorNotifierProvider, (_, __) {});
    reset();
  }

  final ProviderContainer container = ProviderContainer();
  late final ProviderSubscription<EditorState> keepAlive;

  EditorNotifier get notifier =>
      container.read(editorNotifierProvider.notifier);

  void reset() {
    notifier.state = const EditorState(
      project: _project,
      activeMap: _map,
      activeLayerId: 'decor',
      selectedPlacedElementInstanceId: 'placed',
      savedMapSnapshot: _map,
    );
  }

  void dispose() {
    keepAlive.close();
    container.dispose();
  }
}

const _map = MapData(
  id: 'map',
  name: 'Map',
  version: ProjectVersion.v6,
  size: GridSize(width: 6, height: 6),
  layers: <MapLayer>[
    TileLayer(
      id: 'decor',
      name: 'Decor',
      tilesetId: 'tiles',
      tiles: <int>[
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
      ],
    ),
  ],
  placedElements: <MapPlacedElement>[
    MapPlacedElement(
      id: 'placed',
      layerId: 'decor',
      elementId: 'element-3x2',
      pos: GridPos(x: 1, y: 1),
    ),
  ],
);

const _project = ProjectManifest(
  name: 'Rotation shortcuts',
  version: ProjectVersion.v6,
  maps: <ProjectMapEntry>[],
  tilesets: <ProjectTilesetEntry>[
    ProjectTilesetEntry(
      id: 'tiles',
      name: 'Tiles',
      relativePath: 'assets/tiles.png',
    ),
  ],
  elements: <ProjectElementEntry>[
    ProjectElementEntry(
      id: 'element-3x2',
      name: 'Element 3x2',
      tilesetId: 'tiles',
      categoryId: 'decor',
      frames: <TilesetVisualFrame>[
        TilesetVisualFrame(
          source: TilesetSourceRect(x: 0, y: 0, width: 3, height: 2),
        ),
      ],
    ),
  ],
);
